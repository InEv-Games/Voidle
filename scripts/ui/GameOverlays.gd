class_name GameOverlays
extends RefCounted

## Full-screen overlay of the planet trait picker (one of three cards with a
## re-roll, survivors-like). It opens on its own CanvasLayer above the HUD; ESC
## or a click on the shade closes it (the trait pick stays waiting).

const LAYER := 240
const CARD_W := 230.0

# ── Shared ───────────────────────────────────────────────────────────────────

## A dimmed full-screen layer with a centred column; returns [layer, column].
## A dimmed full-screen layer with a centred column headed by a hero
## (`subtitle` as caption, `title` big); returns [layer, column].
static func _overlay(host: Node, title: String, subtitle: String, dim := 0.72) -> Array:
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	host.get_tree().root.add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(UIStyle.color(&"panel_bg"), dim)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed \
				and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			close(layer)
		elif ev is InputEventKey and (ev as InputEventKey).pressed and (ev as InputEventKey).keycode == KEY_ESCAPE:
			close(layer))
	layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)
	# a hero: `subtitle` as its caption over the big `title`
	var hero := HeroHeader.create(subtitle, title.to_upper())
	(hero.get_node("Title") as Label).autowrap_mode = TextServer.AUTOWRAP_OFF
	col.add_child(hero)
	AudioManager.play("click")
	return [layer, col]

static func close(layer: CanvasLayer) -> void:
	if is_instance_valid(layer):
		TooltipManager.hide_tip()
		layer.queue_free()

static func _card(min_h: float = 0.0) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := UIStyle.item_box(UIStyle.color(&"accent_dim"), 5)
	sb.content_margin_left = 12.0
	sb.content_margin_top = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 12.0
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(CARD_W, min_h)
	return p

static func _text(txt: String, size: int, col: Color = Color(0, 0, 0, 0), wrap_text := true) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col if col.a > 0.0 else UIStyle.color(&"text_bright"))
	if wrap_text:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = CARD_W - 24.0
	return l

static func _good() -> Color:
	return UIStyle.color(&"good")

static func _bad() -> Color:
	return UIStyle.color(&"bad")

static func _pop_in(c: Control, delay: float) -> void:
	c.modulate.a = 0.0
	c.pivot_offset = c.custom_minimum_size * 0.5
	c.scale = Vector2(0.85, 0.85)
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, 0.25).set_delay(delay)
	tw.tween_property(c, "scale", Vector2.ONE, 0.3).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ── Planet trait picker ──────────────────────────────────────────────────────

const TRAIT_CARD_W := 272.0
const TRAIT_INNER_W := TRAIT_CARD_W - 32.0
## A trait's head: its icon, the name on the icon's foot.
const TRAIT_HEAD_H := 150.0
const TRAIT_NAME_PX := 26
const TRAIT_NAME_H := 34.0
## Darker than the other overlays: the panels behind fought with the small print.
const TRAIT_DIM := 0.90

static var _trait_layer: CanvasLayer = null

## The HUD hides its "choose a trait" button while the cards are up.
static func trait_picker_open() -> bool:
	return is_instance_valid(_trait_layer)

