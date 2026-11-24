class_name ColonyTutorial
extends RefCounted

# New guided saves use this course. The old Guide still reads older saves.
const FLAG := "colony_tutorial"
const START_RULES := "colony_start_rules"
const FIRST_DIG := "vesyn_toppled_stones"
const CITY_HOUSING := 200
const CITY_LV2_HOUSING := 10000
const STEPS := [
	"turn", "zoom", "city", "survey", "residential", "housing", "comms", "energy", "solar",
	"capital_2", "government", "advisor", "inbox", "housing_fill", "solar_fill", "commercial",
	"market", "residential_2", "housing_five", "city_2", "energy_2", "solar_four",
	"science", "lab", "mining", "production", "quarry", "overflow", "warehouse", "civilization",
	"processing", "factory", "first_goods", "wind", "turbine", "habitat_research", "remove_house",
	"habitat", "capital_3", "trade", "sell", "buy", "bureau", "dig", "dig_result", "bolo",
]
const DISTRICTS := {
	"city": DistrictDef.Type.CITY, "residential": DistrictDef.Type.RESIDENTIAL,
	"energy": DistrictDef.Type.GENERATOR, "commercial": DistrictDef.Type.COMMERCIAL,
	"science": DistrictDef.Type.SCIENCE, "production": DistrictDef.Type.MINING,
}
const BUILDINGS := {
	"survey": ["survey_office", "city", 1], "housing": ["low_rise_housing", "residential", 1],
	"comms": ["communications_station", "city", 1], "solar": ["solar_panel", "energy", 1],
	"government": ["government_building", "city", 1],
	"housing_fill": ["low_rise_housing", "residential", 3], "solar_fill": ["solar_panel", "energy", 3],
	"market": ["commercial", "commercial", 1], "housing_five": ["low_rise_housing", "residential", 5],
	"solar_four": ["solar_panel", "energy", 4], "lab": ["field_observatory", "science", 1],
	"quarry": ["surface_quarry", "production", 1], "warehouse": ["warehouse", "production", 1],
	"factory": ["refinery", "production", 1], "turbine": ["wind_turbine", "energy", 1],
	"habitat": ["residential", "residential", 1], "bureau": ["archaeology_bureau", "city", 1],
}
const DISTRICT_LEVELS := {"capital_2": ["city", 2], "residential_2": ["residential", 2],
	"energy_2": ["energy", 2], "capital_3": ["city", 3]}
const RESEARCH := {"mining": "start_production", "civilization": "civilization_studies",
	"processing": "processing_basics", "wind": "wind_power", "habitat_research": "neighborhood_building",
	"trade": "trade_access"}
const LENSES := {"residential": "residential", "energy": "energy", "commercial": "commercial",
	"science": "science", "production": "production"}
