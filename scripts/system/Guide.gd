## Guide — autoload. The tutorial the chosen AI runs (docs/design/narrative,
## SCENES.md "AI ile tamamlanan öğretici"), rebuilt 10.11 to lead the way like
## the first tutorial did: each step is one concrete goal on the objectives card
## (the advisor's words, a checklist of what to press, a "how" line for mouse
## and keys, the reward), the advisor says it once in the dialogue panel and the
## game runs on. What to press next pulses on screen (and, playing with the
## keys, comes up selected). A step is done when the game shows it done, also
## if the player got there first; its reward is paid then.
##   guide_city        the home world's first City stands
##   guide_district    a Residential District stands
##   guide_building    a building stands in it (Low-rise Housing)
##   guide_commerce    a Commercial District with a building (Market)
##   guide_energy      an Energy District with a building (Solar Array)
##   guide_science     a Science District with a building (Field Lab)
##   guide_research    something researched in the Upgrade Tree
##   guide_level       a district levelled up
##   guide_city_level  the City levelled up
##   guide_done        the last line; the tutorial is over
## Beside the step the card offers what the story may add on the side: the
## ship's record after the Capital, the first ruin's signal once the City stands.
## Played once (SettingsManager.tutorial_ever_done, set when it ends), later
## games get the same steps as an optional checklist instead (10.11, like the
## first tutorial): no lines, nothing pulses, any order, each pays when done.
## Settings → Reset Tutorial brings the guided run back.
## Saved: GameState.tutorial_step ("" before the handover, a step id, "done");
## rewards paid: GameState.story_flags "guide_paid:<step>" (never twice).
extends CanvasLayer

const GRAPH := "res://resources/narrative/tutorial.tres"
const RECORDS := "res://resources/narrative/ship_records.tres"
## (10.11: no "Open the Capital District" step any more: it sent the player
## into the Capital and the next step straight back out to add a district.)
const STEPS := ["guide_city", "guide_district", "guide_building", "guide_commerce",
	"guide_energy", "guide_science", "guide_research", "guide_level", "guide_city_level", "guide_done"]
const TITLES := {
	"guide_city": "Found your first City",
	"guide_district": "Place a Residential District",
	"guide_building": "Build the first homes",
	"guide_commerce": "Open a Market",
	"guide_energy": "Power the City",
	"guide_science": "Start the research",
	"guide_research": "Research a technology",
	"guide_level": "Level up a district",
	"guide_city_level": "Level up the City",
	"guide_done": "Continue developing your City",
}
## Paid when the step is done (resource id → amount; shown as icons).
const REWARDS := {
	"guide_district": {"credits": 200.0},
	"guide_building": {"credits": 150.0},
	"guide_commerce": {"credits": 300.0},
	"guide_energy": {"credits": 300.0},
	"guide_science": {"science": 50.0},
	"guide_research": {"science": 50.0},
	"guide_level": {"credits": 400.0},
	"guide_city_level": {"credits": 600.0},
}
## The steps the tutorial graph has no line for: said as plain lines, by advisor.
const LINES := {
	"guide_district": {
		"mother_superior": "People need homes before anything else. Place a Residential District within the City.",
		"high_father": "Housing first. Add a Residential District inside the City's reach."},
	"guide_building": {
		"mother_superior": "Now open it and give the families their first homes: Low-rise Housing.",
		"high_father": "Open the Residential District, choose an empty slot and build Low-rise Housing."},
	"guide_commerce": {
		"mother_superior": "People need somewhere to trade. A Commercial District with a Market keeps the City's coffers filling.",
		"high_father": "Add a Commercial District, then a Market in it. It turns the residents' work into steady income."},
	"guide_energy": {
		"mother_superior": "Everything we build draws power. An Energy District with a Solar Array will keep the lights on.",
		"high_father": "The grid runs short as the City grows. Place an Energy District and fit a Solar Array."},
	"guide_science": {
		"mother_superior": "Curious minds are worth more than anything we carried here. Give them a Science District and a Field Lab.",
		"high_father": "Research needs a Science District. Fit a Field Lab to start the work."},
	"guide_research": {
		"mother_superior": "What the lab learns, we can use. Open the Upgrade Tree and choose something to research.",
		"high_father": "Open the Upgrade Tree. Spend what the lab produces on your first technology."},
	"guide_level": {
		"mother_superior": "A district can grow. Open one and level it up; it will give more.",
		"high_father": "Open a district and press LEVEL UP. Higher levels raise its output."},
	"guide_city_level": {
		"mother_superior": "The City itself can grow too, and make room for more districts.",
		"high_father": "Level up the City from its panel. Each City level opens more district slots."},
}
const FIRST_RUIN := "vesyn_toppled_stones"
## The guided run keeps the player on its step (10.11): over the game's UI
## (left panel 228, news 229, top bar 230), under the story (233) and popups.
const BLOCK_LAYER := 231

## A full-screen catcher with holes: clicks land only where the step allows.
class _Blocker extends Control:
	var holes: Array[Rect2] = []
	func _has_point(point: Vector2) -> bool:
		for r in holes:
			if r.has_point(point):
				return false
		return true
