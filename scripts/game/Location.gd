## Location multiplier for a surface district and its buildings.
## The nearest surface district (including Capital Districts) sets the distance
## tier. The legal centre-to-centre angle range from that district is split in
## thirds. Each eligible neighbour in its Near band contributes a proximity bonus.
class_name Location
extends RefCounted

## Distance tiers, nearest first (12.11: three; the old five-band names are gone).
enum Band { NEAR, MID, FAR }

static var _cache: Dictionary = {}   # seed -> signature, district breakdowns and radii

## Surface radius of a body in km (reference world × planet_size).
static func radius_km(pd: PlanetData) -> float:
	return Balance.cfg.planet_radius_km * maxf(pd.planet_size, 0.05)

static func distance_km(pd: PlanetData, a: POIData, b: POIData) -> float:
	return _distance_rad(a, b) * radius_km(pd)

static func _distance_rad(a: POIData, b: POIData) -> float:
	return TerrainSampler.angular_distance(deg_to_rad(a.lon_deg), deg_to_rad(a.lat_deg),
		deg_to_rad(b.lon_deg), deg_to_rad(b.lat_deg))

static func _city_reach_angle(pd: PlanetData, city: POIData) -> float:
	if ColonyTutorial.active() and pd.seed == GameState.home_planet_seed:
		return deg_to_rad(TerrainSampler.city_reach_deg(pd, 1))
	var lv := 1
	var pp := GameState.get_planet(pd.seed)
	if pp != null and city != null:
		lv = int(pp.district_levels.get(city.label, 1))
	return deg_to_rad(TerrainSampler.city_reach_deg(pd, lv))

static func _territory_angle(pd: PlanetData, poi: POIData) -> float:
	if ColonyTutorial.active() and pd.seed == GameState.home_planet_seed:
		return deg_to_rad(TerrainSampler.SETTLE_BASE_DEG * TerrainSampler.body_scale(pd))
	if poi.label == "":
		return deg_to_rad(TerrainSampler.territory_radius_deg(pd, poi))
	var radii: Dictionary = _planet_cache(pd)["radii"]
	var id := poi.get_instance_id()
	if not radii.has(id):
		radii[id] = deg_to_rad(TerrainSampler.territory_radius_deg(pd, poi))
	return float(radii[id])

## Tier of a centre-to-centre angle in the placement range.
static func band(angle: float, min_angle: float, max_angle: float) -> Band:
	var third := (max_angle - min_angle) / 3.0
	if angle < min_angle + third:
		return Band.NEAR
	if angle < min_angle + 2.0 * third:
		return Band.MID
	return Band.FAR

static func band_label(b: Band) -> String:
	return ["Near", "Mid", "Far"][int(b)]

## The tier's multiplier (×1 near).
static func band_mult(b: Band) -> float:
	match b:
		Band.MID: return Balance.cfg.location_mid_mult
		Band.FAR: return Balance.cfg.location_far_mult
	return 1.0

## The tier's bonus over ×1 (0 near).
static func band_bonus(b: Band) -> float:
	return band_mult(b) - 1.0

## Districts that count as places on the map: finished, on the surface.
static func _counts(p: POIData) -> bool:
	return not p.constructing and not p.is_orbital()

## Places that count for the distance tier: everything on the surface, under
## construction too (a district going up next door is already next door).
static func _stands(p: POIData) -> bool:
	return not p.is_orbital()

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
			"nearest_km": INF, "band": Band.FAR, "reach_km": 0.0, "sources": []}
	if poi.label == "":
		return _compute(pd, poi, null)
	var breakdowns: Dictionary = _planet_cache(pd)["breakdowns"]
	var id := poi.get_instance_id()
	if not breakdowns.has(id):
		breakdowns[id] = _compute(pd, poi, null)
	return breakdowns[id]

## What `poi`'s location would be if `extra` (a district being placed) stood
## too — no cache (the placement card's effect on neighbours).
static func breakdown_with(pd: PlanetData, poi: POIData, extra: POIData) -> Dictionary:
	return _compute(pd, poi, extra)

## The City a district belongs to (its own POI for a City); for a placement
## probe without one, the nearest City on the world. Null if there is none.
static func home_city(pd: PlanetData, poi: POIData) -> POIData:
	var label := poi.label if poi.is_city() else poi.parent_city
	var best: POIData = null
	var best_km := INF
	for p: POIData in pd.custom_pois:
		if not p.is_city() or p.is_orbital():
			continue
		if label != "" and p.label == label:
			return p
		var km := distance_km(pd, poi, p)
		if label == "" and km < best_km:
			best_km = km
			best = p
	return best

