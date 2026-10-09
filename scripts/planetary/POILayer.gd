extends Node2D

signal poi_clicked(index: int, data: Dictionary)

const DOT_RADIUS       := 5.0
const DOT_HOVER_RADIUS := 8.0
const LINE_DIAG_LEN    := 28.0
const LINE_HORIZ_LEN   := 52.0
const FONT_SIZE        := 15
const NIGHT_GLOW_MAX   := 5.0   # max glow radius in pixels
const NIGHT_GLOW_MIN   := 0.8   # glow radius for a single active building

var _planet: ColorRect
var _pois: Array[Dictionary] = []
var _hovered_index:  int = -1
var _selected_index: int = -1

## District placement preview. While placement_mode is on, POI clicks are ignored
## and spacing rings are drawn around existing districts.
var placement_mode: bool = false
var spacing_deg:    float = 8.0
## { lon, lat, ok, title, detail } — empty when the cursor is off the planet.
var _ghost: Dictionary = {}
## Optional: global screen pos → index of the district whose territory is there (-1 = none).
var territory_lookup: Callable

func set_ghost(lon: float, lat: float, ok: bool, title: String, detail: String, tag: String = "") -> void:
	_ghost = {"lon": lon, "lat": lat, "ok": ok, "title": title, "detail": detail, "tag": tag}

func clear_ghost() -> void:
	_ghost = {}

func setup(renderer: ColorRect) -> void:
	_planet = renderer
	set_process_input(true)

func clear_pois() -> void:
	_pois.clear()
	_hovered_index  = -1
	_selected_index = -1

func deselect_all() -> void:
	_hovered_index  = -1
	_selected_index = -1
	queue_redraw()

func select_poi(index: int) -> void:
	_selected_index = index
	queue_redraw()

func add_poi(lon_deg: float, lat_deg: float, label: String, data: Dictionary = {}) -> void:
	_pois.append({
		"lon":    deg_to_rad(lon_deg),
		"lat":    deg_to_rad(lat_deg),
		"label":  label,
		"data":   data,
		"screen": Vector2.ZERO,
		"visible": false,
		"alpha":  0.0,
	})

func _get_planet_params() -> Dictionary:
	if not _planet or not _planet.material:
		return {}
	var center := _planet.global_position + _planet.size * 0.5
	var radius_frac: float = _planet.material.get_shader_parameter("planet_radius")
	var aspect: float      = _planet.material.get_shader_parameter("aspect_ratio")
	var r_px := _planet.size.y * radius_frac  # radius in screen pixels (based on height)
	return {"center": center, "r_px": r_px, "aspect": aspect}

## Screen area the planet is visible in (its container, not the oversized renderer).
func _clip_rect() -> Rect2:
	var parent := _planet.get_parent() as Control
	return parent.get_global_rect() if parent else _planet.get_global_rect()

## Projects a surface point to screen. Returns Vector3(x, y, depth); depth <= 0 is the far side.
func project(lon: float, lat: float) -> Vector3:
	var p := _get_planet_params()
	if p.is_empty():
		return Vector3(0, 0, -1)
	var center: Vector2 = p["center"]
	var r_px: float     = p["r_px"]
	var v: Vector3 = _planet.lonlat_to_view(lon, lat)
	return Vector3(center.x + v.x * r_px, center.y + v.y * r_px, v.z)

## Draws a dotted pixel circle of the given angular radius around (lon, lat), front side only.
func _draw_surface_circle(lon: float, lat: float, radius_rad: float, col: Color, _width: float) -> void:
	var c := Vector3(sin(lon) * cos(lat), sin(lat), cos(lon) * cos(lat))
	# Orthonormal basis around the centre direction.
	var up := Vector3.UP if absf(c.y) < 0.95 else Vector3.RIGHT
	var u := c.cross(up).normalized()
	var v := c.cross(u).normalized()
	const SEGS := 48
	var clip := _clip_rect()
	var block := maxf(2.0, roundf(_pixel_size() * 0.5))
	for i in SEGS:
		var a := TAU * float(i) / float(SEGS)
		var d := (c * cos(radius_rad) + (u * cos(a) + v * sin(a)) * sin(radius_rad)).normalized()
		var pt := project(atan2(d.x, d.z), asin(clampf(d.y, -1.0, 1.0)))
		if pt.z > 0.0 and clip.has_point(Vector2(pt.x, pt.y)):
			var lp := (Vector2(pt.x, pt.y) - global_position) / block
			draw_rect(Rect2(lp.floor() * block, Vector2(block, block)), col)

