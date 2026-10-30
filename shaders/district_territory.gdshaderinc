// District territories — pixel regions on the planet surface owned by each
// surface district. Shared by the planet shaders; include it after noise3(),
// rot_x(), rot_y() and the aspect_ratio / planet_radius / tilt /
// rotation_offset uniforms are declared.
//
// Ownership must stay in sync with PlanetaryView._territory_owner() (GDScript),
// which hit-tests the same regions for hover and click.

#define MAX_DISTRICTS 128

uniform vec4 district_pos[MAX_DISTRICTS];  // xyz = world-space centre normal, w = angular radius (rad)
uniform vec4 district_col[MAX_DISTRICTS];  // rgb = territory colour, a = night-light intensity 0..1
uniform float district_sea[MAX_DISTRICTS]; // 1 = district built on water (platforms)
// Settlements stretch along the roads / sea lanes leaving them. Up to
// MAX_SPOKES per district: xyz = unit tangent (at the district) pointing down a
// road, w = 0..1 how far it has grown that way (grows with the district after
// the road appeared). Must match PlanetaryView (SPOKE_* constants).
#define MAX_SPOKES 4
uniform vec4 district_spokes[MAX_DISTRICTS * MAX_SPOKES];
const float SPOKE_STRETCH = 1.6;   // extra reach along a road (× radius)
const float SPOKE_SHARP   = 12.0;  // how narrow the stretched lobe is
// Alt held: every district's border is shown (set from PlanetaryView).
uniform float show_all_borders = 0.0;
uniform int  district_count    = 0;
uniform int  district_hover    = -1;
uniform int  district_selected = -1;
// Borders fade in only once zoomed in (set from PlanetaryView).
uniform float border_alpha     = 1.0;
// 0..1: territories (sprawl, lights, borders) grow out from their centres —
// animated when the view switches to another body.
uniform float district_reveal  = 1.0;

// Resource lens overlay (ResourceMap.lens_texture): equirectangular RGBA,
// alpha = strength. lens_alpha 0 = off.
uniform sampler2D lens_tex : filter_linear, repeat_enable;
uniform float lens_alpha = 0.0;

// Radius multiplier for district i toward rn: 1 off-road, up to 1+STRETCH along a spoke.
float spoke_stretch(int i, vec3 rn, vec3 c) {
	vec3 t = rn - c * dot(rn, c);
	float tl = length(t);
	if (tl < 0.00001) return 1.0;
	t /= tl;
	float best = 0.0;
	for (int k = 0; k < MAX_SPOKES; k++) {
		vec4 s = district_spokes[i * MAX_SPOKES + k];
		if (s.w > 0.0) best = max(best, s.w * pow(max(dot(t, s.xyz), 0.0), SPOKE_SHARP));
	}
	return 1.0 + SPOKE_STRETCH * best;
}

// Owner of a world-space surface point: the district with the smallest
// noise-warped normalised distance, if < 1 (-1 = unclaimed). Owners only decide
// borders, hover and tint — the sprawl itself is drawn from that smallest
// distance, i.e. the union of all settlements, so merged cities stay merged
// and a new district never removes built-up ground.
int district_owner_raw(vec3 rn, out float score) {
	score = 2.0;
	if (district_count <= 0) return -1;
	int owner = -1;
	float warp = noise3(rn * 22.0) * 0.18;   // ragged, organic edges
	for (int i = 0; i < MAX_DISTRICTS; i++) {
		if (i >= district_count) break;
		vec4 d = district_pos[i];
		float ang = acos(clamp(dot(rn, d.xyz), -1.0, 1.0));
		float s = ang / max(d.w * spoke_stretch(i, rn, d.xyz), 0.0001) + warp;
		if (s < score) { score = s; owner = i; }
	}
	return score < 1.0 ? owner : -1;
}

// Owner with exclaves dropped: a point only belongs to its district if every
// check point on the way back to the district centre belongs to it too, so each
// territory is one piece reachable from its centre. Detached patches (cut off
// by a neighbour, or stretched out along a sea lane) are unclaimed.
#define EXCLAVE_CHECKS 6
int district_owner(vec3 rn, out float score) {
	int owner = district_owner_raw(rn, score);
	if (owner < 0) return -1;
	if (district_reveal < 1.0) {
		score /= max(district_reveal, 0.001);   // shrink every territory towards its centre
		if (score >= 1.0) { score = 2.0; return -1; }
	}
	vec3 c = district_pos[owner].xyz;
	float s2;
	for (int k = 1; k <= EXCLAVE_CHECKS; k++) {
		float t = float(k) / float(EXCLAVE_CHECKS + 1);
		if (district_owner_raw(normalize(mix(c, rn, t)), s2) != owner) {
			score = 2.0;
			return -1;
		}
	}
	return owner;
}

