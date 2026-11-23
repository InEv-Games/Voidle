## Star System view — the layer above a planet (replaces the Solar View in play;
## SolarView / GalaxyView stay in the project, out of the game flow).
## (Development: Mechanic-Test/Star-Map.)
##
## The system on a tilted plane: the star in the middle, every planet standing
## still on its orbit (spread out so neighbours never meet, which fits more
## worlds on a small screen), its moons around it once you are close enough
## (LOD), a marker over each world. A few general orbit lines frame the system;
## a world's own orbit shows, dashed, while it is hovered or picked. Drag (left
## Picking a world adds a second control layer on it: a left drag / two-finger
## drag that starts on that world turns the globe round its axis (horizontal
## only, flung like the planet view) and its moons go round with it;
## Esc, a click on empty space or zooming out past the farthest zoom gives the
## controls back to the system.
## Otherwise a left drag (and a two-finger trackpad drag) moves the system on its plane;
## right drag (Shift + two-finger drag) turns and tilts it around the screen's
## centre; the wheel / pinch zooms towards the cursor, or the hovered world. Click a world to
## pick it and follow it; keep zooming into it (or click its row twice) and the
## planet view takes over: the camera closes in until the world has the size it
## has in the planet view, then SceneTransition.go_soft melts one scene into the
## other. Zooming out of a planet view lands here the same way, framed on that
## world, and eases out to the whole system.
##
## Details (SystemDetails): asteroid clusters on short arcs between orbits and
## nebula clouds in open space; hovered they light up with a dashed outline and
## their name, a click picks them (the camera goes to them, the panel shows them).
##
## The side panel is the system's own: its level (StarSystemProgress), what it
## allows, and its worlds as rows.
extends Control

const PLANET_SCENE := "res://scenes/planetary/PlanetaryView.tscn"
const PlanetView := preload("res://scripts/planetary/PlanetaryView.gd")   # its ship sprites

const ZOOM_MIN := 0.6
const ZOOM_MAX := 5.0
const ZOOM_STEP := 1.2
const TILT_MIN := 0.16
const TILT_MAX := 0.85
const CAM_TIME := 0.18
## Wheel steps into a world already at ZOOM_MAX before the planet view opens.
const ENTER_CHARGE := 2
## A turned planet swings its moons by this share of its spin (1 = together); a fling fades
## at this rate (1/s).
const MOON_SWING := 1.0
const FLING_DECAY := 2.5
## Up to the Star Cluster: wheel steps / pinch-out at the farthest zoom with
## nothing picked; the system then shrinks to CLUSTER_EXIT_ZOOM and the cluster
## takes over at that size. Coming down from it, the view opens at FROM_CLUSTER_ZOOM.
const CLUSTER_SCENE := "res://scenes/starcluster/StarClusterView.tscn"
const CLUSTER_EXIT_CHARGE := 3
const CLUSTER_EXIT_PINCH := 0.7
const CLUSTER_EXIT_ZOOM := 0.3
const CLUSTER_EXIT_SEC := 0.35
const FROM_CLUSTER_ZOOM := 0.3
var _cluster_charge := 0
var _cluster_pinch := 1.0
## Coming out of a planet view, the camera settles at this zoom on that world.
const ARRIVE_ZOOM := 2.2
const ARRIVE_ZOOM_MOON := 3.2
## The same for a trackpad pinch (product of the gesture factors).
const ENTER_PINCH := 1.4
var _enter_pinch := 1.0

## Plane layout (units = px at zoom 1 on a 1080 p screen).
const ORBIT_BASE := 210.0
const ORBIT_STEP := 115.0
## World size on screen at zoom 1 (px at 1080 p), relative to planet_size and
## stretched (power > 1) so the difference reads at a glance: a small barren
## world (0.5) ≈ 11 px, an Earth (1.0) 30, a gas giant (1.8) ≈ 72.
const BODY_PX := 30.0
const BODY_POW := 1.5
const BODY_MIN := 9.0
const BODY_MAX := 90.0
## Moons on the same scale, a little gentler so the smallest stay visible.
const MOON_PX := 26.0
const MOON_POW := 1.2
const MOON_MIN := 6.0
## Moons fade in between these zooms.
const MOON_LOD_A := 1.5
const MOON_LOD_B := 2.3

const RING_COL := Color(0.72, 0.84, 1.0, 0.26)
## Moons sit this much closer to their planet here than in the Planet System.
const SS_MOON_K := 0.45
## Ships and bases (ShipManager, GameState.outposts) — live, as in the Planet
## System: every world's ships circle it, a detail with a base gets a station
## mark and its own ships, and ships flying between them follow a transfer arc
## round the star (from one's orbit radius to the other's, swinging prograde,
## Kepler-paced: slower out where it is farther), its path dashed.
const SHIP_COL := Color(0.95, 0.97, 1.0)
const BASE_COL := Color(0.55, 0.95, 1.0)

## The golden angle that spreads the worlds around the star.
const GOLDEN := 2.39996323
const RING_SEL_COL := Color(0.55, 0.95, 1.0, 0.9)
const MARK_COL := Color(0.92, 0.96, 1.0)

@onready var _space: Control = $Space
@onready var _panel: LeftPanel = $SidePanel

var _solar: SolarData
## [{ pd, parent (index or -1), r, a0, speed, rect, mat, sz }]
var _bodies: Array[Dictionary] = []
var _star: ColorRect
## The star's light: two additive halos lying in the plane (emissive look) and a
## Light2D that brightens the orbit lines near it (they carry light mask 2).
var _halo_near: Sprite2D
var _halo_far: Sprite2D
var _light: PointLight2D
## A black hole's accretion disk (null for a star).
var _disk: Sprite2D = null
var _back: Node2D
var _mid: Node2D
var _front: Node2D
var _outer_r := 600.0
var _time := 0.0

# camera (current, target, spring velocity)
var _yaw := 0.6
var _yaw_t := 0.6
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
## Side panel slide, as in the planet view: Tab (LeftPanel._toggle_panel calls
## _set_panel_open on the current scene) or the ‹ › arrow by its stroke.
const PANEL_SLIDE_SEC := 0.9
var _panel_open := true
var _panel_t := 1.0
var _panel_tween: Tween = null
var _panel_toggle_btn: Button = null
## The starfield's material / viewport (Starfield.apply) and its last offset.
var _sky: Dictionary = {}
var _sky_off := Vector2.INF
## Details (SystemDetails.generate) and their nodes: nebula "sprites", "badge".
var _details: Array[Dictionary] = []
var _hover_f := -1
var _sel_f := -1
var _entering := -1
var _enter_charge := 0
var _leaving := false
var _drag_btn := -1
var _drag_from := Vector2.ZERO
var _drag_moved := 0.0
## The left drag started on the picked world: it turns that world, not the map.
var _drag_world := false
var _last_row_click := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	HUDManager.set_game_hud(not GameState.showcase_mode)
	CursorManager.set_state(CursorManager.State.NORMAL)
	# a fuller sky than the planet view's, with a little more haze; it drifts
	# a touch as the system is moved (parallax, _sky_follow)
	_sky = Starfield.apply($Background as ColorRect, {"density": 0.055, "brightness": 0.85, "nebula": 0.12})
	_back = Node2D.new()
	_back.z_index = 0
	_mid = Node2D.new()
	_mid.z_index = 55
	_front = Node2D.new()
	_front.z_index = 200
	for n: Node2D in [_back, _mid, _front]:
		n.z_as_relative = false
		_space.add_child(n)
	_back.draw.connect(_draw_back)
	_mid.draw.connect(_draw_mid)
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
	var from_body: PlanetData = pending if pending is PlanetData else null
	var sd: SolarData = pending if pending is SolarData else null
	if from_body != null and from_body.has_meta("__solar_data"):
		sd = from_body.get_meta("__solar_data") as SolarData
	if sd == null:
		sd = GameState.get_home_solar()
	await get_tree().process_frame   # sizes laid out
	_load(sd)
	if from_body != null:
		_arrive_from(from_body)
	elif GameState.has_meta("enter_from_cluster"):
		# down from the Star Cluster: the star starts at the size it had there
		GameState.remove_meta("enter_from_cluster")
		_zoom = FROM_CLUSTER_ZOOM
		_zoom_v = 0.0
		_zoom_t = 1.0
	NavigationManager.end_apply()
	if _solar != null:
		NavigationManager.visit(NavigationManager.solar_entry(_solar))


## Back / forward landing on this view while it shows the same system.
func nav_apply(entry: Dictionary) -> bool:
	var sd := entry.get("data") as SolarData
	if sd == null:
		return false
	if sd != _solar:
		_load(sd)
	NavigationManager.end_apply()
	return true


# ── Side panel slide (same as PlanetaryView) ─────────────────────────────────

func _set_panel_open(open: bool) -> void:
	if open and GameState.showcase_mode:
		return
	_panel_open = open
	if _panel_tween != null and _panel_tween.is_valid():
		_panel_tween.kill()
	_panel_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_panel_tween.tween_method(_apply_panel_t, _panel_t, 1.0 if open else 0.0, PANEL_SLIDE_SEC)


## t: 1 open … 0 hidden. The map takes the room the panel leaves.
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


