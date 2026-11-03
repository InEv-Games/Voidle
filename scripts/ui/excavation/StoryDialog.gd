class_name StoryDialog
extends Control

## An excavation, start to end: the site; its opening (a VSM graph's "start"
## entry); the price and how long it takes; the crews at work; when they're done,
## the rest of the story ("return" entry) with its choices; what it paid and who
## joined. Opened again from the map mark, it picks up at the stage the dig is at.
## Layout: scenes/ui/excavation/StoryDialog.tscn.

const SCENE_PATH := "res://scenes/ui/excavation/StoryDialog.tscn"
const LAYER := 235
## How fast story text types itself, in characters per second.
const TYPE_CPS := 55.0

enum Page { SITE, OPENING, PAY, DIGGING, RETURN, END }

var site: ExcavationSiteDef
var _page := Page.SITE
var _mgr: VSMManager = null
var _typing: Tween = null
var _bb_len := 0

@onready var _card: Control = $Center/Card
@onready var _title: Label = $Center/Card/VBox/Header/Title
@onready var _counter: Label = $Center/Card/VBox/Header/Counter
@onready var _scene_icon: TextureRect = $Center/Card/VBox/Row/Frame/SceneIcon
@onready var _portrait: TextureRect = $Center/Card/VBox/Row/Frame/Portrait
@onready var _speaker: Label = $Center/Card/VBox/Row/Col/Speaker
@onready var _body: RichTextLabel = $Center/Card/VBox/Row/Col/Body
@onready var _details: Control = $Center/Card/VBox/Row/Col/Details
@onready var _time_row: InfoRow = $Center/Card/VBox/Row/Col/Details/TimeRow
@onready var _returns: RichTextLabel = $Center/Card/VBox/Row/Col/Details/ReturnsRow/Value
@onready var _time_box: PanelContainer = $Center/Card/VBox/Row/Col/TimeBox
@onready var _time: Label = $Center/Card/VBox/Row/Col/TimeBox/Time
@onready var _rewards: RichTextLabel = $Center/Card/VBox/Row/Col/Rewards
@onready var _block: RichTextLabel = $Center/Card/VBox/Row/Col/Block
@onready var _choices: VBoxContainer = $Center/Card/VBox/Row/Col/Choices
@onready var _buttons: Control = $Center/Card/VBox/Buttons
@onready var _later: IconButton = $Center/Card/VBox/Buttons/Later
@onready var _next: IconButton = $Center/Card/VBox/Buttons/Next

## The panels of this mechanic open and close the same way.
static func pop_in(card: Control) -> void:
	card.modulate.a = 0.0
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.97, 0.97)
	var tw := card.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.16)
	tw.tween_property(card, "scale", Vector2.ONE, 0.16)

static func pop_out(card: Control, layer: Node) -> void:
	TooltipManager.hide_tip()
	var tw := card.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(card, "modulate:a", 0.0, 0.1)
	tw.tween_callback(layer.queue_free)

static func open(host: Node, site_id: String) -> void:
	var s := Excavations.find_site(site_id)
	if s == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	host.get_tree().root.add_child(layer)
	var d := (load(SCENE_PATH) as PackedScene).instantiate() as StoryDialog
	d.site = s
	layer.add_child(d)
	AudioManager.play("click")

func _ready() -> void:
	_later.pressed.connect(_close)
	_next.pressed.connect(_on_next)
	_counter.text = _counter_text()
	_title.text = site.display_name.to_upper()
	($Center/Card as Control).gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_skip_typing())
	ProgressFill.attach(_time_box, UIStyle.color(&"accent"), _dig_progress, true)
	match Excavations.stage(site):
		Excavations.Stage.DIGGING:
			_show_digging()
		Excavations.Stage.READY:
			_play(Page.RETURN, ExcavationSiteDef.ENTRY_RETURN)
		_:
			_show_site()
	pop_in.call_deferred(_card)

func _process(_delta: float) -> void:
	if _page != Page.DIGGING:
		return
	if Excavations.stage(site) == Excavations.Stage.READY:
		_time.text = "READY"
		_next.label_text = "CONTINUE"
	else:
		_time.text = Excavations.time_text(Excavations.time_left(site))

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match (event as InputEventKey).keycode:
		KEY_SPACE, KEY_ENTER:
			get_viewport().set_input_as_handled()
			if _typing != null:
				_skip_typing()
			elif _next.visible and not _next.disabled:
				_on_next()
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if _page != Page.RETURN:   # the dig is paid: its story plays out
				_close()

