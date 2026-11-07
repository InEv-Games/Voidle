@tool
extends Control
## Runs in the editor too (@tool): there only the backdrop is built — sun,
## stars, planets, orbits — so the shot can be seen and tuned without playing.

const ROTATE_SPEED  := 0.018
const ORBITRON      := "res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf"

const GLITCH_CHARS     := "!@#$%^&*<>?/\\|[]{}~±§"
const GLITCH_STEPS     := 16
const GLITCH_STEP_DUR  := 0.06

var _planet_rect:   ColorRect
var _rotation_off:  float = 0.0
var _font:          Font
var _version_lbl:   Label
var _play_btn:      Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_right  = 1.0
	anchor_bottom = 1.0
	if Engine.is_editor_hint():
		_build_bg()
		_build_stars()
		_build_system(false)
		_build_planet()
		_build_system(true)
		_build_vignette()
		return
	HUDManager.set_game_hud(false)
	_font = load(ORBITRON) as Font

	_build_bg()
	_build_stars()
	_build_system(false)
	_build_planet()
	_build_system(true)
	_build_vignette()
	_build_menu()
	_build_version()

# ── Background ─────────────────────────────────────────────────────────────
# A planet-rise shot: a big world rises out of the bottom-right corner, lit
# from the upper left (an off-screen sun) so its bright rim faces the menu;
# a blue glow behind it, still stars in three depths, a vignette over all.
# The mouse moves the layers a few pixels against it, far ones least.

## Planet size as a share of the screen height; its centre in screen shares.
const PLANET_H_FRAC := 1.35
const PLANET_CENTER := Vector2(0.80, 1.04)
const LIGHT_DIR := Vector3(-0.75, -0.55, 0.35)   # from the upper left (shader: y down)
## Parallax as a camera orbiting the planet: the whole shot turns as one body
## about the planet's centre. The mouse left / right turns it by up to
## PARALLAX_YAW rad, up / down by PARALLAX_PITCH (up shows the north pole). The
## globe's front moves its radius × the angle; the stars and backdrop lie
## behind it (depth in planet radii) and move depth × the angle the other way —
## so they always keep step with the globe.
const PARALLAX_YAW := 0.05
const PARALLAX_PITCH := 0.035
const PARALLAX_BACKDROP := 2.6
const PARALLAX_STARS := [2.4, 2.0, 1.7]   # far, mid, near (planet radii behind its centre)
const PARALLAX_EASE := 4.0      # 1/s — how fast the layers follow the mouse
const PARALLAX_MARGIN := 110.0   # layers overhang the screen by this, so no edge shows
## Stars per layer (far → near): count, size range px, alpha range, twinkle.
const STAR_LAYERS := [
	[220, Vector2(1.0, 1.0), Vector2(0.20, 0.45), 0.25],
	[90,  Vector2(1.0, 2.0), Vector2(0.40, 0.70), 0.35],
	[28,  Vector2(2.0, 2.0), Vector2(0.70, 0.95), 0.45],
]

var _parallax := Vector2.ZERO       # smoothed mouse offset, -0.5 … 0.5
var _planet_spin := 0.0             # the globe's extra turn from the mouse (rad)
var _planet_tilt := 0.0             # …and its tilt
var _layers: Array = []             # [Control, base position, depth px]
var _star_layers: Array[Control] = []
var _stars: Array = []              # per layer: Array of [pos, size, alpha, twinkle, phase, speed]
var _time := 0.0

## The screen size: the game window, or the project's in the editor (where the
## viewport is the editor's own).
func _vp() -> Vector2:
	if Engine.is_editor_hint():
		return Vector2(float(ProjectSettings.get_setting("display/window/size/viewport_width")),
			float(ProjectSettings.get_setting("display/window/size/viewport_height")))
	return get_viewport().get_visible_rect().size

func _add_layer(c: Control, depth: float) -> void:
	_layers.append([c, c.position, depth])

func _build_bg() -> void:
	var vp := _vp()
	var bg := ColorRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.position = Vector2(-PARALLAX_MARGIN, -PARALLAX_MARGIN)
	bg.size = vp + Vector2.ONE * PARALLAX_MARGIN * 2.0
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/menu_backdrop.gdshader")
	mat.set_shader_parameter("aspect", bg.size.x / bg.size.y)
	mat.set_shader_parameter("glow_pos", Vector2(
		(vp.x * PLANET_CENTER.x + PARALLAX_MARGIN) / bg.size.x,
		(vp.y * PLANET_CENTER.y * 0.94 + PARALLAX_MARGIN) / bg.size.y))
	mat.set_shader_parameter("warm_pos", Vector2(
		(vp.x * SUN_CENTER.x + PARALLAX_MARGIN) / bg.size.x,
		(vp.y * SUN_CENTER.y + PARALLAX_MARGIN) / bg.size.y))
	mat.set_shader_parameter("warm_strength", 0.16)
	bg.material = mat
	add_child(bg)
	_add_layer(bg, PARALLAX_BACKDROP)

# ── Stars (still, twinkling a little) ──────────────────────────────────────

func _build_stars() -> void:
	var vp := _vp()
	var area := vp + Vector2.ONE * PARALLAX_MARGIN * 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 7331
	for li in STAR_LAYERS.size():
		var spec: Array = STAR_LAYERS[li]
		var list := []
		for i in int(spec[0]):
			var sz_range: Vector2 = spec[1]
			var a_range: Vector2 = spec[2]
			list.append([Vector2(rng.randf() * area.x, rng.randf() * area.y),
				roundf(rng.randf_range(sz_range.x, sz_range.y)),
				rng.randf_range(a_range.x, a_range.y),
				float(spec[3]) * rng.randf(), rng.randf() * TAU, rng.randf_range(0.6, 2.2)])
		_stars.append(list)
		var layer := Control.new()
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.position = Vector2(-PARALLAX_MARGIN, -PARALLAX_MARGIN)
		layer.size = area
		var cap := li
		layer.draw.connect(func() -> void: _draw_stars(layer, cap))
		add_child(layer)
		_star_layers.append(layer)
		_add_layer(layer, float(PARALLAX_STARS[li]))

func _draw_stars(layer: Control, li: int) -> void:
	for s: Array in _stars[li]:
		var a: float = float(s[2]) * (1.0 - float(s[3]) * (0.5 + 0.5 * sin(_time * float(s[5]) + float(s[4]))))
		var sz: float = s[1]
		layer.draw_rect(Rect2(s[0], Vector2(sz, sz)), Color(0.86, 0.91, 1.0, a))

