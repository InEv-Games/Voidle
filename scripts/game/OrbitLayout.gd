## Where a world's moons sit round it, the same for every view and for the
## ships (Star System, Planet System, ShipManager's burn windows).
class_name OrbitLayout
extends RefCounted

const GOLDEN := 2.39996323


## A stand-in body seed for a star system's detail (asteroid cluster, nebula),
## so ships can orbit / fly to it like a world: far above any planet seed.
static func detail_seed(solar_seed: int, index: int) -> int:
	return 100000000 + absi(hash([solar_seed, index])) % 800000000


static func is_detail_seed(seed_val: int) -> bool:
	return seed_val >= 100000000


## Moon j's angle round its planet, on the system's plane.
static func moon_angle(planet_seed: int, j: int) -> float:
	return fposmod(float(planet_seed % 628) * 0.01 + 0.9 + GOLDEN * float(j), TAU)


## Plane direction from body `from` to body `to`, when one is the other's moon
## (or both moons of one planet); ZERO when they are not in one planet system.
static func dir_between(from_seed: int, to_seed: int) -> Vector2:
	var a := _place(from_seed)
	var b := _place(to_seed)
	if a.is_empty() or b.is_empty() or int(a["planet"]) != int(b["planet"]):
		return Vector2.ZERO
	var d: Vector2 = Vector2(b["pos"]) - Vector2(a["pos"])
	return d.normalized() if d.length() > 0.0001 else Vector2.ZERO


## Orbit radius (planet radii) a ship is captured into round a moon, and how
## much wider the Planet System draws orbits (its ORBIT_SPREAD): the capture
## point sits CAPTURE_R out, i.e. 1 + (CAPTURE_R − 1) × SPREAD body radii there.
const CAPTURE_R := 1.4
const SPREAD := 3.0


## A transfer's own tilt off the system's plane (radians), fixed per ship so
## the Planet System draws it and ShipManager captures on it alike: turned
## about the line from its start to its end, so both ends stay put.
static func transfer_inc(ship_id: String) -> float:
	return (float(absi(ship_id.hash()) % 1000) / 1000.0 - 0.5) * 1.1   # about ±31°


## The orbit a ship ends in after a transfer from `from_seed` to `to_seed`
## (a Hohmann half-ellipse round the planet, flown with `sense` +1 / −1), so it
## carries on from exactly where and the way it arrived:
## { angle, spin (+1 / −1), radius (or −1 to keep its own) } in the target's
## frame (inclination 0, node 0: the system's plane). {} when not one system.
static func capture(from_seed: int, to_seed: int, sense: float, inc := 0.0) -> Dictionary:
	var d := dir_between(from_seed, to_seed)
	if d == Vector2.ZERO:
		return {}
	var dir_s := -d                      # where the transfer starts, from the planet
	var to_planet := Vector2(_place(to_seed).get("pos", Vector2.ONE)) == Vector2.ZERO
	var rel := -dir_s if to_planet else dir_s   # arrival point, seen from the target
	var t := (-dir_s).rotated(PI * 0.5) * sense   # its heading there
	# an orbit whose angle-0 point is the arrival point (node turns its x axis
	# onto it), tilted like the transfer; spin so it moves on the way it came
	var node := -rel.angle()
	var fwd := Vector2(sin(node), cos(node))   # where angle grows, on the plane
	var spin := 1.0 if fwd.dot(t) >= 0.0 else -1.0
	# the tilt that carries on the transfer's own climb / dive at that point:
	# the transfer leans by `inc` about its start–end line, so it arrives
	# heading along t with a vertical part of −σ·sin(inc), σ = t·n = −sense
	# (n: the start direction turned 90°); the capture orbit's vertical part
	# at angle 0 is −sin(its inc)·spin — equal when its inc = −inc·sense·spin
	return {"angle": 0.0, "node": node, "inc": -inc * sense * spin, "spin": spin,
		"radius": -1.0 if to_planet else CAPTURE_R}


## { planet (seed of the planet the body belongs to), pos (unit-ish plane
## position: the planet at 0, moon j at its angle) }, or {}.
static func _place(seed_val: int) -> Dictionary:
	var sd := GameState.get_home_solar()
	if sd == null:
		return {}
	for pd: PlanetData in sd.planets:
		if pd.seed == seed_val:
			return {"planet": pd.seed, "pos": Vector2.ZERO}
		for j in pd.moons.size():
			if (pd.moons[j] as PlanetData).seed == seed_val:
				return {"planet": pd.seed, "pos": Vector2.from_angle(moon_angle(pd.seed, j)) * (1.0 + float(j))}
	return {}