## The arrow sits in the strip left of the panel's stroke, centred vertically.
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


# ── Building the system ──────────────────────────────────────────────────────

func _load(sd: SolarData) -> void:
	_solar = sd
	for b: Dictionary in _bodies:
		(b["rect"] as Node).queue_free()
		for key: String in ["cell", "badge"]:
			(b["marker"][key] as Node).queue_free()
	_bodies.clear()
	if _star != null:
		_star.queue_free()
	for l in [_halo_near, _halo_far, _light, _disk]:
		if l != null:
			l.queue_free()
	_disk = null
	for d: Dictionary in _details:
		for spr: Node in d.get("sprites", []):
			spr.queue_free()
		(d["badge"] as Node).queue_free()
	_details.clear()
	_hover = -1
	_selected = -1
	_hover_f = -1
	_sel_f = -1
	if sd == null:
		return
	_star = _make_star(sd)
	_space.add_child(_star)
	_make_light(sd)
	var rng := RandomNumberGenerator.new()
	for i in sd.planets.size():
		var pd: PlanetData = sd.planets[i]
		rng.seed = pd.seed ^ 0x5157
		var r := ORBIT_BASE + ORBIT_STEP * float(i)
		var p_idx := _bodies.size()
		# standing still, each a golden angle on from the last: far from both neighbours
		_bodies.append(_make_body(pd, -1, r, planet_angle(sd, i), 0.0, planet_px(pd)))
		if pd.moons.is_empty():
			pd.generate_moons(pd.seed)
		for j in pd.moons.size():
			var m: PlanetData = pd.moons[j]
			_bodies.append(_make_body(m, p_idx, 0.0, moon_angle(pd.seed, j), 0.0, moon_px(m)))
	_outer_r = ORBIT_BASE + ORBIT_STEP * float(maxi(sd.planets.size() - 1, 0))
	var planet_pos: Array[Vector2] = []
	for i in _bodies.size():
		if int(_bodies[i]["parent"]) < 0:
			planet_pos.append(_body_plane(i))
	_details = SystemDetails.generate(sd, planet_pos, ORBIT_BASE, ORBIT_STEP)
	for d: Dictionary in _details:
		_make_detail_nodes(d)
	_build_panel()


func _make_body(pd: PlanetData, parent: int, r: float, a0: float, speed: float, sz: float) -> Dictionary:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_as_relative = false
	var mat := _planet_material(pd)
	rect.material = mat
	_space.add_child(rect)
	return {"pd": pd, "parent": parent, "r": r, "a0": a0, "speed": speed, "rect": rect, "mat": mat,
		"marker": _make_marker(pd, parent >= 0),
		"sz": sz, "spin": randf() * TAU, "spin_v": randf_range(0.06, 0.16),
		"tilt": 0.0, "fling": 0.0, "turn": 0.0}


## A world's marker in the interface's own look: the IconCell of the list rows
## (ListItem) with the world's icon, and its name on a Badge beside it while
## hovered or picked. Settled worlds glow in the accent, the rest stay muted.
func _make_marker(pd: PlanetData, is_moon: bool) -> Dictionary:
	var cell := PanelContainer.new()
	cell.theme_type_variation = &"IconCell"
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.z_as_relative = false
	cell.z_index = 190
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var side := 14.0 if is_moon else 18.0
	icon.custom_minimum_size = Vector2(side, side)
	cell.add_child(icon)
	_space.add_child(cell)
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
	var m := {"cell": cell, "icon": icon, "badge": badge}
	_style_marker(m, pd)
	return m


func _style_marker(m: Dictionary, pd: PlanetData) -> void:
	var icon: TextureRect = m["icon"]
	var icon_id := _marker_icon(pd)
	var settled := icon_id != ""
	if icon_id == "":
		icon_id = "moon" if pd.planet_type == PlanetData.Type.MOON else "planet"
	icon.texture = UIIcons.get_icon(icon_id)
	icon.self_modulate = UIStyle.color(&"accent") if settled else Color(0.62, 0.70, 0.82)
	m["settled"] = settled


## The world's rim (a pixel ring drawn by its own shader): faint white so it
## stands off the background, brighter while hovered; the picked one gets a
## wider rim in the accent that breathes slowly.
func _set_rim(i: int, mat: ShaderMaterial) -> void:
	var px := 1.0
	var col := Color(1, 1, 1, 0.32)
	if i == _selected:
		px = 2.0
		col = Color(RING_SEL_COL, 0.65 + 0.35 * (0.5 + 0.5 * sin(_time * 3.0)))
	elif i == _hover:
		col = Color(1, 1, 1, 0.85)
	mat.set_shader_parameter("rim_px", px)
	mat.set_shader_parameter("rim_color", col)


## Puts each marker over its world (moons only once they show).
func _place_markers() -> void:
	var moon_a := _moon_alpha()
	for i in _bodies.size():
		var b := _bodies[i]
		var m: Dictionary = b["marker"]
		var cell: PanelContainer = m["cell"]
		var badge: PanelContainer = m["badge"]
		var is_moon := int(b["parent"]) >= 0
		var a := 1.0
		if is_moon:
			a = _moon_vis(i)
		var shown := a > 0.3 and (b["rect"] as CanvasItem).visible
		var lit := i == _hover or i == _selected
		# a marker only where there is something of ours; any world's name on hover
		cell.visible = shown and m["settled"]
		badge.visible = shown and lit
		var p := _project(_body_plane(i))
		var top := Vector2(p.x, p.y - _body_px(i) * 0.5 - 3.0)
		if cell.visible:
			var stem := 12.0 if is_moon else 20.0
			cell.size = cell.get_combined_minimum_size()
			cell.position = (top - Vector2(0, stem) - Vector2(cell.size.x * 0.5, cell.size.y)).round()
			cell.modulate.a = a
		if badge.visible:
			badge.size = badge.get_combined_minimum_size()
			if cell.visible:
				badge.position = (cell.position + Vector2(cell.size.x + 6.0, (cell.size.y - badge.size.y) * 0.5)).round()
			else:
				badge.position = (top - Vector2(badge.size.x * 0.5, badge.size.y + 8.0)).round()


# ── Details: asteroid clusters, nebulae ──────────────────────────────────────

## The sky drifts slowly against the system as it is moved (a far layer).
func _sky_follow() -> void:
	if _sky.is_empty():
		return
	# a skybox: it turns and tilts with the camera, drifting a little with the focus
	Skybox.follow(_sky, _yaw, _tilt, _focus.rotated(_yaw) * _ui() * 0.05, _ui())


func _make_detail_nodes(d: Dictionary) -> void:
	var sprites: Array[Sprite2D] = []
	if d["kind"] == "nebula":
		for b: Dictionary in d["blobs"]:
			var spr := _halo_sprite(b["col"], float(b["k"]), 3)
			sprites.append(spr)
	d["sprites"] = sprites
	var badge := PanelContainer.new()
	badge.theme_type_variation = &"Badge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_as_relative = false
	badge.z_index = 191
	var lbl := Label.new()
	lbl.text = String(d["name"]).to_upper()
	lbl.theme_type_variation = &"CounterLabel"
	badge.add_child(lbl)
	badge.visible = false
	_space.add_child(badge)
	d["badge"] = badge


## Nebula clouds lie in the plane (squashed by the tilt) and glow brighter while
## hovered / picked; each detail's name badge sits over it then.
func _place_details() -> void:
	var k := _scale()
	for f in _details.size():
		var d := _details[f]
		var lit := f == _hover_f or f == _sel_f
		if d["kind"] == "nebula":
			var sprites: Array = d["sprites"]
			var blobs: Array = d["blobs"]
			# a volume: each puff stands at its height off the plane (lifted by
			# how far the view looks down), and keeps most of its roundness
			var up := sqrt(maxf(0.0, 1.0 - _tilt * _tilt))
			var squash := lerpf(_tilt, 1.0, 0.6)
			for bi in sprites.size():
				var spr: Sprite2D = sprites[bi]
				var b: Dictionary = blobs[bi]
				var p := _project(Vector2(d["center"]) + Vector2(b["off"]))
				spr.position = Vector2(p.x, p.y - float(b["h"]) * k * up)
				spr.rotation = float(b["rot"]) - _yaw
				spr.scale = Vector2(float(b["elong"]), squash) * (float(b["r"]) * k / 128.0)
				spr.modulate = Color(1.7, 1.7, 1.7) if lit else Color.WHITE
		var badge: PanelContainer = d["badge"]
		badge.visible = lit
		if lit:
			var c := _project(d["center"])
			var top := Vector2(c.x, INF)
			if d["kind"] == "nebula":
				for q: Vector2 in _nebula_contour(d, 8.0):   # over the outline's top
					top.y = minf(top.y, q.y)
			else:
				top.y = c.y - (float(d["w"]) * k * _tilt + 14.0)
			badge.size = badge.get_combined_minimum_size()
			badge.position = (top - Vector2(badge.size.x * 0.5, badge.size.y + 6.0)).round()


