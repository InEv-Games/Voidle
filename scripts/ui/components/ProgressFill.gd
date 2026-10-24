## Design-system progress: the host element's own background fills left →
## right with a gradient (faint at the start, strong at the leading edge)
## instead of a separate bar. Drawn over the host's panel / button box and
## under its content, so labels stay on top and readable.
##   ProgressFill.attach(card, UIStyle.color(&"good")).progress = 0.4
##   ProgressFill.attach(btn, col, func() -> float: return pp.upgrade_progress, true)
## Lives as an internal child, so containers don't lay it out.
@tool
class_name ProgressFill
extends Control

## 0..1; below 0 hides the fill.
@export_range(-1.0, 1.0) var progress: float = -1.0:
	set(v): progress = v; queue_redraw()
@export var color: Color = Color(0.137, 0.725, 0.906):
	set(v): color = v; queue_redraw()
## Crawling diagonal stripes over the gradient: the look for anything being
## built or levelled.
@export var striped: bool = false:
	set(v): striped = v; set_process(striped or source.is_valid()); queue_redraw()
## Polled every frame when set (returns 0..1), so the fill follows live state.
var source: Callable:
	set(v): source = v; set_process(striped or source.is_valid())

const START_ALPHA := 0.06
const END_ALPHA := 0.38
const STRIPE := 8.0

static func attach(host: Control, col: Color, src := Callable(), stripes := false) -> ProgressFill:
	var f := ProgressFill.new()
	f.color = col
	f.source = src
	f.striped = stripes
	f.progress = float(src.call()) if src.is_valid() else -1.0
	host.add_child(f, false, Node.INTERNAL_MODE_FRONT)
	return f

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(false)

func _process(_delta: float) -> void:
	if source.is_valid():
		var p := float(source.call())
		if p != progress:
			progress = p
			return
	if striped and progress >= 0.0:
		queue_redraw()

func _draw() -> void:
	if progress < 0.0 or size.x < 1.0 or size.y < 1.0:
		return
	# the leading edge is cut at 45°: its top runs `size.y` ahead of its
	# bottom, so `w` (the top) travels the width plus that slant
	var w := (size.x + size.y) * clampf(progress, 0.0, 1.0)
	if w < 0.5:
		return
	# edge to edge, matching the host's rounded corners
	var radius := 0.0
	var sb := _host_box()
	if sb is StyleBoxFlat:
		radius = float((sb as StyleBoxFlat).corner_radius_top_left)
	var area := Rect2(Vector2.ZERO, size)
	var box := _rounded_rect(area, radius)
	for poly: PackedVector2Array in Geometry2D.intersect_polygons(box, _slant(area, 0.0, w)):
		var cols := PackedColorArray()
		for p: Vector2 in poly:
			cols.append(Color(color, lerpf(START_ALPHA, END_ALPHA, clampf(p.x / w, 0.0, 1.0))))
		draw_polygon(poly, cols)
	if striped:
		_draw_stripes(area, w, radius)

## Band between two 45° lines whose tops sit at x0 and x1.
static func _slant(area: Rect2, x0: float, x1: float) -> PackedVector2Array:
	var h := area.size.y
	return PackedVector2Array([Vector2(x0, area.position.y), Vector2(x1, area.position.y),
		Vector2(x1 - h, area.end.y), Vector2(x0 - h, area.end.y)])

func _draw_stripes(area: Rect2, w: float, radius: float) -> void:
	radius = minf(radius, minf(area.size.x, area.size.y) * 0.5)
	var shift := fmod(float(Time.get_ticks_msec()) / 40.0, STRIPE * 2.0)
	var y := area.position.y
	while y < area.end.y:   # diagonal stripes, built row by row from rects
		# keep each row inside the rounded corners
		var dy := maxf(maxf(area.position.y + radius - (y + 1.0), (y + 1.0) - (area.end.y - radius)), 0.0)
		var cut := radius - sqrt(maxf(radius * radius - dy * dy, 0.0))
		var row_w := w - (y + 1.0 - area.position.y)   # follow the 45° leading edge
		var x := -STRIPE * 2.0 + fmod(shift + y, STRIPE * 2.0)
		while x < row_w:
			var x0 := maxf(x, area.position.x + cut)
			var x1 := minf(minf(x + STRIPE, row_w), area.end.x - cut)
			if x1 > x0:
				draw_rect(Rect2(x0, y, x1 - x0, 2.0), Color(color, 0.16))
			x += STRIPE * 2.0
		y += 2.0

## The box the host draws itself with (button "normal", else "panel").
func _host_box() -> StyleBox:
	var host := get_parent() as Control
	if host == null:
		return null
	if host is Button:
		return host.get_theme_stylebox(&"normal")
	return host.get_theme_stylebox(&"panel")

static func _rounded_rect(r: Rect2, radius: float) -> PackedVector2Array:
	radius = minf(radius, minf(r.size.x, r.size.y) * 0.5)
	if radius < 0.5:
		return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	var pts := PackedVector2Array()
	var centres := [Vector2(r.end.x - radius, r.position.y + radius), Vector2(r.end.x - radius, r.end.y - radius),
		Vector2(r.position.x + radius, r.end.y - radius), Vector2(r.position.x + radius, r.position.y + radius)]
	for i in 4:   # clockwise from the top-right corner
		for s in 5:
			var a := -PI * 0.5 + (float(i) + float(s) / 4.0) * PI * 0.5
			pts.append(centres[i] + Vector2(cos(a), sin(a)) * radius)
	return pts
