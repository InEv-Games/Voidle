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
	_font = load("res://Fonts/Orbitron-VariableFont_wght.ttf") as Font

	# click anywhere outside closes the menu
	var backdrop := Control.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			close())
	add_child(backdrop)

	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.12, 0.96)
	sb.border_color = Color(0.30, 0.42, 0.80, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 4; sb.content_margin_right = 4
	sb.content_margin_top = 6;  sb.content_margin_bottom = 4
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.custom_minimum_size = Vector2(200, 0)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	_panel.add_child(box)

	box.add_child(_padded(_label(title, 10, Color(0.85, 0.88, 1.0))))
	if subtitle != "":
		box.add_child(_padded(_label(subtitle, 7, Color(0.48, 0.55, 0.78))))
	var sep := HSeparator.new()
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.25, 0.32, 0.55, 0.45)
	sep_s.content_margin_top = 1
	sep.add_theme_stylebox_override("separator", sep_s)
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

func _row(c: GameCommand) -> Control:
	var blocked := c.can_execute()
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 24)
	var hov := StyleBoxFlat.new()
	hov.bg_color = Color(0.16, 0.22, 0.42, 0.75) if blocked == "" else Color(0.12, 0.12, 0.18, 0.6)
	hov.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", hov)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 8; row.offset_right = -8
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)
	var col := c.color if blocked == "" else Color(0.42, 0.45, 0.56)
	if c.icon != "":
		var ic := _label(c.icon, 9, col)
		ic.custom_minimum_size = Vector2(14, 0)
		row.add_child(ic)
	var name_lbl := _label(c.label, 8, col)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)
	if c.cost != "":
		row.add_child(_label(c.cost, 7, Color(0.95, 0.85, 0.45) if blocked == "" else Color(0.45, 0.42, 0.35)))

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