## Asteroid rocks: little pixel squares, each on its own side of the star's
## depth (so a cluster passes behind / in front of it); lit ones go paler. The
## hovered / picked detail gets a dashed outline.
func _draw_details(back_half: bool, canvas: Node2D, star_depth: float) -> void:
	var k := _scale()
	for f in _details.size():
		var d := _details[f]
		var lit := f == _hover_f or f == _sel_f
		var col_ol := RING_SEL_COL if f == _sel_f else Color(RING_SEL_COL, 0.6)
		if d["kind"] == "asteroids":
			for rk: Dictionary in d["rocks"]:
				var a: float = rk["a"]
				var p := _project(Vector2(cos(a), sin(a)) * float(rk["r"]))
				if ((p.z - star_depth) < 0.0) != back_half:
					continue
				var px := clampf(float(rk["s"]) * k, 1.5, 16.0)
				var shade: float = rk["shade"]
				var col := Color(0.60 * shade, 0.55 * shade, 0.50 * shade)
				if lit:
					col = col.lerp(Color(0.85, 0.95, 1.0), 0.4)
				var at := (Vector2(p.x, p.y) - Vector2(px, px) * 0.5).round()
				canvas.draw_rect(Rect2(at - Vector2.ONE, Vector2(px, px) + Vector2(2, 2)), Color(0, 0, 0, 0.55))
				canvas.draw_rect(Rect2(at, Vector2(px, px)), col)
			if lit:
				var arcs := _arc_list(float(d["a"]), float(d["span"]) + 0.12)
				var w: float = d["w"]
				_ring(canvas, float(d["r"]) - w * 1.5, col_ol, 1.4, back_half, star_depth, 0.5, arcs)
				_ring(canvas, float(d["r"]) + w * 1.5, col_ol, 1.4, back_half, star_depth, 0.5, arcs)
		elif lit and not back_half:
			# a territory-like outline that follows the cloud's own shape
			var pts := _nebula_contour(d, 8.0)
			for e in range(0, pts.size() - 1):
				if e % 3 != 2:   # dashes
					canvas.draw_line(pts[e], pts[e + 1], col_ol, 1.6, true)


## How far a puff visibly reaches, as a share of its sprite's radius (the
## radial fade is near zero past this).
const NEBULA_EXTENT := 0.62
const CONTOUR_STEPS := 72

## Screen centre of a nebula (its puffs' average, with their heights).
func _nebula_screen_center(d: Dictionary) -> Vector2:
	var k := _scale()
	var up := sqrt(maxf(0.0, 1.0 - _tilt * _tilt))
	var sum := Vector2.ZERO
	var blobs: Array = d["blobs"]
	for b: Dictionary in blobs:
		var p := _project(Vector2(d["center"]) + Vector2(b["off"]))
		sum += Vector2(p.x, p.y - float(b["h"]) * k * up)
	return sum / float(maxi(blobs.size(), 1))


## For each direction from the cloud's centre, how far its farthest puff
## reaches on screen (each puff an ellipse: stretched, turned, squashed as
## drawn). Smoothed: the outline of the cloud as a whole.
func _nebula_radial(d: Dictionary, c: Vector2) -> PackedFloat32Array:
	var k := _scale()
	var up := sqrt(maxf(0.0, 1.0 - _tilt * _tilt))
	var squash := lerpf(_tilt, 1.0, 0.6)
	var ells: Array = []
	for b: Dictionary in d["blobs"]:
		var p := _project(Vector2(d["center"]) + Vector2(b["off"]))
		var r := float(b["r"]) * k * NEBULA_EXTENT
		ells.append([Vector2(p.x, p.y - float(b["h"]) * k * up) - c,
			r * float(b["elong"]), r * squash, float(b["rot"]) - _yaw])
	var out := PackedFloat32Array()
	out.resize(CONTOUR_STEPS)
	for s_i in CONTOUR_STEPS:
		var th := TAU * float(s_i) / float(CONTOUR_STEPS)
		var u := Vector2(cos(th), sin(th))
		var best := 0.0
		for e: Array in ells:
			# ray c + t·u against the ellipse (centre o, semi-axes ax, ay, turned rot)
			var o: Vector2 = e[0]
			var ax: float = e[1]
			var ay: float = e[2]
			var ur := u.rotated(-float(e[3]))
			var orr := o.rotated(-float(e[3]))
			var A := (ur.x * ur.x) / (ax * ax) + (ur.y * ur.y) / (ay * ay)
			var B := -2.0 * ((ur.x * orr.x) / (ax * ax) + (ur.y * orr.y) / (ay * ay))
			var C := (orr.x * orr.x) / (ax * ax) + (orr.y * orr.y) / (ay * ay) - 1.0
			var disc := B * B - 4.0 * A * C
			if disc < 0.0:
				continue
			var t := (-B + sqrt(disc)) / (2.0 * A)
			best = maxf(best, t)
		out[s_i] = best
	# smooth twice (neighbours) so the outline flows instead of scalloping
	for pass_i in 2:
		var sm := PackedFloat32Array()
		sm.resize(CONTOUR_STEPS)
		for s_i in CONTOUR_STEPS:
			sm[s_i] = (out[(s_i - 1 + CONTOUR_STEPS) % CONTOUR_STEPS] + out[s_i] * 2.0 + out[(s_i + 1) % CONTOUR_STEPS]) * 0.25
		out = sm
	return out


## The cloud's outline as a closed screen polyline, `pad` px outside it.
func _nebula_contour(d: Dictionary, pad: float) -> PackedVector2Array:
	var c := _nebula_screen_center(d)
	var rad := _nebula_radial(d, c)
	var pts := PackedVector2Array()
	for s_i in CONTOUR_STEPS + 1:
		var th := TAU * float(s_i % CONTOUR_STEPS) / float(CONTOUR_STEPS)
		pts.append(c + Vector2(cos(th), sin(th)) * (rad[s_i % CONTOUR_STEPS] + pad))
	return pts


func _in_contour(lp: Vector2, d: Dictionary) -> bool:
	var c := _nebula_screen_center(d)
	var v := lp - c
	var rad := _nebula_radial(d, c)
	var idx := int(round(fposmod(atan2(v.y, v.x), TAU) / TAU * float(CONTOUR_STEPS))) % CONTOUR_STEPS
	return v.length() <= rad[idx]


## [from, to] plane-angle pieces of an arc centred on `a`, split at 0 / TAU.
static func _arc_list(a: float, span: float) -> Array:
	var a0 := fposmod(a - span * 0.5, TAU)
	var a1 := a0 + span
	if a1 <= TAU:
		return [[a0, a1]]
	return [[a0, TAU], [0.0, a1 - TAU]]


## Which detail is under a screen point (-1: none).
func _detail_at(lp: Vector2) -> int:
	var q := _unproject_at(lp, _focus, _zoom, _yaw, _tilt)
	for f in _details.size():
		var d := _details[f]
		if d["kind"] == "asteroids":
			var diff := wrapf(atan2(q.y, q.x) - float(d["a"]), -PI, PI)
			if absf(diff) <= float(d["span"]) * 0.5 + 0.06 and absf(q.length() - float(d["r"])) <= float(d["w"]) * 1.6:
				return f
		elif _in_contour(lp, d):
			return f
	return -1


func _select_detail(f: int) -> void:
	_selected = -1
	_sel_f = f
	_enter_charge = 0
	AudioManager.play("poi_select")
	_focus_t = _details[f]["center"]
	_zoom_t = maxf(_zoom_t, 1.8)
	_build_panel()


func _make_light(sd: SolarData) -> void:
	var col: Vector3 = SolarData.get_star_colors(sd.star_type)["corona"]
	var core: Vector3 = SolarData.get_star_colors(sd.star_type)["surface"]
	var c := Color(col.x, col.y, col.z)
	var cc := Color(core.x, core.y, core.z)
	var bh := sd.star_type == SolarData.StarType.BLACK_HOLE
	_halo_far = _halo_sprite(c, 0.22 if bh else 0.30, 3)
	_halo_near = _halo_sprite(cc, 0.30 if bh else 0.55, 4)
	if bh:
		# the accretion disk: a bright ring lying in the plane, just under the hole
		_disk = Sprite2D.new()
		_disk.texture = _ring_tex(cc)
		var dm := CanvasItemMaterial.new()
		dm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		dm.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_disk.material = dm
		_disk.z_as_relative = false
		_disk.z_index = 49
		_space.add_child(_disk)
	_light = PointLight2D.new()
	_light.texture = _radial_tex(Color.WHITE, 1.0)
	_light.color = cc.lerp(Color.WHITE, 0.3)
	_light.energy = 1.6
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.range_item_cull_mask = 2
	_space.add_child(_light)
	_back.light_mask = 3
	_mid.light_mask = 3


func _halo_sprite(col: Color, strength: float, z: int) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = _radial_tex(col, strength)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	spr.material = mat
	spr.z_as_relative = false
	spr.z_index = z
	_space.add_child(spr)
	return spr


## 256 px radial falloff (bright middle, soft edge).
static func _radial_tex(col: Color, strength: float) -> GradientTexture2D:
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


