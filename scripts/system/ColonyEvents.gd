class_name ColonyEvents
extends RefCounted
## Monthly incidents. The cursor, open decisions and delayed outcomes live in the save slot.

const STATE := "colony_events"
const EVENTS_CSV := "res://resources/narrative/colony_events.csv"
const VOICES_CSV := "res://resources/narrative/colony_event_advisors.csv"
const MINOR_WAIT := 6
const MAJOR_WAIT := 24
const MAX_OFFLINE_MINOR := 3
const SAFE_TO_LOSE := ["commercial", "lab", "harbor_market", "lakeside_market", "volcanic_market"]
const REWARDS := {"credits": Vector2i(100, 200), "science": Vector2i(30, 60),
	"ferrite": Vector2i(30, 60), "goods": Vector2i(12, 24)}

static var _definitions: Dictionary = {}
static var _voices: Dictionary = {}
static var _content_loaded := false

static func _month() -> int:
	return floori(GameState.calendar_seconds / GameState.MONTH_SEC)

static func _eligible() -> bool:
	return not GameState.showcase_mode and GameState.onboarding_stage == "done" \
		and not ColonyTutorial.active() and GameState.has_founded_city()

static func _state(first_month: int) -> Dictionary:
	if not GameState.story_flags.has(STATE):
		GameState.story_flags[STATE] = {"month": first_month, "last_minor": first_month,
			"last_major": first_month, "minor": {}, "major": {}, "followups": [], "recovery": {}}
	return GameState.story_flags[STATE]

static func tick(present: bool) -> void:
	var scene := GameState.get_tree().current_scene
	if scene == null or scene.scene_file_path.ends_with("MainMenu.tscn") or GameState.offline_pending or not _eligible():
		return
	var state := _state(_month())
	_advance(state, _month())
	if present and not has_welcome():
		_present_next(state)

## Called on actual simulated calendar boundaries. Minor effects can feed the next
## economy cycle. Major consequences always wait for an answer in the dialogue panel.
static func advance_offline(from_month: int, to_month: int, reports: Array) -> void:
	if to_month <= from_month or not _eligible():
		return
	var state := _state(from_month)
	_advance(state, to_month, reports)

static func _advance(state: Dictionary, through_month: int, reports: Variant = null) -> void:
	if through_month <= int(state["month"]):
		return
	_load_content()
	var offline := reports is Array
	for month in range(int(state["month"]) + 1, through_month + 1):
		state["month"] = month
		var rng := _rng(month, "calendar")
		var major_wait := month - int(state["last_major"])
		if (state["major"] as Dictionary).is_empty() and major_wait >= MAJOR_WAIT:
			var chance := minf(0.08, 0.03 + (major_wait - MAJOR_WAIT) * 0.002)
			if rng.randf() < chance:
				var major := _pick_major(state, month, rng)
				if not major.is_empty():
					major["due"] = month if offline else month + rng.randi_range(2, 5)
					state["major"] = major
					state["last_major"] = month
		var minor_wait := month - int(state["last_minor"])
		if minor_wait < MINOR_WAIT:
			continue
		if (offline and reports.size() >= MAX_OFFLINE_MINOR) \
			or (not offline and not (state["minor"] as Dictionary).is_empty()):
			continue
		if rng.randf() >= minf(0.20, 0.05 + (minor_wait - MINOR_WAIT) * 0.01):
			continue
		var pool := _available_definitions(state, "minor")
		if pool.is_empty():
			continue
		var event := {"id": pool[rng.randi_range(0, pool.size() - 1)], "month": month}
		state["last_minor"] = month
		if offline:
			reports.append(_resolve_minor(state, event, "", true))
		else:
			state["minor"] = event

static func _pick_major(state: Dictionary, month: int, rng: RandomNumberGenerator) -> Dictionary:
	var choices: Array[Dictionary] = []
	for id: String in _available_definitions(state, "major"):
		var def: Dictionary = _definitions[id]
		for pp: PlanetProgress in GameState._planet_progress.values():
			if not pp.is_colonized:
				continue
			var pd := GameState.get_planet_data(pp.planet_seed)
			if pd == null or pd.planet_type == PlanetData.Type.MOON:
				continue
			if def["scope"] == "planet":
				var event := {"id": id, "month": month, "seed": pp.planet_seed, "place": pd.planet_name}
				if not _damage_targets(event).is_empty():
					choices.append(event)
			elif def["scope"] == "coastal_city":
				for poi: POIData in pd.custom_pois:
					if not poi.constructing and poi.coastal and poi.is_city() and not poi.is_orbital():
						var event := {"id": id, "month": month, "seed": pp.planet_seed,
							"city": poi.label, "place": poi.shown_name()}
						if not _damage_targets(event).is_empty():
							choices.append(event)
	return {} if choices.is_empty() else choices[rng.randi_range(0, choices.size() - 1)]

