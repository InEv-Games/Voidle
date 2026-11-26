class_name GovernmentPanel
extends RefCounted

## Civil Administration opens a council with the Facilitator, the advisor and
## a press assistant. Older cabinets are shown until the new office is built.

const LAYER := 234   # under AGENTS (235): its screen comes up over this one
const COL_W := 250.0        # one ministry's width
const COL_H := 380.0        # …and height
const COL_GAP := 28
const PORTRAIT_H := 330.0   # the minister standing, from the column's top
const PORTRAIT_X := 0.6     # their centre across the column (share)
const NAME_SIZE := 24       # the ministry's name (the hero's font, smaller)
const CARD_H := 76.0        # every card as tall, so the names line up
const REVEAL_SLOW := 2.0
const FACILITATOR := {"id": "facilitator", "name": "Facilitator", "title": "Leader"}

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
	LeftPanel.close_dropdowns(host.get_tree())   # revision 12.11: none left open behind it
	var council := GameState.government_available()
	if not council and not GameState.legacy_government_available():
		CompanionGallery.open(host)
		return
	var p := ModalPopup.open(host, "Government", "groups", "", LAYER)
	_popup = p
	var caption := "Year %d" % GameState.calendar_year()
	if not GameState.colony_name.is_empty():
		caption = "%s  //  %s" % [GameState.colony_name, caption]
	var hero := p.use_hero(caption, "GOVERNMENT")
	p.card.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())   # the ministries have their own cards
	(p.card.get_node("VBox/Buttons") as Control).visible = false   # the ✕ by the hero, Esc
	p.closed.connect(func() -> void: _popup = null)
	# AGENTS: every Agent met, at the hero's end by the ✕
	var agents := IconButton.create("AGENTS", "population", IconButton.Variant.DEFAULT,
		"%d met" % GameState.unlocked_advisors.size())
	agents.size_flags_vertical = Control.SIZE_SHRINK_END   # level with the title
	agents.pressed.connect(func() -> void:
		AudioManager.play("click")
		p.close()
		CompanionGallery.open(host, GameState.CHANCELLERY, func() -> void: open(host)))
	var head := hero.get_parent()
	if not GameState.colony_logo.is_empty():
		var emblem := TextureRect.new()
		emblem.texture = UIIcons.get_icon(GameState.colony_logo)
		emblem.custom_minimum_size = Vector2(36, 36)
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem.size_flags_vertical = Control.SIZE_SHRINK_END
		emblem.modulate = UIStyle.color(&"accent")
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_child(emblem)
		head.move_child(emblem, hero.get_index())
	head.add_child(agents)
	head.move_child(agents, hero.get_index() + 1)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", COL_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_content(row)
	var fronts: Array[Control] = []
	var offices: Array = [GameState.ministry_def(GameState.CHANCELLERY), FACILITATOR,
		GameState.ASSISTANT_OFFICE] if council else GameState.MINISTRIES
	for i in offices.size():
		row.add_child(_slot(host, p, offices[i], i, fronts))
	(func() -> void:   # the cards come in as the panels' rows do
		for f: Control in fronts:
			if is_instance_valid(f):
				RowReveal.play(f, REVEAL_SLOW)).call_deferred()