## A vignette over the whole shot (planet included), under the menu.
func _build_vignette() -> void:
	var v := ColorRect.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/menu_backdrop.gdshader")
	mat.set_shader_parameter("overlay", true)
	v.material = mat
	add_child(v)

## The globe's radius on screen (px): the shader's planet_radius share of the rect.
func _planet_radius_px() -> float:
	if _planet_rect == null or _planet_rect.material == null:
		return 0.0
	return float((_planet_rect.material as ShaderMaterial).get_shader_parameter("planet_radius")) * _planet_rect.size.y

## Eases the layers toward the mouse (each by its depth) and twinkles the stars.
func _tick_backdrop(delta: float) -> void:
	_time += delta
	var vp := _vp()
	# the editor's mouse isn't the player's: there the shot only drifts
	var m := vp * 0.5 if Engine.is_editor_hint() else get_viewport().get_mouse_position()
	var target := Vector2(clampf(m.x / vp.x, 0.0, 1.0) - 0.5, clampf(m.y / vp.y, 0.0, 1.0) - 0.5)
	if not Engine.is_editor_hint():
		var rx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		var ry := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		if absf(rx) > 0.15 or absf(ry) > 0.15:
			target.x = clampf(target.x + rx * 0.5, -0.5, 0.5)
			target.y = clampf(target.y + ry * 0.5, -0.5, 0.5)
	# a slow camera drift under the mouse, so the shot never stands still
	target += Vector2(sin(_time * DRIFT_SPEED.x) * DRIFT_AMOUNT.x,
		sin(_time * DRIFT_SPEED.y + 1.3) * DRIFT_AMOUNT.y)
	_parallax = _parallax.lerp(target, 1.0 - exp(-delta * PARALLAX_EASE))
	# the camera orbits: one turn for everything (yaw: + moves the globe's front
	# right; pitch: + moves it down, bringing the north into view)
	var k := _parallax * 2.0   # -1 … 1
	var yaw := -k.x * PARALLAX_YAW
	var pitch := -k.y * PARALLAX_PITCH
	var r := _planet_radius_px()
	for l: Array in _layers:
		var c := l[0] as Control
		if is_instance_valid(c):
			var depth := float(l[2]) * r   # behind the planet's centre
			c.position = (l[1] as Vector2) + Vector2(-depth * yaw, -depth * pitch)
	# the globe's own drag rule (PlanetRenderer): its front moves right as the
	# spin offset goes down, and down as the tilt goes up
	_planet_spin = -yaw
	_planet_tilt = pitch
	for layer in _star_layers:
		layer.queue_redraw()
	for b: Array in _bodies:
		var bm := b[0] as ShaderMaterial
		b[2] = fposmod(float(b[2]) + float(b[1]) * delta, TAU)
		bm.set_shader_parameter("rotation_offset", fposmod(float(b[2]) + _planet_spin, TAU))
		bm.set_shader_parameter("tilt", _planet_tilt)

# ── Star system ────────────────────────────────────────────────────────────
# The rest of the system around the focus world: its sun just inside the
# top-left corner (the light every body takes its shading from), one big ringed
# gas giant far behind, and a moon a little in front of the
# focus world. Each body sits at its own depth, so the mouse (and the slow
# drift) slides them past each other; a faint orbit line runs through each,
# centred on the sun and brightest at its body.

## The sun's centre in screen shares (mostly off screen) and its rect's size
## as a share of the screen height.
const SUN_CENTER := Vector2(0.03, -0.05)
const SUN_H_FRAC := 0.80
const SUN_DEPTH := 4.0
## Orbits: tilted ellipses about the sun (tilt rad, minor / major axis).
const ORBIT_TILT := 0.32
const ORBIT_FLAT := 0.40
const ORBIT_ALPHA := Vector2(0.05, 0.20)   # line alpha: far from / at its body
## The slow camera drift, in mouse shares (amount) and rad/s (speed).
const DRIFT_AMOUNT := Vector2(0.16, 0.10)
const DRIFT_SPEED := Vector2(0.085, 0.061)
## Bodies: type, seed, centre (screen shares), globe diameter (screen-height
## share), depth (planet radii behind the focus world's centre; < 0 in front),
## spin rad/s, ringed, in front of the focus world.
const BODIES := [
	[PlanetData.Type.GAS_GIANT, 8803, Vector2(0.600, 0.200), 0.190, 3.0,  0.008, true,  false],
	[PlanetData.Type.MOON,      5519, Vector2(0.505, 0.615), 0.085, -0.9, 0.015, false, true],
]
const GLOBE_FILL := 0.42   # planet_radius: the globe's share of its rect
## Every planet and moon (rings too) is drawn at this brightness; the sun isn't.
## Set on their colours, not laid over them, so nothing around a globe darkens.
const PLANET_BRIGHTNESS := 0.70

## Sets a planet shader's colour uniform at PLANET_BRIGHTNESS.
static func _set_color(mat: ShaderMaterial, key: String, v: Vector3) -> void:
	mat.set_shader_parameter(key, v * PLANET_BRIGHTNESS)
## Distance haze: a body (or orbit) `depth` radii behind the focus world is
## dimmed and cooled toward the night sky, DEPTH_FADE at DEPTH_FADE_AT and on.
const DEPTH_FADE := 0.55
const DEPTH_FADE_AT := 3.2
const DEPTH_FOG := 0.42   # haze over a globe at DEPTH_FADE_AT
const HAZE := Color(0.62, 0.72, 0.98)

## The tint for something `depth` radii behind the focus world (white in front).
static func _depth_tint(depth: float) -> Color:
	var t := _depth_t(depth)
	var b := 1.0 - DEPTH_FADE * t
	var c := Color.WHITE.lerp(HAZE, t) * b
	c.a = 1.0
	return c

## 0 at the focus world (or in front of it) … 1 at DEPTH_FADE_AT and beyond,
## fast at first, then levelling off.
static func _depth_t(depth: float) -> float:
	var t := clampf(depth / DEPTH_FADE_AT, 0.0, 1.0)
	return 1.0 - (1.0 - t) * (1.0 - t)

