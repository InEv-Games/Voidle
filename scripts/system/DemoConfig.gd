## DemoConfig — the itch.io demo's links, edited in the Inspector:
## open res://resources/demo/demo_config.tres (ITCH_DEMO_PLAN.md).
## An empty URL hides its button / form.
class_name DemoConfig
extends Resource

const PATH := "res://resources/demo/demo_config.tres"

@export_group("Links")
## Steam store page for the WISHLIST ON STEAM button (e.g. https://store.steampowered.com/app/…/Voidle/).
@export var steam_url: String = ""
## Google Apps Script web app URL (ends with /exec) that appends signups to the Sheet.
@export var signup_url: String = ""
## Tag stored with each signup (which build it came from).
@export var signup_source: String = "itch-web"

static var _cached: DemoConfig

## The project's demo config (an empty one if the file is missing).
static func get_config() -> DemoConfig:
	if _cached == null:
		_cached = load(PATH) as DemoConfig if ResourceLoader.exists(PATH) else DemoConfig.new()
	return _cached
