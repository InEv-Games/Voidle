class_name NewGamePreview
extends Control

## What an option means, large and without a background (not even stars): a
## turning globe (the seed's home world and its moon, or another kind of world),
## or a drawing of the star system and later civilization scales. The globes and drawings
## sit in a SessionPrep.PREVIEW square centred along the top.
## Locked looks get a LOCKED tag. A new look doesn't cut in: the shown one
## blurs and fades out over SWAP_OUT (shaders/blur_swap.gdshader), the new one
## comes in from the blur and sharpens over SWAP_IN; hovering on meanwhile only
## changes what comes in. The first look comes in the same way (reveal).
## Part of NewGamePanel (scenes/ui/NewGamePanel.tscn).

const SWAP_OUT := 0.225
const SWAP_IN := 0.425
const BLUR_SHADER := preload("res://shaders/blur_swap.gdshader")
const BLUR_SPILL := 60.0   # the blur reaches this far past the square (a globe's blur isn't cut)
const BRIGHT := 0.85
const GALAXY_DOT_COUNT := 224
const ORBIT_COLOR := Color(0.6, 0.75, 1.0, 0.18)
const GALAXY_ARM_COLOR := Color(0.57, 0.66, 1.0)
const SOLAR_INNER_PLANET_COUNT := 4
const SOLAR_PLANET_TYPES: Array[PlanetData.Type] = [
	PlanetData.Type.BARREN, PlanetData.Type.ARID, PlanetData.Type.ICE, PlanetData.Type.VOLCANIC,
	PlanetData.Type.GAS_GIANT, PlanetData.Type.GAS_GIANT, PlanetData.Type.ICE, PlanetData.Type.GAS_GIANT,
]
var _globes: Array = []   # [ColorRect, ShaderMaterial, spin rad/s, rotation]
var _mode := "globe"
var _locked := false
var _solar_star_type := SolarData.StarType.YELLOW_DWARF
var _home_idx := 0
var _target_scale := 3
var _orbit_points := PackedVector2Array()
var _galaxy_arms: Array[PackedVector2Array] = []
var _galaxy_dots := PackedVector2Array()
var _omega_outline := PackedVector2Array()
var _t := 0.0
var _square: Control   # the globes' square, centred along the top

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 65:
		_orbit_points.append(Vector2.from_angle(TAU * float(i) / 64.0))
	_square = Control.new()
	_square.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_square.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_square.offset_left = -SessionPrep.PREVIEW * 0.5
	_square.offset_right = SessionPrep.PREVIEW * 0.5
	_square.offset_bottom = SessionPrep.PREVIEW
	_square.draw.connect(_draw_square)
	add_child(_square)
	# the square: [its drawings,] the globes, a copy of the screen, the blur
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_square.add_child(_content)
	var bbc := BackBufferCopy.new()
	bbc.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	_square.add_child(bbc)
	_blur = ColorRect.new()
	_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blur.offset_left = -BLUR_SPILL
	_blur.offset_top = -BLUR_SPILL
	_blur.offset_right = BLUR_SPILL
	_blur.offset_bottom = BLUR_SPILL
	_blur_mat = ShaderMaterial.new()
	_blur_mat.shader = BLUR_SHADER
	_blur.material = _blur_mat
	_square.add_child(_blur)
	_set_blur(0.0)

var _key := ""        # the look shown
var _apply: Callable  # builds the look asked for last
var _want := ""       # …and its key
var _swap: Tween = null
var _content: Control       # the globes
var _blur: ColorRect        # the blur over them, while swapping
var _blur_mat: ShaderMaterial
var _blur_p := 0.0
var _held := false          # coming in (reveal): a new look just takes the old one's place

func _set_blur(v: float) -> void:
	_blur_p = v
	_blur_mat.set_shader_parameter("progress", v)
	_blur.visible = v > 0.001
	# a focus pull: the look goes soft first, then fades out over the
	# second half (no sudden drop where the old one is swapped for the new)
	var a := 1.0 - smoothstep(0.25, 1.0, v)
	_content.modulate.a = a
	_square.self_modulate.a = a   # …and its drawings

