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
## The last show_tip was refused (a locked tip under the mouse); its follow-up
## calls (set_title_icon …) are refused too.
var _ignored := false

## Where a locked tip stays open: the tip itself, a small area where the mouse
## rested when it locked, and the corridor between them.
func _lock_zone() -> Rect2:
	var tip := (_panel.get_parent() as Control).get_global_rect().grow(8.0)
	var spot := Rect2(_lock_at - Vector2(28, 28), Vector2(56, 56))
	var zone := tip.merge(spot)
	for n in _nests:
		if n.visible:
			zone = zone.merge(n.get_global_rect().grow(8.0))   # reading a nested term
	return zone

# ── Nested tips (playtest 31.10) ──────────────────────────────────────────────
## A [url] term (Glossary) in a locked tip opens a small tip of its own beside
## the mouse; a term inside that one opens the next, and so on (a stack). Each
## stays while the mouse is on its term or on it.
const NEST_MAX := 4
var _nests: Array[PanelContainer] = []
var _nest_hide := 0.0
var _nest_hide_from := 0   # the first level the running hide timer would close

func _nest_at(level: int) -> PanelContainer:
	while _nests.size() <= level:
		var lv := _nests.size()
		var p := PanelContainer.new()
		p.theme_type_variation = &"TooltipPanel"
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.visible = false
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(vb)
		var head := HBoxContainer.new()   # title │ corner (an entry's third part)
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(head)
		var t := Label.new()
		t.theme_type_variation = &"HeaderLabel"
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(t)
		var corner := RichTextLabel.new()
		corner.bbcode_enabled = true
		corner.fit_content = true
		corner.scroll_active = false
		corner.autowrap_mode = TextServer.AUTOWRAP_OFF
		corner.theme_type_variation = &"TooltipBody"
		corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		corner.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(corner)
		var b := RichTextLabel.new()
		b.bbcode_enabled = true
		b.fit_content = true
		b.scroll_active = false
		b.theme_type_variation = &"TooltipBody"
		b.mouse_filter = Control.MOUSE_FILTER_PASS   # its own terms open the next level
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(240, 0)
		b.meta_hover_started.connect(func(m: Variant) -> void: _show_nest(lv + 1, String(m)))
		b.meta_hover_ended.connect(func(_m: Variant) -> void: _leave_term(lv + 1))
		vb.add_child(b)
		add_child(p)
		_nests.append(p)
	return _nests[level]

func _on_term_hovered(term: String) -> void:
	_show_nest(0, term)

func _on_term_left(_term: String) -> void:
	_leave_term(0)

func _show_nest(level: int, term: String) -> void:
	var e := Glossary.entry(term)
	if e.is_empty() or not _locked or level >= NEST_MAX:
		return
	var p := _nest_at(level)
	var vb := p.get_child(0)
	var head := vb.get_child(0)
	(head.get_child(0) as Label).text = String(e[0]).to_upper()
	(head.get_child(1) as RichTextLabel).text = String(e[2]) if e.size() > 2 else ""
	(vb.get_child(1) as RichTextLabel).text = String(e[1])
	_hide_nests_from(level + 1)
	p.visible = true
	p.reset_size()
	var m := get_viewport().get_mouse_position()
	var vp := get_viewport().get_visible_rect().size
	var sz := p.get_combined_minimum_size()
	var pos := m + Vector2(14, 10)
	if pos.x + sz.x > vp.x - 4.0:
		pos.x = m.x - sz.x - 14.0
	pos.y = clampf(pos.y, 4.0, maxf(4.0, vp.y - sz.y - 4.0))
	p.position = pos
	_nest_hide = 0.0

func _leave_term(level: int) -> void:
	_nest_hide = 0.25   # time to reach the nested tip
	_nest_hide_from = level

## The deepest open nested tip under the mouse, -1 when none.
func _nest_under_mouse() -> int:
	var m := get_viewport().get_mouse_position()
	for i in range(_nests.size() - 1, -1, -1):
		if _nests[i].visible and _nests[i].get_global_rect().has_point(m):
			return i
	return -1

func _hide_nests_from(level: int) -> void:
	for i in range(level, _nests.size()):
		_nests[i].visible = false

