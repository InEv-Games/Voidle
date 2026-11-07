## Global HUD overlay — shows credits and other persistent info across all scenes.
extends CanvasLayer

var _skill_btn_tween: Tween = null
## Fraction of the screen width the game view occupies (left of the side panel).
## The energy readout stays centred on it; PlanetaryView animates it when the
## side panel slides in or out.
var view_area_fraction: float = 0.7
var _orbitron: Font
var _res_poll: float = 0.0
## The top resource bar (scenes/ui/components/ResourceBar.tscn) — exposed so
## views can read its screen height.
var credits_panel: ResourceBar = null
var science_panel: PanelContainer = null
var _top_layer: CanvasLayer = null
var _pause_overlay: CanvasLayer = null

func set_game_hud(visible_state: bool) -> void:
	visible = visible_state
	if is_instance_valid(_top_layer):
		_top_layer.visible = visible_state
## A credit amount, "21.6k" — no "cr": the credits icon stands beside it
## (playtest 31.10: "cr" is never written).
static func fmt_credits(val: float) -> String:
	if val >= 1_000_000_000.0:
		return "%.2fb" % (val / 1_000_000_000.0)
	elif val >= 1_000_000.0:
		return "%.2fm" % (val / 1_000_000.0)
	elif val >= 1_000.0:
		return "%.1fk" % (val / 1_000.0)
	return "%.0f" % val

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

	TutorialManager.highlight_changed.connect(_on_tut_highlight)
	TutorialManager.highlight_cleared.connect(_on_tut_highlight_clear)

	# Credits + Science go into a top layer (above SkillTree at 220)
	var top_layer := CanvasLayer.new()
	top_layer.layer = 230
	_top_layer = top_layer
	get_parent().call_deferred("add_child", top_layer)

	credits_panel = ResourceBar.create()   # top-left
	top_layer.call_deferred("add_child", credits_panel)

	# (no settings button: Esc opens the pause menu)


	# Upgrade Tree // Trade // Explore live at the bottom of the view's LeftPanel
	# (fill_shortcuts). This bottom-left row only shows when no LeftPanel is on
	# screen (Galaxy view, a hidden or slid-out panel).
	var sci_panel := PanelContainer.new()
	var bar_box := UIStyle.box(&"SidePanel").duplicate() as StyleBoxFlat
	bar_box.content_margin_top = 6.0
	bar_box.content_margin_bottom = 6.0
	sci_panel.add_theme_stylebox_override("panel", bar_box)   # SidePanel look, tighter margins
	sci_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	sci_panel.anchor_top    = 1.0
	sci_panel.anchor_bottom = 1.0
	sci_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN

	var sci_row := HBoxContainer.new()
	sci_row.add_theme_constant_override("separation", 4)
	sci_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sci_panel.add_child(sci_row)
	fill_shortcuts(sci_row)

	science_panel = sci_panel
	top_layer.call_deferred("add_child", sci_panel)

	GameState.credits_changed.connect(_on_credits_changed)
	GameState.civilization_reached.connect(func(_civ: int) -> void: _show_act1_complete())
	GameState.lander_reached_moon.connect(func(_moon_seed: int) -> void: AudioManager.play("building_done"))   # the news bar tells it
	GameState.expedition_changed.connect(_on_expedition_changed)
	GameState.science_changed.connect(_on_science_changed)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

## Upgrade Tree // Trade // Explore into `row` (a LeftPanel's Shortcuts, or the
## HUD's own bottom-left row). Each row gets its own buttons.
var _skill_btns: Array[Button] = []
var _explore_btns: Array[Button] = []
var _trade_btns: Array[Button] = []   # shown only once Trade Access is researched

func fill_shortcuts(row: HBoxContainer) -> void:
	var skill_btn := _make_skill_button()
	var trade_btn := _make_trade_button()
	var companions_btn := _make_companions_button()
	var explore_btn := _make_explore_button()
	explore_btn.visible = GameState.explore_available()
	trade_btn.visible = Trade.has_access()
	for b: Button in [skill_btn, trade_btn, companions_btn, explore_btn]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # share the row evenly
		row.add_child(b)
	companions_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER   # square, icon only
	for list: Array[Button] in [_skill_btns, _explore_btns, _trade_btns]:   # drop rows freed with their view
		for i in range(list.size() - 1, -1, -1):
			if not is_instance_valid(list[i]):
				list.remove_at(i)
	_skill_btns.append(skill_btn)
	_explore_btns.append(explore_btn)
	_trade_btns.append(trade_btn)