const LINES := {
	"turn": "This is the surface feed from I-330. Hold the right mouse button and drag to turn the globe. WASD works here too.",
	"zoom": "Roll the wheel to bring the landing area closer. I'll put our survey mark on the map.",
	"city": "Found the City at the marked site and give it a name.",
	"survey": "Build a Survey Office in the Capital. We need a surface survey before placing the other districts.",
	"residential": "Open the Population lens and place a Residential District at the marked site.",
	"housing": "The population indicator shows our housing and available workers. Open the district and build one Low-rise Housing.",
	"comms": "Build a Communications Station in the other Capital slot. We can start receiving the news.",
	"energy": "The transmitter has put the grid in deficit. Open the Energy lens and build at the marked site. The wind here will be useful later.",
	"solar": "Build a Solar Array. Check the power indicator after it starts supplying the grid.",
	"capital_2": "We need room for a government. Upgrade the Capital District to open a third building slot.",
	"government": "Build the Government Building in the new slot. Then you can appoint an advisor.",
	"advisor": "You have heard from both of us. Choose who will advise you.",
	"inbox": "Open Notifications. If you miss something I tell you, look there for issues you can act on.",
	"housing_fill": "Our workers have run out of housing and output has fallen. Follow the population warning and fill the two empty housing slots.",
	"solar_fill": "The new homes have put the grid in deficit. Follow the energy warning and fill both Solar Array slots.",
	"commercial": "Follow the City notification. Select the Commercial lens and use the City's last district slot for Commerce.",
	"market": "Open the Commercial District and build a Market. Compare its monthly income with the district's own income.",
	"residential_2": "We are short on housing again. A district needs a road to a neighbour at the next level. The Capital is already level 2. Upgrade Residential.",
	"housing_five": "Fill both new housing slots. Check available workers once the homes are ready.",
	"city_2": "We need a Science District. Look at the City panel: all three district slots are full. Upgrade the City to make room.",
	"energy_2": "The labs and the refinery will draw from this grid too. Upgrade the Energy District. It has a road to the level 2 Capital.",
	"solar_four": "Build one more Solar Array. Leave the fifth slot free for a stronger generator.",
	"science": "Use the Science lens and place the Science District.",
	"lab": "Build a Field Lab. Its Science pays for research in the Upgrade Tree.",
	"mining": "Buy Mining Operations in the Upgrade Tree. Look at the new nodes and hover a price before closing the tree. Each purchase raises the price of other research.",
	"production": "Open the Production lens and establish the Production District at the marked site.",
	"quarry": "Build a Surface Quarry to extract Ferrite. The first delivery will show how much stock we can hold.",
	"overflow": "The first load is coming in. Check how much the temporary store accepts and how much spills.",
	"warehouse": "Our Ferrite store has filled up. Build a Warehouse and inspect the new storage limits.",
	"civilization": "We are still a Type 0 civilization. To establish ourselves on this planet and reach beyond it, begin Civilization Studies at the foot of the space branch.",
	"processing": "Research Basic Processing so the quarry's Ferrite can be turned into Goods.",
	"factory": "Build a Goods Factory. The start-up supplies include enough Ferrite for its first production cycle.",
	"first_goods": "Watch the factory's first cycle. It consumes four Ferrite and adds Goods to the stock.",
	"wind": "The factory has overloaded the grid. Research Wind Power. We picked a site that can take a turbine.",
	"turbine": "Build the Wind Turbine. Its terrain requirement lets it use cheaper construction materials. It consumes one Goods per month.",
	"habitat_research": "We need more workers for the bureau. Research Habitat Blocks so we can fit more housing in the same district.",
	"remove_house": "Use Remove on one Low-rise Housing. Check its refund before opening the new slot.",
	"habitat": "Build a Habitat Block in the empty slot. Its housing rises by five thousand and it needs one Goods per month.",
	"capital_3": "Upgrade the Capital District to level 3. We need the fourth slot for the Archaeology Bureau.",
	"trade": "The bureau needs Goods we cannot spare yet. Research Trade Access so we can sell Ferrite and buy what we need.",
	"sell": "Open Trade and sell fifty Ferrite. Keep a little back for the factory.",
	"buy": "Use the sale proceeds to buy Goods for the bureau. Complete the purchase yourself in Trade.",
	"bureau": "Build the Archaeology Bureau with the Goods you bought. I'll show you the site once it opens.",
	"dig": "Follow the excavation notification to The Toppled Stones and start the dig.",
	"dig_result": "Return to the site through Notifications when the excavation is ready. Read the report and decide what to do with the find.",
	"bolo": "Bolo can now advise us. Open Government, choose Bolo and confirm the paid handover.",
}

static func active() -> bool:
	return bool(GameState.story_flags.get(FLAG, false)) and GameState.tutorial_step != "done" \
		and not GameState.showcase_mode

static func building_available(id: String) -> bool:
	return id not in ["survey_office", "communications_station", "government_building", "archaeology_bureau"] \
		or uses_start_rules()

static func uses_start_rules() -> bool:
	return bool(GameState.story_flags.get(START_RULES, false) or GameState.story_flags.get(FLAG, false))

static func facility_ready(id: String) -> bool:
	return not uses_start_rules() or GameState.has_finished_building(GameState.home_planet_seed, id)

