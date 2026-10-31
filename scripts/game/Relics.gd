class_name Relics
extends RefCounted

## Relics (playtest 31.10): a fixed set of artefacts, one per world, found in
## order. Each sits at a small site on its world — in Old Ruins, or in a Crater
## where the world has no ruins (the Moon) — shown on the map once the previous
## relic is found (the first from the start). Clicking the site tells its story
## and excavates it for a Science price. A found relic gives a global bonus and
## a hint where the next one lies. The Museum lists them all (RelicMuseum).
##
## State lives in GameState: relics_found { relic id: unix time } and
## relic_sites { relic id: Vector2(lon, lat) radians } (fixed once chosen).

## Kinds of bonus: "resource" multiplies one output everywhere (Economy.scope_bonus,
## a third scale after City and planet); "build_speed" makes every district
## build faster (ProductionManager.district_build_speed).
## Shown for the first relic before anything is found.
const FIRST_HINT := "Old Ruins on your home world hide something. Look for the relic mark on the map."

const CATALOGUE: Array[Dictionary] = [
	{"id": "first_compass", "name": "The First Compass", "world": "home",
		"story": "Under the toppled stones of the Old Ruins your surveyors find a bronze compass. Its needle ignores the poles and points, steadily, at the pale companion in the night sky.",
		"bonus": {"kind": "resource", "res": "credits", "value": 0.05},
		"cost": 250.0,
		"hint": "The Compass points at the Moon. Scan its surface: something waits inside one of its craters."},
	{"id": "selene_seal", "name": "The Selene Seal", "world": "moon",
		"story": "At the bottom of a crater lies a sealed hatch older than any human record. Its seal is a builder's mark — and every crew that touches it works faster.",
		"bonus": {"kind": "build_speed", "value": 0.25},
		"cost": 600.0,
		"hint": "The Seal's rim is etched with a rust-red, dusty world. The next relic lies beyond the Moon."},
	{"id": "rust_tablet", "name": "The Rust Tablet", "world": PlanetData.Type.ARID,
		"story": "A slab of oxidised metal covered in a miner's ledger nobody can read — yet its tallies always match your own.",
		"bonus": {"kind": "resource", "res": "raw", "value": 0.05},
		"cost": 1500.0,
		"hint": "The ledger ends with a drawing of ice and a single sung note."},
	{"id": "frost_choir", "name": "The Frost Choir", "world": PlanetData.Type.ICE,
		"story": "Crystal pipes buried in the ice hum when the wind passes. Scientists who listen sleep less and think more.",
		"bonus": {"kind": "resource", "res": "science", "value": 0.05},
		"cost": 3000.0,
		"hint": "The pipes fall silent when warmed — as if afraid of a burning world."},
	{"id": "ember_heart", "name": "The Ember Heart", "world": PlanetData.Type.VOLCANIC,
		"story": "A stone that never cools. Wired into the grid, it seems to lend every generator a little of its fire.",
		"bonus": {"kind": "resource", "res": "energy", "value": 0.05},
		"cost": 5000.0,
		"hint": "The last relic. The set is complete."},
]

# ── Queries ──────────────────────────────────────────────────────────────────

static func count() -> int:
	return CATALOGUE.size()

static func found_count() -> int:
	return GameState.relics_found.size()

static func is_found(id: String) -> bool:
	return GameState.relics_found.has(id)

static func index_of(id: String) -> int:
	for i in CATALOGUE.size():
		if CATALOGUE[i]["id"] == id:
			return i
	return -1

## The relic to look for now (the first not found), or {} when all are found.
static func next_relic() -> Dictionary:
	for r: Dictionary in CATALOGUE:
		if not is_found(r["id"]):
			return r
	return {}

## True once the relic's place is known: the first from the start, each later
## one once the one before it is found.
static func is_hinted(id: String) -> bool:
	var i := index_of(id)
	return i == 0 or (i > 0 and is_found(CATALOGUE[i - 1]["id"]))

## The world a relic lies on, or null (a later world not in this system).
static func world_of(r: Dictionary) -> PlanetData:
	var w = r["world"]
	if w is String:
		return GameState.get_home_planet() if w == "home" else GameState.home_moon()
	var sys: SolarData = GameState.get_home_solar()
	if sys != null:
		for p: PlanetData in sys.planets:
			if int(p.planet_type) == int(w) and p.seed != GameState.home_planet_seed:
				return p
	return null

