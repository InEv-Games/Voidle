class_name RoadAStar
extends AStar3D

## AStar3D with per-edge costs for RoadNetwork: bridges (links across a short
## non-green gap) cost BRIDGE_COST × their length, so a route only bridges when
## curving around over green land would be much longer.

const BRIDGE_COST: float = 3.0

var _bridges: Dictionary = {}   # edge key -> true
## Land-only routing: ports / sea cells become (practically) impassable. Set by
## RoadNetwork when both ends share a landmass, so a land road always wins.
var land_only := false
var cell_count := 0              # ids >= this are ports
var kind: PackedByteArray        # RoadNetwork._kind (1 = sea)
## Ports belong to the towns they serve: a port farther than port_reach (chord
## on the unit sphere) from both route ends costs PORT_FAR_PENALTY extra, so a
## city's harbour sits inside its own borders. 0 = off.
var port_reach := 0.0
var port_end_a := Vector3.ZERO
var port_end_b := Vector3.ZERO
const PORT_FAR_PENALTY: float = 2.0

static func _key(a: int, b: int) -> int:
	return mini(a, b) * 4294967296 + maxi(a, b)

func add_bridge(a: int, b: int) -> void:
	connect_points(a, b)
	_bridges[_key(a, b)] = true

func _compute_cost(from_id: int, to_id: int) -> float:
	var d := get_point_position(from_id).distance_to(get_point_position(to_id))
	if land_only and (to_id >= cell_count or kind[to_id] == 1):
		return d * 1.0e6
	if to_id >= cell_count and port_reach > 0.0:
		var p := get_point_position(to_id).normalized()
		if p.distance_to(port_end_a) > port_reach and p.distance_to(port_end_b) > port_reach:
			d += PORT_FAR_PENALTY
	return d * BRIDGE_COST if _bridges.has(_key(from_id, to_id)) else d

func _estimate_cost(from_id: int, end_id: int) -> float:
	return get_point_position(from_id).distance_to(get_point_position(end_id))
