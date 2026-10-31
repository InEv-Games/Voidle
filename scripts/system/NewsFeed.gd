## NewsFeed — autoload. A news crawl along the bottom of the game screen
## (playtest 31.10): "narrative entries" about what the player just did (a
## district placed, research finished, a City levelled …) and, between them,
## small flavour stories about their own Cities and districts.
##
## Anything can post: NewsFeed.post("text", NewsFeed.Kind.EVENT). The crawl
## never runs empty: items follow each other with a separator; events go
## first, and when none are waiting a flavour story or a live status line
## (credits, population, the grid …) fills in. Nothing here is saved.
##
## The bar runs the full width under the view's left panel — it lives in the
## panel's parent, just before it, so the panel opens over it and nothing moves.
## Views without a left panel get it on this layer instead.
extends CanvasLayer

enum Kind { EVENT, FLAVOUR }

const HEIGHT := 22.0
## Crawl speed, px per second.
const SPEED := 70.0
## Between two items.
const SEPARATOR := "     ◈     "
## Buildings finished within this many seconds are told as one entry.
const BUILD_BATCH_SEC := 6.0
## Most events kept waiting (older ones drop).
const MAX_QUEUE := 12

## Flavour lines: {city} {district} {planet} {n} {m} are filled from the
## player's own settlements (FLAVOUR_HOME needs no settlement).
const FLAVOUR := [
	"Three workers lost their lives in an accident at {district}. The safety board promises a review.",
	"{city} night market elects a cat as honorary mayor. Turnout: unusually high.",
	"Commuters in {district} report the trams are on time for the {n}th day running.",
	"A citizen of {city} claims to have counted every solar panel on {planet}. Officials decline to check.",
	"{district} celebrates its founding day with fireworks and one minor fire.",
	"Local poll: {n}% of {city} residents would rather live on the Moon. The rest have seen the Moon.",
	"A shipment of left boots arrives in {district}. Right boots are 'on the way'.",
	"{city} schoolchildren win the planetary model-rocket contest. Nobody was hurt this year.",
	"Power flickers across {district}; engineers blame a very determined pigeon.",
	"The {city} archive finds a ledger from the first settlers. Mostly complaints about the weather.",
	"A strike in {district} ends after {m} hours when the canteen brings back dessert.",
	"Housing prices in {city} rise again. Residents rise earlier to afford them.",
	"{district} foreman promoted after a record shift; the record is disputed by {district}'s other foreman.",
	"A sinkhole opens near {district}. Geologists call it 'interesting', residents call it something else.",
	"{city} unveils a statue of its founder. The founder asks for a better nose.",
	"Night shift in {district} spots strange lights above the horizon. Probably a freighter. Probably.",
	"{n} couples marry on the same day in {city}. The registry office requests a holiday.",
	"Dust storm warning lifted for {district}. Laundry may go back out.",
	"A {city} chef invents a dish made entirely of mineral by-products. Reviews are mixed.",
	"Census: {planet} now counts more vending machines than parks. A committee is formed.",
]
const FLAVOUR_HOME := [
	"Astronomers name a new comet after a cleaning robot. The robot is unavailable for comment.",
	"Historians debate whether the old ruins were a temple, a market or a very large bench.",
	"Weather service promises clear skies. Weather disagrees.",
	"Interplanetary radio hit of the week: 'Orbit Me Tender'.",
	"Scientists confirm the sky is still up. Funding renewed.",
	"Lost and found reports a single glove, a spanner and a very confused drone.",
	"Survey: most citizens can't name the planet's capital. Most citizens live in it.",
	"A retired miner sets the record for the longest nap on record. Nobody woke him to tell him.",
]
## Live status lines: {credits} {science} {pop} {cap} {energy} {planet} {cities}.
const STATUS := [
	"Treasury report: {credits} credits in the vaults.",
	"Research desks have {science} Science waiting to be spent.",
	"Census: {pop} people live in housing for {cap}.",
	"Grid operator: the energy balance stands at {energy}/s.",
	"{planet} now counts {cities} Cit{ies} and {districts} districts.",
]

