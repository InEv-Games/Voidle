## SkillTree — Autoload singleton: the research graph, what the player has
## bought, and the modifiers those purchases grant.
##
## Act I layout (the demo): a central Ascent spine climbs from the home world to
## the Moon — Rocketry → Orbital Assembly → Orbital Shipyard → Lunar Program —
## and five district branches spread around the core (Energy right, Industry
## left, Science down-left, Habitation down-right, Commerce down). Key nodes are
## also gated by planet milestones (`gate`) so a pile of Science alone can't
## rush the player to orbit. `act2` nodes are teasers: visible, never buyable.
extends Node

signal skill_unlocked(id: String)

## Nodes every new game starts with.
const DEFAULT_SKILLS: Array[String] = ["unlock_solar_panel", "unlock_residential", "unlock_lab", "unlock_commercial"]

# Global set of purchased/unlocked skill IDs
var unlocked_skills: Array[String] = ["root", "unlock_solar_panel", "unlock_residential", "unlock_lab", "unlock_commercial"]

# Dictionary for upgrade levels (for multi-level upgrades)
# format: { skill_id: current_level_int }
var skill_levels: Dictionary = {
	"unlock_solar_panel": 1,
	"unlock_residential": 1,
	"unlock_lab": 1,
	"unlock_commercial": 1
}

enum NodeShape { HEXAGON, DIAMOND, CIRCLE }

# Definitions of all nodes in the skill tree graph
class SkillNode:
	var id: String
	var name: String
	var description: String
	var cost: float
	var pos: Vector2
	var parents: Array[String]
	var tier: int
	var effect_desc: String
	var max_level: int # 1 = single purchase, >1 = leveled upgrade
	var shape: NodeShape
	## core / ascent / energy / industry / science / habitation / commerce
	var branch: String = "core"
	## Buildings this node unlocks.
	var grants: Array[String] = []
	## Milestones needed before it can be bought (see gate_block).
	var gate: Dictionary = {}
	## Act II teaser: shown, never purchasable in the demo.
	var act2: bool = false

	func _init(p_id: String, p_name: String, p_desc: String, p_cost: float, p_pos: Vector2, p_parents: Array[String], p_tier: int, p_eff: String, p_max_lv: int = 1, p_shape: NodeShape = NodeShape.HEXAGON) -> void:
		id = p_id
		name = p_name
		description = p_desc
		cost = p_cost
		pos = p_pos
		parents = p_parents
		tier = p_tier
		effect_desc = p_eff
		max_level = p_max_lv
		shape = p_shape

# The upgrade graph structure
var nodes: Dictionary = {}
## building id -> node id that grants it
var _grant_of: Dictionary = {}

