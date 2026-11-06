// Whole-screen analog CRT look (ScreenFX), after the late-70s sci-fi terminal:
// phosphor glow on bright parts, a faint green-cyan cast, fine scanlines, a
// colour fringe that grows toward the edges, a slow per-line wobble with a
// rare tracking band, a tiny brightness flicker, grain and a soft vignette.
// `intensity` lays the treated image over the clean one; every part is kept
// mild so the whole stays subtle.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float intensity : hint_range(0.0, 1.0) = 0.35;
uniform vec4 phosphor : source_color = vec4(0.72, 1.0, 0.93, 1.0);   // the cast's colour
uniform float tint = 0.3;             // how much of the cast
uniform float glow = 1.0;              // bloom of what is brighter than glow_threshold
uniform float glow_threshold = 0.2;
uniform float glow_lod = 3.0;          // blur size (mip level) of the glow
uniform float scanline = 0.3;          // darkness of the dark half of each line pair
uniform float scan_period = 3.0;       // px per scanline pair (physical pixels)
uniform float bleed = 0.0012;          // colour fringe (UV), more toward the edges
uniform float wobble = 0.0007;         // per-line drift (UV)
uniform float flicker = 0.02;
uniform float grain = 0.03;
uniform float vignette = 0.22;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise1(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash(vec2(i, 0.0)), hash(vec2(i + 1.0, 0.0)), f * f * (3.0 - 2.0 * f));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME;
	// analog wobble: a slow drift that varies line by line, and now and then a
	// thin tracking band rolling down
	float dx = (noise1(FRAGCOORD.y * 0.015 + t * 0.7) - 0.5) * wobble;
	float band_on = step(0.92, hash(vec2(floor(t * 0.5), 3.0)));
	dx += band_on * smoothstep(0.025, 0.0, abs(uv.y - fract(t * 0.21))) * wobble * 5.0;
	vec2 d = uv - 0.5;
	float edge = dot(d, d);   // 0 at the centre, 0.5 in the corners
	float b = bleed * (0.3 + edge * 2.0);
	vec3 col;
	col.r = textureLod(screen_tex, uv + vec2(dx + b, 0.0), 0.0).r;
	col.g = textureLod(screen_tex, uv + vec2(dx, 0.0), 0.0).g;
	col.b = textureLod(screen_tex, uv + vec2(dx - b, 0.0), 0.0).b;
	vec3 clean = textureLod(screen_tex, uv, 0.0).rgb;
	// phosphor glow: the bright parts bloom
	vec3 blur = textureLod(screen_tex, uv, glow_lod).rgb * 0.6
		+ textureLod(screen_tex, uv, glow_lod + 1.5).rgb * 0.4;
	col += max(blur - glow_threshold, vec3(0.0)) * glow;
	// the cast
	col = mix(col, col * phosphor.rgb * 1.12, tint);
	// scanlines
	col *= 1.0 - scanline * (0.5 + 0.5 * cos(FRAGCOORD.y * TAU / scan_period));
	// flicker and grain
	col *= 1.0 + (noise1(t * 9.0) - 0.5) * flicker * 2.0;
	col += (hash(FRAGCOORD.xy + fract(t) * 100.0) - 0.5) * grain;
	// soft vignette
	col *= 1.0 - vignette * smoothstep(0.12, 0.5, edge);
	COLOR = vec4(mix(clean, col, intensity), 1.0);
}
