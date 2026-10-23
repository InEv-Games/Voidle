## ShipManager — autoload singleton.
## Tracks all ships across all planets, ticks orbital motion and travel.
extends Node

signal ship_changed(ship: ShipData)   # orbit angle updated or state changed
signal ship_arrived(ship: ShipData)   # reached destination
signal ship_added(ship: ShipData)     # new ship placed in orbit

## { planet_seed -> Array[ShipData] }
var _ships: Dictionary = {}

const ORBIT_SPEED: float = 0.12   # radians per second

func _process(delta: float) -> void:
	var arrived: Array[ShipData] = []   # moved after the loop (lists change)
	for seed_val: int in _ships:
		for ship: ShipData in _ships[seed_val]:
			if ship.is_travelling():
				ship.travel_progress += delta / ship.travel_duration
				if ship.travel_progress >= 1.0:
					ship.travel_progress = 1.0
					arrived.append(ship)
			else:
				ship.orbit_angle = fmod(ship.orbit_angle + ship.orbit_speed * delta, TAU)
			ship_changed.emit(ship)
	for ship: ShipData in arrived:
		_on_arrived(ship)
	_tick_traffic(delta)

## Any ship flying to `dest_seed` (optionally of one type), or null.
func travelling_to(dest_seed: int, ship_type: String = "") -> ShipData:
	for seed_val: int in _ships:
		for ship: ShipData in _ships[seed_val]:
			if ship.is_travelling() and ship.dest_seed == dest_seed \
					and (ship_type == "" or ship.ship_type == ship_type):
				return ship
	return null

func _on_arrived(ship: ShipData) -> void:
	# a transfer route ends on a point of the destination orbit — carry on
	# orbiting from exactly there
	if not is_nan(ship.transfer_arrive_angle):
		ship.orbit_angle = ship.transfer_arrive_angle
	ship.transfer_depart_angle = NAN
	ship.transfer_arrive_angle = NAN
	var old_seed := ship.orbit_seed
	if ship.ship_type == FREIGHTER:   # captured into the destination orbit
		ship.traffic_state = "captured"
		ship.traffic_partner = old_seed
		ship.state_t = 0.0
		ship.state_len = randf_range(0.3, 0.8) * TAU / maxf(absf(ship.orbit_speed), 0.05)
	ship.orbit_seed      = ship.dest_seed
	ship.dest_seed       = -1
	ship.travel_progress = 0.0
	ship.travel_duration = 0.0
	# Move ship to new planet's list
	remove_ship(old_seed, ship.ship_id)
	add_ship(ship)
	if ship.ship_type == FREIGHTER:
		_dock_at_hub(ship)
	ship_arrived.emit(ship)

# ── Public API ────────────────────────────────────────────────────────────────

func ships_for(planet_seed: int) -> Array[ShipData]:
	if not _ships.has(planet_seed):
		return []
	var result: Array[ShipData] = []
	result.assign(_ships[planet_seed])
	return result

func add_ship(ship: ShipData) -> void:
	if not _ships.has(ship.orbit_seed):
		_ships[ship.orbit_seed] = []
	(_ships[ship.orbit_seed] as Array).append(ship)
	ship_changed.emit(ship)
	ship_added.emit(ship)

func remove_ship(planet_seed: int, ship_id: String) -> void:
	if not _ships.has(planet_seed):
		return
	var arr: Array = _ships[planet_seed]
	for i in arr.size():
		if (arr[i] as ShipData).ship_id == ship_id:
			arr.remove_at(i)
			return

## Launch a new ship from a spaceport planet. Returns the new ShipData.
func launch(planet_seed: int, name: String, cargo: Dictionary = {}) -> ShipData:
	var angle := randf() * TAU
	var ship   := ShipData.make(name, planet_seed, angle)
	ship.cargo  = cargo
	add_ship(ship)
	return ship

## Send an orbiting ship to a destination planet.
func dispatch(ship: ShipData, dest_seed: int, duration_sec: float) -> void:
	ship.dest_seed       = dest_seed
	ship.travel_duration = duration_sec
	ship.travel_progress = 0.0
	ship_changed.emit(ship)

