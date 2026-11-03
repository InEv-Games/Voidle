class_name PlanetTags
extends RefCounted

## Planet traits (playtest 31.10): every world shows two plain tags — its size
## and its atmosphere — and three trait slots. The first opens with the world
## (the home world starts with CRADLE; any other draws a pick when scanned);
## the others need a planet level (Balance trait_slot_levels) and are opened
## by paying Science and Rare Elements (trait_slot_costs) — then the player
## picks one of three, roguelite style, and may re-roll them: the first re-roll
## of a pick is free, the next ones cost Science (reroll_cost). The traits are
## files in res://resources/traits (TraitDef), each with a rarity; later slots
## roll rarer ones (Balance trait_rarity_odds). Most are a planet-wide support
## counted with the Orbit's (Economy.planet_bonus): +10% Science on this world;
## the rare ones add districts per City or building slots.
##
## State lives in GameState: planet_tags { "seed": [trait id, …] }, tag_offers
## { "seed": [[id, id, id], …] } (offers waiting for a pick, kept in the save so
## reloading can't reroll them) and tag_rerolls { "seed": re-rolls of the first
## waiting pick }.

## How many traits are offered per pick.
const OFFER_SIZE := 3
## Trait slots per world.
const SLOTS := 3
## Effects that are counts, not fractions ("+1 district per City").
const COUNT_EFFECTS: Array[String] = ["city_districts", "district_slots"]
## The home world's trait.
const CRADLE := "cradle_world"

# ── Queries ──────────────────────────────────────────────────────────────────

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
		total += float(_effects_of(tid).get(key, 0.0))
	return total

static func _effects_of(id: String) -> Dictionary:
	var def := TraitDef.find(id)
	return def.effects if def != null else {}

## The amount alone: "+15%", "−5%", "+1".
static func effect_value(rid: String, v: float) -> String:
	var n := roundi(absf(v)) if rid in COUNT_EFFECTS else roundi(absf(v) * 100.0)
	return "%s%d%s" % ["+" if v >= 0.0 else "−", n, "" if rid in COUNT_EFFECTS else "%"]

static func effect_icon(rid: String) -> String:
	return {"city_districts": "district", "district_slots": "factory"}.get(rid, rid)

## A malus reads red, a count gold, the rest in the resource's colour.
static func effect_color(rid: String, v: float) -> Color:
	if v < 0.0:
		return Color(1.0, 0.45, 0.42)
	if rid in COUNT_EFFECTS:
		return Color(0.95, 0.82, 0.45)
	return Economy.color_of(rid) if rid != Economy.RAW else Color(0.85, 0.78, 0.70)

## An effect in icons and its amount, no words: "[science] +15%", the four
## output icons for raw, "[city] +1 [district]" for a count per City.
static func effect_short_bb(rid: String, v: float, px: int) -> String:
	var c := effect_color(rid, v)
	var val := "[color=#%s]%s[/color]" % [c.to_html(false), effect_value(rid, v)]
	match rid:
		"city_districts":
			return "%s %s %s" % [UIIcons.bb("city", px, c), val, UIIcons.bb("district", px, c)]
		"district_slots":
			return "%s %s %s" % [UIIcons.bb("district", px, c), val, UIIcons.bb("factory", px, c)]
		Economy.RAW:
			var icons := ""
			for id: String in [Economy.RAW, Economy.GOODS, Economy.FUEL, Economy.RARE]:
				var ic := c if v < 0.0 or id == Economy.RAW else Economy.color_of(id)
				icons += UIIcons.bb(id, px, ic)
			return "%s %s" % [icons, val]
	return "%s %s" % [UIIcons.bb(rid, px, c), val]

