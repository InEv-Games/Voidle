## PadScheme — Autoload controller chord & Quick Command Hub manager.
## Holds View / Select (JOY_BUTTON_BACK) as a chord modifier for instant global
## shortcuts (Select + Y/X/A/RB/LB/D-Pad/Start), or taps View / Select to toggle
## the visual Quick Command Hub popup.
extends Node

const HUB_LAYER := 244

var chord_held := false
var _chord_used := false
var _hub_open_on_press := false
var _move_queued := false
var _hub: ModalPopup = null
## Planet view: Select opens a radial Quick Command wheel instead of the grid hub.
var _radial: QuickRadial = null
var _radial_open_on_press := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := get_tree().root
	if root != null:
		root.child_entered_tree.connect(_on_root_child)
		_queue_move_last()

func _on_root_child(n: Node) -> void:
	if n != self:
		_queue_move_last()

func _queue_move_last() -> void:
	if _move_queued:
		return
	_move_queued = true
	_move_last.call_deferred()

func _move_last() -> void:
	_move_queued = false
	var p := get_parent()
	if p != null and p.get_child(p.get_child_count() - 1) != self:
		p.move_child(self, -1)

func is_hub_open() -> bool:
	return _hub != null and is_instance_valid(_hub)

func is_radial_open() -> bool:
	return _radial != null and is_instance_valid(_radial)

## True while Select is held or the radial wheel is up: views leave the sticks
## and triggers alone (no globe turn / panel nav under the wheel).
func sticks_captured() -> bool:
	return chord_held or is_radial_open()

func close_hub() -> void:
	if is_hub_open():
		_hub.close()
	_hub = null
	close_radial()

func close_radial() -> void:
	if is_radial_open():
		_radial.close()
	_radial = null

## The scene shows a radial wheel (it says where its centre is).
func _radial_scene() -> Node:
	var sc := get_tree().current_scene
	if sc != null and sc.has_method("pad_radial_center"):
		return sc
	return null

func _allowed() -> bool:
	var sc := get_tree().current_scene
	if sc == null or sc.scene_file_path.ends_with("MainMenu.tscn"):
		return false
	if get_tree().paused or GameState.showcase_mode:
		return false
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return false
	var dc := get_node_or_null("/root/DevConsole")
	if dc != null and bool(dc.get("_open")):
		return false
	return true

func _input(event: InputEvent) -> void:
	var jb := event as InputEventJoypadButton
	if jb == null:
		return

	# Track View / Select (JOY_BUTTON_BACK) chord state
	if jb.button_index == JOY_BUTTON_BACK:
		if jb.pressed:
			if ShortcutsHelp._popup != null and is_instance_valid(ShortcutsHelp._popup):
				AudioManager.play("click")
				ShortcutsHelp.toggle(HUDManager)
				get_viewport().set_input_as_handled()
				return
			if not _allowed():
				chord_held = false
				return
			chord_held = true
			_chord_used = false
			_hub_open_on_press = is_hub_open()
			_radial_open_on_press = is_radial_open()
			if not _radial_open_on_press and _radial_scene() != null and not Narrative.owns_keys():
				close_hub()
				open_radial()
			get_viewport().set_input_as_handled()
		else:
			var was_held := chord_held
			chord_held = false
			if was_held:
				get_viewport().set_input_as_handled()
				if is_radial_open() and not _chord_used:
					if _radial_open_on_press:
						AudioManager.play("click")
						close_radial()
					elif _radial.hovered_act() != "":
						_pick_radial(_radial.hovered_act())
					# else: a tap — the wheel stays pinned open (stick + A)
					return
				if not _chord_used and _allowed():
					if _hub_open_on_press and is_hub_open():
						AudioManager.play("click")
						close_hub()
					elif not Narrative.owns_keys():
						AudioManager.play("click")
						open_hub()
		return

	# Chord combination while View / Select is held
	if chord_held:
		if not jb.pressed:
			get_viewport().set_input_as_handled()
			return
		var act := _action_for_chord_button(jb.button_index)
		get_viewport().set_input_as_handled()
		if jb.button_index == JOY_BUTTON_B and is_radial_open():
			_chord_used = true
			AudioManager.play("click")
			close_radial()
			return
		if act != "":
			_chord_used = true
			close_hub()
			_run_action(act)
		return

	# Radial wheel pinned open: A picks, B closes, the hub's single-press
	# shortcuts still work; everything else is swallowed
	if is_radial_open():
		get_viewport().set_input_as_handled()
		if not jb.pressed:
			return
		match jb.button_index:
			JOY_BUTTON_A:
				if _radial.hovered_act() != "":
					_pick_radial(_radial.hovered_act())
				else:
					AudioManager.play("denied")
			JOY_BUTTON_B:
				AudioManager.play("click")
				close_radial()
			_:
				var r_act := _action_for_chord_button(jb.button_index)
				if r_act != "" and r_act != "companions":
					close_radial()
					_run_action(r_act)
		return

	# Quick single-press shortcuts while the Quick Command Hub is pinned open
	if is_hub_open() and jb.pressed:
		var hub_act := ""
		match jb.button_index:
			JOY_BUTTON_Y:              hub_act = "tree"
			JOY_BUTTON_X:              hub_act = "trade"
			JOY_BUTTON_RIGHT_SHOULDER: hub_act = "inbox"
			JOY_BUTTON_LEFT_SHOULDER:  hub_act = "cycle_body"
			JOY_BUTTON_START:          hub_act = "shortcuts_help"
		if hub_act != "":
			get_viewport().set_input_as_handled()
			close_hub()
			_run_action(hub_act)

