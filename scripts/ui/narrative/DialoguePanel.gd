class_name DialoguePanel
extends Control

## The story's visual-novel panel (docs/design/narrative/UI.md): at the bottom,
## between the left panel and the screen's right edge, above the news bar. The
## speaker's name (or NARRATOR) is a hero over the card; in the card the line
## types itself on the left and, past a rule, the answers stack on the right
## (or SKIP / LOG / CONTINUE at its bottom right). Behind it all,
## large and standing over the card's right side, the speaker's portrait.
## Narrative drives it.
##
## Input: the first press (CONTINUE, a click on the card, Space / Enter) finishes
## the line being typed, the next one goes on. Answers are only taken by a click
## on one of them (or Enter on the focused one): holding a key never chooses.

signal advance_requested
signal choice_made(index: int, text: String)
signal log_requested
signal skip_requested   # SKIP / Esc / pad B on a scene that may be skipped

## How fast a line types itself, in characters per second.
const TYPE_CPS := 55.0
const MARGIN := 12.0
const MIN_W := 480.0
const MAX_W := 700.0
const ROOM_SHARE := 0.62    # of the room between the left panel and the right edge
const PORTRAIT_H := 540.0   # the standing portrait's height: its foot at the card's bottom, behind it
const PORTRAIT_X := 0.78    # its centre across the card (share of the card's width)
const SIDE_W := 220.0       # the answers' column, at least, while there are answers;
                            # else it is just as wide as its buttons (the rule sits by them)

const SCENE_PATH := "res://scenes/ui/narrative/DialoguePanel.tscn"

@onready var _card: Control = $Card                  # the whole: portrait, hero and card (shown / hidden as one)
@onready var _front: VBoxContainer = $Card/Front     # the hero and the card
@onready var _box: PanelContainer = $Card/Front/Box  # the card
@onready var _portrait: TextureRect = $Card/Portrait
@onready var _hero: HeroHeader = $Card/Front/Head/Hero
@onready var _body: RichTextLabel = $Card/Front/Box/Row/Body
@onready var _side: VBoxContainer = $Card/Front/Box/Row/Side
@onready var _choices: VBoxContainer = $Card/Front/Box/Row/Side/Choices
@onready var _skip: IconButton = $Card/Front/Box/Row/Side/Buttons/Skip
@onready var _log_btn: IconButton = $Card/Front/Box/Row/Side/Buttons/Log
@onready var _next: IconButton = $Card/Front/Box/Row/Side/Buttons/Next
var _typing: Tween = null
var _has_choices := false
var _btn_lit: Control = null   # SKIP / LOG / CONTINUE lit by ← / → (10.11)
var _lit := -1   # the answer the keys lit up, -1: none

## Layout: scenes/ui/narrative/DialoguePanel.tscn.
static func create() -> DialoguePanel:
	return (load(SCENE_PATH) as PackedScene).instantiate() as DialoguePanel

func _ready() -> void:
	_card.visible = false   # until a scene shows it (the scene may keep it visible for editing)
	(_hero.get_node("Title") as Label).autowrap_mode = TextServer.AUTOWRAP_OFF   # one line
	_hero.set_outline()   # the speaker's portrait stands behind it
	_box.gui_input.connect(_on_card_input)
	_skip.pressed.connect(func() -> void:
		AudioManager.play("click")
		skip_requested.emit())
	_skip.mouse_entered.connect(func() -> void:
		TooltipManager.show_tip("Skip", "You have played this before: skip the rest of the scene.  [Esc]"))
	_skip.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	_log_btn.pressed.connect(func() -> void: log_requested.emit())
	_log_btn.mouse_entered.connect(func() -> void:
		TooltipManager.show_tip("Narrative Log", "Read again what has been said.  [L]"))
	_log_btn.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	_next.pressed.connect(_on_next)

## SKIP shows for scenes the player may skip (the opening after a first run).
func set_skippable(on: bool) -> void:
	if _skip != null:
		_skip.visible = on

var _hiding: Tween = null   # the card fading out (a scene ended)
var _show_n := 0   # each show / hide: a coming-in left waiting gives way

func show_panel() -> void:
	if _hiding != null:   # a scene ended and the next one starts at once: it stays up
		_hiding.kill()
		_hiding = null
		_card.modulate.a = 1.0
	if _card.visible:
		return
	_card.visible = true
	# unseen until its line is in and the containers have laid it out (the
	# first frame drew it at the top left, squeezed), then it pops in
	_card.modulate.a = 0.0
	_show_n += 1
	var n := _show_n
	for i in 2:
		await get_tree().process_frame
	if n != _show_n or not _card.visible:
		return
	_place()
	StoryDialog.pop_in(_card)

