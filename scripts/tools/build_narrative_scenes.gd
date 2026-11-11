extends SceneTree

## Builds the story's VSM graphs (resources/narrative/*.tres) from the scene
## texts in docs/design/narrative/SCENES.md. A ONE-TIME starting point: once the
## graphs exist, edit them in the VSM editor; running this again overwrites
## those edits.
##
##   Godot --headless --path . -s scripts/tools/build_narrative_scenes.gd
##
## Spec per entry: a list of steps, each
##   ["Speaker", "line"]                         a Narrative node (Narrator: no talker)
##   {"choice": [["label", "Speaker", "reply"], …]}  the line before it gets one exit
##                                               per answer, each to its reply line
##   {"exit": "name"}                            ends the entry there (default "done")
## Outcomes the game acts on are told by the exit's name (story_finished).

const OUT := "res://resources/narrative/"

const MS := "Mother Superior"
const HF := "High Father"
const BOLO := "Bolo"
const UNKNOWN := "Unknown Woman"
const NARRATOR := "Narrator"

func _scenes() -> Dictionary:
	return {
		"opening": {
			"intro": [
				[NARRATOR, "In 2440, I-330 landed on a world that looked like its destination. Its charts did not match the sky."],
				[NARRATOR, "The ship carried the embryos of a colony. The caretakers raised the first generation aboard. Today, they are ready to build a city of their own."],
				[HF, "Seventeen thousand four hundred and ninety people are ready to settle. We have enough hands to build, and enough work for all of them."],
				[MS, "Until today, everyone you grew up with has lived under the same roof. You can see the world they chose you to settle. Look at it for a moment."],
				[HF, "The colony has chosen you as its first Facilitator. You may appoint either of us as your advisor."],
				{"exit": "choose_advisor"},
			],
			"handover_mother_superior": [
				[MS, "You have our authority, Facilitator. We will carry out your orders. I will serve with you for at least five years. Choose where we will build our first home."],
			],
			"handover_high_father": [
				[HF, "Authority transferred. We will carry out your orders. My term is five years at minimum. Select a site for the first City."],
			],
		},
		"tutorial": {
			"guide_city_mother_superior": [[MS, "Look for a place where you would want to put down roots. Select it when you are ready."]],
			"guide_city_high_father": [[HF, "Inspect the terrain. Confirm a valid site for the City."]],
			"guide_capital_mother_superior": [[MS, "Your City already has a centre. Open its Capital District. This is where you can see what the first crews have set up."]],
			"guide_capital_high_father": [[HF, "Open the City panel, then the Capital District. It came with the City and has its own building slots."]],
			"guide_district_mother_superior": [[MS, "A district gives part of the City a job. Pick the one you need and place it within the City."]],
			"guide_district_high_father": [[HF, "Select a district role in the City panel. Check the site and the price before confirming."]],
			"guide_building_mother_superior": [[MS, "Open a district and choose a building. Its card will show what it needs and what it gives the City."]],
			"guide_building_high_father": [[HF, "Open a district and inspect a building's inputs, outputs and capacity requirements. Place it when you are ready."]],
			"guide_done_mother_superior": [[MS, "The crews know the way to work now. What they build next is up to you."]],
			"guide_done_high_father": [[HF, "The basic controls are covered. Keep an eye on the objectives when you want to plan your next expansion."]],
			"first_ruin_signal_mother_superior": [[MS, "The surveyors found steps under the fallen stones. Someone once took care to build there. We can send a crew when you are ready."]],
			"first_ruin_signal_high_father": [[HF, "The survey has marked a chamber under the fallen stones. I have added the site to the map. The excavation card has the cost and estimated time."]],
		},
		"ship_records": {
			"archive_lazarus": [
				["I-330 Archive", "In 2200, the nuclear war began. Project Lazarus launched eight seedships before Earth's last launch sites went dark."],
				["I-330 Archive", "I-330 was bound for LHS 1140 b. During the crossing, a field of debris forced the ship off course. The next confirmed position is the world below."],
				["I-330 Archive", "Navigation note. The planet resembles the target. No catalogue match for the sky."],
			],
		},
		"bolo": {
			"meet_bolo": [
				[NARRATOR, "There is a lamp at the foot of the stairs. A woman sits beside it, sorting fragments into a row. She moves one aside to make room for your boots."],
				[UNKNOWN, "Careful. That bit with the scratch goes next to the hinge. I've been looking for it since before your surveyors arrived."],
				[UNKNOWN, "You're the Facilitator. Your survey crews cut down my fig tree. I planted it the night your ship came down."],
				[UNKNOWN, "I called the tree Bolo. You can call me that."],
				[BOLO, "I grew up underground. When the floods came, my people taught a fungus to cut rooms through rock. My family lived in one of those rooms. People still live there."],
				[BOLO, "I came up when your ship landed. I learned your words from the broadcasts. I wanted to ask what your ship had heard on its way down."],
				[BOLO, "There is a record in here. I can read parts of it. The pauses are the same as a signal I have been hearing from the Moon."],
				[BOLO, "I used my own blood to try the equipment down here. I ran the test again years later. My readings should have changed by then. They match right down to the last decimal."],
				{"choice": [
					["What do you hear?", BOLO, "A hum with a gap in it. Always the same gap. That is usually where somebody has left room for an answer."],
					["Tell me about your tree.", BOLO, "It shaded the entrance in the afternoon. I used to set my recorder there. The soil is still bare where the roots were."],
				]},
				[BOLO, "I can give you my recordings. In return, I want to see what I-330's receivers pick up before your caretakers clean it. Some of those gaps might have data in them."],
				["Player", "You'll have access to the signal. Let me know what you find."],
				[BOLO, "Then we can work together. I will start with the Moon."],
				{"exit": "joined"},
			],
			"bolo_before_moon": [
				[NARRATOR, "A woman waits by the Spaceport cargo ramp with a recorder wrapped in a cloth. She keeps one hand on it when the ground crew passes."],
				[UNKNOWN, "Call me Bolo. It's the name of a fig tree I planted the night your ship came down."],
				[BOLO, "My people moved underground when the floods came. I grew up in rooms they carved with fungus. They're still down there. I came up to see what had landed."],
				[BOLO, "I picked up a pulse from a crater on the Moon. The pause matches a recording I've been working on under the fallen stones."],
				[BOLO, "I used my blood to test an instrument in that room. Years later I got the same reading, down to the last decimal. I'd like to try the instrument at the other end."],
				["Player", "Come with us. I'll give you access to the ship's raw receiver logs."],
				[BOLO, "Good. I'll carry the recorder on board myself. Where can I strap it down?"],
				{"exit": "joined"},
			],
			"bolo_at_toppled_stones": [
				[BOLO, "This is the room I told you about at the port. I copied the marks on the plate next to the hinge. Watch where you put your lamp."],
			],
			"bolo_surface_invitation": [
				[BOLO, "I took all five surveys home. We put them beside the maps we've kept since the floods. Your crews found a road we thought we'd lost. A cart can take it all the way to the surface."],
				[BOLO, "Every household sent someone to the meeting. By morning, everyone had agreed to move up. They asked me to find out if you'll make room for us."],
				{"choice": [
					["Tell them they are welcome.", BOLO, "I'll send word. Tell your crews to meet us at the road by the survey camp. The first carts will come up there.", "accepted"],
					["Let's make room first.", BOLO, "I'll tell them to keep the carts below. Come find me when you're ready.", "later"],
				]},
			],
		},
	}

