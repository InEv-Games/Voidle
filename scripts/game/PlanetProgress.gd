class_name PlanetProgress
extends Resource

# ── Identity ────────────────────────────────────────────────────────────────
@export var planet_seed: int = 0

# ── Level & Limits ──────────────────────────────────────────────────────────
@export var level: int = 1
@export var is_upgrading: bool = false
@export var upgrade_progress: float = 0.0
@export var upgrade_duration: float = 60.0

const BASE_DISTRICTS:        int = 2   # district slots at level 1
const BASE_ORBITAL_DISTRICTS: int = 1  # orbital slots at level 1–5

@export var max_districts:          int = BASE_DISTRICTS
@export var max_orbital_districts:  int = BASE_ORBITAL_DISTRICTS
@export var max_mining_lv:          int = 1
@export var max_generators:         int = 2
@export var max_spaceports:         int = 0

# ── Districts ────────────────────────────────────────────────────────────────
@export var districts_used: int = 0

# ── Buildings ────────────────────────────────────────────────────────────────
## Each entry: { "district_id": String, "building_id": String, "amount": int }
@export var buildings: Array[Dictionary] = []

# ── Resources ────────────────────────────────────────────────────────────────
@export var stored_resources: Dictionary = {}

func has_building(bid: String) -> bool:
	for entry in buildings:
		if entry.get("building_id", "") == bid and not entry.get("constructing", false):
			return true
	return false

# ── Unlock flags ─────────────────────────────────────────────────────────────
@export var is_colonizing:      bool = false
@export var colonize_progress:  float = 0.0
@export var colonize_duration:  float = 30.0

@export var is_colonized:   bool = false
@export var has_spaceport:  bool = false
@export var moons_unlocked: bool = false
## Moon landing: 0 none, 1 lander parked in orbit, 2 landed (GameState).
@export var lander_state: int = 0
## The planet's Orbit — a unique City-like hub whose districts are Space
## Stations. 0 = not founded; each level opens one more station (Leveling).
@export var orbit_level: int = 0

# ── District upgrade levels ──────────────────────────────────────────────────
## { district_label -> upgrade_level: int }, default 1
@export var district_levels: Dictionary = {}
## { district_label -> progress: float 0..1 } — districts currently upgrading
@export var district_upgrading: Dictionary = {}
## { city_label -> city level }, default 1 (see Leveling)
@export var city_levels: Dictionary = {}
## City label -> 0..1 while that City levels up (ProductionManager ticks it).
@export var city_upgrading: Dictionary = {}
## 0..1 while the Orbit levels up, -1 otherwise (ProductionManager ticks it).
@export var orbit_upgrading: float = -1.0

## Seconds a City takes to reach `target_lv`.
static func city_upgrade_duration(target_lv: int) -> float:
	return 10.0 * target_lv

# ────────────────────────────────────────────────────────────────────────────

## Duration in seconds for upgrading a district to the given target level.
static func district_upgrade_duration(target_lv: int) -> float:
	return 5.0 * target_lv

## Planet level-up cost. Credits follow the balance profile ("legacy" table or
## geometric); materials are the same either way for now.
func get_upgrade_cost() -> Dictionary:
	var cost := {}
	var next_lv := level + 1
	match next_lv:
		2:
			cost["credits"] = 4000
		3:
			cost["credits"] = 12000
			cost["ANY_T1"]  = 200
		_:
			cost["credits"] = 8000 * next_lv
			cost["ANY_T1"]  = 250 * next_lv          # any raw resources
			if next_lv > 4:
				cost[Economy.GOODS] = 50 * (next_lv - 4)  # later levels need Consumer Goods
	var c: BalanceConfig = Balance.cfg
	if c.planet_level_credit_mode == "geometric":
		cost["credits"] = roundf(Balance.geometric(c.planet_level_credit_base, c.planet_level_credit_growth, next_lv - 2))
	return cost

func recalculate_limits() -> void:
	max_districts         = BASE_DISTRICTS + (level - 1)
	max_orbital_districts = orbit_level   # one Space Station per Orbit level

	var st = null
	if Engine.has_singleton("SceneTree") and Engine.get_main_loop():
		st = Engine.get_main_loop().root.get_node_or_null("SkillTree")
	if st and st.has_method("get_max_districts_add"):
		max_districts += st.get_max_districts_add()

	max_mining_lv  = 1 + (level - 1)
	max_generators = 2 + (level - 1) * 2
	max_spaceports = 1 if level >= 2 else 0

func districts_free() -> int:
	return max_districts - districts_used

