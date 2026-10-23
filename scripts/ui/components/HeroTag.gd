## One cell of the hero tag bar:  tag text │
## Placed as nodes in HeroHeader.tscn (and under a hero's Tags in a scene);
## add, hide or reorder them in the editor. Look: TagLabel, Palette good / bad.
@tool
class_name HeroTag
extends HBoxContainer

enum Tone { PLAIN, GOOD, BAD }

@export var text: String = "Tag":
	set(v): text = v; _sync()
## GOOD / BAD colour the text (e.g. a planet modifier's sign).
@export var tone: Tone = Tone.PLAIN:
	set(v): tone = v; _sync()
## Tooltip shown on hover; empty = no tooltip.
@export_multiline var tip: String = "":
	set(v): tip = v; _sync()

@onready var _label: Label = $Label

func _ready() -> void:
	_sync()

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_sync()

func _sync() -> void:
	if not is_node_ready():
		return
	_label.text = text
	if tone == Tone.PLAIN:
		_label.remove_theme_color_override("font_color")
	else:
		_label.add_theme_color_override("font_color", get_theme_color(&"good" if tone == Tone.GOOD else &"bad", &"Palette"))
	_label.tooltip_text = tip
	_label.mouse_filter = Control.MOUSE_FILTER_STOP if tip != "" else Control.MOUSE_FILTER_IGNORE
