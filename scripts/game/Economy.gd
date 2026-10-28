class_name Economy
extends RefCounted

## The game's economy in one place: resource definitions, the named raw
## resources found on each kind of body, conversion yields, population rules
## and planet-wide bonuses. Numbers here are first-pass balance values.
##
## Resource ids:
##   core       credits, energy (a flow: surplus or deficit, not stored), science,
##              population (per planet capacity)
##   processed  goods, fuel, rare_elements — made in Industrial districts from raw resources
##   raw        named resources (ferrite, moonstone, …) mined on specific body types

# ── Resource ids ──────────────────────────────────────────────────────────────
const CREDITS    := "credits"
const ENERGY     := "energy"
const SCIENCE    := "science"
const POPULATION := "population"
const GOODS      := "goods"
const FUEL       := "fuel"
const RARE       := "rare_elements"
## Building input/output key meaning "raw resources": a mine's output is split
## across the planet's raw resources; a converter's input takes the best raw in stock.
const RAW        := "raw"

const PROCESSED := [GOODS, FUEL, RARE]

## Display info for non-raw resources.
const INFO := {
	CREDITS:    {"name": "Credits",        "short": "cr",   "color": Color(1.0, 0.72, 0.20)},   # orange-gold: apart from Energy's yellow
	ENERGY:     {"name": "Energy",         "short": "⚡",   "color": Color(0.95, 0.88, 0.25)},
	SCIENCE:    {"name": "Science",        "short": "sci",  "color": Color(0.35, 0.65, 1.00)},
	POPULATION: {"name": "Population",     "short": "pop",  "color": Color(0.60, 0.95, 0.60)},
	GOODS:      {"name": "Consumer Goods", "short": "goods","color": Color(0.95, 0.60, 0.35)},
	FUEL:       {"name": "Fuel Rods",      "short": "fuel", "color": Color(0.55, 0.95, 0.85)},
	RARE:       {"name": "Rare Elements",  "short": "rare", "color": Color(0.80, 0.55, 1.00)},
}

## One colour per output family, taken from its resource's symbol, so a
## district, its buildings, its lens and its icon in the top bar all match.
## Production has no single resource: it uses the mining orange.
const PRODUCTION_COLOR := Color(1.0, 0.58, 0.28)

static func family_color(family: String) -> Color:
	match family:
		"energy":      return INFO[ENERGY]["color"]
		"residential": return INFO[POPULATION]["color"]
		"commercial":  return INFO[CREDITS]["color"]
		"science":     return INFO[SCIENCE]["color"]
		"production":  return PRODUCTION_COLOR
	return Color.WHITE

# ── Raw resources ────────────────────────────────────────────────────────────
## Named raw resources. `bodies` = planet types that carry it (empty = any),
## Which civilization opens a mineral follows its rarity: R1–2 Tip 0 (Ferrite,
## Moonstone), R3–4 Tip 1, R5–6 Tip 2 … R11–12 Tip 5 (see mineral_civ).
## Higher rarity converts into more processed goods (see yield_mult).
const RAW_TABLE := [
	{"id": "ferrite",     "name": "Ferrite",     "rarity": 1,  "color": Color(0.66, 0.58, 0.52), "bodies": [0, 1, 4]},
	{"id": "moonstone",   "name": "Moonstone",   "rarity": 2,  "color": Color(0.80, 0.84, 0.95), "bodies": [6]},
	{"id": "cinderite",   "name": "Cinderite",   "rarity": 3,  "color": Color(0.98, 0.45, 0.20), "bodies": [3]},
	{"id": "cryolite",    "name": "Cryolite",    "rarity": 4,  "color": Color(0.55, 0.88, 1.00), "bodies": [2]},
	{"id": "dune_quartz", "name": "Dune Quartz", "rarity": 5,  "color": Color(0.98, 0.82, 0.45), "bodies": [1]},
	{"id": "helion",      "name": "Helion",      "rarity": 6,  "color": Color(0.85, 0.70, 1.00), "bodies": [5]},
	{"id": "astralite",   "name": "Astralite",   "rarity": 7,  "color": Color(0.60, 0.98, 0.80), "bodies": [7]},
	{"id": "aurorium",    "name": "Aurorium",    "rarity": 8,  "color": Color(0.40, 1.00, 0.60), "bodies": [0, 2]},
	{"id": "xenite",      "name": "Xenite",      "rarity": 9,  "color": Color(0.30, 0.90, 1.00), "bodies": [5, 6]},
	{"id": "nyxium",      "name": "Nyxium",      "rarity": 10, "color": Color(0.60, 0.40, 0.95), "bodies": [3, 4]},
	{"id": "quantium",    "name": "Quantium",    "rarity": 11, "color": Color(1.00, 0.88, 0.30), "bodies": [7]},
	{"id": "singularite", "name": "Singularite", "rarity": 12, "color": Color(0.95, 0.30, 0.60), "bodies": []},
]