## Soft occlusion over a globe of radius `r` px at `centre` (in `parent`):
## limb shading (darkest away from the sun) and its distance haze.
func _add_ao(parent: Node, centre: Vector2, r: float, light: Vector2, px: float, depth: float = 0.0) -> void:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var side := 2.0 * r + 4.0
	rect.size = Vector2(side, side)
	rect.position = centre - rect.size * 0.5
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/menu_body_ao.gdshader")
	mat.set_shader_parameter("radius", r / side)
	mat.set_shader_parameter("pixel_count", maxf(side / px, 8.0))
	mat.set_shader_parameter("light", light)
	mat.set_shader_parameter("fog", DEPTH_FOG * _depth_t(depth))
	rect.material = mat
	parent.add_child(rect)

var _bodies: Array = []    # [ShaderMaterial, spin rad/s, rotation]

func _sun_px() -> Vector2:
	var vp := _vp()
	return Vector2(vp.x * SUN_CENTER.x, vp.y * SUN_CENTER.y)

## The far half (sun, orbits, far bodies) or the near half (bodies in front).
func _build_system(front: bool) -> void:
	var vp := _vp()
	if not front:
		_build_sun(vp)
		# the focus world's own orbit, fixed with it
		_build_orbit(Vector2(vp.x * PLANET_CENTER.x, vp.y * PLANET_CENTER.y), 0.0)
	for spec: Array in BODIES:
		if bool(spec[7]) != front:
			continue
		var c: Vector2 = spec[2]
		var centre := Vector2(vp.x * c.x, vp.y * c.y)
		if not front:
			_build_orbit(centre, float(spec[4]))
		_build_body(spec, centre, vp)

func _build_sun(vp: Vector2) -> void:
	var side := vp.y * SUN_H_FRAC
	var sun := ColorRect.new()
	sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sun.size = Vector2(side, side)
	sun.position = _sun_px() - sun.size * 0.5
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/star.gdshader")
	mat.set_shader_parameter("star_radius", 0.20)
	mat.set_shader_parameter("corona_size", 0.28)
	mat.set_shader_parameter("pixel_count", maxf(side / 4.25, 32.0))
	mat.set_shader_parameter("flicker_speed", 0.25)
	mat.set_shader_parameter("seed", 911)
	sun.material = mat
	add_child(sun)
	_add_layer(sun, SUN_DEPTH)

## A faint ellipse about the sun through `through`, on that body's depth.
func _build_orbit(through: Vector2, depth: float) -> void:
	var vp := _vp()
	var layer := Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.position = Vector2(-PARALLAX_MARGIN, -PARALLAX_MARGIN)
	layer.size = vp + Vector2.ONE * PARALLAX_MARGIN * 2.0
	var off := Vector2.ONE * PARALLAX_MARGIN
	var sun := _sun_px() + off
	var local := (through + off - sun).rotated(-ORBIT_TILT)
	var rx := sqrt(local.x * local.x + pow(local.y / ORBIT_FLAT, 2.0))
	var at := atan2(local.y / ORBIT_FLAT, local.x)   # the body's angle on it
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var segs := 360
	var line := UIStyle.color(&"text_bright")
	for i in segs + 1:
		var t := TAU * float(i) / float(segs)
		pts.append(sun + Vector2(cos(t) * rx, sin(t) * rx * ORBIT_FLAT).rotated(ORBIT_TILT))
		var d := absf(wrapf(t - at, -PI, PI))
		var a := lerpf(ORBIT_ALPHA.x, ORBIT_ALPHA.y, exp(-d * d / 0.08))
		cols.append(Color(line, a))
	layer.draw.connect(func() -> void: layer.draw_polyline_colors(pts, cols, 1.0))
	layer.modulate = _depth_tint(depth * 0.5)
	add_child(layer)
	_add_layer(layer, depth)

## One body: a holder at its depth with the ring's far half, the globe, and
## the ring's near half.
func _build_body(spec: Array, centre: Vector2, vp: Vector2) -> void:
	var type: PlanetData.Type = spec[0]
	var data: PlanetData
	match type:
		PlanetData.Type.GAS_GIANT: data = PlanetData.make_gas_giant(int(spec[1]))
		PlanetData.Type.MOON:      data = PlanetData.make_moon(int(spec[1]))
		_:                         data = PlanetData.from_seed_as_type(int(spec[1]), type)
	var disc := vp.y * float(spec[3])
	var side := disc / (GLOBE_FILL * 2.0)

	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = centre
	holder.modulate = _depth_tint(float(spec[4])) * Color(PLANET_BRIGHTNESS, PLANET_BRIGHTNESS, PLANET_BRIGHTNESS)
	add_child(holder)
	_add_layer(holder, float(spec[4]))

	var ringed := bool(spec[6])
	if ringed:
		holder.draw.connect(func() -> void: _draw_ring(holder, disc * 0.5, false))

	var globe := ColorRect.new()
	globe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	globe.size = Vector2(side, side)
	globe.position = -globe.size * 0.5
	var light2 := (_sun_px() - centre).normalized()
	var mat := _body_material(data, side, Vector3(light2.x, light2.y, 0.25).normalized())
	globe.material = mat
	holder.add_child(globe)
	_add_ao(holder, Vector2.ZERO, disc * 0.5, light2, 4.25, float(spec[4]))
	var rot := randf() * TAU
	_bodies.append([mat, float(spec[5]), rot])

	if ringed:
		var near := Control.new()
		near.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(near)
		near.draw.connect(func() -> void: _draw_ring(near, disc * 0.5, true))

## A tilted ring around a globe of radius `r` (px): bands of ellipse arcs, the
## near half (below the centre) drawn over the globe, the far half under it.
const RING_TILT := -0.38
const RING_FLAT := 0.26
const RING_BANDS := [[1.30, 0.30], [1.42, 0.55], [1.55, 0.70], [1.66, 0.40], [1.78, 0.62], [1.92, 0.32]]

func _draw_ring(on: CanvasItem, r: float, near: bool) -> void:
	var col := Color(0.86, 0.76, 0.56)
	var w := maxf(r * 0.10, 1.5)
	for band: Array in RING_BANDS:
		var rx := r * float(band[0])
		var pts := PackedVector2Array()
		var from := 0.0 if near else PI
		for i in 49:
			var t := from + PI * float(i) / 48.0
			pts.append(Vector2(cos(t) * rx, sin(t) * rx * RING_FLAT).rotated(RING_TILT))
		on.draw_polyline(pts, Color(col, float(band[1]) * (0.85 if near else 0.55)), w)

