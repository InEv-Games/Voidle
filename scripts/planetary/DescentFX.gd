extends Control

## One descent from orbit to a real point on the surface, shared by the Moon
## lander and ships told to land (OrbitalLayer):
##   COLLAPSE  the craft holds still while its orbit line shrinks away
##   DESCENT   it spirals down the orbit's way — dashed projected path ahead,
##             exhaust trail behind — onto the site
##   IMPACT    a dust puff (LAND) or a burst of sparks (CRASH), anchored to
##             the site as the globe turns
## Everything is in global screen space; the callables are polled each frame
## so the path follows a rotating, zooming globe.

signal touched_down   # the craft reached the surface (impact starts)
signal finished       # effect over — free to act on the result

enum Kind { LAND, CRASH }

const COLLAPSE_SEC := 1.0
const DESCENT_SEC  := 3.2
const IMPACT_SEC   := 1.4

var kind: Kind = Kind.LAND
## "lander", "shuttle" or "station" — which pixel sprite to draw.
var sprite := "lander"
var sprite_scale := 2.0

var _center_fn: Callable    # () -> Vector2  planet centre
var _target_fn: Callable    # () -> Vector3  site (x, y, z>0 when facing us)
var _orbit_fn: Callable     # (angle) -> Vector2  orbit point, for the collapse
## Optional 3D route: (t 0..1) -> Vector3(screen x, screen y, 1 if hidden behind
## the globe). When set it replaces the 2D spiral — the craft follows its orbit
## forward and dives onto the site in the planet's own frame (OrbitalLayer).
var _path3: Callable
var _orbit_a0 := 0.0
var _orbit_dir := 1.0

var _phase := 0
var _t := 0.0
var _start := Vector2.ZERO
var _a0 := 0.0
var _r0 := 0.0
var _da := 0.0
var _pos := Vector2.ZERO
var _heading := Vector2.RIGHT
var _trail: Array[Vector2] = []
var _hidden := false   # behind the globe right now (3D route)
var _bits: Array[Dictionary] = []   # impact particles, offsets from the site
# last centre / site read — used if the owner of the callables goes away
var _last_c := Vector2.ZERO
var _last_site := Vector3.ZERO

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 13
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## `start` — where the craft is now (global). `orbit_fn`/`orbit_a0`/`orbit_dir`
## describe the orbit it leaves (pass an invalid Callable to skip the collapse).
func begin(start: Vector2, center_fn: Callable, target_fn: Callable,
		orbit_fn: Callable = Callable(), orbit_a0 := 0.0, orbit_dir := 1.0,
		path3: Callable = Callable()) -> void:
	_path3 = path3
	_start = start
	_pos = start
	_center_fn = center_fn
	_target_fn = target_fn
	_orbit_fn = orbit_fn
	_orbit_a0 = orbit_a0
	_orbit_dir = orbit_dir
	_phase = 0 if orbit_fn.is_valid() else 1
	_t = 0.0
	if _phase == 1:
		_lock_path()

## Centre and site from the callables, or the last known ones if their owner
## was freed (e.g. the layer rebuilt) — the effect still finishes in place.
func _c() -> Vector2:
	if _center_fn.is_valid():
		_last_c = _center_fn.call()
	return _last_c

func _site3() -> Vector3:
	if _path3.is_valid():
		var e: Vector3 = _path3.call(1.0)
		_last_site = Vector3(e.x, e.y, 1.0)
	elif _target_fn.is_valid():
		_last_site = _target_fn.call()
	return _last_site

## Craft position at t (and whether the globe hides it).
func _at(t: float, c: Vector2, site: Vector2) -> Vector3:
	if _path3.is_valid():
		return _path3.call(t)
	var p := _path(t, c, site)
	return Vector3(p.x, p.y, 0.0)

## Old-landing easing: leaves at orbital speed, then accelerates.
static func ease_dive(t: float) -> float:
	return t * (1.0 + t) * 0.5

func _lock_path() -> void:
	var c: Vector2 = _c()
	var s := _pos - c
	_a0 = s.angle()
	_r0 = s.length()

