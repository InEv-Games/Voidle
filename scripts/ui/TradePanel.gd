## TradePanel — the trade window (GDD §18, playtest 31.10). It opens inside the
## view's left panel (LeftPanel.show_overlay: the panel slides out, swaps to it
## and slides back; BACK returns), or docked in the same column where a view
## has no left panel. One compact row per tradeable product, every part a
## fixed size so nothing moves as research or prices change:
##   [▣] ▁▃▅ │ cr 4.50 │ [target][■] │ [SELL][BUY]
## The icon's tooltip names the product. SELL / BUY trade one lot (Shift ×10,
## Ctrl / Cmd everything possible). With Trade Automation the target and the
## square mode button set a standing order (Off, Sell until, Buy until, Keep
## it at). A locked product keeps its row, greyed, under a "Research …" band.
## Stock and limits are in the top bar, not here.
class_name TradePanel
extends Control

static var is_open: bool = false
## The floating panel's screen rect while open (views ignore the mouse over it).
static var rect := Rect2()

## True when the mouse at `pos` is over the open floating trade panel.
static func covers(pos: Vector2) -> bool:
	return is_open and rect.has_point(pos)

## Set before adding: inside a LeftPanel (true) or floating on its own layer.
var embedded := false

const ROW_H := 24.0
const ICON_BOX := 22.0
const CHART_W := 42.0
const PRICE_W := 56.0
const TARGET_W := 42.0
const BTN_W := 40.0
const GAP := 4
const MODE_GLYPH := {"off": "–", "sell": "▼", "buy": "▲", "keep": "◆"}
## The small line under BACK: a bit of the market's life, one picked per opening.
const MARKET_LINES := [
	"Haulers dock and undock all day; every crate you trade moves the board.",
	"Brokers shout over the hum of the cargo lifts. Prices settle as the shifts change.",
	"The exchange never sleeps — big orders make waves that fade within minutes.",
	"Traders watch the screens and each other. Buy cheap, sell dear, don't flood the floor.",
	"A freighter captain swears the Goods price moved because she sneezed.",
]
## Up green, down red — prices and their charts (playtest 31.10).
const UP_COL := Color(0.45, 0.95, 0.55)
const DOWN_COL := Color(1.0, 0.45, 0.42)
const FLAT_COL := Color(0.80, 0.85, 1.0)

var _font: Font
var _panel: PanelContainer
var _list: VBoxContainer
var _status: Label
var _rows: Dictionary = {}   # id -> { price: Label, chart: Control, target: LineEdit, mode: Button }
var _refresh_t: float = 0.0

func _ready() -> void:
	TradePanel.is_open = true
	_font = load("res://theme/fonts/Tomorrow/Tomorrow-Regular.ttf")
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	if embedded:
		mouse_filter = Control.MOUSE_FILTER_PASS
		custom_minimum_size = Vector2(0, 0)
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(v)
		TradePanel.rect = Rect2()
	else:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE   # the world beside it stays usable
		_panel = PanelContainer.new()
		_panel.theme_type_variation = &"PopupCard"
		_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_panel.clip_contents = true
		add_child(_panel)
		_panel.add_child(v)
		_place()
		get_viewport().size_changed.connect(_place)

	# the market's name on top, then BACK (to the panel's own content)
	var title := _label("MARKET", 22, Color(0.65, 0.85, 1.0))
	v.add_child(title)
	var back := IconButton.create_text("‹  BACK")
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(close)
	v.add_child(back)
	# one small line of colour under it (warnings show here for a moment)
	_status = _label("", 9, Color(0.6, 0.68, 0.85))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(10, 0)
	v.add_child(_status)
	v.add_child(HSeparator.new())
	v.add_child(_column_head())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)

	# (no trade log: it didn't read well — playtest 31.10; GameState.trade_log still records)

	_build_rows()
	GameState.trade_changed.connect(_refresh)
	SkillTree.skill_unlocked.connect(func(_id: String) -> void: _build_rows())

