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
## Placement guide rings: [{lon, lat, r (radians), color}] (city zones / reach).
var placement_rings: Array = []
## 0..1 — how visible non-city districts are. Zoomed out only cities show.
var detail: float = 1.0
## { lon, lat, ok, title, detail } — empty when the cursor is off the planet.
var _ghost: Dictionary = {}
## Optional: global screen pos → index of the district whose territory is there (-1 = none).
var territory_lookup: Callable
## Arcs shown while Alt is held: (district index → its City index) into _pois.
var links: Array[Vector2i] = []
## Top-left of the planet's pixel grid on screen (set by PlanetaryView from the
## low-res render) — markers snap to it.
var pixel_grid_origin: Vector2 = Vector2.INF
## 0..1 — all markers and labels (cities included). 0 at the closest zoom.
var marker_vis: float = 1.0
## Neighbouring district pairs (indices into _pois). Hovering the selected
## district draws arcs to its neighbours.
var neighbor_pairs: Array[Vector2i] = []
## Alt held: network overview (arcs to each district's City, every district visible).
var show_overlay: bool = false
## Routed roads (RoadNetwork.route results):
## [{ segments: [{ sea: bool, points: PackedVector2Array (lon, lat) }], ports: PackedVector2Array }]
var roads: Array = []
## 0..1 — road network visibility (zoom-driven; hidden when far out).
var road_vis: float = 1.0
## Port under the cursor: { lon, lat, name } or empty.
var _hover_port: Dictionary = {}
## View-space light direction (planet shader's light_direction) for road shading.
var light_dir: Vector3 = Vector3(0, 0, 1)

## `lines`: Array of [text: String, color: Color] shown under the title.
## `neighbors`: indices into _pois this site would neighbour (preview arcs).
func set_ghost(lon: float, lat: float, ok: bool, title: String, lines: Array = [],
		tag: String = "", neighbors: Array = []) -> void:
	_ghost = {"lon": lon, "lat": lat, "ok": ok, "title": title, "lines": lines,
		"tag": tag, "neighbors": neighbors}

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
	var clip := _clip_rect()
	var block := maxf(2.0, roundf(_pixel_size() * 0.5))
	# keep dot spacing roughly constant on screen, whatever the circle size
	var p := _get_planet_params()
	var r_px: float = p.get("r_px", 200.0)
	var segs := clampi(int(TAU * sin(radius_rad) * r_px / (block * 3.0)), 24, 220)
	for i in segs:
		var a := TAU * float(i) / float(segs)
		var d := (c * cos(radius_rad) + (u * cos(a) + v * sin(a)) * sin(radius_rad)).normalized()
		var pt := project(atan2(d.x, d.z), asin(clampf(d.y, -1.0, 1.0)))
		if pt.z > 0.0 and clip.has_point(Vector2(pt.x, pt.y)):
			var lp := (Vector2(pt.x, pt.y) - global_position) / block
			draw_rect(Rect2(lp.floor() * block, Vector2(block, block)), col)

func _draw_placement_overlay(font: Font) -> void:
	var spacing := deg_to_rad(spacing_deg)
	for ring: Dictionary in placement_rings:
		_draw_surface_circle(ring["lon"], ring["lat"], ring["r"], ring["color"], 1.0)
	for poi in _pois:
		# no-build spacing around every district
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
	var gtag: String = _ghost.get("tag", "")
	_draw_pixel_icon(sp, _marker_icon(gtag, gtag == "city"), block, col, 1.0)
	_draw_pixel_brackets(sp, block * 6.0, block, Color(col, 0.9))
	# preview arcs to the districts this one would neighbour
	for ni in _ghost.get("neighbors", []):
		if int(ni) < _pois.size():
			var other: Dictionary = _pois[int(ni)]
			_draw_arc(_ghost["lon"], _ghost["lat"], other["lon"], other["lat"],
				0.85, Color(0.55, 1.0, 0.65) if ok else Color(1.0, 0.55, 0.45))
	_draw_ghost_info(font, sp, ok)

