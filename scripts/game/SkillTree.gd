## SkillTree — Autoload singleton: the research graph, what the player has
## bought, and the modifiers those purchases grant.
##
## Canonical research ids follow docs/design/VOIDLE_GDD.md §17. Older saves use
## the 54 ids of the Act I tree; LEGACY_MAP converts them on load (§17.23) and
## is_unlocked() still answers for them, so old callers keep working.
##
## Rules (§17.3–§17.9):
##   parents      ANY one bought parent opens the node
##   requires     every listed node must be bought as well
##   access       products/minerals the player must be able to get (fuel, rare,
##                goods, moonstone) — an undiscovered mineral is never named
##   events       physical milestones (a Moon production district, …)
##   common       the shared Civilization 0 path: no cross-branch surcharge,
##                and it doesn't count toward other branches' surcharge
##   price        base × target level × (1 + research_cross_branch × distinct
##                strategy nodes bought in other branches of the same civilization)
##   levels       bonuses go to Lv3; effective level = max(bought, inherited)
## Inherited levels come from the fractal buyout (M6); the field is saved now.
##
## Layout: root in the middle, the common path climbs straight up to the final
## rocket; Energy right, Production left, Processing and Public up-left,
## Orbital and Planning up-right, Science down-left, Trade down, Population down-right.
extends Node

signal skill_unlocked(id: String)

## Nodes every new game starts with (free roots; start_production is a free
## first click so the tutorial can point at it).
const DEFAULT_SKILLS: Array[String] = ["root", "start_energy", "start_science", "start_residential", "start_commercial"]

## Centre node of Civilization 1's tree: stands for the whole Civilization 0 tree.
const LEGACY_NODE_1 := "civilization_0_tree"

## Grid step of the layout (px per unit).
const GRID := 130.0

## Old Act I id → canonical id(s) (GDD §17.23). Ids missing here were previews
## with no real right; they are dropped from old saves.
const LEGACY_MAP := {
	"root": ["root"],
	"unlock_spaceport": ["rocketry"],
	"unlock_space_station": ["orbital_assembly"],
	"unlock_zero_g_nexus": ["orbital_science"],
	"unlock_orbital_mirrors": ["orbital_mirrors"],
	"unlock_orbital_shipyard": ["orbital_shipyard"],
	"unlock_orbital_offworld_market": ["orbital_offworld_market"],
	"unlock_moon": ["lunar_program"],
	"unlock_solar_panel": ["start_energy"],
	"unlock_wind_turbine": ["wind_power"],
	"solar_efficiency": ["solar_efficiency"],
	"unlock_tidal_generator": ["tidal_power"],
	"power_transmission": ["grid_efficiency"],
	"unlock_geothermal_plant": ["geothermal_power"],
	"unlock_solar_matrix": ["solar_matrix"],
	"unlock_fusion_reactor": ["fusion_power"],
	"unlock_mining": ["start_production", "processing_basics"],
	"unlock_rich_vein_excavator": ["advanced_excavation"],
	"mine_speed": ["extraction_efficiency"],
	"unlock_deep_drill": ["deep_drilling"],
	"deep_mining": ["extraction_efficiency"],
	"unlock_plasma_smelter": ["fuel_processing", "dense_fuel"],
	"unlock_molecular_forge": ["rare_processing"],
	"unlock_mantle_cracker": ["mantle_cracking"],
	"unlock_lab": ["start_science"],
	"science_income_1": ["science_efficiency"],
	"unlock_mountain_observatory": ["mountain_optics"],
	"unlock_advanced_lab": ["advanced_research"],
	"science_income_2": ["science_efficiency"],
	"unlock_particle_accelerator": ["particle_physics"],
	"unlock_residential": ["start_residential"],
	"housing_income_1": ["housing_efficiency"],
	"unlock_seaside_villas": ["coastal_living"],
	"unlock_apartments": ["high_rise"],
	"housing_income_2": ["housing_efficiency"],
	"unlock_luxury_complex": ["luxury_living"],
	"unlock_commercial": ["start_commercial"],
	"unlock_harbor_market": ["harbor_trade"],
	"unlock_bazaar": ["consumer_goods"],
	"trade_income_1": ["trade_efficiency"],
	"unlock_trading_post": ["trade_networks"],
	"trade_income_2": ["trade_efficiency"],
	"unlock_commodities_exchange": ["commodity_markets"],
	"unlock_logistics_center": ["logistics"],
	"unlock_command_center": ["advanced_coordination"],
}

## Pairs of output families that Karma Ağlar (cross_networks) links (§17.21,
## §17.27 "Science–trade, population–science, energy–industry").
const CROSS_FAMILIES := {
	"science": ["commercial", "residential"],
	"commercial": ["science"],
	"residential": ["science"],
	"energy": ["production"],
	"production": ["energy"],
}

# Global set of purchased/unlocked skill IDs
var unlocked_skills: Array[String] = DEFAULT_SKILLS.duplicate()

# Bought levels: { skill_id: int }
var skill_levels: Dictionary = {}

## Levels granted by a later civilization's buyout (M6): { skill_id: int }.
var inherited_levels: Dictionary = {}

enum NodeShape { HEXAGON, DIAMOND, CIRCLE }

# Definitions of all nodes in the skill tree graph
class SkillNode:
	var id: String
	var name: String
	var description: String
	## Base Science of the first level (GDD "taban Science").
	var cost: float
	var pos: Vector2
	## ANY one of these opens the node.
	var parents: Array[String]
	var tier: int
	var effect_desc: String
	var max_level: int # 1 = single purchase, 3 = levelled bonus
	var shape: NodeShape
	## Main branch for the cross-branch price (energy, production, processing,
	## science, population, trade, public, proximity, distance, geography, common, orbital).
	var branch: String = "common"
	## Buildings this node grants (a building granted by several nodes needs them all).
	var grants: Array[String] = []
	## Every one of these nodes must be bought too.
	var requires: Array[String] = []
	## Products / minerals the player must have access to.
	var access: Array[String] = []
	## Physical milestones (see event_met).
	var events: Array[String] = []
	## Shared Civilization 0 path (no cross-branch price, not counted).
	var common: bool = false
	## Lowest civilization that can buy it.
	var min_civilization: int = 0
	## Civilization this node belongs to (cross-branch counter scope).
	var civilization: int = 0
	## A real right a later buyout may grant (GDD legacy_eligible).
	var legacy_eligible: bool = true
	## Preview only: shown, never purchasable (future content).
	var act2: bool = false
	## Feature id for geography_specialization:<feature> nodes.
	var feature: String = ""

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
## building id -> Array of node ids that grant it (all needed)
var _grant_of: Dictionary = {}
## Bumped on every purchase; caches that depend on research read it.
var version: int = 0