## Upgrade Tree button (opens / closes the SkillTreeView layer).
func _make_skill_button() -> Button:
	var skill_btn := IconButton.create("UPGRADE TREE", "research", IconButton.Variant.DEFAULT)
	skill_btn.mouse_filter = Control.MOUSE_FILTER_STOP

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
			_open_skill_tree())

		
	skill_btn.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		TooltipManager.show_tip("Upgrade Tree", "Research new buildings and upgrades with Science."))
	skill_btn.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	return skill_btn

const TREE_FADE_SEC := 1.2

## Opens the Upgrade Tree: the view's left panel closes first (overlay_begin),
## then the tree fades in while the planet zooms out a little
## (overlay_zoom_out); closing it puts the view back (overlay_end). Views
## without these hooks just get the fade.
func _open_skill_tree() -> void:
	var view := get_tree().current_scene
	var wait := 0.0
	if view != null and view.has_method("overlay_begin"):
		wait = float(view.call("overlay_begin"))
	var st_layer := CanvasLayer.new()
	st_layer.layer = 220
	var st_view: Control = load("res://scripts/ui/SkillTreeView.gd").new()
	st_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	st_view.modulate.a = 0.0
	st_layer.add_child(st_view)
	get_tree().root.add_child(st_layer)
	st_view.tree_exiting.connect(func() -> void:
		if is_instance_valid(view) and view.has_method("overlay_end"):
			view.call("overlay_end"))
	var tw := st_view.create_tween()
	tw.tween_interval(wait)
	tw.tween_callback(func() -> void:
		if is_instance_valid(view) and view.has_method("overlay_zoom_out"):
			view.call("overlay_zoom_out", TREE_FADE_SEC))
	tw.tween_property(st_view, "modulate:a", 1.0, TREE_FADE_SEC) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Trade button next to the Upgrade Tree button (opens TradePanel).
func _make_trade_button() -> Button:
	var b := IconButton.create("TRADE", "trade", IconButton.Variant.NEUTRAL)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(func() -> void:
		if TutorialManager.blocks_hud():   # like the Upgrade Tree: shut during the guided tutorial
			AudioManager.play("error")
			return
		AudioManager.play("click")
		toggle_trade_panel())
	b.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		TooltipManager.show_tip("Trade", "Buy and sell (prices move with your trades), keep reserves and set standing orders." \
			if Trade.has_access() else "Research Trade Access to buy and sell."))
	b.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	return b

## Companions: every companion of the game, joined or not (CompanionGallery).
func _make_companions_button() -> Button:
	var b := IconButton.create("", "population", IconButton.Variant.DEFAULT)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(func() -> void:
		TooltipManager.hide_tip()
		CompanionGallery.open(self))
	b.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		TooltipManager.show_tip("Companions", "Joined: %d / %d. Each gives a bonus everywhere." % [Excavations.joined_count(), CompanionDef.all().size()]))
	b.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	return b

## A pill under the top bar while a world has a trait pick waiting.
var _trait_btn: IconButton = null
var _trait_poll := 0.0

func _update_trait_notice(delta: float) -> void:
	_trait_poll -= delta
	if _trait_poll > 0.0 or _top_layer == null or not is_instance_valid(_top_layer):
		return
	_trait_poll = 0.5
	var seeds := PlanetTags.pending_seeds()
	var want := visible and not seeds.is_empty() and not TutorialManager.blocks_hud() and not GameOverlays.trait_picker_open()
	if not want:
		if _trait_btn != null and is_instance_valid(_trait_btn):
			_trait_btn.queue_free()
		_trait_btn = null
		return
	if _trait_btn != null and is_instance_valid(_trait_btn):
		return
	_trait_btn = IconButton.create("CHOOSE A PLANET TRAIT", "planet", IconButton.Variant.POSITIVE)
	_trait_btn.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_trait_btn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_trait_btn.offset_top = 96.0
	_trait_btn.pressed.connect(func() -> void:
		var s := PlanetTags.pending_seeds()
		if not s.is_empty():
			GameOverlays.open_trait_picker(self, s[0]))
	_top_layer.add_child(_trait_btn)