## Point on the descent at 0..1 — turn early, drop late, ending on the site.
func _path(t: float, c: Vector2, site: Vector2) -> Vector2:
	var v := site - c
	var ang := _a0 + _da * (1.0 - pow(1.0 - t, 2.0))
	var rad := lerpf(_r0, v.length(), t * t)
	return c + Vector2.from_angle(ang) * rad

func _process(delta: float) -> void:
	var c: Vector2 = _c()
	var tgt3: Vector3 = _site3()
	var site := Vector2(tgt3.x, tgt3.y)
	match _phase:
		0:
			if _path3.is_valid():   # the craft rides along with the turning globe
				var a0: Vector3 = _path3.call(0.0)
				_pos = Vector2(a0.x, a0.y)
				_hidden = a0.z > 0.5
			_t += delta / COLLAPSE_SEC
			if _t >= 1.0:
				_phase = 1
				_t = 0.0
				_lock_path()
		1:
			if _t == 0.0:
				# keep turning the way the orbit runs, the short way round
				_da = wrapf((site - c).angle() - _a0, -PI, PI)
				if _orbit_dir > 0.0 and _da < -PI * 0.25:
					_da += TAU
				elif _orbit_dir < 0.0 and _da > PI * 0.25:
					_da -= TAU
			_t += delta / DESCENT_SEC
			var prev := _pos
			var at := _at(clampf(_t, 0.0, 1.0), c, site)
			_pos = Vector2(at.x, at.y)
			_hidden = at.z > 0.5
			var mv := _pos - prev
			if mv.length() > 0.05:
				_heading = _heading.lerp(mv.normalized(), 0.25).normalized()
			if _hidden:
				_trail.clear()
			elif _trail.is_empty() or _trail[-1].distance_to(_pos) > 3.0:
				_trail.append(_pos)
				if _trail.size() > 40:
					_trail.remove_at(0)
			if _t >= 1.0:
				_phase = 2
				_t = 0.0
				_spawn_impact((site - c).normalized())
				touched_down.emit()
		2:
			_t += delta / IMPACT_SEC
			for b: Dictionary in _bits:
				b["off"] = (b["off"] as Vector2) + (b["vel"] as Vector2) * delta
				b["vel"] = (b["vel"] as Vector2) * pow(0.25 if kind == Kind.LAND else 0.6, delta) \
					+ (b["grav"] as Vector2) * delta
			if _trail.size() > 0:
				_trail.remove_at(0)
			if _t >= 1.0:
				finished.emit()
				queue_free()
				return
	queue_redraw()

## `up` — surface normal on screen (from the centre through the site).
func _spawn_impact(up: Vector2) -> void:
	_bits.clear()
	var tangent := Vector2(-up.y, up.x)
	var n := 14 if kind == Kind.LAND else 16
	for i in n:
		var spread := randf_range(-1.0, 1.0)
		var b := {}
		if kind == Kind.LAND:
			# dust rolls out sideways along the ground, rising a little
			b["vel"] = tangent * spread * randf_range(30.0, 60.0) + up * randf_range(4.0, 16.0)
			b["grav"] = -up * 6.0
			b["col"] = Color(0.80, 0.76, 0.68)
			b["size"] = randf_range(2.0, 4.0)
		else:
			b["vel"] = (up * randf_range(0.6, 1.0) + tangent * spread).normalized() * randf_range(40.0, 90.0)
			b["grav"] = -up * 70.0
			b["col"] = Color(1.0, randf_range(0.25, 0.6), 0.05)
			b["size"] = 2.0
		b["off"] = Vector2.ZERO
		_bits.append(b)