## How to press what pulses, for the mouse and for the keys.
const HOW_PRESS := "Click it  //  keys: ↑ ↓ to it, Enter"
const HOW_PLACE := "Click a spot on the globe  //  keys: WASD to aim, Enter to place"
const HOW_WAIT := "It builds by itself; the game runs on."
const PULSE := Color(2.0, 1.85, 1.3, 1.0)

var _card: ObjectivesCard = null
var _hero: HeroHeader = null
var _desc: RichTextLabel = null
var _checks: RichTextLabel = null
var _reward: RichTextLabel = null
var _shown_step := ""
var _poll := 0.0
var _capital_opened := false
var _progress := -1   # the furthest sub-step of the shown step seen done (never goes back)
var _subs_text := ""
var _target: Control = null
var _target_tw: Tween = null
var _focused_goal := ""
var _block_layer: CanvasLayer = null
var _blocker: _Blocker = null
var _cur_sub: Dictionary = {}   # the guided step's current sub-step (what it allows)

func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.onboarding_finished.connect(func() -> void:
		if GameState.tutorial_step == "":
			GameState.tutorial_step = STEPS[0])
	GameState.save_deleted.connect(_reset)

## The Capital District panel opened (PlanetaryView).
func note_capital_opened() -> void:
	_capital_opened = true

## The tutorial is running.
func is_active() -> bool:
	return GameState.tutorial_step != "" and GameState.tutorial_step != "done"

func _reset() -> void:
	_cur_sub = {}
	_capital_opened = false
	_shown_step = ""
	_progress = -1
	_set_target(null)
	if _card != null and is_instance_valid(_card):
		_card.queue_free()
	_card = null

func _process(delta: float) -> void:
	_update_blocker()
	var step := GameState.tutorial_step
	if step != "" and step != "done" and not STEPS.has(step):
		GameState.tutorial_step = STEPS[0]   # a step id of an older build: start over (done ones pass at once)
		step = STEPS[0]
	if step == "" or step == "done" or NewsFeed.on_main_menu() or GameState.showcase_mode:
		if _card != null and is_instance_valid(_card):
			_card.active = false
		_set_target(null)
		return
	if checklist_mode():
		_process_checklist(delta)
		return
	if _shown_step == CHECKLIST:
		_shown_step = ""   # Reset Tutorial: back to the guided run
	if step != _shown_step:
		var pre := _subs(step) if step != "guide_done" else []
		if not pre.is_empty() and bool(pre[-1]["done"]):
			_advance(step)   # done before it came up (an older save, a quick player): paid, not said
			return
		_show_step(step)
	_poll += delta
	if _poll < 0.25:
		return
	_poll = 0.0
	_refresh_extras()
	if step == "guide_done":
		_set_target(null)
		return
	var subs := _subs(step)
	# the furthest sub-step done now (10.11: not "ever": opening another
	# district's page ticked "Open the district" for good and the step stuck)
	_progress = -1
	for i in range(subs.size() - 1, -1, -1):
		if bool(subs[i]["done"]):
			_progress = i
			break
	if _progress >= subs.size() - 1:
		_advance(step)
		return
	_refresh_checks(subs)
	var cur: Dictionary = subs[_progress + 1]
	_cur_sub = cur
	var t := _find_target(cur.get("find", []))
	if t == null and not (cur.get("find", []) as Array).is_empty():
		t = _way_back()   # on another district's page: only the way back (11.11)
	_set_target(t)

func _advance(step: String) -> void:
	_pay(step)
	var i := STEPS.find(step)
	GameState.tutorial_step = STEPS[mini(i + 1, STEPS.size() - 1)]
	_set_target(null)
	AudioManager.play("building_done")
	NewsFeed.post("Tutorial: %s." % String(TITLES[step]), NewsFeed.Kind.EVENT, "", "", {}, false)

func _pay(step: String) -> void:
	var flag := "guide_paid:" + step
	if GameState.story_flags.has(flag):
		return
	GameState.story_flags[flag] = true
	var r: Dictionary = REWARDS.get(step, {})
	for id: String in r:
		if id == Economy.CREDITS:
			GameState.earn_credits(float(r[id]))
		elif id == Economy.SCIENCE:
			GameState.add_science(float(r[id]))
		else:
			GameState.add_resource(id, float(r[id]))

func _advisor() -> String:
	return GameState.active_advisor if GameState.active_advisor != "" else "mother_superior"

## The step's card, and its line said once in the panel.
func _show_step(step: String) -> void:
	_shown_step = step
	_progress = -1
	_cur_sub = {}
	_subs_text = ""
	_ensure_card()
	var i := STEPS.find(step)
	_hero.caption = "Tutorial  //  %d / %d" % [i + 1, STEPS.size()]
	_hero.title = String(TITLES[step]).to_upper()
	_card.tip_title = String(TITLES[step])
	var def := CompanionDef.find(_advisor())
	_desc.text = "[color=#%s]%s[/color]\n%s" % [UIStyle.hex(&"text_subtle"),
		def.display_name if def != null else "", _line_text(step)]
	_reward.text = _reward_bb(step)
	_reward.visible = _reward.text != ""
	_skip.visible = false
	_checks.text = ""
	_card.active = true
	_card.reveal()
	NewsFeed.flag_new_objective()
	var on_done := Callable()
	if step == "guide_done":
		on_done = func(_exit: String) -> void: _finish()
	var queued: bool
	if LINES.has(step):
		queued = Narrative.play("", step, {"id": "guide:" + step, "main": false, "on_done": on_done,
			"lines": [[def.display_name if def != null else "Mother Superior", _line_text(step)]]})
	else:
		queued = Narrative.play(GRAPH, "%s_%s" % [step, _advisor()], {"id": step, "main": false, "on_done": on_done})
	if not queued and step == "guide_done":
		_finish()   # said already (a game closed right after it)

