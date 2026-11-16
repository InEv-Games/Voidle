## QuickRadial — controller Quick Command wheel (Planet view).
## PadScheme opens it on View / Select. Either stick points at a slice; the
## pick runs on releasing Select (hold + flick) or on A when it stays pinned
## open after a tap. Mouse hover / click work too. Drawn in the project
## theme's Palette colours.
class_name QuickRadial
extends Control

signal picked(act: String)
signal dismissed

const R_OUT := 300.0      # wide ring around the planet …
const THICK := 38.0       # … but a thin band; the middle stays see-through
const ICON_PX := 20.0
const STICK_MIN := 0.5
const SHOW_DELAY := 0.1   # quick Select + button chords never flash the wheel

## Each item: {act, label, icon, enabled} (a "badge" key is ignored)
var items: Array[Dictionary] = []
var center := Vector2.ZERO
var hovered := -1

var _fade := 0.0
var _closing := false
var _scene: Node = null   # the view it opened over; it goes when that view does

static func open(parent: Node, at: Vector2, entries: Array[Dictionary], layer: int) -> QuickRadial:
	var cl := CanvasLayer.new()
	cl.layer = layer
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	parent.add_child(cl)
	var r := QuickRadial.new()
	r.items = entries
	r.center = at
	r._scene = r_scene(parent)
	cl.add_child(r)
	return r

static func r_scene(n: Node) -> Node:
	return n.get_tree().current_scene if n.is_inside_tree() else null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_interval(SHOW_DELAY)
	tw.tween_method(func(v: float) -> void:
		_fade = v
		queue_redraw(), 0.0, 1.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

## Inner / outer radius: as wide as R_OUT, but always on screen.
func _radii() -> Vector2:
	var ro := minf(R_OUT, minf(size.x, size.y) * 0.5 - 18.0)
	return Vector2(ro - THICK, ro)

func _on_ring(d: Vector2) -> bool:
	var rr := _radii()
	return d.length() >= rr.x - 24.0 and d.length() <= rr.y + 24.0

## Index of the slice a direction (screen space, y down) points at.
func _slice_for(dir: Vector2) -> int:
	var n := items.size()
	if n == 0:
		return -1
	var step := TAU / float(n)
	# 0 = straight up, increasing clockwise
	var a := fposmod(atan2(dir.x, -dir.y) + step * 0.5, TAU)
	return int(a / step) % n

func _slice_angle(i: int) -> float:
	# screen angle (0 = right, clockwise) of slice i's middle
	return -PI * 0.5 + TAU * float(i) / float(maxi(items.size(), 1))

func _process(_dt: float) -> void:
	if _closing:
		return
	if _scene != null and (not is_instance_valid(_scene) or get_tree().current_scene != _scene or get_tree().paused):
		dismissed.emit()
		return
	var l := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	var r := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	var s := l if l.length() >= r.length() else r
	if s.length() >= STICK_MIN:
		_set_hovered(_slice_for(s))

func _set_hovered(i: int) -> void:
	if i == hovered:
		return
	hovered = i
	if i >= 0:
		AudioManager.play("hover")
	queue_redraw()

func hovered_act() -> String:
	if hovered < 0 or hovered >= items.size():
		return ""
	return String(items[hovered]["act"])

func hovered_enabled() -> bool:
	return hovered >= 0 and hovered < items.size() and bool(items[hovered]["enabled"])

func _gui_input(event: InputEvent) -> void:
	if _closing:
		return
	if event is InputEventMouseMotion:
		var d := (event as InputEventMouseMotion).position - center
		_set_hovered(_slice_for(d) if _on_ring(d) else -1)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		accept_event()
		var mb := event as InputEventMouseButton
		var d := mb.position - center
		if mb.button_index == MOUSE_BUTTON_LEFT and _on_ring(d):
			_set_hovered(_slice_for(d))
			picked.emit(hovered_act())
		else:
			dismissed.emit()

func close() -> void:
	if _closing:
		return
	_closing = true
	var layer := get_parent()
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		_fade = minf(_fade, v)
		queue_redraw(), _fade, 0.0, 0.08)
	tw.tween_callback(func() -> void:
		if layer is CanvasLayer:
			layer.queue_free()
		else:
			queue_free())

