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
## global energy throttle ratio (0.0-1.0)
var _global_energy_ratio: float = 1.0
## { "construct:pm_key" -> float 0.0-1.0 }
var _construct:     Dictionary = {}

func _process(delta: float) -> void:
	_calc_global_energy()
	_tick_all(delta)

func get_progress(key: String) -> float:
	return _progress.get(key, 0.0)

func is_paused(key: String) -> bool:
	return _paused.get(key, false)

func get_construct_progress(key: String) -> float:
	return _construct.get("construct:" + key, 0.0)

func is_constructing(key: String) -> bool:
	return _construct.has("construct:" + key)

func toggle_user_pause(key: String) -> void:
	var entry := _entry_for_key(key)
	entry["user_paused"] = not bool(entry.get("user_paused", false))
	_user_paused[key] = entry["user_paused"]
	_calc_global_energy()
	building_toggled.emit(key, _user_paused[key])

func is_user_paused(key: String) -> bool:
	var entry := _entry_for_key(key)
	return bool(entry.get("user_paused", false))

## Returns 0.0–1.0: global energy coverage ratio. < 1.0 = energy crisis.
func get_energy_ratio(_planet_seed: int = 0) -> float:
	return _global_energy_ratio

## Returns the global net energy balance (positive = surplus, negative = deficit).
func get_global_energy() -> float:
	return _global_energy

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
					poi.construct_progress += delta / max(0.1, poi.construct_duration)
					if poi.construct_progress >= 1.0:
						poi.constructing = false
						poi.construct_progress = 1.0
						if poi.is_orbital():
							GameState.ensure_station_ship(pd.seed, poi)
						district_changed = true
					building_progress_changed.emit(planet_seed, poi.label, poi.construct_progress)
			if district_changed:
				GameState.planet_progress_changed.emit(planet_seed)

		var energy_ratio: float = _global_energy_ratio

		var mods := PlanetModifier.for_planet(_planet_type(planet_seed))

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
			if entry.get("constructing", false):
				var ck: String = "construct:" + key
				var cdur: float = def.construct_duration if def.construct_duration > 0.0 else maxf(3.0, def.tick_duration)
				var cp: float = float(entry.get("construction_progress", 0.0)) + delta / cdur
				entry["construction_progress"] = cp
				if cp >= 1.0:
					_construct.erase(ck)
					entry["constructing"] = false
					var merge_idx: int = entry.get("merge_into", -1)
					if merge_idx >= 0:
						pending_merges.append(entry)
					# Spaceport starts paused after construction — player launches manually
					if def.building_id == "spaceport":
						_user_paused[key] = true
						entry["user_paused"] = true
					completed_buildings.append({ "key": key, "bid": bid })
					building_ticked.emit(planet_seed, key)
				else:
					_construct[ck] = cp
					building_progress_changed.emit(planet_seed, key, cp)
				continue

			if def.tick_duration <= 0.0:
				continue

			# ── User-toggled off ──────────────────────────────────────────────
			if entry.get("user_paused", false):
				continue

			# ── Start of cycle resource consumption ───────────────────────────
			var prev: float = float(entry.get("cycle_progress", 0.0))
			if prev <= 0.0 and not entry.get("cycle_funded", false):
				if def.input_type != BuildingDef.OutputType.NONE:
					# Find what the user selected to burn
					var intended_input: String = entry.get("input_mineral", "")
					if intended_input == "":
						intended_input = _resource_key(def.input_type, pp.planet_seed, entry)

					var input_def: ResourceData = GameState.known_resources.get(intended_input)
					var expected_tag := ResourceData.Tag.RAW_MINERAL if def.input_type == BuildingDef.OutputType.RAW_MINERAL else ResourceData.Tag.REFINED_MINERAL
					if input_def == null or input_def.tag != expected_tag or input_def.tier != def.input_tier:
						_paused[key] = true
						continue
					var required_amt := def.input_amount * amount * get_building_consume_mult(entry.get("level", 1))
					if GameState.global_resources.get(intended_input, 0.0) < required_amt:
						if not _paused.get(key, false):
							_paused[key] = true
							building_ticked.emit(planet_seed, key)
						_emit_progress(planet_seed, key)
						continue   # can't start — wait for resource

					# Resource available: consume it immediately from global pool
					GameState.consume_resource(intended_input, required_amt)
					# Lock this resource as the one currently burning for this cycle
					var old_burning: String = entry.get("burning_mineral", "")
					entry["burning_mineral"] = intended_input
					if old_burning != intended_input:
						building_ticked.emit(planet_seed, key)

				entry["cycle_funded"] = true
				entry["cycle_level"] = int(entry.get("level", 1))
				entry["cycle_amount"] = amount
				# Clear pause if we successfully started the cycle
				if _paused.get(key, false):
					_paused[key] = false
					building_ticked.emit(planet_seed, key)

			var duration := get_cycle_duration(pp, entry, def)
			if is_inf(duration):
				_emit_progress(planet_seed, key)
				continue
			var rate := delta / duration
			var next: float = prev + rate

			if next >= 1.0:
				# ── End-of-cycle production ───────────────────────────────────
				_on_tick_complete(pp, def, key, 0.0, amount, entry)
				_progress[key] = 0.0
				entry["cycle_progress"] = 0.0
				entry["cycle_funded"] = false
				# Spaceport: re-pause after each launch cycle so player must trigger manually
				if def.building_id == "spaceport":
					_user_paused[key] = true
					entry["user_paused"] = true
				building_ticked.emit(planet_seed, key)
			else:
				_progress[key] = next
				entry["cycle_progress"] = next

			_emit_progress(planet_seed, key)

		# Apply stacked-build merges now that iteration is complete
		for entry: Dictionary in pending_merges:
			var merge_idx: int = entry.get("merge_into", -1)
			if merge_idx >= 0 and merge_idx < pp.buildings.size():
				var target: Dictionary = pp.buildings[merge_idx]
				var merge_def := BuildingDef.find(entry.get("building_id", ""))
				if target.get("level", 1) == entry.get("level", 1) and not (merge_def.input_type != BuildingDef.OutputType.NONE and target.get("cycle_funded", false)):
					target["amount"] = target.get("amount", 1) + 1
					pp.remove_building_stack(entry)
			entry.erase("merge_into")

		for c in completed_buildings:
			building_constructed.emit(planet_seed, c.key, c.bid)

