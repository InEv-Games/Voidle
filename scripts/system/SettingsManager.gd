extends Node

const SETTINGS_PATH = "user://settings.cfg"

## Emitted when a visual setting changes so open views can re-apply it.
signal night_shadow_changed(value: float)
signal theme_changed(theme_id: String)

## Theme presets: an accent hue and a harmony for ThemeBuilder. "cyan" is the
## project theme as authored (voidle_theme.tres); "custom" is the theme builder's.
const THEMES := {
	"cyan":    {"label": "Cyan (Default)",    "hue": 194.0, "harmony": ThemeBuilder.Harmony.ANALOGOUS,     "original": true},
	"yellow":  {"label": "Solar Gold (News)", "hue": 43.0,  "harmony": ThemeBuilder.Harmony.COMPLEMENTARY},
	"emerald": {"label": "Bio Emerald",       "hue": 151.0, "harmony": ThemeBuilder.Harmony.ANALOGOUS},
	"crimson": {"label": "Mars Crimson",      "hue": 352.0, "harmony": ThemeBuilder.Harmony.MONOCHROMATIC},
	"violet":  {"label": "Nebula Violet",     "hue": 265.0, "harmony": ThemeBuilder.Harmony.ANALOGOUS},
	"custom":  {"label": "Custom"},
}
const THEME_ORDER: Array[String] = ["cyan", "yellow", "emerald", "crimson", "violet", "custom"]

var master_volume: float = 1.0
var music_volume:  float = 1.0
var ui_volume:     float = 1.0
var sfx_volume:    float = 1.0
var is_fullscreen: bool = true
var tutorial_ever_done: bool = false
## How dark the night side of planets gets: 0 = fully lit, 1 = full shadow.
var night_shadow: float = 1.0
## Lowest layer of the current civ (Tip 0: buildings) shown as stacks ×N (true)
## or one card each with its own demolish button (false).
var stack_lowest_layer: bool = true
var theme_id: String = "cyan"
## Theme builder (theme_id "custom"): accent hue in degrees, ThemeBuilder.Harmony, saturation scale.
var theme_hue: float = 194.0
var theme_harmony: int = ThemeBuilder.Harmony.ANALOGOUS
var theme_vividness: float = 1.0

## The project theme as authored, captured before any recolour.
var _base_theme: Theme = null
var _applied_theme_key := ""

## Frame cap (laptop heat, playtest 31.10): an idle game needs no 120 fps on a
## ProMotion screen, and in the background it only has to keep ticking.
const FPS_FOCUSED := 60
const FPS_BACKGROUND := 12

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = FPS_FOCUSED
	_ensure_buses()
	load_settings()
	apply_settings()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			Engine.max_fps = FPS_BACKGROUND
		NOTIFICATION_APPLICATION_FOCUS_IN:
			Engine.max_fps = FPS_FOCUSED