func _dig_progress() -> float:
	return 1.0 - Excavations.time_left(site) / maxf(site.duration_sec, 1.0)

## "VESYN  2 / 5".
func _counter_text() -> String:
	var w := Excavations.world_of_site(site.site_id)
	var world := w.planet() if w != null else null
	var at := w.sites.find(site) + 1 if w != null else 1
	var total := w.sites.size() if w != null else 1
	return "%s  %d / %d" % [world.planet_name.to_upper() if world != null else "", at, total]

func _close() -> void:
	set_process_unhandled_input(false)
	pop_out(_card, get_parent())

## Types `text` into the body; the buttons and choices fade in when it's done.
func _type(text: String) -> void:
	_body.text = text
	_body.visible_characters = 0
	_buttons.modulate.a = 0.0
	_choices.modulate.a = 0.0
	if _typing != null:
		_typing.kill()
	var chars := _body.get_total_character_count()
	_typing = create_tween()
	_typing.tween_property(_body, "visible_characters", chars, chars / TYPE_CPS)
	_typing.tween_callback(_done_typing)

func _skip_typing() -> void:
	if _typing != null:
		_typing.kill()
		_done_typing()

func _done_typing() -> void:
	_typing = null
	_body.visible_characters = -1
	_reveal(_buttons)
	_reveal(_choices)

func _reveal(c: Control) -> void:
	create_tween().tween_property(c, "modulate:a", 1.0, 0.18)

## A portrait for who's speaking; the scene's icon when no one is.
func _show_face(who: CompanionDef) -> void:
	var was: Texture2D = _portrait.texture if _portrait.visible else null
	_portrait.visible = who != null
	_scene_icon.visible = who == null
	if who != null:
		_portrait.texture = who.portrait_texture()
		if was != _portrait.texture:
			_portrait.modulate.a = 0.0
			_reveal(_portrait)

func _on_next() -> void:
	if _typing != null:   # the first press finishes the line
		_skip_typing()
		return
	match _page:
		Page.SITE:
			AudioManager.play("click")
			_play(Page.OPENING, ExcavationSiteDef.ENTRY_OPENING)
		Page.OPENING, Page.RETURN:
			_mgr.advance()
		Page.PAY:
			if Excavations.start(site):
				AudioManager.play("building_done")
				_show_digging()
			else:
				AudioManager.play("error")
		Page.DIGGING:
			if Excavations.stage(site) == Excavations.Stage.READY:
				_play(Page.RETURN, ExcavationSiteDef.ENTRY_RETURN)
			else:
				_close()
		Page.END:
			_close()

## The site's name and teaser, nothing to pay yet.
func _show_site() -> void:
	_page = Page.SITE
	_show_face(null)
	_body.text = site.teaser
	_next.label_text = "INVESTIGATE"
	var why := ""
	var w := Excavations.world_of_site(site.site_id)
	if w == null or Excavations.next_site(w) != site:
		why = "Finish the excavation before it first"
	_next.disabled = why != ""
	_block.text = why
	_block.visible = why != ""

func _play(page: Page, entry: String) -> void:
	_page = page
	_block.visible = false
	_time_box.visible = false
	_details.visible = false
	_rewards.visible = false
	_later.visible = page == Page.OPENING   # nothing is paid yet
	_next.counter_items = PackedStringArray()
	_next.label_text = "CONTINUE"
	_next.disabled = false
	_next.visible = true
	_mgr = VSMManager.new()
	_mgr.dialogue_shown.connect(_on_line)
	_mgr.choices_shown.connect(_on_choices)
	_mgr.story_finished.connect(_on_finished)
	_mgr.start(site.story, entry)

func _on_line(speaker: String, text: String) -> void:
	_clear_choices()
	_show_face(_companion_named(speaker))
	_speaker.visible = speaker != "Narrator"
	_speaker.text = speaker
	_next.visible = true
	_type(text)
	# the choices stand under the line they answer: no "continue" in between
	if _visible_exits(_mgr._current as VSMDialogueNodeData) > 1:
		_mgr.advance()