## The world's first waiting pick, in icons more than words (the words are in
## the tooltips): three trait cards, a re-roll and "later" (the pick stays waiting).
static func open_trait_picker(host: Node, planet_seed: int) -> void:
	if PlanetTags.offers_of(planet_seed).is_empty():
		return
	var pd := GameState.get_planet_data(planet_seed)
	var o := _overlay(host, pd.planet_name if pd else "This world",
		"Pick a trait // It stays for good", TRAIT_DIM)
	var layer: CanvasLayer = o[0]
	_trait_layer = layer
	var col: VBoxContainer = o[1]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(actions)
	var reroll := IconButton.create("RE-ROLL", "cycle", IconButton.Variant.DEFAULT)
	_tip_on(reroll, "Re-roll", "Three new cards. The first re-roll of each pick is free, then the price rises.")
	actions.add_child(reroll)
	var later := IconButton.create_text("LATER")
	_tip_on(later, "Later", "The pick keeps waiting for this world.")
	later.pressed.connect(func() -> void: close(layer))
	actions.add_child(later)
	var note := _rich("", 12, TRAIT_INNER_W)
	note.custom_minimum_size.y = 18.0   # keeps the column still when it fills
	note.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(note)
	_fill_trait_cards(row, planet_seed, layer)
	_sync_reroll(reroll, note, planet_seed)
	reroll.pressed.connect(func() -> void:
		if PlanetTags.reroll(planet_seed):
			AudioManager.play("click")
			_fill_trait_cards(row, planet_seed, layer)
			_sync_reroll(reroll, note, planet_seed)
		else:
			AudioManager.play("error"))
	# Science keeps coming in while the cards are up
	var poll := Timer.new()
	poll.wait_time = 0.5
	poll.autostart = true
	poll.timeout.connect(func() -> void: _sync_reroll(reroll, note, planet_seed))
	layer.add_child(poll)

static func _tip_on(c: Control, title: String, body: String) -> void:
	c.mouse_entered.connect(func() -> void: TooltipManager.show_tip(title, body))
	c.mouse_exited.connect(func() -> void: TooltipManager.hide_tip())

static func _fill_trait_cards(row: HBoxContainer, planet_seed: int, layer: CanvasLayer) -> void:
	for c in row.get_children():
		row.remove_child(c)
		c.queue_free()
	var i := 0
	for id in PlanetTags.offers_of(planet_seed)[0]:
		var def := TraitDef.find(String(id))
		if def == null:
			continue
		var card := _trait_card(def, planet_seed, layer)
		row.add_child(card)
		_pop_in(card, 0.08 * i)
		i += 1

## One trait: its effect's icon large and faint, the name over the icon's foot,
## and under them a small card with the rarity, the effects as icons and
## amounts (words in their tooltips), one line of story and CHOOSE.
static func _trait_card(def: TraitDef, planet_seed: int, layer: CanvasLayer) -> Control:
	var rc := def.rarity_color()
	var item := VBoxContainer.new()
	item.custom_minimum_size.x = TRAIT_CARD_W
	item.add_theme_constant_override("separation", 6)
	# the head: the icon, the name sitting on its lower part
	var head := Control.new()
	head.custom_minimum_size = Vector2(TRAIT_CARD_W, TRAIT_HEAD_H)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(head)
	if not def.effects.is_empty():
		var icon := TextureRect.new()
		icon.texture = UIIcons.get_icon(PlanetTags.effect_icon(String(def.effects.keys()[0])))
		icon.modulate = Color(rc, 0.35)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_bottom = -TRAIT_NAME_H * 0.35   # the name covers its foot
		head.add_child(icon)
	var title := _text(def.display_name.to_upper(), TRAIT_NAME_PX, Color(0, 0, 0, 0), false)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	title.offset_top = -TRAIT_NAME_H
	head.add_child(title)
	# the card
	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL   # cards in a row end level
	card.add_theme_stylebox_override("panel", _trait_card_box(rc, false))
	card.mouse_entered.connect(func() -> void: card.add_theme_stylebox_override("panel", _trait_card_box(rc, true)))
	card.mouse_exited.connect(func() -> void:
		if not card.get_global_rect().has_point(card.get_global_mouse_position()):   # not onto its own parts
			card.add_theme_stylebox_override("panel", _trait_card_box(rc, false)))
	item.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var rarity := _rich("[center][color=#%s]%s[/color][/center]" % [rc.to_html(false), def.rarity_name().to_upper()], 11, TRAIT_INNER_W)
	rarity.mouse_filter = Control.MOUSE_FILTER_PASS
	_tip_on(rarity, def.rarity_name(), _trait_odds_tip(planet_seed))
	v.add_child(rarity)
	for rid: String in def.effects:
		var amount := float(def.effects[rid])
		var row := _rich("[center]%s[/center]" % PlanetTags.effect_short_bb(rid, amount, 20), 20, TRAIT_INNER_W)
		row.mouse_filter = Control.MOUSE_FILTER_PASS   # its tooltip; the card keeps its hover
		_tip_on(row, def.display_name, PlanetTags.effect_explain(rid))
		v.add_child(row)
	var line := ColorRect.new()
	line.color = Color(rc, 0.35)
	line.custom_minimum_size.y = 1.0
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(line)
	var story := _text(def.description, 11, UIStyle.color(&"text_muted"))
	story.custom_minimum_size.x = TRAIT_INNER_W
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(story)
	if not def.allowed_planet_types.is_empty():
		var kinds: Array[String] = []
		var muted := UIStyle.color(&"text_muted")
		for t: int in def.allowed_planet_types:
			var ic := "moon" if t == PlanetData.Type.MOON else "planet"
			kinds.append("%s [color=#%s]%s[/color]" % [UIIcons.bb(ic, 12, muted), muted.to_html(false),
				String(PlanetData.Type.keys()[t]).capitalize()])
		v.add_child(_rich("[center]%s[/center]" % "   ".join(kinds), 11, TRAIT_INNER_W))
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL   # CHOOSE at the foot of each card
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp)
	var btn := IconButton.create("CHOOSE", "confirm", IconButton.Variant.POSITIVE)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tid := def.trait_id
	btn.pressed.connect(func() -> void:
		if PlanetTags.choose(planet_seed, tid):
			AudioManager.play("building_done")
		close(layer))
	v.add_child(btn)
	return item

