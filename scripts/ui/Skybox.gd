## The map views' sky (and the planet view's) as a skybox: the starfield (Starfield.apply) turns with
## the camera. Turning (yaw) slides it sideways round the full circle, tilting
## slides it up and down, and the focus moving drifts it a little; the
## starfield's three layers each take their own share (far least, near most:
## shaders/starfield.gdshader), so the sky has depth. The field never ends, so
## a whole turn just keeps going.
##
## The offset depends only on the camera's yaw / tilt (and focus), which the
## views hand over to each other on every switch: the sky stays put across a
## zoom from one view to the next.
##   Skybox.follow(_sky, _yaw, _tilt, _focus.rotated(_yaw) * k, _ui())
class_name Skybox
extends RefCounted

## px of sky (at 1080 p) per radian of turn: a full turn ≈ 1.5 screen widths.
const PX_PER_RAD := 460.0
## px of sky per unit of tilt (the views' tilt runs ~0.16 … 0.9).
const PX_PER_TILT := 420.0
## Below this change (px) the sky isn't redrawn.
const MIN_STEP := 0.5


static func follow(sky: Dictionary, yaw: float, tilt: float, drift := Vector2.ZERO, ui := 1.0) -> void:
	if sky.is_empty():
		return
	# the sky is the far side of the turn: it goes the other way from the
	# things in front (turning right, the near side goes right, the sky left);
	# looking down more, it slides up
	var off := Vector2(-yaw * PX_PER_RAD, (tilt - 0.45) * PX_PER_TILT) * ui + drift
	var last: Vector2 = sky.get("last", Vector2.INF)
	if last.is_finite() and off.distance_to(last) < MIN_STEP:
		return
	sky["last"] = off
	(sky["mat"] as ShaderMaterial).set_shader_parameter("offset", off)
	(sky["vp"] as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE
