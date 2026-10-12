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
## First-pass balance numbers — tune here.

# ── Districts ────────────────────────────────────────────────────────────────

## Credits to raise a district from `lv` to `lv + 1`.
static func district_level_credits(lv: int) -> float:
	return 400.0 * pow(2.2, float(lv - 1))

## Why `poi` can't go up a level right now ("" when it can).
static func district_level_block(pd: PlanetData, pp: PlanetProgress, poi: POIData) -> String:
	var lv: int = pp.district_levels.get(poi.label, 1)
	if pp.is_district_upgrading(poi.label):
		return "Already upgrading"
	if lv >= Economy.MAX_DISTRICT_LEVEL:
		return "Max level"
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

## Total district levels a City needs to reach level `next`: 3, 9, 18, 30 …
static func city_level_req(next: int) -> int:
	return int(round(1.5 * float(next) * float(next - 1)))

static func city_level_credits(next: int) -> float:
	return 1500.0 * pow(2.5, float(next - 2))

static func city_level_pop(next: int) -> int:
	return 4000 * (next - 1)

## Population a City's levels occupy (all levels gained so far).
static func city_pop_cost(lv: int) -> int:
	var c := 0
	for n in range(2, lv + 1):
		c += city_level_pop(n)
	return c

static func city_level_block(pd: PlanetData, pp: PlanetProgress, city: POIData) -> String:
	var next := city_level(pp, city) + 1
	var have := city_district_levels(pd, pp, city)
	var need := city_level_req(next)
	if have < need:
		return "Needs %d total district levels in this City (has %d)" % [need, have]
	return ""

# ── Planet ───────────────────────────────────────────────────────────────────

## Cities a planet may hold: two at Lv 1, one more per level.
static func max_cities(pp: PlanetProgress) -> int:
	return pp.level + 1

static func planet_city_levels(pd: PlanetData, pp: PlanetProgress) -> int:
	var total := 0
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital():
			total += city_level(pp, p)
	return total

## Total city levels a planet needs to reach level `next`: 3, 5, 7 …
static func planet_level_req(next: int) -> int:
	return 2 * next - 1

static func planet_level_block(pd: PlanetData, pp: PlanetProgress) -> String:
	var need := planet_level_req(pp.level + 1)
	var have := planet_city_levels(pd, pp)
	if have < need:
		return "Needs %d total city levels on this planet (has %d)" % [need, have]
	return ""
