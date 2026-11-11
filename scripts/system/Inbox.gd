## Inbox — autoload. The notifications panel (10.11): only what the player can
## act on now, not what already happened (that is the news bar's):
##   EXCAVATIONS  a dig that can start, or whose crews are waiting
##   EXPEDITIONS  the lunar lander to prepare, the Moon to scan / land on, the
##                rocket to launch or aim
##   TASKS        the objective in progress (after the tutorial)
##   STORY        side stories and scenes waiting (posted: the Guide, Bolo)
##   WARNINGS     energy short, housing full, storage full
## Most rows are worked out from the game as it is (every second) and go once
## done; story rows are posted and saved. A row's ✕ (X / LB) dismisses it until
## it changes. The news bar's flag button shows how many are new; O (or the
## flag, or the pad's shortcuts menu) opens it at the bottom right, the keys on
## its first row, and Esc / O / B closes it back to where they were.
## Saved in the game: GameState "inbox" (story rows); dismissed / seen ids in
## GameState.story_flags ("inbox_x:<id>", "inbox_seen:<id>").
extends Node

signal changed

const MAX := 30
const LAYER := 236
const W := 400.0
const MAX_H := 440.0
const POLL_SEC := 1.0
const MARGIN := 12.0

## Posted rows: { id, kind, icon, title, text, act: {...}, at: float }
var entries: Array = []
var _live: Array = []   # worked out each second
var _sig := ""
var _serial := 0
var _layer: CanvasLayer = null
var _poll := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	entries = GameState.inbox_data.duplicate(true)   # the save was read before this autoload
	GameState.save_deleted.connect(func() -> void:
		entries.clear()
		_live.clear()
		close()
		changed.emit())

# ── Rows ─────────────────────────────────────────────────────────────────────
## Posts (or refreshes) a row. `act`: {"loc": {…}} the camera there; {"story":
## "record" | "ruin"}; {"site": id}; {"companions": true}; {"tree": true};
## {"rocket": true} (start it); {} only to read.
func post(id: String, kind: String, icon: String, title: String, text := "", act := {}) -> void:
	if title == "":
		return
	if id == "":
		_serial += 1
		id = "e%d_%d" % [int(GameState.play_seconds), _serial]
	remove(id, false)
	entries.push_front({"id": id, "kind": kind, "icon": icon, "title": title, "text": text, "act": act,
		"at": GameState.play_seconds})
	GameState.story_flags.erase("inbox_x:" + id)
	GameState.story_flags.erase("inbox_seen:" + id)
	while entries.size() > MAX:
		entries.pop_back()
	_changed()

func remove(id: String, emit := true) -> void:
	for i in range(entries.size() - 1, -1, -1):
		if String(entries[i]["id"]) == id:
			entries.remove_at(i)
	if emit:
		_changed()

func has(id: String) -> bool:
	for e: Dictionary in entries:
		if String(e["id"]) == id:
			return true
	return false

## Everything to show now, in its sections' order, dismissed ones left out.
func items() -> Array:
	var out: Array = []
	for e: Dictionary in _live + entries:
		if not GameState.story_flags.has("inbox_x:" + String(e["id"])):
			out.append(e)
	var order := ["dig", "expedition", "task", "story", "warn"]
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return order.find(a["kind"]) < order.find(b["kind"]))
	return out

func unread() -> int:
	var n := 0
	for e: Dictionary in items():
		if not GameState.story_flags.has("inbox_seen:" + String(e["id"])):
			n += 1
	return n

## ✕ / X: gone until it changes (a live row comes back under a new id).
func dismiss(id: String) -> void:
	GameState.story_flags["inbox_x:" + id] = true
	_changed()

func _mark_seen() -> void:
	for e: Dictionary in items():
		GameState.story_flags["inbox_seen:" + String(e["id"])] = true
	changed.emit()

