## Back/forward history for the map views (Galaxy › System › Planet › City/District)
## and the navigation HUD (top-centre of the map) that drives it — so
## right-click stays free for actions.
##
## Views report where the player is with visit(). Going back/forward restores an
## entry: in place via the view's nav_apply(entry) when it's already showing that
## body, otherwise by loading the scene; the view then calls end_apply().
## Controls: ‹ › buttons, mouse back/forward buttons, Alt+← / Alt+→,
## breadcrumbs to jump up. In showcase, H hides the bar for clean captures.
extends CanvasLayer

const GALAXY_SCENE := "res://scenes/galaxy/GalaxyView.tscn"
const SOLAR_SCENE  := "res://scenes/solar/SolarView.tscn"
const PLANET_SCENE := "res://scenes/planetary/PlanetaryView.tscn"
const MAX_HISTORY  := 50
const APPLY_TIMEOUT_MS := 4000

var _history: Array[Dictionary] = []
var _index: int = -1
## Entry being restored — visits are ignored until the view calls end_apply().
var _applying: Dictionary = {}
var _applying_since: int = 0
## Panel state for PlanetaryView to open once it has loaded (see end_apply).
var pending_sub: Dictionary = {}
var _user_hidden := false

var _bar: PanelContainer = null
var _back_btn: Button = null
var _fwd_btn: Button = null
var _crumbs: HBoxContainer = null
var _font: Font = null

# ── Entries ──────────────────────────────────────────────────────────────────

static func galaxy_entry(gd: GalaxyData) -> Dictionary:
	return {"key": "galaxy", "scene": GALAXY_SCENE, "data": gd, "sub": {}, "label": "Galaxy"}

static func solar_entry(sd: SolarData) -> Dictionary:
	return {"key": "solar:%d" % sd.seed, "scene": SOLAR_SCENE, "data": sd, "sub": {},
		"label": sd.system_name}

## `sub` picks the planet view's panel: {} overview, {"city": label},
## {"district": label} or {"orbit": true}; `sub_label` names it in the crumbs.
static func planet_entry(pd: PlanetData, sub: Dictionary = {}, sub_label := "") -> Dictionary:
	var sub_key := ""
	for k: String in sub:
		sub_key += "%s=%s;" % [k, str(sub[k])]
	return {"key": "planet:%d|%s" % [pd.seed, sub_key], "scene": PLANET_SCENE, "data": pd,
		"sub": sub, "label": pd.planet_name, "sub_label": sub_label}

# ── History ──────────────────────────────────────────────────────────────────

func visit(entry: Dictionary) -> void:
	if not _applying.is_empty():
		return
	if _index >= 0 and _history[_index]["key"] == entry["key"]:
		_history[_index] = entry   # same place rebuilt — keep the fresher data
		_refresh()
		return
	_history.resize(_index + 1)   # a new step drops the forward history
	_history.append(entry)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	_index = _history.size() - 1
	_refresh()

func can_back() -> bool:
	return _index > 0 and _applying.is_empty()

func can_forward() -> bool:
	return _index < _history.size() - 1 and _applying.is_empty()

func back() -> void:
	if can_back():
		_restore(_index - 1)

func forward() -> void:
	if can_forward():
		_restore(_index + 1)

## Jump to a place as a new step (breadcrumbs).
func go(entry: Dictionary) -> void:
	_open(entry, false)

## Called by a view once it has finished showing the restored entry.
func end_apply() -> void:
	_applying = {}
	pending_sub = {}
	_refresh()

func clear_history() -> void:
	_history.clear()
	_index = -1
	_applying = {}
	pending_sub = {}
	_refresh()

func _restore(i: int) -> void:
	if _is_transitioning():
		return
	_index = i
	_open(_history[i], true)

func _open(entry: Dictionary, restoring: bool) -> void:
	if _is_transitioning():
		return
	if restoring:
		_applying = entry
		_applying_since = Time.get_ticks_msec()
	var scene := get_tree().current_scene
	if scene != null and scene.scene_file_path == entry["scene"] and scene.has_method("nav_apply") \
			and bool(scene.call("nav_apply", entry)):
		if restoring:
			end_apply()
		return
	pending_sub = entry.get("sub", {})
	AudioManager.play("click")
	SceneTransition.go(entry["scene"], entry["data"])

func _is_transitioning() -> bool:
	return bool(SceneTransition.get("_transitioning"))

# ── HUD ──────────────────────────────────────────────────────────────────────

func _ready() -> void:
	layer = 120
	_font = load("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf") as Font
	_build_ui()
	_refresh()

func _build_ui() -> void:
	_bar = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.10, 0.82)
	sb.border_color = Color(0.25, 0.35, 0.65, 0.45)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 6; sb.content_margin_right = 10
	sb.content_margin_top = 3;  sb.content_margin_bottom = 3
	_bar.add_theme_stylebox_override("panel", sb)
	_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_bar.add_child(row)
	_back_btn = _make_btn("‹", "Back  (Alt+←, mouse back)", back)
	_fwd_btn  = _make_btn("›", "Forward  (Alt+→, mouse forward)", forward)
	row.add_child(_back_btn)
	row.add_child(_fwd_btn)
	var sep := VSeparator.new()
	row.add_child(sep)
	_crumbs = HBoxContainer.new()
	_crumbs.add_theme_constant_override("separation", 2)
	row.add_child(_crumbs)

