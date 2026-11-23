## Planet System view — a world and its moons, between the planet view and the
## Star System (Mechanic-Test/Star-Map; first base, replacing the planet view's
## top-right moon corner, CompanionBodies, step by step).
##
## Reached straight from the planet view by zooming out past its farthest zoom
## (no detour through the Star System). The planet sits in the middle, its
## moons stand still on their orbits round it on a tilted plane, laid out by
## the very rules the Star System uses (StarSystemView.moon_angle / moon_orbit,
## the same sizes ×SIZE_K), so going between the two lines up; the sun lights
## them from where it really is. Any drag (or two fingers) turns and tilts it
## (no panning: it stays on the world), wheel / pinch zooms;
## hover gives a body its rim and name, a click picks it, a second click (or
## zooming on into it) goes down to its planet view. Zooming out past the
## farthest zoom goes up to the Star System, framed on this world.
## Every switch is SceneTransition.go_soft with matched sizes, as elsewhere.
extends Control

const PLANET_SCENE := "res://scenes/planetary/PlanetaryView.tscn"
const SYSTEM_SCENE := "res://scenes/starsystem/StarSystemView.tscn"
const SystemView := preload("res://scripts/starsystem/StarSystemView.gd")

const ZOOM_MIN := 0.8
const ZOOM_MAX := 4.0
const ZOOM_STEP := 1.2
const TILT_MIN := 0.16
const TILT_MAX := 0.85
const CAM_TIME := 0.18
const ENTER_CHARGE := 2
const ENTER_PINCH := 1.4
const EXIT_CHARGE := 3
const EXIT_PINCH := 0.7
## Going up: the view shrinks to this before the Star System takes over.
const EXIT_ZOOM := 0.55
const EXIT_SEC := 0.35
## Coming up from a planet view the camera eases out to this (all moons in).
const ARRIVE_ZOOM := 1.0

const NO_MARKERS := true
## Everything is the Star System's layout ×SIZE_K at zoom 1 (px at 1080 p).
const SIZE_K := 3.6
## Coming down from the Star System the camera goes on closing in to this.
const ARRIVE_FROM_SYSTEM := 1.25

const RING_COL := Color(0.72, 0.84, 1.0, 0.26)
const SEL_COL := Color(0.55, 0.95, 1.0, 0.9)

@onready var _space: Control = $Space
@onready var _panel: LeftPanel = $SidePanel

var _planet: PlanetData
var _solar: SolarData
## [{ pd, r (orbit, 0 = the planet), a, rad (px at zoom 1), rect, mat, spin }]
var _bodies: Array[Dictionary] = []
var _back: Node2D
var _front: Node2D
var _sky: Dictionary = {}
var _outer := 300.0
## Towards the sun, on the plane (from the planet).
var _sun_dir := Vector2(-1, 0)
## The look: the sun's glow off towards it, the planet's air glow, the markers.
var _sun_glow: Sprite2D
var _air_glow: Sprite2D
## Flights between bodies (test for now): [{ from, to, t, dur }].
var _flights: Array[Dictionary] = []

var _yaw := 0.5
var _yaw_t := 0.5
var _yaw_v := 0.0
var _tilt := 0.42
var _tilt_t := 0.42
var _tilt_v := 0.0
var _zoom := 1.0
var _zoom_t := 1.0
var _zoom_v := 0.0
var _focus := Vector2.ZERO
var _focus_t := Vector2.ZERO
var _focus_v := Vector2.ZERO

var _hover := -1
var _selected := -1
var _entering := -1
var _leaving := false
var _enter_charge := 0
var _enter_pinch := 1.0
var _exit_charge := 0
var _exit_pinch := 1.0
var _drag_btn := -1
var _drag_moved := 0.0
var _time := 0.0

