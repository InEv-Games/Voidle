## Draws orbital ships with proper Y-axis (longitude) rotation.
## Ships on the far side of the planet are hidden behind it.
class_name OrbitalLayer
extends Control

var _planet_seed:     int     = -1
var _planet_radius:   float   = 0.0
var _planet_rotation: float   = 0.0   # Y-axis rotation (longitude) from planet drag
var _planet_tilt:     float   = 0.0   # camera tilt around screen X (PlanetRenderer.tilt)
var _planet_center:   Vector2 = Vector2.ZERO   # actual planet center in local coords
var _hovered_ship:    ShipData = null
var _selected_ship:   ShipData = null
var suppress_label:   bool     = false   # true when ship panel is open

var _drag_ship:   ShipData = null
var _drag_last_x: float    = 0.0
var _drag_anchor: Vector2  = Vector2.ZERO  # ship 2D pos (in orbit-radius units) at drag start

## Per-ship orbit-reveal: ship_id -> {progress: float, spawn_angle: float}
var _reveal: Dictionary = {}

## Per-POI orbit-reveal: poi_label -> {progress: float, spawn_angle: float}
var _reveal_poi: Dictionary = {}

## Per-ship landing animation state
## ship_id -> DescentFX while that ship comes down (the effect draws it).
var _landing: Dictionary = {}
## Ships the planet view draws itself (flights to a neighbouring body).
var hidden_ships: Dictionary = {}
## ship_id -> coast state while a landing ship flies on to its dive point.
var _coasting: Dictionary = {}
const DescentScript := preload("res://scripts/planetary/DescentFX.gd")
## Set by PlanetaryView: (ship's global screen pos) -> landing site as
## Vector2(lon, lat) in radians, or Vector2.INF for none.
var landing_site_for: Callable


signal ship_hovered(ship: ShipData, screen_pos: Vector2)
signal ship_unhovered()
signal ship_clicked(ship: ShipData)
signal ship_right_clicked(ship: ShipData, screen_pos: Vector2)
signal ship_deselected()
signal ship_landed(ship: ShipData)
signal rendezvous_reached(ship: ShipData, target: ShipData)

func setup(planet_seed: int) -> void:
	_planet_seed = planet_seed
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ShipManager.ship_changed.connect(_on_ship_changed)

func deselect() -> void:
	if _selected_ship != null:
		_selected_ship = null
		queue_redraw()
		ship_deselected.emit()

func select_ship(ship: ShipData) -> void:
	_selected_ship = ship
	queue_redraw()
	ship_clicked.emit(ship)

## Brings `ship` down onto the surface point `site` (lon, lat in radians;
## Vector2.INF = ask landing_site_for, else wherever its orbit dives to).
## It never turns back in the air: it keeps flying its orbit (sped up) until it
## is just short of where the orbit passes closest to the site, then dives
## forward onto it. The route lives in the planet's own frame, so it turns
## with the globe and hides behind it. `on_touchdown` runs at the ground.
func start_landing(ship: ShipData, site: Vector2 = Vector2.INF, on_touchdown: Callable = Callable()) -> void:
	if _landing.has(ship.ship_id) or _coasting.has(ship.ship_id):
		return
	if not site.is_finite() and landing_site_for.is_valid():
		var sv := _project(ship, ship.orbit_angle)
		site = landing_site_for.call(global_position + _center_now() + Vector2(sv.x, sv.y))
	var dir: float = signf(ship.orbit_speed) if ship.orbit_speed != 0.0 else 1.0
	var s_dir: Vector3
	if site.is_finite():
		s_dir = Vector3(sin(site.x) * cos(site.y), -sin(site.y), -cos(site.x) * cos(site.y))
	else:   # no site: where the orbit itself comes down
		s_dir = _frame_point(ship, ship.orbit_angle + dir * (LAND_LEAD + 0.3)).normalized()
	# where the orbit passes closest to the site, looking ahead only
	var best_k := 0.0
	var best_dot := -INF
	for i in 120:
		var k := TAU * float(i) / 120.0
		var d := _frame_point(ship, ship.orbit_angle + dir * k).normalized().dot(s_dir)
		if d > best_dot:
			best_dot = d
			best_k = k
	var coast := fposmod(best_k - LAND_LEAD, TAU)   # forward distance to the dive point
	if coast > TAU - 0.15:
		coast = 0.0   # already (just past) there
	if selected_ship_is(ship):
		_selected_ship = null
		queue_redraw()
		ship_deselected.emit()
	_coasting[ship.ship_id] = {"ship": ship, "left": coast, "dir": dir, "s_dir": s_dir,
		"on_touchdown": on_touchdown, "speed": absf(ship.orbit_speed)}
	if coast <= 0.0:
		_begin_dive(ship.ship_id)