func _init() -> void:
	for s: String in DEFAULT_SKILLS:
		skill_levels[s] = 1
	_add_node("root", "Civilization 0", "The heart of your civilization. In later civilizations this centre stands for the tree before it.",
		0.0, Vector2.ZERO, [], 1, "Starting technologies", 1, NodeShape.CIRCLE)

	# ── Free roots (GDD §17.11) ──────────────────────────────────────────────
	_n("start_energy", "Energy Operations", "Energy Districts and Solar Arrays.",
		0.0, Vector2(2, 0), ["root"], "energy", "Unlocks Energy Districts & Solar Array",
		{"grants": ["solar_panel"], "common": true})
	_n("start_production", "Mining Operations", "Production Districts: Mines and Warehouses.",
		0.0, Vector2(-2, 0), ["root"], "production", "Unlocks Production Districts, Mine & Warehouse",
		{"grants": ["mine", "warehouse"], "common": true})
	_n("start_science", "Research Operations", "Science Districts and Research Labs.",
		0.0, Vector2(-2, 2), ["root"], "science", "Unlocks Science Districts & Research Lab",
		{"grants": ["lab"], "common": true})
	_n("start_residential", "Habitation Operations", "Residential Districts and Habitat Blocks.",
		0.0, Vector2(2, 2), ["root"], "population", "Unlocks Residential Districts & Habitat Block",
		{"grants": ["residential"], "common": true})
	_n("start_commercial", "Commerce Operations", "Commercial Districts and Markets.",
		0.0, Vector2(0, 2), ["root"], "trade", "Unlocks Commercial Districts & Market",
		{"grants": ["commercial"], "common": true})

	# ── Common Civilization 0 path (§17.9): 6,500 Science in all ─────────────
	_n("processing_basics", "Basic Processing", "Turn Ferrite into Goods.",
		0.0, Vector2(-1, -1), ["start_production"], "common", "Unlocks Goods Factory",
		{"grants": ["refinery"], "common": true})
	_n("trade_access", "Trade Access", "Buy and sell at fixed prices. Once researched, storage overflow is sold instead of lost.",
		150.0, Vector2(1, 1), ["root"], "common", "Manual trade and overflow sales",
		{"common": true})
	_n("fuel_processing", "Fuel Processing", "Small-scale Fuel production — the first step towards rockets.",
		450.0, Vector2(0, -2), ["processing_basics"], "common", "Unlocks Compact Fuel Workshop, Fuel access",
		{"grants": ["compact_fuel_workshop"], "common": true})
	_n("rare_processing", "Rare Processing", "Extract rare elements from bulk ore.",
		900.0, Vector2(-1, -3), ["fuel_processing"], "common", "Unlocks Rare Element Forge, Rare access",
		{"grants": ["molecular_forge"], "common": true})
	_n("rocketry", "Rocketry", "Heavy-lift launch technology. Build a Spaceport in a Capital District.",
		600.0, Vector2(0, -3), ["fuel_processing"], "common", "Unlocks Spaceport",
		{"grants": ["spaceport"], "common": true})
	_n("lunar_program", "Lunar Program", "A lander that carries settlers to the Moon. It needs a working station in orbit first. Pick the Moon in the Local System view.",
		1200.0, Vector2(0, -4), ["orbital_assembly"], "common", "Unlocks the Moon lander",
		{"events": ["orbit_station"], "common": true, "shape": NodeShape.CIRCLE})
	_n("lunar_materials", "Lunar Materials", "Build with what the Moon gives: local plans, habitats and the Lunar Spaceport.",
		1200.0, Vector2(0, -5), ["lunar_program"], "common", "Unlocks Lunar Spaceport, Modular Moon Habitat, Regolith Goods Plant",
		{"grants": ["modular_moon_habitat", "regolith_goods_plant", "lunar_spaceport"], "events": ["moon_production"], "common": true})
	_n("advanced_planet_rocket", "Advanced Planetary Rocket", "The rocket that leaves the Moon for a new world.",
		2000.0, Vector2(0, -6.5), ["lunar_materials"], "common", "Unlocks the final rocket",
		{"requires": ["rare_processing"], "events": ["moon_moonstone_100"], "common": true, "shape": NodeShape.CIRCLE})

	# ── Production (left) §17.12 ─────────────────────────────────────────────
	_n("surface_excavation", "Surface Excavation", "Shallow pits that need little investment.",
		75.0, Vector2(-3, -1), ["start_production"], "production", "Unlocks Surface Quarry",
		{"grants": ["surface_quarry"]})
	_n("advanced_excavation", "Advanced Excavation", "Heavy excavators — dense extraction anywhere.",
		450.0, Vector2(-3, 0), ["start_production"], "production", "Unlocks Rich Vein Excavator",
		{"grants": ["rich_vein_excavator"]})
	_n("deep_drilling", "Deep Drilling", "Drills that reach through bedrock.",
		350.0, Vector2(-2, -1.0), ["start_production"], "production", "Unlocks Deep Drill",
		{"grants": ["deep_drill"]})
	_n("mantle_cracking", "Mantle Cracking", "Crack the mantle for enormous raw yields.",
		900.0, Vector2(-4, 0), ["advanced_excavation", "deep_drilling"], "production", "Unlocks Mantle Cracker",
		{"grants": ["mantle_cracker"], "access": ["fuel", "rare"]})
	_n("extraction_efficiency", "Extraction Efficiency", "Better drills and sorting at every mine.",
		150.0, Vector2(-2, 1), ["start_production"], "production", "+10% Raw output per level",
		{"max": 3, "shape": NodeShape.DIAMOND})

	# ── Processing (up-left) ─────────────────────────────────────────────────
	_n("ore_sorting", "Ore Sorting", "Large-scale sorting lines for Goods.",
		450.0, Vector2(-2, -2), ["processing_basics"], "processing", "Unlocks Ore Sorting Workshop",
		{"grants": ["ore_sorting_workshop"]})
	_n("dense_fuel", "Dense Fuel", "Refineries that turn out Fuel in bulk.",
		350.0, Vector2(-1, -2), ["fuel_processing"], "processing", "Unlocks Fuel Refinery",
		{"grants": ["plasma_smelter"]})
	_n("fuel_process_efficiency", "Fuel Processes", "Tighter refining tolerances.",
		150.0, Vector2(1, -2), ["fuel_processing"], "processing", "+10% Fuel output per level",
		{"max": 3, "shape": NodeShape.DIAMOND})

	# ── Energy (right) §17.13 ────────────────────────────────────────────────
	_n("wind_power", "Wind Power", "Turbines for windy sites.",
		150.0, Vector2(3, 0), ["start_energy"], "energy", "Unlocks Wind Turbine",
		{"grants": ["wind_turbine"]})
	_n("tidal_power", "Tidal Power", "Generators along coasts with strong tides. The building still needs a coast.",
		350.0, Vector2(4, 0), ["wind_power", "start_commercial"], "energy", "Unlocks Tidal Generator",
		{"grants": ["tidal_generator"]})
	_n("shallow_heat", "Shallow Heat", "Small wells on warm ground.",
		250.0, Vector2(3, 1), ["start_energy"], "geography", "Unlocks Shallow Geothermal Well",
		{"grants": ["shallow_geothermal_well"]})
	_n("geothermal_power", "Geothermal Power", "Tap the planet's heat at geothermal sites.",
		450.0, Vector2(5, 0), ["shallow_heat", "tidal_power"], "energy", "Unlocks Geothermal Plant",
		{"grants": ["geothermal_plant"]})
	_n("ridge_wind", "Ridge Winds", "Large turbines on windswept ridges.",
		450.0, Vector2(4, -1), ["wind_power"], "geography", "Unlocks Ridge Turbine",
		{"grants": ["ridge_turbine"]})
	_n("solar_matrix", "Solar Matrix", "Colossal tracking solar fields.",
		350.0, Vector2(3, -1), ["start_energy"], "energy", "Unlocks Solar Matrix",
		{"grants": ["solar_matrix"]})
	_n("fusion_power", "Fusion Power", "Fuel-burning fusion reactors — huge output.",
		900.0, Vector2(6, 0), ["solar_matrix", "geothermal_power"], "energy", "Unlocks Fusion Reactor",
		{"grants": ["fusion_reactor"], "access": ["fuel", "rare"]})
	_n("solar_efficiency", "Photovoltaics", "Better solar cells.",
		150.0, Vector2(2, -1), ["start_energy"], "energy", "+10% Solar output per level",
		{"max": 3, "shape": NodeShape.DIAMOND})
	_n("grid_efficiency", "Superconducting Grid", "Fewer losses in the power lines.",
		300.0, Vector2(1, -1), ["start_energy"], "energy", "−5% energy use per level",
		{"max": 3, "shape": NodeShape.DIAMOND})

	# ── Science (down-left) §17.14 ───────────────────────────────────────────
	_n("field_research", "Field Research", "Small observation posts out in the field.",
		100.0, Vector2(-3, 2), ["start_science"], "science", "Unlocks Field Observatory",
		{"grants": ["field_observatory"]})
	_n("mountain_optics", "Mountain Optics", "Observatories on high peaks.",
		450.0, Vector2(-3, 3), ["start_science"], "science", "Unlocks Mountain Observatory",
		{"grants": ["mountain_observatory"]})
	_n("advanced_research", "Advanced Research", "Dedicated research institutes.",
		350.0, Vector2(-3, 1), ["start_science"], "science", "Unlocks Research Institute",
		{"grants": ["advanced_lab"]})
	_n("particle_physics", "Particle Physics", "Accelerators fed with rare elements.",
		900.0, Vector2(-4, 1), ["advanced_research", "rare_processing"], "science", "Unlocks Particle Accelerator",
		{"grants": ["particle_accelerator"], "access": ["rare", "moonstone"]})
	_n("science_efficiency", "Science Efficiency", "Fund the universities.",
		150.0, Vector2(-2, 3), ["start_science"], "science", "+10% Science per level",
		{"max": 3, "shape": NodeShape.DIAMOND})
	_n("lunar_research", "Lunar Research", "Study lunar samples where they are found.",
		600.0, Vector2(1, -6), ["lunar_materials"], "science", "Unlocks Lunar Sample Lab",
		{"grants": ["lunar_sample_lab"], "events": ["moon_city"], "access": ["rare"]})

	# ── Population (down-right) §17.15 ───────────────────────────────────────
	_n("neighborhood_building", "Neighbourhood Building", "Cheap low-rise blocks.",
		75.0, Vector2(3, 2), ["start_residential"], "population", "Unlocks Low-rise Housing",
		{"grants": ["low_rise_housing"]})
	_n("coastal_living", "Coastal Living", "Villas for coastal districts.",
		250.0, Vector2(2, 3), ["start_residential"], "population", "Unlocks Seaside Villas",
		{"grants": ["seaside_villas"]})
	_n("coastal_density", "Coastal Density", "Apartment blocks along the shore.",
		350.0, Vector2(2, 4), ["coastal_living"], "population", "Unlocks Coastal Apartments",
		{"grants": ["coastal_apartments"]})
	_n("civic_enterprise", "Civic Enterprise", "People without a job start small businesses.",
		150.0, Vector2(3, 3), ["start_residential"], "population", "Idle population earns Credits",
		{})
	_n("free_research", "Free Research", "People without a job tinker, study and publish.",
		150.0, Vector2(1, 3), ["start_residential", "start_science"], "population", "Idle population earns Science",
		{})
	_n("population_reserve", "Production Reserve", "A spare workforce covers shifts and peaks.",
		300.0, Vector2(3, 4), ["civic_enterprise", "free_research"], "population", "Raw and processed output +2% per full 10% idle population (max +20%)",
		{})
	_n("high_rise", "High-Rise Housing", "Dense apartment towers.",
		350.0, Vector2(4, 3), ["coastal_living", "civic_enterprise"], "population", "Unlocks Apartment Towers",
		{"grants": ["apartments"]})
	_n("luxury_living", "Luxury Living", "Premium spires for the elite.",
		900.0, Vector2(5, 3), ["high_rise"], "population", "Unlocks Luxury Spires",
		{"grants": ["luxury_complex"], "access": ["fuel", "rare", "moonstone"]})
	_n("housing_efficiency", "Housing Efficiency", "Smarter cities house more people.",
		150.0, Vector2(4, 2), ["start_residential"], "population", "+10% housing from buildings per level",
		{"max": 3, "shape": NodeShape.DIAMOND})

	# ── Trade (down) §17.16 ──────────────────────────────────────────────────
	_n("consumer_goods", "Consumer Goods", "Bazaars that sell factory Goods.",
		250.0, Vector2(0, 3), ["start_commercial"], "trade", "Unlocks Bazaar",
		{"grants": ["bazaar"]})
	_n("local_business", "Local Business", "Neighbourhood trade centres.",
		150.0, Vector2(2, 1), ["trade_access"], "trade", "Unlocks Local Trade Center",
		{"grants": ["local_trade_center"]})
	_n("trade_networks", "Trade Networks", "Trade Hubs link your Cities' markets.",
		350.0, Vector2(0, 4), ["consumer_goods", "local_business"], "trade", "Unlocks Trade Hub",
		{"grants": ["trading_post"]})
	_n("harbor_trade", "Harbor Trade", "Markets on the waterfront.",
		450.0, Vector2(1, 5), ["coastal_living", "trade_networks"], "trade", "Unlocks Harbor Market",
		{"grants": ["harbor_market"]})
	_n("commodity_markets", "Commodity Markets", "Exchanges that trade Goods in bulk.",
		900.0, Vector2(0, 5), ["trade_networks"], "trade", "Unlocks Commodity Exchange",
		{"grants": ["commodities_exchange"], "access": ["fuel", "rare", "moonstone"]})
	_n("trade_automation", "Trade Automation", "Standing orders: sell above a reserve, buy up to a target stock.",
		300.0, Vector2(1, 2), ["trade_access"], "trade", "Trade automation with reserves",
		{})
	_n("trade_efficiency", "Trade Efficiency", "Lower tariffs, more business.",
		150.0, Vector2(-1, 3), ["start_commercial"], "trade", "+10% produced Credits per level",
		{"max": 3, "shape": NodeShape.DIAMOND})
	_n("lunar_supply", "Lunar Supply Network", "Markets that keep the Moon supplied.",
		600.0, Vector2(-1, -6), ["lunar_materials", "trade_networks"], "trade", "Unlocks Lunar Supply Market",
		{"grants": ["lunar_supply_market"], "requires": ["trade_access"], "events": ["moon_city"], "access": ["fuel"]})

	# ── Public, proximity, distance (up-left / up-right) §17.17 ──────────────
	_n("public_administration", "Public Administration", "The root of the Capital's support offices.",
		350.0, Vector2(-3, -2), ["root"], "public", "Opens public support buildings",
		{})
	_n("logistics", "Logistics", "One Logistics Center coordinates the whole planet.",
		450.0, Vector2(-3, -3), ["ore_sorting", "trade_networks"], "public", "Unlocks Logistics Center",
		{"grants": ["logistics_center"], "requires": ["public_administration"]})
	_n("advanced_coordination", "Advanced Coordination", "A single command centre for the whole planet.",
		900.0, Vector2(-4, -3), ["fusion_power", "advanced_research"], "public", "Unlocks Planetary Command",
		{"grants": ["command_center"], "requires": ["public_administration"], "access": ["fuel", "rare", "moonstone"]})
	_n("construction_management", "Construction Management", "A planning office for big builds.",
		350.0, Vector2(-4, -2), ["public_administration"], "public", "Construction Office (coming later)",
		{})
	_n("fuel_storage", "Fuel Storage", "Tanks that keep Fuel ready for launch.",
		200.0, Vector2(1, -3), ["fuel_processing"], "public", "Unlocks Fuel Depot",
		{"grants": ["fuel_depot"]})
	_n("recycling_1", "Recycling I", "Salvage more when you tear something down.",
		250.0, Vector2(-5, -2), ["root"], "public", "Credit refund on demolition 65%",
		{})
	_n("recycling_2", "Recycling II", "Salvage nearly everything.",
		500.0, Vector2(-5, -3), ["recycling_1"], "public", "Credit refund on demolition 75%",
		{})
	_n("settlement_layout", "Settlement Layout", "Plan, rearrange and move settlements.",
		250.0, Vector2(-4, -4), ["root"], "public", "Move districts and buildings",
		{})
	_n("cluster_planning", "Cluster Planning", "Districts that stand together work together.",
		200.0, Vector2(3, -2), ["root"], "proximity", "Proximity and centre bonuses ×1.1 per level",
		{"max": 3, "shape": NodeShape.DIAMOND})
	_n("independent_centers", "Independent Centres", "Remote districts learn to stand on their own.",
		200.0, Vector2(4, -2), ["root"], "distance", "+10 points to a distance bonus per level",
		{"max": 3, "shape": NodeShape.DIAMOND})
	_n("cross_networks", "Mixed Networks", "Science and trade, housing and science, energy and industry help each other.",
		450.0, Vector2(3, -3), ["cluster_planning", "science_efficiency", "trade_efficiency"], "proximity",
		"Linked families support each other: very near +5%, near +2.5%", {})
	# one specialisation per visible terrain feature, 3 levels each
	var gi := 0
	for fid: String in FeatureMap.IDS:
		var gid := "geography_specialization:" + fid
		var gpos := Vector2(4.0 + 0.8 * float(gi % 5), -3.2 - 0.8 * floorf(float(gi) / 5.0))
		_n(gid, "%s Specialisation" % FeatureMap.feature_name(fid), "Learn to use this terrain. It doesn't create the terrain.",
			200.0, gpos, ["root"], "geography", "Bonuses from %s ×1.1 per level" % FeatureMap.feature_name(fid),
			{"max": 3, "shape": NodeShape.DIAMOND})
		(nodes[gid] as SkillNode).feature = fid
		gi += 1

	# ── Orbital (KARARLAR §5): Orbital Assembly is on the common path — the Moon
	# needs a station in orbit first. The rest of the orbit stays optional.
	_n("orbital_assembly", "Orbital Assembly", "Assemble modular stations in low orbit from Spaceport launches. The road to the Moon goes through orbit.",
		1500.0, Vector2(1, -3.5), ["rocketry"], "common", "Unlocks Space Station Districts",
		{"events": ["built:spaceport"], "common": true})
	_n("orbital_science", "Zero-G Research", "Microgravity laboratories aboard your stations.",
		1500.0, Vector2(2, -4), ["orbital_assembly"], "orbital", "Unlocks Zero-G Lab",
		{"grants": ["zero_g_nexus"], "legacy": false})
	_n("orbital_mirrors", "Orbital Mirrors", "Station-mounted mirrors that focus sunlight onto the surface.",
		2500.0, Vector2(2, -5), ["orbital_assembly"], "orbital", "Unlocks Orbital Mirrors",
		{"grants": ["orbital_mirrors"], "legacy": false})
	_n("orbital_shipyard", "Orbital Shipyard", "Dry docks in orbit. Not needed for the Moon.",
		4000.0, Vector2(1, -5), ["orbital_assembly"], "orbital", "Unlocks Orbital Shipyard",
		{"grants": ["orbital_shipyard"], "legacy": false})
	_n("orbital_offworld_market", "Offworld Trade", "Trade with passing haulers straight from orbit.",
		3500.0, Vector2(2, -6), ["orbital_shipyard"], "orbital", "Unlocks Offworld Market",
		{"grants": ["orbital_offworld_market"], "legacy": false})
	_n("orbital_logistics", "Orbital Logistics", "Planet-wide coordination of orbital trade fleets.",
		0.0, Vector2(3, -6), ["orbital_offworld_market"], "orbital", "Orbital Logistics Hub",
		{"act2": true, "legacy": false, "min_civ": 1})

	# ── Later civilizations ──────────────────────────────────────────────────
	# Civilization 0's tree shows the next tree's door at its top; double-click
	# opens it. Every later tree has the previous tree as its centre node
	# (KARARLAR §8): double-click goes down into it, and buying it is the buyout.
	_n("civilization_1_root", "Civilization 1", "The next civilization. Reached by the final rocket. Double-click to look at its research.",
		0.0, Vector2(0, -8), ["advanced_planet_rocket"], "common", "Civilization 1 research",
		{"act2": true, "min_civ": 1, "legacy": false, "shape": NodeShape.CIRCLE})
	_n(LEGACY_NODE_1, "Civilization 0", "Everything researched in Civilization 0. Double-click to open that tree. Buying it researches every missing node and level there at once.",
		0.0, Vector2.ZERO, [], "common", "Buyout: all missing Civilization 0 research",
		{"min_civ": 1, "civ": 1, "legacy": false, "common": true, "shape": NodeShape.CIRCLE})
	var fams := [["energy", "Energy", Vector2(2, 0)], ["production", "Production", Vector2(-2, 0)],
		["science", "Science", Vector2(-1.4, 1.8)], ["residential", "Residential", Vector2(1.4, 1.8)],
		["commercial", "Commercial", Vector2(0, -2)]]
	for f: Array in fams:
		_n("research_t1_subtype_" + String(f[0]), "%s City Roles" % String(f[1]),
			"Civilization 1: special districts of %s Cities." % String(f[1]),
			500.0, f[2], [LEGACY_NODE_1], String(f[0]), "Unlocks %s special district types" % String(f[1]),
			{"max": 3, "min_civ": 1, "civ": 1, "shape": NodeShape.HEXAGON})
	_n("orbital_storage", "Orbital Storage", "Civilization 1: fuel tanks in orbit.",
		600.0, Vector2(0, -3.2), ["research_t1_subtype_commercial"], "orbital", "Orbital Fuel Tank",
		{"act2": true, "min_civ": 1, "civ": 1, "legacy": false})