## The globe's material for `data` at a rect `side` px across, lit from `light`.
func _body_material(data: PlanetData, side: float, light: Vector3) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(PlanetData.get_shader_path(data.planet_type)) as Shader
	mat.set_shader_parameter("planet_radius", GLOBE_FILL)
	mat.set_shader_parameter("pixel_count", maxf(side / 4.25, 20.0))
	mat.set_shader_parameter("seed", data.seed)
	mat.set_shader_parameter("terrain_roughness", data.terrain_roughness)
	mat.set_shader_parameter("aspect_ratio", 1.0)
	mat.set_shader_parameter("light_direction", light)
	var colors := PlanetData.get_colors(data.planet_type)
	match PlanetData.get_shader_type(data.planet_type):
		PlanetData.ShaderType.ROCKY:
			mat.set_shader_parameter("cloud_speed", data.cloud_speed)
			mat.set_shader_parameter("cloud_coverage", data.cloud_coverage)
			mat.set_shader_parameter("has_clouds", 1.0 if data.has_clouds else 0.0)
			mat.set_shader_parameter("atmosphere_density", data.atmosphere_density if data.has_atmosphere else 0.0)
			mat.set_shader_parameter("sea_level", data.sea_level)
			mat.set_shader_parameter("continent_scale", data.continent_scale)
			mat.set_shader_parameter("specular_strength", data.specular_strength)
			mat.set_shader_parameter("city_lights", 0.0)
			for key in colors:
				_set_color(mat, key, colors[key])
		PlanetData.ShaderType.GAS:
			mat.set_shader_parameter("cloud_speed", data.cloud_speed)
			mat.set_shader_parameter("atmosphere_density", data.atmosphere_density)
			_set_color(mat, "color_band_a", colors.get("color_sand", Vector3(0.72, 0.55, 0.35)))
			_set_color(mat, "color_band_b", colors.get("color_forest", Vector3(0.50, 0.32, 0.18)))
			_set_color(mat, "color_storm", colors.get("color_snow", Vector3(0.88, 0.82, 0.72)))
			_set_color(mat, "color_atmosphere", colors.get("color_atmosphere", Vector3(0.72, 0.55, 0.35)))
		PlanetData.ShaderType.MOON:
			_set_color(mat, "color_highland", colors.get("color_mountain", Vector3(0.62, 0.60, 0.56)))
			_set_color(mat, "color_mare", colors.get("color_deep_ocean", Vector3(0.22, 0.21, 0.20)))
			_set_color(mat, "color_rim", colors.get("color_snow", Vector3(0.78, 0.76, 0.72)))
			_set_color(mat, "color_floor", colors.get("color_ocean", Vector3(0.16, 0.15, 0.14)))
	return mat

# ── Planet ─────────────────────────────────────────────────────────────────

func _build_planet() -> void:
	var vp := _vp()
	var side := vp.y * PLANET_H_FRAC

	_planet_rect = ColorRect.new()
	_planet_rect.custom_minimum_size = Vector2(side, side)
	_planet_rect.size                = Vector2(side, side)
	# rising out of the bottom-right corner (centre below the screen's edge)
	_planet_rect.position = Vector2(vp.x * PLANET_CENTER.x, vp.y * PLANET_CENTER.y) - Vector2(side, side) * 0.5
	_planet_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_planet_rect)

	var data := PlanetData.from_seed_no_minor(7331)
	# Force a nice terran planet for the main menu
	data.planet_type        = PlanetData.Type.TERRAN
	data.has_atmosphere     = true
	data.atmosphere_density = 1.0
	data.has_clouds         = true
	data.cloud_speed        = 0.025
	data.cloud_coverage     = 0.50
	data.sea_level          = 0.0
	data.continent_scale    = 1.0
	data.terrain_roughness  = 1.0
	data.specular_strength  = 0.4
	data.city_lights        = 0.2

	var shader := load(PlanetData.get_shader_path(data.planet_type)) as Shader
	var mat    := ShaderMaterial.new()
	mat.shader  = shader

	var sz          : float = clamp(float(data.planet_size), 0.2, 2.0)
	var base_radius : float = clamp(0.42 * sz, 0.10, 0.48)
	# same pixel size as the old 680px planet at 160 (≈4.25px a pixel), at any size
	var pcount: float = clampf(160.0 * _planet_rect.size.x / 680.0, 32.0, 512.0)

	mat.set_shader_parameter("rotation_offset",   0.0)
	mat.set_shader_parameter("planet_radius",     base_radius)
	mat.set_shader_parameter("pixel_count",       pcount)
	mat.set_shader_parameter("seed",              data.seed)
	mat.set_shader_parameter("terrain_roughness", data.terrain_roughness)
	mat.set_shader_parameter("aspect_ratio",      1.0)
	mat.set_shader_parameter("cloud_speed",       data.cloud_speed)
	mat.set_shader_parameter("cloud_coverage",    data.cloud_coverage)
	mat.set_shader_parameter("has_clouds",        1.0)
	mat.set_shader_parameter("atmosphere_density",data.atmosphere_density)
	mat.set_shader_parameter("sea_level",         data.sea_level)
	mat.set_shader_parameter("continent_scale",   data.continent_scale)
	mat.set_shader_parameter("specular_strength", data.specular_strength)
	mat.set_shader_parameter("city_lights",       data.city_lights)

	var colors := PlanetData.get_colors(data.planet_type)
	for key in colors:
		_set_color(mat, key, colors[key])

	_update_light(mat)
	_planet_rect.material = mat
	_add_ao(self, _planet_rect.position + _planet_rect.size * 0.5, base_radius * side,
		Vector2(LIGHT_DIR.x, LIGHT_DIR.y).normalized(), side / pcount)

# ── Menu UI ────────────────────────────────────────────────────────────────

