## GameState — autoload singleton.
## Tracks global progression: credits, unlocks, per-planet progress.
extends Node

signal credits_changed(new_val: float)
signal save_deleted
signal science_changed(new_val: float)
signal world_ready
signal unlock_changed(key: String, value: bool)
signal planet_progress_changed(seed_val: int)
signal asteroid_discovered(slot: int, count: int)
signal global_resources_changed
signal district_placed(planet_seed: int, district_type_id: int)

# ── Starting Config (edit these to change new-game defaults) ─────────────────
## Starting credits / Science for a new game come from the balance profile
## (Balance.cfg.start_credits, start_science).
## Whether Solar View is unlocked from the start.
@export var start_solar_unlocked: bool  = false
## Whether Galaxy View is unlocked from the start.
@export var start_galaxy_unlocked: bool = false
## Whether the home planet starts colonized.
@export var start_colonized:      bool  = true

# ── Economy ──────────────────────────────────────────────────────────────────
## Global mineral/resource pool shared across all planets and facilities.
var global_resources: Dictionary = {}
## Resources the top bar has revealed so far (it shows them as they're met).
var revealed_resources: Array = []

# ── Civilization & mineral discovery ─────────────────────────────────────────
## Medeniyet tipi 0–5 (docs/design/PLAN.md M0.3). Gates which minerals exist for
## the player (Economy.mineral_civ).
var civilization_type: int = 0
## Bodies whose minerals have been discovered: seed -> true. A body is surveyed
## when its first raw producer (mine building or Mining district) is completed.
var surveyed_bodies: Dictionary = {}
## Minerals discovered anywhere: id -> true. Permanent — losing the last mine
## doesn't hide a mineral again.
var discovered_minerals: Dictionary = {}
signal minerals_discovered(body_seed: int, mineral_ids: Array)
signal trade_changed

## Trade (see Trade.gd): player reserves {id: amount}, automation orders
## {id: order}, recent trades and the running overflow-sale totals.
var trade_reserves: Dictionary = {}
var trade_orders: Dictionary = {}
var trade_log: Array = []
var trade_seq: int = 0
var overflow_sold: Dictionary = {}

func is_body_surveyed(body_seed: int) -> bool:
	return surveyed_bodies.has(body_seed)

## Discovers a body's minerals (for the current civilization) once its first
## raw producer is complete. Returns the minerals new to the player.
func discover_body_minerals(body_seed: int) -> Array:
	var pd := get_planet_data(body_seed)
	if pd == null:
		return []
	surveyed_bodies[body_seed] = true
	var fresh: Array = []
	for r: Dictionary in Economy.raw_for_body(pd):
		if not discovered_minerals.has(r["id"]):
			discovered_minerals[r["id"]] = true
			fresh.append(r["id"])
	if not fresh.is_empty():
		minerals_discovered.emit(body_seed, fresh)
	return fresh

## Saves from before discovery existed: bodies that already have a finished
## raw producer count as surveyed.
func _sync_mineral_discoveries() -> void:
	for pp: PlanetProgress in _planet_progress.values():
		if not pp.is_colonized or surveyed_bodies.has(pp.planet_seed):
			continue
		var found := false
		for b: Dictionary in pp.buildings:
			var def := BuildingDef.find(String(b.get("building_id", "")))
			if def != null and def.outputs.has(Economy.RAW) and not b.get("constructing", false):
				found = true
				break
		var pd := get_planet_data(pp.planet_seed)
		if not found and pd != null:
			for poi: POIData in pd.custom_pois:
				var ddef := ProductionManager.district_def(poi)
				if ddef != null and not poi.constructing and ddef.base_outputs.has(Economy.RAW):
					found = true
					break
		if found:
			discover_body_minerals(pp.planet_seed)
## The planet-wide view (planet overview, more cities, planet level) opens once
## the first City reaches Lv 2 — until then the side panel stays on the City.
var planet_view_unlocked: bool = false

## Adds to the stock, up to the resource's storage cap (Economy.cap). New
## stock that doesn't fit is sold once Trade Access is researched, otherwise
## lost (Trade.sell_overflow). Old stock above the cap stays as it is.
func add_resource(resource_id: String, amount: float) -> void:
	var have: float = global_resources.get(resource_id, 0.0)
	var v := have + amount
	if amount > 0.0 and Economy.is_capped(resource_id):
		v = maxf(have, minf(v, Economy.cap(resource_id)))
		var overflow := have + amount - v
		if overflow > 0.0001:
			Trade.sell_overflow(resource_id, overflow)
	global_resources[resource_id] = v
	global_resources_changed.emit()

func consume_resource(resource_id: String, amount: float) -> bool:
	var have: float = global_resources.get(resource_id, 0.0)
	if have < amount:
		return false
	global_resources[resource_id] = have - amount
	global_resources_changed.emit()
	return true

func get_resource(resource_id: String) -> float:
	return global_resources.get(resource_id, 0.0)

var credits: float = 500.0 :
	set(v):
		credits = maxf(v, 0.0)
		credits_changed.emit(credits)

var science_points: float = 0.0 :
	set(v):
		science_points = maxf(v, 0.0)
		science_changed.emit(science_points)

# ── Unlock flags ─────────────────────────────────────────────────────────────
var solar_unlocked:    bool = false
var moon_unlocked:     bool = false
## Moonstone actually mined on the Moon (bought Moonstone never counts) — the
## final rocket's research needs 100 (GDD §17.9, KARARLAR §5).
var moon_local_moonstone: float = 0.0
var galaxy_unlocked:   bool = false

# ── Showcase (read-only viewer) ──────────────────────────────────────────────
## Explore mode (internally "showcase"): a read-only look around every map —
## galaxy, systems, other planets — from inside the player's own game, once the
## tutorial is done (HUD "◎ Explore" button). Gameplay UI is hidden and nothing
## can be built there; the player's economy keeps running in the background.
## ESC or the RETURN button goes back to the home world. Never saved itself.
var showcase_mode: bool = false
## Browser demo (itch.io web build, feature tag "demo"): nothing is saved or
## loaded — a refresh starts over. See docs/design/ITCH_DEMO_PLAN.md.
var demo_build: bool = is_demo_build()

static func is_demo_build() -> bool:
	return OS.has_feature("demo") or OS.has_feature("web")

## Seconds played in this world (unpaused), for the demo's end screen.
var play_seconds: float = 0.0
## The "first step on the Moon" banner was shown (once per world).
var moon_city_celebrated: bool = false

## Numbers for the demo's end screen: minutes played, worlds settled, cities,
## research bought.
func demo_stats() -> Dictionary:
	var worlds := 0
	var cities := 0
	for sd in _planet_progress:
		if (_planet_progress[sd] as PlanetProgress).is_colonized:
			worlds += 1
			var pd := get_planet_data(int(sd))
			if pd != null:
				for p: POIData in pd.custom_pois:
					if p.is_city() and not p.constructing:
						cities += 1
	var research := 0
	for id: String in SkillTree.unlocked_skills:
		if not id in SkillTree.DEFAULT_SKILLS:
			research += 1
	return {"minutes": int(play_seconds / 60.0), "worlds": worlds, "cities": cities, "research": research}

## Explore opens once the guided tutorial is done and the Moon has a City.
func explore_available() -> bool:
	# the wider universe opens once the Moon is settled (playtest 23.10)
	return TutorialManager.tutorial_finished() and not showcase_mode and SkillTree.event_met("moon_city")

