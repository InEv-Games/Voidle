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
				if ship.pending_dest >= 0:
					_try_window(ship, delta)
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
	var old_seed := ship.orbit_seed
	# it ends on the orbit its approach came in on (OrbitLayout.arrival: the
	# near point of its incoming hyperbola, or the capture of a transfer inside
	# one planet system) — same place, same heading as the views drew it
	# (the lander keeps its own flow: the planet view's planned angle)
	var arr := OrbitLayout.arrival(ship)
	if not arr.is_empty():
		ship.orbit_inclination = float(arr["inc"])
		ship.orbit_node = float(arr["node"])
		ship.orbit_angle = float(arr["angle"])
		ship.orbit_speed = absf(ship.orbit_speed) * float(arr["spin"])
		ship.orbit_radius = float(arr["radius"])
	elif not is_nan(ship.transfer_arrive_angle):
		ship.orbit_angle = ship.transfer_arrive_angle
	ship.transfer_depart_angle = NAN
	ship.transfer_arrive_angle = NAN
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
	if ship.ship_type == PIONEER:
		_pioneer_arrived(ship, old_seed)
	elif ship.ship_type == HAULER:
		ship.traffic_partner = old_seed   # next run goes back
		ship.traffic_state = "orbit"
		ship.state_t = 0.0
		ship.state_len = randf_range(HAULER_WAIT_MIN, HAULER_WAIT_MAX)
	ship_arrived.emit(ship)

# ── Public API ────────────────────────────────────────────────────────────────

func ships_for(planet_seed: int) -> Array[ShipData]:
	if not _ships.has(planet_seed):
		return []
	var result: Array[ShipData] = []
	result.assign(_ships[planet_seed])
	return result

## Flying ships headed for `dest_seed` (read only; one index a frame).
func inbound(dest_seed: int) -> Array:
	var f := Engine.get_process_frames()
	if f != _inbound_frame:
		_inbound_frame = f
		_inbound.clear()
		for seed_val: int in _ships:
			for ship: ShipData in _ships[seed_val]:
				if ship.is_travelling():
					if not _inbound.has(ship.dest_seed):
						_inbound[ship.dest_seed] = []
					(_inbound[ship.dest_seed] as Array).append(ship)
	return _inbound.get(dest_seed, _NONE)

var _inbound := {}
var _inbound_frame := -1

## The ships at a place, without a copy: read only, never changed or kept
## (views go through these every frame). ships_for() for a list to work on.
func ships_at(planet_seed: int) -> Array:
	return _ships.get(planet_seed, _NONE)

const _NONE: Array = []

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
func launch(planet_seed: int, ship_name: String, cargo: Dictionary = {}) -> ShipData:
	var angle := randf() * TAU
	var ship   := ShipData.make(ship_name, planet_seed, angle)
	ship.cargo  = cargo
	add_ship(ship)
	return ship

## Send an orbiting ship to a destination planet.
func dispatch(ship: ShipData, dest_seed: int, duration_sec: float) -> void:
	ship.dest_seed       = dest_seed
	ship.travel_duration = duration_sec
	ship.travel_progress = 0.0
	ship_changed.emit(ship)

## Orders a transfer that starts at the burn window: the ship keeps circling
## its parking orbit until it is on the far side from the target (a Hohmann
## transfer burns there, so the far point of its path meets the target), then
## leaves. Bodies not in one planet system (no window): it leaves at once.
func dispatch_on_window(ship: ShipData, dest_seed: int, duration_sec: float) -> void:
	ship.pending_dest = dest_seed
	ship.pending_duration = duration_sec
	ship.pending_wait = 0.0
	ship_changed.emit(ship)


## How close (cos of the angle) the ship must be to the burn point.
const WINDOW_COS := 0.985

func _try_window(ship: ShipData, delta: float) -> void:
	ship.pending_wait += delta
	# inside one planet system: a Hohmann burn on the far side from the target;
	# out to another: at the near point of the escape that heads off the way
	# the lane goes (OrbitLayout.burn_dir). A base's ships just go.
	var to_dest := OrbitLayout.dir_between(ship.orbit_seed, ship.pending_dest)
	var want := -to_dest if to_dest != Vector2.ZERO else OrbitLayout.burn_dir(ship, ship.pending_dest)
	var period := TAU / maxf(absf(ship.orbit_speed), 0.05)
	var go := OrbitLayout.is_detail_seed(ship.orbit_seed) or ship.pending_wait > period * 1.5   # never wait forever
	if not go:
		var v := ShipData.orbit_point(1.0, ship.orbit_inclination, ship.orbit_node, ship.orbit_angle)
		var here := Vector2(v.x, v.z)
		go = here.length() > 0.2 and here.normalized().dot(want) >= WINDOW_COS
	if go:
		var dest := ship.pending_dest
		var dur := ship.pending_duration
		ship.pending_dest = -1
		ship.pending_wait = 0.0
		dispatch(ship, dest, dur)

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
				"pending_dest":      ship.pending_dest,
				"pending_duration":  ship.pending_duration,
				"pending_wait":      ship.pending_wait,
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
		s.pending_dest      = int(d.get("pending_dest", -1))
		s.pending_duration  = float(d.get("pending_duration", 0.0))
		s.pending_wait      = float(d.get("pending_wait", 0.0))
		if s.orbit_seed >= 0:
			add_ship(s)

# ── Spaceport traffic ─────────────────────────────────────────────────────────
# Every pair of worlds with a finished Spaceport (or an older save's Lunar Spaceport) gets a
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
			elif ship.ship_type == HAULER:
				_advance_hauler(ship, delta)
	_traffic_t += delta
	if _traffic_t >= TRAFFIC_TICK:
		_traffic_t = 0.0
		_balance_fleets()
		_balance_haulers()