// World-space surface point under a (pixel-snapped) UV, untilted spin only.
bool territory_uv_to_world(vec2 uvp, out vec3 rn) {
	vec2 c = uvp - vec2(0.5);
	c.x *= aspect_ratio;
	vec2 nv = c / planet_radius;
	float r2 = dot(nv, nv);
	if (r2 > 1.0) { rn = vec3(0.0); return false; }
	rn = rot_y(rot_x(vec3(nv, sqrt(1.0 - r2)), tilt), rotation_offset);
	return true;
}

// True when any 4-neighbour pixel belongs to a different owner — a 1-pixel border.
bool territory_is_border(vec2 uvp, vec2 px, int owner) {
	vec2 offs[4] = vec2[4](vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
	for (int k = 0; k < 4; k++) {
		vec3 nrn;
		float s;
		int o = territory_uv_to_world(uvp + offs[k], nrn) ? district_owner(nrn, s) : -1;
		if (o != owner) return true;
	}
	return false;
}

// Whether a district's border is drawn: hovered, selected, or Alt held.
bool territory_border_on(int owner) {
	return owner == district_hover || owner == district_selected || show_all_borders > 0.5;
}

// Border colour strength.
float territory_border_strength(int owner) {
	if (owner == district_selected) return border_alpha;
	if (owner == district_hover)    return 0.75 * border_alpha;
	return 0.6 * border_alpha;   // Alt overview
}

// Lens colour at a world-space surface point.
vec4 lens_sample(vec3 rn) {
	float lon = atan(rn.x, rn.z);
	float lat = asin(clamp(-rn.y, -1.0, 1.0));
	return texture(lens_tex, vec2(fract(lon / TAU), 0.5 - lat / PI));
}

// Applies the lens on top of the lit surface: the terrain dims, the resource
// colour shows at full strength day or night.
vec3 apply_lens(vec3 surf, vec3 rn) {
	if (lens_alpha <= 0.0) return surf;
	vec4 lv = lens_sample(rn);
	vec3 dimmed = surf * mix(1.0, 0.45, lens_alpha);
	return mix(dimmed, lv.rgb, lv.a * lens_alpha);
}

// Visible surface features (FeatureMap.texture, equirectangular RGBA8):
//   R land cover 1 forest · 2 desert · 3 tundra · 4 volcanic · 5 caves · 6 ion storm (Moon)
//   G lines      1 river  · 2 geothermal rift
//   B spots      1 crater floor · 2 crater rim · 3 ruins
//   A unused (was the windy region, no longer a feature)
// The economy reads the same grid, so what is drawn is what counts.
uniform sampler2D feature_tex : filter_nearest, repeat_enable;
uniform float feature_on = 0.0;

ivec4 feature_sample(vec3 rn) {
	float lon = atan(rn.x, rn.z);
	float lat = asin(clamp(-rn.y, -1.0, 1.0));
	vec4 f = texture(feature_tex, vec2(fract(lon / TAU), 0.5 - lat / PI));
	return ivec4(round(f * 255.0));
}

float feature_hash(vec3 cell, vec3 k) {
	return fract(sin(dot(cell, k)) * 43758.5453);
}

// How strongly features are painted (PlanetaryView: soft by default, stronger
// while a role lens is on). 0 hides them.
uniform float feature_strength = 0.5;
uniform sampler2D river_tex : filter_linear, repeat_enable;
uniform float river_on = 0.0;
// 0 when zoomed out (rivers hidden) … 1 close up (PlanetaryView, by zoom).
uniform float river_vis = 1.0;
// 1 while the Energy role lens is on: windy regions are drawn only then.
uniform float wind_vis = 0.0;
// Wind strength per cell (FeatureMap.wind_texture, the sites' "Wind %").
uniform sampler2D wind_tex : filter_linear, repeat_enable;
uniform float wind_on = 0.0;

// How much river (water and the bank right next to it) covers a point,
// whatever the zoom — settlements leave it free (planet_rocky.gdshader).
float river_cover(vec3 rn) {
	if (river_on <= 0.0) return 0.0;
	float lon = atan(rn.x, rn.z);
	float lat = asin(clamp(-rn.y, -1.0, 1.0));
	vec2 rv = texture(river_tex, vec2(fract(lon / TAU), 0.5 - lat / PI)).rg;
	return max(smoothstep(0.15, 0.6, rv.r), smoothstep(0.55, 0.9, rv.g));
}

// Soft coverage of every feature around a point: a jittered 3×3 tap average of
// the grid, so edges fade over about a cell instead of stepping.
//   cover  forest, desert, tundra, volcanic · lines river, rift
//   spots  crater floor, crater rim, ruins  · lunar  caves, ion storm
void feature_cover(vec3 rn, out vec4 cover, out vec2 lines, out vec3 spots, out vec2 lunar) {
	float lon = atan(rn.x, rn.z);
	float lat = asin(clamp(-rn.y, -1.0, 1.0));
	vec2 uv = vec2(fract(lon / TAU), 0.5 - lat / PI);
	vec2 px = 1.0 / vec2(textureSize(feature_tex, 0));
	vec3 cell = floor(rn * 300.0);
	vec2 jit = (vec2(feature_hash(cell, vec3(1.3, 7.7, 4.1)), feature_hash(cell, vec3(9.1, 2.3, 6.7))) - 0.5) * px;
	cover = vec4(0.0);
	lines = vec2(0.0);
	spots = vec3(0.0);
	lunar = vec2(0.0);
	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			vec2 o = vec2(float(dx), float(dy)) * px * 1.25 + jit;
			ivec4 f = ivec4(round(texture(feature_tex, uv + o) * 255.0));
			float w = (dx == 0 && dy == 0) ? 2.0 : 1.0;   // weights add up to 10
			cover += w * vec4(f.r == 1 ? 1.0 : 0.0, f.r == 2 ? 1.0 : 0.0, f.r == 3 ? 1.0 : 0.0, f.r == 4 ? 1.0 : 0.0);
			lines += w * vec2(f.g == 1 ? 1.0 : 0.0, f.g == 2 ? 1.0 : 0.0);
			spots += w * vec3(f.b == 1 ? 1.0 : 0.0, f.b == 2 ? 1.0 : 0.0, f.b == 3 ? 1.0 : 0.0);
			lunar += w * vec2(f.r == 5 ? 1.0 : 0.0, f.r == 6 ? 1.0 : 0.0);
		}
	}
	cover /= 10.0;
	lines /= 10.0;
	spots /= 10.0;
	lunar /= 10.0;
}