## Radians of orbit the dive itself covers before reaching the site's longitude.
const LAND_LEAD := 0.9
## Fastest a ship flies its orbit while heading for the dive point (rad/s).
const LAND_COAST_SPEED := 0.9

func selected_ship_is(ship: ShipData) -> bool:
	return _selected_ship == ship

## Flies coasting ships forward along their orbits until their dive point.
func _tick_coasting(delta: float) -> void:
	for sid: String in _coasting.keys():
		var c: Dictionary = _coasting[sid]
		var ship: ShipData = c["ship"]
		# ease up towards coast speed, ease back down near the dive point
		var left: float = c["left"]
		var target := minf(LAND_COAST_SPEED, maxf(c["speed"], left * 1.6))
		c["speed"] = lerpf(c["speed"], target, 1.0 - exp(-delta * 3.0))
		var step: float = minf(left, float(c["speed"]) * delta)
		ship.orbit_angle += float(c["dir"]) * step
		c["left"] = left - step
		if c["left"] <= 0.0005:
			_begin_dive(sid)

func _begin_dive(sid: String) -> void:
	var c: Dictionary = _coasting[sid]
	_coasting.erase(sid)
	var ship: ShipData = c["ship"]
	var dir: float = c["dir"]
	var s_dir: Vector3 = c["s_dir"]
	var a0 := ship.orbit_angle
	var r0 := ship.orbit_radius
	var path3 := func(t: float) -> Vector3:
		var e := DescentScript.ease_dive(t)
		# keep flying the orbit forward while the pull towards the site grows
		var on_orbit := _frame_point(ship, a0 + dir * LAND_LEAD * e).normalized()
		var q := on_orbit.lerp(s_dir, smoothstep(0.0, 1.0, e)).normalized()
		var v := _view(q * lerpf(r0, 1.0, pow(t, 1.4)) * _planet_radius)
		var cc := global_position + _center_now()
		return Vector3(cc.x + v.x, cc.y + v.y, 1.0 if _is_occluded(v) else 0.0)
	var sv := _project(ship, a0)
	var start := global_position + _center_now() + Vector2(sv.x, sv.y)
	_reveal[ship.ship_id] = {"progress": 1.0, "spawn_angle": a0}
	var fx: Control = DescentScript.new()
	fx.sprite = ship.ship_type if ship.ship_type in ["station", "lander"] else "shuttle"
	fx.sprite_scale = 1.0
	_landing[sid] = fx
	# the ship is gone the moment it touches down (the effect plays on its own)
	fx.touched_down.connect(func() -> void:
		_landing.erase(sid)
		ShipManager.remove_ship(ship.orbit_seed, sid)
		ship_landed.emit(ship))
	var on_touchdown: Callable = c["on_touchdown"]
	if on_touchdown.is_valid():
		fx.touched_down.connect(on_touchdown)
	get_parent().add_child(fx)
	fx.begin(start, func() -> Vector2: return global_position + _center_now(),
		func() -> Vector3: return Vector3.ZERO,   # (the route ends on the site)
		func(a: float) -> Vector2:
			var v := _project(ship, a)
			return global_position + _center_now() + Vector2(v.x, v.y),
		a0, dir, path3)

## A point of `ship`'s orbit in the planet's own frame (before the globe's spin
## and the camera tilt) — the frame where surface points stay put.
func _frame_point(ship: ShipData, angle: float) -> Vector3:
	var r := ship.orbit_radius
	var inc := ship.orbit_inclination
	var px := r * cos(angle)
	var py := r * sin(angle) * sin(inc)
	var pz := r * sin(angle) * cos(inc)
	var node := ship.orbit_node
	return Vector3(px * cos(node) + pz * sin(node), py, -px * sin(node) + pz * cos(node))

## Planet-frame point → view (spin + tilt), same as _project.
func _view(f: Vector3) -> Vector3:
	var rot := _planet_rotation
	return _tilted(f.x * cos(rot) + f.z * sin(rot), f.y, -f.x * sin(rot) + f.z * cos(rot))

func _center_now() -> Vector2:
	return _planet_center if _planet_center != Vector2.ZERO else size * 0.5

func _process(delta: float) -> void:
	if _planet_seed < 0:
		return
	_tick_coasting(delta)
	for ship_id: String in _reveal:
		var rv: Dictionary = _reveal[ship_id]
		if rv["progress"] < 1.0:
			rv["progress"] = minf(rv["progress"] + delta * 1.8, 1.0)
	for poi_label: String in _reveal_poi:
		var rv: Dictionary = _reveal_poi[poi_label]
		if rv["progress"] < 1.0:
			rv["progress"] = minf(rv["progress"] + delta * 0.6, 1.0)
	_tick_rendezvous(delta)
	queue_redraw()