## Save / load
func serialize() -> Array:
	var out: Array = []
	for seed_val: int in _ships:
		for ship: ShipData in _ships[seed_val]:
			out.append({
				"ship_id":           ship.ship_id,
				"ship_name":         ship.ship_name,
				"ship_type":         ship.ship_type,
				"orbit_seed":        ship.orbit_seed,
				"orbit_angle":       ship.orbit_angle,
				"orbit_radius":      ship.orbit_radius,
				"orbit_speed":       ship.orbit_speed,
				"orbit_inclination": ship.orbit_inclination,
				"orbit_node":        ship.orbit_node,
				"cargo":             ship.cargo,
				"dest_seed":         ship.dest_seed,
				"travel_progress":   ship.travel_progress,
				"travel_duration":   ship.travel_duration,
				"transfer_depart_angle": ship.transfer_depart_angle,
				"transfer_arrive_angle": ship.transfer_arrive_angle,
				"traffic_state":     ship.traffic_state,
				"traffic_partner":   ship.traffic_partner,
				"traffic_pair":      ship.traffic_pair,
				"state_t":           ship.state_t,
				"state_len":         ship.state_len,
				"park_radius":       ship.park_radius,
			})
	return out

func deserialize(arr: Array) -> void:
	_ships.clear()
	for d: Dictionary in arr:
		var s               := ShipData.new()
		s.ship_id           = d.get("ship_id",        "")
		s.ship_name         = d.get("ship_name",      "Shuttle")
		s.ship_type         = d.get("ship_type",      "shuttle")
		s.orbit_seed        = d.get("orbit_seed",     -1)
		s.orbit_angle       = d.get("orbit_angle",       0.0)
		s.orbit_radius      = d.get("orbit_radius",      1.06)
		s.orbit_speed       = d.get("orbit_speed",       1.0)
		s.orbit_inclination = d.get("orbit_inclination", 0.0)
		s.orbit_node        = d.get("orbit_node",        0.0)
		s.cargo             = d.get("cargo",             {})
		s.dest_seed         = d.get("dest_seed",      -1)
		s.travel_progress   = d.get("travel_progress",0.0)
		s.travel_duration   = d.get("travel_duration",0.0)
		s.transfer_depart_angle = d.get("transfer_depart_angle", NAN)
		s.transfer_arrive_angle = d.get("transfer_arrive_angle", NAN)
		s.traffic_state     = String(d.get("traffic_state", ""))
		s.traffic_partner   = int(d.get("traffic_partner", -1))
		s.traffic_pair      = String(d.get("traffic_pair", ""))
		s.state_t           = float(d.get("state_t", 0.0))
		s.state_len         = float(d.get("state_len", 0.0))
		s.park_radius       = float(d.get("park_radius", 1.2))
		if s.orbit_seed >= 0:
			add_ship(s)

# ── Spaceport traffic ─────────────────────────────────────────────────────────
# Every pair of worlds with a finished Spaceport (or Lunar Spaceport) gets a
# fleet of freighters shuttling between them: real ships, saved with the game,
# but purely visual — they carry nothing and pay nothing. The fleet grows with
# the Cities on both ends: a picture of how developed the settlements are,
# never a source of income. Each freighter lifts off from its Spaceport,
# circles in free orbit, transfers to the other world, is captured into its
# orbit, lands there, waits, and goes back.

const FREIGHTER := "freighter"
const TRAFFIC_TICK := 2.0
const FLEET_MIN := 1
const FLEET_MAX := 14
const ASCENT_SEC := 7.0
const DESCENT_SEC := 6.0
const TRANSFER_SEC := 24.0
const FREIGHTER_SPEED := 0.22   # rad/s in orbit
var _traffic_t := 0.0

func _tick_traffic(delta: float) -> void:
	for seed_val: int in _ships.keys():
		for ship: ShipData in (_ships[seed_val] as Array).duplicate():
			if ship.ship_type == FREIGHTER:
				_advance_freighter(ship, delta)
	_traffic_t += delta
	if _traffic_t >= TRAFFIC_TICK:
		_traffic_t = 0.0
		_balance_fleets()

## Worlds with a finished Spaceport or Lunar Spaceport.
func _port_worlds() -> Array[int]:
	var out: Array[int] = []
	for pp: PlanetProgress in GameState._planet_progress.values():
		if pp.is_colonized and (GameState.has_finished_building(pp.planet_seed, "spaceport")
				or GameState.has_finished_building(pp.planet_seed, "lunar_spaceport")):
			out.append(pp.planet_seed)
	return out

static func _pair_key(a: int, b: int) -> String:
	return "%d:%d" % [mini(a, b), maxi(a, b)]

