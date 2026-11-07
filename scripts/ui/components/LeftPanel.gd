## The one left panel every view uses (design: Side Panel):
##   PanelContent       the view's own lists — each view fills this (scene nodes or code)
##   ─────────────────
##   Shortcuts          Upgrade Tree // Trade // Explore, built by HUDManager
## Layout: scenes/ui/components/LeftPanel.tscn. Look: SidePanel.
## The panel places itself (GAP / WIDTH, under the HUD's resource bar), so it
## sits in the same spot in every view; views only slide it (set_slide).
## While a view has one the HUD hides its own bottom-left shortcut row, so the
## shortcuts close with the panel.
class_name LeftPanel
extends PanelContainer

const GROUP := &"left_panel"
## Empty strip left of the open panel, as a fraction of the screen width.
const GAP := 0.025
## Panel width, as a fraction of the screen width.
const WIDTH := 0.3

@onready var content: VBoxContainer = $Layout/PanelContent
@onready var _shortcuts: HBoxContainer = $Layout/Shortcuts

## 1 = open, 0 = slid fully off the left edge (as the view set it).
var slide_t := 1.0

## Overlay content (playtest 31.10: Trade opens inside the panel): the panel
## stays where it is and its content is swapped for the overlay in place, with
## the CyberReveal scramble as the only transition (no slide out / in);
## close_overlay() does the same the other way. The view's own content is only
## hidden meanwhile (and anything the view rebuilds stays hidden), so going
## back shows it as it was. The view's hide button hides the overlay with the
## panel and brings it back on unhide; opening an overlay on a closed panel asks
## the view to open it (or, in a view that can't, shows it anyway).
var _overlay: Control = null
var _hidden: Array = []          # the view's content hidden behind the overlay
var _force_open := false   # a view with no open/close of its own: keep the overlay visible

func overlay() -> Control:
	return _overlay if _overlay != null and is_instance_valid(_overlay) else null

## Shows `c` in place of the panel's content (swapped in place, scrambled in).
func show_overlay(c: Control) -> void:
	if slide_t < 0.99:
		var view := get_tree().current_scene
		if view != null and view.has_method("_set_panel_open"):
			view.call("_set_panel_open", true)   # the view slides it in, its normal way
		else:
			_force_open = true
	_swap(func() -> void:
		if overlay() != null:
			_overlay.queue_free()
		else:
			for child in content.get_children():
				if child is CanvasItem and (child as CanvasItem).visible:
					_hidden.append(weakref(child))
					(child as CanvasItem).visible = false
		_overlay = c
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(c)
		reveal())

## Back to the view's own content.
func close_overlay() -> void:
	if overlay() == null:
		return
	_swap(func() -> void:
		if overlay() != null:
			_overlay.queue_free()
		_overlay = null
		_force_open = false
		for w in _hidden:
			var n = (w as WeakRef).get_ref()
			if n != null and is_instance_valid(n):
				(n as CanvasItem).visible = true
		_hidden.clear()
		reveal())

## Swaps the content right away; reveal() inside `change` plays the scramble.
func _swap(change: Callable) -> void:
	change.call()
	_place()
	queue_redraw()   # _force_open may have changed the backdrop's opacity

## Whatever the view adds while an overlay is up stays behind it.
func _on_content_child(n: Node) -> void:
	if overlay() != null and n != _overlay and n is CanvasItem:
		(n as CanvasItem).visible = false
		_hidden.append(weakref(n))

func _ready() -> void:
	add_to_group(GROUP)
	_hide_native_frame()   # the stroke is drawn by hand (see Left stroke)
	item_rect_changed.connect(queue_redraw)   # the backdrop follows the slide
	content.child_entered_tree.connect(_on_content_child)
	var hud := get_node_or_null("/root/HUDManager")
	if hud != null:
		hud.fill_shortcuts(_shortcuts)
	_place()
	reveal()   # the view's first menu

## Plays the panel's opening animation over the content once this frame's
## building is done: every row comes in on its own tween, as when the panel
## opens (see "Open / close" below). Views call it when they switch to a new
## menu; several calls in one frame play it once.
var _reveal_queued := false

func reveal() -> void:
	if _reveal_queued:
		return
	_reveal_queued = true
	_play_reveal.call_deferred()

func _play_reveal() -> void:
	_reveal_queued = false
	# closed or mid open / close: the slide brings the rows in itself
	if not is_inside_tree() or not visible or _effective_t() < 1.0:
		return
	for id in _rows.keys():   # rows of the menu just replaced
		if not is_instance_valid(_rows[id]["node"]) or not (_rows[id]["node"] as Control).is_visible_in_tree():
			_finish_row(id)
	_opening = true
	_collect_rows($Layout, 0)   # each new row starts its own tween
	if _rows.is_empty():
		_opening = false

func _process(_delta: float) -> void:
	if absf(offset_top - _hud_bar_height()) > 0.5:
		_place()
	_update_stroke_span()
	_tick_nav(_delta)

## Slides the panel between hidden (0) and open (1).
func set_slide(t: float) -> void:
	slide_t = t
	_place()
	queue_redraw()

