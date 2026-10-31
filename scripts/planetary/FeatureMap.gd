class_name FeatureMap
extends RefCounted

## Visible surface features of a planet (docs/design/VOIDLE_GDD.md §6.1).
##
## Built once per planet from the baked terrain (TerrainMap) and resource noise
## (ResourceMap) into an equirectangular grid. The planet shaders draw the same
## grid (texture()), so what the player sees is exactly what the economy reads:
## a site is ON a feature (full bonus), within Balance.cfg.terrain_near_km of it
## (half), or neither. No hidden percentages, no per-pixel potential.
##
## Mountains, plains, sea coasts and polar ice come from the height bands the
## planet already shows; forests, deserts, tundra, rivers, lakes, volcanic
## fields, geothermal rifts, ruins and — on the Moon — craters, caves and ion
## storm regions are added here and
## drawn by the shaders from texture().
##
## Districts store their shares in POIData.site_features when placed (and when
## a planet's maps are ready), so the economy works for bodies not on screen.
##
## Usage:
##   FeatureMap.build(data)                     # after TerrainMap.bake + ResourceMap.build
##   FeatureMap.shares(data, lon, lat)          # { "terrain_mountain": 1.0, "terrain_seacoast": 0.5, … }
##   FeatureMap.texture(data.seed)              # for the planet shader

## Bit order of the grid mask. WIND keeps its slot so the bits stay put, but
## the windy region is no longer a feature (integration decisions 29.10 §3):
## nothing marks it any more.
enum F { MOUNTAIN, PLAIN, FOREST, SEACOAST, LAKESIDE, RIVER, DESERT, TUNDRA,
	GLACIER, VOLCANIC, GEOTHERMAL, WIND, RUINS, CRATER, CAVES, ION_STORM }

## Ids by F (index = bit). Use CATALOGUE for the features that exist.
const IDS: Array[String] = ["terrain_mountain", "terrain_plain", "terrain_forest",
	"terrain_seacoast", "terrain_lakeside", "terrain_river", "terrain_desert",
	"terrain_tundra", "terrain_glacier", "terrain_volcanic", "terrain_geothermal",
	"terrain_wind", "terrain_ruins", "terrain_crater", "terrain_caves", "terrain_ion_storm"]
const NAMES: Array[String] = ["Mountain", "Plain", "Forest", "Sea coast", "Lakeside",
	"River", "Desert", "Tundra", "Glacier", "Volcanic field", "Geothermal rift",
	"Windy region", "Old ruins", "Crater", "Caves", "Ion storm region"]

## The 15 geography types: 12 general ones and three found only on the Moon.
const CATALOGUE: Array[String] = ["terrain_mountain", "terrain_plain", "terrain_forest",
	"terrain_seacoast", "terrain_lakeside", "terrain_river", "terrain_desert",
	"terrain_tundra", "terrain_glacier", "terrain_volcanic", "terrain_geothermal",
	"terrain_ruins", "terrain_crater", "terrain_caves", "terrain_ion_storm"]
## Shown with a "Moon only" tag (tables, build list, tooltips).
const MOON_ONLY: Array[String] = ["terrain_crater", "terrain_caves", "terrain_ion_storm"]

const WIDTH:  int = 384
const HEIGHT: int = 192

# Texture encoding (RGBA8, sampled with filter_nearest):
#   R  land cover   0 none · 1 forest · 2 desert · 3 tundra · 4 volcanic · 5 caves · 6 ion storm
#   G  lines        0 none · 1 river  · 2 geothermal rift
#   B  spots        0 none · 1 crater floor · 2 crater rim · 3 ruins
#   A  unused (the windy region is no longer a feature)
const COVER_FOREST := 1
const COVER_DESERT := 2
const COVER_TUNDRA := 3
const COVER_VOLCANIC := 4
## Lowest wind value a Mountain / Tundra cell gets in the lens texture.
const WIND_LENS_MIN := 0.45
const COVER_CAVES := 5
const COVER_ION_STORM := 6
const LINE_RIVER := 1
const LINE_RIFT := 2
const SPOT_CRATER_FLOOR := 1
const SPOT_CRATER_RIM := 2
const SPOT_RUINS := 3

## Windy regions: the windiest WINDY_SHARE of a world's land, never below WINDY_MIN wind.
const WINDY_SHARE := 0.18
const WINDY_MIN := 0.25

## Height bands (match planet_rocky.gdshader and TerrainSampler).
const MOUNTAIN_H := 0.32
const SNOW_H := 0.44
const PLAIN_TOP_H := 0.26
const GLACIER_LAT_DEG := 72.0

static var _maps: Dictionary = {}   # seed -> { "mask": PackedInt32Array, "tex": ImageTexture }

static func has_map(planet_seed: int) -> bool:
	return _maps.has(planet_seed)

static func texture(planet_seed: int) -> ImageTexture:
	return _maps[planet_seed]["tex"] if _maps.has(planet_seed) else null

## Wind strength on the feature grid for the Energy lens's wind currents —
## Mountain and Tundra cells only (see _compute); null without a wind field.
static func wind_texture(planet_seed: int) -> ImageTexture:
	return _maps[planet_seed].get("wind", null) if _maps.has(planet_seed) else null

