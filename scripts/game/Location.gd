## Location economy (docs/design/VOIDLE_GDD.md §7): real surface distances in km,
## proximity contributions and the distance bonus. Roads, intersections and
## what lies in between play no part — only physical distance.
##
## A district's location multiplier = 1 + proximity + centres + distance bonus.
## Research: Cluster Planning scales proximity and centres, Independent Centres
## adds to a distance bonus, Mixed Networks lets linked families count at half.
## It applies once to the district's base income and to every building in it.
##   proximity  every other finished district of the same family:
##              very near +proximity_very_near, near +proximity_near (no
##              diminishing, no source cap — Balance.cfg.proximity_cap is a total cap, 0 = none)
##   centres    every City (its Capital District) in reach supports all families
##   distance   by the nearest other finished district: 0 / 12.5 / 25 / 37.5 / 50 %
## Bands are fractions of the district's City reach (reach_km), not fixed km,
## so every band can be reached at every City level and on small bodies.
## Numbers come from Balance.cfg. Results are cached per planet until a
## district is placed, finished or removed.
class_name Location
extends RefCounted

## Distance labels, nearest first.
enum Band { VERY_NEAR, NEAR, MID, FAR, VERY_FAR }

static var _cache: Dictionary = {}   # seed -> { "sig": String, "mult": {label: Dictionary} }

## Surface radius of a body in km (reference world × planet_size).
static func radius_km(pd: PlanetData) -> float:
	return Balance.cfg.planet_radius_km * maxf(pd.planet_size, 0.05)

static func distance_km(pd: PlanetData, a: POIData, b: POIData) -> float:
	return TerrainSampler.angular_distance(deg_to_rad(a.lon_deg), deg_to_rad(a.lat_deg),
		deg_to_rad(b.lon_deg), deg_to_rad(b.lat_deg)) * radius_km(pd)

## Reach of the City `poi` belongs to (its own, for a City), in km: how far
## beyond its settlements that City may place districts.
static func reach_km(pd: PlanetData, poi: POIData) -> float:
	var city := poi.label if poi.is_city() else poi.parent_city
	var lv := 1
	var pp := GameState.get_planet(pd.seed)
	if pp != null and city != "":
		lv = int(pp.district_levels.get(city, 1))
	return deg_to_rad(TerrainSampler.city_reach_deg(pd, lv)) * radius_km(pd)

## Band of a distance, as a share of `reach` (km): ≤ very_near, ≤ near, ≤ mid,
## < far, then very far.
static func band(km: float, reach: float) -> Band:
	var c: BalanceConfig = Balance.cfg
	var f := km / maxf(reach, 1.0)
	if f <= c.distance_very_near_frac: return Band.VERY_NEAR
	if f <= c.distance_near_frac:      return Band.NEAR
	if f <= c.distance_mid_frac:       return Band.MID
	if f < c.distance_far_frac:        return Band.FAR
	return Band.VERY_FAR

static func band_label(b: Band) -> String:
	return ["Very near", "Near", "Mid", "Far", "Very far"][int(b)]

static func band_bonus(b: Band) -> float:
	var bonuses: Array = Balance.cfg.distance_bonuses
	return float(bonuses[int(b)]) if int(b) < bonuses.size() else 0.0

## Districts that count as places on the map: finished, on the surface.
static func _counts(p: POIData) -> bool:
	return not p.constructing and not p.is_orbital()

## Family key for proximity: the district type ("city" = a centre).
static func family(p: POIData) -> String:
	return p.type_tag

## Output family of a district (science, commercial, residential, energy,
## production) — what Mixed Networks links.
static func output_family(p: POIData) -> String:
	match p.poi_type:
		POIData.POIType.MINING:      return "production"
		POIData.POIType.ENERGY:      return "energy"
		POIData.POIType.SCIENCE:     return "science"
		POIData.POIType.RESIDENTIAL: return "residential"
		POIData.POIType.COMMERCIAL:  return "commercial"
	return ""

## Full breakdown for a district (or a placement probe with label ""):
## { "mult": float, "proximity": float, "centre": float, "distance": float,
##   "nearest_km": float, "band": Band, "sources": [{ "poi", "km", "share", "kind" }] }
static func breakdown(pd: PlanetData, poi: POIData) -> Dictionary:
	if pd == null or poi == null:
		return {"mult": 1.0, "proximity": 0.0, "centre": 0.0, "distance": 0.0,
			"nearest_km": INF, "band": Band.VERY_FAR, "reach_km": 0.0, "sources": []}
	if poi.label != "":
		var cached := _cached(pd, poi.label)
		if not cached.is_empty():
			return cached
	var out := _compute(pd, poi, null)
	if poi.label != "":
		_store(pd, poi.label, out)
	return out

