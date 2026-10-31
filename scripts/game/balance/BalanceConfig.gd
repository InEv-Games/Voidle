## One balance profile: every tunable economy number in one place, editable in
## the inspector. Profiles live in res://resources/balance/ (profile_*.tres);
## the active one is Balance.cfg (see Balance.gd).
##
## Fields marked "(not used yet)" are reserved for later milestones so profile
## files don't have to change shape as systems land (docs/design/PLAN.md).
class_name BalanceConfig
extends Resource

## Shown in the dev console and written to saves.
@export var profile_name: String = "current"

@export_group("Income")
## Every Science income (districts, buildings, idle population) × this —
## playtest 30.10: Science came four times too fast; research prices stay.
@export var science_income_mult: float = 0.25

@export_group("Start")
@export var start_credits: float = 1000.0
@export var start_science: float = 0.0

@export_group("Buildings")
## Each extra building makes the next one dearer by this factor.
@export var building_cost_growth: float = 1.35
## What counts toward that price: every building in the district, or only the same model.
@export_enum("district_all", "model") var building_counter_scope: String = "district_all"
## Named materials a building asks for on top of credits, by its economic tier
## (BuildingDef.econ_tier; Tier 0: none). Integration decisions 29.10 §8.1. A
## model's own BuildingDef.build_materials overrides these.
@export var build_materials_tier1: Dictionary = {"ferrite": 30.0, "goods": 5.0}
@export var build_materials_tier2: Dictionary = {"ferrite": 90.0, "goods": 15.0, "fuel": 5.0}
@export var build_materials_tier3: Dictionary = {"ferrite": 180.0, "goods": 45.0, "fuel": 15.0, "rare_elements": 5.0}
## Civilization 1 models (not playable in the demo).
@export var build_materials_tier4: Dictionary = {"ferrite": 180.0, "goods": 45.0, "fuel": 15.0, "rare_elements": 5.0}

@export_group("Districts")
@export var district_base_cost: float = 300.0
## Per district already in the City, whatever its type.
@export var district_cost_growth: float = 1.6
@export var max_district_level: int = 10
## Credits to go from level L to L+1: base × growth^(L−1).
@export var level_credit_base: float = 400.0
@export var level_credit_growth: float = 2.2
## District output by level: linear 1 + step·(L−1), or geometric growth^(L−1).
@export_enum("linear", "geometric") var level_output_mode: String = "linear"
@export var level_output_step: float = 0.5
@export var level_output_growth: float = 1.25

@export_group("Cities")
@export var city_base_cost: float = 2500.0
## Per City already on the planet (the first City is free).
@export var city_cost_growth: float = 2.5
## Housing every City gives before any Population buildings.
@export var city_base_pop: int = 15000
## Total district levels needed for City level n: round(a·n² + b·n + c).
@export var city_level_req_a: float = 1.5
@export var city_level_req_b: float = -1.5
@export var city_level_req_c: float = 0.0
## Credits for City level n: base × growth^(n−2).
@export var city_level_credit_base: float = 1500.0
@export var city_level_credit_growth: float = 2.5
## Population for City level n: base × (n−1 if linear) × growth^(n−2).
@export var city_level_pop_base: float = 4000.0
@export var city_level_pop_linear: bool = true
@export var city_level_pop_growth: float = 1.0

@export_group("Population")
## Population the k-th district of a City takes to found: base × (1 + step·k).
@export var district_found_pop_base: float = 3000.0
@export var district_found_pop_step: float = 0.25   # 0.5 starved the early game of housing (playtest 23.10)
## Population for a district level L → L+1: base × growth^(L−1).
@export var level_pop_base: float = 2000.0
@export var level_pop_growth: float = 2.0
## Worst slowdown from an overpopulated / underpowered economy (0.5 = half speed).
@export var pop_max_slowdown: float = 0.5
@export var energy_max_slowdown: float = 0.5

@export_group("Planet")
## City levels needed for planet level n: a·n + b.
@export var planet_level_req_a: int = 2
@export var planet_level_req_b: int = -1
## "legacy": 4k, 12k (+200 raw), then 8k·n (+250·n raw, Goods past Lv4).
## "geometric": credit_base × credit_growth^(n−2), same materials.
@export_enum("legacy", "geometric") var planet_level_credit_mode: String = "legacy"
@export var planet_level_credit_base: float = 2500.0
@export var planet_level_credit_growth: float = 1.8