## Rivers drawn as thin lines at RIVER_SCALE × the grid (R water, G bank);
## null on worlds without rivers. Only for drawing — the economy reads the grid.
static func river_texture(planet_seed: int) -> ImageTexture:
	return _maps[planet_seed].get("river", null) if _maps.has(planet_seed) else null

static func feature_name(id: String) -> String:
	var i := IDS.find(id)
	return NAMES[i] if i >= 0 else id

## "Crater (Moon only)" for the Moon's three, else the plain name.
static func feature_label(id: String) -> String:
	return feature_name(id) + (" (Moon only)" if id in MOON_ONLY else "")

# ── Queries ──────────────────────────────────────────────────────────────────

static func _index(lon: float, lat: float) -> int:
	var x := posmod(floori(fposmod(lon, TAU) / TAU * WIDTH), WIDTH)
	var y := clampi(floori((0.5 - lat / PI) * HEIGHT), 0, HEIGHT - 1)
	return y * WIDTH + x

## Bit mask of the features at a point (bit f = F value); 0 when no map.
static func mask_at(planet_seed: int, lon: float, lat: float) -> int:
	if not _maps.has(planet_seed):
		return 0
	return (_maps[planet_seed]["mask"] as PackedInt32Array)[_index(lon, lat)]

## Centres (lon, lat radians) of every grid cell holding feature `f`; empty
## when the map isn't built yet.
static func cells_with(planet_seed: int, f: int) -> Array:
	var out: Array = []
	if not _maps.has(planet_seed):
		return out
	var mask: PackedInt32Array = _maps[planet_seed]["mask"]
	var bit := 1 << f
	for i in mask.size():
		if mask[i] & bit:
			out.append(_cell_lonlat(i % WIDTH, i / WIDTH))
	return out

## Share of each feature's bonus a site gets: 1.0 on it, 0.5 within
## terrain_near_km of its visible edge, nothing otherwise (only keys > 0).
## Empty when the planet's map isn't built yet.
static func shares(data: PlanetData, lon: float, lat: float) -> Dictionary:
	var out := {}
	if data == null or not _maps.has(data.seed):
		return out
	var on := mask_at(data.seed, lon, lat)
	var near := 0
	var r_km := Location.radius_km(data)
	var near_rad := Balance.cfg.terrain_near_km / maxf(r_km, 1.0)
	# probe two rings out to the near radius
	for ring: float in [0.5, 1.0]:
		var d := near_rad * ring
		for k in 12:
			var a := TAU * float(k) / 12.0
			var plat := clampf(lat + sin(a) * d, -PI * 0.5, PI * 0.5)
			var plon := lon + cos(a) * d / maxf(cos(lat), 0.2)
			near |= mask_at(data.seed, plon, plat)
	for f in IDS.size():
		if f == F.WIND:
			continue
		var bit := 1 << f
		if on & bit:
			out[IDS[f]] = 1.0
		elif near & bit:
			out[IDS[f]] = 0.5
	return out

# ── Economy ──────────────────────────────────────────────────────────────────

## Output family of a resource for terrain bonuses (the five specialist
## district families; `_energy_tag` is no longer used — energy is one family).
static func family_of(resource_id: String, _energy_tag: String = "") -> String:
	match resource_id:
		Economy.CREDITS:    return "commercial"
		Economy.SCIENCE:    return "science"
		Economy.POPULATION: return "residential"
		Economy.ENERGY:     return "energy"
	return "production"   # raw, goods, fuel, rare

## Bonus fraction of one feature share: on it (1.0) or near it (0.5).
static func step_bonus(share: float) -> float:
	if share >= 1.0:
		return Balance.cfg.terrain_on_bonus
	return Balance.cfg.terrain_near_bonus if share > 0.0 else 0.0

## Bonus fraction of a set of feature shares for one family (§3.1): every
## distinct feature type that helps it adds its step — on +1 (×2), near +0.5
## (×1.5) — and the steps add up, e.g. on a Mountain and near a Volcanic field
## = +1.5 (×2.5). A site holds each type once (shares()), so the same type
## never counts twice; on and near of one type is its "on".
static func bonus_for(site: Dictionary, family: String) -> float:
	var table: Dictionary = Balance.cfg.terrain_bonuses
	var total := 0.0
	for fid: String in site:
		var row: Dictionary = table.get(fid, {})
		total += float(row.get(family, 0.0)) * step_bonus(float(site[fid])) \
			* SkillTree.get_feature_mult(fid)   # Geography Specialisation
	return total

## Families a feature helps, as labels: "Production, Science".
static func helped_families(fid: String) -> String:
	var row: Dictionary = Balance.cfg.terrain_bonuses.get(fid, {})
	var out: Array[String] = []
	for fam: String in row:
		out.append(family_label(fam))
	return ", ".join(out)

static func family_label(fam: String) -> String:
	return fam.capitalize()