## The tutorial is over: its card goes; the usual objectives take its place.
func _finish() -> void:
	GameState.tutorial_step = "done"
	if not SettingsManager.tutorial_ever_done:   # later games: the optional checklist
		SettingsManager.tutorial_ever_done = true
		SettingsManager.save_settings()
	_set_target(null)
	if _card != null and is_instance_valid(_card):
		_card.active = false
	NewsFeed.post("Tutorial complete. The City is yours to grow.", NewsFeed.Kind.EVENT)

func _reward_bb(step: String) -> String:
	var r: Dictionary = REWARDS.get(step, {})
	if r.is_empty():
		return ""
	var parts: Array[String] = []
	for id: String in r:
		parts.append("%s [color=#%s]+%s[/color]" % [UIIcons.bb(id, 11, Economy.color_of(id)),
			UIStyle.hex(&"good"), Economy.fmt(float(r[id]))])
	return "[color=#%s]Reward[/color]   %s" % [UIStyle.hex(&"text_subtle"), "   ".join(parts)]

# ── Keeping to the step (guided run) ─────────────────────────────────────────
## The guided run is on a step the player must follow (not the checklist, not
## the last line, in the planet view).
func blocking() -> bool:
	if checklist_mode() or GameState.showcase_mode or NewsFeed.on_main_menu():
		return false
	var step := GameState.tutorial_step
	if not STEPS.has(step) or step == "guide_done" or step != _shown_step or _cur_sub.is_empty():
		return false
	var scene := get_tree().current_scene
	return scene != null and scene.has_method("_set_panel_open")

## What to press is on screen: only it may be used. Missing (the panel shut, or
## on another page), the left panel stays free so the player can get there.
func _strict() -> bool:
	return _target != null and is_instance_valid(_target) and _target.is_visible_in_tree()

## Steps the step lets run free: placing on the globe, the Upgrade Tree.
func _free_now() -> bool:
	var scene := get_tree().current_scene
	if scene != null and scene.get("_placing_def") != null:
		return true
	if SkillTreeView.is_open:
		return true
	return String(_cur_sub.get("how", "")) == HOW_PLACE

## LeftPanel's keys: only the target while it is on screen; nothing to press
## (a wait): nothing; missing: the panel as it is.
func nav_filter(items: Array[Control]) -> Array[Control]:
	if not blocking() or _free_now():
		return items
	var only: Array[Control] = []
	if _strict():
		if items.has(_target):
			only.append(_target)
		return only
	if String(_cur_sub.get("how", "")) == HOW_WAIT:
		return only
	return items

## Tab, Backspace / Esc in the panel: not while the target is up (they'd lead away).
func blocks_panel_keys() -> bool:
	return blocking() and not _free_now() and (_strict() or String(_cur_sub.get("how", "")) == HOW_WAIT)

## A shortcut ("trade", "tree", "companions" …) the step allows.
func allows_shortcut(which: String) -> bool:
	if not blocking():
		return true
	return which == "tree" and GameState.tutorial_step == "guide_research"

func _update_blocker() -> void:
	var on := blocking() and not _free_now()
	if not on:
		if _blocker != null and is_instance_valid(_blocker):
			_blocker.visible = false
		return
	if _blocker == null or not is_instance_valid(_blocker):
		_block_layer = CanvasLayer.new()
		_block_layer.layer = BLOCK_LAYER
		add_child(_block_layer)
		_blocker = _Blocker.new()
		_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		_blocker.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed \
					and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				AudioManager.play("denied"))   # not now: follow the step
		_block_layer.add_child(_blocker)
	_blocker.visible = true
	var holes: Array[Rect2] = []
	if _card != null and is_instance_valid(_card) and _card.is_visible_in_tree():
		holes.append(_card.get_global_rect())
	var rb = HUDManager.get("credits_panel")
	if rb != null and is_instance_valid(rb):
		holes.append((rb as Control).get_global_rect())   # the top bar's tips
	var news = NewsFeed.get("_bar")
	if news != null and is_instance_valid(news) and (news as Control).is_visible_in_tree():
		holes.append((news as Control).get_global_rect())
	if _strict():
		holes.append(_target.get_global_rect().grow(2.0))
	elif not (_cur_sub.get("find", []) as Array).is_empty() or String(_cur_sub.get("how", "")) == HOW_PRESS:
		# what to press isn't on screen: the left panel (and its arrow) stay free
		for n in get_tree().get_nodes_in_group(LeftPanel.GROUP):
			if n is Control and (n as Control).is_visible_in_tree():
				holes.append((n as Control).get_global_rect())
		var scene := get_tree().current_scene
		var arrow = scene.get("_panel_toggle_btn") if scene != null else null
		if arrow != null and is_instance_valid(arrow) and (arrow as Control).is_visible_in_tree():
			holes.append((arrow as Control).get_global_rect())
		for root in _search_roots():
			if root is CanvasLayer:   # an open dropdown
				for c in root.get_children():
					if c is Control:
						holes.append((c as Control).get_global_rect())
	_blocker.holes = holes

