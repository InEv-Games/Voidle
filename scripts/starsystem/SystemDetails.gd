## Details of a star system — its "biomes": asteroid clusters and nebulae.
## (Development: Mechanic-Test/Star-Map.)
##
## Made from the system's seed, the same every time (nothing is saved). They
## sit in small patches, never a whole orbit: an asteroid cluster on a short arc
## between two planets' orbits (the system's asteroid_belt_slots first), a
## nebula as a cloud in open space. Both are placed where they stay clear of
## the planets (the angle with the most room of a few tries).
##
## Plane units are StarSystemView's (orbit i at orbit_base + orbit_step × i).
## Each detail: { kind, name, center (plane), … }
##   asteroids: r, w (half width), a (centre angle), span, rocks [{ r, a, s, shade }]
##   nebula:    radius, height, color, blobs [{ off, h, r, k, elong, rot, col }]
##              a volume, not a disc: every puff has a height off the plane (h)
##              and its own stretch / turn / tint, so the cloud has a shape.
class_name SystemDetails
extends RefCounted

const ASTEROID_NAMES_A := ["Kerr", "Vasa", "Orin", "Halden", "Ishi", "Morrow", "Tamsin", "Corvo", "Lysa", "Bram"]
const ASTEROID_NAMES_B := ["Drift", "Shoal", "Reach", "Scatter", "Shards", "Cluster"]
const NEBULA_NAMES_A := ["Ashen", "Veyra", "Saffron", "Halcyon", "Mire", "Cinder", "Opal", "Lumen", "Tide", "Hollow"]
const NEBULA_NAMES_B := ["Nebula", "Veil", "Cloud", "Shroud"]
const NEBULA_COLORS: Array[Color] = [
	Color(0.62, 0.38, 1.00),   # violet
	Color(0.25, 0.85, 0.85),   # teal
	Color(1.00, 0.42, 0.62),   # rose
	Color(1.00, 0.70, 0.30),   # amber
	Color(0.40, 0.60, 1.00),   # blue
]


static func generate(sd: SolarData, planet_pos: Array[Vector2], orbit_base: float, orbit_step: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var n := planet_pos.size()
	if n < 2:
		return out
	var rng := RandomNumberGenerator.new()
	rng.seed = sd.seed ^ 0xA57E
	var outer := orbit_base + orbit_step * float(n - 1)
	var used: Array = []

	# ── asteroid clusters: 2–3, each between two neighbouring orbits ──
	var slots: Array[int] = []
	for sl: int in sd.asteroid_belt_slots:
		if sl >= 0 and sl <= n - 2 and not (sl in slots):
			slots.append(sl)
	var want := rng.randi_range(2, 3)
	var tries := 0
	while slots.size() < want and tries < 20:
		var sl := rng.randi_range(0, n - 2)
		if not (sl in slots):
			slots.append(sl)
		tries += 1
	for sl: int in slots.slice(0, want):
		var r := orbit_base + orbit_step * (float(sl) + 0.5)
		var span := rng.randf_range(0.35, 0.7)
		var a := _roomiest_angle(rng, r, planet_pos, 0.0)
		var w := orbit_step * rng.randf_range(0.12, 0.2)
		var rocks: Array[Dictionary] = []
		for k in rng.randi_range(28, 46):
			# thicker in the middle: the sum of two randoms
			var ra := a + (rng.randf() + rng.randf() - 1.0) * span * 0.5
			var rr := r + (rng.randf() + rng.randf() - 1.0) * w
			rocks.append({"r": rr, "a": ra, "s": rng.randf_range(1.2, 3.8), "shade": rng.randf_range(0.55, 1.0)})
		out.append({"kind": "asteroids", "name": _name(rng, ASTEROID_NAMES_A, ASTEROID_NAMES_B, used),
			"r": r, "w": w, "a": a, "span": span, "rocks": rocks,
			"center": Vector2(cos(a), sin(a)) * r})

	# ── nebulae: 1–2 clouds in open space ──
	for k in rng.randi_range(1, 2):
		# sizes vary a lot: most are small, about a third are big clouds
		var radius := rng.randf_range(55.0, 110.0) * (rng.randf_range(1.7, 2.4) if rng.randf() < 0.35 else 1.0)
		var best := Vector2.ZERO
		var best_room := -INF
		for t in 16:
			var cr := rng.randf_range(orbit_base * 1.3, outer * 1.12)
			var ca := rng.randf_range(0.0, TAU)
			var c := Vector2(cos(ca), sin(ca)) * cr
			var room := _room(c, planet_pos) - radius
			for d: Dictionary in out:
				room = minf(room, c.distance_to(d["center"]) - radius - 60.0)
			if room > best_room:
				best_room = room
				best = c
		var col: Color = NEBULA_COLORS[rng.randi() % NEBULA_COLORS.size()]
		var col2: Color = NEBULA_COLORS[rng.randi() % NEBULA_COLORS.size()]
		var height := radius * rng.randf_range(0.35, 0.6)
		# the cloud's own shape: a lopsided body along a random axis, a dense
		# core, a few long wisps trailing off it
		var axis := rng.randf_range(0.0, TAU)
		var stretch := rng.randf_range(1.3, 2.0)
		var blobs: Array[Dictionary] = []
		for b in rng.randi_range(14, 20):
			var core := b < 4
			var ang := rng.randf_range(0.0, TAU)
			var dist := sqrt(rng.randf()) * radius * (0.25 if core else 0.75)
			var off := Vector2(cos(ang) * stretch, sin(ang)) * dist / stretch
			off = off.rotated(axis)
			blobs.append({"off": off,
				"h": (rng.randf() + rng.randf() - 1.0) * height * (0.4 if core else 1.0),
				"r": radius * (rng.randf_range(0.35, 0.55) if core else rng.randf_range(0.25, 0.6)),
				"k": rng.randf_range(0.22, 0.34) if core else rng.randf_range(0.10, 0.24),
				"elong": rng.randf_range(1.0, 1.4) if core else rng.randf_range(1.2, 2.6),
				"rot": axis + rng.randf_range(-0.6, 0.6),
				"col": col.lerp(col2, rng.randf() * 0.6).lerp(Color.WHITE, 0.25 if core else 0.0)})
		out.append({"kind": "nebula", "name": _name(rng, NEBULA_NAMES_A, NEBULA_NAMES_B, used),
			"radius": radius, "height": height, "color": col, "blobs": blobs, "center": best})
	return out


## Of a few angles on circle r, the one farthest from every planet (+ jitter).
static func _roomiest_angle(rng: RandomNumberGenerator, r: float, planet_pos: Array[Vector2], _pad: float) -> float:
	var best := 0.0
	var best_room := -INF
	for t in 24:
		var a := TAU * float(t) / 24.0 + rng.randf_range(-0.1, 0.1)
		var room := _room(Vector2(cos(a), sin(a)) * r, planet_pos)
		if room > best_room:
			best_room = room
			best = a
	return fposmod(best, TAU)


static func _room(p: Vector2, planet_pos: Array[Vector2]) -> float:
	var m := INF
	for q: Vector2 in planet_pos:
		m = minf(m, p.distance_to(q))
	return m


## A name whose first word no other detail of this system uses.
static func _name(rng: RandomNumberGenerator, a: Array, b: Array, used: Array) -> String:
	var first: String = a[rng.randi() % a.size()]
	for t in a.size():
		if not (first in used):
			break
		first = a[(a.find(first) + 1) % a.size()]
	used.append(first)
	return "%s %s" % [first, b[rng.randi() % b.size()]]
