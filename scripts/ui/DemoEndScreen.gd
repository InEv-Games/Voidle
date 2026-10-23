## DemoEndScreen — "CIVILIZATION 0 COMPLETE" (scenes/ui/DemoEndScreen.tscn).
## Texts, colours and layout are edited in the scene. Labels may hold
## placeholders, filled in when the screen opens:
##   {planet}   the world the rocket reached
##   {minutes} {worlds} {cities} {research}   GameState.demo_stats()
## The fractal collapse (the Civilization 0 tree folding into one point) plays
## behind the content, then the content fades in.
extends Control

@export var shade_alpha := 0.72
@export var collapse_sec := 2.2
@export var content_delay := 1.8
@export var ring_color := Color(1.0, 0.85, 0.5)

@onready var _shade: ColorRect = %Shade
@onready var _rings: Control = %Rings
@onready var _content: Control = %Content
@onready var _keep: Button = %KeepPlayingButton

var _t := 0.0

func _ready() -> void:
	var tgt := GameState.get_planet_data(int(GameState.expedition("rocket").get("target_seed", -1)))
	var fill := GameState.demo_stats()
	fill["planet"] = tgt.planet_name if tgt != null else "a new world"
	_fill_labels(_content, fill)
	_keep.pressed.connect(func() -> void:
		AudioManager.play("click")
		_close())
	_rings.draw.connect(_draw_rings)
	_shade.color.a = 0.0
	_content.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_shade, "color:a", shade_alpha, 1.2)
	tw.tween_method(func(v: float) -> void:
		_t = v
		_rings.queue_redraw(), 0.0, 1.0, collapse_sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(_content, "modulate:a", 1.0, 1.6).set_delay(content_delay)
	AudioManager.play("building_done")

## Replaces {placeholders} in every Label / RichTextLabel / Button under `n`.
func _fill_labels(n: Node, fill: Dictionary) -> void:
	for c in n.get_children():
		if c is Label:
			(c as Label).text = (c as Label).text.format(fill)
		elif c is RichTextLabel:
			(c as RichTextLabel).text = (c as RichTextLabel).text.format(fill)
		elif c is Button:
			(c as Button).text = (c as Button).text.format(fill)
		_fill_labels(c, fill)

## Nested hexagon rings fold into one point — the whole Civilization 0 tree
## becoming the centre node of Civilization 1's tree.
func _draw_rings() -> void:
	var c := _rings.size * 0.5
	var base := minf(_rings.size.x, _rings.size.y) * 0.45
	for i in 7:
		var k := float(i) / 7.0
		var r := base * (1.0 - k * 0.8) * (1.0 - _t)
		if r < 1.0:
			continue
		var pts := PackedVector2Array()
		for j in 7:
			var a := float(j) * TAU / 6.0 + _t * PI * (1.0 + k)
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		_rings.draw_polyline(pts, Color(ring_color, 0.65 * (1.0 - _t) + 0.1), 2.0, true)
	_rings.draw_circle(c, 4.0 + 10.0 * _t, Color(ring_color.lightened(0.3), _t))

func _close() -> void:
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()