# ── Optional checklist (after the first run) ─────────────────────────────────
const CHECKLIST := "__checklist"

## The tutorial was played through once: later games get the checklist.
func checklist_mode() -> bool:
	return not GameState.tutorial_guided   # chosen at New Game (SessionPrep, 11.11)

## What skipping the checklist pays: every reward not paid yet, summed.
func skip_rewards() -> Dictionary:
	var total := {}
	for step: String in STEPS:
		if GameState.story_flags.has("guide_paid:" + step):
			continue
		var r: Dictionary = REWARDS.get(step, {})
		for id: String in r:
			total[id] = float(total.get(id, 0.0)) + float(r[id])
	return total

func _ask_skip() -> void:
	AudioManager.play("click")
	var total := skip_rewards()
	var parts: Array[String] = []
	for id: String in total:
		parts.append("%s [color=#%s]+%s[/color]" % [UIIcons.bb(id, 12, Economy.color_of(id)),
			UIStyle.hex(&"good"), Economy.fmt(float(total[id]))])
	var host := get_tree().current_scene
	if host == null:
		return
	ConfirmPanel.ask(host, "Skip the first steps?",
		"The checklist goes away and you get all of its rewards now:\n\n%s" % "   ".join(parts),
		"SKIP", skip_tutorial, false)

## Ends the checklist and pays every reward not paid yet.
func skip_tutorial() -> void:
	for step: String in STEPS:
		_pay(step)   # flagged: never twice
	GameState.tutorial_step = "done"
	_set_target(null)
	if _card != null and is_instance_valid(_card):
		_card.active = false
	AudioManager.play("building_done")
	NewsFeed.post("First steps skipped: their rewards are yours.", NewsFeed.Kind.EVENT)

## Settings → Reset Tutorial: the guided run again, from the step this game
## is at (done steps pass at once, their rewards aren't paid twice).
func reset_tutorial() -> void:
	SettingsManager.tutorial_ever_done = false
	SettingsManager.save_settings()
	GameState.tutorial_guided = true
	if GameState.onboarding_stage == "done" and GameState.tutorial_step == "done":
		GameState.tutorial_step = STEPS[0]
	_shown_step = ""
	_progress = -1

func _process_checklist(delta: float) -> void:
	_set_target(null)
	if _shown_step != CHECKLIST:
		_shown_step = CHECKLIST
		_ensure_card()
		_hero.caption = "Optional  //  first steps"
		_hero.title = "FIRST STEPS"
		_card.tip_title = "First steps"
		_desc.text = "[color=#%s]Do them in any order; each one pays when it is done.[/color]" % UIStyle.hex(&"text_subtle")
		_reward.visible = false
		_skip.visible = true
		_subs_text = ""
		_card.active = true
		_card.reveal()
		_poll = 1.0
	_poll += delta
	if _poll < 0.5:
		return
	_poll = 0.0
	_refresh_extras()
	var good := UIStyle.hex(&"good")
	var dim := UIStyle.hex(&"text_subtle")
	var lines: Array[String] = []
	var left := 0
	for step: String in STEPS:
		if step == "guide_done":
			continue
		var subs := _subs(step)
		var done: bool = bool(subs[-1]["done"]) or GameState.story_flags.has("guide_paid:" + step)
		if done and not GameState.story_flags.has("guide_paid:" + step):
			_pay(step)
			AudioManager.play("building_done")
			NewsFeed.post("First step done: %s." % String(TITLES[step]), NewsFeed.Kind.EVENT, "", "", {}, false)
		if done:
			lines.append("%s [color=#%s]%s[/color]" % [UIIcons.bb("confirm", 10, UIStyle.color(&"good")), dim, TITLES[step]])
		else:
			left += 1
			var rb := _reward_icons(step)
			lines.append("[color=#%s]·[/color]  %s%s" % [good, TITLES[step], ("   " + rb) if rb != "" else ""])
	var t := "\n".join(lines)
	if t != _subs_text:
		_subs_text = t
		_checks.text = t
		_hero.caption = "Optional  //  %d / %d" % [STEPS.size() - 1 - left, STEPS.size() - 1]
	if left == 0:
		GameState.tutorial_step = "done"
		if _card != null and is_instance_valid(_card):
			_card.active = false
		NewsFeed.post("All first steps done. The City is yours to grow.", NewsFeed.Kind.EVENT)

func _reward_icons(step: String) -> String:
	var r: Dictionary = REWARDS.get(step, {})
	var parts: Array[String] = []
	for id: String in r:
		parts.append("%s [color=#%s]+%s[/color]" % [UIIcons.bb(id, 10, Economy.color_of(id)),
			UIStyle.hex(&"good"), Economy.fmt(float(r[id]))])
	return "  ".join(parts)

