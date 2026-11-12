class_name CompanionGallery
extends Control

## AGENTS (10.11: was Companions): the collectable Agents; one sits in each
## open ministry of the Government (GovernmentPanel) and gives their bonus.
## Opened for a ministry (`open(host, ministry)`, the Chancellery by default),
## APPOINT puts the picked Agent there: free once the sitting one's term is
## over, before that for credits (GameState.early_appoint_cost).
## Before: the advisors (docs/design/narrative/ADVISORS.md, UI.md "Companions"): the two
## caretakers, Bolo and Burkai, and a ??? for who is still to come. One of them
## is the ACTIVE advisor and gives their bonus; the others can be appointed
## once met, after the tutorial and once the active one's five-year term is
## over (the reason or the time left shows by ASSIGN). Laid out like the save
## slots: ‹ BACK above a hero ("Advisor: …" / COMPANIONS), the list card and,
## beside it, the picked one standing full height with, at their feet, a small
## hero (role / NAME) over a card with their bonus, words and ASSIGN. Before
## they are met: a dark silhouette, "Not met yet" / ??? and where to look.
## Esc, ‹ BACK or a click outside closes it.
## Layout: scenes/ui/excavation/CompanionGallery.tscn.

const SCENE_PATH := "res://scenes/ui/excavation/CompanionGallery.tscn"
const LAYER := 235
const NAME_SIZE := 26   # the name hero over their words: smaller than the page's
## Who is still to come (later civilizations): a silhouette, no profile.
const FUTURE := "__future"

const PORTRAIT_SCALE := 1.07

@onready var _card: Control = $Center/Card
@onready var _list: VBoxContainer = $Center/Card/Row/ListCard/Scroll/List
@onready var _detail: Control = $Center/Card/Row/Detail
@onready var _portrait: TextureRect = $Center/Card/Row/Detail/Portrait
@onready var _name: HeroHeader = $Center/Card/Row/Detail/Foot/NameHero
@onready var _bonus: RichTextLabel = $Center/Card/Row/Detail/Foot/BioCard/Info/Bonus
@onready var _bio: RichTextLabel = $Center/Card/Row/Detail/Foot/BioCard/Info/Bio

var _items: Array[ListItem] = []
var _ids: Array[String] = []
var _status: RichTextLabel = null
var _assign: IconButton = null
var _invite: IconButton = null   # Bolo's people's offer, when it waits
var _picked := ""
var ministry := "chancellery"   # where APPOINT puts the picked Agent (GameState.CHANCELLERY)
var on_closed := Callable()

static func open(host: Node, for_ministry: String = "chancellery", closed_cb := Callable()) -> void:
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	# runs while the game is paused: LISTEN TO BOLO closes it as her scene
	# starts and pauses the game, and its closing must not stop half-way
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	host.get_tree().root.add_child(layer)
	var g := (load(SCENE_PATH) as PackedScene).instantiate() as CompanionGallery
	g.ministry = for_ministry
	g.on_closed = closed_cb
	layer.add_child(g)
	AudioManager.play("click")

func _title_of(ministry_id: String) -> String:
	return String(GameState.ministry_def(ministry_id).get("title", "Minister"))

func _ready() -> void:
	_name.set_title_size(NAME_SIZE)
	var back := LeftPanel.back_button("BACK")
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(func() -> void:
		AudioManager.play("click")
		_close())
	_card.add_child(back)
	_card.move_child(back, 0)
	($Dim as Control).gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_close())
	# under the words: why they can't be appointed yet (or their office); the
	# buttons stand under the card
	var info := _bio.get_parent() as VBoxContainer
	_status = RichTextLabel.new()
	_status.bbcode_enabled = true
	_status.fit_content = true
	_status.scroll_active = false
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override(&"normal_font_size", 11)
	info.add_child(_status)
	_assign = IconButton.create("APPOINT AS %s" % _title_of(ministry).to_upper(), "confirm", IconButton.Variant.POSITIVE)
	_assign.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_assign.pressed.connect(_on_assign)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override(&"separation", 6)
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	($Center/Card/Row/Detail/Foot as VBoxContainer).add_child(actions)
	actions.add_child(_assign)
	_invite = IconButton.create("LISTEN TO BOLO", "notes", IconButton.Variant.DEFAULT)
	_invite.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_invite.pressed.connect(func() -> void:
		AudioManager.play("click")
		on_closed = Callable()   # not back to Government: the scene plays next
		_close()   # the scene plays in the panel under this screen
		Excavations.hear_bolo_invitation())
	actions.add_child(_invite)
	# the portrait a little larger than its room (PORTRAIT_SCALE), about its centre
	_portrait.resized.connect(func() -> void: _portrait.pivot_offset = _portrait.size * 0.5)
	_portrait.scale = Vector2.ONE * PORTRAIT_SCALE
	_build_list()
	_pick(GameState.active_advisor if GameState.active_advisor != "" else _ids[0])
	StoryDialog.pop_in(_card)
	RowReveal.play(_card)

