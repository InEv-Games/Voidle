## Galaxy map — the layer above the Star Cluster (Mechanic-Test/Star-Map; a
## first base). Not the old GalaxyView (that stays out of the game flow).
##
## The whole galaxy, not paper-flat: a bulging core and a gently warped disk
## (GalaxyMapData.height_at lifts every point), a thick cloud of light and star
## dust along the spiral arms, and its neighbourhoods as territories that
## border each other, like the Cities' on a planet (GalaxyMapData: Voronoi
## cells with wobbled borders and a ragged outer edge).
## Lanes join bordering neighbourhoods, star-chart style: ours / the frontier /
## the unknown look different, as in the cluster.
##
## Controls as in the other map views. A click picks a neighbourhood; a second
## click (or zooming on into it) goes down to its Star Cluster with
## SceneTransition.go_soft; zooming out of a Star Cluster lands here on it.
extends Control

const CLUSTER_SCENE := "res://scenes/starcluster/StarClusterView.tscn"

const ZOOM_MIN := 0.7
const ZOOM_MAX := 5.0
const ZOOM_STEP := 1.2
const TILT_MIN := 0.2
const TILT_MAX := 0.9
const CAM_TIME := 0.18
const ENTER_CHARGE := 2
const ENTER_PINCH := 1.4
## Handing over to a cluster: the cell is drawn this big (px, radius) when the
## cluster takes over, at about the size the cluster opens with.
const HANDOVER_SCREEN_R := 0.15   # of the view's width

const ACC_COL := Color(0.55, 0.95, 1.0)
## Coming up from a cluster the camera eases out to at most this share of the
## zoom it took over at (never back in).
const ARRIVE_OUT := 0.6

@onready var _space: Control = $Space
@onready var _panel: LeftPanel = $SidePanel

var _data: Dictionary = {}
var _sites: Array[Dictionary] = []
var _links: Array[Vector2i] = []
var _home := -1
## The cells as last drawn on screen (for picking: the map is lifted).
var _screen_polys: Array[PackedVector2Array] = []
var _radius := 1000.0
var _back: Node2D
var _front: Node2D
var _glow: Array[Dictionary] = []   # [{ spr, pos, h, r }]
## Star dust along the arms: plane points and their heights.
var _dust: PackedVector2Array = PackedVector2Array()
var _dust_h: PackedFloat32Array = PackedFloat32Array()
var _dust_a: PackedFloat32Array = PackedFloat32Array()
var _sky: Dictionary = {}

var _yaw := 0.3
var _yaw_t := 0.3
var _yaw_v := 0.0
var _tilt := 0.55
var _tilt_t := 0.55
var _tilt_v := 0.0
var _zoom := 1.0
var _zoom_t := 1.0
var _zoom_v := 0.0
var _focus := Vector2.ZERO
var _focus_t := Vector2.ZERO
var _focus_v := Vector2.ZERO
var _focus_h := 0.0

var _hover := -1
var _selected := -1
var _entering := -1
var _leaving := false
var _enter_charge := 0
var _enter_pinch := 1.0
var _drag_btn := -1
var _drag_moved := 0.0

const PANEL_SLIDE_SEC := 0.9
var _panel_open := true
var _panel_t := 1.0
var _panel_tween: Tween = null
var _panel_toggle_btn: Button = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	HUDManager.set_game_hud(not GameState.showcase_mode)
	CursorManager.set_state(CursorManager.State.NORMAL)
	_sky = Starfield.apply($Background as ColorRect, {"density": 0.05, "brightness": 0.8, "nebula": 0.1})
	_back = Node2D.new()
	_back.z_index = 10
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
	await get_tree().process_frame
	_load()
	if pending is Dictionary:
		_arrive_from(pending)
	NavigationManager.end_apply()
	NavigationManager.visit(NavigationManager.galaxy_map_entry())


func nav_apply(_entry: Dictionary) -> bool:
	NavigationManager.end_apply()
	return true


# ── Building ─────────────────────────────────────────────────────────────────

func _load() -> void:
	_data = GalaxyMapData.generate(GameState.home_planet_seed)
	_sites = _data["sites"]
	_links = _data["links"]
	_radius = _data["radius"]
	for i in _sites.size():
		if _sites[i]["home"]:
			_home = i
		_make_badge(_sites[i])
	_make_glow()
	_build_panel()


