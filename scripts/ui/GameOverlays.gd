class_name GameOverlays
extends RefCounted

## Full-screen overlay of the planet trait picker (one of three cards with a
## re-roll, survivors-like). It opens on its own CanvasLayer above the HUD; ESC
## or a click on the shade closes it (the trait pick stays waiting).

const LAYER := 240
const CARD_W := 230.0

# ── Shared ───────────────────────────────────────────────────────────────────

## A dimmed full-screen layer with a centred column; returns [layer, column].
static func _overlay(host: Node, title: String, subtitle: String, dim := 0.72) -> Array:
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	host.get_tree().root.add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.04, dim)
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
	var t := Label.new()
	t.text = title.to_upper()
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 20)
	col.add_child(t)
	if subtitle != "":
		var s := Label.new()
		s.text = subtitle
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.add_theme_color_override("font_color", UIStyle.color(&"text_subtle"))
		col.add_child(s)
	AudioManager.play("click")
	return [layer, col]

static func close(layer: CanvasLayer) -> void:
	if is_instance_valid(layer):
		TooltipManager.hide_tip()
		layer.queue_free()

static func _card(min_h: float = 0.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIStyle.box(&"SidePanel"))
	p.custom_minimum_size = Vector2(CARD_W, min_h)
	return p

static func _text(txt: String, size: int, col: Color = Color(0, 0, 0, 0), wrap := true) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", size)
	if col.a > 0.0:
		l.add_theme_color_override("font_color", col)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = CARD_W - 24.0
	return l

static func _good() -> Color:
	return Color(0.55, 0.95, 0.60)

static func _bad() -> Color:
	return Color(1.0, 0.55, 0.50)

static func _pop_in(c: Control, delay: float) -> void:
	c.modulate.a = 0.0
	c.pivot_offset = c.custom_minimum_size * 0.5
	c.scale = Vector2(0.85, 0.85)
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, 0.25).set_delay(delay)
	tw.tween_property(c, "scale", Vector2.ONE, 0.3).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# ── Planet trait picker ──────────────────────────────────────────────────────

const TRAIT_CARD_W := 272.0
const TRAIT_CARD_H := 316.0
const TRAIT_INNER_W := TRAIT_CARD_W - 32.0
## Darker than the other overlays: the panels behind fought with the small print.
const TRAIT_DIM := 0.90

static var _trait_layer: CanvasLayer = null

## The HUD hides its "choose a trait" button while the cards are up.
static func trait_picker_open() -> bool:
	return is_instance_valid(_trait_layer)

## The world's first waiting pick, in icons more than words (the words are in
## the tooltips): what it already has, three trait cards, the rarity odds of this
## slot, a re-roll and "later" (the pick stays waiting).
static func open_trait_picker(host: Node, planet_seed: int) -> void:
	if PlanetTags.offers_of(planet_seed).is_empty():
		return
	var pd := GameState.get_planet_data(planet_seed)
	var o := _overlay(host, "A trait for %s" % (pd.planet_name if pd else "this world"),
		"Pick one. It stays for good.", TRAIT_DIM)
	var layer: CanvasLayer = o[0]
	_trait_layer = layer
	var col: VBoxContainer = o[1]
	if pd != null:
		col.add_child(_trait_slot_strip(pd))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(row)
	col.add_child(_trait_odds_line(planet_seed))
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

## "[star][star][star]": one more per rarity step.
static func _stars_bb(rarity: int, px: int) -> String:
	var out := ""
	for i in rarity + 1:
		out += UIIcons.bb("star", px, TraitDef.RARITY_COLORS[rarity])
	return out

