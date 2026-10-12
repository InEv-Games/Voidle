## DebugResourceGen — @tool helper: lists which named raw resources each body
## type carries at a given distance from home (Economy.RAW_TABLE).
## Add as a child node anywhere in a scene, then use the Inspector buttons.
@tool
extends Node

@export_group("Body Settings")
@export var planet_type: PlanetData.Type = PlanetData.Type.TERRAN
@export var system_hop:  int = 0

@export_group("Actions")
@export var generate: bool = false : set = _do_generate
@export var list_all_bodies: bool = false : set = _do_all

@export_group("Output (read-only)")
@export var last_result: String = ""

func _lines_for(pt: PlanetData.Type, hop: int) -> Array[String]:
	var pd := PlanetData.new()
	pd.planet_type = pt
	pd.system_hop = hop
	var lines: Array[String] = []
	for info: Dictionary in Economy.raw_for_body(pd):
		lines.append("  [R%d] %-12s ×%.2f yield  (%s)" % [info["rarity"], info["name"],
			Economy.yield_mult(int(info["rarity"])), info["id"]])
	if lines.is_empty():
		lines.append("  (no raw resources)")
	return lines

func _do_generate(v: bool) -> void:
	generate = false
	if not v: return
	var lines: Array[String] = ["=== %s at hop %d ===" % [PlanetData.Type.keys()[planet_type], system_hop]]
	lines.append_array(_lines_for(planet_type, system_hop))
	last_result = "\n".join(lines)
	print(last_result)

func _do_all(v: bool) -> void:
	list_all_bodies = false
	if not v: return
	var lines: Array[String] = ["=== Raw resources by body type (hop %d) ===" % system_hop]
	for i in PlanetData.Type.size():
		lines.append("%s:" % PlanetData.Type.keys()[i])
		lines.append_array(_lines_for(i as PlanetData.Type, system_hop))
	last_result = "\n".join(lines)
	print(last_result)
