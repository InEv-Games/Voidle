class_name RefineryLogic
extends BuildingLogic

func requires_mineral_selector() -> bool:
	return true

func produce(pp: PlanetProgress, def: BuildingDef, amount: int, mods: Array, entry: Dictionary, skill_tree: Node) -> void:
	var input_id: String = entry.get("burning_mineral", entry.get("input_mineral", ""))
	var input: ResourceData = GameState.known_resources.get(input_id)
	if input == null:
		return
	var output := input.processed()
	GameState.known_resources[output.resource_id()] = output
	var mult: float = PlanetModifier.combined(mods, PlanetModifier.Effect.MINE_OUTPUT_MULT) * skill_tree.get_mine_output_mult()
	mult *= ProductionManager.get_building_level_mult(entry.get("level", 1))
	var buffs := ProductionManager.get_district_buffs(pp, entry.get("district_id", ""))
	mult *= float(buffs.mine_output_mult)
	pp.add_resource(output.resource_id(), ProductionManager.get_building_output(pp, entry, def))
