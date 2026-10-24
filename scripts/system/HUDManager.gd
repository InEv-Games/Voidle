## Global HUD overlay — shows credits and other persistent info across all scenes.
extends CanvasLayer

var _credits_lbl: Label
var _science_lbl: Label
var _skill_btn: Button = null
var _skill_btn_tween: Tween = null
## Fraction of the screen width the game view occupies (left of the side panel).
## The energy readout stays centred on it; PlanetaryView animates it when the
## side panel slides in or out.
var view_area_fraction: float = 0.7
## Current displayed value (tweened, may lag behind GameState.credits)
var _credits_display: float = 0.0
var _credits_tween: Tween = null
var _science_display: float = 0.0
var _science_tween: Tween = null
var _orbitron: Font
## The credits panel node — exposed so PlanetaryView can read its screen height for toast offset.
## Top resource bar cells (Stellaris-style): id -> Label
var _res_lbls: Dictionary = {}
var _res_poll: float = 0.0
## id -> the cell, hidden until GameState reveals the resource
var _res_slots: Dictionary = {}
## id -> ResourceChip (scenes/ui/components/ResourceChip.tscn)
var _res_chips: Dictionary = {}
## Small superscript income/upkeep labels next to each value: id -> Label
var _rate_lbls: Dictionary = {}
## Raw resources dropdown under the "Raw ▾" cell (null when closed)
var _raw_dd: PanelContainer = null
var _raw_dd_list: VBoxContainer = null
var _raw_cell: Control = null
var credits_panel: PanelContainer = null
var science_panel: PanelContainer = null
var _top_layer: CanvasLayer = null
var _pause_overlay: CanvasLayer = null

func set_game_hud(visible_state: bool) -> void:
	visible = visible_state
	if is_instance_valid(_top_layer):
		_top_layer.visible = visible_state
static func fmt_credits(val: float) -> String:
	if val >= 1_000_000_000.0:
		return "%.2fb cr" % (val / 1_000_000_000.0)
	elif val >= 1_000_000.0:
		return "%.2fm cr" % (val / 1_000_000.0)
	elif val >= 1_000.0:
		return "%.1fk cr" % (val / 1_000.0)
	return "%.0f cr" % val

static func fmt_science(val: float) -> String:
	if val >= 1_000_000_000.0:
		return "%.2fB" % (val / 1_000_000_000.0)
	elif val >= 1_000_000.0:
		return "%.2fM" % (val / 1_000_000.0)
	elif val >= 1_000.0:
		return "%.1fK" % (val / 1_000.0)
	return "%.0f" % val

func _ready() -> void:
	layer = 226  # Energy above DevConsole (225), hidden when SkillTree opens
	process_mode = Node.PROCESS_MODE_ALWAYS
	_orbitron = load("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf")

	var panel := PanelContainer.new()
	panel.theme_type_variation = &"ResourceBar"   # voidle_theme.tres
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hbox)

	_add_res_cell(hbox, Economy.CREDITS, "◈", "Earned by Commercial districts. Spent on districts and buildings.", false)
	_credits_lbl = _res_lbls[Economy.CREDITS]

	# Skill Tree Button
	var skill_btn := IconButton.create("UPGRADE TREE", "research", IconButton.Variant.DEFAULT)
	skill_btn.mouse_filter = Control.MOUSE_FILTER_STOP

	_skill_btn = skill_btn
	TutorialManager.highlight_changed.connect(_on_tut_highlight)
	TutorialManager.highlight_cleared.connect(_on_tut_highlight_clear)

	skill_btn.pressed.connect(func() -> void:
		if TutorialManager._active and not TutorialManager._tutorial_done \
				and TutorialManager.get_action_step_type() != "skill":
			AudioManager.play("error")
			return
		AudioManager.play("click")
		var root := get_tree().root
		var existing_layer: CanvasLayer = null
		for child in root.get_children():
			if child is CanvasLayer:
				for gc in child.get_children():
					var sc = gc.get_script()
					if sc != null and sc.resource_path.ends_with("SkillTreeView.gd"):
						existing_layer = child as CanvasLayer
						break
			if existing_layer != null:
				break
		if existing_layer != null:
			CursorManager.set_state(CursorManager.State.NORMAL)
			
			# Find SkillTreeView to update its static state
			for gc in existing_layer.get_children():
				if gc.get_script() != null and gc.get_script().resource_path.ends_with("SkillTreeView.gd"):
					gc.set("is_open", false)
					break
					
			existing_layer.queue_free()
		else:
			var st_layer := CanvasLayer.new()
			st_layer.layer = 220
			var st_view = load("res://scripts/ui/SkillTreeView.gd").new()
			st_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			st_layer.add_child(st_view)
			root.add_child(st_layer))

		
	skill_btn.mouse_entered.connect(func() -> void:
		AudioManager.play("hover")
		CursorManager.set_state(CursorManager.State.POINTER)
		TooltipManager.show_tip("Upgrade Tree", "Research new buildings and upgrades with Science."))
	skill_btn.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
		
	# Anchor top-left
	panel.anchor_left   = 0.0
	panel.anchor_right  = 0.0
	panel.anchor_top    = 0.0
	panel.anchor_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_END
	panel.grow_vertical   = Control.GROW_DIRECTION_END
	panel.offset_left   = 0.0
	panel.offset_top    = 0.0
	# Allow mouse clicks on HUD panel buttons
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.mouse_filter = Control.MOUSE_FILTER_STOP

	# Credits + Science go into a top layer (above SkillTree at 220)
	var top_layer := CanvasLayer.new()
	top_layer.layer = 230
	_top_layer = top_layer
	get_parent().call_deferred("add_child", top_layer)

	top_layer.call_deferred("add_child", panel)
	credits_panel = panel

	var settings_btn := IconButton.create("", "settings", IconButton.Variant.DEFAULT)   # square, icon only
	settings_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	settings_btn.anchor_left = 1.0
	settings_btn.anchor_right = 1.0
	settings_btn.anchor_top = 0.0
	settings_btn.anchor_bottom = 0.0
	settings_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	settings_btn.grow_vertical = Control.GROW_DIRECTION_END
	settings_btn.offset_right = -4
	settings_btn.offset_top = 4
	
	settings_btn.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		AudioManager.play("hover"))
	settings_btn.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	settings_btn.pressed.connect(show_pause_menu)
	
	top_layer.call_deferred("add_child", settings_btn)


	# Upgrade Tree panel — bottom-right (the side panel holds the left)
	var sci_panel := PanelContainer.new()   # default PanelContainer look from the theme
	sci_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var sci_vbox := VBoxContainer.new()
	sci_vbox.add_theme_constant_override("separation", 6)
	sci_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sci_panel.add_child(sci_vbox)

	_add_res_cell(hbox, Economy.SCIENCE, "⬡", "Produced by Science districts. Spent in the Upgrade Tree.")
	_science_lbl = _res_lbls[Economy.SCIENCE]

	sci_vbox.add_child(skill_btn)
	sci_vbox.add_child(_make_trade_button())
	_explore_btn = _make_explore_button()
	sci_vbox.add_child(_explore_btn)
	_build_resource_cells(hbox)

	sci_panel.anchor_left   = 1.0
	sci_panel.anchor_right  = 1.0
	sci_panel.anchor_top    = 1.0
	sci_panel.anchor_bottom = 1.0
	sci_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	sci_panel.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	sci_panel.offset_right  = -4.0
	sci_panel.offset_bottom = -4.0
	science_panel = sci_panel
	top_layer.call_deferred("add_child", sci_panel)

	_credits_display = GameState.credits
	_science_display = GameState.science_points

	GameState.credits_changed.connect(_on_credits_changed)
	GameState.civilization_reached.connect(func(_civ: int) -> void: _show_act1_complete())
	GameState.lander_reached_moon.connect(_show_lander_notice)
	GameState.science_changed.connect(_on_science_changed)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