const PANEL_SLIDE_SEC := 0.9
var _panel_open := true
var _panel_t := 1.0
var _panel_tween: Tween = null
var _panel_toggle_btn: Button = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	HUDManager.set_game_hud(not GameState.showcase_mode)
	CursorManager.set_state(CursorManager.State.NORMAL)
	_sky = Starfield.apply($Background as ColorRect, {"density": 0.055, "brightness": 0.85, "nebula": 0.12})
	_back = Node2D.new()
	_back.z_index = 0
	_front = Node2D.new()
	_front.z_index = 200
	for n: Node2D in [_back, _front]:
		n.z_as_relative = false
		_space.add_child(n)
	_back.draw.connect(_draw_back)
	_front.draw.connect(_draw_front)
	_panel.visible = not GameState.showcase_mode
	if GameState.showcase_mode:
		_panel_open = false
		_panel_t = 0.0
	_build_panel_toggle()
	_apply_panel_t(_panel_t)
	tree_exiting.connect(func() -> void: HUDManager.set_view_area_fraction(1.0 - LeftPanel.edge_frac()))

	var pending = SceneTransition.pending_data
	SceneTransition.pending_data = null
	var from: PlanetData = pending if pending is PlanetData else null
	if from == null:
		from = GameState.get_home_planet()
	await get_tree().process_frame
	_load(from)
	_arrive_from(from)
	NavigationManager.end_apply()


func nav_apply(_entry: Dictionary) -> bool:
	NavigationManager.end_apply()
	return true


# ── Building ─────────────────────────────────────────────────────────────────

## The world to show for `body`: a moon shows its planet (the moon picked).
func _load(body: PlanetData) -> void:
	_solar = body.get_meta("__solar_data") if body.has_meta("__solar_data") else GameState.get_home_solar()
	_planet = body
	if _solar != null:
		for pd: PlanetData in _solar.planets:
			if body in pd.moons:
				_planet = pd
	if _planet.moons.is_empty() and _planet.planet_type != PlanetData.Type.MOON:
		_planet.generate_moons(_planet.seed)
	var p_diam := SystemView.planet_px(_planet) * SIZE_K
	_add_body(_planet, 0.0, 0.0, p_diam * 0.5)
	for j in _planet.moons.size():
		var m: PlanetData = _planet.moons[j]
		var r := SystemView.moon_orbit(p_diam, j)
		_add_body(m, r, SystemView.moon_angle(_planet.seed, j), SystemView.moon_px(m) * SIZE_K * 0.5)
		_outer = maxf(_outer, r)
	_outer = maxf(_outer, p_diam * 1.4)
	# where the sun is: the planet's place round its star, seen from the planet
	_sun_dir = Vector2(-1, -0.4).normalized()
	if _solar != null:
		var pi_ := _solar.planets.find(_planet)
		if pi_ >= 0:
			_sun_dir = -Vector2.from_angle(SystemView.planet_angle(_solar, pi_))
	_make_look()
	_build_panel()


func _add_body(pd: PlanetData, r: float, a: float, rad: float) -> void:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_as_relative = false
	var mat: ShaderMaterial = SystemView._planet_material(pd)
	rect.material = mat
	_space.add_child(rect)
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_as_relative = false
	badge.z_index = 191
	var lbl := Label.new()
	lbl.text = pd.planet_name.to_upper()
	lbl.theme_type_variation = &"CounterLabel"
	badge.add_child(lbl)
	badge.visible = false
	_space.add_child(badge)
	_bodies.append({"pd": pd, "r": r, "a": a, "rad": rad, "rect": rect, "mat": mat, "badge": badge,
		"spin": float(pd.seed % 360) * 0.0175})


# ── Camera & projection ──────────────────────────────────────────────────────

func _ui() -> float:
	return maxf(_space.size.y, 1.0) / 1080.0


func _scale() -> float:
	return _zoom * _ui()


func _center() -> Vector2:
	return _space.size * 0.5 + Vector2(0, _space.size.y * 0.04)


func _project(p: Vector2) -> Vector3:
	var d := p - _focus
	var c := cos(_yaw)
	var s := sin(_yaw)
	var rx := d.x * c - d.y * s
	var ry := d.x * s + d.y * c
	var k := _scale()
	return Vector3(_center().x + rx * k, _center().y + ry * _tilt * k, ry)


func _unproject_at(sp: Vector2, focus: Vector2, zoom: float) -> Vector2:
	var k := zoom * _ui()
	var rx := (sp.x - _center().x) / k
	var ry := (sp.y - _center().y) / (k * _tilt_t)
	var c := cos(_yaw_t)
	var sn := sin(_yaw_t)
	return focus + Vector2(rx * c + ry * sn, -rx * sn + ry * c)


func _plane(i: int) -> Vector2:
	var b := _bodies[i]
	return Vector2.from_angle(float(b["a"])) * float(b["r"])


