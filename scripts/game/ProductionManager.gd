## ProductionManager — autoload singleton.
## Ticks every building on every colonized planet each _process frame.
extends Node

signal building_ticked(planet_seed: int, key: String)
signal building_progress_changed(planet_seed: int, key: String, progress: float)
signal resource_produced(planet_seed: int, poi_label: String, text: String, color: Color, icon: Texture2D)
signal building_constructed(planet_seed: int, key: String, building_id: String)
signal building_toggled(key: String, paused: bool)
signal building_queued(planet_seed: int, building_id: String)

## { pm_key -> float 0.0-1.0 }
var _progress:    Dictionary = {}
## { pm_key -> bool } true = auto-paused (resource/energy shortage)
var _paused:      Dictionary = {}
## { pm_key -> bool } true = user manually toggled off
var _user_paused: Dictionary = {}
## global energy balance (sum across all colonies, updated each frame)
var _global_energy:       float = 0.0
## global energy made / used (⚡), updated each frame
var _global_energy_prod:   float = 0.0
var _global_energy_demand: float = 0.0
## global energy throttle ratio (0.0-1.0)
var _global_energy_ratio: float = 1.0
## Largest slowdown an energy deficit causes (0.5 = consumers at 50% speed at worst).
## { pm_key -> true } building waiting because every output's storage is full
var _storage_full: Dictionary = {}
## { planet_seed -> work speed from population } (Economy.pop_speed), per frame
var _pop_speed: Dictionary = {}
## { "seed:district_label" -> float 0.0-1.0 } district base-income cycles
var _base_progress: Dictionary = {}
## { "construct:pm_key" -> float 0.0-1.0 }
var _construct:     Dictionary = {}

## Set by a load with no saved cycle progress (older saves): the first tick
## gives every cycle a random head start so the bars don't all fill in step.
var _randomize_missing := false
var _randomize_tries := 0

func _process(delta: float) -> void:
	_calc_global_energy()
	if _randomize_missing:
		_randomize_tries += 1
		_randomize_missing = not _randomize_cycles() and _randomize_tries < 600   # retry until planets load
	_tick_all(delta)
	_tick_idle_income(delta)
	GameState.tick_expeditions(delta)
	Trade.tick_prices(delta)

# ── Save / load ───────────────────────────────────────────────────────────────

## Cycle and construction progress, so bars resume where they were.
func get_save_data() -> Dictionary:
	return {
		"progress":    _progress.duplicate(),
		"base":        _base_progress.duplicate(),
		"construct":   _construct.duplicate(),
		"user_paused": _user_paused.duplicate(),
	}

func load_save_data(d: Dictionary) -> void:
	_progress.clear(); _base_progress.clear(); _construct.clear(); _user_paused.clear()
	if d.is_empty():
		_randomize_missing = true
		_randomize_tries = 0
		return
	_progress.merge(d.get("progress", {}))
	_base_progress.merge(d.get("base", {}))
	_construct.merge(d.get("construct", {}))
	_user_paused.merge(d.get("user_paused", {}))

func _randomize_cycles() -> bool:
	var all_ready := true
	for pp: PlanetProgress in _all_colonies():
		for entry: Dictionary in pp.buildings:
			if entry.get("constructing", false) or not entry.has("uid"):
				continue
			var key := _key(pp.planet_seed, entry.get("district_id", ""), entry["uid"])
			if not _progress.has(key):
				_progress[key] = randf() * 0.9
		var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
		if pd == null or pd.custom_pois.is_empty():
			all_ready = false
			continue
		for poi: POIData in pd.custom_pois:
			var k := "%d:%s" % [pp.planet_seed, poi.label]
			if not _base_progress.has(k):
				_base_progress[k] = randf() * 0.9
	return all_ready

func get_progress(key: String) -> float:
	return _progress.get(key, 0.0)

func is_paused(key: String) -> bool:
	return _paused.get(key, false)

## True while a building waits because its outputs' storage is full.
func is_storage_full(key: String) -> bool:
	return _storage_full.get(key, false)

func get_construct_progress(key: String) -> float:
	return _construct.get("construct:" + key, 0.0)

func is_constructing(key: String) -> bool:
	return _construct.has("construct:" + key)

func toggle_user_pause(key: String) -> void:
	_user_paused[key] = not _user_paused.get(key, false)
	_calc_global_energy()
	building_toggled.emit(key, _user_paused[key])

func is_user_paused(key: String) -> bool:
	return _user_paused.get(key, false)

## A City finished levelling up (`unlocked_planet_view`: that opened the planet view).
signal city_leveled(planet_seed: int, city_label: String, level: int, unlocked_planet_view: bool)

## Returns 0.0–1.0: global energy coverage ratio. < 1.0 = energy crisis.
func get_energy_ratio(_planet_seed: int = 0) -> float:
	return _global_energy_ratio

## Returns the global net energy balance (positive = surplus, negative = deficit).
func get_global_energy() -> float:
	return _global_energy

## (made, used) energy across all colonies — the parts of get_global_energy.
func get_global_energy_split() -> Vector2:
	return Vector2(_global_energy_prod, _global_energy_demand)

## Called by PlanetaryView after building is placed so UI can refresh immediately.
func invalidate(planet_seed: int) -> void:
	building_ticked.emit(planet_seed, "")

# ── Internal ──────────────────────────────────────────────────────────────────

