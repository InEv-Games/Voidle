## A single ship in orbit around a planet.
class_name ShipData
extends Resource

## Unique id — generated at launch.
@export var ship_id:      String = ""
@export var ship_name:    String = "Shuttle"
## "shuttle" | "station" | "lander" (the Moon colony lander — not commandable)
@export var ship_type:    String = "shuttle"

## Which planet this ship currently orbits (seed).
@export var orbit_seed:   int    = -1

## Orbital angle in radians (advances each tick).
@export var orbit_angle:  float  = 0.0

## Orbital radius as fraction of planet radius (1.0 = surface, ~1.02 = just above).
@export var orbit_radius: float  = 1.06

## Inclination of orbital plane in radians (random per ship — gives varied tilt angles).
@export var orbit_inclination: float = 0.0

## Orbital angular speed in rad/s. Positive = one direction, negative = opposite.
@export var orbit_speed: float = 0.01

## Longitude of ascending node — rotates the orbital plane around the Y axis.
## With orbit_inc and orbit_angle, this gives full 3-DOF orbital orientation.
@export var orbit_node: float = 0.0

## Cargo: resource_id -> amount
@export var cargo:        Dictionary = {}

## Station buildings — same format as PlanetProgress.buildings entries.
## Only used when ship_type == "station".
@export var buildings:    Array      = []

## Rendezvous: ship_id of target ship, or "" if not rendezvousing.
@export var rendezvous_target_id:  String = ""
## Speed before rendezvous override (restored on arrival/cancel).
@export var rendezvous_base_speed: float  = 0.0

## Active mission task chain and current execution index.
@export var mission_tasks:      Array = []
@export var mission_task_index: int   = 0

## Mission: "deliver" | "pickup" | ""
@export var transfer_dir:      String = ""
## Resource to pick up (pickup only; deliver uses cargo).
@export var transfer_resource: String = ""
## Amount to pick up (pickup only).
@export var transfer_amount:   int    = 0

## Destination planet seed (-1 = parked in orbit).
@export var dest_seed:    int    = -1

## Travel progress 0.0–1.0 (0 = just launched, 1 = arrived).
@export var travel_progress: float = 0.0

## Travel duration in seconds.
@export var travel_duration: float = 0.0

## Transfer route between two bodies (planet view): the origin-orbit angle of
## the burn that leaves it, and the destination-orbit angle the ship holds when
## the journey ends (it keeps orbiting from there). NAN = not chosen yet.
@export var transfer_depart_angle: float = NAN
@export var transfer_arrive_angle: float = NAN

## Spaceport traffic (ShipManager): a freighter's place in its loop —
## "pad" (on the ground, hidden) → "ascend" → "orbit" (free orbit: circling,
## tied to nothing, may leave any time) → "transfer" → "captured" (circling the
## destination) → "descend" → "pad". Purely visual: no cargo, no economy.
@export var traffic_state:   String = ""
## The body it heads for next, and its route ("a:b", lower seed first).
@export var traffic_partner: int    = -1
@export var traffic_pair:    String = ""
## Time in the current state and how long it lasts.
@export var state_t:   float = 0.0
@export var state_len: float = 0.0
## Orbit radius it parks at (spread so freighters don't sit on one ring).
@export var park_radius: float = 1.2

## Planet-frame point of an orbit (radius, inclination, node, angle).
static func orbit_point(r: float, inc: float, node: float, angle: float) -> Vector3:
	var px := r * cos(angle)
	var py := r * sin(angle) * sin(inc)
	var pz := r * sin(angle) * cos(inc)
	return Vector3(px * cos(node) + pz * sin(node), py, -px * sin(node) + pz * cos(node))

## Planet-frame direction (OrbitalLayer's frame) of a surface point.
static func frame_dir(lon: float, lat: float) -> Vector3:
	return Vector3(cos(lat) * sin(lon), -sin(lat), -cos(lat) * cos(lon))

## Puts the ship's orbit through point `p` (unit, planet frame) moving along
## `dir` (tangent): sets inclination, node and angle; speed made positive.
func fit_orbit(p: Vector3, dir: Vector3) -> void:
	dir -= p * dir.dot(p)
	if dir.length() < 1e-6:
		dir = p.cross(Vector3.UP)
		if dir.length() < 1e-6:
			dir = Vector3.RIGHT
	dir = dir.normalized()
	var nrm := p.cross(dir).normalized()
	var inc := acos(clampf(-nrm.y, -1.0, 1.0))
	var node := atan2(nrm.x, nrm.z) if sin(inc) > 1e-5 else 0.0
	var u := Vector3(cos(node), 0.0, -sin(node))
	var w := Vector3(cos(inc) * sin(node), sin(inc), cos(inc) * cos(node))
	orbit_inclination = inc
	orbit_node = node
	orbit_angle = atan2(p.dot(w), p.dot(u))
	orbit_speed = absf(orbit_speed) if orbit_speed != 0.0 else 0.1

func is_travelling() -> bool:
	return dest_seed >= 0 and travel_progress < 1.0

func eta_seconds() -> float:
	if not is_travelling():
		return 0.0
	return travel_duration * (1.0 - travel_progress)

func cargo_total() -> float:
	var t: float = 0.0
	for v in cargo.values():
		t += float(v)
	return t

static func make(name: String, planet_seed: int, angle: float = 0.0) -> ShipData:
	var s               := ShipData.new()
	s.ship_id            = "%d_%d" % [planet_seed, Time.get_ticks_msec()]
	s.ship_name          = name
	s.orbit_seed         = planet_seed
	s.orbit_angle        = angle
	s.orbit_inclination  = randf() * TAU   # random orbital plane tilt
	return s
