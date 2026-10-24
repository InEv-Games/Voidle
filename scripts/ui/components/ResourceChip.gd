## Top-bar resource box (design: Resource Panels.png):
##   [icon] 50.000 ⁺¹·⁵
## States: normal, hover (accent edge), inactive (dim value and icon — nothing
## stored and nothing coming in). `alert` paints the value in the palette's
## "bad" colour (stock at its cap, energy deficit, overcrowding).
## Layout: scenes/ui/components/ResourceChip.tscn. Look: theme type ResourceChip
## (panel / panel_hover / panel_inactive), ValueLabel / ValueLabelInactive, StatLabel.
@tool
class_name ResourceChip
extends PanelContainer

const SCENE_PATH := "res://scenes/ui/components/ResourceChip.tscn"
enum Tone { PLAIN, GOOD, BAD }

## Resource id (credits, science, energy, population, raw, goods …) or a UIIcons name.
@export var resource_id: String = "credits":
	set(v): resource_id = v; _sync()
## Tint for the icon; transparent = the resource's own colour.
@export var icon_color: Color = Color(0, 0, 0, 0):
	set(v): icon_color = v; _sync()
@export var value_text: String = "50.000":
	set(v): value_text = v; _sync()
## Small "+1.5" next to the value; hidden when empty.
@export var rate_text: String = "":
	set(v): rate_text = v; _sync()
@export var rate_tone: Tone = Tone.GOOD:
	set(v): rate_tone = v; _sync()
@export var inactive: bool = false:
	set(v): inactive = v; _apply_state()
@export var alert: bool = false:
	set(v): alert = v; _apply_state()
## Fixed value width so the bar never jumps; 0 = fit the text.
@export var value_width: float = 0.0:
	set(v): value_width = v; _sync()
## Editor preview of the hover look.
@export var preview_hover: bool = false:
	set(v): preview_hover = v; _apply_state()

## Usable right after create(), before the chip enters the tree.
var value_label: Label:
	get: return $Row/Value
var rate_label: Label:
	get: return $Row/Rate

var _hovered := false
var _applying := false   # our own overrides raise THEME_CHANGED again

static func create(id: String) -> ResourceChip:
	var c := (load(SCENE_PATH) as PackedScene).instantiate() as ResourceChip
	c.resource_id = id
	return c

func _ready() -> void:
	_sync()
	if Engine.is_editor_hint():
		return
	mouse_entered.connect(func() -> void: _hovered = true; _apply_state())
	mouse_exited.connect(func() -> void: _hovered = false; _apply_state())

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_apply_state()

func _sync() -> void:
	if not is_node_ready():
		return
	var ic := $Row/Icon as TextureRect
	ic.texture = UIIcons.get_icon(resource_id)
	value_label.text = value_text
	value_label.custom_minimum_size.x = value_width
	value_label.clip_text = value_width > 0.0
	rate_label.text = rate_text
	rate_label.visible = rate_text != ""
	_apply_state()

func _apply_state() -> void:
	if not is_node_ready() or _applying:
		return
	_applying = true
	var ic := $Row/Icon as TextureRect
	var base := icon_color if icon_color.a > 0.0 else _resource_color()
	ic.self_modulate = Color(base, 0.4 if inactive else 1.0)
	value_label.theme_type_variation = &"ValueLabelInactive" if inactive else &"ValueLabel"
	if alert and not inactive:
		value_label.add_theme_color_override("font_color", get_theme_color(&"bad", &"Palette"))
	else:
		value_label.remove_theme_color_override("font_color")
	rate_label.add_theme_color_override("font_color",
		get_theme_color(&"good" if rate_tone == Tone.GOOD else (&"bad" if rate_tone == Tone.BAD else &"text_subtle"), &"Palette"))
	if inactive:
		add_theme_stylebox_override("panel", get_theme_stylebox(&"panel_inactive", &"ResourceChip"))
	elif _hovered or preview_hover:
		add_theme_stylebox_override("panel", get_theme_stylebox(&"panel_hover", &"ResourceChip"))
	else:
		remove_theme_stylebox_override("panel")
	_applying = false

func _resource_color() -> Color:
	if Economy.INFO.has(resource_id):
		return Economy.color_of(resource_id)
	return get_theme_color(&"icon", &"Palette")