func _tick_all(delta: float) -> void:
	for pp: PlanetProgress in GameState._planet_progress.values():
		if pp.is_colonizing:
			# a lander in flight sets the pace; it finishes the job on arrival
			var lander: ShipData = ShipManager.travelling_to(pp.planet_seed, "lander")
			if lander != null:
				pp.colonize_progress = lander.travel_progress
				building_progress_changed.emit(pp.planet_seed, "colonize", pp.colonize_progress)
				continue
			pp.colonize_progress += delta / max(0.1, pp.colonize_duration)
			if pp.colonize_progress >= 1.0:
				GameState.finish_colonization(pp.planet_seed)
			else:
				building_progress_changed.emit(pp.planet_seed, "colonize", pp.colonize_progress)

	for pp: PlanetProgress in _all_colonies():
		var planet_seed: int = pp.planet_seed
		var pd: PlanetData = GameState.get_planet_data(planet_seed)
		if pd:
			var district_changed := false
			
			if pp.is_upgrading:
				pp.upgrade_progress += delta / max(0.1, pp.upgrade_duration)
				if pp.upgrade_progress >= 1.0:
					pp.is_upgrading = false
					pp.upgrade_progress = 0.0
					pp.upgrade_paid = {}
					pp.level += 1
					pp.recalculate_limits()
					PlanetTags.on_planet_level(GameState.get_planet_data(planet_seed), pp.level)
					NewsFeed.post_planet_level(planet_seed, pp.level)
					GameState.planet_progress_changed.emit(planet_seed)

			# City level-ups
			for clabel in pp.city_upgrading.keys():
				var c_next: int = int(pp.city_levels.get(clabel, 1)) + 1
				pp.city_upgrading[clabel] += delta / max(0.1, PlanetProgress.city_upgrade_duration(c_next))
				if pp.city_upgrading[clabel] >= 1.0:
					pp.city_upgrading.erase(clabel)
					pp.city_levels[clabel] = c_next
					var opened := not GameState.planet_view_unlocked and c_next >= 2
					if opened:
						GameState.planet_view_unlocked = true
					GameState.planet_progress_changed.emit(planet_seed)
					city_leveled.emit(planet_seed, clabel, c_next, opened)
					break  # dict modified — next frame handles the rest

			# Orbit level-up (as long as a City's)
			if pp.orbit_upgrading >= 0.0:
				pp.orbit_upgrading += delta / max(0.1, PlanetProgress.city_upgrade_duration(pp.orbit_level + 1))
				if pp.orbit_upgrading >= 1.0:
					pp.orbit_upgrading = -1.0
					pp.orbit_level += 1
					pp.recalculate_limits()
					GameState.planet_progress_changed.emit(planet_seed)

			# District upgrades (independent of planet upgrade state)
			for dlabel in pp.district_upgrading.keys():
				var target_lv: int = pp.district_levels.get(dlabel, 1) + 1
				var dur: float = PlanetProgress.district_upgrade_duration(target_lv)
				pp.district_upgrading[dlabel] += delta / max(0.1, dur)
				if pp.district_upgrading[dlabel] >= 1.0:
					pp.district_upgrading.erase(dlabel)
					pp.district_levels[dlabel] = target_lv
					GameState.planet_progress_changed.emit(planet_seed)
					break  # dict modified — next frame handles remaining

			var build_speed := district_build_speed()
			for poi in pd.custom_pois:
				if poi.constructing:
					# Orbit districts too: their rocket animation follows this progress
					# (PlanetaryView), so a faster build is a faster flight
					poi.construct_progress += delta * build_speed / max(0.1, poi.construct_duration)
					if poi.construct_progress >= 1.0:
						poi.constructing = false
						poi.construct_progress = 1.0
						district_changed = true
						# a finished Mining district surveys the body's minerals
						var built_def := district_def(poi)
						if built_def != null and built_def.id == DistrictDef.Type.MINING:
							GameState.discover_body_minerals(planet_seed)
					building_progress_changed.emit(planet_seed, poi.label, poi.construct_progress)
			if district_changed:
				GameState.planet_progress_changed.emit(planet_seed)

		var energy_ratio: float = _global_energy_ratio
		# population pressure changes slowly — refresh it twice a second
		var ps_key := "t%d" % planet_seed
		if pd != null and Time.get_ticks_msec() - int(_pop_speed.get(ps_key, -100000)) > 500:
			_pop_speed[planet_seed] = Economy.pop_speed(pd, pp)
			_pop_speed[ps_key] = Time.get_ticks_msec()
		var st := get_node("/root/SkillTree")

		# Collect entries to merge/remove after iteration (avoid modifying array mid-loop)
		var pending_merges: Array[Dictionary] = []
		var completed_buildings: Array[Dictionary] = []

		# Iterate with explicit index so identical-content entries get unique keys
		for i in pp.buildings.size():
			var entry: Dictionary = pp.buildings[i]
			var poi_label: String  = entry.get("district_id", "")
			var bid: String        = entry.get("building_id", "")
			var amount: int        = entry.get("amount", 1)
			if not entry.has("uid"):
				entry["uid"] = str(randi())
			var key: String        = _key(planet_seed, poi_label, entry["uid"])
			var def := BuildingDef.find(bid)
			if def == null:
				continue

			# ── Construction phase ────────────────────────────────────────────
			# (runs before the zero-tick skip — passive buildings still get built)
			if entry.get("constructing", false):
				var ck: String = "construct:" + key
				var cdur: float = def.construct_duration if def.construct_duration > 0.0 else maxf(def.tick_duration, 1.0)
				var cp: float  = _construct.get(ck, 0.0) + delta / cdur
				if cp >= 1.0:
					_construct.erase(ck)
					entry["constructing"] = false
					pending_merges.append(entry)
					# Spaceport starts paused after construction — player launches manually
					if def.building_id == "spaceport":
						_user_paused[key] = true
					completed_buildings.append({ "key": key, "bid": bid })
					building_ticked.emit(planet_seed, key)
				else:
					_construct[ck] = cp
					building_progress_changed.emit(planet_seed, key, cp)
				continue

			if def.tick_duration <= 0.0:
				continue   # passive building — no production cycle
			# housing / energy only, nothing to pay: standing amounts, no cycle
			# to run (its bar stays empty — playtest 31.10)
			if def.inputs.is_empty() and not _has_stock(def) and def.logic == null:
				if _progress.has(key):   # an older save's half-filled bar
					_progress.erase(key)
					_emit_progress(planet_seed, key)
				continue

			# ── User-toggled off ──────────────────────────────────────────────
			if _user_paused.get(key, false):
				continue

			# ── Start of cycle: room to store the output, then pay the upkeep ──
			var prev: float = _progress.get(key, 0.0)
			if prev <= 0.0:
				var full := _outputs_full(pp, def)
				if full != _storage_full.get(key, false):
					_storage_full[key] = full
					building_ticked.emit(planet_seed, key)
				if full:
					_emit_progress(planet_seed, key)
					continue   # storage full — wait instead of wasting inputs
				if not _pay_inputs(def, amount, entry):
					if not _paused.get(key, false):
						_paused[key] = true
						building_ticked.emit(planet_seed, key)
					_emit_progress(planet_seed, key)
					continue   # can't start — wait for resources
				if _paused.get(key, false):
					_paused[key] = false
					building_ticked.emit(planet_seed, key)

			# ── No power at all: wait ─────────────────────────────────────────
			# (a partial deficit doesn't slow the cycle — it lowers what the
			# cycle makes; see output_efficiency)
			if def.energy_per_tick < 0.0 and energy_ratio <= 0.0:
				_emit_progress(planet_seed, key)   # inputs already paid; waits for power
				continue

			# ── Tick production bar ───────────────────────────────────────────
			var speed_mult: float = st.get_global_speed_mult()
			if def.outputs.has(Economy.RAW):
				speed_mult *= st.get_mine_speed_mult()
			var rate: float = delta / (def.tick_duration / maxf(speed_mult, 0.0001))
			var next: float = prev + rate

			if next >= 1.0:
				_on_tick_complete(pp, def, key, amount, entry)
				_progress[key] = 0.0
				# Spaceport: re-pause after each launch cycle so player must trigger manually
				if def.building_id == "spaceport":
					_user_paused[key] = true
				building_ticked.emit(planet_seed, key)
			else:
				_progress[key] = next

			_emit_progress(planet_seed, key)

		# Apply stacked-build merges now that iteration is complete
		# (by content, not index: a sibling still under construction gets its
		# own entry, so identical buildings always end up in one stack)
		for entry: Dictionary in pending_merges:
			entry.erase("merge_into")
			pp.merge_identical(entry)

		for c in completed_buildings:
			var c_def := BuildingDef.find(String(c.bid))
			if c_def != null and c_def.outputs.has(Economy.RAW):
				GameState.discover_body_minerals(planet_seed)   # first mine surveys the body
			building_constructed.emit(planet_seed, c.key, c.bid)

		if pd:
			_tick_district_base(pp, pd, delta)

