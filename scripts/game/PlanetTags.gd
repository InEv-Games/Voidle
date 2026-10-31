class_name PlanetTags
extends RefCounted

## Planet traits (playtest 31.10): every world shows two plain tags — its size
## and its atmosphere — and three trait slots. The first opens with the world
## (the home world starts with CRADLE; any other draws a pick when scanned);
## the others need a planet level (Balance trait_slot_levels) and are opened
## by paying Science and Rare Elements (trait_slot_costs) — then the player
## picks one of three, roguelite style. Most traits are a planet-wide support
## counted with the Orbit's (Economy.planet_bonus): +10% Science on this world;
## the strong ones of the later slots add districts per City or building slots.
##
## State lives in GameState: planet_tags { "seed": [trait id, …] } and
## tag_offers { "seed": [[id, id, id], …] } (offers waiting for a pick, kept in
## the save so reloading can't reroll them).

## How many traits are offered per pick.
const OFFER_SIZE := 3
## Trait slots per world.
const SLOTS := 3
## Effects that are counts, not fractions ("+2 districts per City").
const COUNT_EFFECTS: Array[String] = ["city_districts", "district_slots"]
## The home world's trait.
const CRADLE := "cradle_world"

## id: { name, desc, effect { resource_id: +fraction }, types (PlanetData.Type,
## empty = any world), weight (how often it is offered) }. "raw" in an effect
## means raw and processed output (raw, goods, fuel, rare elements).
const CATALOGUE := {
	"cradle_world":     {"name": "Cradle World", "desc": "Where your people began. Home feels like home.",
		"effect": {"population": 0.10}, "types": [], "weight": 0},
	"rich_crust":       {"name": "Rich Crust", "desc": "Mineral veins run close to the surface.",
		"effect": {"raw": 0.10}, "types": [], "weight": 10},
	"fertile_basins":   {"name": "Fertile Basins", "desc": "Sheltered lowlands where settlements thrive.",
		"effect": {"population": 0.10}, "types": [], "weight": 10},
	"clear_skies":      {"name": "Clear Skies", "desc": "Cloudless nights and still air for instruments.",
		"effect": {"science": 0.10}, "types": [], "weight": 10},
	"busy_crossroads":  {"name": "Busy Crossroads", "desc": "Haulers and traders like to stop here.",
		"effect": {"credits": 0.10}, "types": [], "weight": 10},
	"restless_core":    {"name": "Restless Core", "desc": "A warm, active interior that is easy to tap.",
		"effect": {"energy": 0.10}, "types": [], "weight": 10},
	"ancient_archives": {"name": "Ancient Archives", "desc": "Someone studied this world long before you.",
		"effect": {"science": 0.15, "credits": -0.05}, "types": [], "weight": 5},
	"boomtown":         {"name": "Boomtown", "desc": "Fast money, fast growth, cramped streets.",
		"effect": {"credits": 0.15, "population": -0.05}, "types": [], "weight": 5},
	"deep_lodes":       {"name": "Deep Lodes", "desc": "Huge deposits — mining them takes power.",
		"effect": {"raw": 0.15, "energy": -0.05}, "types": [], "weight": 5},
	"low_gravity":      {"name": "Low Gravity", "desc": "Light loads, light structures, easy power.",
		"effect": {"energy": 0.15}, "types": [PlanetData.Type.MOON, PlanetData.Type.BARREN, PlanetData.Type.ASTEROID], "weight": 6},
	"regolith_seas":    {"name": "Regolith Seas", "desc": "Plains of loose rock ready to be sifted.",
		"effect": {"raw": 0.15}, "types": [PlanetData.Type.MOON, PlanetData.Type.BARREN], "weight": 6},
	"earthrise_views":  {"name": "Earthrise Views", "desc": "Settlers come for the view and stay.",
		"effect": {"population": 0.15}, "types": [PlanetData.Type.MOON], "weight": 6},
	"stable_plates":    {"name": "Stable Plates", "desc": "Quiet ground: every scale works a little better.",
		"effect": {"credits": 0.05, "science": 0.05, "raw": 0.05}, "types": [], "weight": 3},
	# strong ones: only in the slots you pay for (min_slot)
	"grand_plateaus":   {"name": "Grand Plateaus", "desc": "Wide, level land: cities spread without limits.",
		"effect": {"city_districts": 2}, "types": [], "weight": 4, "min_slot": 1},
	"deep_bedrock":     {"name": "Deep Bedrock", "desc": "Solid ground under every quarter: build taller.",
		"effect": {"district_slots": 1}, "types": [], "weight": 4, "min_slot": 1},
	"golden_age":       {"name": "Golden Age", "desc": "Everything here seems to go right.",
		"effect": {"credits": 0.20, "science": 0.20}, "types": [], "weight": 2, "min_slot": 2},
}