func _make_star(sd: SolarData) -> ColorRect:
	if sd.star_type == SolarData.StarType.BLACK_HOLE:
		return make_black_hole(sd.seed)
	var s := ColorRect.new()
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.z_as_relative = false
	s.z_index = 50
	var colors := SolarData.get_star_colors(sd.star_type)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/star.gdshader")
	mat.set_shader_parameter("star_radius", 0.35)
	mat.set_shader_parameter("corona_size", 0.14)
	mat.set_shader_parameter("pixel_count", 96.0)
	mat.set_shader_parameter("aspect_ratio", 1.0)
	mat.set_shader_parameter("flicker_speed", 0.35)
	mat.set_shader_parameter("seed", sd.seed % 99999)
	mat.set_shader_parameter("color_core", colors["core"])
	mat.set_shader_parameter("color_surface", colors["surface"])
	mat.set_shader_parameter("color_corona", colors["corona"])
	s.material = mat
	return s


# ── Shared layout (Star System ⇄ Planet System) ──────────────────────────────
# Both views place a world's moons by these, so a moon is at the same angle and
# the same distance (in planet sizes) in both, and the switch lines up.

## A world's angle round the star (the golden-angle spread).
static func planet_angle(sd: SolarData, i: int) -> float:
	return fposmod(float(sd.seed % 628) * 0.01 + GOLDEN * float(i), TAU)


## Moon j's angle round its planet.
static func moon_angle(planet_seed: int, j: int) -> float:
	return OrbitLayout.moon_angle(planet_seed, j)


## A world's size on screen at zoom 1 (px at 1080 p).
static func planet_px(pd: PlanetData) -> float:
	return clampf(BODY_PX * pow(maxf(pd.planet_size, 0.05), BODY_POW), BODY_MIN, BODY_MAX)


static func moon_px(pd: PlanetData) -> float:
	return maxf(MOON_PX * pow(maxf(pd.planet_size, 0.05), MOON_POW), MOON_MIN)


## Moon j's orbit radius, for a planet `planet_diam` across (same unit back).
## Wide on purpose: room between a world and its moons for the flights
## (landers, rockets) to be seen.
static func moon_orbit(planet_diam: float, j: int) -> float:
	return planet_diam * 0.5 * (4.0 + 1.3 * float(j))


## A black hole in place of a star (also used by the Star Cluster view).
static func make_black_hole(seed_val: int) -> ColorRect:
	var s := ColorRect.new()
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.z_as_relative = false
	s.z_index = 50
	var c := SolarData.get_star_colors(SolarData.StarType.BLACK_HOLE)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/black_hole.gdshader")
	mat.set_shader_parameter("ring_color", c["core"])
	mat.set_shader_parameter("glow_color", c["corona"])
	mat.set_shader_parameter("seed", float(seed_val % 997))
	s.material = mat
	return s


## The same planet look as the other views (PlanetOrbitNode's material).
static func _planet_material(pd: PlanetData) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(PlanetData.get_shader_path(pd.planet_type))
	mat.set_shader_parameter("planet_radius", 0.40)
	mat.set_shader_parameter("pixel_count", 40.0)
	mat.set_shader_parameter("aspect_ratio", 1.0)
	mat.set_shader_parameter("seed", pd.seed)
	mat.set_shader_parameter("terrain_roughness", pd.terrain_roughness)
	mat.set_shader_parameter("rotation_offset", 0.0)
	mat.set_shader_parameter("night_shadow", SettingsManager.night_shadow)   # the night darkness setting
	var c := PlanetData.get_colors(pd.planet_type)
	match PlanetData.get_shader_type(pd.planet_type):
		PlanetData.ShaderType.ROCKY:
			mat.set_shader_parameter("sea_level", pd.sea_level)
			mat.set_shader_parameter("continent_scale", pd.continent_scale)
			mat.set_shader_parameter("continentality", pd.effective_continentality())
			mat.set_shader_parameter("has_clouds", 0.0)
			mat.set_shader_parameter("atmosphere_density", pd.atmosphere_density if pd.has_atmosphere else 0.0)
			mat.set_shader_parameter("specular_strength", pd.specular_strength)
			mat.set_shader_parameter("city_lights", 0.0)
			mat.set_shader_parameter("poi_count", 0)
			for key in c:
				mat.set_shader_parameter(key, c[key])
		PlanetData.ShaderType.GAS:
			mat.set_shader_parameter("cloud_speed", 0.0)
			mat.set_shader_parameter("atmosphere_density", pd.atmosphere_density)
			mat.set_shader_parameter("color_band_a", c.get("color_sand", Vector3(0.72, 0.55, 0.35)))
			mat.set_shader_parameter("color_band_b", c.get("color_forest", Vector3(0.50, 0.32, 0.18)))
			mat.set_shader_parameter("color_storm", c.get("color_snow", Vector3(0.88, 0.82, 0.72)))
			mat.set_shader_parameter("color_atmosphere", c.get("color_atmosphere", Vector3(0.72, 0.55, 0.35)))
		PlanetData.ShaderType.MOON:
			mat.set_shader_parameter("color_highland", c.get("color_mountain", Vector3(0.62, 0.60, 0.56)))
			mat.set_shader_parameter("color_mare", c.get("color_deep_ocean", Vector3(0.22, 0.21, 0.20)))
			mat.set_shader_parameter("color_rim", c.get("color_snow", Vector3(0.78, 0.76, 0.72)))
			mat.set_shader_parameter("color_floor", c.get("color_ocean", Vector3(0.16, 0.15, 0.14)))
		PlanetData.ShaderType.ASTEROID:
			mat.set_shader_parameter("irregularity", pd.irregularity)
			mat.set_shader_parameter("elongation", 1.0 + pd.irregularity * 0.8)
	return mat


# ── Camera & projection ──────────────────────────────────────────────────────

## Screen scale: 1080 p reference.
func _ui() -> float:
	return maxf(_space.size.y, 1.0) / 1080.0


## How much the plane is spread to fill the view at zoom 1.
func _fit() -> float:
	return minf((_space.size.x * 0.44) / maxf(_outer_r * _ui(), 1.0), 1.4)


## Plane units → px at the current zoom.
func _scale() -> float:
	return _zoom * _ui() * _fit()


func _center() -> Vector2:
	return _space.size * 0.5 + Vector2(0, _space.size.y * 0.04)


## Plane point → Vector3(local x, local y, depth); depth > 0 = nearer (lower).
func _project(p: Vector2) -> Vector3:
	var d := p - _focus
	var c := cos(_yaw)
	var s := sin(_yaw)
	var rx := d.x * c - d.y * s
	var ry := d.x * s + d.y * c
	var k := _scale()
	return Vector3(_center().x + rx * k, _center().y + ry * _tilt * k, ry)


func _body_plane(i: int) -> Vector2:
	var b := _bodies[i]
	var a: float = float(b["a0"]) + _time * float(b["speed"])
	if int(b["parent"]) >= 0:
		a += float(_bodies[int(b["parent"])]["turn"])   # swung by hand (picked planet)
	if int(b["parent"]) < 0:
		return Vector2(cos(a), sin(a)) * float(b["r"])
	var pb := _bodies[int(b["parent"])]
	# in step with the planet's size on screen, whatever the zoom
	# kept small here (a miniature): the Planet System spreads them out on zoom
	var mr := moon_orbit(float(pb["sz"]), _moon_index(i)) * SS_MOON_K
	return _body_plane(int(b["parent"])) + Vector2(cos(a), sin(a)) * mr / _fit()


func _moon_index(i: int) -> int:
	var p := int(_bodies[i]["parent"])
	var n := 0
	for k in range(p + 1, i):
		if int(_bodies[k]["parent"]) == p:
			n += 1
	return n


func _body_px(i: int) -> float:
	return float(_bodies[i]["sz"]) * _zoom * _ui()


## How visible moon i is: only the picked world's moons show (and the picked
## or entered moon with its siblings), the rest stay hidden whatever the zoom.
func _moon_vis(i: int) -> float:
	var par := int(_bodies[i]["parent"])
	if i == _selected or i == _entering:
		return 1.0
	for pick: int in [_selected, _entering]:
		if pick < 0:
			continue
		if pick == par or int(_bodies[pick]["parent"]) == par:
			return 1.0
	return 0.0


func _moon_alpha() -> float:
	return smoothstep(MOON_LOD_A, MOON_LOD_B, _zoom)


## The zoom at which a world has the size it has in the planet view at `pv_zoom`
## (PlanetaryView: radius = clamp(0.42 × size, 0.10, 0.48) of the view height).
func _zoom_for_planet_view(i: int, pv_zoom: float) -> float:
	var pd: PlanetData = _bodies[i]["pd"]
	var diam := 2.0 * clampf(0.42 * clampf(pd.planet_size, 0.2, 2.0), 0.10, 0.48) * _space.size.y * pv_zoom
	return diam / maxf(float(_bodies[i]["sz"]) * _ui(), 1.0)


# ── Frame ────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _solar == null:
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
	_place_star()
	_place_bodies(delta)
	_place_markers()
	_place_details()
	_sky_follow()
	_back.queue_redraw()
	_mid.queue_redraw()
	_front.queue_redraw()
	if _entering >= 0 and not _leaving and _zoom >= _zoom_t * 0.96:
		_hand_over(_entering)