## Floating: docked over the left panel's column, under the top bar.
func _place() -> void:
	if _panel == null:
		return
	var vw := get_viewport_rect().size
	var top := 4.0
	var hud := get_node_or_null("/root/HUDManager")
	var bar = hud.get("credits_panel") if hud != null else null
	if bar != null and is_instance_valid(bar as Node):
		top = (bar as Control).get_global_rect().end.y + 6.0
	_panel.position = Vector2(vw.x * LeftPanel.GAP, top)
	_panel.size = Vector2(vw.x * LeftPanel.WIDTH, vw.y - top - NewsFeed.HEIGHT - 8.0)
	TradePanel.rect = Rect2(_panel.position, _panel.size)

func _exit_tree() -> void:
	TradePanel.is_open = false
	TradePanel.rect = Rect2()

## BACK / Esc: inside a left panel, back to its content; floating, closes.
func close() -> void:
	TradePanel.is_open = false
	CursorManager.set_state(CursorManager.State.NORMAL)
	TooltipManager.hide_tip()
	AudioManager.play("click")
	var p := get_parent()
	while p != null and not (p is LeftPanel):
		p = p.get_parent()
	if p is LeftPanel:
		(p as LeftPanel).close_overlay()
		return
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()

## The SELL / BUY button under the mouse: its tip follows Shift / Ctrl live.
var _trade_hover: Dictionary = {}
var _trade_tip_key := ""

func _trade_tip(b: Control, id: String, selling: bool) -> void:
	b.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		_trade_hover = {"id": id, "sell": selling}
		_trade_tip_key = ""
		_show_trade_tip())
	b.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		_trade_hover = {}
		TooltipManager.hide_tip())

## What this click would do, in big colours: what it costs and what it brings.
func _show_trade_tip() -> void:
	if _trade_hover.is_empty():
		return
	var id: String = _trade_hover["id"]
	var selling: bool = _trade_hover["sell"]
	var qty := _click_qty(id, selling)
	if selling:
		qty = minf(qty, Trade.sellable(id))
	else:
		qty = minf(qty, Trade.max_buy(id))
	var credits := Trade.sell_value(id, qty) if selling else Trade.buy_cost(id, qty)
	var key := "%s|%s|%s|%s" % [id, selling, Economy.fmt(qty), Economy.fmt(credits)]
	if key == _trade_tip_key:
		return
	_trade_tip_key = key
	var pname := Economy.display_name(id)
	var lines: Array[String] = []
	# the three click sizes on top, the one in force lit
	var mode := 2 if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META) \
		else (1 if Input.is_key_pressed(KEY_SHIFT) else 0)
	var opts: Array[String] = []
	for i in 3:
		opts.append(("[color=#e8ecf6]%s[/color]" if i == mode else "%s") % ["one lot", "Shift ×10", "Ctrl/Cmd all"][i])
	lines.append("[color=#8a93b0]%s[/color]" % " · ".join(opts))
	# then the deal on one line: what comes in, then what goes out
	if qty <= 0.0:
		lines.append("[color=#e36a6a]%s[/color]" % (
			"Nothing to sell" if selling else ("Storage is full" if Trade.room(id) <= 0.0 else "Not enough Credits")))
	elif selling:
		lines.append(_amount_bb("+", Economy.CREDITS, credits, false) + "    " + _amount_bb("−", id, qty, true))
	else:
		lines.append(_amount_bb("+", id, qty, false) + "    " + _amount_bb("−", Economy.CREDITS, credits, true))
	TooltipManager.show_tip(("Sell " if selling else "Buy ") + pname, "\n".join(lines))

## "− [icon] 22K": an amount by its resource icon, red when it is paid,
## the resource's colour when it is gained (body size: the title stays larger).
static func _amount_bb(sign: String, rid: String, amount: float, paid: bool) -> String:
	var col := Color(0.89, 0.42, 0.42) if paid else Economy.color_of(rid)
	return "[color=#%s]%s %s %s[/color]" % [col.to_html(false), sign,
		UIIcons.bb(rid, 13, Economy.color_of(rid)), Economy.fmt(amount)]