func _initialize() -> void:
	var gs = root.get_node_or_null("GameState")
	if gs != null:
		gs.set("_save_suspended", true)   # a -s run boots GameState, which saves on exit
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var scenes := _scenes()
	for graph_name: String in scenes:
		var data := _build(graph_name, scenes[graph_name])
		var path := OUT + graph_name + ".tres"
		var err := ResourceSaver.save(data, path)
		print("NARRATIVE ", path, " entries ", (scenes[graph_name] as Dictionary).size(), " nodes ", data.nodes.size(), " err ", err)
	quit()

func _build(graph_name: String, entries: Dictionary) -> VSMData:
	var data := VSMData.new()
	data.graph_name = graph_name
	var talkers: Array[String] = []
	var row := 0
	for entry_name: String in entries:
		var y := float(row) * 260.0
		var col := 0
		var entry := VSMEntryNodeData.new()
		entry.id = data.allocate_id()
		entry.entry_name = entry_name
		entry.graph_position = Vector2(0, y)
		data.add_node(entry)
		data.occurrences.append(entry_name)
		# nodes waiting for their next step: [node, exit label, actions]
		var open: Array = [[entry, ""]]
		var steps: Array = entries[entry_name]
		var exit_name := "done"
		var choice_exits: Array = []   # [reply node, exit name] when a choice ends the entry
		for step in steps:
			if step is Dictionary and (step as Dictionary).has("exit"):
				exit_name = String(step["exit"])
				continue
			if step is Dictionary and (step as Dictionary).has("choice"):
				col += 1
				var replies: Array = []
				var k := 0
				for ch: Array in step["choice"]:
					var reply := _line(data, String(ch[1]), String(ch[2]), Vector2(col * 340.0, y + k * 140.0), talkers)
					for o: Array in open:
						_link(o[0], reply, String(ch[0]))
					replies.append(reply)
					if ch.size() > 3:
						choice_exits.append([reply, String(ch[3])])
					k += 1
				open = []
				for r in replies:
					open.append([r, ""])
				continue
			col += 1
			var node := _line(data, String(step[0]), String(step[1]), Vector2(col * 340.0, y), talkers)
			for o: Array in open:
				_link(o[0], node, String(o[1]))
			open = [[node, ""]]
			choice_exits.clear()
		col += 1
		if not choice_exits.is_empty():
			# each answer ends the entry at its own exit
			var k := 0
			for ce: Array in choice_exits:
				var ex := _exit(data, String(ce[1]), Vector2(col * 340.0, y + k * 140.0))
				_link(ce[0], ex, "")
				if not data.endings.has(ex.exit_name):
					data.endings.append(ex.exit_name)
				k += 1
		else:
			var ex := _exit(data, exit_name, Vector2(col * 340.0, y))
			for o: Array in open:
				_link(o[0], ex, String(o[1]))
			if not data.endings.has(exit_name):
				data.endings.append(exit_name)
		row += 1
	data.talkers = talkers
	if not data.occurrences.is_empty():
		data.default_occurrence = data.occurrences[0]
	return data

func _line(data: VSMData, speaker: String, text: String, pos: Vector2, talkers: Array[String]) -> VSMDialogueNodeData:
	var n := VSMDialogueNodeData.new()
	n.id = data.allocate_id()
	n.text = text
	n.graph_position = pos
	if speaker != NARRATOR:
		var t := VSMTalkerModifier.new()
		t.talker = speaker
		n.modifiers.append(t)
		if not talkers.has(speaker):
			talkers.append(speaker)
	data.add_node(n)
	return n

func _exit(data: VSMData, exit_name: String, pos: Vector2) -> VSMExitNodeData:
	var e := VSMExitNodeData.new()
	e.id = data.allocate_id()
	e.exit_name = exit_name
	e.graph_position = pos
	data.add_node(e)
	return e

func _link(from: VSMNodeData, to: VSMNodeData, label: String) -> void:
	var link := VSMExitLink.new()
	link.target_id = to.id
	link.label = label
	(from.get("exits") as Array).append(link)
