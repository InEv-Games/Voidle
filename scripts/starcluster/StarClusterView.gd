## Star Cluster view — the layer above the Star System: the home star's
## neighbourhood. (Development: Mechanic-Test/Star-Map; a first base.)
##
## The cluster's own generation (ClusterData, from the run's seed): 16–24
## stars and black holes on a lane network, a black hole at the core, the home
## system out towards the edge, and a few wide nebulae. On a tilted plane with
## a little height each (a stem drops from every star to the plane, so the depth
## reads); distance rings frame the core. A black hole is a star like the
## others: it can be picked and has its own system.
##
## Controls as in the Star System view: left drag moves, right drag (Shift +
## two fingers) turns, wheel / pinch zooms towards the cursor or the hovered
## star; a click picks a star, a second click (or zooming on into it) goes down
## to its Star System with SceneTransition.go_soft. Zooming out of a Star
## System lands here on that star and eases out.
extends Control

const SYSTEM_SCENE := "res://scenes/starsystem/StarSystemView.tscn"
const SystemView := preload("res://scripts/starsystem/StarSystemView.gd")


const ZOOM_MIN := 1.0   # the whole neighbourhood; farther out is the Galaxy map's job
const ZOOM_MAX := 6.0
const ZOOM_STEP := 1.2
const TILT_MIN := 0.16
const TILT_MAX := 0.85
const CAM_TIME := 0.18
const ENTER_CHARGE := 2
const ENTER_PINCH := 1.4
## Coming out of a Star System, the camera settles here on that star.
const ARRIVE_ZOOM := 1.8
## Star size on screen at zoom 1 (px at 1080 p) by type.
const STAR_PX := {
	SolarData.StarType.WHITE_DWARF: 7.0,
	SolarData.StarType.RED_DWARF: 8.0,
	SolarData.StarType.YELLOW_DWARF: 10.0,
	SolarData.StarType.ORANGE_SUBGIANT: 12.0,
	SolarData.StarType.BLUE_GIANT: 15.0,
	SolarData.StarType.BLACK_HOLE: 13.0,
}
## The Star System view draws its star 150 px × its zoom (StarSystemView._place_star),
## and opens from here at SYSTEM_ARRIVE_ZOOM (StarSystemView.FROM_CLUSTER_ZOOM).
const SYSTEM_STAR_PX := 150.0
const SYSTEM_ARRIVE_ZOOM := 0.3

const ACC_COL := Color(0.55, 0.95, 1.0)
const RING_COL := Color(0.72, 0.84, 1.0)

@onready var _space: Control = $Space
@onready var _panel: LeftPanel = $SidePanel

var _loaded := false
## Which neighbourhood this is: { cluster_seed, home, index (galaxy site; -1 =
## home), name, screen_r }. Carried to its systems (SolarData meta "__cluster")
## so coming back up lands in the same one.
var _info: Dictionary = {}
const GALAXY_SCENE := "res://scenes/galaxymap/GalaxyMapView.tscn"
const GALAXY_EXIT_CHARGE := 3
const GALAXY_EXIT_PINCH := 0.7
const GALAXY_EXIT_ZOOM := 0.75   # a short ease out before the Galaxy map takes over
const GALAXY_EXIT_SEC := 0.35
var _galaxy_charge := 0
var _galaxy_pinch := 1.0
## ClusterData stars + their nodes: [{ name, type, seed, pos, h, home, rect, mat, badge, cell }]
var _stars: Array[Dictionary] = []
## ClusterData nebulae + their "sprites" and "badge".
var _nebulae: Array[Dictionary] = []
var _hover_n := -1
var _sel_n := -1
var _links: Array[Vector2i] = []   # pairs of indices into _stars
var _outer_r := 400.0
## The neighbourhood's shape as the Galaxy map draws it, in cluster units
## round the core (GalaxyMapData.cluster_bounds): the cluster's border.
var _bounds := PackedVector2Array()
var _back: Node2D
var _front: Node2D
## Planet previews, split at each star's depth: behind every star / in front of
## every star but under the badges and markers.
var _prev_back: Node2D
var _prev_front: Node2D
var _sky: Dictionary = {}
var _sky_off := Vector2.INF

