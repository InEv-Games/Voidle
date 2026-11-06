@tool
extends ColorRect

signal planet_clicked(screen_pos: Vector2)

## How fast a flung globe slows down (1/s; frame-rate independent).
@export var momentum_friction: float = 4.5
## How fast the globe catches up with the drag (1/s). Higher = tighter, lower = silkier.
@export var drag_smoothing: float = 30.0

## Editor preview controls — no effect at runtime.
@export_group("Editor Preview")
@export var preview_planet_type: PlanetData.Type = PlanetData.Type.TERRAN:
	set(v):
		preview_planet_type = v
		if Engine.is_editor_hint():
			if is_inside_tree(): _apply_preview()
			else: call_deferred("_apply_preview")
@export var preview_seed: int = 42:
	set(v):
		preview_seed = v
		if Engine.is_editor_hint():
			if is_inside_tree(): _apply_preview()
			else: call_deferred("_apply_preview")
@export_range(0.1, 2.0, 0.05) var preview_planet_size: float = 1.0:
	set(v):
		preview_planet_size = v
		if Engine.is_editor_hint():
			if is_inside_tree(): _apply_preview()
			else: call_deferred("_apply_preview")
@export_group("")

var _dragging := false
var _drag_velocity := 0.0   # rad/s, kept for the fling after release
var _last_drag_time := 0
var _last_drag_usec := 0
## Drag / momentum not yet shown: eased in by tick_motion() so the globe glides
## instead of stepping with each mouse event.
var _pending_rot := 0.0
var _pending_tilt := 0.0
var _motion_frame := -1
var _drag_total_px := 0.0
var _rotation_offset := 0.0
## Camera tilt around the screen X axis (radians). + brings the north pole into view.
var tilt := 0.0
var _tilt_velocity := 0.0
const MAX_TILT := 1.4   # ~80°
## Set while something (e.g. a rocket launch) relies on the untilted projection.
var tilt_locked := false
var _last_mouse_x := 0.0
var _last_mouse_y := 0.0
var _planet_radius_px := 0.0
## Global light angle (shared time-of-day clock, advances in PlanetaryView._process)
var light_angle: float = 0.0
## Per-planet offset so each world has its own "local noon" position
var local_time_offset: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_preview")
	# At runtime, material is assigned externally by PlanetaryView._setup_material()

func _apply_preview() -> void:
	if not Engine.is_editor_hint():
		return
	var data := PlanetData.new()
	data.planet_type = preview_planet_type
	data.seed        = preview_seed
	data.planet_size = preview_planet_size
	# Fill in defaults that from_seed() would normally set
	data.has_atmosphere    = true
	data.atmosphere_density = 1.0
	data.has_clouds        = true
	data.cloud_speed       = 0.04
	data.cloud_coverage    = 0.55
	data.sea_level         = 0.0
	data.continent_scale   = 1.0
	data.terrain_roughness = 1.0
	data.specular_strength = 0.4
	data.city_lights       = 0.0
	data.irregularity      = 0.4

	var shader := load(PlanetData.get_shader_path(data.planet_type)) as Shader
	var mat    := ShaderMaterial.new()
	mat.shader  = shader

	var sz: float          = clamp(data.planet_size, 0.2, 2.0)
	var base_radius: float = clamp(0.42 * sz, 0.10, 0.48)
	var pcount: float      = 140.0
	if sz > 1.2:
		pcount = round(clamp(140.0 * (sz / 1.2), 140.0, 280.0))

	mat.set_shader_parameter("rotation_offset",   0.0)
	mat.set_shader_parameter("planet_radius",     base_radius)
	mat.set_shader_parameter("pixel_count",       pcount)
	mat.set_shader_parameter("seed",              data.seed)
	mat.set_shader_parameter("terrain_roughness", data.terrain_roughness)

	var stype := PlanetData.get_shader_type(data.planet_type)
	var colors := PlanetData.get_colors(data.planet_type)
	match stype:
		PlanetData.ShaderType.ROCKY:
			mat.set_shader_parameter("cloud_speed",        data.cloud_speed)
			mat.set_shader_parameter("cloud_coverage",     data.cloud_coverage)
			mat.set_shader_parameter("has_clouds",         1.0 if data.has_clouds else 0.0)
			mat.set_shader_parameter("atmosphere_density", data.atmosphere_density)
			mat.set_shader_parameter("sea_level",          data.sea_level)
			mat.set_shader_parameter("continent_scale",    data.continent_scale)
			mat.set_shader_parameter("specular_strength",  data.specular_strength)
			mat.set_shader_parameter("city_lights",        data.city_lights)
			for key in colors:
				mat.set_shader_parameter(key, colors[key])
		PlanetData.ShaderType.GAS:
			mat.set_shader_parameter("cloud_speed",        data.cloud_speed)
			mat.set_shader_parameter("atmosphere_density", data.atmosphere_density)
			mat.set_shader_parameter("color_band_a",     colors.get("color_sand",        Vector3(0.72, 0.55, 0.35)))
			mat.set_shader_parameter("color_band_b",     colors.get("color_forest",      Vector3(0.50, 0.32, 0.18)))
			mat.set_shader_parameter("color_storm",      colors.get("color_snow",        Vector3(0.88, 0.82, 0.72)))
			mat.set_shader_parameter("color_atmosphere", colors.get("color_atmosphere",  Vector3(0.72, 0.55, 0.35)))
		PlanetData.ShaderType.MOON:
			mat.set_shader_parameter("color_highland", colors.get("color_mountain",   Vector3(0.62, 0.60, 0.56)))
			mat.set_shader_parameter("color_mare",     colors.get("color_deep_ocean", Vector3(0.22, 0.21, 0.20)))
			mat.set_shader_parameter("color_rim",      colors.get("color_snow",       Vector3(0.78, 0.76, 0.72)))
			mat.set_shader_parameter("color_floor",    colors.get("color_ocean",      Vector3(0.16, 0.15, 0.14)))
		PlanetData.ShaderType.ASTEROID:
			mat.set_shader_parameter("irregularity", data.irregularity)
			mat.set_shader_parameter("elongation",   1.0 + data.irregularity * 0.8)

	material = mat
	# Fake a midday light direction so the planet is visible
	var ld := Vector3(0.6, -0.4, 0.7).normalized()
	mat.set_shader_parameter("light_direction", ld)