## A district's site, merged with its City's: each feature counts once at the
## stronger of the two shares (the City's location carries to its districts).
static func merged_site(pd: PlanetData, poi: POIData) -> Dictionary:
	var site: Dictionary = poi.site_features.duplicate()
	if poi.parent_city != "" and pd != null:
		for p: POIData in pd.custom_pois:
			if p.label == poi.parent_city:
				for fid: String in p.site_features:
					site[fid] = maxf(float(site.get(fid, 0.0)), float(p.site_features[fid]))
				break
	return site

## Geography multiplier of a specialist district's base output (§3, §7.1): 1 +
## the summed steps of the features at its own site. The Capital (a City) and
## the Orbit get none, and buildings never get one — only the district's base.
static func terrain_mult(pd: PlanetData, poi: POIData, resource_id: String, _energy_tag: String = "") -> float:
	if poi == null or poi.is_orbital() or poi.is_city():
		return 1.0
	return 1.0 + bonus_for(poi.site_features, family_of(resource_id))

## Shorelines and rivers are one grid cell thin. The decisions (§3.2) ask for
## a site ON the feature for its special building — 250 km near is not enough.
## Flip this to also accept NEAR for these thin edge features if playtests show
## they are too hard to hit.
const EDGE_FEATURES: Array[String] = ["terrain_seacoast", "terrain_lakeside", "terrain_river"]
const EDGE_NEAR_OK := false

## Why a site can't host a building that needs one of `features` ("" if it can).
static func requirement_block(site: Dictionary, features: Array[String]) -> String:
	if features.is_empty():
		return ""
	var names: Array[String] = []
	for fid: String in features:
		var share := float(site.get(fid, 0.0))
		if share >= 1.0 or (EDGE_NEAR_OK and share > 0.0 and fid in EDGE_FEATURES):
			return ""
		names.append(feature_name(fid))
	return "Needs to stand on: " + " or ".join(names)

# ── Role overlay (role buttons) ──────────────────────────────────────────────

## Role buttons of the planet view, with the output family each one asks about.
## Tints are the family colours (Economy.family_color): lens, district and symbol match.
static var ROLES := {
	"energy":      {"label": "Energy",     "family": "energy",      "tint": Economy.INFO[Economy.ENERGY]["color"]},
	"residential": {"label": "Population", "family": "residential", "tint": Economy.INFO[Economy.POPULATION]["color"]},
	"production":  {"label": "Production", "family": "production",  "tint": Economy.PRODUCTION_COLOR},
	"science":     {"label": "Science",    "family": "science",     "tint": Economy.INFO[Economy.SCIENCE]["color"]},
	"commercial":  {"label": "Commercial", "family": "commercial",  "tint": Economy.INFO[Economy.CREDITS]["color"]},
}
## Overlay levels: a cell's terrain bonus for the role ≥ STRONG is "strong",
## ≥ GOOD "good" (shown fainter and dotted), below that nothing.
const ROLE_STRONG := 0.30
const ROLE_GOOD := 0.10

## Where a role thrives: an overlay texture of the terrain bonus each cell gives
## that role (only features you stand ON; the half bonus near them isn't drawn).
## Same grid as the features, so the overlay matches the map and the economy.
static func role_texture(planet_seed: int, role: String) -> ImageTexture:
	if not _maps.has(planet_seed) or not ROLES.has(role):
		return null
	var m: Dictionary = _maps[planet_seed]
	if not m.has("roles"):
		m["roles"] = {}
	if m["roles"].has(role):
		return m["roles"][role]
	var fam: String = ROLES[role]["family"]
	var tint: Color = ROLES[role]["tint"]
	var mask: PackedInt32Array = m["mask"]
	var by_mask := {}   # memo: mask value -> bonus
	var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	for y in HEIGHT:
		for x in WIDTH:
			var mv: int = mask[y * WIDTH + x]
			if mv == 0:
				continue
			if not by_mask.has(mv):
				var site := {}
				for f in IDS.size():
					if mv & (1 << f):
						site[IDS[f]] = 1.0
				by_mask[mv] = _role_cell(site, fam, tint)
			var cell: Array = by_mask[mv]
			var b: float = cell[0]
			var col: Color = cell[1]
			if b >= ROLE_STRONG:
				img.set_pixel(x, y, Color(col, 0.85))
			elif b >= ROLE_GOOD and (x + y) % 2 == 0:   # dotted, so the levels differ by more than colour
				img.set_pixel(x, y, Color(col.darkened(0.15), 0.55))
	var tex := ImageTexture.create_from_image(img)
	m["roles"][role] = tex
	return tex

