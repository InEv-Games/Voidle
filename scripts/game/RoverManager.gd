## RoverManager — autoload. Surface units (TEST: Development/Some-New-Mechanics-Test).
##
## Rovers are exploration units that drive on a world's surface. They are not
## fighters: they go where they are sent and survey the ground around them as
## they pass (explored grid per world). The planet view draws and commands them
## (RoverLayer); this node owns their state, moves them every frame — also while
## another view is open — and saves them with the game.
##
## Positions are planet-fixed unit vectors (x = sin(lon)·cos(lat), y = sin(lat),
## z = cos(lon)·cos(lat)), the same frame POILayer uses for surface circles.
## Driving follows the land: a coarse lon/lat grid is routed with AStar3D and the
## route is straightened where a direct arc stays on land. City roads (the land
## segments PlanetaryView routes, set_roads) join the same graph as cheap nodes:
## a rover drives ROAD_SPEED_MULT times faster on them, so routes take the road
## when it saves time. Sea, gas giants and
## the poles are out of bounds. On the Moon, ion storm regions slow a rover down.
##
## Actions: an idle rover can work where it stands (ACTIONS): each takes play
## time, costs its inputs up front and pays its outputs when done, like a fixed
## production run. Which ones it offers depends on the ground under it
## (FeatureMap). From near a City on a world with an Orbit it can lift to orbit;
## in orbit it can land anywhere on that world or transfer to another settled one.
##
## The whole feature sits behind ENABLED: false = no rovers anywhere, nothing
## spawned, the planet view behaves as before (saved rovers are kept untouched).
extends Node

signal rovers_changed(planet_seed: int)          # added / removed
signal rover_order_changed(rover_id: String)     # new path, arrived, stopped
signal area_explored(planet_seed: int)
signal rover_action_changed(rover_id: String)    # started, finished, cancelled

## Test switch for the whole unit system.
const ENABLED := true

## Driving speed, km of surface per second of play.
const SPEED_KM_S := 30.0
## Speed multiplier inside an ion storm region (Moon).
const STORM_SLOW := 0.4
## Speed multiplier on a City road.
const ROAD_SPEED_MULT := 3.0
## How far around itself a rover surveys, km.
const SCAN_RADIUS_KM := 350.0
## Rovers given at once on a world that has a City but no rover yet (test).
## 0: rovers come from the Rover Bay (Capital District building) only.
const STARTER_ROVERS := 0
## Rover Bay: what one rover costs (×ROVER_COST_GROWTH per rover owned) and
## how long it takes.
const ROVER_COST := {"credits": 1500.0}
const ROVER_COST_GROWTH := 1.25
const ROVER_BUILD_SEC := 60.0
const BAY_ID := "rover_bay"
## Highest latitude a rover drives to (degrees).
const MAX_LAT_DEG := 78.0

## How close (degrees) to a City a rover must be to lift to orbit.
const ORBIT_CITY_DEG := 6.0

## Ground actions. where: FeatureMap ids the rover must stand on (any of them;
## empty = anywhere). "@mineral" in out = this world's first mineral.
const ACTIONS: Array[Dictionary] = [
	{"id": "survey", "name": "Field Survey", "dur": 45.0,
		"in": {"credits": 120.0}, "out": {"science": 45.0}, "where": [],
		"desc": "Reads the ground around it."},
	{"id": "core", "name": "Core Sample", "dur": 60.0,
		"in": {"credits": 160.0}, "out": {"@mineral": 25.0},
		"where": ["terrain_mountain", "terrain_crater"],
		"desc": "Drills into exposed rock and brings up ore."},
	{"id": "ruins", "name": "Scan Ruins", "dur": 90.0,
		"in": {"credits": 300.0}, "out": {"science": 180.0}, "where": ["terrain_ruins"],
		"desc": "Maps what is left of the old builders."},
	{"id": "caves", "name": "Explore Caves", "dur": 120.0,
		"in": {"credits": 400.0}, "out": {"science": 120.0, "rare_elements": 3.0},
		"where": ["terrain_caves"], "desc": "Goes under the surface."},
	{"id": "storm", "name": "Log Ion Storm", "dur": 60.0,
		"in": {"credits": 100.0}, "out": {"science": 90.0}, "where": ["terrain_ion_storm"],
		"desc": "Records the storm from inside it."},
	{"id": "ice", "name": "Ice Core", "dur": 60.0,
		"in": {"credits": 150.0}, "out": {"science": 80.0},
		"where": ["terrain_glacier", "terrain_tundra"], "desc": "Old air, trapped in ice."},
	{"id": "thermal", "name": "Thermal Reading", "dur": 60.0,
		"in": {"credits": 150.0}, "out": {"science": 70.0},
		"where": ["terrain_volcanic", "terrain_geothermal"], "desc": "Measures the heat below."},
]
## Movement actions.
const ORBIT_UP := {"id": "orbit_up", "name": "Lift to Orbit", "dur": 25.0,
	"in": {"credits": 500.0}, "out": {}, "desc": "Rides up to the world's Orbit."}
