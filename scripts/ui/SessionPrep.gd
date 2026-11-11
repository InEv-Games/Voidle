class_name SessionPrep
extends RefCounted

## NEW GAME's preparation window (11.11): before the game starts the player
## picks the start, then BEGIN. Left: a square preview (the home world of the
## seed, turning, with its moon) and the seed (typed or RANDOM). Right:
##   START WORLD   the home world's kind. Only the Terran world for now; the
##                 others open across games once a City stands on such a world
##                 (SettingsManager.unlocked_starts), played in a later build.
##   MOON          the home world's moon. Only the rocky moon for now (locked).
##   CIVILIZATION  where the run begins. Only Civilization 0 for now (locked);
##                 hovering the others teases their scale in the preview (the
##                 seed's own star system, its galaxy).
##   HEAD START    one of BOONS: a small push in one direction.
##   TUTORIAL      the small box by BEGIN: guided (the advisor leads) or the
##                 optional checklist, which can be skipped for its rewards.
## Hovering an option shows it in the preview; leaving shows the choice again.
## The choices go to GameState.pending_setup (the seed is read by delete_save,
## the rest by _apply_new_game_start).

const LAYER := 236
const PREVIEW := 236.0   # the preview square (px)

## Start worlds: id → [title, icon, text, playable in this build].
const WORLDS := {
	"terran": ["TERRAN WORLD", "planet", "Seas, forests and mountains: the cradle of the colony.", true],
	"red":    ["RED WORLD", "planet", "Found a City on a red desert world to start there.", false],
	"ice":    ["ICE WORLD", "planet", "Found a City on an ice world to start there.", false],
}
const WORLD_ORDER := ["terran", "red", "ice"]
## Moons: id → [title, icon, text, open].
const MOONS := {
	"rocky": ["ROCKY MOON", "moon", "A grey, airless moon close by: the colony's first step off-world.", true],
	"icy":   ["ICY MOON", "moon", "A frozen moon with water under its crust. Comes with later civilizations.", false],
	"twin":  ["TWIN MOONS", "moon", "Two moons in one sky. Comes with later civilizations.", false],
}
const MOON_ORDER := ["rocky", "icy", "twin"]
## Civilizations: id → [title, icon, text, open].
const CIVS := {
	"c0": ["CIVILIZATION 0", "city", "One world and its moon: grow a colony up to its final rocket.", true],
	"c1": ["CIVILIZATION 1", "explore", "Launch the final rocket to unlock: the whole star system is yours to settle.", false],
	"c2": ["CIVILIZATION 2", "map", "The stars beyond: a galaxy to cross. Comes after Civilization 1.", false],
}
const CIV_ORDER := ["c0", "c1", "c2"]

## Head starts: id → [title, icon, what it gives].
const BOONS := {
	"":         ["STANDARD", "city", "A little more to begin with:"],   # + STANDARD_BONUS in icons
	"merchant": ["TRADER", "trade", "Trade Access is researched: buy and sell from the first day."],
	"industry": ["INDUSTRY", "factory", "Mining Operations and Basic Processing are researched, and your first Production District is free."],
	"gifted":   ["GIFTED WORLD", "planet", "Your home world opens its second trait at once: pick one of three."],
}
const BOON_ORDER := ["", "merchant", "industry", "gifted"]

## The worlds' noise reads the seed as a float offset: seeds stay in this
## range. Anything typed (a long number, a word) is folded into it (seed_of).
const SEED_MIN := 1000
const SEED_MAX := 99999
const NAME_MAX := 20

static var _popup: ModalPopup = null