static func _available_definitions(state: Dictionary, kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in _definitions:
		if _definitions[id]["kind"] != kind:
			continue
		var in_progress := false
		for followup: Dictionary in state["followups"]:
			if String(followup["id"]) == id:
				in_progress = true
				break
		if not in_progress:
			ids.append(id)
	return ids

static func _present_next(state: Dictionary) -> void:
	_load_content()
	var major: Dictionary = state["major"]
	if not major.is_empty():
		if int(major["due"]) <= _month():
			_present_major(state, major)
			return
		if not bool(major.get("warned", false)):
			var scene_id := _scene_id(major) + ":warning"
			if Narrative.play("", "warning", {"id": scene_id, "once": false,
				"lines": [["", _line(major, "warning")]],
				"on_done": func(_exit: String) -> void:
					major["warned"] = true
					GameState.save()}):
				GameState.save()
			return
	for followup: Dictionary in state["followups"]:
		if int(followup["due"]) <= _month():
			_present_followup(state, followup)
			return
	var minor: Dictionary = state["minor"]
	if not minor.is_empty():
		_present_minor(state, minor)

static func _present_minor(state: Dictionary, event: Dictionary) -> void:
	if Narrative.play("", "minor", {"id": _scene_id(event), "once": false, "main": true, "pause": true,
		"lines": [["", _line(event, "briefing")]],
		"choices": func() -> Array: return _minor_choices(event),
		"on_done": func(answer: String) -> void:
			var result := _resolve_minor(state, event, answer, false)
			Narrative.play("", "result", {"id": _scene_id(event) + ":result", "once": false,
				"lines": [["", result]]})
			GameState.save()}):
		GameState.save()

static func _minor_choices(event: Dictionary) -> Array:
	var def: Dictionary = _definitions[event["id"]]
	var choices: Array = []
	for side: String in ["a", "b"]:
		var rewards := _reward_pool(String(def["pool_" + side]), "credits" if side == "a" else "science")
		var descriptions: PackedStringArray = []
		for id: String in rewards:
			var band: Vector2i = rewards[id]
			descriptions.append("%d–%d %s" % [band.x, band.y, Economy.display_name(id)])
		choices.append({"id": side, "label": def["choice_" + side],
			"tip": "Receive one of these rewards. " + " or ".join(descriptions) + "."})
	return choices

static func _resolve_minor(state: Dictionary, event: Dictionary, answer: String, offline: bool) -> String:
	var rng := _rng(int(event["month"]), String(event["id"]))
	var side := ("a" if rng.randi_range(0, 1) == 0 else "b") if offline else answer
	var def: Dictionary = _definitions[event["id"]]
	var rewards := _reward_pool(String(def["pool_" + side]), "credits" if side == "a" else "science")
	var ids := rewards.keys()
	var id := String(ids[rng.randi_range(0, ids.size() - 1)])
	var band: Vector2i = rewards[id]
	var gain := _award(id, rng.randi_range(band.x, band.y))
	var stage := ("offline_" if offline else "result_") + side
	var report := _line(event, stage, {"reward": Narrative.amounts_text(gain)})
	if not offline:
		state["minor"] = {}
	Narrative.log_event(Narrative.amounts_text(gain), _scene_id(event))
	return report

static func _reward_pool(pool: String, fallback: String) -> Dictionary:
	var eligible := {}
	for id: String in pool.split("|", false):
		if not REWARDS.has(id) or (id == "ferrite" and not Economy.is_mineral_discovered(id)) \
			or (id == "goods" and not bool(GameState.story_flags.get("made:goods", false))
			and Economy.amount(id) <= 0.0):
			continue
		var band: Vector2i = REWARDS[id]
		if Economy.is_capped(id):
			band.y = mini(band.y, floori(Economy.cap(id) - Economy.amount(id)))
		if band.y >= band.x:
			eligible[id] = band
	if eligible.is_empty():
		eligible[fallback] = REWARDS[fallback]
	return eligible

static func _present_major(state: Dictionary, event: Dictionary) -> void:
	if Narrative.play("", "crisis", {"id": _scene_id(event), "once": false,
		"lines": [["", _line(event, "briefing")]],
		"choices": func() -> Array: return _major_choices(event),
		"on_done": func(answer: String) -> void: _resolve_major(state, event, answer)}):
		GameState.save()

static func _major_choices(event: Dictionary) -> Array:
	var def: Dictionary = _definitions[event["id"]]
	var aid := _cost(def)
	var missing := Economy.cost_block(aid)
	var mitigation := String(def["mitigation_tip"])
	if not aid.is_empty():
		mitigation += " Spend " + Narrative.amounts_text(aid).replace("+", "") + "."
	var months := int(def["power_months"])
	if months > 0:
		mitigation += " Energy output on %s falls by %d%% for %d colony months." % [
			event["place"], roundi((1.0 - _power_factor(def)) * 100.0), months]
	if missing != "":
		mitigation += " " + missing + "."
	var names: PackedStringArray = []
	for target: Dictionary in _damage_targets(event):
		names.append(String(target["name"]))
	var loss := "No eligible buildings remain in the affected area." if names.is_empty() \
		else "Permanently lose " + ", ".join(names) + "."
	var ready := ProductionManager.has_running_facility("emergency_response_center")
	var emergency_tip := "Prevent the damage. Total energy demand rises by 20% for one colony month."
	if not ready:
		emergency_tip += " Requires an operating Emergency Response Center."
	return [{"id": "a", "label": def["choice_a"], "tip": mitigation, "enabled": missing == ""},
		{"id": "b", "label": def["choice_b"], "tip": loss},
		{"id": "emergency", "label": "Use emergency power", "tip": emergency_tip, "enabled": ready}]

static func _resolve_major(state: Dictionary, event: Dictionary, answer: String) -> void:
	var def: Dictionary = _definitions[event["id"]]
	var result := ""
	var result_tokens := {}
	match answer:
		"emergency":
			if not GameState.start_emergency_response():
				return
			result = "The emergency crews contained the damage. Total energy demand is 20% higher for one month."
		"a":
			var cost := _cost(def)
			if not Economy.pay(cost):
				return
			var months := int(def["power_months"])
			if months > 0:
				(state["recovery"] as Dictionary)[str(event["seed"])] = {
					"until": GameState.calendar_seconds + months * GameState.MONTH_SEC,
					"factor": _power_factor(def)}
			result = _line(event, "result_a")
		"b":
			var lost: PackedStringArray = []
			var pp := GameState.find_planet(int(event["seed"]))
			for target: Dictionary in _damage_targets(event):
				if Settlement.destroy_incident_building(pp, target["entry"]):
					lost.append(String(target["name"]))
			result = "We lost " + ", ".join(lost) + "." if not lost.is_empty() \
				else "The crews found no damaged buildings still standing in the affected area."
			result_tokens["lost_buildings"] = ", ".join(lost)
		_:
			return
	state["major"] = {}
	state["last_major"] = _month()
	var followup := event.duplicate()
	followup["answer"] = answer
	followup["decided_month"] = _month()
	followup["outcome"] = result_tokens
	followup["due"] = _month() + _rng(int(event["month"]), String(event["id"])).randi_range(24, 48)
	(state["followups"] as Array).append(followup)
	Narrative.log_event(result, _scene_id(event))
	var report := _line(event, "result_" + answer, result_tokens, result)
	Narrative.play("", "result", {"id": _scene_id(event) + ":result", "once": false,
		"lines": [["", report]]})
	GameState.save()

static func _present_followup(state: Dictionary, event: Dictionary) -> void:
	var def: Dictionary = _definitions[event["id"]]
	var answer := String(event["answer"])
	var reward_id := String(def["followup_resource"])
	var reward := int(def["followup_" + answer])
	var tokens: Dictionary = (event.get("outcome", {}) as Dictionary).duplicate()
	tokens["reward"] = Narrative.amounts_text({reward_id: reward}) if reward > 0 else ""
	var scene_id := _scene_id(event) + ":followup"
	Narrative.play("", "followup", {"id": scene_id, "once": false,
		"lines": [["", _line(event, "followup_text_" + answer, tokens)]],
		"on_done": func(_exit: String) -> void:
			(state["followups"] as Array).erase(event)
			if reward > 0:
				Narrative.log_event(Narrative.amounts_text(_award(reward_id, reward)), scene_id)
			GameState.save()})

## Limit permanent damage to replaceable structures. Protect all power, housing,
## refining, storage, travel and unlock buildings, even if they share the district.
static func _damage_targets(event: Dictionary) -> Array[Dictionary]:
	var seed := int(event["seed"])
	var city := String(event.get("city", ""))
	var pp := GameState.find_planet(seed)
	var pd := GameState.get_planet_data(seed)
	var candidates: Array[Dictionary] = []
	if pp == null or pd == null:
		return candidates
	for entry: Dictionary in pp.buildings:
		if bool(entry.get("constructing", false)) or not String(entry.get("building_id", "")) in SAFE_TO_LOSE:
			continue
		var poi := ProductionManager.district_at(pd, String(entry.get("district_id", "")))
		if poi == null or poi.is_orbital() or poi.is_city():
			continue
		if city != "" and (poi.parent_city != city or not poi.coastal):
			continue
		var def := BuildingDef.find(String(entry["building_id"]))
		if def != null:
			candidates.append({"entry": entry, "name": "%s (%s)" % [def.display_name, poi.shown_name()]})
	var chosen: Array[Dictionary] = []
	var rng := _rng(int(event["month"]), "damage:" + String(event["id"]))
	for i in mini(candidates.size(), rng.randi_range(1, 2)):
		var at := rng.randi_range(0, candidates.size() - 1)
		chosen.append(candidates.pop_at(at))
	return chosen

static func _cost(def: Dictionary) -> Dictionary:
	var amounts := {}
	for pair: String in String(def["cost"]).split("|", false):
		var parts := pair.split("=", false, 1)
		if parts.size() == 2:
			amounts[parts[0]] = int(parts[1])
	return amounts

static func _power_factor(def: Dictionary) -> float:
	return clampf(float(def["power_factor"]), 0.01, 1.0)

static func energy_factor(seed: int) -> float:
	var state: Dictionary = GameState.story_flags.get(STATE, {})
	var recovery: Dictionary = state.get("recovery", {})
	var effect: Dictionary = recovery.get(str(seed), {})
	if GameState.calendar_seconds >= float(effect.get("until", 0.0)):
		return 1.0
	return float(effect["factor"])

static func _award(id: String, amount: int) -> Dictionary:
	var before := Economy.amount(id)
	Economy.add(id, amount)
	return {id: Economy.amount(id) - before}

static func _rng(month: int, purpose: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = ("%d:%d:%s" % [GameState.home_planet_seed, month, purpose]).hash()
	return rng

static func _scene_id(event: Dictionary) -> String:
	return "colony_event:%s:%d" % [event["id"], event["month"]]

static func _line(event: Dictionary, stage: String, tokens: Dictionary = {}, fallback := "") -> String:
	var id := String(event["id"])
	var key := "%s:%s:%s" % [id, stage, GameState.active_advisor]
	var def: Dictionary = _definitions[id]
	var phrase := String(_voices.get(key, def.get(stage, "")))
	if phrase.is_empty():
		phrase = fallback
	var replacements := tokens.duplicate()
	replacements["place"] = String(event.get("place", "the colony"))
	return phrase.format(replacements)

static func has_welcome() -> bool:
	return GameState.story_flags.has("colony_welcome")

static func remember_welcome(gains: Dictionary, reports: Array) -> void:
	var prior: Dictionary = GameState.story_flags.get("colony_welcome", {})
	var combined: Dictionary = prior.get("gains", {})
	for id: String in gains:
		combined[id] = float(combined.get(id, 0.0)) + float(gains[id])
	var combined_reports: Array = prior.get("reports", [])
	combined_reports.append_array(reports)
	GameState.story_flags["colony_welcome"] = {"gains": combined, "reports": combined_reports}

static func present_welcome() -> void:
	var saved: Dictionary = GameState.story_flags.get("colony_welcome", {})
	if saved.is_empty():
		return
	var gains := Narrative.amounts_text(saved["gains"])
	var opening := "Welcome back. Here's where we stand since you left."
	var lines := [["", opening]]
	for report: String in saved["reports"]:
		lines.append(["", report])
	lines.append(["", "Here's what the ledgers show. " + gains + "." if gains != ""
		else "Our stores are at the same levels as when you left."])
	var state: Dictionary = GameState.story_flags.get(STATE, {})
	var major: Dictionary = state.get("major", {})
	if not major.is_empty() and int(major["due"]) <= _month():
		lines.append(["", "There's one decision I held for you. I'll brief you now."])
	Narrative.play("", "welcome", {"id": "colony_welcome", "once": false, "lines": lines,
		"on_done": func(_exit: String) -> void:
			GameState.story_flags.erase("colony_welcome")
			GameState.save()})

static func _load_content() -> void:
	if _content_loaded:
		return
	_content_loaded = true
	for row: Dictionary in _csv_rows(EVENTS_CSV):
		_definitions[row["id"]] = row
	for row: Dictionary in _csv_rows(VOICES_CSV):
		if not String(row["line"]).is_empty():
			_voices["%s:%s:%s" % [row["event_id"], row["stage"], row["advisor_id"]]] = row["line"]

static func _csv_rows(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return rows
	var headers := file.get_csv_line()
	while file.get_position() < file.get_length():
		var fields := file.get_csv_line()
		if fields.size() != headers.size() or fields[0].is_empty():
			continue
		var row := {}
		for i in headers.size():
			row[headers[i]] = fields[i]
		rows.append(row)
	return rows