## Leaves the player's world for the read-only map tour (starts at the galaxy).
func start_explore() -> void:
	if showcase_mode:
		return
	enter_showcase()
	SceneTransition.go("res://scenes/galaxy/GalaxyView.tscn")

## Back from the tour to the home world.
func end_explore() -> void:
	if not showcase_mode:
		return
	exit_showcase()
	var home := get_home_planet()
	if home != null:
		SceneTransition.go("res://scenes/planetary/PlanetaryView.tscn", home)
	else:
		SceneTransition.go("res://scenes/galaxy/GalaxyView.tscn")

## View access — showcase opens every map without touching the unlock flags;
## so does completing the demo (post-demo inspection, PLAN M7). Only viewing
## opens: playing other content still follows playable_content_type.
func can_view_solar() -> bool:
	return showcase_mode or demo_completed or solar_unlocked

func can_view_galaxy() -> bool:
	return showcase_mode or demo_completed or galaxy_unlocked

func can_view_moon() -> bool:
	return showcase_mode or demo_completed or moon_unlocked

## Whether a body can be played on (settled, built on). Showcase never plays;
## after the demo, only the home world and its Moon keep being playable.
func can_play_on(planet_seed: int) -> bool:
	if showcase_mode:
		return false
	if not demo_completed:
		return true
	var moon := home_moon()
	return planet_seed == home_planet_seed or (moon != null and planet_seed == moon.seed)

func enter_showcase() -> void:
	save()   # keep progress safe before looking around (no-op in the demo)
	showcase_mode = true
	HUDManager.set_game_hud(false)
	_show_explore_bar()

## RETURN button + a short controls hint that fades (the button stays).
var _explore_layer: CanvasLayer = null
func _show_explore_bar() -> void:
	if _explore_layer != null and is_instance_valid(_explore_layer):
		_explore_layer.queue_free()
	_explore_layer = CanvasLayer.new()
	_explore_layer.layer = 150
	add_child(_explore_layer)
	var font := load("res://Fonts/Orbitron-VariableFont_wght.ttf") as Font
	var back := Button.new()
	back.text = "↩  RETURN TO YOUR WORLD"
	back.focus_mode = Control.FOCUS_NONE
	if font:
		back.add_theme_font_override("font", font)
	back.add_theme_font_size_override("font_size", 11)
	back.add_theme_color_override("font_color", Color(0.65, 1.0, 0.75))
	back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	back.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	back.grow_vertical = Control.GROW_DIRECTION_BEGIN
	back.position -= Vector2(16, 14)
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		end_explore())
	_explore_layer.add_child(back)
	var lbl := Label.new()
	lbl.text = "EXPLORING  ·  look around freely — nothing here can be built  ·  ESC return  ·  H hide navigation"
	if font:
		lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 1.0, 0.85))
	lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	lbl.position += Vector2(16, -18)
	_explore_layer.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.0)

func exit_showcase() -> void:
	var was := showcase_mode
	showcase_mode = false
	if was:
		HUDManager.set_game_hud(true)   # the planet view doesn't re-show it itself
	if _explore_layer != null and is_instance_valid(_explore_layer):
		_explore_layer.queue_free()
	_explore_layer = null

## Seed of the planet currently shown in PlanetaryView. -1 when not in that scene.
var active_planet_seed: int = -1
var discovered_asteroids: Array[int] = []
var asteroid_scan_counts: Dictionary = {}   # slot → int (1-3 asteroids revealed)

# day/night cycle — persists across scene changes, advances in real time
var light_angle:          float = 0.8
var light_last_unix:      int   = 0   # unix timestamp when we last stored the angle

# ── Per-planet progress ───────────────────────────────────────────────────────
var _planet_progress:       Dictionary = {}
var _body_resources:        Dictionary = {}
var known_resources:        Dictionary = {}
var resource_deposit_counts: Dictionary = {}
var unlocked_buildings:     Dictionary = {}
## Temp storage: POI dicts loaded from save, applied after _bootstrap_world
var _pending_poi_restore:   Dictionary = {}  # seed_val(int) -> Array[Dictionary]

# ── Home location (set once at world generation, then saved) ─────────────────
var home_planet_seed: int  = -1   # seed of the Terran home planet
var home_star_idx:    int  = -1   # which star in home_galaxy is the home system
var home_planet_idx:  int  = -1   # which planet index in that system

# ── Pre-generated world ───────────────────────────────────────────────────────
var home_galaxy: GalaxyData = null
var _home_solar: SolarData  = null

# ────────────────────────────────────────────────────────────────────────────

var _autosave_timer: float = 0.0
const AUTOSAVE_INTERVAL := 60.0

func _ready() -> void:
	ShipManager.ship_arrived.connect(_on_ship_arrived)
	load_save()
	if home_planet_seed < 0:
		home_planet_seed = randi_range(1000, 99999)
	_bootstrap_world()

func _process(delta: float) -> void:
	if not get_tree().paused:
		play_seconds += delta
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		save()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_EXIT_TREE:
		save()

static func has_save() -> bool:
	if is_demo_build():
		return false
	return FileAccess.file_exists(SAVE_PATH)

func unlock_building(building_id: String) -> void:
	if not unlocked_buildings.has(building_id):
		unlocked_buildings[building_id] = true
		print("Building Unlocked: ", building_id)

func _bootstrap_world() -> void:
	# Galaxy first
	if home_galaxy == null:
		home_galaxy = GalaxyData.from_seed(home_planet_seed ^ 0xABCDEF)

	# Home star is always galaxy.home_idx (index 0, center star)
	if home_star_idx < 0 and home_galaxy != null:
		home_star_idx = home_galaxy.home_idx

	# Build home solar and inject home planet at chosen index
	if _home_solar == null:
		_home_solar = _build_home_solar()
	if not _loaded_from_save:
		_apply_new_game_start()

	_seed_starting_resources()
	_apply_pending_pois()
	_sync_mineral_discoveries()
	world_ready.emit()

## Starting budget and unlocks of a brand-new game (Balance.cfg + Starting Config).
## Runs once per new world: loading a save, switching scenes or resetting a
## settlement never hands the budget out again.
func _apply_new_game_start() -> void:
	credits         = Balance.cfg.start_credits
	science_points  = Balance.cfg.start_science
	solar_unlocked  = start_solar_unlocked
	galaxy_unlocked = start_galaxy_unlocked
	get_planet(home_planet_seed).is_colonized = start_colonized
	_loaded_from_save = true   # this world is now the game in progress