## How fast districts are built (1 = their construction_duration). The one
## place a construction speed-up (research, rush …) hooks in: surface districts
## and Orbit districts — and with them the Orbit rocket animation — follow it.
## Seconds one production cycle of `def` takes now (research shortens it,
## mines also by the mining speed) — the number every card and tip shows.
func building_cycle_sec(def: BuildingDef) -> float:
	var st = get_node("/root/SkillTree")
	var m: float = st.get_global_speed_mult()
	if def.outputs.has(Economy.RAW):
		m *= st.get_mine_speed_mult()
	return def.tick_duration / maxf(m, 0.0001)

## Seconds one base-income cycle of a district takes now.
func district_cycle_sec(ddef: DistrictDef) -> float:
	return ddef.base_tick / maxf(float(get_node("/root/SkillTree").get_global_speed_mult()), 0.0001)

## How a cycle is written everywhere (playtest 31.10: amounts are per cycle,
## the cycle stands once beside them): "20s", "7.5s", "1m 05s".
static func cycle_text(sec: float) -> String:
	if sec >= 60.0:
		return "%dm %02ds" % [int(sec) / 60, int(round(sec)) % 60]
	if sec < 10.0 and absf(sec - roundf(sec)) > 0.05:
		return "%.1fs" % sec
	return "%ds" % roundi(sec)

func district_build_speed() -> float:
	return Relics.build_speed()

## Every finished surface district makes its base income (DistrictDef.base_outputs)
## on its own cycle. Energy and population are flows / capacity, handled in
## _planet_energy and Economy.max_population instead.
func _tick_district_base(pp: PlanetProgress, pd: PlanetData, delta: float) -> void:
	var speed: float = get_node("/root/SkillTree").get_global_speed_mult()
	var eff: float = planet_pop_speed(pp.planet_seed)   # overpopulation lowers output, not speed
	for poi: POIData in pd.custom_pois:
		if not makes_base(pd, poi):
			continue
		var ddef := district_def(poi)
		if ddef == null or ddef.base_tick <= 0.0:
			continue
		var income := district_income(pp, poi)
		if not _has_stock_income(income):
			continue
		var k := "%d:%s" % [pp.planet_seed, poi.label]
		var p: float = _base_progress.get(k, 0.0) + delta * speed / ddef.base_tick
		if p < 1.0:
			_base_progress[k] = p
			continue
		_base_progress[k] = 0.0
		for id: String in income:
			if id == Economy.ENERGY or id == Economy.POPULATION:
				continue
			var v: float = float(income[id]) * eff
			if id == Economy.RAW:
				# the Capital's / Orbit City's share waits for the first Production
				# district or mine to survey the body (no early discovery)
				if ddef.id == DistrictDef.Type.MINING or GameState.is_body_surveyed(pp.planet_seed):
					_produce_raw(pp, poi.label, v)
				continue
			Economy.add(id, v)
			if v > 0.0:   # the amount by its resource icon (playtest 31.10), no "cr"
				resource_produced.emit(pp.planet_seed, poi.label,
					("+%.1f" if v < 10.0 else "+%.0f") % v, Economy.color_of(id), UIIcons.get_icon(id))

## Output efficiency from population on a planet (1 = housed; < 1 = overpopulated).
## Cycles keep their length; a finished cycle makes this share of its output.
func planet_pop_speed(planet_seed: int) -> float:
	return float(_pop_speed.get(planet_seed, 1.0))

## Share of its output a building's finished cycle makes: overpopulation on its
## planet and — for consumers — an energy deficit both lower it (multiplied),
## down to Balance.cfg's floors. Inputs are always paid in full.
func output_efficiency(pp: PlanetProgress, def: BuildingDef) -> float:
	var e: float = planet_pop_speed(pp.planet_seed)
	if def.energy_per_tick < 0.0:
		e *= _global_energy_ratio
	return e

## 0..1 progress of a district's base-income cycle.
func base_progress(planet_seed: int, district_label: String) -> float:
	return _base_progress.get("%d:%s" % [planet_seed, district_label], 0.0)