## Each feature's own colour under a lens (playtest 30.10): the lens tells the
## features apart by hue, not by shade — a darker tint would read as "better".
const FEATURE_COLORS := {
	"terrain_mountain":   Color(0.80, 0.68, 0.55),
	"terrain_forest":     Color(0.30, 0.80, 0.35),
	"terrain_seacoast":   Color(0.30, 0.72, 1.00),
	"terrain_lakeside":   Color(0.45, 0.92, 0.92),
	"terrain_river":      Color(0.35, 0.50, 1.00),
	"terrain_desert":     Color(1.00, 0.86, 0.35),
	"terrain_tundra":     Color(0.78, 0.92, 0.80),
	"terrain_glacier":    Color(0.92, 0.97, 1.00),
	"terrain_volcanic":   Color(1.00, 0.35, 0.22),
	"terrain_geothermal": Color(1.00, 0.62, 0.18),
	"terrain_ruins":      Color(0.85, 0.55, 0.98),
	"terrain_crater":     Color(0.72, 0.72, 0.80),
	"terrain_caves":      Color(0.62, 0.48, 0.36),
	"terrain_ion_storm":  Color(0.55, 0.55, 1.00),
}

static func feature_color(fid: String) -> Color:
	return FEATURE_COLORS.get(fid, Color.WHITE)

## [bonus, colour] a cell shows under a role's lens: the colour of the feature
## that gives the role the most there.
static func _role_cell(site: Dictionary, fam: String, tint: Color) -> Array:
	var table: Dictionary = Balance.cfg.terrain_bonuses
	var best := 0.0
	var col := tint
	for fid: String in CATALOGUE:
		if site.has(fid):
			var w := float(table.get(fid, {}).get(fam, 0.0))
			if w > best:
				best = w
				col = feature_color(fid)
	return [bonus_for(site, fam), col]

## The features that help a role, with their lens colours: [[name, colour], …].
static func role_legend(role: String) -> Array:
	var out: Array = []
	if not ROLES.has(role):
		return out
	var fam: String = ROLES[role]["family"]
	var table: Dictionary = Balance.cfg.terrain_bonuses
	for fid: String in CATALOGUE:
		if float(table.get(fid, {}).get(fam, 0.0)) > 0.0:
			out.append([feature_label(fid), feature_color(fid)])
	return out

## Features that help a role, for its button tooltip: "Desert (Solar) …".
static func role_features_text(role: String) -> String:
	if not ROLES.has(role):
		return ""
	var fam: String = ROLES[role]["family"]
	var table: Dictionary = Balance.cfg.terrain_bonuses
	var parts: Array[String] = []
	for fid: String in CATALOGUE:
		var row: Dictionary = table.get(fid, {})
		if row.has(fam):
			parts.append(feature_label(fid))
	return "\n".join(parts)

# ── Build ────────────────────────────────────────────────────────────────────

static func _cell_lonlat(x: int, y: int) -> Vector2:
	return Vector2((float(x) + 0.5) / WIDTH * TAU, (0.5 - (float(y) + 0.5) / HEIGHT) * PI)

static func _noise(seed_val: int, freq: float, octaves: int = 3) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_val
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = octaves
	return n

static func _n3(n: FastNoiseLite, lon: float, lat: float) -> float:
	return n.get_noise_3d(sin(lon) * cos(lat) * 100.0, sin(lat) * 100.0, cos(lon) * cos(lat) * 100.0)

## Builds the feature grid and texture for `data` (synchronous; a few hundred ms
## once per planet). Rocky worlds need TerrainMap baked; ResourceMap is used for
## the geothermal and wind fields when built.
static func build(data: PlanetData) -> void:
	if _maps.has(data.seed):
		return
	_finish(data.seed, _compute(data))

## build() on a worker thread (the grid takes a few seconds in GDScript, which
## froze the first frames of a new game). Textures are made back on the main thread.
static func build_async(data: PlanetData, host: Node) -> void:
	if _maps.has(data.seed):
		return
	if OS.has_feature("web"):   # the web demo is exported without threads
		build(data)
		return
	var result := {}
	var task := WorkerThreadPool.add_task(func() -> void: result.merge(_compute(data)), false, "FeatureMap %d" % data.seed)
	while not WorkerThreadPool.is_task_completed(task):
		await host.get_tree().process_frame
	WorkerThreadPool.wait_for_task_completion(task)
	if not _maps.has(data.seed):
		_finish(data.seed, result)

static func _finish(planet_seed: int, r: Dictionary) -> void:
	_maps[planet_seed] = {"mask": r["mask"], "tex": ImageTexture.create_from_image(r["img"])}
	if r.has("river_img"):
		_maps[planet_seed]["river"] = ImageTexture.create_from_image(r["river_img"])
	if r.has("wind_img"):
		_maps[planet_seed]["wind"] = ImageTexture.create_from_image(r["wind_img"])