func _draw_placement_overlay(font: Font) -> void:
	var spacing := deg_to_rad(spacing_deg)
	for poi in _pois:
		_draw_surface_circle(poi["lon"], poi["lat"], spacing, Color(1.0, 0.45, 0.35, 0.45), 1.0)
	if _ghost.is_empty():
		return
	var pt := project(_ghost["lon"], _ghost["lat"])
	if pt.z <= 0.0 or not _clip_rect().has_point(Vector2(pt.x, pt.y)):
		return
	var ok: bool = _ghost["ok"]
	var col := Color(0.45, 1.0, 0.55) if ok else Color(1.0, 0.40, 0.35)
	_draw_surface_circle(_ghost["lon"], _ghost["lat"], spacing * 0.5, Color(col, 0.85), 1.5)
	var sp := _snap(Vector2(pt.x, pt.y)) - global_position
	var block := maxf(2.0, roundf(_pixel_size() * 0.5))
	_draw_site_beam(_ghost["lon"], _ghost["lat"], col)
	_draw_pixel_icon(sp, _marker_icon(_ghost.get("tag", "")), block, col, 1.0)
	_draw_pixel_brackets(sp, block * 6.0, block, Color(col, 0.9))
	# Info label next to the cursor.
	var title: String  = _ghost["title"]
	var detail: String = _ghost["detail"]
	var pos := sp + Vector2(14, -6)
	for ox: int in [-1, 0, 1]:
		for oy: int in [-1, 0, 1]:
			if ox == 0 and oy == 0:
				continue
			var o := Vector2(ox * 1.5, oy * 1.5)
			draw_string(font, pos + o, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0, 0, 0, 0.9))
			if detail != "":
				draw_string(font, pos + o + Vector2(0, 15), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0, 0, 0, 0.9))
	draw_string(font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	if detail != "":
		draw_string(font, pos + Vector2(0, 15), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(col, 0.95))

# ── Pixel-art helpers ─────────────────────────────────────────────────────────
# Markers snap to the planet shader's pixel grid so they read as part of the art.

const _ICONS := {
	"city": [
		"...#...",
		"..##.#.",
		"..##.#.",
		".######",
		".######",
		"#######",
		"#######",
	],
	"generator": [
		"...###.",
		"..###..",
		".###...",
		"######.",
		"..###..",
		".###...",
		".##....",
	],
	"mining": [
		"...#...",
		"..###..",
		".##.##.",
		"###.###",
		".##.##.",
		"..###..",
		"...#...",
	],
	"default": [
		"..###..",
		".#####.",
		"#######",
		"#######",
		"#######",
		".#####.",
		"..###..",
	],
}

func _marker_icon(tag: String) -> Array:
	return _ICONS.get(tag, _ICONS["default"])

func _marker_color(tag: String) -> Color:
	match tag:
		"generator": return Color(0.45, 0.85, 1.0)
		"mining":    return Color(1.0, 0.58, 0.28)
		_:           return Color(1.0, 0.82, 0.25)

## Size of one shader pixel on screen.
func _pixel_size() -> float:
	if not _planet or not _planet.material:
		return 4.0
	var pc: float = _planet.material.get_shader_parameter("pixel_count")
	return _planet.size.y / maxf(pc, 1.0)

## Snaps a global point to the shader's pixel grid (cell centres).
func _snap(global_pt: Vector2) -> Vector2:
	var cell := _pixel_size()
	var origin := _planet.global_position
	return origin + ((global_pt - origin) / cell).floor() * cell + Vector2(cell, cell) * 0.5

func _snap_local(local_pt: Vector2) -> Vector2:
	return _snap(local_pt + global_position) - global_position

func _draw_pixel_icon(center: Vector2, rows: Array, block: float, col: Color, alpha: float) -> void:
	var h := rows.size()
	var w: int = (rows[0] as String).length()
	var origin := (center - Vector2(w, h) * block * 0.5).floor()
	var outline := Color(0, 0, 0, alpha * 0.85)
	# 1-block dark outline first, then the fill
	for pass_i in 2:
		for y in h:
			var row: String = rows[y]
			for x in w:
				if row[x] != "#":
					continue
				var p := origin + Vector2(x, y) * block
				if pass_i == 0:
					draw_rect(Rect2(p - Vector2(block, block), Vector2(block, block) * 3.0), outline)
				else:
					draw_rect(Rect2(p, Vector2(block, block)), col)

func _draw_pixel_line(a: Vector2, b: Vector2, block: float, col: Color) -> void:
	var steps := int(ceil(maxf(absf(b.x - a.x), absf(b.y - a.y)) / block))
	for i in steps + 1:
		var t := float(i) / float(maxi(steps, 1))
		var p := (a.lerp(b, t) / block).floor() * block
		draw_rect(Rect2(p, Vector2(block, block)), col)

## Four corner brackets around a point — the pixel-art selection frame.
func _draw_pixel_brackets(center: Vector2, half: float, block: float, col: Color) -> void:
	var arm := block * 3.0
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			var corner := (center + Vector2(sx, sy) * half).floor()
			var hx := corner.x if sx < 0.0 else corner.x - arm + block
			var vy := corner.y if sy < 0.0 else corner.y - arm + block
			draw_rect(Rect2(Vector2(hx, corner.y), Vector2(arm, block)), col)
			draw_rect(Rect2(Vector2(corner.x, vy), Vector2(block, arm)), col)

## Blocky night-side city glow: stacked squares instead of soft circles.
func _draw_pixel_glow(center: Vector2, radius: float, a: float) -> void:
	var block := maxf(2.0, roundf(_pixel_size() * 0.5))
	var c := (center / block).floor() * block
	var steps := maxi(1, int(round(radius / block)) + 1)
	for i in range(steps, -1, -1):
		var ext := float(i) * block
		var t := 1.0 - float(i) / float(steps + 1)
		var col := Color(1.0, lerpf(0.72, 1.0, t), lerpf(0.28, 0.9, t), a * lerpf(0.10, 0.75, t))
		draw_rect(Rect2(c - Vector2(ext, ext), Vector2(ext * 2.0 + block, ext * 2.0 + block)), col)

## Light beam rising straight up from a surface point. It is projected like the
## planet (orthographic), so its on-screen length and direction show how that
## spot is angled toward the camera: long and sideways near the limb, short when
## facing us — where a flare shows we're looking down the beam instead.
const BEAM_HEIGHT := 0.28   # beam length as a fraction of the planet radius

func _draw_site_beam(lon: float, lat: float, col: Color) -> void:
	var p := _get_planet_params()
	if p.is_empty():
		return
	var v: Vector3 = _planet.lonlat_to_view(lon, lat)
	if v.z <= 0.0:
		return
	var center: Vector2 = p["center"] - global_position
	var r_px: float     = p["r_px"]
	var block := maxf(2.0, roundf(_pixel_size() * 0.5))
	var base := center + Vector2(v.x, v.y) * r_px
	var rise := Vector2(v.x, v.y) * r_px * BEAM_HEIGHT   # screen projection of the normal
	var dir := rise.normalized() if rise.length() > 0.5 else Vector2.UP
	var perp := Vector2(-dir.y, dir.x)
	var steps := maxi(1, int(rise.length() / block))
	for i in steps:
		var t := float(i) / float(steps)
		var half_w := lerpf(2.0, 0.0, t)              # tapers toward the tip
		var pos := base + rise * t
		for k in range(-int(half_w), int(half_w) + 1):
			var edge := absf(float(k)) / (half_w + 1.0)
			var q := ((pos + perp * float(k) * block) / block).floor() * block
			draw_rect(Rect2(q, Vector2(block, block)), Color(col, (1.0 - t) * 0.55 * (1.0 - edge)))
	# sparks drifting up the beam
	var now := float(Time.get_ticks_msec()) / 1000.0
	for k in 3:
		var tt := fposmod(now * 0.9 + float(k) / 3.0, 1.0)
		var q := ((base + rise * tt) / block).floor() * block
		draw_rect(Rect2(q, Vector2(block, block)), Color(1, 1, 1, (1.0 - tt) * 0.9))
	# head-on flare: the more the spot faces the camera, the brighter the halo
	var facing := v.z * v.z
	var b0 := (base / block).floor() * block
	for ring in range(3, 0, -1):
		var ext := block * float(ring) * (1.0 + facing * 1.5)
		draw_rect(Rect2(b0 - Vector2(ext, ext), Vector2(ext * 2.0 + block, ext * 2.0 + block)),
			Color(col, facing * 0.16 / float(ring)))

func _get_rotation() -> float:
	if _planet and _planet.has_method("get_rotation_offset"):
		return _planet.get_rotation_offset()
	return 0.0

func _process(_delta: float) -> void:
	if not _planet:
		return
	var p := _get_planet_params()
	if p.is_empty():
		return
	var center: Vector2 = p["center"]
	var r_px: float     = p["r_px"]
	var clip: Rect2     = _clip_rect()

	for poi in _pois:
		var v: Vector3 = _planet.lonlat_to_view(poi["lon"], poi["lat"])
		poi["screen"]  = center + Vector2(v.x, v.y) * r_px
		poi["view"]    = v             # view-space position, drives label direction
		poi["sz"]      = v.z           # store raw depth for glow culling
		poi["alpha"]   = clamp(v.z * 4.0, 0.0, 1.0)
		# Zoomed in, the globe overflows its container — hide POIs scrolled out of view.
		poi["visible"] = v.z > -0.05 and clip.has_point(poi["screen"])

	var keep_texts: Array[Dictionary] = []
	for ft in _floating_texts:
		ft.time += _delta
		if ft.time < ft.max_time:
			if not ft.get("fixed", false):
				var v: Vector3 = _planet.lonlat_to_view(ft.lon, ft.lat)
				ft.screen  = center + Vector2(v.x, v.y) * r_px
				ft.visible = v.z > -0.05
				ft.alpha   = clamp(v.z * 4.0, 0.0, 1.0)
			keep_texts.append(ft)
	_floating_texts = keep_texts

	queue_redraw()

var _orbitron: Font
var _floating_texts: Array[Dictionary] = []

func spawn_floating_text_at_screen(screen_pos: Vector2, text: String, color: Color = Color.WHITE, font_size: int = 14, icon: Texture2D = null) -> void:
	var same_count := 0
	for ft in _floating_texts:
		if ft.screen.distance_to(screen_pos) < 5.0 and ft.time < 0.5:
			same_count += 1
	_floating_texts.append({
		"lon": 0.0, "lat": 0.0,
		"text": text, "color": color,
		"time": same_count * 0.35,
		"max_time": 2.5 + same_count * 0.35,
		"visible": true,
		"screen": screen_pos,
		"alpha": 1.0,
		"font_size": font_size,
		"icon": icon,
		"y_offset": same_count * 20.0,
		"fixed": true
	})

func spawn_floating_text(lon_deg: float, lat_deg: float, text: String, color: Color = Color.WHITE, font_size: int = 14, icon: Texture2D = null) -> void:
	# Stagger multiple texts spawned at same location so they don't overlap
	var same_count := 0
	for ft in _floating_texts:
		if absf(ft.lon - deg_to_rad(lon_deg)) < 0.001 and absf(ft.lat - deg_to_rad(lat_deg)) < 0.001 and ft.time < 0.3:
			same_count += 1

	# Calculate initial screen position immediately so _draw is correct before first _process
	var init_screen := Vector2.ZERO
	var p := _get_planet_params()
	if not p.is_empty():
		var center: Vector2 = p["center"]
		var r_px: float     = p["r_px"]
		var v: Vector3 = _planet.lonlat_to_view(deg_to_rad(lon_deg), deg_to_rad(lat_deg))
		init_screen = center + Vector2(v.x, v.y) * r_px

	_floating_texts.append({
		"lon": deg_to_rad(lon_deg),
		"lat": deg_to_rad(lat_deg),
		"text": text,
		"color": color,
		"time": same_count * 0.35,
		"max_time": 2.5 + same_count * 0.35,
		"visible": true,
		"screen": init_screen,
		"alpha": 1.0,
		"font_size": font_size,
		"icon": icon,
		"y_offset": same_count * 20.0
	})

func _ready() -> void:
	_orbitron = load("res://Fonts/Orbitron-VariableFont_wght.ttf")

func _draw() -> void:
	var font: Font = _orbitron if _orbitron else ThemeDB.fallback_font
	if placement_mode:
		_draw_placement_overlay(font)
	if _pois.is_empty() and _floating_texts.is_empty():
		return

	for ft in _floating_texts:
		if not ft.visible: continue
		if ft.screen == Vector2.ZERO: continue

		var progress: float = ft.time / ft.max_time
		var text_alpha: float = (1.0 - progress * progress) * ft.alpha
		if text_alpha <= 0.0: continue
		
		var float_up_offset := Vector2(0, -progress * 40.0 - ft.get("y_offset", 0.0))
		var pos: Vector2 = to_local(ft.screen) + float_up_offset
		
		var c: Color = ft.color
		c.a *= text_alpha
		
		var f_size: int = ft.get("font_size", 14)
		var text_width := font.get_string_size(ft.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size).x
		
		var icon_tex: Texture2D = ft.get("icon")
		var total_w := text_width
		var icon_size := 16.0
		if icon_tex != null:
			total_w += icon_size + 4.0
			
		var start_x := pos.x - total_w * 0.5
		
		var text_x := start_x
		if icon_tex != null:
			var icon_pos := Vector2(start_x, pos.y - icon_size * 0.8)
			draw_texture_rect(icon_tex, Rect2(icon_pos, Vector2(icon_size, icon_size)), false, Color(1, 1, 1, c.a), false)
			text_x += icon_size + 4.0
			
		var text_pos := Vector2(text_x, pos.y)
		
		draw_string_outline(font, text_pos, ft.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, 4, Color(0, 0, 0, c.a * 0.9))
		draw_string(font, text_pos, ft.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, c)

	for i in _pois.size():
		var poi: Dictionary = _pois[i]

		# ── Night-side glow ──────────────────────────────────────────────────────
		# Draw city-light glow only for POIs that face the camera (sz > 0)
		# but have low alpha (near the terminator / in shadow from the light).
		# Back-facing POIs (sz ≤ 0) project inside the planet disc and must
		# NOT draw anything — otherwise they appear as stray 1-px yellow dots.
		var poi_sz: float = poi.get("sz", 1.0)
		var data_dict: Dictionary = poi.get("data", {}) as Dictionary
		var night_size: int = data_dict.get("night_size", 0)
		if night_size > 0 and poi_sz > 0.05 and poi["alpha"] < 0.55 \
				and _clip_rect().has_point(poi["screen"]):
			# Fade glow as POI approaches the terminator (alpha rising toward 0.55)
			var night_a: float = clampf((0.55 - poi["alpha"]) * 3.0, 0.0, 1.0)
			var glow_r: float  = clampf(
				NIGHT_GLOW_MIN + float(night_size - 1) * 0.8,
				NIGHT_GLOW_MIN, NIGHT_GLOW_MAX)
			_draw_pixel_glow(poi["screen"] - global_position, glow_r, night_a)

		if not poi["visible"]:
			continue

		var alpha: float  = poi["alpha"]
		var px: float     = _pixel_size()
		var sp: Vector2   = _snap(poi["screen"]) - global_position
		var view: Vector3 = poi["view"]
		var hovered: bool = (i == _hovered_index)

		# Leader direction follows where the POI sits on screen: above centre → up,
		# right of centre → right. Works for any spin/tilt of the globe.
		var vert_dir: float  = 1.0 if view.y > 0.05 else -1.0
		var horiz_dir: float = -1.0 if view.x < 0.0 else 1.0

		var diag_end := _snap_local(sp + Vector2(horiz_dir * LINE_DIAG_LEN * 0.7, vert_dir * LINE_DIAG_LEN))
		var horiz_end := _snap_local(diag_end + Vector2(horiz_dir * LINE_HORIZ_LEN, 0.0))

		var col := Color(0.85, 0.85, 0.85, alpha * 0.9)
		var selected: bool = (i == _selected_index)
		var active: bool   = hovered or selected
		var tag: String    = poi["data"].get("type", "")
		var base_col: Color = _marker_color(tag)
		var dot_col := base_col.lightened(0.45) if active else base_col
		dot_col.a = alpha

		# leader lines — chunky pixel steps, drawn first so the marker sits on top
		var line_px := maxf(2.0, roundf(px * 0.5))
		_draw_pixel_line(sp, diag_end, line_px, col)
		_draw_pixel_line(diag_end, horiz_end, line_px, col)

		# marker — pixel icon per district type, bracket frame when hovered/selected
		_draw_pixel_icon(sp, _marker_icon(tag), line_px, dot_col, alpha)
		if active:
			var frame_col := Color(1.0, 0.95, 0.5, alpha * (0.9 if selected else 0.6))
			_draw_pixel_brackets(sp, line_px * 6.0, line_px, frame_col)

		# label
		var label: String = poi["label"]
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
		var label_pos := horiz_end + Vector2(horiz_dir * 3.0, text_size.y * 0.35)
		if horiz_dir < 0.0:
			label_pos.x -= text_size.x

		# thick outline
		var oc := Color(0.0, 0.0, 0.0, alpha * 0.90)
		for ox: int in [-1, 0, 1]:
			for oy: int in [-1, 0, 1]:
				if ox == 0 and oy == 0:
					continue
				draw_string(font, label_pos + Vector2(ox * 1.5, oy * 1.5), label,
					HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, oc)
		# foreground
		var fc := Color(1.0, 0.95, 0.5, alpha) if hovered else Color(1.0, 1.0, 1.0, alpha)
		draw_string(font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, fc)

		# district level sub-label
		var dist_lv: int = poi["data"].get("district_level", 0)
		if dist_lv > 0:
			const LV_SIZE := 10
			var lv_str := "Lv %d" % dist_lv
			var lv_pos := label_pos + Vector2(0, text_size.y * 0.9)
			if horiz_dir < 0.0:
				var lv_w := font.get_string_size(lv_str, HORIZONTAL_ALIGNMENT_LEFT, -1, LV_SIZE).x
				lv_pos.x = label_pos.x + text_size.x - lv_w
			draw_string(font, lv_pos + Vector2(1, 1), lv_str,
				HORIZONTAL_ALIGNMENT_LEFT, -1, LV_SIZE, Color(0, 0, 0, alpha * 0.7))
			draw_string(font, lv_pos, lv_str,
				HORIZONTAL_ALIGNMENT_LEFT, -1, LV_SIZE, Color(0.65, 0.85, 1.0, alpha * 0.85))

func _unhandled_input(event: InputEvent) -> void:
	if not _planet:
		return

	if placement_mode:
		return

	if event is InputEventMouseMotion:
		var prev := _hovered_index
		var on_marker := _get_poi_at(event.global_position)
		_hovered_index = on_marker
		# Hovering a district's territory highlights it too (border glow in the shader).
		if _hovered_index < 0 and territory_lookup.is_valid() \
				and not (event as InputEventMouseMotion).button_mask:
			_hovered_index = territory_lookup.call(event.global_position)
		if _hovered_index != prev:
			queue_redraw()
			if _hovered_index >= 0:
				if on_marker >= 0:
					AudioManager.play("poi_ping")
				CursorManager.set_state(CursorManager.State.POINTER)
			else:
				CursorManager.set_state(CursorManager.State.NORMAL)

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var idx := _get_poi_at(event.global_position)
		if idx >= 0:
			AudioManager.play("poi_select")
			_selected_index = idx
			queue_redraw()
			poi_clicked.emit(idx, _pois[idx]["data"])
			get_viewport().set_input_as_handled()

## Returns the global screen position of the POI with the given label, or Vector2.ZERO.
func get_poi_screen_pos(label: String) -> Vector2:
	for poi: Dictionary in _pois:
		if poi["label"] == label:
			return poi["screen"]
	return Vector2.ZERO

## Returns the (lon, lat) in radians for the given label, or Vector2.ZERO.
func get_poi_lon_lat(label: String) -> Vector2:
	for poi: Dictionary in _pois:
		if poi["label"] == label:
			return Vector2(poi["lon"], poi["lat"])
	return Vector2.ZERO

func _get_poi_at(global_pos: Vector2) -> int:
	for i in _pois.size():
		var poi: Dictionary = _pois[i]
		if not poi["visible"] or poi["alpha"] < 0.3:
			continue
		var sp: Vector2 = poi["screen"]
		if global_pos.distance_to(sp) <= DOT_HOVER_RADIUS + 4.0:
			return i
	return -1