static func _has_stock_income(income: Dictionary) -> bool:
	for id: String in income:
		if id != Economy.ENERGY and id != Economy.POPULATION and float(income[id]) > 0.0:
			return true
	return false

## True when a model makes something stored per cycle (not only housing / energy).
static func _has_stock(def: BuildingDef) -> bool:
	for id: String in def.outputs:
		if id != Economy.ENERGY and id != Economy.POPULATION:
			return true
	return false

## The district type a POI was founded as.
static func district_def(poi: POIData) -> DistrictDef:
	return DistrictDef.find_by_key(poi.type_tag) if poi != null else null

## True when a finished POI makes its own base income: every surface district
## and the Orbit City (Orbit support districts make none of their own, §6.2).
static func makes_base(pd: PlanetData, poi: POIData) -> bool:
	if poi == null or poi.constructing:
		return false
	return not poi.is_orbital() or Leveling.is_orbit_city(pd, poi)

## Per-planet lookups rebuilt when the district list changes: label -> POI and
## City label -> its districts.
static var _poi_index: Dictionary = {}   # seed -> { "n": count, "by_label": {}, "children": {} }

static func _index(pd: PlanetData) -> Dictionary:
	var ix: Dictionary = _poi_index.get(pd.seed, {})
	if ix.is_empty() or int(ix["n"]) != pd.custom_pois.size():
		var by_label := {}
		var children := {}
		for p: POIData in pd.custom_pois:
			by_label[p.label] = p
			if p.parent_city != "":
				if not children.has(p.parent_city):
					children[p.parent_city] = []
				children[p.parent_city].append(p)
		ix = {"n": pd.custom_pois.size(), "by_label": by_label, "children": children}
		_poi_index[pd.seed] = ix
	return ix

## Unscaled base income: { id: base × terrain × location } (before level, City
## bonuses and skills). Terrain = the visible features at the site (and its
## City's), by output family (FeatureMap); location = proximity + centres +
## distance bonus, by real km — no roads (Location.gd).
static func district_income_raw(pd: PlanetData, poi: POIData) -> Dictionary:
	var out := {}
	var ddef := district_def(poi)
	if ddef == null:
		return out
	var loc := 1.0 if poi.is_orbital() else Location.mult(pd, poi)
	for id: String in ddef.base_outputs:
		out[id] = float(ddef.base_outputs[id]) * Economy.site_mult(FeatureMap.terrain_mult(pd, poi, id), loc)
	return out

## A district's base income per its cycle (per second for energy, capacity for
## population): (base × site + neighbours) × level × planet bonus × skills.
## District incomes change slowly (buildings, levels, neighbours) but are read
## every frame by the energy grid, population and the HUD: cache them, refreshed
## every INCOME_CACHE_MS and whenever a planet changes.
const INCOME_CACHE_MS := 500
var _income_cache: Dictionary = {}   # "seed:label" -> [time_ms, income]

func _invalidate_income(_seed: int = 0) -> void:
	_income_cache.clear()

func district_income(pp: PlanetProgress, poi: POIData) -> Dictionary:
	if not makes_base(GameState.get_planet_data(pp.planet_seed), poi):
		return {}
	var ck := "%d:%s" % [pp.planet_seed, poi.label]
	var now := Time.get_ticks_msec()
	if _income_cache.has(ck) and now - int(_income_cache[ck][0]) < INCOME_CACHE_MS:
		return _income_cache[ck][1]
	if not GameState.planet_progress_changed.is_connected(_invalidate_income):
		GameState.planet_progress_changed.connect(_invalidate_income)
	var inc := _district_income_now(pp, poi)
	_income_cache[ck] = [now, inc]
	return inc

func _district_income_now(pp: PlanetProgress, poi: POIData) -> Dictionary:
	var raw := district_income_raw(GameState.get_planet_data(pp.planet_seed), poi)
	var lv_m := DistrictDef.level_mult(pp.district_levels.get(poi.label, 1))
	for id: String in raw:
		raw[id] = _skill_mods(pp, id, float(raw[id]) * lv_m * Economy.scope_bonus(pp, poi.label, id), "")
	return raw

## What a district or building shows as its own output (§7.2): the real value
## without the City / planet supports, which the City and planet totals show
## on their own lines instead (City panel, Orbit panel).
func district_income_shown(pp: PlanetProgress, poi: POIData) -> Dictionary:
	var out := district_income(pp, poi).duplicate()
	for id: String in out:
		out[id] = float(out[id]) / maxf(Economy.scope_bonus(pp, poi.label, id), 0.0001)
	return out

func output_before_support(pp: PlanetProgress, entry: Dictionary, def: BuildingDef, id: String) -> float:
	return output_per_cycle(pp, entry, def, id) \
		/ maxf(Economy.scope_bonus(pp, entry.get("district_id", ""), id), 0.0001)

## A City's contributions before and after its supports: { resource_id:
## [before, city multiplier] } per cycle (energy per second, housing as
## capacity) — districts' base and every building, the City's free housing included.
func city_support_breakdown(pp: PlanetProgress, pd: PlanetData, city: POIData) -> Dictionary:
	var before := {}
	var members: Array[String] = []
	for p: POIData in pd.custom_pois:
		if p == city or (p.parent_city == city.label and not p.is_orbital()):
			members.append(p.label)
			var inc := district_income_shown(pp, p)
			for id: String in inc:
				before[id] = float(before.get(id, 0.0)) + float(inc[id])
	if not city.constructing:
		before[Economy.POPULATION] = float(before.get(Economy.POPULATION, 0.0)) + float(Balance.cfg.city_base_pop)
	for b: Dictionary in pp.buildings:
		if b.get("constructing", false) or not String(b.get("district_id", "")) in members:
			continue
		var def := BuildingDef.find(b.get("building_id", ""))
		if def == null:
			continue
		for id: String in def.outputs:
			before[id] = float(before.get(id, 0.0)) + output_before_support(pp, b, def, id)
	var out := {}
	for id: String in before:
		out[id] = [float(before[id]), Economy.city_support(pp, city.label, id, pd)]
	return out

func district_base(pp: PlanetProgress, poi: POIData, id: String) -> float:
	return float(district_income(pp, poi).get(id, 0.0))

