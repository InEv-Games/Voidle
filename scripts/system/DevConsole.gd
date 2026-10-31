## Developer console — toggle with Cmd+Shift+C (Mac) or Ctrl+Shift+C (Win/Linux).
## Type "help" for a list of commands.
extends CanvasLayer

var _panel:        Control
var _top_spacer:   Control
var _log:          RichTextLabel
var _field:        LineEdit
var _input_row:    Control
var _orbitron:     Font
var _history:  Array[String] = []
var _hist_idx: int = -1
var _open:     bool = false
var _booting:  bool = false
var _skip_boot: bool = false

# Output typewriter state
var _out_lines: Array[String] = []   # collected by _log_* during _exec
var _out_gen:   int = 0              # increment to cancel in-progress drain

var show_planet_coords: bool = true

const MAX_LINES    := 200
const PANEL_H      := 300.0
const RIGHT_MARGIN_FRAC := 0.31   # right panel is anchored at 0.70 of vp; leave 31% gap
const FONT_SIZE    := 9

# Retro boot lines: [pre_delay_sec, bbcode_text, sec_per_char]
const BOOT_LINES: Array = [
	[0.00, "[color=#1e5c2a]╔══════════════════════════════════════╗[/color]",      0.010],
	[0.02, "[color=#1e5c2a]║[/color]  [color=#33aa55]VOIDLE/OS[/color]  [color=#2e7a3e]kernel 4.7.1-void[/color]       [color=#1e5c2a]║[/color]", 0.010],
	[0.02, "[color=#1e5c2a]╚══════════════════════════════════════╝[/color]",      0.010],
	[0.10, "[color=#2e7a3e]>[/color] [color=#33cc55]BOOT[/color]   neural_interface.sys   [color=#1a6630]......[/color] [color=#44ff77]OK[/color]", 0.016],
	[0.06, "[color=#2e7a3e]>[/color] [color=#33cc55]INIT[/color]   quantum_entropy_pool   [color=#1a6630]......[/color] [color=#44ff77]OK[/color]", 0.016],
	[0.06, "[color=#2e7a3e]>[/color] [color=#33cc55]LOAD[/color]   dev_console v3.9.2     [color=#1a6630]......[/color] [color=#44ff77]OK[/color]", 0.016],
	[0.06, "[color=#2e7a3e]>[/color] [color=#33cc55]SYNC[/color]   game_state_bridge      [color=#1a6630]......[/color] [color=#44ff77]OK[/color]", 0.016],
	[0.12, "",                                                                     0.0],
	[0.00, "[color=#55ff88]▸ ACCESS GRANTED  —  type help for commands[/color]",   0.022],
	[0.04, "",                                                                     0.0],
]