## The whole grid as plain data and Images — no textures, safe off the main thread.
static func _compute(data: PlanetData) -> Dictionary:
	var n := WIDTH * HEIGHT
	var cover := PackedByteArray(); cover.resize(n)
	var lines := PackedByteArray(); lines.resize(n)
	var spots := PackedByteArray(); spots.resize(n)
	var windy := PackedByteArray(); windy.resize(n)
	var mask := PackedInt32Array(); mask.resize(n)
	var stype := PlanetData.get_shader_type(data.planet_type)
	var rocky := stype == PlanetData.ShaderType.ROCKY and TerrainMap.has_map(data.seed, TerrainMap.Mode.ROCKY)
	var moon := stype == PlanetData.ShaderType.MOON
	if not rocky and not moon:
		return {"mask": mask, "img": _pack(cover, lines, spots, windy)}   # gas giants, asteroids: nothing

	var rng := RandomNumberGenerator.new()
	rng.seed = data.seed ^ 0x5EA7

	# height and land
	var height := PackedFloat32Array(); height.resize(n)
	var land := PackedByteArray(); land.resize(n)
	for y in HEIGHT:
		for x in WIDTH:
			var i := y * WIDTH + x
			var ll := _cell_lonlat(x, y)
			var h := 0.2
			if rocky:
				h = TerrainMap.value(data.seed, ll.x, ll.y) - data.sea_level
			height[i] = h
			land[i] = 1 if h >= TerrainSampler.SHORE_H else 0

	var river_paths: Array = []
	if rocky:
		river_paths = _build_rocky(data, rng, height, land, cover, lines, mask)
	# Crater, Caves and Ion storm region exist only on the Moon (§3.3)
	if data.planet_type == PlanetData.Type.MOON:
		_place_craters(data, rng, land, spots, mask, 10)
		# big enough to find and to build on (playtest 30.10: they were tiny)
		_place_patches(rng, cover, mask, F.CAVES, COVER_CAVES, 7, 3.0, 5.0)
		_place_patches(rng, cover, mask, F.ION_STORM, COVER_ION_STORM, 4, 6.0, 10.0)
	if rocky and data.planet_type == PlanetData.Type.TERRAN:
		_place_ruins(rng, land, height, spots, mask, 4)
	var out := {"mask": mask, "img": _pack(cover, lines, spots, windy)}
	if not river_paths.is_empty():
		out["river_img"] = _bake_rivers(river_paths, data.seed, land)
	# Wind currents for the Energy lens: only where wind is used — on Mountains
	# and Tundra of a world with an atmosphere (the Wind Turbine's sites; the
	# windy region is no longer a feature). Every such cell shows some current,
	# windier ones more (the shader draws from 0.35 up).
	if ResourceMap.has_map(data.seed) and data.has_atmosphere:
		var wb := PackedByteArray(); wb.resize(n)
		var windy_bits := (1 << F.MOUNTAIN) | (1 << F.TUNDRA)
		for y in HEIGHT:
			for x in WIDTH:
				var i := y * WIDTH + x
				if land[i] == 0 or (mask[i] & windy_bits) == 0:
					continue
				var ll := _cell_lonlat(x, y)
				var w := clampf(ResourceMap.field(data.seed, "wind", ll.x, ll.y), 0.0, 1.0)
				wb[i] = int((WIND_LENS_MIN + (1.0 - WIND_LENS_MIN) * w) * 255.0)
		out["wind_img"] = Image.create_from_data(WIDTH, HEIGHT, false, Image.FORMAT_R8, wb)
	return out

