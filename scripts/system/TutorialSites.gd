class_name TutorialSites
extends RefCounted

const PLAN := "course:sites"
const ORDER := ["energy", "residential", "commercial", "science", "production"]

static func choose(pd: PlanetData, cities: Array) -> Dictionary:
	var best := {}
	var best_score := INF
	var wind := BuildingDef.find("wind_turbine")
	if wind == null or cities.is_empty() or not pd.custom_pois.is_empty():
		return best
	cities = cities.duplicate()
	cities.append_array(_wind_neighbourhoods(pd, cities.size()))
	for candidate: Dictionary in cities:
		var centre := Vector2(candidate["lon"], candidate["lat"])
		var city := _probe(pd, DistrictDef.find(DistrictDef.Type.CITY), centre, "")
		city.label = "@tutorial_capital"
		pd.custom_pois.append(city)
		var plan := {"city": centre}
		var score := _city_error(pd, city)
		var bearing := 0.0
		for key: String in ORDER:
			var def := DistrictDef.find(ColonyTutorial.DISTRICTS[key])
			var wind_site: Vector2 = candidate.get("wind_site", Vector2.INF)
			var result := _find(pd, city, def, centre, wind if key == "energy" else null, wind_site, bearing)
			if result.is_empty():
				break
			plan[key] = result["site"]
			pd.custom_pois.append(result["poi"])
			score += float(result["score"])
			if key == "energy":
				bearing = _bearing(centre, result["site"])
			bearing += TAU / ORDER.size()
		if plan.has("energy"):
			for i in range(1, pd.custom_pois.size()):
				var p: POIData = pd.custom_pois[i]
				var def := DistrictDef.find(ColonyTutorial.DISTRICTS[ORDER[i - 1]])
				score += _output_error(pd, p, def)
			if plan.size() > best.size() or (plan.size() == best.size() and score < best_score):
				best_score = score
				best = plan
		pd.custom_pois.clear()
		Location.invalidate(pd.seed)
		if best.size() == ORDER.size() + 1 and is_zero_approx(best_score):
			break
	return best

static func _wind_neighbourhoods(pd: PlanetData, limit: int) -> Array:
	var cells := wind_cells(pd)
	var out: Array = []
	var start := DistrictDef.find(DistrictDef.Type.CITY)
	var reach := deg_to_rad(TerrainSampler.city_reach_deg(pd, 1) \
		+ TerrainSampler.SETTLE_BASE_DEG * TerrainSampler.body_scale(pd))
	var stride := maxi(1, ceili(float(cells.size()) / maxf(1.0, float(limit * 2))))
	for i in range(0, cells.size(), stride):
		var wind_site: Vector2 = cells[i]
		for dir in 8:
			var site := _offset(wind_site, reach * 0.80, TAU * float(dir) / 8.0)
			if TerrainSampler.check_site(pd, start, site.x, site.y)["ok"]:
				out.append({"lon": site.x, "lat": site.y, "wind_site": wind_site})
				break
		if out.size() >= limit:
			break
	return out

static func wind_cells(pd: PlanetData) -> Array:
	return FeatureMap.cells_with(pd.seed, FeatureMap.F.MOUNTAIN)

static func marker(site: Vector2, pd: PlanetData) -> Dictionary:
	return {"lon": site.x, "lat": site.y, "r": deg_to_rad(TerrainSampler.min_spacing_deg(pd)) * 0.47}

static func _city_error(pd: PlanetData, city: POIData) -> float:
	return absf(1.0 - FeatureMap.terrain_mult(pd, city, Economy.ENERGY)) \
		+ absf(1.0 - FeatureMap.terrain_mult(pd, city, Economy.POPULATION))

