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