## Backdrop (the panel itself is transparent): darkens from the screen's left
## edge to the right, so the content stays readable over a zoomed-in planet.
## Each stop is (x as a fraction of the panel width, opacity); x 0 is the panel's
## left edge, the first stop starts at the screen edge, the last fades out past
## the panel's right edge. Its colour is the SidePanel style's bg_color.
const BACKDROP_STOPS := [[0.0, 0.88], [0.7, 0.78], [1.0, 0.5], [1.35, 0.0]]
## How much darker than the style's bg_color (0 = same, 1 = black).
const BACKDROP_DARKEN := 0.5

func _draw() -> void:
	_draw_backdrop()
	var f := _frame_style()
	if f != null and f.border_width_left > 0:
		draw_rect(Rect2(0.0, _stroke_span.x, f.border_width_left, _stroke_span.y - _stroke_span.x),
			f.border_color)

func _draw_backdrop() -> void:
	var t := _effective_t()
	if t <= 0.0:
		return
	var sb := _frame_style()
	var col := Color(0.035, 0.094, 0.169)
	if sb != null:
		col = sb.bg_color
	col = col.darkened(BACKDROP_DARKEN)
	var xs: Array[float] = []
	var alphas: Array[float] = []
	for s in BACKDROP_STOPS:
		xs.append(float(s[0]) * size.x)
		alphas.append(float(s[1]) * t)
	xs[0] = minf(-position.x, 0.0)   # reach back to the screen's left edge
	for i in xs.size() - 1:
		var a := Color(col, alphas[i])
		var b := Color(col, alphas[i + 1])
		draw_polygon(
			PackedVector2Array([Vector2(xs[i], 0), Vector2(xs[i + 1], 0),
				Vector2(xs[i + 1], size.y), Vector2(xs[i], size.y)]),
			PackedColorArray([a, b, b, a]))

# ── Left stroke ───────────────────────────────────────────────────────────────
# The SidePanel style's left border, drawn by hand and only between the
# resource bar and the news bar: both lie on top of the panel and are a little
# see-through, so a full-height stroke showed through them. The panel itself
# gets an empty style with the same content margins.

var _stroke_span := Vector2.ZERO   # (top, bottom) of the stroke, in panel space

## The SidePanel style from the theme (not the override this panel carries).
func _frame_style() -> StyleBoxFlat:
	var th := ThemeDB.get_project_theme()
	if th != null and th.has_stylebox(&"panel", theme_type_variation):
		return th.get_stylebox(&"panel", theme_type_variation) as StyleBoxFlat
	return null

func _hide_native_frame() -> void:
	var f := _frame_style()
	var empty := StyleBoxEmpty.new()
	if f != null:
		empty.content_margin_left = f.content_margin_left
		empty.content_margin_top = f.content_margin_top
		empty.content_margin_right = f.content_margin_right
		empty.content_margin_bottom = f.content_margin_bottom
	add_theme_stylebox_override(&"panel", empty)

## The gap between the resource bar's bottom and the news bar's top.
func _update_stroke_span() -> void:
	var top := 0.0
	var bottom := size.y
	var hud := get_node_or_null("/root/HUDManager")
	var bar = hud.get("credits_panel") if hud != null else null
	if bar != null and is_instance_valid(bar as Node) and (bar as Control).is_visible_in_tree():
		top = (bar as Control).get_global_rect().end.y - global_position.y
	var news := get_tree().get_first_node_in_group(&"news_panel") as Control
	if news != null and news.is_visible_in_tree():
		bottom = news.get_global_rect().position.y - global_position.y
	var span := Vector2(clampf(top, 0.0, size.y), clampf(bottom, 0.0, size.y))
	if not span.is_equal_approx(_stroke_span):
		_stroke_span = span
		queue_redraw()

## The way back up from a menu ("‹  HALLACLI"): a plain text button, shown
## above the menu's hero.
const BACK_FONT := 11

static func back_button(label: String) -> Button:
	var b := Button.new()
	b.theme_type_variation = &"ButtonFlat"
	b.text = "‹  " + label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override(&"font_size", BACK_FONT)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

## The panel's right edge as a fraction of the screen width, for a slide t.
static func edge_frac(t: float = 1.0) -> float:
	return (GAP + WIDTH) * t

## The panel never moves: closing it scrambles its text into random glyphs and
## fades the content out (opening runs the same backwards); the left stroke
## stays put. `t` is the view's slide value, so its tween drives the effect.
func _effective_t() -> float:
	return 1.0 if _force_open and overlay() != null else slide_t

func _place() -> void:
	var t := _effective_t()
	anchor_left = GAP
	anchor_right = anchor_left + WIDTH
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_right = 0.0
	#offset_top = _hud_bar_height()
	offset_top = 0.0
	offset_bottom = 0.0
	_apply_fade(t)

# ── Open / close: scramble out, scramble in ──────────────────────────────────

