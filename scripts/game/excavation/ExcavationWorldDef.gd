@tool
class_name ExcavationWorldDef
extends Resource

## The excavations of one world, in order (Excavations): a file in
## res://resources/excavations/. Each opens when the one before it is done.

enum World { HOME, MOON, PLANET_TYPE }

@export var world: World = World.HOME
## For World.PLANET_TYPE.
@export var planet_type: PlanetData.Type = PlanetData.Type.ARID
@export var sites: Array[ExcavationSiteDef] = []

func planet() -> PlanetData:
	match world:
		World.HOME: return GameState.get_home_planet()
		World.MOON: return GameState.home_moon()
	var sys: SolarData = GameState.get_home_solar()
	if sys != null:
		for p: PlanetData in sys.planets:
			if p.planet_type == planet_type and p.seed != GameState.home_planet_seed:
				return p
	return null

static var _cache: Array[ExcavationWorldDef] = []

static func all() -> Array[ExcavationWorldDef]:
	if not _cache.is_empty():
		return _cache
	var dir := DirAccess.open("res://resources/excavations")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			var path := file_name.trim_suffix(".remap")
			if not dir.current_is_dir() and path.ends_with(".tres"):
				var res := ResourceLoader.load("res://resources/excavations/" + path) as ExcavationWorldDef
				if res:
					_cache.append(res)
			file_name = dir.get_next()
	return _cache
