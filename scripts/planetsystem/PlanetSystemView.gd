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
##
## Man-made things are here as things, not effects: every body's orbitals
## (its Orbit districts / stations, on the rings the planet view shows) and the
## ships ShipManager keeps — in orbit, lifting off, and flying between the
## world and its moons (freighter traffic, the Moon lander, shuttles) — are read
## from their live state each frame and drawn where they are, in front of or
## behind each body by depth.
extends Control

const PLANET_SCENE := "res://scenes/planetary/PlanetaryView.tscn"
const SYSTEM_SCENE := "res://scenes/starsystem/StarSystemView.tscn"
const SystemView := preload("res://scripts/starsystem/StarSystemView.gd")
const PlanetView := preload("res://scripts/planetary/PlanetaryView.gd")   # its ship sprites

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
## Orbitals and ships: behind every body / in front of every body.
var _orb_back: Node2D
var _orb_front: Node2D
var _sky: Dictionary = {}
var _outer := 300.0
## Towards the sun, on the plane (from the planet).
var _sun_dir := Vector2(-1, 0)
## The look: the sun's glow off towards it, the planet's air glow, the markers.
var _sun_glow: Sprite2D
var _air_glow: Sprite2D
## Orbitals and ships under the mouse: [{ key, name, pos }] as last drawn.
var _orb_hits: Array[Dictionary] = []
var _hover_orb := ""
var _orb_badge: PanelContainer
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
	_orb_back = Node2D.new()
	_orb_back.z_index = 30
	_orb_front = Node2D.new()
	_orb_front.z_index = 70
	for n: Node2D in [_orb_back, _orb_front]:
		n.z_as_relative = false
		_space.add_child(n)
	_orb_back.draw.connect(func() -> void: _draw_orbitals(true, _orb_back))
	_orb_front.draw.connect(func() -> void: _draw_orbitals(false, _orb_front))
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


## Bodies keep more of their size than distances do: on screen a body grows
## as zoom^SIZE_POW while distances grow as zoom. Zoomed out, the worlds come
## together but stay readable (a symbolic map); zoomed in, the room between
## them and their orbits opens up. At zoom 1 both agree.
const SIZE_POW := 0.55

func _px(i: int) -> float:
	return float(_bodies[i]["rad"]) * 2.0 * _ui() * pow(maxf(_zoom, 0.0001), SIZE_POW)


## Body i's radius in plane units at this zoom (its size on screen ÷ the
## distance scale): what everything hugging a body (its orbits, the ships'
## parking and capture points) is laid out by, so they stay round it.
func _rad_eff(i: int) -> float:
	return float(_bodies[i]["rad"]) * pow(maxf(_zoom, 0.0001), SIZE_POW - 1.0)


## The zoom at which body i is as big as the planet view draws it at `pv_zoom`
## (PlanetaryView: radius = clamp(0.42 × size, 0.10, 0.48) of the view height).
func _zoom_for_pv(i: int, pv_zoom: float) -> float:
	var pd: PlanetData = _bodies[i]["pd"]
	var diam := 2.0 * clampf(0.42 * clampf(pd.planet_size, 0.2, 2.0), 0.10, 0.48) * _space.size.y * pv_zoom
	return pow(diam / maxf(float(_bodies[i]["rad"]) * 2.0 * _ui(), 1.0), 1.0 / SIZE_POW)


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
	_orb_back.queue_redraw()
	_orb_front.queue_redraw()
	if _entering >= 0 and not _leaving and _zoom >= _zoom_t * 0.96:
		_hand_over(_entering)


func _place_bodies(delta: float) -> void:
	var planet_p := _project(Vector2.ZERO)
	_place_look(planet_p)
	_place_orb_badge()
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
		b["tilt"] = lerpf(float(b.get("tilt", 0.0)), 0.0, 1.0 - exp(-0.8 * delta))   # a planet view's tilt eases out
		mat.set_shader_parameter("tilt", b["tilt"])
		# day and night exactly as the planet view has them (its light formula:
		# the world's clock, its own time offset and its turn), so the same side
		# is lit on both sides of a zoom
		mat.set_shader_parameter("light_direction", _pv_light(i))
		mat.set_shader_parameter("night_shadow", SettingsManager.night_shadow)   # the night darkness setting, live
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

