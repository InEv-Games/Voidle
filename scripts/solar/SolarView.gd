extends Control

signal planet_selected(planet_data: PlanetData)
signal back_pressed

@export var solar_data: SolarData       # inject from parent scene / inspector
@export var random_on_start: bool = true
@export var debug_seed: int = 99999

@onready var _space:        Control      = $SpaceContainer
@onready var _system_name:  Label        = $UICanvas/SidePanel/Layout/PanelContent/SystemName
@onready var _star_type:    Label        = $UICanvas/SidePanel/Layout/PanelContent/StarType
@onready var _planet_list:  VBoxContainer = $UICanvas/SidePanel/Layout/PanelContent/PlanetList
@onready var _panel_content: VBoxContainer = $UICanvas/SidePanel/Layout/PanelContent

var _survey_btn: Button = null
var _scan_wrap: VBoxContainer = null

var _current:      SolarData
var _star:         ColorRect
var _star2:        ColorRect   # binary companion, null if not binary
var _star2_angle:  float = 0.0
var _pivot:        Node2D
var _orbit_lines:  OrbitLines
var _orbits:       Array[PlanetOrbitNode] = []
var _belts:        Array[AsteroidBelt]    = []
var _belt_configs: Array[Dictionary]     = []   # {slot, rx, seed} per belt

var _view_angle:      float     = 0.0
var _orbit_tilt:      float     = 0.38
var _solar_view_angle: float    = 0.0
var _solar_orbit_tilt: float    = 0.38
var _max_orbit_px:    float     = 200.0  # updated after build_planets
var _dragging:        bool      = false
var _left_drag_from:  Vector2   = Vector2.ZERO
var _right_dragging:  bool      = false
var _right_drag_from: Vector2   = Vector2.ZERO
var _hovered_planet:  PlanetData = null
var _active_orbit:    PlanetOrbitNode = null   # tracks which orbit node is hovered
var _enter_charge:    int        = 0   # scroll-in on hovered planet
var _back_charge:     int        = 0   # scroll-out to go back to galaxy
var _is_ready:        bool       = false


const ORBIT_Y_RATIO := 0.38   # must match OrbitLines.y_ratio and PlanetOrbitNode

# visual diameter in pixels per star type (corona included)
const STAR_PX: Dictionary = {
	SolarData.StarType.WHITE_DWARF:     100,
	SolarData.StarType.RED_DWARF:       140,
	SolarData.StarType.YELLOW_DWARF:    210,
	SolarData.StarType.ORANGE_SUBGIANT: 260,
	SolarData.StarType.BLUE_GIANT:      340,
}

func _process(_delta: float) -> void:
	_tick_rocket_fx()
	if _dragging or _right_dragging:
		CursorManager.set_state(CursorManager.State.GRAB)
		return
	if _active_orbit != null:
		CursorManager.set_state(CursorManager.State.POINTER)
		return
	CursorManager.set_state(CursorManager.State.NORMAL)

# ── Final rocket (GDD §20.15–§20.18) ─────────────────────────────────────────
# Before launch: a label at home and a dotted line to the target. In flight:
# the rocket on a curved path to the target with its ETA (playtest 23.10: the
# trip to a new world had no animation).
var _rocket_fx: Node2D = null
const ROCKET_COL := Color(1.0, 0.85, 0.5)

func _tick_rocket_fx() -> void:
	var st := GameState.expedition_state("rocket")
	var shown := st == "preparing" or st == "ready" or st == "in_transit"
	if not shown or _pivot == null or not is_instance_valid(_pivot):
		if _rocket_fx != null and is_instance_valid(_rocket_fx):
			_rocket_fx.visible = false
		return
	if _rocket_fx == null or not is_instance_valid(_rocket_fx):
		_rocket_fx = Node2D.new()
		_rocket_fx.z_as_relative = false
		_rocket_fx.z_index = 95
		_rocket_fx.draw.connect(_draw_rocket_fx)
		_pivot.add_child(_rocket_fx)
	_rocket_fx.visible = true
	_rocket_fx.queue_redraw()

func _orbit_node_of(seed_val: int) -> PlanetOrbitNode:
	for n: PlanetOrbitNode in _orbits:
		if is_instance_valid(n) and n.planet_data != null and n.planet_data.seed == seed_val:
			return n
	return null