func _on_tick_complete(pp: PlanetProgress, def: BuildingDef,
		_key_str: String, _energy: float, amount: int,
		entry: Dictionary) -> void:
	# Skip if building was scrapped before tick completed
	if not pp.buildings.has(entry):
		return
	# Produce output (scaled by amount)
	var mods := PlanetModifier.for_planet(_planet_type(pp.planet_seed))
	var st := get_node("/root/SkillTree")
	if def.logic != null:
		if def.input_type != BuildingDef.OutputType.NONE:
			var cycle_entry := entry.duplicate()
			cycle_entry["level"] = entry.get("cycle_level", entry.get("level", 1))
			cycle_entry["amount"] = entry.get("cycle_amount", amount)
			def.logic.produce(pp, def, int(cycle_entry.amount), mods, cycle_entry, st)
		else:
			def.logic.produce(pp, def, amount, mods, entry, st)

	var poi_lbl: String = entry.get("district_id", "")
	if def.output_type in [BuildingDef.OutputType.RAW_MINERAL, BuildingDef.OutputType.REFINED_MINERAL]:
		if not poi_lbl.is_empty():
			var outputs := get_resource_outputs(pp, entry, def)
			for id: String in outputs:
				var mineral: ResourceData = GameState.known_resources.get(id)
				if mineral != null and float(outputs[id]) > 0.0:
					resource_produced.emit(pp.planet_seed, poi_lbl, "+%.1f" % float(outputs[id]), mineral.display_color, MineralIcon.make(mineral.tier, mineral.display_color))
		return

	var display_val := get_building_output(pp, entry, def)
	var suffix := ""
	var icon_tex: Texture2D = null
	match def.output_type:
		BuildingDef.OutputType.CREDITS:
			suffix = " cr"
		BuildingDef.OutputType.SCIENCE:
			suffix = " sci"
		BuildingDef.OutputType.ENERGY:
			display_val = 0.0

	if display_val > 0.0 and poi_lbl != "":
		var txt := "+%.0f%s" % [display_val, suffix]
		resource_produced.emit(pp.planet_seed, poi_lbl, txt, def.output_color(), icon_tex)