func _init() -> void:
	_add_node("root", "Central Core", "The heart of your colony.", 0.0, Vector2(0, 0), [], 1, "Starting technologies", 1, NodeShape.CIRCLE)

	# ── Ascent spine (up): home world → orbit → Moon ─────────────────────────
	_n("unlock_spaceport", "Rocketry", "Heavy-lift launch technology. Build a Spaceport in a Capital District to put payloads into orbit.",
		1500.0, Vector2(0, -180), ["root"], "ascent", "Unlocks Spaceport",
		{"grants": ["spaceport"], "gate": {"planet_lv": 2}})
	_n("unlock_space_station", "Orbital Assembly", "Assemble modular stations in low orbit from Spaceport launches.",
		2500.0, Vector2(0, -330), ["unlock_spaceport"], "ascent", "Unlocks Space Station Districts",
		{"gate": {"built": "spaceport"}})
	_n("unlock_zero_g_nexus", "Zero-G Research", "Microgravity laboratories aboard your stations.",
		1500.0, Vector2(-150, -330), ["unlock_space_station"], "ascent", "Unlocks Zero-G Lab",
		{"grants": ["zero_g_nexus"]})
	_n("unlock_orbital_mirrors", "Orbital Mirrors", "Station-mounted mirrors that focus sunlight onto the surface.",
		2500.0, Vector2(150, -330), ["unlock_space_station"], "ascent", "Unlocks Orbital Mirrors",
		{"grants": ["orbital_mirrors"]})
	_n("unlock_orbital_shipyard", "Orbital Shipyard", "Dry docks in orbit — big enough to build a lunar lander.",
		4000.0, Vector2(0, -480), ["unlock_space_station"], "ascent", "Unlocks Orbital Shipyard",
		{"grants": ["orbital_shipyard"], "gate": {"orbitals": 1}})
	_n("unlock_orbital_offworld_market", "Offworld Trade", "Trade with passing haulers straight from orbit.",
		3500.0, Vector2(150, -480), ["unlock_orbital_shipyard"], "ascent", "Unlocks Offworld Market",
		{"grants": ["orbital_offworld_market"]})
	_n("unlock_moon", "Lunar Program", "Everything needed to land settlers on the Moon. Pick the Moon in the Local System view and start colonization.",
		7000.0, Vector2(0, -640), ["unlock_orbital_shipyard"], "ascent", "Unlocks Moon colonization",
		{"gate": {"built": "orbital_shipyard", "planet_lv": 3, "skill": "unlock_plasma_smelter"}, "shape": NodeShape.CIRCLE})
	# Act II teasers
	_n("unlock_asteroids", "Deep Space Tracking", "Track and mine the asteroid belt.",
		0.0, Vector2(-150, -800), ["unlock_moon"], "ascent", "Asteroid Mining", {"act2": true})
	_n("unlock_planetary_colonization", "Planetary Colonization", "Survive on hostile worlds: ice, desert, volcanic and gas giants.",
		0.0, Vector2(0, -800), ["unlock_moon"], "ascent", "Colonize other planets", {"act2": true, "shape": NodeShape.CIRCLE})
	_n("unlock_orbital_logistics", "Orbital Logistics", "Planet-wide coordination of orbital trade fleets.",
		0.0, Vector2(150, -800), ["unlock_moon"], "ascent", "Orbital Logistics Hub", {"act2": true})
	_n("unlock_interstellar", "Interstellar Travel", "Bend spacetime to reach other star systems.",
		0.0, Vector2(0, -950), ["unlock_planetary_colonization"], "ascent", "Discover new star systems", {"act2": true, "shape": NodeShape.CIRCLE})

	# ── Energy (right) ───────────────────────────────────────────────────────
	_n("unlock_solar_panel", "Energy Operations", "Energy Districts and Solar Arrays.",
		50.0, Vector2(200, 0), ["root"], "energy", "Unlocks Energy Districts & Solar Array", {"grants": ["solar_panel"]})
	_n("unlock_wind_turbine", "Wind Power", "Turbines for windy sites.",
		200.0, Vector2(340, 0), ["unlock_solar_panel"], "energy", "Unlocks Wind Turbine", {"grants": ["wind_turbine"]})
	_n("solar_efficiency", "Photovoltaics", "Better solar cells.",
		150.0, Vector2(340, -110), ["unlock_solar_panel"], "energy", "+10% Solar output per level",
		{"max": 5, "shape": NodeShape.DIAMOND})
	_n("unlock_tidal_generator", "Tidal Power", "Generators along coasts with strong tides.",
		450.0, Vector2(480, 0), ["unlock_wind_turbine"], "energy", "Unlocks Tidal Generator", {"grants": ["tidal_generator"]})
	_n("power_transmission", "Superconducting Grid", "Fewer losses in the power lines.",
		400.0, Vector2(480, -110), ["unlock_wind_turbine"], "energy", "−5% energy use per level",
		{"max": 5, "shape": NodeShape.DIAMOND})
	_n("unlock_geothermal_plant", "Geothermal Power", "Tap the planet's heat at geothermal sites.",
		1000.0, Vector2(620, 0), ["unlock_tidal_generator"], "energy", "Unlocks Geothermal Plant",
		{"grants": ["geothermal_plant"], "gate": {"cities": 2}})
	_n("unlock_solar_matrix", "Solar Matrix", "Colossal tracking solar fields.",
		2000.0, Vector2(760, 0), ["unlock_geothermal_plant"], "energy", "Unlocks Solar Matrix",
		{"grants": ["solar_matrix"], "gate": {"city_lv": 3}})
	_n("unlock_fusion_reactor", "Fusion Power", "Fuel-burning fusion reactors — huge output.",
		4500.0, Vector2(900, 0), ["unlock_solar_matrix"], "energy", "Unlocks Fusion Reactor",
		{"grants": ["fusion_reactor"], "gate": {"planet_lv": 3, "skill": "unlock_plasma_smelter"}})
	_n("unlock_antimatter_chamber", "Antimatter Containment", "Staggering energy from antimatter.",
		0.0, Vector2(1040, 0), ["unlock_fusion_reactor"], "energy", "Antimatter Plant", {"act2": true})

	# ── Industry (left) ──────────────────────────────────────────────────────
	_n("unlock_mining", "Mining Operations", "Industrial Districts: Mines, Goods Factories and Warehouses.",
		20.0, Vector2(-200, 0), ["root"], "industry", "Unlocks Industrial Districts",
		{"grants": ["mine", "refinery", "warehouse"]})
	_n("unlock_rich_vein_excavator", "Vein Excavation", "Heavy excavators for mineral-rich sites.",
		500.0, Vector2(-340, 0), ["unlock_mining"], "industry", "Unlocks Rich Vein Excavator", {"grants": ["rich_vein_excavator"]})
	_n("mine_speed", "Excavation Drills", "High-torque diamond drills.",
		150.0, Vector2(-340, -110), ["unlock_mining"], "industry", "+5% mining speed per level",
		{"max": 5, "shape": NodeShape.DIAMOND})
	_n("unlock_deep_drill", "Deep Drilling", "Drills that reach through bedrock.",
		1000.0, Vector2(-480, 0), ["unlock_rich_vein_excavator"], "industry", "Unlocks Deep Drill",
		{"grants": ["deep_drill"], "gate": {"cities": 2}})
	_n("deep_mining", "Seismic Sensors", "Deep scans find richer seams.",
		400.0, Vector2(-480, -110), ["unlock_rich_vein_excavator"], "industry", "+5% Raw output per level",
		{"max": 5, "shape": NodeShape.DIAMOND})
	_n("unlock_plasma_smelter", "Fuel Refining", "Refine raw minerals into rocket Fuel.",
		1800.0, Vector2(-620, 0), ["unlock_deep_drill"], "industry", "Unlocks Fuel Refinery",
		{"grants": ["plasma_smelter"], "gate": {"city_lv": 3}})
	_n("unlock_molecular_forge", "Rare Element Forge", "Extract rare elements from bulk ore.",
		3500.0, Vector2(-760, 0), ["unlock_plasma_smelter"], "industry", "Unlocks Rare Element Forge",
		{"grants": ["molecular_forge"], "gate": {"planet_lv": 3}})
	_n("unlock_mantle_cracker", "Mantle Cracking", "Crack the mantle for enormous raw yields.",
		5000.0, Vector2(-900, 0), ["unlock_molecular_forge"], "industry", "Unlocks Mantle Cracker", {"grants": ["mantle_cracker"]})
	_n("unlock_quantum_harvester", "Quantum Harvesting", "Targeted extraction by quantum teleportation.",
		0.0, Vector2(-1040, 0), ["unlock_mantle_cracker"], "industry", "Quantum Harvester", {"act2": true})

	# ── Science (down-left) ──────────────────────────────────────────────────
	_n("unlock_lab", "Research Operations", "Science Districts and Research Labs.",
		100.0, Vector2(-180, 180), ["root"], "science", "Unlocks Science Districts & Research Lab", {"grants": ["lab"]})
	_n("science_income_1", "Educational Grants", "Fund the universities.",
		200.0, Vector2(-320, 180), ["unlock_lab"], "science", "+10% Science per level",
		{"max": 5, "shape": NodeShape.DIAMOND})
	_n("unlock_mountain_observatory", "Mountain Optics", "Observatories on high peaks.",
		500.0, Vector2(-320, 320), ["unlock_lab"], "science", "Unlocks Mountain Observatory", {"grants": ["mountain_observatory"]})
	_n("unlock_advanced_lab", "Advanced Research", "Dedicated research institutes.",
		1200.0, Vector2(-460, 460), ["unlock_mountain_observatory"], "science", "Unlocks Research Institute",
		{"grants": ["advanced_lab"], "gate": {"cities": 2}})
	_n("science_income_2", "Unified Theory", "A breakthrough that speeds up all research.",
		1500.0, Vector2(-600, 460), ["unlock_advanced_lab"], "science", "+15% Science per level",
		{"max": 5, "shape": NodeShape.DIAMOND})
	_n("unlock_particle_accelerator", "Particle Physics", "Accelerators fed with rare elements.",
		4000.0, Vector2(-600, 600), ["unlock_advanced_lab"], "science", "Unlocks Particle Accelerator",
		{"grants": ["particle_accelerator"], "gate": {"planet_lv": 3}})
	_n("unlock_quantum_computer", "Quantum Computing", "Quantum labs for staggering research.",
		0.0, Vector2(-740, 740), ["unlock_particle_accelerator"], "science", "Quantum Lab", {"act2": true})

	# ── Habitation (down-right) ──────────────────────────────────────────────
	_n("unlock_residential", "Habitation Operations", "Residential Districts and Habitat Blocks.",
		50.0, Vector2(180, 180), ["root"], "habitation", "Unlocks Residential Districts & Habitat Block", {"grants": ["residential"]})
	_n("housing_income_1", "Subsidized Housing", "Public housing programmes.",
		200.0, Vector2(320, 180), ["unlock_residential"], "habitation", "+10% housing per level",
		{"max": 5, "shape": NodeShape.DIAMOND})
	_n("unlock_seaside_villas", "Coastal Living", "Villas for coastal districts.",
		400.0, Vector2(320, 320), ["unlock_residential"], "habitation", "Unlocks Seaside Villas", {"grants": ["seaside_villas"]})
	_n("unlock_apartments", "High-Rise Housing", "Dense apartment towers.",
		1000.0, Vector2(460, 460), ["unlock_seaside_villas"], "habitation", "Unlocks Apartment Towers",
		{"grants": ["apartments"], "gate": {"cities": 2}})
	_n("housing_income_2", "Urban Planning", "Smarter cities house more people.",
		1500.0, Vector2(600, 460), ["unlock_apartments"], "habitation", "+15% housing per level",
		{"max": 5, "shape": NodeShape.DIAMOND})
	_n("unlock_luxury_complex", "Luxury Living", "Premium spires for the elite.",
		3500.0, Vector2(600, 600), ["unlock_apartments"], "habitation", "Unlocks Luxury Spires",
		{"grants": ["luxury_complex"], "gate": {"planet_lv": 3}})
	_n("unlock_arcology", "Arcologies", "Self-contained mega-cities.",
		0.0, Vector2(740, 740), ["unlock_luxury_complex"], "habitation", "Arcology", {"act2": true})

	# ── Commerce (down) ──────────────────────────────────────────────────────
	_n("unlock_commercial", "Commerce Operations", "Commercial Districts and Markets.",
		50.0, Vector2(0, 200), ["root"], "commerce", "Unlocks Commercial Districts & Market", {"grants": ["commercial"]})
	_n("unlock_harbor_market", "Harbor Trade", "Markets on the waterfront.",
		400.0, Vector2(130, 340), ["unlock_commercial"], "commerce", "Unlocks Harbor Market", {"grants": ["harbor_market"]})
	_n("unlock_bazaar", "Consumer Goods", "Bazaars that sell factory Goods.",
		350.0, Vector2(0, 340), ["unlock_commercial"], "commerce", "Unlocks Bazaar",
		{"grants": ["bazaar"], "gate": {"skill": "unlock_mining"}})
	_n("trade_income_1", "Free Trade", "Lower tariffs, more business.",
		200.0, Vector2(-130, 340), ["unlock_commercial"], "commerce", "+10% Credits per level",
		{"max": 5, "shape": NodeShape.DIAMOND})
	_n("unlock_trading_post", "Trade Networks", "Trade Hubs link your Cities' markets.",
		1000.0, Vector2(0, 480), ["unlock_bazaar"], "commerce", "Unlocks Trade Hub",
		{"grants": ["trading_post"], "gate": {"cities": 2}})
	_n("trade_income_2", "Interplanetary Commerce", "Corporate tax incentives.",
		1500.0, Vector2(-130, 480), ["unlock_trading_post"], "commerce", "+15% Credits per level",
		{"max": 5, "shape": NodeShape.DIAMOND})
	_n("unlock_commodities_exchange", "Commodity Markets", "Exchanges that trade Goods in bulk.",
		3000.0, Vector2(0, 620), ["unlock_trading_post"], "commerce", "Unlocks Commodity Exchange",
		{"grants": ["commodities_exchange"], "gate": {"planet_lv": 3}})
	_n("unlock_logistics_center", "Planetary Logistics", "One Logistics Center coordinates the whole planet.",
		4000.0, Vector2(130, 620), ["unlock_commodities_exchange"], "commerce", "Unlocks Logistics Center",
		{"grants": ["logistics_center"]})
	_n("unlock_command_center", "Planetary Command", "A single command centre for the whole planet.",
		6000.0, Vector2(0, 760), ["unlock_commodities_exchange"], "commerce", "Unlocks Planetary Command",
		{"grants": ["command_center"]})
	_n("unlock_central_bank", "Interstellar Banking", "Banks that finance whole star systems.",
		0.0, Vector2(0, 900), ["unlock_command_center"], "commerce", "Interstellar Bank", {"act2": true})