## Buttons for DebugPopup: real ships (ShipManager), not effects — they are
## saved, keep flying when the view is left, and arrive.
func debug_actions() -> Array:
	var out: Array = []
	if _bodies.size() > 1:
		var moon: PlanetData = _bodies[1]["pd"]
		out.append({"name": "Launch a shuttle → %s" % moon.planet_name, "call": func() -> void:
			_test_launch(_planet.seed, moon.seed)})
		out.append({"name": "Launch a shuttle → %s" % _planet.planet_name, "call": func() -> void:
			_test_launch(moon.seed, _planet.seed)})
		out.append({"name": "Launch three, staggered", "call": func() -> void:
			_test_launch(_planet.seed, moon.seed)
			get_tree().create_timer(2.0).timeout.connect(func() -> void: _test_launch(_planet.seed, moon.seed))
			get_tree().create_timer(4.0).timeout.connect(func() -> void: _test_launch(moon.seed, _planet.seed))})
	if _bodies.size() > 1:
		var m: PlanetData = _bodies[1]["pd"]
		out.append({"name": "Pioneer: %s → %s (opens a route)" % [_planet.planet_name, m.planet_name], "call": func() -> void:
			ShipManager.send_pioneer(_planet.seed, m.seed)
			AudioManager.play("click")})
	out.append({"name": "Remove test shuttles", "call": func() -> void:
		for b: Dictionary in _bodies:
			for sh: ShipData in ShipManager.ships_for((b["pd"] as PlanetData).seed):
				if sh.ship_name.begins_with(TEST_SHIP):
					ShipManager.remove_ship(sh.orbit_seed, sh.ship_id)})
	out.append({"name": "Turn the view", "call": func() -> void: _yaw_t += PI * 0.5})
	return out


const TEST_SHIP := "Test Shuttle"
const TEST_FLIGHT_SEC := 30.0

## A real shuttle: put in orbit round `from`, sent to `to` (ShipManager).
func _test_launch(from: int, to: int) -> void:
	var sh := ShipManager.launch(from, "%s %d" % [TEST_SHIP, randi_range(10, 99)])
	sh.ship_type = "shuttle"
	sh.orbit_speed = 0.35
	sh.orbit_inclination = randf_range(-0.25, 0.25)   # a low parking orbit near the plane
	sh.orbit_radius = 1.12
	# it circles the parking orbit until the burn window, then goes (Hohmann)
	ShipManager.dispatch_on_window(sh, to, TEST_FLIGHT_SEC)
	AudioManager.play("click")


# ── Orbitals and ships (live, from the game's own state) ─────────────────────

## Orbit rings are drawn this much wider than to scale (the planet view's
## orbits hug the globe; here they must read past the disc).
const ORBIT_SPREAD := 3.0
const STATION_COL := Color(0.55, 0.95, 1.0)
const SHIP_COL := Color(0.95, 0.97, 1.0)
const LANDER_COL := Color(1.0, 0.72, 0.4)


func _body_index(seed_val: int) -> int:
	for i in _bodies.size():
		if (_bodies[i]["pd"] as PlanetData).seed == seed_val:
			return i
	return -1


## A point of body i's planet frame (ShipData.orbit_point: y is south) as a
## screen point and its depth; `r` is the orbit radius in planet radii.
func _orbit_screen(i: int, v: Vector3) -> Vector3:
	var rad := _rad_eff(i)
	var len := v.length()
	var d := v / maxf(len, 0.0001)
	var draw_r := rad * (1.0 + (len - 1.0) * ORBIT_SPREAD)
	var p := _project(_plane(i) + Vector2(d.x, d.z) * draw_r)
	var up := sqrt(maxf(0.0, 1.0 - _tilt * _tilt))
	return Vector3(p.x, p.y + d.y * draw_r * _scale() * up, p.z)