func _action_for_chord_button(btn: JoyButton) -> String:
	match btn:
		JOY_BUTTON_Y:              return "tree"
		JOY_BUTTON_X:              return "trade"
		JOY_BUTTON_A:              return "companions"
		JOY_BUTTON_RIGHT_SHOULDER: return "inbox"
		JOY_BUTTON_LEFT_SHOULDER:  return "cycle_body"
		JOY_BUTTON_DPAD_UP:        return "top_bar"
		JOY_BUTTON_DPAD_DOWN:      return "news"
		JOY_BUTTON_DPAD_LEFT:      return "nav_back"
		JOY_BUTTON_DPAD_RIGHT:     return "nav_forward"
		JOY_BUTTON_START:          return "shortcuts_help"
	return ""

func _run_action(act: String) -> void:
	if Narrative.owns_keys() and act != "shortcuts_help":
		AudioManager.play("denied")
		return
	match act:
		"tree":
			if not HUDManager.shortcut_open("tree"):
				AudioManager.play("denied")
				return
			HUDManager.press_shortcut("tree")
		"trade":
			if not HUDManager.shortcut_open("trade"):
				AudioManager.play("denied")
				return
			HUDManager.press_shortcut("trade")
		"companions":
			if not HUDManager.shortcut_open("companions"):
				AudioManager.play("denied")
				return
			HUDManager.press_shortcut("companions")
		"inbox":
			if SkillTreeView.is_open:
				HUDManager.call("_try_close_skill_tree")
			Inbox.toggle()
		"cycle_body":
			_cycle_celestial_body()
		"top_bar":
			if SkillTreeView.is_open:
				HUDManager.call("_try_close_skill_tree")
			var rb = HUDManager.get("credits_panel")
			if rb != null and is_instance_valid(rb):
				AudioManager.play("click")
				rb.call("start_browsing")
		"news":
			if SkillTreeView.is_open:
				HUDManager.call("_try_close_skill_tree")
			AudioManager.play("click")
			NewsFeed.start_browsing()
		"nav_back":
			if SkillTreeView.is_open:
				HUDManager.call("_try_close_skill_tree")
			NavigationManager.back()
		"nav_forward":
			if SkillTreeView.is_open:
				HUDManager.call("_try_close_skill_tree")
			NavigationManager.forward()
		"shortcuts_help":
			AudioManager.play("click")
			ShortcutsHelp.toggle(HUDManager)

func _cycle_celestial_body() -> void:
	if SkillTreeView.is_open:
		HUDManager.call("_try_close_skill_tree")
	var sc := get_tree().current_scene
	if sc != null and sc.has_method("cycle_celestial_body"):
		sc.call("cycle_celestial_body", 1)
		return
	var home := GameState.get_home_planet()
	if home != null:
		AudioManager.play("click")
		SceneTransition.go("res://scenes/planetary/PlanetaryView.tscn", home)

