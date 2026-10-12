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
const MAX_ENERGY_SLOWDOWN := 0.5
## { pm_key -> true } building waiting because every output's storage is full
var _storage_full: Dictionary = {}
## { planet_seed -> work speed from population } (Economy.pop_speed), per frame
var _pop_speed: Dictionary = {}
## { "seed:district_label" -> float 0.0-1.0 } district base-income cycles
var _base_progress: Dictionary = {}
## { "construct:pm_key" -> float 0.0-1.0 }
var _construct:     Dictionary = {}

func _process(delta: float) -> void:
	_calc_global_energy()
	_tick_all(delta)

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
					pp.level += 1
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

			for poi in pd.custom_pois:
				if poi.constructing:
					if poi.is_orbital():
						continue  # Orbital progress is driven by rocket animation in PlanetaryView
					poi.construct_progress += delta / max(0.1, poi.construct_duration)
					if poi.construct_progress >= 1.0:
						poi.constructing = false
						poi.construct_progress = 1.0
						district_changed = true
					building_progress_changed.emit(planet_seed, poi.label, poi.construct_progress)
			if district_changed:
				GameState.planet_progress_changed.emit(planet_seed)

		var energy_ratio: float = _global_energy_ratio
		var pop_speed: float = Economy.pop_speed(pd, pp) if pd != null else 1.0
		_pop_speed[planet_seed] = pop_speed
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
			if def == null or def.tick_duration <= 0.0:
				continue

			# ── Construction phase ────────────────────────────────────────────
			if entry.get("constructing", false):
				var ck: String = "construct:" + key
				var cdur: float = def.construct_duration if def.construct_duration > 0.0 else def.tick_duration
				var cp: float  = _construct.get(ck, 0.0) + delta / cdur
				if cp >= 1.0:
					_construct.erase(ck)
					entry["constructing"] = false
					var merge_idx: int = entry.get("merge_into", -1)
					if merge_idx >= 0:
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

			# ── Energy throttle ───────────────────────────────────────────────
			var energy_speed: float = 1.0
			if def.energy_per_tick < 0.0:
				if energy_ratio <= 0.0:
					_emit_progress(planet_seed, key)   # inputs already paid; waits for power
					continue
				energy_speed = energy_ratio

			# ── Tick production bar ───────────────────────────────────────────
			var speed_mult: float = energy_speed * pop_speed * st.get_global_speed_mult()
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
		for entry: Dictionary in pending_merges:
			var merge_idx: int = entry.get("merge_into", -1)
			if merge_idx >= 0 and merge_idx < pp.buildings.size():
				pp.buildings[merge_idx]["amount"] = pp.buildings[merge_idx].get("amount", 1) + 1
			pp.remove_building_stack(entry)

		for c in completed_buildings:
			building_constructed.emit(planet_seed, c.key, c.bid)

		if pd:
			_tick_district_base(pp, pd, delta)

## Every finished surface district makes its base income (DistrictDef.base_outputs)
## on its own cycle. Energy and population are flows / capacity, handled in
## _planet_energy and Economy.max_population instead.
func _tick_district_base(pp: PlanetProgress, pd: PlanetData, delta: float) -> void:
	var speed: float = get_node("/root/SkillTree").get_global_speed_mult() * planet_pop_speed(pp.planet_seed)
	for poi: POIData in pd.custom_pois:
		if poi.constructing or poi.is_orbital():
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
			var v: float = income[id]
			if id == Economy.RAW:
				_produce_raw(pp, poi.label, v)
				continue
			Economy.add(id, v)
			if v > 0.0:
				var short: String = Economy.INFO.get(id, {}).get("short", id)
				resource_produced.emit(pp.planet_seed, poi.label,
					("+%.1f %s" if v < 10.0 else "+%.0f %s") % [v, short], Economy.color_of(id), null)

## Work speed from population on a planet (1 = housed; < 1 = overpopulated).
func planet_pop_speed(planet_seed: int) -> float:
	return float(_pop_speed.get(planet_seed, 1.0))