const LAND := {"id": "land", "name": "Land", "dur": 15.0,
	"in": {"credits": 200.0}, "out": {}, "desc": "Pick a spot on the world, then it comes down."}
const TRANSFER := {"id": "transfer", "name": "Transfer", "dur": 60.0,
	"in": {"credits": 800.0}, "out": {}, "desc": "Flies to another settled world's orbit."}

## Route grid (lon × lat cells) and survey grid.
const NAV_W := 120
const NAV_H := 60
const EXP_W := 90
const EXP_H := 45

## id -> RoverData
var _rovers: Dictionary = {}
var _next_id := 1
## seed -> PackedByteArray(EXP_W * EXP_H), 1 = surveyed
var _explored: Dictionary = {}
## seed -> { astar: AStar3D, open: PackedByteArray, road: { id: true } } (runtime only)
var _nav: Dictionary = {}
## seed -> Array of PackedVector3Array: land road polylines (unit vectors), runtime only
var _roads: Dictionary = {}
var _road_sig: Dictionary = {}
var _scan_t := 0.0
## seed -> { start, end, lon, lat }: a rover being built in that world's Rover Bay.
var _builds: Dictionary = {}


# ── Frame ────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not ENABLED:
		return
	_tick_builds()
	if _rovers.is_empty():
		return
	_scan_t += delta
	var scan_now := _scan_t >= 0.25
	if scan_now:
		_scan_t = 0.0
	for r: RoverData in _rovers.values():
		if r.is_busy() and GameState.play_seconds >= float(r.action.get("end", 0.0)):
			_complete_action(r)
		if r.in_orbit():
			continue
		if r.is_moving() and not r.is_busy():   # an order given while it works waits
			_drive(r, delta)
		if scan_now:
			_survey(r)


func _drive(r: RoverData, delta: float) -> void:
	var radius := _radius_km(r.planet_seed)
	var base := SPEED_KM_S * _speed_factor(r) * delta / radius   # radians at off-road speed
	var budget := 1.0   # share of this frame left
	while budget > 0.0 and not r.path.is_empty():
		var step := base * budget * (ROAD_SPEED_MULT if r.on_road() else 1.0)
		var target: Vector3 = r.path[0]
		var ang := r.pos.angle_to(target)
		if ang <= step:
			r.km_driven += ang * radius
			r.heading = (target - r.pos).normalized() if ang > 1e-6 else r.heading
			r.pos = target
			r.path.pop_front()
			if not r.path_road.is_empty():
				r.path_road.pop_front()
			budget -= budget * (ang / maxf(step, 1e-9))
			if not r.goals.is_empty() and r.pos.angle_to(r.goals[0]) < 1e-4:
				r.goals.pop_front()
				if r.path.is_empty():
					AudioManager.play("click")
			continue
		var next := r.pos.slerp(target, step / ang).normalized()
		r.heading = (next - r.pos).normalized()
		r.km_driven += step * radius
		r.pos = next
		budget = 0.0
	if r.path.is_empty():
		r.goals.clear()
		r.path_road.clear()
		rover_order_changed.emit(r.id)


func _speed_factor(r: RoverData) -> float:
	var pd := GameState.get_planet_data(r.planet_seed)
	if pd == null or pd.planet_type != PlanetData.Type.MOON:
		return 1.0
	var sh := FeatureMap.shares(pd, r.lon(), r.lat())
	return STORM_SLOW if float(sh.get("terrain_ion_storm", 0.0)) >= 1.0 else 1.0


func in_storm(r: RoverData) -> bool:
	return _speed_factor(r) < 1.0


