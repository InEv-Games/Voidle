class_name RoadNetwork
extends RefCounted

## Route finding between districts over the planet surface.
##
## The globe is a lon/lat grid; each cell is a land or a sea node in an AStar3D
## graph (positions on the unit sphere, so costs are surface distances and the
## heuristic works across the date line). Land only links to land and sea to
## sea — the only way between them is a *port* node lifted off the surface by
## PORT_LIFT, which makes every land↔sea switch expensive. So routes follow
## the land and curve around water, take to the sea only where it saves enough
## to pay for a port at each end, and stay at sea until the port nearest the
## destination. Sea cells are cheaper than land (ships are fast), so two coastal
## districts far apart along a coast prefer the sea lane.
##
## Land roads only run over green land (h ≥ GREEN_H). The sand band and water
## are impassable on land, except for short *bridges*: two green cells up to
## BRIDGE_MAX_CELLS apart across non-green ground are linked directly.
##
## The graph is built on a worker thread (start(), then poll is_ready()).

const WIDTH:     int   = 640    # ~0.56° cells — fine enough for thin land bridges
const HEIGHT:    int   = 320
const LAT_LIMIT: float = 1.40     # rad — no roads over the poles
const PORT_LIFT: float = 0.08     # cost of entering a port, in radians of surface
const BRIDGE_MAX_CELLS: int = 4   # widest gap a land road may bridge (~2 planet pixels at 1x)
const PORT_REACH_CELLS: int = 2   # a port may reach the sea across this much sand
const COST_SEA:      float = 0.55
const COST_DEEP_SEA: float = 0.50
const COST_LAND:     float = 1.0
const COST_HIGHLAND: float = 1.6
const COST_MOUNTAIN: float = 3.0

var planet_seed: int
var _astar := AStar3D.new()
var _kind := PackedByteArray()      # per cell: 0 = land, 1 = sea, 2 = shore (sand), 255 = outside graph
var _task_id: int = -1
var _ready := false

# inputs captured on the main thread
var _sea_level: float
var _rocky: bool

static var _nets: Dictionary = {}   # seed -> RoadNetwork

## Returns the network for this planet, starting its build if needed.
static func for_planet(data: PlanetData) -> RoadNetwork:
	if _nets.has(data.seed):
		return _nets[data.seed]
	var net := RoadNetwork.new()
	net.planet_seed = data.seed
	net._sea_level = data.sea_level
	net._rocky = TerrainMap.has_map(data.seed, TerrainMap.Mode.ROCKY)
	_nets[data.seed] = net
	net._task_id = WorkerThreadPool.add_task(net._build, false, "RoadNetwork %d" % data.seed)
	return net

## Forget a planet's network (e.g. its terrain map was rebuilt).
static func forget(planet_seed: int) -> void:
	_nets.erase(planet_seed)

func is_ready() -> bool:
	if not _ready and _task_id >= 0 and WorkerThreadPool.is_task_completed(_task_id):
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1
		_ready = true
	return _ready

static func _cell_lonlat(x: int, y: int) -> Vector2:
	return Vector2((float(x) + 0.5) / WIDTH * TAU, (0.5 - (float(y) + 0.5) / HEIGHT) * PI)

static func _to_vec(lon: float, lat: float) -> Vector3:
	return Vector3(sin(lon) * cos(lat), sin(lat), cos(lon) * cos(lat))

static func _to_lonlat(v: Vector3) -> Vector2:
	var n := v.normalized()
	return Vector2(fposmod(atan2(n.x, n.z), TAU), asin(clampf(n.y, -1.0, 1.0)))

func _build() -> void:
	var n := WIDTH * HEIGHT
	_kind.resize(n)
	_kind.fill(255)
	_astar.reserve_space(n + n / 4)
	# nodes
	for y in HEIGHT:
		for x in WIDTH:
			var ll := _cell_lonlat(x, y)
			if absf(ll.y) > LAT_LIMIT:
				continue
			var i := y * WIDTH + x
			var h := 0.2
			if _rocky:
				h = TerrainMap.value(planet_seed, ll.x, ll.y) - _sea_level
			var cost: float
			if h < TerrainSampler.SHORE_H:
				_kind[i] = 1
				cost = COST_DEEP_SEA if h < -0.12 else COST_SEA
			elif h < TerrainSampler.GREEN_H:
				_kind[i] = 2          # sand: neither road nor sea lane
				continue
			else:
				_kind[i] = 0
				cost = COST_MOUNTAIN if h >= 0.38 else (COST_HIGHLAND if h >= 0.26 else COST_LAND)
			_astar.add_point(i, _to_vec(ll.x, ll.y), cost)
	# edges: same-kind neighbours (E, S, SE, SW), wrapping in longitude
	for y in HEIGHT:
		for x in WIDTH:
			var i := y * WIDTH + x
			if _kind[i] != 0 and _kind[i] != 1:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 1)]:
				var ny := y + d.y
				if ny >= HEIGHT:
					continue
				var j := ny * WIDTH + posmod(x + d.x, WIDTH)
				if _kind[i] == _kind[j]:
					_astar.connect_points(i, j)
				elif _kind[i] == 0:
					_try_bridge(x, y, d)
	# ports: a land cell with the sea next to it (or just past a strip of sand)
	# gets a lifted port node linking both
	for y in HEIGHT:
		for x in WIDTH:
			var i := y * WIDTH + x
			if _kind[i] != 0:
				continue
			var port := -1
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var j := -1
				for step in range(1, PORT_REACH_CELLS + 1):
					var ny := y + d.y * step
					if ny < 0 or ny >= HEIGHT:
						break
					var c := ny * WIDTH + posmod(x + d.x * step, WIDTH)
					if _kind[c] == 1:
						j = c
						break
					if _kind[c] != 2:
						break      # land or off-graph: no sea this way
				if j < 0:
					continue
				if port < 0:
					port = n + i
					_astar.add_point(port, _astar.get_point_position(i) * (1.0 + PORT_LIFT), 1.0)
					_astar.connect_points(i, port)
				_astar.connect_points(port, j)