## Explore: a read-only look at every map from inside the game, once the
## tutorial is done (GameState.start_explore). Hidden until then.
func _make_explore_button() -> Button:
	var b := IconButton.create("EXPLORE", "explore", IconButton.Variant.DEFAULT)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.visible = false
	b.pressed.connect(func() -> void:
		AudioManager.play("click")
		TooltipManager.hide_tip()
		GameState.start_explore())
	b.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		TooltipManager.show_tip("Explore", "Look around the galaxy, other systems and other planets. Nothing there can be built; your world keeps running. ESC returns."))
	b.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	return b

var _trade_layer: CanvasLayer = null

func toggle_trade_panel() -> void:
	# inside the view's left panel when it has one (slides out, swaps, slides in)
	var lp: LeftPanel = null
	for n in get_tree().get_nodes_in_group(LeftPanel.GROUP):
		if n is LeftPanel and (n as LeftPanel).is_inside_tree():
			lp = n
			break
	if lp != null:
		if lp.overlay() is TradePanel:
			lp.close_overlay()
			TradePanel.is_open = false
		else:
			var tp := TradePanel.new()
			tp.embedded = true
			lp.show_overlay(tp)
		return
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

## VAM snapshot (edit in the VAM tab) shared with planet placement.
const PAUSE_SNAPSHOT := &"snapshots/lowpass"

func show_pause_menu() -> void:
	AudioManager.play("ui_click")
	if get_tree().paused:
		return
	get_tree().paused = true
	# ModalPopup (scenes/ui/components/ModalPopup.tscn); closing it resumes
	var p := ModalPopup.open(self, "Paused", "settings", "", 250)
	_pause_overlay = p.get_parent() as CanvasLayer
	# Music muffles while the menu is open. Tied to the overlay's lifetime, so every
	# way of closing it (Resume, a click outside, a second Esc, Main Menu) ends it.
	VAM.start_snapshot(PAUSE_SNAPSHOT, &"pause")
	_pause_overlay.tree_exiting.connect(func() -> void: VAM.stop_snapshot(PAUSE_SNAPSHOT, &"pause"))
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
			CursorManager.set_state(CursorManager.State.POINTER))
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

