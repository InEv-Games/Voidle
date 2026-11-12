## Narrative — autoload. Plays the story's VSM graphs (docs/design/narrative) in
## the bottom dialogue panel (DialoguePanel), one at a time, and keeps the
## Narrative Log.
##
##   Narrative.play("res://resources/narrative/opening.tres", "intro",
##       {"id": "opening_intro", "on_done": func(exit_name): ...})
##
## opts:
##   "id"      scene id for the log and for "once" (default "<graph>:<entry>")
##   "main"    true (default): a story scene. The game pauses and the map takes
##             no input until it ends; it waits while a popup or a placement is
##             open. false: a short line (a tutorial hint, a comment): the game
##             runs on and the map stays usable.
##   "pause"   default = "main": pause the game while it plays (false keeps the
##             world turning behind a main scene, e.g. the opening)
##   "once"    true (default): a scene that played to its end never plays again
##             (GameState.completed_scenes)
##   "on_done" Callable(exit_name: String), called when the scene ends
##   "now"     the player asked for it (a button): it starts at once, ahead of
##             the queue and the waits; a short line on screen gives way to it
##
## Main scenes go before short lines in the queue. Reading the log never runs a
## scene again or pays anything twice. A scene left half-way (the game closed)
## starts again from its entry next time; its log lines stay.
extends Node

signal scene_started(scene_id: String)
signal scene_finished(scene_id: String, exit_name: String)
signal log_changed   # an entry was added to the Narrative Log (an open log follows)

const LAYER := 233   # over the news bar (229) and the HUD (230), under popups (235+)
const LOG_MAX := 600

## Who speaks with which face. Speakers not listed (Narrator, I-330 Archive,
## Player …) show no portrait. Bolo keeps her face before she names herself.
const PORTRAITS := {
	"Mother Superior": "res://resources/companions/portraits/mother_superior.png",
	"High Father": "res://resources/companions/portraits/high_father.png",
	"Bolo": "res://resources/companions/portraits/bolo.png",
	"Unknown Woman": "res://resources/companions/portraits/bolo.png",
	"Burkai": "res://resources/companions/portraits/burkai.png",
}

var _queue: Array = []          # of { graph, entry, id, main, once, on_done }
var _current: Dictionary = {}
var _mgr: VSMManager = null
var _layer: CanvasLayer = null
var _blocker: Control = null
var _panel: DialoguePanel = null
var _was_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# back to the main menu: what was on screen or waiting belongs to the game left
	get_tree().root.child_entered_tree.connect(func(n: Node) -> void:
		if n.scene_file_path.ends_with("MainMenu.tscn"):
			reset())

## Queues a scene; false when it was skipped (a "once" scene already done, or
## the same scene already waiting).
func play(graph_path: String, entry: String, opts: Dictionary = {}) -> bool:
	var id := String(opts.get("id", "%s:%s" % [graph_path.get_file().get_basename(), entry]))
	var once := bool(opts.get("once", true))
	if once and GameState.completed_scenes.has(id):
		return false
	if String(_current.get("id", "")) == id:
		return false
	for q: Dictionary in _queue:
		if String(q["id"]) == id:
			return false
	var main := bool(opts.get("main", true))
	var item := {"graph": graph_path, "entry": entry, "id": id, "main": main,
		"pause": bool(opts.get("pause", main)), "once": once, "on_done": opts.get("on_done", Callable()),
		"now": bool(opts.get("now", false)), "lines": opts.get("lines", []),
		"skippable": bool(opts.get("skippable", false))}
	if item["now"]:
		if not _current.is_empty() and not bool(_current["main"]):
			_end_scene("", true)   # a short line gives way (it stays in the log)
		_queue.push_front(item)
	elif item["main"]:
		# before every short line, after the main scenes already waiting
		var at := 0
		while at < _queue.size() and bool(_queue[at]["main"]):
			at += 1
		_queue.insert(at, item)
	else:
		_queue.append(item)
	return true

## A scene is on screen.
func is_busy() -> bool:
	return not _current.is_empty()

