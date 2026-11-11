class_name BuildingLogic
extends Resource

## The logic that runs when a building cycle completes.
func produce(_pp: PlanetProgress, _def: BuildingDef, _amount: int, _mods: Array, _entry: Dictionary, _skill_tree: Node) -> void:
	pass

## Does this logic require the user to select an input mineral?
func requires_mineral_selector() -> bool:
	return false

## Custom output label formatter (can be empty to use default logic).
func format_output_label(_def: BuildingDef) -> String:
	return ""