## The preview's first coming: after `delay`, the look fades in and comes
## out of the blur over `dur`.
func reveal(delay: float, dur: float) -> void:
	_held = true
	_set_blur(1.0)
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "modulate:a", 1.0, dur * 0.5).set_delay(delay)
	tw.tween_method(_set_blur, 1.0, 0.0, dur).set_delay(delay)
	tw.chain().tween_callback(func() -> void: _held = false)

## Shows the look `key` (built by `apply`), through the swap transition.
func _change(key: String, apply: Callable) -> void:
	_want = key
	_apply = apply
	if _key == "" or _held or not is_inside_tree():   # the first look, or while it comes in: at once
		_key = key
		apply.call()
		return
	if _swap != null:
		_swap.kill()
	_swap = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if key == _key:   # back to what is shown: it settles again
		_swap.tween_method(_set_blur, _blur_p, 0.0, maxf(SWAP_IN * _blur_p, 0.01))
		return
	_swap.tween_method(_set_blur, _blur_p, 1.0, maxf(SWAP_OUT * (1.0 - _blur_p), 0.01))
	_swap.tween_callback(func() -> void:
		_key = _want
		_apply.call())
	_swap.tween_method(_set_blur, 1.0, 0.0, SWAP_IN)

func _process(delta: float) -> void:
	_t += delta
	for g: Array in _globes:
		g[3] = fposmod(float(g[3]) + float(g[2]) * delta, TAU)
		(g[1] as ShaderMaterial).set_shader_parameter("rotation_offset", g[3])
	if _mode != "globe":
		_square.queue_redraw()

func _clear() -> void:
	for g: Array in _globes:
		(g[0] as Node).queue_free()
	_globes.clear()
	_galaxy_arms.clear()
	_galaxy_dots.clear()
	_omega_outline.clear()

## The seed's home world with its moon (`moon`: rocky / icy / twin).
func show_home(s: int, moon: String, locked := false) -> void:
	var lk := locked and moon != "rocky"
	_change("home:%d:%s:%s" % [s, moon, lk], _home.bind(s, moon, lk))

## Another kind of world as a start (locked).
func show_world(s: int, type: PlanetData.Type) -> void:
	_change("world:%d:%d" % [s, type], _world.bind(s, type))

## The seed's star system is the expansion target at Type 1.
func show_solar(s: int) -> void:
	_change("solar:%d" % s, _solar_of.bind(s))

## The civilization's goal uses the scale of the tier above the slider selection.
func show_civilization_target(s: int, target_scale: int) -> void:
	_change("target:%d:%d" % [s, target_scale], _civilization_target.bind(s, target_scale))

func _home(s: int, moon: String, locked: bool) -> void:
	_clear()
	_mode = "globe"
	_locked = locked
	var home := PlanetData.from_seed_as_type(s, PlanetData.Type.TERRAN)
	_add_globe(home, Vector2(0.44, 0.52), 0.74, 0.12)
	match moon:
		"icy":
			var m := PlanetData.from_seed_as_type(s ^ 0x4D6F6F6E, PlanetData.Type.ICE)
			_add_globe(m, Vector2(0.82, 0.2), 0.2, 0.2)
		"twin":
			_add_globe(PlanetData.make_moon(s ^ 0x4D6F6F6E), Vector2(0.84, 0.18), 0.18, 0.2)
			_add_globe(PlanetData.make_moon(s ^ 0x7A11), Vector2(0.86, 0.80), 0.13, 0.25)
		_:
			_add_globe(PlanetData.make_moon(s ^ 0x4D6F6F6E), Vector2(0.84, 0.18), 0.2, 0.2)
	_square.queue_redraw()

func _world(s: int, type: PlanetData.Type) -> void:
	_clear()
	_mode = "globe"
	_locked = true
	_add_globe(PlanetData.from_seed_as_type(s ^ 0x5EED, type), Vector2(0.5, 0.5), 0.82, 0.12)
	_square.queue_redraw()