## Shorthand: opts = {max, shape, grants, requires, access, events, common,
## min_civ, civ, legacy, act2}. `pos` is in grid units.
func _n(id: String, name: String, desc: String, cost: float, pos: Vector2, parents: Array[String],
		branch: String, eff: String, opts: Dictionary = {}) -> void:
	var default_shape := NodeShape.HEXAGON
	_add_node(id, name, desc, cost, pos * GRID, parents, 1, eff, int(opts.get("max", 1)), opts.get("shape", default_shape))
	var node: SkillNode = nodes[id]
	node.branch = branch
	node.act2 = opts.get("act2", false)
	node.common = opts.get("common", false)
	node.min_civilization = int(opts.get("min_civ", 0))
	node.civilization = int(opts.get("civ", 0))
	node.legacy_eligible = opts.get("legacy", true)
	for s: String in opts.get("requires", []):
		node.requires.append(s)
	for s: String in opts.get("access", []):
		node.access.append(s)
	for s: String in opts.get("events", []):
		node.events.append(s)
	for b: String in opts.get("grants", []):
		node.grants.append(b)
		if not _grant_of.has(b):
			_grant_of[b] = []
		(_grant_of[b] as Array).append(id)

func _add_node(id: String, name: String, desc: String, cost: float, pos: Vector2, parents: Array[String], tier: int, eff: String, max_lv: int = 1, shape: NodeShape = NodeShape.HEXAGON) -> void:
	nodes[id] = SkillNode.new(id, name, desc, cost, pos, parents, tier, eff, max_lv, shape)

