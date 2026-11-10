class_name DialoguePanel
extends Control

## The story's visual-novel panel (docs/design/narrative/UI.md): at the bottom,
## between the left panel and the screen's right edge, above the news bar; the
## speaker's portrait on the left (about a quarter), then their name, the line
## typing itself, and the answers or CONTINUE. Narrative drives it.
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
const MIN_W := 440.0
const MAX_W := 780.0
const PORTRAIT_H := 150.0

var _card: PanelContainer
var _portrait: TextureRect
var _speaker: Label
var _body: RichTextLabel
var _choices: VBoxContainer
var _next: IconButton
var _typing: Tween = null
var _has_choices := false
var _skip: IconButton = null
var _lit := -1   # the answer the keys lit up, -1: none

static func create() -> DialoguePanel:
	var p := DialoguePanel.new()
	p.name = "DialoguePanel"
	return p

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card = PanelContainer.new()
	_card.theme_type_variation = &"PopupCard"
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.gui_input.connect(_on_card_input)
	add_child(_card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	_card.add_child(row)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_portrait)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override(&"separation", 6)
	row.add_child(col)
	_speaker = Label.new()
	_speaker.theme_type_variation = &"HeaderLabel"
	col.add_child(_speaker)
	_body = RichTextLabel.new()
	_body.theme_type_variation = &"PopupBody"
	_body.add_theme_font_size_override(&"normal_font_size", 12)
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_body)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override(&"separation", 4)
	col.add_child(_choices)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override(&"separation", 6)
	col.add_child(buttons)
	var log_btn := IconButton.create("LOG", "notes", IconButton.Variant.DEFAULT)
	log_btn.pressed.connect(func() -> void: log_requested.emit())
	log_btn.mouse_entered.connect(func() -> void:
		TooltipManager.show_tip("Narrative Log", "Read again what has been said.  [L]"))
	log_btn.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	buttons.add_child(log_btn)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	buttons.add_child(gap)
	_skip = IconButton.create("SKIP", "close", IconButton.Variant.NEUTRAL)
	_skip.pressed.connect(func() -> void:
		AudioManager.play("click")
		skip_requested.emit())
	_skip.mouse_entered.connect(func() -> void:
		TooltipManager.show_tip("Skip", "You have played this before: skip the rest of the scene.  [Esc]"))
	_skip.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	_skip.visible = false
	buttons.add_child(_skip)
	_next = IconButton.create("CONTINUE", "confirm", IconButton.Variant.POSITIVE)
	_next.pressed.connect(_on_next)
	buttons.add_child(_next)
	_card.visible = false

## SKIP shows for scenes the player may skip (the opening after a first run).
func set_skippable(on: bool) -> void:
	if _skip != null:
		_skip.visible = on

func show_panel() -> void:
	if _card.visible:
		return
	_card.visible = true
	_place()
	StoryDialog.pop_in(_card)

func hide_panel() -> void:
	_kill_typing()
	if not _card.visible:
		return
	var tw := _card.create_tween()
	tw.tween_property(_card, "modulate:a", 0.0, 0.12)
	tw.tween_callback(func() -> void:
		_card.visible = false
		_card.modulate.a = 1.0)

func show_line(speaker: String, text: String, portrait: Texture2D) -> void:
	_clear_choices()
	_speaker.visible = speaker != "Narrator"
	_speaker.text = speaker
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

## The answers to the line on screen; CONTINUE gives way to them.
func show_choices(texts: Array[String]) -> void:
	_clear_choices()
	_has_choices = true
	_next.visible = false
	for i in texts.size():
		var b := IconButton.create(texts[i], "confirm", IconButton.Variant.DEFAULT)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var at := i
		var label := texts[i]
		b.pressed.connect(func() -> void:
			if _typing != null:
				_skip_typing()
				return
			AudioManager.play("click")
			_clear_choices()
			choice_made.emit(at, label))
		_choices.add_child(b)
	_choices.modulate.a = 0.0 if _typing != null else 1.0

func _clear_choices() -> void:
	_has_choices = false
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
		get_viewport().set_input_as_handled()   # nothing for them here; keep them from the panel behind
		return
	if not k.echo and key in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		if _typing != null or not _has_choices:
			_on_next()
		elif _lit < 0:
			_light(0)
		else:
			(_choices.get_child(_lit) as BaseButton).pressed.emit()

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

## Between the left panel (when open) and the right edge, about two thirds of
## that room, centred in it; its bottom just above the news bar.
func _place() -> void:
	var vp := get_viewport_rect().size
	var left := MARGIN
	for n in get_tree().get_nodes_in_group(LeftPanel.GROUP):
		var lp := n as Control
		if lp != null and lp.is_visible_in_tree() and (lp.get_node("Layout") as CanvasItem).visible:
			left = maxf(left, lp.get_global_rect().end.x + MARGIN)
	var room := maxf(vp.x - MARGIN - left, MIN_W)
	var w := clampf(room * 0.66, MIN_W, MAX_W)
	var bottom := vp.y - MARGIN
	var news := get_tree().get_first_node_in_group(&"news_panel") as Control
	if news != null and news.is_visible_in_tree():
		bottom = news.get_global_rect().position.y - MARGIN
	_portrait.custom_minimum_size = Vector2(w * 0.22, PORTRAIT_H) if _portrait.visible else Vector2.ZERO
	_card.custom_minimum_size = Vector2(w, 0.0)
	_card.size = Vector2(w, _card.get_combined_minimum_size().y)
	_card.position = Vector2(left + (room - w) * 0.5, bottom - _card.size.y)