func _update_radius() -> void:
	if material == null:
		return
	var r: float = material.get_shader_parameter("planet_radius")
	# radius in screen pixels = height * planet_radius (aspect-corrected circle)
	_planet_radius_px = size.y * r

func set_tilt(val: float) -> void:
	tilt = clampf(val, -MAX_TILT, MAX_TILT)
	if material:
		(material as ShaderMaterial).set_shader_parameter("tilt", tilt)
		_update_light_direction()

## Surface point → view-space unit vector (x right, y down, z toward the camera).
## Inverse of the shader's view → world transform (tilt, then spin).
func lonlat_to_view(lon: float, lat: float) -> Vector3:
	var l := lon - _rotation_offset
	var x := sin(l) * cos(lat)
	var y := -sin(lat)
	var z := cos(l) * cos(lat)
	var c := cos(tilt)
	var s := sin(tilt)
	return Vector3(x, y * c + z * s, -y * s + z * c)

## View-space unit vector → Vector2(lon, lat) in radians.
func view_to_lonlat(v: Vector3) -> Vector2:
	var c := cos(tilt)
	var s := sin(tilt)
	var y := v.y * c - v.z * s
	var z := v.y * s + v.z * c
	return Vector2(fposmod(_rotation_offset + atan2(v.x, z), TAU), asin(clampf(-y, -1.0, 1.0)))

func get_rotation_offset() -> float:
	return _rotation_offset

func set_rotation_offset(val: float) -> void:
	_rotation_offset = fposmod(val, TAU)
	if material:
		(material as ShaderMaterial).set_shader_parameter("rotation_offset", _rotation_offset)
		# Note: light_direction is recomputed every frame in _process;
		# calling _update_light_direction here too ensures tweens stay in sync.
		_update_light_direction()

func _update_light_direction() -> void:
	if material == null:
		return
	# eff = global_time + planet_local_offset + surface_rotation
	# Adding rotation_offset means the light rotates WITH the terrain:
	# a landmass that's in night stays in night as you spin the planet,
	# giving the feel of a camera orbiting a stationary world.
	var eff: float = light_angle + local_time_offset + _rotation_offset
	var lx := cos(eff) * 0.85
	var lz := sin(eff) * 0.55
	var ld := Vector3(lx, -0.45, lz).normalized()
	# Tilt the light with the camera so the terminator stays put on the terrain.
	var c := cos(tilt)
	var s := sin(tilt)
	ld = Vector3(ld.x, ld.y * c + ld.z * s, -ld.y * s + ld.z * c)
	(material as ShaderMaterial).set_shader_parameter("light_direction", ld)

func _unhandled_input(event: InputEvent) -> void:
	# Absolutely block and ignore any click, drag, or hover events if SkillTreeView is active
	var root := get_tree().root
	var is_tree_open := false
	for child in root.get_children():
		var script = child.get_script()
		if script != null and script.resource_path.ends_with("SkillTreeView.gd"):
			is_tree_open = true
			break
			
	if is_tree_open:
		_dragging = false
		_drag_velocity = 0.0
		return
			
	_update_radius()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var local := get_local_mouse_position()
		var center := size * 0.5
		var dist := local.distance_to(center)
		if event.pressed and dist < _planet_radius_px:
			begin_drag(event.position)
		elif not event.pressed:
			# Only treat as a tap if total drag distance was small
			if _dragging and _drag_total_px < 8.0:
				planet_clicked.emit(event.position)
			end_drag()

	if event is InputEventMouseMotion and _dragging:
		root = get_tree().root
		is_tree_open = false
		for child in root.get_children():
			var script = child.get_script()
			if script != null and script.resource_path.ends_with("SkillTreeView.gd"):
				is_tree_open = true
				break
				
		if is_tree_open:
			_dragging = false
			_drag_velocity = 0.0
			return
				
		drag_to(event.position)

