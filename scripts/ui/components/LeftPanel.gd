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
## slides out, its content is swapped for the overlay, and it slides back in;
## close_overlay() does the same the other way. The view's own content is only
## hidden meanwhile (and anything the view rebuilds stays hidden), so going
## back shows it as it was. The view's hide button hides the overlay with the
## panel and brings it back on unhide; opening an overlay on a closed panel asks
## the view to open it (or, in a view that can't, shows it anyway).
const SWAP_SEC := 0.16
var _overlay: Control = null
var _hidden: Array = []          # the view's content hidden behind the overlay
var _swap_k := 1.0               # 1 = in place, 0 = out (during a swap)
var _swap_tw: Tween = null
var _force_open := false   # a view with no open/close of its own: keep the overlay visible

func overlay() -> Control:
	return _overlay if _overlay != null and is_instance_valid(_overlay) else null

## Shows `c` in place of the panel's content (slide out, swap, slide in).
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
		content.add_child(c))

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
		_hidden.clear())

func _swap(change: Callable) -> void:
	if _swap_tw != null and _swap_tw.is_valid():
		_swap_tw.kill()
	_swap_tw = create_tween()
	_swap_tw.tween_method(_set_swap, _swap_k, 0.0, SWAP_SEC * _swap_k).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_swap_tw.tween_callback(change)
	_swap_tw.tween_method(_set_swap, 0.0, 1.0, SWAP_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _set_swap(k: float) -> void:
	_swap_k = k
	_place()

## Whatever the view adds while an overlay is up stays behind it.
func _on_content_child(n: Node) -> void:
	if overlay() != null and n != _overlay and n is CanvasItem:
		(n as CanvasItem).visible = false
		_hidden.append(weakref(n))

func _ready() -> void:
	add_to_group(GROUP)
	content.child_entered_tree.connect(_on_content_child)
	var hud := get_node_or_null("/root/HUDManager")
	if hud != null:
		hud.fill_shortcuts(_shortcuts)
	_place()

func _process(_delta: float) -> void:
	if absf(offset_top - _hud_bar_height()) > 0.5:
		_place()

## Slides the panel between hidden (0) and open (1).
func set_slide(t: float) -> void:
	slide_t = t
	_place()

## The panel's right edge as a fraction of the screen width, for a slide t.
static func edge_frac(t: float = 1.0) -> float:
	return (GAP + WIDTH) * t

func _place() -> void:
	var t := (1.0 if _force_open and overlay() != null else slide_t) * _swap_k
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
