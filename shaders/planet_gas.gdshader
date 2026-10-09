shader_type canvas_item;

uniform float rotation_offset    : hint_range(0.0, 6.2832) = 0.0;
// Camera tilt around the screen X axis (radians). + shows the north pole.
uniform float tilt = 0.0;
// 0 = night side fully lit, 1 = full day/night shadow (player setting).
uniform float night_shadow : hint_range(0.0, 1.0) = 1.0;
uniform float cloud_speed        : hint_range(0.0, 2.0)    = 0.10;
uniform float atmosphere_density : hint_range(0.0, 3.0)    = 2.0;
uniform float terrain_roughness  : hint_range(0.2, 2.0)    = 0.6;
uniform float planet_radius      : hint_range(0.1, 0.5)    = 0.44;
uniform float pixel_count        : hint_range(32.0, 512.0) = 140.0;
uniform float aspect_ratio       : hint_range(0.1, 4.0)    = 1.0;
uniform int   seed               : hint_range(0, 99999)    = 12345;

uniform vec3 color_band_a    = vec3(0.72, 0.55, 0.35);
uniform vec3 color_band_b    = vec3(0.50, 0.32, 0.18);
uniform vec3 color_storm     = vec3(0.85, 0.70, 0.50);
uniform vec3 color_atmosphere = vec3(0.72, 0.55, 0.35);
uniform vec3 light_direction  = vec3(0.6, -0.55, 0.65);

vec3 hash3(vec3 p) {
	float s = float(seed) * 0.001;
	p = vec3(dot(p, vec3(127.1+s,311.7,74.7)),
	         dot(p, vec3(269.5+s,183.3,246.1)),
	         dot(p, vec3(113.5,271.9,124.6)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}
float noise3(vec3 p) {
	vec3 i=floor(p); vec3 f=fract(p); vec3 u=f*f*(3.0-2.0*f);
	return mix(mix(mix(dot(hash3(i),             f),
	                   dot(hash3(i+vec3(1,0,0)), f-vec3(1,0,0)),u.x),
	               mix(dot(hash3(i+vec3(0,1,0)), f-vec3(0,1,0)),
	                   dot(hash3(i+vec3(1,1,0)), f-vec3(1,1,0)),u.x),u.y),
	           mix(mix(dot(hash3(i+vec3(0,0,1)), f-vec3(0,0,1)),
	                   dot(hash3(i+vec3(1,0,1)), f-vec3(1,0,1)),u.x),
	               mix(dot(hash3(i+vec3(0,1,1)), f-vec3(0,1,1)),
	                   dot(hash3(i+vec3(1,1,1)), f-vec3(1,1,1)),u.x),u.y),u.z);
}
float fbm3(vec3 p, int oct) {
	float v=0.0,a=0.5,f=1.0;
	for(int i=0;i<oct;i++){v+=a*noise3(p*f);f*=2.0;a*=0.5;}
	return v;
}
vec3 rot_y(vec3 p, float a) {
	float c=cos(a),s=sin(a);
	return vec3(p.x*c+p.z*s, p.y, -p.x*s+p.z*c);
}
vec3 rot_x(vec3 p, float a) { float c=cos(a),s=sin(a); return vec3(p.x, p.y*c-p.z*s, p.y*s+p.z*c); }

#include "res://shaders/district_territory.gdshaderinc"

void fragment() {
	// Square pixels: same cell size on both axes regardless of the rect aspect.
	vec2 grid = vec2(pixel_count * aspect_ratio, pixel_count);
	vec2 uv = floor(UV * grid) / grid;
	vec2 c  = uv - vec2(0.5);
	c.x    *= aspect_ratio;
	float dist = length(c);
	float atmo = planet_radius + 0.030;

	if (dist > atmo) {
		COLOR = vec4(0.0);
	} else if (dist > planet_radius) {
		float t = 1.0 - (dist - planet_radius) / 0.030;
		float g = pow(t, 2.0) * atmosphere_density;
		COLOR = vec4(color_atmosphere * g * 0.6, clamp(g * 0.5, 0.0, 1.0));
	} else {
		float nx = c.x / planet_radius;
		float ny = c.y / planet_radius;
		float nz = sqrt(max(0.0, 1.0 - nx*nx - ny*ny));
		vec3  n  = normalize(vec3(nx, ny, nz));
		vec3 tn = rot_x(n, tilt);   // view → world: tilt first, then spin
		float lat = asin(clamp(tn.y, -1.0, 1.0));

		// bands: distorted horizontal stripes with turbulence
		vec3 rn = rot_y(tn, rotation_offset + TIME * cloud_speed);
		float turbulence = fbm3(rn * 3.0 * terrain_roughness, 5) * 0.3;
		float band = sin((lat + turbulence) * 8.0);

		vec3 surf = mix(color_band_b, color_band_a, band * 0.5 + 0.5);

		// storm spots
		float storm = fbm3(rn * 5.0, 4);
		float storm_mask = smoothstep(0.25, 0.32, storm);
		surf = mix(surf, color_storm, storm_mask * 0.6);

		// detail layer
		surf += vec3(fbm3(rn * 10.0, 3) * 0.06 - 0.03);

		// district territory tint
		vec3 d_rn;
		float d_score = 2.0;
		int d_owner = territory_uv_to_world(uv, d_rn) ? district_owner(d_rn, d_score) : -1;
		vec3 d_col = d_owner >= 0 ? district_col[d_owner].rgb : vec3(0.0);
		if (d_owner >= 0)
			surf = mix(surf, vec3(0.55, 0.53, 0.50), 0.18 * smoothstep(1.0, 0.3, d_score));

		// limb darkening
		float limb = pow(nz, 0.4);
		vec3  ld   = normalize(light_direction);
		float diff = max(dot(n, ld), 0.0);
		float lit  = smoothstep(0.0, 0.5, diff) * limb;
		surf *= mix(0.08 + 0.92 * limb, 0.08 + 0.92 * lit, night_shadow);

		surf = apply_lens(surf, d_rn);

		// territory border — after lighting so it stays readable at night
		if (d_owner >= 0 && territory_border_on(d_owner)
				&& territory_is_border(uv, 1.0 / grid, d_owner))
			surf = mix(surf, d_col * 1.2 + vec3(0.12), territory_border_strength(d_owner));


		COLOR = vec4(clamp(surf, vec3(0.0), vec3(1.0)), 1.0);
	}
}
