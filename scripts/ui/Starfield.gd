class_name Starfield
extends RefCounted

## Puts the starfield backdrop (shaders/starfield.gdshader) on a view's
## Background ColorRect, keeping its colour as the base.
##
## Laptop heat (playtest 31.10): the shader ran for every physical pixel, every
## frame. It now draws into a SubViewport at one texel per logical pixel (a
## star pixel), shown scaled up with nearest filtering, and redraws only
## TWINKLE_FPS times a second — the stars look the same at a sliver of the cost.
const SHADER := preload("res://shaders/starfield.gdshader")
const TWINKLE_FPS := 10.0

static func apply(rect: ColorRect) -> void:
	if rect == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("base_color", rect.color)
	mat.set_shader_parameter("pixel", 1.0)
	mat.set_shader_parameter("nebula_scale", 450.0)
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var src := ColorRect.new()
	src.material = mat
	vp.add_child(src)
	rect.add_child(vp)
	var view := TextureRect.new()
	view.texture = vp.get_texture()
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.add_child(view)
	var fit := func() -> void:
		var s := Vector2i(maxi(1, int(rect.size.x)), maxi(1, int(rect.size.y)))
		if vp.size != s:
			vp.size = s
			src.size = Vector2(s)
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	rect.resized.connect(fit)
	fit.call()
	var t := Timer.new()
	t.wait_time = 1.0 / TWINKLE_FPS
	t.autostart = true
	t.timeout.connect(func() -> void: vp.render_target_update_mode = SubViewport.UPDATE_ONCE)
	rect.add_child(t)