func _build_menu() -> void:
	var vp := _vp()

	var root := VBoxContainer.new()
	root.position               = Vector2(vp.x * 0.07, vp.y * 0.22)
	root.custom_minimum_size    = Vector2(vp.x * 0.38, 0.0)
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	_menu_root = root

	# Title
	var title := Label.new()
	title.text = "VOIDLE"
	if _font: title.add_theme_font_override("font", _font)
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", UIStyle.color(&"text_bright"))
	root.add_child(title)

	# Subtitle
	var sub := Label.new()
	sub.text = "An idle space empire"
	if _font: sub.add_theme_font_override("font", _font)
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", UIStyle.color(&"text_muted"))
	root.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 28)
	root.add_child(gap)

	# Buttons — the browser demo has no saves (one PLAY DEMO), no tour and no QUIT
	var demo := GameState.demo_build
	if demo:
		_add_button(root, "PLAY DEMO", _on_new_game)
	else:
		# PLAY opens the save slots (pick one to play, or delete one)
		_play_btn = _add_button(root, "PLAY", _on_play)

	_add_button(root, "SETTINGS",  _on_settings)
	if not demo:
		_add_button(root, "QUIT",      _on_quit)

	# Version
	var ver := Label.new()
	ver.text = "Demo  –  progress isn't saved" if demo else "v0.1  –  Early Access"
	if _font: ver.add_theme_font_override("font", _font)
	ver.add_theme_font_size_override("font_size", 8)
	ver.add_theme_color_override("font_color", UIStyle.color(&"text_muted"))
	var vgap := Control.new()
	vgap.custom_minimum_size = Vector2(0, 32)
	root.add_child(vgap)
	root.add_child(ver)

## Menu item: icon-left Default button (NEW GAME, CONTINUE, SETTINGS, QUIT).
const MENU_ICONS := {"PLAY": "new", "PLAY DEMO": "new", "SETTINGS": "settings", "QUIT": "close"}

func _add_button(parent: Control, label: String, cb: Callable) -> Button:
	var btn := IconButton.create(label, MENU_ICONS.get(label, "unknown"))
	btn.font_size = 12
	btn.min_size = Vector2(260, 36)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn.pressed.connect(cb)
	parent.add_child(btn)
	return btn

# ── Version ──────────────────────────────────────────────────────────────
# Bottom right: "Voidle v0.1 680a54d" (BuildInfo), glitching in once.

func _build_version() -> void:
	_version_lbl = Label.new()
	if _font: _version_lbl.add_theme_font_override("font", _font)
	_version_lbl.add_theme_font_size_override("font_size", 9)
	_version_lbl.add_theme_color_override("font_color", Color(UIStyle.color(&"text_muted"), 0.75))
	_version_lbl.anchor_left   = 1.0
	_version_lbl.anchor_right  = 1.0
	_version_lbl.anchor_top    = 1.0
	_version_lbl.anchor_bottom = 1.0
	_version_lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_version_lbl.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	_version_lbl.offset_right  = -18.0
	_version_lbl.offset_bottom = -14.0
	_version_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_version_lbl)
	_glitch_to(BuildInfo.label())

func _glitch_to(target: String) -> void:
	var rng   := RandomNumberGenerator.new()
	var chars := GLITCH_CHARS
	var orig  := _version_lbl.text
	var max_len := maxi(orig.length(), target.length())

	for step in GLITCH_STEPS:
		var t    := float(step) / float(GLITCH_STEPS)
		var out  := ""
		for i in max_len:
			if i < target.length() and t > float(i) / float(max_len):
				out += target[i]
			elif i < orig.length():
				out += chars[rng.randi() % chars.length()]
			else:
				out += chars[rng.randi() % chars.length()]
		_version_lbl.text = out
		await get_tree().create_timer(GLITCH_STEP_DUR).timeout

	if is_instance_valid(_version_lbl):
		_version_lbl.text = target

# ── Planet animation ───────────────────────────────────────────────────────

func _update_light(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("light_direction", LIGHT_DIR.normalized())

func _process(delta: float) -> void:
	_tick_backdrop(delta)
	if not Engine.is_editor_hint():
		_tick_nav(delta)
	if _planet_rect == null or _planet_rect.material == null:
		return
	_rotation_off = fposmod(_rotation_off + ROTATE_SPEED * delta, TAU)
	var mat := _planet_rect.material as ShaderMaterial
	mat.set_shader_parameter("rotation_offset", fposmod(_rotation_off + _planet_spin, TAU))
	mat.set_shader_parameter("tilt", _planet_tilt)

# ── Button callbacks ────────────────────────────────────────────────────────

# ── Save slots (PLAY) ────────────────────────────────────────────────────────
# PLAY swaps the menu for the save panel in the same spot: ‹ MENU above a hero
# ("Save slots" / PLAY, like the left panel's), then the three slots as cards
# side by side. A card shows its save (or Empty) with PLAY / NEW GAME and a bin
# that deletes the save after a confirm; a save this build can't read says why
# and can't be played. Rows come in with RowReveal; Esc or ‹ MENU goes back.

const SLOT_CARD_W := 210.0
const MENU_REVEAL_SLOW := 3.0   # the menu's transitions run 3x slower than a tooltip's
const MENU_BLINK_SOUND := &"ui/blink"   # VAM event on every row blink of the menu's transitions

var _menu_root: VBoxContainer
var _saves_root: VBoxContainer

func _on_play() -> void:
	AudioManager.play("click", 0.0)
	_open_saves()

func _open_saves() -> void:
	if is_instance_valid(_saves_root):
		_saves_root.queue_free()
	_menu_root.visible = false
	_saves_root = VBoxContainer.new()
	_saves_root.position = _menu_root.position
	_saves_root.add_theme_constant_override("separation", 8)
	add_child(_saves_root)
	var back := LeftPanel.back_button("MENU")
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(_close_saves)
	_saves_root.add_child(back)
	_saves_root.add_child(HeroHeader.create("Save slots", "PLAY"))
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 10)
	for slot in GameState.SAVE_SLOTS:
		cards.add_child(_slot_card(slot))
	_saves_root.add_child(cards)
	RowReveal.play(_saves_root, MENU_REVEAL_SLOW, false, MENU_BLINK_SOUND)

