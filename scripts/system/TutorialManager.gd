## Tutorial: narrative-driven guided tutorial → optional quest panel.
## Phase 1 (new game): blocking narrative with action prompts.
## Phase 2 (optional): non-blocking quest panel.
## If tutorial already done, only the quest panel appears.
extends CanvasLayer

signal highlight_changed(target_id: String)
signal highlight_cleared()

class _PulseRing extends Control:
	var time: float = 0.0
	func _process(dt: float) -> void:
		time += dt
		queue_redraw()
	func _draw() -> void:
		var r1 := 22.0 + 5.0 * sin(time * 3.5)
		var r2 := r1 + 14.0
		var alpha := 0.7 + 0.25 * cos(time * 3.5)
		draw_arc(Vector2.ZERO, r1, 0.0, TAU, 52, Color(0.25, 0.80, 1.0, alpha), 2.5)
		draw_arc(Vector2.ZERO, r2, 0.0, TAU, 52, Color(0.25, 0.80, 1.0, alpha * 0.30), 1.5)

const DISTRICT_CITY        := 0   # DistrictDef.Type.CITY
const DISTRICT_GENERATOR   := 1   # DistrictDef.Type.GENERATOR   (Energy District)
const DISTRICT_RESIDENTIAL := 4   # DistrictDef.Type.RESIDENTIAL (Residential District)
const DISTRICT_COMMERCIAL  := 5   # DistrictDef.Type.COMMERCIAL  (Commercial District)
const DISTRICT_SCIENCE     := 6   # DistrictDef.Type.SCIENCE     (Science District)

# ── Guided tutorial steps ──────────────────────────────────────────────────────
# Each step is {type, ...}:
#   type "narr"   → pages: Array of line-arrays (blocking dialog)
#   type "action" → instruction: String, targets: Array of {type, id}, reward_*
const GUIDED_STEPS: Array = [
	{
		"type":  "narr",
		"pages": [
			[
				"Year 2387. Your ark made it — barely.",
				"You are the Governor of a fragile new colony.",
			],
			[
				"First: choose where your Capital will stand.",
				"Coasts and lowlands make a richer city.",
			],
		],
	},
	{
		"type":        "action",
		"instruction": "Pick a site on the planet  →  Name your Capital",
		"targets":     [{"type": "district", "id": DISTRICT_CITY}],
		"reward_credits": 0.0,
		"reward_science": 0.0,
		"reward_text":   "Capital founded",
	},
	{
		"type":  "narr",
		"pages": [
			[
				"The Capital rises.",
				"Give your people homes: a Residential District.",
			],
		],
	},
	{
		"type":        "action",
		"instruction": "Place a Residential District  →  Build  →  Habitat Block",
		"targets": [
			{"type": "district", "id": DISTRICT_RESIDENTIAL},
			{"type": "building", "id": "residential"},
		],
		"reward_credits": 250.0,
		"reward_science": 0.0,
		"reward_text":   "+250 cr",
	},
	{
		"type":  "narr",
		"pages": [
			[
				"They need work, and you need credits.",
				"Open a Market in a Commercial District.",
			],
		],
	},
	{
		"type":        "action",
		"instruction": "Place a Commercial District  →  Build  →  Market",
		"targets": [
			{"type": "district", "id": DISTRICT_COMMERCIAL},
			{"type": "building", "id": "commercial"},
		],
		"reward_credits": 250.0,
		"reward_science": 0.0,
		"reward_text":   "+250 cr",
	},
	{
		"type":  "narr",
		"pages": [
			[
				"Trade runs on power.",
				"Build a Solar Array in an Energy District.",
			],
		],
	},
	{
		"type":        "action",
		"instruction": "Place an Energy District  →  Build  →  Solar Array",
		"targets": [
			{"type": "district", "id": DISTRICT_GENERATOR},
			{"type": "building", "id": "solar_panel"},
		],
		"reward_credits": 300.0,
		"reward_science": 0.0,
		"reward_text":   "+300 cr",
	},
	{
		"type":  "narr",
		"pages": [
			[
				"Districts grow by level: more income, +2 building slots.",
				"The Capital District leads — level it up first.",
			],
		],
	},
	{
		"type":        "action",
		"instruction": "Open the Capital District  →  Press  LEVEL UP",
		"targets":     [{"type": "district_upgrade"}],
		"reward_credits": 400.0,
		"reward_science": 10.0,
		"reward_text":   "+400 cr  +10 sci",
	},
	{
		"type":  "narr",
		"pages": [
			[
				"Enough district levels let the whole City grow.",
				"Open the City and press CITY LEVEL UP — room for more districts.",
			],
		],
	},
	{
		"type":        "action",
		"instruction": "Open the City  →  Press  CITY LEVEL UP",
		"targets":     [{"type": "city_level_up"}],
		"reward_credits": 500.0,
		"reward_science": 0.0,
		"reward_text":   "+500 cr",
	},
	{
		"type":  "narr",
		"pages": [
			[
				"Knowledge keeps a colony alive.",
				"Build a Research Lab in a Science District.",
			],
		],
	},
	{
		"type":        "action",
		"instruction": "Place a Science District  →  Build  →  Research Lab",
		"targets": [
			{"type": "district", "id": DISTRICT_SCIENCE},
			{"type": "building", "id": "lab"},
		],
		"reward_credits": 0.0,
		"reward_science": 25.0,
		"reward_text":   "+25 sci",
	},
	{
		"type":  "narr",
		"pages": [
			[
				"Raw resources lie beneath the surface.",
				"Research Mining Operations in the Upgrade Tree.",
			],
		],
	},
	{
		"type":        "action",
		"instruction": "Open  ✦ Upgrade Tree  →  Research  Mining Operations",
		"targets":     [{"type": "skill", "id": "start_production"}],
		"reward_credits": 500.0,
		"reward_science": 0.0,
		"reward_text":   "+500 cr",
		"finale":        true,
	},
]

# ── Optional quest panel (shown after guided tutorial OR if already done) ───────
# First TUTORIAL_QUEST_COUNT entries mirror the guided tutorial steps.
# They are shown only when the tutorial was skipped / not played.
const TUTORIAL_QUEST_COUNT := 7

