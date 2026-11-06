// Main menu backdrop (MainMenu.gd). Two uses:
//   overlay = false: deep-space ground — a dark top-to-bottom gradient, a soft
//                    blue glow behind the planet and a faint warm glow from the
//                    off-screen sun.
//   overlay = true:  a vignette laid over everything (planet included), black
//                    with alpha, darkest in the corners.
shader_type canvas_item;

uniform bool overlay = false;
uniform float aspect = 1.7778;                          // width / height of the rect
uniform vec4 base_top : source_color = vec4(0.008, 0.010, 0.030, 1.0);
uniform vec4 base_bottom : source_color = vec4(0.012, 0.030, 0.062, 1.0);
uniform vec2 glow_pos = vec2(0.80, 0.98);               // behind the planet (UV)
uniform vec4 glow_col : source_color = vec4(0.12, 0.42, 0.70, 1.0);
uniform float glow_radius = 0.62;
uniform float glow_strength = 0.30;
uniform vec2 warm_pos = vec2(0.02, -0.05);              // the sun, off screen top-left
uniform vec4 warm_col : source_color = vec4(0.60, 0.36, 0.20, 1.0);
uniform float warm_strength = 0.09;
uniform float vignette = 0.62;                          // corner darkness (overlay)

void fragment() {
	if (overlay) {
		vec2 v = (UV - 0.5) * vec2(1.15, 1.0);
		float k = smoothstep(0.32, 0.92, length(v));
		COLOR = vec4(0.0, 0.0, 0.0, k * vignette);
	} else {
		vec3 c = mix(base_top.rgb, base_bottom.rgb, UV.y);
		vec2 d = (UV - glow_pos) * vec2(aspect, 1.0);
		c += glow_col.rgb * glow_strength * exp(-dot(d, d) / (glow_radius * glow_radius));
		vec2 w = (UV - warm_pos) * vec2(aspect, 1.0);
		c += warm_col.rgb * warm_strength * exp(-dot(w, w) / 0.45);
		COLOR = vec4(c, 1.0);
	}
}