## Opens the window; `begin` runs after the choices are stored (BEGIN).
static func open(host: Node, begin: Callable) -> void:
	if _popup != null and is_instance_valid(_popup):
		_popup.close()
	var p := ModalPopup.open(host, "New Game", "new", "", LAYER)
	_popup = p
	p.use_hero("Prepare your colony", "NEW GAME")
	p.closed.connect(func() -> void:
		TooltipManager.hide_tip()
		_popup = null)
	var choice := {"world": "terran", "moon": "rocky", "civ": "c0", "boon": "",
		"tutorial": not SettingsManager.tutorial_ever_done, "seed": SEED_MIN, "seed_text": _random_seed_text(), "name": ""}

	var main := HBoxContainer.new()
	main.add_theme_constant_override(&"separation", 14)
	p.add_content(main)

	# ── left: the preview and the seed
	var left := VBoxContainer.new()
	left.add_theme_constant_override(&"separation", 6)
	main.add_child(left)
	var pv := _Preview.new()
	pv.custom_minimum_size = Vector2(PREVIEW, PREVIEW)
	left.add_child(pv)
	# the world's name: the seed's own until the player writes another (11.11)
	var name_edit := LineEdit.new()
	name_edit.max_length = NAME_MAX
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.placeholder_text = "World name"
	name_edit.custom_minimum_size.x = PREVIEW
	left.add_child(name_edit)
	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override(&"separation", 6)
	left.add_child(seed_row)
	var seed_edit := LineEdit.new()
	seed_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_edit.max_length = 32   # any number or word (11.11: was 6 digits)
	seed_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	seed_edit.placeholder_text = "Seed"
	seed_row.add_child(seed_edit)
	var dice := IconButton.create("RANDOM", "cycle", IconButton.Variant.DEFAULT)
	seed_row.add_child(dice)

	# what the preview shows: the choice, or what is hovered
	var show_choice := func() -> void:
		pv.show_home(int(choice["seed"]), String(choice["moon"]))
	var set_seed := func(text: String) -> void:
		var t := text.strip_edges()
		if t == "":
			t = _random_seed_text()
		choice["seed_text"] = t
		choice["seed"] = seed_of(t)
		seed_edit.text = t
		if String(choice["name"]) == "":   # not renamed: the new world's own name
			name_edit.text = _home_name(int(choice["seed"]))
		show_choice.call()
	seed_edit.text_submitted.connect(func(t: String) -> void:
		set_seed.call(t)
		seed_edit.release_focus())
	seed_edit.focus_exited.connect(func() -> void:
		if seed_edit.text.strip_edges() != String(choice["seed_text"]):
			set_seed.call(seed_edit.text))
	var set_name := func(t: String) -> void:
		var n := t.strip_edges()
		var own := _home_name(int(choice["seed"]))
		choice["name"] = "" if n == "" or n == own else n
		name_edit.text = n if n != "" else own
	name_edit.text_submitted.connect(func(t: String) -> void:
		set_name.call(t)
		name_edit.release_focus())
	name_edit.focus_exited.connect(func() -> void: set_name.call(name_edit.text))
	dice.pressed.connect(func() -> void:
		AudioManager.play("click")
		set_seed.call(_random_seed_text()))
	set_seed.call(String(choice["seed_text"]))

	# ── right: the options
	var right := VBoxContainer.new()
	right.add_theme_constant_override(&"separation", 6)
	right.custom_minimum_size.x = 520.0
	main.add_child(right)
	var info := _rich(2)   # what the hovered (or chosen) start option is
	var info_of := func(defs: Dictionary, id: String, open_now: bool) -> String:
		var dim := UIStyle.hex(&"text_subtle")
		if open_now:
			return "[color=#%s]%s[/color]" % [dim, String(defs[id][2])]
		if defs == WORLDS and SettingsManager.unlocked_starts.has(id):
			return "[color=#%s]Unlocked. Starting here comes in a later build.[/color]" % dim
		return "[color=#%s]Locked.[/color]  [color=#%s]%s[/color]" % [UIStyle.hex(&"bad"), dim, String(defs[id][2])]
	var chosen_info := func() -> void:
		info.text = info_of.call(WORLDS, String(choice["world"]), true)
	# one row of three for a choice; `look` shows an option in the preview
	var add_row := func(title: String, key: String, defs: Dictionary, order: Array, look: Callable) -> void:
		right.add_child(_head(title))
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 6)
		right.add_child(row)
		var btns := {}
		var paint := func() -> void:
			for id: String in btns:
				(btns[id] as IconButton).variant = IconButton.Variant.NEUTRAL if id == choice[key] \
					else IconButton.Variant.DEFAULT
		for id: String in order:
			var d: Array = defs[id]
			var open_now := bool(d[3]) and (defs != WORLDS or _world_open(id))
			var b := IconButton.create(String(d[0]), String(d[1]), IconButton.Variant.DEFAULT,
				"" if open_now else "LOCKED")
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if not open_now:
				b.modulate = Color(1, 1, 1, 0.55)
			b.mouse_entered.connect(func() -> void:
				info.text = info_of.call(defs, id, open_now)
				look.call(id, open_now))
			b.mouse_exited.connect(func() -> void:
				chosen_info.call()
				show_choice.call())
			b.pressed.connect(func() -> void:
				info.text = info_of.call(defs, id, open_now)
				if not open_now:
					AudioManager.play("error")
					return
				AudioManager.play("click")
				choice[key] = id
				paint.call())
			row.add_child(b)
			btns[id] = b
		paint.call()
	# the civilization first: it decides what the rows under it are (a world
	# now, a star system later)
	add_row.call("CIVILIZATION", "civ", CIVS, CIV_ORDER, func(id: String, _o: bool) -> void:
		if id == "c1":
			pv.show_solar(int(choice["seed"]))
		elif id == "c2":
			pv.show_galaxy(int(choice["seed"]))
		else:
			show_choice.call())
	add_row.call("START WORLD", "world", WORLDS, WORLD_ORDER, func(id: String, _o: bool) -> void:
		if id == "terran":
			show_choice.call()
		else:
			pv.show_world(int(choice["seed"]), PlanetData.Type.ARID if id == "red" else PlanetData.Type.ICE))
	add_row.call("MOON", "moon", MOONS, MOON_ORDER, func(id: String, _o: bool) -> void:
		pv.show_home(int(choice["seed"]), id, true))
	right.add_child(info)
	chosen_info.call()

	# ── head start
	right.add_child(HSeparator.new())
	right.add_child(_head("HEAD START"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 6)
	grid.add_theme_constant_override(&"v_separation", 6)
	right.add_child(grid)
	var boon_desc := _rich(2)
	right.add_child(boon_desc)
	var boon_btns := {}
	var show_boon := func(id: String) -> void:
		boon_desc.text = "[color=#%s]%s[/color]%s" % [UIStyle.hex(&"text_subtle"), String(BOONS[id][2]),
			("  " + _bonus_bb()) if id == "" else ""]
	var paint_boons := func() -> void:
		for id: String in boon_btns:
			var b: IconButton = boon_btns[id]
			b.variant = IconButton.Variant.NEUTRAL if id == choice["boon"] else IconButton.Variant.DEFAULT
	for id: String in BOON_ORDER:
		var bn: Array = BOONS[id]
		var b := IconButton.create(String(bn[0]), String(bn[1]), IconButton.Variant.DEFAULT)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_entered.connect(func() -> void: show_boon.call(id))
		b.mouse_exited.connect(func() -> void: show_boon.call(String(choice["boon"])))
		b.pressed.connect(func() -> void:
			AudioManager.play("click")
			choice["boon"] = id
			paint_boons.call()
			show_boon.call(id))
		grid.add_child(b)
		boon_btns[id] = b
	paint_boons.call()
	show_boon.call("")

	# ── BEGIN, and beside it a small tutorial box (its tip says what it does);
	# no CANCEL: the ✕ by the title closes it (11.11)
	p.cancel_button().visible = false
	var tut := IconButton.create("TUTORIAL", "confirm", IconButton.Variant.DEFAULT)
	tut.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var tut_tip := func() -> void:
		var on := bool(choice["tutorial"])
		TooltipManager.show_tip("Guided tutorial" if on else "First steps checklist",
			"On: your advisor leads you step by step through the first City.\n\nOff: an optional checklist instead; do the first steps in any order, or skip it and take all its rewards." \
			+ "\n\nNow: %s." % ("on" if on else "off"))
	var paint_tut := func() -> void:
		tut.icon_name = "confirm" if bool(choice["tutorial"]) else "empty"
	tut.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		tut_tip.call())
	tut.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	tut.pressed.connect(func() -> void:
		AudioManager.play("click")
		choice["tutorial"] = not bool(choice["tutorial"])
		paint_tut.call()
		tut_tip.call())
	paint_tut.call()
	var ok := p.confirm_button()
	var buttons := ok.get_parent()
	buttons.add_child(tut)
	buttons.move_child(tut, ok.get_index())
	ok.label_text = "BEGIN"
	ok.icon_name = "rocket"
	ok.variant = IconButton.Variant.POSITIVE
	ok.pressed.connect(func() -> void:
		AudioManager.play("click")
		if seed_edit.text.strip_edges() != String(choice["seed_text"]):
			set_seed.call(seed_edit.text)
		set_name.call(name_edit.text)
		GameState.pending_setup = choice.duplicate()
		TooltipManager.hide_tip()
		p.close()
		begin.call())