## Point k (0..1) of the curved path a → b (bulges sideways, like a transfer arc).
static func _rocket_path_at(a: Vector2, b: Vector2, k: float) -> Vector2:
	var mid := (a + b) * 0.5
	var ctrl := mid + (b - a).orthogonal() * 0.25
	return a.lerp(ctrl, k).lerp(ctrl.lerp(b, k), k)

func _draw_rocket_fx() -> void:
	var ex := GameState.expedition("rocket")
	var home := _orbit_node_of(GameState.home_planet_seed)
	if home == null:
		return
	var font := ThemeDB.fallback_font
	var st := String(ex.get("state", ""))
	var target := _orbit_node_of(int(ex.get("target_seed", -1)))
	var a: Vector2 = home.position
	var k := 0.0
	if st == "in_transit":
		k = clampf(1.0 - float(ex.get("flight_left", 0.0)) / GameState.ROCKET_FLIGHT_SEC, 0.0, 1.0)
	if target != null:
		var b: Vector2 = target.position
		const STEPS := 48
		for i in STEPS:
			if i % 2 == 1:
				continue   # dashed
			var t0 := float(i) / STEPS
			var t1 := float(i + 1) / STEPS
			var flown := t1 <= k
			_rocket_fx.draw_line(_rocket_path_at(a, b, t0), _rocket_path_at(a, b, t1),
				Color(ROCKET_COL, 0.85 if flown else 0.30), 2.0 if flown else 1.0, true)
	if st != "in_transit" or target == null:
		var txt := "Final rocket: preparing…" if st == "preparing" else "Final rocket: ready"
		if target == null:
			txt += "  ·  right-click a planet to set its target"
		_rocket_fx.draw_string(font, a + Vector2(16, -22), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ROCKET_COL)
		return
	# the rocket: a small dart along the path with a flickering flame
	var b2: Vector2 = target.position
	var p := _rocket_path_at(a, b2, k)
	var dir := (_rocket_path_at(a, b2, minf(k + 0.01, 1.0)) - p).normalized()
	if dir == Vector2.ZERO:
		dir = (b2 - a).normalized()
	var side := dir.orthogonal()
	var tip := p + dir * 7.0
	_rocket_fx.draw_colored_polygon(PackedVector2Array([tip, p - dir * 4.0 + side * 3.0, p - dir * 4.0 - side * 3.0]),
		Color(0.95, 0.97, 1.0))
	var flame := 4.0 + 2.0 * sin(Time.get_ticks_msec() * 0.03)
	_rocket_fx.draw_line(p - dir * 4.0, p - dir * (4.0 + flame), Color(1.0, 0.6, 0.2, 0.9), 2.0, true)
	var left := int(ceil(float(ex.get("flight_left", 0.0))))
	_rocket_fx.draw_string(font, p + Vector2(10, -10), "→ %s  ·  %d:%02d" % [target.planet_data.planet_name, left / 60, left % 60],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ROCKET_COL)

func _ready() -> void:
	CursorManager.set_state(CursorManager.State.NORMAL)
	
	# back button removed — right-click navigates back
	get_tree().root.size_changed.connect(_on_resize)
	planet_selected.connect(_on_planet_selected)
	CommandRegistry.add_provider("planet", self, _planet_commands)
	CommandRegistry.add_provider("system", self, _system_commands)
	
	_pivot = Node2D.new()
	_space.add_child(_pivot)
	GameState.asteroid_discovered.connect(_on_asteroid_discovered)

	# wait one frame so Control sizes are computed
	await get_tree().process_frame
	# the left panel places itself (LeftPanel); the system fills the rest
	($UICanvas/SidePanel as Control).visible = not GameState.showcase_mode
	_space.anchor_left = LeftPanel.edge_frac()
	if GameState.showcase_mode:
		_space.anchor_left = 0.0   # no side panel: the system fills the screen
		await get_tree().process_frame

	var pending = SceneTransition.pending_data
	SceneTransition.pending_data = null
	if pending is PlanetData:   # coming back from a body: show its star system
		var pd := pending as PlanetData
		load_system(pd.get_meta("__solar_data") as SolarData if pd.has_meta("__solar_data") \
			else GameState.get_home_solar())
	elif pending is SolarData:
		load_system(pending as SolarData)
	elif solar_data != null:
		load_system(solar_data)
	elif random_on_start:
		load_system(SolarData.from_seed(randi() % 99999))
	else:
		load_system(SolarData.from_seed(debug_seed))
	NavigationManager.end_apply()
	if _current != null:
		NavigationManager.visit(NavigationManager.solar_entry(_current))

	_is_ready = true