## Shorthand: opts = {max, shape, grants, gate, act2}.
func _n(id: String, name: String, desc: String, cost: float, pos: Vector2, parents: Array[String],
		branch: String, eff: String, opts: Dictionary = {}) -> void:
	var default_shape := NodeShape.HEXAGON
	_add_node(id, name, desc, cost, pos, parents, 1, eff, int(opts.get("max", 1)), opts.get("shape", default_shape))
	var node: SkillNode = nodes[id]
	node.branch = branch
	node.gate = opts.get("gate", {})
	node.act2 = opts.get("act2", false)
	for b: String in opts.get("grants", []):
		node.grants.append(b)
		_grant_of[b] = id

func _add_node(id: String, name: String, desc: String, cost: float, pos: Vector2, parents: Array[String], tier: int, eff: String, max_lv: int = 1, shape: NodeShape = NodeShape.HEXAGON) -> void:
	nodes[id] = SkillNode.new(id, name, desc, cost, pos, parents, tier, eff, max_lv, shape)

# ── Milestone gates ──────────────────────────────────────────────────────────

## Why the milestones of `id` aren't met yet ("" when they are). Checked
## against the home planet:
##   planet_lv  planet level ≥ n        cities    ≥ n Cities founded
##   city_lv    some City at level ≥ n  built     a finished building of that id
##   orbitals   ≥ n finished stations   skill     another node bought
func gate_block(id: String) -> String:
	var node: SkillNode = nodes.get(id, null)
	if node == null or node.gate.is_empty():
		return ""
	var g := node.gate
	var seed_val: int = GameState.home_planet_seed
	var pp: PlanetProgress = GameState.get_planet(seed_val)
	var pd: PlanetData = GameState.get_planet_data(seed_val)
	var missing: Array[String] = []
	if g.has("planet_lv") and (pp == null or pp.level < int(g["planet_lv"])):
		missing.append("Planet Lv %d" % int(g["planet_lv"]))
	if g.has("cities") and _city_count(pd) < int(g["cities"]):
		missing.append("%d Cities" % int(g["cities"]))
	if g.has("city_lv") and _best_city_level(pd, pp) < int(g["city_lv"]):
		missing.append("a City at Lv %d" % int(g["city_lv"]))
	if g.has("built") and not _has_built(String(g["built"])):
		var def := BuildingDef.find(String(g["built"]))
		missing.append("a built %s" % (def.display_name if def else String(g["built"])))
	if g.has("orbitals") and _orbital_count(pd) < int(g["orbitals"]):
		missing.append("%d Space Station%s" % [int(g["orbitals"]), "" if int(g["orbitals"]) == 1 else "s"])
	if g.has("skill") and not is_unlocked(String(g["skill"])):
		var other: SkillNode = nodes.get(String(g["skill"]), null)
		missing.append(other.name if other else String(g["skill"]))
	return "" if missing.is_empty() else "Requires " + ", ".join(missing)

