class_name TerrainSampler
extends RefCounted

## Reads the terrain under a (lon, lat) point on a planet.
## Mirrors the height bands of the planet shaders, so what the player sees
## under the cursor is what the game logic gets.
##
## Usage:
##   var t: Dictionary = TerrainSampler.sample(data, lon_rad, lat_rad)
##   t.terrain  → TerrainSampler.Terrain
##   t.coastal  → bool (land with water close by)
##   t.height   → float (height relative to sea level; 0 for non-rocky bodies)

enum Terrain {
	DEEP_OCEAN, OCEAN, SHALLOWS, COAST, LOWLANDS, HIGHLANDS, MOUNTAINS, POLAR,
	MARIA,       # moon: dark basalt plains
	CLOUD_DECK,  # gas giant: no solid surface
	REGOLITH,    # asteroid: loose rubble everywhere
}

## Districts can't be placed beyond this latitude (matches LocationFinder's range).
const MAX_PLACE_LAT_DEG: float = 70.0
## Minimum angular distance between two surface districts.
const MIN_SPACING_DEG: float = 4.0
## Districts whose settlements are within this gap of each other are neighbours.
const NEIGHBOR_GAP_DEG: float = 9.0
## How far to look for water when deciding if a land point is coastal.
const COAST_PROBE_DEG: float = 4.0

static func sample(data: PlanetData, lon: float, lat: float) -> Dictionary:
	match PlanetData.get_shader_type(data.planet_type):
		PlanetData.ShaderType.GAS:
			return {"terrain": Terrain.CLOUD_DECK, "coastal": false, "height": 0.0}
		PlanetData.ShaderType.ASTEROID:
			return {"terrain": Terrain.REGOLITH, "coastal": false, "height": 0.0}
		PlanetData.ShaderType.MOON:
			return {"terrain": _moon_terrain(data, lon, lat), "coastal": false, "height": 0.0}

	var h := _height(data, lon, lat)
	var terrain := _rocky_terrain(h, lat)
	var coastal := false
	if is_dry(terrain) and terrain != Terrain.POLAR:
		coastal = terrain == Terrain.COAST or _water_nearby(data, lon, lat)
	return {"terrain": terrain, "coastal": coastal, "height": h}

## Height bands copied from planet_rocky.gdshader.
static func _rocky_terrain(h: float, lat: float) -> Terrain:
	# Shader paints ice from |lat| ≈ 77° (smoothstep 0.78–0.94 of the pole).
	if absf(lat) / (PI * 0.5) > 0.86:
		return Terrain.POLAR
	if h < -0.12: return Terrain.DEEP_OCEAN
	if h <  0.00: return Terrain.OCEAN
	if h <  0.07: return Terrain.SHALLOWS
	if h <  0.12: return Terrain.COAST
	if h <  0.26: return Terrain.LOWLANDS
	if h <  0.38: return Terrain.HIGHLANDS
	return Terrain.MOUNTAINS

static func _height(data: PlanetData, lon: float, lat: float) -> float:
	return PlanetNoise.height_class(lon, lat, data.seed, data.sea_level,
		data.terrain_roughness, data.continent_scale)

## Mirrors the mare mask in planet_moon.gdshader.
static func _moon_terrain(data: PlanetData, lon: float, lat: float) -> Terrain:
	var mare_n: float
	if TerrainMap.has_map(data.seed, TerrainMap.Mode.MOON):
		mare_n = TerrainMap.value(data.seed, lon, lat)
	else:
		var n := Vector3(sin(lon) * cos(lat), -sin(lat), cos(lon) * cos(lat))
		mare_n = PlanetNoise.fbm3(n * data.terrain_roughness * 1.8, 4, data.seed)
	return Terrain.MARIA if mare_n < -0.015 else Terrain.HIGHLANDS

static func _water_nearby(data: PlanetData, lon: float, lat: float) -> bool:
	var r := deg_to_rad(COAST_PROBE_DEG)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var plat := clampf(lat + sin(a) * r, -PI * 0.5, PI * 0.5)
		var plon := lon + cos(a) * r / maxf(cos(lat), 0.2)
		if _height(data, plon, plat) < 0.07:
			return true
	return false

static func is_dry(t: Terrain) -> bool:
	return t not in [Terrain.DEEP_OCEAN, Terrain.OCEAN, Terrain.SHALLOWS, Terrain.CLOUD_DECK]

static func is_water(t: Terrain) -> bool:
	return t in [Terrain.DEEP_OCEAN, Terrain.OCEAN, Terrain.SHALLOWS]

