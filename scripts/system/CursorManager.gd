## CursorManager — autoload singleton.
## Gives the OS a minimal vector cursor pack (SVG, theme accent) as hardware cursors.
## Usage: CursorManager.set_state(CursorManager.State.POINTER)
extends Node

enum State { NORMAL, HOVER, SPACE, GRAB, EXIT, POINTER, IBEAM }

const DIR          := "res://resources/ui/cursors/"
const SIZE         := 24.0
const SVG_ACCENT   := "#59D1FF"

const FILES: Array[String] = [
	"normal",
	"hover",
	"space",
	"grab",
	"exit",
	"pointer",
	"ibeam",
]

const HOTSPOTS: Array[Vector2] = [
	Vector2(3.5, 2.5),    # NORMAL
	Vector2(12.0, 12.0),  # HOVER
	Vector2(12.0, 12.0),  # SPACE
	Vector2(12.0, 12.0),  # GRAB
	Vector2(12.0, 12.0),  # EXIT
	Vector2(3.5, 2.5),    # POINTER (same geometry & hotspot as NORMAL, painted in accent color)
	Vector2(12.0, 12.0),  # IBEAM
]

const FALLBACK_SVGS: Dictionary = {
	"normal": '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M3.5 2.5L19.5 10.5L11.5 12.5L8.5 20.5L3.5 2.5Z" fill="#F0F5FF" stroke="#0A0D18" stroke-width="1.75" stroke-linejoin="round"/><path d="M5.4 4.8L11.0 11.8" stroke="#59D1FF" stroke-width="1.2" stroke-linecap="round" opacity="0.85"/></svg>',
	"hover": '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"><g stroke="#0A0D18" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8.5V4H8.5"/><path d="M15.5 4H20V8.5"/><path d="M20 15.5V20H15.5"/><path d="M8.5 20H4V15.5"/></g><g stroke="#59D1FF" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M4 8.5V4H8.5"/><path d="M15.5 4H20V8.5"/><path d="M20 15.5V20H15.5"/><path d="M8.5 20H4V15.5"/></g><circle cx="12" cy="12" r="1.8" fill="#F0F5FF" stroke="#0A0D18" stroke-width="1.2"/></svg>',
	"space": '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"><g stroke="#0A0D18" stroke-width="3.0" stroke-linecap="round"><line x1="12" y1="3" x2="12" y2="7.5"/><line x1="12" y1="16.5" x2="12" y2="21"/><line x1="3" y1="12" x2="7.5" y2="12"/><line x1="16.5" y1="12" x2="21" y2="12"/></g><circle cx="12" cy="12" r="3.2" stroke="#0A0D18" stroke-width="2.8"/><circle cx="12" cy="12" r="3.2" stroke="#59D1FF" stroke-width="1.4"/><g stroke="#F0F5FF" stroke-width="1.5" stroke-linecap="round"><line x1="12" y1="3" x2="12" y2="7.5"/><line x1="12" y1="16.5" x2="12" y2="21"/><line x1="3" y1="12" x2="7.5" y2="12"/><line x1="16.5" y1="12" x2="21" y2="12"/></g></svg>',
	"grab": '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"><g stroke="#0A0D18" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M9.5 5.5L12 3L14.5 5.5"/><path d="M9.5 18.5L12 21L14.5 18.5"/><path d="M5.5 9.5L3 12L5.5 14.5"/><path d="M18.5 9.5L21 12L18.5 14.5"/></g><g stroke="#F0F5FF" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M9.5 5.5L12 3L14.5 5.5"/><path d="M9.5 18.5L12 21L14.5 18.5"/><path d="M5.5 9.5L3 12L5.5 14.5"/><path d="M18.5 9.5L21 12L18.5 14.5"/></g><circle cx="12" cy="12" r="2.2" fill="#59D1FF" stroke="#0A0D18" stroke-width="1.5"/></svg>',
	"exit": '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"><g stroke="#0A0D18" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"><line x1="4" y1="7" x2="4" y2="17"/><polyline points="12.5,7 7.5,12 12.5,17"/><line x1="8" y1="12" x2="20" y2="12"/></g><line x1="4" y1="7" x2="4" y2="17" stroke="#59D1FF" stroke-width="1.8" stroke-linecap="round"/><polyline points="12.5,7 7.5,12 12.5,17" stroke="#59D1FF" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><line x1="8" y1="12" x2="20" y2="12" stroke="#F0F5FF" stroke-width="1.8" stroke-linecap="round"/></svg>',
	"pointer": '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M3.5 2.5L19.5 10.5L11.5 12.5L8.5 20.5L3.5 2.5Z" fill="#59D1FF" stroke="#0A0D18" stroke-width="1.75" stroke-linejoin="round"/><path d="M5.4 4.8L11.0 11.8" stroke="#F0F5FF" stroke-width="1.2" stroke-linecap="round" opacity="0.85"/></svg>',
	"ibeam": '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"><g stroke="#0A0D18" stroke-width="3.2" stroke-linecap="round"><line x1="9" y1="4" x2="15" y2="4"/><line x1="12" y1="4" x2="12" y2="20"/><line x1="9" y1="20" x2="15" y2="20"/></g><g stroke="#F0F5FF" stroke-width="1.5" stroke-linecap="round"><line x1="9" y1="4" x2="15" y2="4"/><line x1="12" y1="4" x2="12" y2="20"/><line x1="9" y1="20" x2="15" y2="20"/></g><circle cx="12" cy="12" r="1.6" fill="#59D1FF"/></svg>',
}