func _city_count(pd: PlanetData) -> int:
	if pd == null:
		return 0
	var n := 0
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital() and not p.constructing:
			n += 1
	return n

func _best_city_level(pd: PlanetData, pp: PlanetProgress) -> int:
	if pd == null or pp == null:
		return 0
	var best := 0
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital():
			best = maxi(best, Leveling.city_level(pp, p))
	return best

func _orbital_count(pd: PlanetData) -> int:
	if pd == null:
		return 0
	var n := 0
	for p: POIData in pd.custom_pois:
		if p.is_orbital() and not p.constructing:
			n += 1
	return n

func _has_built(building_id: String) -> bool:
	for pp: PlanetProgress in GameState._planet_progress.values():
		for b: Dictionary in pp.buildings:
			if b.get("building_id", "") == building_id and not b.get("constructing", false):
				return true
	return false

# ── Buildings ────────────────────────────────────────────────────────────────

## True when a bought node grants this building.
func building_unlocked(building_id: String) -> bool:
	return is_unlocked(_grant_of.get(building_id, ""))

## The node that grants a building ("" when none does).
func node_for_building(building_id: String) -> String:
	return _grant_of.get(building_id, "")

## Buildings have no levels any more; kept for older callers.
func get_building_max_level(_building_id: String) -> int:
	return 1

