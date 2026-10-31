## Design-system list row (city / district / building / orbit / issue):
##   [icon] │ TITLE ......... [⟳ cycle] [badge]
##          │ ─────
##          │ stats or description      [-][+]
## Cycle / construction progress fills the card's background (ProgressFill).
## Layout: scenes/ui/components/ListItem.tscn. Look: theme type ItemPanel
## (panel / panel_hover / panel_selected), IconCell, Badge.
@tool
class_name ListItem
extends PanelContainer

const SCENE_PATH := "res://scenes/ui/components/ListItem.tscn"

signal pressed
## -1 or +1 from the small stepper buttons.
signal stepped(delta: int)

@export var title: String = "CITY NAME":
	set(v): title = v; _sync()
@export var badge: String = "":
	set(v): badge = v; _sync()
## Icon amounts in the badge instead of its text, "icon:text" each (a cost:
## ["credits:101", "worker:125"]); an empty icon shows the text alone.
@export var badge_items: PackedStringArray = []:
	set(v): badge_items = v; _sync()
## Shown under the title when there are no stats.
@export var description: String = "":
	set(v): description = v; _sync()
@export var icon_name: String = "city":
	set(v): icon_name = v; _sync()
@export var icon_color: Color = Color(0.898, 0.831, 0.675):
	set(v): icon_color = v; _sync()
## Cycle length beside the badge ("20s"; empty hides it): stats are per cycle,
## so they read "+30" and the cycle stands once here (playtest 31.10).
@export var cycle: String = "":
	set(v): cycle = v; _sync()
## "icon_name:text" per entry, e.g. "district:3", "population:12", "credits:+30".
## Resource icons take their resource colour.
@export var stats: PackedStringArray = []:
	set(v): stats = v; _sync()
@export var show_stepper: bool = false:
	set(v): show_stepper = v; _sync()
@export var selected: bool = false:
	set(v): selected = v; _apply_box()
@export var clickable: bool = true
## Cycle / construction progress 0..1; below 0 hides the fill.
@export_range(-1.0, 1.0) var progress: float = -1.0:
	set(v): progress = v; _sync()
@export var progress_color: Color = Color(0.137, 0.725, 0.906):
	set(v): progress_color = v; _sync()
## Construction look: crawling stripes over the fill.
@export var progress_striped: bool = false:
	set(v): progress_striped = v; _sync()

@onready var _icon: TextureRect = $Row/IconCell/Icon
@onready var _title: Label = $Row/Body/Top/Title
@onready var _badge: Control = $Row/Body/Top/Badge
@onready var _badge_lbl: Label = $Row/Body/Top/Badge/Label
@onready var _stats: HBoxContainer = $Row/Body/Bottom/Stats
@onready var _desc: Label = $Row/Body/Bottom/Description
@onready var _stepper: Control = $Row/Body/Bottom/Stepper
var _fill: ProgressFill = null
var _cycle_box: HBoxContainer = null
var _badge_box: HBoxContainer = null
var _cycle_lbl: Label = null
var _hovered := false

static func create(t: String, icon_id: String, badge_text := "", stat_list: PackedStringArray = [], desc := "") -> ListItem:
	var it := (load(SCENE_PATH) as PackedScene).instantiate() as ListItem
	it.title = t
	it.icon_name = icon_id
	it.badge = badge_text
	it.stats = stat_list
	it.description = desc
	return it

func _ready() -> void:
	_fill = ProgressFill.attach(self, progress_color)
	_build_cycle_box()
	if not Engine.is_editor_hint():
		# long titles and stat rows glide inside the row instead of widening
		# the left panel or running under the badge (playtest 30.10)
		_title.clip_text = false   # the marquee clips it now
		MarqueeLabel.wrap(_title)
		MarqueeLabel.wrap(_stats)   # (the description wraps onto more lines instead)
	_sync()
	if Engine.is_editor_hint():
		return
	mouse_entered.connect(func() -> void: _hovered = true; _apply_box())
	mouse_exited.connect(func() -> void: _hovered = false; _apply_box())
	gui_input.connect(_on_gui_input)
	($Row/Body/Bottom/Stepper/Minus as Button).pressed.connect(func() -> void: stepped.emit(-1))
	($Row/Body/Bottom/Stepper/Plus as Button).pressed.connect(func() -> void: stepped.emit(1))