## The panel's content comes and goes row by row (a row: each line of the
## panel — a hero, a card, a header, the shortcut bar… — found by opening the
## plain VBoxContainers it is stacked in). Every open / close is rolled anew:
## the order rows go in, their blinks and which chars scramble when.
##   Closing: each row fades over its own ROW_FADE share of the slide, placed
##            at random, so they leave in a new order each time.
##   Opening: each row runs its own tween (ROW_IN_SEC), starting at a random
##            moment within ROW_IN_STAGGER — it may run past the slide's end.
const ROW_FADE := 0.45
const ROW_IN_SEC := 0.45
const ROW_IN_STAGGER := 0.6
## Each char turns into glyphs once its row drops below the char's own
## threshold, picked in this range — a few go right away, all by the lower end.
const SCRAMBLE_FROM := Vector2(0.35, 1.0)
## Share of a label's chars that scramble at all; the rest only fade.
const SCRAMBLE_SHARE := 1.0
const FADE_GLYPH_SEC := 0.09   # how often a scrambled glyph changes (slow = analog)
## Blink while a row comes or goes: it drops out like a weak tape signal.
## Every BLINK_SEC a row may dip (BLINK_CHANCE) to a random opacity between
## BLINK_DIP.x and BLINK_DIP.y of what its fade says.
const BLINK_SEC := 0.07
const BLINK_CHANCE := 0.35
const BLINK_DIP := Vector2(0.15, 0.6)

## Inside a row, its items (icons, labels, buttons… in reading order: left to
## right, line by line) come one after another: each over ITEM_FADE of the
## row's progress, their starts spread evenly over the rest.
const ITEM_FADE := 0.4

var _rows: Dictionary = {}   # row id → {node, orig, last, p, cap, s, seed, labels, items, tween}
var _fade: Dictionary = {}   # label id → {node, text, last, h}
var _fade_t := 1.0
var _opening := false        # rows run their own tweens (see Opening above)
var _fade_rng := RandomNumberGenerator.new()

## True while rows are coming or going (ScreenFX leaves the panel alone then).
func is_animating() -> bool:
	return _fade_t < 1.0 or not _rows.is_empty()

## A row's blink factor this BLINK_SEC step; `seed` is rolled per row per
## open / close, so the pattern never repeats.
func _blink(bucket: int, seed: int) -> float:
	var r := float(hash(Vector2i(bucket, seed)) & 0xffff) / 65535.0
	if r < BLINK_CHANCE:
		return lerpf(BLINK_DIP.x, BLINK_DIP.y, r / BLINK_CHANCE)
	return 1.0

## A new open / close starts: new order, new blinks, new scramble.
func _reroll() -> void:
	for r: Dictionary in _rows.values():
		_kill_row_tween(r)
		r["s"] = _fade_rng.randf_range(0.0, 1.0 - ROW_FADE)
		r["seed"] = _fade_rng.randi()
		r["cap"] = r["p"]   # closing never brings a half-arrived row back up
	for e: Dictionary in _fade.values():
		e["h"] = _thresholds((e["text"] as String).length())

func _apply_fade(t: float) -> void:
	if t == _fade_t and (t >= 1.0 or t <= 0.0):
		return   # settled: nothing to animate
	var from := _fade_t
	_fade_t = t
	var layout := $Layout as Control
	var shown := t > 0.0
	layout.visible = shown
	mouse_filter = Control.MOUSE_FILTER_STOP if shown else Control.MOUSE_FILTER_IGNORE
	if not shown:
		return
	var opening_start := from <= 0.0
	var closing_start := t < from and (from >= 1.0 or _opening)
	if opening_start or closing_start:
		_opening = opening_start
		VAM.play(&"ui/LeftPanel_Open" if opening_start else &"ui/LeftPanel_Close")
		_collect_rows(layout, 0)
		_reroll()
		if opening_start:
			for id in _rows:
				_start_row_tween(id)
			return
	else:
		_collect_rows(layout, 0)   # rows built meanwhile join in
	if _opening:
		return   # the rows' own tweens drive them
	if t >= 1.0:
		_end_fade()   # a close reversed before it finished
		return
	var bb := Time.get_ticks_msec() / int(BLINK_SEC * 1000.0)
	var gb := Time.get_ticks_msec() / int(FADE_GLYPH_SEC * 1000.0)
	for id in _rows.keys():
		var r: Dictionary = _rows[id]
		var s: float = r["s"]
		_set_row(id, minf(float(r["cap"]), smoothstep(s, s + ROW_FADE, t)), bb, gb)

## Rows (and the labels inside each) under `n`; `row` is the row we are in.
func _collect_rows(n: Node, row: int) -> void:
	for c in n.get_children():
		if not (c is Control) or not (c as Control).is_visible_in_tree():
			continue
		var rid := row
		if rid == 0:
			if (c is VBoxContainer or c is ScrollContainer or c is MarginContainer) \
					and not CyberReveal._is_block(c as Control):
				_collect_rows(c, 0)   # a stack of rows (or a wrapper around one), not a row
				continue
			rid = c.get_instance_id()
			if not _rows.has(rid):
				# a row found as an opening starts is hidden till its tween; one found
				# as a close starts (or reverses) is still fully there — not judged by
				# _fade_t, which already dropped below 1 when a close begins
				var start := 0.0 if _opening else 1.0
				_rows[rid] = {"node": c, "orig": _base_modulate(c as Control),
					"last": (c as Control).modulate, "p": start, "cap": 1.0,
					"s": _fade_rng.randf_range(0.0, 1.0 - ROW_FADE), "seed": _fade_rng.randi(),
					"labels": [], "items": _collect_items(c as Control), "tween": null,
					"blink_b": -1}
				if _opening:
					_start_row_tween(rid)
		if c is Label and not _fade.has(c.get_instance_id()):
			var text := (c as Label).text
			if text.strip_edges() != "":
				_fade[c.get_instance_id()] = {"node": c, "text": text, "last": text,
					"h": _thresholds(text.length())}
				(_rows[rid]["labels"] as Array).append(c.get_instance_id())
		_collect_rows(c, rid)