## True when the building makes stored resources and every one of them is at
## its cap (mines: every raw resource of the planet). Flow / capacity outputs
## (energy, population) never fill up here.
func _outputs_full(pp: PlanetProgress, def: BuildingDef) -> bool:
	var any := false
	for id: String in def.outputs:
		if id == Economy.ENERGY or id == Economy.POPULATION:
			continue
		any = true
		if id == Economy.RAW:
			var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
			if pd == null:
				return false
			for r: Dictionary in Economy.raw_for_body(pd):
				if not Economy.is_full(r["id"]):
					return false
		elif not Economy.is_full(id):
			return false
	return any

## Steady income / upkeep per second of every stored resource across all
## colonies: { resource_id: net per second }. "raw" is all raw kinds together;
## energy is the grid's net. Waiting, paused and constructing buildings count 0.
## `only_seed`: one world's own production and use (its energy net; the
## empire-wide idle income left out).
func resource_rates(only_seed: int = -1) -> Dictionary:
	var rates := {Economy.ENERGY: _global_energy}
	var st := get_node("/root/SkillTree")
	for pp: PlanetProgress in _all_colonies():
		if only_seed != -1 and pp.planet_seed != only_seed:
			continue
		var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
		if pd != null:
			for poi: POIData in pd.custom_pois:
				var ddef := district_def(poi)
				if ddef == null or not makes_base(pd, poi) or ddef.base_tick <= 0.0:
					continue
				var inc := district_income(pp, poi)
				for id: String in inc:
					if id == Economy.ENERGY or id == Economy.POPULATION:
						continue
					rates[id] = float(rates.get(id, 0.0)) \
						+ float(inc[id]) * st.get_global_speed_mult() * planet_pop_speed(pp.planet_seed) / ddef.base_tick
		for entry: Dictionary in pp.buildings:
			if entry.get("constructing", false):
				continue
			var key := _key(pp.planet_seed, entry.get("district_id", ""), entry.get("uid", "-1"))
			if _user_paused.get(key, false) or _paused.get(key, false) or _storage_full.get(key, false):
				continue
			var def := BuildingDef.find(entry.get("building_id", ""))
			if def == null or def.tick_duration <= 0.0:
				continue
			var speed: float = st.get_global_speed_mult()
			if def.outputs.has(Economy.RAW):
				speed *= st.get_mine_speed_mult()
			if def.energy_per_tick < 0.0 and _global_energy_ratio <= 0.0:
				continue   # no power at all: waiting
			if speed <= 0.0:
				continue
			var per_s := speed / def.tick_duration
			var eff := output_efficiency(pp, def)
			for id: String in def.outputs:
				if id == Economy.ENERGY or id == Economy.POPULATION:
					continue
				rates[id] = float(rates.get(id, 0.0)) + output_per_cycle(pp, entry, def, id) * eff * per_s
			for id: String in def.inputs:
				rates[id] = float(rates.get(id, 0.0)) - float(def.inputs[id]) * float(entry.get("amount", 1)) * per_s
	if only_seed != -1:
		var opp := GameState.get_planet(only_seed)
		rates[Economy.ENERGY] = planet_energy_net(opp) if opp != null else 0.0
		return rates
	var idle := idle_income_rates()
	for id: String in idle:
		if float(idle[id]) > 0.0:
			rates[id] = float(rates.get(id, 0.0)) + float(idle[id])
	return rates

## Where every stored resource comes from and goes to, per second, across all
## worlds: { resource id: { source label: per second } } — districts by type,
## buildings by model (upkeep as "<model> upkeep", negative), idle population.
## "raw" holds every raw mineral together (mined minus used); each mineral id
## its own share. Cached for BREAKDOWN_MS; the top bar's rates and tooltips read it.
const BREAKDOWN_MS := 250
var _breakdown: Dictionary = {}
## The same, per unit: { id: { label: { "Market Quarter": per_s, … } } } —
## what a breakdown line is made of (nested tips, playtest 31.10).
var _breakdown_units: Dictionary = {}

func resource_units(id: String, label: String) -> Dictionary:
	resource_breakdowns()
	return _breakdown_units.get(id, {}).get(label, {})
var _breakdown_at := -100000

func resource_breakdowns() -> Dictionary:
	var now := Time.get_ticks_msec()
	if now - _breakdown_at < BREAKDOWN_MS:
		return _breakdown
	_breakdown_at = now
	var out := {}
	var units := {}
	var add := func(id: String, label: String, v: float, unit: String) -> void:
		if absf(v) < 0.00001:
			return
		if not out.has(id):
			out[id] = {}
			units[id] = {}
		out[id][label] = float(out[id].get(label, 0.0)) + v
		if unit != "":
			if not units[id].has(label):
				units[id][label] = {}
			units[id][label][unit] = float(units[id][label].get(unit, 0.0)) + v
	var st := get_node("/root/SkillTree")
	for pp: PlanetProgress in _all_colonies():
		var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
		if pd == null:
			continue
		var minerals: Array = Economy.raw_for_body(pd)
		var spread := func(label: String, v: float, unit: String) -> void:   # a mine's raw output over the body's minerals
			add.call(Economy.RAW, label, v, unit)
			for r: Dictionary in minerals:
				add.call(String(r["id"]), label, v / float(minerals.size()), unit)
		for poi: POIData in pd.custom_pois:
			var ddef := district_def(poi)
			if ddef == null or not makes_base(pd, poi) or ddef.base_tick <= 0.0:
				continue
			var label := "Orbit City" if poi.is_orbital() else ("Capital Districts" if poi.is_city() else ddef.display_name + "s")
			var inc := district_income(pp, poi)
			for id: String in inc:
				if id == Economy.ENERGY or id == Economy.POPULATION:
					continue
				if id == Economy.RAW and ddef.id != DistrictDef.Type.MINING and not GameState.is_body_surveyed(pp.planet_seed):
					continue
				var v: float = float(inc[id]) * st.get_global_speed_mult() * planet_pop_speed(pp.planet_seed) / ddef.base_tick
				if id == Economy.RAW:
					spread.call(label, v, poi.shown_name())
				else:
					add.call(id, label, v, poi.shown_name())
		for entry: Dictionary in pp.buildings:
			if entry.get("constructing", false):
				continue
			var key := _key(pp.planet_seed, entry.get("district_id", ""), entry.get("uid", "-1"))
			if _user_paused.get(key, false) or _paused.get(key, false) or _storage_full.get(key, false):
				continue
			var def := BuildingDef.find(entry.get("building_id", ""))
			if def == null or def.tick_duration <= 0.0:
				continue
			if def.energy_per_tick < 0.0 and _global_energy_ratio <= 0.0:
				continue
			var speed: float = st.get_global_speed_mult()
			if def.outputs.has(Economy.RAW):
				speed *= st.get_mine_speed_mult()
			var per_s := speed / def.tick_duration
			var eff := output_efficiency(pp, def)
			var dpoi := _district_poi(pp, entry.get("district_id", ""))
			var n := int(entry.get("amount", 1))
			var unit := (dpoi.shown_name() if dpoi != null else pd.planet_name) + (" ×%d" % n if n > 1 else "")
			for id: String in def.outputs:
				if id == Economy.ENERGY or id == Economy.POPULATION:
					continue
				var v := output_per_cycle(pp, entry, def, id) * eff * per_s
				if id == Economy.RAW:
					spread.call(def.display_name, v, unit)
				else:
					add.call(id, def.display_name, v, unit)
			for id: String in def.inputs:
				var v := -float(def.inputs[id]) * float(entry.get("amount", 1)) * per_s
				add.call(id, def.display_name + " upkeep", v, unit)
				if Economy.is_raw(id):
					add.call(Economy.RAW, def.display_name + " upkeep", v, unit)
	var idle := idle_income_rates()
	for id: String in idle:
		add.call(id, "Idle population", float(idle[id]), "")
	_breakdown = out
	_breakdown_units = units
	return out