# ── Route traffic (pioneers and haulers) ─────────────────────────────────────
# A first rocket (a pioneer) opens a route when it arrives: between two worlds,
# or to a base it sets up on an asteroid cluster / nebula (GameState.outposts).
# Every open route then gets haulers going back and forth on their own, more
# as the worlds at its ends grow (_world_size) — a picture of the traffic, like
# the freighters: no cargo, no economy. A hauler waits in orbit, leaves (at the
# burn window inside one planet system), arrives, waits, and goes back.

const PIONEER := "pioneer"
const HAULER := "hauler"
const HAULER_WAIT_MIN := 10.0
const HAULER_WAIT_MAX := 26.0
const HAULER_FLEET_MAX := 6
## Travel times: inside one planet system / between planets / to a base.
const LOCAL_SEC := 30.0
const INTERPLANETARY_SEC := 60.0


func flight_sec(a: int, b: int) -> float:
	return LOCAL_SEC if OrbitLayout.dir_between(a, b) != Vector2.ZERO else INTERPLANETARY_SEC


## Sends a first rocket from `from_seed` to `to_seed` (a world, or a detail's
## stand-in seed, OrbitLayout.detail_seed); `base` names the base it sets up
## there ({ kind, name, system } — empty for a world).
func send_pioneer(from_seed: int, to_seed: int, base: Dictionary = {}) -> ShipData:
	var ship := ShipData.make("Pioneer %s-%d" % [char(65 + randi() % 26), randi_range(10, 99)], from_seed, randf() * TAU)
	ship.ship_id += "_%d" % randi()
	ship.ship_type = PIONEER
	ship.orbit_speed = 0.3
	ship.orbit_radius = 1.12
	ship.orbit_inclination = randf_range(-0.3, 0.3)
	ship.traffic_pair = JSON.stringify(base) if not base.is_empty() else ""
	add_ship(ship)
	dispatch_on_window(ship, to_seed, flight_sec(from_seed, to_seed))
	return ship


func _pioneer_arrived(ship: ShipData, from_seed: int) -> void:
	if ship.traffic_pair != "":
		var base = JSON.parse_string(ship.traffic_pair)
		if base is Dictionary:
			GameState.outposts[str(ship.orbit_seed)] = base
	GameState.add_traffic_link(from_seed, ship.orbit_seed)
	# it stays as the route's first hauler
	ship.ship_type = HAULER
	ship.traffic_pair = _pair_key(from_seed, ship.orbit_seed)
	ship.traffic_partner = from_seed
	ship.traffic_state = "orbit"
	ship.state_t = 0.0
	ship.state_len = randf_range(HAULER_WAIT_MIN, HAULER_WAIT_MAX)
	NewsFeed.post("%s reached its goal: a new route is open." % ship.ship_name)


func _advance_hauler(ship: ShipData, delta: float) -> void:
	if ship.is_travelling() or ship.pending_dest >= 0:
		return
	ship.state_t += delta
	if ship.state_t < ship.state_len or ship.traffic_partner < 0:
		return
	ship.traffic_state = "transfer"
	var to := _route_end(ship.orbit_seed, ship.traffic_partner)
	dispatch_on_window(ship, to, flight_sec(ship.orbit_seed, to))


## Where a hauler at `here` lands at the far end `partner` of its route: on a
## route between two planet systems, any settled body of the far one (the
## planet or a colonized moon), so the traffic spreads over them; else partner.
func _route_end(here: int, partner: int) -> int:
	if OrbitLayout.dir_between(here, partner) != Vector2.ZERO or OrbitLayout.is_detail_seed(partner):
		return partner
	var opts: Array[int] = [partner]
	for s: int in OrbitLayout.family(partner):
		if s != partner and GameState._planet_progress.has(s) \
				and (GameState._planet_progress[s] as PlanetProgress).is_colonized:
			opts.append(s)
	return opts[randi() % opts.size()]


## How big a route's fleet is: grows with the worlds at its ends (a base counts small).
func _route_fleet(a: int, b: int) -> int:
	var size := maxi(_world_size(a), 1) + maxi(_world_size(b), 1)
	return clampi(1 + floori(float(size - 2) / 3.0), 1, HAULER_FLEET_MAX)


func _balance_haulers() -> void:
	var have := {}
	for seed_val: int in _ships:
		for ship: ShipData in _ships[seed_val]:
			if ship.ship_type == HAULER:
				have[ship.traffic_pair] = int(have.get(ship.traffic_pair, 0)) + 1
	for l: Array in GameState.traffic_links:
		var a := int(l[0])
		var b := int(l[1])
		var key := _pair_key(a, b)
		var n := int(have.get(key, 0))
		if n < _route_fleet(a, b):
			var at := a if n % 2 == 0 else b
			var ship := ShipData.make("Hauler %s-%d" % [char(65 + randi() % 26), randi_range(10, 99)], at, randf() * TAU)
			ship.ship_id += "_%d" % randi()
			ship.ship_type = HAULER
			ship.orbit_speed = randf_range(0.22, 0.32) * (1.0 if randf() < 0.7 else -1.0)
			ship.orbit_radius = randf_range(1.1, 1.3)
			ship.orbit_inclination = randf_range(-0.5, 0.5)
			ship.traffic_pair = key
			ship.traffic_partner = b if at == a else a
			ship.traffic_state = "orbit"
			ship.state_len = randf_range(HAULER_WAIT_MIN, HAULER_WAIT_MAX)
			add_ship(ship)


## Worlds with a finished Spaceport (or an older save's Lunar Spaceport).
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