func _tick_rendezvous(delta: float) -> void:
	var ships := ShipManager.ships_for(_planet_seed)
	for ship: ShipData in ships:
		if ship.rendezvous_target_id == "":
			continue
		var target: ShipData = null
		for s: ShipData in ships:
			if s.ship_id == ship.rendezvous_target_id:
				target = s
				break
		if target == null:
			ship.orbit_speed          = ship.rendezvous_base_speed
			ship.rendezvous_target_id = ""
			ship.rendezvous_base_speed = 0.0
			continue

		# Project both ships to 2D screen space and measure distance
		var sv := _project(ship,   ship.orbit_angle)
		var tv := _project(target, target.orbit_angle)
		var spos := Vector2(sv.x, sv.y)
		var tpos := Vector2(tv.x, tv.y)
		var dist := (tpos - spos).length()

		if dist < _planet_radius * 0.07:
			# Arrived — restore original speed
			ship.orbit_speed          = ship.rendezvous_base_speed
			ship.rendezvous_target_id = ""
			ship.rendezvous_base_speed = 0.0
			rendezvous_reached.emit(ship, target)
			continue

		# Boost to 2× speed during rendezvous so shuttle closes the angle gap faster.
		ship.orbit_speed = ship.rendezvous_base_speed * 2.0

		# Rotate orbit_node so the ship's projected position drifts toward the target.
		# Try +step and -step, pick the direction that reduces distance — no U-turns needed.
		var node_step: float = 1.2 * delta
		var sv_plus  := _project_at_node(ship, ship.orbit_node + node_step)
		var sv_minus := _project_at_node(ship, ship.orbit_node - node_step)
		var d_plus   := (Vector2(sv_plus.x,  sv_plus.y)  - tpos).length()
		var d_minus  := (Vector2(sv_minus.x, sv_minus.y) - tpos).length()
		ship.orbit_node += node_step if d_plus < d_minus else -node_step

## Projects ship to 2D using its current orbit_node. Used by drag to keep ship position fixed.
func _project_2d(ship: ShipData, angle: float) -> Vector2:
	var r: float   = _planet_radius * ship.orbit_radius
	var inc: float = ship.orbit_inclination
	var px: float  = r * cos(angle)
	var py: float  = r * sin(angle) * sin(inc)
	var pz: float  = r * sin(angle) * cos(inc)
	var rot: float = _planet_rotation + ship.orbit_node
	var rx: float  =  px * cos(rot) + pz * sin(rot)
	var rz: float  = -px * sin(rot) + pz * cos(rot)
	var v := _tilted(rx, py, rz)
	return Vector2(v.x, v.y)

func _project_at_node(ship: ShipData, node: float) -> Vector3:
	var r: float   = _planet_radius * ship.orbit_radius
	var inc: float = ship.orbit_inclination
	var a: float   = ship.orbit_angle
	var px: float  = r * cos(a)
	var py: float  = r * sin(a) * sin(inc)
	var pz: float  = r * sin(a) * cos(inc)
	var rot: float = _planet_rotation + node
	var rx: float  =  px * cos(rot) + pz * sin(rot)
	var rz: float  = -px * sin(rot) + pz * cos(rot)
	return _tilted(rx, py, rz)

func _on_ship_changed(ship: ShipData) -> void:
	if ship.orbit_seed == _planet_seed:
		if not _reveal.has(ship.ship_id):
			_reveal[ship.ship_id] = {"progress": 0.0, "spawn_angle": ship.orbit_angle}
		queue_redraw()

## Projects a ship's 3D orbital position to screen (x,y) and returns depth z.
## z > 0 = behind planet, z < 0 = in front.
func _project(ship: ShipData, angle: float) -> Vector3:
	var r: float   = _planet_radius * ship.orbit_radius
	var inc: float = ship.orbit_inclination
	var px: float  = r * cos(angle)
	var py: float  = r * sin(angle) * sin(inc)
	var pz: float  = r * sin(angle) * cos(inc)
	var rot: float = _planet_rotation + ship.orbit_node
	var rx: float  =  px * cos(rot) + pz * sin(rot)
	var rz: float  = -px * sin(rot) + pz * cos(rot)
	return _tilted(rx, py, rz)

## Applies the camera tilt to an orbit-space point (x right, y down, z away from camera),
## matching the planet shader so orbits stay glued to the tilted globe.
func _tilted(x: float, y: float, z: float) -> Vector3:
	var c := cos(_planet_tilt)
	var s := sin(_planet_tilt)
	return Vector3(x, y * c - z * s, y * s + z * c)

