extends Control

## Neighbouring bodies shown in the planet view's top-right corner when the
## player zooms out past the planet (once the Local System is unlocked): the
## home world's moons, or — from a moon — its planet and sibling moons. More
## than VISIBLE bodies scroll like a slider. Hover names a body; clicking one
## asks PlanetaryView to switch to it (body_clicked).

signal body_clicked(pd: PlanetData, from_rect: Rect2)

const VISIBLE := 3
const GAP := 14.0
const TOP := 74.0          # clear of the resource bar
const RIGHT := 18.0
## Where the bodies sit when fully zoomed in: off past the top-right corner —
## zooming out pulls them in along this offset, as if the camera backs away.
const SLIDE := Vector2(300.0, -260.0)

var bodies: Array[PlanetData] = []
## 0..1 — how far the view is zoomed out (drives alpha and input).
var fade := 0.0
## The sun's angle (PlanetRenderer.light_angle) — one sun lights every body.
var light_angle := 0.0

var _views: Array[ColorRect] = []
var _sizes: Array[float] = []
var _base_pos: Array[Vector2] = []
var _page := 0
var _prev_btn: Button
var _next_btn: Button
var _spin := 0.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_to_group("companion_bodies")

## Lowest screen y the bodies take up while shown (0 when hidden), so other
## top-right UI (the objectives panel) can sit below them.
func occupied_bottom() -> float:
	if not is_visible_in_tree() or fade < 0.05:
		return 0.0
	var bottom := 0.0
	for v in _views:
		if v.visible:
			bottom = maxf(bottom, v.get_global_rect().end.y)
	if _prev_btn != null and _prev_btn.visible:
		bottom = maxf(bottom, _prev_btn.get_global_rect().end.y)
	return bottom

## `main` is the body being viewed; `parent` its planet when it's a moon.
func setup(list: Array[PlanetData], parent: PlanetData) -> void:
	for v in _views:
		v.queue_free()
	_views.clear()
	_sizes.clear()
	bodies = list
	_page = 0
	for pd: PlanetData in list:
		var px := body_px(pd, parent)
		var v := _make_view(pd, px)
		add_child(v)
		_views.append(v)
		_sizes.append(px)
	if _prev_btn == null:
		_prev_btn = _arrow("‹", -1)
		_next_btn = _arrow("›", 1)
	_layout()

static func body_px(pd: PlanetData, parent: PlanetData) -> float:
	return 150.0 if pd == parent else 96.0

## Where each body of `list` will sit (local rects, first page) — used to
## animate a body into its corner slot before the view switches.
func predict_rects(list: Array[PlanetData], parent: PlanetData) -> Dictionary:
	var out := {}
	var x := size.x - RIGHT
	for i in mini(list.size(), VISIBLE):
		var s := body_px(list[i], parent)
		x -= s
		out[list[i]] = Rect2(Vector2(x, TOP), Vector2(s, s))
		x -= GAP
	return out

func _arrow(txt: String, dir: int) -> Button:
	var b := Button.new()
	b.text = txt
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", UIStyle.color(&"text"))
	b.pressed.connect(func() -> void:
		_page = clampi(_page + dir, 0, maxi(0, bodies.size() - VISIBLE))
		AudioManager.play("click")
		_layout())
	add_child(b)
	return b

func _make_view(pd: PlanetData, px: float) -> ColorRect:
	var r := ColorRect.new()
	r.size = Vector2(px, px)
	r.material = _material_for(pd, px)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	r.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	r.mouse_entered.connect(func() -> void:
		if fade < 0.5:
			return
		AudioManager.play("hover")
		TooltipManager.show_tip(pd.planet_name, _status_text(pd)))
	r.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	r.gui_input.connect(func(e: InputEvent) -> void:
		if fade < 0.5:
			return
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
				and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			TooltipManager.hide_tip()
			accept_event()
			body_clicked.emit(pd, r.get_global_rect()))
	return r

