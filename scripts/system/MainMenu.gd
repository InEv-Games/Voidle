extends Control

const ROTATE_SPEED  := 0.018
const ORBITRON      := "res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf"

const CREDITS_LINES := [
	"Developed by Tufan T. Iskender",
	"Thanks to Irem Iskender",
	"Mira Iskender",
	"Ada Iskender",
	"Adem Ozcan",
	"InEv Games",
]
const CREDITS_HOLD     := 4.2   # seconds per line
const GLITCH_CHARS     := "!@#$%^&*<>?/\\|[]{}~±§"
const GLITCH_STEPS     := 16
const GLITCH_STEP_DUR  := 0.06

var _planet_rect:   ColorRect
var _rotation_off:  float = 0.0
var _font:          Font
var _credits_lbl:   Label
var _credits_idx:   int   = 0
var _play_btn:      Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	anchor_right  = 1.0
	anchor_bottom = 1.0
	HUDManager.set_game_hud(false)
	_font = load(ORBITRON) as Font

	_build_bg()
	_build_stars()
	_build_planet()
	_build_vignette()
	_build_menu()
	_build_credits()

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

func _add_layer(c: Control, depth: float) -> void:
	_layers.append([c, c.position, depth])

func _build_bg() -> void:
	var vp := get_viewport().get_visible_rect().size
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
	bg.material = mat
	add_child(bg)
	_add_layer(bg, PARALLAX_BACKDROP)

# ── Stars (still, twinkling a little) ──────────────────────────────────────

func _build_stars() -> void:
	var vp := get_viewport().get_visible_rect().size
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
	var vp := get_viewport().get_visible_rect().size
	var m := get_viewport().get_mouse_position()
	var target := Vector2(clampf(m.x / vp.x, 0.0, 1.0) - 0.5, clampf(m.y / vp.y, 0.0, 1.0) - 0.5)
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

# ── Planet ─────────────────────────────────────────────────────────────────

func _build_planet() -> void:
	var vp := get_viewport().get_visible_rect().size
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
		mat.set_shader_parameter(key, colors[key])

	_update_light(mat)
	_planet_rect.material = mat

# ── Menu UI ────────────────────────────────────────────────────────────────

func _build_menu() -> void:
	var vp := get_viewport().get_visible_rect().size

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

# ── Glitch credits ────────────────────────────────────────────────────────

func _build_credits() -> void:
	var vp := get_viewport().get_visible_rect().size

	_credits_lbl = Label.new()
	_credits_lbl.text = CREDITS_LINES[0]
	if _font: _credits_lbl.add_theme_font_override("font", _font)
	_credits_lbl.add_theme_font_size_override("font_size", 9)
	_credits_lbl.add_theme_color_override("font_color", Color(UIStyle.color(&"text_muted"), 0.75))
	_credits_lbl.anchor_left   = 1.0
	_credits_lbl.anchor_right  = 1.0
	_credits_lbl.anchor_top    = 1.0
	_credits_lbl.anchor_bottom = 1.0
	_credits_lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_credits_lbl.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	_credits_lbl.offset_right  = -18.0
	_credits_lbl.offset_bottom = -14.0
	_credits_lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	add_child(_credits_lbl)

	_cycle_credits()

func _cycle_credits() -> void:
	await get_tree().create_timer(CREDITS_HOLD).timeout
	if not is_instance_valid(_credits_lbl):
		return
	_credits_idx = (_credits_idx + 1) % CREDITS_LINES.size()
	await _glitch_to(CREDITS_LINES[_credits_idx])
	_cycle_credits()

func _glitch_to(target: String) -> void:
	var rng   := RandomNumberGenerator.new()
	var chars := GLITCH_CHARS
	var orig  := _credits_lbl.text
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
		_credits_lbl.text = out
		await get_tree().create_timer(GLITCH_STEP_DUR).timeout

	if is_instance_valid(_credits_lbl):
		_credits_lbl.text = target

# ── Planet animation ───────────────────────────────────────────────────────

func _update_light(mat: ShaderMaterial) -> void:
	mat.set_shader_parameter("light_direction", LIGHT_DIR.normalized())

func _process(delta: float) -> void:
	_tick_backdrop(delta)
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
	RowReveal.play(_saves_root)

func _close_saves() -> void:
	AudioManager.play("click", 0.0)
	if is_instance_valid(_saves_root):
		_saves_root.queue_free()
	_saves_root = null
	_menu_root.visible = true
	RowReveal.play(_menu_root)

func _input(event: InputEvent) -> void:
	if is_instance_valid(_saves_root) and event is InputEventKey and (event as InputEventKey).pressed \
			and (event as InputEventKey).keycode == KEY_ESCAPE:
		_close_saves()
		get_viewport().set_input_as_handled()

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
## `start` runs on BEGIN, before the galaxy opens.
func _show_intro(start: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 235
	add_child(layer)
	var card: Control = (load("res://scenes/ui/IntroCard.tscn") as PackedScene).instantiate()
	card.connect("begun", func() -> void:
		start.call()
		SceneTransition.go("res://scenes/galaxy/GalaxyView.tscn"))
	layer.add_child(card)

## "Civ 0 · 1h 12m played · 28.10 14:05", "Empty", or why it can't load.
static func _slot_text(info: Dictionary) -> String:
	if info.is_empty():
		return "Empty"
	if not info.get("ok", false):
		return String(info.get("why", "Can't be loaded"))
	var secs := int(info.get("play_seconds", 0.0))
	var played := "%dh %02dm" % [secs / 3600, (secs / 60) % 60] if secs >= 3600 else "%dm" % (secs / 60)
	var t: int = int(info.get("saved_at", 0.0)) + Time.get_time_zone_from_system().get("bias", 0) * 60
	var d := Time.get_datetime_dict_from_unix_time(t)
	return "Civ %d  ·  %s played  ·  %02d.%02d %02d:%02d" % [int(info.get("civilization_type", 0)), played,
		d["day"], d["month"], d["hour"], d["minute"]]

func _on_settings() -> void:
	HUDManager.show_settings_popup()

func _on_quit() -> void:
	get_tree().quit()