## The home world's name for a seed (as GameState._build_home_solar makes it).
static func _home_name(s: int) -> String:
	return PlanetData.from_seed_as_type(s, PlanetData.Type.TERRAN).planet_name

## A long random number for RANDOM (any length works).
static func _random_seed_text() -> String:
	return str(randi_range(100000000, 999999999))

## The world seed of what was typed: a number in range stays itself; any other
## number or word is folded into SEED_MIN..SEED_MAX, always the same way.
static func seed_of(text: String) -> int:
	var t := text.strip_edges()
	if t.is_valid_int() and t.length() <= 6:
		var v := int(t)
		if v >= SEED_MIN and v <= SEED_MAX:
			return v
	var h := 2166136261   # FNV-1a over the bytes: the same on every machine
	for b in t.to_utf8_buffer():
		h = ((h ^ b) * 16777619) & 0xFFFFFFFF
	return SEED_MIN + posmod(h, SEED_MAX - SEED_MIN + 1)

static func _head(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"HeaderLabel"
	return l

## `lines` > 0: always that many lines tall, so a longer text doesn't resize
## the window (11.11: hovering a head start made it jump).
static func _rich(lines := 0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(420, 0)
	r.theme_type_variation = &"PopupBody"
	r.add_theme_font_size_override(&"normal_font_size", 11)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if lines > 0:
		# measured on screen (the theme's real font, with an icon on each line),
		# then held: the box never grows or shrinks with its text (11.11: the
		# estimate made off-screen was a little short, so two lines still grew it)
		r.ready.connect(func() -> void:
			var keep := r.text
			var sample := PackedStringArray()
			for i in lines:
				sample.append("Xg %s +0" % UIIcons.bb("credits", 12))
			r.text = "\n".join(sample)
			r.modulate.a = 0.0   # the sample is never seen
			await r.get_tree().process_frame
			if not is_instance_valid(r):
				return
			var h := float(r.get_content_height())
			if r.text == "\n".join(sample):
				r.text = keep   # (unless it was changed meanwhile)
			r.custom_minimum_size.y = ceilf(h) + 2.0
			r.fit_content = false
			r.modulate.a = 1.0)
	return r

## Picked now: opened across games and playable in this build.
static func _world_open(id: String) -> bool:
	return bool(WORLDS[id][3]) and (id == "terran" or SettingsManager.unlocked_starts.has(id))

static func _world_text(id: String) -> String:
	var dim := UIStyle.hex(&"text_subtle")
	var w: Array = WORLDS[id]
	if id == "terran":
		return "[color=#%s]%s[/color]" % [dim, String(w[2])]
	if SettingsManager.unlocked_starts.has(id):
		return "[color=#%s]Unlocked. Starting here comes in a later build.[/color]" % dim
	return "[color=#%s]Locked.[/color]  [color=#%s]%s[/color]" % [UIStyle.hex(&"bad"), dim, String(w[2])]

## A City stands on `pd`: its kind of world opens as a start (across games).
static func note_city(pd: PlanetData) -> void:
	if pd == null:
		return
	var id := ""
	match pd.planet_type:
		PlanetData.Type.ARID: id = "red"
		PlanetData.Type.ICE: id = "ice"
	if id == "" or SettingsManager.unlocked_starts.has(id):
		return
	SettingsManager.unlocked_starts.append(id)
	SettingsManager.save_settings()
	NewsFeed.post("New start world unlocked: %s." % String(WORLDS[id][0]).capitalize(), NewsFeed.Kind.EVENT)

## Gives the head start of a new game (GameState._apply_new_game_start).
## STANDARD's head start: a little more of both, flat (11.11).
const STANDARD_BONUS := {"credits": 500.0, "science": 50.0}
## The research a head start grants: not the player's own, so it neither opens
## the Upgrade Tree nor ticks "Research a technology" (11.11).
const BOON_SKILLS := {
	"merchant": ["trade_access"],
	"industry": ["start_production", "processing_basics"],
}

static func _bonus_bb() -> String:
	var parts: Array[String] = []
	for id: String in STANDARD_BONUS:
		parts.append("%s [color=#%s]+%s[/color]" % [UIIcons.bb(id, 11, Economy.color_of(id)),
			UIStyle.hex(&"good"), Economy.fmt(float(STANDARD_BONUS[id]))])
	return "   ".join(parts)

## Something researched beyond the start and its head start.
static func researched_beyond_start() -> bool:
	var given: Array = BOON_SKILLS.get(GameState.start_boon, [])
	for id: String in SkillTree.unlocked_skills:
		if not id in SkillTree.DEFAULT_SKILLS and not id in given:
			return true
	return false

## Gives the head start of a new game (GameState._apply_new_game_start).
static func apply_boon(boon: String) -> void:
	if boon == "":
		GameState.earn_credits(float(STANDARD_BONUS["credits"]))
		GameState.add_science(float(STANDARD_BONUS["science"]))
		return
	var tree := Engine.get_main_loop() as SceneTree
	var st: Node = tree.root.get_node_or_null("SkillTree") if tree != null else null
	if st != null:
		for id: String in BOON_SKILLS.get(boon, []):
			st.call("grant", id)
	match boon:
		"industry":
			GameState.story_flags[FREE_DISTRICT] = true
		"gifted":
			var home := GameState.get_home_planet()
			PlanetTags.ensure_home(home)
			PlanetTags.queue_offer(home)

## The first Production District on the home world costs nothing (INDUSTRY).
const FREE_DISTRICT := "free_district:mining"

static func free_district(def: DistrictDef, data: PlanetData) -> bool:
	return def != null and data != null and def.id == DistrictDef.Type.MINING and not def.is_orbital \
		and data.seed == GameState.home_planet_seed and GameState.story_flags.has(FREE_DISTRICT)

# ── The preview square ───────────────────────────────────────────────────────
## A small window on what an option means: a turning globe (the seed's home
## world and its moon, or another kind of world), or a drawn tease of the seed's
## star system / galaxy. Locked looks get a LOCKED tag.
class _Preview extends Control:
	const BRIGHT := 0.85
	var _globes: Array = []   # [ColorRect, ShaderMaterial, spin rad/s, rotation]
	var _mode := "globe"
	var _locked := false
	var _solar: SolarData = null
	var _home_idx := 0
	var _galaxy: GalaxyData = null
	var _t := 0.0
	var _stars := PackedVector2Array()

	func _init() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rng := RandomNumberGenerator.new()
		rng.seed = 4242
		for i in 70:
			_stars.append(Vector2(rng.randf(), rng.randf()))

	func _process(delta: float) -> void:
		_t += delta
		for g: Array in _globes:
			g[3] = fposmod(float(g[3]) + float(g[2]) * delta, TAU)
			(g[1] as ShaderMaterial).set_shader_parameter("rotation_offset", g[3])
		if _mode != "globe":
			queue_redraw()

	func _clear() -> void:
		for g: Array in _globes:
			(g[0] as Node).queue_free()
		_globes.clear()
		_solar = null
		_galaxy = null

	## The seed's home world with its moon (`moon`: rocky / icy / twin).
	func show_home(s: int, moon: String, locked := false) -> void:
		_clear()
		_mode = "globe"
		_locked = locked and moon != "rocky"
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
		queue_redraw()

	## Another kind of world as a start (locked).
	func show_world(s: int, type: PlanetData.Type) -> void:
		_clear()
		_mode = "globe"
		_locked = true
		_add_globe(PlanetData.from_seed_as_type(s ^ 0x5EED, type), Vector2(0.5, 0.5), 0.82, 0.12)
		queue_redraw()

	## The seed's own star system, drawn (Civilization 1's tease).
	func show_solar(s: int) -> void:
		_clear()
		_mode = "solar"
		_locked = true
		var g := GalaxyData.from_seed(s ^ 0xABCDEF)
		_solar = SolarData.from_seed(g.seeds[g.home_idx] if not g.seeds.is_empty() else s ^ 0x1234, true)
		_solar.star_type = g.types[g.home_idx] as SolarData.StarType if not g.types.is_empty() else _solar.star_type
		var rng := RandomNumberGenerator.new()
		rng.seed = s ^ 0x5678
		_home_idx = rng.randi() % maxi(_solar.planets.size(), 1)
		queue_redraw()

	## The seed's galaxy, drawn (Civilization 2's tease).
	func show_galaxy(s: int) -> void:
		_clear()
		_mode = "galaxy"
		_locked = true
		_galaxy = GalaxyData.from_seed(s ^ 0xABCDEF)
		queue_redraw()

	func _add_globe(data: PlanetData, centre: Vector2, diameter: float, spin: float) -> void:
		var side := size.x if size.x > 0.0 else PREVIEW
		var disc := side * diameter
		var rect_side := disc / (0.42 * 2.0)
		var r := ColorRect.new()
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.size = Vector2(rect_side, rect_side)
		r.position = centre * side - r.size * 0.5
		var mat := SessionPrep._globe_material(data, rect_side, Vector3(-0.6, -0.45, 0.65).normalized(), BRIGHT)
		r.material = mat
		add_child(r)
		_globes.append([r, mat, spin, randf() * TAU])

	func _draw() -> void:
		var side := size.x
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.025, 0.06))
		for st: Vector2 in _stars:
			var a := 0.25 + 0.5 * fposmod(st.x * 7.3 + st.y * 3.1, 1.0)
			draw_rect(Rect2((st * size).floor(), Vector2(1.5, 1.5)), Color(0.8, 0.86, 1.0, a))
		match _mode:
			"solar": _draw_solar(side)
			"galaxy": _draw_galaxy(side)
		draw_rect(Rect2(Vector2.ZERO, size), UIStyle.color(&"neutral_stroke"), false, 1.0)
		if _locked:
			var font := get_theme_default_font()
			var txt := "LOCKED"
			var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var box := Rect2(Vector2(side - w - 18.0, 8.0), Vector2(w + 10.0, 18.0))
			draw_rect(box, Color(0.04, 0.06, 0.12, 0.85))
			draw_rect(box, UIStyle.color(&"bad"), false, 1.0)
			draw_string(font, box.position + Vector2(5.0, 13.5), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UIStyle.color(&"bad"))

	func _draw_solar(side: float) -> void:
		if _solar == null:
			return
		var c := Vector2(side, side) * 0.5
		var cols := SolarData.get_star_colors(_solar.star_type)
		var core: Vector3 = cols["core"]
		var corona: Vector3 = cols["corona"]
		draw_circle(c, side * 0.075, Color(corona.x, corona.y, corona.z, 0.35))
		draw_circle(c, side * 0.05, Color(core.x, core.y, core.z))
		var n := _solar.planets.size()
		for i in n:
			var rx := side * (0.12 + 0.36 * float(i + 1) / float(maxi(n, 1)))
			var ry := rx * 0.42
			var pts := PackedVector2Array()
			for k in 65:
				var a := TAU * float(k) / 64.0
				pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
			draw_polyline(pts, Color(0.6, 0.75, 1.0, 0.18), 1.0)
			var ang := _t * (0.5 / float(i + 1)) + float(i) * 2.1
			var pp := c + Vector2(cos(ang) * rx, sin(ang) * ry)
			var pd: PlanetData = _solar.planets[i]
			var r := side * (0.022 if pd.planet_type == PlanetData.Type.GAS_GIANT else 0.013)
			draw_circle(pp, r, SessionPrep._type_color(PlanetData.Type.TERRAN if i == _home_idx else pd.planet_type))
			if i == _home_idx:
				draw_arc(pp, r + 4.0, 0.0, TAU, 24, UIStyle.color(&"accent"), 1.0)

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
			draw_line(to_px.call(_galaxy.positions[l.x]), to_px.call(_galaxy.positions[l.y]),
				Color(0.55, 0.7, 1.0, 0.16), 1.0)
		for i in _galaxy.positions.size():
			var pp: Vector2 = to_px.call(_galaxy.positions[i])
			var cols := SolarData.get_star_colors(_galaxy.types[i] as SolarData.StarType)
			var core: Vector3 = cols["core"]
			draw_circle(pp, 1.8, Color(core.x, core.y, core.z, 0.9))
			if i == _galaxy.home_idx:
				draw_arc(pp, 5.0, 0.0, TAU, 20, UIStyle.color(&"accent"), 1.0)