func _ensure_buses() -> void:
	for bus_name in ["Music", "UI", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err == OK:
		master_volume      = config.get_value("audio",    "master_volume", 1.0)
		music_volume       = config.get_value("audio",    "music_volume",  1.0)
		ui_volume          = config.get_value("audio",    "ui_volume",     1.0)
		sfx_volume         = config.get_value("audio",    "sfx_volume",    1.0)
		is_fullscreen      = config.get_value("video",    "fullscreen",    true)
		tutorial_ever_done = config.get_value("tutorial", "ever_done",     false)
		night_shadow       = config.get_value("video",    "night_shadow",  1.0)
		stack_lowest_layer = config.get_value("ui",       "stack_lowest",  true)
		theme_id           = config.get_value("ui",       "theme",         "cyan")
		if not THEMES.has(theme_id):
			theme_id = "cyan"
		theme_hue          = config.get_value("ui",       "theme_hue",       194.0)
		theme_harmony      = config.get_value("ui",       "theme_harmony",   ThemeBuilder.Harmony.ANALOGOUS)
		theme_vividness    = config.get_value("ui",       "theme_vividness", 1.0)
		_take_preset(theme_id)   # saved builder values only count for "custom"
	else:
		master_volume = 1.0
		music_volume  = 1.0
		ui_volume     = 1.0
		sfx_volume    = 1.0
		is_fullscreen = true
		theme_id      = "cyan"

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio",    "master_volume", master_volume)
	config.set_value("audio",    "music_volume",  music_volume)
	config.set_value("audio",    "ui_volume",     ui_volume)
	config.set_value("audio",    "sfx_volume",    sfx_volume)
	config.set_value("video",    "fullscreen",    is_fullscreen)
	config.set_value("video",    "night_shadow",  night_shadow)
	config.set_value("tutorial", "ever_done",     tutorial_ever_done)
	config.set_value("ui",       "stack_lowest",  stack_lowest_layer)
	config.set_value("ui",       "theme",         theme_id)
	config.set_value("ui",       "theme_hue",       theme_hue)
	config.set_value("ui",       "theme_harmony",   theme_harmony)
	config.set_value("ui",       "theme_vividness", theme_vividness)
	config.save(SETTINGS_PATH)

func apply_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_set_bus_volume("Music",  music_volume)
	_set_bus_volume("UI",     ui_volume)
	_set_bus_volume("SFX",    sfx_volume)
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_apply_theme()

## Recolours the project theme in place (open UI follows it). Skipped when
## nothing changed, since a theme swap restyles every Control.
func _apply_theme() -> void:
	var dst := ThemeDB.get_project_theme()
	if dst == null:
		return
	if _base_theme == null:
		_base_theme = Theme.new()
		_base_theme.merge_with(dst)
	var original: bool = THEMES.get(theme_id, {}).get("original", false)
	var key := "original" if original else "%s|%.1f|%d|%.2f" % [theme_id, theme_hue, theme_harmony, theme_vividness]
	if key == _applied_theme_key:
		return
	_applied_theme_key = key
	var src := _base_theme if original else ThemeBuilder.build(_base_theme, theme_hue, theme_harmony, theme_vividness)
	dst.clear()
	dst.merge_with(src)

## The accent colour of the current theme, for a swatch.
func theme_swatch() -> Color:
	return UIStyle.color(&"accent")

## Panel / item / accent colours the builder would make, for a preview.
func theme_preview(hue: float, harmony: int, vividness: float) -> Array[Color]:
	if _base_theme == null:
		_apply_theme()
	return ThemeBuilder.preview(_base_theme, hue, harmony, vividness)

func _set_bus_volume(bus_name: String, val: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	if val <= 0.001:
		AudioServer.set_bus_volume_db(idx, -80.0)
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(val))
		AudioServer.set_bus_mute(idx, false)

func set_master_volume(val: float) -> void:
	master_volume = clamp(val, 0.0, 1.0)
	apply_settings(); save_settings()

func set_music_volume(val: float) -> void:
	music_volume = clamp(val, 0.0, 1.0)
	apply_settings(); save_settings()

func set_ui_volume(val: float) -> void:
	ui_volume = clamp(val, 0.0, 1.0)
	apply_settings(); save_settings()

func set_sfx_volume(val: float) -> void:
	sfx_volume = clamp(val, 0.0, 1.0)
	apply_settings(); save_settings()

func set_night_shadow(val: float) -> void:
	night_shadow = clamp(val, 0.0, 1.0)
	save_settings()
	night_shadow_changed.emit(night_shadow)

func set_stack_lowest_layer(val: bool) -> void:
	stack_lowest_layer = val
	save_settings()

func set_fullscreen(val: bool) -> void:
	is_fullscreen = val
	apply_settings(); save_settings()

## Picks a preset; its hue and harmony become the builder's starting point.
func set_theme_id(id: String) -> void:
	if not THEMES.has(id):
		return
	theme_id = id
	_take_preset(id)
	_apply_theme()
	save_settings()
	theme_changed.emit(theme_id)

func _take_preset(id: String) -> void:
	var preset: Dictionary = THEMES.get(id, {})
	if preset.has("hue"):
		theme_hue = preset["hue"]
		theme_harmony = preset["harmony"]
		theme_vividness = 1.0

## Theme builder: any change makes the theme "custom".
func set_custom_theme(hue: float, harmony: int, vividness: float) -> void:
	theme_id = "custom"
	theme_hue = fposmod(hue, 360.0)
	theme_harmony = harmony
	theme_vividness = clampf(vividness, 0.2, 1.3)
	_apply_theme()
	save_settings()
	theme_changed.emit(theme_id)