func _close_saves() -> void:
	AudioManager.play("click", 0.0)
	if is_instance_valid(_saves_root):
		_saves_root.queue_free()
	_saves_root = null
	_menu_root.visible = true
	RowReveal.play(_menu_root, MENU_REVEAL_SLOW, false, MENU_BLINK_SOUND)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseMotion:
		if _nav_active and (event as InputEventMouseMotion).relative.length_squared() > 4.0:
			_clear_nav_focus()
		return
	var dc := get_node_or_null("/root/DevConsole")
	if dc != null and bool(dc.get("_open")):
		return
	if event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed:
			return
		var k := ke.keycode if ke.keycode != KEY_NONE else ke.physical_keycode
		var pk := ke.physical_keycode if ke.physical_keycode != KEY_NONE else ke.keycode
		var dir := Vector2.ZERO
		if k == KEY_UP or pk == KEY_W:
			dir = Vector2(0, -1)
		elif k == KEY_DOWN or pk == KEY_S:
			dir = Vector2(0, 1)
		elif k == KEY_LEFT or pk == KEY_A:
			dir = Vector2(-1, 0)
		elif k == KEY_RIGHT or pk == KEY_D:
			dir = Vector2(1, 0)
		if dir != Vector2.ZERO:
			if _handle_nav_dir(dir):
				get_viewport().set_input_as_handled()
			return
		if not ke.echo and (k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE):
			if not _nav_active:
				var intro := _find_intro_card()
				if intro != null:
					var begin_btn := intro.get_node_or_null("%BeginButton") as BaseButton
					if begin_btn != null:
						begin_btn.pressed.emit()
						get_viewport().set_input_as_handled()
						return
				if _handle_nav_dir(Vector2(0, 1)):
					get_viewport().set_input_as_handled()
			elif _activate_focused():
				get_viewport().set_input_as_handled()
			return
		if not ke.echo and (k == KEY_BACKSPACE or k == KEY_ESCAPE):
			if _handle_nav_back():
				get_viewport().set_input_as_handled()
			return
	elif event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if not jb.pressed:
			return
		var jdir := Vector2.ZERO
		match jb.button_index:
			JOY_BUTTON_DPAD_UP:    jdir = Vector2(0, -1)
			JOY_BUTTON_DPAD_DOWN:  jdir = Vector2(0, 1)
			JOY_BUTTON_DPAD_LEFT:  jdir = Vector2(-1, 0)
			JOY_BUTTON_DPAD_RIGHT: jdir = Vector2(1, 0)
		if jdir != Vector2.ZERO:
			if _handle_nav_dir(jdir):
				get_viewport().set_input_as_handled()
			return
		match jb.button_index:
			JOY_BUTTON_A:
				if not _nav_active:
					var intro := _find_intro_card()
					if intro != null:
						var begin_btn := intro.get_node_or_null("%BeginButton") as BaseButton
						if begin_btn != null:
							begin_btn.pressed.emit()
							get_viewport().set_input_as_handled()
							return
					if _handle_nav_dir(Vector2(0, 1)):
						get_viewport().set_input_as_handled()
				elif _activate_focused():
					get_viewport().set_input_as_handled()
			JOY_BUTTON_B:
				if _handle_nav_back():
					get_viewport().set_input_as_handled()

# ── Keyboard & Controller Navigation (Hover State) ──────────────────────────

var _nav_active := false
var _nav_focus: Control = null
var _nav_last_root_id: int = 0
var _saved_focus_by_root: Dictionary = {}
var _stick_dir := Vector2i.ZERO
var _stick_timer := 0.0
const STICK_DEADZONE := 0.45
const STICK_INITIAL_DELAY := 0.26
const STICK_REPEAT_DELAY := 0.11

func _find_top_modal() -> ModalPopup:
	var root_vp := get_tree().root
	if root_vp != null:
		for i in range(root_vp.get_child_count() - 1, -1, -1):
			var rch := root_vp.get_child(i)
			if rch is ModalPopup:
				return rch as ModalPopup
			if rch is CanvasLayer:
				for j in range(rch.get_child_count() - 1, -1, -1):
					var cch := rch.get_child(j)
					if cch is ModalPopup:
						return cch as ModalPopup
	for i in range(get_child_count() - 1, -1, -1):
		var ch := get_child(i)
		if ch is ModalPopup:
			return ch as ModalPopup
	return null

func _find_intro_card() -> Control:
	for i in range(get_child_count() - 1, -1, -1):
		var ch := get_child(i)
		if ch is CanvasLayer:
			for j in range(ch.get_child_count() - 1, -1, -1):
				var cch := ch.get_child(j)
				if cch is Control and cch.get_node_or_null("%BeginButton") != null:
					return cch as Control
	return null

func _active_nav_root() -> Node:
	var modal := _find_top_modal()
	if modal != null:
		return modal
	var intro := _find_intro_card()
	if intro != null:
		return intro
	if is_instance_valid(_saves_root) and _saves_root.visible:
		return _saves_root
	if is_instance_valid(_menu_root) and _menu_root.visible:
		return _menu_root
	return null

func _collect_focusables(n: Node, out: Array[Control]) -> void:
	if n == null or not is_instance_valid(n):
		return
	for ch in n.get_children():
		if ch is CanvasLayer:
			_collect_focusables(ch, out)
			continue
		if not (ch is Control):
			continue
		var c := ch as Control
		if not c.visible or not c.is_visible_in_tree():
			continue
		if c is ListItem:
			var li := c as ListItem
			if li.clickable or li.show_stepper:
				out.append(li)
			continue
		if c is LineEdit or c is HSlider:
			out.append(c)
			continue
		if c is BaseButton:
			var vp := _vp()
			if c.size.x > vp.x * 0.6 and c.size.y > vp.y * 0.6:
				continue
			out.append(c)
			continue
		_collect_focusables(c, out)

func _default_focus_for(root: Node, items: Array[Control]) -> Control:
	if items.is_empty():
		return null
	if root == _saves_root and items.size() > 1:
		return items[1]
	return items[0]

func _tick_nav(delta: float) -> void:
	var dc := get_node_or_null("/root/DevConsole")
	if dc != null and bool(dc.get("_open")):
		if _nav_active:
			_clear_nav_focus()
		return
	var lx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var ly := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var new_dir := Vector2i.ZERO
	if absf(ly) >= STICK_DEADZONE or absf(lx) >= STICK_DEADZONE:
		if absf(ly) >= absf(lx):
			new_dir = Vector2i(0, 1 if ly > 0.0 else -1)
		else:
			new_dir = Vector2i(1 if lx > 0.0 else -1, 0)
	if new_dir != Vector2i.ZERO:
		if new_dir != _stick_dir:
			_stick_dir = new_dir
			_stick_timer = STICK_INITIAL_DELAY
			_handle_nav_dir(Vector2(_stick_dir.x, _stick_dir.y))
		else:
			_stick_timer -= delta
			if _stick_timer <= 0.0:
				_stick_timer = STICK_REPEAT_DELAY
				_handle_nav_dir(Vector2(_stick_dir.x, _stick_dir.y))
	else:
		_stick_dir = Vector2i.ZERO
		_stick_timer = 0.0

	if not _nav_active:
		return
	var root := _active_nav_root()
	if root == null:
		_clear_nav_focus()
		return
	var rid := root.get_instance_id()
	var focus_valid := _nav_focus != null and is_instance_valid(_nav_focus) \
		and _nav_focus.is_visible_in_tree() and root.is_ancestor_of(_nav_focus)
	if rid != _nav_last_root_id or not focus_valid:
		_nav_last_root_id = rid
		var items: Array[Control] = []
		_collect_focusables(root, items)
		var restored: Control = null
		if _saved_focus_by_root.has(rid):
			var w: WeakRef = _saved_focus_by_root[rid]
			var cand = w.get_ref() if w != null else null
			if cand != null and is_instance_valid(cand) and items.has(cand as Control):
				restored = cand as Control
		if restored != null:
			_set_nav_focus(restored, false)
		elif not items.is_empty():
			_set_nav_focus(_default_focus_for(root, items), false)
		else:
			_set_nav_focus(null, false)

