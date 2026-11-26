class_name NewGamePanel
extends ModalPopup

## NEW GAME's preparation window (SessionPrep.open; layout:
## scenes/ui/NewGamePanel.tscn), laid out as an excavation (StoryDialog): the
## preview (NewGamePreview: the home world of the seed, turning, with its moon)
## large and without a background above, the hero (and its ✕) right under it,
## and at the top of the screen a trail of the steps (CIVILIZATION TYPE › START WORLD ›
## COLONY SETUP: the ones reached can be pressed to go back to them, the ones
## ahead wait, dim), then one panel in three steps:
##   1 Civ    CIVILIZATION on a slider, 0 to 6 (only 0 is played for now;
##            the others show their scale, locked)                     (NEXT)
##   2 Start  START WORLD, MOON and what the option is           (BACK, NEXT)
##   3 Rest   COLONY TRAIT, identity, and the world's name and seed
##            (BACK, TUTORIAL, BEGIN)
## The rows of options are made from SessionPrep's tables. The preview shows
## the option pressed last (a locked one too, though it isn't chosen), with the
## seed of the moment; hovering only tells about it. The choices go to
## GameState.pending_setup (see SessionPrep). A ModalPopup without a PopupCard:
## its parts are its own (the dim, the hero's ✕, Esc).

## Set before it enters the tree (SessionPrep.open): the main menu (its
## planets give way to the preview), and what BEGIN runs.
var host: Node = null
var begin: Callable

@onready var _hero: HeroHeader = $Center/Box/Head/Hero
@onready var _head: Control = $Center/Box/Head
@onready var _pv: NewGamePreview = $Center/Box/Stage/Preview
@onready var _crumbs: HBoxContainer = $Crumbs
@onready var _pages: PanelContainer = $Center/Box/Pages
@onready var _steps: VBoxContainer = $Center/Box/Pages/Steps
@onready var _civ: VBoxContainer = $Center/Box/Pages/Steps/Civ
@onready var _civ_slider: HSlider = $Center/Box/Pages/Steps/Civ/CivSlider
@onready var _civ_name: Label = $Center/Box/Pages/Steps/Civ/CivName
@onready var _civ_info: RichTextLabel = $Center/Box/Pages/Steps/Civ/CivInfo
@onready var _start: VBoxContainer = $Center/Box/Pages/Steps/Start
@onready var _rest: VBoxContainer = $Center/Box/Pages/Steps/Rest
@onready var _info: RichTextLabel = $Center/Box/Pages/Steps/Start/Info
@onready var _trait_head: Label = $Center/Box/Pages/Steps/Rest/TraitHead
@onready var _traits: GridContainer = $Center/Box/Pages/Steps/Rest/Traits
@onready var _trait_desc: RichTextLabel = $Center/Box/Pages/Steps/Rest/TraitDesc
@onready var _trait_rule: HSeparator = $Center/Box/Pages/Steps/Rest/Rule
@onready var _leader_edit: LineEdit = $Center/Box/Pages/Steps/Rest/IdentityRow/LeaderName
@onready var _colony_edit: LineEdit = $Center/Box/Pages/Steps/Rest/IdentityRow/ColonyName
@onready var _logo: OptionButton = $Center/Box/Pages/Steps/Rest/IdentityRow/Logo
@onready var _name_edit: LineEdit = $Center/Box/Pages/Steps/Rest/SeedRow/NameEdit
@onready var _seed_edit: LineEdit = $Center/Box/Pages/Steps/Rest/SeedRow/SeedEdit
@onready var _dice: IconButton = $Center/Box/Pages/Steps/Rest/SeedRow/Random
@onready var _buttons: HBoxContainer = $Center/Box/Buttons
@onready var _back: IconButton = $Center/Box/Buttons/Back
@onready var _tut: IconButton = $Center/Box/Buttons/Tutorial
@onready var _ok: IconButton = $Center/Box/Buttons/Begin
@onready var _next: IconButton = $Center/Box/Buttons/Next

