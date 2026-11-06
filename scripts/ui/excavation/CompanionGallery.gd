class_name CompanionGallery
extends Control

## Every companion of the game, joined or not. Laid out like the save slots:
## ‹ BACK above a hero ("n / m joined" / COMPANIONS), then the list card and,
## beside it, the picked one standing full height (over the hero's rule) with,
## at their feet, a small hero (role / NAME) over a card with their bonus and
## words. Before they join: a dark silhouette, "Not met yet" / ??? and where
## to look. Rows come in with RowReveal; Esc, ‹ BACK or a
## click outside closes it. Layout: scenes/ui/excavation/CompanionGallery.tscn.

const SCENE_PATH := "res://scenes/ui/excavation/CompanionGallery.tscn"
const LAYER := 235
const NAME_SIZE := 26   # the name hero over their words: smaller than the page's

@onready var _card: Control = $Center/Card
@onready var _list: VBoxContainer = $Center/Card/Row/ListCard/Scroll/List
@onready var _detail: Control = $Center/Card/Row/Detail
@onready var _portrait: TextureRect = $Center/Card/Row/Detail/Portrait
@onready var _name: HeroHeader = $Center/Card/Row/Detail/Foot/NameHero
@onready var _bonus: RichTextLabel = $Center/Card/Row/Detail/Foot/BioCard/Info/Bonus
@onready var _bio: RichTextLabel = $Center/Card/Row/Detail/Foot/BioCard/Info/Bio

var _items: Array[ListItem] = []

static func open(host: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	host.get_tree().root.add_child(layer)
	layer.add_child((load(SCENE_PATH) as PackedScene).instantiate())
	AudioManager.play("click")

func _ready() -> void:
	var all := CompanionDef.all()
	_name.set_title_size(NAME_SIZE)
	($Center/Card/Hero as HeroHeader).caption = "%d / %d joined" % [Excavations.joined_count(), all.size()]
	var back := LeftPanel.back_button("BACK")
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		_close())
	_card.add_child(back)
	_card.move_child(back, 0)
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
	RowReveal.play(_card)

func _pick(all: Array[CompanionDef], i: int) -> void:
	for n in _items.size():
		_items[n].selected = n == i
	var def := all[i]
	var joined := Excavations.has_joined(def.companion_id)
	# no placeholder here: stretched to full height it is a big box over the screen
	_portrait.texture = def.portrait
	_portrait.visible = def.portrait != null
	_portrait.modulate = Color.WHITE if joined else Color(0.25, 0.28, 0.36)
	_name.caption = def.role if joined else "Not met yet"
	_name.title = def.display_name.to_upper() if joined else "???"
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