## Net per second of a resource from resource_breakdowns().
func breakdown_total(id: String) -> float:
	var t := 0.0
	for v in resource_breakdowns().get(id, {}).values():
		t += float(v)
	return t

## Pays a building's per-cycle inputs from the global stock. Returns false (and
## takes nothing) if anything is short. Every input is a fixed, named resource
## (e.g. "ferrite") — a building never picks a different mineral on its own;
## a Moonstone recipe is its own building model.
func _pay_inputs(def: BuildingDef, amount: int, _entry: Dictionary) -> bool:
	if def.inputs.is_empty():
		return true
	var plan := {}   # resource id -> amount to take
	for id: String in def.inputs:
		var need: float = float(def.inputs[id]) * float(amount)
		if id == Economy.RAW:
			push_warning("[ProductionManager] %s has a generic 'raw' input — give it a named mineral." % def.building_id)
			return false
		if Economy.amount(id) < need:
			return false
		plan[id] = float(plan.get(id, 0.0)) + need
	for id: String in plan:
		if id == Economy.CREDITS:
			GameState.spend_credits(plan[id])
		elif id == Economy.SCIENCE:
			GameState.spend_science(plan[id])
		else:
			GameState.consume_resource(id, plan[id])
	return true

## End of a production cycle: add every (non-flow) output, scaled by count,
## planet bonuses, skills and the population/energy efficiency, and show the popups.
func _on_tick_complete(pp: PlanetProgress, def: BuildingDef,
		_key_str: String, amount: int, entry: Dictionary) -> void:
	if not pp.buildings.has(entry):
		return   # scrapped before the cycle finished
	if def.logic != null:   # legacy hook (spaceport launches)
		def.logic.produce(pp, def, amount, PlanetModifier.for_planet(_planet_type(pp.planet_seed)),
			entry, get_node("/root/SkillTree"))
	var poi_lbl: String = entry.get("district_id", "")
	var eff := output_efficiency(pp, def)   # population / energy deficit
	for id: String in def.outputs:
		if id == Economy.ENERGY or id == Economy.POPULATION:
			continue   # flows / capacity, not per-cycle stock
		var value: float = output_per_cycle(pp, entry, def, id) * eff
		if id == Economy.RAW:
			_produce_raw(pp, poi_lbl, value)
			continue
		Economy.add(id, value)
		if poi_lbl != "" and value > 0.0:
			var txt := "+%.1f" % value if value < 10.0 else "+%.0f" % value
			resource_produced.emit(pp.planet_seed, poi_lbl, txt, Economy.color_of(id), UIIcons.get_icon(id))

## Splits a mine's raw output evenly over the body's minerals (the ones this
## civilization can extract). No deposits or densities: every valid site on a
## body yields its whole mineral set.
func _produce_raw(pp: PlanetProgress, poi_lbl: String, total: float) -> void:
	var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
	if pd == null or total <= 0.0:
		return
	if not GameState.is_body_surveyed(pp.planet_seed):
		GameState.discover_body_minerals(pp.planet_seed)
	var raws := Economy.raw_for_body(pd)
	if raws.is_empty():
		return
	for k in raws.size():
		var share: float = total / float(raws.size())
		if share <= 0.0:
			continue
		var rid: String = raws[k]["id"]
		var before := GameState.get_resource(rid)
		GameState.add_resource(rid, share)
		if rid == "moonstone" and pd.planet_type == PlanetData.Type.MOON:
			# only Moonstone really mined on the Moon counts towards the final rocket
			GameState.moon_local_moonstone += maxf(GameState.get_resource(rid) - before, 0.0)
		if share >= 0.05 and poi_lbl != "":
			var col: Color = raws[k]["color"]
			var txt := "+%.1f" % share if share < 1.0 else "+%.0f" % share
			resource_produced.emit(pp.planet_seed, poi_lbl, txt, col, MineralIcon.make(1, col))

## One cycle's worth of `id` from a building entry (count, location, City and
## planet supports, skills) — before population/energy efficiency. Energy is per
## second of flow. Geography never boosts a building (§3, §19.3): only its
## district's own base output.
func output_per_cycle(pp: PlanetProgress, entry: Dictionary, def: BuildingDef, id: String) -> float:
	if not def.outputs.has(id):
		return 0.0
	var v: float = float(def.outputs[id]) * float(entry.get("amount", 1))
	v *= Economy.site_mult(1.0, location_mult(pp, entry.get("district_id", ""))) \
		* Economy.scope_bonus(pp, entry.get("district_id", ""), id)
	return _skill_mods(pp, id, v, def.output_tag)