## Trade button under the Upgrade Tree button (opens TradePanel).
func _make_trade_button() -> Button:
	var b := IconButton.create("TRADE", "trade", IconButton.Variant.NEUTRAL)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(func() -> void:
		AudioManager.play("click")
		toggle_trade_panel())
	b.mouse_entered.connect(func() -> void:
		AudioManager.play("hover")
		CursorManager.set_state(CursorManager.State.POINTER)
		TooltipManager.show_tip("Trade", "Buy and sell at fixed prices, keep reserves and set standing orders." \
			if Trade.has_access() else "Research Trade Access to buy and sell."))
	b.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	return b

## Explore: a read-only look at every map from inside the game, once the
## tutorial is done (GameState.start_explore). Hidden until then.
var _explore_btn: Button = null
func _make_explore_button() -> Button:
	var b := IconButton.create("EXPLORE", "explore", IconButton.Variant.DEFAULT)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.visible = false
	b.pressed.connect(func() -> void:
		AudioManager.play("click")
		TooltipManager.hide_tip()
		GameState.start_explore())
	b.mouse_entered.connect(func() -> void:
		AudioManager.play("hover")
		CursorManager.set_state(CursorManager.State.POINTER)
		TooltipManager.show_tip("Explore", "Look around the galaxy, other systems and other planets. Nothing there can be built; your world keeps running. ESC returns."))
	b.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	return b

var _trade_layer: CanvasLayer = null

func toggle_trade_panel() -> void:
	if _trade_layer != null and is_instance_valid(_trade_layer):
		_trade_layer.queue_free()
		_trade_layer = null
		TradePanel.is_open = false
		return
	_trade_layer = CanvasLayer.new()
	_trade_layer.layer = 225
	var panel := TradePanel.new()
	_trade_layer.add_child(panel)
	get_tree().root.add_child(_trade_layer)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Don't show pause menu when on the main menu
		var current_scene := get_tree().current_scene
		if current_scene == null or current_scene.scene_file_path.ends_with("MainMenu.tscn"):
			return
		if GameState.showcase_mode:   # ESC leaves Explore, back to the home world
			get_viewport().set_input_as_handled()
			GameState.end_explore()
			return
		if get_tree().paused:
			if _pause_overlay != null and is_instance_valid(_pause_overlay):
				get_viewport().set_input_as_handled()
				get_tree().paused = false
				_pause_overlay.queue_free()
				_pause_overlay = null
			return
		get_viewport().set_input_as_handled()
		# Smart escape: close the topmost open thing first
		if _try_close_skill_tree():
			return
		if _top_layer != null and is_instance_valid(_top_layer):
			show_pause_menu()

func _try_close_skill_tree() -> bool:
	var root := get_tree().root
	for child in root.get_children():
		if not (child is CanvasLayer): continue
		for gc in child.get_children():
			var sc = gc.get_script()
			if sc != null and sc.resource_path.ends_with("SkillTreeView.gd"):
				AudioManager.play("click")
				CursorManager.set_state(CursorManager.State.NORMAL)
				gc.set("is_open", false)
				if gc.has_signal("tree_closed"):
					gc.emit_signal("tree_closed")
				child.queue_free()
				return true
	return false