func _solar_of(s: int) -> void:
	_clear()
	_mode = "solar"
	_locked = true
	var galaxy := GalaxyData.from_seed(s ^ 0xABCDEF)
	_solar_star_type = galaxy.types[galaxy.home_idx] as SolarData.StarType if not galaxy.types.is_empty() \
		else SolarData.StarType.YELLOW_DWARF
	var rng := RandomNumberGenerator.new()
	rng.seed = s ^ 0x5678
	_home_idx = rng.randi_range(0, SOLAR_INNER_PLANET_COUNT - 1)
	_square.queue_redraw()

func _civilization_target(s: int, target_scale: int) -> void:
	_clear()
	_locked = true
	_target_scale = target_scale
	_mode = "civilization"
	match target_scale:
		3, 4, 5: _build_galaxy(s)
		7: _build_omega_outline()
	_square.queue_redraw()

func _build_galaxy(s: int) -> void:
	for arm in 2:
		var points := PackedVector2Array()
		for i in 40:
			var radius := lerpf(0.12, 0.94, float(i) / 39.0)
			points.append(Vector2.from_angle(float(arm) * PI + radius * 5.5) * radius)
		_galaxy_arms.append(points)
	var rng := RandomNumberGenerator.new()
	rng.seed = s ^ 0xC171
	for i in GALAXY_DOT_COUNT:
		var radius := lerpf(0.05, 0.98, pow(rng.randf(), 1.2))
		var angle := float(rng.randi_range(0, 1)) * PI + radius * 5.5 + rng.randfn(0.0, 0.22)
		_galaxy_dots.append(Vector2.from_angle(angle) * radius)

func _build_omega_outline() -> void:
	# An outer and inner arc joined by two broad feet form a single outline.
	var centre := Vector2(0.0, -0.07)
	for i in 37:
		var angle := deg_to_rad(52.0 - 284.0 * float(i) / 36.0)
		_omega_outline.append(centre + Vector2.from_angle(angle) * 0.34)
	_omega_outline.append_array(PackedVector2Array([
		Vector2(-0.17, 0.245), Vector2(-0.35, 0.245), Vector2(-0.35, 0.35),
		Vector2(-0.075, 0.35), Vector2(-0.075, 0.22),
	]))
	for i in 37:
		var angle := deg_to_rad(-232.0 + 284.0 * float(i) / 36.0)
		_omega_outline.append(centre + Vector2.from_angle(angle) * 0.21)
	_omega_outline.append_array(PackedVector2Array([
		Vector2(0.075, 0.22), Vector2(0.075, 0.35), Vector2(0.35, 0.35),
		Vector2(0.35, 0.245), Vector2(0.17, 0.245),
	]))

func _add_globe(data: PlanetData, centre: Vector2, diameter: float, spin: float) -> void:
	var side := SessionPrep.PREVIEW
	var disc := side * diameter
	var rect_side := disc / (0.42 * 2.0)
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size = Vector2(rect_side, rect_side)
	r.position = centre * side - r.size * 0.5
	var mat := SessionPrep._globe_material(data, rect_side, Vector3(-0.6, -0.45, 0.65).normalized(), BRIGHT)
	r.material = mat
	_content.add_child(r)
	_globes.append([r, mat, spin, randf() * TAU])

