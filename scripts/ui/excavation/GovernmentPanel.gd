class_name GovernmentPanel
extends RefCounted

## GOVERNMENT (10.11): the ministries, each with one minister's slot. An Agent
## in a slot gives their bonus while they sit there (GameState.active_agents).
## Only the Chancellery is open (the opening's advisor sits there); the others
## stay locked through the demo but show what is to come. A slot's APPOINT /
## REPLACE opens AGENTS for that ministry; AGENTS at the bottom browses them all.
## C (or the pad's shortcuts menu, or the Agents button by the left panel) opens it.

const LAYER := 234   # under AGENTS (235): its screen comes up over this one
const PORTRAIT := Vector2(54, 72)

static var _popup: ModalPopup = null

static func is_open() -> bool:
	return _popup != null and is_instance_valid(_popup)

static func toggle(host: Node) -> void:
	if is_open():
		_popup.close()
		_popup = null
		return
	open(host)

static func open(host: Node) -> void:
	if is_open():
		_popup.close()
	var p := ModalPopup.open(host, "Government", "groups", "", LAYER)
	_popup = p
	p.use_hero("Year %d  //  %d of %d ministries open" % [GameState.calendar_year(),
		GameState.ministries_unlocked.size(), GameState.MINISTRIES.size()], "GOVERNMENT")
	(p.card.get_node("VBox/Buttons") as Control).visible = false   # the ✕ by the hero, Esc
	p.closed.connect(func() -> void: _popup = null)
	var intro := RichTextLabel.new()
	intro.bbcode_enabled = true
	intro.fit_content = true
	intro.scroll_active = false
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size = Vector2(520, 0)
	intro.theme_type_variation = &"PopupBody"
	intro.add_theme_font_size_override(&"normal_font_size", 11)
	intro.text = "[color=#%s]Each ministry seats one of your Agents. While they serve, their bonus applies everywhere.[/color]" \
		% UIStyle.hex(&"text_subtle")
	p.add_content(intro)
	for m: Dictionary in GameState.MINISTRIES:
		p.add_content(_slot(host, p, m))
	var agents := IconButton.create("AGENTS", "population", IconButton.Variant.DEFAULT,
		"%d met" % GameState.unlocked_advisors.size())
	agents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	agents.pressed.connect(func() -> void:
		AudioManager.play("click")
		p.close()
		CompanionGallery.open(host, GameState.CHANCELLERY, func() -> void: open(host)))
	p.add_content(HSeparator.new())
	p.add_content(agents)

static func _slot(host: Node, p: ModalPopup, m: Dictionary) -> Control:
	var mid: String = m["id"]
	var open_slot := GameState.ministry_unlocked(mid)
	var card := PanelContainer.new()
	card.theme_type_variation = &"ItemPanel"
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 10)
	card.add_child(row)
	var agent_id := GameState.minister_of(mid) if open_slot else ""
	var def := CompanionDef.find(agent_id)
	var face := TextureRect.new()
	face.custom_minimum_size = PORTRAIT
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture = def.portrait_texture() if def != null else load(CompanionDef.FALLBACK_PORTRAIT) as Texture2D
	face.modulate = Color.WHITE if def != null else Color(0.25, 0.28, 0.36)
	row.add_child(face)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override(&"separation", 2)
	row.add_child(col)
	var head := Label.new()
	head.text = String(m["name"]).to_upper()
	head.theme_type_variation = &"HeaderLabel"
	col.add_child(head)
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.theme_type_variation = &"PopupBody"
	body.add_theme_font_size_override(&"normal_font_size", 11)
	body.custom_minimum_size = Vector2(300, 0)
	var dim := UIStyle.hex(&"text_subtle")
	if not open_slot:
		body.text = "[color=#%s]Locked. Opens in a later civilization.[/color]" % dim
		card.modulate = Color(0.6, 0.62, 0.7, 0.85)
	elif def == null:
		body.text = "[color=#%s]Vacant: appoint one of your Agents.[/color]" % dim
	else:
		var left := GameState.ministry_ready_at(mid) - GameState.calendar_seconds
		body.text = "%s  [color=#%s]%s  //  Lv %d[/color]\n%s\n[color=#%s]%s[/color]" % [def.display_name, dim, def.role,
			GameState.agent_level(agent_id), def.bonus_bb(12), dim,
			("Serves at least %s more; replacing them earlier costs credits." % GameState.calendar_span_text(left)) if left > 0.0
				else "Their term is over: you may replace them for free."]
	col.add_child(body)
	if open_slot:
		var btn := IconButton.create("REPLACE" if def != null else "APPOINT", "population", IconButton.Variant.DEFAULT)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.pressed.connect(func() -> void:
			AudioManager.play("click")
			p.close()
			CompanionGallery.open(host, mid, func() -> void: open(host)))
		row.add_child(btn)
	return card