const QUESTS := [
	# ── Tutorial-equivalent quests ──────────────────────────────────────────────
	{
		"id":           "first_residents",
		"title":        "First Residents",
		"desc":         "Place a Residential District and build a Habitat Block.",
		"sub_steps":    [
			{"type": "district", "target": DISTRICT_RESIDENTIAL},
			{"type": "building", "target": "residential"},
		],
		"reward_credits": 250.0,
		"reward_science": 0.0,
		"reward_text":  "+250 cr",
	},
	{
		"id":           "open_for_business",
		"title":        "Open for Business",
		"desc":         "Place a Commercial District and build a Market.",
		"sub_steps":    [
			{"type": "district", "target": DISTRICT_COMMERCIAL},
			{"type": "building", "target": "commercial"},
		],
		"reward_credits": 250.0,
		"reward_science": 0.0,
		"reward_text":  "+250 cr",
	},
	{
		"id":           "power_grid",
		"title":        "Power Grid",
		"desc":         "Place an Energy District and build a Solar Array.",
		"sub_steps":    [
			{"type": "district", "target": DISTRICT_GENERATOR},
			{"type": "building", "target": "solar_panel"},
		],
		"reward_credits": 300.0,
		"reward_science": 0.0,
		"reward_text":  "+300 cr",
	},
	{
		"id":           "district_upgrade",
		"title":        "Expand the Grid",
		"desc":         "Raise the Capital District to Lv 2.",
		"sub_steps":    [{"type": "district_upgrade"}],
		"reward_credits": 400.0,
		"reward_science": 10.0,
		"reward_text":  "+400 cr  +10 sci",
	},
	{
		"id":           "city_level_up",
		"title":        "Growing City",
		"desc":         "Raise your City to Level 2.",
		"sub_steps":    [{"type": "city_level_up"}],
		"reward_credits": 300.0,
		"reward_science": 0.0,
		"reward_text":  "+300 cr",
	},
	{
		"id":           "research_wing",
		"title":        "Research Wing",
		"desc":         "Place a Science District and build a Research Lab.",
		"sub_steps":    [
			{"type": "district", "target": DISTRICT_SCIENCE},
			{"type": "building", "target": "lab"},
		],
		"reward_credits": 0.0,
		"reward_science": 25.0,
		"reward_text":  "+25 sci",
	},
	{
		"id":           "mining_ops",
		"title":        "Mining Operations",
		"desc":         "Research Mining Operations in the Upgrade Tree.",
		"sub_steps":    [{"type": "skill", "target": "start_production"}],
		"reward_credits": 500.0,
		"reward_science": 0.0,
		"reward_text":  "+500 cr",
	},
	# ── The road to Civilization 1 (GDD §16, §20) — no economic rewards ──────────
	{"id": "fuel", "title": "Fuel for the Journey", "desc": "Research Fuel Processing and make or buy Fuel.",
		"reward_credits": 300.0, "reward_science": 100.0, "reward_text": "+300 cr  +100 sci",
		"sub_steps": [{"type": "skill", "target": "fuel_processing"}]},
	{"id": "rocketry", "title": "Rocketry", "desc": "Research Rocketry and build a Spaceport in your Capital (it needs Capital Lv2 for its two slots).",
		"reward_credits": 600.0, "reward_science": 150.0, "reward_text": "+600 cr  +150 sci",
		"sub_steps": [{"type": "skill", "target": "rocketry"}, {"type": "building", "target": "spaceport"}]},
	{"id": "orbital", "title": "Into Orbit", "desc": "Research Orbital Assembly, then found your Orbit from the planet panel and launch a Space Station from the Spaceport. The Moon needs it.",
		"reward_credits": 700.0, "reward_science": 150.0, "reward_text": "+700 cr  +150 sci",
		"sub_steps": [{"type": "skill", "target": "orbital_assembly"}, {"type": "event", "target": "orbit_station"}]},
	{"id": "lunar_program", "title": "Lunar Program", "desc": "Research Lunar Program.",
		"reward_credits": 800.0, "reward_science": 200.0, "reward_text": "+800 cr  +200 sci",
		"sub_steps": [{"type": "skill", "target": "lunar_program"}]},
	{"id": "lander", "title": "To the Moon", "desc": "Open the Moon and prepare the lander (3,000 cr, 40 Ferrite, 20 Fuel).",
		"reward_credits": 1000.0, "reward_science": 0.0, "reward_text": "+1000 cr",
		"sub_steps": [{"type": "event", "target": "lander_arrived"}]},
	{"id": "moon_city", "title": "First Lunar City", "desc": "The lander set up the Moon's Central Orbit. Scan the surface (free), then initiate colonization and pick the site of the first City. Terran buildings can't stand on the Moon: research Lunar ones on the lines around Lunar Program.",
		"reward_credits": 500.0, "reward_science": 150.0, "reward_text": "+500 cr  +150 sci",
		"sub_steps": [{"type": "event", "target": "moon_city"}]},
	{"id": "moon_mining", "title": "Lunar Mining", "desc": "Build a Production district on the Moon (300 cr, 30 Ferrite). It finds the Moon's mineral. Regolith Extraction researches its first building.",
		"reward_credits": 800.0, "reward_science": 0.0, "reward_text": "+800 cr",
		"sub_steps": [{"type": "event", "target": "moon_production"}]},
	{"id": "lunar_materials", "title": "Lunar Materials", "desc": "Research Lunar Materials.",
		"reward_credits": 1500.0, "reward_science": 300.0, "reward_text": "+1500 cr  +300 sci",
		"sub_steps": [{"type": "skill", "target": "lunar_materials"}]},
	{"id": "moonstone_100", "title": "100 Local Moonstone", "desc": "Mine 100 Moonstone on the Moon. Bought Moonstone doesn't count.",
		"reward_credits": 2000.0, "reward_science": 300.0, "reward_text": "+2000 cr  +300 sci",
		"sub_steps": [{"type": "event", "target": "moon_moonstone_100"}]},
	{"id": "lunar_spaceport", "title": "Lunar Spaceport", "desc": "Build the Lunar Spaceport in the Moon's Capital.",
		"reward_credits": 2500.0, "reward_science": 400.0, "reward_text": "+2500 cr  +400 sci",
		"sub_steps": [{"type": "building", "target": "lunar_spaceport"}]},
	{"id": "advanced_rocket", "title": "Advanced Rocket", "desc": "Research Advanced Planetary Rocket, then prepare the rocket on the Moon's page.",
		"reward_credits": 3000.0, "reward_science": 0.0, "reward_text": "+3000 cr",
		"sub_steps": [{"type": "skill", "target": "advanced_planet_rocket"}, {"type": "event", "target": "rocket_started"}]},
	{"id": "civilization_1", "title": "Reach Civilization 1", "desc": "Right-click a planet in the Solar System view to set the rocket's target. Its arrival completes Civilization 0.",
		"sub_steps": [{"type": "event", "target": "demo_completed"}]},
]

## Objective rewards and the tutorial's step top-ups. On: a small new-game
## budget (Balance.cfg.start_*) plus rewards that pace the road to the Moon.
const GRANTS_ENABLED := true

## Why an "event" objective step is met (polled once a second).
static func event_done(key: String) -> bool:
	match key:
		"lander_arrived":
			var moon := GameState.home_moon()
			return GameState.expedition_state("lander") == "arrived" \
				or (moon != null and GameState.get_planet(moon.seed).is_colonized)
		"rocket_started":
			return GameState.expedition_state("rocket") != ""
		"demo_completed":
			return GameState.demo_completed
	return SkillTree.event_met(key)

const SKIP_MINERAL_AMOUNT := 30.0

# ── Typewriter ─────────────────────────────────────────────────────────────────
const TW_NARR  := 0.028

# ── State ──────────────────────────────────────────────────────────────────────
var _tutorial_done: bool = false   # guided narrative complete
var _quest_done:    bool = false   # quest panel dismissed

var _guided_step:   int  = 0       # index into GUIDED_STEPS
var _action_sub:    int  = 0       # sub-target within current action step
var _solar_count:   int  = 0       # solar_panel builds total
var _active:        bool = false

var _quest_step:    int  = 0
## Objectives panel folded to a small "OBJECTIVES" tab (O toggles; saved).
var _collapsed:     bool = false
var _side_tab:      Button = null
var _overlay_lbl:   Label = null
var _quest_body:    Array[Control] = []
var _event_poll:    float = 0.0
var _quest_sub:     int  = 0

var _inventory_shown: bool = false
var tutorial_enabled: bool = true  # set false in Settings to skip tutorial entirely

# ── Narrative UI ───────────────────────────────────────────────────────────────
var _dim:         ColorRect      = null
var _narr_panel:  PanelContainer = null
var _narr_lbl:    RichTextLabel  = null
var _narr_btn:    Button         = null
var _narr_page:   int            = 0
var _narr_pages:  Array          = []
var _narr_done_cb: Callable      = Callable()
var _narr_typing: bool           = false
var _narr_instant: bool          = false

# ── Action banner (non-blocking) ───────────────────────────────────────────────
var _action_bar:  PanelContainer = null
var _action_lbl:  Label          = null
var _pulse_ring:      Control = null
var _action_block_on: bool   = false  # whether input blocking is active
var _allowed_rects:   Array[Rect2]  = []      # clicks inside any of these pass through
var _waiting_for_bid: String        = ""      # if set, waiting for this building to finish constructing
var _waiting_for_district: int      = -1      # if >= 0, waiting for a district of this type to finish constructing
var _topup_key: String              = ""      # the step target last topped up once it became doable
var _construction_lbl: Label        = null    # non-blocking "under construction" label

# ── Quest UI ───────────────────────────────────────────────────────────────────
var _quest_panel:    PanelContainer   = null
var _skip_btn:       Button           = null
var _title_lbl:      Label            = null
var _desc_lbl:       Label            = null
var _sub_lbl:        Label            = null
var _reward_lbl:     Label            = null
var _tracker_items:  Array[Dictionary] = []

var _orbitron: Font = null

# ═══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_orbitron = load("res://Fonts/Orbitron-VariableFont_wght.ttf")
	GameState.save_deleted.connect(_on_new_game)
	ProductionManager.building_queued.connect(_on_building_queued)
	ProductionManager.building_constructed.connect(_on_building_constructed)
	GameState.district_placed.connect(_on_district_placed)
	GameState.global_resources_changed.connect(_on_resources_changed)
	GameState.planet_progress_changed.connect(_on_planet_progress_changed)
	get_tree().root.get_node("SkillTree").skill_unlocked.connect(_on_skill_unlocked)
	get_tree().root.child_entered_tree.connect(_on_root_child_entered)

func start() -> void:
	if not tutorial_enabled or _active: return
	_active = true
	# saves from before the road to Civilization 1 existed: show the new objectives
	if _quest_done and _quest_step < QUESTS.size() and not GameState.demo_completed:
		_quest_done = false
	if _tutorial_done:
		if not _quest_done:
			# the first objectives build inside the Capital: wait until it stands
			while not _district_built(DISTRICT_CITY):
				await get_tree().create_timer(0.5).timeout
				if not _active: return
			_build_quest_ui()
			_show_quest_step(_quest_step)
	else:
		_run_guided_step()

func _on_root_child_entered(node: Node) -> void:
	# Hide tutorial UI whenever a new top-level scene is added (scene transition)
	if node.scene_file_path.ends_with("MainMenu.tscn"):
		for n in [_dim, _narr_panel, _action_bar, _quest_panel, _pulse_ring, _construction_lbl, _side_tab, _overlay_lbl]:
			if is_instance_valid(n): (n as CanvasItem).visible = false
		_active = false

