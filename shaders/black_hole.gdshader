// A black hole for the map views (Star System, Star Cluster), in the pixel-art
// look of the star shader: a black disc, a thin bright photon ring round it and
// a slowly swirling haze that fades out. Its accretion disk is a separate
// sprite lying in the system's plane (StarSystemView).
shader_type canvas_item;

uniform float pixel_count = 64.0;
// Share of the rect's half-size the black disc takes.
uniform float hole_radius = 0.16;
uniform vec3 ring_color = vec3(1.0, 0.80, 0.55);
uniform vec3 glow_color = vec3(0.50, 0.28, 0.95);
uniform float seed = 0.0;
uniform float swirl_speed = 1.2;

void fragment() {
	vec2 uv = floor(UV * pixel_count) / pixel_count;
	vec2 c = uv - vec2(0.5);
	float d = length(c);
	float ang = atan(c.y, c.x);
	if (d < hole_radius) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		float swirl = 0.5 + 0.5 * sin(ang * 3.0 + d * 32.0 - TIME * swirl_speed + seed);
		float ring = exp(-pow((d - hole_radius) / 0.016, 2.0));
		float glow = exp(-(d - hole_radius) / 0.085) * (0.55 + 0.45 * swirl);
		vec3 rgb = ring_color * ring * 1.5 + glow_color * glow * 0.9;
		float a = clamp(ring + glow * 0.85, 0.0, 1.0) * smoothstep(0.5, 0.40, d);
		COLOR = vec4(rgb, a);
	}
}