## Seconds left to the last goal at today's speeds (road / off-road; a storm
## counts only where the rover is now).
func eta_sec(r: RoverData) -> float:
	if r.path.is_empty():
		return 0.0
	var radius := _radius_km(r.planet_seed)
	var speed := SPEED_KM_S * _speed_factor(r)
	var t := action_left(r)   # a planned drive starts when the work ends
	var prev := r.pos
	for i in r.path.size():
		var km := prev.angle_to(r.path[i]) * radius
		var road: bool = r.path_road[i] if i < r.path_road.size() else false
		t += km / (speed * (ROAD_SPEED_MULT if road else 1.0))
		prev = r.path[i]
	return t


## Seconds left to goal `gi` (0 = the next one).
func eta_to_goal(r: RoverData, gi: int) -> float:
	if gi < 0 or gi >= r.goals.size():
		return 0.0
	var radius := _radius_km(r.planet_seed)
	var speed := SPEED_KM_S * _speed_factor(r)
	var t := 0.0
	var prev := r.pos
	var seen := 0
	for i in r.path.size():
		var road: bool = r.path_road[i] if i < r.path_road.size() else false
		t += prev.angle_to(r.path[i]) * radius / (speed * (ROAD_SPEED_MULT if road else 1.0))
		prev = r.path[i]
		if seen < r.goals.size() and r.path[i].angle_to(r.goals[seen]) < 1e-4:
			if seen == gi:
				return t
			seen += 1
	return t


static func format_eta(sec: float) -> String:
	var s := int(ceil(sec))
	if s >= 3600:
		return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
	return "%d:%02d" % [s / 60, s % 60]


# ── Queries ──────────────────────────────────────────────────────────────────

func rovers_on(planet_seed: int) -> Array[RoverData]:
	var out: Array[RoverData] = []
	for r: RoverData in _rovers.values():
		if r.planet_seed == planet_seed:
			out.append(r)
	return out


func get_rover(id: String) -> RoverData:
	return _rovers.get(id, null)


static func dir_of(lon: float, lat: float) -> Vector3:
	return Vector3(sin(lon) * cos(lat), sin(lat), cos(lon) * cos(lat))


func _radius_km(planet_seed: int) -> float:
	var pd := GameState.get_planet_data(planet_seed)
	return Location.radius_km(pd) if pd != null else Balance.cfg.planet_radius_km


## Whether rovers can drive on this kind of world at all.
static func world_allows(pd: PlanetData) -> bool:
	if pd == null:
		return false
	var st := PlanetData.get_shader_type(pd.planet_type)
	return st != PlanetData.ShaderType.GAS


## Whether a rover can stand at this point.
func passable(pd: PlanetData, lon: float, lat: float) -> bool:
	if absf(rad_to_deg(lat)) > MAX_LAT_DEG:
		return false
	if PlanetData.get_shader_type(pd.planet_type) != PlanetData.ShaderType.ROCKY:
		return true
	var h := PlanetNoise.height_class(lon, lat, pd.seed, pd.sea_level,
		pd.terrain_roughness, pd.continent_scale)
	return h >= TerrainSampler.SHORE_H


# ── Spawning ─────────────────────────────────────────────────────────────────

func spawn(pd: PlanetData, lon: float, lat: float) -> RoverData:
	var r := RoverData.new()
	r.id = "rv%d" % _next_id
	r.name = "Rover-%d" % _next_id
	_next_id += 1
	r.planet_seed = pd.seed
	r.pos = dir_of(lon, lat)
	_rovers[r.id] = r
	_survey(r)
	rovers_changed.emit(pd.seed)
	return r


## Test helper: gives a world its starter rovers beside its first City.
func ensure_starters(pd: PlanetData) -> void:
	if not ENABLED or not world_allows(pd) or not rovers_on(pd.seed).is_empty():
		return
	var city: POIData = null
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital():
			city = p
			break
	if city == null:
		return
	var clon := deg_to_rad(city.lon_deg)
	var clat := deg_to_rad(city.lat_deg)
	var placed := 0
	for i in 24:
		if placed >= STARTER_ROVERS:
			break
		var a := TAU * float(i) / 8.0
		var d := deg_to_rad(2.5 + 1.5 * float(i / 8))
		var lon := clon + cos(a) * d / maxf(cos(clat), 0.2)
		var lat := clampf(clat + sin(a) * d, -PI * 0.5, PI * 0.5)
		if passable(pd, lon, lat):
			spawn(pd, lon, lat)
			placed += 1