# ── Building Level & Buffs ────────────────────────────────────────────────────

func get_building_level_mult(level: int) -> float:
	return 1.0 + 0.5 * (log(max(1, level)) / log(2.0))

func get_building_consume_mult(level: int) -> float:
	return 1.0 + 0.25 * (log(max(1, level)) / log(2.0))

func get_cycle_duration(pp: PlanetProgress, entry: Dictionary, def: BuildingDef, apply_energy: bool = true) -> float:
	if def.tick_duration <= 0.0:
		return INF
	var st := get_node("/root/SkillTree")
	var buffs := get_district_buffs(pp, entry.get("district_id", ""))
	var mods := PlanetModifier.for_planet(_planet_type(pp.planet_seed))
	var speed: float = _deposit_speed(def, pp.planet_seed, mods) * st.get_global_speed_mult()
	if pp.has_active_building("logistics_center"):
		speed *= 1.20
	match def.output_type:
		BuildingDef.OutputType.RAW_MINERAL:
			speed *= st.get_mine_speed_mult() * float(buffs.mine_speed_mult)
			if def.building_id == "atmospheric_siphon":
				speed *= float(buffs.gas_mining_speed_mult)
		BuildingDef.OutputType.REFINED_MINERAL:
			speed *= st.get_refinery_speed_mult() * float(buffs.refinery_speed_mult)
			if def.building_id == "aerosol_refinery":
				speed *= float(buffs.gas_mining_speed_mult)
		BuildingDef.OutputType.SCIENCE:
			speed *= float(buffs.science_speed_mult)
		BuildingDef.OutputType.CREDITS:
			speed *= st.get_trade_speed_mult() * float(buffs.trade_speed_mult)
	if apply_energy and def.energy_per_tick < 0.0:
		speed *= _global_energy_ratio
	if speed <= 0.0:
		return INF
	var duration: float = entry.get("effective_duration", def.tick_duration)
	if def.output_type == BuildingDef.OutputType.ENERGY and def.input_type != BuildingDef.OutputType.NONE:
		duration *= float(buffs.generator_duration_mult)
		var fuel: ResourceData = GameState.known_resources.get(entry.get("burning_mineral", entry.get("input_mineral", "")))
		if fuel != null:
			duration *= fuel.rarity
	return maxf(0.001, duration / speed)

func get_resource_outputs(pp: PlanetProgress, entry: Dictionary, def: BuildingDef) -> Dictionary:
	var result := {}
	var total := get_building_output(pp, entry, def)
	if def.output_type == BuildingDef.OutputType.REFINED_MINERAL:
		var input: ResourceData = GameState.known_resources.get(entry.get("burning_mineral", entry.get("input_mineral", "")))
		if input != null:
			result[input.processed().resource_id()] = total
		return result
	if def.output_type != BuildingDef.OutputType.RAW_MINERAL:
		return result
	var pd := GameState.get_planet_data(pp.planet_seed)
	if pd == null:
		return result
	var minerals := GameState.get_body_resources_for(pd).get_by_tag(ResourceData.Tag.RAW_MINERAL)
	var target: String = entry.get("target_mineral", "")
	var density_sum := 0.0
	var rng := RandomNumberGenerator.new()
	for mineral: ResourceData in minerals:
		var id := mineral.resource_id()
		if target == id and def.building_id in ["precision_extractor", "quantum_harvester"]:
			return {id: total}
		rng.seed = pd.seed ^ (mineral.rarity * 0x4E3D)
		var density: float = pd.mineral_densities.get(id, pd.deposit_density * rng.randf_range(0.75, 1.25))
		result[id] = maxf(0.0, density)
		density_sum += maxf(0.0, density)
	for id: String in result:
		result[id] = total * float(result[id]) / density_sum if density_sum > 0.0 else 0.0
	return result