static func raw_info(id: String) -> Dictionary:
	for r: Dictionary in RAW_TABLE:
		if r["id"] == id:
			return r
	return {}

static func is_raw(id: String) -> bool:
	return not raw_info(id).is_empty()

## Civilization type that can extract a mineral: two rarities per type.
static func mineral_civ(r: Dictionary) -> int:
	return int(floor((float(r["rarity"]) - 1.0) / 2.0))

## Raw resources a body yields to the current civilization (its mineral set by
## body type, gated by GameState.playable_content_type), lowest rarity first.
## Every one is extracted from anywhere on the body — no deposits or densities.
static func raw_for_body(pd: PlanetData) -> Array:
	var out: Array = []
	for r: Dictionary in RAW_TABLE:
		var bodies: Array = r["bodies"]
		if not bodies.is_empty() and not (int(pd.planet_type) in bodies):
			continue
		if mineral_civ(r) > GameState.playable_content_type:
			continue
		out.append(r)
	return out

## The body's minerals the player has discovered there (empty until a Production
## building or district has been completed on it — see GameState.discover_body_minerals).
static func discovered_raw_for_body(pd: PlanetData) -> Array:
	if pd == null or not GameState.is_body_surveyed(pd.seed):
		return []
	return raw_for_body(pd)

## True once the mineral has been discovered anywhere (its name, icon and price may show).
static func is_mineral_discovered(id: String) -> bool:
	return GameState.discovered_minerals.has(id)

## Processed output per unit for a raw input of this rarity: R1 = 1×, R2 = 1.75×,
## R3 = 2.5× … so better raw resources stretch further.
static func yield_mult(rarity: int) -> float:
	return 1.0 + 0.75 * float(maxi(rarity, 1) - 1)

static func display_name(id: String) -> String:
	if INFO.has(id):
		return INFO[id]["name"]
	var r := raw_info(id)
	return r.get("name", id.capitalize())

static func color_of(id: String) -> Color:
	if INFO.has(id):
		return INFO[id]["color"]
	var r := raw_info(id)
	return r.get("color", Color.WHITE)

# ── Number formatting ─────────────────────────────────────────────────────────
## Compact amount: 950, 12.5K, 3.40M, 1.20B.
static func fmt(v: float) -> String:
	var a := absf(v)
	if a >= 1_000_000_000.0: return "%.2fB" % (v / 1_000_000_000.0)
	if a >= 1_000_000.0:     return "%.2fM" % (v / 1_000_000.0)
	if a >= 10_000.0:        return "%.0fK" % (v / 1_000.0)
	if a >= 1_000.0:         return "%.1fK" % (v / 1_000.0)
	if a >= 10.0 or is_equal_approx(v, round(v)): return "%.0f" % v
	return "%.1f" % v