# ── Sub-steps ────────────────────────────────────────────────────────────────
## The checklist of `step`: [{ "text", "find": [labels of what to press],
## "how", "done" }], in order. A later one done counts the earlier ones done.
func _subs(step: String) -> Array:
	var pd := GameState.get_planet_data(GameState.home_planet_seed)
	var pp := GameState.get_planet(GameState.home_planet_seed)
	if pd == null or pp == null:
		return [{"text": TITLES[step], "find": [], "how": "", "done": false}]
	var city := _city(pd)
	var city_name := city.shown_name().to_upper() if city != null else ""
	var city_word := city.shown_name() if city != null else "the City"
	var placing := _placing_type()
	match step:
		"guide_city":
			return [
				{"text": "Press NEW CITY", "find": ["NEW CITY"], "how": HOW_PRESS,
					"done": placing == DistrictDef.Type.CITY or city != null},
				{"text": "Pick a spot on the globe and name the City", "find": [], "how": HOW_PLACE,
					"done": city != null},
				{"text": "Wait for it to be built", "find": [], "how": HOW_WAIT,
					"done": city != null and not city.constructing}]
		"guide_district":
			return _district_subs(pd, city_name, city_word, DistrictDef.Type.RESIDENTIAL, "Residential District", placing)
		"guide_building":
			return _building_subs(pd, pp, DistrictDef.Type.RESIDENTIAL, "Low-rise Housing")
		"guide_commerce":
			return _district_subs(pd, city_name, city_word, DistrictDef.Type.COMMERCIAL, "Commercial District", placing) \
				+ _building_subs(pd, pp, DistrictDef.Type.COMMERCIAL, "Market")
		"guide_energy":
			return _district_subs(pd, city_name, city_word, DistrictDef.Type.GENERATOR, "Energy District", placing) \
				+ _building_subs(pd, pp, DistrictDef.Type.GENERATOR, "Solar Array")
		"guide_science":
			return _district_subs(pd, city_name, city_word, DistrictDef.Type.SCIENCE, "Science District", placing) \
				+ _building_subs(pd, pp, DistrictDef.Type.SCIENCE, "Field Lab")
		"guide_research":
			var researched := SessionPrep.researched_beyond_start()
			return [
				{"text": "Press UPGRADE TREE", "find": ["UPGRADE TREE"], "how": "Click it  //  keys: U",
					"done": SkillTreeView.is_open or researched},
				{"text": "Pick a lit node and research it", "find": [],
					"how": "Click a node  //  keys: arrows to it, Enter", "done": researched}]
		"guide_level":
			# levels spread out from the Capital (KARARLAR §9): a district goes up
			# only once a road-linked neighbour is there, and the Capital District
			# goes first (11.11: the step asked for a district that couldn't)
			var scene := get_tree().current_scene
			var page = scene.get("_active_district_poi") if scene != null else null
			var levelled := _any_district_level(pd, pp) >= 2
			var cand: POIData = null
			var any_up := false
			for p: POIData in pd.custom_pois:
				if p.is_city() or p.is_orbital() or p.constructing:
					continue
				if pp.is_district_upgrading(p.label):
					any_up = true
				elif cand == null and Leveling.district_level_block(pd, pp, p) == "":
					cand = p
			var subs_l: Array = []
			var cap_lv := int(pp.district_levels.get(city.label, 1)) if city != null else 1
			var cap_up := city != null and pp.is_district_upgrading(city.label)
			if city != null and not levelled and not any_up and (cand == null or cap_lv >= 2 or cap_up):
				var on_cap: bool = page != null and is_instance_valid(page) and page == city
				var cap_name := city.capital_shown_name()
				if on_cap and cap_lv < 2 and not cap_up:
					_grant_missing("district_lv:" + city.label, {Economy.CREDITS: Leveling.district_level_credits(cap_lv + 1)})
				subs_l.append({"text": "Open the Capital District, %s" % cap_name, "find": [cap_name.to_upper()],
					"how": HOW_PRESS, "done": on_cap or cap_lv >= 2 or cap_up})
				subs_l.append({"text": "Press LEVEL UP: levels spread out from the Capital", "find": ["LEVEL UP"] if on_cap else [],
					"how": HOW_PRESS, "done": cap_lv >= 2 or cap_up})
				subs_l.append({"text": "Wait for it to level up", "find": [], "how": HOW_WAIT, "done": cap_lv >= 2})
			var on_cand: bool = cand != null and page != null and is_instance_valid(page) and page == cand
			if on_cand and not levelled:
				var dlv := int(pp.district_levels.get(cand.label, 1))
				_grant_missing("district_lv:" + cand.label, {Economy.CREDITS: Leveling.district_level_credits(dlv + 1)})
			var cname := cand.shown_name() if cand != null else "a district linked to the Capital"
			subs_l.append({"text": "Open %s" % cname, "find": [cand.shown_name().to_upper()] if cand != null else [],
				"how": HOW_PRESS, "done": on_cand or levelled or any_up})
			subs_l.append({"text": "Press LEVEL UP", "find": ["LEVEL UP"] if on_cand else [], "how": HOW_PRESS,
				"done": levelled or any_up})
			subs_l.append({"text": "Wait for it to level up", "find": [], "how": HOW_WAIT, "done": levelled})
			return subs_l
		"guide_city_level":
			var lv := Leveling.city_level(pp, city) if city != null else 1
			if city != null and lv < 2 and Leveling.city_level_block(pd, pp, city) == "":
				_grant_missing("city_lv%d" % (lv + 1), {Economy.CREDITS: Leveling.city_level_credits(lv + 1)})
			return [
				{"text": "Open %s" % city_word, "find": [city_name], "how": HOW_PRESS,
					"done": _visible("CITY LV") or lv >= 2},
				{"text": "Press CITY LV", "find": ["CITY LV"], "how": HOW_PRESS, "done": lv >= 2}]
	return [{"text": TITLES[step], "find": [], "how": "", "done": false}]