func remove_all_on(planet_seed: int) -> void:
	for r: RoverData in rovers_on(planet_seed):
		_rovers.erase(r.id)
	rovers_changed.emit(planet_seed)


# ── Orders ───────────────────────────────────────────────────────────────────

## Sends a rover to (lon, lat). queue = add after its current goals (Shift).
## Returns false if there is no way there (sea, pole, cut-off land).
func order_move(r: RoverData, pd: PlanetData, lon: float, lat: float, queue := false) -> bool:
	var goal := dir_of(lon, lat)
	if r.in_orbit() or not passable(pd, lon, lat):
		return false
	# while it works the route is only planned: it drives once the work is done
	# (or right away with move_now)
	var from := r.pos
	if queue and not r.goals.is_empty():
		from = r.goals[r.goals.size() - 1]
	var route := find_route(pd, from, goal)
	var pts: Array[Vector3] = route["points"]
	if pts.is_empty():
		return false
	if not queue:
		r.path.clear()
		r.path_road.clear()
		r.goals.clear()
	r.path.append_array(pts)
	var flags: Array[bool] = route["road"]
	r.path_road.append_array(flags)
	r.goals.append(goal)
	rover_order_changed.emit(r.id)
	return true


func stop(r: RoverData) -> void:
	r.path.clear()
	r.path_road.clear()
	r.goals.clear()
	rover_order_changed.emit(r.id)


# ── Actions ──────────────────────────────────────────────────────────────────

