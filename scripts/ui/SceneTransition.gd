extends CanvasLayer

var pending_data:   Variant = null
var _overlay:       ColorRect
var _transitioning: bool = false

func _ready() -> void:
	layer  = 128
	_overlay                  = ColorRect.new()
	_overlay.color            = Color(0, 0, 0, 1)   # start fully black
	_overlay.anchor_right     = 1.0
	_overlay.anchor_bottom    = 1.0
	_overlay.grow_horizontal  = Control.GROW_DIRECTION_BOTH
	_overlay.grow_vertical    = Control.GROW_DIRECTION_BOTH
	_overlay.mouse_filter     = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	_fade_to_clear()           # reveal the first scene

func _fade_to_clear() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_overlay, "color:a", 0.0, 0.40)
	tw.tween_callback(func() -> void: _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE)

func go(path: String, data: Variant = null) -> void:
	if _transitioning:
		return
	_transitioning             = true
	pending_data               = data
	_overlay.mouse_filter      = Control.MOUSE_FILTER_STOP
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_overlay, "color:a", 1.0, 0.35)
	tw.tween_callback(func() -> void:
		get_tree().change_scene_to_file(path)
		_transitioning = false
		_fade_to_clear()         # reveal the new scene
	)

## Soft switch for zoom transitions (Planet ⇄ Star System): the last frame of
## the old view stays on top as a still and melts away over the new one, which
## starts in the same framing and keeps zooming — no black in between. The two
## views stay separate scenes (only one is loaded at a time).
func go_soft(path: String, data: Variant = null, fade_sec := 0.45) -> void:
	if _transitioning:
		return
	_transitioning = true
	pending_data = data
	var img := get_viewport().get_texture().get_image()
	var snap := TextureRect.new()
	snap.texture = ImageTexture.create_from_image(img)
	snap.anchor_right = 1.0
	snap.anchor_bottom = 1.0
	snap.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	snap.stretch_mode = TextureRect.STRETCH_SCALE
	snap.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(snap)
	get_tree().change_scene_to_file(path)
	# let the new view build and draw its first frames under the still
	await get_tree().process_frame
	await get_tree().process_frame
	_transitioning = false
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(snap, "modulate:a", 0.0, fade_sec)
	tw.tween_callback(snap.queue_free)
