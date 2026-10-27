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

## 1 = open, 0 = slid fully off the left edge.
var slide_t := 1.0

func _ready() -> void:
	add_to_group(GROUP)
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
	anchor_left = lerpf(-WIDTH, GAP, slide_t)
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