var _choice := {}
var _begun := false        # BEGIN: the game opens, the menu's planets stay away
var _switching := false    # a step is fading out
var _last_look: Callable   # the preview's look: the option pressed last (the seed may change)
var _start_info := ""     # the world or moon description selected by pressing its button
var _trait_btns := {}
var _tutorial_required := false
var _free_seed_text := ""
var _step := 1
var _reached := 1          # the furthest step opened so far (the trail lets you back to it)
const STEPS := 3
## The trail's names, one per step.
const STEP_NAMES := ["CIVILIZATION TYPE", "START WORLD", "COLONY SETUP"]
var _crumb_btns: Array[Button] = []

func _ready() -> void:
	_hero_close = $Center/Box/Head/Close
	_hero_close.pressed.connect(close)
	# a click on the dim background no longer closes it (revision 12.11: the
	# choices were lost by a stray click); the ✕ and Esc still do. The Dim
	# still takes the click, so nothing behind it reacts.
	(_hero.get_node("Title") as Label).autowrap_mode = TextServer.AUTOWRAP_OFF   # one line
	_tutorial_required = not SettingsManager.tutorial_ever_done
	_free_seed_text = SessionPrep._random_seed_text()
	_choice = {"world": "terran", "moon": "rocky", "civ": "c0", "colony_trait": "",
		"tutorial": _tutorial_required, "seed": SessionPrep.SEED_MIN,
		"seed_text": "", "name": ""}
	# the main menu's planets give way to the preview while it is open
	_menu_planets(false)
	closed.connect(func() -> void:
		TooltipManager.hide_tip()
		if not _begun:
			_menu_planets(true))
	_pv.reveal(SessionPrep.PREVIEW_DELAY, SessionPrep.PREVIEW_IN)
	_build_seed()
	_apply_start_options()
	_build_civ()
	_build_start()
	_build_traits()
	_build_logos()
	_build_buttons()

func cancel_button() -> IconButton:
	return null

func confirm_button() -> IconButton:
	return _ok

## The main menu (`host`) hides or shows its planets, if it has them.
func _menu_planets(on: bool) -> void:
	if is_instance_valid(host) and host.has_method(&"set_planets_shown"):
		host.call(&"set_planets_shown", on)

# ── The world: its name and seed ─────────────────────────────────────────────

func _show_choice() -> void:
	_pv.show_home(int(_choice["seed"]), String(_choice["moon"]))

func _show_last() -> void:
	if _last_look.is_valid():
		_last_look.call()
	else:
		_show_choice()

func _set_seed(text: String) -> void:
	var t := SessionPrep.TUTORIAL_SEED_CODE
	if not _uses_tutorial():
		t = text.strip_edges()
		if t.is_empty():
			t = SessionPrep._random_seed_text()
		_free_seed_text = t
	_choice["seed_text"] = t
	_choice["seed"] = SessionPrep.seed_of(t)
	_seed_edit.text = t
	if String(_choice["name"]) == "":   # not renamed: the new world's own name
		_name_edit.text = SessionPrep._home_name(int(_choice["seed"]))
	_show_last()

## The world's name: the seed's own until the player writes another (11.11).
func _set_name(t: String) -> void:
	var n := t.strip_edges()
	var own := SessionPrep._home_name(int(_choice["seed"]))
	_choice["name"] = "" if n == "" or n == own else n
	_name_edit.text = n if n != "" else own

func _build_seed() -> void:
	_seed_edit.text_submitted.connect(func(t: String) -> void:
		_set_seed(t)
		_seed_edit.release_focus())
	_seed_edit.focus_exited.connect(func() -> void:
		if not _uses_tutorial() and _seed_edit.text.strip_edges() != String(_choice["seed_text"]):
			_set_seed(_seed_edit.text))
	_name_edit.text_submitted.connect(func(t: String) -> void:
		_set_name(t)
		_name_edit.release_focus())
	_name_edit.focus_exited.connect(func() -> void: _set_name(_name_edit.text))
	_dice.pressed.connect(func() -> void:
		AudioManager.play("click")
		_set_seed(SessionPrep._random_seed_text()))

# ── Step 1: the civilization ─────────────────────────────────────────────────