## Rarity on top, the effects as icons and amounts (words in their tooltips),
## one line of story, CHOOSE.
static func _trait_card(def: TraitDef, planet_seed: int, layer: CanvasLayer) -> PanelContainer:
	var rc := def.rarity_color()
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(TRAIT_CARD_W, TRAIT_CARD_H)
	card.add_theme_stylebox_override("panel", _trait_card_box(rc, false))
	card.mouse_entered.connect(func() -> void: card.add_theme_stylebox_override("panel", _trait_card_box(rc, true)))
	card.mouse_exited.connect(func() -> void:
		if not card.get_global_rect().has_point(card.get_global_mouse_position()):   # not onto its own parts
			card.add_theme_stylebox_override("panel", _trait_card_box(rc, false)))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	v.add_child(_rich("[center]%s  [color=#%s]%s[/color][/center]" % [_stars_bb(def.rarity, 12), rc.to_html(false),
		def.rarity_name().to_upper()], 11, TRAIT_INNER_W))
	if not def.effects.is_empty():
		var icon := TextureRect.new()
		icon.texture = UIIcons.get_icon(PlanetTags.effect_icon(String(def.effects.keys()[0])))
		icon.modulate = rc
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(44.0, 44.0)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(icon)
	var title := _text(def.display_name.to_upper(), 17)
	title.custom_minimum_size.x = TRAIT_INNER_W
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var line := ColorRect.new()
	line.color = Color(rc, 0.35)
	line.custom_minimum_size.y = 1.0
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(line)
	for rid: String in def.effects:
		var amount := float(def.effects[rid])
		var row := _rich("[center]%s[/center]" % PlanetTags.effect_short_bb(rid, amount, 20), 20, TRAIT_INNER_W)
		row.mouse_filter = Control.MOUSE_FILTER_PASS   # its tooltip; the card keeps its hover
		_tip_on(row, PlanetTags.effect_part(rid, amount).capitalize() if rid in PlanetTags.COUNT_EFFECTS \
			else PlanetTags.effect_part(rid, amount), PlanetTags.effect_explain(rid))
		v.add_child(row)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(sp)
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
	var btn := IconButton.create("CHOOSE", "confirm", IconButton.Variant.POSITIVE)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tid := def.trait_id
	btn.pressed.connect(func() -> void:
		if PlanetTags.choose(planet_seed, tid):
			AudioManager.play("building_done")
		close(layer))
	v.add_child(btn)
	return card

static func _trait_card_box(rc: Color, hover: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(rc.r * 0.14 + 0.03, rc.g * 0.14 + 0.04, rc.b * 0.14 + 0.07, 0.98) if hover \
		else Color(0.04, 0.05, 0.09, 0.98)
	sb.border_color = rc if hover else Color(rc, 0.55)
	sb.set_border_width_all(1)
	sb.border_width_top = 4
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 14.0
	return sb

## The world's three slots in a row: its traits as name and icons, a gold plus on
## the one being picked, an empty box on the rest.
static func _trait_slot_strip(pd: PlanetData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var have := PlanetTags.traits_of(pd.seed)
	var gold := TraitDef.RARITY_COLORS[TraitDef.Rarity.LEGENDARY]
	for i in PlanetTags.SLOTS:
		var c := UIStyle.color(&"text_muted")
		var bb := UIIcons.bb("empty", 13, c)
		var tip_title := "Trait slot %d" % (i + 1)
		var tip := "Empty."
		match PlanetTags.slot_state(pd, i):
			PlanetTags.Slot.FILLED:
				var def := TraitDef.find(String(have[i]))
				if def != null:
					c = def.rarity_color()
					var parts: Array[String] = []
					for rid: String in def.effects:
						parts.append(PlanetTags.effect_short_bb(rid, float(def.effects[rid]), 13))
					bb = "[color=#%s]%s[/color]  %s" % [c.to_html(false), def.display_name, "  ".join(parts)]
					tip_title = def.display_name
					tip = "%s\n\n%s" % [def.description, PlanetTags.effect_bb(def.trait_id)]
			PlanetTags.Slot.PICKING:
				if i == have.size():
					c = gold
					tip = "You are picking this one now."
				else:
					tip = "A pick waits for this one."
				bb = UIIcons.bb("positive", 13, c)
		var chip := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(c, 0.08)
		sb.border_color = Color(c, 0.6)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(3)
		sb.content_margin_left = 8.0
		sb.content_margin_right = 8.0
		sb.content_margin_top = 3.0
		sb.content_margin_bottom = 3.0
		chip.add_theme_stylebox_override("panel", sb)
		var l := _rich(bb, 11, 0.0)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		chip.add_child(l)
		_tip_on(chip, tip_title, tip)
		row.add_child(chip)
	return row

## Each rarity's stars and its share in this slot; the tooltip says what it is.
static func _trait_odds_line(planet_seed: int) -> RichTextLabel:
	var odds := PlanetTags.rarity_odds(PlanetTags.traits_of(planet_seed).size())
	var total := 0
	for r: String in odds:
		total += int(odds[r])
	var parts: Array[String] = []
	var words: Array[String] = []
	for i in TraitDef.RARITY_NAMES.size():
		var n := int(odds.get(TraitDef.RARITY_NAMES[i].to_lower(), 0))
		if n > 0:
			var share := "%d%%" % roundi(100.0 * n / total)
			var hex := TraitDef.RARITY_COLORS[i].to_html(false)
			parts.append("%s [color=#%s]%s[/color]" % [_stars_bb(i, 12), hex, share])
			words.append("[color=#%s]%s[/color] %s" % [hex, TraitDef.RARITY_NAMES[i], share])
	var l := _rich("[center]%s[/center]" % "     ".join(parts), 12, TRAIT_CARD_W * 2.0)
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	_tip_on(l, "Rarity odds in this slot", "\n".join(words))
	return l

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
