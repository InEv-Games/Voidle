## One action the player can take on something — shown in the right-click
## context menu (ContextMenu) and gathered by CommandRegistry.
##
## can_execute() returns "" when the action is allowed, otherwise the reason it
## isn't; the menu shows blocked actions greyed out with that reason instead of
## hiding them. Small actions are built with GameCommand.make(); bigger ones
## (demolish, move, update…) can subclass and override can_execute/execute.
class_name GameCommand
extends RefCounted

var id: String = ""
var label: String = ""
var icon: String = ""
var color: Color = Color(0.75, 0.85, 1.0)
## Short cost shown on the right of the row, e.g. "◈ 1.2k cr".
var cost: String = ""
## Extra text for the row's tooltip.
var tooltip: String = ""

var _run: Callable
var _can: Callable

## `run` performs the action; `can` (optional) returns "" or the reason it's blocked.
## `opts` may set icon, color, cost and tooltip.
static func make(p_id: String, p_label: String, run: Callable, can: Callable = Callable(),
		opts: Dictionary = {}) -> GameCommand:
	var c := GameCommand.new()
	c.id = p_id
	c.label = p_label
	c._run = run
	c._can = can
	c.icon = opts.get("icon", "")
	c.color = opts.get("color", c.color)
	c.cost = opts.get("cost", "")
	c.tooltip = opts.get("tooltip", "")
	return c

func can_execute() -> String:
	return String(_can.call()) if _can.is_valid() else ""

## Runs the action if it's allowed; false when blocked.
func execute() -> bool:
	if can_execute() != "" or not _run.is_valid():
		return false
	_run.call()
	return true