# ── Storage limits ────────────────────────────────────────────────────────────
## Every stored resource except Credits and Science has a cap (energy is a
## flow and isn't stored). Base caps here;
## buildings raise them with BuildingDef.storage = { resource_id: +amount }
## ("raw" there raises every raw resource's cap). Population's cap is the
## per-planet housing (max_population). Base caps come from the balance profile.
static func base_cap(key: String) -> float:
	var c: BalanceConfig = Balance.cfg
	match key:
		GOODS: return c.base_cap_goods
		FUEL:  return c.base_cap_fuel
		RARE:  return c.base_cap_rare
		RAW:   return c.base_cap_raw   # per raw resource kind
	return 0.0

static var _cap_cache: Dictionary = {}
static var _cap_frame: int = -1

static func is_capped(id: String) -> bool:
	return id != CREDITS and id != SCIENCE and id != POPULATION and id != ENERGY and id != ""

## Storage limit of a resource (INF when uncapped).
static func cap(id: String) -> float:
	if not is_capped(id):
		return INF
	var frame := Engine.get_process_frames()
	if frame != _cap_frame:
		_cap_frame = frame
		_cap_cache.clear()
	if _cap_cache.has(id):
		return _cap_cache[id]
	var key := RAW if is_raw(id) else id
	var total: float = base_cap(key)
	for pp: PlanetProgress in GameState._planet_progress.values():
		if not pp.is_colonized:
			continue
		for b: Dictionary in pp.buildings:
			if b.get("constructing", false):
				continue
			var def := BuildingDef.find(b.get("building_id", ""))
			if def != null and def.storage.has(key):
				total += float(def.storage[key]) * float(b.get("amount", 1))
	_cap_cache[id] = total
	return total

## Drops cached caps (call after buildings change mid-frame).
static func invalidate_caps() -> void:
	_cap_frame = -1

static func is_full(id: String) -> bool:
	return is_capped(id) and amount(id) >= cap(id) - 0.001

# ── Stock (stored resources) ──────────────────────────────────────────────────
## Credits and science keep their GameState properties (signals, HUD); every
## other stored resource lives in GameState.global_resources.

static func amount(id: String) -> float:
	match id:
		CREDITS: return GameState.credits
		SCIENCE: return GameState.science_points
	return float(GameState.global_resources.get(id, 0.0))

static func add(id: String, value: float) -> void:
	if value == 0.0:
		return
	match id:
		CREDITS: GameState.earn_credits(value)
		SCIENCE: GameState.add_science(value)
		_:       GameState.add_resource(id, value)

## Amount of raw resources in stock, summed over all kinds.
static func raw_total() -> float:
	var t := 0.0
	for r: Dictionary in RAW_TABLE:
		t += amount(r["id"])
	return t

# ── Site ─────────────────────────────────────────────────────────────────────
## The site multiplier the economy uses: terrain × location, snapped to half
## steps — 1x, 1.5x, 2x … (playtest 23.10, KARARLAR §10): players read one
## simple number, and the tooltip shows exactly what is paid out.
static func site_mult(terrain: float, location: float) -> float:
	return maxf(1.0, roundf(terrain * location * 2.0) / 2.0)

## "1x", "1.5x", "2x" …
static func mult_text(m: float) -> String:
	return ("%dx" % int(m)) if is_equal_approx(m, roundf(m)) else ("%.1fx" % m)

# ── Costs ────────────────────────────────────────────────────────────────────
## Buildings already in a district make the next one there dearer
## (Balance.cfg.building_cost_growth each). The profile picks what counts: every
## building in the district, or only the same model. Districts don't affect each other.
static func building_cost(pp: PlanetProgress, def: BuildingDef, district_label: String) -> float:
	var c: BalanceConfig = Balance.cfg
	var same_model_only := c.building_counter_scope == "model"
	var owned := 0
	if pp != null:
		for b: Dictionary in pp.buildings_in_district(district_label):
			if same_model_only and String(b.get("building_id", "")) != def.building_id:
				continue
			owned += int(b.get("amount", 1))
	return roundf(Balance.geometric(def.base_cost, c.building_cost_growth, owned))