## The star system, civilization drawings and LOCKED badge swap with the square.
func _draw_square() -> void:
	var side := SessionPrep.PREVIEW
	match _mode:
		"solar": _draw_solar(side)
		"civilization": _draw_civilization(side)
	if _locked:
		var font := get_theme_default_font()
		var txt := "LOCKED"
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var box := Rect2(Vector2(side - w - 18.0, 8.0), Vector2(w + 10.0, 18.0))
		_square.draw_rect(box, Color(0.04, 0.06, 0.12, 0.85))
		_square.draw_rect(box, UIStyle.color(&"bad"), false, 1.0)
		_square.draw_string(font, box.position + Vector2(5.0, 13.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIStyle.color(&"bad"))

func _draw_solar(side: float) -> void:
	var c := Vector2.ONE * side * 0.5
	var cols := SolarData.get_star_colors(_solar_star_type)
	var core: Vector3 = cols["core"]
	var corona: Vector3 = cols["corona"]
	_square.draw_circle(c, side * 0.075, Color(corona.x, corona.y, corona.z, 0.35))
	_square.draw_circle(c, side * 0.05, Color(core.x, core.y, core.z))
	var plane := Transform2D(0.0, Vector2(1.0, 0.42), 0.0, c)
	var count := SOLAR_PLANET_TYPES.size()
	for i in count:
		var orbit_radius := side * lerpf(0.17, 0.45, float(i) / float(count - 1))
		_draw_orbit(plane, orbit_radius, ORBIT_COLOR)
		var ang := _t * (0.5 / float(i + 1)) + float(i) * 2.1
		var pp := plane * (Vector2.from_angle(ang) * orbit_radius)
		var planet_type := PlanetData.Type.TERRAN if i == _home_idx else SOLAR_PLANET_TYPES[i]
		var size_fraction := 0.011 + float(i % 3) * 0.002
		if i >= SOLAR_INNER_PLANET_COUNT:
			size_fraction += 0.007
		var r := side * size_fraction
		_square.draw_circle(pp, r, SessionPrep._type_color(planet_type))
		if i == _home_idx:
			_square.draw_arc(pp, r + 4.0, 0.0, TAU, 24, UIStyle.color(&"accent"), 1.0)

func _draw_orbit(plane: Transform2D, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for point: Vector2 in _orbit_points:
		points.append(plane * (point * radius))
	_square.draw_polyline(points, color, 1.0, true)

func _draw_civilization(side: float) -> void:
	var centre := Vector2.ONE * side * 0.5
	var accent := UIStyle.color(&"accent")
	var stellar_colors := SolarData.get_star_colors(SolarData.StarType.YELLOW_DWARF)
	var core: Vector3 = stellar_colors["core"]
	var stars := Color(core.x, core.y, core.z, 0.82)
	match _target_scale:
		3:
			_draw_galaxy(centre, side * 0.44, -0.45, _t * 0.28, GALAXY_ARM_COLOR, stars)
		4:
			_draw_universe(centre, side * 0.44, -0.24, _t * 0.20, GALAXY_ARM_COLOR, stars)
		5:
			var plane := Transform2D(-0.18, Vector2(1.0, 0.74), 0.0, centre)
			var orbit_radius := side * 0.27
			_draw_orbit(plane, orbit_radius, ORBIT_COLOR)
			for i in 3:
				var angle := _t * 0.13 + TAU * float(i) / 3.0
				var pos := plane * (Vector2.from_angle(angle) * orbit_radius)
				var tilt := float(i - 1) * 0.62 + sin(angle) * 0.18
				var radius := side * (0.17 if i == 0 else 0.135)
				var tint := GALAXY_ARM_COLOR.lerp(accent, float(i) * 0.35)
				_draw_universe(pos, radius, tilt, _t * (0.21 + float(i) * 0.04), tint, stars)
		6:
			_draw_tesseract(centre, side, accent, stars)
		7:
			_draw_omega(centre, side, accent, stars)

func _draw_galaxy(centre: Vector2, radius: float, tilt: float, spin: float, tint: Color, core: Color) -> void:
	var plane := Transform2D(tilt, Vector2(radius, radius * 0.58), 0.0, centre)
	var disc := plane * Transform2D(spin, Vector2.ZERO)
	for arm: PackedVector2Array in _galaxy_arms:
		var points := PackedVector2Array()
		for point: Vector2 in arm:
			points.append(disc * point)
		_square.draw_polyline(points, Color(tint, 0.11), maxf(radius * 0.13, 1.5), true)
		_square.draw_polyline(points, Color(tint, 0.33), maxf(radius * 0.04, 1.0), true)
	var stride := maxi(1, ceili(115.0 / radius))
	var dot_radius := clampf(radius * 0.007, 0.65, 1.55)
	for i in range(0, _galaxy_dots.size(), stride):
		var color := core if i % 5 == 0 else tint.lightened(0.28)
		_square.draw_circle(disc * _galaxy_dots[i], dot_radius, Color(color, 0.66 + float(i % 3) * 0.11))
	_square.draw_circle(centre, radius * 0.13, Color(tint, 0.14))
	_square.draw_circle(centre, radius * 0.08, Color(core, 0.38))
	_square.draw_circle(centre, maxf(radius * 0.04, 1.4), core)

func _draw_universe(centre: Vector2, radius: float, tilt: float, spin: float, tint: Color, core: Color) -> void:
	var plane := Transform2D(tilt, Vector2(1.0, 0.75), 0.0, centre)
	_draw_orbit(plane, radius, Color(tint, 0.22))
	_draw_orbit(plane, radius * 0.83, ORBIT_COLOR)
	_draw_orbit(plane, radius * 0.59, ORBIT_COLOR)
	_draw_galaxy(centre, radius * 0.20, tilt - 0.30, spin * 1.6, tint, core)
	var count := 6 if radius > 100.0 else 3
	for i in count:
		var angle := spin + TAU * float(i) / float(count)
		var orbit_radius := radius * (0.59 if i % 2 == 0 else 0.83)
		var pos := plane * (Vector2.from_angle(angle) * orbit_radius)
		var size := radius * (0.115 + float(i % 3) * 0.024)
		_draw_galaxy(pos, size, tilt + float(i) * 0.48, spin * 1.3 + float(i) * 1.6, tint, core)

func _draw_tesseract(centre: Vector2, side: float, accent: Color, stars: Color) -> void:
	for i in 3:
		var tilt := _t * 0.09 + PI * float(i) / 3.0
		var plane := Transform2D(tilt, Vector2(1.0, 0.44), 0.0, centre)
		_draw_orbit(plane, side * 0.39, Color(accent, 0.13))
	# Four bits select the corner's coordinates. An edge flips exactly one bit.
	var points := PackedVector2Array()
	var phase := _t * 0.32
	var phase_cos := cos(phase)
	var phase_sin := sin(phase)
	for i in 16:
		var p := Vector3(1.0 if (i & 1) != 0 else -1.0,
			1.0 if (i & 2) != 0 else -1.0, 1.0 if (i & 4) != 0 else -1.0)
		var w := 1.0 if (i & 8) != 0 else -1.0
		var x := p.x * phase_cos - w * phase_sin
		w = p.x * phase_sin + w * phase_cos
		p.x = x
		p = p.rotated(Vector3.UP, 0.58 + _t * 0.16).rotated(Vector3.RIGHT, -0.38) / (1.95 - w * 0.50)
		points.append(centre + Vector2(p.x, p.y) * (side * 0.63 / (3.1 - p.z)))
	_square.draw_circle(centre, side * 0.036, Color(accent, 0.20))
	_square.draw_circle(centre, side * 0.012, stars)
	for i in points.size():
		for axis: int in [1, 2, 4, 8]:
			var other := i ^ axis
			if other > i:
				var line := Color(accent, 0.48) if axis == 8 else Color(ORBIT_COLOR, 0.51)
				_square.draw_line(points[i], points[other], line, 1.0, true)
	for point: Vector2 in points:
		_square.draw_circle(point, 2.1, stars)

func _draw_omega(centre: Vector2, side: float, accent: Color, stars: Color) -> void:
	var yaw := sin(_t * 0.72) * 0.55
	var depth := Vector2(sin(yaw) * 0.075, 0.017) * side
	var face := PackedVector2Array()
	var back := PackedVector2Array()
	var colors := PackedColorArray()
	for point: Vector2 in _omega_outline:
		var perspective := 1.0 / (1.0 + point.x * sin(yaw) * 0.48)
		var pos := centre + Vector2(point.x * cos(yaw), point.y + 0.03) * (side * 1.06 * perspective)
		face.append(pos)
		back.append(pos + depth)
		var mix_amount := lerpf(0.22, 0.70, inverse_lerp(-0.41, 0.35, point.y))
		colors.append(Color(stars, 1.0).lerp(Color(accent, 1.0), mix_amount))
	var outline := face.duplicate()
	outline.append(face[0])
	_square.draw_colored_polygon(back, Color(accent, 0.35))
	_square.draw_polyline(outline, Color(accent, 0.20), 11.0, true)
	_square.draw_polygon(face, colors)
	_square.draw_polyline(outline, Color(stars, 0.86), 1.5, true)