## Capital supports need two rights each (GDD §17.18).
func _ready() -> void:
	_also_grant("financial_district", ["public_administration", "trade_networks"])
	_also_grant("research_academy", ["public_administration", "advanced_research"])
	_also_grant("cryo_vault", ["public_administration", "high_rise"])

func _also_grant(building_id: String, ids: Array[String]) -> void:
	_grant_of[building_id] = ids.duplicate()

# ── Requirements ─────────────────────────────────────────────────────────────

## Why the extra conditions of `id` aren't met yet ("" when they are): the
## required nodes, product / mineral access and physical events. Parents are
## checked separately (parent_ok). An undiscovered mineral is never named.
func gate_block(id: String) -> String:
	var node: SkillNode = nodes.get(id, null)
	if node == null:
		return ""
	var missing: Array[String] = []
	if node.min_civilization > GameState.playable_content_type:
		missing.append("Civilization %d content (not playable in the demo)" % node.min_civilization)
	for s: String in node.requires:
		if not is_unlocked(s):
			var other: SkillNode = nodes.get(s, null)
			missing.append(other.name if other else s)
	for a: String in node.access:
		if not has_access(a):
			missing.append(access_label(a))
	for e: String in node.events:
		if not event_met(e):
			missing.append(event_label(e))
	return "" if missing.is_empty() else "Requires " + ", ".join(missing)

