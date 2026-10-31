// Starfield behind the planet and system views: a few layers of sparse,
// pixel-snapped stars (so they sit with the pixel art), a gentle twinkle on
// some of them and a faint nebula haze over the ColorRect's base colour.
// Kept quiet on purpose: it is a backdrop, not a feature.
shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.04, 0.05, 0.10, 1.0);
// Stars per layer: chance a grid cell holds a star.
uniform float density = 0.035;
// Overall star brightness.
uniform float brightness = 0.75;
// Size of one star pixel on screen.
uniform float pixel = 2.0;
// Nebula haze strength (0 = none).
uniform float nebula = 0.06;
// Shifts the field (parallax, e.g. from the view's pan); in pixels.
uniform vec2 offset = vec2(0.0);
// Nebula cloud size, in pixels of the render (Starfield renders at one texel
// per logical pixel, so 450 there matches 900 physical on a Retina screen).
uniform float nebula_scale = 900.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

// One layer: cells of `cell` star-pixels, at most one star each.
float star_layer(vec2 px, float cell, float seed, float twinkle_amt) {
	vec2 g = floor(px / cell);
	float h = hash(g + seed);
	if (h > density) return 0.0;
	// the star's own pixel inside its cell
	vec2 at = floor(vec2(hash(g + seed + 1.7), hash(g + seed + 9.3)) * (cell - 1.0));
	vec2 local = floor(px - g * cell);
	float d = max(abs(local.x - at.x), abs(local.y - at.y));
	float big = step(0.8, hash(g + seed + 4.1));   // a few stars get a faint cross
	float core = step(d, 0.0);
	float arm = big * step(d, 1.0) * step(min(abs(local.x - at.x), abs(local.y - at.y)), 0.0) * 0.35;
	float tw = 1.0 - twinkle_amt * (0.5 + 0.5 * sin(TIME * (0.6 + 2.0 * hash(g + seed + 2.2)) + h * 50.0));
	return (core + arm) * tw * (0.45 + 0.55 * hash(g + seed + 7.7));
}

void fragment() {
	vec2 px = floor((FRAGCOORD.xy + offset) / pixel);
	vec3 col = base_color.rgb;
	// faint nebula: two soft colour clouds
	vec2 uv = (FRAGCOORD.xy + offset * 0.3) / nebula_scale;
	float n1 = fbm(uv * 1.3 + 3.1);
	float n2 = fbm(uv * 1.7 - 5.4);
	col += vec3(0.20, 0.10, 0.35) * smoothstep(0.55, 0.85, n1) * nebula;
	col += vec3(0.05, 0.18, 0.30) * smoothstep(0.55, 0.85, n2) * nebula;
	// three layers: far (many, dim), mid, near (few, brighter, some twinkle)
	float s = star_layer(px, 9.0, 11.0, 0.0) * 0.45
		+ star_layer(px, 17.0, 37.0, 0.25) * 0.75
		+ star_layer(px, 31.0, 73.0, 0.55);
	vec3 tint = mix(vec3(0.75, 0.85, 1.0), vec3(1.0, 0.92, 0.80), hash(px * 0.01));
	col += tint * s * brightness;
	COLOR = vec4(col, base_color.a);
}
