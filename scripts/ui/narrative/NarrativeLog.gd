class_name NarrativeLog
extends ModalPopup

## The Narrative Log (docs/design/narrative/UI.md; layout:
## scenes/ui/narrative/NarrativeLog.tscn): a panel along the right edge with
## everything the story has shown, in order, grouped under the scene it came
## from (an excavation's story under its site), the newest at the bottom. Each
## entry is its speaker's name with the line under it, a space between entries;
## the player's answers are "YOU", and what the story did in the game (a
## reward paid, a companion joining, an advisor appointed: Narrative.log_event)
## stands as a mark of its own. Reading it never runs a scene or pays anything;
## it follows new entries while open. LOG / L / Esc / ✕ / a click outside close it.

const LAYER := 238   # over the dialogue panel (Narrative.LAYER)
const PANEL_SCENE := "res://scenes/ui/narrative/NarrativeLog.tscn"
const SLIDE := 40.0   # it slides in from the right this far (px)
const SLIDE_IN := 0.22
const TEXT_SIZE := 13

@onready var _side: Control = $Side
@onready var _scroll: ScrollContainer = $Side/Col/Scroll
@onready var _entries: VBoxContainer = $Side/Col/Scroll/Entries

var _shown := 0                  # log entries already laid out
var _last_scene: Variant = null  # the scene the last heading was written for

static func show_log(host: Node) -> ModalPopup:
	var cl := CanvasLayer.new()
	cl.layer = LAYER
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	var p := (load(PANEL_SCENE) as PackedScene).instantiate() as NarrativeLog
	cl.add_child(p)
	host.get_tree().root.add_child(cl)
	host.get_viewport().gui_release_focus()   # keys must not reach a box under it (the City's name)
	return p

func _ready() -> void:
	_hero_close = $Side/Col/Head/Close
	_hero_close.pressed.connect(close)
	(($Side/Col/Head/Hero as HeroHeader).get_node("Title") as Label).autowrap_mode = TextServer.AUTOWRAP_OFF
	($Dim as Control).gui_input.connect(func(e: InputEvent) -> void:
		if dismissable and e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			close())
	_add_new()
	Narrative.log_changed.connect(_add_new)
	# in from the right
	var x := _side.position.x
	_side.position.x = x + SLIDE
	_side.modulate.a = 0.0
	var tw := _side.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_side, "position:x", x, SLIDE_IN)
	tw.tween_property(_side, "modulate:a", 1.0, SLIDE_IN)

func cancel_button() -> IconButton:
	return null

func confirm_button() -> IconButton:
	return null

## Lays out the entries not shown yet and goes to the newest.
func _add_new() -> void:
	var all: Array = GameState.narrative_log
	if all.is_empty() and _entries.get_child_count() == 0:
		_entries.add_child(_text("[color=#%s]Nothing has been said yet.[/color]" % UIStyle.hex(&"text_subtle")))
		return
	if _shown == 0 and _entries.get_child_count() > 0 and not all.is_empty():
		for c in _entries.get_children():   # the "nothing yet" note
			c.queue_free()
	if _shown > all.size():   # the log was trimmed (LOG_MAX): lay it out again
		for c in _entries.get_children():
			c.queue_free()
		_shown = 0
		_last_scene = null
	for i in range(_shown, all.size()):
		_add_entry(all[i] as Dictionary)
	_shown = all.size()
	_to_bottom.call_deferred()

func _to_bottom() -> void:
	await get_tree().process_frame   # once the new entries have their size
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)

func _add_entry(e: Dictionary) -> void:
	var scene := String(e.get("s", ""))
	if scene != _last_scene:
		var h := Label.new()
		h.text = "//  " + _scene_title(scene)
		h.theme_type_variation = &"SubLabel"
		_entries.add_child(h)
		_last_scene = scene
	var kind := String(e.get("k", "line"))
	var who := String(e.get("n", ""))
	var line := String(e.get("t", ""))
	if kind == "event":   # what the story did in the game
		_entries.add_child(_text("%s  [color=#%s]%s[/color]" % [UIIcons.bb("confirm", 12, UIStyle.color(&"good")),
			UIStyle.hex(&"good"), line]))
		return
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)
	var name_l := Label.new()
	name_l.theme_type_variation = &"HeaderLabel"
	if kind == "choice":
		name_l.text = "YOU"
		box.add_child(name_l)
		box.add_child(_text("[color=#%s]>  %s[/color]" % [UIStyle.hex(&"accent"), line]))
	else:
		name_l.text = "NARRATOR" if who == "" or who == "Narrator" else who.to_upper()
		box.add_child(name_l)
		box.add_child(_text(("[i]%s[/i]" % line) if name_l.text == "NARRATOR" else line))
	_entries.add_child(box)

func _text(bb: String) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.theme_type_variation = &"PopupBody"
	r.add_theme_font_size_override(&"normal_font_size", TEXT_SIZE)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.text = bb
	return r

## A scene's heading: an excavation's site by its name; else "opening_intro" →
## "Opening Intro".
static func _scene_title(id: String) -> String:
	if id == "":
		return "Remarks"
	var site := Excavations.find_site(id)
	if site != null:
		return site.display_name
	return id.replace("_", " ").capitalize()

func _process(delta: float) -> void:
	if _scroll == null or PadScheme.chord_held:
		return
	var sy := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	var ly := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var v := sy if absf(sy) > absf(ly) else ly
	if absf(v) > 0.2:
		_scroll.scroll_vertical += int(round(v * 520.0 * delta))

func _unhandled_input(event: InputEvent) -> void:
	if PadScheme.chord_held:
		return
	if event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		var jb := event as InputEventJoypadButton
		match jb.button_index:
			JOY_BUTTON_Y, JOY_BUTTON_B:
				get_viewport().set_input_as_handled()
				AudioManager.play("click")
				close()
				return
			JOY_BUTTON_DPAD_UP:
				if _scroll != null:
					_scroll.scroll_vertical = maxi(0, _scroll.scroll_vertical - 64)
				get_viewport().set_input_as_handled()
				return
			JOY_BUTTON_DPAD_DOWN:
				if _scroll != null:
					_scroll.scroll_vertical += 64
				get_viewport().set_input_as_handled()
				return
	super._unhandled_input(event)