## The guided run never stalls on a price (11.11: no credits left for the
## Science District after the City's level-up): what a step's district or
## building costs and the player lacks is granted, once per step and thing.
func _grant_missing(key: String, cost: Dictionary) -> void:
	if checklist_mode() or cost.is_empty() or GameState.story_flags.has("guide_grant:" + key):
		return
	var short := {}
	for id: String in cost:
		var need := float(cost[id])
		var have := GameState.credits if id == Economy.CREDITS else Economy.payable_amount(id)
		if need > have + 0.001:
			short[id] = need - have
	if short.is_empty():
		return
	GameState.story_flags["guide_grant:" + key] = true
	for id: String in short:
		if id == Economy.CREDITS:
			GameState.earn_credits(ceilf(float(short[id])))
		else:
			Economy.add(id, ceilf(float(short[id])))
	NewsFeed.post("Your advisor finds what the next step needs.", NewsFeed.Kind.EVENT, "", "", {}, false)

func _district_subs(pd: PlanetData, city_name: String, city_word: String, type: int, dname: String, placing: int) -> Array:
	var have := _has_district(pd, type)
	var picking := _visible(dname.to_upper())
	var lead: Array = []
	# a full City takes no new district: level it up first (10.11: the step
	# said ADD DISTRICT with no room for one)
	var city := _city(pd)
	var pp := GameState.get_planet(pd.seed)
	if city != null and pp != null and not have and placing != type:
		var lv := Leveling.city_level(pp, city)
		if Leveling.city_district_count(pd, city) >= Leveling.city_max_districts(lv, pd):
			# the guided run never stalls on this: what the level-up lacks is granted, once
			var price := Leveling.city_level_credits(lv + 1)
			var flag := "guide_grant:city_lv%d" % (lv + 1)
			if not checklist_mode() and GameState.credits < price and not GameState.story_flags.has(flag):
				GameState.story_flags[flag] = true
				GameState.earn_credits(price - GameState.credits)
				NewsFeed.post("Your advisor finds the funds for the City's level-up.", NewsFeed.Kind.EVENT, "", "", {}, false)
			lead.append({"text": "%s is full: open it and press CITY LV" % city_word, "find": ["CITY LV", city_name],
				"how": HOW_PRESS, "done": false})
	# the district's price only once there is room for it (the level-up comes first)
	var ddef := DistrictDef.find(type as DistrictDef.Type)
	if lead.is_empty() and not have and ddef != null and city != null and pp != null \
			and not pp.city_upgrading.has(city.label):
		_grant_missing("district:%d" % type, DistrictDef.placement_full_cost(ddef, pd, city.label))
	return lead + [
		{"text": "Open %s" % city_word, "find": [city_name], "how": HOW_PRESS,
			"done": _visible("ADD DISTRICT") or picking or placing == type or have},
		{"text": "Press ADD DISTRICT", "find": ["ADD DISTRICT"], "how": HOW_PRESS,
			"done": picking or placing == type or have},
		{"text": "Choose %s" % dname, "find": [dname.to_upper()], "how": HOW_PRESS,
			"done": placing == type or have},
		{"text": "Place it within the City's reach", "find": [], "how": HOW_PLACE, "done": have},
		{"text": "Wait for it to be built", "find": [], "how": HOW_WAIT, "done": _has_district(pd, type, true)}]

const STEP_BUILDINGS := {"Low-rise Housing": "low_rise_housing", "Market": "commercial",
	"Solar Array": "solar_panel", "Field Lab": "field_observatory"}

func _building_subs(pd: PlanetData, pp: PlanetProgress, type: int, bname: String) -> Array:
	var host := _district_of(pd, type)
	var host_name := host.shown_name().to_upper() if host != null else ""
	var have := _has_building(pd, pp, type)
	var bdef := BuildingDef.find(String(STEP_BUILDINGS.get(bname, "")))
	if not have and host != null and not host.constructing and bdef != null:
		_grant_missing("building:" + bdef.building_id, Economy.building_full_cost(pp, bdef, host.label))
	# its own page, not any district's (an EMPTY SLOT shows on every one)
	var scene := get_tree().current_scene
	var on_page: bool = host != null and scene != null and scene.get("_active_district_poi") == host
	var picking := on_page and _visible(bname.to_upper())
	return [
		{"text": "Open %s" % (host.shown_name() if host != null else "the district"), "find": [host_name],
			"how": HOW_PRESS, "done": on_page or have},
		{"text": "Press an EMPTY SLOT", "find": ["EMPTY SLOT"] if on_page else [], "how": HOW_PRESS, "done": picking or have},
		{"text": "Choose %s" % bname, "find": [bname.to_upper()], "how": HOW_PRESS, "done": have},
		{"text": "Wait for it to be built", "find": [], "how": HOW_WAIT, "done": _has_building(pd, pp, type, true)}]

