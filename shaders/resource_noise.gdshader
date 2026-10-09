shader_type canvas_item;

// Bakes a planet's natural-resource noise fields into an equirectangular map
// (ResourceMap.gd). Values only need to agree with ResourceMap itself — the
// lens overlay is drawn from the same baked data — so this is free to differ
// from the terrain noise.
//
// layer 0: R = geothermal ridge, G = mineral 0, B = mineral 1
// layer 1: R = mineral 2,       G = mineral 3, B = mineral 4
// layer 2: R = storm tracks (wind noise)

uniform int seed  = 12345;
uniform int layer = 0;

vec3 hash3(vec3 p) {
	float s = float(seed) * 0.0013 + 17.0;
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

// Deposit field: patchy blobs, 0..1.
float mineral(vec3 rn, float k) {
	float f = fbm3(rn * 2.2 + vec3(k * 17.3, k * 5.1, -k * 9.7), 4) * 0.5 + 0.5;
	return smoothstep(0.38, 0.72, f);
}

void fragment() {
	float lon = UV.x * TAU;
	float lat = (0.5 - UV.y) * PI;
	vec3 rn = vec3(sin(lon) * cos(lat), -sin(lat), cos(lon) * cos(lat));
	if (layer == 0) {
		// thin ridges along "fault lines"
		float ridge = 1.0 - abs(fbm3(rn * 2.6 + vec3(41.0), 5));
		COLOR = vec4(pow(ridge, 6.0), mineral(rn, 0.0), mineral(rn, 1.0), 1.0);
	} else if (layer == 1) {
		COLOR = vec4(mineral(rn, 2.0), mineral(rn, 3.0), mineral(rn, 4.0), 1.0);
	} else {
		// broad, smooth storm tracks — stretched east-west like real jet streams
		vec3 q = rn * vec3(1.2, 3.2, 1.2) + vec3(91.0);
		COLOR = vec4(fbm3(q, 3) * 0.5 + 0.5, 0.0, 0.0, 1.0);
	}
}
