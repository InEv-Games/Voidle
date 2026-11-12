// New Game's preview swapping one look for another (SessionPrep._Preview): what
// is under the rect blurs as `progress` goes 0 → 1 (the look itself fades with
// it, from the script), and sharpens again as it goes back to 0. Laid over the
// preview's square after a BackBufferCopy. Its edges are soft, so the blurred
// part blends into the sharp space around it.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float max_radius = 2.0;   // blur reach at full progress (physical pixels): a focus pull
uniform float max_lod = 1.0;       // …and the mip level it samples from (kept low: a mip is a blur too)
uniform float edge_soft = 0.12;    // share of the rect the blur fades out over at its sides

void fragment() {
	float p = progress;
	vec2 r = SCREEN_PIXEL_SIZE * max_radius * p;
	float lod = max_lod * p;
	// a centre tap and two rings of eight (the outer one turned half a step)
	vec3 acc = textureLod(screen_tex, SCREEN_UV, lod).rgb * 0.2;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398;
		acc += textureLod(screen_tex, SCREEN_UV + vec2(cos(a), sin(a)) * r * 0.5, lod).rgb * 0.06;
		float b = a + 0.392699;
		acc += textureLod(screen_tex, SCREEN_UV + vec2(cos(b), sin(b)) * r, lod).rgb * 0.04;
	}
	float side = smoothstep(0.0, edge_soft, UV.x) * smoothstep(0.0, edge_soft, 1.0 - UV.x)
		* smoothstep(0.0, edge_soft, UV.y) * smoothstep(0.0, edge_soft, 1.0 - UV.y);
	COLOR = vec4(acc, side * smoothstep(0.0, 0.15, p));
}