func _px(i: int) -> float:
	return float(_bodies[i]["rad"]) * 2.0 * _scale()


## The zoom at which body i is as big as the planet view draws it at `pv_zoom`
## (PlanetaryView: radius = clamp(0.42 × size, 0.10, 0.48) of the view height).
func _zoom_for_pv(i: int, pv_zoom: float) -> float:
	var pd: PlanetData = _bodies[i]["pd"]
	var diam := 2.0 * clampf(0.42 * clampf(pd.planet_size, 0.2, 2.0), 0.10, 0.48) * _space.size.y * pv_zoom
	return diam / maxf(float(_bodies[i]["rad"]) * 2.0 * _ui(), 1.0)


## The planet view's zoom that draws body i as big as it is here now.
func _pv_zoom_of(i: int) -> float:
	var pd: PlanetData = _bodies[i]["pd"]
	var diam := 2.0 * clampf(0.42 * clampf(pd.planet_size, 0.2, 2.0), 0.10, 0.48) * _space.size.y
	return _px(i) / maxf(diam, 1.0)


# ── Frame ────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _bodies.is_empty():
		return
	_time += delta
	var r := Spring.damp_angle(_yaw, _yaw_v, _yaw_t, CAM_TIME, delta)
	_yaw = r.x
	_yaw_v = r.y
	r = Spring.damp(_tilt, _tilt_v, _tilt_t, CAM_TIME, delta)
	_tilt = r.x
	_tilt_v = r.y
	r = Spring.damp(_zoom, _zoom_v, _zoom_t, CAM_TIME * (1.6 if _entering >= 0 else 1.0), delta)
	_zoom = r.x
	_zoom_v = r.y
	var f := Spring.damp_v2(_focus, _focus_v, _focus_t, CAM_TIME, delta)
	_focus = f[0]
	_focus_v = f[1]
	Skybox.follow(_sky, _yaw, _tilt, Vector2.ZERO, _ui())   # the sky turns with the camera
	_place_bodies(delta)
	for fl: Dictionary in _flights:
		fl["t"] = float(fl["t"]) + delta
	var live: Array[Dictionary] = []   # (filter() would hand back an untyped Array)
	for fl: Dictionary in _flights:
		if float(fl["t"]) < float(fl["dur"]) + 0.6:
			live.append(fl)
	_flights = live
	_back.queue_redraw()
	_front.queue_redraw()
	if _entering >= 0 and not _leaving and _zoom >= _zoom_t * 0.96:
		_hand_over(_entering)


func _place_bodies(delta: float) -> void:
	var planet_p := _project(Vector2.ZERO)
	_place_look(planet_p)
	for i in _bodies.size():
		var b := _bodies[i]
		var p := _project(_plane(i))
		var px := _px(i)
		var rect: ColorRect = b["rect"]
		rect.size = Vector2(px, px) / 0.8   # the shader's disc is 0.4 of the rect
		rect.position = Vector2(p.x, p.y) - rect.size * 0.5
		# depth: moons behind the planet go under it
		rect.z_index = 50 if i == 0 else (60 if p.z > planet_p.z else 40)
		var mat: ShaderMaterial = b["mat"]
		mat.set_shader_parameter("pixel_count", clampf(px * 0.55, 16.0, 150.0))
		b["spin"] = fposmod(float(b["spin"]) + 0.08 * delta, TAU)
		# turning the view turns the globes with it: the camera goes round them,
		# so another side of each faces it (+yaw moves the near side the way the
		# moons in front move)
		mat.set_shader_parameter("rotation_offset", fposmod(float(b["spin"]) + _yaw, TAU))
		# lit from where the sun really is (as the Star System lights them)
		var sp := _project(_plane(i) + _sun_dir * 5000.0)
		var to_sun := Vector2(sp.x - p.x, sp.y - p.y)
		mat.set_shader_parameter("light_direction", Vector3(to_sun.x, to_sun.y, to_sun.length() * 0.9).normalized())
		var px_rim := 1.0
		var col := Color(1, 1, 1, 0.32)
		if i == _selected:
			px_rim = 2.0
			col = Color(SEL_COL, 0.65 + 0.35 * (0.5 + 0.5 * sin(_time * 3.0)))
		elif i == _hover:
			col = Color(1, 1, 1, 0.85)
		mat.set_shader_parameter("rim_px", px_rim)
		mat.set_shader_parameter("rim_color", col)
		var badge: PanelContainer = b["badge"]
		badge.visible = i == _hover or i == _selected
		if badge.visible:
			badge.size = badge.get_combined_minimum_size()
			var cell: PanelContainer = b.get("cell")
			if cell != null:
				badge.position = (cell.position + Vector2(cell.size.x + 6.0, (cell.size.y - badge.size.y) * 0.5)).round()
			else:
				badge.position = (Vector2(p.x, p.y - px * 0.5 - 8.0) - Vector2(badge.size.x * 0.5, badge.size.y)).round()