static func _find(pd: PlanetData, city: POIData, def: DistrictDef, centre: Vector2, wind: BuildingDef,
		preferred: Vector2, preferred_bearing: float) -> Dictionary:
	var lower := deg_to_rad(TerrainSampler.min_spacing_deg(pd))
	var upper := deg_to_rad(TerrainSampler.city_reach_deg(pd, 1) + TerrainSampler.territory_radius_deg(pd, city))
	var best := {}
	var best_rank := INF
	var others: Array = []
	for existing: POIData in pd.custom_pois:
		if existing == city:
			continue
		var existing_def := ProductionManager.district_def(existing)
		var buildings_need_location := _needs_full_location(existing_def)
		var geo := FeatureMap.terrain_mult(pd, existing, String(existing_def.base_outputs.keys()[0]))
		others.append({"poi": existing, "geo": geo, "buildings_need_location": buildings_need_location,
			"error": _output_error(pd, existing, existing_def)})
	for i in range(0 if wind != null and preferred != Vector2.INF else 1, 11):
		var angle := lerpf(lower, upper, float(i) / 11.0)
		if i == 0:
			angle = TerrainSampler.angular_distance(centre.x, centre.y, preferred.x, preferred.y)
		for direction in (1 if i == 0 else 32):
			var bearing := TAU * (float(direction) + 0.27 * i) / 32.0
			var site := preferred if i == 0 else _offset(centre, angle, bearing)
			if wind != null and not _wind_cell(pd, site):
				continue
			var check := TerrainSampler.check_site(pd, def, site.x, site.y)
			if not check["ok"]:
				continue
			var poi := _probe(pd, def, site, city.label)
			if wind != null and not wind.site_block_reason(poi, pd).is_empty():
				continue
			var score := _output_error(pd, poi, def)
			var separation := angle
			for other: Dictionary in others:
				var existing: POIData = other["poi"]
				var after := float(Location.breakdown_with(pd, existing, poi)["mult"])
				var change := absf(2.0 - Economy.site_mult(float(other["geo"]), after))
				if other["buildings_need_location"]:
					change += absf(2.0 - after)
				score += maxf(0.0, change - float(other["error"]))
				separation = minf(separation, TerrainSampler.angular_distance(site.x, site.y,
					deg_to_rad(existing.lon_deg), deg_to_rad(existing.lat_deg)))
			var rank := score - separation * 0.01
			# Spread the five districts around the City before a gap is used up.
			if wind == null:
				rank += absf(angle_difference(bearing, preferred_bearing)) * 0.008
			if rank < best_rank:
				best_rank = rank
				best = {"site": site, "poi": poi, "score": score}
	return best

static func _wind_cell(pd: PlanetData, site: Vector2) -> bool:
	var mask := FeatureMap.mask_at(pd.seed, site.x, site.y)
	return (mask & (1 << FeatureMap.F.MOUNTAIN)) != 0

static func _needs_full_location(def: DistrictDef) -> bool:
	return def.id in [DistrictDef.Type.GENERATOR, DistrictDef.Type.RESIDENTIAL]

static func _output_error(pd: PlanetData, poi: POIData, def: DistrictDef) -> float:
	var location := Location.mult(pd, poi)
	var geography := FeatureMap.terrain_mult(pd, poi, String(def.base_outputs.keys()[0]))
	var error := absf(2.0 - Economy.site_mult(geography, location))
	if _needs_full_location(def):
		error += absf(2.0 - location)
	return error

static func _probe(pd: PlanetData, def: DistrictDef, site: Vector2, parent: String) -> POIData:
	var poi := POIData.new()
	poi.label = ""
	poi.parent_city = parent
	poi.poi_type = def.to_poi_type()
	poi.type_tag = def.type_key()
	poi.lon_deg = rad_to_deg(site.x)
	poi.lat_deg = rad_to_deg(site.y)
	poi.site_features = FeatureMap.shares(pd, site.x, site.y)
	return poi

static func _offset(origin: Vector2, angle: float, bearing: float) -> Vector2:
	var lat := asin(clampf(sin(origin.y) * cos(angle) + cos(origin.y) * sin(angle) * cos(bearing), -1.0, 1.0))
	var lon := origin.x + atan2(sin(bearing) * sin(angle) * cos(origin.y), cos(angle) - sin(origin.y) * sin(lat))
	return Vector2(wrapf(lon, -PI, PI), lat)

static func _bearing(from: Vector2, to: Vector2) -> float:
	var delta_lon := to.x - from.x
	return atan2(sin(delta_lon) * cos(to.y), cos(from.y) * sin(to.y) - sin(from.y) * cos(to.y) * cos(delta_lon))