var _yaw := 0.4
var _yaw_t := 0.4
var _yaw_v := 0.0
var _tilt := 0.45
var _tilt_t := 0.45
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
	_sky = Starfield.apply($Background as ColorRect, {"density": 0.07, "brightness": 0.9, "nebula": 0.16})
	_back = Node2D.new()
	_back.z_index = 0
	_front = Node2D.new()
	_front.z_index = 200
	_prev_back = Node2D.new()
	_prev_back.z_index = 9
	_prev_front = Node2D.new()
	_prev_front.z_index = 185
	for n: Node2D in [_back, _front, _prev_back, _prev_front]:
		n.z_as_relative = false
		_space.add_child(n)
	_back.draw.connect(_draw_back)
	_front.draw.connect(_draw_front)
	_prev_back.draw.connect(func() -> void: _draw_previews(true, _prev_back))
	_prev_front.draw.connect(func() -> void: _draw_previews(false, _prev_front))
	_panel.visible = not GameState.showcase_mode
	if GameState.showcase_mode:
		_panel_open = false
		_panel_t = 0.0
	_build_panel_toggle()
	_apply_panel_t(_panel_t)
	tree_exiting.connect(func() -> void: HUDManager.set_view_area_fraction(1.0 - LeftPanel.edge_frac()))

	var pending = SceneTransition.pending_data
	SceneTransition.pending_data = null
	var from_sd: SolarData = pending if pending is SolarData else null   # `as` errors on a Dictionary
	var info: Dictionary = {}
	if pending is Dictionary:
		info = pending   # down from the Galaxy map
	elif from_sd != null and from_sd.has_meta("__cluster"):
		info = from_sd.get_meta("__cluster")
	if info.is_empty():
		info = {"cluster_seed": GameState.home_planet_seed, "home": true, "index": -1}
	await get_tree().process_frame
	_load(info)
	if from_sd != null:
		_arrive_from(from_sd)
	elif pending is Dictionary and pending.has("screen_r"):
		# the cell was this big on the Galaxy map: start the cluster that big
		_zoom = float(pending["screen_r"]) / maxf(_outer_r * _ui() * _fit(), 0.001)
		_zoom_v = 0.0
		if pending.has("yaw"):   # the galaxy's angle, so the stars line up
			_yaw = float(pending["yaw"])
			_yaw_t = _yaw
			_tilt = clampf(float(pending["tilt"]), TILT_MIN, TILT_MAX)
			_tilt_t = _tilt
		_zoom_t = 1.0
	NavigationManager.end_apply()
	NavigationManager.visit(NavigationManager.cluster_entry())


func nav_apply(_entry: Dictionary) -> bool:
	NavigationManager.end_apply()
	return true


# ── Building ─────────────────────────────────────────────────────────────────

func _load(info: Dictionary) -> void:
	_info = info
	# its cell on the Galaxy map gives its shape (and its seed, the same one)
	var gdata := GalaxyMapData.generate(GameState.home_planet_seed)
	var site: Dictionary = gdata["sites"][GalaxyMapData.site_index(gdata, int(info.get("index", -1)))]
	_bounds = GalaxyMapData.cluster_bounds(site)
	_outer_r = GalaxyMapData.cluster_outer(_bounds)
	var home_sd := GameState.get_home_solar() if bool(info.get("home", true)) else null
	var data := ClusterData.generate(int(info.get("cluster_seed", GameState.home_planet_seed)), home_sd, _bounds)
	_stars = data["stars"]
	_links = data["links"]
	_nebulae = data["nebulae"]
	for st: Dictionary in _stars:
		_make_star_nodes(st)
	for nb: Dictionary in _nebulae:
		_make_nebula_nodes(nb)
	_loaded = true
	_build_panel()


func _make_star_nodes(st: Dictionary) -> void:
	if st["type"] == SolarData.StarType.BLACK_HOLE:
		var bh: ColorRect = SystemView.make_black_hole(int(st["seed"]))
		_space.add_child(bh)
		st["rect"] = bh
		st["mat"] = bh.material
		_make_star_labels(st)
		return
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_as_relative = false
	var colors := SolarData.get_star_colors(st["type"])
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/star.gdshader")
	mat.set_shader_parameter("star_radius", 0.35)
	mat.set_shader_parameter("corona_size", 0.14)
	mat.set_shader_parameter("pixel_count", 48.0)
	mat.set_shader_parameter("aspect_ratio", 1.0)
	mat.set_shader_parameter("flicker_speed", 0.35)
	mat.set_shader_parameter("seed", int(st["seed"]) % 99999)
	mat.set_shader_parameter("color_core", colors["core"])
	mat.set_shader_parameter("color_surface", colors["surface"])
	mat.set_shader_parameter("color_corona", colors["corona"])
	rect.material = mat
	_space.add_child(rect)
	st["rect"] = rect
	st["mat"] = mat
	_make_star_labels(st)


## Name badge (hover / picked), and the home system's marker.
func _make_star_labels(st: Dictionary) -> void:
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_as_relative = false
	badge.z_index = 191
	var lbl := Label.new()
	lbl.text = String(st["name"]).to_upper()
	lbl.theme_type_variation = &"CounterLabel"
	badge.add_child(lbl)
	badge.visible = false
	_space.add_child(badge)
	st["badge"] = badge
	if st["home"]:
		var cell := PanelContainer.new()
		cell.theme_type_variation = &"IconCell"
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.z_as_relative = false
		cell.z_index = 190
		var icon := TextureRect.new()
		icon.texture = UIIcons.get_icon("city")
		icon.self_modulate = UIStyle.color(&"accent")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(18, 18)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)
		_space.add_child(cell)
		st["cell"] = cell


## A wide nebula: additive puffs standing at their heights (a volume), and a
## name badge shown while hovered.
func _make_nebula_nodes(nb: Dictionary) -> void:
	var sprites: Array[Sprite2D] = []
	for b: Dictionary in nb["blobs"]:
		var spr := Sprite2D.new()
		spr.texture = _puff_tex(b["col"], float(b["k"]))
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		spr.material = mat
		spr.z_as_relative = false
		spr.z_index = 3
		_space.add_child(spr)
		sprites.append(spr)
	nb["sprites"] = sprites
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_as_relative = false
	badge.z_index = 191
	var lbl := Label.new()
	lbl.text = String(nb["name"]).to_upper()
	lbl.theme_type_variation = &"CounterLabel"
	badge.add_child(lbl)
	badge.visible = false
	_space.add_child(badge)
	nb["badge"] = badge