## One ministry: its minister standing (or an empty silhouette), and over their
## lower part the ministry's name, the card and the button.
static func _slot(host: Node, p: ModalPopup, m: Dictionary, i: int, fronts: Array[Control]) -> Control:
	var mid: String = m["id"]
	var leader := mid == FACILITATOR["id"]
	var press := mid == GameState.PRESS_ASSISTANT
	var open_slot := GameState.ministry_unlocked(mid)
	var agent_id := GameState.minister_of(mid) if (open_slot or press) else ""
	var def := CompanionDef.find(agent_id)
	var col := Control.new()
	col.custom_minimum_size = Vector2(COL_W, COL_H)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# behind: the minister
	var tex: Texture2D = def.portrait_texture() if def != null else load(CompanionDef.FALLBACK_PORTRAIT) as Texture2D
	if tex != null:
		var face := TextureRect.new()
		face.texture = tex
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if tex.get_width() <= 512 \
			else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pw := PORTRAIT_H * float(tex.get_width()) / maxf(float(tex.get_height()), 1.0)
		face.size = Vector2(pw, PORTRAIT_H)
		face.position = Vector2(COL_W * (0.5 if leader else PORTRAIT_X) - pw * 0.5, 0.0)
		var tint := Color.WHITE if def != null or leader else Color(0.25, 0.28, 0.36)
		face.modulate = Color(tint, 0.0)
		col.add_child(face)
		face.create_tween().tween_property(face, "modulate:a", 1.0, 0.5) \
			.set_delay(i * 0.12).set_trans(Tween.TRANS_SINE)
	# in front: the ministry's name, the card, the button
	var front := VBoxContainer.new()
	front.add_theme_constant_override(&"separation", 6)
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(front)
	fronts.append(front)
	var office_name := String(m["name"]).replace("Ministry of ", "")
	if leader and not GameState.colony_leader_name.is_empty():
		office_name = GameState.colony_leader_name
	var title := HeroHeader.create(String(m["title"]), office_name.to_upper(), NAME_SIZE)
	var title_label := title.get_node("Title") as Label
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	if leader:
		title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		title_label.mouse_filter = Control.MOUSE_FILTER_PASS
		title_label.tooltip_text = office_name
	title.set_outline()   # over the minister's portrait
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_child(title)
	var card := PanelContainer.new()
	card.theme_type_variation = &"PopupCard"
	card.custom_minimum_size = Vector2(COL_W, CARD_H)
	front.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override(&"separation", 6)
	card.add_child(inner)
	var dim := UIStyle.hex(&"text_subtle")
	if leader:
		inner.add_child(_text("You lead the colony."))
	elif not open_slot:
		inner.add_child(_text("[color=#%s]Locked. Opens when the tutorial is over.[/color]" % dim))
		col.modulate = Color(0.6, 0.62, 0.7, 0.85)
	elif def == null:
		inner.add_child(_text("[color=#%s]Vacant: appoint one of your Agents.[/color]" % dim))
	elif press:
		inner.add_child(_text("[font_size=13]%s[/font_size]\nSpeaks to the press in the News feed." % def.display_name))
	else:
		inner.add_child(_text("[font_size=13]%s[/font_size]\n[color=#%s]%s  //  Lv %d[/color]\n%s" % [
			def.display_name, dim, def.role, GameState.agent_level(agent_id), def.bonus_bb(12)]))
	# the button, centred under the card (a locked ministry keeps its room empty)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_child(buttons)
	var btn := IconButton.create("REPLACE" if def != null else "APPOINT", "population", IconButton.Variant.DEFAULT)
	btn.pressed.connect(func() -> void:
		AudioManager.play("click")
		p.close()
		CompanionGallery.open(host, mid, func() -> void: open(host)))
	# the term and what replacing costs: its tip, not the card
	if def != null:
		btn.mouse_entered.connect(func() -> void:
			TooltipManager.live(func() -> void:
				TooltipManager.show_tip("Replace", _replace_tip(mid, def))))
		btn.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())
	buttons.add_child(btn)
	if leader or not open_slot:   # keep the cards aligned
		buttons.custom_minimum_size.y = btn.get_combined_minimum_size().y
		btn.visible = false
	# at the column's bottom once its size is known
	var place := func() -> void:
		var sz := front.get_combined_minimum_size()
		front.size = Vector2(COL_W, sz.y)
		front.position = Vector2(0.0, COL_H - sz.y)
	front.minimum_size_changed.connect(place)
	place.call_deferred()
	return col

## REPLACE's tip: whose bonus would end, how long their term still runs and
## what replacing them now costs.
static func _replace_tip(mid: String, def: CompanionDef) -> String:
	var dim := UIStyle.hex(&"text_subtle")
	var lines: Array[String] = ["[color=#%s]Ends:[/color]  %s" % [UIStyle.hex(&"bad"), def.bonus_bb(12)]]
	var left := GameState.ministry_ready_at(mid) - GameState.calendar_seconds
	var cost := GameState.early_appoint_cost(mid)
	if left > 0.0 and cost > 0.0:
		lines.append("[color=#%s]Serves at least %s more: replacing them now costs[/color]  %s %s" % [dim,
			GameState.calendar_span_text(left), UIIcons.bb(Economy.CREDITS, 12, Economy.color_of(Economy.CREDITS)),
			HUDManager.fmt_credits(cost)])
	else:
		lines.append("[color=#%s]Their term is over: replacing them is free.[/color]" % dim)
	lines.append("[color=#%s]Pick who takes their seat in AGENTS.[/color]" % dim)
	return "\n".join(lines)

static func _text(bb: String) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.clip_contents = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.theme_type_variation = &"PopupBody"
	r.add_theme_font_size_override(&"normal_font_size", 12)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.text = bb
	return r
