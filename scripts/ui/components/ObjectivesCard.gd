## The objectives card: a small card at the bottom-right, above the news bar,
## opened / closed by the flag button in that bar (NewsFeed.toggle_objectives,
## or O). Its owner fills `content` (the objective's name as a small hero, then
## its details) and sets `active` while it has something to show.
##
## Above the objective it shows NewsFeed's messages (hints, notices, toasts) in
## the same layout. The card with an objective hosts them; without one,
## NewsFeed's own `messages_only` card shows them in the same spot. A message
## opens the card even while the objective is hidden (the objective stays
## hidden then).
class_name ObjectivesCard
extends PanelContainer

const WIDTH := 300.0
## An objective's name as a hero: smaller than a world's name.
const HERO_SIZE := 22
const MARGIN_RIGHT := 12.0
const GAP_ABOVE_NEWS := 8.0
const FADE_SEC := 0.15
const FONT := preload("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf")
const TEXT_SIZE := 9
const GROUP := &"objectives_card"

var content: VBoxContainer = null
## The owner has an objective to show (the card still waits for the button).
var active := true:
	set(v):
		if active == v:
			return
		active = v
		_sync(false)
## The objective's name for the button's tooltip.
var tip_title := ""
## NewsFeed's card for messages when no card has an objective.
var messages_only := false

var _root: VBoxContainer = null
var _msg_box: VBoxContainer = null
var _msg_sep: HSeparator = null
var _msg_shown: Array = []   # serials of the messages on the card
var _fading := false

func _init() -> void:
	theme_type_variation = &"PopupCard"
	add_to_group(GROUP)
	custom_minimum_size = Vector2(WIDTH, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 8)
	add_child(_root)
	_msg_box = VBoxContainer.new()
	_msg_box.add_theme_constant_override("separation", 8)
	_root.add_child(_msg_box)
	_msg_sep = HSeparator.new()
	_root.add_child(_msg_sep)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	_root.add_child(content)

func _ready() -> void:
	NewsFeed.objectives_changed.connect(func(_open: bool) -> void: _sync(true))
	NewsFeed.messages_changed.connect(_rebuild_messages)
	_rebuild_messages()
	_sync(false)
	_place()

func _exit_tree() -> void:
	if not messages_only:
		NewsFeed.set_objectives_source(get_instance_id(), false)

func _process(_delta: float) -> void:
	if not messages_only:
		NewsFeed.set_objectives_source(get_instance_id(), active, tip_title)
	_rebuild_messages()
	_sync(false)
	_place()

## The card with an objective shows the messages; NewsFeed's own card only
## while no card has one.
func _hosts_messages() -> bool:
	if not NewsFeed.messages_allowed():
		return false
	if messages_only:
		return not NewsFeed.has_objective_card()
	return active

func _objective_shown() -> bool:
	return active and not messages_only and NewsFeed.objectives_open and not NewsFeed.on_main_menu()

func _shown() -> bool:
	return _objective_shown() or (_hosts_messages() and not NewsFeed.messages.is_empty())

## Opening plays the side panels' cyber entrance; closing fades out quickly.
func _sync(animate: bool) -> void:
	if not is_inside_tree():
		return
	var obj := _objective_shown()
	var msgs := _msg_box.get_child_count() > 0
	if content.visible != obj:
		content.visible = obj
	_msg_box.visible = msgs
	_msg_sep.visible = obj and msgs
	var want := _shown()
	if _fading and not want:
		return   # the fade-out finishes first
	if want == visible and modulate.a > 0.99:
		return
	_fading = false
	if want:
		visible = true
		modulate.a = 1.0
		if animate:
			reveal()
	elif animate and visible:
		_fading = true
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, FADE_SEC)
		tw.tween_callback(func() -> void:
			if not _fading:
				return   # opened again meanwhile
			_fading = false
			if not _shown():
				visible = false
			modulate.a = 1.0)
	else:
		visible = false

## Plays the entrance again, e.g. when the objective changes.
func reveal() -> void:
	if visible:
		CyberReveal.play(self)

# ── Messages ──────────────────────────────────────────────────────────────────
## Builds the message blocks again; a message that just came in plays the
## entrance (on its own block when the objective is on the card too).
func _rebuild_messages() -> void:
	var list: Array = NewsFeed.messages if _hosts_messages() else []
	var serials: Array = list.map(func(m: Dictionary) -> int: return int(m["serial"]))
	if serials == _msg_shown:
		return
	var was_open := visible and _msg_box.get_child_count() > 0
	var fresh: Control = null
	for c in _msg_box.get_children():
		_msg_box.remove_child(c)
		c.queue_free()
	for m in list:
		var block := _message_block(m)
		_msg_box.add_child(block)
		if not _msg_shown.has(int(m["serial"])) and bool(m.get("fresh", true)) and fresh == null:
			fresh = block
	_msg_shown = serials
	_sync(false)
	if fresh != null and visible:
		if was_open or _objective_shown():
			CyberReveal.play(fresh)
		else:
			CyberReveal.play(self)

func _message_block(m: Dictionary) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(HeroHeader.create(String(m["caption"]), String(m["title"]), HERO_SIZE))
	if String(m["body"]) != "":
		v.add_child(_text(String(m["body"]), &"text_subtle"))
	if String(m["extra"]) != "":
		v.add_child(_text(String(m["extra"]), StringName(m["extra_color"])))
	if String(m["action"]) != "":
		var btn := IconButton.create(String(m["action"]), String(m["action_icon"]), IconButton.Variant.POSITIVE)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var id := String(m["id"])
		var cb: Callable = m["on_action"]
		btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
		btn.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		btn.pressed.connect(func() -> void:
			CursorManager.set_state(CursorManager.State.NORMAL)
			AudioManager.play("click")
			NewsFeed.clear_message(id)
			if cb.is_valid():
				cb.call())
		v.add_child(btn)
	return v

func _text(t: String, color: StringName) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", TEXT_SIZE)
	l.add_theme_color_override("font_color", UIStyle.color(color))
	return l

## Bottom-right corner, just above the news bar (or the screen's bottom).
func _place() -> void:
	var vp := get_viewport_rect().size
	var bottom := vp.y
	var news := get_tree().get_first_node_in_group(&"news_panel") as Control
	if news != null and news.is_visible_in_tree():
		bottom = news.get_global_rect().position.y
	reset_size()
	global_position = Vector2(vp.x - size.x - MARGIN_RIGHT, bottom - size.y - GAP_ABOVE_NEWS)