static func seed_label(seed: int) -> String:
	if seed == GameState.home_planet_seed and GameState.story_flags.get(FLAG, false):
		return SessionPrep.TUTORIAL_SEED_CODE
	return str(seed)

static func city_housing(pd: PlanetData, poi: POIData, pp: PlanetProgress) -> int:
	if GameState.story_flags.get(FLAG, false) and pd.seed == GameState.home_planet_seed and poi == host(pd, "city"):
		return CITY_LV2_HOUSING if Leveling.city_level(pp, poi) >= 2 else CITY_HOUSING
	return Balance.cfg.city_base_pop

static func index() -> int:
	return clampi(int(GameState.story_flags.get("course:index", 0)), 0, STEPS.size() - 1)

static func step() -> String:
	return STEPS[index()]

static func reached(id: String) -> bool:
	return not active() or index() >= STEPS.find(id)

static func acknowledged() -> bool:
	return bool(GameState.story_flags.get("course:confirmed", false))

static func note(id: String) -> void:
	if active() and step() == id and acknowledged():
		GameState.story_flags["course:action:" + id] = true

static func _noted(id: String) -> bool:
	return bool(GameState.story_flags.get("course:action:" + id, false))

static func lens_open(role: String) -> bool:
	if role.is_empty():
		return true
	if not facility_ready("survey_office"):
		return false
	return not active() or not LENSES.values().has(role) or reached(String(LENSES.find_key(role)))

static func note_lens(role: String) -> bool:
	if not active() or not acknowledged() or LENSES.get(step(), "") != role or role.is_empty():
		return false
	var key := "course:lens:" + role
	if GameState.story_flags.has(key):
		return false
	GameState.story_flags[key] = true
	return true

static func permits_district(id: int) -> bool:
	if not active():
		return true
	var current := step()
	if not acknowledged() or int(DISTRICTS.get(current, -1)) != id:
		return false
	if LENSES.has(current) and not GameState.story_flags.has("course:lens:" + String(LENSES[current])):
		return false
	return current != "commercial" or _noted("commercial")

static func permits_research(id: String) -> bool:
	return not active() or (acknowledged() and String(RESEARCH.get(step(), "")) == id)

static func research_visible(id: String) -> bool:
	if not active():
		return true
	if id == "root" or id == RESEARCH.get(step(), "") or SkillTree.is_unlocked(id):
		return true
	# After the first purchase, existing tree rules reveal the connections and new prices.
	return SkillTree.is_unlocked("start_production")

static func allows_ui(which: String) -> bool:
	if not active():
		if which == "companions":
			return facility_ready("government_building")
		if which == "inbox" or which == "log":
			return facility_ready("communications_station")
		return true
	match which:
		"tree": return reached("mining")
		"trade": return reached("sell")
		"companions": return reached("advisor")
		"inbox": return reached("inbox")
		"log": return reached("bolo")
	return false

static func resource_open(id: String) -> bool:
	if not active():
		return true
	match id:
		"credits": return true
		"population": return reached("housing")
		"energy": return reached("energy")
		"science": return reached("lab")
		"raw": return reached("quarry")
		"goods": return reached("factory")
	return false

static func host(pd: PlanetData, kind: String) -> POIData:
	if pd == null:
		return null
	for p: POIData in pd.custom_pois:
		if p.is_orbital():
			continue
		if p.is_city() and kind == "city":
			return p
		var def := ProductionManager.district_def(p)
		if def != null and def.id == DISTRICTS.get(kind, -1):
			return p
	return null

static func count(pp: PlanetProgress, poi: POIData, id: String, finished := false) -> int:
	if pp == null or poi == null:
		return 0
	var n := 0
	for b: Dictionary in pp.buildings_in_district(poi.label):
		if b.get("building_id", "") == id and (not finished or not b.get("constructing", false)):
			n += int(b.get("amount", 1))
	return n