## What an effect touches, in a sentence for BBCode (its tooltip on the trait
## cards): resources by their icons, never their names.
static func effect_explain(rid: String) -> String:
	const PX := 12
	var ic := UIIcons.bb(rid, PX, effect_color(rid, 1.0)) if rid not in COUNT_EFFECTS and rid != Economy.RAW else ""
	match rid:
		"city_districts":   return "Every City on this world can hold more districts."
		"district_slots":   return "Every surface district on this world has room for more buildings."
		Economy.RAW:
			var icons := ""
			for id: String in [Economy.RAW, Economy.GOODS, Economy.FUEL, Economy.RARE]:
				icons += UIIcons.bb(id, PX, Economy.color_of(id) if id != Economy.RAW else effect_color(id, 1.0))
			return "Mining and processing on this world: %s" % icons
		Economy.POPULATION: return "The %s room of every City on this world." % ic
		Economy.ENERGY:     return "The %s made by every building on this world." % ic
	return "All the %s this world makes." % ic

## Whole-number effect of a world's traits ("city_districts" → +2).
static func planet_count(planet_seed: int, key: String) -> int:
	var total := 0
	for tid: String in traits_of(planet_seed):
		total += int(_effects_of(tid).get(key, 0))
	return total

## The effect as tooltip BBCode: one line per resource, its icon and colour,
## at the body's size (the colour sets it apart); a malus in red. "on this
## planet" closes it.
static func effect_bb(id: String) -> String:
	var lines: Array[String] = []
	var eff := _effects_of(id)
	for rid: String in eff:
		var v := float(eff[rid])
		lines.append(effect_short_bb(rid, v, 13))
	return "\n".join(lines) + "\n[color=#8a93b0]on this planet[/color]"

static func resource_label(rid: String, count := 1) -> String:
	match rid:
		"city_districts":   return "district per City" if count == 1 else "districts per City"
		"district_slots":   return "building slot in every district" if count == 1 else "building slots in every district"
		Economy.RAW:        return "raw & processed output"
		Economy.POPULATION: return "housing"
		Economy.ENERGY:     return "energy output"
	return Economy.display_name(rid)

## True when every part of the trait's effect is good.
static func is_positive(id: String) -> bool:
	for v in _effects_of(id).values():
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
## none from another offer waiting for it). Seeded per world, pick and re-roll,
## so the same game offers the same three.
static func queue_offer(pd: PlanetData) -> void:
	if pd == null:
		return
	var offers: Array = offers_of(pd.seed).duplicate()
	var slot := traits_of(pd.seed).size() + offers.size()
	var pick := _draw(pd, slot, _taken(pd.seed), _roll_rng(pd.seed, slot, 0))
	if pick.is_empty():
		return
	offers.append(pick)
	GameState.tag_offers[str(pd.seed)] = offers
	GameState.tag_offers_changed.emit()