## 0..1 progress of a district's base-income cycle.
func base_progress(planet_seed: int, district_label: String) -> float:
	return _base_progress.get("%d:%s" % [planet_seed, district_label], 0.0)

static func _has_stock_income(income: Dictionary) -> bool:
	for id: String in income:
		if id != Economy.ENERGY and id != Economy.POPULATION and float(income[id]) > 0.0:
			return true
	return false

## The district type a POI was founded as.
static func district_def(poi: POIData) -> DistrictDef:
	return DistrictDef.find_by_key(poi.type_tag) if poi != null else null

## Districts that pay neighbour income to `poi`: its map neighbours (poi.neighbors)
## and, for a City, every district built under it — each counted once.
## Unfinished districts give nothing.
static func income_sources(pd: PlanetData, poi: POIData) -> Array[POIData]:
	var out: Array[POIData] = []
	if pd == null or poi == null:
		return out
	for p: POIData in pd.custom_pois:
		if p == poi or p.constructing or p.is_orbital():
			continue
		if poi.neighbors.has(p.label) or (poi.is_city() and p.parent_city == poi.label):
			out.append(p)
	return out

## Space bonus: a district far from every other one makes more on its own —
## the trade-off against neighbour income. +ISOLATION_MAX at ISOLATION_RANGE_DEG
## beyond the minimum spacing.
const ISOLATION_MAX := 0.6
const ISOLATION_RANGE_DEG := 10.0

static func isolation_mult(pd: PlanetData, poi: POIData) -> float:
	if pd == null or poi == null:
		return 1.0
	var best := INF
	for p: POIData in pd.custom_pois:
		if p == poi or p.is_orbital() or (p.label == poi.label and poi.label != ""):
			continue
		best = minf(best, rad_to_deg(TerrainSampler.angular_distance(deg_to_rad(poi.lon_deg), deg_to_rad(poi.lat_deg),
			deg_to_rad(p.lon_deg), deg_to_rad(p.lat_deg))))
	if best == INF:
		return 1.0
	var t := clampf((best - TerrainSampler.MIN_SPACING_DEG) / ISOLATION_RANGE_DEG, 0.0, 1.0)
	return 1.0 + ISOLATION_MAX * t

## Unscaled base income: { id: base × site × space + Σ neighbour income × road
## weight } (before level, City bonuses and skills).
static func district_income_raw(pd: PlanetData, poi: POIData) -> Dictionary:
	var out := {}
	var ddef := district_def(poi)
	if ddef == null:
		return out
	var sm := ddef.site_mult(poi) * isolation_mult(pd, poi)
	for id: String in ddef.base_outputs:
		out[id] = float(ddef.base_outputs[id]) * sm
	for src: POIData in income_sources(pd, poi):
		var add: Dictionary = ddef.income_from(src.type_tag)
		var w: float = float(poi.neighbor_weight.get(src.label, 1.0))
		for id: String in add:
			out[id] = float(out.get(id, 0.0)) + float(add[id]) * w
	return out

