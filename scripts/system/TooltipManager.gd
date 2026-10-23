extends CanvasLayer

## Layout: scenes/ui/components/TooltipView.tscn (a TooltipCard + a side panel).
## Look: TooltipPanel / TooltipSubPanel / TooltipBody in voidle_theme.tres.
const VIEW_SCENE := "res://scenes/ui/components/TooltipView.tscn"

var _panel:      TooltipCard
var _visible:    bool  = false
var _sub_panel:  PanelContainer
var _sub_lbl:    RichTextLabel
var _cost_lbl:   Label
var _cost_color: Color
var _hide_timer: float = 0.0
var _hbox:       HBoxContainer
var _flipped:    bool = false

func _ready() -> void:
	layer = 300
	_hbox = (load(VIEW_SCENE) as PackedScene).instantiate() as HBoxContainer
	_panel     = _hbox.get_node("Card")
	_sub_panel = _hbox.get_node("SubPanel")
	_sub_lbl   = _hbox.get_node("SubPanel/Body")
	_cost_lbl  = _panel.get_node("VBox/CostBox/Cost/Value")
	_cost_color = _cost_lbl.get_theme_color("font_color")
	# game tooltips are laid out with explicit line breaks: grow to the text, don't wrap
	(_panel.get_node("VBox/Body") as RichTextLabel).autowrap_mode = TextServer.AUTOWRAP_OFF
	_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_panel.visible = false
	_hbox.visible = false
	add_child(_hbox)

func _process(delta: float) -> void:
	if _hide_timer > 0.0:
		_hide_timer -= delta
		if _hide_timer <= 0.0:
			_panel.get_parent().visible = false
			_panel.visible = false
			_sub_panel.visible = false
			_visible       = false
		return
	if not _visible:
		return
	# get_combined_minimum_size() is synchronous — no frame delay needed
	var root_node := _panel.get_parent() as Control
	# Make sure _panel is visible so it contributes to size
	_panel.visible = true
	var sz: Vector2 = root_node.get_combined_minimum_size()
	var pw: float = sz.x
	var ph: float = sz.y
	if pw <= 1.0 or ph <= 1.0:
		return
	var mouse := get_viewport().get_mouse_position()
	var vp    := get_viewport().get_visible_rect().size
	var pos := mouse + Vector2(10, -ph - 8.0)
	var should_flip := pos.x + pw > vp.x
	if should_flip:
		# Flip to the left of the mouse so it doesn't block clicks!
		pos.x = mouse.x - pw - 10.0
	if pos.x < 4.0:       pos.x = 4.0
	if pos.y < 4.0:       pos.y = mouse.y + 14.0
	root_node.position = pos
	root_node.visible  = true
	# When flipped left: sub_panel (small) goes to left, _panel (big) to right
	if should_flip != _flipped:
		_flipped = should_flip
		if should_flip:
			_hbox.move_child(_sub_panel, 0)
		else:
			_hbox.move_child(_panel, 0)

## Show a tooltip.
## body: String or Array — Array elements may be String or ImageTexture (rendered inline).
## cost: String, Array[String], or Array[Variant] mixing strings and textures.
## Show a tooltip.
## body: String or Array — Array elements may be String or Texture2D (rendered inline).
## cost: String, Array[String], or Array[Variant] mixing strings and textures.
func show_tip(title: String, body = "", cost = "", sub_body = "") -> void:
	_panel.title = title.to_upper()
	_panel.icon_name = ""
	if body is Array:
		_panel.set_body_parts(body as Array)
	else:
		_panel.set_body_parts([String(body)] if String(body) != "" else [])

	var cost_lines: Array[String] = []
	if cost is String and (cost as String) != "":
		cost_lines.append(cost as String)
	elif cost is Array:
		for item in (cost as Array):
			if item is String and (item as String) != "":
				cost_lines.append(item as String)
	_panel.cost = "\n".join(cost_lines)

	_panel.visible = true
	_hbox.visible = false

	_sub_lbl.clear()
	var sub_parts: Array = sub_body if sub_body is Array else ([sub_body] if String(sub_body) != "" else [])
	for part in sub_parts:
		if part is String:
			_sub_lbl.append_text(part as String)
		elif part is Texture2D:
			_sub_lbl.add_image(part as Texture2D, 13, 13)
	_sub_panel.visible = not sub_parts.is_empty()

	_hide_timer = 0.0
	_visible    = true

## Icon before the title (UIIcons name or resource id); call after show_tip.
func set_title_icon(icon_name: String) -> void:
	_panel.icon_name = icon_name

func set_cost_color(c: Color) -> void:
	_cost_lbl.add_theme_color_override("font_color", c)

func hide_tip() -> void:
	_cost_lbl.add_theme_color_override("font_color", _cost_color)  # back to the scene's colour
	_hide_timer = 0.18   # 180 ms grace period before actually hiding