static func _compute(pd: PlanetData, poi: POIData, extra: POIData) -> Dictionary:
	var c: BalanceConfig = Balance.cfg
	if poi.is_city() or poi.is_orbital():
		return {"mult": 1.0, "proximity": 0.0, "centre": 0.0, "distance": 0.0, "nearest_km": INF,
			"band": Band.NEAR, "reach_km": 0.0, "sources": [], "city": null, "nearest": null}
	var city := home_city(pd, poi)
	var reach_angle := _city_reach_angle(pd, city)
	var min_angle := deg_to_rad(TerrainSampler.min_spacing_deg(pd))
	var same_kind_share := c.neighbour_mult * SkillTree.get_proximity_mult()
	var kind := family(poi)
	var linked: Array = SkillTree.cross_families(output_family(poi))
	var prox := 0.0
	var centre := 0.0
	var sources: Array = []
	var others: Array = pd.custom_pois
	if extra != null:
		others = pd.custom_pois.duplicate()
		others.append(extra)
	var nearest: POIData = null
	var nearest_angle := INF
	var radius := radius_km(pd)
	for p: POIData in others:
		if p == poi or (poi.label != "" and p.label == poi.label) or (p != extra and not _stands(p)):
			continue
		var angle := _distance_rad(poi, p)
		if angle < nearest_angle:
			nearest_angle = angle
			nearest = p
		# Proximity comes from finished districts. The placement preview includes its new district.
		if p != extra and not _counts(p):
			continue
		var is_capital := p.is_city()
		var same_kind := family(p) == kind
		if not is_capital and not same_kind and not linked.has(output_family(p)):
			continue
		if band(angle, min_angle, reach_angle + _territory_angle(pd, p)) != Band.NEAR:
			continue
		if is_capital:
			centre += c.centre_near
			continue
		var share := same_kind_share if same_kind else same_kind_share * 0.5
		prox += share
		sources.append({"poi": p, "km": angle * radius, "share": share, "kind": "family" if same_kind else "cross"})
	if c.proximity_cap > 0.0:
		prox = minf(prox, c.proximity_cap)
	var nb := Band.NEAR
	var max_angle := 0.0
	if nearest != null:
		max_angle = reach_angle + _territory_angle(pd, nearest)
		nb = band(nearest_angle, min_angle, max_angle)
	var dist := band_bonus(nb)
	if dist > 0.0:   # Independent Centres never turns near into far
		dist += SkillTree.get_distance_bonus_add()
	return {"mult": 1.0 + prox + centre + dist, "proximity": prox, "centre": centre,
		"distance": dist, "nearest_km": nearest_angle * radius, "band": nb,
		"reach_km": max_angle * radius, "sources": sources, "city": city, "nearest": nearest}

## The district's location multiplier (1 = no bonus).
static func mult(pd: PlanetData, poi: POIData) -> float:
	return float(breakdown(pd, poi)["mult"])

static func invalidate(planet_seed: int = -1) -> void:
	if planet_seed < 0:
		_cache.clear()
		_sig_memo.clear()
	else:
		_cache.erase(planet_seed)
		_sig_memo.erase(planet_seed)

# The signature includes everything that can move a centre or change its radius.
static var _sig_frame := -1
static var _sig_memo: Dictionary = {}   # planet seed -> signature, this frame

static func _signature(pd: PlanetData) -> int:
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

static func _signature_now(pd: PlanetData) -> int:
	var state := [pd.get_instance_id(), pd.planet_size, Balance.profile_name, SkillTree.version]
	var pp := GameState.get_planet(pd.seed)
	for p: POIData in pd.custom_pois:
		if _stands(p):
			state.append([p.get_instance_id(), p.lon_deg, p.lat_deg, p.parent_city, p.constructing, p.type_tag])
	if pp != null:
		state.append(pp.district_levels)
		state.append(pp.city_levels)
		for b: Dictionary in pp.buildings:
			if not b.get("constructing", false):
				state.append([b.get("district_id", ""), b.get("building_id", ""), b.get("amount", 1)])
	return hash(state)

static func _planet_cache(pd: PlanetData) -> Dictionary:
	var sig := _signature(pd)
	var entry: Dictionary = _cache.get(pd.seed, {})
	if entry.is_empty() or entry["sig"] != sig:
		entry = {"sig": sig, "breakdowns": {}, "radii": {}}
		_cache[pd.seed] = entry
	return entry