func _on_new_game() -> void:
	_tutorial_done = SettingsManager.tutorial_ever_done
	_quest_done    = false
	_guided_step   = 0
	_action_sub    = 0
	_solar_count   = 0
	_quest_step    = 0
	_quest_sub     = 0
	_active          = false
	_action_block_on = false
	_allowed_rects   = []
	_waiting_for_bid = ""
	_waiting_for_district = -1
	_topup_key = ""
	_inventory_shown = false
	_hide_construction_wait()
	_narr_instant     = false
	_narr_pages    = []
	_narr_done_cb  = Callable()
	for n in [_dim, _narr_panel, _action_bar, _quest_panel, _pulse_ring, _side_tab, _overlay_lbl]:
		if is_instance_valid(n): n.queue_free()
	_dim = null; _narr_panel = null; _action_bar = null; _quest_panel = null; _pulse_ring = null

# ── Signal handlers ────────────────────────────────────────────────────────────
## Fired when player clicks BUILD — advances guided tutorial immediately (don't wait for construction).
func _on_building_queued(_seed: int, bid: String) -> void:
	if not _active or _tutorial_done or _guided_step >= GUIDED_STEPS.size(): return
	var step: Dictionary = GUIDED_STEPS[_guided_step]
	if step["type"] != "action": return
	var tgt: Dictionary = step["targets"][_action_sub]
	if tgt["type"] == "building" and tgt["id"] == bid:
		if bid == "solar_panel": _solar_count += 1
		_hide_action_bar()
		_waiting_for_bid = bid
		_action_block_on  = true   # re-enable: PlanetaryView sets wait rects each frame
		highlight_changed.emit("construction_wait")
		_show_construction_wait()

func _on_building_constructed(_seed: int, _key: String, bid: String) -> void:
	# Guided tutorial — advance when the waited building finishes
	if _waiting_for_bid != "" and _waiting_for_bid == bid:
		_waiting_for_bid = ""
		_hide_construction_wait()
		_advance_action()
	# Quest panel
	if not _quest_done and _quest_step < QUESTS.size() and is_instance_valid(_quest_panel):
		var q: Dictionary = QUESTS[_quest_step]
		var ss: Dictionary = q["sub_steps"][_quest_sub]
		if ss["type"] == "building" and ss["target"] == bid:
			_advance_quest_sub()

func _on_skill_unlocked(id: String) -> void:
	# Guided tutorial
	if _active and not _tutorial_done and _guided_step < GUIDED_STEPS.size():
		var step: Dictionary = GUIDED_STEPS[_guided_step]
		if step["type"] == "action":
			var tgt: Dictionary = step["targets"][_action_sub]
			if tgt["type"] == "skill" and tgt["id"] == id:
				_close_skill_tree()
				await get_tree().create_timer(0.3).timeout
				_advance_action()
	# Quest panel
	if not _quest_done and _quest_step < QUESTS.size() and is_instance_valid(_quest_panel):
		var q: Dictionary = QUESTS[_quest_step]
		var ss: Dictionary = q["sub_steps"][_quest_sub]
		if ss["type"] == "skill" and ss["target"] == id:
			_advance_quest_sub()

func _on_district_placed(_seed: int, dtype: int) -> void:
	if _active and not _tutorial_done and _guided_step < GUIDED_STEPS.size():
		var step: Dictionary = GUIDED_STEPS[_guided_step]
		if step["type"] == "action":
			var tgt: Dictionary = step["targets"][_action_sub]
			if tgt["type"] == "district" and tgt["id"] == dtype and _waiting_for_district < 0:
				if _district_built(dtype):
					_advance_action()
				else:   # the next instruction would need the district — wait for it to stand
					_hide_action_bar()
					_waiting_for_district = dtype
					_action_block_on = int(dtype) != DISTRICT_CITY
					highlight_changed.emit("construction_wait")
					_show_construction_wait()

	# quests: a district sub-step is met once it is built (polled in _process)
	_check_quest_sub_already_done()

func _on_planet_progress_changed(planet_seed: int) -> void:
	var pp: PlanetProgress = GameState.get_planet(planet_seed)
	if pp == null: return
	# Guided tutorial — planet level up / district upgrade
	if _active and not _tutorial_done and _guided_step < GUIDED_STEPS.size():
		var step: Dictionary = GUIDED_STEPS[_guided_step]
		if step["type"] == "action":
			var tgt: Dictionary = step["targets"][_action_sub]
			if tgt["type"] == "city_level_up" and _city_any_leveled(pp):
				_advance_action()
			elif tgt["type"] == "district_upgrade" and _district_any_upgraded(pp):
				_advance_action()
	# Quest panel
	if not _quest_done and _quest_step < QUESTS.size() and is_instance_valid(_quest_panel):
		var q: Dictionary = QUESTS[_quest_step]
		var ss: Dictionary = q["sub_steps"][_quest_sub]
		if ss["type"] == "city_level_up" and _city_any_leveled(pp):
			_advance_quest_sub()
		elif ss["type"] == "district_upgrade" and _district_any_upgraded(pp):
			_advance_quest_sub()

func _check_freeform_action_step(step: Dictionary) -> void:
	if step["type"] != "action": return
	var targets: Array = step["targets"]
	if _action_sub >= targets.size(): return
	var tgt: Dictionary = targets[_action_sub]
	if tgt["type"] not in ["city_level_up", "district_upgrade"]: return
	# Check against all colonized planets
	for pp: PlanetProgress in GameState._planet_progress.values():
		if not pp.is_colonized: continue
		if tgt["type"] == "city_level_up" and _city_any_leveled(pp):
			_advance_action(); return
		if tgt["type"] == "district_upgrade" and _district_any_upgraded(pp):
			_advance_action(); return

func _city_any_leveled(pp: PlanetProgress) -> bool:
	for c in pp.city_levels:
		if int(pp.city_levels[c]) >= 2:
			return true
	return false

func _district_any_upgraded(pp: PlanetProgress) -> bool:
	for dlabel in pp.district_levels:
		if pp.district_levels[dlabel] >= 2 and not pp.district_upgrading.has(dlabel):
			return true
	return false

func _on_resources_changed() -> void:
	if _inventory_shown: return
	for key in GameState.global_resources:
		if GameState.global_resources[key] > 0.0:
			_inventory_shown = true
			_show_inventory_hint()
			return

# ── Guided tutorial state machine ──────────────────────────────────────────────
func _run_guided_step() -> void:
	if _guided_step >= GUIDED_STEPS.size():
		_end_guided_tutorial()
		return
	var step: Dictionary = GUIDED_STEPS[_guided_step]
	if step["type"] == "narr":
		_show_narr(step["pages"], func() -> void:
			_guided_step += 1
			_run_guided_step())
	else:  # action
		_action_sub = 0
		_hide_dim()
		_show_action_bar(step)
		# Unblock input for steps that need free navigation
		var first_tgt: Dictionary = step["targets"][0]
		if first_tgt["type"] in ["skill", "city_level_up", "district_upgrade"] \
				or (first_tgt["type"] == "district" and int(first_tgt["id"]) == DISTRICT_CITY):
			_action_block_on = false
		if GRANTS_ENABLED:
			_grant_step_needs(step["targets"], "id")
		# Immediately advance if condition already met (e.g. player acted during narration)
		_check_freeform_action_step(step)

## Credits / science the remaining targets of a tutorial step cost, so the
## player can never get stuck on one: { "credits": x, "science": y }.
func _step_needs(targets: Array, id_key: String) -> Dictionary:
	var need := {"credits": 0.0, "science": 0.0}
	var home: PlanetData = GameState.get_home_planet()
	var pp: PlanetProgress = GameState.get_planet(home.seed) if home != null else null
	for tgt: Dictionary in targets:
		match tgt["type"]:
			"district":
				var ddef: DistrictDef = DistrictDef.find(int(tgt[id_key]) as DistrictDef.Type)
				if ddef != null and home != null:
					need["credits"] += DistrictDef.placement_cost(ddef, home, _first_city_key(home))
			"building":
				var bdef := BuildingDef.find(String(tgt[id_key]))
				if bdef != null:
					need["credits"] += bdef.base_cost   # first building of a fresh district
			"skill":
				need["science"] += float(get_node("/root/SkillTree").get_next_cost(String(tgt[id_key])))
			"district_upgrade":
				if home != null and pp != null:
					var ck := _first_city_key(home)
					need["credits"] += Leveling.district_level_credits(int(pp.district_levels.get(ck, 1)))
			"city_level_up":
				if home != null and pp != null:
					var ck2 := _first_city_key(home)
					need["credits"] += Leveling.city_level_credits(int(pp.city_levels.get(ck2, 1)) + 1)
	return need

## Internal id of a planet's first City ("" before one is founded).
static func _first_city_key(pd: PlanetData) -> String:
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital():
			return p.label
	return ""

