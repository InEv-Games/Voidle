## Neutral civilizations (Mechanic-Test/Neutral-Civs): peoples the player does
## not control, settled on other worlds of the home star system. They hold a
## world (sometimes a moon or two more) with a capital and a few districts,
## exactly as the player's settlements look — but they never grow or spread:
## what the generator gives them is what they have. Later the player meets
## them through diplomacy / quests and brings them into the civilization.
##
## Nothing here is saved: the same run always gets the same peoples (from the
## home system's seed). Only their standing with the player will be (later).
##
##   civ: { id, name, adjective, color, temperament {id, name, desc},
##          population, home (world seed), worlds [seed], relation }
##
## The home planet, its Moon, gas giants and any world the player has settled
## or is settling are never given to a neutral people.
class_name NeutralCivs
extends RefCounted

## How many peoples a system holds (fewer when it has few free worlds).
const CIVS_MIN := 2
const CIVS_MAX := 3
## Extra worlds a people holds besides its homeworld.
const EXTRA_WORLDS_MAX := 2
## Districts round the capital: on the homeworld / on another of their worlds.
const HOME_DISTRICTS := Vector2i(4, 6)
const COLONY_DISTRICTS := Vector2i(1, 3)

const NAME_A := ["Vel", "Oru", "Kesh", "Tal", "Ama", "Syr", "Dhu", "Ix", "Nor", "Qel", "Ur", "Zha", "Mer", "Ost"]
const NAME_B := ["ani", "ethi", "orin", "uvai", "essa", "ari", "ondi", "ul", "ei", "aru", "ith", "ova"]
const SETTLE_A := ["Hollow", "Ember", "Still", "Deep", "High", "Salt", "Ash", "Stone", "Mirror", "Iron", "Glass", "Dawn"]
const SETTLE_B := ["reach", "hold", "well", "spire", "fold", "watch", "gate", "haven", "mark", "crest", "vale", "rest"]

const TEMPERAMENTS := [
	{"id": "isolationist", "name": "Isolationist", "desc": "They keep to themselves and answer few calls. Trust is earned slowly."},
	{"id": "mercantile", "name": "Mercantile", "desc": "Traders at heart. They talk to anyone with something to offer."},
	{"id": "scholarly", "name": "Scholarly", "desc": "Keepers of old knowledge, curious about what we have learned."},
	{"id": "devout", "name": "Devout", "desc": "Bound by an old faith. They judge newcomers by their deeds."},
	{"id": "proud", "name": "Proud", "desc": "An old people with long memories. They want to be met as equals."},
]

## Their colours: apart from the player's district families (one each).
const COLORS: Array[Color] = [Color(0.86, 0.42, 0.95), Color(0.30, 0.90, 0.78), Color(0.98, 0.52, 0.40),
	Color(0.62, 0.70, 1.0), Color(0.95, 0.85, 0.45)]

## District kinds a neutral settlement can have: [POIType, type_tag].
const DISTRICT_KINDS := [
	[POIData.POIType.MINING, "mining"], [POIData.POIType.ENERGY, "generator"],
	[POIData.POIType.SCIENCE, "science"], [POIData.POIType.RESIDENTIAL, "residential"],
	[POIData.POIType.COMMERCIAL, "commercial"]]

## Prefix of a neutral settlement's label (never a player district's).
const LABEL_PREFIX := "nc:"

## Dev: changing it rolls new peoples (DevConsole `civs reroll`).
static var salt := 0

static var _key := -1
static var _civs: Array[Dictionary] = []
## world seed → its settlements (POIData), made the first time it is shown.
static var _pois := {}


## Every neutral people of the home system.
static func all() -> Array[Dictionary]:
	var sd := GameState.get_home_solar()
	if sd == null:
		return []
	var key := hash([sd.seed, GameState.home_planet_seed, salt])
	if key != _key:
		_key = key
		_pois.clear()
		_civs = _generate(sd)
	return _civs


## The people holding a world, or {}.
static func civ_of_world(seed_val: int) -> Dictionary:
	for c: Dictionary in all():
		if seed_val in (c["worlds"] as Array):
			return c
	return {}


static func civ_by_id(id: String) -> Dictionary:
	for c: Dictionary in all():
		if c["id"] == id:
			return c
	return {}


## Whether a label is a neutral settlement's.
static func is_neutral_label(label: String) -> bool:
	return label.begins_with(LABEL_PREFIX)