// Paints the features onto the (unlit) surface — muted tints that blend into
// the terrain. `land` is 1 where land shows; `t` is TIME (wind streaks drift).
vec3 apply_features(vec3 surf, vec3 rn, float land, float t) {
	if (feature_on <= 0.0 || feature_strength <= 0.0) return surf;
	vec4 cover; vec2 lines; vec3 spots; vec2 lunar;
	feature_cover(rn, cover, lines, spots, lunar);
	float k = feature_strength * land;
	vec4 c = smoothstep(vec4(0.05), vec4(0.85), cover);
	// forest: a darker green, in clumps
	float clump = feature_hash(floor(rn * 220.0), vec3(12.9898, 78.233, 37.719));
	surf = mix(surf, surf * vec3(0.55, 0.80, 0.55) * (0.9 + 0.2 * clump), c.x * 0.8 * k);
	// desert: warm sand, gentle dune bands
	float dune = 0.5 + 0.5 * sin(dot(rn, vec3(90.0, 30.0, 60.0)));
	surf = mix(surf, mix(vec3(0.62, 0.56, 0.42), vec3(0.70, 0.63, 0.47), dune), c.y * 0.7 * k);
	// tundra: paler, cooler
	surf = mix(surf, mix(surf, vec3(0.55, 0.58, 0.54), 0.6), c.z * k);
	// volcanic field: dark basalt, a few faint glowing cracks
	float crack = smoothstep(0.94, 1.0, feature_hash(floor(rn * 180.0), vec3(7.1, 113.3, 41.9)));
	surf = mix(surf, vec3(0.20, 0.17, 0.16), c.w * 0.75 * k);
	surf += vec3(0.8, 0.25, 0.05) * crack * c.w * 0.35 * k;
	// rivers: their own finer texture (FeatureMap.river_texture), smooth lines
	// with a soft water edge and a greener bank; clear even at the soft strength
	if (river_on > 0.0 && river_vis > 0.0) {
		float rlon = atan(rn.x, rn.z);
		float rlat = asin(clamp(-rn.y, -1.0, 1.0));
		vec2 rv = texture(river_tex, vec2(fract(rlon / TAU), 0.5 - rlat / PI)).rg;
		float rs = max(feature_strength, 0.75);
		rs *= river_vis;
		surf = mix(surf, surf * vec3(0.84, 1.02, 0.82) + vec3(0.0, 0.02, 0.0), rv.g * 0.4 * rs * land);
		float shimmer = 0.03 * sin(t * 1.6 + dot(rn, vec3(140.0, 60.0, 95.0)));
		// across the beach the river thins out into the sea's own colour
		float inland = smoothstep(0.0, 1.0, land);
		surf = mix(surf, vec3(0.20, 0.42, 0.62) + shimmer, smoothstep(0.30, 0.80, rv.r) * 0.9 * rs * inland);
	}
	surf = mix(surf, vec3(0.85, 0.40, 0.15), smoothstep(0.25, 0.7, lines.y) * 0.6 * feature_strength);
	// spots
	surf *= 1.0 - smoothstep(0.2, 0.8, spots.x) * 0.3 * feature_strength;
	surf = mix(surf, vec3(0.66, 0.63, 0.58), smoothstep(0.2, 0.8, spots.y) * 0.4 * feature_strength);
	float blk = step(0.45, feature_hash(floor(rn * 260.0), vec3(3.7, 91.1, 17.3)));
	surf = mix(surf, vec3(0.58, 0.54, 0.46), smoothstep(0.2, 0.8, spots.z) * 0.6 * blk * feature_strength);
	// Moon-only: caves as dark pitted ground, ion storm regions as a faint
	// shifting blue-violet glow
	vec2 l = smoothstep(vec2(0.05), vec2(0.85), lunar);
	float pit = step(0.6, feature_hash(floor(rn * 240.0), vec3(5.3, 61.7, 29.9)));
	surf = mix(surf, surf * 0.45, l.x * (0.55 + 0.35 * pit) * feature_strength);
	float storm = 0.5 + 0.5 * sin(t * 0.8 + dot(rn, vec3(45.0, 80.0, 25.0)));
	surf = mix(surf, vec3(0.45, 0.50, 0.95), l.y * (0.35 + 0.25 * storm) * feature_strength);
	return surf;
}