func _save_current_angles_to_game_state() -> void:
	if not _is_ready:
		return
	if _current != null:
		GameState.set_meta("solar_view_angle_%d" % _current.seed, _view_angle)
		GameState.set_meta("solar_orbit_tilt_%d" % _current.seed, _orbit_tilt)

func _load_current_angles_from_game_state() -> void:
	if _current != null:
		_view_angle = GameState.get_meta("solar_view_angle_%d" % _current.seed, 0.0)
		_orbit_tilt = GameState.get_meta("solar_orbit_tilt_%d" % _current.seed, 0.38)

func _go_to_galaxy() -> void:
	if not GameState.can_view_galaxy():
		return
	_save_current_angles_to_game_state()
	var gd: GalaxyData = null
	if _current != null and _current.has_meta("__galaxy_data"):
		gd = _current.get_meta("__galaxy_data") as GalaxyData
	if gd == null:
		gd = GameState.home_galaxy
	SceneTransition.go("res://scenes/galaxy/GalaxyView.tscn", gd)

func _can_access(pd: PlanetData) -> bool:
	if pd.planet_type == PlanetData.Type.MOON:
		if not GameState.can_view_moon():
			return false
		if not GameState.can_view_solar():
			var home_pd: PlanetData = null
			if _current != null:
				for p in _current.planets:
					if p.seed == GameState.home_planet_seed:
						home_pd = p
						break
			if home_pd != null:
				var is_home_moon := false
				for m in home_pd.moons:
					if m.seed == pd.seed:
						is_home_moon = true
						break
				if not is_home_moon:
					return false
	else:
		if not GameState.can_view_solar() and pd.seed != GameState.home_planet_seed:
			return false
	return true

func _on_planet_selected(pd: PlanetData) -> void:
	if not _can_access(pd):
		print("[SolarView] Access denied to planet/moon: ", pd.planet_name)
		_show_access_denied_text()
		return
		
	# straight to the body's planet view — its moons are reached from there
	# (zoom out: they show in the corner)
	_save_current_angles_to_game_state()
	pd.set_meta("__solar_data", _current)
	SceneTransition.go("res://scenes/planetary/PlanetaryView.tscn", pd)

# ── Right-click actions (CommandRegistry + ContextMenu) ──────────────────────

func _open_context_menu(global_pos: Vector2) -> void:
	if GameState.showcase_mode or _current == null:
		return
	var pd: PlanetData = _hovered_planet
	var cmds: Array[GameCommand]
	if pd != null:
		cmds = CommandRegistry.commands_for("planet", pd)
		var kind: String = String(PlanetData.Type.keys()[pd.planet_type]).capitalize()
		ContextMenu.open(self, pd.planet_name, kind, cmds, global_pos)
	else:
		cmds = CommandRegistry.commands_for("system", _current)
		ContextMenu.open(self, _current.system_name, "Star system", cmds, global_pos)

func _planet_commands(pd: PlanetData) -> Array:
	var out: Array = [GameCommand.make("view_planet", "View planet", planet_selected.emit.bind(pd),
		_planet_access_block.bind(pd), {"icon": "◉", "color": Color(0.60, 0.75, 1.0)})]
	# the final rocket's destination (GDD §20.15–§20.17): pick or change it until launch
	var rs := GameState.expedition_state("rocket")
	if (rs == "preparing" or rs == "ready") and pd.seed != GameState.home_planet_seed:
		var current := int(GameState.expedition("rocket").get("target_seed", -1)) == pd.seed
		out.append(GameCommand.make("rocket_target", "Final rocket target" + ("  ✓" if current else ""),
			func() -> void: GameState.set_rocket_target(pd.seed),
			func() -> String: return "Already the target" if current else GameState.rocket_target_block(pd.seed),
			{"icon": "▲", "color": Color(1.0, 0.85, 0.5),
			 "tooltip": "The rocket leaves the Moon for this planet once it is ready. Arriving completes Civilization 0."}))
	return out

