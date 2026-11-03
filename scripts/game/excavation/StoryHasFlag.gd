@tool
class_name StoryHasFlag
extends VSMCondition

## On a story exit: shows it only if an earlier choice set this flag (or, with
## `negate`, only if it didn't). Two exits with opposite checks act as a silent
## branch: only one is visible, so VSM takes it without asking.

@export var flag: String = ""
@export var negate: bool = false

func evaluate(blackboard: Dictionary) -> bool:
	var has: bool = GameState.story_flags.has(flag) or flag in blackboard.get(Excavations.BB_FLAGS, [])
	return not has if negate else has

func describe() -> String:
	return ("not " if negate else "") + flag