func _process(delta: float) -> void:
	_show_trade_tip()   # Shift / Ctrl change the amount while hovering
	_refresh_t += delta
	if _refresh_t >= 0.5:
		_refresh_t = 0.0
		_refresh()

# ── Rows ─────────────────────────────────────────────────────────────────────

func _build_rows() -> void:
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()
	_status.text = "Research Trade Access (150 Science) to buy and sell." if not Trade.has_access() \
		else MARKET_LINES[randi() % MARKET_LINES.size()]
	for id: String in Trade.products():
		_list.add_child(_product_row(id))
	_refresh()

## A label row over the columns: "AUTOMATION" above the target and mode.
func _column_head() -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", GAP)
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(fill)
	var auto := _label("AUTOMATION", 8, Color(0.55, 0.62, 0.80))
	auto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fixed(auto, TARGET_W + GAP + ROW_H - 2.0, 12.0)
	auto.mouse_filter = Control.MOUSE_FILTER_STOP
	_tip(auto, "Automation", func() -> String:
		return "Set a target and a mode: the market trades for you every 20 s, a little worse than by hand." \
			if Trade.has_automation() else "Research Trade Automation for standing orders.")
	head.add_child(auto)
	var trade_sp := Control.new()   # over SELL / BUY
	_fixed(trade_sp, BTN_W * 2.0 + GAP, 12.0)
	trade_sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(trade_sp)
	return head

## One lot of a product, grown with the player's stockpile (playtest 31.10):
## about LOT_SHARE of its storage (or of the stock, for uncapped Science),
## snapped to a round 1-2-5 number — 10 with a 200 store, 50 at 1K, 500 at
## 10K, 5K at 100K. Only the amount is shown, never the share.
const LOT_SHARE := 0.05

static func lot(id: String) -> float:
	var cap := Economy.cap(id)
	var scale := maxf(Trade.stock(id), 100.0) if cap == INF else maxf(cap, Trade.stock(id))
	return _nice(scale * LOT_SHARE)

## The 1-2-5 number nearest below or at `v` (at least 1).
static func _nice(v: float) -> float:
	if v <= 1.0:
		return 1.0
	var mag := pow(10.0, floorf(log(v) / log(10.0)))
	var f := v / mag
	return (5.0 if f >= 5.0 else (2.0 if f >= 2.0 else 1.0)) * mag

## Units a click trades: one lot, ×10 with Shift, everything with Ctrl / Cmd.
static func _click_qty(id: String, selling: bool) -> float:
	if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META):
		return Trade.sellable(id) if selling else Trade.max_buy(id)
	return lot(id) * (10.0 if Input.is_key_pressed(KEY_SHIFT) else 1.0)

## A fixed-size control: never grows with its content.
static func _fixed(c: Control, w: float, h: float = ROW_H) -> Control:
	c.custom_minimum_size = Vector2(w, h)
	c.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return c

