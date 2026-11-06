// Ambient occlusion over a globe on the main menu (MainMenu.gd): darkens the
// limb, most on the side away from the sun, so the sphere reads rounder and
// deeper; far globes also get a flat haze that lifts their darks. Nothing is
// drawn outside the globe.
// Snapped to the globe's pixel grid so it matches the pixel-art shading.
shader_type canvas_item;

uniform float radius = 0.42;          // the globe's radius as a share of this rect
uniform float pixel_count = 128.0;    // pixels across this rect
uniform vec2 light = vec2(-0.7, -0.7); // towards the sun (screen, y down)
uniform float limb_strength = 0.45;
uniform float fog = 0.0;              // distance haze over the globe (0 near … 1 gone)
uniform vec3 fog_color : source_color = vec3(0.10, 0.14, 0.25);

void fragment() {
	vec2 uv = (floor(UV * pixel_count) + 0.5) / pixel_count;
	vec2 c = uv - 0.5;
	float d = length(c) / radius;
	float a = 0.0;
	vec3 col = vec3(0.0);
	if (d < 1.0) {
		float lit = dot(normalize(c + vec2(1e-5)), normalize(light));
		float k = smoothstep(0.50, 1.0, d);
		a = limb_strength * k * k * mix(1.0, 0.30, clamp(lit, 0.0, 1.0));
		// haze first, the occlusion over it, as one layer
		float f = fog * smoothstep(1.0, 0.92, d);
		float A = 1.0 - (1.0 - f) * (1.0 - a);
		col = A > 0.0 ? fog_color * f * (1.0 - a) / A : vec3(0.0);
		a = A;
	}
	COLOR = vec4(col, a);
}