func _apply_pending_pois() -> void:
	for seed_val: int in _pending_poi_restore:
		var poi_list: Array = _pending_poi_restore[seed_val]
		var pd_target: PlanetData = get_planet_data(seed_val)
		if pd_target == null:
			pd_target = PlanetData.from_seed(seed_val)
			cache_planet_data(pd_target)
		pd_target.custom_pois.clear()
		for pd_entry: Dictionary in poi_list:
			var poi := POIData.new()
			poi.label              = pd_entry.get("label",              "District")
			poi.display_name       = pd_entry.get("display_name",       "")
			poi.neighbors          = pd_entry.get("neighbors",          [])
			poi.neighbor_weight    = pd_entry.get("neighbor_weight",    {})
			poi.poi_type           = pd_entry.get("poi_type",           0) as POIData.POIType
			poi.type_tag           = pd_entry.get("type_tag",           "")
			poi.light_intensity    = pd_entry.get("light_intensity",    1.0)
			poi.level              = pd_entry.get("level",              1)
			poi.placement          = pd_entry.get("placement",          0) as LocationFinder.Placement
			poi.manual_position    = pd_entry.get("manual_position",    false)
			poi.lon_deg            = pd_entry.get("lon_deg",            0.0)
			poi.lat_deg            = pd_entry.get("lat_deg",            0.0)
			poi.terrain            = pd_entry.get("terrain",            -1)
			poi.coastal            = pd_entry.get("coastal",            false)
			poi.parent_city        = pd_entry.get("parent_city",        "")
			poi.resource_tags      = pd_entry.get("resource_tags",      {})
			poi.site_features      = pd_entry.get("site_features",      {})
			poi.paid_credits       = float(pd_entry.get("paid_credits",  -1.0))
			poi.spoke_birth        = pd_entry.get("spoke_birth",        {})
			poi.constructing       = pd_entry.get("constructing",       false)
			poi.construct_progress = pd_entry.get("construct_progress", 0.0)
			poi.construct_duration = pd_entry.get("construct_duration", 15.0)
			poi.orbit_angle        = pd_entry.get("orbit_angle",        0.0)
			poi.orbit_speed        = pd_entry.get("orbit_speed",        0.25)
			poi.orbit_inclination  = pd_entry.get("orbit_inclination",  0.0)
			poi.orbit_node         = pd_entry.get("orbit_node",         0.0)
			poi.orbit_radius       = pd_entry.get("orbit_radius",       1.35)
			pd_target.custom_pois.append(poi)
	_pending_poi_restore.clear()

func _seed_starting_resources() -> void:
	var home_pp := get_planet(home_planet_seed)
	var home_pd := get_home_planet()

	# Home starts with a single raw resource (its body type's, e.g. Ferrite);
	# more appear as the player reaches moons and other worlds.
	if home_pd != null:
		get_body_resources_for(home_pd)
	_register_processed_resources()

	pass  # orbital district added later via SkillTree unlock

func _build_home_solar() -> SolarData:
	# Use the galaxy star's own seed so the system matches what the galaxy would generate
	var solar_seed: int
	if home_galaxy != null and home_star_idx >= 0 and home_star_idx < home_galaxy.seeds.size():
		solar_seed = home_galaxy.seeds[home_star_idx]
	else:
		solar_seed = home_planet_seed ^ 0x1234
	var sd         := SolarData.from_seed(solar_seed, true)  # ensure_gas_giant
	sd.is_home     = true
	sd.hop_distance = 0
	if home_galaxy != null and home_star_idx >= 0:
		sd.system_name = home_galaxy.names[home_star_idx]
		sd.star_type   = home_galaxy.types[home_star_idx] as SolarData.StarType

	# Decide home planet index by seed (not necessarily 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = home_planet_seed ^ 0x5678
	home_planet_idx = rng.randi() % maxi(sd.planets.size(), 1)

	# Override that slot with guaranteed Terran planet — always exactly 1 moon
	var home_pd := PlanetData.from_seed_as_type(home_planet_seed, PlanetData.Type.TERRAN)
	home_pd.continentality = HOME_CONTINENTALITY   # the home world: a few big continents
	home_pd.moons.clear()
	var moon := PlanetData.make_moon(home_planet_seed ^ 0x4D6F6F6E)
	moon.planet_name = home_pd.planet_name + " a"
	home_pd.moons.append(moon)
	home_pd.set_meta("__is_home", true)
	
	sd.planets[home_planet_idx] = home_pd

	# Cache all generated planets in the home system so that tooltips and production
	# work correctly immediately after loading a save file.
	for pd in sd.planets:
		cache_planet_data(pd)
		for m in pd.moons:
			cache_planet_data(m)

	sd.set_meta("__is_home", true)

	# The new-game budget and unlocks are applied in _bootstrap_world, and only
	# for a real new game — never over a loaded save.
	# No starting City: the player picks the site and names it (PlanetaryView).

	if home_planet_idx < sd.planets.size():
		sd.planets[home_planet_idx] = home_pd
	else:
		sd.planets.append(home_pd)
		home_planet_idx = sd.planets.size() - 1

	# Propagate hop=0 to all home system planets for resource rarity
	sd.tag_planets_hop()

	# Tag the solar data with the galaxy reference for back-navigation
	if home_galaxy != null:
		sd.set_meta("__galaxy_data",    home_galaxy)
		sd.set_meta("__galaxy_star_idx", home_star_idx)

	return sd

# ── Accessors ─────────────────────────────────────────────────────────────────

func get_home_solar() -> SolarData:
	return _home_solar

func get_home_planet() -> PlanetData:
	if _home_solar == null or home_planet_idx < 0:
		return null
	return _home_solar.planets[home_planet_idx]

func get_planet(seed_val: int) -> PlanetProgress:
	if not _planet_progress.has(seed_val):
		_planet_progress[seed_val] = PlanetProgress.make(seed_val)
	return _planet_progress[seed_val]

## Returns cached PlanetData for a given seed (set by PlanetaryView when visiting).
var _planet_data_cache: Dictionary = {}   # seed -> PlanetData
func cache_planet_data(pd: PlanetData) -> void:
	_planet_data_cache[pd.seed] = pd
func get_planet_data(seed_val: int) -> PlanetData:
	return _planet_data_cache.get(seed_val, null)

## Raw resources of a body by seed (only valid once the body's PlanetData is
## known — falls back to an empty pool).
func get_body_resources(body_seed: int, _rarity_min: int = 1, _rarity_max: int = 1) -> BodyResources:
	if not _body_resources.has(body_seed):
		var pd := get_planet_data(body_seed)
		if pd != null:
			return get_body_resources_for(pd)
		var empty := BodyResources.new()
		empty.body_seed = body_seed
		return empty
	return _body_resources[body_seed] as BodyResources

## The named raw resources on a body (Economy.RAW_TABLE by body type and hop).
func get_body_resources_for(pd: PlanetData) -> BodyResources:
	if not _body_resources.has(pd.seed):
		var br := BodyResources.generate_for(pd)
		_body_resources[pd.seed] = br
		_register_resources(br)
	var out: BodyResources = _body_resources[pd.seed]
	if pd.mineral_densities.is_empty():
		_populate_mineral_densities(pd, out)
	return out

func _populate_mineral_densities(pd: PlanetData, br: BodyResources) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = pd.seed ^ 0x9999
	var raw_list := br.get_by_tag(ResourceData.Tag.RAW_MINERAL)
	if raw_list.is_empty(): return
	
	var base_density := pd.deposit_density
	var total_weight: float = 0.0
	var weights: Array[float] = []
	for rd in raw_list:
		# Lower rarity = much higher weight. e.g. R1=1.0, R2=0.4, R3=0.16
		var w := 1.0 / pow(2.5, float(rd.rarity - br.rarity_min))
		w *= rng.randf_range(0.8, 1.2)
		weights.append(w)
		total_weight += w
	
	for i in raw_list.size():
		var share := weights[i] / total_weight
		pd.mineral_densities[raw_list[i].resource_id()] = share * base_density * rng.randf_range(0.9, 1.1)