## Tops credits / science up to what the step needs, shown as a small reward.
func _grant_step_needs(targets: Array, id_key: String) -> void:
	var need := _step_needs(targets, id_key)
	var cr: float = maxf(0.0, ceilf(need["credits"] - GameState.credits))
	var sci: float = maxf(0.0, ceilf(need["science"] - GameState.science_points))
	if cr > 0.0:
		GameState.earn_credits(cr)
	if sci > 0.0:
		GameState.add_science(sci)
	if cr > 0.0 or sci > 0.0:
		var parts: Array[String] = []
		if cr > 0.0: parts.append("+%.0f cr" % cr)
		if sci > 0.0: parts.append("+%.0f sci" % sci)
		_flash_reward("Tutorial grant  " + "  ".join(parts))

func _advance_action() -> void:
	if _guided_step >= GUIDED_STEPS.size(): return
	var step: Dictionary = GUIDED_STEPS[_guided_step]
	_action_sub += 1
	if _action_sub >= step["targets"].size():
		# Action complete
		if GRANTS_ENABLED:
			if step.get("reward_credits", 0.0) > 0.0: GameState.credits     += step["reward_credits"]
			if step.get("reward_science", 0.0) > 0.0: GameState.add_science(step["reward_science"])
			if step.has("reward_text"): _flash_reward(step["reward_text"])
		_hide_action_bar()
		if step.get("finale", false):
			_run_finale()
			return
		_guided_step += 1
		_run_guided_step()
	else:
		# Update sub-target label and highlight
		var tgt: Dictionary = step["targets"][_action_sub]
		if is_instance_valid(_action_lbl):
			_action_lbl.text = "✓ Done!  Now:  " + _target_hint(tgt)
		highlight_changed.emit(_highlight_id_for(tgt))

## Called by PlanetaryView to query what building the current action step wants.
func get_action_building_target() -> String:
	if _tutorial_done or _guided_step >= GUIDED_STEPS.size(): return ""
	var step: Dictionary = GUIDED_STEPS[_guided_step]
	if step["type"] != "action": return ""
	var sz: int = (step["targets"] as Array).size()
	var sub_idx: int = _action_sub if _action_sub < sz else sz - 1
	var tgt: Dictionary = step["targets"][sub_idx]
	return tgt["id"] if tgt["type"] == "building" else ""

## Returns "building" or "district" for the current action sub-target.
func get_action_district_target() -> int:
	if _tutorial_done or _guided_step >= GUIDED_STEPS.size(): return -1
	var step: Dictionary = GUIDED_STEPS[_guided_step]
	if step["type"] != "action": return -1
	var sz: int = (step["targets"] as Array).size()
	var sub_idx: int = _action_sub if _action_sub < sz else sz - 1
	var tgt: Dictionary = step["targets"][sub_idx]
	return int(tgt["id"]) if tgt["type"] == "district" else -1

func get_action_step_type() -> String:
	if _tutorial_done or _guided_step >= GUIDED_STEPS.size(): return ""
	var step: Dictionary = GUIDED_STEPS[_guided_step]
	if step["type"] != "action": return ""
	var sz: int = (step["targets"] as Array).size()
	var sub_idx: int = _action_sub if _action_sub < sz else sz - 1
	return GUIDED_STEPS[_guided_step]["targets"][sub_idx]["type"]

func set_allowed_rects(rects: Array[Rect2]) -> void:
	_allowed_rects = rects

## Input blocker — only clicks inside _allowed_rects pass through.
func _process(delta: float) -> void:
	if is_instance_valid(_quest_panel):
		_place_quest_panel()
		_event_poll += delta
		if _event_poll >= 1.0:   # "event" objectives have no signal of their own
			_event_poll = 0.0
			if not _quest_done and _quest_step < QUESTS.size():
				var ss: Dictionary = QUESTS[_quest_step]["sub_steps"][_quest_sub]
				if ss["type"] == "event" and event_done(String(ss["target"])):
					_advance_quest_sub()
				elif ss["type"] == "district":
					_check_quest_sub_already_done()
				elif _quest_step < TUTORIAL_QUEST_COUNT and GRANTS_ENABLED:
					_topup_when_doable(ss, "target", "q%d.%d" % [_quest_step, _quest_sub])
	if not _active or _tutorial_done or _guided_step >= GUIDED_STEPS.size(): return
	var step: Dictionary = GUIDED_STEPS[_guided_step]
	if step["type"] == "action":
		if _waiting_for_district >= 0:
			if _district_built(_waiting_for_district):
				_finish_district_wait(step)
			return
		_check_freeform_action_step(step)
		if GRANTS_ENABLED and _action_sub < (step["targets"] as Array).size():
			_topup_when_doable(step["targets"][_action_sub], "id", "g%d.%d" % [_guided_step, _action_sub])

## The waited district stands: show the step's next instruction (or finish it).
func _finish_district_wait(step: Dictionary) -> void:
	_waiting_for_district = -1
	_hide_construction_wait()
	if _action_sub + 1 < (step["targets"] as Array).size():
		_action_sub += 1
		_show_action_bar(step)
		_action_lbl.text = "✓ Done!  Now:  " + _target_hint(step["targets"][_action_sub])
	else:
		_advance_action()

## A finished (not under construction) district of this DistrictDef type on any colonized world.
func _district_built(dtype: int) -> bool:
	var ddef: DistrictDef = DistrictDef.find(dtype as DistrictDef.Type)
	var poi_t: int = int(ddef.to_poi_type()) if ddef != null else -1
	for pp: PlanetProgress in GameState._planet_progress.values():
		if not pp.is_colonized: continue
		var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
		if pd == null: continue
		for poi: POIData in pd.custom_pois:
			if int(poi.poi_type) == poi_t and not poi.constructing:
				return true
	return false

## Level-up targets can need more than the step's opening grant (credits spent
## meanwhile on what the level needs first): once the target can be done, top
## the credits up to its price, once.
func _topup_when_doable(tgt: Dictionary, id_key: String, key: String) -> void:
	if _topup_key == key or tgt["type"] not in ["city_level_up", "district_upgrade"]:
		return
	var home: PlanetData = GameState.get_home_planet()
	if home == null: return
	var pp: PlanetProgress = GameState.get_planet(home.seed)
	var city: POIData = null
	for p: POIData in home.custom_pois:
		if p.is_city() and not p.is_orbital():
			city = p
			break
	if pp == null or city == null: return
	var block := Leveling.city_level_block(home, pp, city) if tgt["type"] == "city_level_up" \
		else Leveling.district_level_block(home, pp, city)
	if block != "": return
	_topup_key = key
	_grant_step_needs([tgt], id_key)

## A narrative card is up: the world behind it must not react to the mouse.
func is_narrating() -> bool:
	return is_instance_valid(_narr_panel) or is_instance_valid(_dim)

## The guided tutorial waits for a building or district to finish.
func is_waiting_construction() -> bool:
	return _waiting_for_bid != "" or _waiting_for_district >= 0

## HUD buttons outside the current step (Trade, …) stay shut during the guided tutorial.
func blocks_hud() -> bool:
	return _active and not _tutorial_done

func _input(event: InputEvent) -> void:
	if not _action_block_on: return
	if not (event is InputEventMouseButton): return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT: return
	var click := mb.position
	for r in _allowed_rects:
		if r.has_point(click): return
	get_viewport().set_input_as_handled()
	_flash_deny(click)

func _flash_deny(pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = "✗"
	if _orbitron: lbl.add_theme_font_override("font", _orbitron)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	lbl.position = pos + Vector2(-10, -20)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 28, 0.5)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(lbl.queue_free).set_delay(0.5)

func _highlight_id_for(tgt: Dictionary) -> String:
	match tgt["type"]:
		"district":        return "add_district"
		"skill":           return "skill_tree_btn"
		"city_level_up":   return "city_level_up_btn"
		"district_upgrade": return "district_upgrade_btn"
	if tgt["type"] == "building":
		return "generator_district"   # the district the player just placed
	return ""

func _spawn_pulse_ring() -> void:
	if is_instance_valid(_pulse_ring): return
	_pulse_ring = _PulseRing.new()
	_pulse_ring.position = Vector2(-999, -999)  # off-screen until positioned
	_pulse_ring.custom_minimum_size = Vector2(80, 80)
	_pulse_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pulse_ring.modulate.a = 0.0
	add_child(_pulse_ring)
	create_tween().tween_property(_pulse_ring, "modulate:a", 1.0, 0.4)

func _clear_pulse_ring() -> void:
	if not is_instance_valid(_pulse_ring): return
	var r := _pulse_ring; _pulse_ring = null
	var tw := create_tween()
	tw.tween_property(r, "modulate:a", 0.0, 0.3)
	tw.tween_callback(r.queue_free)