func _start_row_tween(id: int) -> void:
	var r: Dictionary = _rows[id]
	_kill_row_tween(r)
	_set_row(id, 0.0, 0, 0)   # hidden until its turn
	var tw := create_tween()
	tw.tween_interval(_fade_rng.randf_range(0.0, ROW_IN_STAGGER))
	tw.tween_method(func(p: float) -> void:
		_set_row(id, p, Time.get_ticks_msec() / int(BLINK_SEC * 1000.0),
			Time.get_ticks_msec() / int(FADE_GLYPH_SEC * 1000.0)),
		0.0, 1.0, ROW_IN_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_finish_row.bind(id))
	r["tween"] = tw

func _kill_row_tween(r: Dictionary) -> void:
	var tw = r["tween"]
	if tw != null and (tw as Tween).is_valid():
		(tw as Tween).kill()
	r["tween"] = null

## A row's items in reading order (tree order: an HBox runs left to right,
## a card's lines top to bottom), each with where it starts in the row.
func _collect_items(row: Control) -> Array:
	var leaves: Array[Control] = []
	_item_leaves(row, leaves)
	var items := []
	var n := leaves.size()
	for i in n:
		var c := leaves[i]
		items.append({"node": c, "orig": _base_modulate(c), "last": c.modulate,
			"o": (float(i) / float(n - 1)) * (1.0 - ITEM_FADE) if n > 1 else 0.0})
	return items

func _item_leaves(n: Control, out: Array[Control]) -> void:
	for c in n.get_children():
		if not (c is Control) or not (c as Control).visible:
			continue
		var ctl := c as Control
		var has_kids := ctl.get_children().any(func(k: Node) -> bool: return k is Control)
		if ctl is Label or ctl is TextureRect or ctl is BaseButton or ctl is Separator or not has_kids:
			out.append(ctl)   # an item (a button is one, whatever is inside it)
		else:
			_item_leaves(ctl, out)

## Shows row `id` at progress p (0 gone, 1 fully there): opacity with blinks,
## its items one after another, its labels scrambled to match.
func _set_row(id: int, p: float, blink_bucket: int, glyph_bucket: int) -> void:
	var r: Dictionary = _rows.get(id, {})
	if r.is_empty():
		return
	r["p"] = p
	if is_instance_valid(r["node"]):
		var node := r["node"] as Control
		if node.modulate == r["last"]:   # else someone else drives it: leave it be
			var blink := _blink(blink_bucket, r["seed"]) if p > 0.0 and p < 1.0 else 1.0
			# One sound per dip: _set_row runs every frame with the same bucket,
			# so play only the first time a row dips in a given BLINK_SEC step.
			if blink < 1.0 and r.get("blink_b", -1) != blink_bucket:
				r["blink_b"] = blink_bucket
				VAM.play(&"ui/blink")
			var a := p * blink
			var orig: Color = r["orig"]
			var m := Color(orig.r, orig.g, orig.b, orig.a * a)
			node.modulate = m
			r["last"] = m
	var item_p := {}   # label id → its own progress, for the scramble
	for it: Dictionary in r["items"]:
		if not is_instance_valid(it["node"]):
			continue
		var ic := it["node"] as Control
		var o: float = it["o"]
		var ip := smoothstep(o, o + ITEM_FADE, p)
		item_p[ic.get_instance_id()] = ip
		if ic.modulate == it["last"]:   # else someone else drives it
			var io: Color = it["orig"]
			var im := Color(io.r, io.g, io.b, io.a * ip)
			ic.modulate = im
			it["last"] = im
	for lid in r["labels"]:
		var e: Dictionary = _fade.get(lid, {})
		if e.is_empty() or not is_instance_valid(e["node"]):
			continue
		var lab := e["node"] as Label
		if lab.text != e["last"]:   # the game wrote new text meanwhile: take it
			e["text"] = lab.text
			e["h"] = _thresholds(lab.text.length())
		var text: String = e["text"]
		var h: PackedFloat32Array = e["h"]
		var lp: float = item_p.get(lid, p)
		var out := ""
		for i in text.length():
			var ch := text[i]
			if ch.strip_edges() == "" or lp >= h[i]:
				out += ch
				continue
			var g := CyberReveal.GLYPHS[absi(hash(Vector3i(i, glyph_bucket, lid & 0xffff))) % CyberReveal.GLYPHS.length()]
			out += g.to_lower() if ch != ch.to_upper() else g
		lab.text = out
		e["last"] = out

## A row is fully back: its real modulate and text, and it leaves the books.
func _finish_row(id: int) -> void:
	var r: Dictionary = _rows.get(id, {})
	if r.is_empty():
		return
	_restore_row(r)
	_rows.erase(id)
	if _rows.is_empty():
		_opening = false