# ── Drawing ──────────────────────────────────────────────────────────────────

func _arc_pts(r: float, a0: float, a1: float, seg: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in seg + 1:
		var a := lerpf(a0, a1, float(k) / float(seg))
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts

func _draw() -> void:
	if _fade <= 0.001:
		return
	var f := _fade
	var n := items.size()
	if n == 0:
		return
	var panel := UIStyle.color(&"panel_bg")
	var accent := UIStyle.color(&"accent")
	var text_c := UIStyle.color(&"text")
	var text_bright := UIStyle.color(&"text_bright")
	var muted := UIStyle.color(&"text_inactive")
	var font := get_theme_font(&"font", &"Label")
	var fs := get_theme_font_size(&"font_size", &"Label")

	# dim the world a little; the planet stays readable behind the wheel
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.18 * f))

	var step := TAU / float(n)
	var gap := 0.012
	var rr := _radii() * lerpf(0.92, 1.0, f)
	var ri := rr.x
	var ro := rr.y
	for i in n:
		var mid := _slice_angle(i)
		var a0 := mid - step * 0.5 + gap
		var a1 := mid + step * 0.5 - gap
		var it: Dictionary = items[i]
		var on := bool(it["enabled"])
		var hot := i == hovered
		var outer := _arc_pts(ro + (5.0 if hot else 0.0), a0, a1, 24)
		var inner := _arc_pts(ri, a1, a0, 24)
		var poly := outer.duplicate()
		poly.append_array(inner)
		var fill := Color(accent, 0.35) if hot else Color(panel, 0.80)
		draw_colored_polygon(poly, Color(fill, fill.a * f))
		var edge := poly.duplicate()
		edge.append(poly[0])
		draw_polyline(edge, Color(accent if hot else muted, (0.95 if hot else 0.35) * f), 1.5 if hot else 1.0, true)

		# just the icon on the band; the name shows in the middle
		var rm := (ri + ro) * 0.5 + (2.5 if hot else 0.0)
		var p := center + Vector2(cos(mid), sin(mid)) * rm
		var ic_col := text_bright if hot else (text_c if on else muted)
		if not on:
			ic_col.a *= 0.5
		var tex := UIIcons.get_icon(String(it["icon"]))
		if tex != null:
			var sz := Vector2(ICON_PX, ICON_PX)
			draw_texture_rect(tex, Rect2(p - sz * 0.5, sz), false, Color(ic_col, ic_col.a * f))

	# see-through middle: the pointed command's name over the planet, outlined
	var title := "QUICK"
	var sub := "Stick to aim"
	if hovered >= 0:
		title = String(items[hovered]["label"])
		sub = "" if bool(items[hovered]["enabled"]) else "Locked"
	_draw_centered(font, title, center + Vector2(0, -2), fs + 4, Color(text_bright, f), ri * 1.4)
	if sub != "":
		_draw_centered(font, sub, center + Vector2(0, fs + 6), fs - 2, Color(text_c, 0.85 * f), ri * 1.4)

func _draw_centered(font: Font, s: String, at: Vector2, fsz: int, col: Color, max_w: float) -> void:
	var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
	var k := fsz
	while sz.x > max_w and k > 8:
		k -= 1
		sz = font.get_string_size(s, HORIZONTAL_ALIGNMENT_CENTER, -1, k)
	var pos := at + Vector2(-sz.x * 0.5, 0)
	draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, -1, k, 4, Color(0, 0, 0, 0.75 * col.a))
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_CENTER, -1, k, col)