func _system_commands(_sd: SolarData) -> Array:
	return [GameCommand.make("galaxy_view", "Galaxy view", _go_to_galaxy, _galaxy_access_block,
		{"icon": "✦", "color": Color(0.60, 0.75, 1.0)})]

func _planet_access_block(pd: PlanetData) -> String:
	return "" if _can_access(pd) else "Not reachable yet"

func _galaxy_access_block() -> String:
	return "" if GameState.can_view_galaxy() else "Galaxy navigation is locked"

func _show_access_denied_text(msg: String = "ACCESS DENIED") -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", UIStyle.color(&"bad"))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 4)
	var orbitron := load("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf") as Font
	if orbitron:
		lbl.add_theme_font_override("font", orbitron)
		lbl.add_theme_font_size_override("font_size", 14)
	lbl.global_position = get_viewport().get_mouse_position() + Vector2(-40, -20)
	lbl.z_index = 1000
	add_child(lbl)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "position", lbl.global_position + Vector2(0, -40), 1.2)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.2)
	tw.chain().tween_callback(lbl.queue_free)

func load_system(data: SolarData) -> void:
	_save_current_angles_to_game_state()
	_current = data

	_load_current_angles_from_game_state()
	get_tree().root.set_meta("__active_solar", data)
	# auto-unlock if any planet already has a POI (e.g. returned from PlanetaryView)
	_check_poi_unlock(data)
	_clear()
	_build_star(data)
	_build_planets(data)
	_update_panel()
	_apply_current_angles()
	queue_redraw()

func _apply_current_angles() -> void:
	for node in _orbits:
		node.set_view_angle(_view_angle)
		node.set_tilt(_orbit_tilt)
	for belt in _belts:
		belt.set_view_angle(_view_angle)
		belt.set_tilt(_orbit_tilt)
	if _orbit_lines:
		_orbit_lines.set_tilt(_orbit_tilt)

func _check_poi_unlock(data: SolarData) -> void:
	if data.is_home or GameState.showcase_mode:   # showcase never changes progress
		return
	var gd: GalaxyData = data.get_meta("__galaxy_data") as GalaxyData if data.has_meta("__galaxy_data") else null
	var idx: int       = data.get_meta("__galaxy_star_idx") as int     if data.has_meta("__galaxy_star_idx") else -1
	if gd == null or idx < 0 or gd.is_unlocked(idx):
		return
	for pd in data.planets:
		if pd.custom_pois.size() > 0:
			gd.unlock(idx)
			return

func _clear() -> void:
	for node in _orbits:
		node.queue_free()
	_orbits.clear()
	if _star:
		_star.queue_free()
		_star = null
	if _star2:
		_star2.queue_free()
		_star2 = null
	if _pivot:
		_pivot.queue_free()
		_pivot = null
	_orbit_lines = null
	_belts.clear()
	_belt_configs.clear()
	for child in _planet_list.get_children():
		child.queue_free()