static func _roll_rng(planet_seed: int, slot: int, rerolls: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = planet_seed ^ (0x7A65 + slot * 7919 + rerolls * 104729)
	return rng

## Trait ids a world has or has on offer: { id: true }.
static func _taken(planet_seed: int) -> Dictionary:
	var taken := {}
	for t in traits_of(planet_seed):
		taken[t] = true
	for o: Array in offers_of(planet_seed):
		for t in o:
			taken[t] = true
	return taken

## Up to OFFER_SIZE different traits the world allows, none of `taken`.
static func _draw(pd: PlanetData, slot: int, taken: Dictionary, rng: RandomNumberGenerator) -> Array:
	var pool: Array[TraitDef] = []
	for def: TraitDef in TraitDef.all():
		if def.weight > 0 and not taken.has(def.trait_id) and def.allows(int(pd.planet_type)):
			pool.append(def)
	var pick: Array = []
	while pick.size() < OFFER_SIZE and not pool.is_empty():
		var def := _draw_one(pool, slot, rng)
		pick.append(def.trait_id)
		pool.erase(def)
	return pick

## First its rarity by the slot's odds, then a trait of that rarity by weight.
## A rarity with nothing left gives its share to the others; when the slot's
## odds have nothing left at all, any trait still in the pool can come.
static func _draw_one(pool: Array[TraitDef], slot: int, rng: RandomNumberGenerator) -> TraitDef:
	var odds := rarity_odds(slot)
	var rarity_weight := {}
	for def: TraitDef in pool:
		rarity_weight[def.rarity] = int(odds.get(def.rarity_key(), 0))
	var rarity := -1
	var total := 0
	for r: int in rarity_weight:
		total += int(rarity_weight[r])
	if total > 0:
		var roll := rng.randi_range(1, total)
		for r: int in rarity_weight:
			roll -= int(rarity_weight[r])
			if roll <= 0:
				rarity = r
				break
	var kin: Array[TraitDef] = []
	var kin_total := 0
	for def: TraitDef in pool:
		if rarity < 0 or def.rarity == rarity:
			kin.append(def)
			kin_total += def.weight
	var roll := rng.randi_range(1, kin_total)
	for def: TraitDef in kin:
		roll -= def.weight
		if roll <= 0:
			return def
	return kin[0]

## { rarity key: weight } for slot `i`.
static func rarity_odds(i: int) -> Dictionary:
	var table: Array[Dictionary] = Balance.cfg.trait_rarity_odds
	return table[mini(i, table.size() - 1)]

## The player takes `id` from the world's first waiting offer.
static func choose(planet_seed: int, id: String) -> bool:
	var k := str(planet_seed)
	var offers: Array = offers_of(planet_seed).duplicate()
	var def := TraitDef.find(id)
	if offers.is_empty() or def == null or not (id in (offers[0] as Array)):
		return false
	offers.remove_at(0)
	if offers.is_empty():
		GameState.tag_offers.erase(k)
	else:
		GameState.tag_offers[k] = offers
	GameState.tag_rerolls.erase(k)   # the next pick has its own free re-roll
	var have: Array = traits_of(planet_seed).duplicate()
	have.append(id)
	GameState.planet_tags[k] = have
	Economy.invalidate_bonus_cache()
	GameState.tag_offers_changed.emit()
	GameState.planet_progress_changed.emit(planet_seed)
	var pd := GameState.get_planet_data(planet_seed)
	NewsFeed.post("%s is now known for its %s." % [pd.planet_name if pd else "A world", def.display_name], NewsFeed.Kind.EVENT,
		"%s\n\n%s" % [def.description, effect_bb(id)], def.display_name,
		{"seed": planet_seed})
	return true

# ── Re-rolls ─────────────────────────────────────────────────────────────────

static func rerolls_used(planet_seed: int) -> int:
	return int(GameState.tag_rerolls.get(str(planet_seed), 0))

## What the next re-roll of the world's first waiting pick costs: {} when free.
static func reroll_cost(planet_seed: int) -> Dictionary:
	var used := rerolls_used(planet_seed)
	if used == 0:
		return {}
	var costs: Array[float] = Balance.cfg.trait_reroll_costs
	var base: float = costs[mini(traits_of(planet_seed).size(), costs.size() - 1)]
	return {Economy.SCIENCE: roundf(base * pow(Balance.cfg.trait_reroll_growth, used - 1))}

## Pays and swaps the first waiting pick for three new cards; the old ones come
## back only if the world has too few other traits left.
static func reroll(planet_seed: int) -> bool:
	var pd := GameState.get_planet_data(planet_seed)
	var offers: Array = offers_of(planet_seed).duplicate()
	if pd == null or offers.is_empty():
		return false
	var used := rerolls_used(planet_seed) + 1
	var slot := traits_of(planet_seed).size()
	var rng := _roll_rng(planet_seed, slot, used)
	var taken := _taken(planet_seed)
	var pick := _draw(pd, slot, taken, rng)
	if pick.size() < OFFER_SIZE:
		for t in offers[0]:
			taken.erase(t)
		for t in pick:
			taken[t] = true
		pick.append_array(_draw(pd, slot, taken, rng).slice(0, OFFER_SIZE - pick.size()))
	if pick.is_empty() or not Economy.pay(reroll_cost(planet_seed)):
		return false
	offers[0] = pick
	GameState.tag_offers[str(planet_seed)] = offers
	GameState.tag_rerolls[str(planet_seed)] = used
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