static func _build_rocky(data: PlanetData, rng: RandomNumberGenerator, height: PackedFloat32Array,
		land: PackedByteArray, cover: PackedByteArray, lines: PackedByteArray, mask: PackedInt32Array) -> Array:
	var n := WIDTH * HEIGHT
	var ptype := data.planet_type
	var forest_n := _noise(data.seed ^ 0xF0E5, 0.035, 4)
	var arid_n := _noise(data.seed ^ 0xA21D, 0.02, 3)
	var volc_n := _noise(data.seed ^ 0x701C, 0.05, 2)
	var real_sea := ptype in [PlanetData.Type.TERRAN, PlanetData.Type.ICE]

	# water bodies: big ones are seas, small enclosed ones are lakes
	var comp := PackedInt32Array(); comp.resize(n); comp.fill(-1)
	var comp_size: Array[int] = []
	for start in n:
		if land[start] == 1 or comp[start] >= 0:
			continue
		var id := comp_size.size()
		var q := PackedInt32Array([start])
		comp[start] = id
		var head := 0
		while head < q.size():
			var i := q[head]; head += 1
			for j in _neighbours4(i):
				if land[j] == 0 and comp[j] < 0:
					comp[j] = id
					q.append(j)
		comp_size.append(q.size())
	var lake_max := int(n * 0.004)

	# geothermal ridges from the resource noise (thin "fault lines")
	var geo := PackedFloat32Array(); geo.resize(n)
	if ResourceMap.has_map(data.seed):
		for y in HEIGHT:
			for x in WIDTH:
				var ll := _cell_lonlat(x, y)
				geo[y * WIDTH + x] = ResourceMap.field(data.seed, "geothermal", ll.x, ll.y)

	# Terran worlds always get some Mountains and Geothermal rifts (playtest
	# 30.10): the cut is the world's own top heights / heat when the fixed
	# bands would give none
	var mountain_h := MOUNTAIN_H
	var rift_cut := 0.72
	if ptype == PlanetData.Type.TERRAN:
		var hs := PackedFloat32Array()
		var gs := PackedFloat32Array()
		for i in n:
			if land[i] == 1:
				hs.append(height[i])
				gs.append(geo[i])
		if hs.size() > 100:
			hs.sort()
			gs.sort()
			mountain_h = minf(MOUNTAIN_H, hs[int(hs.size() * 0.94)])
			if gs[gs.size() - 1] > 0.0:
				rift_cut = minf(rift_cut, gs[int(gs.size() * 0.985)])
	for y in HEIGHT:
		for x in WIDTH:
			var i := y * WIDTH + x
			if land[i] == 0:
				continue
			var ll := _cell_lonlat(x, y)
			var lat_deg := absf(rad_to_deg(ll.y))
			var h := height[i]
			var m := 0

			# from the height bands the planet already shows
			if lat_deg >= GLACIER_LAT_DEG or h >= SNOW_H:
				m |= 1 << F.GLACIER
			if h >= mountain_h:
				m |= 1 << F.MOUNTAIN
			for j in _neighbours8(i):
				if land[j] == 0:
					var big := comp_size[comp[j]] > lake_max
					if big and real_sea:
						m |= 1 << F.SEACOAST
					elif not big:
						m |= 1 << F.LAKESIDE

			# land cover by planet type
			var c := 0
			match ptype:
				PlanetData.Type.ARID:
					if h < MOUNTAIN_H: c = COVER_DESERT
				PlanetData.Type.VOLCANIC:
					c = COVER_VOLCANIC
				PlanetData.Type.ICE:
					if h < MOUNTAIN_H: c = COVER_TUNDRA
				PlanetData.Type.TERRAN:
					var arid := _n3(arid_n, ll.x, ll.y) + 0.35 * (1.0 - absf(lat_deg - 25.0) / 25.0)
					if h < MOUNTAIN_H and lat_deg >= 56.0 and lat_deg < GLACIER_LAT_DEG:
						c = COVER_TUNDRA
					elif h < MOUNTAIN_H and arid > 0.42:
						c = COVER_DESERT
					elif h < MOUNTAIN_H and lat_deg < 60.0 and _n3(forest_n, ll.x, ll.y) > 0.08:
						c = COVER_FOREST
					elif h >= mountain_h and _n3(volc_n, ll.x, ll.y) > 0.55:
						c = COVER_VOLCANIC
			cover[i] = c
			match c:
				COVER_FOREST:   m |= 1 << F.FOREST
				COVER_DESERT:   m |= 1 << F.DESERT
				COVER_TUNDRA:   m |= 1 << F.TUNDRA
				COVER_VOLCANIC: m |= 1 << F.VOLCANIC
			if c == 0 and h < PLAIN_TOP_H and not (m & (1 << F.GLACIER)):
				m |= 1 << F.PLAIN

			# geothermal rifts: the strongest fault-line ridges on land
			if geo[i] >= rift_cut:
				lines[i] = LINE_RIFT
				m |= 1 << F.GEOTHERMAL
			mask[i] = m

	if ptype == PlanetData.Type.TERRAN:
		return _trace_rivers(rng, height, land, lines, mask)
	return []

## Rivers: every sizeable landmass gets its share (by area), springing from its
## own highlands (its upper height range, not a planet-wide mountain line),
## spaced apart, and running downhill to the sea or into another river. A river
## that gets stuck in a basin climbs out over the lowest unvisited neighbour;
## one that still can't reach the sea is dropped. Returns each river's cells
## (spring first; the last one is its mouth or the river it joins).
static func _trace_rivers(rng: RandomNumberGenerator, height: PackedFloat32Array, land: PackedByteArray,
		lines: PackedByteArray, mask: PackedInt32Array) -> Array:
	var paths: Array = []
	var n := WIDTH * HEIGHT
	# landmasses
	var comp := PackedInt32Array(); comp.resize(n); comp.fill(-1)
	var masses: Array = []   # Array of PackedInt32Array (cells)
	for start in n:
		if land[start] == 0 or comp[start] >= 0:
			continue
		var id := masses.size()
		var cells := PackedInt32Array()
		var stack: Array[int] = [start]
		comp[start] = id
		while not stack.is_empty():
			var c: int = stack.pop_back()
			cells.append(c)
			for j in _neighbours4(c):
				if land[j] == 1 and comp[j] < 0:
					comp[j] = id
					stack.append(j)
		masses.append(cells)
	var springs_used: Array[int] = []
	for cells: PackedInt32Array in masses:
		if cells.size() < 120:
			continue   # small islands keep no rivers
		var want := clampi(floori(float(cells.size()) / 450.0), 1, 9)
		# its highlands: the top 30% of its own heights, below the snow line
		var hs := PackedFloat32Array()
		for c: int in cells:
			hs.append(height[c])
		hs.sort()
		var h_min := hs[int(float(hs.size()) * 0.70)]
		var cand: Array[int] = []
		for c: int in cells:
			if height[c] >= h_min and height[c] < SNOW_H:
				cand.append(c)
		if cand.is_empty():
			continue
		var made := 0
		var tries := 0
		while made < want and tries < want * 12:
			tries += 1
			var s: int = cand[rng.randi() % cand.size()]
			if _near_any(s, springs_used, 9):
				continue   # keep springs apart: no parallel twin rivers
			var path := _flow(s, height, land, lines)
			if path.is_empty():
				continue
			springs_used.append(s)
			for c: int in path:
				if land[c] == 1:
					lines[c] = LINE_RIVER
					mask[c] |= 1 << F.RIVER
			paths.append(path)
			made += 1
	return paths