func hide_panel() -> void:
	_kill_typing()
	_show_n += 1
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
	_light_btn(null)
	_clear_choices()
	# the speaker is the hero (the narrator too), in the title font
	_hero.title = "NARRATOR" if speaker == "" else speaker.to_upper()
	var was := _portrait.texture if _portrait.visible else null
	_portrait.visible = portrait != null
	if portrait != null:
		_portrait.texture = portrait
		# pixel sprites stay sharp; the big renders scale smoothly
		_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if portrait.get_width() <= 512 \
			else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		if was != portrait:
			_portrait.modulate.a = 0.0
			_portrait.create_tween().tween_property(_portrait, "modulate:a", 1.0, 0.18)
	_next.visible = true
	_type(text)

## The answers to the line on screen; CONTINUE gives way to them. `tips[i]`:
## what that answer leads to in the game, shown in its tooltip ("": none).
func show_choices(texts: Array[String], tips: Array[String] = []) -> void:
	_clear_choices()
	_has_choices = true
	_side.custom_minimum_size.x = SIDE_W
	_next.visible = false
	for i in texts.size():
		var b := IconButton.create(texts[i], "confirm", IconButton.Variant.DEFAULT)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # the column's width, stacked
		var at := i
		var label := texts[i]
		b.pressed.connect(func() -> void:
			if _typing != null:
				_skip_typing()
				return
			AudioManager.play("click")
			TooltipManager.hide_tip()
			_clear_choices()
			choice_made.emit(at, label))
		var tip := tips[i] if i < tips.size() else ""
		if tip != "":   # what it leads to (the keys / pad light it as a hover: the tip shows too)
			b.mouse_entered.connect(func() -> void: TooltipManager.show_tip(label, tip))
			b.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
		_choices.add_child(b)
	_choices.modulate.a = 0.0 if _typing != null else 1.0

func _clear_choices() -> void:
	_has_choices = false
	_side.custom_minimum_size.x = 0.0
	_lit = -1
	for c in _choices.get_children():
		_choices.remove_child(c)
		c.queue_free()

func _on_next() -> void:
	if _typing != null:
		_skip_typing()
		return
	if _has_choices:
		return
	AudioManager.play("click")
	advance_requested.emit()

func _on_card_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_on_next()
		accept_event()

func _unhandled_input(ev: InputEvent) -> void:
	if not _card.visible:
		return
	var jb := ev as InputEventJoypadButton   # the pad: D-pad ↑ / ↓ lights, A takes / goes on
	if jb != null and jb.pressed:
		var jk := KEY_NONE
		match jb.button_index:
			JOY_BUTTON_DPAD_UP: jk = KEY_UP
			JOY_BUTTON_DPAD_DOWN: jk = KEY_DOWN
			JOY_BUTTON_DPAD_LEFT: jk = KEY_LEFT
			JOY_BUTTON_DPAD_RIGHT: jk = KEY_RIGHT
			JOY_BUTTON_A: jk = KEY_ENTER
			JOY_BUTTON_B: jk = KEY_ESCAPE
		if jk != KEY_NONE:
			var fake := InputEventKey.new()
			fake.keycode = jk
			fake.pressed = true
			ev = fake
	var k := ev as InputEventKey
	if k == null or not k.pressed:
		return
	var key := k.keycode if k.keycode != KEY_NONE else k.physical_keycode
	var step := 0
	if key in [KEY_UP, KEY_W] or (key == KEY_TAB and k.shift_pressed):
		step = -1
	elif key in [KEY_DOWN, KEY_S, KEY_TAB]:
		step = 1
	if step != 0:
		get_viewport().set_input_as_handled()
		if _has_choices and _typing == null:
			_light(_lit + step if _lit >= 0 else (0 if step > 0 else _choices.get_child_count() - 1))
		return
	if key == KEY_ESCAPE and not k.echo and _skip != null and _skip.visible:
		get_viewport().set_input_as_handled()
		AudioManager.play("click")
		skip_requested.emit()
		return
	if key == KEY_L and not k.echo and not k.ctrl_pressed and not k.meta_pressed:
		get_viewport().set_input_as_handled()
		AudioManager.play("click")
		log_requested.emit()   # L: the Narrative Log, like LOG
		return
	if key in [KEY_LEFT, KEY_RIGHT]:
		get_viewport().set_input_as_handled()   # the buttons below: SKIP / LOG / CONTINUE
		var row := _row_buttons()
		if not row.is_empty():
			var at := row.find(_btn_lit)
			at = (row.size() - 1 if key == KEY_LEFT else 0) if at < 0 else clampi(at + (-1 if key == KEY_LEFT else 1), 0, row.size() - 1)
			_light_btn(row[at])
		return
	if not k.echo and key in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		if _btn_lit != null and is_instance_valid(_btn_lit) and _btn_lit.is_visible_in_tree():
			var b := _btn_lit as BaseButton
			_light_btn(null)
			b.pressed.emit()
			return
		if _typing != null or not _has_choices:
			_on_next()
		elif _lit < 0:
			_light(0)
		else:
			(_choices.get_child(_lit) as BaseButton).pressed.emit()

