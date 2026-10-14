class_name LunarTransitRocket
extends Node2D

## The lander flying from the home world to its Moon in the Local System view.
## Its position follows the moon's colonize_progress along an arc from the
## planet's limb to the moon; emits `arrived` once the colonization finishes.

signal arrived(moon: PlanetData)

var moon: PlanetData
var planet_center: Callable   # () -> Vector2, in this node's parent space
var planet_radius: float = 96.0
var target: Node2D            # the moon's orbit node
## Hull size multiplier for the pixel sprite.
var sprite_scale := 1.0

var _trail: Array[Vector2] = []
var _eta: Label

func setup(p_moon: PlanetData, p_center: Callable, p_radius: float, p_target: Node2D) -> void:
	moon = p_moon
	planet_center = p_center
	planet_radius = p_radius
	target = p_target
	z_as_relative = false
	z_index = 70
	_eta = Label.new()
	var orbitron := load("res://Fonts/Orbitron-VariableFont_wght.ttf") as Font
	if orbitron:
		_eta.add_theme_font_override("font", orbitron)
	_eta.add_theme_font_size_override("font_size", 9)
	_eta.add_theme_color_override("font_color", Color(0.65, 0.88, 1.0, 0.85))
	_eta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_eta.add_theme_constant_override("outline_size", 3)
	_eta.position = Vector2(8, -6)
	add_child(_eta)

func _process(_delta: float) -> void:
	var pp := GameState.get_planet(moon.seed)
	if pp.is_colonized:
		arrived.emit(moon)
		queue_free()
		return
	if not is_instance_valid(target):
		return
	var from: Vector2 = planet_center.call()
	var to: Vector2 = target.global_position - get_parent().global_position
	var dir := (to - from).normalized()
	var start := from + dir * planet_radius
	# arc bulging "up" (screen) so it reads as a trajectory, not a straight line
	var ctrl := (start + to) * 0.5 + Vector2(0, -minf(140.0, start.distance_to(to) * 0.45))
	var t := clampf(pp.colonize_progress, 0.0, 1.0)
	# ease in (launch) and out (orbit insertion)
	var e := t * t * (3.0 - 2.0 * t)
	var p := _bezier(start, ctrl, to, e)
	var ahead := _bezier(start, ctrl, to, minf(1.0, e + 0.01))
	rotation = (ahead - p).angle()
	if _trail.is_empty() or _trail[-1].distance_to(p) > 4.0:
		_trail.append(p)
		if _trail.size() > 40:
			_trail.remove_at(0)
	position = p
	var left := int(ceil((1.0 - t) * pp.colonize_duration))
	_eta.text = "LANDER  %02d:%02d" % [left / 60, left % 60]
	_eta.rotation = -rotation
	queue_redraw()

func _bezier(a: Vector2, c: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(c, t).lerp(c.lerp(b, t), t)

func _draw() -> void:
	# fading exhaust trail (drawn in parent space → undo our transform)
	var inv := get_transform().affine_inverse()
	for i in _trail.size():
		var a := float(i) / maxf(1.0, float(_trail.size()))
		draw_rect(Rect2(inv * _trail[i] - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.65, 0.25, a * 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * sprite_scale)
	# flame
	var hue: float = 0.45 + randf() * 0.25
	draw_rect(Rect2(Vector2(-9, -1), Vector2(3, 2)), Color(1.0, hue, 0.05, 0.9))
	draw_rect(Rect2(Vector2(-12, -1), Vector2(2, 2)), Color(1.0, hue * 0.6, 0.02, 0.5))
	# hull (pointing +x)
	var hull := Color(0.92, 0.95, 1.0)
	draw_rect(Rect2(Vector2(-6, -2), Vector2(8, 4)), hull)
	draw_rect(Rect2(Vector2(2, -1), Vector2(3, 2)), hull)
	draw_rect(Rect2(Vector2(-6, -4), Vector2(2, 2)), Color(0.55, 0.75, 1.0))
	draw_rect(Rect2(Vector2(-6, 2), Vector2(2, 2)), Color(0.55, 0.75, 1.0))
