## A PopupCard over a dimmed screen, on its own CanvasLayer. Esc, the close
## button or a click outside closes it.
##   var p := ModalPopup.open(self, "UPGRADE PLANET", "upgrade", "Raise Vesuna to Lv 3.")
##   p.add_row("Credits", "5k cr", InfoRow.Tone.GOOD)
##   p.confirm_button().pressed.connect(...)
## Layout: scenes/ui/components/ModalPopup.tscn (+ PopupCard.tscn inside).
class_name ModalPopup
extends Control

const SCENE_PATH := "res://scenes/ui/components/ModalPopup.tscn"
const INFO_ROW := "res://scenes/ui/components/InfoRow.tscn"
const LIST_ITEM := "res://scenes/ui/components/ListItem.tscn"

signal closed

@onready var card: PopupCard = $Center/Card

## False: no close button, Esc and clicks outside do nothing (a choice is required).
var dismissable: bool = true:
	set(v):
		dismissable = v
		(card.get_node("VBox/Header/Close") as Control).visible = v
		cancel_button().visible = v

static func open(host: Node, title: String, icon_name: String, body := "", layer := 235) -> ModalPopup:
	var cl := CanvasLayer.new()
	cl.layer = layer
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	var m := (load(SCENE_PATH) as PackedScene).instantiate() as ModalPopup
	cl.add_child(m)
	host.get_tree().root.add_child(cl)
	m.card.title = title.to_upper()
	m.card.icon_name = icon_name
	m.card.body = body
	return m

func _ready() -> void:
	($Dim as Control).gui_input.connect(func(e: InputEvent) -> void:
		if dismissable and e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			close())
	card.close_pressed.connect(close)
	cancel_button().pressed.connect(close)

func content() -> VBoxContainer:
	return card.get_node("VBox/Content") as VBoxContainer

func cancel_button() -> IconButton:
	return card.get_node("VBox/Buttons/Cancel") as IconButton

func confirm_button() -> IconButton:
	return card.get_node("VBox/Buttons/Confirm") as IconButton

## Adds an InfoRow ("key ...... value") to the content area.
func add_row(key: String, value: String, tone: InfoRow.Tone = InfoRow.Tone.PLAIN) -> InfoRow:
	var r := (load(INFO_ROW) as PackedScene).instantiate() as InfoRow
	r.key = key
	r.value = value
	r.tone = tone
	add_content(r)
	return r

## Adds a ListItem to the content area (not clickable).
func add_item(title: String, icon_id: String, badge := "", description := "") -> ListItem:
	var it := ListItem.create(title, icon_id, badge, [], description)
	it.clickable = false
	add_content(it)
	return it

func add_content(c: Control) -> void:
	content().add_child(c)
	content().visible = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if dismissable:
			close()

func close() -> void:
	closed.emit()
	CursorManager.set_state(CursorManager.State.NORMAL)
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()