# ── Queries ──────────────────────────────────────────────────────────────────

static func info(id: String) -> Dictionary:
	return CATALOGUE.get(id, {})

static func traits_of(planet_seed: int) -> Array:
	return GameState.planet_tags.get(str(planet_seed), [])

static func offers_of(planet_seed: int) -> Array:
	return GameState.tag_offers.get(str(planet_seed), [])

## Worlds with a trait pick waiting, as seeds.
static func pending_seeds() -> Array[int]:
	var out: Array[int] = []
	for k: String in GameState.tag_offers:
		if not (GameState.tag_offers[k] as Array).is_empty():
			out.append(int(k))
	return out

## The planet-wide fraction a world's traits give `id` (Economy.planet_bonus).
static func planet_fraction(planet_seed: int, id: String) -> float:
	var key := Economy.RAW if id in [Economy.RAW, Economy.GOODS, Economy.FUEL, Economy.RARE] else id
	if GameState.get_planet_data(planet_seed) == null:
		return 0.0
	var total := 0.0
	for tid: String in traits_of(planet_seed):
		total += float(info(tid).get("effect", {}).get(key, 0.0))
	return total

## "+10% Science · −5% Credits" / "+2 districts per City".
static func effect_text(id: String) -> String:
	var parts: Array[String] = []
	var eff: Dictionary = info(id).get("effect", {})
	for rid: String in eff:
		parts.append(_part_text(rid, float(eff[rid])))
	return " · ".join(parts)

static func _part_text(rid: String, v: float) -> String:
	if rid in COUNT_EFFECTS:
		return "%s%d %s" % ["+" if v >= 0.0 else "−", roundi(absf(v)), resource_label(rid)]
	return "%s%d%% %s" % ["+" if v >= 0.0 else "−", roundi(absf(v) * 100.0), resource_label(rid)]

## Whole-number effect of a world's traits ("city_districts" → +2).
static func planet_count(planet_seed: int, key: String) -> int:
	var total := 0
	for tid: String in traits_of(planet_seed):
		total += int(info(tid).get("effect", {}).get(key, 0))
	return total

## The effect as tooltip BBCode: one line per resource, its icon and colour,
## at the body's size (the colour sets it apart); a malus in red. "on this
## planet" closes it.
static func effect_bb(id: String) -> String:
	var lines: Array[String] = []
	var eff: Dictionary = info(id).get("effect", {})
	for rid: String in eff:
		var v := float(eff[rid])
		var col := Economy.color_of(rid) if rid != Economy.RAW else Color(0.85, 0.78, 0.70)
		if v < 0.0:
			col = Color(1.0, 0.45, 0.42)
		var icon: String = {"city_districts": "district", "district_slots": "factory"}.get(rid, rid)
		if rid in COUNT_EFFECTS:
			col = Color(0.95, 0.82, 0.45)   # a strong trait reads gold
		lines.append("%s [color=#%s]%s[/color]" % [UIIcons.bb(icon, 13, col), col.to_html(false), _part_text(rid, v)])
	return "\n".join(lines) + "\n[color=#8a93b0]on this planet[/color]"

static func resource_label(rid: String) -> String:
	match rid:
		"city_districts":   return "districts per City"
		"district_slots":   return "building slot in every district"
		Economy.RAW:        return "raw & processed output"
		Economy.POPULATION: return "housing"
		Economy.ENERGY:     return "energy output"
	return Economy.display_name(rid)

## True when every part of the trait's effect is good.
static func is_positive(id: String) -> bool:
	for v in info(id).get("effect", {}).values():
		if float(v) < 0.0:
			return false
	return true

## [label, tooltip] of a world's size and atmosphere — always shown, no effect.
static func size_tag(pd: PlanetData) -> Array:
	var s := "Small" if pd.planet_size < 0.8 else ("Large" if pd.planet_size > 1.3 else "Medium")
	return ["%s world" % s, "%s world (size %.2f). Shows how big the globe is; it has no effect on output." % [s, pd.planet_size]]

static func atmosphere_tag(pd: PlanetData) -> Array:
	var a := "None"
	if pd.has_atmosphere:
		a = "Thin" if pd.atmosphere_density < 0.4 else ("Dense" if pd.atmosphere_density > 0.7 else "Standard")
	var tip := "No atmosphere: Wind Turbines can't stand here." if a == "None" \
		else "%s atmosphere (density %.2f). Wind Turbines need one." % [a, pd.atmosphere_density]
	return ["Atmosphere: %s" % a, tip]