func set_highlight_pos(screen_pos: Vector2) -> void:
	if is_instance_valid(_pulse_ring):
		_pulse_ring.position = screen_pos

func _target_hint(tgt: Dictionary) -> String:
	match tgt["type"]:
		"district":
			var ddef: DistrictDef = DistrictDef.find(int(tgt["id"]) as DistrictDef.Type)
			return "Place a%s %s" % ["n" if ddef != null and ddef.display_name.substr(0, 1) in ["A", "E", "I", "O", "U"] else "",
				ddef.display_name if ddef != null else "district"]
		"city_level_up":    return "Open the City  →  Press  CITY LEVEL UP"
		"district_upgrade": return "Open the Capital District  →  Press  LEVEL UP"
	var bdef := BuildingDef.find(tgt.get("id", ""))
	if bdef != null:
		return "Build  →  %s inside the district" % bdef.display_name
	return "Build: " + tgt.get("id", "")

func _close_skill_tree() -> void:
	var root := get_tree().root
	for child: Node in root.get_children():
		if not (child is CanvasLayer): continue
		for gc: Node in child.get_children():
			var sc = gc.get_script()
			if sc != null and (sc as Script).resource_path.ends_with("SkillTreeView.gd"):
				if gc.has_signal("tree_closed"):
					gc.emit_signal("tree_closed")
				child.queue_free()
				return

func _run_finale() -> void:
	# Clean up any open narrative UI or action bar if skipped
	_narr_done_cb = Callable()
	_narr_instant = true
	if is_instance_valid(_narr_panel): _narr_panel.queue_free(); _narr_panel = null
	_hide_action_bar()

	# Close SkillTree and return to planet view
	_close_skill_tree()
	await get_tree().create_timer(0.55).timeout

	# Reward was already given by _advance_action before _run_finale — nothing extra needed here

	# Big "Tutorial Complete" banner at top of planet area
	var banner := PanelContainer.new()
	var sb := _panel_style(Color(0.02, 0.04, 0.10, 0.96), Color(0.35, 0.70, 1.0, 0.85))
	banner.add_theme_stylebox_override("panel", sb)
	banner.custom_minimum_size = Vector2(520, 0)
	var _ca := _planet_area_center_anchor()
	banner.anchor_left   = _ca;  banner.anchor_right  = _ca
	banner.anchor_top    = 0.0;  banner.anchor_bottom = 0.0
	banner.offset_left   = -260; banner.offset_right  = 260
	banner.offset_top    = 52
	banner.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	banner.modulate.a    = 0.0
	add_child(banner)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	banner.add_child(vbox)

	var tag := Label.new()
	tag.text = "◈  TUTORIAL COMPLETE  ◈"
	if _orbitron: tag.add_theme_font_override("font", _orbitron)
	tag.add_theme_font_size_override("font_size", 9)
	tag.add_theme_color_override("font_color", Color(0.45, 0.78, 1.0))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(tag)

	var title := Label.new()
	title.text = "The void is no longer empty."
	if _orbitron: title.add_theme_font_override("font", _orbitron)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.92, 0.94, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "You have shelter. Power. Knowledge. Minerals.\nFrom this foothold, the stars are reachable."
	if _orbitron: sub.add_theme_font_override("font", _orbitron)
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color(0.60, 0.72, 0.90))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size = Vector2(460, 0)
	vbox.add_child(sub)

	create_tween().tween_property(banner, "modulate:a", 1.0, 0.7)
	await get_tree().create_timer(4.2).timeout

	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 0.0, 0.8)
	await tw.finished
	if is_instance_valid(banner): banner.queue_free()
	_end_guided_tutorial()

## The guided tutorial is over (this game or ever) — Explore mode opens.
func tutorial_finished() -> bool:
	return _tutorial_done

func _end_guided_tutorial() -> void:
	_tutorial_done = true
	_hide_dim()
	AchievementManager.notify_trigger(AchievementDef.Trigger.TUTORIAL_COMPLETE)
	SettingsManager.tutorial_ever_done = true
	SettingsManager.save_settings()
	# Tutorial quests already completed — start from the post-tutorial quests
	_quest_step = TUTORIAL_QUEST_COUNT
	_quest_sub  = 0
	await get_tree().create_timer(0.4).timeout
	if not _quest_done:
		_build_quest_ui()
		_show_quest_step(_quest_step)

## The side panel sits on the left: the planet area is the rest of the screen.
func _side_panel_edge() -> float:
	var side := get_tree().root.find_child("SidePanel", true, false) as Control
	if not is_instance_valid(side) or not side.is_visible_in_tree():
		return 0.0
	return maxf(0.0, side.position.x + side.size.x)

func _planet_area_center_anchor() -> float:
	var vp_w: float = get_viewport().get_visible_rect().size.x
	if vp_w <= 0.0: return 0.65
	var edge := _side_panel_edge()
	return (edge + (vp_w - edge) * 0.5) / vp_w

# ── Dim overlay ────────────────────────────────────────────────────────────────
func _show_dim() -> void:
	if is_instance_valid(_dim): return
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)
	move_child(_dim, 0)   # behind panel
	create_tween().tween_property(_dim, "color", Color(0, 0, 0, 0.68), 0.35)

func _hide_dim() -> void:
	if not is_instance_valid(_dim): return
	var d := _dim; _dim = null
	var tw := create_tween()
	tw.tween_property(d, "color", Color(0, 0, 0, 0), 0.30)
	tw.tween_callback(d.queue_free)

# ── Narrative dialog ───────────────────────────────────────────────────────────
func _show_narr(pages: Array, on_done: Callable) -> void:
	_narr_pages   = pages
	_narr_done_cb = on_done
	_narr_page    = 0
	_show_dim()
	_build_narr_ui()
	_type_page(0)

func _build_narr_ui() -> void:
	if is_instance_valid(_narr_panel): _narr_panel.queue_free()

	_narr_panel = PanelContainer.new()
	var sb := _panel_style(Color(0.04, 0.04, 0.10, 0.97), Color(0.35, 0.45, 0.80, 0.50))
	_narr_panel.add_theme_stylebox_override("panel", sb)
	_narr_panel.custom_minimum_size = Vector2(600, 0)
	# Top-center
	var _na := _planet_area_center_anchor()
	_narr_panel.anchor_left   = _na;  _narr_panel.anchor_right  = _na
	_narr_panel.anchor_top    = 0.0;  _narr_panel.anchor_bottom = 0.0
	_narr_panel.offset_left   = -300; _narr_panel.offset_right  = 300
	_narr_panel.offset_top    = 52
	_narr_panel.modulate.a    = 0.0
	add_child(_narr_panel)
	create_tween().tween_property(_narr_panel, "modulate:a", 1.0, 0.35)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	_narr_panel.add_child(vbox)

	_narr_lbl = RichTextLabel.new()
	_narr_lbl.bbcode_enabled = true
	_narr_lbl.scroll_active  = false
	_narr_lbl.fit_content    = true
	_narr_lbl.custom_minimum_size = Vector2(528, 80)
	if _orbitron:
		_narr_lbl.add_theme_font_override("normal_font", _orbitron)
		_narr_lbl.add_theme_font_override("bold_font",   _orbitron)
	_narr_lbl.add_theme_font_size_override("normal_font_size", 13)
	_narr_lbl.add_theme_font_size_override("bold_font_size",   13)
	_narr_lbl.add_theme_color_override("default_color", Color(0.82, 0.86, 0.95))
	vbox.add_child(_narr_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 0)
	vbox.add_child(btn_row)

	var hint := Label.new()
	hint.text = "[ click anywhere to continue ]"
	if _orbitron: hint.add_theme_font_override("font", _orbitron)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(0.35, 0.40, 0.55))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(hint)

	_narr_btn = _mk_btn("Continue  ›", Color(0.65, 0.82, 1.0))
	_narr_btn.pressed.connect(_on_narr_btn)
	btn_row.add_child(_narr_btn)

	# Full-panel invisible click catcher (behind button row — but same z, so add first)
	# We catch _unhandled from the panel's gui_input instead:
	_narr_panel.gui_input.connect(_on_narr_panel_click)
	_narr_panel.mouse_filter = Control.MOUSE_FILTER_STOP

func _on_narr_panel_click(event: InputEvent) -> void:
	if not (event is InputEventMouseButton): return
	var mb := event as InputEventMouseButton
	if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		if _narr_typing:
			_narr_instant = true
		else:
			_on_narr_btn()

func _on_narr_btn() -> void:
	if _narr_typing:
		_narr_instant = true
		return
	_narr_page += 1
	if _narr_page >= _narr_pages.size():
		_close_narr()
	else:
		_type_page(_narr_page)

func _close_narr() -> void:
	var cb := _narr_done_cb; _narr_done_cb = Callable()
	_narr_instant = true
	if is_instance_valid(_narr_panel):
		var tw := create_tween()
		tw.tween_property(_narr_panel, "modulate:a", 0.0, 0.28)
		await tw.finished
	if is_instance_valid(_narr_panel): _narr_panel.queue_free(); _narr_panel = null
	if cb.is_valid(): cb.call()

