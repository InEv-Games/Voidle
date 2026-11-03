@tool
class_name StorySetFlag
extends VSMAction

## Story exit: remembers a choice for the later stories (StoryHasFlag).

@export var flag: String = ""

func execute(blackboard: Dictionary) -> void:
	var out: Array = blackboard.get(Excavations.BB_FLAGS, [])
	out.append(flag)
	blackboard[Excavations.BB_FLAGS] = out

func describe() -> String:
	return "Remember: " + flag
