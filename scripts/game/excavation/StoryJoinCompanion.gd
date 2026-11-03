@tool
class_name StoryJoinCompanion
extends VSMAction

## Story exit: this companion joins when the excavation ends.

@export var companion: CompanionDef

func execute(blackboard: Dictionary) -> void:
	if companion != null:
		blackboard[Excavations.BB_JOIN] = companion.companion_id

func describe() -> String:
	return "Joins: " + (companion.display_name if companion != null else "(none)")