static func _trait_card_box(rc: Color, hover: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(rc.r * 0.14 + 0.03, rc.g * 0.14 + 0.04, rc.b * 0.14 + 0.07, 0.98) if hover \
		else Color(0.04, 0.05, 0.09, 0.98)
	sb.border_color = rc if hover else Color(rc, 0.55)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 14.0
	return sb

## Each rarity and its share in this slot, for the rarity label's tooltip.
static func _trait_odds_tip(planet_seed: int) -> String:
	var odds := PlanetTags.rarity_odds(PlanetTags.traits_of(planet_seed).size())
	var total := 0
	for r: String in odds:
		total += int(odds[r])
	var words: Array[String] = []
	for i in TraitDef.RARITY_NAMES.size():
		var n := int(odds.get(TraitDef.RARITY_NAMES[i].to_lower(), 0))
		if n > 0:
			var share := "%d%%" % roundi(100.0 * n / total)
			var hex := TraitDef.RARITY_COLORS[i].to_html(false)
			words.append("[color=#%s]%s[/color] %s" % [hex, TraitDef.RARITY_NAMES[i], share])
	return "\n".join(words)

## The button's price (free, or Science); under it what's missing, if anything.
static func _sync_reroll(btn: IconButton, note: RichTextLabel, planet_seed: int) -> void:
	var cost := PlanetTags.reroll_cost(planet_seed)
	var free := cost.is_empty()
	var price := float(cost.get(Economy.SCIENCE, 0.0))
	var items := PackedStringArray() if free else PackedStringArray(["%s:%s" % [Economy.SCIENCE, Economy.fmt(price)]])
	if btn.counter_items != items:
		btn.counter_items = items
	var word := "FREE" if free else ""
	if btn.counter != word:
		btn.counter = word
	var short := Economy.cost_block(cost) != ""
	btn.disabled = short
	var bad := _bad()
	var text := "[center]%s [color=#%s]−%s[/color][/center]" % [UIIcons.bb(Economy.SCIENCE, 13, bad), bad.to_html(false),
		Economy.fmt(price - GameState.science_points)] if short else ""
	if note.text != text:
		note.text = text

static func _rich(bb: String, size: int, width: float) -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.custom_minimum_size.x = width
	l.add_theme_font_size_override("normal_font_size", size)
	l.text = bb
	return l