## What a row does when pressed.
func activate(e: Dictionary) -> void:
	GameState.story_flags["inbox_seen:" + String(e["id"])] = true
	var act: Dictionary = e.get("act", {})
	var host := get_tree().current_scene
	close()
	if act.has("loc"):
		NewsFeed.go_to(act["loc"])
	elif act.has("site"):
		if host != null:
			StoryDialog.open(host, String(act["site"]))
	elif act.has("story"):
		Guide.play_side_story(String(act["story"]))
	elif act.has("companions"):
		if String(e["kind"]) == "story":
			remove(String(e["id"]), false)   # read: Bolo's news, a new Agent
		if host != null:
			CompanionGallery.open(host)
	elif act.has("tree"):
		HUDManager.press_shortcut("tree")
	elif act.has("rocket"):
		if host != null:
			ConfirmPanel.ask(host, "Launch the rocket?", "It is built at the Spaceport, then you pick where it flies.\n\nCost  %s"
				% Economy.cost_text(GameState.ROCKET_COST), "LAUNCH", func() -> void:
					if not GameState.start_rocket():
						AudioManager.play("error"))
	changed.emit()

func save_data() -> Array:
	return entries.duplicate(true)

func load_data(a: Array) -> void:
	entries = a.duplicate(true)
	_changed()

func _changed() -> void:
	changed.emit()
	_refresh_panel()

# ── What can be done now (worked out each second) ────────────────────────────
func _process(delta: float) -> void:
	_poll += delta
	if _poll < POLL_SEC:
		return
	_poll = 0.0
	if NewsFeed.on_main_menu() or GameState.home_planet_seed < 0 or not GameState.has_founded_city():
		if not _live.is_empty():
			_live.clear()
			_changed()
		return
	Guide._refresh_extras()   # the side stories, once they are open to the player
	var live: Array = []
	_add_digs(live)
	_add_expeditions(live)
	_add_task(live)
	_add_warnings(live)
	var sig := ""
	for e: Dictionary in live:
		sig += String(e["id"]) + "|" + String(e["title"]) + ";"
	_live = live
	if sig != _sig:
		_sig = sig
		_changed()

static func _row(id: String, kind: String, icon: String, title: String, text: String, act := {}) -> Dictionary:
	return {"id": id, "kind": kind, "icon": icon, "title": title, "text": text, "act": act}

func _add_digs(out: Array) -> void:
	for w: ExcavationWorldDef in ExcavationWorldDef.all():
		var pd := w.planet()
		if pd == null or not GameState.is_scanned(pd.seed):
			continue
		var s := Excavations.next_site(w)
		if s == null:
			continue
		match Excavations.stage(s):
			Excavations.Stage.IDLE:
				out.append(_row("dig:%s:idle" % s.site_id, "dig", "explore", "Excavation: %s" % s.display_name,
					"On %s. Open it to start the dig." % pd.planet_name, {"site": s.site_id}))
			Excavations.Stage.READY:
				out.append(_row("dig:%s:ready" % s.site_id, "dig", "explore", "%s is ready" % s.display_name,
					"Your crews are waiting: see what they found.", {"site": s.site_id}))

func _add_expeditions(out: Array) -> void:
	var moon := GameState.home_moon()
	if moon != null:
		var mp := GameState.get_planet(moon.seed)
		var no_city := true
		for p: POIData in moon.custom_pois:
			if p.is_city() and not p.is_orbital():
				no_city = false
		# the lander's Central Orbit makes the Moon "colonized"; it still waits
		# for its first City (10.11: the scan row never came)
		if mp != null and no_city:
			if mp.lander_state == 1:
				if not GameState.is_scanned(moon.seed):
					out.append(_row("exp:moon_scan", "expedition", "rocket", "Scan the Moon",
						"The lander is in lunar orbit: scan the surface (free), then pick where it lands.",
						{"loc": {"seed": moon.seed, "lander": true}}))
				else:
					out.append(_row("exp:moon_land", "expedition", "rocket", "Pick the Moon's landing site",
						"The lander waits in orbit for a site for the first City.", {"loc": {"seed": moon.seed, "lander": true}}))
			elif not mp.is_colonized and GameState.moon_colonize_block(moon.seed) == "":
				out.append(_row("exp:lander", "expedition", "rocket", "Prepare the lunar lander",
					"Everything is ready at the Spaceport: open the Moon and prepare the lander.", {"loc": {"seed": moon.seed}}))
	var rst := GameState.expedition_state("rocket")
	if rst == "" and GameState.rocket_block() == "":
		out.append(_row("exp:rocket", "expedition", "rocket", "Launch the rocket",
			"The Spaceport can build the rocket to the next world.", {"rocket": true}))
	elif (rst == "preparing" or rst == "ready") \
			and GameState.rocket_target_block(int(GameState.expedition("rocket").get("target_seed", -1))) != "":
		out.append(_row("exp:rocket_target", "expedition", "rocket", "Pick the rocket's target",
			"In the star system view, right-click a planet to aim the rocket.", {"loc": {"solar": true}}))

