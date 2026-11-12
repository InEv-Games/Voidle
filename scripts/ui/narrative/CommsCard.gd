class_name CommsCard
extends Control

## Someone speaking in the middle of play (layout:
## scenes/ui/narrative/CommsCard.tscn): a small card at the bottom, the
## speaker's bust on its left rising over its top edge, their name and the line
## typing itself on the right. For the lines that don't stop the game: the
## tutorial / objectives' advisor (Narrative's short scenes, "main": false) and
## anyone who speaks as a notice (Narrative.say). The story's own scenes use the
## DialoguePanel.
##
## It never takes the keys and never blocks the map: a click on the card
## finishes the line being typed, the next click goes on; left alone, a line
## goes on by itself once it has had time to be read (READ_*). Narrative
## drives it (advance_requested).

signal advance_requested

const TYPE_CPS := 55.0
const MARGIN := 12.0
const CARD_W := 540.0
const FACE_W := 130.0       # the bust's room on the card's left
const FACE_RISE := 44.0     # how far the bust rises over the card's top
const BUST_SCALE := 1.35    # the portrait's width over the bust's room (head and shoulders show)
## A line goes on by itself after READ_MIN s, or longer for a long one
## (READ_CPS characters a second), counted from when it has finished typing.
const READ_MIN := 4.0
const READ_CPS := 14.0

@onready var _card: Control = $Card
@onready var _box: PanelContainer = $Card/Box
@onready var _pad: Control = $Card/Box/Row/Pad
@onready var _speaker: Label = $Card/Box/Row/Col/Speaker
@onready var _body: RichTextLabel = $Card/Box/Row/Col/Body
@onready var _face: Control = $Card/Face
@onready var _portrait: TextureRect = $Card/Face/Portrait

var _typing: Tween = null
var _line_id := 0   # the auto-advance belongs to the line it was started for

static func create() -> CommsCard:
	return (load("res://scenes/ui/narrative/CommsCard.tscn") as PackedScene).instantiate() as CommsCard

func _ready() -> void:
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_box.gui_input.connect(func(ev: InputEvent) -> void:
		var mb := ev as InputEventMouseButton
		if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_click()
			_box.accept_event())

var _hiding: Tween = null   # the card fading out (a scene ended)

func show_panel() -> void:
	if _hiding != null:   # a scene ended and the next one starts at once: it stays up
		_hiding.kill()
		_hiding = null
		_card.modulate.a = 1.0
	if _card.visible:
		return
	_card.visible = true
	_place()
	StoryDialog.pop_in(_card)

func hide_panel() -> void:
	_kill_typing()
	_line_id += 1
	if not _card.visible:
		return
	if _hiding != null:
		return
	_hiding = _card.create_tween()
	_hiding.tween_property(_card, "modulate:a", 0.0, 0.12)
	_hiding.tween_callback(func() -> void:
		_hiding = null
		_card.visible = false
		_card.modulate.a = 1.0)

func show_line(speaker: String, text: String, portrait: Texture2D) -> void:
	_speaker.text = "NARRATOR" if speaker == "" or speaker == "Narrator" else speaker.to_upper()
	var was := _portrait.texture if _face.visible else null
	_face.visible = portrait != null
	_pad.custom_minimum_size.x = FACE_W if portrait != null else 0.0
	if portrait != null:
		_portrait.texture = portrait
		# pixel sprites stay sharp; the big renders scale smoothly
		_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if portrait.get_width() <= 512 \
			else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if was != portrait:
			_face.modulate.a = 0.0
			_face.create_tween().tween_property(_face, "modulate:a", 1.0, 0.18)
	_type(text)

## A click: the line being typed shows whole; else the next line.
func _on_click() -> void:
	if _typing != null:
		_skip_typing()
		return
	_go_on()

func _go_on() -> void:
	_line_id += 1
	AudioManager.play("click")
	advance_requested.emit()

func _type(text: String) -> void:
	_kill_typing()
	_line_id += 1
	_body.text = text
	_body.visible_characters = 0
	var chars := _body.get_total_character_count()
	_typing = create_tween()
	_typing.tween_property(_body, "visible_characters", chars, chars / TYPE_CPS)
	_typing.tween_callback(_done_typing)

func _skip_typing() -> void:
	_kill_typing()
	_done_typing()

func _kill_typing() -> void:
	if _typing != null:
		_typing.kill()
		_typing = null

## Typed: it goes on by itself once it has had time to be read.
func _done_typing() -> void:
	_typing = null
	_body.visible_characters = -1
	var id := _line_id
	var secs := maxf(READ_MIN, float(_body.get_total_character_count()) / READ_CPS)
	get_tree().create_timer(secs, true).timeout.connect(func() -> void:
		if id == _line_id and _card.visible:
			_go_on())

func _process(_delta: float) -> void:
	if _card.visible:
		_place()

## Between the left panel (when open) and the right edge, centred in that
## room; its bottom just above the news bar. The bust stands on the card's
## bottom edge, over its left end, rising above its top.
func _place() -> void:
	var vp := get_viewport_rect().size
	var left := MARGIN
	for n in get_tree().get_nodes_in_group(LeftPanel.GROUP):
		var lp := n as Control
		if lp != null and lp.is_visible_in_tree() and (lp.get_node("Layout") as CanvasItem).visible:
			left = maxf(left, lp.get_global_rect().end.x + MARGIN)
	var room := maxf(vp.x - MARGIN - left, 320.0)
	var w := minf(CARD_W, room)
	var bottom := vp.y - MARGIN
	var news := get_tree().get_first_node_in_group(&"news_panel") as Control
	if news != null and news.is_visible_in_tree():
		bottom = news.get_global_rect().position.y - MARGIN
	_box.custom_minimum_size.x = w
	_box.size = Vector2(w, _box.get_combined_minimum_size().y)
	_box.position = Vector2(0.0, FACE_RISE)
	_card.size = Vector2(w, FACE_RISE + _box.size.y)
	_card.position = Vector2(left + (room - w) * 0.5, bottom - _card.size.y)
	_face.position = Vector2(8.0, 0.0)
	_face.size = Vector2(FACE_W, _card.size.y - 1.0)   # down to the card's bottom edge
	var tex := _portrait.texture
	if tex != null:
		var pw := FACE_W * BUST_SCALE
		var ph := pw * float(tex.get_height()) / maxf(float(tex.get_width()), 1.0)
		_portrait.size = Vector2(pw, ph)
		_portrait.position = Vector2((FACE_W - pw) * 0.5, 0.0)
