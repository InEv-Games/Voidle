## The one left panel every view uses (design: Side Panel):
##   PanelContent       the view's own lists — each view fills this (scene nodes or code)
##   ─────────────────
##   Shortcuts          Upgrade Tree · Trade · Explore, built by HUDManager
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
	item_rect_changed.connect(queue_redraw)   # the backdrop follows the slide
	content.child_entered_tree.connect(_on_content_child)
	var hud := get_node_or_null("/root/HUDManager")
	if hud != null:
		hud.fill_shortcuts(_shortcuts)
	_place()
	reveal()   # the view's first menu

## Plays the cyberpunk entrance (CyberReveal) over the content once this
## frame's building is done. Views call it when they switch to a new menu;
## several calls in one frame play it once.
var _reveal_queued := false

func reveal() -> void:
	if _reveal_queued:
		return
	_reveal_queued = true
	_play_reveal.call_deferred()

func _play_reveal() -> void:
	_reveal_queued = false
	if is_inside_tree() and visible:
		CyberReveal.play(content)

func _process(_delta: float) -> void:
	if absf(offset_top - _hud_bar_height()) > 0.5:
		_place()

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
	var t := 1.0 if _force_open and overlay() != null else slide_t
	if t <= 0.0:
		return
	var sb := get_theme_stylebox(&"panel")
	var col := Color(0.035, 0.094, 0.169)
	if sb is StyleBoxFlat:
		col = (sb as StyleBoxFlat).bg_color
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
	if sb != null:
		draw_style_box(sb, Rect2(Vector2.ZERO, size))   # keep the border on top

## The panel's right edge as a fraction of the screen width, for a slide t.
static func edge_frac(t: float = 1.0) -> float:
	return (GAP + WIDTH) * t

func _place() -> void:
	var t := 1.0 if _force_open and overlay() != null else slide_t
	anchor_left = lerpf(-WIDTH, GAP, t)
	anchor_right = anchor_left + WIDTH
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_right = 0.0
	#offset_top = _hud_bar_height()
	offset_top = 0.0
	offset_bottom = 0.0

## Height of the HUD's resource bar — the panel starts below it.
func _hud_bar_height() -> float:
	var hud := get_node_or_null("/root/HUDManager")
	var cp = hud.get("credits_panel") if hud != null else null
	if cp != null and is_instance_valid(cp as Node) and (cp as Control).size.y > 4.0:
		return (cp as Control).size.y + 6.0
	return 58.0