func _is_occluded(proj: Vector3) -> bool:
	return proj.z > 0.0 and Vector2(proj.x, proj.y).length() < _planet_radius

## Pixel-art shuttle: T shape (post-booster-separation look).
func _draw_pixel_ship(pos: Vector2, col: Color) -> void:
	var p  := (pos - Vector2.ONE).floor()
	var sz := Vector2(2, 2)
	draw_rect(Rect2(p + Vector2(-2, -2), sz), col)
	draw_rect(Rect2(p + Vector2( 0, -2), sz), col)
	draw_rect(Rect2(p,                   sz), col)

## Pixel-art colony lander: a squat hull on two splayed legs.
func _draw_pixel_lander(pos: Vector2, col: Color) -> void:
	var p := (pos - Vector2.ONE).floor()
	draw_rect(Rect2(p + Vector2(-2, -2), Vector2(6, 4)), col)
	draw_rect(Rect2(p + Vector2(0, -4), Vector2(2, 2)), Color(0.55, 0.75, 1.0, col.a))
	draw_rect(Rect2(p + Vector2(-4, 2), Vector2(2, 2)), Color(col, col.a * 0.8))
	draw_rect(Rect2(p + Vector2(4, 2), Vector2(2, 2)), Color(col, col.a * 0.8))

## Pixel-art ISS: horizontal truss + solar panels + center node.
func _draw_pixel_station(pos: Vector2, col: Color) -> void:
	var p  := (pos - Vector2.ONE).floor()
	var sz := Vector2(2, 2)
	for ox: int in [-4, -2, 0, 2, 4]:
		draw_rect(Rect2(p + Vector2(ox, 0), sz), col)
	draw_rect(Rect2(p + Vector2(0, -2), sz), col)
	draw_rect(Rect2(p + Vector2(0,  2), sz), col)
	draw_rect(Rect2(p + Vector2(-6, -2), sz), col)
	draw_rect(Rect2(p + Vector2(-6,  2), sz), col)
	draw_rect(Rect2(p + Vector2( 6, -2), sz), col)
	draw_rect(Rect2(p + Vector2( 6,  2), sz), col)

## Leader line + name label, like POILayer districts.
## True when the station `label` has a finished `building_id` module.
func _has_module(label: String, building_id: String) -> bool:
	var pp := GameState.get_planet(_planet_seed)
	for b: Dictionary in pp.buildings_in_district(label):
		if b.get("building_id", "") == building_id and not b.get("constructing", false):
			return true
	return false

## A station carrying an Orbital Shipyard: a long dock — two gantry rails with
## ribs, a hull under construction between them and blinking work lights.
func _draw_pixel_shipyard(pos: Vector2, col: Color) -> void:
	var p := pos.floor()
	var rail := col
	var rib := Color(col, col.a * 0.55)
	draw_rect(Rect2(p + Vector2(-16, -7), Vector2(32, 2)), rail)
	draw_rect(Rect2(p + Vector2(-16,  5), Vector2(32, 2)), rail)
	for x in [-16, -8, 0, 8, 14]:
		draw_rect(Rect2(p + Vector2(x, -5), Vector2(2, 10)), rib)
	var hull := Color(0.95, 0.85, 0.60, col.a)
	draw_rect(Rect2(p + Vector2(-10, -2), Vector2(16, 4)), hull)
	draw_rect(Rect2(p + Vector2(6, -1), Vector2(4, 2)), hull)
	draw_rect(Rect2(p + Vector2(-12, -1), Vector2(2, 2)), Color(0.55, 0.75, 1.0, col.a))
	var on := int(Time.get_ticks_msec() / 400) % 2 == 0
	var lamp := Color(1.0, 0.6, 0.15, col.a) if on else Color(0.5, 0.25, 0.05, col.a * 0.6)
	draw_rect(Rect2(p + Vector2(-18, -7), Vector2(2, 2)), lamp)
	draw_rect(Rect2(p + Vector2( 16,  5), Vector2(2, 2)), lamp)
	draw_rect(Rect2(p + Vector2( 16, -7), Vector2(2, 2)), Color(lamp, lamp.a * 0.5) if on else lamp)