# ── Leaving and reaching a body (any flight that leaves the view's body) ─────
# A ship leaves its parking orbit on an escape hyperbola: its burn point (the
# near point) is where it was circling when it fired, the curve lies in that
# orbit's own plane and opens outward as it climbs, fast low down and slow far
# out (Kepler, hyperbolic). Coming in it is the same curve backwards, ending
# on the orbit it is captured into (arrival()). The views draw these legs and
# fade them out with height: many ships together look like a fountain.

## Eccentricity of the escape / approach hyperbolas.
const ESCAPE_E := 1.6
## Share of a flight spent on each of the two legs (leaving, arriving).
const ESCAPE_U := 0.22
## Height (body radii) a leg reaches at its far end, where the views have faded it.
const ESCAPE_R := 6.0


## Where a body is on its star system's plane (Star System units): a moon at
## its planet, a detail stand-in at its cloud. ZERO when unknown.
static func system_pos(seed_val: int) -> Vector2:
	var sd := GameState.get_home_solar()
	if sd == null:
		return Vector2.ZERO
	var planet_pos: Array[Vector2] = []
	for i in sd.planets.size():
		planet_pos.append(Vector2.from_angle(fposmod(float(sd.seed % 628) * 0.01 + GOLDEN * float(i), TAU))
			* (SYS_ORBIT_BASE + SYS_ORBIT_STEP * float(i)))
	for i in sd.planets.size():
		var pd: PlanetData = sd.planets[i]
		if pd.seed == seed_val:
			return planet_pos[i]
		for m: PlanetData in pd.moons:
			if m.seed == seed_val:
				return planet_pos[i]
	if is_detail_seed(seed_val):
		var key := sd.seed
		if not _details_cache.has(key):
			_details_cache[key] = SystemDetails.generate(sd, planet_pos, SYS_ORBIT_BASE, SYS_ORBIT_STEP)
		var dets: Array = _details_cache[key]
		for f in dets.size():
			if detail_seed(sd.seed, f) == seed_val:
				return dets[f]["center"]
	return Vector2.ZERO

## StarSystemView's ORBIT_BASE / ORBIT_STEP (planet i circles at BASE + STEP·i).
const SYS_ORBIT_BASE := 210.0
const SYS_ORBIT_STEP := 115.0
static var _details_cache := {}


## The way a ship between two planet systems is heading, on the plane, as it
## leaves `from_seed` (at_end false) or reaches `to_seed` (true): round the star
## the way the worlds go (as the Star System draws the lane), leaning out or
## in towards the other's distance.
static func heading(from_seed: int, to_seed: int, at_end: bool) -> Vector2:
	var pa := system_pos(from_seed)
	var pb := system_pos(to_seed)
	var here := pb if at_end else pa
	if here.length() < 0.001:
		return Vector2.RIGHT
	var lean := clampf((pb.length() - pa.length()) / maxf(here.length(), 1.0), -1.0, 1.0) * 0.6
	return (here.normalized().rotated(PI * 0.5) + here.normalized() * lean).normalized()


## The escape leg of a ship leaving its body now: { peri, inc, node, sense, rp }.
static func departure_leg(ship: ShipData) -> Dictionary:
	return {"peri": ship.orbit_angle, "inc": ship.orbit_inclination, "node": ship.orbit_node,
		"sense": 1.0 if ship.orbit_speed >= 0.0 else -1.0, "rp": maxf(ship.orbit_radius, 1.02), "inbound": false}


## The approach leg of a flying ship, ending on its arrival() orbit, or {}.
static func arrival_leg(ship: ShipData) -> Dictionary:
	var arr := arrival(ship)
	if arr.is_empty():
		return {}
	return {"peri": float(arr["angle"]), "inc": float(arr["inc"]), "node": float(arr["node"]),
		"sense": float(arr["spin"]), "rp": maxf(float(arr["radius"]), 1.02), "inbound": true}