## Title + detail lines in a dark box beside the cursor.
func _draw_ghost_info(font: Font, sp: Vector2, ok: bool) -> void:
	const TITLE_SIZE := 12
	const LINE_SIZE  := 9
	const PAD        := 6.0
	var title: String = _ghost["title"]
	var lines: Array  = _ghost.get("lines", [])
	var w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE).x
	for ln: Array in lines:
		w = maxf(w, font.get_string_size(ln[0], HORIZONTAL_ALIGNMENT_LEFT, -1, LINE_SIZE).x)
	var h := 16.0 + 13.0 * lines.size()
	var box := Rect2(sp + Vector2(16, -14), Vector2(w + PAD * 2.0, h + PAD))
	# keep the box on screen: flip left of the cursor near the right edge
	var clip := _clip_rect()
	if box.end.x + global_position.x > clip.end.x:
		box.position.x = sp.x - 16 - box.size.x
	draw_rect(box, Color(0.04, 0.06, 0.12, 0.88))
	draw_rect(box, Color(0.45, 1.0, 0.55, 0.5) if ok else Color(1.0, 0.45, 0.4, 0.5), false, 1.0)
	var pos := box.position + Vector2(PAD, PAD + 10.0)
	draw_string(font, pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE, Color.WHITE)
	for ln: Array in lines:
		pos.y += 13.0
		draw_string(font, pos, ln[0], HORIZONTAL_ALIGNMENT_LEFT, -1, LINE_SIZE, ln[1])

# ── Pixel-art helpers ─────────────────────────────────────────────────────────
# Markers snap to the planet shader's pixel grid so they read as part of the art.

const _ICONS := {
	# 9×9 metropolis skyline — cities are parent districts and read differently
	# from the rest. The 1-px gaps fill with the outline: building edges + windows.
	"capital_city": [
		"....#....",
		"....#....",
		"...###.#.",
		".#.#.#.#.",
		".#.###.##",
		"##.#.#.##",
		"##.###.##",
		"##.###.##",
		"#########",
	],
	"city": [
		"...#...",
		"..##.#.",
		"..##.#.",
		".######",
		".######",
		"#######",
		"#######",
	],
	# Districts use compact 5×5 icons so cities stand out when zoomed in.
	"generator": [
		"..###",
		".##..",
		"#####",
		"..##.",
		".##..",
	],
	"mining": [
		"..#..",
		".###.",
		"##.##",
		".###.",
		"..#..",
	],
	"residential": [
		"..#..",
		".###.",
		"#####",
		".#.#.",
		".###.",
	],
	"default": [
		".###.",
		"#####",
		"#####",
		"#####",
		".###.",
	],
}

func _marker_icon(tag: String, is_city: bool = false) -> Array:
	if is_city:
		return _ICONS["capital_city"]
	return _ICONS.get(tag, _ICONS["default"])

func _marker_color(tag: String) -> Color:
	match tag:
		"generator": return Color(0.45, 0.85, 1.0)
		"mining":    return Color(1.0, 0.58, 0.28)
		"residential": return Color(0.60, 0.95, 0.60)
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
	var origin := pixel_grid_origin if pixel_grid_origin.is_finite() else _planet.global_position
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

# ── Roads ─────────────────────────────────────────────────────────────────────
# Routes follow the land and switch to sea lanes at ports (RoadNetwork). Drawn
# as pixel blocks on the globe, shaded by the same sun as the planet; at night
# land roads show a sparse string of lights. Ships sail the sea lanes.
const ROAD_COL  := Color(0.34, 0.32, 0.29)
const SEA_COL   := Color(0.90, 0.95, 1.0)    # shipping-lane dashes
const PORT_COL  := Color(0.95, 0.97, 1.0)    # port rings
const SHIP_COL  := Color(1.0, 0.97, 0.88)
const SHIP_SPEED := 0.03     # radians of surface per second (average)
const SEA_DASH_ON  := 3      # dash pattern along a lane, in pixel blocks
const SEA_DASH_OFF := 2

func _shade(v: Vector3) -> float:
	return 0.25 + 0.75 * smoothstep(-0.05, 0.4, v.dot(light_dir))

