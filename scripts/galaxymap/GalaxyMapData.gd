## The galaxy, as the Galaxy map shows it (Mechanic-Test/Star-Map; a first
## base). Made from the run's seed, nothing saved.
##
## A spiral disk whose neighbourhoods (Star Clusters) tile it like a City's
## territories on the planet: every neighbourhood is a cell of the space nearest
## its site (Voronoi), so neighbours share a border; the borders are wobbled
## by one noise field, so a shared border still fits both sides. Lanes join the
## neighbourhoods that share a border (the star-chart's routes); where a
## neighbourhood sits apart (across a gap between arms), a bridge lane joins it
## to the nearest one of the rest, so every neighbourhood can be reached.
##
## Shape: most neighbourhoods follow the spiral arms (the arm tips may reach
## past the disk), a few fill the inner disk; a cell only reaches so far from
## its site, by a noisy amount per direction, so the rim is ragged and the gaps
## between arms stay open. Relief: height_at() — a bulge at the core and a
## gentle warp — lifts the whole map off the flat plane.
##
##   { name, radius, arms, twist, arm_phase,
##     sites: [{ pos, seed, name, poly (wobbly border, plane), center, size, home }],
##     links: [Vector2i], bridges: [Vector2i] (the gap-crossing ones, also in links),
##     noise (FastNoiseLite, for height_at) }
## A site's seed makes its Star Cluster (ClusterData); the home site uses the
## run's seed, as the home cluster always has.
class_name GalaxyMapData
extends RefCounted

const RADIUS := 1000.0
const SITES_MIN := 42
const SITES_MAX := 58
const MIN_GAP := 85.0
## A cell reaches about this far from its site (× 0.7–1.3 by direction, noisy).
const CELL_MAX_R := 150.0
## Relief (plane units): the core bulge's height and the warp's.
const BULGE := 150.0
const BULGE_R := 0.24   # × RADIUS
const WARP := 45.0
const WOBBLE := 13.0
const WOBBLE_STEP := 12.0

const NAME_A := ["Ser", "Kal", "Ond", "Vey", "Thra", "Myr", "Ast", "Cor", "Eld", "Fen", "Gal", "Ith", "Lor", "Nev", "Orm", "Pyr", "Rhe", "Sol", "Tor", "Ulv"]
const NAME_B := ["ane", "eth", "ion", "ora", "ys", "aris", "enn", "ul", "ica", "ar"]
const NAME_C := ["Reach", "Expanse", "Drift", "Hollow", "Span", "Verge", "Deep", "Marches"]