## Whether a point with this terrain satisfies a district's placement rule.
static func fits_placement(t: Dictionary, placement: LocationFinder.Placement) -> bool:
	var terrain: Terrain = t["terrain"]
	match placement:
		LocationFinder.Placement.LAND:  return is_dry(terrain) or terrain == Terrain.CLOUD_DECK
		LocationFinder.Placement.SEA:   return is_water(terrain) or terrain == Terrain.CLOUD_DECK
		LocationFinder.Placement.COAST: return t["coastal"] or terrain == Terrain.SHALLOWS \
				or terrain == Terrain.CLOUD_DECK
		_:                              return true

static func placement_label(placement: LocationFinder.Placement) -> String:
	match placement:
		LocationFinder.Placement.LAND:  return "land"
		LocationFinder.Placement.SEA:   return "water"
		LocationFinder.Placement.COAST: return "a coastline"
		_:                              return "any terrain"

## Player-facing name. Rocky worlds reuse the same height bands but their
## "oceans" are dunes, lava or dust depending on the planet type.
static func label(t: Terrain, planet_type: PlanetData.Type) -> String:
	match planet_type:
		PlanetData.Type.ARID:
			match t:
				Terrain.DEEP_OCEAN: return "Salt Basin"
				Terrain.OCEAN:      return "Dune Sea"
				Terrain.SHALLOWS:   return "Dry Flats"
				Terrain.COAST:      return "Basin Rim"
				Terrain.LOWLANDS:   return "Badlands"
				Terrain.HIGHLANDS:  return "Mesas"
		PlanetData.Type.VOLCANIC:
			match t:
				Terrain.DEEP_OCEAN: return "Lava Lake"
				Terrain.OCEAN:      return "Lava Sea"
				Terrain.SHALLOWS:   return "Cooling Crust"
				Terrain.COAST:      return "Lava Shore"
				Terrain.LOWLANDS:   return "Ash Plains"
				Terrain.HIGHLANDS:  return "Basalt Ridges"
		PlanetData.Type.ICE:
			match t:
				Terrain.DEEP_OCEAN: return "Deep Ice Sea"
				Terrain.OCEAN:      return "Ice Sea"
				Terrain.SHALLOWS:   return "Pack Ice"
				Terrain.LOWLANDS:   return "Tundra"
		PlanetData.Type.BARREN:
			match t:
				Terrain.DEEP_OCEAN: return "Deep Basin"
				Terrain.OCEAN:      return "Basin"
				Terrain.SHALLOWS:   return "Dust Flats"
				Terrain.COAST:      return "Basin Rim"
				Terrain.LOWLANDS:   return "Rock Plains"
	match t:
		Terrain.DEEP_OCEAN: return "Deep Ocean"
		Terrain.OCEAN:      return "Ocean"
		Terrain.SHALLOWS:   return "Shallows"
		Terrain.COAST:      return "Coast"
		Terrain.LOWLANDS:   return "Lowlands"
		Terrain.HIGHLANDS:  return "Highlands"
		Terrain.MOUNTAINS:  return "Mountains"
		Terrain.POLAR:      return "Polar Ice"
		Terrain.MARIA:      return "Maria"
		Terrain.CLOUD_DECK: return "Cloud Deck"
		Terrain.REGOLITH:   return "Regolith"
	return "Unknown"

## Angular distance between two (lon, lat) points, in radians.
static func angular_distance(lon_a: float, lat_a: float, lon_b: float, lat_b: float) -> float:
	var a := Vector3(sin(lon_a) * cos(lat_a), sin(lat_a), cos(lon_a) * cos(lat_a))
	var b := Vector3(sin(lon_b) * cos(lat_b), sin(lat_b), cos(lon_b) * cos(lat_b))
	return acos(clampf(a.dot(b), -1.0, 1.0))

## Full placement check for a surface district at (lon, lat).
## Returns { ok: bool, reason: String, terrain: Dictionary }.
static func check_site(data: PlanetData, def: DistrictDef, lon: float, lat: float) -> Dictionary:
	var t := sample(data, lon, lat)
	var result := {"ok": true, "reason": "", "terrain": t}
	if absf(rad_to_deg(lat)) > MAX_PLACE_LAT_DEG:
		result.ok = false
		result.reason = "Too close to the pole"
		return result
	if not fits_placement(t, def.placement):
		result.ok = false
		result.reason = "%s must be built on %s" % [def.display_name, placement_label(def.placement)]
		return result
	var min_d := deg_to_rad(MIN_SPACING_DEG)
	for p: POIData in data.custom_pois:
		if p.is_orbital():
			continue
		if angular_distance(lon, lat, deg_to_rad(p.lon_deg), deg_to_rad(p.lat_deg)) < min_d:
			result.ok = false
			result.reason = "Too close to %s" % p.label
			return result
	return result