## A district's base income per its cycle (per second for energy, capacity for
## population): (base × site + neighbours) × level × planet bonus × skills.
func district_income(pp: PlanetProgress, poi: POIData) -> Dictionary:
	if poi == null or poi.constructing or poi.is_orbital():
		return {}
	var raw := district_income_raw(GameState.get_planet_data(pp.planet_seed), poi)
	var lv_m := DistrictDef.level_mult(pp.district_levels.get(poi.label, 1))
	for id: String in raw:
		raw[id] = _skill_mods(pp, id, float(raw[id]) * lv_m * Economy.scope_bonus(pp, poi.label, id), "")
	return raw

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
func resource_rates() -> Dictionary:
	var rates := {Economy.ENERGY: _global_energy}
	var st := get_node("/root/SkillTree")
	for pp: PlanetProgress in _all_colonies():
		var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
		if pd != null:
			for poi: POIData in pd.custom_pois:
				var ddef := district_def(poi)
				if ddef == null or poi.is_orbital() or ddef.base_tick <= 0.0:
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
			var speed: float = st.get_global_speed_mult() * planet_pop_speed(pp.planet_seed)
			if def.outputs.has(Economy.RAW):
				speed *= st.get_mine_speed_mult()
			if def.energy_per_tick < 0.0:
				speed *= _global_energy_ratio
			if speed <= 0.0:
				continue
			var per_s := speed / def.tick_duration
			var yield_m := 1.0
			if def.inputs.has(Economy.RAW):
				var rinfo := Economy.raw_info(entry.get("burning_mineral", ""))
				yield_m = Economy.yield_mult(int(rinfo.get("rarity", 1)))
			for id: String in def.outputs:
				if id == Economy.ENERGY or id == Economy.POPULATION:
					continue
				rates[id] = float(rates.get(id, 0.0)) + output_per_cycle(pp, entry, def, id) * yield_m * per_s
			for id: String in def.inputs:
				rates[id] = float(rates.get(id, 0.0)) - float(def.inputs[id]) * float(entry.get("amount", 1)) * per_s
	return rates

## Pays a building's per-cycle inputs from the global stock. Returns false (and
## takes nothing) if anything is short. A "raw" input takes the highest-rarity
## raw resource in stock, remembered in entry.burning_mineral for the yield.
func _pay_inputs(def: BuildingDef, amount: int, entry: Dictionary) -> bool:
	if def.inputs.is_empty():
		return true
	var plan := {}   # resource id -> amount to take
	for id: String in def.inputs:
		var need: float = float(def.inputs[id]) * float(amount)
		if id == Economy.RAW:
			var rid := Economy.best_raw_in_stock(need)
			if rid == "":
				return false
			plan[rid] = float(plan.get(rid, 0.0)) + need
			entry["burning_mineral"] = rid
		else:
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
## raw-input yield, planet bonuses and skills, and show the popups.
func _on_tick_complete(pp: PlanetProgress, def: BuildingDef,
		_key_str: String, amount: int, entry: Dictionary) -> void:
	if not pp.buildings.has(entry):
		return   # scrapped before the cycle finished
	if def.logic != null:   # legacy hook (spaceport launches)
		def.logic.produce(pp, def, amount, PlanetModifier.for_planet(_planet_type(pp.planet_seed)),
			entry, get_node("/root/SkillTree"))
	var poi_lbl: String = entry.get("district_id", "")
	var yield_mult := 1.0
	if def.inputs.has(Economy.RAW):
		var rinfo := Economy.raw_info(entry.get("burning_mineral", ""))
		yield_mult = Economy.yield_mult(int(rinfo.get("rarity", 1)))
	for id: String in def.outputs:
		if id == Economy.ENERGY or id == Economy.POPULATION:
			continue   # flows / capacity, not per-cycle stock
		var value: float = output_per_cycle(pp, entry, def, id) * yield_mult
		if id == Economy.RAW:
			_produce_raw(pp, poi_lbl, value)
			continue
		Economy.add(id, value)
		if poi_lbl != "" and value > 0.0:
			var short: String = Economy.INFO.get(id, {}).get("short", id)
			var txt := "+%.1f %s" % [value, short] if value < 10.0 else "+%.0f %s" % [value, short]
			resource_produced.emit(pp.planet_seed, poi_lbl, txt, Economy.color_of(id), null)