## True when the player can obtain this product / mineral.
func has_access(key: String) -> bool:
	match key:
		"goods": return is_unlocked("processing_basics")
		"fuel":  return is_unlocked("fuel_processing")
		"rare":  return is_unlocked("rare_processing")
		"moonstone": return Economy.is_mineral_discovered("moonstone")
	return false

func access_label(key: String) -> String:
	match key:
		"goods": return "Goods access (Basic Processing)"
		"fuel":  return "Fuel access (Fuel Processing)"
		"rare":  return "Rare access (Rare Processing)"
		"moonstone": return "Moonstone access" if Economy.is_mineral_discovered("moonstone") else "access to an undiscovered mineral"
	return key

## Physical milestones:
##   moon_production     a finished Production district on the Moon
##   moon_city           a finished City on the Moon
##   moon_moonstone_100  100 Moonstone mined on the Moon (GameState.moon_local_moonstone)
##   built:<building>    a finished building of that id anywhere
func event_met(key: String) -> bool:
	if key.begins_with("built:"):
		return _has_built(key.trim_prefix("built:"))
	match key:
		"moon_production": return _moon_has(POIData.POIType.MINING)
		"moon_city":       return _moon_has(POIData.POIType.CITY)
		"orbit_station":   return _home_station_built()
		"moon_moonstone_100": return GameState.moon_local_moonstone >= 100.0
	return false