# ── Drawing ──────────────────────────────────────────────────────────────────

func _draw_back() -> void:
	if _bodies.is_empty():
		return
	var acc := UIStyle.color(&"accent")
	# HUD lines like the other maps: one glowing guide ring with a scale of
	# ticks past the moons
	var r_out := _outer * 1.25
	_ring(r_out, Color(acc, 0.05), 6.0, false)
	_ring(r_out, Color(acc, 0.32), 1.3, false)
	for k in 72:
		var d := Vector2.from_angle(TAU * float(k) / 72.0)
		var a := _project(d * r_out)
		var b := _project(d * r_out * (1.04 if k % 6 == 0 else 1.02))
		_back.draw_line(Vector2(a.x, a.y), Vector2(b.x, b.y), Color(acc, 0.22), 1.0, true)
	# a moon's orbit only while it is hovered / picked (as in the Star System)
	for i in range(1, _bodies.size()):
		if i == _hover or i == _selected:
			_ring(float(_bodies[i]["r"]), Color(SEL_COL, 0.75 if i == _selected else 0.5), 1.5, true)


func _ring(r: float, col: Color, w: float, dash: bool) -> void:
	var n := 120
	var prev := _project(Vector2(r, 0.0))
	for k in range(1, n + 1):
		var p := _project(Vector2.from_angle(TAU * float(k) / float(n)) * r)
		if not dash or k % 4 < 2:
			_back.draw_line(Vector2(prev.x, prev.y), Vector2(p.x, p.y), col, w, true)
		prev = p


# ── Flights (rockets / landers between bodies) — tried from the debug popup ──

## Buttons for DebugPopup.
func debug_actions() -> Array:
	var out: Array = []
	if _bodies.size() > 1:
		out.append({"name": "Rocket: %s → %s" % [_bodies[0]["pd"].planet_name, _bodies[1]["pd"].planet_name],
			"call": func() -> void: fly(0, 1)})
		out.append({"name": "Rocket: %s → %s" % [_bodies[1]["pd"].planet_name, _bodies[0]["pd"].planet_name],
			"call": func() -> void: fly(1, 0)})
		out.append({"name": "Three rockets, staggered", "call": func() -> void:
			fly(0, 1)
			get_tree().create_timer(0.5).timeout.connect(func() -> void: fly(0, 1))
			get_tree().create_timer(1.0).timeout.connect(func() -> void: fly(1, 0))})
	out.append({"name": "Spin the view", "call": func() -> void: _yaw_t += PI * 0.5})
	return out


## Sends a rocket from body a to body b (a curved climb, a coast, an arrival).
func fly(a: int, b: int, dur := 3.2) -> void:
	_flights.append({"from": a, "to": b, "t": 0.0, "dur": dur, "side": 1.0 if _flights.size() % 2 == 0 else -1.0})


## Where a flight is at share u (0..1): leaves body a's surface, arcs out to
## one side and up off the plane, comes down onto body b. Screen position.
func _flight_point(fl: Dictionary, u: float) -> Vector2:
	var a := int(fl["from"])
	var b := int(fl["to"])
	var pa := _plane(a)
	var pb := _plane(b)
	var dir := (pb - pa).normalized()
	var start := pa + dir * float(_bodies[a]["rad"])
	var end := pb - dir * float(_bodies[b]["rad"])
	var side := Vector2(-dir.y, dir.x) * float(fl["side"]) * start.distance_to(end) * 0.25
	var q := start.lerp(end, u) + side * sin(u * PI)
	var lift := start.distance_to(end) * 0.22 * sin(u * PI)
	var p := _project(q)
	var up := sqrt(maxf(0.0, 1.0 - _tilt * _tilt))
	return Vector2(p.x, p.y - lift * _scale() * up)


