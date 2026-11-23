## The home Star Cluster, made from the run's seed (Mechanic-Test/Star-Map).
## Nothing is saved: the same run always gets the same cluster.
##
##   stars:   [{ name, type (SolarData.StarType), seed, pos (plane), h, home }]
##   links:   [Vector2i] — lanes between stars (indices into stars)
##   nebulae: [{ name, center, radius, height, color, blobs [{ off, h, r, k, elong, rot, col }] }]
##
## 16–24 stars. The home system is one of them, not the middle: the cluster's
## core holds a black hole (a landmark to head for), the home star sits out
## towards its edge, so the neighbourhood has a direction. HOME_AT_CENTER
## puts us in the middle instead.
##
## Every star is on the lane network: a spanning tree (no star left out) plus
## lanes to each star's nearest neighbours, so most stars have a few ways on.
class_name ClusterData
extends RefCounted

const HOME_AT_CENTER := false
const RADIUS := 620.0
const MIN_GAP := 75.0
const HEIGHT := 90.0
## Extra lanes: each star links to this many of its nearest (on top of the tree).
const NEAREST_LINKS := 2

const NAMES_A := ["Ves", "Kor", "Thal", "Ny", "Aur", "Sel", "Dra", "Mir", "Ost", "Pel", "Quor", "Zan", "Ery", "Hel", "Lum", "Cas"]
const NAMES_B := ["ara", "ion", "oth", "enna", "ix", "eus", "ora", "ane", "ul", "eth", "is", "ova"]
const NEB_A := ["Ashen", "Veyra", "Saffron", "Halcyon", "Mire", "Cinder", "Opal", "Lumen", "Tide", "Hollow"]
const NEB_B := ["Nebula", "Veil", "Expanse", "Reach"]
const NEB_COLORS: Array[Color] = [Color(0.62, 0.38, 1.0), Color(0.25, 0.85, 0.85),
	Color(1.0, 0.42, 0.62), Color(1.0, 0.70, 0.30), Color(0.40, 0.60, 1.0)]


static func generate(run_seed: int, home: SolarData) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed ^ 0xC1D5
	var stars: Array[Dictionary] = []
	var n := rng.randi_range(16, 24)
	var used_names := {}

	# the core: a black hole in the middle (home there instead if HOME_AT_CENTER)
	var home_pos := Vector2.ZERO
	if not HOME_AT_CENTER:
		var a := rng.randf_range(0.0, TAU)
		home_pos = Vector2(cos(a), sin(a)) * RADIUS * rng.randf_range(0.45, 0.6)
		stars.append(_star(rng, used_names, SolarData.StarType.BLACK_HOLE, Vector2.ZERO, 0.0))
	var home_type: int = home.star_type if home != null else SolarData.StarType.YELLOW_DWARF
	var hs := _star(rng, used_names, home_type, home_pos, 0.0)
	hs["home"] = true
	if home != null:
		hs["name"] = home.system_name
		hs["seed"] = home.seed
	stars.append(hs)

	# the rest, spread out (never too close to another)
	var tries := 0
	while stars.size() < n and tries < 2000:
		tries += 1
		var p := Vector2.from_angle(rng.randf_range(0.0, TAU)) * RADIUS * sqrt(rng.randf())
		var ok := true
		for s: Dictionary in stars:
			if p.distance_to(s["pos"]) < MIN_GAP:
				ok = false
				break
		if not ok:
			continue
		# about one in twelve is a black hole; the rest by the usual odds
		var t: int = SolarData.StarType.BLACK_HOLE if rng.randf() < 0.08 else _roll_type(rng)
		stars.append(_star(rng, used_names, t, p, rng.randf_range(-HEIGHT, HEIGHT)))

	return {"stars": stars, "links": _links(stars), "nebulae": _nebulae(rng, stars)}


static func _star(rng: RandomNumberGenerator, used: Dictionary, type: int, pos: Vector2, h: float) -> Dictionary:
	var nm := ""
	for t in 20:
		nm = NAMES_A[rng.randi() % NAMES_A.size()] + NAMES_B[rng.randi() % NAMES_B.size()]
		if type == SolarData.StarType.BLACK_HOLE:
			nm += " Rift"
		if not used.has(nm):
			break
	used[nm] = true
	return {"name": nm, "type": type, "seed": rng.randi() % 99999, "pos": pos, "h": h, "home": false}


