class_name LunarLander
extends Control

## The colony lander above the Moon: flies in from deep space, parks in orbit
## until the player picks a landing site, then descends onto it.
## PlanetaryView owns it and calls tick() every frame.

enum Phase { ARRIVING, ORBIT, DESCENT }

signal landed

var phase: Phase = Phase.ORBIT
var heading: Vector2 = Vector2.RIGHT
var flame: float = 0.0

var _t := 0.0
var _orbit_a := 0.0
var _from := Vector2.ZERO
var _target: Callable          # () -> Vector3 (screen x, y, visible z) for DESCENT
const ARRIVE_SEC  := 3.0
const DESCENT_SEC := 3.2
const ORBIT_SPEED := 0.35      # rad/s

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 12
	size = Vector2.ZERO

## Fly in from off-screen before settling into orbit.
func arrive(from_global: Vector2) -> void:
	phase = Phase.ARRIVING
	_from = from_global
	_t = 0.0

## Drop onto the site `target` returns (re-evaluated as the globe turns).
func descend(target: Callable) -> void:
	phase = Phase.DESCENT
	_from = global_position
	_target = target
	_t = 0.0

func tick(delta: float, center: Vector2, r_px: float) -> void:
	_orbit_a = fposmod(_orbit_a + ORBIT_SPEED * delta, TAU)
	var orbit_pos := center + Vector2(cos(_orbit_a) * r_px * 1.45, sin(_orbit_a) * r_px * 0.36)
	var behind := sin(_orbit_a) < 0.0 and absf(orbit_pos.x - center.x) < r_px
	var prev := global_position
	match phase:
		Phase.ARRIVING:
			_t += delta / ARRIVE_SEC
			var e := 1.0 - pow(1.0 - clampf(_t, 0.0, 1.0), 3.0)
			global_position = _from.lerp(orbit_pos, e)
			flame = 1.0 - e
			modulate.a = 1.0
			if _t >= 1.0:
				phase = Phase.ORBIT
		Phase.ORBIT:
			global_position = orbit_pos
			flame = 0.0
			modulate.a = 0.0 if behind else 1.0
		Phase.DESCENT:
			_t += delta / DESCENT_SEC
			var tgt: Vector3 = _target.call()
			var e := clampf(_t, 0.0, 1.0)
			e = e * e   # accelerate down…
			global_position = _from.lerp(Vector2(tgt.x, tgt.y), e)
			flame = 1.0
			modulate.a = 1.0
			if _t >= 1.0:
				landed.emit()
				queue_free()
				return
	var mv := global_position - prev
	if mv.length() > 0.05:
		heading = heading.lerp(mv.normalized(), 0.2).normalized()
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, heading.angle(), Vector2(2, 2))
	if flame > 0.02:
		var hue: float = 0.45 + randf() * 0.25
		draw_rect(Rect2(Vector2(-9, -1), Vector2(3, 2)), Color(1.0, hue, 0.05, 0.9 * flame))
		draw_rect(Rect2(Vector2(-12, -1), Vector2(2, 2)), Color(1.0, hue * 0.6, 0.02, 0.5 * flame))
	var hull := Color(0.92, 0.95, 1.0)
	draw_rect(Rect2(Vector2(-6, -2), Vector2(8, 4)), hull)
	draw_rect(Rect2(Vector2(2, -1), Vector2(3, 2)), hull)
	draw_rect(Rect2(Vector2(-6, -4), Vector2(2, 2)), Color(0.55, 0.75, 1.0))
	draw_rect(Rect2(Vector2(-6, 2), Vector2(2, 2)), Color(0.55, 0.75, 1.0))