func _build_star(data: SolarData) -> void:
	var colors           := SolarData.get_star_colors(data.star_type)
	# binary pairs share the same footprint as a single star — scale both down
	var binary_scale: float = 0.62 if data.is_binary else 1.0
	var px_size: float    = float(STAR_PX.get(data.star_type, 210)) * binary_scale

	_star               = ColorRect.new()
	_star.size          = Vector2(px_size, px_size)
	_star.position      = _star_center() - _star.size * 0.5
	_star.z_as_relative = false
	_star.z_index       = 50   # between back-planets(20) and front-planets(80)

	var mat    := ShaderMaterial.new()
	mat.shader  = load("res://shaders/star.gdshader")
	# star_radius = 0.35 means star fills 70% of ColorRect radius; corona fills the rest
	mat.set_shader_parameter("star_radius",   0.35)
	mat.set_shader_parameter("corona_size",   0.14)
	mat.set_shader_parameter("pixel_count",   clamp(px_size * 0.55, 64.0, 256.0))
	mat.set_shader_parameter("aspect_ratio",  1.0)
	mat.set_shader_parameter("flicker_speed", 0.35)
	mat.set_shader_parameter("seed",          data.seed % 99999)
	mat.set_shader_parameter("color_core",    colors["core"])
	mat.set_shader_parameter("color_surface", colors["surface"])
	mat.set_shader_parameter("color_corona",  colors["corona"])
	_star.material = mat
	_space.add_child(_star)

	# binary companion star
	if data.is_binary:
		var s2_px: float = float(STAR_PX.get(data.secondary_type, 100)) * 0.65
		_star2               = ColorRect.new()
		_star2.size          = Vector2(s2_px, s2_px)
		_star2.z_as_relative = false
		_star2.z_index       = 48
		var mat2    := ShaderMaterial.new()
		mat2.shader  = load("res://shaders/star.gdshader")
		var c2       := SolarData.get_star_colors(data.secondary_type)
		mat2.set_shader_parameter("star_radius",   0.35)
		mat2.set_shader_parameter("corona_size",   0.14)
		mat2.set_shader_parameter("pixel_count",   clamp(s2_px * 0.55, 48.0, 180.0))
		mat2.set_shader_parameter("aspect_ratio",  1.0)
		mat2.set_shader_parameter("flicker_speed", 0.28)
		mat2.set_shader_parameter("seed",          (data.seed ^ 0xCAFE) % 99999)
		mat2.set_shader_parameter("color_core",    c2["core"])
		mat2.set_shader_parameter("color_surface", c2["surface"])
		mat2.set_shader_parameter("color_corona",  c2["corona"])
		_star2.material = mat2
		_space.add_child(_star2)
		# position: side by side with primary at center, slight Y offset for depth
		var center := _star_center()
		var gap    := (px_size * 0.5 + s2_px * 0.5) * 0.30   # heavily overlapping
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = data.seed ^ 0xB1A2
		var side: float = 1.0 if rng2.randf() > 0.5 else -1.0
		var s2_offset := Vector2(side * gap, px_size * 0.12)
		_star2.position = center + s2_offset - _star2.size * 0.5
		# push primary slightly the other way so they share a center of mass visually
		_star.position = center + Vector2(-side * gap * (s2_px / px_size) * 0.5, 0.0) - _star.size * 0.5
		# whichever star is lower on screen (higher Y) is closer to camera — give it higher z
		if s2_offset.y > 0.0:
			_star2.z_index = 52   # companion is lower → in front
			_star.z_index  = 50
		else:
			_star2.z_index = 48   # companion is higher → behind
			_star.z_index  = 50

func _build_planets(data: SolarData) -> void:
	_pivot          = Node2D.new()
	_pivot.position = _star_center()
	_pivot.z_index  = 1
	_space.add_child(_pivot)

	var star_px:   float = float(STAR_PX.get(data.star_type, 210))
	var min_orbit: float = star_px * 0.5 + 40.0

	# max orbit: fits inside SpaceContainer; clamp tightly so system doesn't sprawl
	var margin:    float = 60.0
	var max_by_x:  float = _space.size.x * 0.44 - margin
	var max_by_y:  float = (_space.size.y * 0.42) / ORBIT_Y_RATIO
	var max_orbit: float = min(max_by_x, max_by_y)
	max_orbit = clamp(max_orbit, min_orbit + 60.0, 420.0)

	var count: int = data.planets.size()

	# Build per-gap step sizes: belt gaps are 2.2x wider than planet gaps.
	# Total weighted slots = (count-1) gaps where belt gaps count as 2.2
	const BELT_FACTOR := 2.2
	var total_weight: float = 0.0
	for gap in count - 1:
		total_weight += BELT_FACTOR if gap in data.asteroid_belt_slots else 1.0
	total_weight = max(total_weight, 1.0)
	var base_step: float = clamp((max_orbit - min_orbit) / total_weight, 55.0, 100.0)

	# Pre-compute each planet's orbit radius
	var orbit_radii_arr: Array[float] = []
	var cur: float = min_orbit
	orbit_radii_arr.append(cur)
	for gap in count - 1:
		var w: float = BELT_FACTOR if gap in data.asteroid_belt_slots else 1.0
		cur += base_step * w
		orbit_radii_arr.append(cur)

	# orbit lines: absolute z=10 so they're behind star(50) and all planets
	_orbit_lines               = OrbitLines.new()
	_orbit_lines.z_as_relative = false
	_orbit_lines.z_index       = 10
	_pivot.add_child(_orbit_lines)
	_orbit_lines.refresh(orbit_radii_arr)

	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed ^ 0xABCD

	for i in count:
		var radius_x:    float = orbit_radii_arr[i]
		var start_angle: float = rng.randf_range(0.0, TAU)
		var node := PlanetOrbitNode.new()
		node.clicked.connect(func(pd: PlanetData) -> void: planet_selected.emit(pd))
		node.hover_start.connect(func(pd: PlanetData) -> void:
			# force-close any other hovered node before activating this one
			if _active_orbit != null and _active_orbit != node and _active_orbit._hover:
				_active_orbit._on_hover_end()
			_active_orbit   = node
			_hovered_planet = pd
			_enter_charge   = 0)
		node.hover_end.connect(func() -> void:
			if _active_orbit == node:
				_active_orbit   = null
				_hovered_planet = null
				_enter_charge   = 0)
		_pivot.add_child(node)
		node.setup(data.planets[i], radius_x, start_angle)
		if data.planets[i].has_meta("__is_home"):
			node.mark_as_home()
		if not data.planets[i].custom_pois.is_empty():
			var lv := GameState.get_planet(data.planets[i].seed).level
			node.set_settlement_level(lv)
		_orbits.append(node)

	# asteroid belts — always visible; asteroids only appear after discovery
	for slot in data.asteroid_belt_slots:
		if slot < 0 or slot >= count - 1:
			continue
		var inner:   float = orbit_radii_arr[slot]
		var outer:   float = orbit_radii_arr[slot + 1]
		var belt_rx: float = (inner + outer) * 0.5
		var belt_seed: int = data.seed ^ (slot * 0x1337)
		var belt := AsteroidBelt.new()
		_pivot.add_child(belt)
		var ast_count: int = GameState.asteroid_scan_counts.get(slot, 0)
		belt.setup(belt_rx, belt_seed, ast_count)
		_belts.append(belt)
		_belt_configs.append({"slot": slot, "rx": belt_rx, "seed": belt_seed})

	_max_orbit_px = orbit_radii_arr.back() if orbit_radii_arr.size() > 0 else 200.0