static func _puff_tex(col: Color, strength: float) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([Color(col, strength), Color(col, strength * 0.45),
		Color(col, strength * 0.12), Color(col, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t


func _place_nebulae() -> void:
	var k := _scale()
	var squash := lerpf(_tilt, 1.0, 0.6)
	for ni in _nebulae.size():
		var nb := _nebulae[ni]
		var sprites: Array = nb["sprites"]
		var blobs: Array = nb["blobs"]
		var lit := ni == _hover_n or ni == _sel_n
		for bi in sprites.size():
			var spr: Sprite2D = sprites[bi]
			var b: Dictionary = blobs[bi]
			var p := _project(Vector2(nb["center"]) + Vector2(b["off"]), float(b["h"]))
			spr.position = Vector2(p.x, p.y)
			spr.rotation = float(b["rot"]) - _yaw
			spr.scale = Vector2(float(b["elong"]), squash) * (float(b["r"]) * k / 128.0)
			spr.modulate = Color(1.5, 1.5, 1.5) if lit else Color.WHITE
		var badge: PanelContainer = nb["badge"]
		badge.visible = lit
		if lit:
			var c := _nebula_screen_center(nb)
			var top := c.y
			for q: Vector2 in _nebula_contour(nb, 8.0):
				top = minf(top, q.y)
			badge.size = badge.get_combined_minimum_size()
			badge.position = (Vector2(c.x, top) - Vector2(badge.size.x * 0.5, badge.size.y + 6.0)).round()


func _nebula_at(lp: Vector2) -> int:
	for ni in _nebulae.size():
		if _in_contour(lp, _nebulae[ni]):
			return ni
	return -1


# ── Nebula outline (the cloud's own shape, as in the Star System view) ───────

const NEBULA_EXTENT := 0.62
const CONTOUR_STEPS := 72

func _puff_screen(nb: Dictionary, b: Dictionary) -> Vector2:
	var p := _project(Vector2(nb["center"]) + Vector2(b["off"]), float(b["h"]))
	return Vector2(p.x, p.y)


func _nebula_screen_center(nb: Dictionary) -> Vector2:
	var sum := Vector2.ZERO
	var blobs: Array = nb["blobs"]
	for b: Dictionary in blobs:
		sum += _puff_screen(nb, b)
	return sum / float(maxi(blobs.size(), 1))


## For each direction from the cloud's centre, how far its farthest puff
## reaches on screen (each puff an ellipse, as drawn); smoothed.
func _nebula_radial(nb: Dictionary, c: Vector2) -> PackedFloat32Array:
	var k := _scale()
	var squash := lerpf(_tilt, 1.0, 0.6)
	var ells: Array = []
	for b: Dictionary in nb["blobs"]:
		var r := float(b["r"]) * k * NEBULA_EXTENT
		ells.append([_puff_screen(nb, b) - c, r * float(b["elong"]), r * squash, float(b["rot"]) - _yaw])
	var out := PackedFloat32Array()
	out.resize(CONTOUR_STEPS)
	for s_i in CONTOUR_STEPS:
		var th := TAU * float(s_i) / float(CONTOUR_STEPS)
		var u := Vector2(cos(th), sin(th))
		var best := 0.0
		for e: Array in ells:
			var ax: float = e[1]
			var ay: float = e[2]
			var ur := u.rotated(-float(e[3]))
			var orr := (e[0] as Vector2).rotated(-float(e[3]))
			var qa := (ur.x * ur.x) / (ax * ax) + (ur.y * ur.y) / (ay * ay)
			var qb := -2.0 * ((ur.x * orr.x) / (ax * ax) + (ur.y * orr.y) / (ay * ay))
			var qc := (orr.x * orr.x) / (ax * ax) + (orr.y * orr.y) / (ay * ay) - 1.0
			var disc := qb * qb - 4.0 * qa * qc
			if disc >= 0.0:
				best = maxf(best, (-qb + sqrt(disc)) / (2.0 * qa))
		out[s_i] = best
	for pass_i in 2:
		var sm := PackedFloat32Array()
		sm.resize(CONTOUR_STEPS)
		for s_i in CONTOUR_STEPS:
			sm[s_i] = (out[(s_i - 1 + CONTOUR_STEPS) % CONTOUR_STEPS] + out[s_i] * 2.0 + out[(s_i + 1) % CONTOUR_STEPS]) * 0.25
		out = sm
	return out


func _nebula_contour(nb: Dictionary, pad: float) -> PackedVector2Array:
	var c := _nebula_screen_center(nb)
	var rad := _nebula_radial(nb, c)
	var pts := PackedVector2Array()
	for s_i in CONTOUR_STEPS + 1:
		var th := TAU * float(s_i % CONTOUR_STEPS) / float(CONTOUR_STEPS)
		pts.append(c + Vector2(cos(th), sin(th)) * (rad[s_i % CONTOUR_STEPS] + pad))
	return pts


func _in_contour(lp: Vector2, nb: Dictionary) -> bool:
	var c := _nebula_screen_center(nb)
	var v := lp - c
	var rad := _nebula_radial(nb, c)
	var idx := int(round(fposmod(atan2(v.y, v.x), TAU) / TAU * float(CONTOUR_STEPS))) % CONTOUR_STEPS
	return v.length() <= rad[idx]


func _select_nebula(ni: int) -> void:
	_selected = -1
	_sel_n = ni
	_enter_charge = 0
	AudioManager.play("poi_select")
	_focus_t = _nebulae[ni]["center"]
	_zoom_t = maxf(_zoom_t, 1.3)
	_build_panel()


# ── Half-zoom: a star's planets, small (NMS-style galaxy map) ─────────────────

## The picked star's neighbours show their planets between these zooms (the
## picked star itself from a little farther out).
const PREVIEW_LOD_A := 2.0
const PREVIEW_LOD_B := 3.0
## Orbit spacing of the preview, in plane units (orbit i at (i + 1) × this).
const PREVIEW_STEP := 4.2
const GOLDEN := 2.39996323
const PLANET_DOT_COL: Array[Color] = [
	Color(0.35, 0.60, 0.95),   # Terran
	Color(0.88, 0.68, 0.42),   # Arid
	Color(0.82, 0.92, 1.00),   # Ice
	Color(0.95, 0.40, 0.25),   # Volcanic
	Color(0.62, 0.60, 0.57),   # Barren
	Color(0.88, 0.74, 0.52),   # Gas Giant
	Color(0.70, 0.70, 0.70),   # Moon
	Color(0.55, 0.52, 0.48),   # Asteroid
]


## The planets of star i for the preview (made once, as the Star System view
## would place them: same order and the same golden-angle spread).
func _preview_of(i: int) -> Array:
	var st := _stars[i]
	if st.has("preview"):
		return st["preview"]
	var sd := GameState.get_home_solar() if st["home"] else SolarData.from_seed(int(st["seed"]))
	var out: Array = []
	if sd != null:
		for p_i in sd.planets.size():
			var pd: PlanetData = sd.planets[p_i]
			out.append({"r": PREVIEW_STEP * float(p_i + 2), "a": fposmod(float(sd.seed % 628) * 0.01 + GOLDEN * float(p_i), TAU),
				"size": clampf(pd.planet_size, 0.3, 2.0), "type": int(pd.planet_type)})
	st["preview"] = out
	return out


## The picked star's planets (and, dimmer, its lane neighbours'), in
## perspective with it: whatever is farther than the star goes behind it
## (back_half), the nearer part in front. Not every orbit is drawn: two flat
## guide rings (the middle and the outer edge of the system) give the plane.
func _draw_previews(back_half: bool, canvas: Node2D) -> void:
	if _selected < 0:
		return
	var base := smoothstep(1.4, 2.2, _zoom)
	if base <= 0.01:
		return
	var shown := {_selected: base}
	var nb_a := base * smoothstep(PREVIEW_LOD_A, PREVIEW_LOD_B, _zoom) * 0.6
	if nb_a > 0.01:
		for l: Vector2i in _links:
			if l.x == _selected:
				shown[l.y] = nb_a
			elif l.y == _selected:
				shown[l.x] = nb_a
	var k := _scale()
	var view := Rect2(Vector2.ZERO, _space.size).grow(80.0)
	for i: int in shown:
		var a: float = shown[i]
		var st := _stars[i]
		var sp := _project(st["pos"], st["h"])
		if not view.has_point(Vector2(sp.x, sp.y)):
			continue
		var sd := sp.z
		var planets := _preview_of(i)
		if planets.is_empty():
			continue
		var r_out: float = planets[planets.size() - 1]["r"] + PREVIEW_STEP
		for ring: Array in [[r_out * 0.55, 0.12], [r_out, 0.20]]:
			_preview_ring(canvas, st, float(ring[0]), Color(RING_COL, float(ring[1]) * a), back_half, sd)
		for pl: Dictionary in planets:
			var pa: float = pl["a"]
			var q := _project(Vector2(st["pos"]) + Vector2(cos(pa), sin(pa)) * float(pl["r"]), st["h"])
			if ((q.z - sd) < 0.0) != back_half:
				continue
			var dot := clampf(float(pl["size"]) * 0.9 * k, 1.5, 6.0)
			var col: Color = PLANET_DOT_COL[clampi(int(pl["type"]), 0, PLANET_DOT_COL.size() - 1)]
			canvas.draw_circle(Vector2(q.x, q.y), dot + 1.0, Color(0, 0, 0, 0.6 * a))
			canvas.draw_circle(Vector2(q.x, q.y), dot, Color(col, a))


## A flat ring round star st at its height, the half on `back_half`'s side of it.
func _preview_ring(canvas: Node2D, st: Dictionary, r: float, col: Color, back_half: bool, star_depth: float) -> void:
	var prev := _project(Vector2(st["pos"]) + Vector2(r, 0.0), st["h"])
	for kk in range(1, 41):
		var ang := TAU * float(kk) / 40.0
		var qq := _project(Vector2(st["pos"]) + Vector2(cos(ang), sin(ang)) * r, st["h"])
		if (((qq.z + prev.z) * 0.5 - star_depth) < 0.0) == back_half:
			canvas.draw_line(Vector2(prev.x, prev.y), Vector2(qq.x, qq.y), col, 1.0, true)
		prev = qq


## The star's Star System (the home one is the saved one; the others are made
## from their seed, under their cluster name and type).
func _system_of(i: int) -> SolarData:
	var st := _stars[i]
	var sd: SolarData
	if st["home"]:
		sd = GameState.get_home_solar()
	else:
		sd = SolarData.from_seed(int(st["seed"]))
		sd.system_name = st["name"]
		sd.star_type = st["type"] as SolarData.StarType
	sd.set_meta("__cluster_star", i)
	sd.set_meta("__cluster", _info)
	return sd


# ── Camera & projection ──────────────────────────────────────────────────────

func _ui() -> float:
	return maxf(_space.size.y, 1.0) / 1080.0


func _fit() -> float:
	return minf((_space.size.x * 0.42) / maxf(_outer_r * _ui(), 1.0), 2.0)


func _scale() -> float:
	return _zoom * _ui() * _fit()


func _center() -> Vector2:
	return _space.size * 0.5 + Vector2(0, _space.size.y * 0.04)


## Plane point + height → Vector3(local x, local y, depth).
func _project(p: Vector2, h := 0.0) -> Vector3:
	var d := p - _focus
	var c := cos(_yaw)
	var s := sin(_yaw)
	var rx := d.x * c - d.y * s
	var ry := d.x * s + d.y * c
	var k := _scale()
	var up := sqrt(maxf(0.0, 1.0 - _tilt * _tilt))
	return Vector3(_center().x + rx * k, _center().y + ry * _tilt * k - h * k * up, ry)


func _unproject_at(sp: Vector2, focus: Vector2, zoom: float) -> Vector2:
	var k := zoom * _ui() * _fit()
	var rx := (sp.x - _center().x) / k
	var ry := (sp.y - _center().y) / (k * _tilt_t)
	var c := cos(_yaw_t)
	var sn := sin(_yaw_t)
	return focus + Vector2(rx * c + ry * sn, -rx * sn + ry * c)


func _star_px(i: int) -> float:
	return float(STAR_PX.get(_stars[i]["type"], 10.0)) * _zoom * _ui()


## The zoom at which star i is as big as the Star System view draws its star at `sys_zoom`.
func _zoom_for_system(i: int, sys_zoom: float) -> float:
	return SYSTEM_STAR_PX * sys_zoom / float(STAR_PX.get(_stars[i]["type"], 10.0))


# ── Frame ────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _loaded:
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
	_place_stars()
	_place_nebulae()
	_sky_follow()
	_back.queue_redraw()
	_front.queue_redraw()
	_prev_back.queue_redraw()
	_prev_front.queue_redraw()
	if _entering >= 0 and not _leaving and _zoom >= _zoom_t * 0.96:
		_hand_over(_entering)


func _place_stars() -> void:
	for i in _stars.size():
		var st := _stars[i]
		var p := _project(st["pos"], st["h"])
		var px := clampf(_star_px(i), 4.0, 2400.0)
		var rect: ColorRect = st["rect"]
		# the star shader's disc is 0.35 of the rect; the black hole's ring ~0.2
		rect.size = Vector2(px, px) / (0.4 if st["type"] == SolarData.StarType.BLACK_HOLE else 0.7)
		rect.position = Vector2(p.x, p.y) - rect.size * 0.5
		rect.z_index = clampi(100 + int(p.z * 0.1), 10, 180)
		(st["mat"] as ShaderMaterial).set_shader_parameter("pixel_count", clampf(px * 0.9, 16.0, 220.0))
		var lit := i == _hover or i == _selected
		rect.modulate = Color(1.35, 1.35, 1.35) if lit else Color.WHITE
		var top := Vector2(p.x, p.y - px * 0.5 - 4.0)
		var badge: PanelContainer = st["badge"]
		var cell: PanelContainer = st.get("cell")
		if cell != null:
			cell.size = cell.get_combined_minimum_size()
			cell.position = (top - Vector2(0, 18) - Vector2(cell.size.x * 0.5, cell.size.y)).round()
		badge.visible = lit
		if lit:
			badge.size = badge.get_combined_minimum_size()
			if cell != null:
				badge.position = (cell.position + Vector2(cell.size.x + 6.0, (cell.size.y - badge.size.y) * 0.5)).round()
			else:
				badge.position = (top - Vector2(badge.size.x * 0.5, badge.size.y + 6.0)).round()


func _sky_follow() -> void:
	if _sky.is_empty():
		return
	# a skybox: it turns and tilts with the camera, drifting a little with the focus
	Skybox.follow(_sky, _yaw, _tilt, _focus.rotated(_yaw) * _ui() * 0.08, _ui())


# ── Drawing ──────────────────────────────────────────────────────────────────

func _draw_back() -> void:
	if not _loaded:
		return
	var acc := UIStyle.color(&"accent")
	# the neighbourhood's border: its shape on the Galaxy map, lying on the plane
	# (a faint fill, a soft glow and a crisp line, like a territory)
	if _bounds.size() >= 3:
		var pts := PackedVector2Array()
		for q: Vector2 in _bounds:
			var pp := _project(q)
			pts.append(Vector2(pp.x, pp.y))
		_back.draw_colored_polygon(pts, Color(acc, 0.035))
		pts.append(pts[0])
		_back.draw_polyline(pts, Color(acc, 0.08), 7.0, true)
		_back.draw_polyline(pts, Color(acc, 0.55), 1.4, true)
	# one faint ring round the core, for scale
	_ring(_outer_r * 0.35, Color(acc, 0.08), 1.0, 0.5)
	# lanes between the stars, by how far we have come:
	#   ours     (both ends reached)  — thick accent line on a strong glow
	#   frontier (one end reached)    — accent line on a soft glow: the next steps
	#   unknown  (neither reached)    — thin, grey, dashed
	# each is lit while it touches the picked / hovered star
	for l: Vector2i in _links:
		var a := _project(_stars[l.x]["pos"], _stars[l.x]["h"])
		var b := _project(_stars[l.y]["pos"], _stars[l.y]["h"])
		var on := l.x in [_hover, _selected] or l.y in [_hover, _selected]
		var pa := Vector2(a.x, a.y)
		var pb := Vector2(b.x, b.y)
		var reach := int(_reached(l.x)) + int(_reached(l.y))
		match reach:
			2:
				_back.draw_line(pa, pb, Color(acc, 0.18 if on else 0.12), 7.0, true)
				_back.draw_line(pa, pb, Color(acc.lerp(Color.WHITE, 0.3), 0.95 if on else 0.8), 2.2, true)
			1:
				_back.draw_line(pa, pb, Color(acc, 0.10 if on else 0.05), 5.0, true)
				_back.draw_line(pa, pb, Color(acc, 0.75 if on else 0.40), 1.3 if on else 1.1, true)
			_:
				# the accent, greyed down — still a lane, not a measure
				_dashed(pa, pb, Color(acc.lerp(Color(0.6, 0.65, 0.75), 0.55), 0.55 if on else 0.24), 1.2)
	# height stems: only a measure — a plain hairline that fades out on its way
	# down to a small ring lying flat on the plane (no dashes: those are lanes)
	for i in _stars.size():
		var st := _stars[i]
		var s := _project(st["pos"], st["h"])
		var foot := _project(st["pos"], 0.0)
		var lit := i == _hover or i == _selected
		var col := Color(1, 1, 1, 0.55) if lit else Color(0.80, 0.84, 0.92, 0.28)
		_fading(Vector2(s.x, s.y), Vector2(foot.x, foot.y), col)
		_plane_circle(st["pos"], 4.0 if not lit else 7.0, col)


## Whether we have reached star i (a system where we are: the home one for
## now; a settled or rover-visited system later).
func _reached(i: int) -> bool:
	return bool(_stars[i]["home"])


## A dashed line (9 px on, 6 off).
func _dashed(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var total := a.distance_to(b)
	if total < 1.0:
		return
	var dir := (b - a) / total
	var t := 0.0
	while t < total:
		_back.draw_line(a + dir * t, a + dir * minf(t + 9.0, total), col, w, true)
		t += 15.0


## A solid hairline from a (full colour) fading towards b.
func _fading(a: Vector2, b: Vector2, col: Color) -> void:
	var steps := 6
	for k in steps:
		var t0 := float(k) / float(steps)
		var t1 := float(k + 1) / float(steps)
		_back.draw_line(a.lerp(b, t0), a.lerp(b, t1), Color(col, col.a * (1.0 - t0 * 0.85)), 1.0, true)


## A dotted line (2 px on, 3 off).
func _dotted(a: Vector2, b: Vector2, col: Color) -> void:
	var total := a.distance_to(b)
	if total < 1.0:
		return
	var dir := (b - a) / total
	var t := 0.0
	while t < total:
		_back.draw_line(a + dir * t, a + dir * minf(t + 2.0, total), col, 1.0)
		t += 5.0


## A circle lying in the plane at `center`, about `px` on screen across its
## widest: squashed and turned with the plane, not facing the camera.
func _plane_circle(center: Vector2, px: float, col: Color) -> void:
	var r := px / maxf(_scale(), 0.001)
	var pts := PackedVector2Array()
	for k in 25:
		var a := TAU * float(k) / 24.0
		var p := _project(center + Vector2(cos(a), sin(a)) * r)
		pts.append(Vector2(p.x, p.y))
	_back.draw_polyline(pts, col, 1.0, true)


func _ring(r: float, col: Color, w: float, dash: float) -> void:
	var n := 120
	var prev := _project(Vector2(r, 0.0))
	for k in range(1, n + 1):
		var a := TAU * float(k) / float(n)
		var p := _project(Vector2(cos(a), sin(a)) * r)
		if dash <= 0.0 or k % 4 < 2:
			_back.draw_line(Vector2(prev.x, prev.y), Vector2(p.x, p.y), col, w, true)
		prev = p


func _draw_front() -> void:
	# the hovered / picked nebula's outline, following its shape
	for ni in _nebulae.size():
		if ni != _hover_n and ni != _sel_n:
			continue
		var col := ACC_COL if ni == _sel_n else Color(ACC_COL, 0.6)
		var pts := _nebula_contour(_nebulae[ni], 8.0)
		for e in range(0, pts.size() - 1):
			if e % 3 != 2:
				_front.draw_line(pts[e], pts[e + 1], col, 1.6, true)
	# the home marker's stem
	for i in _stars.size():
		var st := _stars[i]
		var cell: PanelContainer = st.get("cell")
		if cell == null:
			continue
		var p := _project(st["pos"], st["h"])
		_front.draw_line(Vector2(p.x, p.y - _star_px(i) * 0.5 - 4.0),
			cell.position + Vector2(cell.size.x * 0.5, cell.size.y), Color(1, 1, 1, 0.6), 1.0)


# ── Input ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _loaded or _leaving:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var lp := _space.get_global_transform().affine_inverse() * mm.global_position
		if _drag_btn >= 0:
			_drag_moved += mm.relative.length()
			_turn(mm.relative)   # any drag turns round the focus (no panning)
			get_viewport().set_input_as_handled()
			return
		var h := _star_at(lp)
		if h != _hover:
			if h >= 0:
				AudioManager.play("hover")
			_hover = h
		_hover_n = _nebula_at(lp) if h < 0 else -1
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
					_wheel_in(lp)
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					_enter_charge = 0
					if _zoom_t <= ZOOM_MIN + 0.001:
						# a few more steps out go up to the Galaxy map (the
						# first lets go of a pick, if there is one)
						if _selected >= 0 or _sel_n >= 0:
							_select(-1)
						_galaxy_charge += 1
						if _galaxy_charge >= GALAXY_EXIT_CHARGE:
							_go_to_galaxy()
					else:
						_galaxy_charge = 0
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
			_enter_pinch = 1.0
			if _selected >= 0 or _sel_n >= 0:
				_select(-1)
			_galaxy_pinch *= mg.factor
			if _galaxy_pinch <= GALAXY_EXIT_PINCH:
				_galaxy_pinch = 1.0
				_go_to_galaxy()
		else:
			if mg.factor < 1.0:
				_enter_pinch = 1.0
			else:
				_galaxy_pinch = 1.0
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
		if ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE and (_selected >= 0 or _sel_n >= 0):
			_select(-1)
			get_viewport().set_input_as_handled()


func _star_at(lp: Vector2) -> int:
	var best := -1
	var best_d := INF
	for i in _stars.size():
		var p := _project(_stars[i]["pos"], _stars[i]["h"])
		var d := Vector2(p.x, p.y).distance_to(lp)
		if d < maxf(_star_px(i) * 0.6, 10.0) + 4.0 and d < best_d:
			best_d = d
			best = i
	return best


func _click(lp: Vector2, double: bool) -> void:
	var i := _star_at(lp)
	if i < 0:
		var ni := _nebula_at(lp)
		if ni >= 0:
			if ni != _sel_n:
				_select_nebula(ni)
		elif _selected >= 0 or _sel_n >= 0:
			_select(-1)
		return
	if double or i == _selected:
		_begin_enter(i)
		return
	_select(i)


func _select(i: int) -> void:
	_selected = i
	_sel_n = -1
	_enter_charge = 0
	if i >= 0:
		AudioManager.play("poi_select")
		_focus_t = _stars[i]["pos"]
		_zoom_t = maxf(_zoom_t, _frame_zoom(i))
	else:
		_focus_t = Vector2.ZERO   # nothing picked: back round the core
	_build_panel()


## A zoom that frames star i's little system: its outer guide ring about a
## quarter of the view's height across its radius (like picking a planet).
func _frame_zoom(i: int) -> float:
	var planets := _preview_of(i)
	var r_out := PREVIEW_STEP * 6.0
	if not planets.is_empty():
		r_out = float(planets[planets.size() - 1]["r"]) + PREVIEW_STEP
	var want := (_space.size.y * 0.24) / maxf(r_out * _ui() * _fit(), 0.001)
	return clampf(want, 1.6, ZOOM_MAX)


func _wheel_in(lp: Vector2) -> void:
	var target := _hover if _hover >= 0 else _selected
	if _zoom_t >= ZOOM_MAX - 0.001 and target >= 0:
		_enter_charge += 1
		if _enter_charge >= ENTER_CHARGE:
			_begin_enter(target)
		return
	_zoom_to(clampf(_zoom_t * ZOOM_STEP, ZOOM_MIN, ZOOM_MAX), lp)


## Zooms on the focus (the picked object, else the middle): no panning — the
## view is moved by picking things, it turns round whatever is picked.
func _zoom_to(z: float, _lp: Vector2) -> void:
	_zoom_t = z


func _pan(rel: Vector2) -> void:
	var k := _scale()
	var dx := rel.x / k
	var dy := rel.y / (k * _tilt)
	var c := cos(_yaw)
	var sn := sin(_yaw)
	_focus_t -= Vector2(dx * c + dy * sn, -dx * sn + dy * c)
	if _focus_t.length() > _outer_r * 1.2:
		_focus_t = _focus_t.normalized() * _outer_r * 1.2
	_focus = _focus_t
	_focus_v = Vector2.ZERO


func _turn(rel: Vector2) -> void:
	_yaw_t -= rel.x * 0.006
	_tilt_t = clampf(_tilt_t + rel.y * 0.0025, TILT_MIN, TILT_MAX)


# ── Into / out of a Star System ──────────────────────────────────────────────

func _begin_enter(i: int) -> void:
	AudioManager.play("click")
	_selected = i
	_entering = i
	_focus_t = _stars[i]["pos"]
	# close in until the star is as big as the Star System shows it when it opens
	_zoom_t = _zoom_for_system(i, SYSTEM_ARRIVE_ZOOM)


func _hand_over(i: int) -> void:
	_leaving = true
	GameState.set_meta("enter_from_cluster", true)
	SceneTransition.go_soft(SYSTEM_SCENE, _system_of(i))


## Zooms the whole cluster out a little more on its own, then the Galaxy map
## takes over on this neighbourhood, at the size the cluster had then.
func _go_to_galaxy() -> void:
	if _leaving:
		return
	_leaving = true
	_galaxy_charge = 0
	_focus_t = Vector2.ZERO
	_zoom_t = GALAXY_EXIT_ZOOM
	await get_tree().create_timer(GALAXY_EXIT_SEC).timeout
	SceneTransition.go_soft(GALAXY_SCENE, {"index": int(_info.get("index", -1)),
		"screen_r": _outer_r * _scale(), "yaw": _yaw, "tilt": _tilt})


## Came out of a Star System: start on its star at the size it had there, then
## ease out to its neighbourhood, picked.
func _arrive_from(sd: SolarData) -> void:
	var idx := -1
	if sd.has_meta("__cluster_star"):
		idx = int(sd.get_meta("__cluster_star"))
	elif sd == GameState.get_home_solar() or sd.is_home:
		for i in _stars.size():
			if _stars[i]["home"]:
				idx = i
	if idx >= _stars.size():
		idx = -1
	if idx < 0:
		return
	_focus = _stars[idx]["pos"]
	_focus_t = _focus
	_zoom = _zoom_for_system(idx, float(sd.get_meta("__sys_zoom", 0.3)))
	_zoom_v = 0.0
	_zoom_t = maxf(ARRIVE_ZOOM, _frame_zoom(idx))
	_selected = idx
	_build_panel()


# ── Side panel ───────────────────────────────────────────────────────────────

func _build_panel() -> void:
	if GameState.showcase_mode or not _loaded:
		return
	var content := _panel.get_node("Layout/PanelContent")
	for c in content.get_children():
		if c.name in ["ClusterHero", "ClusterPanel"]:
			c.name = "__freeing"
			c.queue_free()
	# named after its core (the black hole in the middle)
	var core_name := String(_stars[0]["name"]).replace(" Rift", "") if not _stars.is_empty() else ""
	var hero := HeroHeader.create("Star Cluster", "%s Cluster" % core_name)
	hero.name = "ClusterHero"
	content.add_child(hero)
	var root := VBoxContainer.new()
	root.name = "ClusterPanel"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	content.add_child(root)
	root.add_child(_info_line("Systems", str(_stars.size())))
	var settled := 0
	for st: Dictionary in _stars:
		if st["home"]:
			settled += 1
	root.add_child(_info_line("Settled", str(settled)))
	root.add_child(HSeparator.new())
	if _sel_n >= 0:
		var nb := _nebulae[_sel_n]
		root.add_child(SectionHeader.create("SELECTED", ""))
		var row := ListItem.create(String(nb["name"]).to_upper(), "explore", "NEBULA", PackedStringArray(),
			"A wide cloud of gas and dust between the stars.")
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.selected = true
		row.icon_color = nb["color"]
		row.pressed.connect(func() -> void: _focus_t = nb["center"])
		root.add_child(row)
		root.add_child(HSeparator.new())
	if _selected >= 0 and not _stars[_selected]["home"]:
		root.add_child(SectionHeader.create("SELECTED", ""))
		root.add_child(_system_row(_selected))
		root.add_child(HSeparator.new())
	# only systems where we are (the home one for now)
	var listed: Array[int] = []
	for i in _stars.size():
		if _stars[i]["home"]:
			listed.append(i)
	root.add_child(SectionHeader.create("SYSTEMS", str(listed.size())))
	for i: int in listed:
		root.add_child(_system_row(i))


func _system_row(i: int) -> Control:
	var st := _stars[i]
	var desc := "Home system  //  Level %d" % StarSystemProgress.level() if st["home"] else "Uncharted"
	if st["type"] == SolarData.StarType.BLACK_HOLE and not st["home"]:
		desc = "A black hole, with its own system"
	var row := ListItem.create(String(st["name"]).to_upper(), "explore",
		SolarData.get_star_type_name(st["type"]).to_upper(), PackedStringArray(), desc)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.selected = i == _selected
	row.icon_color = UIStyle.color(&"accent") if st["home"] else Color(0.62, 0.70, 0.82)
	row.mouse_entered.connect(func() -> void:
		_hover = i
		TooltipManager.show_tip(String(st["name"]), "Click to pick it on the map; click again to go down to it."))
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


func _info_line(key: String, value: String) -> Control:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var k := Label.new()
	k.text = key
	k.theme_type_variation = &"SubLabel"
	var v := MarqueeLabel.create(value)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(k)
	row.add_child(v)
	return row


# ── Side panel slide (Tab / arrow), as in the other map views ────────────────

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
