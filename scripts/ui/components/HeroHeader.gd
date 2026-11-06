## Big panel header (design: Panel Hero):
##   caption            "Terran - Level 2"
##   TITLE              planet / city name (wraps when too long)
##   ─────────────────
## The tag bar is no longer part of the header: it sits next to it in each panel scene.
## Layout: scenes/ui/components/HeroHeader.tscn. Look: SubLabel, HeaderHero, TagLabel.
@tool
class_name HeroHeader
extends VBoxContainer

const SCENE_PATH := "res://scenes/ui/components/HeroHeader.tscn"

@export var caption: String = "Planet - Level 4":
	set(v): caption = v; _sync()
@export var title: String = "LASANDA":
	set(v): title = v; _sync()

@onready var _caption: Label = $Caption
@onready var _title: Label = $Title

## `title_size` > 0 makes the title smaller than the theme's HeaderHero
## (e.g. an objective's name, which is a sentence rather than a name).
static func create(cap: String, t: String, title_size := 0) -> HeroHeader:
	var h := (load(SCENE_PATH) as PackedScene).instantiate() as HeroHeader
	h.caption = cap
	h.title = t
	if title_size > 0:
		h.get_node("Title").add_theme_font_size_override(&"font_size", title_size)
		# the scene's tight spacing is tuned for the big size: shrink it with it
		h.get_node("Title").add_theme_constant_override(&"line_spacing", -int(title_size * 0.4))
		h.add_theme_constant_override(&"separation", -int(round(8.0 * (title_size / 36.0) * 0.4)))
	return h

func _ready() -> void:
	_sync()

func _sync() -> void:
	if not is_node_ready():
		return
	_caption.text = caption
	_caption.visible = caption != ""
	_title.text = title