func _product_row(id: String) -> Control:
	var block := Trade.product_block(id)
	var auto_ok := Trade.has_automation()
	# the row sits under an optional "Research …" band; same layout either way
	var stack := MarginContainer.new()
	stack.custom_minimum_size = Vector2(0, ROW_H)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", GAP)
	stack.add_child(row)

	# the product: an icon in an item box; its name in the tooltip
	var box := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.14, 0.9)
	sb.border_color = Color(Economy.color_of(id), 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	box.add_theme_stylebox_override("panel", sb)
	_fixed(box, ICON_BOX, ICON_BOX)
	var icon := TextureRect.new()
	icon.texture = UIIcons.get_icon(id if not Economy.is_raw(id) else UIIcons.RAW_PLACEHOLDER)
	icon.self_modulate = Economy.color_of(id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(16, 16)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	_tip(box, Economy.display_name(id), func() -> String:
		return "%s %s a unit now (usually %s).%s" % [UIIcons.bb(Economy.CREDITS, 11, Economy.color_of(Economy.CREDITS)), _price(Trade.unit_price(id)),
			_price(Trade.reference_price(id)), _trend(id)])
	row.add_child(box)

	# the unit price in credits, right by the icon, in a box like it
	var pbox := PanelContainer.new()
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.04, 0.07, 0.14, 0.9)
	psb.border_color = Color(Economy.color_of(Economy.CREDITS), 0.45)
	psb.set_border_width_all(1)
	psb.set_corner_radius_all(3)
	psb.content_margin_left = 4
	psb.content_margin_right = 4
	pbox.add_theme_stylebox_override("panel", psb)
	_fixed(pbox, PRICE_W, ICON_BOX)
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 3)
	prow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pbox.add_child(prow)
	var cr := TextureRect.new()
	cr.texture = UIIcons.get_icon("credits")
	cr.self_modulate = Economy.color_of(Economy.CREDITS)
	cr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cr.custom_minimum_size = Vector2(10, 10)
	cr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prow.add_child(cr)
	var price := _label("", 10, Color(0.80, 0.85, 1.0))
	price.clip_text = true
	price.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prow.add_child(price)
	pbox.mouse_filter = Control.MOUSE_FILTER_STOP
	_tip(pbox, "Price", func() -> String:
		return "%s %s a unit, buying or selling. Big trades move it as they go.%s" % [
			UIIcons.bb(Economy.CREDITS, 11, Economy.color_of(Economy.CREDITS)), _price(Trade.unit_price(id)), _trend(id)])
	row.add_child(pbox)

	var chart := _Sparkline.new()
	chart.product = id
	_fixed(chart, CHART_W, ROW_H - 8.0)
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # fills the room up to the automation
	chart.mouse_filter = Control.MOUSE_FILTER_STOP
	_tip(chart, "%s price" % Economy.display_name(id), func() -> String:
		var minutes := float(Trade.history(id).size()) * Trade.HISTORY_STEP / 60.0
		return "The last %.0f min of its price against the usual price (dotted).\nGreen: up, dearer than usual — good to sell. Red: down, cheap — good to buy." % maxf(minutes, 1.0))
	row.add_child(chart)

	# automation: a target and the square mode button (greyed until researched)
	var o := Trade.order(id)
	var target := LineEdit.new()
	_fixed(target, TARGET_W, ROW_H - 4.0)
	target.placeholder_text = "target"
	target.text = Economy.fmt(float(o["target"])) if float(o["target"]) > 0.0 else ""
	target.add_theme_font_size_override("font_size", 10)
	var mode := _compact_button(MODE_GLYPH.get(String(o["mode"]), "–"), UIStyle.DEFAULT)
	_fixed(mode, ROW_H - 2.0, ROW_H - 2.0)
	mode.add_theme_font_size_override("font_size", 11)
	var live := block == ""
	target.editable = auto_ok and live
	mode.disabled = not (auto_ok and live)
	var apply := func(new_mode: String) -> void:
		var why := Trade.set_order(id, new_mode, _parse(target.text))
		if why != "":
			AudioManager.play("error")
			_status.text = "⚠ %s: %s" % [Economy.display_name(id), why]
			get_tree().create_timer(4.0).timeout.connect(func() -> void:
				if is_instance_valid(_status) and _status.text.begins_with("⚠"):
					_status.text = MARKET_LINES[randi() % MARKET_LINES.size()])
		_refresh()
	target.text_submitted.connect(func(_t: String) -> void: apply.call(String(Trade.order(id)["mode"])))
	target.focus_exited.connect(func() -> void:
		if target.editable:
			apply.call(String(Trade.order(id)["mode"])))
	mode.pressed.connect(func() -> void: _open_mode_menu(mode, id, apply))
	_tip(target, "Automation target", func() -> String:
		return "The amount the standing order works towards." if auto_ok else "Research Trade Automation for standing orders.")
	_tip(mode, "Automation", func() -> String:
		if not auto_ok:
			return "Research Trade Automation for standing orders."
		return "%s\n\n%s\n\nClick to change: Off · Sell until · Buy until · Keep it at." % [
			Trade.mode_label(String(Trade.order(id)["mode"])), Trade.order_text(id)])
	row.add_child(target)
	row.add_child(mode)

	var sell := _compact_button("SELL", UIStyle.NEGATIVE)   # sell red, buy green
	_fixed(sell, BTN_W, ROW_H - 2.0)
	sell.disabled = not live
	sell.pressed.connect(func() -> void:
		_do(Trade.sell(id, _click_qty(id, true)))
		_trade_tip_key = "")   # the tip shows the next click
	_trade_tip(sell, id, true)
	row.add_child(sell)
	var buy := _compact_button("BUY", UIStyle.POSITIVE)
	_fixed(buy, BTN_W, ROW_H - 2.0)
	buy.disabled = not live
	buy.pressed.connect(func() -> void:
		_do(Trade.buy(id, _click_qty(id, false)))
		_trade_tip_key = "")
	_trade_tip(buy, id, false)
	row.add_child(buy)

	if not live:
		# locked: same row, greyed, under a band that says what opens it
		row.modulate = Color(1, 1, 1, 0.35)
		var band := Label.new()
		band.text = block
		band.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		band.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		band.add_theme_font_size_override("font_size", 10)
		band.add_theme_color_override("font_color", Color(1.0, 0.82, 0.55))
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color(0.03, 0.05, 0.10, 0.55)
		bsb.set_corner_radius_all(3)
		band.add_theme_stylebox_override("normal", bsb)
		band.mouse_filter = Control.MOUSE_FILTER_STOP   # nothing under it reacts
		stack.add_child(band)
	_rows[id] = {"price": price, "chart": chart, "target": target, "mode": mode}
	return stack

