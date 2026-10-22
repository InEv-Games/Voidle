## TradePanel — the trade window (GDD §18). One row per product the player
## knows: stock, fixed sell / buy prices, quick buy and sell buttons and a
## reserve that no sale dips into. With Trade Automation each row also gets a
## standing order. Opened from the HUD's Trade button; Esc or CLOSE closes it.
class_name TradePanel
extends Control

static var is_open: bool = false

const QUICK := [10.0, 100.0]

var _font: Font
var _list: VBoxContainer
var _log_lbl: RichTextLabel
var _status: Label
var _rows: Dictionary = {}   # id -> {stock: Label, sell: Label, buy: Label, order: Label}
var _refresh_t: float = 0.0

func _ready() -> void:
	TradePanel.is_open = true
	_font = load("res://Fonts/Orbitron-VariableFont_wght.ttf")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			close())
	add_child(dim)

	var panel := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.06, 0.11, 0.97)
	s.border_color = Color(0.28, 0.42, 0.72, 0.6)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", s)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(900, 560)
	panel.position = -panel.custom_minimum_size * 0.5
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var head := HBoxContainer.new()
	v.add_child(head)
	var title := _label("⇄  TRADE", 15, Color(0.65, 0.85, 1.0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close_btn := _button("CLOSE", Color(0.9, 0.92, 1.0))
	close_btn.pressed.connect(close)
	head.add_child(close_btn)

	_status = _label("", 9, Color(0.6, 0.68, 0.85))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_status)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 6)
	scroll.add_child(_list)

	_log_lbl = RichTextLabel.new()
	_log_lbl.bbcode_enabled = true
	_log_lbl.fit_content = false
	_log_lbl.custom_minimum_size = Vector2(0, 90)
	_log_lbl.add_theme_font_size_override("normal_font_size", 10)
	v.add_child(_log_lbl)

	_build_rows()
	GameState.trade_changed.connect(_refresh)
	SkillTree.skill_unlocked.connect(func(_id: String) -> void: _build_rows())

func _exit_tree() -> void:
	TradePanel.is_open = false

func close() -> void:
	TradePanel.is_open = false
	CursorManager.set_state(CursorManager.State.NORMAL)
	TooltipManager.hide_tip()
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()

func _process(delta: float) -> void:
	_refresh_t += delta
	if _refresh_t >= 0.5:
		_refresh_t = 0.0
		_refresh()

# ── Rows ─────────────────────────────────────────────────────────────────────

func _build_rows() -> void:
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()
	var access := Trade.has_access()
	_status.text = ("Sell %d%% · buy %d%% of the reference price. Storage overflow is sold automatically." % [
		int(round(Balance.cfg.trade_sell_ratio * 100.0)), int(round(Balance.cfg.trade_buy_ratio * 100.0))]) \
		if access else "Research Trade Access (150 Science) to buy and sell. Until then, storage overflow is lost."
	if not Trade.has_automation() and access:
		_status.text += "  Research Trade Automation for standing orders."
	for id: String in Trade.products():
		_list.add_child(_product_row(id))
	_refresh()

