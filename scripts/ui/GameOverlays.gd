class_name GameOverlays
extends RefCounted

## Full-screen overlays of the 31.10 mechanics: the planet trait picker (one of
## three cards, survivors-like), the relic site card and the Relic Museum.
## Each opens on its own CanvasLayer above the HUD; ESC or a click on the shade
## closes it (the trait pick stays waiting).

const LAYER := 240
const CARD_W := 230.0

# ── Shared ───────────────────────────────────────────────────────────────────

## A dimmed full-screen layer with a centred column; returns [layer, column].
static func _overlay(host: Node, title: String, subtitle: String) -> Array:
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	host.get_tree().root.add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.01, 0.04, 0.72)
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

## Three trait cards for the world's first waiting pick; choosing one keeps it.
static func open_trait_picker(host: Node, planet_seed: int) -> void:
	var offers := PlanetTags.offers_of(planet_seed)
	if offers.is_empty():
		return
	var pd := GameState.get_planet_data(planet_seed)
	var o := _overlay(host, "A trait for %s" % (pd.planet_name if pd else "this world"),
		"Choose one. It stays with the world and counts for its whole total.")
	var layer: CanvasLayer = o[0]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	(o[1] as VBoxContainer).add_child(row)
	var i := 0
	for id in offers[0]:
		var tid := String(id)
		var info := PlanetTags.info(tid)
		var card := _card(220.0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 10)
		card.add_child(v)
		v.add_child(_text(String(info["name"]).to_upper(), 15))
		v.add_child(_text(PlanetTags.effect_text(tid), 13, _good() if PlanetTags.is_positive(tid) else Color(1.0, 0.85, 0.45)))
		v.add_child(_text(String(info["desc"]), 11, UIStyle.color(&"text_subtle")))
		var sp := Control.new()
		sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(sp)
		var btn := IconButton.create("CHOOSE", "confirm", IconButton.Variant.POSITIVE)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func() -> void:
			if PlanetTags.choose(planet_seed, tid):
				AudioManager.play("building_done")
			close(layer))
		v.add_child(btn)
		row.add_child(card)
		_pop_in(card, 0.08 * i)
		i += 1
	var later := IconButton.create_text("LATER")
	later.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	later.pressed.connect(func() -> void: close(layer))
	(o[1] as VBoxContainer).add_child(later)

# ── Relic site ───────────────────────────────────────────────────────────────

## The card of a relic site on the map: its story and the excavation.
static func open_relic_site(host: Node, relic_id: String) -> void:
	var idx := Relics.index_of(relic_id)
	if idx < 0:
		return
	var r: Dictionary = Relics.CATALOGUE[idx]
	var o := _overlay(host, "Relic site", "Relic %d of %d" % [idx + 1, Relics.count()])
	var layer: CanvasLayer = o[0]
	var card := _card()
	card.custom_minimum_size.x = 420.0
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	var story := _text(String(r["story"]), 12)
	story.custom_minimum_size.x = 396.0
	v.add_child(story)
	var block := Relics.excavate_block(relic_id)
	var btn := IconButton.create("EXCAVATE", "library", IconButton.Variant.POSITIVE,
		"%s sci" % Economy.fmt(float(r["cost"])))
	btn.disabled = block != ""
	v.add_child(btn)
	if block != "":
		v.add_child(_text(block, 11, _bad()))
	btn.pressed.connect(func() -> void:
		if not Relics.excavate(relic_id):
			AudioManager.play("error")
			return
		AudioManager.play("achievement")
		close(layer)
		_found_card(host, r))
	(o[1] as VBoxContainer).add_child(card)
	_pop_in(card, 0.0)

static func _found_card(host: Node, r: Dictionary) -> void:
	var o := _overlay(host, r["name"], "Added to the Museum  ·  %d / %d relics" % [Relics.found_count(), Relics.count()])
	var card := _card()
	card.custom_minimum_size.x = 420.0
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	var b := _text(Relics.bonus_text(r), 14, _good())
	b.custom_minimum_size.x = 396.0
	v.add_child(b)
	var h := _text("Next: " + String(r["hint"]), 12, Color(1.0, 0.85, 0.45))
	h.custom_minimum_size.x = 396.0
	v.add_child(h)
	(o[1] as VBoxContainer).add_child(card)
	_pop_in(card, 0.0)

# ── Museum ───────────────────────────────────────────────────────────────────

## Every relic of the game: found ones with their bonus and story, the one being
## looked for with its hint, the rest unknown.
static func open_museum(host: Node) -> void:
	var o := _overlay(host, "Museum", "%d / %d relics found" % [Relics.found_count(), Relics.count()])
	var layer: CanvasLayer = o[0]
	var grid := HFlowContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.custom_minimum_size.x = (CARD_W + 12.0) * 3.0
	grid.alignment = FlowContainer.ALIGNMENT_CENTER
	(o[1] as VBoxContainer).add_child(grid)
	for i in Relics.count():
		var r: Dictionary = Relics.CATALOGUE[i]
		var card := _card(200.0)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		card.add_child(v)
		var found := Relics.is_found(r["id"])
		v.add_child(_text("RELIC %d" % (i + 1), 10, UIStyle.color(&"text_muted")))
		if found:
			v.add_child(_text(String(r["name"]).to_upper(), 14))
			v.add_child(_text(Relics.bonus_text(r), 12, _good()))
			v.add_child(_text(String(r["story"]), 10, UIStyle.color(&"text_subtle")))
		else:
			v.add_child(_text("???", 14, UIStyle.color(&"text_muted")))
			if Relics.is_hinted(r["id"]):
				var hint: String = Relics.FIRST_HINT if i == 0 else String(Relics.CATALOGUE[i - 1]["hint"])
				v.add_child(_text("Hint: " + hint, 11, Color(1.0, 0.85, 0.45)))
			else:
				v.add_child(_text("Not yet known.", 11, UIStyle.color(&"text_muted")))
		if not found:
			card.modulate = Color(0.75, 0.78, 0.85, 0.85)
		grid.add_child(card)
		_pop_in(card, 0.05 * i)
	var shut := IconButton.create_text("CLOSE")
	shut.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	shut.pressed.connect(func() -> void: close(layer))
	(o[1] as VBoxContainer).add_child(shut)
