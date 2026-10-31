## Defines a district type: what it's called, where it can be placed,
## what buildings it can contain, and its default placement preference.
class_name DistrictDef
extends Resource

## Display names: CITY = Capital District, GENERATOR = Energy, MINING =
## Production, SPACE_STATION = Orbit City (the Orbit's centre, not a district).
## (Enum names stay so saved district types and type_tags keep working; new
## types are appended.) The ORBITAL_* types are the Orbit's five support
## districts; INTERSTELLAR_PORT is future (Civilization 1) content.
enum Type { CITY, GENERATOR, MINING, SPACE_STATION, RESIDENTIAL, COMMERCIAL, SCIENCE,
	ORBITAL_RESIDENTIAL, ORBITAL_COMMERCIAL, ORBITAL_SCIENCE, ORBITAL_ENERGY, ORBITAL_PRODUCTION,
	INTERSTELLAR_PORT }

@export var id:           Type
@export var display_name: String
@export var description:  String
@export var icon:         String
@export var placement:    LocationFinder.Placement
@export var base_cost:    float
@export var construction_duration: float = 15.0
## If true, this district orbits the planet instead of sitting on the surface.
@export var is_orbital:   bool = false
## Max number of this district type per planet. 0 = unlimited.
@export var max_per_planet: int = 0
## Empty = available on all planet types.
@export var allowed_planet_types: Array[PlanetData.Type] = []
## Which BuildingDef building_ids are available inside this district type.
@export var building_ids: Array[String] = []
## Name pool used for random name suggestions (cities, stations).
@export var name_pool:    Array[String] = []
## Districts under a City are named "<City> <suffix>" from this list.
@export var name_suffixes: Array[String] = []
## Required skill node to unlock this district. Empty = unlocked by default.
@export var unlock_skill: String = ""
## Lowest civilization type that may build it (Interstellar Port: 1).
@export var min_civilization: int = 0

## ── Orbit (integration decisions 29.10 §6) ─────────────────────────────────
## The Orbit's centre (Orbit City): founded with the Orbit, never offered as a
## district, holds no buildings; makes the same base as a Capital.
@export var is_orbit_city: bool = false
## Surface district family whose buildings an Orbit district holds (a
## POIData.POIType; -1 = its own type).
@export var hosts_poi_type: int = -1
## Planet-wide support: { resource_id: +fraction } for the whole planet's
## total, from the district itself — whatever buildings it holds (§6.2).
@export var planet_support: Dictionary = {}
## Storage the district itself adds: { resource_id: +amount } ("raw" = each raw mineral).
@export var storage: Dictionary = {}
## The district's own workers and energy use (⚡/s), apart from its buildings.
@export var own_workers: int = 0
@export var own_energy_use: float = 0.0
## Buildings it comes with: [[building_id, count], …], each paid at its own
## repeat price when the district is placed (§6.3).
@export var prefab: Array = []
## Bonuses this district gets from neighbouring districts, keyed by the
## neighbour's type key ("city", "generator", "mining", "space_station") →
## player-facing description, e.g. {"generator": "+10% credits"}.
## Shown during placement; gameplay effects are not wired up yet.
@export var neighbor_bonuses: Dictionary = {}

## ── Base income ────────────────────────────────────────────────────────────
## What the district makes on its own, before any buildings: per base_tick
## cycle ("energy" is ⚡ per second of flow, "population" is housing).
## Scaled by the site (site_mult) and the district's level (level_mult).
@export var base_outputs: Dictionary = {}
@export var base_tick: float = 30.0
## Site factors that raise the base income: { factor: weight }, giving
## ×(1 + Σ weight × factor). Factors (0..1): "solar", "wind", "geothermal",
## "tidal", "minerals" (richest local deposit), "coastal", and terrain names
## ("lowlands", "highlands", "mountains", …) — see BuildingDef.site_value.
@export var site_bonus: Dictionary = {}

## Base income multiplier from where the district stands.
func site_mult(poi: POIData) -> float:
	var m := 1.0
	for key: String in site_bonus:
		m += float(site_bonus[key]) * BuildingDef.site_value(poi, key)
	return m

## [[label, +fraction], …] of the site factors that apply here, largest first.
func site_breakdown(poi: POIData) -> Array:
	var out: Array = []
	for key: String in site_bonus:
		var v := float(site_bonus[key]) * BuildingDef.site_value(poi, key)
		if v > 0.005:
			out.append([BuildingDef.tag_label(key), v])
	out.sort_custom(func(a, b) -> bool: return a[1] > b[1])
	return out

## ── Neighbour income ───────────────────────────────────────────────────────
## Extra base income per neighbouring district, by the neighbour's type key:
## { "residential": { "credits": 4.0 }, … } — same units as base_outputs.
## A City also counts every district built under it as a neighbour.
@export var neighbor_income: Dictionary = {}

## What one neighbour of type `key` adds: { resource_id: amount } (may be empty).
func income_from(key: String) -> Dictionary:
	return neighbor_income.get(key, {})