## The checklist on the card: done ones ticked, the current one bright with its "how".
func _refresh_checks(subs: Array) -> void:
	var good := UIStyle.hex(&"good")
	var dim := UIStyle.hex(&"text_subtle")
	var lines: Array[String] = []
	for i in subs.size():
		var s: Dictionary = subs[i]
		if i <= _progress:
			lines.append("%s [color=#%s]%s[/color]" % [UIIcons.bb("confirm", 10, UIStyle.color(&"good")), dim, s["text"]])
		elif i == _progress + 1:
			lines.append("[color=#%s]›[/color] %s" % [good, s["text"]])
			if String(s.get("how", "")) != "":
				lines.append("   [color=#%s][font_size=9]%s[/font_size][/color]" % [dim, s["how"]])
		else:
			lines.append("[color=#%s]·  %s[/color]" % [dim, s["text"]])
	var t := "\n".join(lines)
	if t != _subs_text:
		_subs_text = t
		_checks.text = t

# ── World state ──────────────────────────────────────────────────────────────
static func _city(pd: PlanetData) -> POIData:
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital():
			return p
	return null

## A surface district of `type` (-1: any but the City); `built`: finished.
static func _has_district(pd: PlanetData, type: int, built := false) -> bool:
	for p: POIData in pd.custom_pois:
		if p.is_orbital() or p.is_city() or (built and p.constructing):
			continue
		var dd := ProductionManager.district_def(p)
		if dd != null and (type < 0 or dd.id == type):
			return true
	return false

static func _district_of(pd: PlanetData, type: int) -> POIData:
	for p: POIData in pd.custom_pois:
		if p.is_orbital() or p.is_city():
			continue
		var dd := ProductionManager.district_def(p)
		if dd != null and dd.id == type:
			return p
	return null

## A building in a district of `type` (`built`: finished).
static func _has_building(pd: PlanetData, pp: PlanetProgress, type: int, built := false) -> bool:
	for e: Dictionary in pp.buildings:
		if built and e.get("constructing", false):
			continue
		var host := _poi(pd, String(e.get("district_id", "")))
		if host == null or host.is_city() or host.is_orbital():
			continue
		var dd := ProductionManager.district_def(host)
		if dd != null and dd.id == type:
			return true
	return false

static func _any_district_level(pd: PlanetData, pp: PlanetProgress) -> int:
	var best := 1
	for p: POIData in pd.custom_pois:
		if p.is_orbital() or p.is_city() or p.constructing:
			continue
		best = maxi(best, int(pp.district_levels.get(p.label, 1)))
	return best

static func _poi(pd: PlanetData, label: String) -> POIData:
	for p: POIData in pd.custom_pois:
		if p.label == label:
			return p
	return null

## The district type being placed in the planet view (-2: none).
func _placing_type() -> int:
	var scene := get_tree().current_scene
	var def = scene.get("_placing_def") if scene != null else null
	return (def as DistrictDef).id if def is DistrictDef else -2

# ── What to press ────────────────────────────────────────────────────────────
## Is a button / row whose text starts with `label` on screen (left panel, its dropdowns)?
func _visible(label: String) -> bool:
	return _find_target([label]) != null

func _find_target(labels: Array) -> Control:
	for label in labels:
		var want := String(label)
		if want == "":
			continue
		for root in _search_roots():
			var hit := _find_in(root, want)
			if hit != null:
				return hit
	return null

## On a district's page while what to press is elsewhere: its "‹ City" button
## (the page's way back up), so nothing else on the page can be used meanwhile.
## (11.11: the whole panel was left free, and buildings could be built there.)
func _way_back() -> Control:
	var scene := get_tree().current_scene
	if scene == null or scene.get("_active_district_poi") == null:
		return null
	var found: Control = null
	for n in get_tree().get_nodes_in_group(LeftPanel.GROUP):
		found = _find_back(n, found)
	return found

static func _find_back(n: Node, best: Control) -> Control:
	for ch in n.get_children():
		if ch is Control and not (ch as Control).is_visible_in_tree():
			continue
		if ch is Button and not (ch is IconButton) and (ch as Button).text.begins_with("‹"):
			# the City's, rather than the Orbit's, when a page has both
			if best == null or (best as Button).text.ends_with("ORBIT"):
				best = ch as Control
			continue
		best = _find_back(ch, best)
	return best

func _search_roots() -> Array[Node]:
	var out: Array[Node] = []
	for c in get_tree().root.get_children():   # dropdowns (district / building pickers) first
		if c is CanvasLayer and c.has_meta("left_panel_dropdown"):
			out.append(c)
	var scene := get_tree().current_scene
	if scene != null:
		for c in scene.get_children():
			if c is CanvasLayer and c.has_meta("left_panel_dropdown"):
				out.append(c)
	if scene != null:   # the building picker under an EMPTY SLOT
		var dd = scene.get("_active_slot_dropdown")
		if dd != null and is_instance_valid(dd) and (dd as Control).is_visible_in_tree():
			out.append(dd)
	for n in get_tree().get_nodes_in_group(LeftPanel.GROUP):
		out.append(n)
	return out

