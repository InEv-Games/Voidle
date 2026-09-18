class_name ScienceLogic
extends BuildingLogic

func produce(pp: PlanetProgress, def: BuildingDef, _amount: int, _mods: Array, entry: Dictionary, _skill_tree: Node) -> void:
	GameState.add_science(ProductionManager.get_building_output(pp, entry, def))