func _handle_nav_dir(dir: Vector2) -> bool:
	var root := _active_nav_root()
	if root == null:
		return false
	var items: Array[Control] = []
	_collect_focusables(root, items)
	if items.is_empty():
		return false
	_nav_active = true
	_nav_last_root_id = root.get_instance_id()
	if _nav_focus == null or not is_instance_valid(_nav_focus) or not items.has(_nav_focus):
		var saved: Control = null
		if _saved_focus_by_root.has(_nav_last_root_id):
			var w: WeakRef = _saved_focus_by_root[_nav_last_root_id]
			var cand = w.get_ref() if w != null else null
			if cand != null and is_instance_valid(cand) and items.has(cand as Control):
				saved = cand as Control
		_set_nav_focus(saved if saved != null else _default_focus_for(root, items), true)
		return true

	if absf(dir.x) > 0.5 and _nav_focus is HSlider:
		var sl := _nav_focus as HSlider
		var step := sl.step if sl.step > 0.0 else (sl.max_value - sl.min_value) * 0.05
		sl.value = clampf(sl.value + (1.0 if dir.x > 0.0 else -1.0) * step, sl.min_value, sl.max_value)
		AudioManager.play("hover")
		return true

	if absf(dir.x) > 0.5 and _nav_focus is OptionButton:
		var opt := _nav_focus as OptionButton
		if opt.item_count > 0:
			opt.selected = posmod(opt.selected + (1 if dir.x > 0.0 else -1), opt.item_count)
			opt.item_selected.emit(opt.selected)
		return true

	var cur_rect := _nav_focus.get_global_rect()
	var cur_c := cur_rect.get_center()
	var best: Control = null
	var best_score := INF

	if absf(dir.x) > 0.5:
		for c in items:
			if c == _nav_focus:
				continue
			var r := c.get_global_rect()
			var cc := r.get_center()
			var dx := (cc.x - cur_c.x) * dir.x
			var dy := absf(cc.y - cur_c.y)
			if dx <= 4.0 or dy > maxf(cur_rect.size.y, r.size.y) * 1.2:
				continue
			var score := dx + dy * 2.0
			if score < best_score:
				best_score = score
				best = c
	else:
		for c in items:
			if c == _nav_focus:
				continue
			var r := c.get_global_rect()
			var cc := r.get_center()
			var dy := (cc.y - cur_c.y) * dir.y
			if dy <= 4.0:
				continue
			var dx := absf(cc.x - cur_c.x)
			var score := dy + dx * 0.25
			if score < best_score:
				best_score = score
				best = c
		if best == null:
			var idx := items.find(_nav_focus)
			var next_idx := clampi(idx + (1 if dir.y > 0.0 else -1), 0, items.size() - 1)
			if next_idx != idx:
				best = items[next_idx]

	if best != null and best != _nav_focus:
		_set_nav_focus(best, true)
	return true

func _set_nav_focus(c: Control, play_sound: bool) -> void:
	if _nav_focus != null and is_instance_valid(_nav_focus) and _nav_focus != c:
		_apply_hover_visual(_nav_focus, false)
	_nav_focus = c
	if _nav_focus != null and is_instance_valid(_nav_focus):
		var root := _active_nav_root()
		if root != null:
			_saved_focus_by_root[root.get_instance_id()] = weakref(_nav_focus)
		TooltipManager.set_focus_anchor(_nav_focus)
		_apply_hover_visual(_nav_focus, true)
		if play_sound:
			AudioManager.play("hover")
	else:
		TooltipManager.set_focus_anchor(null)
		TooltipManager.hide_tip()

func _clear_nav_focus() -> void:
	if _nav_focus != null and is_instance_valid(_nav_focus):
		_apply_hover_visual(_nav_focus, false)
	_nav_focus = null
	_nav_active = false
	TooltipManager.set_focus_anchor(null)
	TooltipManager.hide_tip()

func _apply_hover_visual(c: Control, hovered: bool) -> void:
	if hovered:
		if c is Button:
			var hsb := c.get_theme_stylebox(&"hover")
			if hsb != null:
				c.add_theme_stylebox_override(&"disabled", hsb)
				c.set_meta("_nav_disabled_hover", true)
		c.notification(Control.NOTIFICATION_MOUSE_ENTER)
		c.mouse_entered.emit()
	else:
		if c is Button and c.has_meta("_nav_disabled_hover"):
			c.remove_theme_stylebox_override(&"disabled")
			c.remove_meta("_nav_disabled_hover")
		c.notification(Control.NOTIFICATION_MOUSE_EXIT)
		c.mouse_exited.emit()

func _activate_focused() -> bool:
	if _nav_focus == null or not is_instance_valid(_nav_focus) or not _nav_focus.is_visible_in_tree():
		return false
	var c := _nav_focus
	if c is ListItem:
		var li := c as ListItem
		if li.clickable:
			li.pressed.emit()
			return true
		if li.show_stepper:
			li.stepped.emit(1)
			return true
		return false
	if c is OptionButton:
		var opt := c as OptionButton
		if opt.item_count > 0:
			opt.selected = posmod(opt.selected + 1, opt.item_count)
			opt.item_selected.emit(opt.selected)
		return true
	if c is HSlider:
		return true
	if c is BaseButton:
		var btn := c as BaseButton
		if btn.disabled:
			AudioManager.play("denied")
			return true
		if btn.toggle_mode:
			btn.button_pressed = not btn.button_pressed
		btn.pressed.emit()
		return true
	return false