## District output by level (Balance.cfg): linear 1 + step·(L−1) — +50% per
## level in "current" — or geometric growth^(L−1).
static func level_mult(level: int) -> float:
	var c: BalanceConfig = Balance.cfg
	var l := float(maxi(level, 1) - 1)
	if c.level_output_mode == "geometric":
		return pow(c.level_output_growth, l)
	return 1.0 + c.level_output_step * l

## Lower-case type key used by neighbor_bonuses and POIData.type_tag.
func type_key() -> String:
	return Type.keys()[id].to_lower()

## Districts every connected system needs one of (they may be placed anywhere).
func is_system_anchor() -> bool:
	return id == Type.CITY

# ── Registry ─────────────────────────────────────────────────────────────────

static var _cache: Array[DistrictDef] = []

static func all() -> Array[DistrictDef]:
	if not _cache.is_empty():
		return _cache
		
	var dir := DirAccess.open("res://resources/districts")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res := ResourceLoader.load("res://resources/districts/" + file_name) as DistrictDef
				if res:
					_cache.append(res)
			file_name = dir.get_next()
	return _cache

static func for_planet(planet_type: PlanetData.Type) -> Array[DistrictDef]:
	var st = Engine.get_main_loop().root.get_node_or_null("SkillTree")
	var result: Array[DistrictDef] = []
	for d: DistrictDef in all():
		if d.unlock_skill != "" and (st == null or not st.is_unlocked(d.unlock_skill)):
			continue
		if d.min_civilization > GameState.playable_content_type:
			continue   # future content stays closed in the demo
		if d.allowed_planet_types.is_empty() or planet_type in d.allowed_planet_types:
			result.append(d)
	return result

static func find_by_key(key: String) -> DistrictDef:
	for d: DistrictDef in all():
		if d.type_key() == key:
			return d
	return null

static func find(district_type: Type) -> DistrictDef:
	for d: DistrictDef in all():
		if d.id == district_type:
			return d
	return null

# ── Factory ───────────────────────────────────────────────────────────────────

## Credits to place a district. The type doesn't matter — the price grows with
## how many districts its City already has (× district_cost_growth each), so a
## City of five Commercial districts costs the same as a mixed one. Cities grow
## in price per City on the planet; a planet's first City is free. (Balance.cfg)

static func placement_cost(def: DistrictDef, data: PlanetData, parent_city: String = "") -> float:
	if def.is_orbital:
		return def.base_cost + float(prefab_cost(def, data).get(Economy.CREDITS, 0.0))
	if def.is_system_anchor():
		var cities := 0
		for poi: POIData in data.custom_pois:
			if poi.is_city() and not poi.is_orbital():
				cities += 1
		return 0.0 if cities == 0 else roundf(Balance.geometric(Balance.cfg.city_base_cost, Balance.cfg.city_cost_growth, cities - 1))
	return roundf(Balance.geometric(Balance.cfg.district_base_cost, Balance.cfg.district_cost_growth,
		districts_in_city(data, parent_city)))

## Named materials a district costs on top of credits (GDD §20.6): a Production
## district on the Moon asks for 30 Ferrite and no Moonstone; an Orbit district,
## its prefab buildings' materials.
static func placement_materials(def: DistrictDef, data: PlanetData) -> Dictionary:
	if def != null and data != null and not def.is_orbital and data.planet_type == PlanetData.Type.MOON \
			and def.id == Type.MINING:
		return {"ferrite": 30.0}
	if def != null and def.is_orbital:
		var mats := prefab_cost(def, data)
		mats.erase(Economy.CREDITS)
		return mats
	return {}

## Prefab tiers (playtest 30.10): the player picks which tier of each starter
## building an Orbit district comes with. A prefab building's ladder, Tier 0
## up; a tier not researched yet falls back to the highest one that is.
const PREFAB_LADDERS := {
	"low_rise_housing":     ["low_rise_housing", "residential", "apartments", "luxury_complex"],
	"commercial":           ["commercial", "local_trade_center", "trading_post", "commodities_exchange"],
	"field_observatory":    ["field_observatory", "lab", "advanced_lab", "particle_accelerator"],
	"solar_panel":          ["solar_panel", "solar_matrix", "fission_reactor", "antimatter_chamber"],
	"surface_quarry":       ["surface_quarry", "mine", "deep_drill", "mantle_cracker"],
	"ore_sorting_workshop": ["ore_sorting_workshop", "refinery", "refinery", "refinery"],
	"warehouse":            ["warehouse", "warehouse", "storage_facility", "storage_facility"],
}
## Chosen prefab tier per Orbit district type (DistrictDef.Type → 0..3), set by
## the build list's stepper; placement and its price read it.
static var prefab_tier: Dictionary = {}

## The building a prefab entry becomes at the chosen tier (researched only).
static func prefab_building(base_id: String, tier: int) -> String:
	var ladder: Array = PREFAB_LADDERS.get(base_id, [base_id])
	var avail := BuildingDef.available_buildings()
	for t in range(clampi(tier, 0, ladder.size() - 1), -1, -1):
		var bid: String = ladder[t]
		for b: BuildingDef in avail:
			if b.building_id == bid:
				return bid
	return base_id