## Splits a mine's raw output over the planet's raw resources, by deposit
## density × what lies under the district.
func _produce_raw(pp: PlanetProgress, poi_lbl: String, total: float) -> void:
	var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
	if pd == null or total <= 0.0:
		return
	var raws := Economy.raw_for_body(pd)
	if raws.is_empty():
		return
	var weights: Array[float] = []
	var sum := 0.0
	for r: Dictionary in raws:
		var rid: String = r["id"]
		var w: float = float(pd.mineral_densities.get(rid, 1.0 / pow(2.5, float(r["rarity"]) - 1.0)))
		w *= local_mineral_factor(pp, poi_lbl, rid)
		weights.append(w)
		sum += w
	if sum <= 0.0:
		return
	for k in raws.size():
		var share: float = total * weights[k] / sum
		if share <= 0.0:
			continue
		var rid: String = raws[k]["id"]
		GameState.add_resource(rid, share)
		if share >= 0.05 and poi_lbl != "":
			var col: Color = raws[k]["color"]
			var txt := "+%.1f" % share if share < 1.0 else "+%.0f" % share
			resource_produced.emit(pp.planet_seed, poi_lbl, txt, col, MineralIcon.make(1, col))

## One cycle's worth of `id` from a building entry (count, site, planet bonus,
## skills) — before any raw-input yield. Energy is per second of flow.
func output_per_cycle(pp: PlanetProgress, entry: Dictionary, def: BuildingDef, id: String) -> float:
	if not def.outputs.has(id):
		return 0.0
	var v: float = float(def.outputs[id]) * float(entry.get("amount", 1))
	v *= get_site_mult(pp, entry, def) * Economy.scope_bonus(pp, entry.get("district_id", ""), id)
	return _skill_mods(pp, id, v, def.output_tag)

## Skill / planet-modifier multipliers shared by buildings and district base income.
func _skill_mods(pp: PlanetProgress, id: String, v: float, output_tag: String) -> float:
	var st := get_node("/root/SkillTree")
	match id:
		Economy.CREDITS:
			v *= st.get_credits_mult()
		Economy.RAW:
			v *= st.get_mine_output_mult() * PlanetModifier.combined(
				PlanetModifier.for_planet(_planet_type(pp.planet_seed)), PlanetModifier.Effect.MINE_OUTPUT_MULT)
		Economy.ENERGY:
			if output_tag == "solar":
				v *= st.get_solar_mult()
	return v

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

## The district POI an entry belongs to, or null.
func _district_poi(pp: PlanetProgress, district_id: String) -> POIData:
	var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
	if pd == null:
		return null
	for poi: POIData in pd.custom_pois:
		if poi.label == district_id:
			return poi
	return null

## Output multiplier from the district site's resources (BuildingDef.output_tag).
func get_site_mult(pp: PlanetProgress, entry: Dictionary, def: BuildingDef) -> float:
	if def.output_tag == "":
		return 1.0
	return def.site_mult(_district_poi(pp, entry.get("district_id", "")))

## Mines draw the planet's raw resources in proportion to what lies under the
## district: planet density × this factor (≈1 for an average deposit).
func local_mineral_factor(pp: PlanetProgress, district_id: String, resource_id: String) -> float:
	var poi := _district_poi(pp, district_id)
	if poi == null or not poi.resource_tags.has("minerals"):
		return 1.0
	var mins: Dictionary = poi.resource_tags["minerals"]
	if not mins.has(resource_id):
		return 1.0
	return 0.15 + 1.7 * float(mins[resource_id])

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
	return Vector2(prod, demand)

## Base energy (⚡/s) of a planet's finished districts.
func districts_energy(pp: PlanetProgress) -> float:
	var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
	if pd == null:
		return 0.0
	var e := 0.0
	for poi: POIData in pd.custom_pois:
		if not poi.is_orbital():
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
	# A deficit slows energy consumers a little: down to 50% speed when the
	# grid makes nothing, e.g. 75% when it covers half the demand.
	if total_demand <= 0.0 or _global_energy >= 0.0:
		_global_energy_ratio = 1.0
	else:
		_global_energy_ratio = 1.0 - MAX_ENERGY_SLOWDOWN * (1.0 - clampf(total_prod / total_demand, 0.0, 1.0))

## Per-planet energy contribution (used by PlanetaryView for breakdown display).
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
