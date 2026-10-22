## ConfirmPanel — a small modal "are you sure?" box for actions that can't be
## undone (demolish, reset …). Shows a preview text and runs `on_confirm` only
## when the player confirms; Esc or a click outside cancels.
##   ConfirmPanel.ask(self, "Demolish Alpha?", preview_text, "DEMOLISH", func() -> void: …)
class_name ConfirmPanel
extends Control

var _on_confirm: Callable

static func ask(host: Node, title: String, body: String, confirm_label: String, on_confirm: Callable,
		danger: bool = true) -> ConfirmPanel:
	var layer := CanvasLayer.new()
	layer.layer = 235
	var p := ConfirmPanel.new()
	p._on_confirm = on_confirm
	layer.add_child(p)
	host.get_tree().root.add_child(layer)
	p._build(title, body, confirm_label, danger)
	return p

func _build(title: String, body: String, confirm_label: String, danger: bool) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var font := load("res://Fonts/Orbitron-VariableFont_wght.ttf") as Font
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_close())
	add_child(dim)
	var panel := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.06, 0.11, 0.97)
	s.border_color = Color(0.85, 0.35, 0.3, 0.7) if danger else Color(0.28, 0.42, 0.72, 0.6)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", s)
	panel.custom_minimum_size = Vector2(420, 0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var t := Label.new()
	t.text = title
	if font: t.add_theme_font_override("font", font)
	t.add_theme_font_size_override("font_size", 13)
	t.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6) if danger else Color(0.65, 0.85, 1.0))
	v.add_child(t)
	var b := RichTextLabel.new()
	b.bbcode_enabled = true
	b.fit_content = true
	b.scroll_active = false
	b.custom_minimum_size = Vector2(420, 0)
	b.add_theme_font_size_override("normal_font_size", 11)
	b.text = body
	v.add_child(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var cancel := Button.new()
	cancel.visible = _on_confirm.is_valid()   # an info box has only its OK button
	cancel.text = "CANCEL"
	if font: cancel.add_theme_font_override("font", font)
	cancel.add_theme_font_size_override("font_size", 10)
	cancel.focus_mode = Control.FOCUS_NONE
	cancel.pressed.connect(_close)
	row.add_child(cancel)
	var ok := Button.new()
	ok.text = confirm_label
	if font: ok.add_theme_font_override("font", font)
	ok.add_theme_font_size_override("font_size", 10)
	ok.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45) if danger else Color(0.6, 1.0, 0.7))
	ok.focus_mode = Control.FOCUS_NONE
	ok.pressed.connect(func() -> void:
		var cb := _on_confirm
		_close()
		if cb.is_valid():
			cb.call())
	row.add_child(ok)
	# centre once the size is known
	panel.reset_size()
	panel.position = (get_viewport_rect().size - panel.get_combined_minimum_size()) * 0.5

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()