## Goods / Fuel / Rare Elements are known from the start (cargo, costs, icons).
func _register_processed_resources() -> void:
	for id: String in Economy.PROCESSED:
		if not known_resources.has(id):
			known_resources[id] = ResourceData.from_processed(id)

func _register_resources(br: BodyResources) -> void:
	for rd: ResourceData in br.as_array():
		var type_key := rd.resource_id()
		if not known_resources.has(type_key):
			known_resources[type_key] = rd
			resource_deposit_counts[type_key] = 1
		else:
			resource_deposit_counts[type_key] = resource_deposit_counts.get(type_key, 1) + 1

func deposit_count(resource_id: String) -> int:
	return resource_deposit_counts.get(resource_id, 0)

# ── Unlocks ───────────────────────────────────────────────────────────────────

func set_unlock(key: String, value: bool) -> void:
	match key:
		"solar":  solar_unlocked  = value
		"galaxy": galaxy_unlocked = value
	unlock_changed.emit(key, value)

func discover_asteroid(slot_idx: int) -> void:
	var cur: int = asteroid_scan_counts.get(slot_idx, 0)
	if cur >= 3:
		return
	var new_count := cur + 1
	asteroid_scan_counts[slot_idx] = new_count
	if slot_idx not in discovered_asteroids:
		discovered_asteroids.append(slot_idx)
	asteroid_discovered.emit(slot_idx, new_count)

func discover_asteroid_all(slot_idx: int) -> void:
	asteroid_scan_counts[slot_idx] = 3
	if slot_idx not in discovered_asteroids:
		discovered_asteroids.append(slot_idx)
	asteroid_discovered.emit(slot_idx, 3)

# ── Economy ───────────────────────────────────────────────────────────────────

func spend_credits(amount: float) -> bool:
	if credits < amount:
		return false
	credits -= amount
	return true

func earn_credits(amount: float) -> void:
	credits += amount

func add_science(amount: float) -> void:
	science_points += amount

func spend_science(amount: float) -> bool:
	if science_points < amount:
		return false
	science_points -= amount
	return true

## Stub colonize — no ship requirement yet. Returns false if can't afford.
func colonize_planet(planet_seed: int, cost: float = 1000.0) -> bool:
	if not spend_credits(cost):
		return false
	var pp := get_planet(planet_seed)
	pp.is_colonizing = true
	pp.colonize_progress = 0.0
	pp.colonize_duration = 30.0 # 30 seconds
	
	planet_progress_changed.emit(planet_seed)
	return true

# ── Expeditions (GDD §20) ────────────────────────────────────────────────────
# Two expeditions finish Civilization 0:
#   lander  Earth Spaceport → Moon. Paid once when preparation starts (30 s),
#           then it flies MOON_TRANSIT_SEC, parks in lunar orbit (lander_state 1),
#           the player picks the landing site and the first lunar City is free.
#   rocket  Lunar Spaceport → another natural planet of the home system. Paid
#           once (60 s preparation); the target can change until it launches;
#           the flight takes 60 s and its arrival completes Civilization 0.
# States: preparing → ready → in_transit → arrived. A state change never
# charges again, and the arrival is recorded once.
const LANDER_COST := {"credits": 3000.0, "ferrite": 40.0, "fuel": 20.0}
const LANDER_PREP_SEC  := 30.0
const MOON_TRANSIT_SEC := 30.0
const ROCKET_COST := {"credits": 12000.0, "moonstone": 1200.0, "goods": 30.0, "fuel": 120.0, "rare_elements": 40.0}
const ROCKET_PREP_SEC   := 60.0
const ROCKET_FLIGHT_SEC := 60.0

signal act1_completed
signal expedition_changed(kind: String)
## Emitted once when the final rocket arrives (civ = the civilization reached).
signal civilization_reached(civ: int)
## Founding the first City on the Moon: the lander's landing module, paid
## separately from the lander (which only reaches orbit and sets up the Moon's
## Central Orbit).
const LANDING_COST := {"credits": 1000.0, "ferrite": 20.0}
## Worlds whose surface has been scanned from orbit: their role lenses work.
## The home world counts as scanned. { seed: true }
var scanned_bodies: Dictionary = {}
## Worlds whose landing module is paid for (re-trying the landing is free).
var landing_paid: Dictionary = {}

func is_scanned(planet_seed: int) -> bool:
	return planet_seed == home_planet_seed or scanned_bodies.has(planet_seed)

## The lander reached the Moon: it sets up the Moon's Central Orbit (the hub of
## the trade network there) as the first part of colonising it.
func deploy_central_orbit(planet_seed: int) -> void:
	var pd := get_planet_data(planet_seed)
	if pd == null or Leveling.orbit_hub(pd) != null:
		return
	var def := DistrictDef.find(DistrictDef.Type.SPACE_STATION)
	if def == null:
		return
	var lander := moon_lander(planet_seed)
	var poi := POIData.new()
	poi.label = POIData.make_key(pd)
	poi.display_name = "Central Orbit"
	poi.poi_type = def.to_poi_type()
	poi.type_tag = DistrictDef.Type.keys()[def.id].to_lower()
	poi.placement = def.placement
	poi.constructing = false
	poi.construct_progress = 1.0
	poi.paid_credits = 0.0
	poi.orbit_angle = lander.orbit_angle if lander != null else randf() * TAU
	poi.orbit_inclination = lander.orbit_inclination if lander != null else 0.5
	poi.orbit_node = lander.orbit_node if lander != null else 0.0
	poi.orbit_speed = 0.01
	poi.orbit_radius = 1.06
	poi.manual_position = true
	poi.light_intensity = 0.0
	pd.custom_pois.append(poi)
	var pp := get_planet(planet_seed)
	pp.orbit_level = maxi(pp.orbit_level, 1)
	if lander != null:   # the lander itself becomes the Central Orbit
		ShipManager.remove_ship(planet_seed, lander.ship_id)
	planet_progress_changed.emit(planet_seed)

## The landing module leaves the Central Orbit (INITIATE COLONIZATION): a lander
## ship starting at the hub's place in orbit.
func spawn_lander_from_hub(planet_seed: int) -> ShipData:
	var hub := Leveling.orbit_hub(get_planet_data(planet_seed))
	var ship := ShipManager.launch(planet_seed, "Landing Module")
	_lander_orbit(ship)
	if hub != null:
		ship.orbit_radius = hub.orbit_radius
		ship.orbit_inclination = hub.orbit_inclination
		ship.orbit_node = hub.orbit_node
		ship.orbit_angle = hub.orbit_angle
	return ship

## The lander parked in the Moon's orbit (HUD offers to fly there).
signal lander_reached_moon(moon_seed: int)

## The lander's one lap around the home world before it leaves for the Moon (rad/s).
const LANDER_LOOP_SPEED := 0.35

## Old saves: the first City on another world ended the old demo. Kept only so
## those saves load; nothing reads it any more.
var act1_complete: bool = false
## Offline (KARARLAR §4, PLAN M8): the time the game was closed is recorded and
## shown on return. Gains stay off behind one switch, the balance profile's
## offline_progress_enabled; when it is ever turned on, the same cycle code
## must advance the economy — no second offline economy.
const OFFLINE_MIN_SECONDS := 60.0
var offline_seconds: float = 0.0
## Set by load_save; the HUD shows the "while you were away" screen once.
var offline_pending: bool = false
## Time away is measured once per session, at the first load of the save:
## later loads (the main menu reads the save, CONTINUE reads it again) see a
## fresh saved_at and would report nothing.
var _offline_measured: bool = false