## Skill / planet-modifier multipliers shared by buildings and district base income.
func _skill_mods(pp: PlanetProgress, id: String, v: float, output_tag: String) -> float:
	var st := get_node("/root/SkillTree")
	match id:
		Economy.CREDITS:
			v *= st.get_credits_mult()
		Economy.RAW:
			v *= st.get_mine_output_mult()   # planet traits work through Economy.planet_bonus (PlanetTags)
			v *= st.reserve_mult(idle_ratio())
		Economy.GOODS, Economy.RARE:
			v *= st.reserve_mult(idle_ratio())
		Economy.FUEL:
			v *= st.get_fuel_mult() * st.reserve_mult(idle_ratio())
		Economy.SCIENCE:
			v *= st.get_science_mult() * Balance.cfg.science_income_mult
		Economy.ENERGY:
			if output_tag == "solar":
				v *= st.get_solar_mult()
	return v

# ── Idle population (GDD §9.7, §17.20) ────────────────────────────────────────
# Housing nobody works in. Counted over the whole empire, free City housing
# included (Balance.cfg.idle_pop_counts_city_base). Civic Enterprise turns it
# into Credits, Free Research into Science (per minute, paid every cycle) and
# Production Reserve into a small output bonus. The income never adds housing.

const IDLE_CYCLE := 20.0
const IDLE_CACHE_MS := 500
var _idle_timer: float = 0.0
var _idle_cache: Array = [-100000, 0.0, 0.0]   # [time_ms, idle, capacity]
var _idle_computing: bool = false

## Empire idle population and housing capacity: Vector2(idle, capacity).
func empire_idle() -> Vector2:
	var now := Time.get_ticks_msec()
	# housing totals run district income, whose Production Reserve asks for the
	# idle ratio again: answer that inner call from the last value, never recurse
	if _idle_computing:
		return Vector2(float(_idle_cache[1]), float(_idle_cache[2]))
	if now - int(_idle_cache[0]) > IDLE_CACHE_MS:
		_idle_computing = true
		var cap := 0.0
		var used := 0.0
		for pp: PlanetProgress in _all_colonies():
			var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
			if pd == null:
				continue
			cap += float(Economy.world_max_population(pd, pp))
			used += float(Economy.world_used_population(pd, pp))
			if not Balance.cfg.idle_pop_counts_city_base:
				for poi: POIData in pd.custom_pois:
					if poi.is_city() and not poi.is_orbital() and not poi.constructing:
						cap -= Balance.cfg.city_base_pop
		_idle_cache = [now, maxf(cap - used, 0.0), maxf(cap, 0.0)]
		_idle_computing = false
	return Vector2(float(_idle_cache[1]), float(_idle_cache[2]))

## Share of the empire's housing that stands idle (0–1).
func idle_ratio() -> float:
	var v := empire_idle()
	return v.x / v.y if v.y > 0.0 else 0.0

## Idle income per second: { credits, science } (0 until researched).
func idle_income_rates() -> Dictionary:
	var st := get_node("/root/SkillTree")
	var k := empire_idle().x / 1000.0 / 60.0
	return {Economy.CREDITS: k * float(st.idle_credits_per_1000()),
		Economy.SCIENCE: k * float(st.idle_science_per_1000()) * Balance.cfg.science_income_mult}

func _tick_idle_income(delta: float) -> void:
	_idle_timer += delta
	if _idle_timer < IDLE_CYCLE:
		return
	_idle_timer -= IDLE_CYCLE
	var r := idle_income_rates()
	for id: String in r:
		var v: float = float(r[id]) * IDLE_CYCLE
		if v > 0.0:
			Economy.add(id, v)
	Trade.run_orders()   # automation: sales, then purchases (GDD §18.19)

# ── Building helpers (UI) ─────────────────────────────────────────────────────

## Buildings have no levels any more (count only); kept at 1× for older UI code.
func get_building_level_mult(_level: int) -> float:
	return 1.0

func get_building_consume_mult(_level: int) -> float:
	return 1.0

## The building's main output per cycle (what its card shows).
func get_building_output(pp: PlanetProgress, entry: Dictionary, def: BuildingDef) -> float:
	for id: String in def.outputs:
		if id == Economy.POPULATION or id == Economy.ENERGY:
			continue
		return output_per_cycle(pp, entry, def, id)
	if def.outputs.has(Economy.ENERGY):
		return output_per_cycle(pp, entry, def, Economy.ENERGY)
	if def.outputs.has(Economy.POPULATION):
		return output_per_cycle(pp, entry, def, Economy.POPULATION)
	return 0.0

## Location multiplier of a district (proximity, centres, distance — Location.gd);
## a building's output takes its district's.
func location_mult(pp: PlanetProgress, district_id: String) -> float:
	var poi := _district_poi(pp, district_id)
	if poi == null or poi.is_orbital():
		return 1.0
	return Location.mult(GameState.get_planet_data(pp.planet_seed), poi)

## The district POI an entry belongs to, or null.
func _district_poi(pp: PlanetProgress, district_id: String) -> POIData:
	var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
	if pd == null:
		return null
	return _index(pd)["by_label"].get(district_id, null)

## Terrain multiplier of a building's output: always 1 — geography raises only
## its district's base (§3, §19.3). Kept for the UI that shows it.
func get_site_mult(_pp: PlanetProgress, _entry: Dictionary, _def: BuildingDef, _id: String = "") -> float:
	return 1.0

# ── Energy grid ───────────────────────────────────────────────────────────────

## Built, not-paused entries of a planet.
func _running_entries(pp: PlanetProgress) -> Array:
	var out: Array = []
	for entry: Dictionary in pp.buildings:
		if entry.get("constructing", false):
			continue
		if not entry.has("uid"):
			entry["uid"] = str(randi())
		var ekey: String = _key(pp.planet_seed, entry.get("district_id", ""), entry["uid"])
		if _paused.get(ekey, false) or _user_paused.get(ekey, false):
			continue
		out.append(entry)
	return out