func _make_btn(txt: String, tip: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = tip
	b.custom_minimum_size = Vector2(26, 0)
	b.pressed.connect(cb)
	UIStyle.style_button(b, UIStyle.DEFAULT, 12)
	return b

func _crumb(txt: String, target: Dictionary, enabled: bool) -> void:
	if _crumbs.get_child_count() > 0:
		var gt := Label.new()
		gt.text = "›"
		_style_lbl(gt, Color(0.35, 0.40, 0.55))
		_crumbs.add_child(gt)
	if target.is_empty() or not enabled:
		var l := Label.new()
		l.text = txt
		_style_lbl(l, Color(0.85, 0.88, 1.0) if target.is_empty() else Color(0.40, 0.44, 0.58))
		_crumbs.add_child(l)
		return
	var b := Button.new()
	b.text = txt
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void: go(target))
	UIStyle.style_button(b, UIStyle.FLAT)
	_crumbs.add_child(b)

func _style_lbl(l: Label, col: Color) -> void:
	if _font:
		l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", col)

## Rebuilds buttons and breadcrumbs for the current entry.
func _refresh() -> void:
	if _bar == null:
		return
	_back_btn.disabled = not can_back()
	_fwd_btn.disabled = not can_forward()
	for c in _crumbs.get_children():
		c.queue_free()
	if _index < 0:
		return
	var cur: Dictionary = _history[_index]
	var data = cur["data"]
	match cur["scene"]:
		GALAXY_SCENE:
			_crumb("Galaxy", {}, true)
		SOLAR_SCENE:
			var sd := data as SolarData
			_crumb("Galaxy", _galaxy_of(sd), GameState.can_view_galaxy())
			_crumb(sd.system_name, {}, true)
		PLANET_SCENE:
			var pd := data as PlanetData
			var sd := pd.get_meta("__solar_data") as SolarData if pd.has_meta("__solar_data") \
				else GameState.get_home_solar()
			if sd != null:
				_crumb("Galaxy", _galaxy_of(sd), GameState.can_view_galaxy())
				_crumb(sd.system_name, solar_entry(sd), GameState.can_view_solar())
			var sub_label: String = cur.get("sub_label", "")
			if sub_label == "":
				_crumb(pd.planet_name, {}, true)
			else:
				_crumb(pd.planet_name, planet_entry(pd), true)
				_crumb(sub_label, {}, true)

func _galaxy_of(sd: SolarData) -> Dictionary:
	var gd: GalaxyData = sd.get_meta("__galaxy_data") as GalaxyData \
		if sd != null and sd.has_meta("__galaxy_data") else GameState.home_galaxy
	return galaxy_entry(gd) if gd != null else {}

func _process(_delta: float) -> void:
	if not _applying.is_empty() and Time.get_ticks_msec() - _applying_since > APPLY_TIMEOUT_MS:
		end_apply()   # a view never confirmed — don't leave the history stuck
	var scene := get_tree().current_scene
	var path := scene.scene_file_path if scene != null else ""
	var on_map := path == GALAXY_SCENE or path == SOLAR_SCENE or path == PLANET_SCENE
	if path.ends_with("MainMenu.tscn") and not _history.is_empty():
		clear_history()
	_bar.visible = on_map and not SkillTreeView.is_open and not (_user_hidden and GameState.showcase_mode)
	if not _bar.visible:
		return
	# top-centre of the map area (the part of the screen beside the side panel);
	# the bottom edge belongs to the lens / role buttons
	var vp := get_viewport().get_visible_rect().size
	var frac := 1.0 if GameState.showcase_mode else clampf(HUDManager.view_area_fraction, 0.3, 1.0)
	var cx := vp.x * (1.0 - frac) + vp.x * frac * 0.5
	_bar.reset_size()
	var pos := Vector2(roundf(cx - _bar.size.x * 0.5), 12.0)
	# the resource bar (top-left) grows as resources are found: never sit under
	# it — step right of it, or below it when there's no room beside it
	var res := HUDManager.credits_panel
	if res != null and is_instance_valid(res) and res.is_visible_in_tree():
		var rr := res.get_global_rect()
		if pos.x < rr.end.x + 12.0:
			pos.x = rr.end.x + 12.0
			if pos.x + _bar.size.x > vp.x - 80.0:   # keep clear of the settings cog
				pos = Vector2(roundf(cx - _bar.size.x * 0.5), rr.end.y + 8.0)
				pos.x = maxf(pos.x, rr.position.x + 8.0)
	_bar.position = pos

## Unhandled, so typing in text fields (dev console) never triggers navigation.
func _unhandled_input(event: InputEvent) -> void:
	if not (_bar != null and _bar.visible) and not (_user_hidden and GameState.showcase_mode):
		return
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_XBUTTON1:
			back()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_XBUTTON2:
			forward()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := event as InputEventKey
		if k.alt_pressed and k.keycode == KEY_LEFT:
			back()
			get_viewport().set_input_as_handled()
		elif k.alt_pressed and k.keycode == KEY_RIGHT:
			forward()
			get_viewport().set_input_as_handled()
		elif k.keycode == KEY_H and GameState.showcase_mode:
			_user_hidden = not _user_hidden
			get_viewport().set_input_as_handled()