## The galaxy's light: a bright bulging core, a thick cloud of puffs along the
## arms (each at its own height round the surface: a disk with depth) and fine
## star dust tracing the arms, so the spiral reads at a glance.
func _make_glow() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.home_planet_seed ^ 0x9105
	var arms: int = _data["arms"]
	var twist: float = _data["twist"]
	var phase: float = _data["arm_phase"]
	var core_h := _h(Vector2.ZERO)
	_glow.append({"spr": _puff(Color(1.0, 0.78, 0.5), 0.5, 4), "pos": Vector2.ZERO, "h": core_h * 0.6, "r": _radius * 0.36})
	_glow.append({"spr": _puff(Color(1.0, 0.9, 0.75), 0.7, 5), "pos": Vector2.ZERO, "h": core_h * 0.5, "r": _radius * 0.16})
	_glow.append({"spr": _puff(Color(1.0, 0.97, 0.9), 0.9, 6), "pos": Vector2.ZERO, "h": core_h * 0.45, "r": _radius * 0.06})
	for k in 260:
		var t := pow(rng.randf_range(0.04, 1.12), 0.85)
		var arm := rng.randi() % arms
		var ang := phase + TAU * float(arm) / float(arms) + t * twist + rng.randf_range(-0.18, 0.18) / (t + 0.3)
		var pos := Vector2.from_angle(ang) * t * _radius * 0.92
		var col := Color(0.50, 0.62, 1.0).lerp(Color(0.80, 0.50, 1.0), rng.randf()).lerp(Color(1.0, 0.78, 0.55), clampf(1.0 - t * 1.4, 0.0, 1.0))
		var thick := 70.0 * (1.0 - clampf(t, 0.0, 1.0)) + 18.0
		_glow.append({"spr": _puff(col, rng.randf_range(0.07, 0.16), 3), "pos": pos,
			"h": _h(pos) + rng.randf_range(-thick, thick), "r": _radius * rng.randf_range(0.05, 0.11)})
	for k in 1800:
		var t := pow(rng.randf_range(0.03, 1.15), 0.9)
		var arm := rng.randi() % arms
		var spread := 0.32 if rng.randf() < 0.7 else 1.2   # most tight on the arm, some haze
		var ang := phase + TAU * float(arm) / float(arms) + t * twist + rng.randf_range(-spread, spread) * 0.5 / (t + 0.3)
		var pos := Vector2.from_angle(ang) * t * _radius * 0.92 * rng.randf_range(0.96, 1.04)
		var thick := 60.0 * (1.0 - clampf(t, 0.0, 1.0)) + 12.0
		_dust.append(pos)
		_dust_h.append(_h(pos) + rng.randf_range(-thick, thick))
		_dust_a.append(rng.randf_range(0.25, 0.9))


