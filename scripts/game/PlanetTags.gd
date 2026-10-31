class_name PlanetTags
extends RefCounted

## Planet traits (playtest 31.10): every world shows two plain tags — its size
## and its atmosphere — and holds traits with one clear effect each. The home
## world starts with CRADLE; any other world draws one when it is scanned: the
## player picks one of three offered. Planet levels in BONUS_LEVELS offer one
## more pick. A trait's effect is a planet-wide support, counted with the
## Orbit's (Economy.planet_bonus): +10% Science on this world, etc.
##
## State lives in GameState: planet_tags { "seed": [trait id, …] } and
## tag_offers { "seed": [[id, id, id], …] } (offers waiting for a pick, kept in
## the save so reloading can't reroll them).

## How many traits are offered per pick.
const OFFER_SIZE := 3
## Planet levels that offer one more trait.
const BONUS_LEVELS: Array[int] = [3, 5]
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
	var total := 0.0
	for tid: String in traits_of(planet_seed):
		total += float(info(tid).get("effect", {}).get(key, 0.0))
	return total

## "+10% Science · −5% Credits".
static func effect_text(id: String) -> String:
	var parts: Array[String] = []
	var eff: Dictionary = info(id).get("effect", {})
	for rid: String in eff:
		var v := float(eff[rid])
		parts.append("%s%d%% %s" % ["+" if v >= 0.0 else "−", roundi(absf(v) * 100.0), resource_label(rid)])
	return " · ".join(parts)

static func resource_label(rid: String) -> String:
	match rid:
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
		"%s\n\n%s on this world, counted on its whole total." % [info(id)["desc"], effect_text(id)], info(id)["name"],
		{"seed": planet_seed})
	return true

## A world reached `level`: one more pick at BONUS_LEVELS.
static func on_planet_level(pd: PlanetData, level: int) -> void:
	if level in BONUS_LEVELS:
		queue_offer(pd)

## Gives the home world its trait (new games and older saves).
static func ensure_home(pd: PlanetData) -> void:
	if pd != null and not GameState.planet_tags.has(str(pd.seed)):
		GameState.planet_tags[str(pd.seed)] = [CRADLE]