func _type_page(page: int) -> void:
	if not is_instance_valid(_narr_lbl): return
	_narr_btn.disabled = true
	_narr_typing   = true
	_narr_instant  = false
	_narr_lbl.text = ""

	var lines: Array = _narr_pages[page]
	# segments: {bold, text}
	var segs: Array[Dictionary] = []
	for i in lines.size():
		segs.append({"bold": i == 0, "text": lines[i]})

	var typed_segs: Array[Dictionary] = []   # segments fully typed so far

	for si in segs.size():
		var seg: Dictionary = segs[si]
		var full: String    = seg["text"]
		var is_bold: bool   = seg["bold"]

		if _narr_instant:
			typed_segs.append(seg)
			continue

		for ci in full.length():
			if _narr_instant or not is_instance_valid(_narr_lbl): break
			var partial := full.substr(0, ci + 1)
			_narr_lbl.text = _compose_bbcode(typed_segs, is_bold, partial, true)
			AudioManager.play("tick", -19.0)
			await get_tree().create_timer(TW_NARR).timeout
			if _narr_instant or not is_instance_valid(_narr_lbl): break

		typed_segs.append(seg)
		if is_instance_valid(_narr_lbl):
			_narr_lbl.text = _compose_bbcode(typed_segs, false, "", false)

	if not is_instance_valid(_narr_lbl): return
	# Show complete page (handles instant-skip)
	_narr_lbl.text = _all_bbcode(segs)
	_narr_typing   = false
	_narr_instant  = false
	_narr_btn.disabled = false
	var is_last := page >= _narr_pages.size() - 1
	_narr_btn.text = "Begin  ›" if (is_last and _guided_step == 0) else ("Continue  ›")

func _compose_bbcode(done: Array[Dictionary], cur_bold: bool, cur_partial: String, cursor: bool) -> String:
	var r := ""
	for d in done:
		r += ("[b]" + d["text"] + "[/b]\n") if d["bold"] else ("[color=#9eadc8]" + d["text"] + "[/color]\n")
	if cur_partial != "" or cursor:
		var txt := cur_partial + ("▌" if cursor else "")
		r += ("[b]" + txt + "[/b]\n") if cur_bold else ("[color=#9eadc8]" + txt + "[/color]\n")
	return r

func _all_bbcode(segs: Array[Dictionary]) -> String:
	var r := ""
	for s in segs:
		r += ("[b]" + s["text"] + "[/b]\n") if s["bold"] else ("[color=#9eadc8]" + s["text"] + "[/color]\n")
	return r

# ── Action instruction bar ─────────────────────────────────────────────────────
func _show_action_bar(step: Dictionary) -> void:
	if is_instance_valid(_action_bar): _action_bar.queue_free()

	_action_bar = PanelContainer.new()
	var sb := _panel_style(Color(0.04, 0.05, 0.12, 0.88), Color(0.28, 0.55, 0.75, 0.55))
	_action_bar.add_theme_stylebox_override("panel", sb)
	_action_bar.custom_minimum_size = Vector2(420, 0)
	var _aa := _planet_area_center_anchor()
	_action_bar.anchor_left   = _aa;  _action_bar.anchor_right  = _aa
	_action_bar.anchor_top    = 1.0;  _action_bar.anchor_bottom = 1.0
	_action_bar.offset_left   = -210; _action_bar.offset_right  = 210
	_action_bar.offset_top    = -110; _action_bar.offset_bottom = -12
	_action_bar.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_action_bar.modulate.a    = 0.0
	add_child(_action_bar)
	create_tween().tween_property(_action_bar, "modulate:a", 1.0, 0.3)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_action_bar.add_child(vbox)

	var tag := Label.new()
	tag.text = "◈  OBJECTIVE"
	if _orbitron: tag.add_theme_font_override("font", _orbitron)
	tag.add_theme_font_size_override("font_size", 8)
	tag.add_theme_color_override("font_color", Color(0.45, 0.65, 0.90))
	vbox.add_child(tag)

	_action_lbl = Label.new()
	_action_lbl.text = ""  # set below by _target_hint
	if _orbitron: _action_lbl.add_theme_font_override("font", _orbitron)
	_action_lbl.add_theme_font_size_override("font_size", 12)
	_action_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.60))
	vbox.add_child(_action_lbl)

	var tgt0: Dictionary = step["targets"][mini(_action_sub, (step["targets"] as Array).size() - 1)]
	_action_lbl.text = _target_hint(tgt0)

	# Spawn pulse ring and signal which element to highlight
	_action_block_on = true
	_spawn_pulse_ring()
	highlight_changed.emit(_highlight_id_for(tgt0))

	if GRANTS_ENABLED and step.has("reward_text"):
		var rew := Label.new()
		rew.text = "Reward: " + step["reward_text"]
		if _orbitron: rew.add_theme_font_override("font", _orbitron)
		rew.add_theme_font_size_override("font_size", 8)
		rew.add_theme_color_override("font_color", Color(0.38, 0.85, 0.55))
		vbox.add_child(rew)

func _hide_action_bar() -> void:
	_action_block_on = false
	_allowed_rects   = []
	highlight_cleared.emit()
	_clear_pulse_ring()
	if not is_instance_valid(_action_bar): return
	var bar := _action_bar; _action_bar = null
	var tw := create_tween()
	tw.tween_property(bar, "modulate:a", 0.0, 0.25)
	tw.tween_callback(bar.queue_free)

func _show_construction_wait() -> void:
	if is_instance_valid(_construction_lbl): _construction_lbl.queue_free()

	var bar := PanelContainer.new()
	var sb := _panel_style(Color(0.04, 0.05, 0.12, 0.88), Color(0.55, 0.45, 0.20, 0.55))
	bar.add_theme_stylebox_override("panel", sb)
	bar.custom_minimum_size = Vector2(480, 0)
	var _ba := _planet_area_center_anchor()
	bar.anchor_left   = _ba;  bar.anchor_right  = _ba
	bar.anchor_top    = 1.0;  bar.anchor_bottom = 1.0
	bar.offset_left   = -240; bar.offset_right  = 240
	bar.offset_top    = -110; bar.offset_bottom = -12
	bar.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	bar.modulate.a    = 0.0
	add_child(bar)
	create_tween().tween_property(bar, "modulate:a", 1.0, 0.4)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	bar.add_child(vbox)

	var tag := Label.new()
	tag.text = "⚙  CONSTRUCTION"
	if _orbitron: tag.add_theme_font_override("font", _orbitron)
	tag.add_theme_font_size_override("font_size", 8)
	tag.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45))
	vbox.add_child(tag)

	_construction_lbl = Label.new()
	_construction_lbl.text = "Building underway — explore freely while you wait."
	if _orbitron: _construction_lbl.add_theme_font_override("font", _orbitron)
	_construction_lbl.add_theme_font_size_override("font_size", 12)
	_construction_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.60))
	_construction_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_construction_lbl)

	# Store ref on the bar so we can free it in _hide_construction_wait
	bar.set_meta("is_construction_bar", true)
	_construction_lbl.set_meta("bar_ref", bar)

func _hide_construction_wait() -> void:
	if not is_instance_valid(_construction_lbl): return
	var bar: Node = _construction_lbl.get_meta("bar_ref", null) if _construction_lbl.has_meta("bar_ref") else _construction_lbl
	_construction_lbl = null
	if not is_instance_valid(bar): return
	var tw := create_tween()
	tw.tween_property(bar, "modulate:a", 0.0, 0.3)
	tw.tween_callback(bar.queue_free)