static func offline_progress_enabled() -> bool:
	return Balance.cfg.offline_progress_enabled

## World generation version. 2: planets have continentality. Saves without the
## field are 1 and keep their old terrain.
const WORLD_GEN := 2
## Home world's continentality. Above 1 pushes past the usual range: most of the
## land gathers into two or three large continents, few island chains.
const HOME_CONTINENTALITY := 1.35
var world_gen: int = WORLD_GEN

## The final rocket has arrived: Civilization 1 reached, the demo is complete.
var demo_completed: bool = false
## Highest civilization whose content can actually be played (0 in the demo).
var playable_content_type: int = 0
## kind -> { state, prep_left, flight_left, target_seed }
var expeditions: Dictionary = {}

func expedition(kind: String) -> Dictionary:
	return expeditions.get(kind, {})

func expedition_state(kind: String) -> String:
	return String(expedition(kind).get("state", ""))

## The home world's Moon (null before the world is built).
func home_moon() -> PlanetData:
	var home := get_home_planet()
	if home == null or home.moons.is_empty():
		return null
	return home.moons[0]

## True when a finished building of this id stands on that body.
func has_finished_building(planet_seed: int, building_id: String) -> bool:
	var pp: PlanetProgress = _planet_progress.get(planet_seed, null)
	if pp == null:
		return false
	for b: Dictionary in pp.buildings:
		if b.get("building_id", "") == building_id and not b.get("constructing", false):
			return true
	return false

## Why the lander can't be prepared for this Moon right now ("" when it can).
func moon_colonize_block(planet_seed: int) -> String:
	var pp := get_planet(planet_seed)
	var st := expedition_state("lander")
	if st == "preparing":
		return "The lander is being prepared"
	if st == "launching" or st == "orbiting":
		return "The lander is lifting off"
	if pp.is_colonized or pp.is_colonizing or st == "in_transit":
		return "Already underway"
	if not get_node("/root/SkillTree").is_unlocked("lunar_program"):
		return "Research Lunar Program first"
	if not has_finished_building(home_planet_seed, "spaceport"):
		return "Build a Spaceport on your home world"
	if not SkillTree.event_met("orbit_station"):
		return "Put a Space Station into orbit first"
	var short := Economy.cost_block(LANDER_COST)
	return short

## Pays the lander and starts its preparation (it launches on its own).
func start_moon_colonization(planet_seed: int) -> bool:
	if moon_colonize_block(planet_seed) != "":
		return false
	if not Economy.pay(LANDER_COST):
		return false
	expeditions["lander"] = {"state": "preparing", "prep_left": LANDER_PREP_SEC, "flight_left": MOON_TRANSIT_SEC,
		"target_seed": planet_seed}
	expedition_changed.emit("lander")
	planet_progress_changed.emit(planet_seed)
	save()
	return true

func _launch_lander(planet_seed: int, secs: float) -> void:
	var pp := get_planet(planet_seed)
	pp.is_colonizing = true
	pp.colonize_progress = 0.0
	pp.colonize_duration = secs
	launch_moon_lander(planet_seed, secs)
	expeditions["lander"]["state"] = "in_transit"
	expedition_changed.emit("lander")
	planet_progress_changed.emit(planet_seed)
	save()

## The lander ship of the current expedition (null if gone).
func _lander_ship() -> ShipData:
	var id := String(expedition("lander").get("ship_id", ""))
	for s: ShipData in ShipManager.ships_for(home_planet_seed):
		if s.ship_id == id:
			return s
	return null

## A lander placed straight into the home orbit (no lift-off on screen).
func _spawn_home_lander() -> ShipData:
	var ship := ShipManager.launch(home_planet_seed, "Colony Lander")
	ship.orbit_radius = 1.06
	ship.orbit_inclination = randf_range(-0.4, 0.4)
	return ship

## The lander has reached the home orbit (after the Spaceport lift-off): it
## laps the world once, then heads for the Moon. A lift-off that finishes
## after the expedition moved on just removes its ship.
func lander_in_orbit(ship: ShipData) -> void:
	if ship == null:
		return
	if expedition_state("lander") != "launching":
		ShipManager.remove_ship(ship.orbit_seed, ship.ship_id)
		return
	ship.ship_type = "lander"
	ship.ship_name = "Colony Lander"
	ship.orbit_speed = (1.0 if ship.orbit_speed >= 0.0 else -1.0) * LANDER_LOOP_SPEED
	var ex: Dictionary = expeditions["lander"]
	ex["state"] = "orbiting"
	ex["ship_id"] = ship.ship_id
	ex["loop_left"] = TAU
	expedition_changed.emit("lander")
	save()

## The planet view saw the lander reach the point facing the Moon.
func depart_lander_now() -> void:
	var ship := _lander_ship()
	if ship != null and expedition_state("lander") == "orbiting":
		_depart_lander(ship)

func _depart_lander(ship: ShipData) -> void:
	var moon_seed := int(expedition("lander").get("target_seed", -1))
	var pp := get_planet(moon_seed)
	pp.is_colonizing = true
	pp.colonize_progress = 0.0
	pp.colonize_duration = MOON_TRANSIT_SEC
	_lander_orbit(ship)   # the orbit it settles into at the Moon
	ShipManager.dispatch(ship, moon_seed, MOON_TRANSIT_SEC)
	expeditions["lander"]["state"] = "in_transit"
	expedition_changed.emit("lander")
	planet_progress_changed.emit(moon_seed)
	save()

## Why the final rocket can't be prepared right now ("" when it can).
func rocket_block() -> String:
	var st := expedition_state("rocket")
	if st != "":
		return "The rocket is already %s" % ("on its way" if st == "in_transit" else st if st != "arrived" else "there")
	if playable_content_type > 0 or demo_completed:
		return "Civilization 0 is complete"
	if not get_node("/root/SkillTree").is_unlocked("advanced_planet_rocket"):
		return "Research Advanced Planetary Rocket"
	var moon := home_moon()
	if moon == null or not has_finished_building(moon.seed, "lunar_spaceport"):
		return "Build a Lunar Spaceport on the Moon"
	return Economy.cost_block(ROCKET_COST)

func start_rocket(target_seed: int = -1) -> bool:
	if rocket_block() != "":
		return false
	if not Economy.pay(ROCKET_COST):
		return false
	expeditions["rocket"] = {"state": "preparing", "prep_left": ROCKET_PREP_SEC, "flight_left": ROCKET_FLIGHT_SEC,
		"target_seed": target_seed if rocket_target_block(target_seed) == "" else -1}
	expedition_changed.emit("rocket")
	save()
	return true

## Why a body can't be the final rocket's target ("" when it can): another
## natural planet of the home system — not the home world, not the Moon.
func rocket_target_block(target_seed: int) -> String:
	if target_seed < 0:
		return "No target"
	if target_seed == home_planet_seed:
		return "Your home world isn't a new destination"
	var moon := home_moon()
	if moon != null and target_seed == moon.seed:
		return "The Moon is where the rocket starts"
	if _home_solar == null:
		return "Unknown system"
	for pd: PlanetData in _home_solar.planets:
		if pd.seed == target_seed:
			return "" if pd.planet_type != PlanetData.Type.ASTEROID else "Pick a planet"
	return "Pick a planet of your home system"