func _restore_row(r: Dictionary) -> void:
	_kill_row_tween(r)
	if is_instance_valid(r["node"]) and (r["node"] as Control).modulate == r["last"]:
		(r["node"] as Control).modulate = r["orig"]
	for it: Dictionary in r["items"]:
		if is_instance_valid(it["node"]) and (it["node"] as Control).modulate == it["last"]:
			(it["node"] as Control).modulate = it["orig"]
	for lid in r["labels"]:
		var e: Dictionary = _fade.get(lid, {})
		if not e.is_empty() and is_instance_valid(e["node"]) and (e["node"] as Label).text == e["last"]:
			(e["node"] as Label).text = e["text"]
		_fade.erase(lid)

## A row's own modulate — not a passing ScreenFX flicker.
func _base_modulate(c: Control) -> Color:
	var fx := get_node_or_null("/root/ScreenFX")
	if fx != null and fx.has_method("base_modulate"):
		return fx.call("base_modulate", c)
	return c.modulate

func _thresholds(n: int) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	for i in n:
		# -1: never scrambles (p >= -1 always)
		h.append(_fade_rng.randf_range(SCRAMBLE_FROM.x, SCRAMBLE_FROM.y) \
			if _fade_rng.randf() < SCRAMBLE_SHARE else -1.0)
	return h

## Puts every row back as it was (the panel is fully open again).
func _end_fade() -> void:
	for r: Dictionary in _rows.values():
		_restore_row(r)
	_rows.clear()
	_fade.clear()
	_opening = false

## Height of the HUD's resource bar — the panel starts below it.
func _hud_bar_height() -> float:
	var hud := get_node_or_null("/root/HUDManager")
	var cp = hud.get("credits_panel") if hud != null else null
	if cp != null and is_instance_valid(cp as Node) and (cp as Control).size.y > 4.0:
		return (cp as Control).size.y + 6.0
	return 58.0

# ── Keyboard & Controller Navigation ─────────────────────────────────────────
# Allows navigating LeftPanel (and any child dropdown, context menu, trait
# picker, or modal popup) with WASD / Arrow Keys / Enter / Backspace / C or
# Controller Left Stick / D-Pad / A / B / X / Y / LB / RB.

var _nav_active := false
var _nav_focus: Control = null
var _nav_last_root_id: int = 0
var _saved_focus_by_root: Dictionary = {}   # root instance_id -> WeakRef(Control)
var _stick_dir := Vector2i.ZERO
var _stick_timer := 0.0
const STICK_DEADZONE := 0.45
const STICK_INITIAL_DELAY := 0.26
const STICK_REPEAT_DELAY := 0.11

func _nav_blocked() -> bool:
	if not is_visible_in_tree() or GameState.showcase_mode:
		return true
	if SkillTreeView.is_open:
		return true
	var dc := get_node_or_null("/root/DevConsole")
	if dc != null and bool(dc.get("_open")):
		return true
	var scene := get_tree().current_scene
	if scene != null and scene.get("_placing_def") != null and not bool(scene.get("_naming_open")):
		return true
	return false

## Returns the active navigation container: topmost popup/dropdown first, else LeftPanel.$Layout.
func _active_nav_root() -> Node:
	var root_vp := get_tree().root
	if root_vp != null:
		for i in range(root_vp.get_child_count() - 1, -1, -1):
			var rch := root_vp.get_child(i)
			if rch is CanvasLayer and rch.has_meta("left_panel_dropdown"):
				return rch
	var scene := get_tree().current_scene
	if scene != null:
		for i in range(scene.get_child_count() - 1, -1, -1):
			var ch := scene.get_child(i)
			if ch is ModalPopup:
				return ch
		if GameOverlays._trait_layer != null and is_instance_valid(GameOverlays._trait_layer):
			return GameOverlays._trait_layer
		if ContextMenu._current != null and is_instance_valid(ContextMenu._current):
			return ContextMenu._current
		for i in range(scene.get_child_count() - 1, -1, -1):
			var ch := scene.get_child(i)
			if ch is CanvasLayer and ch.has_meta("left_panel_dropdown"):
				return ch
		var slot_dd = scene.get("_active_slot_dropdown")
		if slot_dd != null and is_instance_valid(slot_dd as Node) and (slot_dd as Control).is_visible_in_tree():
			return slot_dd as Node
	if _effective_t() < 0.5:
		return null
	return $Layout

func _collect_focusables(n: Node, out: Array[Control]) -> void:
	if n == null or not is_instance_valid(n):
		return
	for ch in n.get_children():
		if ch is CanvasLayer:
			_collect_focusables(ch, out)
			continue
		if not (ch is Control):
			continue
		var c := ch as Control
		if not c.visible or not c.is_visible_in_tree():
			continue
		if c is ListItem:
			var li := c as ListItem
			if li.clickable or li.show_stepper:
				out.append(li)
			continue
		if c is LineEdit:
			out.append(c)
			continue
		if c is BaseButton:
			var vp := get_viewport_rect().size
			if c.size.x > vp.x * 0.6 and c.size.y > vp.y * 0.6:
				continue
			out.append(c)
			continue
		if c.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND \
				and not c.gui_input.get_connections().is_empty():
			out.append(c)
			continue
		_collect_focusables(c, out)

