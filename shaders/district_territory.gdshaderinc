// District territories — pixel regions on the planet surface owned by each
// surface district. Shared by the planet shaders; include it after noise3(),
// rot_x(), rot_y() and the aspect_ratio / planet_radius / tilt /
// rotation_offset uniforms are declared.
//
// Ownership must stay in sync with PlanetaryView._territory_owner() (GDScript),
// which hit-tests the same regions for hover and click.

#define MAX_DISTRICTS 16

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