func _on_asteroid_discovered(slot: int, count: int) -> void:
	for i in _belt_configs.size():
		if _belt_configs[i]["slot"] == slot:
			_belts[i].queue_free()
			var cfg := _belt_configs[i]
			var belt := AsteroidBelt.new()
			_pivot.add_child(belt)
			belt.setup(cfg["rx"], cfg["seed"], count)
			belt.set_view_angle(_view_angle)
			belt.set_tilt(ORBIT_Y_RATIO)
			_belts[i] = belt
			return

func _update_panel() -> void:
	_system_name.text = _current.system_name
	_star_type.text   = SolarData.get_star_type_name(_current.star_type)
	for child in _planet_list.get_children():
		child.queue_free()
	for i in _current.planets.size():
		var pd: PlanetData = _current.planets[i]
		var btn := IconButton.create("%d. %s" % [i + 1, pd.planet_name.to_upper()], "moon" if pd.planet_type == PlanetData.Type.MOON else "planet")
		btn.disabled = not _can_access(pd)
		btn.pressed.connect(func() -> void: planet_selected.emit(pd))
		_planet_list.add_child(btn)

	# remove old survey / scan buttons
	if _survey_btn and is_instance_valid(_survey_btn):
		_survey_btn.queue_free()
		_survey_btn = null
	if _scan_wrap and is_instance_valid(_scan_wrap):
		_scan_wrap.queue_free()
		_scan_wrap = null

	var is_surveyed := _current.is_home
	var gd: GalaxyData = null
	var star_idx: int = -1

	if not is_surveyed:
		gd = _current.get_meta("__galaxy_data") as GalaxyData if _current.has_meta("__galaxy_data") else null
		star_idx = _current.get_meta("__galaxy_star_idx") as int if _current.has_meta("__galaxy_star_idx") else -1
		if gd != null and star_idx >= 0 and gd.is_unlocked(star_idx):
			is_surveyed = true

	if is_surveyed:
		# Scan Asteroid button — only in SOLAR mode, only if skill unlocked, only if belts exist
		if _current != null \
				and not _current.asteroid_belt_slots.is_empty() \
				and SkillTree.call("is_unlocked", "unlock_asteroids"):
			_build_scan_asteroid_section()
		return

	if gd == null or star_idx < 0:
		return

	const SURVEY_CREDITS: float = 200_000.0
	const SURVEY_SCIENCE: float = 50_000.0

	var orbitron := load("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf") as Font

	# Container for the whole survey section (separator + cost + button)
	var survey_wrap := VBoxContainer.new()
	survey_wrap.add_theme_constant_override("separation", 6)
	_panel_content.add_child(survey_wrap)

	var sep := HSeparator.new()
	survey_wrap.add_child(sep)

	# Survey button styled like Level Up (always green)
	_survey_btn = IconButton.create_text("SURVEY SYSTEM", IconButton.Variant.POSITIVE)


	_survey_btn.mouse_entered.connect(func() -> void:
		AudioManager.play("hover")
		CursorManager.set_state(CursorManager.State.POINTER))
	_survey_btn.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL))
	_survey_btn.pressed.connect(func() -> void: _show_survey_popup(gd, star_idx, SURVEY_CREDITS, SURVEY_SCIENCE))

	survey_wrap.add_child(_survey_btn)