func _tick_nav(delta: float) -> void:
	if _nav_blocked():
		if _nav_active:
			_clear_nav_focus()
		return
	# Poll Left Analog Stick for UI navigation
	var lx := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var ly := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var new_dir := Vector2i.ZERO
	if absf(ly) >= STICK_DEADZONE or absf(lx) >= STICK_DEADZONE:
		if absf(ly) >= absf(lx):
			new_dir = Vector2i(0, 1 if ly > 0.0 else -1)
		else:
			new_dir = Vector2i(1 if lx > 0.0 else -1, 0)
	if new_dir != Vector2i.ZERO:
		if new_dir != _stick_dir:
			_stick_dir = new_dir
			_stick_timer = STICK_INITIAL_DELAY
			_handle_nav_dir(Vector2(_stick_dir.x, _stick_dir.y))
		else:
			_stick_timer -= delta
			if _stick_timer <= 0.0:
				_stick_timer = STICK_REPEAT_DELAY
				_handle_nav_dir(Vector2(_stick_dir.x, _stick_dir.y))
	else:
		_stick_dir = Vector2i.ZERO
		_stick_timer = 0.0

	if not _nav_active:
		return
	var root := _active_nav_root()
	if root == null:
		_clear_nav_focus()
		return
	var rid := root.get_instance_id()
	var focus_valid := _nav_focus != null and is_instance_valid(_nav_focus) \
		and _nav_focus.is_visible_in_tree() and root.is_ancestor_of(_nav_focus)
	if rid != _nav_last_root_id or not focus_valid:
		_nav_last_root_id = rid
		var items: Array[Control] = []
		_collect_focusables(root, items)
		var restored: Control = null
		if _saved_focus_by_root.has(rid):
			var w: WeakRef = _saved_focus_by_root[rid]
			var cand = w.get_ref() if w != null else null
			if cand != null and is_instance_valid(cand) and items.has(cand as Control):
				restored = cand as Control
		if restored != null:
			_set_nav_focus(restored, false)
		elif not items.is_empty():
			_set_nav_focus(items[0], false)
		else:
			_set_nav_focus(null, false)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _nav_active and (event as InputEventMouseMotion).relative.length_squared() > 4.0:
			_clear_nav_focus()
		return
	if _nav_blocked():
		return
	var gui_focus := get_viewport().gui_get_focus_owner()
	var typing := gui_focus is LineEdit or gui_focus is TextEdit
	if event is InputEventKey:
		var ke := event as InputEventKey
		if not ke.pressed:
			return
		var k := ke.keycode if ke.keycode != KEY_NONE else ke.physical_keycode
		var pk := ke.physical_keycode if ke.physical_keycode != KEY_NONE else ke.keycode
		if typing:
			if k == KEY_UP or k == KEY_DOWN:
				gui_focus.release_focus()
				_handle_nav_dir(Vector2(0, -1 if k == KEY_UP else 1))
				get_viewport().set_input_as_handled()
			elif k == KEY_ESCAPE:
				gui_focus.release_focus()
				_handle_nav_back()
				get_viewport().set_input_as_handled()
			return
		if not ke.echo and (k == KEY_TAB or pk == KEY_TAB):
			if _toggle_panel():
				get_viewport().set_input_as_handled()
			return
		var dir := Vector2.ZERO
		if k == KEY_UP or pk == KEY_W:
			dir = Vector2(0, -1)
		elif k == KEY_DOWN or pk == KEY_S:
			dir = Vector2(0, 1)
		elif k == KEY_LEFT or pk == KEY_A:
			dir = Vector2(-1, 0)
		elif k == KEY_RIGHT or pk == KEY_D:
			dir = Vector2(1, 0)
		if dir != Vector2.ZERO:
			if _handle_nav_dir(dir):
				get_viewport().set_input_as_handled()
			return
		if not ke.echo and (k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE):
			if _nav_active and _activate_focused():
				get_viewport().set_input_as_handled()
			return
		if not ke.echo and (k == KEY_BACKSPACE or k == KEY_ESCAPE):
			if _handle_nav_back():
				get_viewport().set_input_as_handled()
			return
		if not ke.echo and (k == KEY_C or pk == KEY_C):
			if _nav_active and _context_focused():
				get_viewport().set_input_as_handled()
			return
	elif event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if not jb.pressed:
			return
		if typing:
			if jb.button_index == JOY_BUTTON_DPAD_UP or jb.button_index == JOY_BUTTON_DPAD_DOWN:
				gui_focus.release_focus()
				_handle_nav_dir(Vector2(0, -1 if jb.button_index == JOY_BUTTON_DPAD_UP else 1))
				get_viewport().set_input_as_handled()
				return
			elif jb.button_index == JOY_BUTTON_A and gui_focus is LineEdit:
				(gui_focus as LineEdit).text_submitted.emit((gui_focus as LineEdit).text)
				get_viewport().set_input_as_handled()
				return
			elif jb.button_index == JOY_BUTTON_B:
				gui_focus.release_focus()
				_handle_nav_back()
				get_viewport().set_input_as_handled()
				return
		var jdir := Vector2.ZERO
		match jb.button_index:
			JOY_BUTTON_DPAD_UP:    jdir = Vector2(0, -1)
			JOY_BUTTON_DPAD_DOWN:  jdir = Vector2(0, 1)
			JOY_BUTTON_DPAD_LEFT:  jdir = Vector2(-1, 0)
			JOY_BUTTON_DPAD_RIGHT: jdir = Vector2(1, 0)
		if jdir != Vector2.ZERO:
			if _handle_nav_dir(jdir):
				get_viewport().set_input_as_handled()
			return
		match jb.button_index:
			JOY_BUTTON_A:
				if not _nav_active:
					_handle_nav_dir(Vector2(0, 1))
				elif _activate_focused():
					get_viewport().set_input_as_handled()
			JOY_BUTTON_B:
				if _handle_nav_back():
					get_viewport().set_input_as_handled()
			JOY_BUTTON_X:
				if _nav_active and _context_focused():
					get_viewport().set_input_as_handled()