## How many freighters a route carries: starts with one and grows with the
## size of the Orbits (level) and of the Capitals (highest City level) on both ends.
func fleet_size(a: int, b: int) -> int:
	var size := _world_size(a) + _world_size(b)   # 4 for two fresh worlds
	return clampi(FLEET_MIN + floori(float(size - 4) / 2.0), FLEET_MIN, FLEET_MAX)

func _world_size(seed_val: int) -> int:
	var pd := GameState.get_planet_data(seed_val)
	var pp := GameState.get_planet(seed_val)
	if pd == null or pp == null:
		return 0
	var cap := 1
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital() and not p.constructing:
			cap = maxi(cap, Leveling.city_level(pp, p))
	return maxi(pp.orbit_level, 1) + cap

func _city_levels(seed_val: int) -> int:
	var pd := GameState.get_planet_data(seed_val)
	var pp := GameState.get_planet(seed_val)
	if pd == null or pp == null:
		return 0
	var n := 0
	for p: POIData in pd.custom_pois:
		if p.is_city() and not p.is_orbital() and not p.constructing:
			n += Leveling.city_level(pp, p)
	return n

func _freighters() -> Array[ShipData]:
	var out: Array[ShipData] = []
	for seed_val: int in _ships:
		for ship: ShipData in _ships[seed_val]:
			if ship.ship_type == FREIGHTER:
				out.append(ship)
	return out

## Adds freighters to routes that need more, retires extras (and those of
## routes that closed) once they're on a pad.
func _balance_fleets() -> void:
	var worlds := _port_worlds()
	var want := {}   # pair key -> [a, b, count]
	for i in worlds.size():
		for j in range(i + 1, worlds.size()):
			want[_pair_key(worlds[i], worlds[j])] = [worlds[i], worlds[j], fleet_size(worlds[i], worlds[j])]
	var have := {}
	for ship: ShipData in _freighters():
		have[ship.traffic_pair] = int(have.get(ship.traffic_pair, 0)) + 1
	for ship: ShipData in _freighters():
		var limit: int = int(want[ship.traffic_pair][2]) if want.has(ship.traffic_pair) else 0
		if int(have.get(ship.traffic_pair, 0)) > limit and ship.traffic_state == "pad":
			remove_ship(ship.orbit_seed, ship.ship_id)
			have[ship.traffic_pair] = int(have[ship.traffic_pair]) - 1
	for key: String in want:
		var w: Array = want[key]
		var n := int(have.get(key, 0))
		if n < int(w[2]):
			var side := n % 2   # alternate which end it starts from
			_spawn_freighter(int(w[side]), int(w[1 - side]), key)

func _spawn_freighter(at_seed: int, partner: int, key: String) -> void:
	var ship := ShipData.make("Freighter %s-%d" % [char(65 + randi() % 26), randi_range(10, 99)], at_seed, 0.0)
	ship.ship_id += "_%d" % randi()   # several can start in one millisecond
	ship.ship_type = FREIGHTER
	ship.traffic_state = "pad"
	ship.traffic_partner = partner
	ship.traffic_pair = key
	ship.state_t = 0.0
	ship.state_len = randf_range(1.0, 12.0)   # staggered first lift-offs
	ship.park_radius = randf_range(1.12, 1.32)
	ship.orbit_radius = 1.0
	add_ship(ship)

## A world's finished Central Orbit, or null.
func _hub_of(seed_val: int) -> POIData:
	var hub := Leveling.orbit_hub(GameState.get_planet_data(seed_val))
	return hub if hub != null and not hub.constructing else null

## True when the ship is passing its world's Central Orbit (or there is none).
func _at_hub(ship: ShipData) -> bool:
	var hub := _hub_of(ship.orbit_seed)
	if hub == null:
		return true
	var hp := ShipData.orbit_point(1.0, hub.orbit_inclination, hub.orbit_node, hub.orbit_angle)
	var sp := ShipData.orbit_point(1.0, ship.orbit_inclination, ship.orbit_node, ship.orbit_angle)
	return hp.dot(sp) > cos(0.12)