func _draw_flights() -> void:
	for fl: Dictionary in _flights:
		var dur: float = fl["dur"]
		var t: float = fl["t"]
		var u := clampf(t / dur, 0.0, 1.0)
		u = u * u * (3.0 - 2.0 * u)   # eased: slow off, slow in
		var fade := 1.0 - clampf((t - dur) / 0.6, 0.0, 1.0)
		# the trail: dots along the way it came, fading
		for k in 24:
			var uu := u - float(k) * 0.012
			if uu <= 0.0:
				break
			var tp := _flight_point(fl, uu)
			_front.draw_rect(Rect2(tp.round() - Vector2.ONE, Vector2(2, 2)),
				Color(1.0, 0.75, 0.4, (1.0 - float(k) / 24.0) * 0.8 * fade))
		if t > dur:
			continue
		# the rocket: a small arrow along its way, a flickering flame behind
		var p := _flight_point(fl, u)
		var ahead := _flight_point(fl, minf(u + 0.01, 1.0))
		var d := (ahead - p).normalized() if ahead.distance_to(p) > 0.01 else Vector2.RIGHT
		var n := Vector2(-d.y, d.x)
		var s := 6.0
		_front.draw_colored_polygon(PackedVector2Array([p + d * s, p - d * s * 0.7 + n * s * 0.55, p - d * s * 0.7 - n * s * 0.55]),
			Color(0.95, 0.97, 1.0))
		var flame := 0.6 + 0.4 * sin(_time * 40.0)
		_front.draw_circle(p - d * s * 1.1, 2.5 * flame, Color(1.0, 0.6, 0.25, 0.9))


func _draw_front() -> void:
	_draw_flights()
	# markers' stems (settled worlds carry an icon cell, as in the Star System)
	for i in _bodies.size():
		var cell: PanelContainer = _bodies[i].get("cell")
		if cell == null or not cell.visible:
			continue
		var p := _project(_plane(i))
		_front.draw_line(Vector2(p.x, p.y - _px(i) * 0.5 - 3.0), cell.position + Vector2(cell.size.x * 0.5, cell.size.y),
			Color(1, 1, 1, 0.6), 1.0)


## The sun's glow (additive, off towards the sun, at the frame's edge), the
## planet's air glow, and an icon cell over each settled body.
func _make_look() -> void:
	var sun_col := Color(1.0, 0.85, 0.6)
	if _solar != null:
		var c: Vector3 = SolarData.get_star_colors(_solar.star_type)["surface"]
		sun_col = Color(c.x, c.y, c.z)
	_sun_glow = _glow_sprite(sun_col, 0.22, 2)
	var air := Color(0.5, 0.7, 1.0)
	var pc := PlanetData.get_colors(_planet.planet_type)
	if pc.has("color_atmosphere"):
		var v: Vector3 = pc["color_atmosphere"]
		air = Color(v.x, v.y, v.z)
	_air_glow = _glow_sprite(air, 0.35 if _planet.has_atmosphere else 0.12, 45)
	# (no icon markers here: the list and the hover names say what is what)
	for i in (range(0) if NO_MARKERS else range(_bodies.size())):
		var pd: PlanetData = _bodies[i]["pd"]
		var pp := GameState.find_planet(pd.seed)
		var settled := pd.seed == GameState.home_planet_seed or (pp != null and pp.is_colonized)
		if not settled:
			continue
		var cell := PanelContainer.new()
		cell.theme_type_variation = &"IconCell"
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.z_as_relative = false
		cell.z_index = 190
		var icon := TextureRect.new()
		icon.texture = UIIcons.get_icon("city" if pd.seed == GameState.home_planet_seed else ("moon" if i > 0 else "planet"))
		icon.self_modulate = UIStyle.color(&"accent")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(18, 18)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)
		_space.add_child(cell)
		_bodies[i]["cell"] = cell