## "+5% Credits everywhere" / "Districts build 25% faster".
static func bonus_text(r: Dictionary) -> String:
	var b: Dictionary = r["bonus"]
	if b["kind"] == "build_speed":
		return "Districts build %d%% faster (Orbit rockets too)" % roundi(float(b["value"]) * 100.0)
	return "+%d%% %s everywhere" % [roundi(float(b["value"]) * 100.0), PlanetTags.resource_label(String(b["res"]))]

## Global multiplier from found relics for resource `id` (1 = none).
static func global_mult(id: String) -> float:
	var key := Economy.RAW if id in [Economy.RAW, Economy.GOODS, Economy.FUEL, Economy.RARE] else id
	var m := 1.0
	for r: Dictionary in CATALOGUE:
		var b: Dictionary = r["bonus"]
		if b["kind"] == "resource" and String(b["res"]) == key and is_found(r["id"]):
			m += float(b["value"])
	return m

## Build speed from found relics (1 = none).
static func build_speed() -> float:
	var m := 1.0
	for r: Dictionary in CATALOGUE:
		if r["bonus"]["kind"] == "build_speed" and is_found(r["id"]):
			m += float(r["bonus"]["value"])
	return m

# ── Sites ────────────────────────────────────────────────────────────────────

## The relic sites to draw on `pd` now: [{ id, name, lon, lat }] (radians).
## Only the relic being looked for, once hinted and its world scanned.
static func sites_on(pd: PlanetData) -> Array:
	var out: Array = []
	if pd == null:
		return out
	var r := next_relic()
	if r.is_empty() or not is_hinted(r["id"]) or not GameState.is_scanned(pd.seed):
		return out
	var w := world_of(r)
	if w == null or w.seed != pd.seed:
		return out
	var at := site_of(r, pd)
	if at.is_finite():
		out.append({"id": r["id"], "name": "Relic site", "lon": at.x, "lat": at.y})
	return out

## Where a relic lies on its world (fixed once chosen): an Old Ruins cell, else
## a Crater cell, else a spot on land. Vector2.INF until the world's map exists.
static func site_of(r: Dictionary, pd: PlanetData) -> Vector2:
	var id: String = r["id"]
	if GameState.relic_sites.has(id):
		var v = GameState.relic_sites[id]
		return v if v is Vector2 else Vector2(float(v[0]), float(v[1]))
	if not FeatureMap.has_map(pd.seed):
		return Vector2.INF
	var cells := FeatureMap.cells_with(pd.seed, FeatureMap.F.RUINS)
	if cells.is_empty():
		cells = FeatureMap.cells_with(pd.seed, FeatureMap.F.CRATER)
	if cells.is_empty():
		cells = FeatureMap.cells_with(pd.seed, FeatureMap.F.PLAIN)
	if cells.is_empty():
		return Vector2.INF
	var rng := RandomNumberGenerator.new()
	rng.seed = pd.seed ^ 0x2E11C
	var at: Vector2 = cells[rng.randi() % cells.size()]
	GameState.relic_sites[id] = [at.x, at.y]
	return at

## Where a relic was found, for the news ({ seed, lon, lat } or {}).
static func _site_loc(r: Dictionary) -> Dictionary:
	var w := world_of(r)
	var v = GameState.relic_sites.get(r["id"], null)
	if w == null or v == null:
		return {}
	var at: Vector2 = v if v is Vector2 else Vector2(float(v[0]), float(v[1]))
	return {"seed": w.seed, "lon": at.x, "lat": at.y}

# ── Excavation ───────────────────────────────────────────────────────────────

## Why the relic can't be excavated now ("" when it can).
static func excavate_block(id: String) -> String:
	if is_found(id):
		return "Already in the Museum"
	if not is_hinted(id):
		return "Find the relic before it first"
	var r: Dictionary = CATALOGUE[index_of(id)]
	return Economy.cost_block({Economy.SCIENCE: float(r["cost"])})

## Pays and takes the relic. Returns false (and takes nothing) when it can't.
static func excavate(id: String) -> bool:
	if excavate_block(id) != "":
		return false
	var r: Dictionary = CATALOGUE[index_of(id)]
	if not Economy.pay({Economy.SCIENCE: float(r["cost"])}):
		return false
	GameState.relics_found[id] = int(Time.get_unix_time_from_system())
	Economy.invalidate_bonus_cache()
	GameState.relics_changed.emit()
	NewsFeed.post("Relic recovered: %s — %s." % [r["name"], bonus_text(r)], NewsFeed.Kind.EVENT,
		"%s\n\nNext: %s" % [r["story"], r["hint"]], r["name"], _site_loc(r))
	return true
