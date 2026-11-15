## A big moment, said big (playtest 12.11 K43/K44/K46): a banner drops in at
## the top-centre of the screen with a ring burst behind it, its caption, a
## title (the panel hero's look, decoding in like a fresh panel), a few icon
## rows and an optional button; it leaves on its own after `sec` or on a click.
## More than one at a time queue up and play one after another.
##   MilestoneBanner.show_banner(tree, "Terra // Planet", "LEVEL 3",
##       ["[icon] Room for one more City"], {"action": "OPEN", "on_action": cb})
class_name MilestoneBanner
extends Control

const LAYER := 232            # over the HUD (230) and the news bar, under tooltips (300)
const SEC := 6.0
const TOP := 118.0
const RING_COL := Color(1.0, 0.85, 0.5)

static var _queue: Array[Dictionary] = []
static var _current: MilestoneBanner = null

var _data: Dictionary = {}
var _t := 0.0
var _card: PanelContainer
var _leaving := false

## Queues a banner. `rows`: BBCode lines (icons via UIIcons.bb). Options:
## sec (seconds on screen), action (button text), action_icon, on_action
## (Callable), color (the ring and title accent), sound (AudioManager key or VAM id).
static func show_banner(tree: SceneTree, caption: String, title: String, rows: Array = [], opts := {}) -> void:
	if tree == null:
		return
	_queue.append({"tree": tree, "caption": caption, "title": title, "rows": rows, "opts": opts})
	if _current == null or not is_instance_valid(_current):
		_next()

static func busy() -> bool:
	return _current != null and is_instance_valid(_current)

static func _next() -> void:
	_current = null
	while not _queue.is_empty():
		var d: Dictionary = _queue.pop_front()
		var tree: SceneTree = d["tree"]
		if tree == null or tree.root == null:
			continue
		var layer := CanvasLayer.new()
		layer.layer = LAYER
		tree.root.add_child(layer)
		var b := MilestoneBanner.new()
		b._data = d
		layer.add_child(b)
		_current = b
		return

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var opts: Dictionary = _data.get("opts", {})
	var accent: Color = opts.get("color", RING_COL)
	_card = PanelContainer.new()
	_card.theme_type_variation = &"PopupCard"
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.custom_minimum_size = Vector2(380, 0)
	add_child(_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(box)
	var hero := HeroHeader.create(String(_data.get("caption", "")), String(_data.get("title", "")))
	box.add_child(hero)
	for line in _data.get("rows", []):
		var r := RichTextLabel.new()
		r.bbcode_enabled = true
		r.fit_content = true
		r.scroll_active = false
		r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		r.custom_minimum_size = Vector2(340, 0)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.text = String(line)
		box.add_child(r)
	var act := String(opts.get("action", ""))
	if act != "":
		var btn := IconButton.create(act, String(opts.get("action_icon", "")), IconButton.Variant.POSITIVE)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var cb: Callable = opts.get("on_action", Callable())
		btn.pressed.connect(func() -> void:
			AudioManager.play("click")
			if cb.is_valid():
				cb.call()
			_leave())
		box.add_child(btn)
	_card.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_leave())
	_card.modulate = Color(accent.lightened(0.4), 0.0)
	AudioManager.play(String(opts.get("sound", "sfx/processDone")))
	await get_tree().process_frame
	if not is_instance_valid(_card):
		return
	_place(-40.0)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_method(_place, -40.0, 0.0, 0.45)
	tw.tween_property(_card, "modulate", Color.WHITE, 0.35)
	CyberReveal.play(box)

func _place(dy: float) -> void:
	if is_instance_valid(_card):
		_card.reset_size()
		_card.position = Vector2((size.x - _card.size.x) * 0.5, TOP + dy)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	var sec := float((_data.get("opts", {}) as Dictionary).get("sec", SEC))
	if _t >= sec and not _leaving:
		_leave()

## The ring burst behind the card: three hexagons growing out of its centre.
func _draw() -> void:
	if _card == null or not is_instance_valid(_card):
		return
	var accent: Color = (_data.get("opts", {}) as Dictionary).get("color", RING_COL)
	var c := _card.position + _card.size * 0.5
	for i in 3:
		var k := clampf((_t - float(i) * 0.18) / 1.4, 0.0, 1.0)
		if k <= 0.0 or k >= 1.0:
			continue
		var r := lerpf(40.0, 340.0, ease(k, 0.4))
		var pts := PackedVector2Array()
		for j in 7:
			var a := float(j) * TAU / 6.0 + PI / 6.0 + k * 0.4
			pts.append(c + Vector2(cos(a), sin(a) * 0.55) * r)
		draw_polyline(pts, Color(accent, (1.0 - k) * 0.7), 2.0, true)

func _leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween().set_parallel(true)
	tw.tween_method(_place, 0.0, -30.0, 0.3)
	tw.tween_property(_card, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(func() -> void:
		var layer := get_parent()
		if layer != null:
			layer.queue_free()
		MilestoneBanner._next())
