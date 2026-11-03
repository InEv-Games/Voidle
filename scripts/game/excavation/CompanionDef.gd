@tool
class_name CompanionDef
extends Resource

## A companion (Excavations), a file in res://resources/companions/: joins
## when a story's StoryJoinCompanion runs and gives a bonus everywhere from then on.

enum Bonus { RESOURCE, BUILD_SPEED }

const FALLBACK_PORTRAIT := "res://resources/companions/portraits/silhouette.svg"

## Saved in companions_joined: don't rename one that shipped.
@export var companion_id: String = ""
@export var display_name: String = ""
## "Wandering trader"
@export var role: String = ""
@export_multiline var bio: String = ""
## In the gallery before they join: where to look.
@export_multiline var hint: String = ""
## Their place in the gallery.
@export var order: int = 0
## Empty: the silhouette, until the art is in.
@export var portrait: Texture2D
@export var bonus: Bonus = Bonus.RESOURCE
## For Bonus.RESOURCE: a resource id ("raw" means raw and processed output).
@export var bonus_resource: String = ""
## 0.05 = +5%.
@export var bonus_value: float = 0.05
## The relic an older save found instead of this companion.
@export var legacy_relic_id: String = ""

func portrait_texture() -> Texture2D:
	return portrait if portrait != null else load(FALLBACK_PORTRAIT) as Texture2D

## "+5% Credits everywhere" / "Districts build 25% faster".
func bonus_text() -> String:
	var pct := roundi(bonus_value * 100.0)
	if bonus == Bonus.BUILD_SPEED:
		return "Districts build %d%% faster (Orbit rockets too)" % pct
	return "+%d%% %s everywhere" % [pct, PlanetTags.resource_label(bonus_resource)]

static var _cache: Array[CompanionDef] = []

## In gallery order.
static func all() -> Array[CompanionDef]:
	if not _cache.is_empty():
		return _cache
	var dir := DirAccess.open("res://resources/companions")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			var path := file_name.trim_suffix(".remap")
			if not dir.current_is_dir() and path.ends_with(".tres"):
				var res := ResourceLoader.load("res://resources/companions/" + path) as CompanionDef
				if res:
					_cache.append(res)
			file_name = dir.get_next()
	_cache.sort_custom(func(a: CompanionDef, b: CompanionDef) -> bool: return a.order < b.order)
	return _cache

static func find(id: String) -> CompanionDef:
	for c: CompanionDef in all():
		if c.companion_id == id:
			return c
	return null