## One river's cells from a spring to the sea or another river; empty if it
## can't get there (or is too short to show).
static func _flow(start: int, height: PackedFloat32Array, land: PackedByteArray, lines: PackedByteArray) -> PackedInt32Array:
	var path := PackedInt32Array()
	var seen := {}
	var i := start
	while path.size() < 260:
		path.append(i)
		seen[i] = true
		if land[i] == 0 or (lines[i] == LINE_RIVER and path.size() > 1):
			return path if path.size() >= 6 else PackedInt32Array()   # mouth or confluence
		var best := -1
		var best_h := INF
		for j in _neighbours8(i):
			if seen.has(j):
				continue
			if height[j] < best_h:
				best_h = height[j]
				best = j
		if best < 0:
			return PackedInt32Array()   # boxed in
		i = best
	return PackedInt32Array()

static func _near_any(c: int, others: Array[int], cells: int) -> bool:
	var cx := c % WIDTH
	var cy := floori(float(c) / float(WIDTH))
	for o: int in others:
		var dx := absi(o % WIDTH - cx)
		dx = mini(dx, WIDTH - dx)
		if dx <= cells and absi(floori(float(o) / float(WIDTH)) - cy) <= cells:
			return true
	return false

## River drawing resolution (texture pixels per grid cell).
const RIVER_SCALE := 4

## Draws every river as a smooth, gently meandering line that widens
## downstream, with a soft bank around it. R = water, G = bank.
static func _bake_rivers(paths: Array, planet_seed: int, land: PackedByteArray) -> Image:
	var rw := WIDTH * RIVER_SCALE
	var rh := HEIGHT * RIVER_SCALE
	var water := PackedByteArray(); water.resize(rw * rh)
	var bank := PackedByteArray(); bank.resize(rw * rh)
	var rng := RandomNumberGenerator.new()
	rng.seed = planet_seed ^ 0x51FE
	var sc := float(RIVER_SCALE)
	for path: PackedInt32Array in paths:
		# cell centres in texture pixels, unwrapped across the date line
		var pts := PackedVector2Array()
		var prev_x := -1.0
		for c: int in path:
			var x := float(c % WIDTH) + 0.5
			var y := floorf(float(c) / float(WIDTH)) + 0.5
			if prev_x >= 0.0:
				while x - prev_x > WIDTH * 0.5: x -= WIDTH
				while prev_x - x > WIDTH * 0.5: x += WIDTH
			prev_x = x
			pts.append(Vector2(x, y) * sc)
		# meander: push the middle points sideways a little
		var phase := rng.randf() * TAU
		for k in range(1, pts.size() - 1):
			var dir := (pts[k + 1] - pts[k - 1]).normalized()
			var side := Vector2(-dir.y, dir.x)
			pts[k] += side * sc * (0.28 * sin(float(k) * 0.7 + phase) + rng.randf_range(-0.10, 0.10))
		for _it in 3:
			pts = _chaikin(pts)
		# a river that reaches the sea runs on a little into it and opens up
		# into an estuary there (the shader fades it into the water)
		var to_sea := land[path[path.size() - 1]] == 0
		if to_sea and pts.size() >= 2:
			var dir_end := (pts[pts.size() - 1] - pts[maxi(pts.size() - 6, 0)]).normalized()
			var tip := pts[pts.size() - 1]
			for e in range(1, 7):
				pts.append(tip + dir_end * sc * 0.4 * float(e))
		# stamp a soft disc every ¾ pixel along the line
		var n := pts.size()
		for k in n - 1:
			var a := pts[k]
			var b := pts[k + 1]
			var t := float(k) / float(maxi(n - 1, 1))
			var w := lerpf(0.45, 1.35, t * t)   # a thread at the spring, widest at the mouth
			if to_sea:
				w *= 1.0 + 1.8 * smoothstep(0.82, 1.0, t)   # estuary
			var reach := w + 1.6
			var seg := b - a
			var steps := maxi(ceili(seg.length() / 0.75), 1)
			for st in steps:
				var p := a + seg * (float(st) / float(steps))
				var x0 := floori(p.x - reach)
				var y0 := maxi(floori(p.y - reach), 0)
				var x1 := ceili(p.x + reach)
				var y1 := mini(ceili(p.y + reach), rh - 1)
				for yy in range(y0, y1 + 1):
					for xx in range(x0, x1 + 1):
						var d := Vector2(float(xx) + 0.5, float(yy) + 0.5).distance_to(p)
						if d > reach:
							continue
						var idx := yy * rw + posmod(xx, rw)
						var wv := int(255.0 * (1.0 - smoothstep(w - 0.5, w + 0.5, d)))
						var bv := int(255.0 * (1.0 - smoothstep(w, reach, d)))
						if wv > water[idx]: water[idx] = wv
						if bv > bank[idx]: bank[idx] = bv
	var bytes := PackedByteArray(); bytes.resize(rw * rh * 2)
	for i in rw * rh:
		bytes[i * 2] = water[i]
		bytes[i * 2 + 1] = bank[i]
	return Image.create_from_data(rw, rh, false, Image.FORMAT_RG8, bytes)

