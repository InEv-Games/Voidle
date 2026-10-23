## Semantic icon names -> Material Symbols SVGs in res://resources/ui/icons/.
## The SVGs are white so they take any colour through modulate / icon colour.
## Add a name here (or drop a new SVG in the folder and use its file name).
class_name UIIcons
extends RefCounted

const DIR := "res://resources/ui/icons/"
## Raw materials and minerals share a placeholder until they get their own art.
const RAW_PLACEHOLDER := "add_triangle"

const MAP := {
	# resources
	"credits": "data_usage", "science": "experiment", "energy": "bolt", "population": "groups",
	"worker": "engineering", "raw": "view_in_ar", "goods": "deployed_code", "fuel": "oil_barrel",
	"rare_elements": "square_dot", "production": "manufacturing",
	# places
	"planet": "public", "moon": "nightlight", "city": "home", "capital": "castle", "district": "home_work",
	"factory": "factory", "warehouse": "warehouse", "rocket": "rocket", "map": "map", "explore": "explore",
	# actions / prompts
	"new": "add_box", "positive": "add_box", "negative": "indeterminate_check_box",
	"unknown": "indeterminate_question_box", "upgrade": "keyboard_double_arrow_up", "downgrade": "tilt_arrow_down",
	"trade": "swap_horizontal_circle", "confirm": "check_box", "empty": "check_box_outline_blank",
	"cancel": "disabled_by_default", "close": "disabled_by_default", "warning": "report", "danger": "dangerous",
	"alert": "frame_exclamation", "rename": "drive_file_rename", "settings": "settings", "research": "lab_research",
	"library": "local_library", "defense": "local_police", "move": "moving_ministry", "notes": "sticky_note_2",
	"save": "upload_file",
}

static var _cache: Dictionary = {}

## Texture for a semantic name, or for a raw SVG file name. Unknown -> "unknown".
static func get_icon(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var file: String = MAP.get(name, name)
	var path := DIR + file + ".svg"
	if not ResourceLoader.exists(path):
		path = DIR + String(MAP["unknown"]) + ".svg"
	var tex := load(path) as Texture2D
	_cache[name] = tex
	return tex
