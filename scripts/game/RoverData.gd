## One surface unit (RoverManager). Plain data; RoverManager moves it.
class_name RoverData
extends RefCounted

var id: String
var name: String
var planet_seed: int
var pos: Vector3 = Vector3(0, 0, 1)
## Remaining route points (unit vectors), next one first.
var path: Array[Vector3] = []
## Per path point: the leg to it runs on a road (faster).
var path_road: Array[bool] = []
## Points the player clicked (for the markers), next one first.
var goals: Array[Vector3] = []
## Unit vector of the last movement direction (for the sprite).
var heading: Vector3 = Vector3.ZERO
var km_driven: float = 0.0
## 0 = on the surface, 1 = in orbit (RoverManager.State).
var state: int = 0
## Running action: { id, name, start, end, in, out, target: {} } (empty = none).
## start / end are GameState.play_seconds.
var action: Dictionary = {}
## Start the same action again when it ends (if it still can).
var repeat: bool = false

func is_moving() -> bool:
	return not path.is_empty()

func in_orbit() -> bool:
	return state == 1

func is_busy() -> bool:
	return not action.is_empty()

func on_road() -> bool:
	return not path_road.is_empty() and path_road[0]

func lon() -> float:
	return atan2(pos.x, pos.z)

func lat() -> float:
	return asin(clampf(pos.y, -1.0, 1.0))

func to_dict() -> Dictionary:
	return {"id": id, "name": name, "seed": planet_seed,
		"pos": [pos.x, pos.y, pos.z], "km": km_driven,
		"path": _vecs_out(path), "road": path_road.duplicate(), "goals": _vecs_out(goals),
		"state": state, "action": action.duplicate(true), "repeat": repeat}

static func _vecs_out(vs: Array[Vector3]) -> Array:
	var out: Array = []
	for v: Vector3 in vs:
		out.append([v.x, v.y, v.z])
	return out

static func vecs_in(arr: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for a: Array in arr:
		if a.size() == 3:
			out.append(Vector3(float(a[0]), float(a[1]), float(a[2])).normalized())
	return out
