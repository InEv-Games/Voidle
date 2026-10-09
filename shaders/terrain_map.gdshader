shader_type canvas_item;

// Bakes a planet's terrain into an equirectangular map for CPU-side queries
// (TerrainMap.gd). The planet shaders run their noise in 32-bit floats; the
// sin()-based hash is chaotic, so GDScript's 64-bit copy (PlanetNoise) does
// not reproduce it. Baking on the GPU gives the exact terrain the player sees.
//
// hash3 / noise3 / fbm3 and the sampling expressions MUST stay identical to
// planet_rocky.gdshader / planet_moon.gdshader / district_territory.gdshaderinc.
//
// Output: R,G = 16-bit terrain value ((v + 2) / 4), B = territory warp noise.
// mode 0 = rocky height fbm (before sea level), 1 = moon mare fbm.

uniform int   seed              = 12345;
uniform float terrain_roughness = 1.0;
uniform float continent_scale   = 1.0;
uniform int   mode              = 0;

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

void fragment() {
	float lon = UV.x * TAU;
	float lat = (0.5 - UV.y) * PI;
	vec3 rn = vec3(sin(lon) * cos(lat), -sin(lat), cos(lon) * cos(lat));

	float v;
	if (mode == 1) {
		vec3 rp = rn * terrain_roughness;
		v = fbm3(rp * 1.8, 4);
	} else {
		v = fbm3(rn * 3.2 * continent_scale * terrain_roughness, 7);
	}
	float e  = clamp((v + 2.0) / 4.0, 0.0, 1.0) * 65535.0;
	float hi = floor(e / 256.0);
	float lo = e - hi * 256.0;
	float w  = noise3(rn * 22.0) * 0.5 + 0.5;
	COLOR = vec4(hi / 255.0, lo / 255.0, w, 1.0);
}