func _draw_orbitals(back_half: bool, canvas: Node2D) -> void:
	if _bodies.is_empty():
		return
	if back_half:
		_orb_hits.clear()   # the back canvas draws first each frame
	for i in _bodies.size():
		var pd: PlanetData = _bodies[i]["pd"]
		var center_z := _project(_plane(i)).z
		# the Orbit's districts / stations: their ring and a small station mark
		for poi: POIData in pd.custom_pois:
			if not poi.is_orbital():
				continue
			var ang := poi.orbit_angle + poi.orbit_speed * _time
			var prev := _orbit_screen(i, ShipData.orbit_point(poi.orbit_radius, poi.orbit_inclination, poi.orbit_node, 0.0))
			for k in range(1, 49):
				var q := _orbit_screen(i, ShipData.orbit_point(poi.orbit_radius, poi.orbit_inclination, poi.orbit_node, TAU * float(k) / 48.0))
				if (((q.z + prev.z) * 0.5 - center_z) < 0.0) == back_half:
					canvas.draw_line(Vector2(prev.x, prev.y), Vector2(q.x, q.y), Color(STATION_COL, 0.18), 1.0, true)
				prev = q
			var sp := _orbit_screen(i, ShipData.orbit_point(poi.orbit_radius, poi.orbit_inclination, poi.orbit_node, ang))
			if ((sp.z - center_z) < 0.0) == back_half:
				_orb_hits.append({"key": "poi:" + poi.label, "name": poi.shown_name(), "pos": Vector2(sp.x, sp.y),
					"front": not back_half})
				var c := Vector2(sp.x, sp.y).round()
				canvas.draw_rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), Color(0, 0, 0, 0.7))
				canvas.draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), STATION_COL)
		# ships coming in from another planet system: their approach leg
		for sh: ShipData in ShipManager.inbound(pd.seed):
			if _body_index(sh.orbit_seed) >= 0:
				continue   # from a body here: its Hohmann transfer (_draw_transfer)
			var on := OrbitLayout.leg_of(sh)
			if on["leg"] == "in":
				var leg := OrbitLayout.arrival_leg(sh)
				if not leg.is_empty():
					_draw_leg(i, sh, leg, float(on["s"]), back_half, canvas)
		# ships of this body: in orbit (also lifting off / coming down), or flying
		for sh: ShipData in ShipManager.ships_at(pd.seed):
			if sh.traffic_state == "pad" or sh.orbit_radius < 0.999:
				continue
			if sh.is_travelling():
				_draw_transfer(i, sh, back_half, canvas)
				continue
			# its parking orbit, faint (brighter while hovered / waiting to burn)
			var lit := _hover_orb == "ship:" + sh.ship_id
			var ring_a := 0.30 if lit else (0.16 if sh.pending_dest >= 0 else 0.08)
			var rp := _orbit_screen(i, ShipData.orbit_point(sh.orbit_radius, sh.orbit_inclination, sh.orbit_node, 0.0))
			for k in range(1, 41):
				var rq := _orbit_screen(i, ShipData.orbit_point(sh.orbit_radius, sh.orbit_inclination, sh.orbit_node, TAU * float(k) / 40.0))
				if (((rq.z + rp.z) * 0.5 - center_z) < 0.0) == back_half:
					canvas.draw_line(Vector2(rp.x, rp.y), Vector2(rq.x, rq.y), Color(SHIP_COL, ring_a), 1.0, true)
				rp = rq
			var sp := _orbit_screen(i, ShipData.orbit_point(sh.orbit_radius, sh.orbit_inclination, sh.orbit_node, sh.orbit_angle))
			if ((sp.z - center_z) < 0.0) != back_half:
				continue
			_orb_hits.append({"key": "ship:" + sh.ship_id, "name": sh.ship_name, "pos": Vector2(sp.x, sp.y),
				"front": not back_half})
			var ahead := _orbit_screen(i, ShipData.orbit_point(sh.orbit_radius, sh.orbit_inclination, sh.orbit_node,
				sh.orbit_angle + 0.05 * signf(sh.orbit_speed if sh.orbit_speed != 0.0 else 1.0)))
			_draw_ship(canvas, Vector2(sp.x, sp.y), Vector2(ahead.x, ahead.y) - Vector2(sp.x, sp.y), sh)