func _hide_nest() -> void:
	_hide_nests_from(0)
	_nest_hide = 0.0

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
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(_draw_ring)
	add_child(_ring)
	_ring.visible = false
	_panel.term_hovered.connect(_on_term_hovered)
	_panel.term_left.connect(_on_term_left)

## The lock charge as an outline filling around the card, clockwise from its
## top-left corner (playtest 31.10: in place of a ring in the corner); the
## whole frame turns gold once locked. `_ring` covers the card's rect.
func _draw_ring() -> void:
	var k := 1.0 if _locked else clampf((_charge - LOCK_DELAY) / LOCK_SEC, 0.0, 1.0)
	if k <= 0.0:
		return
	# follows the card's rounded frame (its stylebox radius), never sharp corners
	var sb := _panel.get_theme_stylebox("panel") as StyleBoxFlat
	var rad := float(sb.corner_radius_top_left) if sb != null else 3.0
	var path := _rounded_path(Rect2(Vector2(1, 1), _ring.size - Vector2(2, 2)), rad)
	var total := 0.0
	for i in path.size() - 1:
		total += path[i].distance_to(path[i + 1])
	var left := k * total
	var pts := PackedVector2Array([path[0]])
	for i in path.size() - 1:
		var seg := path[i].distance_to(path[i + 1])
		if left >= seg:
			pts.append(path[i + 1])
			left -= seg
		else:
			pts.append(path[i].lerp(path[i + 1], left / maxf(seg, 0.001)))
			break
	_ring.draw_polyline(pts, Color(1.0, 0.85, 0.40, 0.95) if _locked else Color(0.65, 0.85, 1.0, 0.85), 2.0, true)

## A rounded rectangle as a closed point path, clockwise from the top-left
## edge's start.
static func _rounded_path(r: Rect2, rad: float) -> PackedVector2Array:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var centres := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad),
		Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	pts.append(Vector2(r.position.x + rad, r.position.y))
	for c in 4:
		var a0 := -PI * 0.5 + c * PI * 0.5
		for s in 5:
			var a := a0 + PI * 0.5 * float(s) / 4.0
			pts.append((centres[c] as Vector2) + Vector2(cos(a), sin(a)) * rad)
	pts.append(Vector2(r.position.x + rad, r.position.y))
	return pts

## Lays the outline over the card where it is now.
func _place_ring() -> void:
	var r := _panel.get_global_rect()
	_ring.position = r.position
	_ring.size = r.size
	_ring.queue_redraw()

func _unlock() -> void:
	_locked = false
	_charge = 0.0
	_since_lock = 0.0
	_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.set_terms_active(false)
	_hide_nest()

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
		_place_ring()
		if _nest_hide > 0.0:
			_nest_hide -= delta
			if _nest_hide <= 0.0:
				# keep what the mouse reached; close the levels past it
				_hide_nests_from(maxi(_nest_hide_from, _nest_under_mouse() + 1))
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
		_panel.set_terms_active(true)   # its underlined terms open nested tips now
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
	_ring.visible = _locked or _charge > LOCK_DELAY   # nothing before the charge starts
	_place_ring.call_deferred()   # after this frame's layout puts the card
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
	# a locked tip keeps the floor only while the mouse is ON it (reading or
	# pointing at it); any other control takes over as usual — a neighbour's
	# tip opens at once. Its own owner may still update it (same title).
	_ignored = _locked and _visible and title.to_upper() != _panel.title \
		and (_panel.get_parent() as Control).get_global_rect().grow(6.0).has_point(get_viewport().get_mouse_position())
	if _ignored:
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
	_panel.set_footer("", "")
	_panel.set_corner("")
	_panel.set_detail("")

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

## Header's top-right corner in BBCode (stored / max …); call after show_tip.
func set_corner(c: String) -> void:
	if _ignored:
		return
	_panel.set_corner(c)

## A block under the body, behind a separator (income lines …); call after show_tip.
func set_detail(d: String) -> void:
	if _ignored:
		return
	_panel.set_detail(d)

## Bottom row in BBCode: `left` (e.g. what it makes) and `right` (the cost,
## bottom-right corner); call after show_tip, like set_title_icon.
func set_footer(left: String, right: String) -> void:
	if _ignored:
		return
	_panel.set_footer(left, right)

## Icon before the title (UIIcons name or resource id); call after show_tip.
func set_title_icon(icon_name: String) -> void:
	if _ignored:
		return   # the show_tip it belongs to didn't take
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