func _draw_ship_label(spos: Vector2, ship: ShipData) -> void:
	var font: Font = ThemeDB.fallback_font
	const FONT_SIZE: int = 10
	const DIAG_LEN:  float = 14.0
	const HORIZ_LEN: float = 20.0

	# Pick direction away from planet center
	var center := _planet_center if _planet_center != Vector2.ZERO else size * 0.5
	var horiz_dir: float = 1.0 if spos.x >= center.x else -1.0
	var vert_dir:  float = -1.0 if spos.y >= center.y else 1.0

	var diag_end  := spos + Vector2(horiz_dir * DIAG_LEN * 0.7, vert_dir * DIAG_LEN)
	var horiz_end := diag_end + Vector2(horiz_dir * HORIZ_LEN, 0.0)

	var accent := Color(1.0, 0.92, 0.30, 1.0)   # gold, matches district hover
	var line_col := Color(accent, 0.75)

	# Corner bracket reticle — only the 4 corners, ship sprite stays visible
	const R: float = 10.0   # half-size of bracket box
	const C: float = 4.0    # corner arm length
	const W: float = 1.5    # line width
	var shadow := Color(0, 0, 0, 0.55)
	for ox: int in [-1, 1]:
		for oy: int in [-1, 1]:
			var cx: float = spos.x + ox * R
			var cy: float = spos.y + oy * R
			# Horizontal arm
			draw_line(Vector2(cx, cy), Vector2(cx - ox * C, cy), shadow, W + 1.0, true)
			draw_line(Vector2(cx, cy), Vector2(cx - ox * C, cy), accent, W, true)
			# Vertical arm
			draw_line(Vector2(cx, cy), Vector2(cx, cy - oy * C), shadow, W + 1.0, true)
			draw_line(Vector2(cx, cy), Vector2(cx, cy - oy * C), accent, W, true)

	# Leader lines — start from the corner bracket closest to label direction
	var line_start := spos + Vector2(horiz_dir * R, vert_dir * R)
	draw_line(line_start, diag_end,  line_col, 1.0, true)
	draw_line(diag_end, horiz_end, line_col, 1.0, true)

	# Label
	var label := ship.ship_name
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var label_pos := horiz_end + Vector2(horiz_dir * 3.0, text_size.y * 0.35)
	if horiz_dir < 0.0:
		label_pos.x -= text_size.x

	# Shadow
	for ox: int in [-1, 0, 1]:
		for oy: int in [-1, 0, 1]:
			if ox == 0 and oy == 0:
				continue
			draw_string(font, label_pos + Vector2(ox, oy), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0, 0.85))
	draw_string(font, label_pos, label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, accent)

func _draw() -> void:
	if _planet_seed < 0 or _planet_radius <= 0.0:
		return
	var center := _planet_center if _planet_center != Vector2.ZERO else size * 0.5

	for ship: ShipData in ShipManager.ships_for(_planet_seed):
		if _landing.has(ship.ship_id) or hidden_ships.has(ship.ship_id):
			continue  # drawn by its DescentFX / the planet view's flight

		var is_selected: bool = ship == _selected_ship
		var is_hovered:  bool = ship == _hovered_ship

		# ── Orbit path ───────────────────────────────────────────────────────────
		var steps := 90
		var orbit_col: Color
		if is_selected:
			orbit_col = Color(1.0, 0.92, 0.30, 0.75)   # gold, matches district hover
		elif is_hovered:
			orbit_col = Color(1.0, 0.95, 0.5, 0.55)    # warm gold
		elif ship.is_travelling():
			orbit_col = Color(1, 1, 1, 0.45)
		else:
			orbit_col = Color(1, 1, 1, 0.30)

		var rv: Dictionary = _reveal.get(ship.ship_id, {})
		var arc_frac:    float = rv.get("progress",    1.0)
		var spawn_angle: float = rv.get("spawn_angle", 0.0)
		var dir: float = sign(ship.orbit_speed) if ship.orbit_speed != 0.0 else 1.0
		var arc_total: float   = arc_frac * TAU
		var prev_v   := _project(ship, spawn_angle)
		var prev_pos := center + Vector2(prev_v.x, prev_v.y)
		for s in range(1, steps + 1):
			var frac: float = float(s) / float(steps)
			if frac * TAU > arc_total:
				break
			var a: float = spawn_angle + dir * frac * TAU
			var v        := _project(ship, a)
			var cur_pos  := center + Vector2(v.x, v.y)
			var in_dash: bool = (s % 6) < 3
			if in_dash and not _is_occluded(prev_v) and not _is_occluded(v):
				draw_line(prev_pos, cur_pos, orbit_col, 1.5 if is_selected else 1.2, true)
			prev_v   = v
			prev_pos = cur_pos

		# ── Ship pixel art ───────────────────────────────────────────────────────
		var sv := _project(ship, ship.orbit_angle)
		if _is_occluded(sv):
			continue
		var spos := center + Vector2(sv.x, sv.y)
		var col: Color
		if is_selected:
			col = Color(1.0, 0.92, 0.30, 1.0)   # gold
		elif is_hovered:
			col = Color(1.0, 0.92, 0.40)
		else:
			col = Color(1, 1, 1, 0.92)

		if ship.ship_type == "station":
			_draw_pixel_station(spos, col)
		elif ship.ship_type == "lander":
			_draw_pixel_lander(spos, col)
		else:
			_draw_pixel_ship(spos, col)

		# ── Selected: bracket reticle + label (suppressed when panel open)
		# ── Hovered (not selected): leader line + name, like districts
		if is_selected:
			if suppress_label:
				_draw_brackets_only(spos)
			else:
				_draw_ship_label(spos, ship)
		elif is_hovered:
			_draw_hover_label(spos, ship)

	# ── Landing animations ───────────────────────────────────────────────────

	# ── Space station districts ───────────────────────────────────────────────
	_draw_station_pois(center)