func _row_buttons() -> Array[Control]:
	var out: Array[Control] = []
	for b in [_skip, _log_btn, _next]:
		if b != null and (b as Control).is_visible_in_tree():
			out.append(b)
	return out

func _light_btn(c: Control) -> void:
	if _btn_lit != null and is_instance_valid(_btn_lit):
		_hover(_btn_lit, false)
	_btn_lit = c
	if c != null:
		_hover(c, true)
		AudioManager.play("hover")

## Lights up answer [i] (wrapping round), as if the mouse were on it.
func _light(i: int) -> void:
	var n := _choices.get_child_count()
	if n == 0:
		return
	if _lit >= 0 and _lit < n:
		_hover(_choices.get_child(_lit) as Control, false)
	_lit = posmod(i, n)
	_hover(_choices.get_child(_lit) as Control, true)
	AudioManager.play("hover")

func _hover(c: Control, on: bool) -> void:
	c.notification(Control.NOTIFICATION_MOUSE_ENTER if on else Control.NOTIFICATION_MOUSE_EXIT)
	if on:
		c.mouse_entered.emit()
	else:
		c.mouse_exited.emit()

## The card is up: the story has the keyboard.
func owns_keys() -> bool:
	return _card != null and _card.visible

func _type(text: String) -> void:
	_kill_typing()
	_body.text = text
	_body.visible_characters = 0
	_next.modulate.a = 0.0
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

func _done_typing() -> void:
	_typing = null
	_body.visible_characters = -1
	create_tween().tween_property(_next, "modulate:a", 1.0, 0.15)
	if _has_choices:
		create_tween().tween_property(_choices, "modulate:a", 1.0, 0.18)

func _process(_delta: float) -> void:
	if _card.visible:
		_place()

## Where the story's cards stand, as (left, right) x on screen: past the left
## panel (when open), short of the objectives / tutorial card on the right when
## one is up (never over either). The CommsCard uses it too.
static func play_room(ci: CanvasItem, margin: float) -> Vector2:
	var vp := ci.get_viewport_rect().size
	var left := margin
	for n in ci.get_tree().get_nodes_in_group(LeftPanel.GROUP):
		var lp := n as Control
		if lp != null and lp.is_visible_in_tree() and (lp.get_node("Layout") as CanvasItem).visible \
				and not _under_tree(lp):
			left = maxf(left, lp.get_global_rect().end.x + margin)
	var right := vp.x - margin
	for n in ci.get_tree().get_nodes_in_group(ObjectivesCard.GROUP):
		var oc := n as Control
		if oc != null and oc.is_visible_in_tree() and oc.modulate.a > 0.01 and not _under_tree(oc):
			var r := oc.get_global_rect()
			if r.position.x > left:   # a card on the right side
				right = minf(right, r.position.x - margin)
	return Vector2(left, right)

## Hidden under the open Upgrade Tree (a lower canvas layer than its 220): it
## doesn't push the cards aside, they centre on the screen (revision 12.11).
const TREE_LAYER := 220
static func _under_tree(c: Control) -> bool:
	if not SkillTreeView.is_open:
		return false
	var cl := c.get_canvas_layer_node()
	return cl == null or cl.layer < TREE_LAYER

## In the play room (play_room), most of it, centred in it; its bottom just
## above the news bar. The portrait stands behind, over the card's right side,
## from the card's bottom up, and stays inside the card's width.
func _place() -> void:
	var vp := get_viewport_rect().size
	var span := play_room(self, MARGIN)
	var left := span.x
	var room := maxf(span.y - span.x, MIN_W)
	var w := minf(clampf(room * ROOM_SHARE, MIN_W, MAX_W), room)
	var bottom := vp.y - MARGIN
	var news := get_tree().get_first_node_in_group(&"news_panel") as Control
	if news != null and news.is_visible_in_tree():
		bottom = news.get_global_rect().position.y - MARGIN
	_front.custom_minimum_size = Vector2(w, 0.0)
	_front.size = Vector2(w, _front.get_combined_minimum_size().y)
	_card.size = _front.size
	_card.position = Vector2(left + (room - w) * 0.5, bottom - _card.size.y)
	_front.position = Vector2.ZERO
	if _portrait.visible and _portrait.texture != null:
		var tex := _portrait.texture
		var foot := _box.position.y + _box.size.y
		var ph := minf(PORTRAIT_H, _card.position.y + foot - MARGIN)   # never above the screen
		var pw := ph * float(tex.get_width()) / maxf(float(tex.get_height()), 1.0)
		_portrait.size = Vector2(pw, ph)
		_portrait.position = Vector2(minf(w * PORTRAIT_X - pw * 0.5, w - pw), foot - ph)