## Waiting items: { text, kind, title, detail, loc } — `detail` (important
## news) shows as a tooltip when the item is hovered; `loc` ({ seed, label }
## or { seed, lon, lat }) is where a click on it takes the camera.
var _queue: Array = []
## Hover: the crawl eases down to HOVER_SPEED_K × SPEED over the bar, the item
## under the mouse grows a little, and after TIP_DELAY its detail shows.
const HOVER_SPEED_K := 0.06
const HOVER_SCALE := 1.12
const TIP_DELAY := 0.35
var _speed_k := 1.0
var _hover_label: Label = null
var _hover_time := 0.0
var _tip_shown := false
var _bar: Panel = null
var _clip: Control = null
var _labels: Array[Label] = []
var _recent: Array[String] = []   # last fillers, not repeated soon
var _build_batch: Dictionary = {}   # "seed|building_id" -> count
var _build_where: Dictionary = {}   # "seed|building_id" -> district label (the last one)
var _batch_left := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	layer = 229   # under the HUD's top layer (230), above the views
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_connect_sources.call_deferred()

## Queues an entry ("" ignored). Events wait in line; flavour lines are dropped
## when events are waiting. `detail` (with its `title`) is the tooltip an
## important item shows on hover.
func post(text: String, kind: Kind = Kind.EVENT, detail: String = "", title: String = "",
		loc: Dictionary = {}) -> void:
	if text == "":
		return
	if kind == Kind.FLAVOUR and not _queue.is_empty():
		return
	_queue.append({"text": ("◆  " if kind == Kind.EVENT else "") + text, "kind": kind,
		"title": title, "detail": detail, "loc": loc})
	while _queue.size() > MAX_QUEUE:
		_queue.remove_at(0)

func post_planet_level(planet_seed: int, level: int) -> void:
	var pd := GameState.get_planet_data(planet_seed)
	var pname := pd.planet_name if pd else "A world"
	var new_pick := level in PlanetTags.BONUS_LEVELS
	post("%s reaches planet level %d.%s" % [pname, level, "  A new planet trait can be chosen." if new_pick else ""],
		Kind.EVENT, "The planet can now hold %d Cities.%s" % [Leveling.max_cities(GameState.get_planet(planet_seed)),
			"\nPick its new trait from the button under the top bar." if new_pick else ""],
		"%s · Level %d" % [pname, level], {"seed": planet_seed})

# ── Sources ──────────────────────────────────────────────────────────────────

func _connect_sources() -> void:
	GameState.district_placed.connect(func(seed_val: int, type_id: int) -> void:
		var def := DistrictDef.find(type_id as DistrictDef.Type)
		var pd := GameState.get_planet_data(seed_val)
		if def != null and pd != null:
			var newest := ""
			for p: POIData in pd.custom_pois:
				if p.type_tag == def.type_key():
					newest = p.label   # the one just placed is the last of its kind
			post("Surveyors stake out a new %s on %s." % [def.display_name, pd.planet_name], Kind.EVENT,
				def.description, def.display_name, {"seed": seed_val, "label": newest}))
	ProductionManager.building_constructed.connect(func(seed_val: int, key: String, bid: String) -> void:
		var k := "%d|%s" % [seed_val, bid]
		_build_batch[k] = int(_build_batch.get(k, 0)) + 1
		var parts := key.split(":")   # "seed:district:uid"
		if parts.size() >= 2:
			_build_where[k] = parts[1]
		if _batch_left <= 0.0:
			_batch_left = BUILD_BATCH_SEC)
	ProductionManager.city_leveled.connect(func(seed_val: int, label: String, level: int, _opened: bool) -> void:
		var pd := GameState.get_planet_data(seed_val)
		var city := _find_poi(pd, label)
		post("%s grows to City level %d." % [city.shown_name() if city else "A City", level], Kind.EVENT,
			"A City of level %d may hold %d districts." % [level, Leveling.city_max_districts(level)],
			city.shown_name() if city else "City", {"seed": seed_val, "label": label}))
	SkillTree.skill_unlocked.connect(func(id: String) -> void:
		var node = SkillTree.nodes.get(id, null)
		if node != null and float(node.cost) > 0.0:
			post("Research complete: %s." % node.name, Kind.EVENT,
				"%s\n\n%s" % [node.description, node.effect_desc], node.name))
	GameState.minerals_discovered.connect(func(body_seed: int, ids: Array) -> void:
		var pd := GameState.get_planet_data(body_seed)
		var names: Array[String] = []
		for id in ids:
			names.append(Economy.display_name(String(id)))
		if not names.is_empty():
			post("Prospectors on %s report %s in the ground." % [pd.planet_name if pd else "a new world", ", ".join(names)],
				Kind.EVENT, "Every extraction building on this world now mines %s." % ", ".join(names), "Minerals found",
				{"seed": body_seed}))
	GameState.lander_reached_moon.connect(func(moon_seed: int) -> void:
		post("The lander reaches lunar orbit. Settlers wait for a landing site.", Kind.EVENT,
			"Open the Moon, scan its surface (free) and pick where the first City lands.", "Lander in orbit",
			{"seed": moon_seed}))
	GameState.civilization_reached.connect(func(civ: int) -> void:
		post("The rocket arrives. Historians already call it the dawn of Civilization %d." % civ, Kind.EVENT,
			"Civilization 0 is complete.", "Civilization %d" % civ))

