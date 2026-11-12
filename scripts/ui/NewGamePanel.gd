class_name NewGamePanel
extends ModalPopup

## NEW GAME's preparation window (SessionPrep.open; layout:
## scenes/ui/NewGamePanel.tscn), laid out as an excavation (StoryDialog): the
## preview (NewGamePreview: the home world of the seed, turning, with its moon)
## large and without a background above, the hero (and its ✕) right under it,
## and under the hero one panel in two steps:
##   1 Start  CIVILIZATION, START WORLD, MOON and what the option is   (NEXT)
##   2 Rest   HEAD START, and the world's name and seed (typed or RANDOM)
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
	_build_seed()
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

# ── Step 1: the start ────────────────────────────────────────────────────────

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
	# the civilization first: it decides what the rows under it are (a world
	# now, a star system later)
	_add_row($Center/Box/Pages/Steps/Start/CivRow, "civ", SessionPrep.CIVS, SessionPrep.CIV_ORDER,
		func(id: String, _o: bool) -> void:
			if id == "c1":
				_pv.show_solar(int(_choice["seed"]))
			elif id == "c2":
				_pv.show_galaxy(int(_choice["seed"]))
			else:
				_show_choice())
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

# ── Step 2: the head start ───────────────────────────────────────────────────

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
		_go_step(2))
	_back.pressed.connect(func() -> void:
		AudioManager.play("click")
		_go_step(1))
	_ok.pressed.connect(_on_begin)
	# both steps shown (unseen) while the panel measures them, then the first
	_show_step(1)
	_rest.visible = true
	_head.modulate.a = 0.0
	_buttons.modulate.a = 0.0
	_hold_height(func() -> void:
		_show_step(1)
		_head.modulate.a = 1.0
		_buttons.modulate.a = 1.0
		RowReveal.play(_head, SessionPrep.REVEAL_SLOW)
		_reveal(1))

## The step shown: 1 the start (NEXT), 2 the rest (BACK, TUTORIAL, BEGIN).
func _show_step(step: int) -> void:
	TooltipManager.hide_tip()
	_start.visible = step == 1
	_rest.visible = step == 2
	_next.visible = step == 1
	_back.visible = step == 2
	_tut.visible = step == 2
	_ok.visible = step == 2
	_hero.caption = "Prepare your colony  //  %d / 2" % step

## Its rows come in (and the buttons under it).
func _reveal(step: int) -> void:
	RowReveal.play(_start if step == 1 else _rest, SessionPrep.REVEAL_SLOW, false, SessionPrep.REVEAL_SOUND)
	RowReveal.play(_buttons, SessionPrep.REVEAL_SLOW)

## The step shown fades out, then the other comes in.
func _go_step(step: int) -> void:
	if _switching:
		return
	_switching = true
	var old: Control = _start if _start.visible else _rest
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
	for st: Control in [_start, _rest]:
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