## Globe dragging, also driven from outside (PlanetaryView's right-drag):
## begin at a point, follow the mouse, end with momentum.
func begin_drag(pos: Vector2) -> void:
	_dragging = true
	_drag_velocity = 0.0
	_tilt_velocity = 0.0
	_drag_total_px = 0.0
	_last_mouse_x = pos.x
	_last_mouse_y = pos.y
	_last_drag_usec = Time.get_ticks_usec()

func end_drag() -> void:
	if Time.get_ticks_msec() - _last_drag_time > 100:
		_drag_velocity = 0.0
		_tilt_velocity = 0.0
	_dragging = false
	_drag_total_px = 0.0

func drag_to(pos: Vector2) -> void:
	if not _dragging:
		return
	var delta_x: float = pos.x - _last_mouse_x
	var delta_y: float = pos.y - _last_mouse_y
	_drag_total_px += abs(delta_x) + abs(delta_y)
	_last_mouse_x = pos.x
	_last_mouse_y = pos.y
	if _planet_radius_px <= 0.0:
		return
	var now := Time.get_ticks_usec()
	var dt := clampf(float(now - _last_drag_usec) / 1e6, 0.004, 0.1)
	_last_drag_usec = now
	# Vertical drag tilts the globe: dragging down brings the north into view.
	var delta_tilt := 0.0
	if not tilt_locked:
		delta_tilt = delta_y / _planet_radius_px
		_pending_tilt += delta_tilt
	# Keep the surface under the cursor moving 1:1: the view centre sits at
	# latitude = tilt, where a radian of spin covers only cos(tilt) of the radius.
	var delta_rot: float = delta_x / (_planet_radius_px * maxf(cos(tilt), 0.35))
	_pending_rot -= delta_rot
	# Velocity in rad/s (time-weighted, so the fling is the same at any mouse
	# or frame rate); smoothed so one odd event doesn't kill the momentum.
	_drag_velocity = lerpf(_drag_velocity, -delta_rot / dt, 0.5)
	_tilt_velocity = lerpf(_tilt_velocity, delta_tilt / dt, 0.5)
	_last_drag_time = Time.get_ticks_msec()

## Feeds a turn into the eased drag path (trackpad pan and the like).
func nudge(d_rot: float, d_tilt: float) -> void:
	_pending_rot += d_rot
	if not tilt_locked:
		_pending_tilt += d_tilt

## Drops any glide still in flight — call before a scripted camera move.
func stop_motion() -> void:
	_pending_rot = 0.0
	_pending_tilt = 0.0
	_drag_velocity = 0.0
	_tilt_velocity = 0.0

## Advances the drag easing and the fling. PlanetaryView calls this first in its
## _process so every layer drawn this frame sees the same globe; otherwise our
## own _process does. Runs once per frame either way.
func tick_motion(delta: float) -> void:
	var frame := Engine.get_process_frames()
	if frame == _motion_frame:
		return
	_motion_frame = frame
	if not _dragging:
		if _drag_velocity != 0.0 or _tilt_velocity != 0.0:
			_pending_rot += _drag_velocity * delta
			_pending_tilt += _tilt_velocity * delta
			var f := exp(-delta * momentum_friction)
			_drag_velocity *= f
			_tilt_velocity *= f
			if absf(_drag_velocity) < 0.003:
				_drag_velocity = 0.0
			if absf(_tilt_velocity) < 0.003:
				_tilt_velocity = 0.0
	if tilt_locked:
		_pending_tilt = 0.0
		_tilt_velocity = 0.0
	if _pending_rot == 0.0 and _pending_tilt == 0.0:
		return
	var k := 1.0 - exp(-delta * drag_smoothing)
	var step_rot := _pending_rot if absf(_pending_rot) < 1e-5 else _pending_rot * k
	var step_tilt := _pending_tilt if absf(_pending_tilt) < 1e-5 else _pending_tilt * k
	_pending_rot -= step_rot
	_pending_tilt -= step_tilt
	set_rotation_offset(_rotation_offset + step_rot)
	if step_tilt != 0.0:
		var want := tilt + step_tilt
		set_tilt(want)
		if not is_equal_approx(tilt, want):   # hit the pole limit: stop pushing
			_pending_tilt = 0.0
			_tilt_velocity = 0.0

func _process(_delta: float) -> void:
	# @tool script: in the editor only the preview runs. Hot-reloaded editor
	# instances also carry null for newly added members, so stay out entirely.
	if Engine.is_editor_hint():
		return
	tick_motion(_delta)
	# Always sync light direction at the END of every frame so both
	# rotation_offset (updated above or in _input) and light_angle
	# (updated by PlanetaryView._process which runs before us as the parent)
	# are fully up-to-date before the GPU renders.
	_update_light_direction()