func _bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var mt := 1.0 - t
	return mt * mt * p0 + 2.0 * mt * t * p1 + t * t * p2

## Like _project but with a custom orbit_radius fraction (for landing spiral).
func _project_r(ship: ShipData, angle: float, orbit_r: float) -> Vector2:
	var center := _planet_center if _planet_center != Vector2.ZERO else size * 0.5
	var r: float   = _planet_radius * orbit_r
	var inc: float = ship.orbit_inclination
	var px: float  = r * cos(angle)
	var py: float  = r * sin(angle) * sin(inc)
	var pz: float  = r * sin(angle) * cos(inc)
	var rot: float = _planet_rotation + ship.orbit_node
	var rx: float  =  px * cos(rot) + pz * sin(rot)
	var rz: float  = -px * sin(rot) + pz * cos(rot)
	var v := _tilted(rx, py, rz)
	return center + Vector2(v.x, v.y)

## Hover nameplate: leader line + name only, no bracket reticle. Like districts on hover.
func _draw_hover_label(spos: Vector2, ship: ShipData) -> void:
	var font: Font = ThemeDB.fallback_font
	const FONT_SIZE: int = 10
	var center := _planet_center if _planet_center != Vector2.ZERO else size * 0.5
	var horiz_dir: float = 1.0 if spos.x >= center.x else -1.0
	var vert_dir:  float = -1.0 if spos.y >= center.y else 1.0
	var diag_end  := spos + Vector2(horiz_dir * 9.8,   vert_dir * 14.0)
	var horiz_end := diag_end + Vector2(horiz_dir * 20.0, 0.0)
	var accent := Color(1.0, 0.95, 0.55, 0.85)
	draw_line(spos, diag_end,  Color(accent, 0.65), 1.0, true)
	draw_line(diag_end, horiz_end, Color(accent, 0.65), 1.0, true)
	var label := ship.ship_name
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var label_pos := horiz_end + Vector2(horiz_dir * 3.0, text_size.y * 0.35)
	if horiz_dir < 0.0:
		label_pos.x -= text_size.x
	for ox: int in [-1, 0, 1]:
		for oy: int in [-1, 0, 1]:
			if ox == 0 and oy == 0: continue
			draw_string(font, label_pos + Vector2(ox, oy), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0, 0.75))
	draw_string(font, label_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, accent)

