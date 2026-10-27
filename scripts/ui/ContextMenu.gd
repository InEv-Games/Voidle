## Right-click context menu: a title, then one row per GameCommand. Blocked
## commands stay listed, greyed out, with the reason in their tooltip.
## Closes on a pick, a click outside, or ESC. Only one is open at a time.
##   ContextMenu.open(self, "Riva", "City · Lv 2", commands, mouse_pos)
class_name ContextMenu
extends CanvasLayer

static var _current: ContextMenu = null

var _panel: PanelContainer = null
var _font: Font = null

static func open(host: Node, title: String, subtitle: String, commands: Array[GameCommand],
		screen_pos: Vector2) -> ContextMenu:
	close_current()
	if commands.is_empty():
		return null
	var m := ContextMenu.new()
	host.get_tree().root.add_child(m)
	m._build(title, subtitle, commands, screen_pos)
	_current = m
	return m

static func close_current() -> void:
	if _current != null and is_instance_valid(_current):
		_current.close()
	_current = null

static func is_open() -> bool:
	return _current != null and is_instance_valid(_current)

func close() -> void:
	TooltipManager.hide_tip()
	CursorManager.set_state(CursorManager.State.NORMAL)
	queue_free()

func _build(title: String, subtitle: String, commands: Array[GameCommand], screen_pos: Vector2) -> void:
	layer = 210
	_font = load("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf") as Font

	# click anywhere outside closes the menu
	var backdrop := Control.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			close())
	add_child(backdrop)

	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"TooltipPanel"   # voidle_theme.tres
	_panel.custom_minimum_size = Vector2(200, 0)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	_panel.add_child(box)

	box.add_child(_padded(_label(title, 10, Color(0.85, 0.88, 1.0))))
	if subtitle != "":
		box.add_child(_padded(_label(subtitle, 7, Color(0.48, 0.55, 0.78))))
	var sep := HSeparator.new()
	box.add_child(sep)

	for c: GameCommand in commands:
		box.add_child(_row(c))

	# place at the cursor, kept inside the screen
	_panel.reset_size()
	await get_tree().process_frame
	if not is_instance_valid(_panel):
		return
	var vp := get_viewport().get_visible_rect().size
	var p := screen_pos + Vector2(4, 4)
	p.x = minf(p.x, vp.x - _panel.size.x - 6.0)
	p.y = minf(p.y, vp.y - _panel.size.y - 6.0)
	_panel.position = p.max(Vector2(6, 6))

## Command id prefix -> UIIcons name for the row's icon cell.
const ROW_ICONS := [
	["open_city", "city"], ["open_capital", "capital"], ["open_parent_city", "city"], ["focus_city", "city"],
	["found_city", "city"], ["open_district", "district"], ["add_district", "district"], ["open_orbit", "rocket"],
	["rocket_target", "rocket"], ["view_planet", "planet"], ["planet_overview", "planet"],
	["star_system", "explore"], ["enter_system", "explore"], ["galaxy_view", "explore"],
	["cancel", "cancel"], ["demolish", "danger"], ["clear", "negative"], ["remove_", "negative"],
	["reset", "downgrade"], ["move", "move"], ["research", "research"],
]
## Destructive commands are Negative rows; everything else Default.
const NEGATIVE_IDS := ["demolish", "clear", "remove_", "reset"]

static func _row_icon(id: String) -> String:
	for pair: Array in ROW_ICONS:
		if id.begins_with(pair[0]):
			return pair[1]
	return "upgrade" if id.contains("level_up") else "unknown"

## Menu row: icon │ LABEL ........ cost (the design system's icon-left button).
func _row(c: GameCommand) -> Control:
	var blocked := c.can_execute()
	var v := IconButton.Variant.DEFAULT
	for n: String in NEGATIVE_IDS:
		if c.id.begins_with(n):
			v = IconButton.Variant.NEGATIVE
	var btn := IconButton.create(c.label.to_upper(), _row_icon(c.id), v, c.cost)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = blocked != ""

	var tip := c.tooltip
	if blocked != "":
		tip = (tip + "\n\n" if tip != "" else "") + "[color=#e06060]➡ %s[/color]" % blocked
	btn.mouse_entered.connect(func() -> void:
		AudioManager.play("hover")
		CursorManager.set_state(CursorManager.State.POINTER if blocked == "" else CursorManager.State.NORMAL)
		if tip != "":
			TooltipManager.show_tip(c.label, tip))
	btn.mouse_exited.connect(func() -> void:
		TooltipManager.hide_tip()
		CursorManager.set_state(CursorManager.State.NORMAL))
	btn.pressed.connect(func() -> void:
		if c.can_execute() != "":   # re-check: things may have changed while open
			AudioManager.play("error")
			return
		AudioManager.play("click")
		close()
		c.execute())
	return btn

func _label(txt: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _font:
		l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _padded(c: Control) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 8)
	m.add_theme_constant_override("margin_right", 8)
	m.add_child(c)
	return m

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