## A point of a leg at s (0..1 of the leg's time), in the body's frame (body
## radii, ShipData.orbit_point's axes): Vector3, and its height in .length().
static func leg_point(leg: Dictionary, s: float) -> Vector3:
	var e := ESCAPE_E
	var rp: float = leg["rp"]
	var a := rp / (e - 1.0)
	var r_end := maxf(ESCAPE_R, rp * 1.5)
	var h_end := acosh((r_end / a + 1.0) / e)
	var m_end := e * sinh(h_end) - h_end
	# hyperbolic Kepler: e·sinh H − H = M, M even in time
	var m := clampf(s, 0.0, 1.0) * m_end
	if leg["inbound"]:
		m = -(1.0 - clampf(s, 0.0, 1.0)) * m_end
	var h := asinh(m / e)
	for it in 8:
		h -= (e * sinh(h) - h - m) / (e * cosh(h) - 1.0)
	var nu := 2.0 * atan(sqrt((e + 1.0) / (e - 1.0)) * tanh(h * 0.5))
	var r := a * (e * cosh(h) - 1.0)
	return ShipData.orbit_point(r, leg["inc"], leg["node"], float(leg["peri"]) + float(leg["sense"]) * nu)


## Which leg a flight is on and how far: { leg ("out" / "in" / ""), s }.
static func leg_of(ship: ShipData) -> Dictionary:
	var u := clampf(ship.travel_progress, 0.0, 1.0)
	if u < ESCAPE_U:
		return {"leg": "out", "s": u / ESCAPE_U}
	if u > 1.0 - ESCAPE_U:
		return {"leg": "in", "s": (u - (1.0 - ESCAPE_U)) / ESCAPE_U}
	return {"leg": "", "s": 0.0}


## The orbit a flying ship ends on at its destination (ShipManager applies it
## on arrival, the views end the approach leg on it): { angle, inc, node, spin,
## radius }. Inside one planet system: capture() (it carries on from its
## transfer). Otherwise it keeps its orbit's tilt and height, and arrives at
## the near point of a hyperbola coming in from the way it was heading. {} for
## the lander (its own flow) and ships not flying.
static func arrival(ship: ShipData) -> Dictionary:
	if ship.dest_seed < 0 or ship.ship_type == "lander":
		return {}
	var sense := 1.0 if ship.orbit_speed >= 0.0 else -1.0
	var cap := capture(ship.orbit_seed, ship.dest_seed, sense, transfer_inc(ship.ship_id))
	if not cap.is_empty():
		cap["radius"] = float(cap["radius"]) if float(cap["radius"]) > 0.0 else ship.orbit_radius
		return cap
	# came in from where it was heading away from; the near point lies ν∞ on
	# from that direction, the way the orbit runs
	var from_dir := -_flight_heading(ship.orbit_seed, ship.dest_seed, true)
	var peri := _angle_facing(ship.orbit_inclination, ship.orbit_node, from_dir.rotated(sense * _nu_inf()))
	return {"angle": peri, "inc": ship.orbit_inclination, "node": ship.orbit_node, "spin": sense,
		"radius": ship.orbit_radius}


## Where a ship should be on its orbit to burn for `to_seed` (the near point of
## its escape, ν∞ back from the way it must head off): plane direction.
static func burn_dir(ship: ShipData, to_seed: int) -> Vector2:
	var sense := 1.0 if ship.orbit_speed >= 0.0 else -1.0
	return _flight_heading(ship.orbit_seed, to_seed, false).rotated(-sense * _nu_inf())


## The leaving / arriving heading of a flight on the body's plane: between two
## planet systems round the star (heading()); inside one, along the transfer
## (away from the other body: a Hohmann burn on the far side).
static func _flight_heading(from_seed: int, to_seed: int, at_end: bool) -> Vector2:
	var d := dir_between(from_seed, to_seed)
	if d != Vector2.ZERO:
		return d
	return heading(from_seed, to_seed, at_end)


static func _nu_inf() -> float:
	return acos(-1.0 / ESCAPE_E)


## The angle on an orbit (tilt inc, node) whose point, seen on the plane,
## points most nearly along `want`.
static func _angle_facing(inc: float, node: float, want: Vector2) -> float:
	var best := 0.0
	var best_d := -INF
	for k in 72:
		var a := TAU * float(k) / 72.0
		var v := ShipData.orbit_point(1.0, inc, node, a)
		var p := Vector2(v.x, v.z)
		if p.length() < 0.05:
			continue
		var d := p.normalized().dot(want)
		if d > best_d:
			best_d = d
			best = a
	return best


## The bodies of one planet system (the planet and its moons), or [seed].
static func family(seed_val: int) -> Array[int]:
	var out: Array[int] = []
	var pl := _place(seed_val)
	var sd := GameState.get_home_solar()
	if pl.is_empty() or sd == null:
		out.append(seed_val)
		return out
	for pd: PlanetData in sd.planets:
		if pd.seed == int(pl["planet"]):
			out.append(pd.seed)
			for m: PlanetData in pd.moons:
				out.append(m.seed)
	return out