## Named materials the first building of this model costs on top of credits
## (repeats grow like credits, see building_full_cost). Its own list, else its tier's.
static func building_materials(def: BuildingDef) -> Dictionary:
	if not def.build_materials.is_empty():
		return def.build_materials
	var c: BalanceConfig = Balance.cfg
	match def.tier:
		2: return c.build_materials_tier2
		3: return c.build_materials_tier3
		4: return c.build_materials_tier4
	return {}

## Full price of `count` more of a model in a district: { "credits": Σ each
## unit's repeat price, material: Σ each unit's repeat amount, … }. Materials grow
## by the same repeat factor as credits (rounded up to whole units).
static func building_full_cost(pp: PlanetProgress, def: BuildingDef, district_label: String, count: int = 1) -> Dictionary:
	var c: BalanceConfig = Balance.cfg
	var owned := 0
	if pp != null:
		for b: Dictionary in pp.buildings_in_district(district_label):
			if c.building_counter_scope == "model" and String(b.get("building_id", "")) != def.building_id:
				continue
			owned += int(b.get("amount", 1))
	var credits := 0.0
	for i in count:
		credits += roundf(Balance.geometric(def.base_cost, c.building_cost_growth, owned + i))
	var out := {CREDITS: credits}
	var mats := building_materials(def)
	for id: String in mats:
		var total := 0.0
		for i in count:
			total += ceilf(Balance.geometric(float(mats[id]), c.building_cost_growth, owned + i) - 0.0001)
		out[id] = total
	return out

## Stock of a resource for paying costs (credits and Science included).
static func payable_amount(id: String) -> float:
	match id:
		CREDITS: return GameState.credits
		SCIENCE: return GameState.science_points
	return amount(id)

## Why `cost` can't be paid ("" when it can), e.g. "Need 30 Ferrite".
static func cost_block(cost: Dictionary) -> String:
	var missing: Array[String] = []
	for id: String in cost:
		var need: float = float(cost[id])
		if need > 0.0 and payable_amount(id) + 0.0001 < need:
			missing.append("%s %s" % [fmt(need - payable_amount(id)), display_name(id)])
	return "" if missing.is_empty() else "Need " + ", ".join(missing)

static func can_pay(cost: Dictionary) -> bool:
	return cost_block(cost) == ""

## Takes the whole cost, or nothing if any part is short.
static func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	for id: String in cost:
		var v: float = float(cost[id])
		if v <= 0.0:
			continue
		match id:
			CREDITS: GameState.spend_credits(v)
			SCIENCE: GameState.spend_science(v)
			_:       GameState.consume_resource(id, v)
	return true

## Short cost text: "450 cr · 30 Ferrite · 5 goods".
static func cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	if cost.has(CREDITS):
		parts.append("%s cr" % fmt(float(cost[CREDITS])))
	for id: String in cost:
		if id != CREDITS:
			parts.append("%s %s" % [fmt(float(cost[id])), INFO.get(id, {}).get("short", display_name(id))])
	return " · ".join(parts)

## How many of a model can be bought in a district now (slots, per-district
## limit and every part of the cost), up to `cap`.
static func max_buildable(pp: PlanetProgress, def: BuildingDef, poi: POIData, cap: int) -> int:
	var free_slots: int = pp.district_slots(poi) - pp.slots_used_in_district(poi.label)
	var n := mini(cap, int(floor(float(free_slots) / float(maxi(def.slot_cost, 1)))))
	if def.max_per_district > 0:
		var have := 0
		for b: Dictionary in pp.buildings_in_district(poi.label):
			if String(b.get("building_id", "")) == def.building_id:
				have += int(b.get("amount", 1))
		n = mini(n, def.max_per_district - have)
	if def.planet_cap() > 0:
		n = mini(n, def.planet_cap() - def.count_on_planet(pp))
	while n > 0 and not can_pay(building_full_cost(pp, def, poi.label, n)):
		n -= 1
	return maxi(n, 0)

