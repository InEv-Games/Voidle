## Settlement operations (docs/design/VOIDLE_GDD.md §15): remove buildings,
## clear content, reset, demolish and move. Every one has a preview (what goes,
## the refund, what is lost) and an apply step; PlanetaryView turns them into
## right-click commands (KARARLAR §6).
##
## Refunds (§15.6): only what was really paid and not refunded yet (the ledger):
##   building stacks  entry["paid"], entry["paid_mats"]   (PlanetProgress.stack_paid / stack_mats)
##   district shell   POIData.paid_credits, paid_materials (the first, free City paid 0)
##   levels           PlanetProgress.level_paid    (district label, "city:<label>")
## k of N buildings give back rate × C·k/N and C drops by the whole share, so
## nothing is refunded twice. Credits and materials come back at the same rate
## (KARARLAR §10): 50%, 65% with Recycling I, 75% with Recycling II.
##
## Moving (§15.9–§15.11) needs Settlement Layout and costs 10% of the moved
## subtree's paid credits (a service fee: not added to the ledger). A City moves
## with its districts (their layout around it is kept).
class_name Settlement
extends RefCounted

const MOVE_FEE := 0.10

static func refund_rate() -> float:
	if SkillTree.is_unlocked("recycling_2"):
		return 0.75
	if SkillTree.is_unlocked("recycling_1"):
		return 0.65
	return 0.50

## The settlement and every district under it (a City's children).
static func subtree(pd: PlanetData, poi: POIData) -> Array[POIData]:
	var out: Array[POIData] = [poi]
	if poi.is_city():
		for p: POIData in pd.custom_pois:
			if p != poi and p.parent_city == poi.label:
				out.append(p)
	return out

static func _shell_paid(poi: POIData) -> float:
	return maxf(poi.paid_credits, 0.0)

static func _levels_paid(pp: PlanetProgress, poi: POIData) -> float:
	var v := float(pp.level_paid.get(poi.label, 0.0))
	if poi.is_city():
		v += float(pp.level_paid.get("city:" + poi.label, 0.0))
	return v

static func _buildings_paid(pp: PlanetProgress, label: String) -> float:
	var v := 0.0
	for b: Dictionary in pp.buildings_in_district(label):
		v += PlanetProgress.stack_paid(b)
	return v

## Credits still on the ledger for a whole subtree (shell + levels + buildings).
static func subtree_paid(pd: PlanetData, pp: PlanetProgress, poi: POIData) -> float:
	var v := 0.0
	for p: POIData in subtree(pd, poi):
		v += _shell_paid(p) + _levels_paid(pp, p) + _buildings_paid(pp, p.label)
	return v

# ── Building stacks ──────────────────────────────────────────────────────────

## Materials refunded for removing k buildings from a stack ({id: amount}).
static func remove_refund_mats(entry: Dictionary, k: int) -> Dictionary:
	var n := int(entry.get("amount", 1))
	if n <= 0:
		return {}
	return PlanetProgress.scale_mats(PlanetProgress.stack_mats(entry), float(mini(k, n)) / float(n) * refund_rate())

## Puts materials back in stock; returns them.
static func _give(mats: Dictionary) -> Dictionary:
	for id: String in mats:
		if float(mats[id]) > 0.0:
			GameState.add_resource(id, float(mats[id]))
	return mats

## Adds `mats` × f into `into`.
static func _sum_into(into: Dictionary, mats: Dictionary, f: float = 1.0) -> void:
	for id: String in mats:
		into[id] = float(into.get(id, 0.0)) + float(mats[id]) * f

## Refund for removing k buildings from a stack.
static func remove_refund(entry: Dictionary, k: int) -> float:
	var n := int(entry.get("amount", 1))
	if n <= 0:
		return 0.0
	return PlanetProgress.stack_paid(entry) * float(mini(k, n)) / float(n) * refund_rate()

## Removes k buildings of a stack; returns the refund paid.
static func remove_buildings(pp: PlanetProgress, entry: Dictionary, k: int) -> float:
	var n := int(entry.get("amount", 1))
	k = mini(k, n)
	if k <= 0:
		return 0.0
	var c := PlanetProgress.stack_paid(entry)
	var share := c * float(k) / float(n)
	var refund := share * refund_rate()
	_give(remove_refund_mats(entry, k))
	if k >= n:
		pp.remove_building_stack(entry)
	else:
		entry["amount"] = n - k
		entry["paid"] = c - share
		entry["paid_mats"] = PlanetProgress.scale_mats(PlanetProgress.stack_mats(entry), float(n - k) / float(n))
	GameState.earn_credits(refund)
	_changed(pp)
	return refund

