## Big panel header (design: Panel Hero + Tags under the Hero):
##   caption            "Terran - Level 2"
##   TITLE              planet / city name (wraps when too long)
##   ─────────────────
##   | tag | tag | tag |  HeroTag nodes under Tags — edit them in the scene
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

static func create(cap: String, t: String) -> HeroHeader:
	var h := (load(SCENE_PATH) as PackedScene).instantiate() as HeroHeader
	h.caption = cap
	h.title = t
	return h

func _ready() -> void:
	_sync()

func _sync() -> void:
	if not is_node_ready():
		return
	_caption.text = caption
	_caption.visible = caption != ""
	_title.text = title

## The tag cells in the bar, in order (hidden ones included).
func tags() -> Array[HeroTag]:
	var out: Array[HeroTag] = []
	for c in $Tags.get_children():
		if c is HeroTag:
			out.append(c)
	return out