func open_hub() -> void:
	close_hub()
	var p := ModalPopup.open(HUDManager, "Quick Commands", "explore",
		"Hold Select + button anytime for instant access, or pick below.", HUB_LAYER)
	_hub = p
	(p.card.get_node("VBox/Buttons") as Control).visible = false

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 6)

	var add_cmd := func(badge: String, label: String, icon: String, enabled: bool, act: String) -> void:
		var b := IconButton.create("%s  %s" % [badge, label], icon, IconButton.Variant.DEFAULT)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = not enabled
		b.pressed.connect(func() -> void:
			p.close()
			_hub = null
			_run_action.call_deferred(act))
		grid.add_child(b)

	add_cmd.call("[Y]", "UPGRADE TREE", "research", HUDManager.shortcut_open("tree"), "tree")
	add_cmd.call("[X]", "TRADE", "trade", HUDManager.shortcut_open("trade"), "trade")
	add_cmd.call("[A]", "GOVERNMENT", "population", HUDManager.shortcut_open("companions"), "companions")
	add_cmd.call("[RB]", "NOTIFICATIONS", "flag", true, "inbox")
	add_cmd.call("[LB]", "NEXT WORLD / MOON", "planet", _can_cycle_body(), "cycle_body")
	var rb = HUDManager.get("credits_panel")
	add_cmd.call("[↑]", "TOP BAR", "explore", rb != null and is_instance_valid(rb), "top_bar")
	add_cmd.call("[↓]", "NEWS FEED", "notes", true, "news")
	add_cmd.call("[←]", "NAV BACK", "explore", true, "nav_back")
	add_cmd.call("[→]", "NAV FORWARD", "explore", true, "nav_forward")
	add_cmd.call("[START]", "SHORTCUTS (?)", "settings", true, "shortcuts_help")

	p.add_content(grid)
	p.closed.connect(func() -> void:
		if _hub == p:
			_hub = null)

## Eight of the hub's commands as wheel slices, clockwise from the top: top bar
## up, trade right, news down, upgrade tree left (nav back / forward stay on the D-pad chord).
func _command_entries() -> Array[Dictionary]:
	var rb = HUDManager.get("credits_panel")
	var e: Array[Dictionary] = []
	var add := func(act: String, label: String, badge: String, icon: String, enabled: bool) -> void:
		e.append({"act": act, "label": label, "badge": badge, "icon": icon, "enabled": enabled})
	add.call("top_bar", "TOP BAR", "↑", "explore", rb != null and is_instance_valid(rb))   # top
	add.call("inbox", "NOTIFICATIONS", "RB", "flag", true)
	add.call("trade", "TRADE", "X", "trade", HUDManager.shortcut_open("trade"))   # right
	add.call("companions", "GOVERNMENT", "A", "population", HUDManager.shortcut_open("companions"))
	add.call("news", "NEWS FEED", "↓", "notes", true)   # bottom
	add.call("shortcuts_help", "SHORTCUTS", "START", "settings", true)
	add.call("tree", "UPGRADE TREE", "Y", "research", HUDManager.shortcut_open("tree"))   # left
	add.call("cycle_body", "NEXT WORLD / MOON", "LB", "planet", _can_cycle_body())
	return e

func open_radial() -> void:
	close_radial()
	var sc := _radial_scene()
	var at: Vector2 = sc.call("pad_radial_center") if sc != null \
		else get_viewport().get_visible_rect().size * 0.5
	var r := QuickRadial.open(HUDManager, at, _command_entries(), HUB_LAYER)
	_radial = r
	r.picked.connect(func(act: String) -> void:
		if _radial == r:
			_pick_radial(act))
	r.dismissed.connect(func() -> void:
		if _radial == r:
			AudioManager.play("click")
			close_radial())

func _pick_radial(act: String) -> void:
	if not is_radial_open():
		return
	var ok := _radial.hovered_enabled()
	close_radial()
	if act == "":
		return
	if not ok:
		AudioManager.play("denied")
		return
	_run_action.call_deferred(act)

func _can_cycle_body() -> bool:
	var home := GameState.get_home_planet()
	if home == null or not GameState.can_view_moon():   # Lunar Program not yet
		return false
	var sc := get_tree().current_scene
	if sc == null or not sc.has_method("cycle_celestial_body"):
		return true
	return not home.moons.is_empty()
