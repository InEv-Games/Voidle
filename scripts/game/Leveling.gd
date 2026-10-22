class_name Leveling
extends RefCounted

## Level rules for districts, cities and the planet — each tier is unlocked by
## the one below it:
##   District  the Capital District levels freely; any other district needs a
##             road partner (POIData.neighbors) already at the target level, so
##             levels spread outward from the Capital. Costs credits + population;
##             gives +2 building slots and more base income.
##   City      needs a total of city_level_req(next) district levels in the City
##             (Capital District included). Costs credits + population; each
##             level lets the City hold more districts.
##   Planet    needs a total of planet_level_req(next) city levels; each level
##             lets the planet hold one more City.
## Balance numbers come from the active profile (Balance.cfg).

## Badge colour for a level: cool at Lv1, warming towards gold at Lv5+.
static func level_color(lv: int) -> Color:
	const COLS := [Color(0.55, 0.62, 0.78), Color(0.35, 0.85, 0.55), Color(0.30, 0.80, 0.95),
		Color(0.70, 0.50, 1.00), Color(1.00, 0.78, 0.30)]
	return COLS[clampi(lv - 1, 0, COLS.size() - 1)]

# ── Districts ────────────────────────────────────────────────────────────────

## Credits to raise a district from `lv` to `lv + 1`.
static func district_level_credits(lv: int) -> float:
	return Balance.geometric(Balance.cfg.level_credit_base, Balance.cfg.level_credit_growth, lv - 1)

## Why `poi` can't go up a level right now ("" when it can).
static func district_level_block(pd: PlanetData, pp: PlanetProgress, poi: POIData) -> String:
	var lv: int = pp.district_levels.get(poi.label, 1)
	if pp.is_district_upgrading(poi.label):
		return "Already upgrading"
	if lv >= Balance.cfg.max_district_level:
		return "Max level"
	if poi.is_orbital():
		return "Stations don't level — level the Orbit for more stations"
	if poi.is_city():
		return ""   # the Capital District leads
	for nb: String in poi.neighbors:
		if int(pp.district_levels.get(nb, 1)) >= lv + 1:
			return ""
	return "Needs a road-linked neighbour at Lv %d first" % (lv + 1)

# ── Cities ───────────────────────────────────────────────────────────────────

static func city_level(pp: PlanetProgress, city: POIData) -> int:
	return int(pp.city_levels.get(city.label, 1))

## Districts (Capital District not counted) a City of level `lv` may hold.
static func city_max_districts(lv: int) -> int:
	return 3 + 2 * (lv - 1)

static func city_district_count(pd: PlanetData, city: POIData) -> int:
	var n := 0
	for p: POIData in pd.custom_pois:
		if p.parent_city == city.label and not p.is_orbital():
			n += 1
	return n

## Sum of district levels in a City, Capital District included.
static func city_district_levels(pd: PlanetData, pp: PlanetProgress, city: POIData) -> int:
	var total: int = pp.district_levels.get(city.label, 1)
	for p: POIData in pd.custom_pois:
		if p.parent_city == city.label and not p.is_orbital():
			total += int(pp.district_levels.get(p.label, 1))
	return total

## Total district levels a City needs to reach level `next`: round(a·n² + b·n + c)
## — 3, 9, 18, 30 … in "current".
static func city_level_req(next: int) -> int:
	var c: BalanceConfig = Balance.cfg
	var n := float(next)
	return int(round(c.city_level_req_a * n * n + c.city_level_req_b * n + c.city_level_req_c))

static func city_level_credits(next: int) -> float:
	return Balance.geometric(Balance.cfg.city_level_credit_base, Balance.cfg.city_level_credit_growth, next - 2)

## Population for City level `next`: base × (next−1 if linear) × growth^(next−2).
static func city_level_pop(next: int) -> int:
	var c: BalanceConfig = Balance.cfg
	var lin := float(next - 1) if c.city_level_pop_linear else 1.0
	return int(round(c.city_level_pop_base * lin * pow(c.city_level_pop_growth, float(next - 2))))

## Population a City's levels occupy (all levels gained so far).
static func city_pop_cost(lv: int) -> int:
	var c := 0
	for n in range(2, lv + 1):
		c += city_level_pop(n)
	return c

static func city_level_block(pd: PlanetData, pp: PlanetProgress, city: POIData) -> String:
	if pp.city_upgrading.has(city.label):
		return "Already levelling up"
	var next := city_level(pp, city) + 1
	var have := city_district_levels(pd, pp, city)
	var need := city_level_req(next)
	if have < need:
		return "Needs %d total district levels in this City (has %d)" % [need, have]
	return ""

# ── Orbit ────────────────────────────────────────────────────────────────────
## The Orbit takes no City slot (it is the world's Central Orbit). Lv n holds n Space Stations, each with a
## single module; it levels once every station is up with its module built.
static func max_orbit_level() -> int:
	return Balance.cfg.max_orbit_level

## The world's Central Orbit: its first station — the hub of the trade network
## (Spaceports below link to it, other stations orbit as satellites, hubs of
## other worlds link to each other). null without an Orbit.
static func orbit_hub(pd: PlanetData) -> POIData:
	if pd == null:
		return null
	for p: POIData in pd.custom_pois:
		if p.is_orbital():
			return p
	return null

static func orbit_stations(pd: PlanetData) -> Array[POIData]:
	var out: Array[POIData] = []
	for p: POIData in pd.custom_pois:
		if p.is_orbital():
			out.append(p)
	return out

static func orbit_level_credits(next: int) -> float:
	return city_level_credits(next) * Balance.cfg.orbit_level_credit_mult

static func orbit_level_block(pd: PlanetData, pp: PlanetProgress) -> String:
	if pp.orbit_level >= max_orbit_level():
		return "Max level"
	var stations := orbit_stations(pd)
	if stations.size() < pp.orbit_level:
		return "Launch all %d station%s first" % [pp.orbit_level, "" if pp.orbit_level == 1 else "s"]
	for st: POIData in stations:
		if st.constructing or pp.buildings_in_district(st.label).filter(
				func(b: Dictionary) -> bool: return not b.get("constructing", false)).is_empty():
			return "Every station needs its module built"
	return ""

## Cities plus the Orbit — what counts against max_cities.
static func cities_used(pd: PlanetData, pp: PlanetProgress) -> int:
	var n := 0
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital():
			n += 1
	return n   # the Orbit (the world's Central Orbit) takes no City slot

# ── Planet ───────────────────────────────────────────────────────────────────

## Cities a planet may hold: two at Lv 1, one more per level.
static func max_cities(pp: PlanetProgress) -> int:
	return pp.level + 1

static func planet_city_levels(pd: PlanetData, pp: PlanetProgress) -> int:
	var total := pp.orbit_level   # the Orbit counts as a City
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital():
			total += city_level(pp, p)
	return total

## Total city levels a planet needs to reach level `next`: a·n + b — 3, 5, 7 … in "current".
static func planet_level_req(next: int) -> int:
	return Balance.cfg.planet_level_req_a * next + Balance.cfg.planet_level_req_b

static func planet_level_block(pd: PlanetData, pp: PlanetProgress) -> String:
	var need := planet_level_req(pp.level + 1)
	var have := planet_city_levels(pd, pp)
	if have < need:
		return "Needs %d total city levels on this planet (has %d)" % [need, have]
	return ""
