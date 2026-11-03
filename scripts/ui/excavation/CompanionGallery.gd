class_name CompanionGallery
extends Control

## Every companion of the game, joined or not: a list on the left, the one picked
## on the right. Before they join: "???", a dark silhouette and where to look.
## Layout: scenes/ui/excavation/CompanionGallery.tscn.

const SCENE_PATH := "res://scenes/ui/excavation/CompanionGallery.tscn"
const LAYER := 235

@onready var _card: Control = $Center/Card
@onready var _list: VBoxContainer = $Center/Card/VBox/Row/Scroll/List
@onready var _detail: Control = $Center/Card/VBox/Row/Detail
@onready var _portrait: TextureRect = $Center/Card/VBox/Row/Detail/Top/Frame/Portrait
@onready var _name: Label = $Center/Card/VBox/Row/Detail/Top/Info/Name
@onready var _role: Label = $Center/Card/VBox/Row/Detail/Top/Info/Role
@onready var _bonus: RichTextLabel = $Center/Card/VBox/Row/Detail/Top/Info/Bonus
@onready var _bio: RichTextLabel = $Center/Card/VBox/Row/Detail/Bio

var _items: Array[ListItem] = []

static func open(host: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	host.get_tree().root.add_child(layer)
	layer.add_child((load(SCENE_PATH) as PackedScene).instantiate())
	AudioManager.play("click")

func _ready() -> void:
	var all := CompanionDef.all()
	($Center/Card/VBox/Header/Counter as Label).text = "%d / %d" % [Excavations.joined_count(), all.size()]
	($Center/Card/VBox/Header/Close as Button).pressed.connect(_close)
	($Dim as Control).gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_close())
	var first := -1
	for i in all.size():
		var def := all[i]
		var joined := Excavations.has_joined(def.companion_id)
		var it := ListItem.create(def.display_name.to_upper() if joined else "???", "population" if joined else "unknown",
			"", [], def.role if joined else "Not met yet")
		var at := i
		it.pressed.connect(func() -> void:
			AudioManager.play("click")
			_pick(all, at))
		_list.add_child(it)
		_items.append(it)
		if joined and first < 0:
			first = i
	if not all.is_empty():
		_pick(all, maxi(first, 0))
	StoryDialog.pop_in(_card)

func _pick(all: Array[CompanionDef], i: int) -> void:
	for n in _items.size():
		_items[n].selected = n == i
	var def := all[i]
	var joined := Excavations.has_joined(def.companion_id)
	_portrait.texture = def.portrait_texture()
	_portrait.modulate = Color.WHITE if joined else Color(0.25, 0.28, 0.36)
	_name.text = def.display_name.to_upper() if joined else "???"
	_role.text = def.role
	_role.visible = joined
	_bonus.text = def.bonus_bb(13)
	_bonus.visible = joined
	_bio.text = def.bio if joined else def.hint
	_detail.modulate.a = 0.0
	create_tween().tween_property(_detail, "modulate:a", 1.0, 0.15)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	StoryDialog.pop_out(_card, get_parent())
