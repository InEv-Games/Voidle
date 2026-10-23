## DemoSignup — the demo end screen's "stay in touch" block
## (scenes/ui/DemoSignup.tscn): a WISHLIST ON STEAM button and an email field
## that posts to the Google Sheet. Links come from DemoConfig
## (res://resources/demo/demo_config.tres); a part hides itself when its URL
## is empty. Layout, texts and colours are edited in the scene; the messages
## below in the Inspector.
##
## The request goes out as text/plain JSON: no CORS preflight, so the browser
## sends it to Apps Script, which writes the row even when the browser can't
## read the reply. A sent request therefore counts as success.
extends VBoxContainer

@export_multiline var msg_bad_email := "That doesn't look like an email address."
@export_multiline var msg_sending := "Sending…"
@export_multiline var msg_thanks := "Thanks! You're on the list."
@export_multiline var msg_failed := "Couldn't reach the server — please try again."
@export var ok_color := Color(0.6, 1.0, 0.7)
@export var error_color := Color(1.0, 0.6, 0.5)

const EMAIL_RE := "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"

@onready var _wishlist: Button = %WishlistButton
@onready var _email_box: Control = %EmailBox
@onready var _field: LineEdit = %EmailField
@onready var _send: Button = %SendButton
@onready var _status: Label = %Status
@onready var _http: HTTPRequest = %Http

var _cfg: DemoConfig
var _sent := false

func _ready() -> void:
	_cfg = DemoConfig.get_config()
	_wishlist.visible = _cfg.steam_url != ""
	_wishlist.pressed.connect(func() -> void:
		AudioManager.play("click")
		OS.shell_open(_cfg.steam_url))
	_email_box.visible = _cfg.signup_url != ""
	_status.text = ""
	_field.text_submitted.connect(func(_t: String) -> void: _submit())
	_send.pressed.connect(_submit)
	_http.request_completed.connect(_on_done)
	visible = _wishlist.visible or _email_box.visible

func _submit() -> void:
	if _sent:
		return
	var email := _field.text.strip_edges()
	if not RegEx.create_from_string(EMAIL_RE).search(email):
		_show(msg_bad_email, false)
		return
	var stats := GameState.demo_stats()
	var body := JSON.stringify({"email": email, "played_min": stats.get("minutes", 0), "source": _cfg.signup_source})
	var err := _http.request(_cfg.signup_url, PackedStringArray(["Content-Type: text/plain;charset=utf-8"]),
		HTTPClient.METHOD_POST, body)
	if err != OK:
		_show(msg_failed, false)
		return
	_send.disabled = true
	_field.editable = false
	_show(msg_sending, true)

func _on_done(result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	# in the browser the reply may be unreadable (CORS) even though the row was
	# written: anything but a connection failure counts as sent
	if result == HTTPRequest.RESULT_CANT_CONNECT or result == HTTPRequest.RESULT_CANT_RESOLVE \
			or result == HTTPRequest.RESULT_TIMEOUT:
		_send.disabled = false
		_field.editable = true
		_show(msg_failed, false)
		return
	_sent = true
	_show(msg_thanks, true)

func _show(text: String, ok: bool) -> void:
	_status.text = text
	_status.add_theme_color_override("font_color", ok_color if ok else error_color)