# ── Population ────────────────────────────────────────────────────────────────
## Numbers come from the balance profile (Balance.cfg): every City houses
## city_base_pop before any Population buildings; founding and levelling
## districts cost population (see below); max_district_level caps districts.

## Population the k-th district of a City (0-based, Residential ones not
## counted) takes to found: base × (1 + step·k) — 3K, 4.5K, 6K … in "current".
static func district_found_pop(k: int) -> int:
	var c: BalanceConfig = Balance.cfg
	return int(round(c.district_found_pop_base * (1.0 + c.district_found_pop_step * float(k))))

## Founding order of a district among its City's non-Residential districts.
static func district_index(pd: PlanetData, poi: POIData) -> int:
	var k := 0
	for p: POIData in pd.custom_pois:
		if p == poi:
			return k
		if p.parent_city == poi.parent_city and not p.is_orbital() \
				and p.poi_type != POIData.POIType.RESIDENTIAL:
			k += 1
	return k

## Population a district occupies at `level` (founding + every level it has
## gained). Residential districts are housing: they never cost population.
static func district_pop_cost(poi: POIData, level: int, pd: PlanetData = null) -> int:
	if poi.poi_type == POIData.POIType.RESIDENTIAL:
		return 0
	var cost := 0
	if not poi.is_city():
		cost = district_found_pop(district_index(pd, poi)) if pd != null else district_found_pop(0)
	for l in range(1, level):
		cost += level_up_pop(l)
	return cost

## Population a specific district's next level costs (0 for Residential).
static func level_up_pop_for(poi: POIData, level: int) -> int:
	return 0 if poi.poi_type == POIData.POIType.RESIDENTIAL else level_up_pop(level)

## Work speed of a planet: 1 while population fits its housing; past that,
## production slows (like an energy deficit) down to 1 − Balance.cfg.pop_max_slowdown.
## Population may go negative — nothing is ever locked by it.
static func pop_speed(pd: PlanetData, pp: PlanetProgress) -> float:
	var used := used_population(pd, pp)
	if used <= 0:
		return 1.0
	var mx := max_population(pd, pp)
	if used <= mx:
		return 1.0
	return 1.0 - Balance.cfg.pop_max_slowdown * (1.0 - clampf(float(mx) / float(used), 0.0, 1.0))

## Population needed to found a district of this kind. Cities, orbital stations
## and Residential districts need none — housing must always be buildable, or a
## full planet could never grow again.
static func founding_pop(def: DistrictDef, pd: PlanetData = null, parent_city: String = "") -> int:
	if def == null or def.is_orbital or def.id == DistrictDef.Type.CITY \
			or def.id == DistrictDef.Type.RESIDENTIAL:
		return 0
	if pd == null:
		return district_found_pop(0)
	var k := 0
	for p: POIData in pd.custom_pois:
		if p.parent_city == parent_city and not p.is_orbital() and p.poi_type != POIData.POIType.RESIDENTIAL:
			k += 1
	return district_found_pop(k)

## Population needed to raise a district from `level` to `level + 1`:
## base × growth^(level−1) — 2K, 4K, 8K … in "current".
static func level_up_pop(level: int) -> int:
	var c: BalanceConfig = Balance.cfg
	return int(round(Balance.geometric(c.level_pop_base, c.level_pop_growth, maxi(level - 1, 0))))

## Population is one pool for the whole civilization (playtest 28.10: the Moon
## doesn't keep its own). These three answer for every colonised world
## together; `pd` / `pp` only say the caller has a world. Per world:
## world_max_population / world_used_population.
static var _pop_frame := -1
static var _pop_totals := Vector2i.ZERO   # (max, used)