@export_group("Orbit")
@export var max_orbit_level: int = 5
## Orbit level credits = City level credits × this.
@export var orbit_level_credit_mult: float = 1.2

@export_group("Location")
## Surface radius of a planet_size 1.0 world, in km (Location.radius_km).
@export var planet_radius_km: float = 6000.0
## Distance bands as fractions of the district's City reach
## (TerrainSampler.city_reach_deg): ≤ very near, ≤ near, ≤ mid, < far, then very
## far. Relative, so the whole range fits inside the area a City may build in —
## at every City level and on small bodies (playtest 23.10, KARARLAR §10).
@export var distance_very_near_frac: float = 0.40
@export var distance_near_frac: float = 0.60
@export var distance_mid_frac: float = 0.80
@export var distance_far_frac: float = 0.95
## Distance bonus by the nearest other district's band (very near … very far).
@export var distance_bonuses: Array[float] = [0.0, 0.125, 0.25, 0.375, 0.5]
## Each same-family district very near / near adds this (no diminishing).
@export var proximity_very_near: float = 0.10
@export var proximity_near: float = 0.05
## Total cap on the same-family proximity bonus; 0 = no cap.
@export var proximity_cap: float = 0.0
## Each City (its Capital District) very near / near adds this to every family.
@export var centre_very_near: float = 0.10
@export var centre_near: float = 0.05

@export_group("Terrain")
## Within this distance of a visible feature's edge a site counts as near it (FeatureMap).
@export var terrain_near_km: float = 250.0
## Steps (integration decisions 29.10 §3.1): ON a feature that helps a family
## +100% (×2), NEAR one +50% (×1.5). Different feature types add up; the same
## type never counts twice. Same on Earth, the Moon and every other world.
@export var terrain_on_bonus: float = 1.0
@export var terrain_near_bonus: float = 0.5
## Which feature boosts which specialist district family's base output (§3).
## Families: production, science, residential, commercial, energy. The Capital
## gets no geography bonus. A feature may also host special buildings
## (BuildingDef.required_features) — that is separate data and adds no bonus.
@export var terrain_bonuses: Dictionary = {
	"terrain_mountain":   {"production": 1.0, "science": 1.0},
	"terrain_plain":      {},
	"terrain_forest":     {"production": 1.0},
	"terrain_seacoast":   {"residential": 1.0, "commercial": 1.0},
	"terrain_lakeside":   {"residential": 1.0},
	"terrain_river":      {"residential": 1.0, "commercial": 1.0, "energy": 1.0},
	"terrain_desert":     {"energy": 1.0},
	"terrain_tundra":     {"science": 1.0},
	"terrain_glacier":    {"science": 1.0},
	"terrain_volcanic":   {"production": 1.0},
	"terrain_geothermal": {"energy": 1.0},
	"terrain_ruins":      {"production": 1.0, "science": 1.0, "residential": 1.0, "commercial": 1.0, "energy": 1.0},
	# Moon only
	"terrain_crater":     {"production": 1.0},
	"terrain_caves":      {"residential": 1.0},
	"terrain_ion_storm":  {"energy": 1.0},
}

@export_group("Storage")
@export var base_cap_raw: float = 500.0
@export var base_cap_goods: float = 200.0
@export var base_cap_fuel: float = 200.0
@export var base_cap_rare: float = 100.0

@export_group("Idle population")
## Per minute per 1,000 idle housing, once Civic Enterprise / Free Research is researched.
@export var idle_pop_credits_per_1000: float = 10.0
@export var idle_pop_science_per_1000: float = 2.0
@export var idle_pop_counts_city_base: bool = true
## (not used yet)
@export var idle_pop_uses_level_mult: bool = false

@export_group("Trade")
@export var trade_sell_ratio: float = 0.9
@export var trade_buy_ratio: float = 1.1
## Dynamic prices (KARARLAR §10): buying raises a product's price, selling lowers
## it; this many credits' worth of trade moves the price by 100%.
@export var trade_depth_credits: float = 4000.0
## Seconds for half of a price change to fade back toward the reference.
@export var trade_recovery_half_life: float = 120.0
## Price multiplier limits (×reference): never below / above these.
@export var trade_price_min: float = 0.4
@export var trade_price_max: float = 3.0

@export_group("Research")
## Price surcharge per distinct strategy node bought in another branch (GDD §17.5).
@export var research_cross_branch: float = 0.02

@export_group("Offline")
## Kill switch for offline gains (KARARLAR §4). Off: only the time away is shown.
@export var offline_progress_enabled: bool = false