## The objective in progress once the tutorial is over (TutorialManager's list),
## and the final rocket (was its own card, 10.11).
func _add_task(out: Array) -> void:
	if not GameState.showcase_mode and SkillTree.is_unlocked("lunar_program") and GameState.expedition_state("rocket") == "" \
			and not GameState.demo_completed:
		var block := GameState.rocket_block()
		if block != "":   # once it can start, EXPEDITIONS has "Launch the rocket"
			var act := {}
			if block.begins_with("Research"):
				act = {"tree": true}
			elif GameState.home_moon() != null and block.find("Moon") >= 0:
				act = {"loc": {"seed": GameState.home_moon().seed}}
			out.append(_row("task:final_rocket", "task", "rocket", "Final rocket",
				"Mined on the Moon: %s / 100.  Next: %s." % [Economy.fmt(minf(GameState.moon_local_moonstone, 100.0)), block], act))
	if GameState.tutorial_step != "done":
		return   # the tutorial card shows the step
	if TutorialManager._quest_done:
		return
	var i := TutorialManager._quest_step
	var quests: Array = TutorialManager.QUESTS
	if i < 0 or i >= quests.size():
		return
	var q: Dictionary = quests[i]
	out.append(_row("task:%s" % String(q.get("id", str(i))), "task", "flag", String(q.get("title", "Objective")),
		String(q.get("desc", ""))))

func _add_warnings(out: Array) -> void:
	var esp: Vector2 = ProductionManager.get_global_energy_split()
	if esp.y > esp.x + 0.001:
		out.append(_row("warn:energy", "warn", "warning", "Energy is short",
			"Buildings use more than the grid makes, so output drops. Build an Energy District or a power building."))
	var pd := GameState.get_planet_data(GameState.home_planet_seed)
	var pp := GameState.get_planet(GameState.home_planet_seed)
	if pd != null and pp != null and pp.is_colonized:
		var mx := Economy.max_population(pd, pp)
		if mx > 0 and Economy.used_population(pd, pp) >= mx:
			out.append(_row("warn:housing", "warn", "warning", "Housing is full",
				"Every home is taken: new buildings will lack workers. Build homes in a Residential District."))
	var full := false
	for id: String in Economy.PROCESSED:
		full = full or Economy.is_full(id)
	for r: Dictionary in Economy.RAW_TABLE:
		full = full or (Economy.is_mineral_discovered(r["id"]) and Economy.is_full(r["id"]))
	if full:
		out.append(_row("warn:storage", "warn", "warning", "Storage is full",
			"What is made beyond the cap is lost. Build a Warehouse, use it or sell it in Trade."))

# ── The panel ────────────────────────────────────────────────────────────────
const SECTION := {"dig": "EXCAVATIONS", "expedition": "EXPEDITIONS", "task": "TASKS", "story": "STORY",
	"warn": "WARNINGS"}

func is_open() -> bool:
	return _layer != null and is_instance_valid(_layer)

func toggle() -> void:
	if is_open():
		close()
	else:
		open()

func close() -> void:
	if is_open():
		_layer.queue_free()
		_mark_seen()
	_layer = null