static func _empire_pop() -> Vector2i:
	var f := Engine.get_process_frames()
	if f == _pop_frame:
		return _pop_totals
	var mx := 0
	var used := 0
	for pp: PlanetProgress in GameState._planet_progress.values():
		if not pp.is_colonized:
			continue
		var pd := GameState.get_planet_data(pp.planet_seed)
		mx += world_max_population(pd, pp)
		used += world_used_population(pd, pp)
	_pop_frame = f
	_pop_totals = Vector2i(mx, used)
	return _pop_totals

static func max_population(pd: PlanetData, pp: PlanetProgress) -> int:
	return _empire_pop().x if pd != null and pp != null else 0

static func used_population(pd: PlanetData, pp: PlanetProgress) -> int:
	return _empire_pop().y if pd != null and pp != null else 0

## Max population of one world: City housing + running Population buildings.
static func world_max_population(pd: PlanetData, pp: PlanetProgress) -> int:
	if pd == null or pp == null:
		return 0
	var total := 0.0
	for poi: POIData in pd.custom_pois:
		if poi.is_orbital():
			continue
		if poi.is_city() and not poi.constructing:   # a City houses nobody until it stands
			total += Balance.cfg.city_base_pop * scope_bonus(pp, poi.label, POPULATION, pd)
		total += ProductionManager.district_base(pp, poi, POPULATION)   # bonus included
	for b: Dictionary in pp.buildings:
		if b.get("constructing", false):
			continue
		var def := BuildingDef.find(b.get("building_id", ""))
		if def == null or not def.outputs.has(POPULATION):
			continue
		var key := "%d:%s:%s" % [pp.planet_seed, b.get("district_id", ""), b.get("uid", "-1")]
		if ProductionManager.is_paused(key):
			continue   # starved of its upkeep (e.g. Goods) — houses nobody
		total += float(def.outputs[POPULATION]) * float(b.get("amount", 1)) \
			* scope_bonus(pp, b.get("district_id", ""), POPULATION, pd) * _housing_mult()
	return int(round(total))

## Population used on a planet: every district's founding + level costs
## (levels in progress count already) + the workers of every building
## (BuildingDef.pop_use; ones under construction count already).
static func world_used_population(pd: PlanetData, pp: PlanetProgress) -> int:
	if pd == null or pp == null:
		return 0
	var used := 0
	var nth := {}   # city label -> non-Residential districts counted so far (founding order)
	for poi: POIData in pd.custom_pois:
		if poi.is_orbital():
			continue
		var lv: int = pp.district_levels.get(poi.label, 1)
		if pp.district_upgrading.has(poi.label):
			lv += 1
		if poi.poi_type == POIData.POIType.RESIDENTIAL:
			pass   # housing never costs population
		elif poi.is_city():
			used += district_pop_cost(poi, lv, null)
		else:
			var k: int = nth.get(poi.parent_city, 0)
			nth[poi.parent_city] = k + 1
			used += district_found_pop(k)
			for l in range(1, lv):
				used += level_up_pop(l)
		if poi.is_city():
			used += Leveling.city_pop_cost(int(pp.city_levels.get(poi.label, 1)))
	for b: Dictionary in pp.buildings:
		var def := BuildingDef.find(b.get("building_id", ""))
		if def != null:
			used += def.pop_use() * int(b.get("amount", 1))
	return used

## Population allocated to one district: its founding + levels + building workers.
static func district_pop_used(pp: PlanetProgress, poi: POIData) -> int:
	var lv: int = pp.district_levels.get(poi.label, 1)
	var used := district_pop_cost(poi, lv, GameState.get_planet_data(pp.planet_seed))
	for b: Dictionary in pp.buildings_in_district(poi.label):
		var def := BuildingDef.find(b.get("building_id", ""))
		if def != null:
			used += def.pop_use() * int(b.get("amount", 1))
	return used

