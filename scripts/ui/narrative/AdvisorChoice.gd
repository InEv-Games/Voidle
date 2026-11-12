class_name AdvisorChoice
extends RefCounted

## The opening's choice (docs/design/narrative/SCENES.md, opening_intro): the two
## caretakers side by side (ChoiceScreen), each standing large with the role,
## name and bonus a Companions card shows, what they say they can do and
## APPOINT. A choice is required: no close button, Esc does nothing.
## `on_pick(advisor_id)` runs on APPOINT.

const LAYER := 236
const IDS := ["mother_superior", "high_father"]

static func open(host: Node, on_pick: Callable) -> ModalPopup:
	var options: Array = []
	for id: String in IDS:
		var def := CompanionDef.find(id)
		if def == null:
			continue
		options.append({
			"id": def.companion_id,
			"portrait": def.portrait_texture(),
			"caption": def.role,
			"name": def.display_name,
			"body": "[i]%s[/i]\n\n%s\n[color=#%s]Serves at least five years once appointed.[/color]" % [
				def.pitch, def.bonus_bb(13), UIStyle.hex(&"text_subtle")],
			"button": "APPOINT",
			"icon": "confirm",
		})
	return ChoiceScreen.open(host, "Facilitator  //  Year 2465", "YOUR ADVISOR", options, on_pick, LAYER, false)