## A globe's material for the preview (as the main menu's bodies).
static func _globe_material(data: PlanetData, side: float, light: Vector3, bright: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(PlanetData.get_shader_path(data.planet_type)) as Shader
	mat.set_shader_parameter("planet_radius", 0.42)
	mat.set_shader_parameter("pixel_count", maxf(side / 3.0, 24.0))
	mat.set_shader_parameter("seed", data.seed)
	mat.set_shader_parameter("terrain_roughness", data.terrain_roughness)
	mat.set_shader_parameter("aspect_ratio", 1.0)
	mat.set_shader_parameter("light_direction", light)
	var colors := PlanetData.get_colors(data.planet_type)
	var col := func(key: String, v: Vector3) -> void:
		mat.set_shader_parameter(key, v * bright)
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
			for key: String in colors:
				col.call(key, colors[key])
		PlanetData.ShaderType.GAS:
			mat.set_shader_parameter("cloud_speed", data.cloud_speed)
			mat.set_shader_parameter("atmosphere_density", data.atmosphere_density)
			col.call("color_band_a", colors.get("color_sand", Vector3(0.72, 0.55, 0.35)))
			col.call("color_band_b", colors.get("color_forest", Vector3(0.50, 0.32, 0.18)))
			col.call("color_storm", colors.get("color_snow", Vector3(0.88, 0.82, 0.72)))
			col.call("color_atmosphere", colors.get("color_atmosphere", Vector3(0.72, 0.55, 0.35)))
		PlanetData.ShaderType.MOON:
			col.call("color_highland", colors.get("color_mountain", Vector3(0.62, 0.60, 0.56)))
			col.call("color_mare", colors.get("color_deep_ocean", Vector3(0.22, 0.21, 0.20)))
			col.call("color_rim", colors.get("color_snow", Vector3(0.78, 0.76, 0.72)))
			col.call("color_floor", colors.get("color_ocean", Vector3(0.16, 0.15, 0.14)))
	return mat

## A planet kind's dot colour in the drawn star system.
static func _type_color(t: PlanetData.Type) -> Color:
	match t:
		PlanetData.Type.TERRAN: return Color(0.35, 0.7, 0.55)
		PlanetData.Type.ARID: return Color(0.85, 0.45, 0.25)
		PlanetData.Type.ICE: return Color(0.75, 0.88, 1.0)
		PlanetData.Type.VOLCANIC: return Color(0.9, 0.3, 0.2)
		PlanetData.Type.GAS_GIANT: return Color(0.85, 0.72, 0.5)
		_: return Color(0.6, 0.6, 0.62)
