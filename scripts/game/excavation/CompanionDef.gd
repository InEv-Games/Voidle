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
## What they say they can do for you, on the advisor's card (the opening choice).
@export_multiline var pitch: String = ""
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
## Off the roster (the old pair, Sera and Dorian, before the narrative's four):
## never listed, found or joined; stories that still name them do nothing.
@export var retired: bool = false

func portrait_texture() -> Texture2D:
	return portrait if portrait != null else load(FALLBACK_PORTRAIT) as Texture2D

## The bonus for BBCode: a resource by its icon ("[credits] +5% everywhere"),
## never its name.
func bonus_bb(px: int) -> String:
	if bonus == Bonus.BUILD_SPEED:
		var col := UIStyle.color(&"good")
		return "%s [color=#%s]Districts build %d%% faster (Orbit rockets too)[/color]" % [UIIcons.bb("upgrade", px, col),
			col.to_html(false), roundi(bonus_value * 100.0)]
	return "%s everywhere" % PlanetTags.effect_short_bb(bonus_resource, bonus_value, px)

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
				if res and not res.retired:
					_cache.append(res)
			file_name = dir.get_next()
	_cache.sort_custom(func(a: CompanionDef, b: CompanionDef) -> bool: return a.order < b.order)
	return _cache

static func find(id: String) -> CompanionDef:
	for c: CompanionDef in all():
		if c.companion_id == id:
			return c
	return null
