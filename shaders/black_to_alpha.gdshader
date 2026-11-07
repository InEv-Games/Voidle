// A logo drawn on solid black, shown over anything: black turns clear and the
// colours keep their look (the inverse of compositing it over black).
shader_type canvas_item;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float a = max(max(c.r, c.g), c.b);
	COLOR = vec4(c.rgb / max(a, 0.0001), a * c.a) * COLOR;
}