func show_pause_menu() -> void:
	AudioManager.play("ui_click")
	if get_tree().paused:
		return
	get_tree().paused = true
	# ModalPopup (scenes/ui/components/ModalPopup.tscn); closing it resumes
	var p := ModalPopup.open(self, "Paused", "settings", "", 250)
	_pause_overlay = p.get_parent() as CanvasLayer
	p.card.get_node("VBox/Buttons").visible = false
	p.closed.connect(func() -> void:
		get_tree().paused = false
		_pause_overlay = null)
	var add := func(txt: String, icon_id: String, v: IconButton.Variant, action: Callable) -> IconButton:
		var b := IconButton.create(txt, icon_id, v)
		b.min_size = Vector2(220, 28)
		b.pressed.connect(func() -> void:
			AudioManager.play("ui_click")
			action.call())
		b.mouse_entered.connect(func() -> void:
			CursorManager.set_state(CursorManager.State.POINTER)
			AudioManager.play("hover"))
		b.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		p.add_content(b)
		return b
	add.call("RESUME", "confirm", IconButton.Variant.POSITIVE, p.close)
	add.call("SETTINGS", "settings", IconButton.Variant.DEFAULT, show_settings_popup)
	if not GameState.demo_build:   # the browser demo doesn't save
		add.call("SAVE GAME", "save", IconButton.Variant.DEFAULT, func() -> void:
			GameState.save()
			p.card.title = "GAME SAVED"
			var tw := create_tween()
			tw.tween_interval(1.5)
			tw.tween_callback(func() -> void:
				if is_instance_valid(p):
					p.card.title = "PAUSED"))
	p.add_content(HSeparator.new())
	add.call("MAIN MENU  (ENDS THIS RUN)" if GameState.demo_build else "MAIN MENU", "map", IconButton.Variant.NEUTRAL, func() -> void:
		p.close()
		set_game_hud(false)
		GameState.save()
		SceneTransition.go("res://scenes/MainMenu.tscn", null))
	if not GameState.demo_build:   # a browser tab has nothing to quit to
		add.call("QUIT TO DESKTOP", "close", IconButton.Variant.NEGATIVE, func() -> void:
			GameState.save()
			get_tree().quit())

func show_settings_popup() -> void:
	AudioManager.play("ui_click")
	var p := ModalPopup.open(self, "Settings", "settings", "", 300)   # above the pause menu
	p.cancel_button().visible = false
	var done := p.confirm_button()
	done.label_text = "CLOSE"
	done.icon_name = "close"
	done.variant = IconButton.Variant.DEFAULT
	done.pressed.connect(p.close)
	var section := func(t: String) -> void:
		var l := Label.new()
		l.text = t
		l.theme_type_variation = &"TitleLabel"
		p.add_content(l)
	var slider_row := func(t: String, value: float, on_change: Callable) -> void:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var l := Label.new()
		l.text = t
		l.theme_type_variation = &"SubLabel"
		l.custom_minimum_size = Vector2(90, 0)
		row.add_child(l)
		var sl := HSlider.new()
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.min_value = 0.0; sl.max_value = 1.0; sl.step = 0.05
		sl.value = value
		sl.value_changed.connect(on_change)
		row.add_child(sl)
		p.add_content(row)
	section.call("AUDIO")
	slider_row.call("Master Volume", SettingsManager.master_volume, func(v: float): SettingsManager.set_master_volume(v))
	slider_row.call("Music", SettingsManager.music_volume, func(v: float): SettingsManager.set_music_volume(v))
	slider_row.call("UI Sounds", SettingsManager.ui_volume, func(v: float): SettingsManager.set_ui_volume(v))
	slider_row.call("Effects", SettingsManager.sfx_volume, func(v: float): SettingsManager.set_sfx_volume(v))
	p.add_content(HSeparator.new())
	section.call("DISPLAY")
	var fs_chk := CheckButton.new()
	fs_chk.text = "Fullscreen"
	fs_chk.focus_mode = Control.FOCUS_NONE
	fs_chk.button_pressed = SettingsManager.is_fullscreen
	fs_chk.toggled.connect(func(on: bool): SettingsManager.set_fullscreen(on))
	fs_chk.mouse_entered.connect(func(): CursorManager.set_state(CursorManager.State.POINTER))
	fs_chk.mouse_exited.connect(func(): CursorManager.set_state(CursorManager.State.NORMAL))
	p.add_content(fs_chk)
	slider_row.call("Night Shadows", SettingsManager.night_shadow, func(v: float): SettingsManager.set_night_shadow(v))
	p.add_content(HSeparator.new())
	var tut_row := HBoxContainer.new()
	var tut_lbl := Label.new()
	tut_lbl.text = "Tutorial"
	tut_lbl.theme_type_variation = &"SubLabel"
	tut_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tut_row.add_child(tut_lbl)
	var reset_btn := Button.new()
	reset_btn.text = "RESET TUTORIAL"
	UIStyle.style_button(reset_btn, UIStyle.DEFAULT, 8)
	reset_btn.pressed.connect(func() -> void:
		SettingsManager.tutorial_ever_done = false
		SettingsManager.save_settings()
		TutorialManager.tutorial_enabled = true
		AudioManager.play("ui_click"))
	tut_row.add_child(reset_btn)
	p.add_content(tut_row)

## Credits / science changes show through the top bar's gain animation
## (_track_stock), polled from _process.
func _on_credits_changed(_new_val: float) -> void:
	pass

func _on_science_changed(_new_val: float) -> void:
	pass

func _process(delta: float) -> void:
	_res_poll += delta
	if _res_poll >= 0.25:
		_res_poll = 0.0
		_refresh_resource_cells()
		_maybe_show_offline()
		_maybe_celebrate_moon()
		if _explore_btn != null and is_instance_valid(_explore_btn):
			_explore_btn.visible = GameState.explore_available()

