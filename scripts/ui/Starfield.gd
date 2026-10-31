class_name Starfield
extends RefCounted

## Puts the starfield backdrop (shaders/starfield.gdshader) on a view's
## Background ColorRect, keeping its colour as the base.
const SHADER := preload("res://shaders/starfield.gdshader")

static func apply(rect: ColorRect) -> void:
	if rect == null:
		return
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("base_color", rect.color)
	rect.material = mat
