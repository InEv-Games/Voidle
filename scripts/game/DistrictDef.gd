## Defines a district type: what it's called, where it can be placed,
## what buildings it can contain, and its default placement preference.
class_name DistrictDef
extends Resource

enum Type { CITY, GENERATOR, MINING, SPACE_STATION, RESIDENTIAL }

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

## Compute actual placement cost. Cost doubles for each district of the same type
## already built under the same City (`parent_city`), so a new City starts with
## fresh prices. Cities themselves double per City on the planet.
static func placement_cost(def: DistrictDef, data: PlanetData, parent_city: String = "") -> float:
	var same_count: int = 0
	for poi: POIData in data.custom_pois:
		if poi.poi_type != def.to_poi_type():
			continue
		if def.is_system_anchor() or poi.parent_city == parent_city:
			same_count += 1
	return def.base_cost * pow(2.0, float(same_count))

## Suggests a name. Cities (and stations) draw from name_pool; a district
## built under a City is named after it: "<City> <suffix>", cycling through
## name_suffixes. Always unique on the planet (" II", " III" … when taken).
func suggest_name(data: PlanetData, parent_city: String = "") -> String:
	var base := display_name
	if parent_city != "" and not name_suffixes.is_empty():
		var n := 0
		for poi: POIData in data.custom_pois:
			if poi.parent_city == parent_city and poi.poi_type == to_poi_type():
				n += 1
		base = "%s %s" % [parent_city, name_suffixes[n % name_suffixes.size()]]
	elif not name_pool.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = data.seed ^ (data.custom_pois.size() * 0xA7F3 + id * 0x1234)
		base = name_pool[rng.randi() % name_pool.size()]
	return unique_label(data, base)

## `base`, or `base` + " II" / " III" … so no two districts share a label —
## labels key buildings, levels and City membership.
static func unique_label(data: PlanetData, base: String, ignore: POIData = null) -> String:
	var taken := {}
	for poi: POIData in data.custom_pois:
		if poi != ignore:
			taken[poi.label] = true
	if not taken.has(base):
		return base
	const NUMERALS := ["II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
	for numeral: String in NUMERALS:
		var candidate := "%s %s" % [base, numeral]
		if not taken.has(candidate):
			return candidate
	var k := 11
	while taken.has("%s %d" % [base, k]):
		k += 1
	return "%s %d" % [base, k]

## Convert DistrictDef.Type → POIData.POIType for placement.
func to_poi_type() -> POIData.POIType:
	match id:
		Type.CITY:          return POIData.POIType.CITY
		Type.GENERATOR:     return POIData.POIType.ENERGY
		Type.MINING:        return POIData.POIType.MINING
		Type.SPACE_STATION: return POIData.POIType.STATION
		Type.RESIDENTIAL:   return POIData.POIType.RESIDENTIAL
		_:                  return POIData.POIType.CITY

## Returns how many of this district type exist on the planet.
static func count_on_planet(def: DistrictDef, data: PlanetData) -> int:
	var n := 0
	for poi: POIData in data.custom_pois:
		if poi.poi_type == def.to_poi_type():
			n += 1
	return n
