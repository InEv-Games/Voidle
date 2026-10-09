class_name RoadAStar
extends AStar3D

## AStar3D with per-edge costs for RoadNetwork: bridges (links across a short
## non-green gap) cost BRIDGE_COST × their length, so a route only bridges when
## curving around over green land would be much longer.

const BRIDGE_COST: float = 3.0

var _bridges: Dictionary = {}   # edge key -> true

static func _key(a: int, b: int) -> int:
	return mini(a, b) * 4294967296 + maxi(a, b)

func add_bridge(a: int, b: int) -> void:
	connect_points(a, b)
	_bridges[_key(a, b)] = true

func _compute_cost(from_id: int, to_id: int) -> float:
	var d := get_point_position(from_id).distance_to(get_point_position(to_id))
	return d * BRIDGE_COST if _bridges.has(_key(from_id, to_id)) else d

func _estimate_cost(from_id: int, end_id: int) -> float:
	return get_point_position(from_id).distance_to(get_point_position(end_id))