## The four modes in a small menu under the square button — drawn in the game
## canvas (layer 490, under the cursor's 500), not as a popup window, so the
## cursor stays on top. A click outside closes it.
func _open_mode_menu(anchor: Control, id: String, apply: Callable) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 490
	get_tree().root.add_child(layer)
	var shade := Control.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			layer.queue_free())
	layer.add_child(shade)
	var box := PanelContainer.new()
	box.theme_type_variation = &"TooltipPanel"
	layer.add_child(box)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	box.add_child(list)
	var now := String(Trade.order(id)["mode"])
	for m: String in Trade.MODES:
		var b := Button.new()
		b.text = "%s  %s" % [MODE_GLYPH[m], Trade.mode_label(m)]
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 11)
		if m == now:
			b.add_theme_color_override("font_color", Color(1.0, 0.85, 0.40))
		b.mouse_entered.connect(func() -> void: CursorManager.set_state(CursorManager.State.POINTER))
		b.mouse_exited.connect(func() -> void: CursorManager.set_state(CursorManager.State.NORMAL))
		b.pressed.connect(func() -> void:
			AudioManager.play("click")
			CursorManager.set_state(CursorManager.State.NORMAL)
			layer.queue_free()
			apply.call(m))
		list.add_child(b)
	var r := anchor.get_global_rect()
	box.position = Vector2(r.position.x, r.end.y + 2.0)
	# keep it on screen
	await get_tree().process_frame
	if is_instance_valid(box):
		var vp := get_viewport_rect().size
		box.position.x = minf(box.position.x, vp.x - box.size.x - 4.0)
		if box.position.y + box.size.y > vp.y - 4.0:
			box.position.y = r.position.y - box.size.y - 2.0

func _do(amount: float) -> void:
	AudioManager.play("click" if amount > 0.0 else "error")
	_refresh()

func _refresh() -> void:
	for id: String in _rows:
		var e: Dictionary = _rows[id]
		if not is_instance_valid(e["price"]):
			continue
		var m := Trade.price_mult(id)
		var tc := UP_COL if m > 1.01 else (DOWN_COL if m < 0.99 else FLAT_COL)
		(e["price"] as Label).text = _price(Trade.unit_price(id))
		(e["price"] as Label).add_theme_color_override("font_color", tc)
		(e["chart"] as Control).queue_redraw()
		(e["mode"] as Button).text = MODE_GLYPH.get(String(Trade.order(id)["mode"]), "–")
		var target := e["target"] as LineEdit
		if not target.has_focus():
			var t := float(Trade.order(id)["target"])
			target.text = Economy.fmt(t) if t > 0.0 else ""