var _self_slide_tw: Tween = null

func _toggle_panel() -> bool:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("_set_panel_open"):
		var now_open := not bool(scene.get("_panel_open"))
		AudioManager.play("click")
		if not now_open:
			_clear_nav_focus()
		scene.call("_set_panel_open", now_open)
		return true
	var now_open := slide_t < 0.5
	AudioManager.play("click")
	if not now_open:
		_clear_nav_focus()
	if _self_slide_tw != null and _self_slide_tw.is_valid():
		_self_slide_tw.kill()
	_self_slide_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_self_slide_tw.tween_method(set_slide, slide_t, 1.0 if now_open else 0.0, 0.9)
	return true

func _handle_nav_dir(dir: Vector2) -> bool:
	var scene := get_tree().current_scene
	if _effective_t() < 0.5 and scene != null and scene.has_method("_set_panel_open"):
		scene.call("_set_panel_open", true)
	var root := _active_nav_root()
	if root == null:
		return false
	var items: Array[Control] = []
	_collect_focusables(root, items)
	if items.is_empty():
		return false
	_nav_active = true
	_nav_last_root_id = root.get_instance_id()
	if _nav_focus == null or not is_instance_valid(_nav_focus) or not items.has(_nav_focus):
		var saved: Control = null
		if _saved_focus_by_root.has(_nav_last_root_id):
			var w: WeakRef = _saved_focus_by_root[_nav_last_root_id]
			var cand = w.get_ref() if w != null else null
			if cand != null and is_instance_valid(cand) and items.has(cand as Control):
				saved = cand as Control
		_set_nav_focus(saved if saved != null else items[0], true)
		return true

	# Stepper ListItem (e.g. filled building slot card): Left = Minus (−), Right = Plus (+)
	if absf(dir.x) > 0.5 and _nav_focus is ListItem and (_nav_focus as ListItem).show_stepper:
		var li := _nav_focus as ListItem
		var btn: BaseButton = li._plus_btn if dir.x > 0.0 else li._minus_btn
		if btn != null and btn.visible:
			if btn.disabled:
				AudioManager.play("denied")
			else:
				btn.pressed.emit()
			return true

	var cur_rect := _nav_focus.get_global_rect()
	var cur_c := cur_rect.get_center()
	var best: Control = null
	var best_score := INF

	if absf(dir.x) > 0.5:
		for c in items:
			if c == _nav_focus:
				continue
			var r := c.get_global_rect()
			var cc := r.get_center()
			var dx := (cc.x - cur_c.x) * dir.x
			var dy := absf(cc.y - cur_c.y)
			if dx <= 4.0 or dy > maxf(cur_rect.size.y, r.size.y) * 0.8:
				continue
			var score := dx + dy * 2.0
			if score < best_score:
				best_score = score
				best = c
	else:
		for c in items:
			if c == _nav_focus:
				continue
			var r := c.get_global_rect()
			var cc := r.get_center()
			var dy := (cc.y - cur_c.y) * dir.y
			if dy <= 4.0:
				continue
			var dx := absf(cc.x - cur_c.x)
			var score := dy + dx * 0.25
			if score < best_score:
				best_score = score
				best = c
		if best == null:
			var idx := items.find(_nav_focus)
			var next_idx := clampi(idx + (1 if dir.y > 0.0 else -1), 0, items.size() - 1)
			if next_idx != idx:
				best = items[next_idx]

	if best != null and best != _nav_focus:
		_set_nav_focus(best, true)
	return true

func _set_nav_focus(c: Control, play_sound: bool) -> void:
	if _nav_focus != null and is_instance_valid(_nav_focus) and _nav_focus != c:
		_apply_hover_visual(_nav_focus, false)
	_nav_focus = c
	if _nav_focus != null and is_instance_valid(_nav_focus):
		var root := _active_nav_root()
		if root != null:
			_saved_focus_by_root[root.get_instance_id()] = weakref(_nav_focus)
		_scroll_into_view(_nav_focus)
		TooltipManager.set_focus_anchor(_nav_focus)
		_apply_hover_visual(_nav_focus, true)
		if play_sound:
			AudioManager.play("hover")
	else:
		TooltipManager.set_focus_anchor(null)
		TooltipManager.hide_tip()

func _clear_nav_focus() -> void:
	if _nav_focus != null and is_instance_valid(_nav_focus):
		_apply_hover_visual(_nav_focus, false)
	_nav_focus = null
	_nav_active = false
	TooltipManager.set_focus_anchor(null)
	TooltipManager.hide_tip()