## The slider names the current civilization and previews its next target.
## Only an open one is chosen; on a locked one NEXT waits.
func _on_civ(v: float) -> void:
	var n := clampi(int(v), 0, SessionPrep.CIV_ORDER.size() - 1)
	var id := String(SessionPrep.CIV_ORDER[n])
	var d: Array = SessionPrep.CIVS[id]
	var open_now := bool(d[3])
	_civ_name.text = String(d[0])
	_civ_name.modulate = Color.WHITE if open_now else Color(1, 1, 1, 0.55)
	_show_description(_civ_info, _info_of(SessionPrep.CIVS, id, open_now))
	if open_now:
		_choice["civ"] = id
	_next.disabled = not open_now and _step == 1
	_paint_crumbs()
	_last_look = func() -> void:
		var home_seed := int(_choice["seed"])
		match n:
			0: _show_choice()
			1: _pv.show_solar(home_seed)
			_: _pv.show_civilization_target(home_seed, n + 1)
	_show_last()

## The stops' numbers: white where the civilization is open, grey where it
## is locked; each right under its tick (placed by _place_civ_scale).
const CIV_OPEN := Color(1, 1, 1)
const CIV_LOCKED := Color(0.5, 0.53, 0.58)

## Each number centred under its tick: Godot draws the ticks across the
## slider's width less the handle's, starting half a handle in.
func _place_civ_scale() -> void:
	var scale_row := $Center/Box/Pages/Steps/Civ/CivScale as Control
	var n := scale_row.get_child_count()
	if n < 2:
		return
	var grab := float(_civ_slider.get_theme_icon(&"grabber").get_width())
	var area := _civ_slider.size.x - grab
	var off := _civ_slider.global_position.x - scale_row.global_position.x
	for i in n:
		var l := scale_row.get_child(i) as Label
		var w := l.get_combined_minimum_size().x
		l.size = Vector2(w, scale_row.size.y)
		l.position = Vector2(off + grab * 0.5 + area * float(i) / float(n - 1) - w * 0.5, 0.0)

func _build_civ() -> void:
	var scale_row := $Center/Box/Pages/Steps/Civ/CivScale as Control
	for i in SessionPrep.CIV_ORDER.size():
		var l := Label.new()
		l.text = str(i)
		l.theme_type_variation = &"SubLabel"
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var open_now := bool(SessionPrep.CIVS[String(SessionPrep.CIV_ORDER[i])][3])
		l.add_theme_color_override(&"font_color", CIV_OPEN if open_now else CIV_LOCKED)
		scale_row.add_child(l)
	_civ_slider.resized.connect(_place_civ_scale)
	scale_row.resized.connect(_place_civ_scale)
	_place_civ_scale.call_deferred()
	_civ_slider.max_value = SessionPrep.CIV_ORDER.size() - 1
	_civ_slider.value = SessionPrep.CIV_ORDER.find(String(_choice["civ"]))
	_civ_slider.value_changed.connect(func(v: float) -> void:
		AudioManager.play("hover")
		_on_civ(v))
	_on_civ(_civ_slider.value)

# ── Step 2: the start ────────────────────────────────────────────────────────

## A closed start option reads like any other on hover (playtest 12.11: a
## LOCKED tag up front kept players from clicking); "Locked." once clicked.
func _info_of(defs: Dictionary, id: String, open_now: bool, clicked := true) -> String:
	var dim := UIStyle.hex(&"text_subtle")
	var description := "[color=#%s]%s[/color]" % [dim, String(defs[id][2])]
	if open_now or not clicked:
		return description
	if defs == SessionPrep.WORLDS and SettingsManager.unlocked_starts.has(id):
		return "[color=#%s]Unlocked. Starting here comes in a later build.[/color]\n%s" % [dim, description]
	return "[color=#%s]Locked.[/color]  %s" % [UIStyle.hex(&"bad"), description]

func _show_description(label: RichTextLabel, description: String) -> void:
	if label.text != description:
		label.text = description
		label.scroll_to_line(0)

