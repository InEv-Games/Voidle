class_name ShortcutsHelp
extends RefCounted

## Every shortcut, for the keys and the pad, in one list (10.11): "?" (pad
## Back / Select) opens it as a popup, with buttons for what the pad has no
## button of its own for (Upgrade Tree, Trade, the news, the top bar, the Log,
## the objectives); the console's `help shortcuts` prints the same rows.
## A row: [keys, pad, what it does].

const ROWS := [
	["↑ ↓ ← →", "L-Stick / D-pad", "Move through the panel, cards and popups"],
	["Enter / Space", "A", "Press what is selected"],
	["Esc / Backspace", "B", "Back, close"],
	["Tab", "L3", "Show / hide the left panel"],
	["W A S D", "Right stick", "Turn the globe (aims with the centre cursor)"],
	["Enter on the globe", "A / X", "Pick under centre cursor; X opens context menu"],
	["Q / E", "LT / RT", "Zoom out / in"],
	["1 – 5, 0", "LB / RB (globe)", "Cycle surface lenses (LB + RB: normal)"],
	["Shift + 1 – 9", "Select + LB", "Switch between home world and moons"],
	["Alt / Ctrl / H", "R3", "Cycle inspect overlay / clean globe"],
	["X / B", "LB / RB (panel)", "Remove one / add one (hold: Fill / Max)"],
	["F", "Y", "Buy what is missing and build (on a build row)"],
	["U", "Select + Y", "Upgrade Tree"],
	["T", "Select + X", "Trade"],
	["C", "Select + A", "Government and Agents"],
	["O", "Select + RB", "Notifications"],
	["R", "Select + ↑", "Browse the top bar"],
	["N", "Select + ↓", "Browse the news"],
	["Alt + ← / →", "Select + ← / →", "Back / forward in view history"],
	["L", "Y (dialogue)", "Narrative Log (in a story line)"],
	["?", "Select + Start", "This list (tap Select: Quick Hub / wheel on planet)"],
	["Esc", "Start", "Pause menu"],
	["Cmd/Ctrl + Shift + C", "", "Developer console"],
]
const LAYER := 245

static var _popup: ModalPopup = null

static func toggle(host: Node) -> void:
	if _popup != null and is_instance_valid(_popup):
		_popup.close()
		_popup = null
		return
	open(host)

static func open(host: Node) -> void:
	var p := ModalPopup.open(host, "Shortcuts", "settings", "", LAYER)
	_popup = p
	# one way out: the ✕ by the title (and Esc / a click outside), no CLOSE row
	(p.card.get_node("VBox/Buttons") as Control).visible = false
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.scroll_active = false
	t.autowrap_mode = TextServer.AUTOWRAP_OFF
	t.theme_type_variation = &"PopupBody"
	t.add_theme_font_size_override(&"normal_font_size", 12)
	t.add_theme_font_size_override(&"bold_font_size", 12)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.text = _table_bb()
	p.add_content(t)
	# what the pad can't reach otherwise ("Menu" above), and the keys too
	# an even grid: every button the same width, three to a row
	var row := GridContainer.new()
	row.columns = 3
	row.add_theme_constant_override(&"h_separation", 6)
	row.add_theme_constant_override(&"v_separation", 6)
	var add := func(label: String, icon: String, ok: bool, act: Callable) -> void:
		if not ok:
			return
		var b := IconButton.create(label, icon, IconButton.Variant.DEFAULT)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			AudioManager.play("click")
			p.close()
			_popup = null
			act.call_deferred())
		row.add_child(b)
	add.call("UPGRADE TREE", "research", HUDManager.shortcut_open("tree"), func() -> void: HUDManager.press_shortcut("tree"))
	add.call("TRADE", "trade", HUDManager.shortcut_open("trade"), func() -> void: HUDManager.press_shortcut("trade"))
	add.call("GOVERNMENT", "population", HUDManager.shortcut_open("companions"), func() -> void: HUDManager.press_shortcut("companions"))
	add.call("NEWS", "notes", true, func() -> void: NewsFeed.start_browsing())
	var rb = HUDManager.get("credits_panel")
	add.call("TOP BAR", "explore", rb != null and is_instance_valid(rb), func() -> void: rb.call("start_browsing"))
	add.call("NARRATIVE LOG", "notes", true, func() -> void: Narrative.open_log())
	add.call("NOTIFICATIONS", "flag", true, func() -> void: Inbox.open())
	if row.get_child_count() > 0:
		p.add_content(HSeparator.new())
		p.add_content(row)
	p.closed.connect(func() -> void: _popup = null)

static func _table_bb() -> String:
	var head := UIStyle.hex(&"accent")
	var dim := UIStyle.hex(&"text_subtle")
	var out := "[table=3][cell][color=#%s][b]KEYS[/b][/color]      [/cell][cell][color=#%s][b]PAD[/b][/color]      [/cell][cell][color=#%s][b]WHAT[/b][/color][/cell]" % [head, head, head]
	for r: Array in ROWS:
		out += "[cell]%s      [/cell][cell][color=#%s]%s[/color]      [/cell][cell][color=#%s]%s[/color][/cell]" % [
			r[0], dim, r[1] if String(r[1]) != "" else "–", dim, r[2]]
	return out + "[/table]"

## The rows as plain text lines (the console).
static func lines() -> Array[String]:
	var out: Array[String] = []
	for r: Array in ROWS:
		out.append("%-22s %-12s %s" % [r[0], r[1] if String(r[1]) != "" else "-", r[2]])
	return out
