class_name ResourceMap
extends RefCounted

## Natural resources of a planet, as equirectangular maps (0..1 per cell):
##   geothermal — thermal flow along fault-line ridges, strongest on volcanic worlds
##   solar      — sunlight: high at the equator, less under clouds / thick air
##   wind       — strong on coasts and highlands, needs an atmosphere
##   tidal      — coastal waters only, on worlds with real seas; moons strengthen it
##   minerals   — one deposit field per raw mineral found on the planet
##
## Noise fields are baked on the GPU (resource_noise.gdshader); the rest is
## derived here from the baked terrain. Lens overlays are drawn from the same
## data, so what the lens shows is exactly what the game reads.
##
## Usage:
##   await ResourceMap.build(data, node_in_tree)   # after TerrainMap.bake()
##   ResourceMap.sample(data.seed, lon, lat)       # -> tags dictionary
##   ResourceMap.lens_texture(data.seed, ResourceMap.Lens.SOLAR)

const WIDTH:  int = 256
const HEIGHT: int = 128
const MAX_MINERALS: int = 5

enum Lens { NONE, MINERALS, GEOTHERMAL, SOLAR, WIND, TIDAL }
const ENERGY_KEYS := ["geothermal", "solar", "wind", "tidal"]

## seed -> { geothermal, solar, wind, tidal: PackedFloat32Array,
##           minerals: { resource_id: PackedFloat32Array },
##           mineral_info: [{ id, name, color, density }], textures: {} }
static var _maps:    Dictionary = {}
static var _pending: Dictionary = {}

static func has_map(planet_seed: int) -> bool:
	return _maps.has(planet_seed)

static func mineral_info(planet_seed: int) -> Array:
	return _maps[planet_seed]["mineral_info"] if _maps.has(planet_seed) else []

## Builds the maps for `data`. For rocky worlds and moons call after
## TerrainMap.bake() so land / sea and height are known.
static func build(data: PlanetData, host: Node) -> void:
	if _maps.has(data.seed) or _pending.has(data.seed):
		return
	_pending[data.seed] = true

	var info: Array = []
	var br = GameState.get_body_resources_for(data)
	if br != null:
		for rd in br.get_by_tag(ResourceData.Tag.RAW_MINERAL):
			if info.size() >= MAX_MINERALS:
				break
			var rid: String = rd.resource_id()
			info.append({
				"id": rid,
				"name": rd.mineral_name if rd.mineral_name != "" else rid,
				"color": rd.display_color,
				"density": float(data.mineral_densities.get(rid, data.deposit_density)),
			})

	var img0 := await _bake_layer(data, host, 0)
	var img1: Image = null
	if info.size() > 2:
		img1 = await _bake_layer(data, host, 1)
	var img2 := await _bake_layer(data, host, 2)
	_pending.erase(data.seed)
	if img0 == null:
		return
	_maps[data.seed] = _derive(data, img0, img1, img2, info)