## One row of three for a choice; `look` shows an option in the preview (pressed).
func _add_row(row: HBoxContainer, key: String, defs: Dictionary, order: Array, look: Callable) -> void:
	var btns := {}
	var paint := func() -> void:
		for id: String in btns:
			(btns[id] as IconButton).variant = IconButton.Variant.NEUTRAL if id == _choice[key] \
				else IconButton.Variant.DEFAULT
	for id: String in order:
		var d: Array = defs[id]
		var open_now := bool(d[3]) and (defs != SessionPrep.WORLDS or SessionPrep._world_open(id))
		var b := IconButton.create(String(d[0]), String(d[1]), IconButton.Variant.DEFAULT)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not open_now:
			b.modulate = Color(1, 1, 1, 0.8)
		b.mouse_entered.connect(func() -> void:
			_show_description(_info, _info_of(defs, id, open_now, false)))
		b.mouse_exited.connect(func() -> void: _show_description(_info, _start_info))
		b.pressed.connect(func() -> void:
			_start_info = _info_of(defs, id, open_now)
			_show_description(_info, _start_info)
			_last_look = look.bind(id, open_now)
			_show_last()
			if not open_now:
				AudioManager.play("error")
				return
			AudioManager.play("click")
			_choice[key] = id
			paint.call())
		row.add_child(b)
		btns[id] = b
	paint.call()

func _build_start() -> void:
	_add_row($Center/Box/Pages/Steps/Start/WorldRow, "world", SessionPrep.WORLDS, SessionPrep.WORLD_ORDER,
		func(id: String, _o: bool) -> void:
			if id == "terran":
				_show_choice()
			else:
				_pv.show_world(int(_choice["seed"]), PlanetData.Type.ARID if id == "red" else PlanetData.Type.ICE))
	_add_row($Center/Box/Pages/Steps/Start/MoonRow, "moon", SessionPrep.MOONS, SessionPrep.MOON_ORDER,
		func(id: String, _o: bool) -> void:
			_pv.show_home(int(_choice["seed"]), id, true))
	_start_info = _info_of(SessionPrep.WORLDS, String(_choice["world"]), true)
	_show_description(_info, _start_info)

# Step 3: the colony's identity and its lasting trait.

func _show_trait(id: String) -> void:
	var trait_def: Dictionary = SessionPrep.COLONY_TRAITS.get(id, {})
	if trait_def.is_empty():
		_show_description(_trait_desc, "Choose one trait for this colony.")
		return
	_show_description(_trait_desc, "[color=#%s]%s[/color]\n%s" % [
		UIStyle.hex(&"good"), trait_def["effect"], trait_def["story"]])

func _paint_traits() -> void:
	for id: String in _trait_btns:
		(_trait_btns[id] as IconButton).variant = IconButton.Variant.NEUTRAL if id == _choice["colony_trait"] \
			else IconButton.Variant.DEFAULT
	_ok.disabled = not _uses_tutorial() and String(_choice["colony_trait"]).is_empty()

func _build_traits() -> void:
	for id: String in SessionPrep.COLONY_TRAITS:
		var trait_def: Dictionary = SessionPrep.COLONY_TRAITS[id]
		var b := IconButton.create(String(trait_def["title"]).to_upper(), String(trait_def["resource"]))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_entered.connect(func() -> void: _show_trait(id))
		b.mouse_exited.connect(func() -> void: _show_trait(String(_choice["colony_trait"])))
		b.focus_entered.connect(func() -> void: _show_trait(id))
		b.focus_exited.connect(func() -> void: _show_trait(String(_choice["colony_trait"])))
		b.pressed.connect(func() -> void:
			AudioManager.play("click")
			_choice["colony_trait"] = id
			_paint_traits()
			_show_trait(id))
		_traits.add_child(b)
		b.focus_mode = Control.FOCUS_ALL
		_trait_btns[id] = b
	_paint_traits()
	_show_trait("")