func _apply_hover_visual(c: Control, hovered: bool) -> void:
	if hovered:
		if c is Button:
			var hsb := c.get_theme_stylebox(&"hover")
			if hsb != null:
				c.add_theme_stylebox_override(&"disabled", hsb)
				c.set_meta("_nav_disabled_hover", true)
		c.notification(Control.NOTIFICATION_MOUSE_ENTER)
		c.mouse_entered.emit()
	else:
		if c is Button and c.has_meta("_nav_disabled_hover"):
			c.remove_theme_stylebox_override(&"disabled")
			c.remove_meta("_nav_disabled_hover")
		c.notification(Control.NOTIFICATION_MOUSE_EXIT)
		c.mouse_exited.emit()

func _scroll_into_view(c: Control) -> void:
	var p := c.get_parent()
	while p != null and p != self:
		if p is ScrollContainer:
			(p as ScrollContainer).ensure_control_visible(c)
			break
		p = p.get_parent()

func _activate_focused() -> bool:
	if _nav_focus == null or not is_instance_valid(_nav_focus) or not _nav_focus.is_visible_in_tree():
		return false
	var c := _nav_focus
	if c is ListItem:
		var li := c as ListItem
		if li.show_stepper and li._plus_btn != null and li._plus_btn.visible:
			if li._plus_btn.disabled:
				AudioManager.play("denied")
			else:
				li._plus_btn.pressed.emit()
			return true
		if li.clickable:
			li.clicked.emit()
			return true
		return false
	if c is LineEdit:
		(c as LineEdit).grab_focus()
		return true
	if c is BaseButton:
		var btn := c as BaseButton
		if btn.disabled:
			AudioManager.play("denied")
			return true
		if btn.toggle_mode:
			btn.button_pressed = not btn.button_pressed
		btn.pressed.emit()
		return true
	_emit_synthetic_click(c, MOUSE_BUTTON_LEFT)
	return true

func _context_focused() -> bool:
	var scene := get_tree().current_scene
	if _nav_focus != null and is_instance_valid(_nav_focus) and _nav_focus.is_visible_in_tree():
		if _nav_focus.has_meta("poi_label") and scene != null and scene.has_method("open_poi_context_menu"):
			if bool(scene.call("open_poi_context_menu", String(_nav_focus.get_meta("poi_label")),
					_nav_focus.get_global_rect().get_center())):
				return true
		if _nav_focus is ListItem and (_nav_focus as ListItem).show_stepper \
				and not _nav_focus.gui_input.get_connections().is_empty():
			_emit_synthetic_click(_nav_focus, MOUSE_BUTTON_RIGHT)
			return true
	if scene != null and scene.has_method("open_poi_context_menu"):
		var anchor := _nav_focus.get_global_rect().get_center() \
			if (_nav_focus != null and is_instance_valid(_nav_focus)) else get_global_rect().get_center()
		if bool(scene.call("open_poi_context_menu", "", anchor)):
			return true
	return false

func _emit_synthetic_click(c: Control, button_index: MouseButton) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button_index
	ev.pressed = true
	ev.position = c.size * 0.5
	ev.global_position = c.get_global_rect().get_center()
	c.gui_input.emit(ev)

func _handle_nav_back() -> bool:
	var root_vp := get_tree().root
	if root_vp != null:
		for i in range(root_vp.get_child_count() - 1, -1, -1):
			var rch := root_vp.get_child(i)
			if rch is CanvasLayer and rch.has_meta("left_panel_dropdown"):
				AudioManager.play("click")
				rch.queue_free()
				return true
	var scene := get_tree().current_scene
	if scene != null:
		for i in range(scene.get_child_count() - 1, -1, -1):
			var ch := scene.get_child(i)
			if ch is ModalPopup:
				if (ch as ModalPopup).dismissable:
					AudioManager.play("click")
					(ch as ModalPopup).close()
				return true
		if GameOverlays._trait_layer != null and is_instance_valid(GameOverlays._trait_layer):
			AudioManager.play("click")
			GameOverlays.close(GameOverlays._trait_layer)
			return true
		if ContextMenu._current != null and is_instance_valid(ContextMenu._current):
			AudioManager.play("click")
			ContextMenu.close_current()
			return true
		for i in range(scene.get_child_count() - 1, -1, -1):
			var ch := scene.get_child(i)
			if ch is CanvasLayer and ch.has_meta("left_panel_dropdown"):
				AudioManager.play("click")
				ch.queue_free()
				return true
		var slot_dd = scene.get("_active_slot_dropdown")
		if slot_dd != null and is_instance_valid(slot_dd as Node):
			AudioManager.play("click")
			(slot_dd as Node).queue_free()
			scene.set("_active_slot_dropdown", null)
			return true
	if overlay() != null:
		var ov := overlay()
		if ov.has_method("close"):
			ov.call("close")
		else:
			close_overlay()
		return true
	var back_btn := _find_back_button(content)
	if back_btn != null:
		back_btn.pressed.emit()
		return true
	if _nav_active:
		_clear_nav_focus()
		return true
	return false

func _find_back_button(n: Node) -> BaseButton:
	if n == null or not is_instance_valid(n):
		return null
	for ch in n.get_children():
		if not (ch is Control) or not (ch as Control).is_visible_in_tree():
			continue
		if ch is Button and (ch as Button).text.begins_with("‹  "):
			return ch as BaseButton
		var found := _find_back_button(ch)
		if found != null:
			return found
	return null