## A ship between two bodies of this system, on a Hohmann transfer: half an
## ellipse round the planet (its focus) from the leaving body to the one it
## heads for — the near point at the planet's parking orbit, the far point at
## the moon's. Where it is on it follows Kepler's law from its real travel
## progress: fast low down by the planet, slow out by the moon. The whole path
## is drawn dashed (the way still to go brighter). Its first and last bits
## blend from / into the parking orbits, so it leaves from where it really was.
## One going to another planet just climbs out and fades.
func _draw_transfer(from_i: int, sh: ShipData, back_half: bool, canvas: Node2D) -> void:
	var to_i := _body_index(sh.dest_seed)
	var u := clampf(sh.travel_progress, 0.0, 1.0)
	if to_i < 0:
		# out of this planet system: its escape leg, then gone (_draw_leg)
		var on := OrbitLayout.leg_of(sh)
		if on["leg"] == "out":
			_draw_leg(from_i, sh, OrbitLayout.departure_leg(sh), float(on["s"]), back_half, canvas)
		return
	var tr := _transfer_of(from_i, to_i, sh)
	_draw_capture_orbit(from_i, to_i, sh, back_half, canvas)
	# the path (dashed), split at the planet's depth like everything round it
	var steps := 64
	var prev := _tproj(tr, 0.0)
	for k in range(1, steps + 1):
		var uu := float(k) / float(steps)
		var pt := _transfer_point(tr, uu)
		var q := _tproj(tr, uu)
		if (((q.z + prev.z) * 0.5 - _near_z(pt, from_i, to_i)) < 0.0) == back_half and k % 3 != 0:
			var ahead := uu > u
			canvas.draw_line(Vector2(prev.x, prev.y), Vector2(q.x, q.y),
				Color(LANDER_COL if sh.ship_type == "lander" else SHIP_COL, 0.45 if ahead else 0.15), 1.0, true)
		prev = q
	var pos := _transfer_point(tr, u)
	# blend out of the parking orbit at the start (it was there when it burned)
	if u < BLEND_U:
		var park := _orbit_screen(from_i, ShipData.orbit_point(sh.orbit_radius, sh.orbit_inclination, sh.orbit_node, sh.orbit_angle))
		var pp := _tproj(tr, u)
		var w := smoothstep(0.0, BLEND_U, u)
		var blended := Vector2(park.x, park.y).lerp(Vector2(pp.x, pp.y), w)
		if ((lerpf(park.z, pp.z, w) - _near_z(pos, from_i, to_i)) < 0.0) == back_half:
			_draw_burn(canvas, sh, blended, _tproj(tr, u + 0.01))
		return
	var p3 := _tproj(tr, u)
	if ((p3.z - _near_z(pos, from_i, to_i)) < 0.0) != back_half:
		return
	_draw_burn(canvas, sh, Vector2(p3.x, p3.y), _tproj(tr, minf(u + 0.01, 1.0)))


const BLEND_U := 0.06

## A ship leaving for / coming from another planet system round body i, on
## its escape / approach hyperbola (OrbitLayout legs, drawn with the same
## spread as every orbit here): the curve dashed and fading out with height
## (a fountain of them over a busy world), the ship on it.
const LEG_STEPS := 36
## Share of a leg's height it has faded out by here (the view is wide).
const LEG_FADE_END := 0.6

func _draw_leg(i: int, sh: ShipData, leg: Dictionary, s: float, back_half: bool, canvas: Node2D) -> void:
	var center_z := _project(_plane(i)).z
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var prev := _orbit_screen(i, OrbitLayout.leg_point(leg, 0.0))
	for k in range(1, LEG_STEPS + 1):
		var t := float(k) / float(LEG_STEPS)
		var f := OrbitLayout.leg_point(leg, t)
		var q := _orbit_screen(i, f)
		if k % 3 != 0 and (((q.z + prev.z) * 0.5 - center_z) < 0.0) == back_half:
			var a := (0.42 if t > s else 0.15) * OrbitalLayer._leg_fade(leg, f.length(), LEG_FADE_END)
			if a > 0.01:
				pts.append(Vector2(prev.x, prev.y))
				pts.append(Vector2(q.x, q.y))
				cols.append(Color(SHIP_COL, a))
		prev = q
	if not pts.is_empty():
		canvas.draw_multiline_colors(pts, cols, 1.0)
	var f0 := OrbitLayout.leg_point(leg, s)
	var fade := OrbitalLayer._leg_fade(leg, f0.length(), LEG_FADE_END)
	var p := _orbit_screen(i, f0)
	if fade < 0.05 or ((p.z - center_z) < 0.0) != back_half:
		return
	var ahead := _orbit_screen(i, OrbitLayout.leg_point(leg, minf(s + 0.01, 1.0)))
	var inbound: bool = leg["inbound"]
	var burning := (s < 0.15 and not inbound) or (s > 0.85 and inbound)
	_orb_hits.append({"key": "ship:" + sh.ship_id, "name": sh.ship_name, "pos": Vector2(p.x, p.y), "front": not back_half})
	_draw_ship(canvas, Vector2(p.x, p.y), Vector2(ahead.x, ahead.y) - Vector2(p.x, p.y), sh, fade, burning)