## One round of Chaikin corner cutting (ends kept).
static func _chaikin(pts: PackedVector2Array) -> PackedVector2Array:
	if pts.size() < 3:
		return pts
	var out := PackedVector2Array([pts[0]])
	for k in pts.size() - 1:
		out.append(pts[k].lerp(pts[k + 1], 0.25))
		out.append(pts[k].lerp(pts[k + 1], 0.75))
	out.append(pts[pts.size() - 1])
	return out

static func _place_craters(data: PlanetData, rng: RandomNumberGenerator, land: PackedByteArray,
		spots: PackedByteArray, mask: PackedInt32Array, count: int) -> void:
	var moon := PlanetData.get_shader_type(data.planet_type) == PlanetData.ShaderType.MOON
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 40:
		tries += 1
		var cx := rng.randi() % WIDTH
		var cy := rng.randi_range(int(HEIGHT * 0.15), int(HEIGHT * 0.85))
		var c := cy * WIDTH + cx
		if not moon and land[c] == 0:
			continue
		var r := rng.randf_range(3.0, 6.0) if moon else rng.randf_range(1.6, 3.0)   # Moon craters big enough to build in
		var ri := ceili(r) + 1
		for dy in range(-ri, ri + 1):
			for dx in range(-ri, ri + 1):
				var y := cy + dy
				if y < 0 or y >= HEIGHT:
					continue
				var d := sqrt(float(dx * dx + dy * dy))
				if d > r:
					continue
				var j := y * WIDTH + posmod(cx + dx, WIDTH)
				if not moon and land[j] == 0:
					continue
				spots[j] = SPOT_CRATER_RIM if d > r - 1.0 else SPOT_CRATER_FLOOR
				mask[j] |= 1 << F.CRATER
		placed += 1

## Round patches of a Moon land cover (caves, ion storm regions), apart from
## each other: `count` patches of radius r_min..r_max cells.
static func _place_patches(rng: RandomNumberGenerator, cover: PackedByteArray, mask: PackedInt32Array,
		f: int, value: int, count: int, r_min: float, r_max: float) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 40:
		tries += 1
		var cx := rng.randi() % WIDTH
		var cy := rng.randi_range(int(HEIGHT * 0.18), int(HEIGHT * 0.82))
		if cover[cy * WIDTH + cx] != 0:
			continue
		var r := rng.randf_range(r_min, r_max)
		var ri := ceili(r) + 1
		for dy in range(-ri, ri + 1):
			for dx in range(-ri, ri + 1):
				var y := cy + dy
				if y < 0 or y >= HEIGHT or sqrt(float(dx * dx + dy * dy)) > r:
					continue
				var j := y * WIDTH + posmod(cx + dx, WIDTH)
				if cover[j] != 0 and cover[j] != value:
					continue
				cover[j] = value
				mask[j] |= 1 << f
		placed += 1

static func _place_ruins(rng: RandomNumberGenerator, land: PackedByteArray, height: PackedFloat32Array,
		spots: PackedByteArray, mask: PackedInt32Array, count: int) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 60:
		tries += 1
		var i := rng.randi() % (WIDTH * HEIGHT)
		var y := i / WIDTH
		if land[i] == 0 or height[i] >= MOUNTAIN_H or y < HEIGHT * 0.2 or y > HEIGHT * 0.8 or spots[i] != 0:
			continue
		for j in [i] + _neighbours4(i):
			if land[j] == 1:
				spots[j] = SPOT_RUINS
				mask[j] |= 1 << F.RUINS
		placed += 1

static func _pack(cover: PackedByteArray, lines: PackedByteArray,
		spots: PackedByteArray, windy: PackedByteArray) -> Image:
	var bytes := PackedByteArray(); bytes.resize(WIDTH * HEIGHT * 4)
	for i in WIDTH * HEIGHT:
		bytes[i * 4]     = cover[i]
		bytes[i * 4 + 1] = lines[i]
		bytes[i * 4 + 2] = spots[i]
		bytes[i * 4 + 3] = windy[i]
	return Image.create_from_data(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8, bytes)

static func _neighbours4(i: int) -> Array[int]:
	var x := i % WIDTH
	var y := i / WIDTH
	var out: Array[int] = [y * WIDTH + posmod(x + 1, WIDTH), y * WIDTH + posmod(x - 1, WIDTH)]
	if y > 0: out.append((y - 1) * WIDTH + x)
	if y < HEIGHT - 1: out.append((y + 1) * WIDTH + x)
	return out

static func _neighbours8(i: int) -> Array[int]:
	var x := i % WIDTH
	var y := i / WIDTH
	var out: Array[int] = []
	for dy in [-1, 0, 1]:
		var ny: int = y + dy
		if ny < 0 or ny >= HEIGHT:
			continue
		for dx in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			out.append(ny * WIDTH + posmod(x + dx, WIDTH))
	return out