const SCAN_SCIENCE: float = 5_000.0

func _build_scan_asteroid_section() -> void:
	var orbitron := load("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf") as Font

	_scan_wrap = VBoxContainer.new()
	_scan_wrap.add_theme_constant_override("separation", 6)
	_panel_content.add_child(_scan_wrap)

	var sep := HSeparator.new()
	_scan_wrap.add_child(sep)

	# Show scan status per belt
	var st_lbl := Label.new()
	var belts: Array = _current.asteroid_belt_slots
	var scanned_total: int = 0
	for slot: int in belts:
		scanned_total += GameState.asteroid_scan_counts.get(slot, 0)
	var max_total: int = belts.size() * 3
	st_lbl.text = "Asteroids: %d / %d scanned" % [scanned_total, max_total]
	st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if orbitron: st_lbl.add_theme_font_override("font", orbitron)
	st_lbl.add_theme_font_size_override("font_size", 8)
	st_lbl.add_theme_color_override("font_color", UIStyle.color(&"text"))
	_scan_wrap.add_child(st_lbl)

	var scan_btn := IconButton.create_text("SCAN ASTEROID BELT", IconButton.Variant.POSITIVE)

	# Find next unsaturated belt
	var next_slot: int = -1
	for slot: int in belts:
		if GameState.asteroid_scan_counts.get(slot, 0) < 3:
			next_slot = slot
			break

	var all_scanned := next_slot < 0
	var can_afford  := GameState.science_points >= SCAN_SCIENCE


	if all_scanned:
		scan_btn.disabled = true
		scan_btn.label_text = "ALL BELTS SCANNED"
	elif not can_afford:
		scan_btn.disabled = true

	var cost_lbl := Label.new()
	cost_lbl.text = "○ %s Science" % HUDManager.fmt_science(SCAN_SCIENCE)
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if orbitron: cost_lbl.add_theme_font_override("font", orbitron)
	cost_lbl.add_theme_font_size_override("font_size", 8)
	cost_lbl.add_theme_color_override("font_color",
		UIStyle.color(&"text") if can_afford else UIStyle.color(&"bad"))
	_scan_wrap.add_child(cost_lbl)
	_scan_wrap.add_child(scan_btn)

	scan_btn.mouse_entered.connect(func() -> void: AudioManager.play("hover"))
	scan_btn.pressed.connect(func() -> void:
		if not GameState.spend_science(SCAN_SCIENCE):
			AudioManager.play("error")
			return
		AudioManager.play("survey", -2.0)
		GameState.discover_asteroid(next_slot)
		_update_panel())

func _show_survey_popup(gd: GalaxyData, star_idx: int, cost_cr: float, cost_sci: float) -> void:
	var p := ModalPopup.open(self, "Survey System", "explore", "Reveal all planets and moons in this system.", 400)
	p.add_row("Credits", "%s / %s" % [HUDManager.fmt_credits(GameState.credits), HUDManager.fmt_credits(cost_cr)],
		InfoRow.Tone.GOOD if GameState.credits >= cost_cr else InfoRow.Tone.BAD)
	p.add_row("Science", "%.0f / %.0f" % [GameState.science_points, cost_sci],
		InfoRow.Tone.GOOD if GameState.science_points >= cost_sci else InfoRow.Tone.BAD)
	var ok := p.confirm_button()
	ok.label_text = "SURVEY"
	ok.icon_name = "explore"
	ok.disabled = not (GameState.credits >= cost_cr and GameState.science_points >= cost_sci)
	ok.pressed.connect(func() -> void:
		AudioManager.play("survey")
		p.close()
		_survey_system(gd, star_idx, cost_cr, cost_sci))

