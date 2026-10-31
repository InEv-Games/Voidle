## Design-system button. Four types (Default blue, Positive green, Neutral
## yellow, Negative red) in two layouts:
##   ICON_LEFT    icon │ LABEL ............ counter   (no label: icon only)
##   TEXT_CENTER        LABEL  counter
## Layout lives in scenes/ui/components/IconButton.tscn, colours in the theme
## (ButtonDefault / ButtonPositive / ButtonNeutral / ButtonNegative).
@tool
class_name IconButton
extends Button

const SCENE_PATH := "res://scenes/ui/components/IconButton.tscn"

enum Variant { DEFAULT, POSITIVE, NEUTRAL, NEGATIVE }
const VARIATIONS := [&"ButtonDefault", &"ButtonPositive", &"ButtonNeutral", &"ButtonNegative"]
enum Layout { ICON_LEFT, TEXT_CENTER }

@export var label_text: String = "BUTTON":
	set(v): label_text = v; _sync()
## Name from UIIcons.MAP or an SVG file name in resources/ui/icons/.
@export var icon_name: String = "unknown":
	set(v): icon_name = v; _sync()
@export var variant: Variant = Variant.DEFAULT:
	set(v): variant = v; _sync()
@export var layout: Layout = Layout.ICON_LEFT:
	set(v): layout = v; _sync()
## Right-aligned counter, e.g. "5/9". Hidden when empty.
@export var counter: String = "":
	set(v): counter = v; _sync()
## Smallest size; the button grows to fit its text. Icon-only buttons stay square.
## (custom_minimum_size is computed from this — edit this one, not that.)
## Icon amounts in place of the plain counter, "icon:text" each, e.g.
## ["credits:9.4K", "worker:12K"]: each amount by its resource icon (playtest 31.10).
@export var counter_items: PackedStringArray = []:
	set(v): counter_items = v; _sync()
var _counter_box: HBoxContainer = null
@export var min_size: Vector2 = Vector2(0, 26):
	set(v): min_size = v; _sync()
## Label / counter font size; 0 = the theme's TitleLabel / CounterLabel size.
@export var font_size: int = 0:
	set(v): font_size = v; _sync()

@onready var _row: HBoxContainer = $Row
@onready var _icon: TextureRect = $Row/Icon
@onready var _sep: Control = $Row/Sep
@onready var _label: Label = $Row/Label
@onready var _counter: Label = $Row/Counter

static func create(txt: String, icon_id: String, v: Variant = Variant.DEFAULT, count := "") -> IconButton:
	var b := (load(SCENE_PATH) as PackedScene).instantiate() as IconButton
	b.label_text = txt
	b.icon_name = icon_id
	b.variant = v
	b.counter = count
	return b

## The text-centred layout (no icon cell).
static func create_text(txt: String, v: Variant = Variant.DEFAULT, count := "") -> IconButton:
	var b := create(txt, "", v, count)
	b.layout = Layout.TEXT_CENTER
	return b

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	_sync()

func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		_layout_row()
		_apply_text_color()
		_update_size.call_deferred()   # child labels pick up the theme first
	elif what == NOTIFICATION_RESIZED:
		_layout_row()
	elif what == NOTIFICATION_DRAW and is_node_ready():
		_row.modulate.a = 0.45 if disabled else 1.0   # the row is not drawn by Button itself

func _sync() -> void:
	if not is_node_ready():
		return
	theme_type_variation = VARIATIONS[variant]
	var centred := layout == Layout.TEXT_CENTER
	_label.text = label_text
	_label.visible = label_text != ""
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centred else HORIZONTAL_ALIGNMENT_LEFT
	_icon.texture = UIIcons.get_icon(icon_name) if icon_name != "" else null
	_icon.visible = not centred and icon_name != ""
	_sep.visible = _icon.visible and _label.visible   # icon-only: no divider
	_counter.text = counter
	_counter.visible = counter != "" and counter_items.is_empty()
	_sync_counter_items()
	for l: Label in [_label, _counter]:
		if font_size > 0:
			l.add_theme_font_size_override("font_size", font_size)
		else:
			l.remove_theme_font_size_override("font_size")
	_row.alignment = BoxContainer.ALIGNMENT_CENTER if _icon_only() else BoxContainer.ALIGNMENT_BEGIN
	_layout_row()
	_apply_text_color()
	_update_size()

## Label and counter use the button type's own font colour (theme: font_color of
## ButtonDefault / ButtonPositive / …), so each type sets its text colour in one place.
func _apply_text_color() -> void:
	if not is_node_ready():
		return
	var col := get_theme_color(&"font_color")
	_label.add_theme_color_override("font_color", col)
	_counter.add_theme_color_override("font_color", col)
	if _counter_box != null:
		for chip in _counter_box.get_children():
			(chip.get_child(1) as Label).add_theme_color_override("font_color", col)

## Just an icon: no label and no counter.
func _icon_only() -> bool:
	return layout == Layout.ICON_LEFT and label_text == "" and counter == "" and counter_items.is_empty() and icon_name != ""

func _sync_counter_items() -> void:
	if _counter_box != null:
		_row.remove_child(_counter_box)
		_counter_box.queue_free()
		_counter_box = null
	if counter_items.is_empty():
		return
	_counter_box = HBoxContainer.new()
	_counter_box.add_theme_constant_override("separation", 8)
	_counter_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for s: String in counter_items:
		var parts := s.split(":", true, 1)
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 3)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := TextureRect.new()
		var id := parts[0] if parts.size() > 1 else ""
		ic.texture = UIIcons.get_icon(id) if id != "" else null
		ic.custom_minimum_size = Vector2(12, 12)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var res := Economy.POPULATION if id == "worker" else id
		ic.self_modulate = Economy.color_of(res) if Economy.INFO.has(res) else Color.WHITE
		if Economy.is_raw(id):
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixel mineral icon
		chip.add_child(ic)
		var l := Label.new()
		l.text = parts[-1]
		l.theme_type_variation = &"CounterLabel"
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if font_size > 0:
			l.add_theme_font_size_override("font_size", font_size)
		chip.add_child(l)
		_counter_box.add_child(chip)
	_row.add_child(_counter_box)

## The row sits inside the current stylebox's content margins.
func _layout_row() -> void:
	if not is_node_ready():
		return
	var sb := get_theme_stylebox("normal")
	# icon-only: the vertical margin on every side keeps the icon centred in a square
	var side := sb.content_margin_top if _icon_only() else sb.content_margin_left
	_row.offset_left = side
	_row.offset_right = -(sb.content_margin_top if _icon_only() else sb.content_margin_right)
	_row.offset_top = sb.content_margin_top
	_row.offset_bottom = -sb.content_margin_bottom

## Button sizes itself from its own `text` only, so the row's size is applied
## through custom_minimum_size (never smaller than min_size).
func _update_size() -> void:
	if not is_node_ready():
		return
	var sb := get_theme_stylebox("normal")
	var need := _row.get_combined_minimum_size() + sb.get_minimum_size()
	if _icon_only():
		var edge := maxf(maxf(need.y, min_size.y), maxf(min_size.x, _icon.custom_minimum_size.y + sb.content_margin_top * 2.0))
		need = Vector2(edge, edge)
	custom_minimum_size = need.max(min_size)