func _place_star() -> void:
	var p := _project(Vector2.ZERO)
	# the light lies in the system's plane: an ellipse squashed by the tilt
	for l: Node2D in [_halo_near, _halo_far, _light]:
		l.position = Vector2(p.x, p.y)
	var k := _scale()
	_halo_near.scale = Vector2(1.0, _tilt) * (ORBIT_BASE * 1.1 * k / 128.0)
	_halo_far.scale = Vector2(1.0, _tilt) * (_outer_r * 1.25 * k / 128.0)
	_light.scale = Vector2(1.0, _tilt) * (_outer_r * 0.9 * k / 128.0)
	var px := clampf(150.0 * _zoom * _ui(), 40.0, 2400.0)
	_star.size = Vector2(px, px)
	_star.position = Vector2(p.x, p.y) - _star.size * 0.5
	(_star.material as ShaderMaterial).set_shader_parameter("pixel_count", clampf(px * 0.45, 48.0, 220.0))
	if _disk != null:
		_disk.position = Vector2(p.x, p.y)
		_disk.rotation = 0.0
		_disk.scale = Vector2(1.0, _tilt) * (px * 0.9 / 128.0)


## A ring texture (transparent middle, bright band, soft fade out) for a disk.
static func _ring_tex(col: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.30, 0.38, 0.5, 0.75, 1.0])
	g.colors = PackedColorArray([Color(col, 0.0), Color(col, 0.0), Color(col.lerp(Color.WHITE, 0.4), 0.95),
		Color(col, 0.6), Color(col, 0.15), Color(col, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t


func _place_bodies(delta: float) -> void:
	var star_p := _project(Vector2.ZERO)
	var moon_a := _moon_alpha()
	for i in _bodies.size():
		var b := _bodies[i]
		var rect: ColorRect = b["rect"]
		var is_moon := int(b["parent"]) >= 0
		var a := 1.0
		if is_moon:
			a = _moon_vis(i)
		rect.visible = a > 0.02
		if not rect.visible:
			continue
		var p := _project(_body_plane(i))
		var px := _body_px(i)
		rect.size = Vector2(px, px) / 0.8   # the shader draws the disc at 0.4 of the rect
		rect.position = Vector2(p.x, p.y) - rect.size * 0.5
		rect.modulate.a = a
		# depth order: a planet against the star (even steps, so its moons fit
		# between), a moon just behind / in front of its own planet by its own
		# depth against the planet's (the planet always comes first in _bodies)
		b["depth"] = p.z
		var owner_i := int(b["parent"])
		if owner_i < 0:
			var dd := p.z - star_p.z
			rect.z_index = (60 + 2 * mini(40, int(absf(dd) * 0.05))) if dd > 0.0 \
				else (45 - 2 * mini(17, int(absf(dd) * 0.05)))
		else:
			var pr: ColorRect = _bodies[owner_i]["rect"]
			rect.z_index = pr.z_index + (1 if p.z > float(_bodies[owner_i].get("depth", 0.0)) else -1)
		var mat: ShaderMaterial = b["mat"]
		mat.set_shader_parameter("pixel_count", clampf(px * 0.55, 16.0, 150.0))
		# its own slow turn, plus what a drag flung (fading out)
		var fl: float = b["fling"]
		var par := int(b["parent"])
		var carried: float = float(_bodies[par]["fling"]) if par >= 0 else 0.0   # a moon turns with its flung planet
		b["spin"] = fposmod(float(b["spin"]) + (float(b["spin_v"]) + fl + carried) * delta, TAU)
		b["turn"] = float(b["turn"]) + fl * MOON_SWING * delta
		b["fling"] = fl * exp(-FLING_DECAY * delta) if absf(fl) > 0.001 else 0.0
		mat.set_shader_parameter("rotation_offset", b["spin"])
		mat.set_shader_parameter("night_shadow", SettingsManager.night_shadow)   # follows the setting live
		mat.set_shader_parameter("tilt", b["tilt"])
		_set_rim(i, mat)
		var to_star := Vector2(star_p.x - p.x, star_p.y - p.y)
		# mostly from the front, leaning towards the star: lit faces, a soft terminator
		var ld := Vector3(to_star.x, to_star.y, maxf(to_star.length() * 1.1, 1.0)).normalized()
		mat.set_shader_parameter("light_direction", ld)


# ── Drawing ──────────────────────────────────────────────────────────────────

# ── Ships, routes and bases ──────────────────────────────────────────────────

## Every place ships can be in this system: { seed: { pos (plane), r (px-ish
## radius of the thing, for the parking ring), detail (index or -1) } }.
func _ship_places() -> Dictionary:
	var out := {}
	for i in _bodies.size():
		if int(_bodies[i]["parent"]) >= 0:
			continue
		out[(_bodies[i]["pd"] as PlanetData).seed] = {"pos": _body_plane(i), "r": _body_px(i) * 0.5 / maxf(_scale(), 0.001), "detail": -1}
	for f in _details.size():
		var ds := OrbitLayout.detail_seed(_solar.seed, f)
		out[ds] = {"pos": _details[f]["center"], "r": 14.0 / maxf(_fit(), 0.01), "detail": f}
	return out


## Plane point of a transfer between two places at u: round the star from one
## radius to the other, prograde, a little swing out on the way.
func _route_point(pa: Vector2, pb: Vector2, u: float) -> Vector2:
	var ta := pa.angle()
	var tb := pb.angle()
	var sweep := fposmod(tb - ta, TAU)   # prograde, the way the worlds go round
	var ra := pa.length()
	var rb := pb.length()
	# Kepler-ish pacing: the angle runs faster where the arc is nearer the star
	var k := u * u * (3.0 - 2.0 * u)
	var r := lerpf(ra, rb, k) * (1.0 + 0.12 * sin(PI * u))
	return Vector2.from_angle(ta + sweep * k) * r


func _draw_routes(back_half: bool, canvas: Node2D) -> void:
	var places := _ship_places()
	var star_z := _project(Vector2.ZERO).z
	for sd: int in places:
		for sh: ShipData in ShipManager.ships_for(sd):
			if not sh.is_travelling() or not places.has(sh.dest_seed):
				continue
			var pa: Vector2 = places[sd]["pos"]
			var pb: Vector2 = places[sh.dest_seed]["pos"]
			var prev := _project(_route_point(pa, pb, 0.0))
			for kk in range(1, 49):
				var uu := float(kk) / 48.0
				var q := _project(_route_point(pa, pb, uu))
				if (((q.z + prev.z) * 0.5 - star_z) < 0.0) == back_half and kk % 3 != 0:
					canvas.draw_line(Vector2(prev.x, prev.y), Vector2(q.x, q.y),
						Color(SHIP_COL, 0.42 if uu > sh.travel_progress else 0.14), 1.0, true)
				prev = q


func _draw_ships() -> void:
	var places := _ship_places()
	for sd: int in places:
		var pl: Dictionary = places[sd]
		var f: int = pl["detail"]
		if f >= 0 and GameState.outposts.has(str(sd)):
			# a base: a station mark on the detail
			var bc := _project(pl["pos"])
			var c := Vector2(bc.x, bc.y).round()
			_front.draw_rect(Rect2(c - Vector2(4, 4), Vector2(8, 8)), Color(0, 0, 0, 0.7))
			_front.draw_rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), BASE_COL)
		for sh: ShipData in ShipManager.ships_for(sd):
			if sh.traffic_state == "pad" or sh.orbit_radius < 0.999:
				continue
			if sh.is_travelling():
				if places.has(sh.dest_seed):
					var pa: Vector2 = pl["pos"]
					var pb: Vector2 = places[sh.dest_seed]["pos"]
					var u := clampf(sh.travel_progress, 0.0, 1.0)
					var q := _project(_route_point(pa, pb, u))
					var burn := u < 0.1 or u > 0.9
					if burn:
						var ah := _project(_route_point(pa, pb, minf(u + 0.01, 1.0)))
						var d := (Vector2(ah.x, ah.y) - Vector2(q.x, q.y)).normalized()
						_front.draw_rect(Rect2((Vector2(q.x, q.y) - Vector2.ONE).floor() - (d * 3.0).round(), Vector2(2, 2)),
							Color(1.0, 0.6, 0.1, 0.9))
					PlanetView.draw_ship_sprite(_front, Vector2(q.x, q.y), sh.ship_type, Color(1, 1, 1, 0.92))
				continue
			# ships circling a world are left to the Planet System (too small here)


## Buttons for DebugPopup: real pioneers (ShipManager.send_pioneer) — on
## arrival they open a route, and haulers start running it on their own.
func debug_actions() -> Array:
	var out: Array = []
	var home := GameState.home_planet_seed
	if _selected >= 0 and int(_bodies[_selected]["parent"]) < 0:
		var pd: PlanetData = _bodies[_selected]["pd"]
		if pd.seed != home:
			out.append({"name": "Pioneer: home → %s" % pd.planet_name, "call": func() -> void:
				ShipManager.send_pioneer(home, pd.seed)
				AudioManager.play("click")})
	if _sel_f >= 0:
		var d := _details[_sel_f]
		var ds := OrbitLayout.detail_seed(_solar.seed, _sel_f)
		out.append({"name": "Pioneer: home → %s (set up a base)" % d["name"], "call": func() -> void:
			ShipManager.send_pioneer(home, ds, {"kind": d["kind"], "name": d["name"], "system": _solar.seed})
			AudioManager.play("click")})
	if out.is_empty():
		out.append({"name": "(pick a world or an asteroid cluster / nebula)", "call": func() -> void: pass})
	out.append({"name": "Clear all routes, bases and haulers (test)", "call": func() -> void:
		GameState.traffic_links.clear()
		GameState.outposts.clear()
		for pd: PlanetData in _solar.planets:
			for sh: ShipData in ShipManager.ships_for(pd.seed):
				if sh.ship_type in [ShipManager.HAULER, ShipManager.PIONEER]:
					ShipManager.remove_ship(sh.orbit_seed, sh.ship_id)
		for f in _details.size():
			for sh: ShipData in ShipManager.ships_for(OrbitLayout.detail_seed(_solar.seed, f)):
				ShipManager.remove_ship(sh.orbit_seed, sh.ship_id)})
	return out


func _draw_back() -> void:
	if _solar == null:
		return
	_draw_rings(true, _back)   # the star's glow is _halo_* / _light now
	_draw_details(true, _back, _project(Vector2.ZERO).z)
	_draw_routes(true, _back)


func _draw_mid() -> void:
	if _solar == null:
		return
	_draw_rings(false, _mid)
	_draw_details(false, _mid, _project(Vector2.ZERO).z)
	_draw_routes(false, _mid)


## Orbit rings, split at the star's depth so the near half passes in front of it.
func _draw_rings(back_half: bool, canvas: Node2D) -> void:
	if _solar == null:
		return
	var sd := _project(Vector2.ZERO).z
	var acc := UIStyle.color(&"accent")
	var r_in := ORBIT_BASE * 0.6
	var r_out := _outer_r * 1.2
	var r_mid := lerpf(r_in, r_out, 0.55)
	# HUD-style screen lines (SkillTree look): few, each of its own kind
	# inner: one hairline
	_ring(canvas, r_in, Color(acc, 0.16), 1.0, back_half, sd)
	# middle: a soft wide band with a crisp line on it
	_ring(canvas, r_mid, Color(acc, 0.05), 7.0, back_half, sd)
	_ring(canvas, r_mid, Color(acc, 0.30), 1.4, back_half, sd)
	# between: broken arcs with ticks, like a scale
	var r_arc := lerpf(r_in, r_mid, 0.5)
	_ring(canvas, r_arc, Color(acc, 0.22), 2.0, back_half, sd, 0.0,
		[[0.15, 1.35], [2.0, 2.9], [3.5, 4.9], [5.4, 6.0]])
	_ticks(canvas, r_arc, r_arc * 1.035, 48, Color(acc, 0.16), back_half, sd)
	# outer: fine dashes, with four heavy brackets on it
	_ring(canvas, r_out, Color(acc, 0.16), 1.0, back_half, sd, 0.5)
	_ring(canvas, r_out, Color(acc, 0.45), 3.0, back_half, sd, 0.0,
		[[0.70, 0.95], [2.27, 2.52], [3.84, 4.09], [5.41, 5.66]])
	# the hovered / picked world's own orbit, dashed
	for idx: int in [_hover, _selected]:
		if idx < 0:
			continue
		var owner_i := idx if int(_bodies[idx]["parent"]) < 0 else int(_bodies[idx]["parent"])
		var col := RING_SEL_COL if idx == _selected else Color(RING_SEL_COL, 0.6)
		_ring(canvas, float(_bodies[owner_i]["r"]), col, 1.6, back_half, sd, 0.5)


## An orbit-plane circle of radius r. dash > 0: dashed; arcs: only these
## [from, to] plane angles (radians). Split at the star's depth (back_half).
func _ring(canvas: Node2D, r: float, col: Color, w: float, back_half: bool, star_depth: float,
		dash := 0.0, arcs: Array = [], center := Vector2.ZERO) -> void:
	var n := 180
	var prev := _project(center + Vector2(r, 0.0))
	for k in range(1, n + 1):
		var a := TAU * float(k) / float(n)
		var p := _project(center + Vector2(cos(a), sin(a)) * r)
		var draw_it: bool = (((p.z + prev.z) * 0.5 - star_depth) < 0.0) == back_half
		if draw_it and dash > 0.0:
			draw_it = k % 4 < 2
		if draw_it and not arcs.is_empty():
			draw_it = false
			var am := a - TAU / float(n) * 0.5
			for arc: Array in arcs:
				if am >= float(arc[0]) and am <= float(arc[1]):
					draw_it = true
		if draw_it:
			canvas.draw_line(Vector2(prev.x, prev.y), Vector2(p.x, p.y), col, w, true)
		prev = p


## Short radial ticks between r0 and r1, `count` around the circle.
func _ticks(canvas: Node2D, r0: float, r1: float, count: int, col: Color, back_half: bool, star_depth: float) -> void:
	for k in count:
		var a := TAU * float(k) / float(count)
		var d := Vector2(cos(a), sin(a))
		var p0 := _project(d * r0)
		if (p0.z - star_depth < 0.0) != back_half:
			continue
		var p1 := _project(d * (r1 if k % 4 == 0 else lerpf(r0, r1, 0.5)))
		canvas.draw_line(Vector2(p0.x, p0.y), Vector2(p1.x, p1.y), col, 1.0, true)


func _draw_front() -> void:
	if _solar == null:
		return
	_draw_ships()
	# marker stems (the markers themselves are UI nodes: _place_markers)
	for i in _bodies.size():
		var m: Dictionary = _bodies[i]["marker"]
		var cell: Control = m["cell"]
		if not cell.visible:
			continue
		var p := _project(_body_plane(i))
		var top := Vector2(p.x, p.y - _body_px(i) * 0.5 - 3.0)
		var bottom := cell.position + Vector2(cell.size.x * 0.5, cell.size.y)
		var lit := i == _hover or i == _selected
		_front.draw_line(top, bottom, Color(RING_SEL_COL if lit else MARK_COL, 0.6 * cell.modulate.a), 1.0)


## Marker icon of a world: the home world, a settled world, the rocket's target.
func _marker_icon(pd: PlanetData) -> String:
	if pd.seed == GameState.home_planet_seed:
		return "city"
	var pp := GameState.find_planet(pd.seed)
	if pp != null and pp.is_colonized:
		return "moon" if pd.planet_type == PlanetData.Type.MOON else "planet"
	return ""


# ── Input ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _solar == null or _leaving:
		return
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var lp := _space.get_global_transform().affine_inverse() * mm.global_position
		if _drag_btn >= 0:
			_drag_moved += mm.relative.length()
			if _drag_btn == MOUSE_BUTTON_LEFT and _drag_world and _selected >= 0:
				_turn_world(_selected, mm.relative, mm.velocity)
			else:
				_turn(mm.relative)   # any other drag turns round the focus (no panning)
			get_viewport().set_input_as_handled()
			return
		var h := _body_at(lp)
		var hf := _detail_at(lp) if h < 0 else -1
		if h != _hover or hf != _hover_f:
			if (h >= 0 and h != _hover) or (hf >= 0 and hf != _hover_f):
				AudioManager.play("hover")
			_hover = h
			_hover_f = hf
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var lp := _space.get_global_transform().affine_inverse() * mb.global_position
		match mb.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if mb.pressed:
					_drag_btn = mb.button_index
					_drag_from = lp
					_drag_moved = 0.0
					_drag_world = mb.button_index == MOUSE_BUTTON_LEFT and _on_picked(lp)
					if _drag_world:
						_bodies[_selected]["fling"] = 0.0   # caught by the hand
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
					_wheel_out(lp)
					get_viewport().set_input_as_handled()
		return
	# trackpad: pinch zooms (towards the fingers / the hovered world, into a
	# world at the closest zoom); a two-finger drag turns and tilts like a drag
	if event is InputEventMagnifyGesture:
		var mg := event as InputEventMagnifyGesture
		_pinch(_space.get_global_transform().affine_inverse() * mg.position, mg.factor)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventPanGesture:
		var pg := event as InputEventPanGesture
		if pg.shift_pressed:
			_turn(pg.delta * 2.0)
		elif _on_picked(_space.get_global_transform().affine_inverse() * pg.position):
			_turn_world(_selected, -pg.delta * 6.0, Vector2.ZERO)
		else:
			_turn(-pg.delta * 2.0)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE and (_selected >= 0 or _sel_f >= 0):
			_select(-1)
			get_viewport().set_input_as_handled()


func _body_at(lp: Vector2) -> int:
	var best := -1
	var best_d := INF
	var moon_a := _moon_alpha()
	for i in _bodies.size():
		if int(_bodies[i]["parent"]) >= 0 and _moon_vis(i) < 0.3:
			continue
		var p := _project(_body_plane(i))
		var rad := maxf(_body_px(i) * 0.5, 8.0) + 4.0
		var d := Vector2(p.x, p.y).distance_to(lp)
		if d < rad and d < best_d:
			best_d = d
			best = i
	return best


func _click(lp: Vector2, double: bool) -> void:
	var i := _body_at(lp)
	if i < 0:
		var f := _detail_at(lp)
		if f >= 0:
			if f != _sel_f:
				_select_detail(f)
		elif _selected >= 0 or _sel_f >= 0:
			_select(-1)
		return
	var pd: PlanetData = _bodies[i]["pd"]
	if GameState.rocket_picking() and GameState.rocket_target_block(pd.seed) == "":
		_offer_rocket_target(pd)
		return
	if double or i == _selected:
		_begin_enter(i)
		return
	_select(i)


func _select(i: int) -> void:
	_selected = i
	_sel_f = -1
	_enter_charge = 0
	if i < 0:
		_focus_t = Vector2.ZERO
		_zoom_t = clampf(_zoom_t, ZOOM_MIN, 1.4)
	else:
		AudioManager.play("poi_select")
		_focus_t = _body_plane(i)
		# close enough that even a small world shows (~70 px)
		var want := clampf(70.0 / float(_bodies[i]["sz"]), 1.8 if int(_bodies[i]["parent"]) < 0 else 2.6, ZOOM_MAX)
		_zoom_t = maxf(_zoom_t, want)
	_build_panel()


func _wheel_in(lp: Vector2) -> void:
	var target := _hover if _hover >= 0 else _selected
	if _zoom_t >= ZOOM_MAX - 0.001 and target >= 0:
		_enter_charge += 1
		if _enter_charge >= ENTER_CHARGE:
			_begin_enter(target)
		return
	_zoom_to(clampf(_zoom_t * ZOOM_STEP, ZOOM_MIN, ZOOM_MAX), lp)


func _wheel_out(lp: Vector2) -> void:
	_enter_charge = 0
	if _zoom_t <= ZOOM_MIN + 0.001:
		# a few more steps out go up to the Star Cluster (the first lets go of
		# a pick, if there is one)
		if _selected >= 0 or _sel_f >= 0:
			_select(-1)
		_cluster_charge += 1
		if _cluster_charge >= CLUSTER_EXIT_CHARGE:
			_go_to_cluster()
		return
	_cluster_charge = 0
	_zoom_to(clampf(_zoom_t / ZOOM_STEP, ZOOM_MIN, ZOOM_MAX), lp)


## Moves the system on its plane by a screen delta (the plane follows the hand).
func _pan(rel: Vector2) -> void:
	var k := _scale()
	var dx := rel.x / k
	var dy := rel.y / (k * _tilt)
	var c := cos(_yaw)
	var sn := sin(_yaw)
	var d := Vector2(dx * c + dy * sn, -dx * sn + dy * c)
	_focus_t -= d
	var lim := _outer_r * 1.25
	if _focus_t.length() > lim:
		_focus_t = _focus_t.normalized() * lim
	_focus = _focus_t   # 1:1 with the hand, no lag
	_focus_v = Vector2.ZERO


## Whether a screen point is on the picked world (a little margin round it).
func _on_picked(lp: Vector2) -> bool:
	if _selected < 0:
		return false
	var p := _project(_body_plane(_selected))
	return Vector2(p.x, p.y).distance_to(lp) <= maxf(_body_px(_selected) * 0.65, 14.0)


## Picked world under the hand: a horizontal drag spins the globe and takes
## its moons round with it; the release keeps some spin (fling).
func _turn_world(i: int, rel: Vector2, vel: Vector2) -> void:
	var b := _bodies[i]
	var r_px := maxf(_body_px(i) * 0.5, 12.0)
	# horizontal only; the surface follows the hand (rotation_offset runs the
	# other way), and the moons go round with it, one with the globe
	var d_spin := -rel.x / r_px
	b["spin"] = fposmod(float(b["spin"]) + d_spin, TAU)
	b["turn"] = float(b["turn"]) + d_spin * MOON_SWING
	for k in _bodies.size():
		if int(_bodies[k]["parent"]) == i:
			_bodies[k]["spin"] = fposmod(float(_bodies[k]["spin"]) + d_spin, TAU)
	b["fling"] = clampf(-vel.x / r_px, -6.0, 6.0) if vel != Vector2.ZERO else 0.0


## Turns (x) and tilts (y) the plane around the screen's centre.
func _turn(rel: Vector2) -> void:
	_yaw_t -= rel.x * 0.006
	_tilt_t = clampf(_tilt_t + rel.y * 0.0025, TILT_MIN, TILT_MAX)


## Trackpad pinch: zoom by `factor`; pinching on at the closest zoom over a
## world goes down into it once it adds up to ENTER_PINCH.
func _pinch(lp: Vector2, factor: float) -> void:
	var target := _hover if _hover >= 0 else _selected
	if factor > 1.0 and _zoom_t >= ZOOM_MAX - 0.001 and target >= 0:
		_enter_pinch *= factor
		if _enter_pinch >= ENTER_PINCH:
			_enter_pinch = 1.0
			_begin_enter(target)
		return
	if factor < 1.0:
		_enter_pinch = 1.0
		if _zoom_t <= ZOOM_MIN + 0.001:
			# at the farthest zoom a pinch-out lets go of the pick (coming out
			# of a planet view, its world is picked) and goes on up
			if _selected >= 0 or _sel_f >= 0:
				_select(-1)
			_cluster_pinch *= factor
			if _cluster_pinch <= CLUSTER_EXIT_PINCH:
				_cluster_pinch = 1.0
				_go_to_cluster()
			return
	else:
		_cluster_pinch = 1.0
	_zoom_to(clampf(_zoom_t * factor, ZOOM_MIN, ZOOM_MAX), lp)


## Zooms keeping one point where it is on screen: the hovered world, else the
## plane point under the cursor (worked out on the target camera, so quick
## wheel steps chain up smoothly).
## Zooms on the focus (the picked object, else the middle): no panning — the
## view is moved by picking things, it turns round whatever is picked.
func _zoom_to(z: float, _lp: Vector2) -> void:
	_zoom_t = z


func _unproject_at(sp: Vector2, focus: Vector2, zoom: float, yaw := INF, tilt := INF) -> Vector2:
	if yaw == INF:
		yaw = _yaw_t
	if tilt == INF:
		tilt = _tilt_t
	var k := zoom * _ui() * _fit()
	var rx := (sp.x - _center().x) / k
	var ry := (sp.y - _center().y) / (k * tilt)
	var c := cos(yaw)
	var sn := sin(yaw)
	return focus + Vector2(rx * c + ry * sn, -rx * sn + ry * c)


# ── Into / out of a planet view ──────────────────────────────────────────────

func _can_enter(pd: PlanetData) -> bool:
	if pd.planet_type == PlanetData.Type.MOON:
		var home := GameState.get_home_planet()
		if home != null and pd in home.moons and not GameState.can_view_moon():
			return false
	return true


## Closes in on world i until it has its planet-view size, then hands over.
func _begin_enter(i: int) -> void:
	var pd: PlanetData = _bodies[i]["pd"]
	if not _can_enter(pd):
		AudioManager.play("error")
		NewsFeed.show_message("system_locked", _solar.system_name, pd.planet_name, "Not reachable yet.", {"sec": 3.0})
		return
	AudioManager.play("click")
	_selected = i
	_entering = i
	_focus_t = _body_plane(i)
	# close in until the world is as big as the Planet System opens with it
	_zoom_t = _zoom_for_planet_view(i, HANDOVER_PV)


## Going down hands over to the Planet System (the world and its moons) at
## this size, in the planet view's terms; the angle goes along too.
const PLANET_SYSTEM_SCENE := "res://scenes/planetsystem/PlanetSystemView.tscn"
const HANDOVER_PV := 0.16

func _hand_over(i: int) -> void:
	_leaving = true
	var pd: PlanetData = _bodies[i]["pd"]
	pd.set_meta("__solar_data", _solar)
	pd.set_meta("__pv_zoom", _pv_zoom_of(i))
	pd.set_meta("__pose", {"yaw": _yaw, "tilt": _tilt})
	SceneTransition.go_soft(PLANET_SYSTEM_SCENE, pd)


## The planet view's zoom that draws body i as big as it is here now.
func _pv_zoom_of(i: int) -> float:
	var pd: PlanetData = _bodies[i]["pd"]
	var diam := 2.0 * clampf(0.42 * clampf(pd.planet_size, 0.2, 2.0), 0.10, 0.48) * _space.size.y
	return _body_px(i) / maxf(diam, 1.0)


## Zooms the whole system out a little more on its own, then the Star Cluster
## view takes over framed on this star (StarClusterView._arrive_from).
func _go_to_cluster() -> void:
	if _leaving:
		return
	_leaving = true
	_cluster_charge = 0
	_focus_t = Vector2.ZERO
	_zoom_t = CLUSTER_EXIT_ZOOM
	await get_tree().create_timer(CLUSTER_EXIT_SEC).timeout
	_solar.set_meta("__sys_zoom", _zoom)
	SceneTransition.go_soft(CLUSTER_SCENE, _solar)


## Came out of a planet view: start framed on that world at its planet-view size
## and ease out to the whole system.
func _arrive_from(pd: PlanetData) -> void:
	var idx := -1
	for i in _bodies.size():
		if (_bodies[i]["pd"] as PlanetData).seed == pd.seed:
			idx = i
	if idx < 0:
		return
	# start on the world we left, at the size the planet view let go of it, and
	# ease out only to its neighbourhood: picked, framed in the middle
	_focus = _body_plane(idx)
	_focus_t = _focus
	_zoom = _zoom_for_planet_view(idx, float(pd.get_meta("__pv_zoom", 0.62)))
	_zoom_v = 0.0
	_zoom_t = minf(_zoom * 0.8, ARRIVE_ZOOM if int(_bodies[idx]["parent"]) < 0 else ARRIVE_ZOOM_MOON)
	if pd.has_meta("__pose"):   # up from the Planet System: its angle, so the moons line up
		var pose: Dictionary = pd.get_meta("__pose")
		pd.remove_meta("__pose")
		_yaw = float(pose["yaw"])
		_yaw_t = _yaw
		_tilt = clampf(float(pose["tilt"]), TILT_MIN, TILT_MAX)
		_tilt_t = _tilt
	_selected = idx
	_build_panel()


func _offer_rocket_target(pd: PlanetData) -> void:
	var kind: String = String(PlanetData.Type.keys()[pd.planet_type]).capitalize()
	var p := ModalPopup.open(self, "Send the Rocket", "rocket", "Send the final rocket to %s?" % pd.planet_name)
	p.add_row("World", kind)
	p.add_row("Flight", "%d min" % int(round(GameState.ROCKET_FLIGHT_SEC / 60.0)))
	p.add_row("On arrival", "Civilization Type 0 complete", InfoRow.Tone.GOOD)
	var ok := p.confirm_button()
	ok.label_text = "SEND ROCKET"
	ok.icon_name = "rocket"
	ok.variant = IconButton.Variant.POSITIVE
	ok.pressed.connect(func() -> void:
		p.close()
		AudioManager.play("click" if GameState.set_rocket_target(pd.seed) else "error"))


# ── Side panel ───────────────────────────────────────────────────────────────

func _build_panel() -> void:
	for b: Dictionary in _bodies:
		_style_marker(b["marker"], b["pd"])
	if GameState.showcase_mode or _solar == null:
		return
	var content := _panel.get_node("Layout/PanelContent")
	for c in content.get_children():
		if c.name in ["SystemHero", "SystemPanel"]:
			c.name = "__freeing"
			c.queue_free()
	var lv := StarSystemProgress.level()
	var hero := HeroHeader.create("Star System - Level %d" % lv, _solar.system_name)
	hero.name = "SystemHero"
	content.add_child(hero)

	var root := VBoxContainer.new()
	root.name = "SystemPanel"
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	content.add_child(root)

	var colonies_row := _info_line("Colonies", "")
	root.add_child(colonies_row)
	var plat_row := _info_line("Platforms", "")
	root.add_child(plat_row)
	root.add_child(_info_line("Star", SolarData.get_star_type_name(_solar.star_type)))

	root.add_child(HSeparator.new())
	if _sel_f >= 0:
		root.add_child(SectionHeader.create("SELECTED", ""))
		root.add_child(_detail_row(_sel_f))
		root.add_child(HSeparator.new())
	var listed: Array[int] = []
	for i in _bodies.size():
		if _listed(_bodies[i]["pd"]):
			listed.append(i)
	root.add_child(SectionHeader.create("WORLDS", str(listed.size())))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for i: int in listed:
		list.add_child(_world_row(i))

	# level up, like a planet's
	root.add_child(HSeparator.new())
	var up := IconButton.create("UPGRADE SYSTEM", "upgrade", IconButton.Variant.POSITIVE)
	up.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ProgressFill.attach(up, UIStyle.color(&"neutral_stroke"),
		func() -> float: return StarSystemProgress.upgrade_progress() if StarSystemProgress.is_upgrading() else -1.0, true)
	up.mouse_entered.connect(func() -> void:
		var cur := StarSystemProgress.level()
		var tip := "Level %d → %d\n\nColonies %d → %d\nPlatforms %d → %d" % [cur, cur + 1,
			StarSystemProgress.colony_capacity(cur), StarSystemProgress.colony_capacity(cur + 1),
			StarSystemProgress.platform_capacity(cur), StarSystemProgress.platform_capacity(cur + 1)]
		var blk := StarSystemProgress.upgrade_block()
		if blk != "" and not StarSystemProgress.is_upgrading():
			tip += "\n\n" + blk
		TooltipManager.show_tip("System level up", tip))
	up.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	up.pressed.connect(func() -> void:
		TooltipManager.hide_tip()
		if StarSystemProgress.start_upgrade():
			AudioManager.play("click")
		else:
			AudioManager.play("error"))
	root.add_child(up)

	var shown_lv := lv
	var refresh := func() -> void:
		if not is_instance_valid(up):
			return
		var cur := StarSystemProgress.level()
		if cur != shown_lv:
			_build_panel()
			return
		_set_info(colonies_row, "%d / %d" % [StarSystemProgress.colonies_used(), StarSystemProgress.colony_capacity()])
		_set_info(plat_row, "0 / %d" % StarSystemProgress.platform_capacity())
		if StarSystemProgress.is_upgrading():
			up.label_text = "LEVELLING UP…"
			up.counter = "%s" % _fmt_time(StarSystemProgress.upgrade_left())
			up.counter_items = PackedStringArray()
			up.disabled = false
		else:
			up.label_text = "UPGRADE SYSTEM  LV %d → %d" % [cur, cur + 1]
			up.counter = ""
			up.counter_items = _cost_items(StarSystemProgress.upgrade_cost())
			up.disabled = StarSystemProgress.upgrade_block() != ""
	refresh.call()
	var tm := Timer.new()
	tm.wait_time = 0.25
	tm.autostart = true
	tm.timeout.connect(refresh)
	root.add_child(tm)


## Worlds the panel lists: the settled ones and those a rover reached (the
## rest are on the map only). Rovers are on another branch: asked by name.
func _listed(pd: PlanetData) -> bool:
	if pd.seed == GameState.home_planet_seed:
		return true
	var pp := GameState.find_planet(pd.seed)
	if pp != null and pp.is_colonized:
		return true
	var rm := get_node_or_null("/root/RoverManager")
	if rm != null and rm.has_method("rovers_on") and not (rm.call("rovers_on", pd.seed) as Array).is_empty():
		return true
	return false


## One world of the system as a list row: click picks it (and follows it on the
## map); clicking the picked one again goes down into it.
func _world_row(i: int) -> Control:
	var b := _bodies[i]
	var pd: PlanetData = b["pd"]
	var is_moon := int(b["parent"]) >= 0
	var pp := GameState.find_planet(pd.seed)
	var status := "Uncharted"
	if pd.seed == GameState.home_planet_seed:
		status = "Home world  //  Level %d" % (pp.level if pp != null else 1)
	elif pp != null and pp.is_colonized:
		status = "Settled  //  Level %d" % pp.level
	var kind: String = String(PlanetData.Type.keys()[pd.planet_type]).capitalize().replace("_", " ")
	var row := ListItem.create(("   " if is_moon else "") + pd.planet_name.to_upper(),
		"moon" if is_moon else "planet", kind.to_upper(), PackedStringArray(), status)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.selected = i == _selected
	row.icon_color = UIStyle.color(&"accent") if pp != null and pp.is_colonized else Color(0.62, 0.70, 0.82)
	row.mouse_entered.connect(func() -> void:
		_hover = i
		TooltipManager.show_tip(pd.planet_name,
			"Click to pick it on the map; click again to go down to it."))
	row.mouse_exited.connect(func() -> void:
		if _hover == i:
			_hover = -1
		TooltipManager.hide_tip())
	row.pressed.connect(func() -> void:
		TooltipManager.hide_tip()
		if GameState.rocket_picking() and GameState.rocket_target_block(pd.seed) == "":
			_offer_rocket_target(pd)
		elif _selected == i:
			_begin_enter(i)
		else:
			_select(i))
	return row


## The picked detail as a list row (like the worlds): its name, kind, a line.
func _detail_row(f: int) -> Control:
	var d := _details[f]
	var neb: bool = d["kind"] == "nebula"
	var row := ListItem.create(String(d["name"]).to_upper(), "explore" if neb else "raw",
		"NEBULA" if neb else "ASTEROIDS", PackedStringArray(),
		"A cloud of gas and dust in open space." if neb else "A cluster of rocks between two orbits.")
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.selected = true
	row.icon_color = Color(d["color"]) if neb else Color(0.80, 0.74, 0.66)
	row.pressed.connect(func() -> void:
		_focus_t = d["center"]
		AudioManager.play("click"))
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


func _set_info(row: Control, text: String) -> void:
	if row == null or not is_instance_valid(row) or row.get_child_count() < 2:
		return
	var v := row.get_child(1)
	if v is MarqueeLabel:
		(v as MarqueeLabel).set_text(text)


static func _cost_items(cost: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if float(cost.get(Economy.CREDITS, 0.0)) > 0.0:
		out.append("credits:" + HUDManager.fmt_credits(float(cost[Economy.CREDITS])))
	for id: String in cost:
		if id != Economy.CREDITS:
			out.append("%s:%s" % [id, Economy.fmt(float(cost[id]))])
	return out


static func _fmt_time(sec: float) -> String:
	var s := int(ceil(sec))
	return "%d:%02d" % [s / 60, s % 60]