static func build_limit(pd: PlanetData, poi: POIData, id: String) -> int:
	if not active():
		return 999
	var spec: Array = BUILDINGS.get(step(), [])
	if not acknowledged() or spec.is_empty() or spec[0] != id or poi == null or poi != host(pd, spec[1]):
		return 0
	if step() in ["housing_fill", "solar_fill"] and not _noted(step()):
		return 0
	return maxi(0, int(spec[2]) - count(GameState.get_planet(pd.seed), poi, id))

static func permits_remove(entry: Dictionary) -> bool:
	return not active() or (step() == "remove_house" and acknowledged() and not _noted("remove_house") \
		and entry.get("building_id", "") == "low_rise_housing" and not entry.get("constructing", false))

static func permits_level(pd: PlanetData, poi: POIData, city_level: bool) -> bool:
	if not active():
		return true
	if not acknowledged():
		return false
	var pp := GameState.get_planet(pd.seed)
	if city_level:
		return step() == "city_2" and Leveling.city_level(pp, poi) == 1
	var spec: Array = DISTRICT_LEVELS.get(step(), [])
	return not spec.is_empty() and poi == host(pd, spec[0]) \
		and int(pp.district_levels.get(poi.label, 1)) < int(spec[1])

static func trade_limit(id: String, selling: bool, quantity: float) -> float:
	if not active():
		return quantity
	if not acknowledged():
		return 0.0
	if step() == "sell" and selling and id == "ferrite":
		return minf(quantity, maxf(0.0, 50.0 - _trade_amount("sell", id)))
	if step() == "buy" and id == "goods":
		if not selling:
			return minf(quantity, _goods_to_buy())
		if Trade.room(id) < 1.0 and _trade_amount("buy", id) <= 0.0:
			return minf(quantity, 2.0)
	return 0.0

static func _trade_amount(kind: String, id: String) -> float:
	var total := 0.0
	for e: Dictionary in GameState.trade_log:
		if e.get("kind") == kind and e.get("id") == id and e.get("source") == "manual":
			total += float(e.get("qty", 0.0))
	return total

static func _goods_to_buy() -> float:
	var bought := _trade_amount("buy", "goods")
	return maxf(ceilf(27.0 - Trade.stock("goods")), 1.0 if bought <= 0.0 else 0.0)

static func _building_cost(pd: PlanetData, pp: PlanetProgress, s: Array) -> Dictionary:
	var poi := host(pd, s[1])
	var b := BuildingDef.find(s[0])
	if poi == null or b == null:
		return {}
	var cost := Economy.building_full_cost(pp, b, poi.label, maxi(0, int(s[2]) - count(pp, poi, s[0])))
	if s[0] == "wind_turbine":
		cost["goods"] = 1.0
	elif s[0] == "residential":
		cost["goods"] = float(cost.get("goods", 0.0)) + 2.0
	elif s[0] == "refinery":
		cost["ferrite"] = float(cost.get("ferrite", 0.0)) + 4.0
	return cost

static func _cost(pd: PlanetData, pp: PlanetProgress, id: String) -> Dictionary:
	if BUILDINGS.has(id):
		return _building_cost(pd, pp, BUILDINGS[id])
	if DISTRICTS.has(id):
		var parent := host(pd, "city")
		return DistrictDef.placement_full_cost(DistrictDef.find(DISTRICTS[id]), pd, parent.label if parent else "")
	if DISTRICT_LEVELS.has(id):
		return {"credits": Leveling.district_level_credits(int(DISTRICT_LEVELS[id][1]) - 1)}
	if RESEARCH.has(id):
		return {"science": SkillTree.get_next_cost(RESEARCH[id])}
	match id:
		"city_2": return {"credits": Leveling.city_level_credits(2)}
		"sell": return {"ferrite": 54.0}
		"buy": return {"credits": Trade.buy_cost("goods", _goods_to_buy())}
		"first_goods": return {} if Trade.stock("goods") > 0.0 else {"ferrite": 4.0}
		"dig":
			var site := Excavations.find_site(FIRST_DIG)
			return Excavations.cost_of(site) if site != null else {}
		"bolo": return {"credits": GameState.early_appoint_cost()}
	return {}