func get_building_output(pp: PlanetProgress, entry: Dictionary, def: BuildingDef) -> float:
	var amount: int = entry.get("amount", 1)
	var level: int = entry.get("level", 1)
	if def.input_type != BuildingDef.OutputType.NONE and entry.get("cycle_funded", false):
		amount = mini(amount, int(entry.get("cycle_amount", amount)))
		level = int(entry.get("cycle_level", level))
	var out := def.output_amount * amount * get_building_level_mult(level)
	var buffs := get_district_buffs(pp, entry.get("district_id", ""))
	var st := get_node("/root/SkillTree")
	match def.output_type:
		BuildingDef.OutputType.CREDITS:
			if def.building_id in ["residential", "apartments", "luxury_complex"]:
				out *= st.get_credits_mult() * float(buffs.get(def.building_id + "_mult", 1.0))
			else:
				out *= st.get_trade_output_mult() * float(buffs.trade_output_mult)
		BuildingDef.OutputType.SCIENCE:
			out *= (1.0 + 0.15 * st.get_skill_level("science_income_1") + 0.20 * st.get_skill_level("science_income_2")) * float(buffs.science_output_mult)
		BuildingDef.OutputType.RAW_MINERAL, BuildingDef.OutputType.REFINED_MINERAL:
			out *= st.get_mine_output_mult() * float(buffs.mine_output_mult)
			out *= PlanetModifier.combined(PlanetModifier.for_planet(_planet_type(pp.planet_seed)), PlanetModifier.Effect.MINE_OUTPUT_MULT)
			if def.building_id == "magma_dredge":
				out *= float(buffs.magma_dredge_output_mult)
		BuildingDef.OutputType.ENERGY:
			if def.building_id in ["solar_panel", "solar_matrix"]:
				out *= st.get_solar_mult() * float(buffs.clean_energy_mult) * float(buffs.solar_mult)
			elif def.building_id == "geothermal_plant":
				out *= st.get_generator_output_mult() * float(buffs.clean_energy_mult) * float(buffs.geothermal_mult)
			elif def.input_type != BuildingDef.OutputType.NONE:
				out *= st.get_generator_output_mult()
				if not entry.get("cycle_funded", false):
					out = 0.0
	return out


