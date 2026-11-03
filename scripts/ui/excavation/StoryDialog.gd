class_name StoryDialog
extends Control

## An excavation, start to end: the site; its opening (a VSM graph's "start"
## entry); the price and how long it takes; the crews at work; when they're done,
## the rest of the story ("return" entry) with its choices; what it paid and who
## joined. Opened again from the map mark, it picks up at the stage the dig is at.
## Layout: scenes/ui/excavation/StoryDialog.tscn.

const SCENE_PATH := "res://scenes/ui/excavation/StoryDialog.tscn"
const LAYER := 240

enum Page { SITE, OPENING, PAY, DIGGING, RETURN, END }

var site: ExcavationSiteDef
var _page := Page.SITE
var _mgr: VSMManager = null

@onready var _portrait: TextureRect = $Center/Panel/Row/Portrait
@onready var _caption: Label = $Center/Panel/Row/Col/Caption
@onready var _title: Label = $Center/Panel/Row/Col/Title
@onready var _speaker: Label = $Center/Panel/Row/Col/Speaker
@onready var _body: RichTextLabel = $Center/Panel/Row/Col/Body
@onready var _time_box: PanelContainer = $Center/Panel/Row/Col/TimeBox
@onready var _time: Label = $Center/Panel/Row/Col/TimeBox/Time
@onready var _rewards: RichTextLabel = $Center/Panel/Row/Col/Rewards
@onready var _block: Label = $Center/Panel/Row/Col/Block
@onready var _choices: VBoxContainer = $Center/Panel/Row/Col/Choices
@onready var _later: IconButton = $Center/Panel/Row/Col/Buttons/Later
@onready var _next: IconButton = $Center/Panel/Row/Col/Buttons/Next

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
	_caption.text = _caption_text()
	_title.text = site.display_name.to_upper()
	ProgressFill.attach(_time_box, Color(0.62, 0.72, 0.88), _dig_progress, true)
	match Excavations.stage(site):
		Excavations.Stage.DIGGING:
			_show_digging()
		Excavations.Stage.READY:
			_play(Page.RETURN, ExcavationSiteDef.ENTRY_RETURN)
		_:
			_show_site()

func _process(_delta: float) -> void:
	if _page != Page.DIGGING:
		return
	if Excavations.stage(site) == Excavations.Stage.READY:
		_time.text = "READY"
		_next.label_text = "CONTINUE"
	else:
		_time.text = Excavations.time_text(Excavations.time_left(site))

func _dig_progress() -> float:
	return 1.0 - Excavations.time_left(site) / maxf(site.duration_sec, 1.0)

## "EXCAVATION 2 / 5  ·  VESYN".
func _caption_text() -> String:
	var w := Excavations.world_of_site(site.site_id)
	var world := w.planet() if w != null else null
	var at := w.sites.find(site) + 1 if w != null else 1
	var total := w.sites.size() if w != null else 1
	return "EXCAVATION %d / %d  ·  %s" % [at, total, world.planet_name.to_upper() if world != null else ""]

func _close() -> void:
	get_parent().queue_free()

func _on_next() -> void:
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
	var who := _companion_named(speaker)
	_portrait.visible = who != null
	if who != null:
		_portrait.texture = who.portrait_texture()
	_speaker.visible = speaker != "Narrator"
	_speaker.text = speaker
	_body.text = text
	_next.visible = true
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
		var b := IconButton.create_text(texts[i])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var at := i
		b.pressed.connect(func() -> void:
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
	_rewards.text = "%s %s      Returns at least   %s" % [UIIcons.bb("cycle", 15, Color(0.62, 0.72, 0.88)),
		Excavations.time_text(site.duration_sec), _amounts_bb(site.reward)]
	_rewards.visible = true
	_next.label_text = "EXCAVATE"
	var items := PackedStringArray()
	for id: String in site.cost:
		items.append("%s:%s" % [id, Economy.fmt(float(site.cost[id]))])
	_next.counter_items = items
	var why := Excavations.start_block(site)
	_next.disabled = why != ""
	_block.text = why
	_block.visible = why != ""

func _show_digging() -> void:
	_page = Page.DIGGING
	_portrait.visible = false
	_speaker.visible = false
	_block.visible = false
	_rewards.visible = false
	_later.visible = false
	_body.text = "Your crews are at work. Come back when they're done."
	_time_box.visible = true
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
	_speaker.visible = false
	var who: CompanionDef = result["companion"]
	if who != null:
		AudioManager.play("achievement")
		_portrait.texture = who.portrait_texture()
		_portrait.visible = true
		_title.text = "%s JOINS YOU" % who.display_name.to_upper()
		_speaker.text = who.role
		_speaker.visible = true
		_body.text = "[color=#8cf299]%s[/color]\n\n%s" % [who.bonus_text(), who.bio]
	else:
		AudioManager.play("building_done")
	_next.visible = true
	_next.label_text = "DONE"

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
