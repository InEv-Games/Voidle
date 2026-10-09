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
uniform int  district_count    = 0;
uniform int  district_hover    = -1;
uniform int  district_selected = -1;
// Borders fade in only once zoomed in (set from PlanetaryView).
uniform float border_alpha     = 1.0;

#define MAX_ROADS 16
// Roads between neighbouring districts: each entry = (index a, index b) into district_pos.
uniform vec2 district_roads[MAX_ROADS];
uniform int  road_count = 0;

// Owner of a world-space surface point: the district with the smallest
// noise-warped normalised distance, if that distance is < 1. -1 = unclaimed.
// Overlapping districts split the overlap along a shared border.
int district_owner(vec3 rn, out float score) {
	score = 2.0;
	if (district_count <= 0) return -1;
	int owner = -1;
	float warp = noise3(rn * 22.0) * 0.18;   // ragged, organic edges
	for (int i = 0; i < MAX_DISTRICTS; i++) {
		if (i >= district_count) break;
		vec4 d = district_pos[i];
		float ang = acos(clamp(dot(rn, d.xyz), -1.0, 1.0));
		float s = ang / max(d.w, 0.0001) + warp;
		if (s < score) { score = s; owner = i; }
	}
	return score < 1.0 ? owner : -1;
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

// Border colour strength (borders only draw while hovered or selected).
float territory_border_strength(int owner) {
	return (owner == district_selected ? 1.0 : 0.75) * border_alpha;
}

// ── Roads ────────────────────────────────────────────────────────────────────
// Roads follow the great circle between two neighbouring districts and meander
// like rivers (world-space noise, two octaves). The meander tapers to zero at
// both ends so the road always meets the settlements. Over water a road becomes
// a dashed sea lane with little ships sailing it (see planet_rocky.gdshader).

float road_wiggle(vec3 p, int i, float arc, float t) {
	// amplitude scales with length but is capped, so long inter-system roads
	// meander like the short ones instead of swinging across the continent
	return (noise3(p * 6.0  + vec3(float(i) * 3.7)) * 0.65
	      + noise3(p * 17.0 + vec3(float(i) * 1.3)) * 0.35) * min(arc * 0.55, 0.06) * sin(PI * t);
}

// Point on road i at parameter t (0 = district a, 1 = district b).
vec3 road_point(vec3 a, vec3 b, vec3 nrm, float arc, int i, float t) {
	vec3 p = normalize(a * sin((1.0 - t) * arc) + b * sin(t * arc));
	return normalize(p + nrm * road_wiggle(p, i, arc, t));
}

// (hit 0/1, t along the road, road arc length in radians).
// half_w = half the road width in radians (≈ a fraction of one screen pixel).
vec3 road_info(vec3 rn, float half_w) {
	for (int i = 0; i < MAX_ROADS; i++) {
		if (i >= road_count) break;
		vec3 a = district_pos[int(district_roads[i].x)].xyz;
		vec3 b = district_pos[int(district_roads[i].y)].xyz;
		vec3 plane = cross(a, b);
		float pl = length(plane);
		if (pl < 0.0001) continue;
		float ab = dot(a, b);
		if (dot(rn, a) < ab || dot(rn, b) < ab) continue;     // outside the segment
		float arc = acos(clamp(ab, -1.0, 1.0));
		vec3  nrm = plane / pl;
		float off = dot(rn, nrm);
		// Meander is sampled on the great circle (rn projected onto it), so the
		// road has constant width and ships (road_point) sit exactly on it.
		vec3  p0  = normalize(rn - nrm * off);
		float t   = clamp(acos(clamp(dot(p0, a), -1.0, 1.0)) / arc, 0.0, 1.0);
		if (abs(off - road_wiggle(p0, i, arc, t)) < half_w)
			return vec3(1.0, t, arc);
	}
	return vec3(0.0);
}

// 1 where a ship sits: two per road, sailing opposite ways at a steady pace.
float ship_mask(vec3 rn, float half_w, float time) {
	for (int i = 0; i < MAX_ROADS; i++) {
		if (i >= road_count) break;
		vec3 a = district_pos[int(district_roads[i].x)].xyz;
		vec3 b = district_pos[int(district_roads[i].y)].xyz;
		vec3 plane = cross(a, b);
		float pl = length(plane);
		if (pl < 0.0001) continue;
		float arc = acos(clamp(dot(a, b), -1.0, 1.0));
		for (int k = 0; k < 2; k++) {
			float ts = fract(time * 0.02 / arc + float(i) * 0.37 + float(k) * 0.5);
			if (k == 1) ts = 1.0 - ts;
			vec3 sp = road_point(a, b, plane / pl, arc, i, ts);
			if (dot(rn, sp) > cos(half_w)) return 1.0;
		}
	}
	return 0.0;
}