func _survey_system(gd: GalaxyData, star_idx: int, cost_cr: float, cost_sci: float) -> void:
	if GameState.credits < cost_cr or GameState.science_points < cost_sci:
		return
	GameState.credits -= cost_cr
	GameState.credits_changed.emit(GameState.credits)
	if not GameState.spend_science(cost_sci):
		GameState.credits += cost_cr
		GameState.credits_changed.emit(GameState.credits)
		return
	gd.unlock(star_idx)
	AchievementManager.notify_trigger(AchievementDef.Trigger.FIRST_SURVEY)
	_update_panel()


func _input(event: InputEvent) -> void:
	if SkillTreeView.is_open or TradePanel.is_open:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_right_dragging  = true
				_right_drag_from = mb.position
			else:
				_right_dragging = false   # back/up lives in the navigation HUD
				if mb.position.distance_to(_right_drag_from) < 5.0:
					_open_context_menu(mb.global_position)
			return
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and _space.get_global_rect().has_point(mb.global_position):
				_dragging = true
				_left_drag_from = mb.position
			elif not mb.pressed:
				_dragging = false
				if mb.position.distance_to(_left_drag_from) < 5.0:
					var target_pd: PlanetData = _hovered_planet
					if target_pd != null:
						planet_selected.emit(target_pd)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			var target_pd: PlanetData = _hovered_planet
			if target_pd != null:
				_enter_charge += 1
				_back_charge   = 0
				if _enter_charge >= 2:
					_enter_charge = 0
					planet_selected.emit(target_pd)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_enter_charge  = 0
			_back_charge  += 1
			if _back_charge >= 3:
				_back_charge = 0
				if not GameState.can_view_galaxy():
					_show_access_denied_text("Galaxy Nav  LOCKED")
				else:
					_go_to_galaxy()
	elif event is InputEventMagnifyGesture:
		if event.factor > 1.0:
			var target_pd: PlanetData = _hovered_planet
			if target_pd != null:
				_enter_charge += 1
				_back_charge   = 0
				if _enter_charge >= 2:
					_enter_charge = 0
					planet_selected.emit(target_pd)
		elif event.factor < 1.0:
			_enter_charge  = 0
			_back_charge  += 1
			if _back_charge >= 3:
				_back_charge = 0
				if not GameState.can_view_galaxy():
					_show_access_denied_text("Galaxy Nav  LOCKED")
				else:
					_go_to_galaxy()
	elif event is InputEventPanGesture:
		# 2-finger trackpad swipe → rotate (horizontal) / tilt (vertical)
		_view_angle += event.delta.x * 0.012
		_orbit_tilt  = clamp(_orbit_tilt - event.delta.y * 0.006, 0.28, 0.50)
		for node in _orbits:
			node.set_view_angle(_view_angle)
			node.set_tilt(_orbit_tilt)
		for belt in _belts:
			belt.set_view_angle(_view_angle)
			belt.set_tilt(_orbit_tilt)
		if _orbit_lines:
			_orbit_lines.set_tilt(_orbit_tilt)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and (_dragging or _right_dragging):
		var mm  := event as InputEventMouseMotion
		if mm.relative.length() < 1.5:
			return
		if _right_dragging:
			# vertical drag → subtle orbit tilt, clamped to a narrow range
			_orbit_tilt = clamp(_orbit_tilt + mm.relative.y * 0.0008, 0.28, 0.50)
			for node in _orbits:
				node.set_tilt(_orbit_tilt)
			for belt in _belts:
				belt.set_tilt(_orbit_tilt)
			if _orbit_lines:
				_orbit_lines.set_tilt(_orbit_tilt)
		else:
			_view_angle -= mm.relative.x * 0.0042
		for node in _orbits:
			node.set_view_angle(_view_angle)
		for belt in _belts:
			belt.set_view_angle(_view_angle)
		get_viewport().set_input_as_handled()


func _star_center() -> Vector2:
	return _space.size * Vector2(0.5, 0.52)

func _on_resize() -> void:
	await get_tree().process_frame
	if _current:
		_build_star(_current)
	if _pivot:
		_pivot.position = _star_center()
	if _star:
		_star.position = _star_center() - _star.size * 0.5
	queue_redraw()