func event_label(key: String) -> String:
	if key.begins_with("built:"):
		var def := BuildingDef.find(key.trim_prefix("built:"))
		return "a built %s" % (def.display_name if def else key.trim_prefix("built:"))
	match key:
		"moon_production": return "a finished Production district on the Moon"
		"orbit_station":   return "a finished Space Station in your home world's orbit"
		"moon_city":       return "a City on the Moon"
		"moon_moonstone_100":
			var mined := "%.0f" % minf(GameState.moon_local_moonstone, 100.0)
			var what := "Moonstone" if Economy.is_mineral_discovered("moonstone") else "local mineral"
			return "100 %s mined on the Moon (%s/100)" % [what, mined]
	return key

func _moon_has(poi_type: POIData.POIType) -> bool:
	for pp: PlanetProgress in GameState._planet_progress.values():
		var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
		if pd == null or pd.planet_type != PlanetData.Type.MOON:
			continue
		for p: POIData in pd.custom_pois:
			if p.poi_type == poi_type and not p.constructing and not p.is_orbital():
				return true
	return false

## A finished station in the home world's orbit.
func _home_station_built() -> bool:
	var pd: PlanetData = GameState.get_planet_data(GameState.home_planet_seed)
	if pd == null:
		return false
	for p: POIData in pd.custom_pois:
		if p.is_orbital() and not p.constructing:
			return true
	return false

func _has_built(building_id: String) -> bool:
	for pp: PlanetProgress in GameState._planet_progress.values():
		for b: Dictionary in pp.buildings:
			if b.get("building_id", "") == building_id and not b.get("constructing", false):
				return true
	return false

## True when at least one parent is bought (or the node has none).
func parent_ok(id: String) -> bool:
	var node: SkillNode = nodes.get(id, null)
	if node == null:
		return false
	if node.parents.is_empty():
		return true
	for p: String in node.parents:
		if is_unlocked(p):
			return true
	return false

# ── Buildings ────────────────────────────────────────────────────────────────

## True when every node that grants this building is bought.
func building_unlocked(building_id: String) -> bool:
	var ids: Array = _grant_of.get(building_id, [])
	if ids.is_empty():
		return false
	for id: String in ids:
		if not is_unlocked(id):
			return false
	return true

## The (first) node that grants a building ("" when none does).
func node_for_building(building_id: String) -> String:
	var ids: Array = _grant_of.get(building_id, [])
	return String(ids[0]) if not ids.is_empty() else ""

## Every node a building needs.
func nodes_for_building(building_id: String) -> Array:
	return _grant_of.get(building_id, [])

## Buildings have no levels any more; kept for older callers.
func get_building_max_level(_building_id: String) -> int:
	return 1

# ── State ────────────────────────────────────────────────────────────────────

