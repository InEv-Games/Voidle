## "Key ............ value" line for panels, tooltips and popups.
## Layout: scenes/ui/components/InfoRow.tscn. Look: SubLabel / CounterLabel, Palette good / bad.
@tool
class_name InfoRow
extends HBoxContainer

const SCENE_PATH := "res://scenes/ui/components/InfoRow.tscn"
enum Tone { PLAIN, GOOD, BAD }

@export var key: String = "Key":
	set(v): key = v; _sync()
@export var value: String = "Value":
	set(v): value = v; _sync()
@export var tone: Tone = Tone.PLAIN:
	set(v): tone = v; _sync()

func _ready() -> void:
	_sync()

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_sync()

func _sync() -> void:
	if not is_node_ready():
		return
	($Key as Label).text = key
	var v := $Value as Label
	v.text = value
	if tone == Tone.PLAIN:
		v.remove_theme_color_override("font_color")
	else:
		v.add_theme_color_override("font_color", get_theme_color(&"good" if tone == Tone.GOOD else &"bad", &"Palette"))