## A world's neutral settlements (empty if no people holds it). Made once per
## run and kept, so the same objects come back every time.
static func settlements_on(pd: PlanetData) -> Array[POIData]:
	var out: Array[POIData] = []
	if pd == null:
		return out
	var civ := civ_of_world(pd.seed)
	if civ.is_empty():
		return out
	if not _pois.has(pd.seed):
		_pois[pd.seed] = _make_settlements(civ, pd)
	out.assign(_pois[pd.seed])
	return out


## Every settlement of a people that has been made so far, by world.
static func settlement_count(civ: Dictionary) -> int:
	var n := 0
	for s: int in civ["worlds"]:
		var pd := _world(s)
		n += settlements_on(pd).size() if pd != null else 0
	return n


## The PlanetData of a body of the home system.
static func _world(seed_val: int) -> PlanetData:
	var sd := GameState.get_home_solar()
	if sd == null:
		return null
	for pd: PlanetData in sd.planets:
		if pd.seed == seed_val:
			return pd
		for m: PlanetData in pd.moons:
			if m.seed == seed_val:
				return m
	return null


static func world_name(seed_val: int) -> String:
	var pd := _world(seed_val)
	return pd.planet_name if pd != null else "?"


# ── Generation ───────────────────────────────────────────────────────────────

static func _free_world(pd: PlanetData) -> bool:
	if pd.seed == GameState.home_planet_seed:
		return false
	var moon := GameState.home_moon()
	if moon != null and pd.seed == moon.seed:
		return false
	if PlanetData.get_shader_type(pd.planet_type) == PlanetData.ShaderType.GAS:
		return false
	var pp := GameState.find_planet(pd.seed)
	if pp != null and (pp.is_colonized or pp.is_colonizing):
		return false
	return true


static func _generate(sd: SolarData) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([sd.seed, 0x4E43, salt])
	# free worlds, in system order (a people's extra worlds are its neighbours)
	var free: Array[PlanetData] = []
	for pd: PlanetData in sd.planets:
		if pd.moons.is_empty():
			pd.generate_moons(pd.seed)
		if _free_world(pd):
			free.append(pd)
		for m: PlanetData in pd.moons:
			if _free_world(m):
				free.append(m)
	var out: Array[Dictionary] = []
	if free.is_empty():
		return out
	var n := mini(rng.randi_range(CIVS_MIN, CIVS_MAX), free.size())
	var colors := COLORS.duplicate()
	var temps := TEMPERAMENTS.duplicate()
	var used_names := {}
	for k in n:
		if free.is_empty():
			break
		var home: PlanetData = free.pop_at(rng.randi() % free.size())
		var worlds: Array = [home.seed]
		# extra worlds: the free ones nearest the homeworld in the system's order
		for e in rng.randi_range(0, EXTRA_WORLDS_MAX):
			var best := -1
			var best_d := INF
			for i in free.size():
				var d := absf(float(_order(sd, free[i].seed) - _order(sd, home.seed)))
				if d < best_d:
					best_d = d
					best = i
			if best < 0 or best_d > 3.0:
				break
			worlds.append(free.pop_at(best).seed)
		var nm := ""
		for t in 20:
			nm = String(NAME_A[rng.randi() % NAME_A.size()]) + String(NAME_B[rng.randi() % NAME_B.size()])
			if not used_names.has(nm):
				break
		used_names[nm] = true
		var col: Color = colors.pop_at(rng.randi() % colors.size())
		var temp: Dictionary = temps.pop_at(rng.randi() % temps.size())
		out.append({"id": "civ%d" % k, "name": nm, "adjective": _adjective(nm), "color": col,
			"temperament": temp, "home": home.seed, "worlds": worlds,
			"population": rng.randi_range(40, 900) * 1000 * worlds.size(), "relation": "uncontacted",
			"seed": rng.randi()})
	return out


## A body's place in the system (planets 0, 1, …; a moon just after its planet).
static func _order(sd: SolarData, seed_val: int) -> int:
	for i in sd.planets.size():
		var pd: PlanetData = sd.planets[i]
		if pd.seed == seed_val:
			return i * 10
		for j in pd.moons.size():
			if (pd.moons[j] as PlanetData).seed == seed_val:
				return i * 10 + j + 1
	return 0


static func _adjective(nm: String) -> String:
	if nm.ends_with("i") or nm.ends_with("ei"):
		return nm
	if nm.ends_with("a"):
		return nm + "n"
	return nm + "ian"


