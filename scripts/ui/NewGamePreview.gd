class_name NewGamePreview
extends Control

## What an option means, large and without a background (not even stars): a
## turning globe (the seed's home world and its moon, or another kind of world),
## or a drawn tease of the seed's star system / galaxy. The globes and drawings
## sit in a SessionPrep.PREVIEW square centred along the top.
## Locked looks get a LOCKED tag. A new look doesn't cut in: the shown one
## blurs and fades out over SWAP_OUT (shaders/blur_swap.gdshader), the new one
## comes in from the blur and sharpens over SWAP_IN; hovering on meanwhile only
## changes what comes in. The first look comes in the same way (reveal).
## Part of NewGamePanel (scenes/ui/NewGamePanel.tscn).

const SWAP_OUT := 0.45
const SWAP_IN := 0.85
const BLUR_SHADER := preload("res://shaders/blur_swap.gdshader")
const BLUR_SPILL := 60.0   # the blur reaches this far past the square (a globe's blur isn't cut)
const BRIGHT := 0.85
var _globes: Array = []   # [ColorRect, ShaderMaterial, spin rad/s, rotation]
var _mode := "globe"
var _locked := false
var _solar: SolarData = null
var _home_idx := 0
var _galaxy: GalaxyData = null
var _t := 0.0
var _square: Control   # the globes' square, centred along the top

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_solar = null
	_galaxy = null

## The seed's home world with its moon (`moon`: rocky / icy / twin).
func show_home(s: int, moon: String, locked := false) -> void:
	var lk := locked and moon != "rocky"
	_change("home:%d:%s:%s" % [s, moon, lk], _home.bind(s, moon, lk))

## Another kind of world as a start (locked).
func show_world(s: int, type: PlanetData.Type) -> void:
	_change("world:%d:%d" % [s, type], _world.bind(s, type))

## The seed's own star system, drawn (Civilization 1's tease).
func show_solar(s: int) -> void:
	_change("solar:%d" % s, _solar_of.bind(s))

## The seed's galaxy, drawn (Civilization 2's tease).
func show_galaxy(s: int) -> void:
	_change("galaxy:%d" % s, _galaxy_of.bind(s))

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
	var g := GalaxyData.from_seed(s ^ 0xABCDEF)
	_solar = SolarData.from_seed(g.seeds[g.home_idx] if not g.seeds.is_empty() else s ^ 0x1234, true)
	_solar.star_type = g.types[g.home_idx] as SolarData.StarType if not g.types.is_empty() else _solar.star_type
	var rng := RandomNumberGenerator.new()
	rng.seed = s ^ 0x5678
	_home_idx = rng.randi() % maxi(_solar.planets.size(), 1)
	_square.queue_redraw()

func _galaxy_of(s: int) -> void:
	_clear()
	_mode = "galaxy"
	_locked = true
	_galaxy = GalaxyData.from_seed(s ^ 0xABCDEF)
	_square.queue_redraw()

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

## The look's drawings (star system, galaxy, LOCKED), on the square: they
## swap with it.
func _draw_square() -> void:
	var side := SessionPrep.PREVIEW
	match _mode:
		"solar": _draw_solar(side)
		"galaxy": _draw_galaxy(side)
	if _locked:
		var font := get_theme_default_font()
		var txt := "LOCKED"
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var box := Rect2(Vector2(side - w - 18.0, 8.0), Vector2(w + 10.0, 18.0))
		_square.draw_rect(box, Color(0.04, 0.06, 0.12, 0.85))
		_square.draw_rect(box, UIStyle.color(&"bad"), false, 1.0)
		_square.draw_string(font, box.position + Vector2(5.0, 13.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIStyle.color(&"bad"))

func _draw_solar(side: float) -> void:
	if _solar == null:
		return
	var c := Vector2(side, side) * 0.5
	var cols := SolarData.get_star_colors(_solar.star_type)
	var core: Vector3 = cols["core"]
	var corona: Vector3 = cols["corona"]
	_square.draw_circle(c, side * 0.075, Color(corona.x, corona.y, corona.z, 0.35))
	_square.draw_circle(c, side * 0.05, Color(core.x, core.y, core.z))
	var n := _solar.planets.size()
	for i in n:
		var rx := side * (0.12 + 0.36 * float(i + 1) / float(maxi(n, 1)))
		var ry := rx * 0.42
		var pts := PackedVector2Array()
		for k in 65:
			var a := TAU * float(k) / 64.0
			pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
		_square.draw_polyline(pts, Color(0.6, 0.75, 1.0, 0.18), 1.0)
		var ang := _t * (0.5 / float(i + 1)) + float(i) * 2.1
		var pp := c + Vector2(cos(ang) * rx, sin(ang) * ry)
		var pd: PlanetData = _solar.planets[i]
		var r := side * (0.022 if pd.planet_type == PlanetData.Type.GAS_GIANT else 0.013)
		_square.draw_circle(pp, r, SessionPrep._type_color(PlanetData.Type.TERRAN if i == _home_idx else pd.planet_type))
		if i == _home_idx:
			_square.draw_arc(pp, r + 4.0, 0.0, TAU, 24, UIStyle.color(&"accent"), 1.0)

func _draw_galaxy(side: float) -> void:
	if _galaxy == null or _galaxy.positions.is_empty():
		return
	var lo := _galaxy.positions[0]
	var hi := lo
	for v: Vector2 in _galaxy.positions:
		lo = Vector2(minf(lo.x, v.x), minf(lo.y, v.y))
		hi = Vector2(maxf(hi.x, v.x), maxf(hi.y, v.y))
	var span := maxf(hi.x - lo.x, hi.y - lo.y)
	if span <= 0.0:
		return
	var spin := _t * 0.05
	var mid := (lo + hi) * 0.5
	var to_px := func(v: Vector2) -> Vector2:
		var q := ((v - mid) / span).rotated(spin)
		return Vector2(side, side) * 0.5 + Vector2(q.x, q.y * 0.6) * side * 0.86
	for l: Vector2i in _galaxy.links:
		_square.draw_line(to_px.call(_galaxy.positions[l.x]), to_px.call(_galaxy.positions[l.y]),
			Color(0.55, 0.7, 1.0, 0.16), 1.0)
	for i in _galaxy.positions.size():
		var pp: Vector2 = to_px.call(_galaxy.positions[i])
		var cols := SolarData.get_star_colors(_galaxy.types[i] as SolarData.StarType)
		var core: Vector3 = cols["core"]
		_square.draw_circle(pp, 1.8, Color(core.x, core.y, core.z, 0.9))
		if i == _galaxy.home_idx:
			_square.draw_arc(pp, 5.0, 0.0, TAU, 20, UIStyle.color(&"accent"), 1.0)
