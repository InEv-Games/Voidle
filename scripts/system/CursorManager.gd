## CursorManager — autoload singleton.
## Hides the OS cursor and renders a minimal vector cursor pack (SVG) on a top CanvasLayer.
## Usage: CursorManager.set_state(CursorManager.State.POINTER)
extends Node

enum State { NORMAL, HOVER, SPACE, GRAB, EXIT, POINTER, IBEAM }

const DIR          := "res://resources/ui/cursors/"
const SIZE         := 24.0
const RASTER_SCALE := 2.0
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

var _state:    State               = State.NORMAL
var _layer:    CanvasLayer         = null
var _sprite:   TextureRect         = null
var _textures: Array[Texture2D]    = []
var _hotspots: Array[Vector2]      = []

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
			if _sprite: _sprite.visible = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
			if _sprite: _sprite.visible = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rebuild_textures()

	# Hide OS cursor
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)

	# CanvasLayer on top of everything
	_layer       = CanvasLayer.new()
	_layer.layer = 500
	_layer.name  = "CursorLayer"
	add_child(_layer)

	_sprite                = TextureRect.new()
	_sprite.mouse_filter   = Control.MOUSE_FILTER_IGNORE
	_sprite.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.size           = Vector2(SIZE, SIZE)
	_layer.add_child(_sprite)

	set_state(State.NORMAL)
	call_deferred("_connect_theme_signal")

func _connect_theme_signal() -> void:
	var sm := get_node_or_null("/root/SettingsManager")
	if sm != null and sm.has_signal("theme_changed"):
		sm.connect("theme_changed", func(_theme_id: String) -> void: _rebuild_textures())

func _rebuild_textures() -> void:
	_textures.clear()
	_hotspots.clear()
	var accent_hex := "#" + UIStyle.hex(&"accent").to_upper()
	for i in FILES.size():
		_textures.append(_load_vector_cursor(FILES[i], accent_hex))
		_hotspots.append(HOTSPOTS[i])
	if _sprite != null and _state < _textures.size():
		_sprite.texture = _textures[_state]

func _process(_delta: float) -> void:
	if _sprite == null:
		return
	var mouse := _sprite.get_viewport().get_mouse_position()
	var hot   := _hotspots[_state]
	_sprite.position = mouse - hot

func set_state(s: State) -> void:
	if _state == s and _sprite != null and _sprite.texture != null:
		return
	_state = s
	if _sprite != null:
		_sprite.texture = _textures[s]

# ── Internal ──────────────────────────────────────────────────────────────────

func _load_vector_cursor(file_name: String, accent_hex: String) -> Texture2D:
	var path := DIR + file_name + ".svg"
	var svg_text := ""
	if FileAccess.file_exists(path):
		svg_text = FileAccess.get_file_as_string(path)
	if svg_text.is_empty():
		svg_text = String(FALLBACK_SVGS.get(file_name, ""))
	if not svg_text.is_empty():
		svg_text = svg_text.replace(SVG_ACCENT, accent_hex)
		var img := Image.new()
		if img.load_svg_from_string(svg_text, RASTER_SCALE) == OK:
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path) as Texture2D
		if res != null:
			return res
	return ImageTexture.new()