static func generate(run_seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed ^ 0x6A1A
	var arms := rng.randi_range(2, 4)
	var twist := rng.randf_range(2.6, 3.6)
	var arm_phase := rng.randf_range(0.0, TAU)
	var sites: Array[Dictionary] = []
	var n := rng.randi_range(SITES_MIN, SITES_MAX)
	var used := {}
	var tries := 0
	while sites.size() < n and tries < 6000:
		tries += 1
		var p: Vector2
		if rng.randf() < 0.85:
			# along an arm: a spiral, tight to its line; the tips may run past
			# the disk's edge
			var t := pow(rng.randf_range(0.08, 1.15), 0.85)
			var arm := rng.randi() % arms
			var ang := arm_phase + TAU * float(arm) / float(arms) + t * twist
			ang += rng.randf_range(-0.22, 0.22) / (t + 0.3)
			p = Vector2.from_angle(ang) * t * RADIUS * 0.92 * rng.randf_range(0.94, 1.06)
		else:
			# a few in the inner disk, between the arms' roots
			p = Vector2.from_angle(rng.randf_range(0.0, TAU)) * RADIUS * 0.6 * sqrt(rng.randf())
		if p.length() < RADIUS * 0.1:
			continue   # the core is the galaxy's own bright heart
		var ok := true
		for s: Dictionary in sites:
			if p.distance_to(s["pos"]) < MIN_GAP:
				ok = false
				break
		if ok:
			sites.append({"pos": p, "seed": rng.randi() % 99999, "name": _name(rng, used), "home": false})

	# home: the site nearest the mid-rim (where a sun like ours would be)
	var home := 0
	var best := INF
	var want := RADIUS * 0.62
	for i in sites.size():
		var d := absf((sites[i]["pos"] as Vector2).length() - want)
		if d < best:
			best = d
			home = i
	sites[home]["home"] = true
	sites[home]["seed"] = run_seed

	var noise := FastNoiseLite.new()
	noise.seed = run_seed ^ 0x51DE
	noise.frequency = 0.012
	var links: Array[Vector2i] = []
	for i in sites.size():
		var res := _cell(sites, i, noise)
		sites[i]["poly"] = _wobble(res["poly"], noise)
		var c := _centroid(res["poly"])
		sites[i]["center"] = c
		sites[i]["size"] = sqrt(absf(_area(res["poly"])) / PI)
		for j: int in res["touch"]:
			if j > i:
				links.append(Vector2i(i, j))
	var bridges := _bridge(sites, links)
	var gname := "%s%s Galaxy" % [NAME_A[rng.randi() % NAME_A.size()], NAME_B[rng.randi() % NAME_B.size()]]
	return {"name": gname, "radius": RADIUS, "arms": arms, "twist": twist, "arm_phase": arm_phase,
		"sites": sites, "links": links, "bridges": bridges, "noise": noise}


# ── A neighbourhood seen from inside (Star Cluster ⇄ Galaxy) ─────────────────
# A cluster is laid out in its own units round its core, which sits on its
# site; cluster_scale turns those into galaxy units, cluster_bounds gives the
# cell's shape in cluster units, so the cluster's stars are made inside it and
# its border is the very border the galaxy draws.

static func cluster_scale(site: Dictionary) -> float:
	return float(site["size"]) * 0.95 / ClusterData.RADIUS


static func cluster_bounds(site: Dictionary) -> PackedVector2Array:
	var sc := cluster_scale(site)
	var origin: Vector2 = site["pos"]
	var out := PackedVector2Array()
	for q: Vector2 in site["poly"]:
		out.append((q - origin) / sc)
	return out


## How far the cluster's shape reaches from its core (both views frame by it).
static func cluster_outer(bounds: PackedVector2Array) -> float:
	var r := 1.0
	for q: Vector2 in bounds:
		r = maxf(r, q.length())
	return r


## The site a cluster view shows: its index, or the home one for -1.
static func site_index(gdata: Dictionary, index: int) -> int:
	var sites: Array = gdata["sites"]
	if index >= 0 and index < sites.size():
		return index
	for i in sites.size():
		if sites[i]["home"]:
			return i
	return 0


## Height of the galaxy at plane point p: the core's bulge plus a gentle warp.
## One smooth field, so shared borders lift the same on both sides.
static func height_at(data: Dictionary, p: Vector2) -> float:
	var r := p.length() / (RADIUS * BULGE_R)
	var noise: FastNoiseLite = data["noise"]
	return BULGE * exp(-r * r) + WARP * noise.get_noise_2d(p.x * 0.15 + 4000.0, p.y * 0.15 - 2000.0)


## Joins every group of neighbourhoods that no border reaches to the nearest
## one of the others (shortest site-to-site lane), until all are one network.
## Returns the added lanes (also appended to links).
static func _bridge(sites: Array[Dictionary], links: Array[Vector2i]) -> Array[Vector2i]:
	var n := sites.size()
	var group: Array[int] = []
	for i in n:
		group.append(i)
	for l: Vector2i in links:
		_join(group, l.x, l.y)
	var added: Array[Vector2i] = []
	for guard in n:
		var g0 := _root(group, 0)
		var all_one := true
		for i in n:
			if _root(group, i) != g0:
				all_one = false
				break
		if all_one:
			break
		# the shortest lane from the first group to any other
		var best := INF
		var bi := -1
		var bj := -1
		for i in n:
			if _root(group, i) != g0:
				continue
			for j in n:
				if _root(group, j) == g0:
					continue
				var d := (sites[i]["pos"] as Vector2).distance_to(sites[j]["pos"])
				if d < best:
					best = d
					bi = i
					bj = j
		if bi < 0:
			break
		var lane := Vector2i(mini(bi, bj), maxi(bi, bj))
		links.append(lane)
		added.append(lane)
		_join(group, bi, bj)
	return added


static func _root(group: Array[int], x: int) -> int:
	while group[x] != x:
		group[x] = group[group[x]]
		x = group[x]
	return x


static func _join(group: Array[int], a: int, b: int) -> void:
	var ra := _root(group, a)
	var rb := _root(group, b)
	if ra != rb:
		group[ra] = rb


static func _name(rng: RandomNumberGenerator, used: Dictionary) -> String:
	var nm := ""
	for t in 30:
		nm = "%s%s %s" % [NAME_A[rng.randi() % NAME_A.size()], NAME_B[rng.randi() % NAME_B.size()],
			NAME_C[rng.randi() % NAME_C.size()]]
		if not used.has(nm):
			break
	used[nm] = true
	return nm


## Site i's Voronoi cell: a circle round it (CELL_MAX_R, also inside the disk)
## cut by the bisector with each other site. Also which sites cut it (borders).
static func _cell(sites: Array[Dictionary], i: int, noise: FastNoiseLite) -> Dictionary:
	var pi_: Vector2 = sites[i]["pos"]
	var poly := PackedVector2Array()
	for k in 40:
		# how far it reaches this way: noisy, so the outer edge is ragged
		var dir := Vector2.from_angle(TAU * float(k) / 40.0)
		var probe := pi_ + dir * 60.0
		var reach := CELL_MAX_R * (1.0 + 0.3 * noise.get_noise_2d(probe.x * 2.0, probe.y * 2.0))
		poly.append(pi_ + dir * reach)
	# nearest sites first; far ones can't cut a cell this size
	var others: Array = []
	for j in sites.size():
		if j != i:
			var d := pi_.distance_to(sites[j]["pos"])
			if d < CELL_MAX_R * 2.8:
				others.append([d, j])
	others.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var cutters: Array[int] = []
	for e: Array in others:
		var j: int = e[1]
		var pj: Vector2 = sites[j]["pos"]
		var clipped := _clip(poly, (pi_ + pj) * 0.5, pj - pi_)
		if clipped.size() >= 3:
			if _changed(poly, clipped):
				cutters.append(j)
			poly = clipped
	# a cutter counts as a neighbour only if its bisector is still part of the border
	var touch: Array[int] = []
	for j: int in cutters:
		var pj: Vector2 = sites[j]["pos"]
		var m := (pi_ + pj) * 0.5
		var nrm := (pj - pi_).normalized()
		var on := 0
		for q: Vector2 in poly:
			if absf((q - m).dot(nrm)) < 0.5:
				on += 1
		if on >= 2:
			touch.append(j)
	return {"poly": poly, "touch": touch}


## Keeps the part of poly where (x − m)·dir ≤ 0 (Sutherland–Hodgman).
static func _clip(poly: PackedVector2Array, m: Vector2, dir: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for k in n:
		var a := poly[k]
		var b := poly[(k + 1) % n]
		var da := (a - m).dot(dir)
		var db := (b - m).dot(dir)
		if da <= 0.0:
			out.append(a)
		if (da < 0.0 and db > 0.0) or (da > 0.0 and db < 0.0):
			out.append(a.lerp(b, da / (da - db)))
	return out


static func _changed(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() != b.size():
		return true
	for k in a.size():
		if a[k].distance_to(b[k]) > 0.01:
			return true
	return false


## Splits every edge into short steps and pushes each point by one shared
## noise field: the border wobbles, and the same border bends the same way for
## both cells it parts.
static func _wobble(poly: PackedVector2Array, noise: FastNoiseLite) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for k in n:
		var a := poly[k]
		var b := poly[(k + 1) % n]
		var steps := maxi(1, int(ceil(a.distance_to(b) / WOBBLE_STEP)))
		for s in steps:
			var p := a.lerp(b, float(s) / float(steps))
			out.append(p + Vector2(noise.get_noise_2d(p.x, p.y), noise.get_noise_2d(p.x + 917.0, p.y - 311.0)) * WOBBLE)
	return out


static func _area(poly: PackedVector2Array) -> float:
	var s := 0.0
	for k in poly.size():
		var a := poly[k]
		var b := poly[(k + 1) % poly.size()]
		s += a.x * b.y - b.x * a.y
	return s * 0.5


static func _centroid(poly: PackedVector2Array) -> Vector2:
	var a := _area(poly)
	if absf(a) < 0.001:
		var sum := Vector2.ZERO
		for q: Vector2 in poly:
			sum += q
		return sum / float(maxi(poly.size(), 1))
	var c := Vector2.ZERO
	for k in poly.size():
		var p := poly[k]
		var q := poly[(k + 1) % poly.size()]
		var f := p.x * q.y - q.x * p.y
		c += (p + q) * f
	return c / (6.0 * a)