func _draw_brackets_only(spos: Vector2) -> void:
	const R: float = 10.0
	const C: float = 4.0
	const W: float = 1.5
	var accent := Color(1.0, 0.92, 0.30, 1.0)
	var shadow := Color(0, 0, 0, 0.55)
	for ox: int in [-1, 1]:
		for oy: int in [-1, 1]:
			var cx: float = spos.x + ox * R
			var cy: float = spos.y + oy * R
			draw_line(Vector2(cx, cy), Vector2(cx - ox * C, cy), shadow, W + 1.0, true)
			draw_line(Vector2(cx, cy), Vector2(cx - ox * C, cy), accent, W, true)
			draw_line(Vector2(cx, cy), Vector2(cx, cy - oy * C), shadow, W + 1.0, true)
			draw_line(Vector2(cx, cy), Vector2(cx, cy - oy * C), accent, W, true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _drag_ship != null:
			var dx: float = event.global_position.x - _drag_last_x
			_drag_last_x = event.global_position.x
			_drag_ship.orbit_node += dx * 0.012
			# Re-find orbit_angle so ship stays at anchor screen position (ring rotates, ship fixed).
			var a: float = _drag_ship.orbit_angle
			for _i in 10:
				var p0: Vector2 = _project_2d(_drag_ship, a)
				var p1: Vector2 = _project_2d(_drag_ship, a + 0.005)
				var tangent: Vector2 = (p1 - p0) / 0.005
				var err: Vector2 = p0 - _drag_anchor
				if tangent.length_squared() < 0.0001:
					break
				a -= err.dot(tangent) / tangent.length_squared()
			_drag_ship.orbit_angle = a
			# Dragging manually cancels any active rendezvous
			if _drag_ship.rendezvous_target_id != "":
				_drag_ship.orbit_speed          = _drag_ship.rendezvous_base_speed
				_drag_ship.rendezvous_target_id  = ""
				_drag_ship.rendezvous_base_speed = 0.0
			queue_redraw()
			accept_event()
			return
		var prev := _hovered_ship
		_hovered_ship = _ship_at(event.global_position, true)   # landers show their name too
		if _hovered_ship != prev:
			queue_redraw()
			if _hovered_ship != null:
				ship_hovered.emit(_hovered_ship, event.global_position)
				CursorManager.set_state(CursorManager.State.NORMAL if _hovered_ship.ship_type == "lander" \
					else CursorManager.State.POINTER)
			else:
				ship_unhovered.emit()
				CursorManager.set_state(CursorManager.State.NORMAL)
		# Station hover
		var local_pos := get_local_mouse_position()
		var prev_st := _hovered_station
		_hovered_station = _station_poi_at(local_pos)
		if _hovered_station != prev_st:
			queue_redraw()
			if _hovered_station != "":
				AudioManager.play("district_hover")
				CursorManager.set_state(CursorManager.State.POINTER)
			else:
				CursorManager.set_state(CursorManager.State.NORMAL)

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if _selected_station != "":
				_selected_station = ""
				queue_redraw()
				accept_event()
				return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				# Check station click first
				var local_pos := get_local_mouse_position()
				var st := _station_poi_at(local_pos)
				if st != "":
					AudioManager.play("click")
					station_poi_clicked.emit(st)
					accept_event()
					return
				var clicked := _ship_at(mb.global_position)
				if clicked != null:
					_selected_ship = clicked
					_drag_ship     = clicked
					_drag_last_x   = mb.global_position.x
					var sv := _project(clicked, clicked.orbit_angle)
					_drag_anchor   = Vector2(sv.x, sv.y)
					queue_redraw()
					ship_clicked.emit(clicked)
					accept_event()
			else:
				if _drag_ship != null:
					_drag_ship = null

## ── Space Station POI drawing ────────────────────────────────────────────────

signal station_poi_clicked(poi_label: String)

var _hovered_station:  String = ""
var _selected_station: String = ""

func set_selected_station(label: String) -> void:
	_selected_station = label
	queue_redraw()

func _draw_station_pois(center: Vector2) -> void:
	var pd := GameState.get_planet_data(_planet_seed)
	if pd == null:
		return
	for poi: POIData in pd.custom_pois:
		if not poi.is_orbital():
			continue
		if poi.constructing:
			continue   # hidden while rocket is in flight; deploy anim plays on arrival
		var is_selected: bool = poi.label == _selected_station
		var is_hovered:  bool = poi.label == _hovered_station
		var col: Color
		if is_selected:
			col = Color(1.0, 0.92, 0.30, 1.0)   # gold — matches ship selected
		elif is_hovered:
			col = Color(1.0, 0.95, 0.5, 0.90)
		else:
			col = Color(0.65, 0.75, 1.0, 0.85)
		# Dashed orbit trail (progressive reveal on first appearance)
		var orbit_col: Color
		if is_selected:
			orbit_col = Color(1.0, 0.92, 0.30, 0.75)
		elif is_hovered:
			orbit_col = Color(1.0, 0.95, 0.5, 0.55)
		else:
			orbit_col = Color(col, 0.30)
		if not _reveal_poi.has(poi.label):
			_reveal_poi[poi.label] = {"progress": 0.0, "spawn_angle": poi.orbit_angle}
		var rv_poi: Dictionary = _reveal_poi[poi.label]
		var arc_frac: float = rv_poi["progress"]
		var spawn_a:  float = rv_poi["spawn_angle"]
		var dir_p:    float = sign(poi.orbit_speed) if poi.orbit_speed != 0.0 else 1.0
		var arc_total: float = arc_frac * TAU
		const STEPS := 72
		var prev_v  := _project_poi(poi, spawn_a)
		var prev_p  := center + Vector2(prev_v.x, prev_v.y)
		for s in range(1, STEPS + 1):
			var frac: float = float(s) / float(STEPS)
			if frac * TAU > arc_total:
				break
			var a := spawn_a + dir_p * frac * TAU
			var v := _project_poi(poi, a)
			var p := center + Vector2(v.x, v.y)
			if (s % 6) < 3 and not _is_occluded_r(prev_v) \
					and not _is_occluded_r(v):
				draw_line(prev_p, p, orbit_col, 1.5 if is_selected else 1.2, true)
			prev_v = v; prev_p = p
		# Icon
		var sv := _project_poi(poi, poi.orbit_angle)
		if _is_occluded_r(sv):
			continue
		var spos := center + Vector2(sv.x, sv.y)
		if _has_module(poi.label, "orbital_shipyard"):
			_draw_pixel_shipyard(spos, col)
		else:
			_draw_pixel_station(spos, col)
		if is_selected:
			_draw_station_label(spos, poi.shown_name())
		elif is_hovered and not suppress_label:
			_draw_station_label(spos, poi.shown_name())

func _draw_station_label(spos: Vector2, label: String) -> void:
	var font := ThemeDB.fallback_font
	const FS := 10; const DL := 14.0; const HL := 20.0
	var center  := _planet_center if _planet_center != Vector2.ZERO else size * 0.5
	var hd      := 1.0 if spos.x >= center.x else -1.0
	var vd      := -1.0 if spos.y >= center.y else 1.0
	var de      := spos + Vector2(hd * DL * 0.7, vd * DL)
	var he      := de + Vector2(hd * HL, 0.0)
	var accent  := Color(1.0, 0.92, 0.30, 1.0)
	var lc      := Color(accent, 0.75)
	const R := 10.0; const C := 4.0; const W := 1.5
	var shadow := Color(0, 0, 0, 0.55)
	for ox: int in [-1, 1]:
		for oy: int in [-1, 1]:
			var cx := spos.x + ox * R; var cy := spos.y + oy * R
			draw_line(Vector2(cx, cy), Vector2(cx - ox * C, cy), shadow, W + 1, true)
			draw_line(Vector2(cx, cy), Vector2(cx - ox * C, cy), accent, W, true)
			draw_line(Vector2(cx, cy), Vector2(cx, cy - oy * C), shadow, W + 1, true)
			draw_line(Vector2(cx, cy), Vector2(cx, cy - oy * C), accent, W, true)
	draw_line(spos, de, lc, 1.0, true); draw_line(de, he, lc, 1.0, true)
	var ts  := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FS)
	var lp  := he + Vector2(hd * 3.0, ts.y * 0.35)
	if hd < 0.0: lp.x -= ts.x
	for ox: int in [-1, 0, 1]:
		for oy: int in [-1, 0, 1]:
			if ox == 0 and oy == 0: continue
			draw_string(font, lp + Vector2(ox, oy), label, HORIZONTAL_ALIGNMENT_LEFT, -1, FS, Color(0,0,0,0.85))
	draw_string(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, FS, accent)