static func _bake_layer(data: PlanetData, host: Node, layer: int) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(WIDTH, HEIGHT)
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var rect := ColorRect.new()
	rect.size = Vector2(WIDTH, HEIGHT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/resource_noise.gdshader")
	mat.set_shader_parameter("seed",  data.seed)
	mat.set_shader_parameter("layer", layer)
	rect.material = mat
	vp.add_child(rect)
	host.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	if img == null or img.is_empty():
		return null
	img.convert(Image.FORMAT_RGB8)
	return img

static func _cell_lonlat(x: int, y: int) -> Vector2:
	return Vector2((float(x) + 0.5) / WIDTH * TAU, (0.5 - (float(y) + 0.5) / HEIGHT) * PI)

## Fills every field from the baked noise + terrain.
static func _derive(data: PlanetData, img0: Image, img1: Image, img2: Image, info: Array) -> Dictionary:
	var n := WIDTH * HEIGHT
	var map_mode := TerrainMap.mode_for(data)
	var rocky := map_mode == TerrainMap.Mode.ROCKY and TerrainMap.has_map(data.seed, TerrainMap.Mode.ROCKY)
	var stype := PlanetData.get_shader_type(data.planet_type)

	# land / sea + height
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

	var dist_to_sea  := _distance_field(land, 0)   # for land cells
	var dist_to_land := _distance_field(land, 1)   # for sea cells

	# per-planet scalars
	var geo_type := 0.8
	match data.planet_type:
		PlanetData.Type.VOLCANIC:  geo_type = 1.5
		PlanetData.Type.ICE:       geo_type = 0.55
		PlanetData.Type.BARREN:    geo_type = 0.7
		PlanetData.Type.MOON:      geo_type = 0.4
		PlanetData.Type.GAS_GIANT: geo_type = 0.0
	var atmo := clampf(data.atmosphere_density, 0.0, 1.2) / 1.2 if data.has_atmosphere else 0.0
	var clouds := data.cloud_coverage if data.has_clouds else 0.0
	var real_sea := rocky and data.planet_type in [PlanetData.Type.TERRAN, PlanetData.Type.ICE]
	var tide := clampf(0.6 + 0.2 * data.moons.size(), 0.0, 1.0)

	var geo := PackedFloat32Array(); geo.resize(n)
	var solar := PackedFloat32Array(); solar.resize(n)
	var wind := PackedFloat32Array(); wind.resize(n)
	var tidal := PackedFloat32Array(); tidal.resize(n)
	# one flat buffer for all minerals (packed arrays are values in GDScript —
	# writing through a dictionary lookup would only change a copy)
	var mineral_buf := PackedFloat32Array(); mineral_buf.resize(n * info.size())

	for y in HEIGHT:
		for x in WIDTH:
			var i := y * WIDTH + x
			var lat := _cell_lonlat(x, y).y
			var c0 := img0.get_pixel(x * img0.get_width() / WIDTH, y * img0.get_height() / HEIGHT)
			var c1 := img1.get_pixel(x * img1.get_width() / WIDTH, y * img1.get_height() / HEIGHT) \
				if img1 != null else Color.BLACK
			var storm := img2.get_pixel(x, y).r if img2 != null else 0.5
			var h := height[i]
			var on_land := land[i] == 1
			var mountain := smoothstep(0.30, 0.45, h) if rocky else 0.0

			geo[i] = clampf((c0.r * 0.9 + 0.25 * mountain) * geo_type * (1.0 if on_land else 0.5), 0.0, 1.0)

			solar[i] = clampf(pow(maxf(cos(lat), 0.0), 1.2) * (1.0 - 0.5 * clouds) * (1.0 - 0.15 * atmo), 0.0, 1.0)

			# Wind is driven by latitude belts — calm at the equator and poles,
			# strongest around ±45° (westerlies) — plus storm tracks, exposed
			# highlands and open water. Coasts only add a little.
			var belt := absf(sin(2.0 * lat))
			var exposure := 0.15 if not on_land else (0.25 * mountain + 0.08 * exp(-float(dist_to_sea[i]) / 2.0))
			if stype == PlanetData.ShaderType.GAS:
				wind[i] = clampf(0.45 + 0.35 * belt + 0.3 * (storm - 0.5), 0.0, 1.0)
			else:
				wind[i] = clampf((0.10 + 0.45 * belt + 0.55 * (storm - 0.3) + exposure) * atmo, 0.0, 1.0)

			if real_sea:
				if on_land:
					tidal[i] = tide * exp(-float(maxi(dist_to_sea[i] - 1, 0)) / 1.2) if dist_to_sea[i] <= 3 else 0.0
				else:
					tidal[i] = tide * 0.9 * exp(-float(maxi(dist_to_land[i] - 1, 0)) / 2.0)

			for k in info.size():
				var v := 0.0
				match k:
					0: v = c0.g
					1: v = c0.b
					2: v = c1.r
					3: v = c1.g
					4: v = c1.b
				mineral_buf[k * n + i] = v if on_land else v * 0.6   # seabed deposits are leaner

	var minerals := {}
	for k in info.size():
		minerals[info[k]["id"]] = mineral_buf.slice(k * n, (k + 1) * n)
	return {
		"geothermal": geo, "solar": solar, "wind": wind, "tidal": tidal,
		"minerals": minerals, "mineral_info": info, "textures": {}, "land": land,
	}

## Grid steps from each cell to the nearest cell whose land flag == `target`
## (0 = sea, 1 = land). Multi-source BFS, longitude wraps.
static func _distance_field(land: PackedByteArray, target: int) -> PackedInt32Array:
	var n := WIDTH * HEIGHT
	var dist := PackedInt32Array(); dist.resize(n); dist.fill(9999)
	var queue := PackedInt32Array()
	for i in n:
		if land[i] == target:
			dist[i] = 0
			queue.append(i)
	var head := 0
	while head < queue.size():
		var i := queue[head]; head += 1
		var x := i % WIDTH
		var y := i / WIDTH
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ny := y + d.y
			if ny < 0 or ny >= HEIGHT:
				continue
			var j := ny * WIDTH + posmod(x + d.x, WIDTH)
			if dist[j] > dist[i] + 1:
				dist[j] = dist[i] + 1
				queue.append(j)
	return dist

static func _index(lon: float, lat: float) -> int:
	var x := posmod(floori(fposmod(lon, TAU) / TAU * WIDTH), WIDTH)
	var y := clampi(floori((0.5 - lat / PI) * HEIGHT), 0, HEIGHT - 1)
	return y * WIDTH + x

## Resource tags at a point: { geothermal, solar, wind, tidal: 0..1, minerals: { id: 0..1 } }.
## Empty when the map isn't built yet.
static func sample(planet_seed: int, lon: float, lat: float) -> Dictionary:
	if not _maps.has(planet_seed):
		return {}
	var m: Dictionary = _maps[planet_seed]
	var i := _index(lon, lat)
	var out := {}
	for key: String in ENERGY_KEYS:
		out[key] = snappedf((m[key] as PackedFloat32Array)[i], 0.01)
	var mins := {}
	for rid: String in m["minerals"]:
		mins[rid] = snappedf((m["minerals"][rid] as PackedFloat32Array)[i], 0.01)
	out["minerals"] = mins
	return out

static func lens_label(lens: Lens) -> String:
	match lens:
		Lens.MINERALS:   return "Minerals"
		Lens.GEOTHERMAL: return "Geothermal"
		Lens.SOLAR:      return "Solar"
		Lens.WIND:       return "Wind"
		Lens.TIDAL:      return "Tidal"
	return "Terrain"

## Overlay alpha per energy lens: transparent below x, full (z) from y — so
## only meaningful values tint the globe.
const LENS_FADE := {
	Lens.GEOTHERMAL: Vector3(0.15, 0.60, 0.85),
	Lens.SOLAR:      Vector3(0.25, 0.95, 0.75),
	Lens.WIND:       Vector3(0.15, 0.60, 0.80),
	Lens.TIDAL:      Vector3(0.03, 0.35, 0.85),
}

## Colour ramp per energy lens (low → high).
static func _ramp(lens: Lens, v: float) -> Color:
	match lens:
		Lens.GEOTHERMAL: return Color(0.35, 0.05, 0.02).lerp(Color(1.0, 0.45, 0.10), v).lerp(Color(1.0, 0.95, 0.55), v * v)
		Lens.SOLAR:      return Color(0.35, 0.28, 0.02).lerp(Color(1.0, 0.92, 0.35), v)
		Lens.WIND:       return Color(0.10, 0.30, 0.45).lerp(Color(0.85, 1.0, 1.0), v)
		Lens.TIDAL:      return Color(0.02, 0.22, 0.32).lerp(Color(0.30, 1.0, 0.90), v)
	return Color.WHITE

## Overlay texture for a lens (RGBA, alpha = strength). `mineral_id` picks one
## mineral for the Minerals lens; empty = strongest mineral per cell.
static func lens_texture(planet_seed: int, lens: Lens, mineral_id: String = "") -> ImageTexture:
	if not _maps.has(planet_seed) or lens == Lens.NONE:
		return null
	var m: Dictionary = _maps[planet_seed]
	var key := "%d:%s" % [lens, mineral_id]
	if m["textures"].has(key):
		return m["textures"][key]
	var img := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	var colors := {}
	for mi: Dictionary in m["mineral_info"]:
		colors[mi["id"]] = mi["color"]
	for y in HEIGHT:
		for x in WIDTH:
			var i := y * WIDTH + x
			var col := Color(0, 0, 0, 0)
			if lens == Lens.MINERALS:
				var best := 0.0
				var best_id := ""
				for rid: String in m["minerals"]:
					if mineral_id != "" and rid != mineral_id:
						continue
					var v: float = (m["minerals"][rid] as PackedFloat32Array)[i]
					if v > best:
						best = v
						best_id = rid
				if best_id != "":
					col = colors[best_id]
					# seabed deposits stay faint so the land ones read first
					var sea_dim := 1.0 if (m["land"] as PackedByteArray)[i] == 1 else 0.35
					col.a = smoothstep(0.05, 0.6, best) * 0.9 * sea_dim
			else:
				var field: PackedFloat32Array = m[ENERGY_KEYS[lens - Lens.GEOTHERMAL]]
				var v := field[i]
				var fade: Vector3 = LENS_FADE[lens]   # (from, to, max alpha)
				col = _ramp(lens, v)
				col.a = smoothstep(fade.x, fade.y, v) * fade.z
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	m["textures"][key] = tex
	return tex