## Puts an arriving freighter on the destination's Central Orbit, heading off
## a random way round — it carries on from the hub.
func _dock_at_hub(ship: ShipData) -> void:
	var hub := _hub_of(ship.orbit_seed)
	if hub == null:
		return
	var hp := ShipData.orbit_point(1.0, hub.orbit_inclination, hub.orbit_node, hub.orbit_angle).normalized()
	var side := hp.cross(Vector3.UP)
	if side.length() < 1e-4:
		side = Vector3.RIGHT
	side = side.normalized()
	var up := side.cross(hp).normalized()
	var h := randf() * TAU
	ship.fit_orbit(hp, side * cos(h) + up * sin(h))
	ship.orbit_radius = hub.orbit_radius
	ship.park_radius = hub.orbit_radius

## The pad of a world: its Spaceport's district (lon, lat in radians), or INF.
func _pad_of(seed_val: int) -> Vector2:
	var pd := GameState.get_planet_data(seed_val)
	var pp := GameState.get_planet(seed_val)
	if pd == null or pp == null:
		return Vector2.INF
	for p: POIData in pd.custom_pois:
		if p.is_orbital() or p.constructing:
			continue
		for b: Dictionary in pp.buildings_in_district(p.label):
			var bid := String(b.get("building_id", ""))
			if (bid == "spaceport" or bid == "lunar_spaceport") and not b.get("constructing", false):
				return Vector2(deg_to_rad(p.lon_deg), deg_to_rad(p.lat_deg))
	return Vector2.INF

func _advance_freighter(ship: ShipData, delta: float) -> void:
	if ship.is_travelling():
		return   # "transfer": the journey itself moves it
	ship.state_t += delta
	var k := clampf(ship.state_t / maxf(ship.state_len, 0.01), 0.0, 1.0)
	match ship.traffic_state:
		"pad":
			if ship.state_t < ship.state_len:
				return
			var pad := _pad_of(ship.orbit_seed)
			if not pad.is_finite():
				remove_ship(ship.orbit_seed, ship.ship_id)   # its port is gone
				return
			# lift off over the pad, heading a random way round the world
			var p := ShipData.frame_dir(pad.x, pad.y)
			var east := p.cross(Vector3(0, -1, 0))
			if east.length() < 1e-4:
				east = Vector3.RIGHT
			east = east.normalized()
			var north := east.cross(p).normalized()
			var h := randf() * TAU
			var heading := east * cos(h) + north * sin(h)
			# along the network: head for the world's Central Orbit when it has one
			var hub := _hub_of(ship.orbit_seed)
			if hub != null:
				var hp := ShipData.orbit_point(1.0, hub.orbit_inclination, hub.orbit_node, hub.orbit_angle)
				if (hp - p).length() > 0.05:
					heading = hp - p
				ship.park_radius = hub.orbit_radius   # climbs to the hub's height
			ship.orbit_speed = 0.05
			ship.fit_orbit(p, heading)
			ship.orbit_radius = 1.0
			ship.traffic_state = "ascend"
			ship.state_t = 0.0
			ship.state_len = ASCENT_SEC
		"ascend":
			var e := smoothstep(0.0, 1.0, k)
			ship.orbit_radius = lerpf(1.0, ship.park_radius, e)
			ship.orbit_speed = lerpf(0.05, FREIGHTER_SPEED, e)
			if k >= 1.0:
				ship.traffic_state = "orbit"
				ship.state_t = 0.0
				ship.state_len = randf_range(0.5, 1.3) * TAU / FREIGHTER_SPEED
		"orbit":   # leaves from the Central Orbit, the next time it passes it
			# (an old save's ring may never pass the hub: go after one extra lap)
			var overdue := ship.state_t > ship.state_len + TAU / maxf(absf(ship.orbit_speed), 0.05)
			if k >= 1.0 and ship.traffic_partner >= 0 and (_at_hub(ship) or overdue):
				ship.traffic_state = "transfer"
				dispatch(ship, ship.traffic_partner, TRANSFER_SEC)
		"captured":
			if k >= 1.0:
				ship.traffic_state = "descend"
				ship.state_t = 0.0
				ship.state_len = DESCENT_SEC
		"descend":
			var d := smoothstep(0.0, 1.0, k)
			ship.orbit_radius = lerpf(ship.park_radius, 1.0, d)
			ship.orbit_speed = lerpf(FREIGHTER_SPEED, 0.05, d)
			if k >= 1.0:
				ship.traffic_state = "pad"
				ship.state_t = 0.0
				ship.state_len = randf_range(6.0, 16.0)
				ship.orbit_radius = 1.0