# ── State ────────────────────────────────────────────────────────────────────

func is_unlocked(id: String) -> bool:
	if id == "root": return true
	return id in unlocked_skills

func get_skill_level(id: String) -> int:
	if id == "root":
		return 1
	if id not in unlocked_skills:
		return 0
	return skill_levels.get(id, 1)

# Get cost of next level: base × (1 + current level)
func get_next_cost(id: String) -> float:
	var node: SkillNode = nodes.get(id, null)
	if node == null:
		return 0.0
	var cur_lv := get_skill_level(id)
	if cur_lv >= node.max_level:
		return 0.0
	return node.cost * (1.0 + cur_lv)

# Check if a skill can be purchased / upgraded
func can_purchase(id: String) -> bool:
	var node: SkillNode = nodes.get(id, null)
	if node == null or node.act2:
		return false
	var cur_lv := get_skill_level(id)
	if cur_lv >= node.max_level:
		return false
	if cur_lv == 0:
		var parent_ok := node.parents.is_empty()
		for p in node.parents:
			if p in unlocked_skills:
				parent_ok = true
				break
		if not parent_ok:
			return false
		if gate_block(id) != "":
			return false
	return GameState.science_points >= get_next_cost(id)

# Buy or upgrade a skill node
func purchase_skill(id: String) -> bool:
	if not can_purchase(id):
		return false
	if not GameState.spend_science(get_next_cost(id)):
		return false
	var cur_lv := get_skill_level(id)
	if cur_lv == 0:
		unlocked_skills.append(id)
		skill_levels[id] = 1
		var node: SkillNode = nodes[id]
		for bid: String in node.grants:
			GameState.unlock_building(bid)
		if id == "unlock_moon":   # opens the Local System view and the Moon
			GameState.moon_unlocked = true
			GameState.unlock_changed.emit("moon_unlocked", true)
	else:
		skill_levels[id] = cur_lv + 1
	skill_unlocked.emit(id)
	GameState.save()
	return true