func open() -> void:
	if is_open() or NewsFeed.on_main_menu():
		return
	AudioManager.play("click")
	_layer = CanvasLayer.new()
	_layer.layer = LAYER
	_layer.set_meta("left_panel_dropdown", true)   # the left panel's keys run it, Esc closes
	_layer.tree_exiting.connect(func() -> void: _mark_seen.call_deferred())
	get_tree().root.add_child(_layer)
	var catcher := Control.new()   # a click elsewhere closes it
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			close())
	_layer.add_child(catcher)
	_refresh_panel(true)

func _refresh_panel(focus_first := false) -> void:
	if not is_open():
		return
	var old := _layer.get_node_or_null("Card")
	if old != null:
		_layer.remove_child(old)
		old.queue_free()
	var list_items := items()
	var card := PanelContainer.new()
	card.name = "Card"
	card.theme_type_variation = &"PopupCard"
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.custom_minimum_size = Vector2(W, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 6)
	card.add_child(col)
	var head := HBoxContainer.new()
	var t := Label.new()
	t.text = "NOTIFICATIONS"
	t.theme_type_variation = &"HeaderLabel"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var n := unread()
	var cnt := Label.new()
	cnt.text = ("%d new" % n) if n > 0 else ("%d" % list_items.size() if not list_items.is_empty() else "")
	cnt.theme_type_variation = &"SubLabel"
	head.add_child(cnt)
	col.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.add_theme_constant_override(&"separation", 4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	col.add_child(scroll)
	var first: Control = null
	if list_items.is_empty():
		var none := Label.new()
		none.text = "Nothing to do right now."
		none.theme_type_variation = &"SubLabel"
		list.add_child(none)
	var section := ""
	for e: Dictionary in list_items:
		var ent := e
		if String(e["kind"]) != section:
			section = String(e["kind"])
			var sh := Label.new()
			sh.text = String(SECTION.get(section, section.to_upper()))
			sh.theme_type_variation = &"SubLabel"
			list.add_child(sh)
		var seen := GameState.story_flags.has("inbox_seen:" + String(e["id"]))
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 4)
		var li := ListItem.create(String(e["title"]).to_upper(), String(e["icon"]),
			"NEW" if not seen else "", [], String(e["text"]))
		li.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		li.pressed.connect(func() -> void:
			AudioManager.play("click")
			activate(ent))
		li.set_meta("key_remove", func() -> void:   # X / LB
			AudioManager.play("click")
			dismiss(String(ent["id"])))
		row.add_child(li)
		var x := IconButton.create("", "close", IconButton.Variant.DEFAULT)
		x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		x.mouse_entered.connect(func() -> void: TooltipManager.show_tip("Dismiss", "Hide it until it changes.  [X]"))
		x.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
		x.pressed.connect(func() -> void:
			AudioManager.play("click")
			TooltipManager.hide_tip()
			dismiss(String(ent["id"])))
		row.add_child(x)
		list.add_child(row)
		if first == null:
			first = li
	# bottom right, just above the news bar, anchored there (any window size)
	card.anchor_left = 1.0
	card.anchor_right = 1.0
	card.anchor_top = 1.0
	card.anchor_bottom = 1.0
	card.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var vp_h := _layer.get_viewport().get_visible_rect().size.y
	var bar = NewsFeed.get("_bar")
	var above := 30.0
	if bar != null and is_instance_valid(bar):
		above = vp_h - (bar as Control).get_global_rect().position.y + 6.0
	card.offset_right = -MARGIN
	card.offset_bottom = -above
	_layer.add_child(card)
	scroll.custom_minimum_size = Vector2(W - 24.0, minf(list.get_combined_minimum_size().y, MAX_H))
	card.offset_left = card.offset_right - card.get_combined_minimum_size().x
	card.offset_top = card.offset_bottom - card.get_combined_minimum_size().y
	# the keys start on the first row (Esc / O / B goes back to where they were)
	if first != null and focus_first:
		var f := first
		(func() -> void:
			if not is_instance_valid(f):
				return
			for lp in get_tree().get_nodes_in_group(LeftPanel.GROUP):
				if lp is LeftPanel:
					(lp as LeftPanel)._nav_active = true
					(lp as LeftPanel)._set_nav_focus(f, false)
					break).call_deferred()