## The cursors are OS (hardware) cursors, so they draw above popups and
## dropdowns too (playtest 07.11: a CanvasLayer sprite went behind embedded
## popup windows) and without lag. Godot shows ARROW over any Control, so the
## current state's image is what ARROW is; Controls asking for a shape of their
## own get the matching image.
const FIXED_SHAPES := {
	Input.CURSOR_POINTING_HAND: State.POINTER,
	Input.CURSOR_IBEAM: State.IBEAM,
	Input.CURSOR_DRAG: State.GRAB,
	Input.CURSOR_MOVE: State.GRAB,
	Input.CURSOR_CROSS: State.HOVER,
}

var _state: State = State.NORMAL
var _scale := 0.0   # cursor pixels per SIZE unit the images were made at
var _images: Array[Image] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rebuild_textures()
	get_tree().root.size_changed.connect(_on_window_resized)
	set_state(State.NORMAL)
	call_deferred("_connect_theme_signal")

# ── Keys play: the cursor hides (10.11) ──────────────────────────────────────
## A key that moves or acts (arrows, WASD, Tab, Enter, Space, Q / E …) or a pad
## button hides the mouse cursor; the mouse moving or clicking brings it back.
## Shortcuts with Cmd / Ctrl and typing in a box leave it alone.
var keys_mode := false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if keys_mode and (event as InputEventMouseMotion).relative.length_squared() > 4.0:
			_set_keys_mode(false)
		return
	if event is InputEventMouseButton:
		if keys_mode and (event as InputEventMouseButton).pressed:
			_set_keys_mode(false)
		return
	if keys_mode:
		return
	if event is InputEventJoypadButton and (event as InputEventJoypadButton).pressed:
		_set_keys_mode(true)
		return
	if event is InputEventJoypadMotion:
		var jm := event as InputEventJoypadMotion
		if jm.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y] \
				and absf(jm.axis_value) > 0.3:
			_set_keys_mode(true)
		return
	var k := event as InputEventKey
	if k == null or not k.pressed or k.ctrl_pressed or k.meta_pressed or k.alt_pressed:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	var key := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
	if key in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_W, KEY_A, KEY_S, KEY_D, KEY_Q, KEY_E,
			KEY_TAB, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_BACKSPACE]:
		_set_keys_mode(true)

func _set_keys_mode(on: bool) -> void:
	keys_mode = on
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if on else Input.MOUSE_MODE_VISIBLE
	var anchor = TooltipManager._focus_anchor
	if on and (anchor == null or not is_instance_valid(anchor)):
		TooltipManager.hide_tip()   # the tip the resting mouse had goes with it

func _connect_theme_signal() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and sm.has_signal("theme_changed"):
		sm.connect("theme_changed", func(_theme_id: String) -> void: _rebuild_textures())

func _on_window_resized() -> void:
	if not is_equal_approx(_cursor_scale(), _scale):
		_rebuild_textures()

## Window pixels per UI unit (the stretch scale), so the cursor keeps the size it
## had as a UI sprite; macOS takes cursor images in points, not pixels.
func _cursor_scale() -> float:
	var root := get_tree().root
	var k := root.get_final_transform().get_scale().x if root != null else 1.0
	if OS.get_name() == "macOS":
		k /= maxf(DisplayServer.screen_get_scale(), 1.0)
	return clampf(k, 0.5, 4.0)

func _rebuild_textures() -> void:
	_scale = _cursor_scale()
	var accent_hex := "#" + UIStyle.hex(&"accent").to_upper()
	_images.clear()
	for i in FILES.size():
		_images.append(_load_vector_cursor(FILES[i], accent_hex, _scale))
	for shape: int in FIXED_SHAPES:
		_apply(FIXED_SHAPES[shape], shape)
	_apply(_state, Input.CURSOR_ARROW)

func _apply(s: int, shape: int) -> void:
	if s < _images.size() and _images[s] != null:
		Input.set_custom_mouse_cursor(_images[s], shape as Input.CursorShape, HOTSPOTS[s] * _scale)

func set_state(s: State) -> void:
	if s == _state and not _images.is_empty():
		return
	_state = s
	_apply(s, Input.CURSOR_ARROW)

# ── Internal ──────────────────────────────────────────────────────────────────

func _load_vector_cursor(file_name: String, accent_hex: String, k: float) -> Image:
	var path := DIR + file_name + ".svg"
	var svg_text := ""
	if FileAccess.file_exists(path):
		svg_text = FileAccess.get_file_as_string(path)
	if svg_text.is_empty():
		svg_text = String(FALLBACK_SVGS.get(file_name, ""))
	if svg_text.is_empty():
		return null
	svg_text = svg_text.replace(SVG_ACCENT, accent_hex)
	var img := Image.new()
	# SVGs are 24 units wide: render at the cursor scale (OS limit 256 px)
	if img.load_svg_from_string(svg_text, k * SIZE / 24.0) != OK:
		return null
	return img