## " ▲12%" / " ▼8%" against the reference price ("" when close to it).
static func _trend(id: String) -> String:
	var d := Trade.price_mult(id) - 1.0
	if absf(d) < 0.01:
		return ""
	return "\n%s%d%% against the reference." % ["▲" if d > 0.0 else "▼", int(round(absf(d) * 100.0))]

static func _price(v: float) -> String:
	return "%.2f" % v if v < 10.0 else Economy.fmt(v)

## "1.2K" / "300" / "" → a number (K / M suffixes understood).
static func _parse(t: String) -> float:
	var s := t.strip_edges().to_upper().replace(",", "")
	if s == "":
		return 0.0
	var mult := 1.0
	if s.ends_with("K"):
		mult = 1000.0
		s = s.trim_suffix("K")
	elif s.ends_with("M"):
		mult = 1_000_000.0
		s = s.trim_suffix("M")
	return maxf(s.to_float() * mult, 0.0)

# ── Widgets ──────────────────────────────────────────────────────────────────

func _label(t: String, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	if _font: l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

## A theme button with its side padding trimmed, so a fixed width holds its text.
static func _compact_button(t: String, variation: StringName) -> Button:
	var b := Button.new()
	b.text = t
	b.theme_type_variation = variation
	b.focus_mode = Control.FOCUS_NONE
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 9)
	for st: String in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		var base := UIStyle.box(variation, st)
		if base == null:
			continue
		var sb := base.duplicate() as StyleBox
		sb.content_margin_left = 2.0
		sb.content_margin_right = 2.0
		sb.content_margin_top = 1.0
		sb.content_margin_bottom = 1.0
		b.add_theme_stylebox_override(st, sb)
	return b

## A live tooltip: `body` is called each time the mouse comes over `c`.
func _tip(c: Control, title: String, body: Callable) -> void:
	c.mouse_entered.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.POINTER)
		TooltipManager.show_tip(title, String(body.call())))
	c.mouse_exited.connect(func() -> void:
		CursorManager.set_state(CursorManager.State.NORMAL)
		TooltipManager.hide_tip())

## The row's price chart: the price multiplier over time (Trade.history), the
## reference as a dotted line; dearer than usual orange, cheaper green.
class _Sparkline extends Control:
	const CHART_SPAN := 0.2
	var product := ""

	func _draw() -> void:
		var h := Trade.history(product)
		var w := size.x
		var hh := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.08, 0.16, 0.6))
		var pts: Array = h.duplicate()
		pts.append(Trade.price_mult(product))   # the price now closes the line
		# one scale for every product: at least ±CHART_SPAN around the reference,
		# so a 1% wobble looks small and a real 14% move stands out
		var lo := 1.0 - CHART_SPAN
		var hi := 1.0 + CHART_SPAN
		for m in pts:
			lo = minf(lo, float(m) - 0.02)
			hi = maxf(hi, float(m) + 0.02)
		var y_of := func(m: float) -> float: return hh - (m - lo) / (hi - lo) * hh
		var ref_y: float = y_of.call(1.0)
		var x := 0.0
		while x < w:   # the reference, dotted
			draw_line(Vector2(x, ref_y), Vector2(minf(x + 2.0, w), ref_y), Color(0.7, 0.75, 0.9, 0.45), 1.0)
			x += 5.0
		if pts.size() < 2:
			return
		var line := PackedVector2Array()
		for i in pts.size():
			line.append(Vector2(float(i) / float(pts.size() - 1) * w, y_of.call(float(pts[i]))))
		var last := float(pts[pts.size() - 1])
		var col := TradePanel.UP_COL if last > 1.01 else (TradePanel.DOWN_COL if last < 0.99 else TradePanel.FLAT_COL)
		draw_polyline(line, col, 1.5, true)
		draw_circle(line[line.size() - 1], 2.0, col)