func _draw_roads() -> void:
	if roads.is_empty() or road_vis <= 0.02:
		return
	var p := _get_planet_params()
	if p.is_empty():
		return
	var center: Vector2 = p["center"] - global_position
	var r_px: float     = p["r_px"]
	var block := maxf(2.0, roundf(_pixel_size() * 0.5))
	var clip := _clip_rect()
	clip.position -= global_position
	var now := float(Time.get_ticks_msec()) / 1000.0
	# Land road pixels are collected first (cell -> [roads through it, shade])
	# and drawn once: shared stretches become one trunk, drawn wider.
	var land_cells := {}
	for road: Dictionary in roads:
		for seg: Dictionary in road.get("segments", []):
			_draw_road_segment(seg["points"], seg["sea"], center, r_px, block, clip, now, land_cells)
	_draw_land_road_cells(land_cells, block)
	# ports on top of the roads
	for road: Dictionary in roads:
		for pt: Vector2 in road.get("ports", PackedVector2Array()):
			var v: Vector3 = _planet.lonlat_to_view(pt.x, pt.y)
			var sp := center + Vector2(v.x, v.y) * r_px
			if v.z <= 0.0 or not clip.has_point(sp):
				continue
			# a small pixel ring, like a port marker on a shipping map
			var c := (sp / block).floor() * block
			var ring_a := (0.45 + 0.35 * _shade(v)) * road_vis
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					if ox == 0 and oy == 0:
						continue
					draw_rect(Rect2(c + Vector2(ox, oy) * block, Vector2(block, block)), Color(PORT_COL, ring_a))
			draw_rect(Rect2(c, Vector2(block, block)), Color(0.05, 0.10, 0.20, ring_a))
	_draw_port_label(center, r_px, block)

## Every port with its screen position: [{ lon, lat, name, screen (global) }].
func _visible_ports() -> Array:
	var out: Array = []
	var p := _get_planet_params()
	if p.is_empty():
		return out
	var clip := _clip_rect()
	for road: Dictionary in roads:
		var ports: PackedVector2Array = road.get("ports", PackedVector2Array())
		var names: PackedStringArray = road.get("port_names", PackedStringArray())
		for k in ports.size():
			var v: Vector3 = _planet.lonlat_to_view(ports[k].x, ports[k].y)
			var sp: Vector2 = p["center"] + Vector2(v.x, v.y) * float(p["r_px"])
			if v.z > 0.0 and clip.has_point(sp):
				out.append({"lon": ports[k].x, "lat": ports[k].y,
					"name": names[k] if k < names.size() else "", "screen": sp})
	return out

func _port_at(global_pos: Vector2) -> Dictionary:
	if road_vis < 0.5:
		return {}
	var reach := maxf(8.0, _pixel_size() * 2.0)
	for port: Dictionary in _visible_ports():
		if (port["screen"] as Vector2).distance_to(global_pos) <= reach:
			return port
	return {}