func can_build(building_type: String) -> bool:
	match building_type:
		"SpacePort": return districts_free() >= 2 and max_spaceports > 0 and not has_spaceport
		_:           return districts_free() >= 1

func buildings_in_district(district_label: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for b: Dictionary in buildings:
		if b.get("district_id", "") == district_label:
			result.append(b)
	return result

## Building slots: 3 + 2 per level; the Capital District (a City) holds only a
## few hand-picked buildings — 2 + 1 per level (its Civic Office and a 2-slot
## Spaceport fit at Lv2).
func district_slots(poi: POIData) -> int:
	var lv: int = district_levels.get(poi.label, 1)
	if poi.is_orbital():
		return 1   # a station holds one module; the Orbit levels instead
	if poi.is_city():
		return lv + 1
	return 3 + (lv - 1) * 2

## Slots one more level adds to this district.
static func slots_per_level(poi: POIData) -> int:
	if poi.is_orbital():
		return 0
	return 1 if poi.is_city() else 2

## Cities a planet may hold: one per planet level (a soft cap the player lifts
## by levelling the planet, instead of a hard distance rule).
func max_cities() -> int:
	return Leveling.max_cities(self)

func can_upgrade_district(district_label: String) -> bool:
	var lv: int = district_levels.get(district_label, 1)
	return lv < Balance.cfg.max_district_level and not district_upgrading.has(district_label)

func is_district_upgrading(district_label: String) -> bool:
	return district_upgrading.has(district_label)

func upgrade_district(district_label: String) -> void:
	if can_upgrade_district(district_label):
		district_upgrading[district_label] = 0.0  # progress 0..1

func slots_used_in_district(district_label: String) -> int:
	var total: int = 0
	for b: Dictionary in buildings_in_district(district_label):
		var def := BuildingDef.find(b.get("building_id", ""))
		if def != null:
			total += def.slot_cost * b.get("amount", 1)
	return total

## `paid` = credits really paid for this one building (the refund ledger's C,
## GDD §15.6); merged stacks add their C together.
func build_in_district(district: POIData, building_id: String,
		target_mineral: String = "", paid: float = 0.0, paid_mats: Dictionary = {}) -> bool:
	var def := BuildingDef.find(building_id)
	if def == null:
		return false
	if slots_used_in_district(district.label) + def.slot_cost > district_slots(district):
		return false
	if def.planet_limit_reached(self):
		return false   # unique on the planet
	
	# Try to find an identical existing building to merge into
	var merge_idx := -1
	for i in buildings.size():
		var b: Dictionary = buildings[i]
		if b.get("district_id") == district.label and b.get("building_id") == building_id and not b.get("constructing", false):
			var b_tgt: String = b.get("target_mineral", "")
			if target_mineral == b_tgt or target_mineral == "":
				merge_idx = i
				break
	
	var entry := { "district_id": district.label, "building_id": building_id, "amount": 1, "constructing": true, "uid": str(randi()), "paid": paid, "paid_mats": paid_mats.duplicate() }
	if merge_idx != -1:
		entry["merge_into"] = merge_idx
		
	# Mines target a specific raw mineral — caller may supply one, otherwise left blank
	if def.output_type == BuildingDef.OutputType.RAW_MINERAL and target_mineral != "":
		entry["target_mineral"] = target_mineral
		
	buildings.append(entry)
	if building_id == "spaceport":
		has_spaceport = true
	return true

## Stack one more of an existing building — goes through construction before merging.
func stack_building_unchecked(district_label: String, building_id: String, merge_into_entry: Dictionary = {}) -> bool:
	for i in buildings.size():
		var b: Dictionary = buildings[i]
		# If we specified an exact entry, merge into that, otherwise find any matching one
		var match_b = is_same(b, merge_into_entry) if not merge_into_entry.is_empty() else (b.get("district_id") == district_label and b.get("building_id") == building_id)
		if match_b and not b.get("constructing", false):
			var entry := {
				"district_id": district_label,
				"building_id": building_id,
				"amount": 1,
				"constructing": true,
				"merge_into": i,
				"uid": str(randi())
			}
			buildings.append(entry)
			return true
	return false

func upgrade_building(entry: Dictionary) -> bool:
	var idx := building_real_index(entry)
	if idx == -1: return false
	var b := buildings[idx]
	var def := BuildingDef.find(b.get("building_id", ""))
	if def == null: return false
	
	var cur_lv: int = b.get("level", 1)
	var amt: int = b.get("amount", 1)
	var cost := def.get_upgrade_cost(cur_lv, amt)
	
	if GameState.spend_credits(cost):
		b["level"] = cur_lv + 1
		return true
	return false

func split_building(entry: Dictionary, split_amount: int) -> bool:
	var idx := building_real_index(entry)
	if idx == -1: return false
	var b := buildings[idx]
	var current_amt: int = b.get("amount", 1)
	if split_amount <= 0 or split_amount >= current_amt:
		return false
		
	var c := stack_paid(b)
	# Reduce current stack
	b["amount"] = current_amt - split_amount
	
	# Create new stack (the paid credits split by count)
	var new_stack := b.duplicate(true)
	new_stack["amount"] = split_amount
	new_stack["paid"] = c * float(split_amount) / float(current_amt)
	b["paid"] = c - float(new_stack["paid"])
	var m := stack_mats(b)
	new_stack["paid_mats"] = scale_mats(m, float(split_amount) / float(current_amt))
	b["paid_mats"] = scale_mats(m, 1.0 - float(split_amount) / float(current_amt))
	new_stack["uid"] = str(randi())
	buildings.append(new_stack)
	return true

func remove_building_stack(entry: Dictionary) -> void:
	var idx = building_real_index(entry)
	if idx >= 0:
		buildings.remove_at(idx)
		for b in buildings:
			if b.has("merge_into"):
				var midx: int = b["merge_into"]
				if midx == idx:
					b.erase("merge_into")
				elif midx > idx:
					b["merge_into"] = midx - 1

## Folds a finished entry into an identical finished one in the same district
## (same building, mine target and level). Returns true when it merged — the
## entry is then gone from `buildings`.
func merge_identical(entry: Dictionary) -> bool:
	if entry.get("constructing", false):
		return false
	for b: Dictionary in buildings:
		if is_same(b, entry) or b.get("constructing", false):
			continue
		if b.get("district_id") == entry.get("district_id") \
				and b.get("building_id") == entry.get("building_id") \
				and b.get("target_mineral", "") == entry.get("target_mineral", "") \
				and int(b.get("level", 1)) == int(entry.get("level", 1)):
			b["paid"] = stack_paid(b) + stack_paid(entry)
			var sum := stack_mats(b).duplicate()
			for id: String in stack_mats(entry):
				sum[id] = float(sum.get(id, 0.0)) + float(stack_mats(entry)[id])
			b["paid_mats"] = sum
			b["amount"] = int(b.get("amount", 1)) + int(entry.get("amount", 1))
			remove_building_stack(entry)
			return true
	return false

## Merges every set of identical finished buildings into one stack.
func consolidate_buildings() -> void:
	var i := 0
	while i < buildings.size():
		if not merge_identical(buildings[i]):
			i += 1

func add_resource(resource_id: String, amount: float) -> void:
	GameState.add_resource(resource_id, amount)

## Credits really paid for a stack and not refunded yet (C). Stacks from older
## saves have no record: their model's base price per building is assumed.
static func stack_paid(entry: Dictionary) -> float:
	if entry.has("paid"):
		return float(entry["paid"])
	var def := BuildingDef.find(entry.get("building_id", ""))
	return (def.base_cost if def != null else 0.0) * float(entry.get("amount", 1))

## Materials really paid for a stack and not refunded yet ({id: amount});
## empty for stacks from older saves.
static func stack_mats(entry: Dictionary) -> Dictionary:
	return entry.get("paid_mats", {})

## Every amount × f (a share of a material record).
static func scale_mats(mats: Dictionary, f: float) -> Dictionary:
	var out := {}
	for id: String in mats:
		out[id] = float(mats[id]) * f
	return out

## Credits really paid for district levels above Lv1 ({label: credits}).
var level_paid: Dictionary = {}

## Returns the true array index of an entry using reference equality.
## Avoids the value-equality bug with pp.buildings.find(entry) when two
## entries have identical content (e.g. two Solar Panels in the same district).
func building_real_index(entry: Dictionary) -> int:
	for i in buildings.size():
		if is_same(buildings[i], entry):
			return i
	return -1

func consume_resource(resource_id: String, amount: float) -> bool:
	return GameState.consume_resource(resource_id, amount)

static func make(seed_val: int) -> PlanetProgress:
	var p := PlanetProgress.new()
	p.planet_seed = seed_val
	p.recalculate_limits()
	return p

func get_total_building_levels() -> int:
	var total := 0
	for b in buildings:
		if not b.get("constructing", false):
			total += b.get("level", 1) * b.get("amount", 1)
	return total
