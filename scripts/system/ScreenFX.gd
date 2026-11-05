## Whole-screen analog VHS look: shaders/vhs_glitch.gdshader at full strength,
## blended faintly (OPACITY) over everything the game draws — above all UI,
## under the cursor (CursorManager's layer 500). Also makes random interface
## parts flicker now and then (see Interface flicker below).
extends Node

const LAYER := 495
const OPACITY := 0.02
const VHS_SHADER := preload("res://shaders/vhs_glitch.gdshader")

var _rect: ColorRect

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	layer.name = "ScreenFXLayer"
	add_child(layer)
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = VHS_SHADER
	mat.set_shader_parameter(&"amount", 1.0)
	mat.set_shader_parameter(&"opacity", OPACITY)
	_rect.material = mat
	layer.add_child(_rect)
	_next_flicker = randf_range(FLICKER_EVERY.x, FLICKER_EVERY.y)

# ── Interface flicker ─────────────────────────────────────────────────────────
# Now and then a few random interface parts (cards, buttons, labels, panels —
# CyberReveal's blocks) dip FLICKER_DIP in opacity, like a weak tape signal,
# and come back. Never the whole screen: huge controls (the globe area, full
# panels) are skipped, and so is anything another script is fading.

const FLICKER_EVERY := Vector2(0.6, 2.4)     # seconds between flickers (random)
const FLICKER_PARTS := Vector2i(1, 3)        # parts per flicker (random)
const FLICKER_DIP := 0.15                    # opacity drop
const FLICKER_MAX_AREA := 0.25               # skip parts bigger than this share of the screen
const FLICKER_MIN_AREA := 120.0              # …or smaller than this many px²
## (seconds, dimmed?) — dim, back, dim a little longer, back.
const FLICKER_PATTERN := [[0.06, true], [0.05, false], [0.10, true]]

var _next_flicker := 0.0
var _flickering: Dictionary = {}   # instance id → its own modulate, while its flicker runs

func _process(delta: float) -> void:
	_next_flicker -= delta
	if _next_flicker > 0.0:
		return
	_next_flicker = randf_range(FLICKER_EVERY.x, FLICKER_EVERY.y)
	var parts: Array[Control] = []
	var screen := get_viewport().get_visible_rect()
	_collect_parts(get_tree().root, parts, screen)
	parts.shuffle()
	for i in mini(randi_range(FLICKER_PARTS.x, FLICKER_PARTS.y), parts.size()):
		_flicker(parts[i])

func _collect_parts(n: Node, out: Array[Control], screen: Rect2) -> void:
	for c in n.get_children():
		if c == self or c is SubViewport or c is Window:
			continue
		if c is CanvasItem and not (c as CanvasItem).visible:
			continue
		if c is LeftPanel and (c as LeftPanel).is_animating():
			continue   # opening / closing: it blinks its parts itself
		if c is Control and CyberReveal._is_block(c as Control):
			var r := (c as Control).get_global_rect()
			var area := r.get_area()
			if area >= FLICKER_MIN_AREA and area <= screen.get_area() * FLICKER_MAX_AREA \
					and screen.intersects(r) and (c as Control).modulate.a > 0.99 \
					and not _flickering.has(c.get_instance_id()):
				out.append(c)
		_collect_parts(c, out, screen)

## A control's own modulate, even while a flicker has it dimmed.
func base_modulate(n: Control) -> Color:
	return _flickering.get(n.get_instance_id(), n.modulate)

func _flicker(n: Control) -> void:
	var id := n.get_instance_id()
	var orig := n.modulate
	_flickering[id] = orig
	var dim := Color(orig.r, orig.g, orig.b, orig.a * (1.0 - FLICKER_DIP))
	var last := [orig]   # what we set last; if it changed, someone else drives it
	var tw := create_tween()
	# by id, not the node itself: it may be freed mid-flicker
	for step in FLICKER_PATTERN:
		var target: Color = dim if step[1] else orig
		tw.tween_callback(func() -> void:
			var c := instance_from_id(id) as Control
			if c != null and c.modulate == last[0]:
				c.modulate = target
				last[0] = target)
		tw.tween_interval(step[0])
	tw.tween_callback(func() -> void:
		_flickering.erase(id)
		var c := instance_from_id(id) as Control
		if c != null and c.modulate == last[0]:
			c.modulate = orig)