func _puff(col: Color, strength: float, z: int) -> Sprite2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([Color(col, strength), Color(col, strength * 0.45), Color(col, strength * 0.12), Color(col, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	var spr := Sprite2D.new()
	spr.texture = t
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spr.material = mat
	spr.z_as_relative = false
	spr.z_index = z
	_space.add_child(spr)
	return spr


func _make_badge(site: Dictionary) -> void:
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_as_relative = false
	badge.z_index = 191
	var lbl := Label.new()
	lbl.text = String(site["name"]).to_upper()
	lbl.theme_type_variation = &"CounterLabel"
	badge.add_child(lbl)
	badge.visible = false
	_space.add_child(badge)
	site["badge"] = badge
	if site["home"]:
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
		site["cell"] = cell


# ── Camera & projection (a lifted plane) ─────────────────────────────────────

func _h(p: Vector2) -> float:
	return GalaxyMapData.height_at(_data, p)


func _ui() -> float:
	return maxf(_space.size.y, 1.0) / 1080.0


func _fit() -> float:
	return (_space.size.x * 0.45) / maxf(_radius * _ui(), 1.0)


func _scale() -> float:
	return _zoom * _ui() * _fit()


func _center() -> Vector2:
	return _space.size * 0.5 + Vector2(0, _space.size.y * 0.04)


## Plane point at height h → screen. Heights count from the focused point's,
## so whatever is in focus sits in the middle of the view.
func _project(p: Vector2, h := 0.0) -> Vector2:
	var d := p - _focus
	var c := cos(_yaw)
	var s := sin(_yaw)
	var k := _scale()
	var up := sqrt(maxf(0.0, 1.0 - _tilt * _tilt))
	var dh := h - _focus_h
	return _center() + Vector2(d.x * c - d.y * s, (d.x * s + d.y * c) * _tilt - dh * up) * k


## A point on the galaxy's surface (its own height).
func _surf(p: Vector2) -> Vector2:
	return _project(p, _h(p))


func _unproject(sp: Vector2, focus: Vector2, zoom: float, yaw: float, tilt: float) -> Vector2:
	var k := zoom * _ui() * _fit()
	var rx := (sp.x - _center().x) / k
	var ry := (sp.y - _center().y) / (k * tilt)
	var c := cos(yaw)
	var sn := sin(yaw)
	return focus + Vector2(rx * c + ry * sn, -rx * sn + ry * c)


# ── A neighbourhood's own stars, inside its cell ─────────────────────────────
# The picked neighbourhood shows the stars of its Star Cluster (ClusterData,
# the same ones that view will show), laid round its site at the cluster's own
# layout, scaled to fit the cell. Going down, the camera closes in on them and
# the cluster takes over with the very same stars at the same place, size and
# angle (yaw / tilt are handed over both ways).

## Star sizes as the Star Cluster view draws them (StarClusterView.STAR_PX).
const CL_STAR_PX := {0: 10.0, 1: 8.0, 2: 15.0, 3: 12.0, 4: 7.0, 5: 13.0}
var _clusters: Dictionary = {}   # site index -> { stars, links, outer }


func _cluster_of(i: int) -> Dictionary:
	if _clusters.has(i):
		return _clusters[i]
	var s := _sites[i]
	var home_sd := GameState.get_home_solar() if s["home"] else null
	var bounds := GalaxyMapData.cluster_bounds(s)
	var data := ClusterData.generate(int(s["seed"]), home_sd, bounds)
	data["outer"] = GalaxyMapData.cluster_outer(bounds)   # as StarClusterView._outer_r
	_clusters[i] = data
	return data


## Galaxy units per cluster unit for site i (the cluster fills its cell).
func _cl_scale(i: int) -> float:
	return GalaxyMapData.cluster_scale(_sites[i])


## The cluster's own screen fit (StarClusterView._fit), for matching star sizes.
func _cl_fit(i: int) -> float:
	return minf((_space.size.x * 0.42) / maxf(float(_cluster_of(i)["outer"]) * _ui(), 1.0), 2.0)


## The zoom at which site i's cluster is `screen_r` px across its radius.
func _zoom_for_cluster_r(i: int, screen_r: float) -> float:
	var r := float(_cluster_of(i)["outer"]) * _cl_scale(i)
	return screen_r / maxf(r * _ui() * _fit(), 0.001)


func _draw_inner(i: int) -> void:
	var k := _scale()
	var cl := _cluster_of(i)
	var sc := _cl_scale(i)
	var cell_px := float(_sites[i]["size"]) * k
	var a := smoothstep(60.0, 140.0, cell_px)
	if a <= 0.01:
		return
	var origin: Vector2 = _sites[i]["pos"]
	var base_h := _h(origin)
	var stars: Array = cl["stars"]
	var pts: Array[Vector2] = []
	for st: Dictionary in stars:
		pts.append(_project(origin + Vector2(st["pos"]) * sc, base_h + float(st["h"]) * sc))
	for l: Vector2i in cl["links"]:
		_back.draw_line(pts[l.x], pts[l.y], Color(ACC_COL, 0.18 * a), 1.0, true)
	var star_k := sc * k / _cl_fit(i)   # = the cluster view's zoom × ui at this size
	for si in stars.size():
		var st: Dictionary = stars[si]
		var t: int = st["type"]
		var r := clampf(float(CL_STAR_PX.get(t, 10.0)) * star_k * 0.5, 1.5, 40.0)
		if t == SolarData.StarType.BLACK_HOLE:
			_back.draw_circle(pts[si], r, Color(0, 0, 0, a))
			_back.draw_arc(pts[si], r * 1.2, 0.0, TAU, 20, Color(1.0, 0.75, 0.5, a), 1.2, true)
		else:
			var c: Vector3 = SolarData.get_star_colors(t)["surface"]
			_back.draw_circle(pts[si], r * 1.8, Color(c.x, c.y, c.z, 0.18 * a))
			_back.draw_circle(pts[si], r, Color(Color(c.x, c.y, c.z).lerp(Color.WHITE, 0.4), a))


## Screen point of site i's star nearest to galaxy point `toward` (where its
## lane to that neighbour leaves from).
func _gateway(i: int, toward: Vector2) -> Vector2:
	var cl := _cluster_of(i)
	var sc := _cl_scale(i)
	var origin: Vector2 = _sites[i]["pos"]
	var best := INF
	var bp := origin
	var bh := 0.0
	for st: Dictionary in cl["stars"]:
		var gp: Vector2 = origin + Vector2(st["pos"]) * sc
		var d := gp.distance_to(toward)
		if d < best:
			best = d
			bp = gp
			bh = float(st["h"]) * sc
	return _project(bp, _h(origin) + bh)


## The zoom at which site i's cell has radius `screen_r` px on screen.
func _zoom_for_screen_r(i: int, screen_r: float) -> float:
	return screen_r / maxf(float(_sites[i]["size"]) * _ui() * _fit(), 0.001)


# ── Frame ────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _sites.is_empty():
		return
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
	_focus_h = _h(_focus)
	_place_glow()
	_place_labels()
	_back.queue_redraw()
	_front.queue_redraw()
	if _entering >= 0 and not _leaving and _zoom >= _zoom_t * 0.96:
		_hand_over(_entering)


func _place_glow() -> void:
	var k := _scale()
	var squash := lerpf(_tilt, 1.0, 0.25)
	for g: Dictionary in _glow:
		var spr: Sprite2D = g["spr"]
		spr.position = _project(g["pos"], g["h"])
		spr.scale = Vector2(1.0, squash) * (float(g["r"]) * k / 64.0)


func _place_labels() -> void:
	for i in _sites.size():
		var s := _sites[i]
		var c := _surf(s["center"])
		var lit := i == _hover or i == _selected
		var badge: PanelContainer = s["badge"]
		var cell: PanelContainer = s.get("cell")
		var top := c - Vector2(0, 10)
		if cell != null:
			cell.size = cell.get_combined_minimum_size()
			cell.position = (top - Vector2(cell.size.x * 0.5, cell.size.y + 6.0)).round()
		badge.visible = lit
		if lit:
			badge.size = badge.get_combined_minimum_size()
			if cell != null:
				badge.position = (cell.position + Vector2(cell.size.x + 6.0, (cell.size.y - badge.size.y) * 0.5)).round()
			else:
				badge.position = (top - Vector2(badge.size.x * 0.5, badge.size.y + 4.0)).round()


# ── Drawing ──────────────────────────────────────────────────────────────────

func _reached(i: int) -> bool:
	return bool(_sites[i]["home"])


func _draw_back() -> void:
	if _sites.is_empty():
		return
	var acc := UIStyle.color(&"accent")
	# star dust along the arms
	var px := clampf(_scale() * 1.6, 1.0, 3.0)
	var view := Rect2(Vector2.ZERO, _space.size).grow(20.0)
	for d_i in _dust.size():
		var q := _project(_dust[d_i], _dust_h[d_i])
		if view.has_point(q):
			_back.draw_rect(Rect2(q.round(), Vector2(px, px)), Color(0.85, 0.88, 1.0, _dust_a[d_i] * 0.55))
	# territories, lying on the galaxy's surface: a faint fill and a border each
	_screen_polys.clear()
	for i in _sites.size():
		var s := _sites[i]
		var pts := PackedVector2Array()
		for q: Vector2 in s["poly"]:
			pts.append(_surf(q))
		_screen_polys.append(pts.duplicate())
		var lit := i == _hover or i == _selected
		var fill := Color(acc, 0.10 if s["home"] else (0.07 if lit else 0.025))
		if pts.size() >= 3:
			_back.draw_colored_polygon(pts, fill)
		pts.append(pts[0])
		var bcol := Color(acc, 0.85) if i == _selected else (Color(acc, 0.6) if lit or s["home"] else Color(0.7, 0.78, 0.92, 0.18))
		_back.draw_polyline(pts, bcol, 1.6 if lit or s["home"] else 1.0, true)
	# lanes between bordering neighbourhoods, by how far we have come
	var bridges: Array = _data.get("bridges", [])
	var inner := _entering if _entering >= 0 else _selected
	var inner_on := inner >= 0 and smoothstep(60.0, 140.0, float(_sites[inner]["size"]) * _scale()) > 0.3
	for l: Vector2i in _links:
		var a := _surf(_sites[l.x]["center"])
		var b := _surf(_sites[l.y]["center"])
		# zoomed in on a neighbourhood: its lanes leave from its star nearest
		# the other end, not from the middle
		if inner_on and l.x == inner:
			a = _gateway(inner, _sites[l.y]["center"])
		elif inner_on and l.y == inner:
			b = _gateway(inner, _sites[l.x]["center"])
		var on := l.x in [_hover, _selected] or l.y in [_hover, _selected]
		match int(_reached(l.x)) + int(_reached(l.y)):
			2:
				_back.draw_line(a, b, Color(acc, 0.15), 6.0, true)
				_back.draw_line(a, b, Color(acc.lerp(Color.WHITE, 0.3), 0.9), 2.0, true)
			1:
				_back.draw_line(a, b, Color(acc, 0.08), 5.0, true)
				_back.draw_line(a, b, Color(acc, 0.75 if on else 0.45), 1.3, true)
			_:
				# a bridge across a gap: longer dashes, so it reads as a crossing
				var gap := l in bridges
				_dashed(a, b, Color(acc.lerp(Color(0.6, 0.65, 0.75), 0.55), 0.5 if on else (0.32 if gap else 0.22)),
					1.4 if gap else 1.1, 16.0 if gap else 9.0)
	# the picked (or entered) neighbourhood's own stars
	if inner >= 0:
		_draw_inner(inner)
	# a node at each neighbourhood's heart
	for i in _sites.size():
		if i == inner and smoothstep(60.0, 140.0, float(_sites[i]["size"]) * _scale()) > 0.5:
			continue   # its stars are showing
		var c := _surf(_sites[i]["center"])
		var lit := i == _hover or i == _selected
		var col := ACC_COL if lit or _sites[i]["home"] else Color(0.8, 0.85, 0.95, 0.55)
		_back.draw_circle(c, 4.0 if lit else 3.0, Color(0, 0, 0, 0.6))
		_back.draw_arc(c, 4.0 if lit else 3.0, 0.0, TAU, 16, col, 1.4, true)


func _dashed(a: Vector2, b: Vector2, col: Color, w: float, dash := 9.0) -> void:
	var total := a.distance_to(b)
	if total < 1.0:
		return
	var dir := (b - a) / total
	var t := 0.0
	while t < total:
		_back.draw_line(a + dir * t, a + dir * minf(t + dash, total), col, w, true)
		t += dash + 6.0


func _draw_front() -> void:
	for i in _sites.size():
		var cell: PanelContainer = _sites[i].get("cell")
		if cell != null:
			var c := _surf(_sites[i]["center"])
			_front.draw_line(c - Vector2(0, 4), cell.position + Vector2(cell.size.x * 0.5, cell.size.y), Color(1, 1, 1, 0.6), 1.0)


# ── Input ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _sites.is_empty() or _leaving:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var lp := _space.get_global_transform().affine_inverse() * mm.global_position
		if _drag_btn >= 0:
			_drag_moved += mm.relative.length()
			_turn(mm.relative)   # any drag turns round the focus (no panning)
			get_viewport().set_input_as_handled()
			return
		var h := _site_at(lp)
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
					_wheel_in(lp)
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					_enter_charge = 0
					if _zoom_t <= ZOOM_MIN + 0.001 and _selected >= 0:
						_select(-1)
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
		else:
			if mg.factor < 1.0:
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


## Which neighbourhood a screen point is in (its cell as drawn, lifted).
func _site_at(lp: Vector2) -> int:
	for i in _screen_polys.size():
		if Geometry2D.is_point_in_polygon(lp, _screen_polys[i]):
			return i
	return -1


func _click(lp: Vector2, double: bool) -> void:
	var i := _site_at(lp)
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
		_focus_t = _sites[i]["center"]
		_zoom_t = maxf(_zoom_t, clampf(_zoom_for_screen_r(i, _space.size.y * 0.16), 1.2, ZOOM_MAX))
	else:
		_focus_t = Vector2.ZERO   # nothing picked: back round the galaxy's heart
	_build_panel()


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
	if _focus_t.length() > _radius:
		_focus_t = _focus_t.normalized() * _radius
	_focus = _focus_t
	_focus_v = Vector2.ZERO


func _turn(rel: Vector2) -> void:
	_yaw_t -= rel.x * 0.006
	_tilt_t = clampf(_tilt_t + rel.y * 0.0025, TILT_MIN, TILT_MAX)


# ── Into / out of a Star Cluster ─────────────────────────────────────────────

func _begin_enter(i: int) -> void:
	AudioManager.play("click")
	_selected = i
	_entering = i
	_focus_t = _sites[i]["pos"]   # the cluster's own middle (its core)
	_zoom_t = _zoom_for_cluster_r(i, _space.size.x * HANDOVER_SCREEN_R)


func _hand_over(i: int) -> void:
	_leaving = true
	var s := _sites[i]
	SceneTransition.go_soft(CLUSTER_SCENE, {"cluster_seed": int(s["seed"]), "home": bool(s["home"]),
		"index": i, "name": s["name"],
		"screen_r": float(_cluster_of(i)["outer"]) * _cl_scale(i) * _scale(),
		"yaw": _yaw, "tilt": _tilt})


## Came out of a Star Cluster: start on its cell at the size the cluster had,
## then ease out to its surroundings, picked.
func _arrive_from(d: Dictionary) -> void:
	var idx := int(d.get("index", -1))
	if idx < 0 or idx >= _sites.size():
		idx = _home
	if idx < 0:
		return
	# the cluster's stars where the cluster left them: same middle, size and angle
	_focus = _sites[idx]["pos"]
	_focus_t = _focus
	_zoom = _zoom_for_cluster_r(idx, float(d.get("screen_r", _space.size.x * 0.12)))
	_zoom_v = 0.0
	if d.has("yaw"):
		_yaw = float(d["yaw"])
		_yaw_t = _yaw
		_tilt = clampf(float(d["tilt"]), TILT_MIN, TILT_MAX)
		_tilt_t = _tilt
	# keep going the way the cluster was going: only ever further out from
	# where it handed over (framing the cell from here made it grow back)
	_zoom_t = clampf(minf(_zoom * ARRIVE_OUT, _zoom_for_screen_r(idx, _space.size.y * 0.16)), ZOOM_MIN, ZOOM_MAX)
	_selected = idx
	_build_panel()


# ── Side panel ───────────────────────────────────────────────────────────────

func _build_panel() -> void:
	if GameState.showcase_mode or _sites.is_empty():
		return
	var content := _panel.get_node("Layout/PanelContent")
	for c in content.get_children():
		if c.name in ["GalaxyHero", "GalaxyPanel"]:
			c.name = "__freeing"
			c.queue_free()
	var hero := HeroHeader.create("Galaxy", String(_data["name"]))
	hero.name = "GalaxyHero"
	content.add_child(hero)
	var root := VBoxContainer.new()
	root.name = "GalaxyPanel"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	content.add_child(root)
	root.add_child(_info_line("Neighbourhoods", str(_sites.size())))
	root.add_child(_info_line("Reached", "1"))
	root.add_child(HSeparator.new())
	if _selected >= 0 and not _sites[_selected]["home"]:
		root.add_child(SectionHeader.create("SELECTED", ""))
		root.add_child(_site_row(_selected))
		root.add_child(HSeparator.new())
	root.add_child(SectionHeader.create("NEIGHBOURHOODS", "1"))
	if _home >= 0:
		root.add_child(_site_row(_home))


func _site_row(i: int) -> Control:
	var s := _sites[i]
	var row := ListItem.create(String(s["name"]).to_upper(), "explore", "CLUSTER", PackedStringArray(),
		"Home neighbourhood" if s["home"] else "Uncharted")
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.selected = i == _selected
	row.icon_color = UIStyle.color(&"accent") if s["home"] else Color(0.62, 0.70, 0.82)
	row.mouse_entered.connect(func() -> void:
		_hover = i
		TooltipManager.show_tip(String(s["name"]), "Click to pick it on the map; click again to go down to it."))
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