func _on_gui_input(e: InputEvent) -> void:
	if clickable and e is InputEventMouseButton and e.pressed \
			and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()

func _sync() -> void:
	if not is_node_ready():
		return
	_title.text = title
	_badge_lbl.text = badge
	_badge.visible = badge != "" or not badge_items.is_empty()
	_sync_badge_items()
	if _cycle_box != null:
		_cycle_lbl.text = cycle
		_cycle_box.visible = cycle != ""
	_icon.texture = UIIcons.get_icon(icon_name)
	_icon.self_modulate = icon_color
	for c in _stats.get_children():
		_stats.remove_child(c)
		c.queue_free()
	for s: String in stats:
		var parts := s.split(":", true, 1)
		_stats.add_child(_make_stat(parts[0] if parts.size() > 1 else "", parts[-1]))
	_stats.visible = not stats.is_empty()
	_desc.text = description
	_desc.visible = stats.is_empty() and description != ""
	if _stats.get_parent() is MarqueeLabel:
		(_stats.get_parent() as Control).visible = _stats.visible

	_stepper.visible = show_stepper
	_fill.progress = progress
	_fill.color = progress_color
	_fill.striped = progress_striped
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW
	_apply_box()

func _sync_badge_items() -> void:
	if _badge_box != null:
		_badge.remove_child(_badge_box)
		_badge_box.queue_free()
		_badge_box = null
	_badge_lbl.visible = badge_items.is_empty()
	if badge_items.is_empty():
		return
	_badge_box = HBoxContainer.new()
	_badge_box.add_theme_constant_override("separation", 6)
	_badge_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s: String in badge_items:
		var parts := s.split(":", true, 1)
		var chip := _make_stat(parts[0] if parts.size() > 1 else "", parts[-1])
		(chip.get_child(chip.get_child_count() - 1) as Label).theme_type_variation = &"BadgeLabel"
		_badge_box.add_child(chip)
	_badge.add_child(_badge_box)

func _build_cycle_box() -> void:
	_cycle_box = HBoxContainer.new()
	_cycle_box.add_theme_constant_override("separation", 2)
	_cycle_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cycle_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic := TextureRect.new()
	ic.texture = UIIcons.get_icon("cycle")
	ic.custom_minimum_size = Vector2(9, 9)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ic.self_modulate = Color(0.62, 0.70, 0.82)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cycle_box.add_child(ic)
	_cycle_lbl = Label.new()
	_cycle_lbl.theme_type_variation = &"StatLabel"
	_cycle_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cycle_box.add_child(_cycle_lbl)
	var top := _badge.get_parent()
	top.add_child(_cycle_box)
	top.move_child(_cycle_box, _badge.get_index())

func _make_stat(icon_id: String, txt: String) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon_id != "":
		var ic := TextureRect.new()
		ic.texture = UIIcons.get_icon(icon_id)
		ic.custom_minimum_size = Vector2(9, 9)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		ic.self_modulate = Economy.color_of(icon_id) if Economy.INFO.has(icon_id) \
			else (Color(0.85, 0.88, 1.0) if icon_id == "worker" else (Color.WHITE if Economy.is_raw(icon_id) else icon_color))
		if Economy.is_raw(icon_id):
			ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # pixel mineral icon
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(ic)
	var l := Label.new()
	l.text = txt
	l.theme_type_variation = &"StatLabel"
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(l)
	return box

func _apply_box() -> void:
	if not is_node_ready():
		return
	if selected:
		add_theme_stylebox_override("panel", get_theme_stylebox(&"panel_selected", &"ItemPanel"))
	elif _hovered and clickable:
		add_theme_stylebox_override("panel", get_theme_stylebox(&"panel_hover", &"ItemPanel"))
	else:
		remove_theme_stylebox_override("panel")