## Sets (or changes) the rocket's target while it is still on the ground.
func set_rocket_target(target_seed: int) -> bool:
	var st := expedition_state("rocket")
	if (st != "preparing" and st != "ready") or rocket_target_block(target_seed) != "":
		return false
	expeditions["rocket"]["target_seed"] = target_seed
	expedition_changed.emit("rocket")
	save()
	return true

## Advances preparation and flights (ProductionManager calls it every frame).
func tick_expeditions(delta: float) -> void:
	var lander: Dictionary = expeditions.get("lander", {})
	match String(lander.get("state", "")):
		"preparing":   # being built at the Spaceport
			lander["prep_left"] = float(lander["prep_left"]) - delta
			if float(lander["prep_left"]) <= 0.0:
				lander["state"] = "launching"
				lander["launch_age"] = 0.0
				lander["animating"] = false
				expedition_changed.emit("lander")   # PlanetaryView plays the lift-off if it shows home
		"launching":   # lifting off; without a lift-off on screen it appears in orbit
			lander["launch_age"] = float(lander.get("launch_age", 0.0)) + delta
			# a lift-off on screen hands the ship over itself (lander_in_orbit);
			# only when none is playing does the lander appear in orbit directly
			if not bool(lander.get("animating", false)) and float(lander["launch_age"]) > 0.3:
				lander_in_orbit(_spawn_home_lander())
		"orbiting":    # circles the home world, then leaves for the Moon
			var ship := _lander_ship()
			if ship == null:
				_launch_lander(int(lander["target_seed"]), MOON_TRANSIT_SEC)
			else:
				lander["loop_left"] = float(lander.get("loop_left", TAU)) - absf(ship.orbit_speed) * delta
				# while the home world is on screen, the planet view waits for the
				# point of the orbit that faces the Moon (depart_lander_now); unseen,
				# the lander leaves after its lap — and never circles a second time
				var watched := Time.get_ticks_msec() - int(lander.get("watched_ms", -100000)) < 500
				if (float(lander["loop_left"]) <= 0.0 and not watched) or float(lander["loop_left"]) <= -TAU:
					_depart_lander(ship)
	var rocket: Dictionary = expeditions.get("rocket", {})
	match String(rocket.get("state", "")):
		"preparing":
			rocket["prep_left"] = float(rocket["prep_left"]) - delta
			if float(rocket["prep_left"]) <= 0.0:
				rocket["state"] = "ready"
				expedition_changed.emit("rocket")
				save()
		"ready":
			if rocket_target_block(int(rocket.get("target_seed", -1))) == "":
				rocket["state"] = "in_transit"   # the target is locked at launch
				expedition_changed.emit("rocket")
				save()
		"in_transit":
			rocket["flight_left"] = float(rocket["flight_left"]) - delta
			if float(rocket["flight_left"]) <= 0.0:
				_rocket_arrived()

## The one arrival: Civilization 0 is complete (GDD §20.18–§20.19). Nothing is
## built or discovered at the target and Earth / Moon keep producing.
func _rocket_arrived() -> void:
	var rocket: Dictionary = expeditions.get("rocket", {})
	if rocket.get("state", "") == "arrived" or demo_completed:
		rocket["state"] = "arrived"
		return
	rocket["state"] = "arrived"
	rocket["flight_left"] = 0.0
	civilization_type = maxi(civilization_type, 1)
	demo_completed = true
	playable_content_type = 0
	expedition_changed.emit("rocket")
	civilization_reached.emit(1)
	save()

## The colony lander as a real ship in the moon's orbit (OrbitalLayer draws,
## spins and lands it). "aim_home" asks the planet view to park it facing the
## home world — used when no flight was drawn (older saves, cheats).
func spawn_moon_lander(planet_seed: int) -> ShipData:
	var ship := ShipManager.launch(planet_seed, "Colony Lander")
	_lander_orbit(ship)
	ship.set_meta("aim_home", true)
	return ship

## The lander leaves the home world now and flies `secs` to the moon (a ShipManager
## journey: the planet view draws it between the two bodies and hands it to
## the moon's orbit on arrival).
func launch_moon_lander(moon_seed: int, secs: float) -> ShipData:
	var ship := ShipManager.launch(home_planet_seed, "Colony Lander")
	_lander_orbit(ship)   # the orbit it will settle into at the moon
	ship.dest_seed = moon_seed
	ship.travel_duration = secs
	ship.travel_progress = 0.0
	return ship

func _lander_orbit(ship: ShipData) -> void:
	ship.ship_type = "lander"
	ship.orbit_radius = 1.35
	ship.orbit_speed = 0.08
	ship.orbit_inclination = randf_range(0.15, 0.45)

## A journey ended: a colony lander reaching its moon finishes the colonization.
func _on_ship_arrived(ship: ShipData) -> void:
	if ship.ship_type == "lander":
		var pp := get_planet(ship.orbit_seed)
		if pp.is_colonizing:
			finish_colonization(ship.orbit_seed)

## The moon's colony lander, if it is still in orbit.
func moon_lander(planet_seed: int) -> ShipData:
	for s: ShipData in ShipManager.ships_for(planet_seed):
		if s.ship_type == "lander":
			return s
	return null

## The lander touched down — the first lunar City is being built.
func mark_landed(planet_seed: int) -> void:
	get_planet(planet_seed).lander_state = 2
	planet_progress_changed.emit(planet_seed)

func complete_act1() -> void:
	if act1_complete:
		return
	act1_complete = true
	act1_completed.emit()
	save()

func finish_colonization(planet_seed: int) -> void:
	var pp := get_planet(planet_seed)
	if expedition_state("lander") == "in_transit" and int(expedition("lander").get("target_seed", -1)) == planet_seed:
		expeditions["lander"]["state"] = "arrived"
		expedition_changed.emit("lander")
		lander_reached_moon.emit.call_deferred(planet_seed)
	pp.is_colonizing = false
	pp.colonize_progress = 1.0
	pp.is_colonized = true
	
	var pd := get_planet_data(planet_seed)
	if pd != null and pd.planet_type == PlanetData.Type.MOON:
		pp.lander_state = 1   # parked in orbit; the player picks the landing site
		# first part: the lander turns into the Moon's Central Orbit (one
		# structure up there; the landing module undocks from it later)
		deploy_central_orbit(planet_seed)
		pd = null
	if pd != null:
		var has_poi := false
		for p in pd.custom_pois:
			if p.poi_type == POIData.POIType.CITY or p.poi_type == POIData.POIType.OUTPOST:
				has_poi = true
				break
		if not has_poi:
			var poi := POIData.new()
			poi.placement = 0 # LocationFinder.Placement.LAND
			if pd.planet_type == PlanetData.Type.MOON:
				poi.label = "Lunar Outpost"
				poi.display_name = "Lunar Outpost"
				poi.poi_type = POIData.POIType.OUTPOST
				poi.type_tag = "outpost"
			else:
				poi.label = "Colony"
				poi.display_name = "Colony"
				poi.poi_type = POIData.POIType.CITY
				poi.type_tag = "city"
			poi.light_intensity = 2.0
			pd.custom_pois.append(poi)

	planet_progress_changed.emit(planet_seed)