## Settings rows for the UI theme: a preset, or the builder (harmony, accent
## hue, vividness) with a 60/30/10 preview. Builder changes apply after a
## short pause, since a theme swap restyles every Control.
func _add_theme_builder(p: ModalPopup) -> void:
	var row_of := func(t: String) -> HBoxContainer:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var l := Label.new()
		l.text = t
		l.theme_type_variation = &"TitleLabel"
		l.custom_minimum_size = Vector2(96, 0)
		row.add_child(l)
		p.add_content(row)
		return row
	var swatch_of := func(parent: Control, c: Color) -> StyleBoxFlat:
		var sw := Panel.new()
		sw.custom_minimum_size = Vector2(14, 14)
		sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(3)
		sb.set_border_width_all(1)
		sb.border_color = Color(1, 1, 1, 0.35)
		sb.bg_color = c
		sw.add_theme_stylebox_override("panel", sb)
		parent.add_child(sw)
		return sb
	var hover := func(c: Control) -> void:
		c.mouse_entered.connect(func(): CursorManager.set_state(CursorManager.State.POINTER))
		c.mouse_exited.connect(func(): CursorManager.set_state(CursorManager.State.NORMAL))

	# preset
	var theme_row: HBoxContainer = row_of.call("Theme Color")
	var swatch_sb: StyleBoxFlat = swatch_of.call(theme_row, SettingsManager.theme_swatch())
	var theme_opt := OptionButton.new()
	theme_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	theme_opt.focus_mode = Control.FOCUS_NONE
	for i in SettingsManager.THEME_ORDER.size():
		theme_opt.add_item(SettingsManager.THEMES[SettingsManager.THEME_ORDER[i]]["label"], i)
	theme_opt.selected = SettingsManager.THEME_ORDER.find(SettingsManager.theme_id)
	hover.call(theme_opt)
	theme_row.add_child(theme_opt)

	# builder
	var harm_row: HBoxContainer = row_of.call("Harmony")
	var harm_opt := OptionButton.new()
	harm_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	harm_opt.focus_mode = Control.FOCUS_NONE
	for i in ThemeBuilder.HARMONY_ORDER.size():
		harm_opt.add_item(ThemeBuilder.HARMONY_LABELS[ThemeBuilder.HARMONY_ORDER[i]], i)
	hover.call(harm_opt)
	harm_row.add_child(harm_opt)

	var slider := func(row: HBoxContainer, lo: float, hi: float, step: float) -> Array:
		var sl := HSlider.new()
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.min_value = lo; sl.max_value = hi; sl.step = step
		row.add_child(sl)
		var v := Label.new()
		v.theme_type_variation = &"MonoLabel"
		v.custom_minimum_size = Vector2(34, 0)
		v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(v)
		return [sl, v]
	var hue_row: HBoxContainer = row_of.call("Accent Hue")
	var hue_sb: StyleBoxFlat = swatch_of.call(hue_row, Color.WHITE)
	var hue_parts: Array = slider.call(hue_row, 0.0, 359.0, 1.0)
	var hue_sl: HSlider = hue_parts[0]
	var hue_lbl: Label = hue_parts[1]
	var viv_row: HBoxContainer = row_of.call("Vividness")
	var viv_parts: Array = slider.call(viv_row, 0.2, 1.3, 0.05)
	var viv_sl: HSlider = viv_parts[0]
	var viv_lbl: Label = viv_parts[1]

	var prev_row: HBoxContainer = row_of.call("Preview")
	prev_row.tooltip_text = "Backgrounds (60%) // items (30%) // accent (10%)"
	var prev_sbs: Array[StyleBoxFlat] = []
	for i in 3:
		var sb: StyleBoxFlat = swatch_of.call(prev_row, Color.BLACK)
		prev_sbs.append(sb)
		(prev_row.get_child(prev_row.get_child_count() - 1) as Control).custom_minimum_size = Vector2(40, 14)

	var syncing := [false]   # true while the controls are set from code
	var gen := [0]
	var refresh := func() -> void:
		var harmony: int = ThemeBuilder.HARMONY_ORDER[maxi(harm_opt.selected, 0)]
		hue_lbl.text = "%d°" % roundi(hue_sl.value)
		viv_lbl.text = "%d%%" % roundi(viv_sl.value * 100.0)
		hue_sb.bg_color = Color.from_hsv(hue_sl.value / 360.0, 0.8, 0.95)
		var cols := SettingsManager.theme_preview(hue_sl.value, harmony, viv_sl.value)
		for i in 3:
			prev_sbs[i].bg_color = cols[i]
	# the colour controls only while the theme is Custom (picking Custom opens them)
	var builder_rows: Array[Control] = [harm_row, hue_row, viv_row, prev_row]
	var sync := func() -> void:
		syncing[0] = true
		for r in builder_rows:
			r.visible = SettingsManager.theme_id == "custom"
		theme_opt.selected = SettingsManager.THEME_ORDER.find(SettingsManager.theme_id)
		harm_opt.selected = maxi(ThemeBuilder.HARMONY_ORDER.find(SettingsManager.theme_harmony), 0)
		hue_sl.value = SettingsManager.theme_hue
		viv_sl.value = SettingsManager.theme_vividness
		swatch_sb.bg_color = SettingsManager.theme_swatch()
		syncing[0] = false
		refresh.call()
	var on_builder := func() -> void:
		if syncing[0]:
			return
		refresh.call()
		gen[0] += 1
		var my_gen: int = gen[0]
		get_tree().create_timer(0.2, true).timeout.connect(func() -> void:
			if my_gen != gen[0] or not is_instance_valid(theme_opt):
				return
			SettingsManager.set_custom_theme(hue_sl.value,
				ThemeBuilder.HARMONY_ORDER[maxi(harm_opt.selected, 0)], viv_sl.value)
			sync.call())
	theme_opt.item_selected.connect(func(idx: int) -> void:
		if syncing[0] or idx < 0 or idx >= SettingsManager.THEME_ORDER.size():
			return
		AudioManager.play("ui_click")
		var tid: String = SettingsManager.THEME_ORDER[idx]
		if tid == "custom":
			for r in builder_rows:
				r.visible = true   # at once; the theme follows after the debounce
			on_builder.call()
		else:
			SettingsManager.set_theme_id(tid)
			sync.call())
	harm_opt.item_selected.connect(func(_i: int) -> void:
		AudioManager.play("ui_click")
		on_builder.call())
	hue_sl.value_changed.connect(func(_v: float) -> void: on_builder.call())
	viv_sl.value_changed.connect(func(_v: float) -> void: on_builder.call())
	sync.call()

