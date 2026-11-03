@tool
class_name StoryGrant
extends VSMAction

## Story exit: adds resources to what the excavation pays when it ends
## (Excavations.finish), so an unfinished story gives nothing.

## { resource id: amount }, e.g. { "credits": 500, "science": 40 }.
@export var resources: Dictionary = {}

func execute(blackboard: Dictionary) -> void:
	var out: Dictionary = blackboard.get(Excavations.BB_GRANTS, {})
	for id: String in resources:
		out[id] = float(out.get(id, 0.0)) + float(resources[id])
	blackboard[Excavations.BB_GRANTS] = out

func describe() -> String:
	var parts: Array[String] = []
	for id: String in resources:
		parts.append("%s +%s" % [id, str(resources[id])])
	return "Grant: " + ", ".join(parts)