func _build_logos() -> void:
	if GameState.demo_build:
		_logo.add_icon_item(UIIcons.get_icon("flag"), "LOGO LOCKED")
		_logo.select(0)
		_logo.tooltip_text = "Colony logo selection is locked in the demo."
		_logo.disabled = true
		return
	_logo.add_icon_item(UIIcons.get_icon("flag"), "No logo")
	_logo.set_item_metadata(0, "")
	for id: String in SessionPrep.COLONY_LOGOS:
		_logo.add_icon_item(UIIcons.get_icon(id), String(SessionPrep.COLONY_LOGOS[id]))
		_logo.set_item_metadata(_logo.item_count - 1, id)
	_logo.select(0)

# ── The buttons and the steps ────────────────────────────────────────────────

func _uses_tutorial() -> bool:
	return _tutorial_required or bool(_choice["tutorial"])

func _tut_tip() -> void:
	if _tutorial_required:
		TooltipManager.show_tip("Guided tutorial", "Complete the tutorial once to unlock custom seeds and colony traits.")
	elif _uses_tutorial():
		TooltipManager.show_tip("Tutorial on", "Use the fixed tutorial world and economy.")
	else:
		TooltipManager.show_tip("Tutorial off", "Choose your seed and colony trait for an unguided game.")

func _apply_start_options() -> void:
	var guided := _uses_tutorial()
	_tut.icon_name = "confirm" if guided else "empty"
	_tut.disabled = _tutorial_required
	_trait_head.visible = not guided
	_traits.visible = not guided
	_trait_desc.visible = not guided
	_trait_rule.visible = not guided
	_seed_edit.visible = not guided
	_dice.visible = not guided
	_set_seed(_free_seed_text)
	_paint_traits()

func _build_buttons() -> void:
	_tut.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		_tut_tip())
	_tut.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	_tut.pressed.connect(func() -> void:
		if _tutorial_required:
			return
		AudioManager.play("click")
		_choice["tutorial"] = not bool(_choice["tutorial"])
		_apply_start_options()
		_tut_tip())
	_next.pressed.connect(func() -> void:
		AudioManager.play("click")
		_go_step(mini(_step + 1, STEPS)))
	_back.pressed.connect(func() -> void:
		AudioManager.play("click")
		_go_step(maxi(_step - 1, 1)))
	_ok.pressed.connect(_on_begin)
	_build_crumbs()
	# every step shown (unseen) while the panel measures them, then the first
	_show_step(1)
	_start.visible = true
	_rest.visible = true
	_head.modulate.a = 0.0
	_crumbs.modulate.a = 0.0
	_buttons.modulate.a = 0.0
	_hold_height(func() -> void:
		_show_step(1)
		_head.modulate.a = 1.0
		_crumbs.modulate.a = 1.0
		_buttons.modulate.a = 1.0
		RowReveal.play(_head, SessionPrep.REVEAL_SLOW)
		RowReveal.play(_crumbs, SessionPrep.REVEAL_SLOW)
		_reveal(1))

# ── The trail of steps ───────────────────────────────────────────────────────

## One flat button per step, a › between them.
func _build_crumbs() -> void:
	for i in STEPS:
		if i > 0:
			var sep := Label.new()
			sep.text = "›"
			sep.theme_type_variation = &"SubLabel"
			sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_crumbs.add_child(sep)
		var b := Button.new()
		b.text = String(STEP_NAMES[i])
		b.theme_type_variation = UIStyle.FLAT
		b.focus_mode = Control.FOCUS_NONE
		var step := i + 1
		b.pressed.connect(func() -> void:
			if step == _step:
				return
			AudioManager.play("click")
			_go_step(step))
		_crumbs.add_child(b)
		_crumb_btns.append(b)
	_paint_crumbs()

## The step shown in the accent; the ones reached pressable; the ones ahead dim
## (and, on a locked civilization, nothing ahead of step 1 opens).
func _paint_crumbs() -> void:
	var held := _step == 1 and _next.disabled
	for i in _crumb_btns.size():
		var b := _crumb_btns[i]
		var step := i + 1
		var current := step == _step
		var reachable := step <= _reached and not (held and step > 1)
		b.disabled = not current and not reachable
		b.mouse_default_cursor_shape = Control.CURSOR_ARROW if current or b.disabled \
			else Control.CURSOR_POINTING_HAND
		if current:
			for c: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
				b.add_theme_color_override(c, UIStyle.color(&"accent"))
		else:
			for c: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color"]:
				b.remove_theme_color_override(c)