static func _roll_type(rng: RandomNumberGenerator) -> int:
	var r := rng.randi() % 10
	if r < 4: return SolarData.StarType.RED_DWARF
	if r < 7: return SolarData.StarType.YELLOW_DWARF
	if r < 8: return SolarData.StarType.ORANGE_SUBGIANT
	if r < 9: return SolarData.StarType.WHITE_DWARF
	return SolarData.StarType.BLUE_GIANT


## Spanning tree (Prim) + each star to its NEAREST_LINKS nearest: all connected.
static func _links(stars: Array[Dictionary]) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var have := {}
	var n := stars.size()
	var in_tree: Array[bool] = []
	in_tree.resize(n)
	in_tree.fill(false)
	in_tree[0] = true
	for step in n - 1:
		var best := INF
		var bi := -1
		var bj := -1
		for i in n:
			if not in_tree[i]:
				continue
			for j in n:
				if in_tree[j]:
					continue
				var d: float = (stars[i]["pos"] as Vector2).distance_to(stars[j]["pos"])
				if d < best:
					best = d
					bi = i
					bj = j
		if bj < 0:
			break
		in_tree[bj] = true
		_add_link(out, have, bi, bj)
	for i in n:
		var near: Array = []
		for j in n:
			if j != i:
				near.append([(stars[i]["pos"] as Vector2).distance_to(stars[j]["pos"]), j])
		near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		for e: Array in near.slice(0, NEAREST_LINKS):
			_add_link(out, have, i, int(e[1]))
	return out


static func _add_link(out: Array[Vector2i], have: Dictionary, a: int, b: int) -> void:
	var key := Vector2i(mini(a, b), maxi(a, b))
	if not have.has(key):
		have[key] = true
		out.append(key)


## 2–3 wide clouds between the stars (volumes, like a system's nebulae, bigger).
static func _nebulae(rng: RandomNumberGenerator, stars: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in rng.randi_range(2, 3):
		var radius := rng.randf_range(130.0, 260.0)
		var center := Vector2.ZERO
		var best_room := -INF
		for t in 20:
			var c := Vector2.from_angle(rng.randf_range(0.0, TAU)) * RADIUS * rng.randf_range(0.2, 1.05)
			var room := INF
			for nb: Dictionary in out:
				room = minf(room, c.distance_to(nb["center"]) - float(nb["radius"]) - radius)
			for s: Dictionary in stars:
				if s["home"]:
					room = minf(room, c.distance_to(s["pos"]) - radius * 0.6)
			if room > best_room:
				best_room = room
				center = c
		var col: Color = NEB_COLORS[rng.randi() % NEB_COLORS.size()]
		var col2: Color = NEB_COLORS[rng.randi() % NEB_COLORS.size()]
		var height := radius * rng.randf_range(0.3, 0.5)
		var axis := rng.randf_range(0.0, TAU)
		var stretch := rng.randf_range(1.4, 2.2)
		var blobs: Array[Dictionary] = []
		for b in rng.randi_range(18, 26):
			var core := b < 5
			var ang := rng.randf_range(0.0, TAU)
			var dist := sqrt(rng.randf()) * radius * (0.3 if core else 0.8)
			var off := (Vector2(cos(ang) * stretch, sin(ang)) * dist / stretch).rotated(axis)
			blobs.append({"off": off,
				"h": (rng.randf() + rng.randf() - 1.0) * height * (0.4 if core else 1.0),
				"r": radius * (rng.randf_range(0.3, 0.5) if core else rng.randf_range(0.22, 0.55)),
				"k": rng.randf_range(0.16, 0.26) if core else rng.randf_range(0.07, 0.18),
				"elong": rng.randf_range(1.0, 1.4) if core else rng.randf_range(1.2, 2.8),
				"rot": axis + rng.randf_range(-0.6, 0.6),
				"col": col.lerp(col2, rng.randf() * 0.6).lerp(Color.WHITE, 0.2 if core else 0.0)})
		out.append({"name": "%s %s" % [NEB_A[rng.randi() % NEB_A.size()], NEB_B[rng.randi() % NEB_B.size()]],
			"center": center, "radius": radius, "height": height, "color": col, "blobs": blobs})
	return out