## Housing one district provides: its base + its housing buildings (City base included).
static func district_housing(pd: PlanetData, pp: PlanetProgress, poi: POIData) -> int:
	var total := ProductionManager.district_base(pp, poi, POPULATION)
	if poi.is_city() and not poi.constructing:
		total += Balance.cfg.city_base_pop * scope_bonus(pp, poi.label, POPULATION, pd)
	for b: Dictionary in pp.buildings_in_district(poi.label):
		if b.get("constructing", false):
			continue
		var def := BuildingDef.find(b.get("building_id", ""))
		if def != null and def.outputs.has(POPULATION):
			total += float(def.outputs[POPULATION]) * float(b.get("amount", 1)) \
				* scope_bonus(pp, poi.label, POPULATION, pd) * _housing_mult()
	return int(round(total))

## Research bonus to housing built by buildings.
static func _housing_mult() -> float:
	var st = Engine.get_main_loop().root.get_node_or_null("SkillTree")
	return st.get_housing_mult() if st != null else 1.0

static func free_population(pd: PlanetData, pp: PlanetProgress) -> int:
	return max_population(pd, pp) - used_population(pd, pp)

# ── City & planet-wide bonuses ──────────────────────────────────────────────
## Capital/City buildings boost a resource: BuildingDef.planet_bonus =
## { resource_id: +fraction per building }. Most boost only their own City (the
## City and every district built under it); rare BuildingDef.planet_wide ones
## (and orbital stations) boost the whole planet.

## The City a district belongs to (its own id for a City), or "".
## Per-frame caches (bonus lookups run for every district, every frame).
static var _cache_frame: int = -1
static var _city_maps: Dictionary = {}     # planet seed -> { district label -> city label }
static var _bonus_cache: Dictionary = {}   # "seed|city|id" -> multiplier

static func _frame_caches() -> void:
	var f := Engine.get_process_frames()
	if f != _cache_frame:
		_cache_frame = f
		_city_maps.clear()
		_bonus_cache.clear()

static func city_key(pd: PlanetData, district_label: String) -> String:
	if pd == null:
		return ""
	_frame_caches()
	var m: Dictionary = _city_maps.get(pd.seed, {})
	if m.is_empty():
		for p: POIData in pd.custom_pois:
			m[p.label] = p.label if p.is_city() or p.parent_city == "" else p.parent_city
		_city_maps[pd.seed] = m
	return m.get(district_label, "")

## Multiplier for `id` produced in `district_label`: 1 + its City's bonuses +
## planet-wide bonuses.
static func scope_bonus(pp: PlanetProgress, district_label: String, id: String, pd: PlanetData = null) -> float:
	if pd == null:
		pd = GameState.get_planet_data(pp.planet_seed)
	var city := city_key(pd, district_label)
	var ck := "%d|%s|%s" % [pp.planet_seed, city, id]
	if _bonus_cache.has(ck):
		return _bonus_cache[ck]
	var mult := 1.0
	for b: Dictionary in pp.buildings:
		if b.get("constructing", false):
			continue
		var def := BuildingDef.find(b.get("building_id", ""))
		if def == null or not def.planet_bonus.has(id):
			continue
		var bd: String = b.get("district_id", "")
		if def.planet_wide or (city != "" and city_key(pd, bd) == city):
			mult += float(def.planet_bonus[id]) * float(b.get("amount", 1))
	_bonus_cache[ck] = mult
	return mult

## Planet-wide bonuses only (kept for callers without a district).
static func planet_bonus(pp: PlanetProgress, id: String) -> float:
	var mult := 1.0
	for b: Dictionary in pp.buildings:
		if b.get("constructing", false):
			continue
		var def := BuildingDef.find(b.get("building_id", ""))
		if def != null and def.planet_wide and def.planet_bonus.has(id):
			mult += float(def.planet_bonus[id]) * float(b.get("amount", 1))
	return mult