# ── Build ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	layer = 225
	_orbitron = load("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf")
	_build_ui()
	_panel.visible = false
	# Tab always cycles back to the field (must be set after node is in tree)
	await get_tree().process_frame
	if is_instance_valid(_field):
		_field.focus_next     = _field.get_path()
		_field.focus_previous = _field.get_path()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.clip_contents = true
	var s := StyleBoxFlat.new()
	s.bg_color             = Color(0.03, 0.05, 0.07, 0.97)
	s.border_color         = Color(0.20, 0.55, 0.30, 0.80)
	s.border_width_bottom  = 2
	s.border_width_right   = 1
	s.corner_radius_bottom_right = 6
	_panel.add_theme_stylebox_override("panel", s)
	# anchor_right = 0 → width set dynamically at open time from viewport
	_panel.anchor_left   = 0.0
	_panel.anchor_right  = 0.0
	_panel.anchor_top    = 0.0
	_panel.anchor_bottom = 0.0
	_panel.grow_vertical = Control.GROW_DIRECTION_END
	_panel.offset_left   = 0.0
	_panel.offset_right  = 800.0   # placeholder; overwritten at open time
	_panel.offset_top    = -PANEL_H
	_panel.offset_bottom = 0.0
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(vbox)

	_top_spacer = Control.new()
	_top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_top_spacer)

	_log = RichTextLabel.new()
	_log.bbcode_enabled  = true
	_log.scroll_following = true
	_log.custom_minimum_size = Vector2(0, 250)
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _orbitron:
		_log.add_theme_font_override("normal_font",   _orbitron)
		_log.add_theme_font_override("bold_font",     _orbitron)
		_log.add_theme_font_override("italics_font",  _orbitron)
	_log.add_theme_font_size_override("normal_font_size",   FONT_SIZE)
	_log.add_theme_font_size_override("bold_font_size",     FONT_SIZE)
	_log.add_theme_font_size_override("italics_font_size",  FONT_SIZE)
	_log.add_theme_color_override("default_color", Color(0.70, 0.82, 0.72))
	_log.focus_mode = Control.FOCUS_NONE
	vbox.add_child(_log)

	# Separator above input
	var sep := HSeparator.new()
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.18, 0.40, 0.24, 0.55)
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_input_row = row
	vbox.add_child(row)

	var prompt := Label.new()
	prompt.text = ">"
	if _orbitron: prompt.add_theme_font_override("font", _orbitron)
	prompt.add_theme_font_size_override("font_size", FONT_SIZE)
	prompt.add_theme_color_override("font_color", Color(0.35, 0.85, 0.50))
	row.add_child(prompt)

	_field = LineEdit.new()
	_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field.placeholder_text      = "enter command..."
	if _orbitron: _field.add_theme_font_override("font", _orbitron)
	_field.add_theme_font_size_override("font_size", FONT_SIZE)
	_field.add_theme_color_override("font_color",               Color(0.90, 0.95, 0.85))
	_field.add_theme_color_override("placeholder_color",        Color(0.35, 0.50, 0.38, 0.6))
	_field.add_theme_color_override("caret_color",              Color(0.45, 0.95, 0.60))
	_field.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_field.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	_field.focus_mode = Control.FOCUS_ALL
	_field.text_submitted.connect(_on_submit)
	_field.text_changed.connect(func(_t: String) -> void: AudioManager.play("tick", -10.0))
	_field.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.IBEAM))
	_field.mouse_exited.connect(func()  -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	row.add_child(_field)

# ── Input ─────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or GameState.demo_build:   # no console in the browser demo
		return
	var ke := event as InputEventKey
	if ke.pressed and ke.keycode == KEY_TAB and _open and not _booting:
		_field.grab_focus()
		get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var ke := event as InputEventKey
	# Toggle shortcut — always active
	if ke.pressed and ke.keycode == KEY_C \
			and ke.shift_pressed \
			and (ke.ctrl_pressed or ke.meta_pressed):
		_toggle()
		get_viewport().set_input_as_handled()
		return
	if not _open or not ke.pressed:
		return
	match ke.keycode:
		KEY_ENTER, KEY_KP_ENTER:
			if _booting:
				_skip_boot = true
				get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			_toggle()
			get_viewport().set_input_as_handled()
		KEY_UP:
			if _booting or _history.is_empty(): return
			_hist_idx = clampi(_hist_idx + 1, 0, _history.size() - 1)
			_field.text = _history[_history.size() - 1 - _hist_idx]
			_field.caret_column = _field.text.length()
			get_viewport().set_input_as_handled()
		KEY_DOWN:
			if _booting: return
			if _hist_idx <= 0:
				_hist_idx = -1; _field.text = ""
			else:
				_hist_idx -= 1
				_field.text = _history[_history.size() - 1 - _hist_idx]
			_field.caret_column = _field.text.length()
			get_viewport().set_input_as_handled()

# ── Toggle / slide ────────────────────────────────────────────────────────────

func _toggle() -> void:
	_open = not _open
	if _open:
		# Set panel width: leave the right 31% for the game side panel
		var vp_w := get_viewport().get_visible_rect().size.x
		_panel.offset_right = vp_w * (1.0 - RIGHT_MARGIN_FRAC)

		var hud: Node = get_node_or_null("/root/HUDManager")
		var top_pad: float = 4.0
		if hud and hud.get("credits_panel") and is_instance_valid(hud.credits_panel):
			top_pad = hud.credits_panel.size.y + 2.0
		_top_spacer.custom_minimum_size = Vector2(0, top_pad)

		_field.text   = ""
		_hist_idx     = -1
		_input_row.visible = false   # hidden until boot finishes

		_panel.visible   = true
		_panel.offset_top    = -PANEL_H
		_panel.offset_bottom = 0.0
		var tw := create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		tw.tween_property(_panel, "offset_top",    0.0,     0.22)
		tw.parallel().tween_property(_panel, "offset_bottom", PANEL_H, 0.22)
		tw.tween_callback(_play_boot_sequence)
	else:
		_out_gen += 1   # cancel any pending output animation
		_log.clear()
		var tw := create_tween()
		tw.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
		tw.tween_property(_panel, "offset_top",    -PANEL_H, 0.18)
		tw.parallel().tween_property(_panel, "offset_bottom", 0.0, 0.18)
		tw.tween_callback(func() -> void: _panel.visible = false)

# ── Boot animation ────────────────────────────────────────────────────────────

func _play_boot_sequence() -> void:
	if _booting: return
	_booting = true
	_skip_boot = false
	_log.clear()
	var completed: Array[String] = []

	for entry in BOOT_LINES:
		var pre_delay: float  = entry[0]
		var bbcode:    String = entry[1]
		var char_spd:  float  = entry[2]

		if pre_delay > 0.0 and not _skip_boot:
			await get_tree().create_timer(pre_delay).timeout
		if not _open: break

		if bbcode == "":
			completed.append("")
			_redraw_log(completed, "")
			continue

		var plain := _strip_bbcode(bbcode)
		if _skip_boot:
			pass # Skip character by character rendering
		else:
			for i in plain.length():
				if not _open or _skip_boot: break
				_redraw_log(completed, plain.substr(0, i + 1) + "▌")
				AudioManager.play("tick", -12.0)
				await get_tree().create_timer(char_spd).timeout

		completed.append(bbcode)
		_redraw_log(completed, "")

	_booting = false
	_input_row.visible = true
	_field.grab_focus()

func _redraw_log(lines: Array[String], current: String) -> void:
	_log.clear()
	for l in lines:
		_log.append_text(l + "\n")
	if current != "":
		_log.append_text("[color=#44cc66]" + current + "[/color]\n")

func _strip_bbcode(s: String) -> String:
	var out := ""; var in_tag := false
	for ch in s:
		if ch == "[": in_tag = true;  continue
		if ch == "]": in_tag = false; continue
		if not in_tag: out += ch
	return out

# ── Submit / exec ─────────────────────────────────────────────────────────────

func _on_submit(raw: String) -> void:
	var line := raw.strip_edges()
	if line.is_empty():
		_field.grab_focus(); return
	_history.append(line)
	_hist_idx = -1
	_field.text = ""
	_out_lines.clear()
	_raw_append("[color=#44aa66]> %s[/color]" % line)   # command echoes instantly
	_exec(line)
	# Animate the collected response lines
	_out_gen += 1
	_drain_output(_out_lines.duplicate(), _out_gen)
	# Wait one frame so Godot's focus system finishes processing Enter, then re-grab
	await get_tree().process_frame
	if _open and is_instance_valid(_field):
		_field.grab_focus()

func _drain_output(lines: Array, gen: int) -> void:
	for ln in lines:
		if _out_gen != gen or not _open: return
		_raw_append(ln)
		AudioManager.play("tick", -14.0)
		await get_tree().create_timer(0.018).timeout

func _exec(line: String) -> void:
	var parts := line.split(" ", false)
	if parts.is_empty(): return
	var cmd := parts[0].to_lower()

	match cmd:
		# ── Help ────────────────────────────────────────────────────────────
		"help", "--help", "-h":
			_log_info("[color=#33cc55]── ECONOMY ──────────────────────────────[/color]")
			_log_info("  [color=#88ddcc]credits[/color] [color=#aaaaaa]<amount>[/color]          — add credits")
			_log_info("  [color=#88ddcc]credits set[/color] [color=#aaaaaa]<amount>[/color]      — set exact")
			_log_info("  [color=#88ddcc]credits clear[/color]               — reset to 0")
			_log_info("  [color=#88ddcc]res[/color]                         — list resources in stock")
			_log_info("  [color=#88ddcc]res[/color] [color=#aaaaaa]<id> <amount>[/color]          — add (capped by storage)")
			_log_info("  [color=#88ddcc]res set[/color] [color=#aaaaaa]<id> <amount>[/color]      — set exact (ignores cap)")
			_log_info("  [color=#88ddcc]res fill[/color] [color=#aaaaaa][id][/color]              — fill to storage cap (all if no id)")
			_log_info("  [color=#555f6a]  ids: ferrite, moonstone, goods, fuel, rare … (name or short)[/color]")
			_log_info("[color=#33cc55]── UNLOCKS ──────────────────────────────[/color]")
			_log_info("  [color=#88ddcc]unlock solar / galaxy / moon / all[/color]")
			_log_info("  [color=#88ddcc]lock solar / galaxy / moon[/color]")
			_log_info("[color=#33cc55]── SCIENCE ──────────────────────────────[/color]")
			_log_info("  [color=#88ddcc]science[/color] [color=#aaaaaa][amount][/color]           — show or add")
			_log_info("  [color=#88ddcc]science set[/color] [color=#aaaaaa]<amount>[/color]       — set exact")
			_log_info("  [color=#88ddcc]science clear[/color]")
			_log_info("[color=#33cc55]── COLONY / ASTEROID ────────────────────[/color]")
			_log_info("  [color=#88ddcc]colonize[/color]  [color=#88ddcc]scan asteroid[/color] [color=#aaaaaa][all][/color]")
			_log_info("  [color=#88ddcc]asteroids[/color]")
			_log_info("[color=#33cc55]── SKILL TREE ───────────────────────────[/color]")
			_log_info("  [color=#88ddcc]skilltree unhide -all[/color]  [color=#88ddcc]hide -all[/color]  [color=#88ddcc]grant <id>|all[/color]")
			_log_info("[color=#33cc55]── BUILDINGS ─────────────────────────────[/color]")
			_log_info("  [color=#88ddcc]buildings[/color] [color=#aaaaaa][district][/color]      — every model by district: open or why not")
			_log_info("  [color=#88ddcc]building[/color] [color=#aaaaaa]<name or id>[/color]     — one model in full (cost, output, needs)")
			_log_info("[color=#33cc55]── SAVE ──────────────────────────────────[/color]")
			_log_info("  [color=#88ddcc]save[/color]              — force save now")
			_log_info("  [color=#88ddcc]clear_save[/color]        — delete save file")
			_log_info("[color=#33cc55]── DEBUG ─────────────────────────────────[/color]")
			_log_info("  [color=#88ddcc]state[/color]  [color=#88ddcc]clear[/color]  [color=#88ddcc]debug coords[/color]")
			_log_info("  [color=#88ddcc]--seed[/color]            — seed of what you're looking at (copied)")
			_log_info("  [color=#88ddcc]moonlaunch[/color] [color=#aaaaaa][sec] [reset][/color] — send the Moon lander now (default 15s)")
			_log_info("  [color=#88ddcc]rocket[/color] [color=#aaaaaa][sec][/color] — launch the final rocket now (completes Civilization 0)")
			_log_info("  [color=#88ddcc]tutorial complete[/color] — skip/finish tutorial")
			_log_info("[color=#33cc55]── BALANCE ───────────────────────────────[/color]")
			_log_info("  [color=#88ddcc]balance[/color]                     — active profile and the ones available")
			_log_info("  [color=#88ddcc]balance[/color] [color=#aaaaaa]<name>[/color]              — switch profile now and list what changed")
			_log_info("  [color=#88ddcc]balance show[/color]                — every value of the active profile")
			_log_info("[color=#33cc55]── SHOWCASE ──────────────────────────────[/color]")
			_log_info("  [color=#88ddcc]showcase[/color] [color=#aaaaaa][on|off][/color]      — Explore (read-only map tour): enter / leave now")

		# ── Credits ─────────────────────────────────────────────────────────
		"credits":
			if parts.size() == 1:
				_log_info("[color=#aaaaaa]credits[/color]  [color=#ffdd66]%s[/color]" % HUDManager.fmt_credits(GameState.credits))
				return
			var sub := parts[1].to_lower() if parts.size() > 1 else ""
			match sub:
				"set":
					var v := _parse_float(parts, 2); if is_nan(v): return
					GameState.credits = v
					_log_ok("Credits → [color=#ffdd66]%s[/color]" % HUDManager.fmt_credits(GameState.credits))
				"clear":
					GameState.credits = 0.0; _log_ok("Credits cleared.")
				_:
					var v := _parse_float(parts, 1); if is_nan(v): return
					GameState.credits += v
					_log_ok("+[color=#ffdd66]%s[/color]  total [color=#ffdd66]%s[/color]" % [
						HUDManager.fmt_credits(v), HUDManager.fmt_credits(GameState.credits)])

		# ── Science ─────────────────────────────────────────────────────────
		"science":
			if parts.size() == 1:
				_log_info("[color=#aaaaaa]science[/color]  [color=#66ccff]%.0f[/color]" % GameState.science_points)
				return
			var sub := parts[1].to_lower() if parts.size() > 1 else ""
			match sub:
				"set":
					var v := _parse_float(parts, 2); if is_nan(v): return
					GameState.science_points = v
					GameState.science_changed.emit(GameState.science_points)
					_log_ok("Science → [color=#66ccff]%.0f[/color]" % GameState.science_points)
				"clear":
					GameState.science_points = 0.0
					GameState.science_changed.emit(0.0)
					_log_ok("Science cleared.")
				_:
					var v := _parse_float(parts, 1); if is_nan(v): return
					GameState.add_science(v)
					_log_ok("+[color=#66ccff]%.0f[/color]  total [color=#66ccff]%.0f[/color]" % [v, GameState.science_points])

		# ── Skill Tree ────────────────────────────────────────────────────────
		"skilltree":
			var sub := parts[1].to_lower() if parts.size() > 1 else ""
			var opt := parts[2].to_lower() if parts.size() > 2 else ""
			if sub == "unhide" and opt == "-all":
				var st = get_tree().root.get_node("SkillTree")
				st.set_meta("debug_reveal_all", true)
				st.skill_unlocked.emit("debug")
				_log_ok("SkillTree nodes [color=#55ff88]revealed[/color] (visual only).")
			elif sub == "hide" and opt == "-all":
				var st = get_tree().root.get_node("SkillTree")
				st.set_meta("debug_reveal_all", false)
				st.skill_unlocked.emit("debug")
				_log_ok("SkillTree nodes [color=#ee5555]hidden[/color].")
			elif sub == "grant" and opt != "":
				var st = get_tree().root.get_node("SkillTree")
				var ids: Array = st.nodes.keys() if opt == "all" else [parts[2]]
				var n := 0
				for nid in ids:
					var node = st.nodes.get(nid, null)
					if node == null or node.act2 or nid == "root" or node.civilization > GameState.playable_content_type:
						continue
					st.grant(nid, node.max_level)
					n += 1
				GameState.save()
				_log_ok("Granted %d research node%s." % [n, "" if n == 1 else "s"])
			else:
				_log_err("Usage: skilltree unhide -all | skilltree hide -all | skilltree grant <id>|all")

		# ── Unlocks ─────────────────────────────────────────────────────────
		"unlock":
			var target := parts[1].to_lower() if parts.size() > 1 else ""
			match target:
				"solar":
					GameState.moon_unlocked = true; GameState.solar_unlocked = true
					GameState.unlock_changed.emit("moon_unlocked", true)
					GameState.unlock_changed.emit("solar_unlocked", true)
					_log_ok("[color=#55ff88]Solar[/color] (+ Moons) unlocked.")
				"galaxy":
					GameState.moon_unlocked = true; GameState.solar_unlocked = true; GameState.galaxy_unlocked = true
					GameState.unlock_changed.emit("moon_unlocked", true)
					GameState.unlock_changed.emit("solar_unlocked", true)
					GameState.unlock_changed.emit("galaxy_unlocked", true)
					_log_ok("[color=#55ff88]Galaxy[/color] (+ Solar, Moons) unlocked.")
				"moon", "moons":
					GameState.moon_unlocked = true
					GameState.unlock_changed.emit("moon_unlocked", true)
					_log_ok("[color=#55ff88]Moons[/color] unlocked.")
				"all":
					GameState.moon_unlocked = true; GameState.solar_unlocked = true; GameState.galaxy_unlocked = true
					GameState.unlock_changed.emit("moon_unlocked", true)
					GameState.unlock_changed.emit("solar_unlocked", true)
					GameState.unlock_changed.emit("galaxy_unlocked", true)
					_log_ok("[color=#55ff88]Everything[/color] unlocked.")
				_:
					_log_err("Unknown target: '%s'" % target)

		"lock":
			var target := parts[1].to_lower() if parts.size() > 1 else ""
			match target:
				"solar":
					GameState.solar_unlocked = false; GameState.galaxy_unlocked = false
					GameState.unlock_changed.emit("solar_unlocked", false)
					GameState.unlock_changed.emit("galaxy_unlocked", false)
					_log_ok("[color=#ee5555]Solar[/color] (+ Galaxy) locked.")
				"galaxy":
					GameState.galaxy_unlocked = false
					GameState.unlock_changed.emit("galaxy_unlocked", false)
					_log_ok("[color=#ee5555]Galaxy[/color] locked.")
				"moon", "moons":
					GameState.moon_unlocked = false; GameState.solar_unlocked = false; GameState.galaxy_unlocked = false
					GameState.unlock_changed.emit("moon_unlocked", false)
					GameState.unlock_changed.emit("solar_unlocked", false)
					GameState.unlock_changed.emit("galaxy_unlocked", false)
					_log_ok("[color=#ee5555]Moons[/color] (+ Solar, Galaxy) locked.")
				_:
					_log_err("Unknown target: '%s'" % target)

		# ── Debug ───────────────────────────────────────────────────────────
		"debug":
			var target := parts[1].to_lower() if parts.size() > 1 else ""
			match target:
				"coords":
					show_planet_coords = not show_planet_coords
					var s := "[color=#55ff88]ON[/color]" if show_planet_coords else "[color=#ee5555]OFF[/color]"
					_log_ok("Planet coords: %s" % s)
				_:
					_log_err("Unknown debug target. Try: coords")

		# ── Colony ──────────────────────────────────────────────────────────
		"colonize":
			var seed := GameState.active_planet_seed
			if seed < 0: _log_err("Not viewing a planet."); return
			var pp := GameState.get_planet(seed)
			pp.is_colonized = true
			GameState.planet_progress_changed.emit(seed)
			_log_ok("Planet [color=#aabbff]#%d[/color] colonized." % seed)

		# ── Asteroid ────────────────────────────────────────────────────────
		"scan":
			var target := parts[1].to_lower() if parts.size() > 1 else ""
			if target != "asteroid": _log_err("Try: scan asteroid"); return
			var sd := GameState.get_home_solar()
			if sd.asteroid_belt_slots.is_empty(): _log_err("No asteroid belts."); return
			var sub := parts[2].to_lower() if parts.size() >= 3 else ""
			if sub == "all":
				var total := 0
				for sl in sd.asteroid_belt_slots:
					for _i in 3 - GameState.asteroid_scan_counts.get(sl, 0):
						GameState.discover_asteroid(sl); total += 1
				if total == 0: _log_info("All already scanned.")
				else: _log_ok("Revealed [color=#ffcc55]%d[/color] asteroid(s)." % total)
			else:
				var slot := -1
				for sl in sd.asteroid_belt_slots:
					if GameState.asteroid_scan_counts.get(sl, 0) < 3: slot = sl; break
				if slot < 0: _log_info("All scanned."); return
				GameState.discover_asteroid(slot)
				var cnt: int = GameState.asteroid_scan_counts.get(slot, 0)
				_log_ok("Belt [color=#aabbff]%d[/color] — [color=#ffcc55]%d/3[/color] revealed." % [slot, cnt])

		"asteroids":
			var sd := GameState.get_home_solar()
			if sd.asteroid_belt_slots.is_empty(): _log_info("No belts."); return
			_log_info("[color=#aabbff]Asteroid Belts[/color]")
			for sl in sd.asteroid_belt_slots:
				var cnt: int = GameState.asteroid_scan_counts.get(sl, 0)
				var status: String
				if   cnt == 0: status = "[color=#ee5555]undiscovered[/color]"
				elif cnt < 3:  status = "[color=#ffcc55]%d/3 scanned[/color]" % cnt
				else:          status = "[color=#88ddaa]fully scanned[/color]"
				_log_info("  [color=#aaaaaa]slot %d[/color] — %s" % [sl, status])

		# ── Tutorial ────────────────────────────────────────────────────────
		"tutorial":
			var target := parts[1].to_lower() if parts.size() > 1 else ""
			if target == "complete":
				if TutorialManager._active and not TutorialManager._tutorial_done:
					TutorialManager._run_finale()
					_log_ok("Tutorial forced to finish.")
				else:
					TutorialManager._tutorial_done = true
					SettingsManager.tutorial_ever_done = true
					SettingsManager.save_settings()
					TutorialManager._quest_step = TutorialManager.TUTORIAL_QUEST_COUNT
					TutorialManager._quest_sub = 0
					_log_ok("Tutorial marked as complete for next run.")
			else:
				_log_err("Unknown target. Try: tutorial complete")

		# ── Stocked resources (raw minerals, goods, fuel, rare elements) ──────
		"res", "resource", "resources":
			_cmd_res(parts)

		# ── Moon lander test ──────────────────────────────────────────────────
		"moonlaunch":
			_cmd_moonlaunch(parts)
		"rocket":
			_cmd_rocket(parts)

		# ── Seed of the current view ──────────────────────────────────────────
		"--seed", "seed":
			_cmd_seed()

		# ── State ───────────────────────────────────────────────────────────
		"buildings":
			_cmd_buildings(" ".join(parts.slice(1)).to_lower())
		"building":
			_cmd_building(" ".join(parts.slice(1)))
		"state":
			var pp := GameState.get_planet(GameState.home_planet_seed)
			var yn := func(b: bool) -> String:
				return "[color=#55ff88]yes[/color]" if b else "[color=#ee5555]no[/color]"
			_log_info("[color=#aabbff]─── Game State ───────────────────────[/color]")
			_log_info("  [color=#aaaaaa]Credits[/color]         [color=#ffdd66]%s[/color]" % HUDManager.fmt_credits(GameState.credits))
			_log_info("  [color=#aaaaaa]Science[/color]         [color=#66ccff]%s[/color]" % HUDManager.fmt_science(GameState.science_points))
			_log_info("  [color=#aaaaaa]Solar unlocked[/color]  %s" % yn.call(GameState.solar_unlocked))
			_log_info("  [color=#aaaaaa]Galaxy unlocked[/color] %s" % yn.call(GameState.galaxy_unlocked))
			_log_info("  [color=#aaaaaa]Home colonized[/color]  %s" % yn.call(pp.is_colonized))
			_log_info("  [color=#aaaaaa]Districts[/color]       [color=#ccddff]%d[/color]" % GameState.get_home_planet().custom_pois.size())
			_log_info("  [color=#aaaaaa]Buildings[/color]       [color=#ccddff]%d[/color]" % pp.buildings.size())

		# ── Clear ───────────────────────────────────────────────────────────
		"clear":
			_out_gen += 1   # cancel pending drain
			_log.clear()

		# ── Balance ─────────────────────────────────────────────────────────
		"balance":
			_cmd_balance(parts)

		# ── Showcase ────────────────────────────────────────────────────────
		"showcase":
			_cmd_showcase(parts)

		# ── Save ─────────────────────────────────────────────────────────────
		"save":
			GameState.save()
			_log_ok("Game [color=#55ff88]saved[/color].")

		"clear_save":
			GameState.delete_save()
			_log_ok("Save [color=#ff5555]deleted[/color]. Restart to begin fresh.")

		_:
			_log_err("Unknown: '[color=#ffcc55]%s[/color]' — type help" % cmd)

# ── Buildings (playtest 31.10: "look at building X" while testing) ─────────────

## Why a model can't be built yet ("" when it is open on the home world).
func _building_block(b: BuildingDef) -> String:
	if b.retired:
		return "retired"
	if b.min_civilization > GameState.playable_content_type:
		return "Civilization %d content" % b.min_civilization
	if b.unlock_skill != "" and not SkillTree.is_unlocked(b.unlock_skill):
		return "research: %s" % b.unlock_skill
	var home := GameState.get_planet_data(GameState.home_planet_seed)
	if home != null and not b.allowed_planet_types.is_empty() and not (home.planet_type in b.allowed_planet_types):
		return "not on this world type" + (" (Moon only)" if b.is_moon_only() else "")
	return ""

## What a site needs for it: "River or Lakeside", "coast", …
static func _building_site_needs(b: BuildingDef) -> String:
	var needs: Array[String] = []
	if not b.required_features.is_empty():
		needs.append(" or ".join(PackedStringArray(b.required_features.map(func(f: String) -> String: return FeatureMap.feature_name(f)))))
	if b.requires_coastal:
		needs.append("a coastal site")
	if not b.required_terrain.is_empty():
		needs.append(" or ".join(PackedStringArray(b.required_terrain.map(func(t: int) -> String: return BuildingDef.terrain_label(t)))))
	if b.required_tag != "":
		needs.append("%s %d%%" % [BuildingDef.tag_label(b.required_tag), int(round(b.required_min * 100.0))])
	if b.requires_atmosphere:
		needs.append("an atmosphere")
	if b.requires_liquid_sea:
		needs.append("a liquid sea")
	return ", ".join(needs)

func _cmd_buildings(filter: String) -> void:
	var groups := {}
	for b: BuildingDef in BuildingDef.all():
		if b.retired:
			continue
		for t in b.allowed_poi_types:
			var nm: String = POIData.TYPE_LABELS[int(t)]
			if filter != "" and not nm.to_lower().begins_with(filter):
				continue
			if not groups.has(nm):
				groups[nm] = []
			groups[nm].append(b)
	if groups.is_empty():
		_log_err("No district '%s'. Try: city, industrial, energy, science, residential, commercial, spaceport." % filter)
		return
	for nm: String in groups:
		_log_info("[color=#33cc55]── %s ──[/color]" % nm.to_upper())
		for b: BuildingDef in groups[nm]:
			var block := _building_block(b)
			var site := _building_site_needs(b)
			_log_info("  %s [color=#aaaaaa]T%d · %s[/color]%s%s" % [
				("[color=#88ddaa]%s[/color]" % b.display_name) if block == "" else ("[color=#777f8a]%s[/color]" % b.display_name),
				b.tier, b.building_id,
				("  [color=#ee8855]%s[/color]" % block) if block != "" else "",
				("  [color=#88aadd]site: %s[/color]" % site) if site != "" else ""])

func _cmd_building(q: String) -> void:
	if q.strip_edges() == "":
		_log_err("Try: building market   (a name, part of one, or an id)")
		return
	var ql := q.strip_edges().to_lower()
	var hit: BuildingDef = BuildingDef.find(ql)
	if hit == null:
		for b: BuildingDef in BuildingDef.all():
			if b.display_name.to_lower() == ql:
				hit = b
				break
	if hit == null:
		var many: Array[String] = []
		for b: BuildingDef in BuildingDef.all():
			if b.display_name.to_lower().contains(ql) or b.building_id.contains(ql):
				many.append(b.display_name)
				if hit == null:
					hit = b
		if many.size() > 1:
			_log_info("[color=#aaaaaa]Matches: %s — showing the first.[/color]" % ", ".join(many))
	if hit == null:
		_log_err("No building like '%s'." % q)
		return
	var b := hit
	var block := _building_block(b)
	var types: Array[String] = []
	for t in b.allowed_poi_types:
		types.append(POIData.TYPE_LABELS[int(t)])
	_log_info("[color=#ffdd66]%s[/color]  [color=#aaaaaa]%s · T%d · %s[/color]" % [b.display_name, b.building_id, b.tier, ", ".join(types)])
	_log_info("  %s" % (("[color=#88ddaa]open[/color]") if block == "" else ("[color=#ee8855]closed — %s[/color]" % block)))
	if b.description != "":
		_log_info("  [color=#aaaaaa]%s[/color]" % b.description)
	_log_info("  makes   %s" % b.output_label())
	if not b.inputs.is_empty():
		var ins: Array[String] = []
		for id: String in b.inputs:
			ins.append("%s %s" % [BuildingDef._num(float(b.inputs[id])), Economy.display_name(id)])
		_log_info("  uses    %s per cycle" % ", ".join(ins))
	if b.energy_per_tick < 0.0:
		_log_info("  energy  %s" % BuildingDef._num(b.energy_per_tick))
	if b.pop_use() > 0:
		_log_info("  workers %s" % Economy.fmt(b.pop_use()))
	_log_info("  cycle   %s · build %ss · base cost %s credits" % [ProductionManager.cycle_text(ProductionManager.building_cycle_sec(b)),
		BuildingDef._num(b.construct_duration if b.construct_duration > 0.0 else b.tick_duration), Economy.fmt(b.base_cost)])
	var site := _building_site_needs(b)
	if site != "":
		_log_info("  site    needs %s" % site)
	if b.unlock_skill != "":
		_log_info("  research %s%s" % [b.unlock_skill, "  (done)" if SkillTree.is_unlocked(b.unlock_skill) else ""])

# ── Logging helpers ───────────────────────────────────────────────────────────

# Queued (animated) output — used by most commands
func _log_ok(text: String) -> void:
	_out_lines.append("[color=#88ddaa]✓ %s[/color]" % text)

func _log_err(text: String) -> void:
	_out_lines.append("[color=#ee5555]✗ %s[/color]" % text)

func _log_info(text: String) -> void:
	_out_lines.append(text)

# Immediate write (boot sequence and command echo)
func _raw_append(bbcode: String) -> void:
	if _log.get_parsed_text().split("\n").size() > MAX_LINES:
		_log.clear()
	_log.append_text(bbcode + "\n")

# ── Resources ────────────────────────────────────────────────────────────────

## Stocked resource ids: the processed ones plus every raw mineral.
func _stock_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in Economy.PROCESSED:
		out.append(id)
	for r: Dictionary in Economy.RAW_TABLE:
		out.append(r["id"])
	return out

## "ferrite", "Fuel Rods", "fuel", "rare" … → resource id ("" if unknown).
func _resolve_res(word: String) -> String:
	var w := word.to_lower().replace("_", " ")
	for id: String in _stock_ids():
		var name := Economy.display_name(id).to_lower()
		var short: String = Economy.INFO.get(id, {}).get("short", "")
		if w == id.replace("_", " ") or w == name or w == short or name.begins_with(w):
			return id
	return ""

func _res_line(id: String) -> String:
	var c := Economy.cap(id)
	return "  [color=#%s]%-14s[/color] [color=#ccddff]%s[/color]%s" % [Economy.color_of(id).to_html(false),
		Economy.display_name(id), Economy.fmt(GameState.get_resource(id)),
		"" if is_inf(c) else "[color=#555f6a] / %s[/color]" % Economy.fmt(c)]

func _cmd_res(parts: Array) -> void:
	if parts.size() == 1:
		_log_info("[color=#aabbff]─── Resources ────────────────────────[/color]")
		for id: String in _stock_ids():
			if GameState.get_resource(id) > 0.0 or id in Economy.PROCESSED:
				_log_info(_res_line(id))
		return
	var sub: String = String(parts[1]).to_lower()
	match sub:
		"fill":
			var ids: Array[String] = []
			if parts.size() > 2:
				var fname := " ".join(parts.slice(2))
				var one := _resolve_res(fname)
				if one == "":
					_log_err("Unknown resource '%s'." % fname); return
				ids.append(one)
			else:
				ids = _stock_ids()
			for id: String in ids:
				var c := Economy.cap(id)
				GameState.global_resources[id] = 1_000_000.0 if is_inf(c) else c
			GameState.global_resources_changed.emit()
			_log_ok("Filled %s to storage cap." % ("everything" if ids.size() > 1 else Economy.display_name(ids[0])))
		"set":
			if parts.size() < 4:
				_log_err("Usage: res set <id> <amount>"); return
			var sname := " ".join(parts.slice(2, parts.size() - 1))   # names may have spaces
			var id := _resolve_res(sname)
			if id == "":
				_log_err("Unknown resource '%s'." % sname); return
			var v := _parse_float(parts, parts.size() - 1); if is_nan(v): return
			GameState.global_resources[id] = maxf(v, 0.0)
			GameState.global_resources_changed.emit()
			_log_ok(_res_line(id).strip_edges())
		_:
			if parts.size() < 3:
				_log_err("Usage: res <id> <amount>"); return
			var aname := " ".join(parts.slice(1, parts.size() - 1))   # names may have spaces
			var id := _resolve_res(aname)
			if id == "":
				_log_err("Unknown resource '%s'. Type [color=#88ddcc]res[/color] to list." % aname); return
			var v := _parse_float(parts, parts.size() - 1); if is_nan(v): return
			GameState.add_resource(id, v)   # respects storage caps
			_log_ok("+%s  →  %s" % [Economy.fmt(v), _res_line(id).strip_edges()])

# ── Moon lander test ─────────────────────────────────────────────────────────

## Starts the Moon colonization flight right away (unlocks, tops up, short
## flight) and zooms the planet view out to watch it. `reset` wipes a Moon that
## was already settled so the whole thing can be replayed.
func _cmd_moonlaunch(parts: Array) -> void:
	var home := GameState.get_home_planet()
	if home == null or home.moons.is_empty():
		_log_err("Home planet has no moon."); return
	var moon: PlanetData = home.moons[0]
	var mp := GameState.get_planet(moon.seed)
	var secs := 15.0
	var reset := false
	for i in range(1, parts.size()):
		var a: String = String(parts[i]).to_lower()
		if a == "reset":
			reset = true
		elif a.is_valid_float():
			secs = maxf(2.0, a.to_float())
	if mp.is_colonized or mp.is_colonizing or mp.lander_state > 0:
		if not reset:
			_log_err("%s is already settled / underway. Add [color=#88ddcc]reset[/color] to wipe it and replay [color=#ee5555](deletes its districts)[/color]." % moon.planet_name)
			return
		mp.is_colonized = false
		mp.is_colonizing = false
		mp.colonize_progress = 0.0
		mp.lander_state = 0
		GameState.expeditions.erase("lander")
		mp.buildings.clear()
		mp.district_levels.clear()
		mp.city_levels.clear()
		moon.custom_pois.clear()
		# landers left over from earlier runs, parked or still flying
		var parked := GameState.moon_lander(moon.seed)
		if parked != null:
			ShipManager.remove_ship(moon.seed, parked.ship_id)
		var flying_old := ShipManager.travelling_to(moon.seed, "lander")
		while flying_old != null:
			ShipManager.remove_ship(flying_old.orbit_seed, flying_old.ship_id)
			flying_old = ShipManager.travelling_to(moon.seed, "lander")
	var st := get_node("/root/SkillTree")
	if not st.is_unlocked("lunar_program"):
		st.grant("lunar_program")
	GameState.moon_unlocked = true
	GameState.unlock_changed.emit("moon_unlocked", true)
	# cheat: no Spaceport, cost or preparation — the lander leaves right now
	GameState.expeditions["lander"] = {"state": "preparing", "prep_left": 0.0, "flight_left": secs,
		"target_seed": moon.seed}
	GameState._launch_lander(moon.seed, secs)
	# a lander left in orbit from a previous run would be a second one
	var old := GameState.moon_lander(moon.seed)
	if old != null:
		ShipManager.remove_ship(moon.seed, old.ship_id)
	# zoom out so the flight is visible
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("_set_zoom_target"):
		scene.call("_set_zoom_target", 0.0, Vector2.INF)
		scene.call("_refresh_active_panel")
	_log_ok("Lander launched to [color=#aabbff]%s[/color] — %ds flight." % [moon.planet_name, int(secs)])

## rocket [sec] — launches the final rocket now (no Lunar Spaceport, cost or
## preparation) at the first valid planet; its arrival completes Civilization 0.
func _cmd_rocket(parts: Array) -> void:
	var secs := 10.0
	if parts.size() > 1 and String(parts[1]).is_valid_float():
		secs = maxf(1.0, String(parts[1]).to_float())
	if GameState.demo_completed:
		_log_err("Civilization 0 is already complete."); return
	var target := -1
	var sd := GameState.get_home_solar()
	if sd != null:
		for pd: PlanetData in sd.planets:
			if GameState.rocket_target_block(pd.seed) == "":
				target = pd.seed
				break
	if target < 0:
		_log_err("No valid target planet."); return
	GameState.expeditions["rocket"] = {"state": "in_transit", "prep_left": 0.0, "flight_left": secs, "target_seed": target}
	GameState.expedition_changed.emit("rocket")
	_log_ok("Rocket launched to [color=#aabbff]%s[/color] — %ds flight." % [GameState.get_planet_data(target).planet_name, int(secs)])

# ── Seed ─────────────────────────────────────────────────────────────────────

## Prints (and copies) the seed of whatever the current scene shows: the planet
## or moon in the planet view, the star system in the solar view.
## balance [name] — show or switch the active balance profile (Balance.cfg).
## Switching applies at once: prices and rates read the profile live.
func _cmd_balance(parts: Array) -> void:
	var names := Balance.available_profiles()
	if parts.size() < 2:
		_log_info("[color=#aaaaaa]balance profile[/color]  [color=#ffdd66]%s[/color]" % Balance.profile_name)
		_log_info("  [color=#555f6a]available: %s  ·  `balance show` lists its values[/color]" % ", ".join(names))
		return
	var want := String(parts[1])
	if want.to_lower() == "show":
		_log_info("[color=#aaaaaa]balance profile[/color]  [color=#ffdd66]%s[/color]" % Balance.profile_name)
		for row: Array in _balance_rows(Balance.cfg):
			if row[0] == "group":
				_log_info("[color=#33cc55]  ── %s[/color]" % row[1])
			else:
				_log_info("    [color=#88ddcc]%s[/color]  %s" % [row[1], str(row[2])])
		return
	var before := Balance.cfg
	if not Balance.load_profile(want):
		_log_err("No profile '%s'. Available: %s" % [want, ", ".join(names)])
		return
	GameState.global_resources_changed.emit()
	_log_ok("Balance profile [color=#ffdd66]%s[/color] active." % want)
	var changed := 0
	for row: Array in _balance_rows(Balance.cfg):
		if row[0] != "value" or row[1] == "profile_name":
			continue
		var old_v = before.get(row[1])
		if str(old_v) != str(row[2]):
			changed += 1
			_log_info("    [color=#88ddcc]%s[/color]  [color=#aaaaaa]%s[/color] → [color=#ffdd66]%s[/color]" % [row[1], str(old_v), str(row[2])])
	if changed == 0:
		_log_info("  [color=#555f6a]no values differ from the previous profile[/color]")

## The profile's exported fields in inspector order: ["group", name] headers and
## ["value", field, value] rows.
func _balance_rows(cfg: BalanceConfig) -> Array:
	var rows: Array = []
	for prop: Dictionary in cfg.get_property_list():
		var usage: int = prop["usage"]
		if usage & PROPERTY_USAGE_GROUP:
			rows.append(["group", prop["name"]])
		elif usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_EDITOR:
			rows.append(["value", prop["name"], cfg.get(prop["name"])])
	return rows

## showcase [on|off] — enter / leave Explore (the read-only map tour) now,
## even before the tutorial is done.
func _cmd_showcase(parts: Array) -> void:
	var on_off := func(v: bool) -> String:
		return "[color=#55ff88]ON[/color]" if v else "[color=#ee5555]OFF[/color]"
	var arg := String(parts[1]).to_lower() if parts.size() > 1 else ""
	match arg:
		"":
			_log_info("[color=#aaaaaa]explore[/color]  %s" % on_off.call(GameState.showcase_mode))
		"on":
			if GameState.showcase_mode:
				_log_info("Explore already on.")
				return
			GameState.start_explore()
			_log_ok("Explore %s — ESC or `showcase off` to return." % on_off.call(true))
		"off":
			if not GameState.showcase_mode:
				_log_info("Explore already off.")
				return
			GameState.end_explore()
			_log_ok("Explore %s" % on_off.call(false))
		_:
			_log_err("Try: showcase / showcase on / showcase off")

func _cmd_seed() -> void:
	var scene := get_tree().current_scene
	var label := ""
	var seed_val := 0
	var found := false
	if scene != null and "current_data" in scene and scene.get("current_data") != null:
		var pd: PlanetData = scene.get("current_data")
		var kind := String(PlanetData.Type.keys()[pd.planet_type]).capitalize()
		label = "%s  [color=#aaaaaa](%s)[/color]" % [pd.planet_name, kind]
		seed_val = pd.seed
		found = true
	elif scene != null and "_current" in scene and scene.get("_current") is SolarData:
		var sd: SolarData = scene.get("_current")
		label = "%s  [color=#aaaaaa](star system)[/color]" % sd.system_name
		seed_val = sd.seed
		found = true
	if not found:
		_log_err("Nothing with a seed in view."); return
	DisplayServer.clipboard_set(str(seed_val))
	_log_ok("%s  seed [color=#ffdd66]%d[/color]  [color=#555f6a](copied)[/color]" % [label, seed_val])

# ── Helpers ──────────────────────────────────────────────────────────────────

func _parse_float(parts: Array, idx: int) -> float:
	if idx >= parts.size(): _log_err("Missing number."); return NAN
	var s: String = parts[idx]
	if s.ends_with("k") or s.ends_with("K"): return s.left(s.length()-1).to_float() * 1_000.0
	if s.ends_with("m") or s.ends_with("M"): return s.left(s.length()-1).to_float() * 1_000_000.0
	if not s.is_valid_float(): _log_err("'%s' is not a number." % s); return NAN
	return s.to_float()
