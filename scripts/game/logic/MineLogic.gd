class_name MineLogic
extends BuildingLogic

func produce(pp: PlanetProgress, def: BuildingDef, _amount: int, _mods: Array, entry: Dictionary, _skill_tree: Node) -> void:
	var outputs := ProductionManager.get_resource_outputs(pp, entry, def)
	for id: String in outputs:
		pp.add_resource(id, float(outputs[id]))