## The dialogue panel is on screen and takes the arrows / Tab / Enter / Space.
func owns_keys() -> bool:
	return _panel != null and is_instance_valid(_panel) and _panel.owns_keys()

## A main scene is on screen (the game is paused for it).
func is_main_scene() -> bool:
	return not _current.is_empty() and bool(_current["main"])

func has_played(scene_id: String) -> bool:
	return GameState.completed_scenes.has(scene_id)

## Drops what is queued and closes what is on screen (a new game, a load).
func reset() -> void:
	_queue.clear()
	if not _current.is_empty():
		_end_scene("", false)

var _waited := 0.0

func _process(delta: float) -> void:
	if not _current.is_empty() or _queue.is_empty():
		_waited = 0.0
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path.ends_with("MainMenu.tscn"):
		return   # never over the menu
	var next: Dictionary = _queue[0]
	if bool(next["main"]) and not bool(next.get("now", false)) and not _can_present_main():
		_waited += delta
		if _waited > 5.0:
			_waited = -1e9   # once per wait
			push_warning("[Narrative] '%s' waits: %s" % [next["id"], _wait_reason()])
		return
	_waited = 0.0
	_queue.pop_front()
	_begin(next)

## Main scenes wait while the player is busy with something that has to finish:
## a popup, a placement or its naming, a scene change.
func _can_present_main() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	if scene.get("_placing_def") != null or bool(scene.get("_naming_open")):
		return false
	for n in get_tree().get_nodes_in_group(&"story_dialog"):   # an excavation card still open
		if n is Control and (n as Control).is_visible_in_tree():
			return false
	for n in get_tree().root.get_children():
		if n is CanvasLayer:
			for c in n.get_children():
				if c is ModalPopup and (c as Control).visible:
					return false
	return true

## What keeps a main scene waiting (for the warning above).
func _wait_reason() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return "no scene"
	if scene.get("_placing_def") != null:
		return "placing"
	if bool(scene.get("_naming_open")):
		return "naming"
	for n in get_tree().get_nodes_in_group(&"story_dialog"):
		if n is Control and (n as Control).is_visible_in_tree():
			return "story dialog %s" % n.get_path()
	for n in get_tree().root.get_children():
		if n is CanvasLayer:
			for c in n.get_children():
				if c is ModalPopup and (c as Control).visible:
					return "popup %s" % c.get_path()
	return "?"

## Plain lines without a graph (opts "lines": [[speaker, text], …]), e.g. the
## Guide's steps; they go one by one on CONTINUE.
var _line_i := -1

func _show_plain_line() -> void:
	var lines: Array = _current["lines"]
	var l: Array = lines[_line_i]
	_on_line(String(l[0]), String(l[1]))

func _begin(item: Dictionary) -> void:
	if not (item.get("lines", []) as Array).is_empty():
		_current = item
		_ensure_ui(bool(item["main"]))
		if bool(item["pause"]):
			_was_paused = get_tree().paused
			get_tree().paused = true
		scene_started.emit(String(item["id"]))
		_line_i = 0
		_show_plain_line()
		return
	var graph := load(String(item["graph"])) as VSMData
	if graph == null:
		push_warning("[Narrative] graph not found: %s" % item["graph"])
		return
	_current = item
	_ensure_ui(bool(item["main"]))
	if bool(item["pause"]):
		_was_paused = get_tree().paused
		get_tree().paused = true
	_mgr = VSMManager.new()
	_mgr.blackboard = {}
	_mgr.dialogue_shown.connect(_on_line)
	_mgr.choices_shown.connect(_on_choices)
	_mgr.story_finished.connect(func(exit_name: String) -> void: _end_scene(exit_name, true))
	scene_started.emit(String(item["id"]))
	_mgr.start(graph, String(item["entry"]))