## The demo's high point: the first City on the Moon gets a short banner.
func _maybe_celebrate_moon() -> void:
	if GameState.moon_city_celebrated or GameState.showcase_mode or not SkillTree.event_met("moon_city"):
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path.ends_with("MainMenu.tscn"):
		return
	GameState.moon_city_celebrated = true
	# scenes/ui/MoonBanner.tscn — texts and timing are edited there
	var layer := CanvasLayer.new()
	layer.layer = 230
	get_tree().root.add_child(layer)
	layer.add_child((load("res://scenes/ui/MoonBanner.tscn") as PackedScene).instantiate())

## The lander parked in the Moon's orbit: a notice that flies the camera there
## (the Moon, its orbit and the lander's INITIATE COLONIZATION card).
func _show_lander_notice(moon_seed: int) -> void:
	if _top_layer == null or not is_instance_valid(_top_layer):
		return
	var btn := IconButton.create("THE LANDER REACHED THE MOON'S ORBIT  —  CLICK TO GO THERE", "moon", IconButton.Variant.POSITIVE)
	btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	btn.offset_top = 132.0
	btn.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	btn.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	btn.pressed.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		btn.queue_free()
		AudioManager.play("click")
		go_to_lander(moon_seed))
	_top_layer.add_child(btn)
	AudioManager.play("building_done")
	# stays a while, then fades away
	var tw := btn.create_tween()
	tw.tween_interval(20.0)
	tw.tween_property(btn, "modulate:a", 0.0, 1.0)
	tw.tween_callback(btn.queue_free)

## Shows the Moon with the lander: in place when the planet view is open,
## otherwise through a scene change (PlanetaryView picks up the request).
func go_to_lander(moon_seed: int) -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("focus_lander_at"):
		scene.call("focus_lander_at", moon_seed)
		return
	var moon := GameState.get_planet_data(moon_seed)
	if moon == null:
		return
	GameState.set_meta("focus_lander", moon_seed)
	moon.set_meta("__solar_data", GameState.get_home_solar())
	SceneTransition.go("res://scenes/planetary/PlanetaryView.tscn", moon)

## "While you were away" (PLAN M8): once after loading, in a gameplay scene.
func _maybe_show_offline() -> void:
	if not GameState.offline_pending or GameState.showcase_mode:
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path.ends_with("MainMenu.tscn"):
		return
	GameState.offline_pending = false
	var body := "You were away for [b]%s[/b]." % _duration_text(GameState.offline_seconds)
	if GameState.offline_progress_enabled():
		body += "\n\nOffline progress is switched on in this profile, but it isn't implemented yet — nothing was produced."
	else:
		body += "\n\nNothing was produced while the game was closed. Your economy picks up where you left it."
	ConfirmPanel.ask(self, "WELCOME BACK", body, "CONTINUE", Callable(), false)

static func _duration_text(sec: float) -> String:
	var d := floori(sec / 86400.0)
	var h := floori(fmod(sec, 86400.0) / 3600.0)
	var m := floori(fmod(sec, 3600.0) / 60.0)
	if d > 0:
		return "%d day%s %d h" % [d, "" if d == 1 else "s", h]
	if h > 0:
		return "%d h %d min" % [h, m]
	return "%d min" % maxi(m, 1)

## Spawn a small "+X" chip that floats upward from the given HUD panel then fades.
func _spawn_hud_chip(text: String, color: Color, panel: PanelContainer) -> void:
	if not is_instance_valid(panel): return
	var chip := Label.new()
	chip.text = text
	if _orbitron: chip.add_theme_font_override("font", _orbitron)
	chip.add_theme_font_size_override("font_size", 11)
	chip.add_theme_color_override("font_color", color)
	chip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	chip.add_theme_constant_override("outline_size", 3)
	# Position just to the right of the panel
	var start := panel.global_position + Vector2(panel.size.x + 6, panel.size.y * 0.15)
	chip.position = start
	chip.z_index  = 400
	add_child(chip)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(chip, "position:y", start.y - 38, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(chip, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(chip): chip.queue_free()

## The planet view's panel width — kept for callers; the top bar no longer
## centres anything in the view area.
func set_view_area_fraction(f: float) -> void:
	view_area_fraction = f

func _on_achievement_unlocked(def) -> void:
	AudioManager.play("achievement", 2.0)
	# Build a gold-bordered achievement popup anchored bottom-right
	var overlay := CanvasLayer.new()
	overlay.layer = 240
	get_tree().root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.theme_type_variation = &"TooltipPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hbox)

	var icon_lbl := Label.new()
	icon_lbl.text = def.icon if def.icon != "" else "★"
	if _orbitron: icon_lbl.add_theme_font_override("font", _orbitron)
	icon_lbl.add_theme_font_size_override("font_size", 24)
	icon_lbl.add_theme_color_override("font_color", Color(0.95, 0.78, 0.15))
	icon_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_lbl)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(vbox)

	var header := Label.new()
	header.text = "Achievement Unlocked"
	if _orbitron: header.add_theme_font_override("font", _orbitron)
	header.add_theme_font_size_override("font_size", 9)
	header.add_theme_color_override("font_color", Color(0.95, 0.78, 0.15, 0.75))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header)

	var title_lbl := Label.new()
	title_lbl.text = def.title
	if _orbitron: title_lbl.add_theme_font_override("font", _orbitron)
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	if def.description != "":
		var desc_lbl := Label.new()
		desc_lbl.text = def.description
		if _orbitron: desc_lbl.add_theme_font_override("font", _orbitron)
		desc_lbl.add_theme_font_size_override("font_size", 9)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.60, 0.85))
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(desc_lbl)

	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0
	panel.anchor_left   = 1.0
	panel.anchor_top    = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	# above the Upgrade Tree panel, which holds the bottom-right corner
	var above := 12.0
	if science_panel != null and is_instance_valid(science_panel):
		above += science_panel.size.y + 6.0
	panel.offset_right  = -12.0
	panel.offset_bottom = -above
	overlay.add_child(panel)

	await get_tree().process_frame
	await get_tree().process_frame
	var h := panel.size.y
	panel.offset_bottom = -above
	panel.offset_top    = panel.offset_bottom - h

	# Slide in, hold, fade out
	panel.modulate = Color(1, 1, 1, 0)
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.5)
	tw.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.6).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: overlay.queue_free())