static func _find_in(n: Node, want: String) -> Control:
	for ch in n.get_children():
		if ch is Control and not (ch as Control).is_visible_in_tree():
			continue
		if ch is ListItem and (ch as ListItem).title.to_upper().begins_with(want):
			return ch
		if ch is IconButton and (ch as IconButton).label_text.to_upper().begins_with(want):
			return ch
		var deeper := _find_in(ch, want)
		if deeper != null:
			return deeper
	return null

## Pulses what to press next; playing with the keys, it comes up selected.
func _set_target(c: Control) -> void:
	if c == _target and (c == null or is_instance_valid(c)):
		return
	if _target_tw != null and _target_tw.is_valid():
		_target_tw.kill()
	if _target != null and is_instance_valid(_target):
		_target.modulate = Color.WHITE
	_target = c
	_target_tw = null
	if c == null:
		return
	_target_tw = c.create_tween().set_loops()
	_target_tw.tween_property(c, "modulate", PULSE, 0.5)
	_target_tw.tween_property(c, "modulate", Color.WHITE, 0.5)
	# keys: selected once per goal (a panel rebuild makes a new button; the
	# player moving elsewhere is not pulled back)
	var is_back := c is Button and not (c is IconButton) and (c as Button).text.begins_with("‹")
	var goal := "%s:%d%s" % [_shown_step, _progress, ":back" if is_back else ""]   # back, then the real one
	if CursorManager.keys_mode and goal != _focused_goal:
		for n in get_tree().get_nodes_in_group(LeftPanel.GROUP):
			var lp := n as LeftPanel
			if lp != null and lp.is_inside_tree() and not lp._nav_blocked():
				lp._nav_active = true
				lp._set_nav_focus(c, false)
				_focused_goal = goal
				break

## The advisor's words for a step, as the card shows them.
func _line_text(step: String) -> String:
	if LINES.has(step):
		var by: Dictionary = LINES[step]
		return String(by.get(_advisor(), by["mother_superior"]))
	var data := load(GRAPH) as VSMData
	if data == null:
		return ""
	var entry := data.get_entry("%s_%s" % [step, _advisor()])
	if entry == null or entry.exits.is_empty():
		return ""
	var n := data.get_node_by_id(entry.exits[0].target_id) as VSMDialogueNodeData
	return n.text if n != null else ""

var _skip: IconButton = null

func _ensure_card() -> void:
	if _card != null and is_instance_valid(_card):
		return
	_card = ObjectivesCard.new()
	add_child(_card)
	_hero = HeroHeader.create("", "", ObjectivesCard.HERO_SIZE)
	_card.content.add_child(_hero)
	_desc = _rich(11)
	_card.content.add_child(_desc)
	_checks = _rich(11)
	_card.content.add_child(_checks)
	_reward = _rich(11)
	_card.content.add_child(_reward)
	# the optional checklist can be skipped: every reward not paid yet comes at once (11.11)
	_skip = IconButton.create("SKIP TUTORIAL", "flag", IconButton.Variant.DEFAULT)
	_skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skip.visible = false
	_skip.pressed.connect(_ask_skip)
	_card.content.add_child(_skip)

static func _rich(px: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.theme_type_variation = &"PopupBody"
	r.add_theme_font_size_override(&"normal_font_size", px)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

# ── On the side (optional) ───────────────────────────────────────────────────
## The ship's record once the Capital has been seen; the first ruin's signal once
## the City stands. Each goes when it has been read / the site was opened.
## (Also run by Inbox each second: after the tutorial this card's loop stops.)
func _refresh_extras() -> void:
	# 10.11: the side stories are notifications now (Inbox), not card buttons
	var i := STEPS.find(GameState.tutorial_step)
	var past_city := i > STEPS.find("guide_city") or checklist_mode() or GameState.tutorial_step == "done"
	if not past_city or blocking():
		return   # not while a guided step is on (they'd lead away from it)
	if not Narrative.has_played("archive_lazarus") and not Inbox.has("story:record") \
			and not GameState.story_flags.has("inbox_told:record"):
		GameState.story_flags["inbox_told:record"] = true
		Inbox.post("story:record", "story", "notes", "Read the ship record",
			"A short read: the ship's log of how I-330 came to land here.", {"story": "record"})
	if not Narrative.has_played("first_ruin_signal") and not Excavations.is_done(FIRST_RUIN) \
			and not Inbox.has("story:ruin") and not GameState.story_flags.has("inbox_told:ruin"):
		GameState.story_flags["inbox_told:ruin"] = true
		Inbox.post("story:ruin", "story", "explore", "The Toppled Stones",
			"Your surveyors found a ruin near the City. Open it to start an excavation.", {"story": "ruin"})

## A side story from the notifications panel: the ship record, or the first
## ruin's signal and then its excavation card.
func play_side_story(which: String) -> void:
	if which == "record":
		Narrative.play(RECORDS, "archive_lazarus", {"id": "archive_lazarus", "now": true})
		Inbox.remove("story:record")
	elif which == "ruin":
		Inbox.remove("story:ruin")
		var site_open := func(_exit: String) -> void:
			var host := get_tree().current_scene
			if host != null:
				StoryDialog.open(host, FIRST_RUIN)
		if not Narrative.play(GRAPH, "first_ruin_signal_" + _advisor(), {"id": "first_ruin_signal", "now": true,
				"on_done": site_open}):
			site_open.call("")   # heard already: straight to the site