func _page(step: int) -> Control:
	return [_civ, _start, _rest][clampi(step, 1, STEPS) - 1]

## The step shown: 1 the civilization (NEXT), 2 the start (BACK, NEXT),
## 3 the rest (BACK, TUTORIAL, BEGIN).
func _show_step(step: int) -> void:
	TooltipManager.hide_tip()
	_step = step
	for i in range(1, STEPS + 1):
		_page(i).visible = i == step
	_next.visible = step < STEPS
	_back.visible = step > 1
	_tut.visible = step == STEPS
	_ok.visible = step == STEPS
	_next.disabled = step == 1 and _civ_slider.value != SessionPrep.CIV_ORDER.find(String(_choice["civ"]))
	_hero.caption = "Prepare your colony  //  %d / %d" % [step, STEPS]
	_reached = maxi(_reached, step)
	_paint_crumbs()

## Its rows come in (and the buttons under it).
func _reveal(step: int) -> void:
	RowReveal.play(_page(step), SessionPrep.REVEAL_SLOW, false, SessionPrep.REVEAL_SOUND)
	RowReveal.play(_buttons, SessionPrep.REVEAL_SLOW)

## The step shown fades out, then the other comes in.
func _go_step(step: int) -> void:
	if _switching:
		return
	_switching = true
	var old: Control = _page(_step)
	var tw := old.create_tween().set_parallel(true)
	tw.tween_property(old, "modulate:a", 0.0, SessionPrep.STEP_OUT)
	tw.tween_property(_buttons, "modulate:a", 0.0, SessionPrep.STEP_OUT)
	tw.chain().tween_callback(func() -> void:
		old.modulate.a = 1.0
		_buttons.modulate.a = 1.0
		_show_step(step)
		_reveal(step)
		_switching = false)

func _on_begin() -> void:
	var guided := _uses_tutorial()
	if not guided and String(_choice["colony_trait"]).is_empty():
		return
	AudioManager.play("click")
	if not guided and _seed_edit.text.strip_edges() != String(_choice["seed_text"]):
		_set_seed(_seed_edit.text)
	_set_name(_name_edit.text)
	var setup := _choice.duplicate()
	setup["tutorial"] = guided
	setup["colony_leader_name"] = _leader_edit.text.strip_edges()
	setup["colony_name"] = _colony_edit.text.strip_edges()
	if not GameState.demo_build and _logo.selected >= 0:
		setup["colony_logo"] = String(_logo.get_item_metadata(_logo.selected))
	if guided:
		setup["seed"] = SessionPrep.tutorial_seed()
		setup["colony_trait"] = ""
		setup["world"] = "terran"
		setup["moon"] = "rocky"
		setup["civ"] = "c0"
	GameState.pending_setup = setup
	TooltipManager.hide_tip()
	_begun = true
	close()
	if begin.is_valid():
		begin.call()

# ── Measuring ────────────────────────────────────────────────────────────────

## Holds the steps as tall as the tallest, so switching never moves the hero or
## the buttons. The panel stays unseen until the rows finish laying out.
func _hold_height(done: Callable) -> void:
	_pages.modulate.a = 0.0
	for i in 3:
		await get_tree().process_frame
		if not is_inside_tree():
			return
	var h := 0.0
	for st: Control in [_civ, _start, _rest]:
		h = maxf(h, st.get_combined_minimum_size().y)
	_steps.custom_minimum_size.y = h
	done.call()
	var stage := _pv.get_parent() as Control
	var box := stage.get_parent() as VBoxContainer
	var overflow := box.get_combined_minimum_size().y + 64.0 - get_viewport_rect().size.y
	if overflow > 0.0:
		stage.custom_minimum_size.y = maxf(stage.custom_minimum_size.y - overflow, 0.0)
	_pages.create_tween().tween_property(_pages, "modulate:a", 1.0, 0.15)