# Visible when bought or a parent is bought. Act II teasers show one step
# earlier — as soon as their parent is visible — so the road ahead is hinted.
func is_visible(id: String) -> bool:
	if has_meta("debug_reveal_all") and get_meta("debug_reveal_all"):
		return true
	if id == "root" or id in unlocked_skills:
		return true
	var node: SkillNode = nodes.get(id, null)
	if node == null:
		return false
	for p in node.parents:
		if p in unlocked_skills:
			return true
		if node.act2 and p != id and is_visible(p):
			return true
	return false

# ── Dynamic Modifiers read by GameState/ProductionManager ─────────────────────

func _lv(id: String) -> int:
	return get_skill_level(id) if id in unlocked_skills else 0

func get_solar_mult() -> float:
	return 1.0 + 0.10 * _lv("solar_efficiency")

func get_mine_speed_mult() -> float:
	return 1.0 + 0.05 * _lv("mine_speed")

func get_mine_output_mult() -> float:
	return 1.0 + 0.05 * _lv("deep_mining")

func get_credits_mult() -> float:
	return 1.0 + 0.10 * _lv("trade_income_1") + 0.15 * _lv("trade_income_2")

func get_science_mult() -> float:
	return 1.0 + 0.10 * _lv("science_income_1") + 0.15 * _lv("science_income_2")

## Housing from buildings (population capacity).
func get_housing_mult() -> float:
	return 1.0 + 0.10 * _lv("housing_income_1") + 0.15 * _lv("housing_income_2")

func get_energy_consume_mult() -> float:
	return maxf(0.1, 1.0 - 0.05 * _lv("power_transmission"))

func get_global_speed_mult() -> float:
	return 1.0

func get_generator_output_mult() -> float:
	return 1.0

func get_refinery_speed_mult() -> float:
	return 1.0

func get_mining_energy_mult() -> float:
	return 1.0

func get_max_districts_add() -> int:
	return 0

func get_trade_output_mult() -> float:
	return 1.0

func get_trade_speed_mult() -> float:
	return 1.0

func get_trade_maintenance_mult() -> float:
	return 1.0
