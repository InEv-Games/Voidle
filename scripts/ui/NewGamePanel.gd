class_name NewGamePanel
extends ModalPopup

## NEW GAME's preparation window (SessionPrep.open; layout:
## scenes/ui/NewGamePanel.tscn), laid out as an excavation (StoryDialog): the
## preview (NewGamePreview: the home world of the seed, turning, with its moon)
## large and without a background above, the hero (and its ✕) right under it,
## and under the hero one panel in three steps:
##   1 Civ    CIVILIZATION on a slider, 0 to 7 (only 0 is played for now;
##            the others show their scale, locked)                     (NEXT)
##   2 Start  START WORLD, MOON and what the option is           (BACK, NEXT)
##   3 Rest   HEAD START, and the world's name and seed (typed or RANDOM)
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
@onready var _pages: PanelContainer = $Center/Box/Pages
@onready var _steps: VBoxContainer = $Center/Box/Pages/Steps
@onready var _civ: VBoxContainer = $Center/Box/Pages/Steps/Civ
@onready var _civ_slider: HSlider = $Center/Box/Pages/Steps/Civ/CivSlider
@onready var _civ_name: Label = $Center/Box/Pages/Steps/Civ/CivName
@onready var _civ_info: RichTextLabel = $Center/Box/Pages/Steps/Civ/CivInfo
@onready var _start: VBoxContainer = $Center/Box/Pages/Steps/Start
@onready var _rest: VBoxContainer = $Center/Box/Pages/Steps/Rest
@onready var _info: RichTextLabel = $Center/Box/Pages/Steps/Start/Info
@onready var _boons: GridContainer = $Center/Box/Pages/Steps/Rest/Boons
@onready var _boon_desc: RichTextLabel = $Center/Box/Pages/Steps/Rest/BoonDesc
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
var _boon_btns := {}
var _step := 1
const STEPS := 3

func _ready() -> void:
	_hero_close = $Center/Box/Head/Close
	_hero_close.pressed.connect(close)
	($Dim as Control).gui_input.connect(func(e: InputEvent) -> void:
		if dismissable and e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			close())
	(_hero.get_node("Title") as Label).autowrap_mode = TextServer.AUTOWRAP_OFF   # one line
	_choice = {"world": "terran", "moon": "rocky", "civ": "c0", "boon": "",
		"tutorial": not SettingsManager.tutorial_ever_done, "seed": SessionPrep.SEED_MIN,
		"seed_text": SessionPrep._random_seed_text(), "name": ""}
	# the main menu's planets give way to the preview while it is open
	_menu_planets(false)
	closed.connect(func() -> void:
		TooltipManager.hide_tip()
		if not _begun:
			_menu_planets(true))
	_pv.reveal(SessionPrep.PREVIEW_DELAY, SessionPrep.PREVIEW_IN)
	_hold_lines(_info, 2)
	_hold_lines(_boon_desc, 2)
	_hold_lines(_civ_info, 2)
	_build_seed()
	_build_civ()
	_build_start()
	_build_boons()
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
	var t := text.strip_edges()
	if t == "":
		t = SessionPrep._random_seed_text()
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
		if _seed_edit.text.strip_edges() != String(_choice["seed_text"]):
			_set_seed(_seed_edit.text))
	_name_edit.text_submitted.connect(func(t: String) -> void:
		_set_name(t)
		_name_edit.release_focus())
	_name_edit.focus_exited.connect(func() -> void: _set_name(_name_edit.text))
	_dice.pressed.connect(func() -> void:
		AudioManager.play("click")
		_set_seed(SessionPrep._random_seed_text()))
	_set_seed(String(_choice["seed_text"]))

# ── Step 1: the civilization ─────────────────────────────────────────────────

## The slider's stop: its name, what it is (locked or not) and its scale in the
## preview (0: the home world; 1: the seed's star system; 2 and on: its
## galaxy). Only an open one is chosen; on a locked one NEXT waits.
func _on_civ(v: float) -> void:
	var id := String(SessionPrep.CIV_ORDER[clampi(int(v), 0, SessionPrep.CIV_ORDER.size() - 1)])
	var d: Array = SessionPrep.CIVS[id]
	var open_now := bool(d[3])
	_civ_name.text = String(d[0])
	_civ_name.modulate = Color.WHITE if open_now else Color(1, 1, 1, 0.55)
	_civ_info.text = _info_of(SessionPrep.CIVS, id, open_now)
	if open_now:
		_choice["civ"] = id
	_next.disabled = not open_now and _step == 1
	var n := int(v)
	_last_look = (func() -> void: _show_choice()) if n == 0 \
		else (func() -> void: _pv.show_solar(int(_choice["seed"]))) if n == 1 \
		else (func() -> void: _pv.show_galaxy(int(_choice["seed"])))
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

func _info_of(defs: Dictionary, id: String, open_now: bool) -> String:
	var dim := UIStyle.hex(&"text_subtle")
	if open_now:
		return "[color=#%s]%s[/color]" % [dim, String(defs[id][2])]
	if defs == SessionPrep.WORLDS and SettingsManager.unlocked_starts.has(id):
		return "[color=#%s]Unlocked. Starting here comes in a later build.[/color]" % dim
	return "[color=#%s]Locked.[/color]  [color=#%s]%s[/color]" % [UIStyle.hex(&"bad"), dim, String(defs[id][2])]