func _flush_build_batch() -> void:
	for k: String in _build_batch:
		var parts := k.split("|")
		var pd := GameState.get_planet_data(int(parts[0]))
		var def := BuildingDef.find(parts[1])
		var n := int(_build_batch[k])
		if def == null:
			continue
		var loc := {"seed": int(parts[0]), "label": String(_build_where.get(k, ""))}
		var tip := def.description
		var makes := def.output_label()
		if makes != "":
			tip += "\n\nEach: " + makes
		if n == 1:
			post("Ribbon cut: a new %s opens on %s." % [def.display_name, pd.planet_name if pd else "a colony"], Kind.EVENT, tip, def.display_name, loc)
		else:
			post("Ribbon cut: %d new %s open on %s." % [n, def.display_name, pd.planet_name if pd else "a colony"], Kind.EVENT, tip, def.display_name, loc)
	_build_batch.clear()
	_build_where.clear()

## A flavour line about one of the player's own settlements.
func _flavour() -> String:
	var cities: Array[String] = []
	var districts: Array[String] = []
	var planet := ""
	for pp: PlanetProgress in GameState._planet_progress.values():
		if not pp.is_colonized:
			continue
		var pd := GameState.get_planet_data(pp.planet_seed)
		if pd == null:
			continue
		planet = pd.planet_name if planet == "" or _rng.randf() < 0.3 else planet
		for p: POIData in pd.custom_pois:
			if p.constructing or p.is_orbital():
				continue
			if p.is_city():
				cities.append(p.shown_name())
			else:
				districts.append(p.shown_name())
	if cities.is_empty() or districts.is_empty() or _rng.randf() < 0.15:
		return FLAVOUR_HOME[_rng.randi() % FLAVOUR_HOME.size()]
	var t: String = FLAVOUR[_rng.randi() % FLAVOUR.size()]
	return t.replace("{city}", cities[_rng.randi() % cities.size()]) \
		.replace("{district}", districts[_rng.randi() % districts.size()]) \
		.replace("{planet}", planet).replace("{n}", str(_rng.randi_range(3, 97))) \
		.replace("{m}", str(_rng.randi_range(2, 30)))

static func _find_poi(pd: PlanetData, label: String) -> POIData:
	if pd == null:
		return null
	for p: POIData in pd.custom_pois:
		if p.label == label:
			return p
	return null

## A filler when no event waits: mostly flavour, sometimes a live status line;
## the last few aren't repeated.
func _filler() -> String:
	for _try in 6:
		var t := _status() if _rng.randf() < 0.3 else _flavour()
		if t != "" and not t in _recent:
			_recent.append(t)
			if _recent.size() > 8:
				_recent.remove_at(0)
			return t
	return _flavour()

func _status() -> String:
	var home := GameState.get_home_planet()
	if home == null:
		return ""
	var pp := GameState.get_planet(home.seed)
	var cities := 0
	var districts := 0
	for p: POIData in home.custom_pois:
		if p.is_orbital() or p.constructing:
			continue
		if p.is_city():
			cities += 1
		else:
			districts += 1
	var e := ProductionManager.get_global_energy()
	var t: String = STATUS[_rng.randi() % STATUS.size()]
	return t.replace("{credits}", Economy.fmt(GameState.credits)) \
		.replace("{science}", Economy.fmt(GameState.science_points)) \
		.replace("{pop}", Economy.fmt(Economy.used_population(home, pp))) \
		.replace("{cap}", Economy.fmt(Economy.max_population(home, pp))) \
		.replace("{energy}", ("+" if e >= 0.0 else "") + Economy.fmt(e)) \
		.replace("{planet}", home.planet_name).replace("{cities}", str(cities)) \
		.replace("{ies}", "y" if cities == 1 else "ies").replace("{districts}", str(districts))