## The orbit a flying ship will be captured into round its target (the same
## one ShipManager puts it on: OrbitLayout.capture), dashed, so the transfer's
## path runs on into it instead of stopping in empty space.
func _draw_capture_orbit(from_i: int, to_i: int, sh: ShipData, back_half: bool, canvas: Node2D) -> void:
	var from_pd: PlanetData = _bodies[from_i]["pd"]
	var to_pd: PlanetData = _bodies[to_i]["pd"]
	var cap := OrbitLayout.capture(from_pd.seed, to_pd.seed, 1.0 if sh.orbit_speed >= 0.0 else -1.0,
		OrbitLayout.transfer_inc(sh.ship_id))
	if cap.is_empty():
		return
	var r := float(cap["radius"]) if float(cap["radius"]) > 0.0 else maxf(sh.orbit_radius, 1.06)
	var inc: float = cap["inc"]
	var node: float = cap["node"]
	var center_z := _project(_plane(to_i)).z
	var col := Color(LANDER_COL if sh.ship_type == "lander" else SHIP_COL, 0.4)
	var prev := _orbit_screen(to_i, ShipData.orbit_point(r, inc, node, 0.0))
	for k in range(1, 49):
		var q := _orbit_screen(to_i, ShipData.orbit_point(r, inc, node, TAU * float(k) / 48.0))
		if (((q.z + prev.z) * 0.5 - center_z) < 0.0) == back_half and k % 3 != 0:
			canvas.draw_line(Vector2(prev.x, prev.y), Vector2(q.x, q.y), col, 1.0, true)
		prev = q

## Depth of whichever of the two bodies a transfer point is nearest: behind
## that one it goes under it (the moon as much as the planet).
func _near_z(p: Vector2, a: int, b: int) -> float:
	var n := a if p.distance_to(_plane(a)) <= p.distance_to(_plane(b)) else b
	return _project(_plane(n)).z

func _draw_burn(canvas: Node2D, sh: ShipData, p: Vector2, ahead3: Vector3) -> void:
	_orb_hits.append({"key": "ship:" + sh.ship_id, "name": sh.ship_name, "pos": p, "front": canvas == _orb_front})
	var burning := sh.travel_progress < 0.12 or sh.travel_progress > 0.9   # the two burns
	_draw_ship(canvas, p, Vector2(ahead3.x, ahead3.y) - p, sh, 1.0, burning)


## How far out a ship captured round body i sits (OrbitLayout.CAPTURE_R, drawn
## as every orbit here: ORBIT_SPREAD wider than to scale).
func _capture_off(i: int) -> float:
	return _rad_eff(i) * (1.0 + (OrbitLayout.CAPTURE_R - 1.0) * ORBIT_SPREAD)