# ── Save / Load ───────────────────────────────────────────────────────────────
const SAVE_PATH := "user://voidle_save.dat"
## Bump when the save format or the economy changes so old saves can't be
## loaded into rules they weren't made for. Saves without a version are v1.
const SAVE_VERSION := 1
## Oldest save version this build can still load.
const MIN_SAVE_VERSION := 1
## True once the in-memory world is a loaded save or a started new game.
var _loaded_from_save: bool = false
## Version of a save on disk this build can't load (-1 = none). While set, the
## file is never overwritten; NEW GAME archives it instead of deleting it.
var incompatible_save_version: int = -1

func save() -> void:
	if demo_build or incompatible_save_version >= 0:   # exploring changes nothing: saving is safe
		return
	var data := {
		"save_version":         SAVE_VERSION,
		"saved_at":             Time.get_unix_time_from_system(),
		"play_seconds":         play_seconds,
		"moon_city_celebrated": moon_city_celebrated,
		"world_gen":            world_gen,
		"scanned_bodies":       scanned_bodies,
		"landing_paid":         landing_paid,
		"balance_profile":      Balance.profile_name,
		"credits":              credits,
		"science_points":       science_points,
		"solar_unlocked":       solar_unlocked,
		"moon_unlocked":        moon_unlocked,
		"act1_complete":        act1_complete,
		"demo_completed":       demo_completed,
		"playable_content_type": playable_content_type,
		"expeditions":          expeditions,
		"galaxy_unlocked":      galaxy_unlocked,
		"discovered_asteroids": discovered_asteroids,
		"asteroid_scan_counts": asteroid_scan_counts,
		"home_planet_seed":     home_planet_seed,
		"home_star_idx":        home_star_idx,
		"home_planet_idx":      home_planet_idx,
		"research":             get_node("/root/SkillTree").get_save_data() if has_node("/root/SkillTree") else {},
		"moon_local_moonstone": moon_local_moonstone,
		"trade": {"reserves": trade_reserves, "orders": trade_orders, "log": trade_log,
			"seq": trade_seq, "overflow_sold": overflow_sold},
		"ships":                get_node("/root/ShipManager").serialize() if has_node("/root/ShipManager") else [],
		"planet_progress":      {},
	}
	for seed_val in _planet_progress:
		var pp: PlanetProgress = _planet_progress[seed_val]
		var pd_save: PlanetData = get_planet_data(seed_val)
		var pois_save: Array = []
		if pd_save != null:
			for poi: POIData in pd_save.custom_pois:
				pois_save.append({
					"label":              poi.label,
					"display_name":       poi.display_name,
					"neighbors":          poi.neighbors,
					"neighbor_weight":    poi.neighbor_weight,
					"poi_type":           int(poi.poi_type),
					"type_tag":           poi.type_tag,
					"light_intensity":    poi.light_intensity,
					"level":              poi.level,
					"placement":          int(poi.placement),
					"manual_position":    poi.manual_position,
					"lon_deg":            poi.lon_deg,
					"lat_deg":            poi.lat_deg,
					"terrain":            poi.terrain,
					"coastal":            poi.coastal,
					"parent_city":        poi.parent_city,
					"resource_tags":      poi.resource_tags,
					"site_features":      poi.site_features,
					"paid_credits":       poi.paid_credits,
					"spoke_birth":        poi.spoke_birth,
					"constructing":       poi.constructing,
					"construct_progress": poi.construct_progress,
					"construct_duration": poi.construct_duration,
					"orbit_angle":        poi.orbit_angle,
					"orbit_speed":        poi.orbit_speed,
					"orbit_inclination":  poi.orbit_inclination,
					"orbit_node":         poi.orbit_node,
					"orbit_radius":       poi.orbit_radius,
				})
		data["planet_progress"][str(seed_val)] = {
			"level":             pp.level,
			"is_upgrading":      pp.is_upgrading,
			"upgrade_progress":  pp.upgrade_progress,
			"upgrade_duration":  pp.upgrade_duration,
			"is_colonizing":     pp.is_colonizing,
			"colonize_progress": pp.colonize_progress,
			"colonize_duration": pp.colonize_duration,
			"is_colonized":      pp.is_colonized,
			"districts_used":    pp.districts_used,
			"district_levels":   pp.district_levels,
			"level_paid":        pp.level_paid,
			"city_levels":       pp.city_levels,
			"city_upgrading":    pp.city_upgrading,
			"district_upgrading": pp.district_upgrading,
			"buildings":         pp.buildings,
			"stored_resources":  pp.stored_resources,
			"has_spaceport":     pp.has_spaceport,
			"moons_unlocked":    pp.moons_unlocked,
			"lander_state":      pp.lander_state,
			"orbit_level":       pp.orbit_level,
			"custom_pois":       pois_save,
		}
	data["global_resources"]    = global_resources
	data["unlocked_buildings"]  = unlocked_buildings
	data["revealed_resources"]  = revealed_resources
	data["civilization_type"]   = civilization_type
	data["surveyed_bodies"]     = surveyed_bodies
	data["discovered_minerals"] = discovered_minerals
	data["planet_view_unlocked"] = planet_view_unlocked
	data["light_angle"]         = light_angle
	data["production"]          = ProductionManager.get_save_data()
	data["achievements"]        = AchievementManager.get_save_data()
	data["tutorial_done"]        = TutorialManager._tutorial_done
	data["tutorial_quest_done"]  = TutorialManager._quest_done
	data["tutorial_guided_step"] = TutorialManager._guided_step
	data["tutorial_action_sub"]  = TutorialManager._action_sub
	data["tutorial_quest_step"]  = TutorialManager._quest_step
	data["objectives_collapsed"] = TutorialManager._collapsed
	data["tutorial_quest_sub"]   = TutorialManager._quest_sub
	data["tutorial_solar_count"] = TutorialManager._solar_count
	data["tutorial_inv_shown"]   = TutorialManager._inventory_shown
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)