## Canonical id for an id that may come from the old tree.
func canonical(id: String) -> String:
	if nodes.has(id):
		return id
	var mapped: Array = LEGACY_MAP.get(id, [])
	return String(mapped[0]) if not mapped.is_empty() else id

func is_unlocked(id: String) -> bool:
	if id == "root":
		return true
	if not nodes.has(id) and LEGACY_MAP.has(id):
		for c: String in LEGACY_MAP[id]:
			if not is_unlocked(c):
				return false
		return true
	return id in unlocked_skills or int(inherited_levels.get(id, 0)) > 0

## Effective level: the higher of the bought and the inherited level.
func get_skill_level(id: String) -> int:
	if id == "root":
		return 1
	id = canonical(id)
	var own := int(skill_levels.get(id, 1)) if id in unlocked_skills else 0
	return maxi(own, int(inherited_levels.get(id, 0)))

## Distinct strategy nodes bought individually in other branches of the same
## civilization (common path, roots and inherited levels don't count).
func cross_branch_count(id: String) -> int:
	var node: SkillNode = nodes.get(id, null)
	if node == null or node.common:
		return 0
	var n := 0
	for s: String in unlocked_skills:
		var other: SkillNode = nodes.get(s, null)
		if other == null or other == node or other.common or other.id == "root":
			continue
		if other.civilization == node.civilization and other.branch != node.branch:
			n += 1
	return n

## Cross-branch price factor of a node (1 on the common path).
func cross_branch_mult(id: String) -> float:
	return 1.0 + Balance.cfg.research_cross_branch * float(cross_branch_count(id))

## Price of the next level: base × target level × cross-branch factor.
func get_next_cost(id: String) -> float:
	if id == LEGACY_NODE_1:
		return buyout_cost(0)
	var node: SkillNode = nodes.get(id, null)
	if node == null:
		return 0.0
	var cur_lv := get_skill_level(id)
	if cur_lv >= node.max_level:
		return 0.0
	return node.cost * float(cur_lv + 1) * cross_branch_mult(id)

## Science still needed to bring a node to its max level at today's prices.
func missing_cost(id: String) -> float:
	var node: SkillNode = nodes.get(id, null)
	if node == null or node.act2:
		return 0.0
	var total := 0.0
	for lv in range(get_skill_level(id) + 1, node.max_level + 1):
		total += node.cost * float(lv) * cross_branch_mult(id)
	return total

# ── Fractal buyout (KARARLAR §8) ─────────────────────────────────────────────

## Real rights of a civilization's tree a buyout covers (no previews, no roots
## of later trees, no rights marked non-inheritable).
func buyout_nodes(civ: int) -> Array[String]:
	var out: Array[String] = []
	for id: String in nodes:
		var n: SkillNode = nodes[id]
		if n.civilization == civ and n.legacy_eligible and not n.act2 and id != "root" and id != LEGACY_NODE_1:
			out.append(id)
	return out

## Buyout price: exactly the sum of every missing node and level of that tree
## at today's prices (bought levels are left out; no discount, no fixed price).
func buyout_cost(civ: int) -> float:
	var total := 0.0
	for id: String in buyout_nodes(civ):
		total += missing_cost(id)
	return total

## Missing nodes and levels the buyout would grant.
func buyout_missing(civ: int) -> int:
	var n := 0
	for id: String in buyout_nodes(civ):
		n += maxi((nodes[id] as SkillNode).max_level - get_skill_level(id), 0)
	return n

func buyout_block(civ: int) -> String:
	if GameState.playable_content_type < civ + 1:
		return "Preview only — Civilization %d isn't playable in the demo" % (civ + 1)
	if buyout_missing(civ) == 0:
		return "Nothing missing"
	if GameState.science_points < buyout_cost(civ):
		return "Not enough Science"
	return ""

## Buys every missing level of that tree as inherited levels. Grants research
## rights only: no buildings, districts, discoveries or free updates.
func buyout(civ: int) -> bool:
	if buyout_block(civ) != "":
		return false
	if not GameState.spend_science(buyout_cost(civ)):
		return false
	for id: String in buyout_nodes(civ):
		var had := is_unlocked(id)
		inherited_levels[id] = (nodes[id] as SkillNode).max_level
		if not had:
			_on_first_level(id)
	version += 1
	skill_unlocked.emit(LEGACY_NODE_1)
	GameState.save()
	return true

## Why `id` can't be bought right now ("" when it can).
func purchase_block(id: String) -> String:
	var node: SkillNode = nodes.get(id, null)
	if node == null:
		return "Unknown research"
	if node.act2:
		return "Not available yet"
	if id == LEGACY_NODE_1:
		return buyout_block(0)
	var cur_lv := get_skill_level(id)
	if cur_lv >= node.max_level:
		return "Fully researched"
	if cur_lv == 0:
		if not parent_ok(id):
			return "Research a connected node first"
		var g := gate_block(id)
		if g != "":
			return g
	if GameState.science_points < get_next_cost(id):
		return "Not enough Science"
	return ""

## The purchase as a command (can_execute = purchase_block, execute = purchase_skill).
func research_command(id: String) -> GameCommand:
	var node: SkillNode = nodes.get(id, null)
	return GameCommand.make("research:" + id, node.name if node else id,
		func() -> void: purchase_skill(id), purchase_block.bind(id),
		{"cost": "%s Science" % Economy.fmt(get_next_cost(id))})

# Check if a skill can be purchased / upgraded
func can_purchase(id: String) -> bool:
	return purchase_block(id) == ""

# Buy or upgrade a skill node
func purchase_skill(id: String) -> bool:
	if id == LEGACY_NODE_1:
		return buyout(0)
	if not can_purchase(id):
		return false
	if not GameState.spend_science(get_next_cost(id)):
		return false
	var cur_lv := get_skill_level(id)
	if not id in unlocked_skills:
		unlocked_skills.append(id)
	skill_levels[id] = cur_lv + 1
	if cur_lv == 0:
		_on_first_level(id)
	version += 1
	skill_unlocked.emit(id)
	GameState.save()
	return true