func _status_text(pd: PlanetData) -> String:
	var pp := GameState.get_planet(pd.seed)
	var kind: String = String(PlanetData.Type.keys()[pd.planet_type]).capitalize()
	var status := "Not colonized"
	if pp.is_colonized:
		status = "Colony  ·  Lv %d" % pp.level
	elif pp.is_colonizing:
		status = "Lander in transit"
	elif pd.planet_type == PlanetData.Type.MOON and not GameState.moon_unlocked:
		status = "Research Lunar Program to colonize"
	return "%s\n%s\n\n[color=#8a93b0]Click to view[/color]" % [kind, status]

func spin() -> float:
	return _spin

## Light vector for a body whose sun angle + local time + spin is `eff`
## (PlanetRenderer._update_light_direction, untilted).
static func light_dir(eff: float) -> Vector3:
	return Vector3(cos(eff) * 0.85, -0.45, sin(eff) * 0.55).normalized()

## Same look as the Local System view's bodies (SolarView._build_local_star).
static func _material_for(pd: PlanetData, px: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(PlanetData.get_shader_path(pd.planet_type))
	mat.set_shader_parameter("planet_radius", 0.40)
	mat.set_shader_parameter("pixel_count", px * 0.5)
	mat.set_shader_parameter("aspect_ratio", 1.0)
	mat.set_shader_parameter("seed", pd.seed)
	mat.set_shader_parameter("terrain_roughness", pd.terrain_roughness)
	mat.set_shader_parameter("rotation_offset", 0.0)
	mat.set_shader_parameter("night_shadow", SettingsManager.night_shadow)   # same night as the globe
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

## Lays the visible page out right-to-left from the top-right corner.
func _layout() -> void:
	var x := size.x - RIGHT
	var shown := 0
	_base_pos.resize(_views.size())
	for i in _views.size():
		var on := i >= _page and i < _page + VISIBLE
		_views[i].visible = on
		if not on:
			continue
		var s := _sizes[i]
		x -= s
		_base_pos[i] = Vector2(x, TOP)
		_views[i].position = Vector2(x, TOP)
		x -= GAP
		shown += 1
	var paged := _views.size() > VISIBLE
	_prev_btn.visible = paged and _page > 0
	_next_btn.visible = paged and _page < _views.size() - VISIBLE
	_prev_btn.position = Vector2(x - 18.0, TOP + 30.0)
	_next_btn.position = Vector2(size.x - RIGHT + 2.0, TOP + 30.0)

## Screen-space centre of a body's view (for rockets), or Vector2.INF.
func center_of(pd: PlanetData) -> Vector2:
	var i := bodies.find(pd)
	if i < 0 or not _views[i].visible:
		return Vector2.INF
	return _views[i].get_global_rect().get_center()

func radius_of(pd: PlanetData) -> float:
	var i := bodies.find(pd)
	return _sizes[i] * 0.40 if i >= 0 else 0.0

func _process(delta: float) -> void:
	modulate.a = clampf(fade * 1.6, 0.0, 1.0)
	visible = fade > 0.01 and not bodies.is_empty()
	# slide in from beyond the corner as the view zooms out
	var off := SLIDE * pow(1.0 - fade, 1.5)
	for i in _views.size():
		if i < _base_pos.size():
			_views[i].position = _base_pos[i] + off
	_spin = fposmod(_spin + delta * 0.08, TAU)
	for i in _views.size():
		var v := _views[i]
		(v.material as ShaderMaterial).set_shader_parameter("rotation_offset", _spin)
		(v.material as ShaderMaterial).set_shader_parameter("night_shadow", SettingsManager.night_shadow)
		(v.material as ShaderMaterial).set_shader_parameter("light_direction",
			light_dir(light_angle + bodies[i].local_time_offset + _spin))
		v.mouse_filter = Control.MOUSE_FILTER_STOP if fade > 0.5 else Control.MOUSE_FILTER_IGNORE

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _prev_btn != null:
		_layout()
