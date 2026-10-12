## Defines a district type: what it's called, where it can be placed,
## what buildings it can contain, and its default placement preference.
class_name DistrictDef
extends Resource

## Display names: GENERATOR = Energy, MINING = Industrial, RESIDENTIAL = Residential.
## (Enum names stay so saved district types and type_tags keep working.)
enum Type { CITY, GENERATOR, MINING, SPACE_STATION, RESIDENTIAL, COMMERCIAL, SCIENCE }

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

## Base income grows +50% per district level above 1.
static func level_mult(level: int) -> float:
	return 1.0 + 0.5 * float(maxi(level, 1) - 1)

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
## how many districts its City already has (×DISTRICT_COST_GROWTH each), so a
## City of five Commercial districts costs the same as a mixed one. Cities grow
## in price per City on the planet; a planet's first City is free.
const DISTRICT_BASE_COST := 300.0
const DISTRICT_COST_GROWTH := 1.6
const CITY_BASE_COST := 2500.0
const CITY_COST_GROWTH := 2.5

static func placement_cost(def: DistrictDef, data: PlanetData, parent_city: String = "") -> float:
	if def.is_orbital:
		return def.base_cost
	if def.is_system_anchor():
		var cities := 0
		for poi: POIData in data.custom_pois:
			if poi.is_city() and not poi.is_orbital():
				cities += 1
		if cities > 0 and GameState.get_planet(data.seed).orbit_level > 0:
			cities += 1   # the Orbit takes a City slot
		return 0.0 if cities == 0 else roundf(CITY_BASE_COST * pow(CITY_COST_GROWTH, float(cities - 1)))
	return roundf(DISTRICT_BASE_COST * pow(DISTRICT_COST_GROWTH, float(districts_in_city(data, parent_city))))

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
		_:                  return POIData.POIType.CITY

## Returns how many of this district type exist on the planet.
static func count_on_planet(def: DistrictDef, data: PlanetData) -> int:
	var n := 0
	for poi: POIData in data.custom_pois:
		if poi.poi_type == def.to_poi_type():
			n += 1
	return n