static func _missing(cost: Dictionary) -> Dictionary:
	var short := {}
	for id: String in cost:
		var gap := float(cost[id]) - Economy.payable_amount(id)
		if gap > 0.0001:
			short[id] = gap
	return short

static func _done(pd: PlanetData, pp: PlanetProgress, id: String) -> bool:
	if BUILDINGS.has(id):
		var s: Array = BUILDINGS[id]
		return count(pp, host(pd, s[1]), s[0], true) >= int(s[2])
	if DISTRICTS.has(id):
		var poi := host(pd, id)
		return poi != null and not poi.constructing
	if DISTRICT_LEVELS.has(id):
		var s: Array = DISTRICT_LEVELS[id]
		var poi := host(pd, s[0])
		return poi != null and int(pp.district_levels.get(poi.label, 1)) >= int(s[1])
	if RESEARCH.has(id):
		return SkillTree.is_unlocked(RESEARCH[id])
	match id:
		"city_2":
			var city := host(pd, "city")
			return city != null and Leveling.city_level(pp, city) >= 2
		"advisor": return not GameState.active_advisor.is_empty()
		"first_goods": return Trade.stock("goods") >= 1.0
		"sell": return _trade_amount("sell", "ferrite") >= 50.0
		"buy": return _trade_amount("buy", "goods") > 0.0 and Trade.stock("goods") >= 27.0
		"dig": return GameState.excavations_digging.has(FIRST_DIG) or Excavations.is_done(FIRST_DIG)
		"dig_result": return Excavations.is_done(FIRST_DIG) and GameState.unlocked_advisors.has("bolo")
		"bolo": return GameState.active_advisor == "bolo"
	return _noted(id)

static func tick(view: Node) -> void:
	if not active() or not is_instance_valid(view) or not view.has_method("_maybe_require_first_city") \
			or Narrative.is_busy() or view.get_tree().paused:
		return
	var pd := GameState.get_home_planet()
	if pd == null:
		return
	var pp := GameState.get_planet(pd.seed)
	var id := step()
	if acknowledged():
		if _done(pd, pp, id):
			if id == "mining" and SkillTreeView.is_open:
				return
			if id == "comms":
				NewsFeed.post("Surface station online. The first transmission has been received.", NewsFeed.Kind.EVENT)
			if id == "bolo":
				for event: String in ["city_founded", "building_completed", "research_completed", "excavation_ready"]:
					GameState.story_flags["bark:" + event] = true
				GameState.tutorial_step = "done"
				SettingsManager.tutorial_ever_done = true
				SettingsManager.save_settings()
				GameState._complete_advisor_roster()
				NewsFeed.post("The colony is yours to lead.", NewsFeed.Kind.EVENT)
			else:
				GameState.story_flags["course:index"] = index() + 1
				GameState.story_flags["course:confirmed"] = false
			if id == "buy" and TradePanel.is_open:
				HUDManager.toggle_trade_panel()
			if RESEARCH.has(id) and SkillTreeView.is_open:
				HUDManager._try_close_skill_tree()
			view.call("_refresh_colony_course")
			GameState.save()
			return
		_open_action(view, id)
		return
	var speaker := ""
	if GameState.active_advisor.is_empty():
		speaker = "Mother Superior" if index() % 2 == 0 else "High Father"
	var lines := [[speaker, LINES[id]]]
	if id == "buy":
		lines.append([speaker, "If the Goods store is full, sell two to make room for the order."])
	var short := _missing(_cost(pd, pp, id))
	if not short.is_empty():
		lines.append([speaker, _supply_line(id) + "\n" + Narrative.amounts_text(short)])
	Narrative.play("", "colony_tutorial", {"id": "course:" + id, "lines": lines, "once": false,
		"on_done": func(_exit: String) -> void:
			if not active() or step() != id:
				return
			var supplies := _missing(_cost(pd, pp, id))
			for resource: String in supplies:
				Economy.add(resource, float(supplies[resource]))
			if not supplies.is_empty():
				Narrative.log_event("Tutorial supplies: " + Narrative.amounts_text(supplies))
			GameState.story_flags["course:confirmed"] = true
			GameState.save()
			_open_action(view, id)
			_focus_action(view, pd, id)})