# ── Picks ────────────────────────────────────────────────────────────────────

## Queues one pick of OFFER_SIZE traits for a world (none it already has,
## none from another offer waiting for it). Seeded per world and pick, so the
## same game offers the same three.
static func queue_offer(pd: PlanetData) -> void:
	if pd == null:
		return
	var k := str(pd.seed)
	var have: Array = traits_of(pd.seed)
	var offers: Array = offers_of(pd.seed).duplicate()
	var taken := {}
	for t in have:
		taken[t] = true
	for o: Array in offers:
		for t in o:
			taken[t] = true
	var pool: Array = []
	for id: String in CATALOGUE:
		var c: Dictionary = CATALOGUE[id]
		if int(c["weight"]) <= 0 or taken.has(id):
			continue
		var types: Array = c["types"]
		if not types.is_empty() and not (int(pd.planet_type) in types):
			continue
		if int(c.get("min_slot", 0)) > have.size() + offers.size():
			continue   # strong traits come only with the slots you pay for
		pool.append(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = pd.seed ^ (0x7A65 + (have.size() + offers.size()) * 7919)
	var pick: Array = []
	while pick.size() < OFFER_SIZE and not pool.is_empty():
		var total := 0
		for id: String in pool:
			total += int(CATALOGUE[id]["weight"])
		var r := rng.randi_range(1, total)
		for i in pool.size():
			r -= int(CATALOGUE[pool[i]]["weight"])
			if r <= 0:
				pick.append(pool[i])
				pool.remove_at(i)
				break
	if pick.is_empty():
		return
	offers.append(pick)
	GameState.tag_offers[k] = offers
	GameState.tag_offers_changed.emit()

## The player takes `id` from the world's first waiting offer.
static func choose(planet_seed: int, id: String) -> bool:
	var k := str(planet_seed)
	var offers: Array = offers_of(planet_seed).duplicate()
	if offers.is_empty() or not (id in (offers[0] as Array)):
		return false
	offers.remove_at(0)
	if offers.is_empty():
		GameState.tag_offers.erase(k)
	else:
		GameState.tag_offers[k] = offers
	var have: Array = traits_of(planet_seed).duplicate()
	have.append(id)
	GameState.planet_tags[k] = have
	Economy.invalidate_bonus_cache()
	GameState.tag_offers_changed.emit()
	GameState.planet_progress_changed.emit(planet_seed)
	var pd := GameState.get_planet_data(planet_seed)
	NewsFeed.post("%s is now known for its %s (%s)." % [pd.planet_name if pd else "A world", info(id)["name"], effect_text(id)], NewsFeed.Kind.EVENT,
		"%s\n\n%s on this planet, counted on its whole total." % [info(id)["desc"], effect_text(id)], info(id)["name"],
		{"seed": planet_seed})
	return true

## A world reached a level: its next slot may be opened now — paid, not given
## (unlock_slot); the level news tells the player (NewsFeed.post_planet_level).
static func on_planet_level(_pd: PlanetData, _level: int) -> void:
	pass

# ── Slots ────────────────────────────────────────────────────────────────────

enum Slot { FILLED, PICKING, OPEN_TO_BUY, LOCKED, UNKNOWN }

## What slot `i` of a world shows: its trait, a pick waiting, ready to be
## bought, locked behind a level, or (first slot) unknown until scanned.
static func slot_state(pd: PlanetData, i: int) -> Slot:
	var have := traits_of(pd.seed).size()
	var waiting := offers_of(pd.seed).size()
	if i < have:
		return Slot.FILLED
	if i < have + waiting:
		return Slot.PICKING
	if i == 0:
		return Slot.UNKNOWN
	var pp := GameState.get_planet(pd.seed)
	if i == have + waiting and pp != null and pp.is_colonized and pp.level >= Balance.cfg.trait_slot_levels[i]:
		return Slot.OPEN_TO_BUY
	return Slot.LOCKED

static func slot_cost(i: int) -> Dictionary:
	return Balance.cfg.trait_slot_costs[i] if i < Balance.cfg.trait_slot_costs.size() else {}

## Pays for slot `i` and queues its pick of three. False when it can't be bought.
static func unlock_slot(pd: PlanetData, i: int) -> bool:
	if slot_state(pd, i) != Slot.OPEN_TO_BUY or not Economy.pay(slot_cost(i)):
		return false
	queue_offer(pd)
	return true

## Gives the home world its trait (new games and older saves).
static func ensure_home(pd: PlanetData) -> void:
	if pd != null and not GameState.planet_tags.has(str(pd.seed)):
		GameState.planet_tags[str(pd.seed)] = [CRADLE]