# ── Quest panel ────────────────────────────────────────────────────────────────
func _build_quest_ui() -> void:
	if is_instance_valid(_quest_panel): _quest_panel.queue_free()
	_tracker_items.clear()

	_quest_panel = PanelContainer.new()
	var sb := _panel_style(Color(0.04, 0.05, 0.10, 0.90), Color(0.28, 0.38, 0.72, 0.55))
	_quest_panel.add_theme_stylebox_override("panel", sb)
	_quest_panel.custom_minimum_size = Vector2(260, 0)
	_quest_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_place_quest_panel()   # top-right of the screen, kept there in _process
	_quest_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_panel.modulate.a  = 0.0
	add_child(_quest_panel)
	create_tween().tween_property(_quest_panel, "modulate:a", 1.0, 0.4)

	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 8)
	_quest_panel.add_child(rv)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 6)
	rv.add_child(hdr)

	_mk_lbl(hdr, "◈", 10, Color(0.55, 0.75, 1.0))
	_mk_lbl(hdr, "OBJECTIVES", 9, Color(0.50, 0.65, 0.95))
	_build_quest_side_ui()

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(spacer)
	_quest_body.clear()

	_skip_btn = _mk_btn("skip tutorial", Color(0.38, 0.38, 0.50))
	_skip_btn.visible = _quest_step < TUTORIAL_QUEST_COUNT   # hiding is the side tab's job
	var skip_btn := _skip_btn
	skip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	skip_btn.pressed.connect(func() -> void:
		# skips the tutorial objectives only; the road to Civilization 1 stays
		if _quest_step < TUTORIAL_QUEST_COUNT:
			_quest_step = TUTORIAL_QUEST_COUNT
			_quest_sub = 0
			_build_quest_ui()
			_show_quest_step(_quest_step)
		else:
			_dismiss_quest_panel())
	skip_btn.mouse_entered.connect(func() -> void:
		TooltipManager.show_tip("Skip tutorial", "Skip the tutorial objectives; the road to Civilization 1 stays.", ""))
	skip_btn.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	hdr.add_child(skip_btn)

	var sep_sty := StyleBoxFlat.new()
	sep_sty.bg_color = Color(0.25, 0.32, 0.55, 0.35)
	sep_sty.content_margin_top = 1
	var sep1 := _hsep(sep_sty)
	rv.add_child(sep1)
	_quest_body.append(sep1)

	_title_lbl = Label.new()
	if _orbitron: _title_lbl.add_theme_font_override("font", _orbitron)
	_title_lbl.add_theme_font_size_override("font_size", 11)
	_title_lbl.add_theme_color_override("font_color", Color(0.92, 0.88, 0.55))
	rv.add_child(_title_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _orbitron: _desc_lbl.add_theme_font_override("font", _orbitron)
	_desc_lbl.add_theme_font_size_override("font_size", 9)
	_desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.78, 0.90))
	rv.add_child(_desc_lbl)

	_reward_lbl = Label.new()
	if _orbitron: _reward_lbl.add_theme_font_override("font", _orbitron)
	_reward_lbl.add_theme_font_size_override("font_size", 9)
	_reward_lbl.add_theme_color_override("font_color", Color(0.38, 0.88, 0.55))
	rv.add_child(_reward_lbl)
	var sep2 := _hsep(sep_sty)
	rv.add_child(sep2)
	_quest_body.append_array([_title_lbl, _desc_lbl, _reward_lbl, sep2])

	for i in QUESTS.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		rv.add_child(row)
		var dot := Label.new()
		dot.text = "○"
		if _orbitron: dot.add_theme_font_override("font", _orbitron)
		dot.add_theme_font_size_override("font_size", 9)
		dot.add_theme_color_override("font_color", Color(0.30, 0.36, 0.50))
		row.add_child(dot)
		var ql := Label.new()
		ql.text = QUESTS[i]["title"]
		if _orbitron: ql.add_theme_font_override("font", _orbitron)
		ql.add_theme_font_size_override("font_size", 9)
		ql.add_theme_color_override("font_color", Color(0.36, 0.42, 0.56))
		row.add_child(ql)
		_tracker_items.append({"dot": dot, "lbl": ql})

	# Pre-mark quests that were already completed (e.g. guided tutorial steps)
	for i in _quest_step:
		if i < _tracker_items.size():
			(_tracker_items[i]["dot"] as Label).text = "✓"
			(_tracker_items[i]["dot"] as Label).add_theme_color_override("font_color", Color(0.30, 0.85, 0.50))
			(_tracker_items[i]["lbl"] as Label).add_theme_color_override("font_color", Color(0.40, 0.72, 0.50))
	_apply_collapsed()

func _show_quest_step(idx: int) -> void:
	_refresh_overlay_text()
	if is_instance_valid(_skip_btn):
		_skip_btn.visible = idx < TUTORIAL_QUEST_COUNT
	if not is_instance_valid(_quest_panel) or idx >= QUESTS.size(): return
	var q: Dictionary = QUESTS[idx]
	for i in _tracker_items.size():
		var dot := _tracker_items[i]["dot"] as Label
		var ql  := _tracker_items[i]["lbl"] as Label
		if i < idx:
			dot.text = "✓"; dot.add_theme_color_override("font_color", Color(0.30, 0.85, 0.50))
			ql.add_theme_color_override("font_color", Color(0.40, 0.72, 0.50))
		elif i == idx:
			dot.text = "▶"; dot.add_theme_color_override("font_color", Color(0.92, 0.88, 0.55))
			ql.add_theme_color_override("font_color", Color(0.92, 0.88, 0.55))
		else:
			dot.text = "○"; dot.add_theme_color_override("font_color", Color(0.30, 0.36, 0.50))
			ql.add_theme_color_override("font_color", Color(0.36, 0.42, 0.56))
	_reward_lbl.text = ("Reward: " + String(q.get("reward_text", ""))) if GRANTS_ENABLED and q.has("reward_text") \
		else "Main goal: reach Civilization 1"
	if idx >= TUTORIAL_QUEST_COUNT and GRANTS_ENABLED and q.has("reward_text"):
		_reward_lbl.text += "   ·   Main goal: Civilization 1"
	# keep the list short: the previous one, the current one and the next four
	for i in _tracker_items.size():
		var row := (_tracker_items[i]["dot"] as Label).get_parent() as Control
		row.visible = i >= idx - 1 and i <= idx + 4
	_tw_label(_title_lbl, q["title"].to_upper(), 0.022)
	await get_tree().create_timer(0.022 * q["title"].length() + 0.1).timeout
	_tw_label(_desc_lbl, q["desc"], 0.022)
	if idx < TUTORIAL_QUEST_COUNT and GRANTS_ENABLED:
		_grant_step_needs(q["sub_steps"], "target")
	# Immediately check if current sub-step is already satisfied
	_check_quest_sub_already_done()

func _check_quest_sub_already_done() -> void:
	if _quest_done or _quest_step >= QUESTS.size() or not is_instance_valid(_quest_panel): return
	var q: Dictionary = QUESTS[_quest_step]
	if _quest_sub >= q["sub_steps"].size(): return
	var ss: Dictionary = q["sub_steps"][_quest_sub]
	var satisfied := false
	match ss["type"]:
		"building":
			for pp: PlanetProgress in GameState._planet_progress.values():
				if pp.has_building(ss["target"]):
					satisfied = true; break
		"district":   # built, not just placed: the next sub-step builds inside it
			satisfied = _district_built(int(ss["target"]))
		"skill":
			satisfied = get_node("/root/SkillTree").is_unlocked(String(ss["target"]))
		"event":
			satisfied = event_done(String(ss["target"]))
		"city_level_up":
			for pp: PlanetProgress in GameState._planet_progress.values():
				if _city_any_leveled(pp):
					satisfied = true; break
		"district_upgrade":
			for pp: PlanetProgress in GameState._planet_progress.values():
				if _district_any_upgraded(pp):
					satisfied = true; break
	if satisfied:
		_advance_quest_sub()

func _advance_quest_sub() -> void:
	if is_instance_valid(_skip_btn):
		_skip_btn.queue_free()
		_skip_btn = null
	var q: Dictionary = QUESTS[_quest_step]
	_quest_sub += 1
	if _quest_sub >= q["sub_steps"].size():
		if GRANTS_ENABLED:
			if q.get("reward_credits", 0.0) > 0.0: GameState.credits     += q["reward_credits"]
			if q.get("reward_science", 0.0) > 0.0: GameState.add_science(q["reward_science"])
			_flash_reward(q.get("reward_text", ""))
		else:
			_flash_reward("✓ " + String(q["title"]))
		if _quest_step < _tracker_items.size():
			(_tracker_items[_quest_step]["dot"] as Label).text = "✓"
			(_tracker_items[_quest_step]["dot"] as Label).add_theme_color_override("font_color", Color(0.30, 0.85, 0.50))
			(_tracker_items[_quest_step]["lbl"] as Label).add_theme_color_override("font_color", Color(0.40, 0.72, 0.50))
		_quest_step += 1; _quest_sub = 0
		if _quest_step >= QUESTS.size():
			await get_tree().create_timer(1.5).timeout
			_dismiss_quest_panel()
		else:
			await get_tree().create_timer(0.9).timeout
			_show_quest_step(_quest_step)
	else:
		# More sub-steps remain — check if the next one is already done too
		_check_quest_sub_already_done()

## Slides the objectives off to the right (like the left side panel); only the
## current objective stays, as a small outlined line of text. O toggles; saved.
func toggle_objectives() -> void:
	_collapsed = not _collapsed
	_apply_collapsed()
	GameState.save()

func _apply_collapsed() -> void:
	if is_instance_valid(_side_tab):
		_side_tab.text = "‹" if _collapsed else "›"
	if is_instance_valid(_overlay_lbl):
		var tw := _overlay_lbl.create_tween()
		tw.tween_property(_overlay_lbl, "modulate:a", 1.0 if _collapsed else 0.0, 0.25)