# ── Crawl ────────────────────────────────────────────────────────────────────

## Builds the bar under `host` (or on this layer when null).
func _build_ui(host: Node) -> void:
	_bar = Panel.new()
	_bar.name = "NewsCrawl"
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.05, 0.10, 0.82)
	sb.border_color = Color(0.45, 0.60, 0.85, 0.35)
	sb.border_width_top = 1
	_bar.add_theme_stylebox_override("panel", sb)
	_bar.anchor_left = 0.0
	_bar.anchor_right = 1.0
	_bar.anchor_top = 1.0
	_bar.anchor_bottom = 1.0
	_bar.offset_left = 0.0
	_bar.offset_right = 0.0
	_bar.offset_top = -HEIGHT
	_bar.offset_bottom = 0.0
	# catches clicks (an item with a place takes the camera there); the left
	# panel, drawn after it, still gets the clicks over it
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_bar.gui_input.connect(_on_bar_input)
	(host if host != null else self).add_child(_bar)
	_clip = Control.new()
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.anchor_right = 1.0
	_clip.anchor_bottom = 1.0
	_clip.offset_left = 6
	_clip.offset_right = -56
	_bar.add_child(_clip)
	var tag := Label.new()
	tag.text = " NEWS "
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", Color(0.04, 0.06, 0.12))
	var tag_bg := StyleBoxFlat.new()
	tag_bg.bg_color = Color(0.95, 0.75, 0.30)
	tag.add_theme_stylebox_override("normal", tag_bg)
	tag.anchor_left = 1.0
	tag.anchor_right = 1.0
	tag.offset_left = -50
	tag.offset_right = -4
	tag.offset_top = 3
	tag.offset_bottom = HEIGHT - 3
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bar.add_child(tag)
	_labels.clear()

## The bar sits in the left panel's parent, just before the panel; without one,
## on this layer. A bar freed with its view is built again.
func _ensure_bar() -> void:
	var panel: Control = null
	for n in get_tree().get_nodes_in_group(LeftPanel.GROUP):
		if n is Control and (n as Control).is_inside_tree():
			panel = n
			break
	var host: Node = panel.get_parent() if panel != null else self
	if _bar == null or not is_instance_valid(_bar) or _bar.is_queued_for_deletion():
		_build_ui(host)
	elif _bar.get_parent() != host:
		_bar.reparent(host, false)
	if panel != null and _bar.get_index() != panel.get_index() - 1:
		var to := panel.get_index()
		if _bar.get_index() < to:
			to -= 1   # the bar's own slot frees up when it moves
		host.move_child(_bar, to)

func _process(delta: float) -> void:
	if _batch_left > 0.0:
		_batch_left -= delta
		if _batch_left <= 0.0:
			_flush_build_batch()
	var on := HUDManager.visible and GameState.home_planet_seed >= 0 and not get_tree().paused
	if not on:
		if _bar != null and is_instance_valid(_bar):
			_bar.visible = false
		return
	_ensure_bar()
	_bar.visible = true
	var width := _clip.size.x
	if width <= 1.0:
		return
	_update_hover(delta)
	# a chain: the first item moves, each next one starts where the one before
	# ends at its current (hover-scaled) width, so a grown item pushes the rest
	# aside instead of covering them
	if not _labels.is_empty():
		_labels[0].position.x -= SPEED * _speed_k * delta
		for i in range(1, _labels.size()):
			_labels[i].position.x = _labels[i - 1].position.x + _shown_width(_labels[i - 1])
	while not _labels.is_empty() and _labels[0].position.x + _shown_width(_labels[0]) < 0.0:
		var gone: Label = _labels.pop_front()
		if gone == _hover_label:
			_clear_hover()
		gone.queue_free()
	# keep the crawl full: the next item starts where the last one ends
	var end := 0.0 if _labels.is_empty() else _labels[-1].position.x + _shown_width(_labels[-1])
	if _labels.is_empty():
		end = width
	var guard := 0
	while end < width + 40.0 and guard < 4:
		guard += 1
		var item: Dictionary = _queue.pop_front() if not _queue.is_empty() \
			else {"text": _filler(), "kind": Kind.FLAVOUR, "title": "", "detail": "", "loc": {}}
		var text: String = item["text"]
		var l := Label.new()
		l.set_meta("title", item["title"])
		l.set_meta("detail", item["detail"])
		l.set_meta("loc", item.get("loc", {}))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color",
			Color(1.0, 0.86, 0.50) if text.begins_with("◆") else Color(0.78, 0.84, 0.95))
		l.text = text + SEPARATOR
		l.position = Vector2(maxf(end, 0.0), 2.0)
		_clip.add_child(l)
		l.reset_size()
		_labels.append(l)
		end = l.position.x + _shown_width(l)

