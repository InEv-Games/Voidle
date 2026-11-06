class_name Spring
extends RefCounted

## A critically damped spring ("smooth damp"): moves a value toward a target
## with its speed easing in from rest and easing out to a stop, never
## overshooting. A new target mid-way bends the motion instead of jerking it,
## which a plain lerp(x, target, k) can't do (that one starts at full speed).
## Frame-rate independent. Each moving value keeps its own velocity:
##   var r := Spring.damp(_zoom, _zoom_vel, _zoom_target, 0.2, delta)
##   _zoom = r.x; _zoom_vel = r.y
## It is linear, so values eased with the same `time` stay in step with each
## other (a point kept under the cursor by zoom + pan stays put).

## How long a move takes, roughly: it covers ~90% of the way in 2 × `time`.
## For a `1 - exp(-rate * delta)` lerp, `time` ≈ 1.18 / rate feels alike.
static func time_for_rate(rate: float) -> float:
	return 1.18 / maxf(rate, 0.001)

## One step: returns Vector2(new value, new velocity).
static func damp(x: float, v: float, target: float, time: float, dt: float) -> Vector2:
	var omega := 2.0 / maxf(time, 0.0001)
	var e := omega * dt
	var decay := 1.0 / (1.0 + e + 0.48 * e * e + 0.235 * e * e * e)
	var change := x - target
	var temp := (v + omega * change) * dt
	return Vector2(target + (change + temp) * decay, (v - omega * temp) * decay)

## Like damp() for an angle (radians): takes the short way round.
static func damp_angle(x: float, v: float, target: float, time: float, dt: float) -> Vector2:
	var near := x + wrapf(target - x, -PI, PI)
	return damp(x, v, near, time, dt)

## damp() per axis; returns [new value: Vector2, new velocity: Vector2].
static func damp_v2(x: Vector2, v: Vector2, target: Vector2, time: float, dt: float) -> Array:
	var a := damp(x.x, v.x, target.x, time, dt)
	var b := damp(x.y, v.y, target.y, time, dt)
	return [Vector2(a.x, b.x), Vector2(a.y, b.y)]

## True once a value is at its target and has stopped (to snap and rest).
static func settled(x: float, v: float, target: float, eps := 0.0005) -> bool:
	return absf(x - target) < eps and absf(v) < eps * 4.0