func _ensure_ui(main: bool) -> void:
	if _layer == null or not is_instance_valid(_layer):
		_layer = CanvasLayer.new()
		_layer.layer = LAYER
		_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().root.add_child(_layer)
		_blocker = ColorRect.new()
		(_blocker as ColorRect).color = Color(0, 0, 0, 0.25)
		_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_blocker.mouse_filter = Control.MOUSE_FILTER_STOP   # the map takes no input in a story scene
		_layer.add_child(_blocker)
		_panel = DialoguePanel.create()
		_layer.add_child(_panel)
		_panel.advance_requested.connect(func() -> void:
			if _mgr != null:
				_mgr.advance()
			elif not _current.is_empty() and not (_current.get("lines", []) as Array).is_empty():
				_line_i += 1
				if _line_i < (_current["lines"] as Array).size():
					_show_plain_line()
				else:
					_end_scene("", true))
		_panel.choice_made.connect(_on_choice_made)
		_panel.log_requested.connect(open_log)
		_panel.skip_requested.connect(func() -> void:
			if not _current.is_empty() and bool(_current.get("skippable", false)):
				_end_scene("", true))
	_blocker.visible = main
	_panel.show_panel()
	_panel.set_skippable(bool(_current.get("skippable", false)))

func _on_line(speaker: String, text: String) -> void:
	_log("line", speaker, text)
	_panel.show_line(speaker, text, portrait_for(speaker))

func _on_choices(texts: Array[String]) -> void:
	_panel.show_choices(texts)

func _on_choice_made(index: int, text: String) -> void:
	_log("choice", "Player", text)
	if _mgr != null:
		_mgr.choose(index)

func _end_scene(exit_name: String, completed: bool) -> void:
	var item := _current
	_current = {}
	_mgr = null
	if bool(item.get("pause", false)):
		get_tree().paused = _was_paused
	if _panel != null and is_instance_valid(_panel):
		_panel.hide_panel()
	if _blocker != null and is_instance_valid(_blocker):
		_blocker.visible = false
	if completed and bool(item.get("once", true)):
		GameState.completed_scenes[String(item["id"])] = true
	scene_finished.emit(String(item.get("id", "")), exit_name)
	var cb: Callable = item.get("on_done", Callable())
	if completed and cb.is_valid():
		cb.call(exit_name)

func _log(kind: String, speaker: String, text: String) -> void:
	_append(String(_current.get("id", "")), kind, speaker, text)

## A line ("line") or an answer ("choice", speaker "Player") shown somewhere
## else than the dialogue panel (an excavation's story), into the log under
## `scene` (for an excavation, its site id).
func log_line(scene: String, speaker: String, text: String, kind := "line") -> void:
	_append(scene, kind, speaker, text)

## What the story did in the game, written in the log as it happened: what a
## reward paid, who joined, who was appointed. Under `scene`, or the scene on
## screen, or (between two scenes) the one logged last.
func log_event(text: String, scene := "") -> void:
	if scene == "":
		scene = String(_current.get("id", ""))
	if scene == "" and not GameState.narrative_log.is_empty():
		scene = String((GameState.narrative_log.back() as Dictionary).get("s", ""))
	_append(scene, "event", "", text)

## "+500 Credits, +40 Science": what a reward paid, for log_event.
static func amounts_text(amounts: Dictionary) -> String:
	var parts: Array[String] = []
	for id: String in amounts:
		var v := float(amounts[id])
		if absf(v) > 0.0001:
			parts.append("%s%s %s" % ["+" if v > 0.0 else "", Economy.fmt(v), Economy.display_name(id)])
	return ", ".join(parts)

func _append(scene: String, kind: String, speaker: String, text: String) -> void:
	GameState.narrative_log.append({"s": scene, "k": kind, "n": speaker, "t": text})
	while GameState.narrative_log.size() > LOG_MAX:
		GameState.narrative_log.pop_front()
	log_changed.emit()

static func portrait_for(speaker: String) -> Texture2D:
	var path := String(PORTRAITS.get(speaker, ""))
	return load(path) as Texture2D if path != "" and ResourceLoader.exists(path) else null

## The Narrative Log: what was shown, oldest first, newest at the bottom.
var _log_popup: ModalPopup = null

## Opens the Narrative Log, or closes it when it is open (LOG, L: a toggle).
func open_log() -> void:
	if _log_popup != null and is_instance_valid(_log_popup) and _log_popup.is_inside_tree():
		_log_popup.close()
		_log_popup = null
		return
	_log_popup = NarrativeLog.show_log(self)