## Slows the crawl while the mouse is over the bar (not over the left panel
## covering it), grows the item under it and, after TIP_DELAY, shows its detail.
func _update_hover(delta: float) -> void:
	var mouse := _bar.get_viewport().get_mouse_position()
	var over := _bar.get_global_rect().has_point(mouse)
	if over:
		for n in get_tree().get_nodes_in_group(LeftPanel.GROUP):
			var c := n as Control
			if c != null and c.is_visible_in_tree() and c.get_global_rect().has_point(mouse):
				over = false
				break
	_speed_k = lerpf(_speed_k, HOVER_SPEED_K if over else 1.0, minf(delta * 6.0, 1.0))
	var hit: Label = null
	if over:
		for l: Label in _labels:
			if l.get_global_rect().has_point(mouse):
				hit = l
				break
	if hit != _hover_label:
		_clear_hover()
		_hover_label = hit
		_hover_time = 0.0
		if hit != null:
			hit.move_to_front()   # drawn over its neighbours while it grows
			if not (hit.get_meta("loc", {}) as Dictionary).is_empty():
				CursorManager.set_state(CursorManager.State.POINTER)
	for l: Label in _labels:
		var want := HOVER_SCALE if l == _hover_label else 1.0
		l.pivot_offset = Vector2(0.0, l.size.y * 0.5)
		l.scale = l.scale.lerp(Vector2(want, want), minf(delta * 10.0, 1.0))
		l.modulate = Color(1.25, 1.25, 1.25) if l == _hover_label else Color.WHITE
	if _hover_label == null:
		return
	_hover_time += delta
	var detail := String(_hover_label.get_meta("detail", ""))
	if not (_hover_label.get_meta("loc", {}) as Dictionary).is_empty():
		detail += ("\n\n" if detail != "" else "") + "Click to go there."
	if detail != "" and not _tip_shown and _hover_time >= TIP_DELAY:
		var title := String(_hover_label.get_meta("title", ""))
		TooltipManager.show_tip(title if title != "" else "News", detail)
		_tip_shown = true

func _clear_hover() -> void:
	if _tip_shown:
		TooltipManager.hide_tip()
	if _hover_label != null and is_instance_valid(_hover_label) \
			and not (_hover_label.get_meta("loc", {}) as Dictionary).is_empty():
		CursorManager.set_state(CursorManager.State.NORMAL)
	_tip_shown = false
	_hover_label = null

func _on_bar_input(ev: InputEvent) -> void:
	var mb := ev as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if _hover_label == null or not is_instance_valid(_hover_label):
		return
	var loc: Dictionary = _hover_label.get_meta("loc", {})
	if loc.is_empty():
		return
	AudioManager.play("click")
	_clear_hover()
	go_to(loc)

## Takes the camera to a place: the planet view focuses it in place, or opens
## on its world first (PlanetaryView picks the request up on load).
func go_to(loc: Dictionary) -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("focus_news_location"):
		scene.call("focus_news_location", loc)
		return
	var pd := GameState.get_planet_data(int(loc.get("seed", -1)))
	if pd == null:
		return
	GameState.set_meta("focus_news", loc)
	pd.set_meta("__solar_data", GameState.get_home_solar())
	SceneTransition.go("res://scenes/planetary/PlanetaryView.tscn", pd)

## A crawl item's width on screen (its hover scale included).
static func _shown_width(l: Label) -> float:
	return l.size.x * l.scale.x