func _glow_sprite(col: Color, strength: float, z: int) -> Sprite2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([Color(col, strength), Color(col, strength * 0.45), Color(col, strength * 0.12), Color(col, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	var spr := Sprite2D.new()
	spr.texture = t
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spr.material = mat
	spr.z_as_relative = false
	spr.z_index = z
	_space.add_child(spr)
	return spr


func _place_look(planet_p: Vector3) -> void:
	if _sun_glow == null:
		return
	# the sun's glow sits where the sun is, pulled back to the frame's edge
	var sp := _project(_sun_dir * 5000.0)
	var c := _center()
	var dir := Vector2(sp.x, sp.y) - c
	var edge := minf(_space.size.x, _space.size.y) * 0.62
	_sun_glow.position = c + dir.limit_length(edge)
	_sun_glow.scale = Vector2.ONE * (_space.size.y * 0.7 / 128.0)
	_air_glow.position = Vector2(planet_p.x, planet_p.y)
	_air_glow.scale = Vector2.ONE * (_px(0) * 0.78 / 128.0)
	for i in _bodies.size():
		var cell: PanelContainer = _bodies[i].get("cell")
		if cell == null:
			continue
		var p := _project(_plane(i))
		cell.size = cell.get_combined_minimum_size()
		cell.position = (Vector2(p.x, p.y - _px(i) * 0.5 - 3.0 - 20.0) - Vector2(cell.size.x * 0.5, cell.size.y)).round()


# ── Input ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _bodies.is_empty() or _leaving:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var lp := _space.get_global_transform().affine_inverse() * mm.global_position
		if _drag_btn >= 0:
			_drag_moved += mm.relative.length()
			_turn(mm.relative)   # any drag turns: this view stays on its world
			get_viewport().set_input_as_handled()
			return
		var h := _body_at(lp)
		if h != _hover:
			if h >= 0:
				AudioManager.play("hover")
			_hover = h
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var lp := _space.get_global_transform().affine_inverse() * mb.global_position
		match mb.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if mb.pressed:
					_drag_btn = mb.button_index
					_drag_moved = 0.0
				elif _drag_btn == mb.button_index:
					_drag_btn = -1
					if _drag_moved < 6.0 and mb.button_index == MOUSE_BUTTON_LEFT:
						_click(lp, mb.double_click)
				get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_UP:
				if mb.pressed:
					_exit_charge = 0
					_wheel_in(lp)
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					_enter_charge = 0
					if _zoom_t <= ZOOM_MIN + 0.001:
						if _selected >= 0:
							_select(-1)
						_exit_charge += 1
						if _exit_charge >= EXIT_CHARGE:
							_go_up()
					else:
						_zoom_to(clampf(_zoom_t / ZOOM_STEP, ZOOM_MIN, ZOOM_MAX), lp)
					get_viewport().set_input_as_handled()
		return
	if event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		var lp := _space.get_global_transform().affine_inverse() * mg.position
		var target := _hover if _hover >= 0 else _selected
		if mg.factor > 1.0 and _zoom_t >= ZOOM_MAX - 0.001 and target >= 0:
			_enter_pinch *= mg.factor
			if _enter_pinch >= ENTER_PINCH:
				_enter_pinch = 1.0
				_begin_enter(target)
		elif mg.factor < 1.0 and _zoom_t <= ZOOM_MIN + 0.001:
			if _selected >= 0:
				_select(-1)
			_exit_pinch *= mg.factor
			if _exit_pinch <= EXIT_PINCH:
				_exit_pinch = 1.0
				_go_up()
		else:
			if mg.factor > 1.0:
				_exit_pinch = 1.0
			else:
				_enter_pinch = 1.0
			_zoom_to(clampf(_zoom_t * mg.factor, ZOOM_MIN, ZOOM_MAX), lp)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventPanGesture:
		var pg := event as InputEventPanGesture
		_turn(-pg.delta * 2.0)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE and _selected >= 0:
			_select(-1)
			get_viewport().set_input_as_handled()


func _body_at(lp: Vector2) -> int:
	var best := -1
	var best_d := INF
	for i in _bodies.size():
		var p := _project(_plane(i))
		var d := Vector2(p.x, p.y).distance_to(lp)
		if d < maxf(_px(i) * 0.5, 10.0) + 4.0 and d < best_d:
			best_d = d
			best = i
	return best


func _click(lp: Vector2, double: bool) -> void:
	var i := _body_at(lp)
	if i < 0:
		if _selected >= 0:
			_select(-1)
		return
	if double or i == _selected:
		_begin_enter(i)
		return
	_select(i)


func _select(i: int) -> void:
	_selected = i
	_enter_charge = 0
	if i >= 0:
		AudioManager.play("poi_select")
		_focus_t = _plane(i)
		_zoom_t = maxf(_zoom_t, clampf(120.0 / maxf(float(_bodies[i]["rad"]), 1.0), 1.0, ZOOM_MAX))
	else:
		_focus_t = Vector2.ZERO
	_build_panel()


func _wheel_in(lp: Vector2) -> void:
	var target := _hover if _hover >= 0 else _selected
	if _zoom_t >= ZOOM_MAX - 0.001 and target >= 0:
		_enter_charge += 1
		if _enter_charge >= ENTER_CHARGE:
			_begin_enter(target)
		return
	_zoom_to(clampf(_zoom_t * ZOOM_STEP, ZOOM_MIN, ZOOM_MAX), lp)


## Zooms on what is in focus (the planet, or the picked moon): no panning here.
func _zoom_to(z: float, _lp: Vector2) -> void:
	_zoom_t = z


func _turn(rel: Vector2) -> void:
	_yaw_t -= rel.x * 0.006
	_tilt_t = clampf(_tilt_t + rel.y * 0.0025, TILT_MIN, TILT_MAX)


# ── Down into a body / up to the Star System ─────────────────────────────────

func _begin_enter(i: int) -> void:
	var pd: PlanetData = _bodies[i]["pd"]
	var home := GameState.get_home_planet()
	if home != null and pd in home.moons and not GameState.can_view_moon():
		AudioManager.play("error")
		return
	AudioManager.play("click")
	_selected = i
	_entering = i
	_focus_t = _plane(i)
	_zoom_t = _zoom_for_pv(i, 0.82)


func _hand_over(i: int) -> void:
	_leaving = true
	var pd: PlanetData = _bodies[i]["pd"]
	if _solar != null:
		pd.set_meta("__solar_data", _solar)
	GameState.set_meta("enter_from_system", true)   # PlanetaryView opens slightly out and zooms in
	SceneTransition.go_soft(PLANET_SCENE, pd)


## Up to the Star System: a short ease out, then it takes over on this world
## at its size here (its _arrive_from reads __pv_zoom, the planet view's terms).
func _go_up() -> void:
	if _leaving or not StarSystemProgress.can_view():
		return
	_leaving = true
	_exit_charge = 0
	_focus_t = Vector2.ZERO
	_zoom_t = EXIT_ZOOM
	await get_tree().create_timer(EXIT_SEC).timeout
	if _solar != null:
		_planet.set_meta("__solar_data", _solar)
	_planet.set_meta("__pv_zoom", _pv_zoom_of(0))
	_planet.set_meta("__pose", {"yaw": _yaw, "tilt": _tilt})
	SceneTransition.go_soft(SYSTEM_SCENE, _planet)


## Came out of a planet view on `body`: start on it at the size it had there,
## then ease out until all the moons are in (it stays picked).
func _arrive_from(body: PlanetData) -> void:
	var idx := 0
	for i in _bodies.size():
		if (_bodies[i]["pd"] as PlanetData).seed == body.seed:
			idx = i
	_focus = _plane(idx)
	_zoom = _zoom_for_pv(idx, float(body.get_meta("__pv_zoom", 0.62)))
	_zoom_v = 0.0
	_focus_t = Vector2.ZERO if idx == 0 else _focus
	if body.has_meta("__pose"):
		# down from the Star System: its angle, and keep closing in
		var pose: Dictionary = body.get_meta("__pose")
		body.remove_meta("__pose")
		_yaw = float(pose["yaw"])
		_yaw_t = _yaw
		_tilt = clampf(float(pose["tilt"]), TILT_MIN, TILT_MAX)
		_tilt_t = _tilt
		_zoom_t = clampf(maxf(_zoom * 1.3, ARRIVE_FROM_SYSTEM), ZOOM_MIN, ZOOM_MAX)
	else:
		# up from a planet view: ease out until the moons are in
		_zoom_t = ARRIVE_ZOOM if idx == 0 else maxf(ARRIVE_ZOOM, 1.6)
	if GameState.has_meta("planet_system_highlight"):
		# the Moon's reveal: pick it, so the player sees where it is
		var hs := int(GameState.get_meta("planet_system_highlight"))
		GameState.remove_meta("planet_system_highlight")
		for i in _bodies.size():
			if (_bodies[i]["pd"] as PlanetData).seed == hs:
				idx = i
	_selected = idx if idx > 0 else -1
	_build_panel()


# ── Side panel ───────────────────────────────────────────────────────────────

func _build_panel() -> void:
	if GameState.showcase_mode or _bodies.is_empty():
		return
	var content := _panel.get_node("Layout/PanelContent")
	for c in content.get_children():
		if c.name in ["PSHero", "PSPanel"]:
			c.name = "__freeing"
			c.queue_free()
	var hero := HeroHeader.create("Planet System", _planet.planet_name)
	hero.name = "PSHero"
	content.add_child(hero)
	var root := VBoxContainer.new()
	root.name = "PSPanel"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	content.add_child(root)
	root.add_child(SectionHeader.create("BODIES", str(_bodies.size())))
	for i in _bodies.size():
		root.add_child(_body_row(i))


func _body_row(i: int) -> Control:
	var pd: PlanetData = _bodies[i]["pd"]
	var pp := GameState.find_planet(pd.seed)
	var status := "Uncharted"
	if pd.seed == GameState.home_planet_seed:
		status = "Home world  //  Level %d" % (pp.level if pp != null else 1)
	elif pp != null and pp.is_colonized:
		status = "Settled  //  Level %d" % pp.level
	var kind: String = String(PlanetData.Type.keys()[pd.planet_type]).capitalize().replace("_", " ")
	var row := ListItem.create(("   " if i > 0 else "") + pd.planet_name.to_upper(), "moon" if i > 0 else "planet",
		kind.to_upper(), PackedStringArray(), status)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.selected = i == _selected
	row.icon_color = UIStyle.color(&"accent") if pp != null and pp.is_colonized else Color(0.62, 0.70, 0.82)
	row.mouse_entered.connect(func() -> void:
		_hover = i
		TooltipManager.show_tip(pd.planet_name, "Click to pick it; click again to go down to it."))
	row.mouse_exited.connect(func() -> void:
		if _hover == i:
			_hover = -1
		TooltipManager.hide_tip())
	row.pressed.connect(func() -> void:
		TooltipManager.hide_tip()
		if _selected == i:
			_begin_enter(i)
		else:
			_select(i))
	return row


# ── Side panel slide (Tab / arrow) ───────────────────────────────────────────

func _set_panel_open(open: bool) -> void:
	if open and GameState.showcase_mode:
		return
	_panel_open = open
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	_panel_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_panel_tween.tween_method(_apply_panel_t, _panel_t, 1.0 if open else 0.0, PANEL_SLIDE_SEC)


func _apply_panel_t(t: float) -> void:
	_panel_t = t
	_panel.set_slide(t)
	_space.anchor_left = LeftPanel.edge_frac(t)
	_space.anchor_right = 1.0
	HUDManager.set_view_area_fraction(1.0 - LeftPanel.edge_frac(t))
	if _panel_toggle_btn != null:
		_panel_toggle_btn.text = "‹" if _panel_open else "›"
		_place_panel_toggle()


func _build_panel_toggle() -> void:
	if GameState.showcase_mode:
		return
	var btn := Button.new()
	btn.text = "‹"
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 20)
	btn.z_index = 201
	btn.z_as_relative = false
	btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	btn.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	btn.pressed.connect(func() -> void:
		AudioManager.play("click")
		_set_panel_open(not _panel_open))
	add_child(btn)
	_panel_toggle_btn = btn
	_panel.resized.connect(_place_panel_toggle)


func _place_panel_toggle() -> void:
	if _panel_toggle_btn == null:
		return
	var stroke_x := LeftPanel.GAP * get_viewport_rect().size.x
	_panel_toggle_btn.anchor_left = 0.0
	_panel_toggle_btn.anchor_right = 0.0
	_panel_toggle_btn.anchor_top = 0.5
	_panel_toggle_btn.anchor_bottom = 0.5
	_panel_toggle_btn.offset_left = maxf(0.0, stroke_x - 24.0)
	_panel_toggle_btn.offset_right = stroke_x
	_panel_toggle_btn.offset_top = -28.0
	_panel_toggle_btn.offset_bottom = 28.0