func _build_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	_items.clear()
	_ids.clear()
	var sitting := CompanionDef.find(GameState.minister_of(ministry))
	var hero := $Center/Card/Hero as HeroHeader
	hero.title = "AGENTS"
	hero.caption = "%s: %s" % [_title_of(ministry), sitting.display_name] if sitting != null else "%s: vacant" % _title_of(ministry)
	for def: CompanionDef in CompanionDef.all():
		var met := GameState.unlocked_advisors.has(def.companion_id)
		var office := GameState.ministry_of(def.companion_id)
		var it := ListItem.create(def.display_name.to_upper() if met else "???", "population" if met else "unknown",
			_title_of(office).to_upper() if office != "" else "", [], ("%s  //  Lv %d" % [def.role, GameState.agent_level(def.companion_id)]) if met else "Not met yet")
		_add_item(it, def.companion_id)
	_add_item(ListItem.create("???", "unknown", "", [], "Later civilizations"), FUTURE)

func _add_item(it: ListItem, id: String) -> void:
	it.pressed.connect(func() -> void:
		AudioManager.play("click")
		_pick(id))
	_list.add_child(it)
	_items.append(it)
	_ids.append(id)

func _pick(id: String) -> void:
	_picked = id
	for n in _items.size():
		_items[n].selected = _ids[n] == id
	var def := CompanionDef.find(id) if id != FUTURE else null
	var met := def != null and GameState.unlocked_advisors.has(id)
	var tex: Texture2D = def.portrait if def != null else load(CompanionDef.FALLBACK_PORTRAIT) as Texture2D
	_portrait.texture = tex
	_portrait.visible = tex != null
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if tex != null and tex.get_width() <= 512 \
		else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_portrait.modulate = Color.WHITE if met else Color(0.25, 0.28, 0.36)
	_name.caption = def.role if met else ("Not met yet" if def != null else "Still to come")
	_name.title = def.display_name.to_upper() if met else "???"
	_bonus.text = def.bonus_bb(13) if def != null else ""
	_bonus.visible = met
	_bio.text = def.bio if met else (def.hint if def != null else "Others will join you in the civilizations ahead.")
	_refresh_assign()
	_detail.modulate.a = 0.0
	create_tween().tween_property(_detail, "modulate:a", 1.0, 0.15)

## ACTIVE, or ASSIGN with why it can't be done yet (the term's time left …).
func _refresh_assign() -> void:
	_invite.visible = _picked == "bolo" and Excavations.bolo_invitation_ready()
	var def := CompanionDef.find(_picked) if _picked != FUTURE else null
	var met := def != null and GameState.unlocked_advisors.has(_picked)
	if not met:
		_status.visible = false
		_assign.visible = false
		return
	_status.visible = true
	var office := GameState.ministry_of(_picked)
	if office != "":
		_assign.visible = false
		var left := GameState.ministry_ready_at(office) - GameState.calendar_seconds
		_status.text = "[color=#%s]Your %s.[/color]%s" % [UIStyle.hex(&"good"), _title_of(office),
			("  Serves at least %s more." % GameState.calendar_span_text(left)) if left > 0.0 else ""]
		return
	var hard := GameState.appoint_block(_picked, ministry)
	var cost := GameState.early_appoint_cost(ministry) if hard == "" else 0.0
	_assign.visible = true
	_assign.disabled = hard != "" or (cost > 0.0 and GameState.credits < cost)
	_assign.counter_items = PackedStringArray(["credits:" + HUDManager.fmt_credits(cost)]) if cost > 0.0 else PackedStringArray()
	var dim := UIStyle.hex(&"text_subtle")
	if hard != "":
		_status.text = "[color=#%s]%s[/color]" % [dim, hard]
	elif cost > 0.0:   # the price stands on the button: no note
		_status.visible = false
	else:
		_status.text = "[color=#%s]Appointing them ends the current term; they serve at least five years.[/color]" % dim

func _on_assign() -> void:
	if _picked == FUTURE or not GameState.appoint_now(_picked, ministry):
		AudioManager.play("error")
		return
	AudioManager.play("click")
	_build_list()
	_pick(_picked)

func _process(_delta: float) -> void:
	if _status != null:
		_refresh_assign()   # the term's time left (and the price) counts down while it is open

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	StoryDialog.pop_out(_card, get_parent())
	if on_closed.is_valid():
		on_closed.call_deferred()