func show_settings_popup() -> void:
	AudioManager.play("ui_click")
	var p := ModalPopup.open(self, "Settings", "settings", "", 300)   # above the pause menu
	p.use_hero("Audio // Display // Tutorial", "SETTINGS")
	# one way out: the X beside the hero (and Esc / a click outside)
	(p.card.get_node("VBox/Buttons") as Control).visible = false
	var section := func(t: String) -> void:
		var l := Label.new()
		l.text = t
		l.theme_type_variation = &"HeaderLabel"
		p.add_content(l)
	var slider_row := func(t: String, value: float, on_change: Callable) -> void:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var l := Label.new()
		l.text = t
		l.theme_type_variation = &"TitleLabel"
		l.custom_minimum_size = Vector2(96, 0)
		row.add_child(l)
		var sl := HSlider.new()
		sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sl.min_value = 0.0; sl.max_value = 1.0; sl.step = 0.05
		sl.value = value
		var pct := Label.new()
		pct.theme_type_variation = &"MonoLabel"
		pct.custom_minimum_size = Vector2(34, 0)
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct.text = "%d%%" % roundi(value * 100.0)
		sl.value_changed.connect(func(v: float) -> void:
			pct.text = "%d%%" % roundi(v * 100.0)
			on_change.call(v))
		row.add_child(sl)
		row.add_child(pct)
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
	_add_theme_builder(p)
	p.add_content(HSeparator.new())
	var tut_row := HBoxContainer.new()
	var tut_lbl := Label.new()
	tut_lbl.text = "Tutorial"
	tut_lbl.theme_type_variation = &"TitleLabel"
	tut_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tut_row.add_child(tut_lbl)
	var reset_btn := IconButton.create_text("RESET TUTORIAL", IconButton.Variant.NEUTRAL)
	reset_btn.pressed.connect(func() -> void:
		SettingsManager.tutorial_ever_done = false
		SettingsManager.save_settings()
		TutorialManager.tutorial_enabled = true
		AudioManager.play("ui_click"))
	tut_row.add_child(reset_btn)
	p.add_content(tut_row)

## Credits / science changes show through the resource bar's gain animation.
func _on_credits_changed(_new_val: float) -> void:
	pass

func _on_science_changed(_new_val: float) -> void:
	pass

func _process(delta: float) -> void:
	_update_shortcut_fallback()
	_update_trait_notice(delta)
	_res_poll += delta
	if _res_poll >= 0.25:
		_res_poll = 0.0
		_maybe_show_offline()
		_maybe_celebrate_moon()
		for b: Button in _explore_btns:
			if is_instance_valid(b):
				b.visible = GameState.explore_available()
		for b: Button in _trade_btns:
			if is_instance_valid(b):
				b.visible = Trade.has_access()

## The demo's high point: the first City on the Moon, in the news bar.
func _maybe_celebrate_moon() -> void:
	if GameState.moon_city_celebrated or GameState.showcase_mode or not SkillTree.event_met("moon_city"):
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path.ends_with("MainMenu.tscn"):
		return
	GameState.moon_city_celebrated = true
	AudioManager.play("building_done")
	NewsFeed.post("First step on the Moon: your civilization now spans two worlds.")