func _product_row(id: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)

	var name_lbl := _label(Economy.display_name(id), 11, Economy.color_of(id))
	name_lbl.custom_minimum_size = Vector2(150, 0)
	row.add_child(name_lbl)
	var stock := _label("", 10, Color(0.85, 0.88, 0.95))
	stock.custom_minimum_size = Vector2(120, 0)
	row.add_child(stock)
	var sell_l := _label("", 10, Color(0.55, 0.95, 0.6))
	sell_l.custom_minimum_size = Vector2(90, 0)
	row.add_child(sell_l)
	var buy_l := _label("", 10, Color(1.0, 0.75, 0.45))
	buy_l.custom_minimum_size = Vector2(90, 0)
	row.add_child(buy_l)

	var block := Trade.product_block(id)
	if block != "":
		row.add_child(_label(block, 9, Color(0.75, 0.55, 0.45)))
		_rows[id] = {"stock": stock, "sell": sell_l, "buy": buy_l}
		return box

	for q: float in QUICK:
		var b := _button("Sell %d" % int(q), Color(0.55, 0.95, 0.6))
		b.pressed.connect(func() -> void: _do(Trade.sell(id, q)))
		row.add_child(b)
	var sell_all := _button("Sell all", Color(0.55, 0.95, 0.6))
	sell_all.pressed.connect(func() -> void: _do(Trade.sell(id, Trade.sellable(id))))
	row.add_child(sell_all)
	for q: float in QUICK:
		var b := _button("Buy %d" % int(q), Color(1.0, 0.75, 0.45))
		b.pressed.connect(func() -> void: _do(Trade.buy(id, q)))
		row.add_child(b)
	var buy_max := _button("Buy max", Color(1.0, 0.75, 0.45))
	buy_max.pressed.connect(func() -> void: _do(Trade.buy(id, Trade.max_buy(id))))
	row.add_child(buy_max)

	row.add_child(_label("Reserve", 9, Color(0.6, 0.68, 0.85)))
	var res := _spin(Trade.reserve(id))
	res.tooltip_text = "Stock no sale may touch (e.g. kept for the rocket)."
	res.value_changed.connect(func(val: float) -> void: Trade.set_reserve(id, val))
	row.add_child(res)

	var entry := {"stock": stock, "sell": sell_l, "buy": buy_l}
	if Trade.has_automation():
		var orow := HBoxContainer.new()
		orow.add_theme_constant_override("separation", 6)
		box.add_child(orow)
		var o := Trade.order(id)
		var on := CheckBox.new()
		on.text = "Auto"
		on.button_pressed = bool(o["enabled"])
		on.focus_mode = Control.FOCUS_NONE
		orow.add_child(on)
		var fields := {}
		for f: Array in [["sell_start", "Sell from"], ["reserve_min", "Keep"], ["buy_target", "Buy to"],
				["credit_reserve", "Credit floor"], ["max_per_cycle", "Max / 20 s"]]:
			orow.add_child(_label(String(f[1]), 9, Color(0.6, 0.68, 0.85)))
			var sp := _spin(float(o[f[0]]))
			orow.add_child(sp)
			fields[f[0]] = sp
		var otext := _label("", 9, Color(0.7, 0.75, 0.9))
		otext.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		otext.custom_minimum_size = Vector2(840, 0)
		box.add_child(otext)
		entry["order"] = otext
		var apply := func() -> void:
			var no := {"enabled": on.button_pressed}
			for k: String in fields:
				no[k] = (fields[k] as SpinBox).value
			var why := Trade.set_order(id, no)
			if why != "":
				otext.text = "⚠ " + why
				AudioManager.play("error")
			else:
				otext.text = Trade.order_text(id)
		on.toggled.connect(func(_b: bool) -> void: apply.call())
		for k: String in fields:
			(fields[k] as SpinBox).value_changed.connect(func(_v: float) -> void: apply.call())
	_rows[id] = entry
	var sep := HSeparator.new()
	box.add_child(sep)
	return box

func _do(amount: float) -> void:
	AudioManager.play("click" if amount > 0.0 else "error")
	_refresh()

func _refresh() -> void:
	for id: String in _rows:
		var e: Dictionary = _rows[id]
		if not is_instance_valid(e["stock"]):
			continue
		var cap := Economy.cap(id)
		(e["stock"] as Label).text = Economy.fmt(Trade.stock(id)) + ("" if cap == INF else " / " + Economy.fmt(cap))
		(e["sell"] as Label).text = "sell %s" % _price(Trade.sell_price(id))
		(e["buy"] as Label).text = "buy %s" % _price(Trade.buy_price(id))
		if e.has("order") and is_instance_valid(e["order"]) and not String((e["order"] as Label).text).begins_with("⚠"):
			(e["order"] as Label).text = Trade.order_text(id)
	var lines: Array[String] = ["[color=#8899bb]Recent trades[/color]"]
	for t: Dictionary in GameState.trade_log.slice(0, 6):
		var col := "#8ef59a" if t["kind"] == "sell" else "#ffbf73"
		lines.append("[color=%s]%s%s %s %s[/color]  %s%s cr" % [col, "auto " if t["source"] == "auto" else "",
			t["kind"], Economy.fmt(float(t["qty"])), Economy.display_name(String(t["id"])),
			"+" if float(t["credits"]) >= 0.0 else "", Economy.fmt(float(t["credits"]))])
	var sold := 0.0
	for k in GameState.overflow_sold:
		sold += float(GameState.overflow_sold[k]) * Trade.sell_price(String(k))
	if sold > 0.0:
		lines.append("[color=#8899bb]Overflow sold so far: %s cr[/color]" % Economy.fmt(sold))
	_log_lbl.text = "\n".join(lines)

static func _price(v: float) -> String:
	return "%.2f" % v if v < 10.0 else Economy.fmt(v)

# ── Widgets ──────────────────────────────────────────────────────────────────

func _label(t: String, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	if _font: l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	return l

func _button(t: String, col: Color) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	if _font: b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 9)
	b.add_theme_color_override("font_color", col)
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.12, 0.22, 0.9)
	st.border_color = Color(0.28, 0.42, 0.72, 0.5)
	st.set_border_width_all(1)
	st.set_corner_radius_all(3)
	st.content_margin_left = 6
	st.content_margin_right = 6
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	b.add_theme_stylebox_override("normal", st)
	var h := st.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.14, 0.2, 0.36, 1.0)
	b.add_theme_stylebox_override("hover", h)
	b.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
	b.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
	return b

func _spin(val: float) -> SpinBox:
	var sp := SpinBox.new()
	sp.min_value = 0.0
	sp.max_value = 1_000_000_000.0
	sp.step = 1.0
	sp.allow_greater = true
	sp.value = val
	sp.custom_minimum_size = Vector2(80, 0)
	sp.focus_mode = Control.FOCUS_CLICK
	return sp