## Small "PORT <name>" tag over the hovered port.
func _draw_port_label(center: Vector2, r_px: float, block: float) -> void:
	if _hover_port.is_empty() or _hover_port.get("name", "") == "":
		return
	var v: Vector3 = _planet.lonlat_to_view(_hover_port["lon"], _hover_port["lat"])
	if v.z <= 0.0:
		return
	var font: Font = _orbitron if _orbitron else ThemeDB.fallback_font
	var text := "PORT  " + String(_hover_port["name"]).to_upper()
	const SIZE := 9
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
	var anchor := center + Vector2(v.x, v.y) * r_px + Vector2(0, -block * 3.0)
	var box := Rect2(anchor - Vector2(tw * 0.5 + 5.0, 13.0), Vector2(tw + 10.0, 15.0))
	draw_rect(box, Color(0.04, 0.07, 0.14, 0.88))
	draw_rect(box, Color(PORT_COL, 0.6), false, 1.0)
	draw_string(font, box.position + Vector2(5.0, 11.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, PORT_COL)

## Land road pixels, accumulated over all roads. A cell several roads share is a
## trunk: drawn 2×2 and a touch lighter. Night adds sodium street light.
func _draw_land_road_cells(cells: Dictionary, block: float) -> void:
	var k := 0
	for cell: Vector2 in cells:
		var info: Array = cells[cell]
		var shared: bool = int(info[0]) > 1
		var shade: float = info[1]
		var col := (ROAD_COL.lightened(0.12) if shared else ROAD_COL) * shade
		var size := Vector2(block, block) * (2.0 if shared else 1.0)
		draw_rect(Rect2(cell, size), Color(col, 0.85 * road_vis))
		if shade < 0.45:
			var night := (0.45 - shade) / 0.45
			var bright := (0.35 if shared else 0.25) + (0.25 if k % 4 == 0 else 0.0)
			draw_rect(Rect2(cell, size), Color(1.0, 0.58, 0.22, night * bright * road_vis))
		k += 1

func _draw_road_segment(pts: PackedVector2Array, sea: bool, center: Vector2, r_px: float,
		block: float, clip: Rect2, now: float, land_cells: Dictionary) -> void:
	if pts.size() < 2:
		return
	var view := PackedVector3Array()
	var along := PackedFloat32Array()     # cumulative surface distance (radians)
	var total := 0.0
	for k in pts.size():
		var v: Vector3 = _planet.lonlat_to_view(pts[k].x, pts[k].y)
		if k > 0:
			total += acos(clampf(v.dot(view[k - 1]), -1.0, 1.0))
		view.append(v)
		along.append(total)
	var steps_done := 0
	var last := Vector2(-INF, -INF)
	for k in range(1, view.size()):
		var va := view[k - 1]
		var vb := view[k]
		if va.z <= 0.0 and vb.z <= 0.0:
			continue
		var a := center + Vector2(va.x, va.y) * r_px
		var b := center + Vector2(vb.x, vb.y) * r_px
		var n := maxi(1, int(ceil(a.distance_to(b) / block)))
		for s in n + 1:
			var t := float(s) / float(n)
			var v := va.lerp(vb, t)
			if v.z <= 0.0:
				continue
			var cell := ((a.lerp(b, t)) / block).floor() * block
			if cell == last or not clip.has_point(cell):
				continue
			last = cell
			steps_done += 1
			var shade := _shade(v.normalized())
			if sea:
				# faint long dashes — present, but never louder than the sea
				if steps_done % (SEA_DASH_ON + SEA_DASH_OFF) < SEA_DASH_ON:
					draw_rect(Rect2(cell, Vector2(block, block)),
						Color(SEA_COL, (0.12 + 0.16 * shade) * road_vis))
			else:
				# count once per road (consecutive repeats were skipped above)
				if land_cells.has(cell):
					(land_cells[cell] as Array)[0] = int(land_cells[cell][0]) + 1
				else:
					land_cells[cell] = [1, shade]
	if sea and total > 0.0001:
		_draw_ships(view, along, total, center, r_px, block, clip, now)

## Ships sail a lane like real traffic: a few per lane (more on long ones),
## each with its own pace, direction and side of the lane, drifting a little —
## they follow the route roughly instead of riding the dashes. Position and
## side-offset live on the globe (not in screen pixels) and snap to the planet's
## pixel grid like the markers, so ships stay steady while zooming / spinning.
const SHIP_LANE_OFFSET := 0.006   # how far a ship keeps off the lane (radians)

func _lane_point(view: PackedVector3Array, along: PackedFloat32Array, d: float) -> Array:
	var k := 1
	while k < along.size() - 1 and along[k] < d:
		k += 1
	var seg_len := maxf(along[k] - along[k - 1], 0.000001)
	var v := view[k - 1].slerp(view[k], clampf((d - along[k - 1]) / seg_len, 0.0, 1.0))
	return [v, (view[k] - view[k - 1]).normalized()]

func _draw_ships(view: PackedVector3Array, along: PackedFloat32Array, total: float,
		center: Vector2, r_px: float, block: float, clip: Rect2, now: float) -> void:
	var count := clampi(int(total / 0.12), 1, 4)
	for i in count:
		var h := fposmod(sin(float(i) * 12.9898 + total * 78.233) * 43758.5453, 1.0)
		var speed := SHIP_SPEED * (0.7 + 0.6 * h)
		var forward := i % 2 == 0
		var tt := fposmod(now * speed / total + h * 3.7, 1.0)
		if not forward:
			tt = 1.0 - tt
		var d := tt * total
		var here: Array = _lane_point(view, along, d)
		var v: Vector3 = here[0]
		var tangent: Vector3 = here[1] * (1.0 if forward else -1.0)
		# keep to one side of the lane and wander slowly — measured on the globe
		var side := ((h - 0.5) * 1.6 + sin(now * 0.6 + float(i) * 2.3) * 0.5) * SHIP_LANE_OFFSET
		var normal := v.cross(tangent).normalized()
		var pos := (v + normal * side).normalized()
		if pos.z <= 0.0:
			continue
		var sp := center + Vector2(pos.x, pos.y) * r_px
		if not clip.has_point(sp):
			continue
		var cell := _snap(sp + global_position) - global_position - Vector2(block, block) * 0.5
		var lit := (0.55 + 0.45 * _shade(pos)) * road_vis   # ships carry lights
		# faint wake one step behind along the lane
		var back: Array = _lane_point(view, along, clampf(d - (1.0 if forward else -1.0) * block * 2.0 / r_px, 0.0, total))
		var bpos := ((back[0] as Vector3) + normal * side).normalized()
		var stern := _snap(center + Vector2(bpos.x, bpos.y) * r_px + global_position) - global_position \
			- Vector2(block, block) * 0.5
		if stern != cell and bpos.z > 0.0:
			draw_rect(Rect2(stern, Vector2(block, block)), Color(SHIP_COL, 0.35 * lit))   # wake
		draw_rect(Rect2(cell, Vector2(block, block)), Color(SHIP_COL, lit))

# ── Neighbour links ───────────────────────────────────────────────────────────
# Grand-strategy style connection arcs. Each arc follows the great circle between
# two districts but is lifted along the surface normal (peaking mid-way), and is
# projected like the globe — so it leaves each settlement perpendicular to the
# surface and bends with the viewing angle. Dashes flow toward the bigger one.
const LINK_HEIGHT_MIN  := 0.03    # arc peak above the surface, × planet radius
const LINK_HEIGHT_PER  := 0.35    # extra peak height per radian of distance
const LINK_DASH_BLOCKS := 6.0     # dash period, in pixel blocks
const LINK_SPEED       := 1.1     # dash periods per second

static func _ll_to_vec(lon: float, lat: float) -> Vector3:
	return Vector3(sin(lon) * cos(lat), sin(lat), cos(lon) * cos(lat))

func _draw_links() -> void:
	# hovering the selected district: arcs to everything it neighbours
	if _selected_index >= 0 and _hovered_index == _selected_index and _selected_index < _pois.size():
		var me: Dictionary = _pois[_selected_index]
		for pr: Vector2i in neighbor_pairs:
			var other := -1
			if pr.x == _selected_index: other = pr.y
			elif pr.y == _selected_index: other = pr.x
			if other < 0 or other >= _pois.size():
				continue
			_draw_arc(me["lon"], me["lat"], _pois[other]["lon"], _pois[other]["lat"],
				0.85, Color(0.55, 1.0, 0.65))
	if not show_overlay:
		return
	# arcs: every district flows to the City it belongs to
	for lk: Vector2i in links:
		if lk.x >= _pois.size() or lk.y >= _pois.size():
			continue
		var focus := lk.x == _hovered_index or lk.x == _selected_index \
			or lk.y == _hovered_index or lk.y == _selected_index
		_draw_arc(_pois[lk.x]["lon"], _pois[lk.x]["lat"], _pois[lk.y]["lon"], _pois[lk.y]["lat"],
			0.85 if focus else 0.6, Color(0.70, 0.88, 1.0))

## One dashed, animated arc from (lon_a, lat_a) to (lon_b, lat_b); dashes flow a → b.
func _draw_arc(lon_a: float, lat_a: float, lon_b: float, lat_b: float, base_a: float, tint: Color) -> void:
	var p := _get_planet_params()
	if p.is_empty():
		return
	var center: Vector2 = p["center"]
	var r_px: float     = p["r_px"]
	var block := maxf(2.0, roundf(_pixel_size() * 0.5))
	var clip := _clip_rect()
	var now := float(Time.get_ticks_msec()) / 1000.0
	var a := _ll_to_vec(lon_a, lat_a)
	var b := _ll_to_vec(lon_b, lat_b)
	var arc := acos(clampf(a.dot(b), -1.0, 1.0))
	if arc < 0.0001:
		return
	var height := LINK_HEIGHT_MIN + LINK_HEIGHT_PER * arc
	var steps := maxi(12, int(arc * r_px * (1.0 + height) / block * 1.3))
	var dash_len := arc * r_px / (block * LINK_DASH_BLOCKS)   # dash periods along the arc
	var last := Vector2(-INF, -INF)
	for i in steps + 1:
		var t := float(i) / float(steps)
		# dashed + animated: skip the "off" half of each period
		if fposmod(t * dash_len - now * LINK_SPEED, 1.0) > 0.55:
			continue
		var d := a.slerp(b, t)
		var v: Vector3 = _planet.lonlat_to_view(atan2(d.x, d.z), asin(clampf(d.y, -1.0, 1.0)))
		var q := v * (1.0 + height * sin(PI * t))          # lifted along the normal
		if q.z < 0.0 and Vector2(q.x, q.y).length() < 1.0:
			continue                                        # behind the globe
		var sp := center + Vector2(q.x, q.y) * r_px
		if not clip.has_point(sp):
			continue
		var cell := ((sp - global_position) / block).floor() * block
		if cell == last:
			continue
		last = cell
		# fade in/out at the ends so the arc grows out of the settlements
		var ends := smoothstep(0.0, 0.12, t) * smoothstep(1.0, 0.88, t)
		draw_rect(Rect2(cell, Vector2(block, block)), Color(tint, base_a * lerpf(0.35, 1.0, ends)))

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

## Neighbouring districts (same "cluster" id) that crowd together on screen show
## one label — the biggest settlement's, with a "+N" count. Zooming in spreads
## them apart and every label comes back. Hovered / selected always keep theirs.
const LABEL_MERGE_PX := 90.0

## Returns { hidden: Dictionary(poi index -> true), extra: Dictionary(index -> hidden count) }.
func _label_merges() -> Dictionary:
	var hidden := {}
	var extra := {}
	var groups := {}
	for i in _pois.size():
		var poi: Dictionary = _pois[i]
		if not poi["visible"]:
			continue
		if detail < 0.5 and not poi["data"].get("is_city", false):
			continue   # zoomed out: hidden districts can't take a city's label
		var cid: int = poi["data"].get("cluster", i)
		if not groups.has(cid):
			groups[cid] = []
		groups[cid].append(i)
	for cid in groups:
		var members: Array = groups[cid]
		if members.size() < 2:
			continue
		var lead: int = members[0]
		for m: int in members:
			if float(_pois[m]["data"].get("size", 0.0)) > float(_pois[lead]["data"].get("size", 0.0)):
				lead = m
		for m: int in members:
			if m == lead or m == _hovered_index or m == _selected_index:
				continue
			var d: float = (_pois[m]["screen"] as Vector2).distance_to(_pois[lead]["screen"])
			if d < LABEL_MERGE_PX:
				hidden[m] = true
				extra[lead] = int(extra.get(lead, 0)) + 1
	return {"hidden": hidden, "extra": extra}

func _draw() -> void:
	var font: Font = _orbitron if _orbitron else ThemeDB.fallback_font
	if placement_mode:
		_draw_placement_overlay(font)
	if _pois.is_empty() and _floating_texts.is_empty():
		return
	var merges := _label_merges()
	_draw_roads()
	_draw_links()

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

		var is_city: bool = poi["data"].get("is_city", false)
		var alpha: float  = poi["alpha"] * (1.0 if is_city else detail) * marker_vis
		if alpha <= 0.02:
			continue
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

		var line_px := maxf(2.0, roundf(px * 0.5))
		var label_hidden: bool = merges["hidden"].has(i)

		# leader lines — chunky pixel steps, drawn first so the marker sits on top
		if not label_hidden:
			_draw_pixel_line(sp, diag_end, line_px, col)
			_draw_pixel_line(diag_end, horiz_end, line_px, col)

		# marker — pixel icon per district type, bracket frame when hovered/selected
		_draw_pixel_icon(sp, _marker_icon(tag, is_city), line_px, dot_col, alpha)
		if active:
			var frame_col := Color(1.0, 0.95, 0.5, alpha * (0.9 if selected else 0.6))
			_draw_pixel_brackets(sp, line_px * (6.0 if is_city else 4.5), line_px, frame_col)
		if label_hidden:
			continue

		# label (+N when crowded neighbours are folded into it)
		var label: String = poi["label"]
		if merges["extra"].has(i):
			label += "  +%d" % int(merges["extra"][i])
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
		_hover_port = _port_at(event.global_position)
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
		if not poi["data"].get("is_city", false) and detail < 0.5:
			continue
		if marker_vis < 0.5:
			continue
		var sp: Vector2 = poi["screen"]
		if global_pos.distance_to(sp) <= DOT_HOVER_RADIUS + 4.0:
			return i
	return -1