## A people's settlements on one of its worlds: a capital (City) on dry land,
## its districts round it at settlement spacing, each one fixed for the run.
static func _make_settlements(civ: Dictionary, pd: PlanetData) -> Array[POIData]:
	var out: Array[POIData] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([int(civ["seed"]), pd.seed])
	var is_home: bool = int(civ["home"]) == pd.seed
	var k := TerrainSampler.body_scale(pd)
	var cap_pos := _land_spot(pd, rng, Vector2.INF, 0.0)
	if not cap_pos.is_finite():
		return out
	var cap := _poi(civ, pd, rng, 0, POIData.POIType.CITY, "city", cap_pos)
	cap.civ_size = rng.randf_range(7.0, 11.0) if is_home else rng.randf_range(3.5, 5.5)
	cap.level = 3 if is_home else 2
	out.append(cap)
	var span := HOME_DISTRICTS if is_home else COLONY_DISTRICTS
	var want := rng.randi_range(span.x, span.y)
	var spacing := (TerrainSampler.SETTLE_BASE_DEG * 2.0 + 3.2) * k
	for i in want:
		# next to the capital or to one of the districts already there
		var anchor: POIData = out[rng.randi() % out.size()]
		var pos := _land_spot(pd, rng, Vector2(anchor.lon_deg, anchor.lat_deg), spacing, out, spacing * 0.8)
		if not pos.is_finite():
			continue
		var kind: Array = DISTRICT_KINDS[rng.randi() % DISTRICT_KINDS.size()]
		var d := _poi(civ, pd, rng, out.size(), kind[0], kind[1], pos)
		d.parent_city = cap.label
		d.civ_size = rng.randf_range(1.5, 4.0) if is_home else rng.randf_range(1.0, 2.5)
		d.level = rng.randi_range(1, 3)
		out.append(d)
	return out


static func _poi(civ: Dictionary, pd: PlanetData, rng: RandomNumberGenerator, i: int,
		type: POIData.POIType, tag: String, pos: Vector2) -> POIData:
	var p := POIData.new()
	p.label = "%s%s:%d:%d" % [LABEL_PREFIX, civ["id"], pd.seed, i]
	p.poi_type = type
	p.type_tag = tag
	p.civ_id = civ["id"]
	p.manual_position = true
	p.lon_deg = pos.x
	p.lat_deg = pos.y
	var t := TerrainSampler.sample(pd, deg_to_rad(pos.x), deg_to_rad(pos.y))
	p.terrain = int(t["terrain"])
	p.coastal = bool(t["coastal"])
	p.display_name = String(SETTLE_A[rng.randi() % SETTLE_A.size()]) + String(SETTLE_B[rng.randi() % SETTLE_B.size()])
	if i == 0:
		p.capital_name = p.display_name
	return p


## A dry spot (lon°, lat°): anywhere on the world (near = INF), or about `dist`
## degrees from `near`, at least `gap` from every settlement in `taken`.
static func _land_spot(pd: PlanetData, rng: RandomNumberGenerator, near: Vector2, dist: float,
		taken: Array[POIData] = [], gap := 0.0) -> Vector2:
	for t in 120:
		var lon: float
		var lat: float
		if not near.is_finite():
			lon = rng.randf_range(-180.0, 180.0)
			lat = rng.randf_range(-50.0, 50.0)
		else:
			var a := rng.randf_range(0.0, TAU)
			var d := dist * rng.randf_range(0.9, 1.25)
			lat = clampf(near.y + d * sin(a), -70.0, 70.0)
			lon = near.x + d * cos(a) / maxf(cos(deg_to_rad(near.y)), 0.2)
		var ok := true
		for q: POIData in taken:
			if _deg_between(Vector2(lon, lat), Vector2(q.lon_deg, q.lat_deg)) < gap:
				ok = false
				break
		if not ok:
			continue
		var s := TerrainSampler.sample(pd, deg_to_rad(lon), deg_to_rad(lat))
		if TerrainSampler.is_dry(s["terrain"]) and int(s["terrain"]) != TerrainSampler.Terrain.POLAR:
			return Vector2(wrapf(lon, -180.0, 180.0), lat)
	return Vector2.INF


static func _deg_between(a: Vector2, b: Vector2) -> float:
	var va := Vector3(cos(deg_to_rad(a.y)) * cos(deg_to_rad(a.x)), sin(deg_to_rad(a.y)), cos(deg_to_rad(a.y)) * sin(deg_to_rad(a.x)))
	var vb := Vector3(cos(deg_to_rad(b.y)) * cos(deg_to_rad(b.x)), sin(deg_to_rad(b.y)), cos(deg_to_rad(b.y)) * sin(deg_to_rad(b.x)))
	return rad_to_deg(acos(clampf(va.dot(vb), -1.0, 1.0)))