## The transfer's ellipse: { focus, start_ang, r_s, r_e, a, e, peri_first }.
func _transfer_of(from_i: int, to_i: int, sh: ShipData) -> Dictionary:
	var planet_rad := _rad_eff(0)
	var park := planet_rad * (1.0 + (maxf(sh.orbit_radius, 1.06) - 1.0) * ORBIT_SPREAD)
	var dir_s: Vector2
	var r_s: float
	var r_e: float
	if from_i == 0:
		var to_dir := _plane(to_i).normalized()
		dir_s = -to_dir                     # burn on the far side
		r_s = park
		r_e = _plane(to_i).length() - _capture_off(to_i)
	else:
		dir_s = _plane(from_i).normalized()
		# leaving a moon it burns on its far side from the planet (ShipManager's
		# window), so the path starts just outside the moon
		r_s = _plane(from_i).length() + _capture_off(from_i)
		r_e = park if to_i == 0 else _plane(to_i).length() - _capture_off(to_i)
	r_e = maxf(r_e, park)
	var a := (r_s + r_e) * 0.5
	var e := absf(r_e - r_s) / maxf(r_s + r_e, 0.001)
	return {"start_ang": dir_s.angle(), "r_s": r_s, "r_e": r_e, "a": a, "e": e, "peri_first": r_s <= r_e,
		"sense": 1.0 if (sh.orbit_speed >= 0.0) else -1.0, "inc": OrbitLayout.transfer_inc(sh.ship_id)}


## Plane point at share u (0..1 of the travel time) along the transfer.
func _transfer_point(tr: Dictionary, u: float) -> Vector2:
	var e: float = tr["e"]
	var a: float = tr["a"]
	# mean anomaly over half an orbit; from the near point (0→π) or the far one (π→2π)
	var m := PI * clampf(u, 0.0, 1.0) + (0.0 if tr["peri_first"] else PI)
	var ea := m
	for it in 6:   # Kepler: E − e·sin E = M (Newton)
		ea -= (ea - e * sin(ea) - m) / (1.0 - e * cos(ea))
	var nu := fposmod(2.0 * atan2(sqrt(1.0 + e) * sin(ea * 0.5), sqrt(1.0 - e) * cos(ea * 0.5)), TAU)
	if not tr["peri_first"] and nu < PI * 0.5:
		nu += TAU   # the very end of an inbound leg (ν = 2π), not its start
	var r := a * (1.0 - e * e) / (1.0 + e * cos(nu))
	# the angle swept since the start point (the near point is the start, or π away)
	var swept := nu - (0.0 if tr["peri_first"] else PI)
	return Vector2.from_angle(float(tr["start_ang"]) + swept * float(tr["sense"])) * r


## The transfer point lifted off the plane by the transfer's own tilt (turned
## about the start–end line): Vector3(plane x, plane y, height).
func _transfer_xyh(tr: Dictionary, u: float) -> Vector3:
	var p := _transfer_point(tr, u)
	var s := Vector2.from_angle(float(tr["start_ang"]))
	var n := s.rotated(PI * 0.5)
	var inc: float = tr["inc"]
	var along := p.dot(s)
	var across := p.dot(n)
	var q := s * along + n * across * cos(inc)
	return Vector3(q.x, q.y, -across * sin(inc))


## Screen point (x, y, depth) of the tilted transfer at u.
func _tproj(tr: Dictionary, u: float) -> Vector3:
	var v := _transfer_xyh(tr, u)
	var p := _project(Vector2(v.x, v.y))
	var up := sqrt(maxf(0.0, 1.0 - _tilt * _tilt))
	return Vector3(p.x, p.y - v.z * _scale() * up, p.z)


## A ship in the planet view's own pixel art (PlanetaryView.draw_ship_sprite:
## the same little hull for a shuttle / freighter, the lander's legs), lit
## yellow while hovered as there, with a pixel engine burn behind it on the
## side away from its heading while it fires.
func _draw_ship(canvas: Node2D, p: Vector2, dir: Vector2, sh: ShipData, a := 1.0, burning := false) -> void:
	var d := dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
	var hovered := _hover_orb == "ship:" + sh.ship_id
	var col := Color(1.0, 0.92, 0.40, a) if hovered else Color(1, 1, 1, 0.92 * a)
	if burning:
		var hue := 0.45 + 0.25 * (0.5 + 0.5 * sin(_time * 37.0 + float(sh.ship_id.hash() % 11)))
		var f := (p - Vector2.ONE).floor() - (d * 3.0).round()
		canvas.draw_rect(Rect2(f, Vector2(2, 2)), Color(1.0, hue, 0.05, 0.9 * a))
	PlanetView.draw_ship_sprite(canvas, p, sh.ship_type, col)


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
	var start := pa + dir * _rad_eff(a)
	var end := pb - dir * _rad_eff(b)
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


