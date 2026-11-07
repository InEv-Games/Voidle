extends Node
## Bridge from the game's original sound keys to VAM events (addons/VAM).
## Sounds, volumes, buses and variations are edited in the VAM tab, not here.
## New code can call VAM directly: VAM.play(&"ui/click").

## Old key → VAM event id. Unknown keys are passed through as ids, so VAM
## warns about them in the Output instead of failing silently.
const LEGACY := {
	"hover": &"ui/hover", "click": &"ui/click", "error": &"ui/error",
	"skill_buy": &"ui/skill_buy", "level_up": &"ui/level_up", "survey": &"ui/survey",
	"clink": &"ui/clink", "poi_hover": &"ui/poi_hover", "district_hover": &"ui/district_hover",
	"poi_ping": &"ui/poi_ping", "poi_select": &"ui/poi_select", "cash": &"ui/cash",
	"achievement": &"ui/achievement", "tick": &"ui/tick",
	"ui_click": &"ui/click",   # was silent before: no sound had this key
	"construct": &"sfx/construct", "rocket": &"sfx/rocket", "building_done": &"sfx/building_done",
	"terrain_earth": &"sfx/terrain_earth", "terrain_water": &"sfx/terrain_water",
	"terrain_sand": &"sfx/terrain_sand", "terrain_ice": &"sfx/terrain_ice",
	"terrain_fire": &"sfx/terrain_fire", "terrain_dust": &"sfx/terrain_dust",
	"terrain_gas": &"sfx/terrain_gas",
}
const CONSTRUCT_LOOP := &"sfx/construct_loop"
const AMBIENCE := &"music/space_drone"
const MUSIC := &"music/main"
const CASH := &"ui/cash"   # throttled by the event's cooldown
## Every button hover in the game, and every interactive item in the left
## panel, plays this one event. Scripts don't call it themselves; see _process.
const HOVER := &"ui/hover"
## Every button press in the game plays this one event, unless the button's own
## code plays a sound for that press (an error, a purchase…). See _on_button_pressed.
const CLICK := &"ui/click"
## Clicking a disabled button plays this instead (disabled buttons emit no pressed).
const DENIED := &"ui/denied"

var _construct_active := false
var _click_pending := false
var _sound_since_press := false
var _hover_target: Control = null
var _hover_moved := false
var _hover_frame := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	VAM.play(AMBIENCE)
	VAM.play_music(MUSIC)
	GameState.credits_changed.connect(func(_v: float) -> void: VAM.play(CASH))
	get_tree().node_added.connect(_watch_button)
	_watch_tree.call_deferred(get_tree().root)   # buttons other autoloads built before us


func set_construction_active(active: bool) -> void:
	if active == _construct_active:
		return
	_construct_active = active
	if active:
		VAM.play(CONSTRUCT_LOOP)
	else:
		VAM.stop(CONSTRUCT_LOOP)


func play(sound: String, vol_db: float = 0.0) -> void:
	var id: StringName = LEGACY.get(sound, StringName(sound))
	if id == HOVER:
		_play_hover()
		return
	_sound_since_press = true   # a button handler chose its own sound: no generic click
	VAM.play(id, vol_db)


# ── click ──────────────────────────────────────────────────────────────

func _watch_tree(n: Node) -> void:
	_watch_button(n)
	for c in n.get_children():
		_watch_tree(c)


func _watch_button(n: Node) -> void:
	if n is BaseButton and not (n as BaseButton).pressed.is_connected(_on_button_pressed):
		# Connected as the button enters the tree, so before the game's own handlers
		# (they connect in _ready): the click waits until those have run.
		(n as BaseButton).pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	_sound_since_press = false
	if not _click_pending:
		_click_pending = true
		_flush_click.call_deferred()


## Runs after every handler of the press: plays CLICK unless one of them already
## played a sound (play("error"), play("click"), play("skill_buy")…).
func _flush_click() -> void:
	_click_pending = false
	if not _sound_since_press:
		VAM.play(CLICK)
	_sound_since_press = false


# ── hover ──────────────────────────────────────────────────────────────

## One hover sound for the whole UI: when the mouse moves onto a new hover
## target, play HOVER once. Only real mouse movement counts, so a panel that
## rebuilds itself under a still mouse stays quiet.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover_moved = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var b := disabled_button_at(get_viewport().gui_get_hovered_control())
		if b != null:
			VAM.play(DENIED)


## The disabled button `c` belongs to (itself or an ancestor), or null. Only the
## nearest button counts: an enabled button inside wins over a disabled frame.
static func disabled_button_at(c: Control) -> BaseButton:
	var n: Node = c
	while n != null:
		if n is BaseButton:
			return n if (n as BaseButton).disabled and (n as BaseButton).is_visible_in_tree() else null
		n = n.get_parent()
	return null


func _process(_delta: float) -> void:
	var target := hover_target_for(get_viewport().gui_get_hovered_control())
	var moved := _hover_moved
	_hover_moved = false
	if target == _hover_target:
		return
	_hover_target = target
	if target != null and moved:
		_play_hover()


## A card with its own play("hover") and this watcher can both fire on the same
## mouse move; once per frame is enough.
func _play_hover() -> void:
	var frame := Engine.get_process_frames()
	if frame == _hover_frame:
		return
	_hover_frame = frame
	VAM.play(HOVER)


## What a hover over `c` counts as, or null:
## - anywhere: the nearest enabled button (IconButton, Button, CheckBox…);
## - inside the LeftPanel also its interactive rows and cards (ListItem, or a
##   panel that reacts to the mouse), while the panel isn't opening / closing.
static func hover_target_for(c: Control) -> Control:
	var button: BaseButton = null
	var item: Control = null
	var panel: LeftPanel = null
	var n: Node = c
	while n != null:
		if n is LeftPanel:
			panel = n
			break
		if button == null and item == null:
			if n is BaseButton:
				button = n
			elif n is ListItem or (n is Control and _reacts_to_mouse(n)):
				item = n
		n = n.get_parent()
	if panel != null and panel.is_animating():
		return null
	if button != null:
		return null if button.disabled else button
	return item if panel != null else null


static func _reacts_to_mouse(c: Control) -> bool:
	if c is Label or c is RichTextLabel or c.mouse_filter != Control.MOUSE_FILTER_STOP:
		return false
	return not c.gui_input.get_connections().is_empty() or not c.mouse_entered.get_connections().is_empty()