func _draw() -> void:
	var o := global_position
	var c: Vector2 = _last_c
	var tgt3: Vector3 = _last_site
	var site := Vector2(tgt3.x, tgt3.y)
	match _phase:
		0:
			# orbit line shrinking from its tail towards the craft
			if _orbit_fn.is_valid() and _center_fn.is_valid():
				var remaining := (1.0 - _t) * TAU
				var col := Color(1, 1, 1, (1.0 - _t) * 0.30)
				const STEPS := 60
				var prev: Vector2 = _orbit_fn.call(_orbit_a0 - _orbit_dir * remaining)
				for s in range(1, STEPS + 1):
					var f := float(s) / float(STEPS)
					if f * TAU > remaining:
						break
					var p: Vector2 = _orbit_fn.call(_orbit_a0 - _orbit_dir * remaining + _orbit_dir * f * TAU)
					if (s % 6) < 3:
						draw_line(prev - o, p - o, col, 1.2, true)
					prev = p
			if not _hidden:
				_draw_craft(_pos - o, 0.0)
		1:
			# dashed projected path still ahead
			var t0 := clampf(_t, 0.0, 1.0)
			const PSTEPS := 32
			var prev3 := _at(t0, c, site)
			for s in range(1, PSTEPS + 1):
				var tt := t0 + float(s) / float(PSTEPS) * (1.0 - t0)
				var p3 := _at(tt, c, site)
				if (s % 5) < 3 and prev3.z < 0.5 and p3.z < 0.5:
					draw_line(Vector2(prev3.x, prev3.y) - o, Vector2(p3.x, p3.y) - o,
						Color(1.0, 0.65, 0.25, 0.45 * (1.0 - t0 * 0.6)), 1.2, true)
				prev3 = p3
			# target marker
			draw_arc(site - o, 5.0, 0.0, TAU, 16, Color(1.0, 0.75, 0.3, 0.6), 1.0)
			_draw_trail(o)
			if not _hidden:
				_draw_craft(_pos - o, 1.0)
		2:
			_draw_trail(o)
			var life := 1.0 - _t
			for b: Dictionary in _bits:
				var p: Vector2 = site + (b["off"] as Vector2) - o
				var sz: float = b["size"] * (1.0 + (_t * 1.5 if kind == Kind.LAND else 0.0))
				draw_rect(Rect2(p - Vector2.ONE * sz * 0.5, Vector2.ONE * sz), Color(b["col"], life * 0.85))
			if kind == Kind.LAND:
				draw_arc(site - o, 4.0 + _t * 18.0, 0.0, TAU, 24, Color(0.85, 0.82, 0.75, life * 0.5), 1.0)

func _draw_trail(o: Vector2) -> void:
	for i in _trail.size():
		var a := float(i + 1) / float(_trail.size() + 1)
		draw_rect(Rect2(_trail[i] - o - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.6, 0.2, a * 0.55))

func _draw_craft(p: Vector2, flame: float) -> void:
	draw_set_transform(p, _heading.angle(), Vector2.ONE * sprite_scale)
	if flame > 0.0:
		var hue: float = 0.45 + randf() * 0.25
		draw_rect(Rect2(Vector2(-9, -1), Vector2(3, 2)), Color(1.0, hue, 0.05, 0.9 * flame))
		draw_rect(Rect2(Vector2(-12, -1), Vector2(2, 2)), Color(1.0, hue * 0.6, 0.02, 0.5 * flame))
	var hull := Color(0.92, 0.95, 1.0)
	match sprite:
		"station":
			draw_rect(Rect2(Vector2(-3, -3), Vector2(6, 6)), Color(0.85, 0.90, 1.0))
			draw_rect(Rect2(Vector2(-9, -1), Vector2(5, 2)), Color(0.30, 0.60, 1.0))
			draw_rect(Rect2(Vector2(4, -1), Vector2(5, 2)), Color(0.30, 0.60, 1.0))
		"shuttle":
			draw_rect(Rect2(Vector2(-3, -1), Vector2(6, 2)), hull)
			draw_rect(Rect2(Vector2(-1, -3), Vector2(2, 6)), hull)
		"lander":
			draw_rect(Rect2(Vector2(-3, -2), Vector2(6, 4)), hull)
			draw_rect(Rect2(Vector2(-1, -4), Vector2(2, 2)), Color(0.55, 0.75, 1.0))
			draw_rect(Rect2(Vector2(-5, 2), Vector2(2, 2)), hull)
			draw_rect(Rect2(Vector2(3, 2), Vector2(2, 2)), hull)
		_:
			draw_rect(Rect2(Vector2(-6, -2), Vector2(8, 4)), hull)
			draw_rect(Rect2(Vector2(2, -1), Vector2(3, 2)), hull)
			draw_rect(Rect2(Vector2(-6, -4), Vector2(2, 2)), Color(0.55, 0.75, 1.0))
			draw_rect(Rect2(Vector2(-6, 2), Vector2(2, 2)), Color(0.55, 0.75, 1.0))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