## Highest tier any prefab building of `def` can take now (0 when nothing more is researched).
static func prefab_max_tier(def: DistrictDef) -> int:
	var best := 0
	for row: Array in def.prefab:
		var ladder: Array = PREFAB_LADDERS.get(String(row[0]), [row[0]])
		for t in ladder.size():
			if prefab_building(String(row[0]), t) == String(ladder[t]):
				best = maxi(best, t)
	return best

## Each prefab building of `def` with its price: [[building_id, {credits, mats…}], …].
## Every copy pays the normal repeat price as if built one after another in
## the new (empty) district (Economy.building_cost rules).
static func prefab_items(def: DistrictDef) -> Array:
	var out: Array = []
	if def == null or def.prefab.is_empty():
		return out
	var c: BalanceConfig = Balance.cfg
	var placed: Array[String] = []
	var tier := int(prefab_tier.get(int(def.id), 0))
	for row: Array in def.prefab:
		var bdef := BuildingDef.find(prefab_building(String(row[0]), tier))
		if bdef == null:
			continue
		for i in int(row[1]):
			var owned := placed.size() if c.building_counter_scope != "model" else placed.count(bdef.building_id)
			var cost := {Economy.CREDITS: roundf(Balance.geometric(bdef.base_cost, c.building_cost_growth, owned))}
			var mats := Economy.building_materials(bdef)
			for id: String in mats:
				cost[id] = ceilf(Balance.geometric(float(mats[id]), c.building_cost_growth, owned) - 0.0001)
			out.append([bdef.building_id, cost])
			placed.append(bdef.building_id)
	return out

## Total price of `def`'s prefab buildings: { credits, material: amount }.
static func prefab_cost(def: DistrictDef, _data: PlanetData = null) -> Dictionary:
	var total := {}
	for item: Array in prefab_items(def):
		for id: String in item[1]:
			total[id] = float(total.get(id, 0.0)) + float(item[1][id])
	return total

## Full placement price: { credits, material: amount }.
static func placement_full_cost(def: DistrictDef, data: PlanetData, parent_city: String = "") -> Dictionary:
	var out := {Economy.CREDITS: placement_cost(def, data, parent_city)}
	out.merge(placement_materials(def, data))
	return out

## Districts already built under a City (orbital ones not counted).
static func districts_in_city(data: PlanetData, parent_city: String) -> int:
	var n := 0
	for poi: POIData in data.custom_pois:
		if poi.parent_city == parent_city and parent_city != "" and not poi.is_orbital():
			n += 1
	return n

## Suggests a display name. Cities (and stations) draw from name_pool,
## preferring one not used on the planet yet; a district built under a City
## cycles through name_suffixes ("Residences", "Housing Quarter" …). Names may
## repeat — districts are keyed by POIData.label, not by name.
func suggest_name(data: PlanetData, parent_city: String = "") -> String:
	if parent_city != "" and not name_suffixes.is_empty():
		var n := 0
		for poi: POIData in data.custom_pois:
			if poi.parent_city == parent_city and poi.poi_type == to_poi_type():
				n += 1
		return name_suffixes[n % name_suffixes.size()]
	if name_pool.is_empty():
		return display_name
	var used := {}
	for poi: POIData in data.custom_pois:
		used[poi.shown_name()] = true
	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed ^ (data.custom_pois.size() * 0xA7F3 + id * 0x1234)
	var start := rng.randi() % name_pool.size()
	for i in name_pool.size():
		var cand: String = name_pool[(start + i) % name_pool.size()]
		if not used.has(cand):
			return cand
	return name_pool[start]

## Convert DistrictDef.Type → POIData.POIType for placement.
func to_poi_type() -> POIData.POIType:
	match id:
		Type.CITY:          return POIData.POIType.CITY
		Type.GENERATOR:     return POIData.POIType.ENERGY
		Type.MINING:        return POIData.POIType.MINING
		Type.SPACE_STATION: return POIData.POIType.STATION
		Type.RESIDENTIAL:   return POIData.POIType.RESIDENTIAL
		Type.COMMERCIAL:    return POIData.POIType.COMMERCIAL
		Type.SCIENCE:       return POIData.POIType.SCIENCE
		Type.ORBITAL_RESIDENTIAL, Type.ORBITAL_COMMERCIAL, Type.ORBITAL_SCIENCE, \
				Type.ORBITAL_ENERGY, Type.ORBITAL_PRODUCTION, Type.INTERSTELLAR_PORT:
			return POIData.POIType.STATION
		_:                  return POIData.POIType.CITY

## Returns how many of this district type exist on the planet.
static func count_on_planet(def: DistrictDef, data: PlanetData) -> int:
	var n := 0
	var key := def.type_key()
	for poi: POIData in data.custom_pois:
		if poi.type_tag == key or (poi.type_tag == "" and poi.poi_type == def.to_poi_type()):
			n += 1
	return n