## Net energy flow of one building entry (production − upkeep), as the grid
## counts it. 0 while it is constructing or paused.
func entry_energy(pp: PlanetProgress, entry: Dictionary) -> float:
	if entry.get("constructing", false):
		return 0.0
	var ekey: String = _key(pp.planet_seed, entry.get("district_id", ""), entry.get("uid", "-1"))
	if _paused.get(ekey, false) or _user_paused.get(ekey, false):
		return 0.0
	var def := BuildingDef.find(entry.get("building_id", ""))
	if def == null:
		return 0.0
	var e := output_per_cycle(pp, entry, def, Economy.ENERGY)
	if def.energy_per_tick < 0.0:
		e += def.energy_per_tick * float(entry.get("amount", 1)) \
			* float(get_node("/root/SkillTree").get_energy_consume_mult())
	return e

## (production, demand) of one planet's energy grid.
func _planet_energy(pp: PlanetProgress) -> Vector2:
	var st := get_node("/root/SkillTree")
	var prod := 0.0
	var demand := 0.0
	for entry: Dictionary in _running_entries(pp):
		var def := BuildingDef.find(entry.get("building_id", ""))
		if def == null:
			continue
		if def.outputs.has(Economy.ENERGY):
			prod += output_per_cycle(pp, entry, def, Economy.ENERGY)
		if def.energy_per_tick < 0.0:
			demand += -def.energy_per_tick * float(entry.get("amount", 1)) * float(st.get_energy_consume_mult())
	prod += districts_energy(pp)
	demand += orbit_districts_energy_use(pp) * float(st.get_energy_consume_mult())
	return Vector2(prod, demand)

## The Orbit districts' own energy use (⚡/s), apart from their buildings.
func orbit_districts_energy_use(pp: PlanetProgress) -> float:
	var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
	if pd == null:
		return 0.0
	var e := 0.0
	for poi: POIData in pd.custom_pois:
		if poi.is_orbital() and not poi.constructing:
			var d := district_def(poi)
			if d != null:
				e += d.own_energy_use
	return e

## Base energy (⚡/s) of a planet's finished districts.
func districts_energy(pp: PlanetProgress) -> float:
	var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
	if pd == null:
		return 0.0
	var e := 0.0
	for poi: POIData in pd.custom_pois:
		if makes_base(pd, poi):
			e += district_base(pp, poi, Economy.ENERGY)
	return e

## Computes global energy balance and ratio across ALL colonized planets.
## Called once per frame before _tick_all.
func _calc_global_energy() -> void:
	var total_prod := 0.0
	var total_demand := 0.0
	for pp: PlanetProgress in _all_colonies():
		var e := _planet_energy(pp)
		total_prod += e.x
		total_demand += e.y
	_global_energy = total_prod - total_demand
	_global_energy_prod = total_prod
	_global_energy_demand = total_demand
	# A deficit lowers what energy consumers make per cycle (output_efficiency):
	# down to 50% when the grid makes nothing, e.g. 75% when it covers half the demand.
	if total_demand <= 0.0 or _global_energy >= 0.0:
		_global_energy_ratio = 1.0
	else:
		_global_energy_ratio = 1.0 - Balance.cfg.energy_max_slowdown * (1.0 - clampf(total_prod / total_demand, 0.0, 1.0))

## Per-planet energy contribution (used by PlanetaryView for breakdown display).
## One world's energy: Vector2(produced, demanded) per second.
## Where energy comes from and goes, every world: { group: { unit: amount } },
## + made, − used (the energy tooltip's groups, playtest 31.10).
func energy_sources() -> Dictionary:
	var out := {}
	var add := func(group: String, unit: String, v: float) -> void:
		if absf(v) < 0.0001:
			return
		if not out.has(group):
			out[group] = {}
		out[group][unit] = float(out[group].get(unit, 0.0)) + v
	var st := get_node("/root/SkillTree")
	var consume: float = float(st.get_energy_consume_mult())
	for pp: PlanetProgress in _all_colonies():
		var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
		if pd == null:
			continue
		for entry: Dictionary in _running_entries(pp):
			var def := BuildingDef.find(entry.get("building_id", ""))
			if def == null:
				continue
			var dpoi := _district_poi(pp, entry.get("district_id", ""))
			var n := int(entry.get("amount", 1))
			var unit := (dpoi.shown_name() if dpoi != null else pd.planet_name) + (" ×%d" % n if n > 1 else "")
			if def.outputs.has(Economy.ENERGY):
				add.call(def.display_name, unit, output_per_cycle(pp, entry, def, Economy.ENERGY))
			if def.energy_per_tick < 0.0:
				add.call(def.display_name, unit, def.energy_per_tick * float(n) * consume)
		for poi: POIData in pd.custom_pois:
			var ddef := district_def(poi)
			if ddef == null:
				continue
			if makes_base(pd, poi):
				var label := "Capital Districts" if poi.is_city() else ("Orbit City" if poi.is_orbital() else ddef.display_name + "s")
				add.call(label, poi.shown_name(), district_base(pp, poi, Economy.ENERGY))
			if poi.is_orbital() and not poi.constructing and ddef.own_energy_use > 0.0:
				add.call("Orbit districts", poi.shown_name(), -ddef.own_energy_use * consume)
	return out

func planet_energy_split(pp: PlanetProgress) -> Vector2:
	return _planet_energy(pp)

func planet_energy_net(pp: PlanetProgress) -> float:
	var e := _planet_energy(pp)
	return e.x - e.y

func _planet_type(planet_seed: int) -> PlanetData.Type:
	var pd := GameState.get_planet_data(planet_seed)
	if pd != null:
		return pd.planet_type
	return PlanetData.Type.TERRAN

func _all_colonies() -> Array[PlanetProgress]:
	var result: Array[PlanetProgress] = []
	for pp: PlanetProgress in GameState._planet_progress.values():
		if pp.is_colonized:
			result.append(pp)
	return result

func _key(planet_seed: int, poi_label: String, uid: String) -> String:
	return "%d:%s:%s" % [planet_seed, poi_label, uid]

func _emit_progress(planet_seed: int, key: String) -> void:
	building_progress_changed.emit(planet_seed, key, _progress.get(key, 0.0))