func get_district_buffs(pp: PlanetProgress, district_id: String) -> Dictionary:
	var buffs := {
		"solar_mult": 1.0,
		"geothermal_mult": 1.0,
		"clean_energy_mult": 1.0,
		"generator_duration_mult": 1.0,
		"mine_output_mult": 1.0,
		"mine_speed_mult": 1.0,
		"refinery_speed_mult": 1.0,
		"mining_energy_cost_mult": 1.0,
		"magma_dredge_output_mult": 1.0,
		"gas_mining_speed_mult": 1.0,
		"residential_mult": 1.0,
		"apartments_mult": 1.0,
		"luxury_complex_mult": 1.0,
		"science_speed_mult": 1.0,
		"science_output_mult": 1.0,
		"trade_speed_mult": 1.0,
		"trade_output_mult": 1.0
	}
	for b in pp.buildings_in_district(district_id):
		if b.get("constructing", false) or b.get("user_paused", false): continue
		var bid = b.get("building_id", "")
		var amt: int = b.get("amount", 1)
		var lv: int = b.get("level", 1)
		var lv_mult := get_building_level_mult(lv)
		
		if bid == "circuit_overloader":
			buffs.solar_mult += 0.03 * amt * lv_mult
		elif bid == "magma_resonator":
			buffs.geothermal_mult += 0.02 * amt * lv_mult
		elif bid == "grid_optimizer":
			buffs.clean_energy_mult += 0.01 * amt * lv_mult
		elif bid == "combustion_stabilizer":
			buffs.generator_duration_mult += 0.05 * amt * lv_mult
		elif bid == "extraction_optimizer":
			buffs.mine_output_mult += 0.05 * amt * lv_mult
		elif bid == "sonic_resonator":
			buffs.mine_speed_mult += 0.05 * amt * lv_mult
		elif bid == "thermal_crusher":
			buffs.refinery_speed_mult += 0.05 * amt * lv_mult
		elif bid == "logistics_hub":
			buffs.mining_energy_cost_mult -= 0.05 * amt * lv_mult
		elif bid == "tectonic_stabilizer":
			buffs.magma_dredge_output_mult += 0.50 * amt * lv_mult
		elif bid == "pressure_funnel":
			buffs.gas_mining_speed_mult += 0.50 * amt * lv_mult
		elif bid == "zero_g_sorter":
			buffs.mine_speed_mult += 0.20 * amt * lv_mult
		elif bid == "culture_center":
			buffs.residential_mult += 0.20 * amt * lv_mult
		elif bid == "recreation_center":
			buffs.apartments_mult += 0.25 * amt * lv_mult
		elif bid == "opera_house":
			buffs.luxury_complex_mult += 0.30 * amt * lv_mult
		elif bid == "library":
			buffs.science_output_mult += 0.35 * amt * lv_mult
		elif bid == "observatory":
			buffs.science_speed_mult += 0.20 * amt * lv_mult
		elif bid == "research_nexus":
			buffs.science_output_mult += 0.30 * amt * lv_mult
		elif bid == "customs_office":
			buffs.trade_output_mult += 0.15 * amt * lv_mult
		elif bid == "logistics_center":
			buffs.trade_speed_mult += 0.10 * amt * lv_mult
		elif bid == "central_bank":
			buffs.trade_output_mult += 0.30 * amt * lv_mult
			
	# Apply Planet-Wide Orbital Support Buffs
	for b in pp.buildings:
		if b.get("constructing", false) or b.get("user_paused", false): continue
		var bid = b.get("building_id", "")
		var amt: int = b.get("amount", 1)
		var lv: int = b.get("level", 1)
		var lv_mult := get_building_level_mult(lv)
		
		if bid == "orbital_mirrors":
			buffs.solar_mult += 0.15 * amt * lv_mult
		elif bid == "orbital_logistics":
			buffs.trade_speed_mult += 0.25 * amt * lv_mult
			buffs.trade_output_mult += 0.25 * amt * lv_mult
		elif bid == "zero_g_nexus":
			buffs.science_output_mult += 0.10 * min(1, amt) * lv_mult
			
	return buffs

## Computes global energy balance and ratio across ALL colonized planets.
## Called once per frame before _tick_all.
func get_building_energy(pp: PlanetProgress, entry: Dictionary, def: BuildingDef) -> float:
	if entry.get("constructing", false) or entry.get("user_paused", false):
		return 0.0
	if def.input_type != BuildingDef.OutputType.NONE and not entry.get("cycle_funded", false):
		return 0.0
	var st := get_node("/root/SkillTree")
	var buffs := get_district_buffs(pp, entry.get("district_id", ""))
	var amount: int = entry.get("amount", 1)
	var level: int = entry.get("level", 1)
	var energy := def.energy_per_tick * amount
	if energy < 0.0:
		var consumption: float = st.get_energy_consume_mult()
		if def.building_id in ["residential", "apartments", "luxury_complex"]:
			consumption -= 0.10 * st.get_skill_level("housing_maintenance")
		elif def.output_type == BuildingDef.OutputType.SCIENCE:
			consumption -= 0.10 * st.get_skill_level("science_maintenance")
		elif def.output_type == BuildingDef.OutputType.CREDITS:
			consumption -= 0.10 * st.get_skill_level("trade_maintenance")
		energy *= get_building_consume_mult(level) * maxf(0.1, consumption)
		if def.output_type in [BuildingDef.OutputType.RAW_MINERAL, BuildingDef.OutputType.REFINED_MINERAL]:
			energy *= maxf(0.1, float(buffs.mining_energy_cost_mult)) * st.get_mining_energy_mult()
		if pp.has_active_building("command_center"):
			energy *= 0.85
	else:
		energy *= get_building_level_mult(level)
	if def.output_type == BuildingDef.OutputType.ENERGY:
		energy += get_building_output(pp, entry, def)
	return energy

