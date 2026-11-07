extends Node
## Bridge from the game's original sound keys to VAM events (addons/VAM).
## Sounds, volumes, buses and variations are edited in the VAM tab, not here.
## New code can call VAM directly: VAM.play(&"ui/click").

## Old key → VAM event id. Unknown keys are passed through as ids, so VAM
## warns about them in the Output instead of failing silently.
const LEGACY := {
	"hover": &"ui/hover", "click": &"ui/click", "error": &"ui/denied",   # one "no" sound
	"skill_buy": &"ui/skill_buy", "level_up": &"sfx/upgrade_start", "survey": &"sfx/scan",
	"clink": &"ui/clink", "poi_hover": &"ui/poi_hover", "district_hover": &"ui/district_hover",
	"poi_ping": &"ui/poi_ping", "poi_select": &"ui/poi_select", "cash": &"sfx/income",
	"achievement": &"ui/achievement", "tick": &"ui/tick",
	"ui_click": &"ui/click",   # was silent before: no sound had this key
	"denied": &"ui/denied",
	"construct": &"sfx/construct", "rocket": &"sfx/rocket", "building_done": &"sfx/building_done",
	"terrain_earth": &"sfx/terrain_earth", "terrain_water": &"sfx/terrain_water",
	"terrain_sand": &"sfx/terrain_sand", "terrain_ice": &"sfx/terrain_ice",
	"terrain_fire": &"sfx/terrain_fire", "terrain_dust": &"sfx/terrain_dust",
	"terrain_gas": &"sfx/terrain_gas",
}
## While the open planet has a district or building under construction.
const CONSTRUCTION_LOOP := &"sfx/construction_loop"
## A district or building on the open planet finished construction.
const CONSTRUCTION_DONE := &"sfx/construction_done"
## While the open planet runs another timed process: a level-up (planet, City,
## Orbit, district) or a surface scan. Shares its clip with CONSTRUCTION_LOOP,
## so only one of the two plays; construction wins.
const PROCESS_LOOP := &"sfx/ProcessLoop"
## One of those processes finished.
const PROCESS_DONE := &"sfx/processDone"
const AMBIENCE := &"music/space_drone"
const MUSIC := &"music/main"
## Credits came in; the event's cooldown keeps steady income from chiming nonstop.
const INCOME := &"sfx/income"
## An expedition finished preparing (GameState.expedition_ready).
const READY := &"sfx/ready"
## Every button hover in the game, and every interactive item in the left
## panel, plays this one event. Scripts don't call it themselves; see _process.
const HOVER := &"ui/hover"
## Every button press in the game plays this one event — BaseButtons and
## controls with their own `pressed` signal (ListItem cards) — unless the button
## opted out with no_click(). Sounds a handler plays for the press (an error, a
## purchase…) come on top of it. See _on_button_pressed.
const CLICK := &"ui/click"
## Meta on a button that must stay silent when pressed (no_click()).
const NO_CLICK_META := &"no_click"
## Clicking a disabled button plays this instead (disabled buttons emit no pressed).
const DENIED := &"ui/denied"

var _loop: StringName = &""   # CONSTRUCTION_LOOP, PROCESS_LOOP or none
var _done_frames := {}         # done event id → last frame it played
var _click_frame := -1
var _hover_target: Control = null
var _hover_moved := false
var _hover_frame := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	VAM.play(AMBIENCE)
	VAM.play_music(MUSIC)
	GameState.credits_earned.connect(func(_amount: float) -> void: _play_game_event(INCOME))
	GameState.expedition_ready.connect(func(_kind: String) -> void: _play_game_event(READY))
	get_tree().node_added.connect(_watch_button)
	_watch_tree.call_deferred(get_tree().root)   # buttons other autoloads built before us


## The loaded save keeps simulating behind the main menu (ProductionManager is
## an autoload), so its income and expeditions stay silent until the game is open.
func _play_game_event(id: StringName) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path.ends_with("MainMenu.tscn"):
		return
	VAM.play(id)


## What the open planet is busy with; picks the one loop that should play.
## Call with (false, false) when the planet view goes away.
func set_activity(constructing: bool, processing: bool) -> void:
	var want: StringName = CONSTRUCTION_LOOP if constructing else (PROCESS_LOOP if processing else &"")
	if want == _loop:
		return
	if _loop != &"":
		VAM.stop(_loop)
	_loop = want
	if want != &"":
		VAM.play(want)


func construction_done() -> void:
	_play_done(CONSTRUCTION_DONE)


func process_done() -> void:
	_play_done(PROCESS_DONE)


## At most once a frame: a prefab's buildings finish together.
func _play_done(id: StringName) -> void:
	var frame := Engine.get_process_frames()
	if _done_frames.get(id, -1) == frame:
		return
	_done_frames[id] = frame
	VAM.play(id)


func play(sound: String, vol_db: float = 0.0) -> void:
	var id: StringName = LEGACY.get(sound, StringName(sound))
	if id == HOVER:
		_play_hover()
		return
	if id == CLICK:
		_play_click(vol_db)
		return
	VAM.play(id, vol_db)


# ── click ──────────────────────────────────────────────────────────────

func _watch_tree(n: Node) -> void:
	_watch_button(n)
	for c in n.get_children():
		_watch_tree(c)


func _watch_button(n: Node) -> void:
	if n.has_meta(&"_click_watched"):
		return
	if n is BaseButton or (n is Control and n.has_signal(&"pressed")):
		n.set_meta(&"_click_watched", true)
		n.connect(&"pressed", _on_button_pressed.bind(n))


## Keeps `button` silent when pressed: the one way out of the click.
static func no_click(button: Control) -> void:
	button.set_meta(NO_CLICK_META, true)


func _on_button_pressed(button: Control) -> void:
	if not button.has_meta(NO_CLICK_META):
		_play_click()


## CLICK, at most once a frame: a handler that still calls play("click") for
## the same press doesn't double it.
func _play_click(vol_db: float = 0.0) -> void:
	var frame := Engine.get_process_frames()
	if frame == _click_frame:
		return
	_click_frame = frame
	VAM.play(CLICK, vol_db)


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
