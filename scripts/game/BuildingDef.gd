class_name BuildingDef
extends Resource

## Primary output, used by the UI for colours / labels. Derived from `outputs`
## when that is set (see _derive_legacy_fields). New values are appended so
## saved integers keep their meaning.
enum OutputType { NONE, ENERGY, CREDITS, RAW_MINERAL, REFINED_MINERAL, SCIENCE, POPULATION, GOODS, FUEL, RARE }

@export var building_id:       String   = ""
@export var display_name:      String   = ""
@export var description:       String   = ""
@export var allowed_poi_types: Array[POIData.POIType] = []
@export var allowed_planet_types: Array[PlanetData.Type] = []
@export var base_cost:         float    = 100.0
@export var slot_cost:         int      = 1
@export var min_planet_lv:     int      = 1
## If > 0, restricts how many of this building can be built in a single district.
@export var max_per_district:  int      = 0
## Required skill node to unlock this building. Empty = unlocked by default.
@export var unlock_skill:      String   = ""

## Production
@export var construct_duration: float     = 0.0    # build time; 0 = use tick_duration
@export var tick_duration:     float      = 30.0   # seconds to fill production bar
@export var energy_per_tick:   float      = 0.0    # negative = consume, positive = produce
@export var output_type:       OutputType = OutputType.NONE
@export var output_amount:     float      = 0.0
@export var input_type:        OutputType = OutputType.NONE
@export var input_amount:      float      = 0.0
@export var input_tier:        int        = 1      # Required material tier (T1-T5)

## ── Economy (see Economy.gd) ───────────────────────────────────────────────
## Per production cycle, scaled by the building's count:
##   outputs  { resource_id: amount } — "energy" is a continuous flow (per the
##            energy grid), "population" is housing capacity, "raw" splits
##            over the planet's raw resources (mines).
##   inputs   { resource_id: amount } consumed at the start of each cycle; the
##            building waits (and gives nothing, energy/housing included) until
##            it can pay. "raw" = the best raw resource in stock, whose rarity
##            multiplies every non-flow output (Economy.yield_mult).
@export var outputs: Dictionary = {}
@export var inputs:  Dictionary = {}
## Boost per building: { resource_id: +fraction } (City buildings). Applies to
## its own City (the City and its districts) unless planet_wide.
@export var planet_bonus: Dictionary = {}
## The boost covers the whole planet (rare, expensive, usually 1 per City).
@export var planet_wide: bool = false
## Storage limit raised per building: { resource_id: +amount }. "raw" raises
## every raw resource's cap. See Economy.cap.
@export var storage: Dictionary = {}
## Workers a building employs (population it uses). -1 = derive: housing 0,
## City (planet-wide boost) buildings 1K, others by tier (500 / 1.5K / 3K …).
@export var pop_cost: int = -1

func pop_use() -> int:
	if pop_cost >= 0:
		return pop_cost
	if outputs.has(Economy.POPULATION):
		return 0
	if not planet_bonus.is_empty():
		return 1000
	return [500, 1500, 3000, 6000][clampi(tier - 1, 0, 3)]

## Building tier within its district (1 = basic). Display / ordering only.
@export var tier: int = 1

func output_color() -> Color:
	match output_type:
		OutputType.ENERGY:         return Color(0.95, 0.88, 0.25)
		OutputType.CREDITS:        return Color(0.35, 0.95, 0.55)
		OutputType.RAW_MINERAL:    return Color(0.15, 0.75, 0.50) # Cyan-emerald green for raw mining
		OutputType.REFINED_MINERAL:return Color(0.75, 0.55, 1.00)
		OutputType.SCIENCE:        return Color(0.20, 0.60, 1.00) # Science Blue
		OutputType.POPULATION:     return Economy.color_of(Economy.POPULATION)
		OutputType.GOODS:          return Economy.color_of(Economy.GOODS)
		OutputType.FUEL:           return Economy.color_of(Economy.FUEL)
		OutputType.RARE:           return Economy.color_of(Economy.RARE)
	if not planet_bonus.is_empty():
		return Color(0.95, 0.82, 0.45)
	return Color(0.5, 0.5, 0.5)

