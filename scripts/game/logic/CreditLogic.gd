class_name CreditLogic
extends BuildingLogic

func produce(pp: PlanetProgress, def: BuildingDef, _amount: int, _mods: Array, entry: Dictionary, _skill_tree: Node) -> void:
	GameState.earn_credits(ProductionManager.get_building_output(pp, entry, def))
