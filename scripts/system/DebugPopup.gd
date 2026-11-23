## A small draggable debug window (Developer Console: `debug-popup --open` /
## `--close`), for trying a view's animations by hand.
##
## It lists the buttons the current scene offers: a scene that wants some
## defines `debug_actions() -> Array` of { "name": String, "call": Callable }.
## The list is rebuilt when the scene changes (and with ⟳). It lives on the
## root, over every view, and stays where it was dragged.
class_name DebugPopup
extends CanvasLayer

static var _instance: DebugPopup = null

var _panel: PanelContainer
var _list: VBoxContainer
var _title: Label
var _drag := false
var _drag_off := Vector2.ZERO
var _scene_id := 0


static func open(tree: SceneTree) -> void:
	if _instance != null and is_instance_valid(_instance):
		_instance._rebuild()
		return
	_instance = DebugPopup.new()
	tree.root.add_child(_instance)


static func close() -> void:
	if _instance != null and is_instance_valid(_instance):
		_instance.queue_free()
	_instance = null


static func is_open() -> bool:
	return _instance != null and is_instance_valid(_instance)


func _ready() -> void:
	layer = 120
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"ItemPanel"
	_panel.position = Vector2(get_viewport().get_visible_rect().size.x - 300.0, 120.0)
	_panel.custom_minimum_size = Vector2(260, 0)
	add_child(_panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_panel.add_child(col)
	# title bar: drag it; ⟳ refreshes, × closes
	var bar := HBoxContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.mouse_default_cursor_shape = Control.CURSOR_MOVE
	bar.gui_input.connect(_on_bar_input)
	col.add_child(bar)
	_title = Label.new()
	_title.text = "DEBUG"
	_title.theme_type_variation = &"TitleLabel"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(_title)
	var refresh := Button.new()
	refresh.text = "⟳"
	refresh.flat = true
	refresh.focus_mode = Control.FOCUS_NONE
	refresh.pressed.connect(_rebuild)
	bar.add_child(refresh)
	var x := Button.new()
	x.text = "×"
	x.flat = true
	x.focus_mode = Control.FOCUS_NONE
	x.pressed.connect(func() -> void: DebugPopup.close())
	bar.add_child(x)
	col.add_child(HSeparator.new())
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	col.add_child(_list)
	_rebuild()


var _sig := ""
var _poll := 0.0

func _process(delta: float) -> void:
	# a new scene, or the scene's buttons changed (e.g. something else picked):
	# rebuild the list
	var sc := get_tree().current_scene
	var id := sc.get_instance_id() if sc != null else 0
	if id != _scene_id:
		_rebuild()
		return
	_poll += delta
	if _poll < 0.3:
		return
	_poll = 0.0
	if _signature(sc) != _sig:
		_rebuild()


func _signature(sc: Node) -> String:
	if sc == null or not sc.has_method("debug_actions"):
		return ""
	var names: PackedStringArray = []
	for a: Dictionary in sc.call("debug_actions"):
		names.append(String(a.get("name", "")))
	return "|".join(names)


func _rebuild() -> void:
	for c in _list.get_children():
		c.queue_free()
	var sc := get_tree().current_scene
	_scene_id = sc.get_instance_id() if sc != null else 0
	_title.text = "DEBUG  //  %s" % (String(sc.name) if sc != null else "-")
	var actions: Array = []
	if sc != null and sc.has_method("debug_actions"):
		actions = sc.call("debug_actions")
	_sig = _signature(sc)
	if actions.is_empty():
		var none := Label.new()
		none.text = "This view has no debug actions."
		none.theme_type_variation = &"SubLabel"
		_list.add_child(none)
		return
	for a: Dictionary in actions:
		var b := Button.new()
		b.text = String(a.get("name", "?"))
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var cb: Callable = a.get("call", Callable())
		b.pressed.connect(func() -> void:
			if cb.is_valid():
				cb.call())
		_list.add_child(b)


func _on_bar_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_drag = (e as InputEventMouseButton).pressed
		_drag_off = _panel.position - (e as InputEventMouseButton).global_position
	elif e is InputEventMouseMotion and _drag:
		var vp := get_viewport().get_visible_rect().size
		var p := (e as InputEventMouseMotion).global_position + _drag_off
		_panel.position = Vector2(clampf(p.x, 0.0, vp.x - 60.0), clampf(p.y, 0.0, vp.y - 30.0))
