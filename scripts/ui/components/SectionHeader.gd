## "CITIES ............ 3/5" — a panel section title with an optional counter.
## Layout: scenes/ui/components/SectionHeader.tscn. Look: HeaderLabel / CounterLabel.
@tool
class_name SectionHeader
extends HBoxContainer

const SCENE_PATH := "res://scenes/ui/components/SectionHeader.tscn"

@export var title: String = "CITIES":
	set(v): title = v; _sync()
@export var counter: String = "3/5":
	set(v): counter = v; _sync()

static func create(t: String, count := "") -> SectionHeader:
	var h := (load(SCENE_PATH) as PackedScene).instantiate() as SectionHeader
	h.title = t
	h.counter = count
	return h

func _ready() -> void:
	_sync()

func _sync() -> void:
	if not is_node_ready():
		return
	($Title as Label).text = title
	($Counter as Label).text = counter
	($Counter as Label).visible = counter != ""
