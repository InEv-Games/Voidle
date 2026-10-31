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

## Locking (playtest 30.10): a tip shown for LOCK_SEC stops following the mouse
## (a ring in its corner fills meanwhile) and stays while the mouse is on it, so
## it can be read and pointed at; leaving it closes it. LOCK_GRACE lets the
## mouse travel from the hovered control onto the tip.
## A resting mouse waits LOCK_DELAY before anything shows, then the ring fills
## over LOCK_SEC (playtest 31.10: quick checks must never lock).
const LOCK_DELAY := 1.5
const LOCK_SEC := 3.0
## Widest a tooltip's text may run (px); longer lines wrap (playtest 31.10).
const MAX_TEXT_W := 360.0
const LOCK_GRACE := 0.15
var _charge := 0.0
var _locked := false
var _since_lock := 0.0
var _ring: Control = null
var _last_mouse := Vector2.ZERO
var _lock_at := Vector2.ZERO

## Where a locked tip stays open: the tip itself, a small area where the mouse
## rested when it locked, and the corridor between them.
func _lock_zone() -> Rect2:
	var tip := (_panel.get_parent() as Control).get_global_rect().grow(8.0)
	var spot := Rect2(_lock_at - Vector2(28, 28), Vector2(56, 56))
	return tip.merge(spot)

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
	_ring = Control.new()
	_ring.custom_minimum_size = Vector2(12, 12)
	_ring.size = Vector2(12, 12)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(_draw_ring)
	add_child(_ring)
	_ring.visible = false

func _draw_ring() -> void:
	var k := 1.0 if _locked else clampf((_charge - LOCK_DELAY) / LOCK_SEC, 0.0, 1.0)
	var c := Vector2(6, 6)
	_ring.draw_arc(c, 4.5, 0.0, TAU, 20, Color(1, 1, 1, 0.18), 1.5, true)
	if k > 0.0:
		_ring.draw_arc(c, 4.5, -PI * 0.5, -PI * 0.5 + TAU * k, 24,
			Color(1.0, 0.85, 0.40, 0.95) if _locked else Color(0.65, 0.85, 1.0, 0.85), 1.5, true)

func _unlock() -> void:
	_locked = false
	_charge = 0.0
	_since_lock = 0.0
	_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if _hide_timer > 0.0:
		_hide_timer -= delta
		if _hide_timer <= 0.0:
			_panel.get_parent().visible = false
			_panel.visible = false
			_sub_panel.visible = false
			_visible       = false
			_ring.visible  = false
			_unlock()
		return
	if not _visible:
		return
	var root_now := _panel.get_parent() as Control
	if _locked:
		# stays put while the mouse is on it, still where it locked (on the
		# control it explains) or on the way between the two; closes once the
		# mouse is elsewhere
		_since_lock += delta
		root_now.size = root_now.get_combined_minimum_size()   # content may change (Shift …)
		if not _lock_zone().has_point(get_viewport().get_mouse_position()) and _since_lock > LOCK_GRACE:
			_hide_timer = 0.12
		return
	# only a resting mouse charges the lock (tips that follow a moving mouse —
	# the lens, the news — never lock under it)
	var m := get_viewport().get_mouse_position()
	if m.distance_to(_last_mouse) > 3.0:
		_charge = 0.0
	_last_mouse = m
	_charge += delta
	if _charge >= LOCK_DELAY + LOCK_SEC:
		_locked = true
		_since_lock = 0.0
		_lock_at = m
		_hbox.mouse_filter = Control.MOUSE_FILTER_STOP   # the mouse may rest on it
	_ring.queue_redraw()
	# get_combined_minimum_size() is synchronous — no frame delay needed
	var root_node := _panel.get_parent() as Control
	# Make sure _panel is visible so it contributes to size
	_panel.visible = true
	var sz: Vector2 = root_node.get_combined_minimum_size()
	root_node.size = sz   # shrinks with shorter content (it is updated in place now)
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
	_ring.visible = _locked or _charge > LOCK_DELAY   # no ring during the first second
	_ring.position = pos + Vector2(_panel.size.x - 16.0, 4.0) if not _flipped \
		else pos + Vector2(root_node.size.x - 16.0, 4.0)
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
	# a locked tip keeps the floor while the mouse is in its zone; its own
	# owner may still update it (same title — e.g. Shift changing an amount)
	if _locked and _visible and _lock_zone().has_point(get_viewport().get_mouse_position()) \
			and title.to_upper() != _panel.title:
		return
	if title.to_upper() != _panel.title:
		_unlock()
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
	# hide only for the first frame of a new tip (it is sized then shown);
	# a tip already on screen is updated in place — no flicker as it changes
	if not _visible or _hide_timer > 0.0 and not _hbox.visible:
		_hbox.visible = false

	_sub_lbl.clear()
	var sub_parts: Array = sub_body if sub_body is Array else ([sub_body] if String(sub_body) != "" else [])
	for part in sub_parts:
		if part is String:
			_sub_lbl.append_text(part as String)
		elif part is Texture2D:
			_sub_lbl.add_image(part as Texture2D, 13, 13)
	_sub_panel.visible = not sub_parts.is_empty()
	_limit_width(_panel.get_node("VBox/Body") as RichTextLabel)
	_limit_width(_sub_lbl)

	_hide_timer = 0.0
	_visible    = true

## Short text keeps its own width (lines are broken by hand); text whose
## longest line runs past MAX_TEXT_W wraps at that width instead.
func _limit_width(l: RichTextLabel) -> void:
	var font := l.get_theme_font("normal_font")
	var fsize := l.get_theme_font_size("normal_font_size")
	var widest := 0.0
	for line: String in l.get_parsed_text().split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x)
	if widest > MAX_TEXT_W:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = MAX_TEXT_W
	else:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.custom_minimum_size.x = 0.0

## Icon before the title (UIIcons name or resource id); call after show_tip.
func set_title_icon(icon_name: String) -> void:
	_panel.icon_name = icon_name

## Title of the tip on screen (upper-cased), "" when none is shown.
func shown_title() -> String:
	return _panel.title if _visible else ""

func set_cost_color(c: Color) -> void:
	_cost_lbl.add_theme_color_override("font_color", c)

func hide_tip() -> void:
	if _locked and _visible:
		return   # a locked tip closes when the mouse leaves it (see _process)
	_cost_lbl.add_theme_color_override("font_color", _cost_color)  # back to the scene's colour
	_hide_timer = 0.18   # 180 ms grace period before actually hiding
