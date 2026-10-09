class_name TerrainMap
extends RefCounted

## GPU-baked terrain for CPU-side queries.
##
## The planet shaders hash with fract(sin(x) * 43758.5453) in 32-bit floats.
## That hash is chaotic, so PlanetNoise's 64-bit GDScript copy lands on
## different terrain almost everywhere. Instead, terrain_map.gdshader bakes the
## exact same noise into an equirectangular image on the GPU once per planet,
## and lookups read from it.
##
## Usage:
##   await TerrainMap.bake(data, some_node_in_tree)
##   TerrainMap.value(seed, lon, lat)   # raw fbm (height before sea level / mare value)
##   TerrainMap.warp(seed, lon, lat)    # territory edge noise, -1..1

const WIDTH:  int = 2048
const HEIGHT: int = 1024
enum Mode { ROCKY, MOON }

static var _maps:    Dictionary = {}   # seed -> Image
static var _modes:   Dictionary = {}   # seed -> Mode
static var _pending: Dictionary = {}   # seed -> true while baking

static func has_map(planet_seed: int, mode: Mode = Mode.ROCKY) -> bool:
	return _maps.has(planet_seed) and _modes[planet_seed] == mode

static func mode_for(data: PlanetData) -> int:
	match PlanetData.get_shader_type(data.planet_type):
		PlanetData.ShaderType.ROCKY: return Mode.ROCKY
		PlanetData.ShaderType.MOON:  return Mode.MOON
	return -1

## Renders the map for `data` (no-op for gas giants / asteroids or if cached).
## `host` must be inside the scene tree; the bake viewport lives there for a frame.
static func bake(data: PlanetData, host: Node) -> void:
	var mode := mode_for(data)
	if mode < 0 or _maps.has(data.seed) or _pending.has(data.seed):
		return
	_pending[data.seed] = true
	var vp := SubViewport.new()
	vp.size = Vector2i(WIDTH, HEIGHT)
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var rect := ColorRect.new()
	rect.size = Vector2(WIDTH, HEIGHT)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/terrain_map.gdshader")
	mat.set_shader_parameter("seed",              data.seed)
	mat.set_shader_parameter("terrain_roughness", data.terrain_roughness)
	mat.set_shader_parameter("continent_scale",   data.continent_scale)
	mat.set_shader_parameter("mode",              mode)
	rect.material = mat
	vp.add_child(rect)
	host.add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	_pending.erase(data.seed)
	if img == null or img.is_empty():
		return
	img.convert(Image.FORMAT_RGB8)
	_maps[data.seed]  = img
	_modes[data.seed] = mode

## Bilinear sample of the 16-bit terrain value. NAN when no map is baked.
static func value(planet_seed: int, lon: float, lat: float) -> float:
	var img: Image = _maps.get(planet_seed)
	if img == null:
		return NAN
	return _bilinear(img, lon, lat, func(c: Color) -> float:
		var e: float = round(c.r * 255.0) * 256.0 + round(c.g * 255.0)
		return e / 65535.0 * 4.0 - 2.0)

## Territory warp noise (noise3(rn * 22)) in -1..1. NAN when no map is baked.
static func warp(planet_seed: int, lon: float, lat: float) -> float:
	var img: Image = _maps.get(planet_seed)
	if img == null:
		return NAN
	return _bilinear(img, lon, lat, func(c: Color) -> float: return c.b * 2.0 - 1.0)

static func _bilinear(img: Image, lon: float, lat: float, decode: Callable) -> float:
	# Texel i holds lon = (i + 0.5) / W * TAU; row j holds lat = (0.5 - (j + 0.5) / H) * PI.
	var fx := fposmod(lon, TAU) / TAU * WIDTH - 0.5
	var fy := (0.5 - lat / PI) * HEIGHT - 0.5
	var x0 := floori(fx)
	var y0 := clampi(floori(fy), 0, HEIGHT - 1)
	var y1 := clampi(y0 + 1, 0, HEIGHT - 1)
	var tx := fx - floorf(fx)
	var ty := clampf(fy - float(y0), 0.0, 1.0)
	var xa := posmod(x0, WIDTH)
	var xb := posmod(x0 + 1, WIDTH)
	var top: float = lerpf(decode.call(img.get_pixel(xa, y0)), decode.call(img.get_pixel(xb, y0)), tx)
	var bot: float = lerpf(decode.call(img.get_pixel(xa, y1)), decode.call(img.get_pixel(xb, y1)), tx)
	return lerpf(top, bot, ty)
