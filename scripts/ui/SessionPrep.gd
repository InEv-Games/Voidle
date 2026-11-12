class_name SessionPrep
extends RefCounted

## NEW GAME (11.11): before the game starts the player picks the start, then
## BEGIN. The window is NewGamePanel (scenes/ui/NewGamePanel.tscn); here are
## what it offers and what the choices do in the game:
##   CIVILIZATION  where the run begins. Only Civilization 0 for now (locked);
##                 pressing the others teases their scale in the preview (the
##                 seed's own star system, its galaxy).
##   START WORLD   the home world's kind. Only the Terran world for now; the
##                 others open across games once a City stands on such a world
##                 (SettingsManager.unlocked_starts), played in a later build.
##   MOON          the home world's moon. Only the rocky moon for now (locked).
##   HEAD START    one of BOONS: a small push in one direction.
##   TUTORIAL      the small box by BEGIN: guided (the advisor leads) or the
##                 optional checklist, which can be skipped for its rewards.
## The choices go to GameState.pending_setup (the seed is read by delete_save,
## the rest by _apply_new_game_start).

const LAYER := 236
const PANEL_SCENE := "res://scenes/ui/NewGamePanel.tscn"   # the window (NewGamePanel)
const PREVIEW := 480.0   # the preview's square, where the globes sit (px)
## Transitions: the panel's rows come in as the main menu's do (RowReveal, its
## blink sound), a little quicker; a step fades out in STEP_OUT before the next
## comes in; the preview waits PREVIEW_DELAY (the main menu's system fading
## away), then comes in from a blur over PREVIEW_IN.
const REVEAL_SLOW := 2.0
const REVEAL_SOUND := &"ui/blink"
const STEP_OUT := 0.1
const PREVIEW_DELAY := 1.0
const PREVIEW_IN := 1.6

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

## Opens the window over `host` (the main menu); `begin` runs after the
## choices are stored (BEGIN).
static func open(host: Node, begin: Callable) -> void:
	if _popup != null and is_instance_valid(_popup):
		_popup.close()
	var cl := CanvasLayer.new()
	cl.layer = LAYER
	cl.process_mode = Node.PROCESS_MODE_ALWAYS
	# (by path and untyped: NewGamePanel reads this class's tables)
	var p := (load(PANEL_SCENE) as PackedScene).instantiate() as ModalPopup
	p.set(&"host", host)
	p.set(&"begin", begin)
	cl.add_child(p)
	host.get_tree().root.add_child(cl)
	_popup = p
	p.closed.connect(func() -> void: _popup = null)

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
	mat.set_shader_parameter("fade_with_modulate", true)   # the swaps fade it
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