## Side effects of a node's first level.
func _on_first_level(id: String) -> void:
	var node: SkillNode = nodes[id]
	for bid: String in node.grants:
		if building_unlocked(bid):
			GameState.unlock_building(bid)
	if id == "lunar_program":   # opens the Local System view and the Moon
		GameState.moon_unlocked = true
		GameState.unlock_changed.emit("moon_unlocked", true)

## Grants a node without paying (dev console, migration).
func grant(id: String, level: int = 1) -> void:
	if not nodes.has(id):
		return
	if not id in unlocked_skills:
		unlocked_skills.append(id)
		_on_first_level(id)
	skill_levels[id] = clampi(maxi(level, int(skill_levels.get(id, 0))), 1, (nodes[id] as SkillNode).max_level)
	version += 1
	skill_unlocked.emit(id)

# Visible when bought or a parent is bought. Previews show one step
# earlier — as soon as their parent is visible — so the road ahead is hinted.
func is_visible(id: String) -> bool:
	if has_meta("debug_reveal_all") and get_meta("debug_reveal_all"):
		return true
	if id == "root" or is_unlocked(id):
		return true
	var node: SkillNode = nodes.get(id, null)
	if node == null:
		return false
	for p in node.parents:
		if is_unlocked(p):
			return true
		if node.act2 and p != id and is_visible(p):
			return true
	return false

## Effect line for the tooltip (numbers from the balance profile where they live there).
func effect_text(id: String) -> String:
	var node: SkillNode = nodes.get(id, null)
	if node == null:
		return ""
	match id:
		"civic_enterprise":
			return "+%s Credits / min per 1,000 idle population" % Economy.fmt(Balance.cfg.idle_pop_credits_per_1000)
		"free_research":
			return "+%s Science / min per 1,000 idle population" % Economy.fmt(Balance.cfg.idle_pop_science_per_1000)
	return node.effect_desc

# ── Save / load ──────────────────────────────────────────────────────────────

func reset_to_defaults() -> void:
	unlocked_skills.clear()
	skill_levels.clear()
	inherited_levels.clear()
	for s: String in DEFAULT_SKILLS:
		unlocked_skills.append(s)
		skill_levels[s] = 1
	version += 1

func get_save_data() -> Dictionary:
	return {"unlocked_skills": unlocked_skills.duplicate(), "skill_levels": skill_levels.duplicate(),
		"inherited_levels": inherited_levels.duplicate()}

## Loads bought research; old Act I ids are converted (GDD §17.23–§17.24):
## merged bonus pairs keep the higher old level, capped at the new max.
func load_save_data(data: Dictionary) -> void:
	reset_to_defaults()
	var old_levels: Dictionary = data.get("skill_levels", {})
	for raw in data.get("unlocked_skills", []):
		var sid := String(raw)
		var targets: Array = [sid] if nodes.has(sid) else LEGACY_MAP.get(sid, [])
		for t: String in targets:
			var node: SkillNode = nodes.get(t, null)
			if node == null or node.act2:
				continue
			var lv := clampi(int(old_levels.get(sid, 1)), 1, node.max_level)
			if not t in unlocked_skills:
				unlocked_skills.append(t)
			skill_levels[t] = maxi(lv, int(skill_levels.get(t, 0)))
	var inh: Dictionary = data.get("inherited_levels", {})
	for k in inh:
		if nodes.has(String(k)):
			inherited_levels[String(k)] = int(inh[k])
	version += 1

# ── Dynamic Modifiers read by GameState/ProductionManager ─────────────────────

func _lv(id: String) -> int:
	return get_skill_level(id)

func get_solar_mult() -> float:
	return 1.0 + 0.10 * _lv("solar_efficiency")

## Mines no longer speed up (Extraction Efficiency raises output instead).
func get_mine_speed_mult() -> float:
	return 1.0

func get_mine_output_mult() -> float:
	return 1.0 + 0.10 * _lv("extraction_efficiency")

func get_fuel_mult() -> float:
	return 1.0 + 0.10 * _lv("fuel_process_efficiency")

func get_credits_mult() -> float:
	return 1.0 + 0.10 * _lv("trade_efficiency")

func get_science_mult() -> float:
	return 1.0 + 0.10 * _lv("science_efficiency")

## Housing from buildings (population capacity).
func get_housing_mult() -> float:
	return 1.0 + 0.10 * _lv("housing_efficiency")

func get_energy_consume_mult() -> float:
	return maxf(0.1, 1.0 - 0.05 * _lv("grid_efficiency"))

## Cluster Planning: every proximity / centre contribution ×(1 + 0.1·level).
func get_proximity_mult() -> float:
	return 1.0 + 0.10 * _lv("cluster_planning")

## Independent Centres: points added to a distance bonus that is already > 0.
func get_distance_bonus_add() -> float:
	return 0.10 * _lv("independent_centers")

## Geography specialisation: the feature's bonus ×(1 + 0.1·level).
func get_feature_mult(feature_id: String) -> float:
	return 1.0 + 0.10 * _lv("geography_specialization:" + feature_id)

## Mixed Networks: families that support `family` across the family line.
func cross_families(family: String) -> Array:
	if not is_unlocked("cross_networks"):
		return []
	return CROSS_FAMILIES.get(family, [])

## Idle-population income per minute per 1,000 idle (0 until researched).
func idle_credits_per_1000() -> float:
	return Balance.cfg.idle_pop_credits_per_1000 if is_unlocked("civic_enterprise") else 0.0

func idle_science_per_1000() -> float:
	return Balance.cfg.idle_pop_science_per_1000 if is_unlocked("free_research") else 0.0

## Production Reserve: +2% per full 10% of idle population, at most +20%.
func reserve_mult(idle_ratio: float) -> float:
	if not is_unlocked("population_reserve"):
		return 1.0
	return 1.0 + minf(0.02 * floorf(clampf(idle_ratio, 0.0, 1.0) * 10.0), 0.20)

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