## What the rover can do now: [{ id, name, desc, dur, in, out, ok, why, target }].
## Listed even when blocked (why says what's missing), so the panel can show it.
func actions_for(r: RoverData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var pd := GameState.get_planet_data(r.planet_seed)
	if pd == null:
		return out
	if r.in_orbit():
		out.append(_resolved(r, LAND, pd, {}))
		for dest: PlanetData in _transfer_targets(r.planet_seed):
			var a := _resolved(r, TRANSFER, pd, {"seed": dest.seed})
			a["name"] = "Transfer to %s" % dest.planet_name
			out.append(a)
		return out
	var sh := FeatureMap.shares(pd, r.lon(), r.lat())
	for def: Dictionary in ACTIONS:
		var where: Array = def["where"]
		var here := where.is_empty()
		for f in where:
			if float(sh.get(String(f), 0.0)) >= 1.0:
				here = true
		if here:
			out.append(_resolved(r, def, pd, {}))
	var pp := GameState.find_planet(r.planet_seed)
	if pp != null and pp.orbit_level > 0:
		var up := _resolved(r, ORBIT_UP, pd, {})
		if not _near_city(pd, r):
			up["hidden"] = true
			up["ok"] = false
		out.append(up)
	return out


func _resolved(r: RoverData, def: Dictionary, pd: PlanetData, target: Dictionary) -> Dictionary:
	var a := def.duplicate(true)
	var outs := {}
	for k: String in (def["out"] as Dictionary):
		var id := k
		if k == "@mineral":
			var raws := Economy.raw_for_body(pd)
			if raws.is_empty():
				continue
			id = String(raws[0]["id"])
		outs[id] = float(def["out"][k])
	a["out"] = outs
	a["target"] = target
	# hidden: not offered right now (busy, driving); why: can't pay
	# hidden: not offered while it drives; while it works the others stay listed
	# but can't be started (why = "Busy")
	a["hidden"] = r.is_moving() and not r.is_busy()
	var why := "Busy" if r.is_busy() else Economy.cost_block(a["in"])
	a["why"] = why
	a["ok"] = why == "" and not a["hidden"]
	return a


func _near_city(pd: PlanetData, r: RoverData) -> bool:
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital():
			var c := dir_of(deg_to_rad(p.lon_deg), deg_to_rad(p.lat_deg))
			if r.pos.angle_to(c) <= deg_to_rad(ORBIT_CITY_DEG):
				return true
	return false


## Other settled worlds of the home system a rover in orbit can fly to.
func _transfer_targets(from_seed: int) -> Array[PlanetData]:
	var out: Array[PlanetData] = []
	var home := GameState.get_home_planet()
	if home == null:
		return out
	var bodies: Array[PlanetData] = [home]
	for m: PlanetData in home.moons:
		bodies.append(m)
	for b: PlanetData in bodies:
		if b.seed == from_seed or not world_allows(b):
			continue
		var pp := GameState.find_planet(b.seed)
		if pp != null and pp.is_colonized:
			out.append(b)
	return out


## Pays and starts action `id` (target: { lon, lat } for land, { seed } for transfer).
func start_action(r: RoverData, id: String, target: Dictionary = {}) -> bool:
	var pick: Dictionary = {}
	for a: Dictionary in actions_for(r):
		if a["id"] == id and (id != "transfer" or int(a["target"].get("seed", -1)) == int(target.get("seed", -2))):
			pick = a
	if pick.is_empty() or not pick["ok"]:
		return false
	if id == "land":
		var pd := GameState.get_planet_data(r.planet_seed)
		if pd == null or not passable(pd, float(target.get("lon", 0.0)), float(target.get("lat", 0.0))):
			return false
	if not Economy.pay(pick["in"]):
		return false
	var t := GameState.play_seconds
	r.action = {"id": id, "name": pick["name"], "start": t, "end": t + float(pick["dur"]),
		"in": pick["in"], "out": pick["out"], "target": target}
	rover_action_changed.emit(r.id)
	return true


## Calls the running action off (inputs back) so a planned drive starts now.
func move_now(r: RoverData) -> void:
	cancel_action(r)


## Whether a drive is planned but waits for the running action.
func waiting_to_move(r: RoverData) -> bool:
	return r.is_busy() and r.is_moving()


## Calls the running action off and gives its inputs back.
func cancel_action(r: RoverData) -> void:
	if not r.is_busy():
		return
	var ins: Dictionary = r.action.get("in", {})
	for k: String in ins:
		Economy.add(k, float(ins[k]))
	r.action = {}
	rover_action_changed.emit(r.id)


func action_progress(r: RoverData) -> float:
	if not r.is_busy():
		return 0.0
	var s := float(r.action.get("start", 0.0))
	var e := float(r.action.get("end", 0.0))
	return clampf((GameState.play_seconds - s) / maxf(e - s, 0.001), 0.0, 1.0)


func action_left(r: RoverData) -> float:
	return maxf(0.0, float(r.action.get("end", 0.0)) - GameState.play_seconds) if r.is_busy() else 0.0


func _complete_action(r: RoverData) -> void:
	var a := r.action
	r.action = {}
	var outs: Dictionary = a.get("out", {})
	for k: String in outs:
		Economy.add(k, float(outs[k]))
	var target: Dictionary = a.get("target", {})
	match String(a.get("id", "")):
		"orbit_up":
			r.state = 1
			r.path.clear()
			r.path_road.clear()
			r.goals.clear()
		"land":
			r.state = 0
			r.pos = dir_of(float(target.get("lon", 0.0)), float(target.get("lat", 0.0)))
			_survey(r)
		"transfer":
			var to := int(target.get("seed", r.planet_seed))
			var from := r.planet_seed
			for b: PlanetData in _transfer_targets(from):
				if b.seed == to:
					GameState.cache_planet_data(b)   # radius / ground lookups there
			r.planet_seed = to
			rovers_changed.emit(from)
			rovers_changed.emit(to)
	AudioManager.play("cash" if not outs.is_empty() else "click")
	rover_action_changed.emit(r.id)
	if r.repeat and not outs.is_empty() and r.path.is_empty():   # a planned drive goes first
		start_action(r, String(a.get("id", "")), target)


# ── Rover Bay ────────────────────────────────────────────────────────────────

## Cost of the next rover (grows with every rover owned).
func rover_cost() -> Dictionary:
	var out := {}
	var mult := pow(ROVER_COST_GROWTH, float(_rovers.size()))
	for k: String in ROVER_COST:
		out[k] = roundf(float(ROVER_COST[k]) * mult)
	return out


func is_building(planet_seed: int) -> bool:
	return _builds.has(planet_seed)


func build_progress(planet_seed: int) -> float:
	var b: Dictionary = _builds.get(planet_seed, {})
	if b.is_empty():
		return 0.0
	var st := float(b["start"])
	return clampf((GameState.play_seconds - st) / maxf(float(b["end"]) - st, 0.001), 0.0, 1.0)


func build_left(planet_seed: int) -> float:
	var b: Dictionary = _builds.get(planet_seed, {})
	return maxf(0.0, float(b.get("end", 0.0)) - GameState.play_seconds) if not b.is_empty() else 0.0


## Pays for a rover and starts building it; it rolls out at (lon, lat) (radians,
## beside the Capital). False when busy or short.
func start_rover_build(pd: PlanetData, lon: float, lat: float) -> bool:
	if not ENABLED or is_building(pd.seed) or not world_allows(pd):
		return false
	if not Economy.pay(rover_cost()):
		return false
	var t := GameState.play_seconds
	_builds[pd.seed] = {"start": t, "end": t + ROVER_BUILD_SEC, "lon": lon, "lat": lat}
	return true


func _tick_builds() -> void:
	if _builds.is_empty():
		return
	for sd: int in _builds.keys():
		var b: Dictionary = _builds[sd]
		if GameState.play_seconds < float(b["end"]):
			continue
		_builds.erase(sd)
		var pd := GameState.get_planet_data(sd)
		if pd == null:
			continue
		# roll out on the nearest passable ground around the bay
		var lon := float(b["lon"])
		var lat := float(b["lat"])
		for i in 32:
			var a := TAU * float(i) / 8.0
			var d := deg_to_rad(1.0 + 0.8 * float(i / 8))
			var plon := lon + cos(a) * d / maxf(cos(lat), 0.2)
			var plat := clampf(lat + sin(a) * d, -1.4, 1.4)
			if passable(pd, plon, plat):
				lon = plon
				lat = plat
				break
		var r := spawn(pd, lon, lat)
		AudioManager.play("cash")
		NewsFeed.post("%s rolled out of the Rover Bay on %s." % [r.name, pd.planet_name])


# ── Routing ──────────────────────────────────────────────────────────────────

## Route from `a` to `b` (unit vectors): { points: [Vector3] without `a`,
## ending at `b`; road: [bool] per point = the leg to it runs on a road }.
## points is empty when no land route exists.
func find_route(pd: PlanetData, a: Vector3, b: Vector3) -> Dictionary:
	var pts_out: Array[Vector3] = []
	var road_out: Array[bool] = []
	var out := {"points": pts_out, "road": road_out}
	var has_roads := not (_roads.get(pd.seed, []) as Array).is_empty()
	if not has_roads and _arc_clear(pd, a, b):
		pts_out.append(b)
		road_out.append(false)
		return out
	var nav := _nav_for(pd)
	var astar: AStar3D = nav["astar"]
	var road_ids: Dictionary = nav["road"]
	var ia := _nearest_open(nav, a)
	var ib := _nearest_open(nav, b)
	if ia < 0 or ib < 0:
		return out
	var ids := astar.get_id_path(ia, ib)
	if ids.is_empty():
		if _arc_clear(pd, a, b):
			pts_out.append(b)
			road_out.append(false)
		return out
	var pts: Array[Vector3] = [a]
	var on_road: Array[bool] = [false]
	for id: int in ids:
		pts.append(astar.get_point_position(id))
		on_road.append(road_ids.has(id))
	pts.append(b)
	on_road.append(false)
	# road legs (two road points in a row) are kept as they are; everything else
	# is string-pulled: jump to the farthest point still reachable in a straight
	# arc, without skipping past the next road point
	var i := 0
	var n := pts.size()
	while i < n - 1:
		if on_road[i] and on_road[i + 1]:
			pts_out.append(pts[i + 1])
			road_out.append(true)
			i += 1
			continue
		var lim := n - 1
		for k in range(i + 1, n):
			if on_road[k]:
				lim = k
				break
		var j := lim
		while j > i + 1 and not _arc_clear(pd, pts[i], pts[j]):
			j -= 1
		pts_out.append(pts[j])
		road_out.append(false)
		i = j
	# a road detour that is slower than driving straight is dropped
	if _arc_clear(pd, a, b):
		var t_route := 0.0
		var prev := a
		for k in pts_out.size():
			t_route += prev.angle_to(pts_out[k]) / (ROAD_SPEED_MULT if road_out[k] else 1.0)
			prev = pts_out[k]
		if a.angle_to(b) <= t_route:
			pts_out.clear()
			road_out.clear()
			pts_out.append(b)
			road_out.append(false)
	return out


## Whether the great-circle arc a→b stays on passable ground.
func _arc_clear(pd: PlanetData, a: Vector3, b: Vector3) -> bool:
	var ang := a.angle_to(b)
	var n := maxi(2, int(ceil(ang / deg_to_rad(0.75))))
	for k in n + 1:
		var p := a.slerp(b, float(k) / float(n)).normalized()
		if not passable(pd, atan2(p.x, p.z), asin(clampf(p.y, -1.0, 1.0))):
			return false
	return true


func _cell_dir(x: int, y: int) -> Vector3:
	var lon := (float(x) + 0.5) / NAV_W * TAU - PI
	var lat := (float(y) + 0.5) / NAV_H * PI - PI * 0.5
	return dir_of(lon, lat)


func _nav_for(pd: PlanetData) -> Dictionary:
	if _nav.has(pd.seed):
		return _nav[pd.seed]
	var astar := AStar3D.new()
	var open := PackedByteArray()
	open.resize(NAV_W * NAV_H)
	for y in NAV_H:
		for x in NAV_W:
			var d := _cell_dir(x, y)
			var ok := passable(pd, atan2(d.x, d.z), asin(d.y))
			open[y * NAV_W + x] = 1 if ok else 0
			if ok:
				astar.add_point(y * NAV_W + x, d)
	for y in NAV_H:
		for x in NAV_W:
			var id := y * NAV_W + x
			if open[id] == 0:
				continue
			for dy in [0, 1]:
				for dx in [-1, 0, 1]:
					if dy == 0 and dx != 1:
						continue
					var ny: int = y + dy
					if ny >= NAV_H:
						continue
					var nx: int = posmod(x + dx, NAV_W)
					var nid := ny * NAV_W + nx
					if open[nid] == 1:
						astar.connect_points(id, nid)
	# City roads: their points join the graph as cheap nodes, linked along each
	# road and to the open grid cells around them
	var road_ids := {}
	var next_id := NAV_W * NAV_H
	for line: PackedVector3Array in _roads.get(pd.seed, []):
		var prev_id := -1
		for v: Vector3 in line:
			var rid := next_id
			next_id += 1
			astar.add_point(rid, v, 1.0 / ROAD_SPEED_MULT)
			road_ids[rid] = true
			if prev_id >= 0:
				astar.connect_points(prev_id, rid)
			prev_id = rid
			var lon := atan2(v.x, v.z)
			var lat := asin(clampf(v.y, -1.0, 1.0))
			var cx := int(floor((lon + PI) / TAU * NAV_W))
			var cy := int(floor((lat + PI * 0.5) / PI * NAV_H))
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var gy := cy + dy
					if gy < 0 or gy >= NAV_H:
						continue
					var gid := gy * NAV_W + posmod(cx + dx, NAV_W)
					if open[gid] == 1:
						astar.connect_points(rid, gid)
	var nav := {"astar": astar, "open": open, "road": road_ids}
	_nav[pd.seed] = nav
	return nav


func _nearest_open(nav: Dictionary, p: Vector3) -> int:
	var astar: AStar3D = nav["astar"]
	if astar.get_point_count() == 0:
		return -1
	return astar.get_closest_point(p)


## Drop the cached route grid of a world (its map was rebuilt).
func forget_nav(planet_seed: int) -> void:
	_nav.erase(planet_seed)


## The world's routed roads (POILayer.roads format: [{ segments: [{ sea, points:
## PackedVector2Array (lon, lat) }] }]). Land segments become rover roads.
func set_roads(planet_seed: int, roads: Array) -> void:
	var lines: Array = []
	var sig := 0
	for rd: Dictionary in roads:
		for seg: Dictionary in rd.get("segments", []):
			if bool(seg.get("sea", false)):
				continue
			var pts: PackedVector2Array = seg.get("points", PackedVector2Array())
			if pts.size() < 2:
				continue
			var line := PackedVector3Array()
			for ll: Vector2 in pts:
				line.append(dir_of(ll.x, ll.y))
			lines.append(line)
			sig = hash([sig, pts.size(), pts[0], pts[pts.size() - 1]])
	if int(_road_sig.get(planet_seed, -1)) == sig and _roads.has(planet_seed):
		return
	_road_sig[planet_seed] = sig
	_roads[planet_seed] = lines
	_nav.erase(planet_seed)   # rebuilt with the roads on the next order


## Whether a point lies on (within ~0.6° of) one of the world's roads.
func near_road(planet_seed: int, v: Vector3) -> bool:
	for line: PackedVector3Array in _roads.get(planet_seed, []):
		for p: Vector3 in line:
			if p.angle_to(v) < 0.01:
				return true
	return false


# ── Survey ───────────────────────────────────────────────────────────────────

func _survey(r: RoverData) -> void:
	var grid: PackedByteArray = _explored.get(r.planet_seed, PackedByteArray())
	if grid.is_empty():
		grid.resize(EXP_W * EXP_H)
	var rad := SCAN_RADIUS_KM / _radius_km(r.planet_seed)
	var lat0 := r.lat()
	var changed := false
	var y_lo := clampi(int(floor((lat0 - rad + PI * 0.5) / PI * EXP_H)), 0, EXP_H - 1)
	var y_hi := clampi(int(floor((lat0 + rad + PI * 0.5) / PI * EXP_H)), 0, EXP_H - 1)
	for y in range(y_lo, y_hi + 1):
		var clat := (float(y) + 0.5) / EXP_H * PI - PI * 0.5
		for x in EXP_W:
			var idx := y * EXP_W + x
			if grid[idx] == 1:
				continue
			var clon := (float(x) + 0.5) / EXP_W * TAU - PI
			if r.pos.angle_to(dir_of(clon, clat)) <= rad:
				grid[idx] = 1
				changed = true
	_explored[r.planet_seed] = grid
	if changed:
		area_explored.emit(r.planet_seed)


## Share of the world surveyed by rovers, 0..1 (area-weighted).
func explored_fraction(planet_seed: int) -> float:
	var grid: PackedByteArray = _explored.get(planet_seed, PackedByteArray())
	if grid.is_empty():
		return 0.0
	var tot := 0.0
	var got := 0.0
	for y in EXP_H:
		var w := cos((float(y) + 0.5) / EXP_H * PI - PI * 0.5)
		for x in EXP_W:
			tot += w
			if grid[y * EXP_W + x] == 1:
				got += w
	return got / maxf(tot, 1e-6)


func is_explored(planet_seed: int, lon: float, lat: float) -> bool:
	var grid: PackedByteArray = _explored.get(planet_seed, PackedByteArray())
	if grid.is_empty():
		return false
	var x := clampi(int(floor((fposmod(lon + PI, TAU)) / TAU * EXP_W)), 0, EXP_W - 1)
	var y := clampi(int(floor((lat + PI * 0.5) / PI * EXP_H)), 0, EXP_H - 1)
	return grid[y * EXP_W + x] == 1


# ── Save ─────────────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	var rs: Array = []
	for r: RoverData in _rovers.values():
		rs.append(r.to_dict())
	var ex := {}
	for s: int in _explored.keys():
		ex[str(s)] = Marshalls.raw_to_base64(_explored[s])
	var bs := {}
	for sd: int in _builds.keys():
		bs[str(sd)] = _builds[sd]
	return {"next_id": _next_id, "rovers": rs, "explored": ex, "builds": bs}


func deserialize(data: Dictionary) -> void:
	_rovers.clear()
	_explored.clear()
	_nav.clear()
	_builds.clear()
	var bs: Dictionary = data.get("builds", {})
	for k: String in bs.keys():
		_builds[int(k)] = bs[k]
	_next_id = int(data.get("next_id", 1))
	for d: Dictionary in data.get("rovers", []):
		var r := RoverData.new()
		r.id = String(d.get("id", "rv%d" % _next_id))
		r.name = String(d.get("name", r.id))
		r.planet_seed = int(d.get("seed", 0))
		var p: Array = d.get("pos", [0, 0, 1])
		r.pos = Vector3(float(p[0]), float(p[1]), float(p[2])).normalized()
		r.km_driven = float(d.get("km", 0.0))
		r.path = RoverData.vecs_in(d.get("path", []))
		r.goals = RoverData.vecs_in(d.get("goals", []))
		r.state = int(d.get("state", 0))
		r.action = d.get("action", {})
		r.repeat = bool(d.get("repeat", false))
		for f in d.get("road", []):
			r.path_road.append(bool(f))
		while r.path_road.size() < r.path.size():
			r.path_road.append(false)
		_rovers[r.id] = r
	var ex: Dictionary = data.get("explored", {})
	for k: String in ex.keys():
		var raw := Marshalls.base64_to_raw(String(ex[k]))
		if raw.size() == EXP_W * EXP_H:
			_explored[int(k)] = raw