## The planet view's light for body i (PlanetRenderer._update_light_direction):
## the shared light angle running on in real time (GameState.light_angle since
## light_last_unix, at PlanetaryView.LIGHT_SPEED), plus the body's own time
## offset and its turn here (spin + yaw); tilted with the body.
const PV_LIGHT_SPEED := 0.04

func _pv_light(i: int) -> Vector3:
	var b := _bodies[i]
	var pd: PlanetData = b["pd"]
	var la := GameState.light_angle
	if GameState.light_last_unix > 0:
		la += float(int(Time.get_unix_time_from_system()) - GameState.light_last_unix) * PV_LIGHT_SPEED
	var eff := la + pd.local_time_offset + fposmod(float(b["spin"]) + _yaw, TAU)
	var ld := Vector3(cos(eff) * 0.85, -0.45, sin(eff) * 0.55).normalized()
	var t: float = b.get("tilt", 0.0)
	var c := cos(t)
	var sn := sin(t)
	return Vector3(ld.x, ld.y * c + ld.z * sn, -ld.y * sn + ld.z * c)


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


## The hovered orbital's / ship's name, following it.
func _place_orb_badge() -> void:
	if _orb_badge == null:
		_orb_badge = PanelContainer.new()
		_orb_badge.theme_type_variation = &"Badge"
		_orb_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_orb_badge.z_as_relative = false
		_orb_badge.z_index = 192
		var lbl := Label.new()
		lbl.theme_type_variation = &"CounterLabel"
		_orb_badge.add_child(lbl)
		_space.add_child(_orb_badge)
	var hit: Dictionary = {}
	for h: Dictionary in _orb_hits:
		if h["key"] == _hover_orb:
			hit = h
	_orb_badge.visible = not hit.is_empty()
	if hit.is_empty():
		return
	(_orb_badge.get_child(0) as Label).text = String(hit["name"]).to_upper()
	_orb_badge.size = _orb_badge.get_combined_minimum_size()
	_orb_badge.position = ((hit["pos"] as Vector2) - Vector2(_orb_badge.size.x * 0.5, _orb_badge.size.y + 10.0)).round()


func _place_look(planet_p: Vector3) -> void:
	if _sun_glow == null:
		return
	# the sun's glow sits where the sun is, pulled back to the frame's edge
	var ld := _pv_light(0)   # the glow sits on the lit side
	var c := _center()
	var dir := Vector2(ld.x, ld.y) * 5000.0
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
		# an orbital / ship near the mouse names itself: one passing in front of
		# a body wins over that body; one behind it only shows off the disc
		var ho := ""
		var best := 10.0
		for hit: Dictionary in _orb_hits:
			if h >= 0 and not bool(hit.get("front", true)):
				continue
			var d := (hit["pos"] as Vector2).distance_to(lp)
			if d < best:
				best = d
				ho = hit["key"]
		if ho != "":
			h = -1
		if h != _hover:
			if h >= 0:
				AudioManager.play("hover")
			_hover = h
		if ho != _hover_orb and ho != "":
			AudioManager.play("hover")
		_hover_orb = ho
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
		_zoom_t = maxf(_zoom_t, clampf(pow(120.0 / maxf(float(_bodies[i]["rad"]), 1.0), 1.0 / SIZE_POW), 1.0, ZOOM_MAX))
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
	# the face shown here, for the planet view to open on
	pd.set_meta("__ps_rot", fposmod(float(_bodies[i]["spin"]) + _yaw, TAU))
	pd.set_meta("__ps_tilt", float(_bodies[i].get("tilt", 0.0)))
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
	# up from a planet view: the globe keeps the face it showed there (its turn
	# is the spin plus our yaw; its tilt eases back to the plane's)
	if body.has_meta("__pv_rot"):
		var b := _bodies[idx]
		b["spin"] = fposmod(float(body.get_meta("__pv_rot")) - _yaw, TAU)
		b["tilt"] = float(body.get_meta("__pv_tilt", 0.0))
		body.remove_meta("__pv_rot")
		body.remove_meta("__pv_tilt")
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