# ── Previews ─────────────────────────────────────────────────────────────────

## What an operation does: { refund, districts: [POIData], buildings: int,
## housing, text }. kind: "clear", "reset", "demolish".
static func preview(kind: String, pd: PlanetData, poi: POIData) -> Dictionary:
	var pp := GameState.get_planet(pd.seed)
	var rate := refund_rate()
	var tree := subtree(pd, poi)
	var gone: Array[POIData] = []          # districts removed entirely
	var emptied: Array[POIData] = tree     # districts whose buildings go
	var paid := 0.0
	match kind:
		"reset":
			if poi.is_city():
				gone = tree.slice(1)
			else:
				emptied = [poi]
			paid += _levels_paid(pp, poi)
		"demolish":
			gone = tree
		"clear":
			pass
	var n_buildings := 0
	var housing := 0.0
	var mats := {}
	for p: POIData in emptied:
		paid += _buildings_paid(pp, p.label)
		for b: Dictionary in pp.buildings_in_district(p.label):
			n_buildings += int(b.get("amount", 1))
			_sum_into(mats, PlanetProgress.stack_mats(b), rate)
			var def := BuildingDef.find(b.get("building_id", ""))
			if def != null and def.outputs.has(Economy.POPULATION) and not gone.has(p):
				housing += float(def.outputs[Economy.POPULATION]) * float(b.get("amount", 1))
	for p: POIData in gone:
		paid += _shell_paid(p) + (_levels_paid(pp, p) if p != poi or kind == "demolish" else 0.0)
		_sum_into(mats, p.paid_materials, rate)
		housing += float(Economy.district_housing(pd, pp, p))
	var lines: Array[String] = []
	if not gone.is_empty():
		var names: Array[String] = []
		for p: POIData in gone:
			names.append(p.shown_name())
		lines.append("Removes " + ", ".join(names))
	if n_buildings > 0:
		lines.append("%d building%s go" % [n_buildings, "" if n_buildings == 1 else "s"])
	if kind == "reset":
		lines.append("%s returns to Lv1" % poi.shown_name())
	if housing > 0.0:
		lines.append("Housing lost: about %s" % Economy.fmt(housing))
	var back := {Economy.CREDITS: paid * rate}
	back.merge(mats)
	lines.append("Refund: %s (%d%% of what was paid)" % [Economy.cost_text(back), int(round(rate * 100.0))])
	return {"refund": paid * rate, "materials": mats, "districts": gone, "buildings": n_buildings,
		"housing": housing, "text": "\n".join(lines)}

# ── Operations ───────────────────────────────────────────────────────────────

## Why the operation can't run ("" when it can).
static func block(kind: String, pd: PlanetData, poi: POIData) -> String:
	if GameState.showcase_mode:
		return "Read-only showcase"
	if poi.is_orbital():
		return "Stations can't be changed this way yet"
	var pp := GameState.get_planet(pd.seed)
	match kind:
		"clear":
			for p: POIData in subtree(pd, poi):
				if not pp.buildings_in_district(p.label).is_empty():
					return ""
			return "Nothing to clear"
		"reset":
			if poi.constructing:
				return "Under construction"
			if subtree(pd, poi).size() > 1 or not pp.buildings_in_district(poi.label).is_empty() \
					or int(pp.district_levels.get(poi.label, 1)) > 1 or pp.district_upgrading.has(poi.label) \
					or (poi.is_city() and int(pp.city_levels.get(poi.label, 1)) > 1):
				return ""
			return "Already at Lv1 and empty"
		"demolish":
			return ""
	return "Unknown operation"

## Clear content: every building in the settlement (a City: its Capital and all
## its districts). Shells, names, places and levels stay.
static func clear(pd: PlanetData, poi: POIData) -> float:
	var pp := GameState.get_planet(pd.seed)
	var refund := 0.0
	for p: POIData in subtree(pd, poi):
		refund += _drop_buildings(pp, p.label)
	GameState.earn_credits(refund)
	_changed(pp)
	return refund