## Short economy line, e.g. "+3 goods · −2 raw" or "+15% credits planet-wide".
func output_label() -> String:
	var parts: Array[String] = []
	for id: String in outputs:
		var v: float = outputs[id]
		match id:
			Economy.ENERGY:     parts.append("+%s ⚡/s" % _num(v))
			Economy.POPULATION: parts.append("+%s pop" % Economy.fmt(v))
			Economy.RAW:        parts.append("+%s raw" % _num(v))
			_:                  parts.append("+%s %s" % [_num(v), Economy.INFO.get(id, {}).get("short", id)])
	for id: String in storage:
		parts.append("+%s %s storage" % [Economy.fmt(float(storage[id])),
			Economy.INFO.get(id, {}).get("short", id)])
	for id: String in planet_bonus:
		parts.append("+%d%% %s %s" % [int(round(float(planet_bonus[id]) * 100.0)),
			Economy.INFO.get(id, {}).get("short", id),
			"planet-wide" if planet_wide else "in this city"])
	return " · ".join(parts)

## Upkeep line, e.g. "−2 goods" ("" when the building consumes nothing).
func input_label() -> String:
	var parts: Array[String] = []
	for id: String in inputs:
		parts.append("−%s %s" % [_num(float(inputs[id])), Economy.INFO.get(id, {}).get("short", id)])
	return " · ".join(parts)

static func _num(v: float) -> String:
	return "%d" % int(v) if is_equal_approx(v, round(v)) else "%.1f" % v

## Fills the legacy single-output fields from `outputs` so older UI code that
## reads output_type / output_amount keeps working.
func _derive_legacy_fields() -> void:
	if outputs.is_empty():
		return
	var priority := [Economy.POPULATION, Economy.CREDITS, Economy.SCIENCE, Economy.GOODS,
		Economy.FUEL, Economy.RARE, Economy.RAW, Economy.ENERGY]
	for id: String in priority:
		if not outputs.has(id):
			continue
		output_amount = float(outputs[id])
		match id:
			Economy.POPULATION: output_type = OutputType.POPULATION
			Economy.CREDITS:    output_type = OutputType.CREDITS
			Economy.SCIENCE:    output_type = OutputType.SCIENCE
			Economy.GOODS:      output_type = OutputType.GOODS
			Economy.FUEL:       output_type = OutputType.FUEL
			Economy.RARE:       output_type = OutputType.RARE
			Economy.RAW:        output_type = OutputType.RAW_MINERAL
			Economy.ENERGY:     output_type = OutputType.ENERGY
		break

## ── Site requirements (the district's resource tags, see ResourceMap) ──────
## Tag this building needs at the district site: "geothermal", "solar", "wind",
## "tidal" or "" for none, and the minimum value (0..1) of that tag.
@export var required_tag: String = ""
@export var required_min: float  = 0.0
## Needs a coastal site.
@export var requires_coastal: bool = false
## Needs one of these terrains at the site (TerrainSampler.Terrain); empty = any.
@export var required_terrain: Array[int] = []
## Output scales with this tag at the site: ×(0.5 + value), so a 50% site = 1×.
@export var output_tag: String = ""

static func tag_label(key: String) -> String:
	match key:
		"geothermal": return "Geothermal"
		"solar":      return "Solar"
		"wind":       return "Wind"
		"tidal":      return "Tidal"
		"minerals":   return "Rich deposits"
		"coastal":    return "Coastal"
	return key.capitalize()

## A site factor 0..1 at a district: a resource tag ("solar", "wind",
## "geothermal", "tidal"), "minerals" (richest local deposit), "coastal", or a
## terrain name ("lowlands", "highlands", "mountains", …: 1 if it stands there).
static func site_value(poi: POIData, key: String) -> float:
	if poi == null:
		return 0.0
	match key:
		"coastal":
			return 1.0 if poi.coastal else 0.0
		"minerals":
			var best := 0.0
			var mins: Dictionary = poi.resource_tags.get("minerals", {})
			for rid in mins:
				best = maxf(best, float(mins[rid]))
			return best
	if poi.resource_tags.has(key):
		return float(poi.resource_tags[key])
	var names: Array = TerrainSampler.Terrain.keys()
	if poi.terrain >= 0 and poi.terrain < names.size() and String(names[poi.terrain]).to_lower() == key:
		return 1.0
	return 0.0

