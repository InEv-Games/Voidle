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

@export_group("Start")
@export var start_credits: float = 1000.0
@export var start_science: float = 0.0

@export_group("Buildings")
## Each extra building makes the next one dearer by this factor.
@export var building_cost_growth: float = 1.35
## What counts toward that price: every building in the district, or only the same model.
@export_enum("district_all", "model") var building_counter_scope: String = "district_all"
## Named materials a building asks for on top of credits, by tier (Tier 1: none).
## Fixed per building — the repeat counter grows credits only. A model's own
## BuildingDef.build_materials overrides these.
@export var build_materials_tier2: Dictionary = {"ferrite": 30.0, "goods": 5.0}
@export var build_materials_tier3: Dictionary = {"ferrite": 90.0, "goods": 15.0, "fuel": 5.0, "rare_elements": 2.0}
@export var build_materials_tier4: Dictionary = {"ferrite": 90.0, "goods": 15.0, "fuel": 5.0, "rare_elements": 2.0}

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
@export var district_found_pop_step: float = 0.5
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
## Within this distance of a visible feature's edge a site gets half its bonus (FeatureMap).
@export var terrain_near_km: float = 250.0
## Full bonus on each visible feature, by output family (GDD §6.1). Families:
## production, science, residential, commercial, energy_solar, energy_wind,
## energy_tidal, energy_geothermal.
@export var terrain_bonuses: Dictionary = {
	"terrain_mountain":   {"production": 0.20, "science": 0.30},
	"terrain_plain":      {"residential": 0.20, "commercial": 0.10},
	"terrain_forest":     {"residential": 0.10, "science": 0.10},
	"terrain_seacoast":   {"residential": 0.20, "commercial": 0.20, "energy_tidal": 0.20},
	"terrain_lakeside":   {"residential": 0.20, "science": 0.10},
	"terrain_river":      {"residential": 0.10, "commercial": 0.20},
	"terrain_desert":     {"energy_solar": 0.30, "science": 0.10},
	"terrain_tundra":     {"science": 0.20, "residential": 0.10},
	"terrain_glacier":    {"science": 0.20},
	"terrain_volcanic":   {"energy_geothermal": 0.30, "production": 0.20},
	"terrain_geothermal": {"energy_geothermal": 0.40},
	"terrain_wind":       {"energy_wind": 0.30},
	"terrain_ruins":      {"science": 0.30, "commercial": 0.20},
	"terrain_crater":     {"production": 0.10, "science": 0.20},
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

@export_group("Trade (not used yet)")
@export var trade_sell_ratio: float = 0.9
@export var trade_buy_ratio: float = 1.1

@export_group("Research")
## Price surcharge per distinct strategy node bought in another branch (GDD §17.5).
@export var research_cross_branch: float = 0.02

@export_group("Offline")
## Kill switch for offline gains (KARARLAR §4). Off: only the time away is shown.
@export var offline_progress_enabled: bool = false