## The final rocket left the Moon: the news bar tells it; clicking the item
## opens the star system view, where its flight is drawn.
func _on_expedition_changed(kind: String) -> void:
	if kind != "rocket" or GameState.expedition_state("rocket") != "in_transit":
		return
	var tgt := GameState.get_planet_data(int(GameState.expedition("rocket").get("target_seed", -1)))
	AudioManager.play("building_done")
	NewsFeed.post("The final rocket leaves for %s. Click to watch its flight." % (tgt.planet_name if tgt != null else "a new world"),
		NewsFeed.Kind.EVENT, "", "", {"solar": true})

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
	# the hero's caption says how long ("Away for 4 min")
	var body := "Offline progress is switched on in this profile, but it isn't implemented yet — nothing was produced." \
		if GameState.offline_progress_enabled() \
		else "Nothing was produced while the game was closed. Your economy picks up where you left it."
	ConfirmPanel.ask(self, "WELCOME BACK", body, "CONTINUE", Callable(), false) \
		.use_hero("Away for %s" % _duration_text(GameState.offline_seconds), "WELCOME BACK")

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

## The HUD's own shortcut row only shows in views without a LeftPanel; while a
## view's panel is closed its shortcuts go with it.
func _update_shortcut_fallback() -> void:
	if science_panel == null or not is_instance_valid(science_panel):
		return
	science_panel.visible = get_tree().get_nodes_in_group(LeftPanel.GROUP).is_empty()

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
	icon_lbl.add_theme_color_override("font_color", UIStyle.color(&"neutral_stroke"))
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
	header.add_theme_color_override("font_color", Color(UIStyle.color(&"neutral_stroke"), 0.75))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(header)

	var title_lbl := Label.new()
	title_lbl.text = def.title
	if _orbitron: title_lbl.add_theme_font_override("font", _orbitron)
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", UIStyle.color(&"neutral_stroke"))
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	if def.description != "":
		var desc_lbl := Label.new()
		desc_lbl.text = def.description
		if _orbitron: desc_lbl.add_theme_font_override("font", _orbitron)
		desc_lbl.add_theme_font_size_override("font_size", 9)
		desc_lbl.add_theme_color_override("font_color", Color(UIStyle.color(&"text_subtle"), 0.85))
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(desc_lbl)

	panel.anchor_right  = 1.0
	panel.anchor_bottom = 1.0
	panel.anchor_left   = 1.0
	panel.anchor_top    = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical   = Control.GROW_DIRECTION_BEGIN
	var above := 12.0   # bottom-right corner (the shortcut row is on the left)
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

## The Upgrade Tree button the player can see (the LeftPanel's, else the HUD's).
func _visible_skill_btn() -> Button:
	for i in range(_skill_btns.size() - 1, -1, -1):
		var b := _skill_btns[i]
		if is_instance_valid(b) and b.is_visible_in_tree():
			return b
	return null

func _on_tut_highlight(target: String) -> void:
	var btn := _visible_skill_btn()
	if target != "skill_tree_btn" or btn == null: return
	if is_instance_valid(_skill_btn_tween): _skill_btn_tween.kill()
	_skill_btn_tween = create_tween().set_loops()
	_skill_btn_tween.tween_property(btn, "modulate", Color(1.6, 1.5, 0.6, 1.0), 0.5)
	_skill_btn_tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

func _on_tut_highlight_clear() -> void:
	if is_instance_valid(_skill_btn_tween): _skill_btn_tween.kill(); _skill_btn_tween = null
	for b: Button in _skill_btns:
		if is_instance_valid(b): b.modulate = Color.WHITE



# ── End of Act I (demo) ──────────────────────────────────────────────────────

## Shown once, when the final rocket arrives: Civilization 0 is complete.
func _show_act1_complete() -> void:
	# scenes/ui/DemoEndScreen.tscn — texts and layout are edited in the scene
	var layer := CanvasLayer.new()
	layer.layer = 240
	get_tree().root.add_child(layer)
	layer.add_child((load("res://scenes/ui/DemoEndScreen.tscn") as PackedScene).instantiate())