func _calc_global_energy() -> void:
	var production := GameState.base_energy()
	var demand := 0.0
	for pp: PlanetProgress in _all_colonies():
		for entry: Dictionary in pp.buildings:
			var def := BuildingDef.find(entry.get("building_id", ""))
			if def == null:
				continue
			var energy := get_building_energy(pp, entry, def)
			production += maxf(0.0, energy)
			demand += maxf(0.0, -energy)
	_global_energy = production - demand
	_global_energy_ratio = 1.0 if demand <= 0.0 else clampf(production / demand, 0.0, 1.0)

func planet_energy_net(pp: PlanetProgress) -> float:
	var total := GameState.base_energy() if pp.planet_seed == GameState.home_planet_seed else 0.0
	for entry: Dictionary in pp.buildings:
		var def := BuildingDef.find(entry.get("building_id", ""))
		if def != null:
			total += get_building_energy(pp, entry, def)
	return total

func _planet_type(planet_seed: int) -> PlanetData.Type:
	var pd := GameState.get_planet_data(planet_seed)
	if pd != null:
		return pd.planet_type
	return PlanetData.Type.TERRAN

func _deposit_speed(def: BuildingDef, planet_seed: int,
		mods: Array[PlanetModifier]) -> float:
	if def.output_type != BuildingDef.OutputType.RAW_MINERAL:
		return 1.0
	var pd := GameState.get_planet_data(planet_seed)
	var br := GameState.get_body_resources_for(pd) if pd != null \
		else GameState.get_body_resources(planet_seed)
	var base: float = clampf(br.avg_power() * 0.4, 0.5, 3.0)
	var planet_mult: float = PlanetModifier.combined(mods, PlanetModifier.Effect.MINE_SPEED_MULT)
	return base * planet_mult

func _all_colonies() -> Array[PlanetProgress]:
	var result: Array[PlanetProgress] = []
	for pp: PlanetProgress in GameState._planet_progress.values():
		if pp.is_colonized:
			result.append(pp)
	return result

func _entry_index(pp: PlanetProgress, entry: Dictionary) -> int:
	for i in pp.buildings.size():
		if pp.buildings[i] == entry:
			return i
	return 0

func _key(planet_seed: int, poi_label: String, uid: String) -> String:
	return "%d:%s:%s" % [planet_seed, poi_label, uid]

func _resource_key(out_type: BuildingDef.OutputType, planet_seed: int,
		entry: Dictionary = {}) -> String:
	var def := BuildingDef.find(entry.get("building_id", ""))
	var tier: int = def.input_tier if def != null else 1
	var tag := ResourceData.Tag.RAW_MINERAL if out_type == BuildingDef.OutputType.RAW_MINERAL else ResourceData.Tag.REFINED_MINERAL
	for id: String in GameState.known_resources:
		var rd: ResourceData = GameState.known_resources[id]
		if rd.tag == tag and rd.tier == tier:
			entry["input_mineral"] = id
			return id
	return ""

func _emit_progress(planet_seed: int, key: String) -> void:
	building_progress_changed.emit(planet_seed, key, _progress.get(key, 0.0))

func _entry_for_key(key: String) -> Dictionary:
	for pp: PlanetProgress in GameState._planet_progress.values():
		for entry: Dictionary in pp.buildings:
			if _key(pp.planet_seed, entry.get("district_id", ""), entry.get("uid", "")) == key:
				return entry
	return {}