## Reset: back to a Lv1 shell. A City loses its districts too.
static func reset(pd: PlanetData, poi: POIData) -> float:
	var pp := GameState.get_planet(pd.seed)
	var refund := 0.0
	if poi.is_city():
		for p: POIData in subtree(pd, poi).slice(1):
			refund += _remove_district(pd, pp, p)
	refund += _drop_buildings(pp, poi.label)
	refund += _levels_paid(pp, poi) * refund_rate()
	pp.level_paid.erase(poi.label)
	pp.level_paid.erase("city:" + poi.label)
	pp.district_levels.erase(poi.label)
	pp.district_upgrading.erase(poi.label)
	if poi.is_city():
		pp.city_levels.erase(poi.label)
		pp.city_upgrading.erase(poi.label)
	GameState.earn_credits(refund)
	_changed(pp)
	return refund

## Demolish: the settlement and everything under it. The natural body stays.
static func demolish(pd: PlanetData, poi: POIData) -> float:
	var pp := GameState.get_planet(pd.seed)
	var refund := 0.0
	var all := subtree(pd, poi)
	all.reverse()   # children first
	for p: POIData in all:
		refund += _remove_district(pd, pp, p)
	GameState.earn_credits(refund)
	_changed(pp)
	return refund

static func _drop_buildings(pp: PlanetProgress, label: String) -> float:
	var refund := 0.0
	for b: Dictionary in pp.buildings_in_district(label):
		refund += PlanetProgress.stack_paid(b) * refund_rate()
		_give(PlanetProgress.scale_mats(PlanetProgress.stack_mats(b), refund_rate()))
		pp.remove_building_stack(b)
	return refund

## Removes one district (its buildings, levels and shell); returns its refund (not paid yet).
static func _remove_district(pd: PlanetData, pp: PlanetProgress, p: POIData) -> float:
	var refund := _drop_buildings(pp, p.label)
	refund += (_shell_paid(p) + _levels_paid(pp, p)) * refund_rate()
	_give(PlanetProgress.scale_mats(p.paid_materials, refund_rate()))
	pp.level_paid.erase(p.label)
	pp.level_paid.erase("city:" + p.label)
	pp.district_levels.erase(p.label)
	pp.district_upgrading.erase(p.label)
	pp.city_levels.erase(p.label)
	pp.city_upgrading.erase(p.label)
	pd.custom_pois.erase(p)
	return refund

# ── Cancelling (full refund) ────────────────────────────────────────────────
# Work that hasn't finished can be called off: everything paid for it comes back
# (playtest 23.10) — no Recycling rate, nothing was built yet.

## A building still under construction. Returns what came back ({} when it can't).
static func cancel_building(pp: PlanetProgress, entry: Dictionary) -> Dictionary:
	if not entry.get("constructing", false):
		return {}
	var back := {Economy.CREDITS: PlanetProgress.stack_paid(entry)}
	back.merge(_give(PlanetProgress.stack_mats(entry)))
	GameState.earn_credits(float(back[Economy.CREDITS]))
	pp.remove_building_stack(entry)
	_changed(pp)
	return back

## Why a district / City under construction can't be called off ("" when it can).
static func cancel_district_block(pd: PlanetData, poi: POIData) -> String:
	if GameState.showcase_mode:
		return "Read-only showcase"
	if not poi.constructing:
		return "Already built"
	if poi.is_orbital():
		return "The station is already on its way"
	if poi.is_city():
		for p: POIData in pd.custom_pois:
			if p != poi and p.is_city() and not p.is_orbital():
				return ""
		return "A world's first City can't be called off"
	return ""

## A district / City still under construction goes; its full price comes back.
static func cancel_district(pd: PlanetData, poi: POIData) -> Dictionary:
	if cancel_district_block(pd, poi) != "":
		return {}
	var pp := GameState.get_planet(pd.seed)
	var back := {Economy.CREDITS: _shell_paid(poi)}
	back.merge(_give(poi.paid_materials))
	GameState.earn_credits(float(back[Economy.CREDITS]))
	pp.district_levels.erase(poi.label)
	pd.custom_pois.erase(poi)
	_changed(pp)
	return back

## Credits a level-up in progress cost (what cancelling it gives back), 0 when
## none is running. `city`: the City's own level, else the district's.
static func level_in_progress_paid(pp: PlanetProgress, poi: POIData, city: bool) -> float:
	if city:
		if not pp.city_upgrading.has(poi.label):
			return 0.0
		return Leveling.city_level_credits(Leveling.city_level(pp, poi) + 1)
	if not pp.district_upgrading.has(poi.label):
		return 0.0
	return Leveling.district_level_credits(int(pp.district_levels.get(poi.label, 1)))