func _visible_exits(line: VSMDialogueNodeData) -> int:
	var n := 0
	for e: VSMExitLink in line.exits:
		if e.is_visible(_mgr.blackboard):
			n += 1
	return n

func _on_choices(texts: Array[String]) -> void:
	_clear_choices()
	_next.visible = false
	for i in texts.size():
		var b := IconButton.create(texts[i], "confirm", IconButton.Variant.DEFAULT)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var at := i
		b.pressed.connect(func() -> void:
			if _typing != null:
				_skip_typing()
				return
			AudioManager.play("click")
			_mgr.choose(at))
		_choices.add_child(b)

func _clear_choices() -> void:
	for c in _choices.get_children():
		_choices.remove_child(c)
		c.queue_free()

func _on_finished(_exit_name: String) -> void:
	_clear_choices()
	if _page == Page.OPENING:
		_show_pay()
	else:
		_show_end()

## The opening's last line stays; under it how long it takes and what it returns
## at least, the price on the button.
func _show_pay() -> void:
	_page = Page.PAY
	_later.visible = true
	_next.visible = true
	_time_row.value = Excavations.time_text(site.duration_sec)
	_returns.text = "[right]%s[/right]" % _amounts_bb(site.reward)
	_details.visible = true
	_next.label_text = "EXCAVATE"
	var items := PackedStringArray()
	for id: String in site.cost:
		items.append("%s:%s" % [id, Economy.fmt(float(site.cost[id]))])
	_next.counter_items = items
	var why := Excavations.start_block(site)
	_next.disabled = why != ""
	_block.text = _missing_bb() if Economy.cost_block(site.cost) != "" else why
	_block.visible = why != ""
	_details.modulate.a = 0.0
	_reveal(_details)

func _show_digging() -> void:
	_page = Page.DIGGING
	_show_face(null)
	_speaker.visible = false
	_block.visible = false
	_details.visible = false
	_rewards.visible = false
	_later.visible = false
	_body.text = "Your crews are at work. Come back when they're done."
	_time_box.visible = true
	_time.text = Excavations.time_text(Excavations.time_left(site))
	_next.counter_items = PackedStringArray()
	_next.label_text = "CLOSE"
	_next.visible = true
	_next.disabled = false

## What it paid, and the companion with their bonus if one joined.
func _show_end() -> void:
	_page = Page.END
	var result := Excavations.finish(site, _mgr.blackboard)
	_rewards.text = _amounts_bb(result["grants"])
	_rewards.visible = not (result["grants"] as Dictionary).is_empty()
	_rewards.modulate.a = 0.0
	_reveal(_rewards)
	_speaker.visible = false
	_next.visible = true
	_next.label_text = "DONE"
	var who: CompanionDef = result["companion"]
	if who != null:
		AudioManager.play("achievement")
		_show_face(who)
		_title.text = "%s JOINS YOU" % who.display_name.to_upper()
		_speaker.text = who.role
		_speaker.visible = true
		_type("%s\n\n%s" % [who.bonus_bb(13), who.bio])
	else:
		AudioManager.play("building_done")

## What the player is short of, as red icon amounts.
func _missing_bb() -> String:
	var bad := UIStyle.color(&"bad")
	var parts: Array[String] = []
	for id: String in site.cost:
		var short := float(site.cost[id]) - Economy.payable_amount(id)
		if short > 0.0:
			parts.append("%s %s" % [UIIcons.bb(id, 13, bad), Economy.fmt(short)])
	return "Missing   " + "   ".join(parts)

func _amounts_bb(amounts: Dictionary) -> String:
	var parts: Array[String] = []
	for id: String in amounts:
		var c := Economy.color_of(id)
		parts.append("%s [color=#%s]+%s[/color]" % [UIIcons.bb(id, 15, c), c.to_html(false), Economy.fmt(float(amounts[id]))])
	return "   ".join(parts)

## The speaker's portrait, if they are a companion: VSM talkers use display names.
func _companion_named(speaker: String) -> CompanionDef:
	for c: CompanionDef in CompanionDef.all():
		if c.display_name == speaker:
			return c
	return null
