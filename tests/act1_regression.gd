extends Node

# Run only in an isolated project copy with a separate APPDATA directory.
# These are deterministic system fixtures, not a balance playthrough.
var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error("FAIL: " + label)

func near(actual: float, expected: float, label: String) -> void:
	check(absf(actual - expected) < 0.0001, "%s (%.4f / %.4f)" % [label, actual, expected])

func unlock(id: String, level: int = 1) -> void:
	if id not in SkillTree.unlocked_skills:
		SkillTree.unlocked_skills.append(id)
	SkillTree.skill_levels[id] = level
	var bid := id.trim_prefix("unlock_")
	GameState.unlock_building("mine" if bid == "mining" else bid)

func entry(bid: String, district: String, level: int = 1) -> Dictionary:
	return {"building_id": bid, "district_id": district, "level": level, "amount": 1, "uid": str(randi())}

func _ready() -> void:
	if OS.get_environment("VOIDLE_AUDIT") != "1":
		push_error("Use tests/Run-Act1Audit.ps1 to run these fixtures with an isolated save directory.")
		get_tree().quit(2)
		return
	call_deferred("run")

func run() -> void:
	GameState.set_process(false)
	ProductionManager.set_process(false)
	ShipManager.set_process(false)
	TutorialManager.set_process(false)
	var home := GameState.get_home_planet()
	var pp := GameState.get_planet(home.seed)
	pp.buildings.clear()
	pp.level = 4
	pp.recalculate_limits()
	GameState.credits = 100000.0
	GameState.science_points = 100000.0
	var capital := pp.find_district("Capital")
	var mine := POIData.new()
	mine.label = "Test Mine"
	mine.poi_type = POIData.POIType.MINING
	home.custom_pois.append(mine)
	var orbital := POIData.new()
	orbital.label = "Test Orbital"
	orbital.poi_type = POIData.POIType.STATION
	home.custom_pois.append(orbital)
	unlock("unlock_mining", 10)
	unlock("unlock_lab", 10)
	unlock("unlock_solar_panel", 10)
	unlock("unlock_space_station")
	unlock("unlock_spaceport")
	unlock("unlock_refinery", 10)
	unlock("unlock_generator", 5)
	unlock("unlock_orbital_mirrors", 5)
	unlock("unlock_orbital_shipyard", 5)
	unlock("unlock_lunar_observatory", 5)
	unlock("unlock_moon_helium3", 5)

	# Every defined asset must load, every research parent must exist.
	for def: BuildingDef in BuildingDef.all():
		check(def != null, "building resource")
	for id: String in SkillTree.nodes:
		if id == "find_available_star":
			continue # Existing future megastructure placeholder, outside this scope.
		for parent: String in SkillTree.nodes[id].parents:
			check(SkillTree.nodes.has(parent), "research parent " + id + "/" + parent)
	for level in range(1, 11):
		SkillTree.skill_levels["unlock_lab"] = level
		check(SkillTree.get_building_max_level("lab") == level, "University cap " + str(level))
		var lab := entry("lab", capital.label, level)
		var before := GameState.science_points
		BuildingDef.find("lab").logic.produce(pp, BuildingDef.find("lab"), 1, [], lab, SkillTree)
		near(GameState.science_points - before, ProductionManager.get_building_output(pp, lab, BuildingDef.find("lab")), "science display equals inventory " + str(level))

	# New level-one purchases never merge into upgraded buildings.
	var lab_def := BuildingDef.find("lab")
	for level in range(1, 6):
		unlock("science_income_1", level)
		near(ProductionManager.get_building_output(pp, entry("lab", capital.label), lab_def), 2.0 * (1.0 + 0.15 * level), "science passive " + str(level))
		unlock("housing_income_1", level)
		near(SkillTree.get_credits_mult(), 1.0 + 0.15 * level, "housing passive " + str(level))
		unlock("generator_efficiency", level)
		near(SkillTree.get_generator_output_mult(), 1.0 + 0.05 * level, "generator passive " + str(level))
	for id: String in ["science_income_1", "housing_income_1", "generator_efficiency"]:
		SkillTree.unlocked_skills.erase(id)
		SkillTree.skill_levels.erase(id)
	near(ProductionManager.get_building_output(pp, entry("lab", capital.label, 2), lab_def), 3.0, "University level two produces three science")
	near(ProductionManager.get_building_energy(pp, entry("lab", capital.label, 2), lab_def), -2.5, "University level two consumes 2.5 energy")
	var initial_money := GameState.credits
	var upgrading_lab := entry("lab", capital.label)
	pp.buildings = [upgrading_lab]
	SkillTree.skill_levels["unlock_lab"] = 1
	check(not pp.upgrade_building(upgrading_lab), "research cap enforced by transaction")
	near(GameState.credits, initial_money, "rejected building upgrade free of charge")
	SkillTree.skill_levels["unlock_lab"] = 2
	check(pp.upgrade_building(upgrading_lab), "researched building level purchasable")
	near(GameState.credits, initial_money - 200.0, "building upgrade exact price")
	SkillTree.skill_levels["unlock_lab"] = 10
	pp.buildings = [entry("lab", capital.label, 3)]
	check(pp.build_in_district(capital, "lab"), "build university")
	check(not pp.buildings.back().has("merge_into"), "no free level through auto merge")
	pp.buildings.clear()
	pp.buildings.append(entry("solar_panel", capital.label))
	pp.buildings.append(entry("residential", capital.label))
	pp.buildings.append(entry("lab", capital.label))
	ProductionManager._calc_global_energy()
	near(ProductionManager.get_energy_ratio(), 1.0, "starting economy full speed")
	near(ProductionManager.get_global_energy(), 2.0, "starting surplus")
	check(not pp.stack_building_unchecked(capital.label, "lab", pp.buildings[2]), "stack cannot exceed slots")
	pp.buildings.clear()
	var solar := entry("solar_panel", capital.label, 4)
	pp.buildings.append(solar)
	near(ProductionManager.get_building_energy(pp, solar, BuildingDef.find("solar_panel")), 4.0, "solar level four")
	var mirrors := entry("orbital_mirrors", orbital.label)
	mirrors["constructing"] = true
	pp.buildings.append(mirrors)
	ProductionManager._tick_all(100.0)
	check(not mirrors.get("constructing", false), "zero-cycle support construction completes")
	near(ProductionManager.get_building_energy(pp, solar, BuildingDef.find("solar_panel")), 4.6, "orbital mirror bonus")
	mirrors["user_paused"] = true
	near(ProductionManager.get_building_energy(pp, solar, BuildingDef.find("solar_panel")), 4.0, "paused orbital has no bonus")

	# Atomic transactions: failed purchases preserve all resources.
	pp.buildings.clear()
	pp.level = 3
	GameState.global_resources.clear()
	var money := GameState.credits
	check(not pp.start_planet_upgrade(), "missing minerals reject planet upgrade")
	near(GameState.credits, money, "failed planet upgrade keeps credits")
	var ore := ResourceData.generate(home.seed, ResourceData.Tag.RAW_MINERAL, 1, 1)
	GameState.known_resources[ore.resource_id()] = ore
	GameState.add_resource(ore.resource_id(), 1000.0)
	check(pp.start_planet_upgrade(), "planet upgrade accepts full payment")
	near(GameState.get_resource(ore.resource_id()), 600.0, "planet deducts exact ore")
	check(not pp.start_planet_upgrade(), "planet upgrade cannot be bought twice")
	pp.is_upgrading = false
	pp.level = 4

	# Paid input is consumed once and yields a real refined resource.
	var refinery := entry("refinery", mine.label)
	refinery["input_mineral"] = ore.resource_id()
	pp.buildings = [refinery]
	ProductionManager._calc_global_energy()
	var stock := GameState.get_resource(ore.resource_id())
	ProductionManager._tick_all(0.01)
	near(GameState.get_resource(ore.resource_id()), stock - 15.0, "refinery pays once")
	refinery["user_paused"] = true
	ProductionManager._tick_all(1.0)
	near(GameState.get_resource(ore.resource_id()), stock - 15.0, "paused refinery does not repay")
	refinery["user_paused"] = false
	ProductionManager._tick_all(40.0)
	var ingot := ore.processed()
	check(GameState.known_resources.has(ingot.resource_id()), "refined resource registered")
	near(GameState.get_resource(ingot.resource_id()), ProductionManager.get_building_output(pp, refinery, BuildingDef.find("refinery")), "refinery actual output")

	# Moon district compatibility, uniqueness, station identity and access gates.
	var moon: PlanetData = home.moons[0]
	var moon_pp := GameState.get_planet(moon.seed)
	moon_pp.is_colonized = true
	moon_pp.level = 2
	GameState.finish_colonization(moon.seed)
	var outpost: POIData = moon.custom_pois[0]
	check(moon_pp.build_in_district(outpost, "lunar_observatory"), "Moon observatory placeable in outpost")
	check(not moon_pp.build_in_district(outpost, "lunar_observatory"), "observatory district limit")
	check(not pp.build_in_district(capital, "lunar_observatory"), "Moon observatory cannot be placed on home")
	GameState.ensure_station_ship(home.seed, orbital)
	GameState.ensure_station_ship(home.seed, orbital)
	var station_count := 0
	var station: ShipData
	for ship: ShipData in ShipManager.ships_for(home.seed):
		if ship.ship_name == orbital.label:
			station_count += 1
			station = ship
	check(station_count == 1, "station registration idempotent")
	check(not SkillTree.requirement_text("unlock_planetary_colonization").is_empty(), "unfinished observatory blocks solar access")
	var moon_lab: Dictionary = moon_pp.buildings[0]
	moon_lab["constructing"] = false
	moon_lab["user_paused"] = true
	check(not SkillTree.requirement_text("unlock_planetary_colonization").is_empty(), "paused observatory blocks solar access")
	moon_lab["user_paused"] = false
	ProductionManager._calc_global_energy()
	check(SkillTree.requirement_text("unlock_planetary_colonization").is_empty(), "operating lunar observatory permits final research")

	# Five paid shipyard levels all have a concrete effect.
	var yard := entry("orbital_shipyard", orbital.label)
	pp.buildings = [yard, entry("spaceport", capital.label)]
	for level in range(1, 6):
		yard["level"] = level
		near(GameState.ship_cost(home.seed).credits, 600.0 * (0.8 - 0.05 * (level - 1)), "shipyard level " + str(level))
	yard["user_paused"] = true
	near(GameState.ship_cost(home.seed).credits, 600.0, "paused shipyard no discount")
	GameState.add_resource(ingot.resource_id(), 100.0)
	check(GameState.build_colony_ship(home.seed), "colony ship order available")
	check(not GameState.build_colony_ship(home.seed), "duplicate assembly rejected")
	GameState._tick_colony_ship_orders(30.0)
	check(GameState.arrived_colony_ship(home.seed) != null, "colony ship completes in orbit")
	unlock("unlock_moon")
	GameState.moon_unlocked = true
	moon_pp.is_colonized = false
	check(GameState.send_colony_ship(moon.seed), "send to home Moon")
	check(not GameState.send_colony_ship(moon.seed), "duplicate Moon expedition rejected")
	check(not GameState.colonize_planet(moon.seed), "cannot settle before arrival")
	ShipManager._process(60.0)
	check(GameState.colonize_planet(moon.seed), "arrived colony ship permits settlement")
	check(GameState.arrived_colony_ship(moon.seed) == null, "settlement consumes colony ship")

	# Actual panel construction catches runtime-only property and identity bugs.
	pp.buildings = [entry("lab", capital.label, 2), yard]
	SkillTree.skill_levels["unlock_lab"] = 10
	var view: Node = load("res://scenes/planetary/PlanetaryView.tscn").instantiate()
	add_child(view)
	view._build_district_panel(capital, home)
	var before_count := pp.buildings.size()
	view._open_station_district(station, view)
	check(pp.buildings.size() == before_count, "opening station preserves buildings")
	var tree_view := SkillTreeView.new()
	add_child(tree_view)
	tree_view.queue_free()
	view.queue_free()
	await get_tree().process_frame
	# Save round trip preserves money, queues, input state and processed names.
	var saved_money := GameState.credits
	var saved_science := GameState.science_points
	var paused_solar := entry("solar_panel", capital.label, 3)
	paused_solar["user_paused"] = true
	var saved_refinery := entry("refinery", mine.label, 2)
	saved_refinery["burning_mineral"] = ore.resource_id()
	saved_refinery["cycle_funded"] = false
	saved_refinery["cycle_progress"] = 0.0
	pp.buildings = [paused_solar, saved_refinery]
	GameState.colony_ship_orders[str(home.seed)] = 17.0
	GameState.save()
	GameState.credits = 1.0
	GameState.science_points = 1.0
	check(GameState.load_save(), "saved game loads")
	GameState._bootstrap_world()
	await get_tree().process_frame
	near(GameState.credits, saved_money, "load preserves credits")
	near(GameState.science_points, saved_science, "load preserves science")
	near(GameState.colony_ship_orders[str(home.seed)], 17.0, "load preserves assembly timer")
	var restored := GameState.get_planet(home.seed)
	check(restored.buildings[0].get("user_paused", false), "pause persists")
	check(not restored.buildings[1].get("cycle_funded", true), "load does not grant a free input cycle")
	check(GameState.known_resources[ingot.resource_id()].unique_name == ingot.unique_name, "refined name survives save")
	print("ACT1_REGRESSION: %d checks, %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