func load_save() -> bool:
	if demo_build:
		return false
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var raw = file.get_var()
	if not raw is Dictionary:
		incompatible_save_version = 0
		push_warning("[GameState] Save file is unreadable — kept, not loaded.")
		return false
	var data: Dictionary = raw
	var version := int(data.get("save_version", 1))
	if version < MIN_SAVE_VERSION or version > SAVE_VERSION:
		incompatible_save_version = version
		push_warning("[GameState] Save v%d can't be loaded by this build (v%d) — kept, not loaded." % [version, SAVE_VERSION])
		return false
	incompatible_save_version = -1
	# play on with the balance profile the save was made with
	var profile := String(data.get("balance_profile", ""))
	if profile != "" and profile != Balance.profile_name and not Balance.load_profile(profile):
		push_warning("[GameState] Save's balance profile '%s' not found — using '%s'." % [profile, Balance.profile_name])
	_loaded_from_save = true
	play_seconds = float(data.get("play_seconds", 0.0))
	moon_city_celebrated = bool(data.get("moon_city_celebrated", false))
	world_gen = int(data.get("world_gen", 1))
	scanned_bodies = data.get("scanned_bodies", {})
	landing_paid = data.get("landing_paid", {})
	# time away (KARARLAR §4): only measured and shown — no offline economy yet.
	# A clock that went backwards counts as no time away (GDD §19.27).
	var saved_at := float(data.get("saved_at", 0.0))
	if not _offline_measured:
		_offline_measured = true
		offline_seconds = maxf(Time.get_unix_time_from_system() - saved_at, 0.0) if saved_at > 0.0 else 0.0
		offline_pending = offline_seconds >= OFFLINE_MIN_SECONDS
	ProductionManager.load_save_data(data.get("production", {}))
	credits                  = data.get("credits",              500.0)
	science_points           = data.get("science_points",       0.0)
	solar_unlocked           = data.get("solar_unlocked",       false)
	moon_unlocked            = data.get("moon_unlocked",        false)
	act1_complete            = data.get("act1_complete",        false)
	demo_completed           = bool(data.get("demo_completed", false))
	playable_content_type    = int(data.get("playable_content_type", 0))
	expeditions              = data.get("expeditions", {})
	if expedition_state("lander") == "launching":
		expeditions["lander"]["animating"] = false   # a lift-off on screen doesn't survive a reload
	galaxy_unlocked          = data.get("galaxy_unlocked",      false)
	home_planet_seed         = data.get("home_planet_seed",     -1)
	home_star_idx            = data.get("home_star_idx",        -1)
	home_planet_idx          = data.get("home_planet_idx",      -1)
	discovered_asteroids     = data.get("discovered_asteroids", [])
	asteroid_scan_counts     = data.get("asteroid_scan_counts", {})
	
	# research: current saves keep it under "research"; older ones (Act I ids)
	# stored the two lists at the top level — SkillTree converts those ids
	var research: Dictionary = data.get("research", {})
	if research.is_empty():
		research = {"unlocked_skills": data.get("unlocked_skills", []), "skill_levels": data.get("skill_levels", {})}
	get_node("/root/SkillTree").load_save_data(research)
	moon_local_moonstone = float(data.get("moon_local_moonstone", 0.0))
	var trade: Dictionary = data.get("trade", {})
	trade_reserves = trade.get("reserves", {})
	trade_orders = trade.get("orders", {})
	trade_log = trade.get("log", [])
	trade_seq = int(trade.get("seq", 0))
	overflow_sold = trade.get("overflow_sold", {})

	global_resources    = data.get("global_resources",   {})
	global_resources.erase(Economy.ENERGY)   # energy is a flow; older saves stored it
	unlocked_buildings  = data.get("unlocked_buildings", {})
	revealed_resources  = data.get("revealed_resources", [])
	civilization_type   = int(data.get("civilization_type", 0))
	surveyed_bodies     = data.get("surveyed_bodies", {})
	discovered_minerals = data.get("discovered_minerals", {})
	planet_view_unlocked = data.get("planet_view_unlocked", false)
	light_angle         = data.get("light_angle",        0.8)

	if data.has("achievements"):
		AchievementManager.load_save(data["achievements"])

	TutorialManager._tutorial_done    = data.get("tutorial_done",        false)
	TutorialManager._quest_done       = data.get("tutorial_quest_done",  false)
	TutorialManager._guided_step      = data.get("tutorial_guided_step", 0)
	TutorialManager._action_sub       = data.get("tutorial_action_sub",  0)
	TutorialManager._quest_step       = data.get("tutorial_quest_step",  0)
	TutorialManager._collapsed        = bool(data.get("objectives_collapsed", false))
	TutorialManager._quest_sub        = data.get("tutorial_quest_sub",   0)
	TutorialManager._solar_count      = data.get("tutorial_solar_count", 0)
	TutorialManager._inventory_shown  = data.get("tutorial_inv_shown",   false)

	if has_node("/root/ShipManager"):
		get_node("/root/ShipManager").deserialize(data.get("ships", []))

	for key in data.get("planet_progress", {}).keys():
		var seed_val: int    = int(key)
		var d: Dictionary    = data["planet_progress"][key]
		var pp               := PlanetProgress.make(seed_val)
		pp.level             = d.get("level",            1)
		pp.is_upgrading      = d.get("is_upgrading",     false)
		pp.upgrade_progress  = d.get("upgrade_progress", 0.0)
		pp.upgrade_duration  = d.get("upgrade_duration", 60.0)
		pp.is_colonizing     = d.get("is_colonizing",    false)
		pp.colonize_progress = d.get("colonize_progress", 0.0)
		pp.colonize_duration = d.get("colonize_duration", 30.0)
		pp.is_colonized      = d.get("is_colonized",     false)
		pp.districts_used    = d.get("districts_used",   0)
		pp.district_levels   = d.get("district_levels",  {})
		pp.level_paid        = d.get("level_paid",       {})
		pp.city_levels       = d.get("city_levels",      {})
		pp.city_upgrading    = d.get("city_upgrading",   {})
		pp.buildings          = d.get("buildings",          [])
		pp.consolidate_buildings()
		pp.district_upgrading = d.get("district_upgrading", {})
		pp.has_spaceport      = d.get("has_spaceport",      false)
		pp.moons_unlocked     = d.get("moons_unlocked",     false)
		pp.lander_state       = d.get("lander_state",       0)
		pp.orbit_level        = d.get("orbit_level",        0)
		pp.recalculate_limits()
		_planet_progress[seed_val] = pp
		# Store POI data for later — applied in _apply_pending_pois() after _bootstrap_world
		if d.has("custom_pois"):
			_pending_poi_restore[seed_val] = d["custom_pois"]
	return true

## Why CONTINUE can't load the save on disk ("" when it can, or there's none).
func save_block_reason() -> String:
	if incompatible_save_version == 0:
		return "The save file can't be read."
	if incompatible_save_version > SAVE_VERSION:
		return "This save is from a newer version of Voidle (v%d)." % incompatible_save_version
	if incompatible_save_version >= 0:
		return "This save is from an older version (v%d) and can't be continued. NEW GAME keeps it as a backup." % incompatible_save_version
	return ""

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		if incompatible_save_version >= 0:
			# never destroy a save this build couldn't read — set it aside
			var backup := "user://voidle_save_v%d_%d.dat" % [incompatible_save_version, int(Time.get_unix_time_from_system())]
			DirAccess.rename_absolute(SAVE_PATH, backup)
		else:
			DirAccess.remove_absolute(SAVE_PATH)
	incompatible_save_version = -1
	_loaded_from_save = false   # what follows is a brand-new world
	exit_showcase()
	play_seconds = 0.0
	moon_city_celebrated = false
	save_deleted.emit()
	credits              = Balance.cfg.start_credits
	science_points       = Balance.cfg.start_science
	solar_unlocked       = false
	moon_unlocked        = false
	act1_complete        = false
	demo_completed       = false
	playable_content_type = 0
	world_gen            = WORLD_GEN
	scanned_bodies       = {}
	landing_paid         = {}
	offline_pending      = false   # a new world has no time away
	_offline_measured    = true
	expeditions          = {}
	galaxy_unlocked      = false
	discovered_asteroids = []
	asteroid_scan_counts = {}
	home_planet_seed     = randi_range(1000, 99999)
	home_star_idx        = -1
	home_planet_idx      = -1
	_home_solar          = null
	home_galaxy          = null
	get_node("/root/SkillTree").reset_to_defaults()
	moon_local_moonstone = 0.0
	trade_reserves.clear()
	trade_orders.clear()
	trade_log.clear()
	trade_seq = 0
	overflow_sold.clear()
	unlocked_buildings.clear()
	revealed_resources.clear()
	civilization_type = 0
	surveyed_bodies.clear()
	discovered_minerals.clear()
	planet_view_unlocked = false
	global_resources.clear()
	_planet_progress.clear()
	_bootstrap_world()