static func terrain_label(t: int) -> String:
	var names: Array = TerrainSampler.Terrain.keys()
	return String(names[t]).capitalize() if t >= 0 and t < names.size() else "?"

## Why this building can't be built at the district, or "" if it can.
func site_block_reason(poi: POIData) -> String:
	if poi == null:
		return ""
	if requires_coastal and not poi.coastal:
		return "Needs a coastal site"
	if not required_terrain.is_empty() and not (poi.terrain in required_terrain):
		return "Needs %s" % " or ".join(PackedStringArray(required_terrain.map(func(t: int) -> String: return terrain_label(t))))
	if required_tag != "":
		var v: float = site_value(poi, required_tag)
		if v < required_min:
			return "Needs %s %d%% (site %d%%)" % [tag_label(required_tag),
				int(round(required_min * 100.0)), int(round(v * 100.0))]
	return ""

## Output multiplier from the site's resources (1.0 when not site-dependent).
func site_mult(poi: POIData) -> float:
	if output_tag == "" or poi == null or not poi.resource_tags.has(output_tag):
		return 1.0
	return 0.5 + float(poi.resource_tags[output_tag])

## How much one of these grows its district's settlement on the planet map.
## -1 = derive from output_type (housing / trade grow it most, energy least).
@export var settlement_size: float = -1.0

func settlement_weight() -> float:
	if settlement_size >= 0.0:
		return settlement_size
	match output_type:
		OutputType.POPULATION:      return 1.0   # housing grows a city fastest
		OutputType.CREDITS:         return 0.9   # markets, trade
		OutputType.SCIENCE:         return 0.7
		OutputType.GOODS, OutputType.FUEL, OutputType.RARE, OutputType.REFINED_MINERAL:
			return 0.5
		OutputType.RAW_MINERAL:     return 0.4
		OutputType.ENERGY:          return 0.3   # solar arrays, generators
	return 0.5

@export var logic: BuildingLogic
@export var unlocked_by_default: bool = true

func get_upgrade_cost(level: int, amount: int) -> float:
	return (base_cost * pow(1.5, float(level - 1))) * float(amount)

func get_cumulative_upgrade_cost_for_one(target_level: int) -> float:
	var total := 0.0
	for l in range(1, target_level):
		total += get_upgrade_cost(l, 1)
	return total

func get_build_cost(target_level: int = 1) -> float:
	return base_cost + get_cumulative_upgrade_cost_for_one(target_level)

# ── Catalogue ─────────────────────────────────────────────────────────────────

static var _cache: Array[BuildingDef] = []

static func all() -> Array[BuildingDef]:
	if not _cache.is_empty():
		return _cache
		
	var dir := DirAccess.open("res://resources/buildings")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var res := ResourceLoader.load("res://resources/buildings/" + file_name) as BuildingDef
				if res:
					res._derive_legacy_fields()
					_cache.append(res)
			file_name = dir.get_next()
	return _cache

static func available_buildings() -> Array[BuildingDef]:
	var st = Engine.get_main_loop().root.get_node_or_null("SkillTree")
	var result: Array[BuildingDef] = []
	for b in all():
		if b.unlock_skill != "" and (st == null or not st.is_unlocked(b.unlock_skill)):
			continue
		# a building the research tree grants is available once that node is bought
		if st != null and st.node_for_building(b.building_id) != "":
			if st.building_unlocked(b.building_id):
				result.append(b)
		elif b.unlocked_by_default or GameState.unlocked_buildings.has(b.building_id):
			result.append(b)
	return result

static func find(bid: String) -> BuildingDef:
	for b in all():
		if b.building_id == bid:
			return b
	return null

## Buildings a district of `poi_type` can hold. Cities hold the Capital's
## planet-wide boost buildings; each other district type its own production line.
static func for_poi_and_planet(poi_type: POIData.POIType, planet_type: PlanetData.Type) -> Array[BuildingDef]:
	var result: Array[BuildingDef] = []
	for b in available_buildings():
		if poi_type in b.allowed_poi_types:
			if b.allowed_planet_types.is_empty() or planet_type in b.allowed_planet_types:
				result.append(b)
	return result