// Energy lens: windy regions as bright wind lines flowing east, drawn on top
// of the lens (after its dimming) so they read clearly. Only while wind_vis is on.
vec3 apply_wind_lens(vec3 surf, vec3 rn, float t) {
	if (wind_vis <= 0.0 || wind_on <= 0.0) return surf;
	float lon = atan(rn.x, rn.z);
	float lat = asin(clamp(-rn.y, -1.0, 1.0));
	// stronger wind → denser, brighter currents (from about 35% up; full at 75%)
	float wind = texture(wind_tex, vec2(fract(lon / TAU), 0.5 - lat / PI)).r;
	float region = smoothstep(0.35, 0.75, wind);
	if (region <= 0.0) return surf;
	// long, gently wavy currents moving east; noise breaks them into gusts
	float wave = lat * 26.0 + sin(lon * 7.0 + t * 0.4) * 0.6;
	float band = 1.0 - abs(fract(wave) * 2.0 - 1.0);
	band = smoothstep(0.80, 0.97, band);
	float gust = fbm3(vec3(lon * 6.0 - t * 0.9, lat * 10.0, 3.7), 3);
	gust = smoothstep(-0.05, 0.25, gust);
	// a faint tint marks the whole region, the currents sit on top
	surf = mix(surf, vec3(0.70, 0.86, 0.95), 0.12 * region * wind_vis);
	surf = mix(surf, vec3(0.90, 0.97, 1.0), band * gust * 0.75 * region * wind_vis);
	return surf;
}