## What `poi`'s location would be if `extra` (a district being placed) stood
## too — no cache (the placement card's effect on neighbours).
static func breakdown_with(pd: PlanetData, poi: POIData, extra: POIData) -> Dictionary:
	return _compute(pd, poi, extra)

static func _compute(pd: PlanetData, poi: POIData, extra: POIData) -> Dictionary:
	var c: BalanceConfig = Balance.cfg
	var cluster: float = SkillTree.get_proximity_mult()
	var linked: Array = SkillTree.cross_families(output_family(poi))
	var prox := 0.0
	var centre := 0.0
	var nearest := INF
	var sources: Array = []
	var reach := reach_km(pd, poi)
	var others: Array = pd.custom_pois
	if extra != null:
		others = pd.custom_pois.duplicate()
		others.append(extra)
	for p: POIData in others:
		if p == poi or (poi.label != "" and p.label == poi.label) or (p != extra and not _counts(p)):
			continue
		var km := distance_km(pd, poi, p)
		nearest = minf(nearest, km)
		var b := band(km, reach)
		if b != Band.VERY_NEAR and b != Band.NEAR:
			continue
		if p.is_city():   # a centre supports every family in reach
			var cs := (c.centre_very_near if b == Band.VERY_NEAR else c.centre_near) * cluster
			centre += cs
			sources.append({"poi": p, "km": km, "share": cs, "kind": "centre"})
		elif poi.is_city():
			continue
		elif family(p) == family(poi):
			var ps := (c.proximity_very_near if b == Band.VERY_NEAR else c.proximity_near) * cluster
			prox += ps
			sources.append({"poi": p, "km": km, "share": ps, "kind": "family"})
		elif linked.has(output_family(p)):   # Mixed Networks: half of a family source
			var xs := (c.proximity_very_near if b == Band.VERY_NEAR else c.proximity_near) * 0.5 * cluster
			prox += xs
			sources.append({"poi": p, "km": km, "share": xs, "kind": "cross"})
	if c.proximity_cap > 0.0:
		prox = minf(prox, c.proximity_cap)
	var nb := band(nearest, reach) if nearest != INF else Band.VERY_FAR
	var dist := band_bonus(nb)
	if dist > 0.0:   # Independent Centres never turns near into far
		dist += SkillTree.get_distance_bonus_add()
	return {"mult": 1.0 + prox + centre + dist, "proximity": prox, "centre": centre,
		"distance": dist, "nearest_km": nearest, "band": nb, "reach_km": reach, "sources": sources}

## The district's location multiplier (1 = no bonus).
static func mult(pd: PlanetData, poi: POIData) -> float:
	return float(breakdown(pd, poi)["mult"])

static func invalidate(planet_seed: int = -1) -> void:
	if planet_seed < 0:
		_cache.clear()
	else:
		_cache.erase(planet_seed)

# Cache: valid while the set of finished surface districts and the Cities'
# levels (their reach sets the bands) are unchanged.
static var _sig_frame := -1
static var _sig_memo: Dictionary = {}   # planet seed -> signature, this frame

static func _signature(pd: PlanetData) -> String:
	# asked for every building every frame: worked out once per world per frame
	var f := Engine.get_process_frames()
	if f != _sig_frame:
		_sig_frame = f
		_sig_memo.clear()
	if _sig_memo.has(pd.seed):
		return _sig_memo[pd.seed]
	var sig := _signature_now(pd)
	_sig_memo[pd.seed] = sig
	return sig

static func _signature_now(pd: PlanetData) -> String:
	var built := 0
	var city_lv := 0
	var pp := GameState.get_planet(pd.seed)
	for p: POIData in pd.custom_pois:
		if _counts(p):
			built += 1
		if p.is_city() and pp != null:
			city_lv = city_lv * 31 + int(pp.district_levels.get(p.label, 1))
	return "%d|%d|%d|%s|%d" % [pd.custom_pois.size(), built, city_lv, Balance.profile_name, SkillTree.version]

static func _cached(pd: PlanetData, label: String) -> Dictionary:
	var entry: Dictionary = _cache.get(pd.seed, {})
	if entry.is_empty() or entry["sig"] != _signature(pd):
		return {}
	return entry["mult"].get(label, {})

static func _store(pd: PlanetData, label: String, value: Dictionary) -> void:
	var sig := _signature(pd)
	var entry: Dictionary = _cache.get(pd.seed, {})
	if entry.is_empty() or entry["sig"] != sig:
		entry = {"sig": sig, "mult": {}}
		_cache[pd.seed] = entry
	entry["mult"][label] = value