## Projects POIData orbital position to 3D (z > 0 = behind planet).
func _project_poi(poi: POIData, angle: float) -> Vector3:
	var r   := _planet_radius * poi.orbit_radius
	var inc := poi.orbit_inclination
	var px  := r * cos(angle)
	var py  := r * sin(angle) * sin(inc)
	var pz  := r * sin(angle) * cos(inc)
	var rot := _planet_rotation + poi.orbit_node
	var rx  :=  px * cos(rot) + pz * sin(rot)
	var rz  := -px * sin(rot) + pz * cos(rot)
	return _tilted(rx, py, rz)

func _is_occluded_r(proj: Vector3) -> bool:
	return proj.z > 0.0 and Vector2(proj.x, proj.y).length() < _planet_radius

func _station_poi_at(local_pos: Vector2) -> String:
	if _planet_seed < 0 or _planet_radius <= 0.0:
		return ""
	var center := _planet_center if _planet_center != Vector2.ZERO else size * 0.5
	var pd := GameState.get_planet_data(_planet_seed)
	if pd == null:
		return ""
	for poi: POIData in pd.custom_pois:
		if not poi.is_orbital():
			continue
		var sv := _project_poi(poi, poi.orbit_angle)
		if _is_occluded_r(sv):
			continue
		var hit_r := 20.0 if _has_module(poi.label, "orbital_shipyard") else 12.0
		if local_pos.distance_to(center + Vector2(sv.x, sv.y)) <= hit_r:
			return poi.label
	return ""

## Ship under the cursor. The colony lander only answers hover (its name) —
## it takes orders from Found First Settlement, not clicks.
func _ship_at(global_pos: Vector2, include_landers := false) -> ShipData:
	if _planet_seed < 0 or _planet_radius <= 0.0:
		return null
	var center := get_global_rect().position + (_planet_center if _planet_center != Vector2.ZERO else size * 0.5)
	for ship: ShipData in ShipManager.ships_for(_planet_seed):
		if ship.ship_type == "lander" and not include_landers:
			continue
		var sv := _project(ship, ship.orbit_angle)
		if _is_occluded(sv):
			continue
		var spos := center + Vector2(sv.x, sv.y)
		if global_pos.distance_to(spos) <= 8.0:
			return ship
	return null
