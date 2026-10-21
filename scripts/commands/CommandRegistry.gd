## CommandRegistry — autoload. Gathers the actions for whatever the player
## right-clicked.
##
## Systems register providers per target kind; a provider returns the
## GameCommands for one target. Several providers may serve the same kind, so
## new systems (demolish, move, update…) add actions without touching the views.
##   CommandRegistry.add_provider("district", self, func(poi: POIData) -> Array: …)
##
## Target kinds in use:
##   "city", "district", "station"  POIData on the planet view
##   "surface"                      {"pos": Vector2, "hit": Dictionary} empty planet spot
##   "planet"                       PlanetData in the star system view
##   "star"                         {"galaxy": GalaxyData, "index": int} in the galaxy view
extends Node

## kind -> Array of {"owner": WeakRef, "fn": Callable}
var _providers: Dictionary = {}

## Registers `fn` for `kind`. One provider per owner and kind: registering again
## replaces it. Providers of freed owners are dropped automatically.
func add_provider(kind: String, owner: Object, fn: Callable) -> void:
	var list: Array = _providers.get(kind, [])
	list = list.filter(func(p: Dictionary) -> bool:
		var o: Object = (p["owner"] as WeakRef).get_ref()
		return o != null and o != owner)
	list.append({"owner": weakref(owner), "fn": fn})
	_providers[kind] = list

func commands_for(kind: String, target: Variant) -> Array[GameCommand]:
	var out: Array[GameCommand] = []
	for p: Dictionary in _providers.get(kind, []):
		if (p["owner"] as WeakRef).get_ref() == null or not (p["fn"] as Callable).is_valid():
			continue
		for c in (p["fn"] as Callable).call(target):
			if c is GameCommand:
				out.append(c)
	return out