## The edge tab (hide / show) and the outlined current-objective line.
func _build_quest_side_ui() -> void:
	for n: Node in [_side_tab, _overlay_lbl]:
		if is_instance_valid(n):
			n.queue_free()
	_side_tab = Button.new()
	_side_tab.focus_mode = Control.FOCUS_NONE
	if _orbitron: _side_tab.add_theme_font_override("font", _orbitron)
	_side_tab.add_theme_font_size_override("font_size", 11)
	_side_tab.add_theme_color_override("font_color", Color(0.65, 0.78, 1.0))
	var ts := _panel_style(Color(0.04, 0.05, 0.10, 0.90), Color(0.28, 0.38, 0.72, 0.55))
	ts.content_margin_left = 5
	ts.content_margin_right = 5
	ts.content_margin_top = 14
	ts.content_margin_bottom = 14
	_side_tab.add_theme_stylebox_override("normal", ts)
	var th := ts.duplicate() as StyleBoxFlat
	th.bg_color = Color(0.10, 0.14, 0.26, 0.95)
	_side_tab.add_theme_stylebox_override("hover", th)
	_side_tab.pressed.connect(toggle_objectives)
	_side_tab.mouse_entered.connect(func() -> void:
		TooltipManager.show_tip("Objectives", ("Show" if _collapsed else "Hide") + " the objectives (O).", ""))
	_side_tab.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	add_child(_side_tab)

	_overlay_lbl = Label.new()
	if _orbitron: _overlay_lbl.add_theme_font_override("font", _orbitron)
	_overlay_lbl.add_theme_font_size_override("font_size", 11)
	_overlay_lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.35))
	_overlay_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_overlay_lbl.add_theme_constant_override("outline_size", 6)
	_overlay_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_overlay_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_lbl.modulate.a = 1.0 if _collapsed else 0.0
	_overlay_lbl.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
				and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and _collapsed:
			toggle_objectives())
	add_child(_overlay_lbl)
	_refresh_overlay_text()

func _refresh_overlay_text() -> void:
	if not is_instance_valid(_overlay_lbl):
		return
	if _quest_done or _quest_step >= QUESTS.size():
		_overlay_lbl.text = ""
		return
	_overlay_lbl.text = "◈  " + String(QUESTS[_quest_step]["title"])

func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or k.keycode != KEY_O or k.ctrl_pressed or k.meta_pressed:
		return
	if is_instance_valid(_quest_panel) and _quest_panel.visible and not _quest_done:
		get_viewport().set_input_as_handled()
		toggle_objectives()

## Objectives sit at the top-right, below the settings button and clear of the map's middle.
func _place_quest_panel() -> void:
	var vp := get_viewport().get_visible_rect().size
	var y := 72.0
	# the planet view's neighbouring bodies take the same corner when zoomed
	# out — step below them so they stay clickable
	for n in get_tree().get_nodes_in_group("companion_bodies"):
		var bottom: float = n.call("occupied_bottom")
		if bottom > 0.0:
			y = maxf(y, bottom + 12.0)
	var w := maxf(_quest_panel.size.x, 260.0)
	# hidden: slid off past the right edge (the tab and overlay stay)
	var target := Vector2(vp.x + 8.0 if _collapsed else vp.x - w - 24.0, y)
	# glide rather than jump (sliding away, bodies moving in and out)
	_quest_panel.position = target if _quest_panel.position == Vector2.ZERO \
		else _quest_panel.position.lerp(target, 0.2)
	var live := not _quest_done and _active
	if is_instance_valid(_side_tab):
		_side_tab.visible = live
		_side_tab.reset_size()
		var tab_x := vp.x - _side_tab.size.x if _collapsed else _quest_panel.position.x - _side_tab.size.x + 1.0
		_side_tab.position = Vector2(tab_x, y + 18.0)
	if is_instance_valid(_overlay_lbl):
		_overlay_lbl.visible = live
		_overlay_lbl.reset_size()
		var tab_w := _side_tab.size.x if is_instance_valid(_side_tab) else 0.0
		_overlay_lbl.position = Vector2(vp.x - tab_w - _overlay_lbl.size.x - 10.0, y + 22.0)

func _dismiss_quest_panel() -> void:
	_quest_done = true
	for n: Node in [_side_tab, _overlay_lbl]:
		if is_instance_valid(n):
			n.queue_free()
	if is_instance_valid(_quest_panel):
		var tw := create_tween()
		tw.tween_property(_quest_panel, "modulate:a", 0.0, 0.5)
		await tw.finished
		if is_instance_valid(_quest_panel): _quest_panel.queue_free(); _quest_panel = null

## Skipping the optional objectives pays out the home world's raw resource.
const SKIP_REWARD_RAW := "ferrite"

func _give_skip_minerals() -> void:
	var rd := ResourceData.from_raw(Economy.raw_info(SKIP_REWARD_RAW))
	var rid := rd.resource_id()
	if not GameState.known_resources.has(rid): GameState.known_resources[rid] = rd
	GameState.add_resource(rid, SKIP_MINERAL_AMOUNT)

func _flash_skip_reward(pos: Vector2) -> void:
	var rd := ResourceData.from_raw(Economy.raw_info(SKIP_REWARD_RAW))
	var ore_icon := MineralIcon.make(rd.tier, rd.display_color)

	var root := HBoxContainer.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_theme_constant_override("separation", 4)
	root.position = pos + Vector2(-30, -20)
	root.modulate.a = 0.0

	var icon_rect := TextureRect.new()
	icon_rect.texture = ore_icon
	icon_rect.custom_minimum_size = Vector2(14, 14)
	icon_rect.size = Vector2(14, 14)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	icon_rect.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(icon_rect)

	var lbl := Label.new()
	lbl.text = "+%.0f" % SKIP_MINERAL_AMOUNT
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _orbitron: lbl.add_theme_font_override("font", _orbitron)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", rd.display_color)
	root.add_child(lbl)

	add_child(root)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(root, "modulate:a", 1.0, 0.15)
	tw.tween_property(root, "position:y", root.position.y - 50, 1.0)
	await get_tree().create_timer(0.15).timeout
	create_tween().tween_property(root, "modulate:a", 0.0, 0.5).set_delay(0.4)
	await get_tree().create_timer(0.9).timeout
	if is_instance_valid(root): root.queue_free()

# ── Reward flash ──────────────────────────────────────────────────────────────
func _flash_reward(text: String) -> void:
	var anchor: Control = _quest_panel if is_instance_valid(_quest_panel) else _action_bar
	if not is_instance_valid(anchor): return
	var flash := Label.new()
	flash.text = "+ " + text
	if _orbitron: flash.add_theme_font_override("font", _orbitron)
	flash.add_theme_font_size_override("font_size", 14)
	flash.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
	flash.position = anchor.position + Vector2(16, -28)
	add_child(flash)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(flash, "position:y", flash.position.y - 44, 1.2)
	tw.tween_property(flash, "modulate:a", 0.0, 1.2)
	await tw.finished
	if is_instance_valid(flash): flash.queue_free()

# ── Inventory hint ─────────────────────────────────────────────────────────────
func _show_inventory_hint() -> void:
	var hint := Label.new()
	hint.text = "◈  Your stockpile is in the top bar — hover ⛏ Raw for details"
	if _orbitron: hint.add_theme_font_override("font", _orbitron)
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 3)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(_side_panel_edge() + 20.0, -140)
	hint.modulate.a = 0.0
	add_child(hint)
	var tw := create_tween()
	tw.tween_property(hint, "modulate:a", 1.0, 0.4)
	tw.tween_interval(4.5)
	tw.tween_property(hint, "modulate:a", 0.0, 0.6)
	await tw.finished
	if is_instance_valid(hint): hint.queue_free()

# ── Typewriter (plain Label) ──────────────────────────────────────────────────
func _tw_label(lbl: Label, text: String, spd: float) -> void:
	if not is_instance_valid(lbl): return
	lbl.text = ""
	for i in text.length():
		await get_tree().create_timer(spd).timeout
		if not is_instance_valid(lbl): return
		lbl.text = text.substr(0, i + 1) + "▌"
	if is_instance_valid(lbl):
		lbl.text = text

# ── Style helpers ─────────────────────────────────────────────────────────────
func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.set_border_width_all(1); s.set_corner_radius_all(7)
	s.content_margin_left = 22; s.content_margin_right  = 22
	s.content_margin_top  = 18; s.content_margin_bottom = 16
	return s

func _mk_lbl(parent: Node, txt: String, sz: int, col: Color) -> Label:
	var l := Label.new()
	l.text = txt
	if _orbitron: l.add_theme_font_override("font", _orbitron)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

func _mk_btn(txt: String, col: Color) -> Button:
	var b := Button.new()
	b.text = txt; b.flat = true
	if _orbitron: b.add_theme_font_override("font", _orbitron)
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_color_override("font_color", col)
	return b

func _hsep(sty: StyleBoxFlat) -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_stylebox_override("separator", sty)
	return s