## Calls off a level-up in progress; returns the credits given back.
static func cancel_level(pp: PlanetProgress, poi: POIData, city: bool) -> float:
	var price := level_in_progress_paid(pp, poi, city)
	if price <= 0.0:
		return 0.0
	var key := ("city:" + poi.label) if city else poi.label
	pp.level_paid[key] = maxf(float(pp.level_paid.get(key, 0.0)) - price, 0.0)
	if city:
		pp.city_upgrading.erase(poi.label)
	else:
		pp.district_upgrading.erase(poi.label)
	GameState.earn_credits(price)
	_changed(pp)
	return price

# ── Moving ───────────────────────────────────────────────────────────────────

static func move_fee(pd: PlanetData, poi: POIData) -> float:
	return roundf(subtree_paid(pd, GameState.get_planet(pd.seed), poi) * MOVE_FEE)

static func move_block(pd: PlanetData, poi: POIData) -> String:
	if GameState.showcase_mode:
		return "Read-only showcase"
	if not SkillTree.is_unlocked("settlement_layout"):
		return "Research Settlement Layout"
	if poi.is_orbital():
		return "Stations can't be moved"
	for p: POIData in subtree(pd, poi):
		if p.constructing:
			return "Wait until construction ends"
	if GameState.credits < move_fee(pd, poi):
		return "Need %s cr" % Economy.fmt(move_fee(pd, poi))
	return ""

## New positions (lon/lat degrees) for the subtree when `poi` goes to `site`
## (radians): a City's districts keep their layout around it.
static func moved_positions(pd: PlanetData, poi: POIData, site: Vector2) -> Dictionary:
	var from := _unit(deg_to_rad(poi.lon_deg), deg_to_rad(poi.lat_deg))
	var to := _unit(site.x, site.y)
	var q := Quaternion(from, to) if not from.is_equal_approx(to) and not from.is_equal_approx(-to) else Quaternion.IDENTITY
	var out := {}
	for p: POIData in subtree(pd, poi):
		var v: Vector3 = q * _unit(deg_to_rad(p.lon_deg), deg_to_rad(p.lat_deg))
		out[p] = Vector2(fposmod(rad_to_deg(atan2(v.z, v.x)), 360.0), rad_to_deg(asin(clampf(v.y, -1.0, 1.0))))
	return out

## Why the subtree can't stand at `site` (radians) ("" when it can): every moved
## settlement must fit its own terrain and spacing rules at its new place.
static func move_site_block(pd: PlanetData, poi: POIData, site: Vector2) -> String:
	var tree := subtree(pd, poi)
	var pos := moved_positions(pd, poi, site)
	for p: POIData in tree:
		var def := ProductionManager.district_def(p)
		if def == null:
			continue
		var v: Vector2 = pos[p]
		var chk := TerrainSampler.check_site(pd, def, deg_to_rad(v.x), deg_to_rad(v.y), tree)
		if not chk["ok"]:
			return ("%s: " % p.shown_name() if p != poi else "") + String(chk["reason"])
	return ""

static func _unit(lon: float, lat: float) -> Vector3:
	return Vector3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))

## Moves the subtree (positions from moved_positions) and charges the fee.
static func move(pd: PlanetData, poi: POIData, site: Vector2) -> bool:
	if move_block(pd, poi) != "" or move_site_block(pd, poi, site) != "":
		return false
	var fee := move_fee(pd, poi)
	if not GameState.spend_credits(fee):
		return false
	var pos := moved_positions(pd, poi, site)
	for p: POIData in pos:
		var v: Vector2 = pos[p]
		p.lon_deg = v.x
		p.lat_deg = v.y
		var lon := deg_to_rad(v.x)
		var lat := deg_to_rad(v.y)
		var t := TerrainSampler.sample(pd, lon, lat)
		p.terrain = t["terrain"]
		p.coastal = t["coastal"]
		p.resource_tags = ResourceMap.sample(pd.seed, lon, lat)
		p.site_features = FeatureMap.shares(pd, lon, lat)
	_changed(GameState.get_planet(pd.seed))
	return true

static func _changed(pp: PlanetProgress) -> void:
	pp.has_spaceport = GameState.has_finished_building(pp.planet_seed, "spaceport")
	Location.invalidate(pp.planet_seed)
	ProductionManager.invalidate(pp.planet_seed)
	Economy.invalidate_caps()
	pp.recalculate_limits()
	GameState.planet_progress_changed.emit(pp.planet_seed)
	GameState.save()