func _chosen_info() -> void:
	_info.text = _info_of(SessionPrep.WORLDS, String(_choice["world"]), true)

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
		var b := IconButton.create(String(d[0]), String(d[1]), IconButton.Variant.DEFAULT,
			"" if open_now else "LOCKED")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not open_now:
			b.modulate = Color(1, 1, 1, 0.55)
		b.mouse_entered.connect(func() -> void: _info.text = _info_of(defs, id, open_now))
		b.mouse_exited.connect(_chosen_info)
		b.pressed.connect(func() -> void:
			_info.text = _info_of(defs, id, open_now)
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
	_chosen_info()

# ── Step 3: the head start ───────────────────────────────────────────────────

func _show_boon(id: String) -> void:
	_boon_desc.text = "[color=#%s]%s[/color]%s" % [UIStyle.hex(&"text_subtle"), String(SessionPrep.BOONS[id][2]),
		("  " + SessionPrep._bonus_bb()) if id == "" else ""]

func _paint_boons() -> void:
	for id: String in _boon_btns:
		(_boon_btns[id] as IconButton).variant = IconButton.Variant.NEUTRAL if id == _choice["boon"] \
			else IconButton.Variant.DEFAULT

func _build_boons() -> void:
	for id: String in SessionPrep.BOON_ORDER:
		var bn: Array = SessionPrep.BOONS[id]
		var b := IconButton.create(String(bn[0]), String(bn[1]), IconButton.Variant.DEFAULT)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.mouse_entered.connect(func() -> void: _show_boon(id))
		b.mouse_exited.connect(func() -> void: _show_boon(String(_choice["boon"])))
		b.pressed.connect(func() -> void:
			AudioManager.play("click")
			_choice["boon"] = id
			_paint_boons()
			_show_boon(id))
		_boons.add_child(b)
		_boon_btns[id] = b
	_paint_boons()
	_show_boon("")

# ── The buttons and the steps ────────────────────────────────────────────────

## TUTORIAL: guided (the advisor leads) or the optional checklist; its tip says.
func _tut_tip() -> void:
	var on := bool(_choice["tutorial"])
	TooltipManager.show_tip("Guided tutorial" if on else "First steps checklist",
		"On: your advisor leads you step by step through the first City.\n\nOff: an optional checklist instead; do the first steps in any order, or skip it and take all its rewards." \
		+ "\n\nNow: %s." % ("on" if on else "off"))

func _paint_tut() -> void:
	_tut.icon_name = "confirm" if bool(_choice["tutorial"]) else "empty"

func _build_buttons() -> void:
	_tut.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		_tut_tip())
	_tut.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())
	_tut.pressed.connect(func() -> void:
		AudioManager.play("click")
		_choice["tutorial"] = not bool(_choice["tutorial"])
		_paint_tut()
		_tut_tip())
	_paint_tut()
	_next.pressed.connect(func() -> void:
		AudioManager.play("click")
		_go_step(mini(_step + 1, STEPS)))
	_back.pressed.connect(func() -> void:
		AudioManager.play("click")
		_go_step(maxi(_step - 1, 1)))
	_ok.pressed.connect(_on_begin)
	# every step shown (unseen) while the panel measures them, then the first
	_show_step(1)
	_start.visible = true
	_rest.visible = true
	_head.modulate.a = 0.0
	_buttons.modulate.a = 0.0
	_hold_height(func() -> void:
		_show_step(1)
		_head.modulate.a = 1.0
		_buttons.modulate.a = 1.0
		RowReveal.play(_head, SessionPrep.REVEAL_SLOW)
		_reveal(1))

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
	AudioManager.play("click")
	if _seed_edit.text.strip_edges() != String(_choice["seed_text"]):
		_set_seed(_seed_edit.text)
	_set_name(_name_edit.text)
	GameState.pending_setup = _choice.duplicate()
	TooltipManager.hide_tip()
	_begun = true
	close()
	if begin.is_valid():
		begin.call()

# ── Measuring ────────────────────────────────────────────────────────────────

## Holds the steps as tall as the tallest, so switching never moves the hero or
## the buttons. The panel stays unseen until the fixed-height texts have
## measured themselves on screen (_hold_lines); then `done` shows the first step.
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
	_pages.create_tween().tween_property(_pages, "modulate:a", 1.0, 0.15)

## `r` is always `lines` lines tall, so a longer text doesn't resize the window
## (11.11: hovering a head start made it jump): measured on screen (the theme's
## real font, with an icon on each line), then held.
func _hold_lines(r: RichTextLabel, lines: int) -> void:
	var sample := PackedStringArray()
	for i in lines:
		sample.append("Xg %s +0" % UIIcons.bb("credits", 12))
	var keep := r.text
	r.text = "\n".join(sample)
	r.modulate.a = 0.0   # the sample is never seen
	await get_tree().process_frame
	if not is_instance_valid(r):
		return
	var h := float(r.get_content_height())
	if r.text == "\n".join(sample):
		r.text = keep   # (unless it was changed meanwhile)
	r.custom_minimum_size.y = ceilf(h) + 2.0
	r.fit_content = false
	r.modulate.a = 1.0