## Links green cell (x, y) to the next green cell along `d` if only non-green
## ground (sand / water) lies between them and the gap is short — a bridge.
func _try_bridge(x: int, y: int, d: Vector2i) -> void:
	for step in range(2, BRIDGE_MAX_CELLS + 2):
		var ny := y + d.y * step
		if ny < 0 or ny >= HEIGHT:
			return
		var j := ny * WIDTH + posmod(x + d.x * step, WIDTH)
		if _kind[j] == 0:
			_astar.connect_points(y * WIDTH + x, j)
			return
		if _kind[j] == 255:
			return

## Route between two surface points (radians). Returns
## { segments: [{ sea: bool, points: PackedVector2Array (lon, lat) }],
##   ports: PackedVector2Array } — empty when no route exists.
## `sea_a` / `sea_b`: the endpoint district sits on water (joins via a sea node).
func route(lon_a: float, lat_a: float, lon_b: float, lat_b: float,
		sea_a: bool = false, sea_b: bool = false) -> Dictionary:
	if not is_ready():
		return {}
	var a := _endpoint(lon_a, lat_a, sea_a)
	var b := _endpoint(lon_b, lat_b, sea_b)
	if a < 0 or b < 0 or a == b:
		return {}
	var ids := _astar.get_id_path(a, b)
	if ids.is_empty():
		return {}
	var n := WIDTH * HEIGHT
	var segments: Array = []
	var ports := PackedVector2Array()
	var cur := PackedVector3Array()
	var cur_sea := false
	for id: int in ids:
		if id >= n:
			# port: close the current segment here and start the next one
			var p := _astar.get_point_position(id).normalized()
			ports.append(_to_lonlat(p))
			cur.append(p)
			if cur.size() >= 2:
				segments.append({"sea": cur_sea, "pts": cur})
			cur = PackedVector3Array([p])
			continue
		var sea := _kind[id] == 1
		if cur.size() > 1 and sea != cur_sea:
			segments.append({"sea": cur_sea, "pts": cur})
			cur = PackedVector3Array([cur[cur.size() - 1]])
		cur_sea = sea
		cur.append(_astar.get_point_position(id))
	if cur.size() >= 2:
		segments.append({"sea": cur_sea, "pts": cur})
	# start / end exactly at the districts
	if not segments.is_empty():
		(segments[0]["pts"] as PackedVector3Array)[0] = _to_vec(lon_a, lat_a)
		var last: PackedVector3Array = segments[segments.size() - 1]["pts"]
		last[last.size() - 1] = _to_vec(lon_b, lat_b)
	var out: Array = []
	for seg: Dictionary in segments:
		var smooth := _chaikin(seg["pts"], 2)
		var pts := PackedVector2Array()
		for v: Vector3 in smooth:
			pts.append(_to_lonlat(v))
		out.append({"sea": seg["sea"], "points": pts})
	return {"segments": out, "ports": ports}

## Nearest grid cell of the wanted kind (land or sea) around a point, searching
## outward in rings. -1 if none close by.
func _endpoint(lon: float, lat: float, sea: bool) -> int:
	var x := posmod(floori(fposmod(lon, TAU) / TAU * WIDTH), WIDTH)
	var y := clampi(floori((0.5 - lat / PI) * HEIGHT), 0, HEIGHT - 1)
	var want := 1 if sea else 0
	for r in 8:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var ny := y + dy
				if ny < 0 or ny >= HEIGHT:
					continue
				var j := ny * WIDTH + posmod(x + dx, WIDTH)
				if _kind[j] == want:
					return j
	return -1

## Corner-cutting smoothing on the sphere; keeps both endpoints.
static func _chaikin(pts: PackedVector3Array, iterations: int) -> PackedVector3Array:
	var cur := pts
	for _it in iterations:
		if cur.size() < 3:
			return cur
		var nxt := PackedVector3Array([cur[0]])
		for k in cur.size() - 1:
			var p := cur[k]
			var q := cur[k + 1]
			nxt.append((p * 0.75 + q * 0.25).normalized())
			nxt.append((p * 0.25 + q * 0.75).normalized())
		nxt.append(cur[cur.size() - 1])
		cur = nxt
	return cur
