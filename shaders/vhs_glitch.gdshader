// Analog VHS distortion over whatever is drawn behind this rect (screen-reading).
// `amount` 0..1 drives everything: 0 is a clean pass-through.
//   - line wobble: each scanline band drifts sideways a little, slowly
//   - tracking tears: now and then a band jumps further, like a bad tape spot
//   - colour bleed: red / blue split horizontally
//   - scanlines and grain
// `opacity` blends the result over the clean image.
// Used by ScreenFX: the whole screen, faintly, all the time.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float band_px = 3.0;          // height of one wobble band, in pixels
uniform float wobble = 0.006;         // max sideways drift (fraction of screen width)
uniform float tear = 0.035;           // max jump of a torn band
uniform float bleed = 0.0035;         // red / blue split
uniform float tape_fps = 12.0;        // how often the wobble pattern changes: low = analog
uniform float opacity : hint_range(0.0, 1.0) = 1.0;   // how much of the result lies over the clean image

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float frame = floor(TIME * tape_fps);
	float band = floor(FRAGCOORD.y / band_px);
	// smooth-ish drift: blend this frame's band offset with its neighbour's
	float drift = mix(hash(vec2(band, frame)), hash(vec2(band + 1.0, frame)), fract(FRAGCOORD.y / band_px)) - 0.5;
	float dx = drift * wobble * amount;
	// tracking tear: a few bands per frame jump, more of them at higher amount
	float big = floor(FRAGCOORD.y / (band_px * 6.0));
	if (hash(vec2(big, frame * 1.7)) > 1.0 - 0.18 * amount) {
		dx += (hash(vec2(big, frame + 3.1)) - 0.35) * tear * amount;
	}
	vec2 uv = SCREEN_UV + vec2(dx, 0.0);
	float b = bleed * amount;
	vec3 col;
	col.r = texture(screen_tex, uv + vec2(b, 0.0)).r;
	col.g = texture(screen_tex, uv).g;
	col.b = texture(screen_tex, uv - vec2(b, 0.0)).b;
	// scanlines + grain
	float scan = mod(FRAGCOORD.y, 2.0) < 1.0 ? 1.0 - 0.18 * amount : 1.0;
	col *= scan;
	col += (hash(FRAGCOORD.xy + frame) - 0.5) * 0.10 * amount;
	COLOR = vec4(col, opacity);
}