func _on_tut_highlight(target: String) -> void:
	if target != "skill_tree_btn" or not is_instance_valid(_skill_btn): return
	if is_instance_valid(_skill_btn_tween): _skill_btn_tween.kill()
	_skill_btn_tween = create_tween().set_loops()
	_skill_btn_tween.tween_property(_skill_btn, "modulate", Color(1.6, 1.5, 0.6, 1.0), 0.5)
	_skill_btn_tween.tween_property(_skill_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

func _on_tut_highlight_clear() -> void:
	if is_instance_valid(_skill_btn_tween): _skill_btn_tween.kill(); _skill_btn_tween = null
	if is_instance_valid(_skill_btn): _skill_btn.modulate = Color.WHITE

func _energy_breakdown_text() -> String:
	var pm: Node = get_node_or_null("/root/ProductionManager")
	if pm == null:
		return "No data"
	var lines: Array[String] = []
	var total: float = 0.0
	for pp: PlanetProgress in GameState._planet_progress.values():
		if not pp.is_colonized:
			continue
		var net: float = pm.planet_energy_net(pp)
		if net == 0.0:
			continue
		var pd: PlanetData = GameState.get_planet_data(pp.planet_seed)
		var name_str: String = pd.planet_name if pd != null else "Colony"
		var sign_s := "+" if net > 0.0 else ""
		var net_fmt := ("%.1f" if absf(net - floorf(net)) > 0.01 else "%.0f") % net
		lines.append("%s  %s%s" % [name_str, sign_s, net_fmt])
		total += net
	if lines.is_empty():
		return "No active colonies"
	lines.sort()
	var sign_t := "+" if total > 0.0 else ""
	var tot_fmt := ("%.1f" if absf(total - floorf(total)) > 0.01 else "%.0f") % total
	lines.append("─────────────────")
	lines.append("Net  %s%s" % [sign_t, tot_fmt])
	return "\n".join(lines)

# ── Top resource bar ─────────────────────────────────────────────────────────
## Credits │ Science │ Energy │ Population │ Raw ▾ │ Goods │ Fuel │ Rare.
## Values show the stock only (red at the cap, see Economy.cap) with the
## steady income per second as a small superscript; refreshed from _process.

func _build_resource_cells(hbox: HBoxContainer) -> void:
	_add_res_cell(hbox, Economy.ENERGY, "⚡", "")
	_add_res_cell(hbox, Economy.POPULATION, "☺", "")
	_add_res_cell(hbox, Economy.RAW, "⛏", "")
	_add_res_cell(hbox, Economy.GOODS, "▣", "Consumer Goods — made from raw resources in Industrial districts.\nUsed by luxury housing and trade.")
	_add_res_cell(hbox, Economy.FUEL, "◆", "Fuel Rods — made from raw resources in Industrial districts.\nUsed by advanced power plants.")
	_add_res_cell(hbox, Economy.RARE, "✧", "Rare Elements — made from raw resources in Industrial districts.\nUsed by advanced science.")
	_refresh_resource_cells()

## Fixed text width per top-bar cell, so the bar never changes width; the
## value's font shrinks to fit instead (_fit_label).
const CELL_TEXT_W := {
	"credits": 62, "science": 38, "energy": 36, "population": 70,
	"raw": 46, "goods": 32, "fuel": 32, "rare_elements": 32,
}
## Largest value size is the theme's ValueLabel font size (voidle_theme.tres).
const VALUE_FONT_MIN := 7

## Sets a value label's text, shrinking its font until it fits its fixed width.
func _set_value(lbl: Label, text: String) -> void:
	if lbl.text == text:
		return
	lbl.text = text
	var font: Font = lbl.get_theme_font("font")
	var w := lbl.custom_minimum_size.x
	var size := UIStyle.font_size(&"ValueLabel")
	while size > VALUE_FONT_MIN and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > w:
		size -= 1
	lbl.add_theme_font_size_override("font_size", size)

## ── Incoming resources ──────────────────────────────────────────────────────
## A gain shows as "+x" under its cell, floats up into the bar, and the value
## then ticks up to the new amount. Spending updates at once.
var _shown: Dictionary = {}     # id -> value currently displayed
var _target: Dictionary = {}    # id -> value the display is heading to
var _gain_tw: Dictionary = {}   # id -> Tween

func _stock_amount(id: String) -> float:
	return Economy.raw_total() if id == Economy.RAW else Economy.amount(id)

func _stock_text(id: String, v: float) -> String:
	match id:
		Economy.CREDITS: return fmt_credits(v)
		Economy.RAW:     return "%s %s" % [Economy.fmt(v), "▴" if _raw_dd != null else "▾"]
	return Economy.fmt(v)

func _track_stock(id: String) -> void:
	var lbl: Label = _res_lbls.get(id)
	if not is_instance_valid(lbl):
		return
	var actual := _stock_amount(id)
	if not _shown.has(id):
		_shown[id] = actual
		_target[id] = actual
	var target: float = _target[id]
	if actual > target + 0.05:
		_target[id] = actual
		_spawn_gain(id, actual - target, lbl)
		var tw: Tween = _gain_tw.get(id)
		if tw != null and tw.is_valid():
			tw.kill()
		tw = create_tween()
		_gain_tw[id] = tw
		tw.tween_interval(0.55)   # let the "+x" reach the bar first
		tw.tween_method(func(v: float) -> void:
			_shown[id] = v
			if is_instance_valid(lbl):
				_set_value(lbl, _stock_text(id, v)),
			float(_shown[id]), actual, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif actual < target - 0.0001:
		var tw2: Tween = _gain_tw.get(id)
		if tw2 != null and tw2.is_valid():
			tw2.kill()
		if target - actual >= 0.05:
			_spawn_loss(id, target - actual, lbl)
		_target[id] = actual
		_shown[id] = actual
	_set_value(lbl, _stock_text(id, _shown[id]))

func _spawn_gain(id: String, amount: float, lbl: Label) -> void:
	if not is_instance_valid(_top_layer) or amount < 0.05:
		return
	var chip := Label.new()
	chip.text = "+" + (fmt_credits(amount) if id == Economy.CREDITS else Economy.fmt(amount))
	if _orbitron: chip.add_theme_font_override("font", _orbitron)
	chip.add_theme_font_size_override("font_size", 10)
	var col := Economy.color_of(id) if id != Economy.RAW else Color(0.85, 0.78, 0.70)
	chip.add_theme_color_override("font_color", col.lerp(Color.WHITE, 0.25))
	chip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	chip.add_theme_constant_override("outline_size", 3)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_layer.add_child(chip)
	var start := lbl.global_position + Vector2(2.0, lbl.size.y + 14.0)
	chip.position = start
	chip.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(chip, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(chip, "position:y", start.y - 4.0, 0.12)
	tw.tween_interval(0.2)
	tw.tween_property(chip, "position:y", lbl.global_position.y + 2.0, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(chip, "modulate:a", 0.0, 0.3).set_delay(0.1)
	tw.tween_callback(chip.queue_free)

## A spend shows as a red "−x" that drops out of the value and fades.
func _spawn_loss(id: String, amount: float, lbl: Label) -> void:
	if not is_instance_valid(_top_layer):
		return
	var chip := Label.new()
	chip.text = "−" + (fmt_credits(amount) if id == Economy.CREDITS else Economy.fmt(amount))
	if _orbitron: chip.add_theme_font_override("font", _orbitron)
	chip.add_theme_font_size_override("font_size", 10)
	chip.add_theme_color_override("font_color", Color(1.0, 0.42, 0.36))
	chip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	chip.add_theme_constant_override("outline_size", 3)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_layer.add_child(chip)
	var start := lbl.global_position + Vector2(2.0, lbl.size.y * 0.5)
	chip.position = start
	var tw := create_tween()
	tw.tween_property(chip, "position:y", start.y + 26.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(chip, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.tween_callback(chip.queue_free)

func _set_rate(id: String, per_s: float) -> void:
	var chip: ResourceChip = _res_chips.get(id)
	if not is_instance_valid(chip) or not _rate_lbls.has(id):
		return
	var v := snappedf(per_s, 0.1)
	chip.rate_text = ("+" if v >= 0.0 else "−") + Economy.fmt(absf(v))
	chip.rate_tone = ResourceChip.Tone.GOOD if v >= 0.0 else ResourceChip.Tone.BAD

## One ResourceChip per resource (scenes/ui/components/ResourceChip.tscn).
## The icon comes from UIIcons; `_glyph` and `_sep` stay for call compatibility.
func _add_res_cell(hbox: HBoxContainer, id: String, _glyph: String, tip: String, _sep: bool = true) -> void:
	var cell := ResourceChip.create(id)
	cell.value_width = float(CELL_TEXT_W.get(id, 40))
	cell.value_text = ""
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	hbox.add_child(cell)
	_res_slots[id] = cell   # hidden until GameState reveals the resource
	_res_chips[id] = cell
	_res_lbls[id] = cell.value_label
	if id != Economy.ENERGY and id != Economy.POPULATION:
		# energy: net only; population: available / max — the rest is in the tooltip
		_rate_lbls[id] = cell.rate_label
	var title := Economy.display_name(id).to_upper() if id != Economy.RAW else "RAW RESOURCES"
	cell.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		if id == Economy.RAW:
			if _raw_dd == null:
				TooltipManager.show_tip(title, "Click to show every raw resource.")
				TooltipManager.set_title_icon(id)
			return
		TooltipManager.show_tip(title, _cell_tip(id, tip))
		TooltipManager.set_title_icon(id))
	cell.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	if id == Economy.RAW:
		_raw_cell = cell
		cell.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and (e as InputEventMouseButton).pressed \
					and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
				AudioManager.play("click")
				TooltipManager.hide_tip()
				_toggle_raw_dropdown()
				cell.accept_event())

func _hover_tip(ctrl: Control, title: String, body: String) -> void:
	ctrl.mouse_filter = Control.MOUSE_FILTER_STOP
	ctrl.mouse_entered.connect(func() -> void: TooltipManager.show_tip(title, body))
	ctrl.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())

## Tooltip body of a top-bar cell, with live numbers.
func _cell_tip(id: String, base: String) -> String:
	match id:
		Economy.ENERGY:
			var pm: Node = get_node_or_null("/root/ProductionManager")
			var net: float = pm.get_global_energy() if pm != null else 0.0
			var sp: Vector2 = pm.get_global_energy_split() if pm != null else Vector2.ZERO
			var lines: Array[String] = [
				"Produced   +%s ⚡" % Economy.fmt(sp.x),
				"Consumed   −%s ⚡" % Economy.fmt(sp.y),
				"Balance    %s%s ⚡" % ["+" if net >= 0.0 else "", Economy.fmt(net)],
				"",
				"A deficit lowers what energy-using buildings make (down to %d%% at worst) — cycles keep their length." % int(round((1.0 - Balance.cfg.energy_max_slowdown) * 100.0))]
			if net < 0.0:
				lines.append("Now producing at %d%% output." % int(round(pm.get_energy_ratio() * 100.0)))
			lines.append("")
			lines.append(_energy_breakdown_text())
			return "\n".join(lines)
		Economy.POPULATION:
			var pd: PlanetData = GameState.get_planet_data(GameState.active_planet_seed) \
				if GameState.active_planet_seed != -1 else null
			var pp: PlanetProgress = GameState.get_planet(pd.seed) if pd != null else null
			var head := ""
			var penalty := ""
			if pd != null and pp != null and pp.is_colonized:
				head = "Available  %s\nUsed       %s\nMax        %s\n\n" % [Economy.fmt(Economy.free_population(pd, pp)),
					Economy.fmt(Economy.used_population(pd, pp)), Economy.fmt(Economy.max_population(pd, pp))]
				var spd := Economy.pop_speed(pd, pp)
				if spd < 0.999:
					penalty = "\n\n[color=#ff6a5c]Overcrowded — every building and district on this planet makes %d%% of its output.[/color]" % int(round(spd * 100.0))
			return head + "Shown as available / max.\nCities house %s each; Residential districts add more.\nNew districts (%s) and district levels use population.\n\nIf more people work than you can house, every finished cycle on the planet makes less (down to %d%% at worst) until you build homes." % [
				Economy.fmt(Balance.cfg.city_base_pop), Economy.fmt(Economy.district_found_pop(0)), int(round((1.0 - Balance.cfg.pop_max_slowdown) * 100.0))] + penalty + _idle_pop_text()
	var r: float = ProductionManager.resource_rates().get(id, 0.0)
	return "%s\n\nStored  %s  (max %s)\nPer second  %s%s" % [base, Economy.fmt(Economy.amount(id)),
		Economy.fmt(Economy.cap(id)), "+" if r >= 0.0 else "", Economy.fmt(r)]

## Idle housing across the empire and what research turns it into.
func _idle_pop_text() -> String:
	var idle := ProductionManager.empire_idle()
	var out := "\n\nIdle across all worlds  %s (%d%%)" % [Economy.fmt(idle.x),
		int(round(ProductionManager.idle_ratio() * 100.0))]
	var r := ProductionManager.idle_income_rates()
	if float(r[Economy.CREDITS]) > 0.0:
		out += "\n  +%s Credits / min  (Civic Enterprise)" % Economy.fmt(float(r[Economy.CREDITS]) * 60.0)
	if float(r[Economy.SCIENCE]) > 0.0:
		out += "\n  +%s Science / min  (Free Research)" % Economy.fmt(float(r[Economy.SCIENCE]) * 60.0)
	var reserve: float = SkillTree.reserve_mult(ProductionManager.idle_ratio())
	if reserve > 1.0:
		out += "\n  +%d%% Raw and processed output  (Production Reserve)" % int(round((reserve - 1.0) * 100.0))
	return out

## Resources show up in the bar as the player meets them (credits and
## population always). Revealed ids persist in GameState.revealed_resources.
const ALWAYS_SHOWN := ["credits", "population"]

func _update_reveals(rates: Dictionary) -> void:
	for id: String in _res_slots:
		var slot: Control = _res_slots[id]
		var shown := id in ALWAYS_SHOWN or GameState.revealed_resources.has(id)
		if not shown and _should_reveal(id, rates):
			GameState.revealed_resources.append(id)
			shown = true
			slot.modulate = Color(2.0, 2.0, 1.4, 0.0)
			var tw := create_tween()
			tw.tween_property(slot, "modulate", Color.WHITE, 0.8).set_trans(Tween.TRANS_QUAD)
		slot.visible = shown

func _should_reveal(id: String, rates: Dictionary) -> bool:
	match id:
		Economy.ENERGY:
			var sp: Vector2 = ProductionManager.get_global_energy_split()
			return sp.x > 0.0 or sp.y > 0.0
		Economy.SCIENCE:
			return GameState.science_points > 0.0 or float(rates.get(id, 0.0)) > 0.0
		Economy.RAW:
			return Economy.raw_total() > 0.0 or float(rates.get(id, 0.0)) != 0.0
	return Economy.amount(id) > 0.0 or float(rates.get(id, 0.0)) != 0.0

func _refresh_resource_cells() -> void:
	if _res_lbls.is_empty():
		return
	var rates: Dictionary = ProductionManager.resource_rates()
	_update_reveals(rates)
	_set_rate(Economy.CREDITS, rates.get(Economy.CREDITS, 0.0))
	_set_rate(Economy.SCIENCE, rates.get(Economy.SCIENCE, 0.0))
	_track_stock(Economy.CREDITS)
	_track_stock(Economy.SCIENCE)
	_set_chip_state(Economy.SCIENCE, false, GameState.science_points <= 0.0 and float(rates.get(Economy.SCIENCE, 0.0)) <= 0.0)
	var e_lbl: Label = _res_lbls.get(Economy.ENERGY)
	if is_instance_valid(e_lbl):
		var net: float = rates.get(Economy.ENERGY, 0.0)
		_set_value(e_lbl, ("+" if snappedf(net, 0.1) >= 0.0 else "−") + Economy.fmt(absf(snappedf(net, 0.1))))
		var sp: Vector2 = ProductionManager.get_global_energy_split()
		_set_chip_state(Economy.ENERGY, net < 0.0, sp.x <= 0.0 and sp.y <= 0.0)

	var pop_lbl: Label = _res_lbls.get(Economy.POPULATION)
	if is_instance_valid(pop_lbl):
		var pd: PlanetData = GameState.get_planet_data(GameState.active_planet_seed) \
			if GameState.active_planet_seed != -1 else null
		var pp: PlanetProgress = GameState.get_planet(pd.seed) if pd != null else null
		if pd != null and pp != null and pp.is_colonized:
			var used := Economy.used_population(pd, pp)
			var mx := Economy.max_population(pd, pp)
			# available / max (used is in the tooltip)
			_set_value(pop_lbl, "%s/%s" % [Economy.fmt(mx - used), Economy.fmt(mx)])
			_set_chip_state(Economy.POPULATION, used >= mx, false)
		else:
			_set_value(pop_lbl, "—")
			_set_chip_state(Economy.POPULATION, false, true)
	for id: String in Economy.PROCESSED:
		var l: Label = _res_lbls.get(id)
		if is_instance_valid(l):
			_track_stock(id)
			_set_rate(id, rates.get(id, 0.0))
			_set_chip_state(id, Economy.is_full(id), Economy.amount(id) <= 0.0 and float(rates.get(id, 0.0)) == 0.0)
	var raw_lbl: Label = _res_lbls.get(Economy.RAW)
	if is_instance_valid(raw_lbl):
		_track_stock(Economy.RAW)
		var any_full := false
		for r: Dictionary in _listed_raws():
			if Economy.is_full(r["id"]): any_full = true
		_set_rate(Economy.RAW, rates.get(Economy.RAW, 0.0))
		_set_chip_state(Economy.RAW, any_full, Economy.raw_total() <= 0.0 and float(rates.get(Economy.RAW, 0.0)) == 0.0)
	if _raw_dd != null:
		_fill_raw_dropdown()

## Alert = value in the palette's "bad" colour (at the cap, deficit, overcrowded);
## inactive = nothing stored and nothing coming in (dimmed chip).
func _set_chip_state(id: String, alert: bool, inactive: bool) -> void:
	var chip: ResourceChip = _res_chips.get(id)
	if not is_instance_valid(chip):
		return
	if chip.alert != alert:
		chip.alert = alert
	if chip.inactive != inactive:
		chip.inactive = inactive

## Raw resources worth listing: discovered ones (or anything in stock).
## Undiscovered minerals never leak their name here.
func _listed_raws() -> Array:
	var out: Array = []
	for r: Dictionary in Economy.RAW_TABLE:
		if Economy.is_mineral_discovered(r["id"]) or Economy.amount(r["id"]) > 0.0:
			out.append(r)
	return out

func _toggle_raw_dropdown() -> void:
	if _raw_dd != null:
		_close_raw_dropdown()
		return
	if not is_instance_valid(_raw_cell) or not is_instance_valid(_top_layer):
		return
	var dd := PanelContainer.new()
	dd.theme_type_variation = &"TooltipPanel"
	dd.mouse_filter = Control.MOUSE_FILTER_STOP
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 4)
	dd.add_child(list)
	_top_layer.add_child(dd)
	dd.global_position = Vector2(_raw_cell.global_position.x - 6.0,
		credits_panel.global_position.y + credits_panel.size.y + 2.0)
	_raw_dd = dd
	_raw_dd_list = list
	_fill_raw_dropdown()
	_refresh_resource_cells()

func _close_raw_dropdown() -> void:
	if is_instance_valid(_raw_dd):
		_raw_dd.queue_free()
	_raw_dd = null
	_raw_dd_list = null
	_refresh_resource_cells()

## One ResourceChip per raw resource (mineral colour, stock; red at the cap,
## dim when empty). The name is in its tooltip.
func _fill_raw_dropdown() -> void:
	if not is_instance_valid(_raw_dd_list):
		return
	var raws := _listed_raws()
	var rows := _raw_dd_list.get_children()
	if rows.size() != raws.size() or raws.is_empty():
		for c in rows:
			c.queue_free()
		if raws.is_empty():
			var none := Label.new()
			none.text = "No raw resources yet"
			none.theme_type_variation = &"SubLabel"
			_raw_dd_list.add_child(none)
			return
		rows = []
		for r: Dictionary in raws:
			var chip := ResourceChip.create(UIIcons.RAW_PLACEHOLDER)
			chip.icon_color = r["color"]
			chip.value_width = 44.0
			var nm: String = r["name"]
			chip.mouse_entered.connect(func() -> void: TooltipManager.show_tip(nm))
			chip.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
			_raw_dd_list.add_child(chip)
			rows.append(chip)
	for i in raws.size():
		var r: Dictionary = raws[i]
		var chip := rows[i] as ResourceChip
		chip.icon_color = r["color"]
		chip.value_text = Economy.fmt(Economy.amount(r["id"]))
		chip.alert = Economy.is_full(r["id"])
		chip.inactive = Economy.amount(r["id"]) <= 0.0

## Closes the raw dropdown on any click outside it (and outside its cell).
func _input(event: InputEvent) -> void:
	if _raw_dd == null or not (event is InputEventMouseButton) or not (event as InputEventMouseButton).pressed:
		return
	var pos := (event as InputEventMouseButton).global_position
	if is_instance_valid(_raw_dd) and _raw_dd.get_global_rect().has_point(pos):
		return
	if is_instance_valid(_raw_cell) and _raw_cell.get_global_rect().has_point(pos):
		return
	_close_raw_dropdown()


# ── End of Act I (demo) ──────────────────────────────────────────────────────

## Shown once, when the final rocket arrives: Civilization 0 is complete.
func _show_act1_complete() -> void:
	# scenes/ui/DemoEndScreen.tscn — texts and layout are edited in the scene
	var layer := CanvasLayer.new()
	layer.layer = 240
	get_tree().root.add_child(layer)
	layer.add_child((load("res://scenes/ui/DemoEndScreen.tscn") as PackedScene).instantiate())