static func _supply_line(id: String) -> String:
	if id == "factory":
		return "The first factory needs construction supplies and enough ore for a trial run. I've set aside the missing stock."
	if id == "buy":
		return "The Ferrite sale covered part of this order. The colony's supply budget will cover the difference."
	if id == "bolo":
		return "The treasury can cover the remainder of the handover fee."
	if RESEARCH.has(id):
		return "The survey archive has the research data we're missing. I'll release it to the lab."
	if BUILDINGS.has(id) or DISTRICTS.has(id) or DISTRICT_LEVELS.has(id) or id == "city_2":
		return "I've approved the supplies missing from this construction order."
	return "I've approved the supplies needed for this assignment."

static func _focus_action(view: Node, pd: PlanetData, id: String) -> void:
	if not is_instance_valid(view):
		return
	if id in ["housing_fill", "solar_fill", "commercial"]:
		Inbox.open()
		return
	var poi: POIData
	if BUILDINGS.has(id):
		poi = host(pd, BUILDINGS[id][1])
	elif DISTRICT_LEVELS.has(id):
		poi = host(pd, DISTRICT_LEVELS[id][0])
	elif DISTRICTS.has(id) or id == "city_2":
		poi = host(pd, "city")
	if poi != null:
		view.call("_open_tutorial_district", poi.label, BUILDINGS.has(id) or DISTRICT_LEVELS.has(id))
	if id == "dig" or id == "dig_result":
		Inbox.open()

static func _open_action(view: Node, id: String) -> void:
	if not is_instance_valid(view):
		return
	match id:
		"city": view.call("_maybe_require_first_city")
		"advisor": view.call("_choose_tutorial_advisor")
		"overflow":
			if not _noted("overflow"):
				var before := Trade.stock("ferrite")
				var delivery := maxf(2.0, 22.0 - before)
				GameState.add_resource("ferrite", delivery)
				var lost := before + delivery - Trade.stock("ferrite")
				NewsFeed.post("Ferrite store full. %s Ferrite did not fit." % Economy.fmt(lost), NewsFeed.Kind.EVENT)
				note("overflow")

static func notifications() -> Array:
	if not active() or not reached("inbox"):
		return []
	var pd := GameState.get_home_planet()
	if pd == null:
		return []
	var pp := GameState.get_planet(pd.seed)
	var rows: Array = []
	var housing := host(pd, "residential")
	var energy := host(pd, "energy")
	var city := host(pd, "city")
	if Economy.free_population(pd, pp) < 0 and housing != null:
		rows.append(_notification_row("population", "population", "Housing is short. Output has fallen.",
			"Open Residential to add housing.", housing))
	var power := ProductionManager.get_global_energy_split()
	if power.y > power.x + 0.001 and energy != null:
		rows.append(_notification_row("energy", "energy", "Energy is short", "Open the Energy District.", energy))
	if energy != null and not reached("commercial") and pp.slots_used_in_district(energy.label) < 3:
		rows.append(_notification_row("energy_slot", "energy", "Energy District has empty building slots", "Add more Solar Arrays.", energy))
	if housing != null and not reached("solar_fill") and pp.slots_used_in_district(housing.label) < 3:
		rows.append(_notification_row("housing_slot", "population", "Residential has empty building slots", "Add more homes.", housing))
	if city != null and not reached("market") and Leveling.city_district_count(pd, city) < 3:
		rows.append(_notification_row("city_slot", "city", "The City has room for a district", "Open the City to place Commerce.", city))
	return rows

static func _notification_row(id: String, icon: String, title: String, body: String, poi: POIData) -> Dictionary:
	return {"id": "course:" + id, "kind": "warn", "icon": icon, "title": title, "text": body,
		"act": {"course": id, "district": poi.label}}

static func allows_notification(id: String) -> bool:
	match step():
		"housing_fill": return id in ["population", "housing_slot"]
		"solar_fill": return id in ["energy", "energy_slot"]
		"commercial": return id == "city_slot"
	return true