func _handle_nav_back() -> bool:
	var modal := _find_top_modal()
	if modal != null:
		if modal.dismissable:
			AudioManager.play("click")
			modal.close()
		return true
	var intro := _find_intro_card()
	if intro != null:
		AudioManager.play("click")
		if intro.has_method("_close"):
			intro.call("_close")
		return true
	if is_instance_valid(_saves_root) and _saves_root.visible:
		_close_saves()
		return true
	if _nav_active:
		_clear_nav_focus()
		return true
	return false

## One slot: SLOT n (+ LAST PLAYED), its save in a few lines, PLAY / NEW GAME
## and the bin.
func _slot_card(slot: int) -> Control:
	var info := GameState.slot_info(slot)
	var blocked := ""
	if not info.is_empty() and not bool(info.get("ok", false)):
		blocked = String(info.get("why", "Can't be loaded"))
	elif not info.is_empty() and slot == GameState.save_slot and GameState.save_block_reason() != "":
		blocked = GameState.save_block_reason()

	var card := PanelContainer.new()
	card.theme_type_variation = &"PopupCard"
	card.custom_minimum_size = Vector2(SLOT_CARD_W, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)

	var head := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = "SLOT %d" % (slot + 1)
	name_lbl.theme_type_variation = &"HeaderLabel"
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_lbl)
	if slot == GameState.save_slot and not info.is_empty():
		var last := Label.new()
		last.text = "LAST PLAYED"
		last.theme_type_variation = &"SubLabel"
		head.add_child(last)
	v.add_child(head)
	v.add_child(HSeparator.new())

	for line: String in _slot_lines(info, blocked):
		var l := Label.new()
		l.text = line
		l.theme_type_variation = &"SubLabel"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = SLOT_CARD_W - 24.0
		v.add_child(l)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fill)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 4)
	var play := IconButton.create("NEW GAME" if info.is_empty() else "PLAY", "new",
		IconButton.Variant.DEFAULT if info.is_empty() else IconButton.Variant.POSITIVE)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play.disabled = blocked != ""
	if blocked != "":
		play.modulate.a = 0.35
	play.pressed.connect(func() -> void: _play_slot(slot))
	btns.add_child(play)
	if not info.is_empty():
		var del := IconButton.create("", "danger", IconButton.Variant.NEGATIVE)
		del.tooltip_text = "Delete this save"
		del.pressed.connect(func() -> void: _delete_slot(slot))
		btns.add_child(del)
	v.add_child(btns)
	return card

## The save's details, one per line ("Empty", or why it can't be played).
static func _slot_lines(info: Dictionary, blocked: String) -> Array[String]:
	if info.is_empty():
		return ["Empty", "Starts a new game"]
	if blocked != "":
		return [blocked]
	var secs := int(info.get("play_seconds", 0.0))
	var played := "%dh %02dm" % [secs / 3600, (secs / 60) % 60] if secs >= 3600 else "%dm" % (secs / 60)
	var t: int = int(info.get("saved_at", 0.0)) + Time.get_time_zone_from_system().get("bias", 0) * 60
	var d := Time.get_datetime_dict_from_unix_time(t)
	return ["Civilization %d" % int(info.get("civilization_type", 0)), "%s played" % played,
		"Saved %02d.%02d  %02d:%02d" % [d["day"], d["month"], d["hour"], d["minute"]]]

func _play_slot(slot: int) -> void:
	AudioManager.play("click", 0.0)
	var info := GameState.slot_info(slot)
	if info.is_empty():
		_show_intro(func() -> void: GameState.new_game_in(slot))
		return
	if not bool(info.get("ok", false)):
		return
	# the game already loaded at boot just goes on; another slot is opened first
	if slot != GameState.save_slot or not GameState.has_save():
		GameState.open_slot(slot)
	_enter_game()

## Opens the run's first scene. While the solar and galaxy maps are still
## locked (a new game) that is the home planet, straight away: going through
## the galaxy first showed its side panel and the HUD over a black screen for
## a moment before it passed the player on to the planet.
func _enter_game() -> void:
	var home := GameState.get_home_planet()
	if home != null and not GameState.can_view_solar() and not GameState.can_view_galaxy():
		SceneTransition.go("res://scenes/planetary/PlanetaryView.tscn", home)
	else:
		SceneTransition.go("res://scenes/galaxy/GalaxyView.tscn")

func _delete_slot(slot: int) -> void:
	var info := GameState.slot_info(slot)
	if info.is_empty():
		return
	AudioManager.play("click", 0.0)
	ConfirmPanel.ask(self, "Delete slot %d?" % (slot + 1),
		"%s\n\nThis can't be undone." % _slot_text(info), "DELETE", func() -> void:
			GameState.delete_slot(slot)
			_open_saves())

## PLAY DEMO (the browser demo has no saves).
func _on_new_game() -> void:
	AudioManager.play("click", 0.0)
	_show_intro(func() -> void: GameState.delete_save())

## The short goal card before the first scene (scenes/ui/IntroCard.tscn);
## `start` runs on BEGIN, before the first scene opens.
func _show_intro(start: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 235
	add_child(layer)
	var card: Control = (load("res://scenes/ui/IntroCard.tscn") as PackedScene).instantiate()
	card.connect("begun", func() -> void:
		start.call()
		_enter_game())
	layer.add_child(card)

## "Civ 0 // 1h 12m played // 28.10 14:05", "Empty", or why it can't load.
static func _slot_text(info: Dictionary) -> String:
	if info.is_empty():
		return "Empty"
	if not info.get("ok", false):
		return String(info.get("why", "Can't be loaded"))
	var secs := int(info.get("play_seconds", 0.0))
	var played := "%dh %02dm" % [secs / 3600, (secs / 60) % 60] if secs >= 3600 else "%dm" % (secs / 60)
	var t: int = int(info.get("saved_at", 0.0)) + Time.get_time_zone_from_system().get("bias", 0) * 60
	var d := Time.get_datetime_dict_from_unix_time(t)
	return "Civ %d  //  %s played  //  %02d.%02d %02d:%02d" % [int(info.get("civilization_type", 0)), played,
		d["day"], d["month"], d["hour"], d["minute"]]

func _on_settings() -> void:
	HUDManager.show_settings_popup()

func _on_quit() -> void:
	get_tree().quit()
