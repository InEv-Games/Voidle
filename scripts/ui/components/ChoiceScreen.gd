class_name ChoiceScreen
extends RefCounted

## A choice between a few characters (or anything with a tall picture), laid
## out as the advisor choice: a hero across the top, and under it the options
## side by side. Each option is a large standing portrait with, over its lower
## left, its role and name and a small card (what it says, what it gives) with
## the option's button at the card's bottom right. Built on ModalPopup (the dim,
## Esc, the hero); its own card is left without a background.
##   ChoiceScreen.open(self, "Facilitator  //  Year 2465", "YOUR ADVISOR", [
##       {"id": "a", "portrait": tex, "caption": "Ship caretaker", "name": "Mother Superior",
##        "body": "[i]I can help…[/i]", "button": "APPOINT", "icon": "confirm"},
##       …], func(id: String) -> void: …, 236, false)
## `on_pick(id)` runs on an option's button, after the screen closes.
## `dismissable` false: a choice is required (no ✕, Esc does nothing).

const COL_W := 420.0        # one option's width
const COL_H := 560.0        # …and height (its portrait runs on below it)
const COL_GAP := 60.0
const PORTRAIT_H := 680.0   # from the option's top; its foot runs off the bottom
const PORTRAIT_X := 0.6     # the portrait's centre across the option (share)
const CARD_W := 300.0
const CARD_BOTTOM := 30.0   # the card's bottom above the option's bottom
const NAME_SIZE := 18
const PORTRAIT_IN := 0.6    # the portraits fade in (s), one after the other
const PORTRAIT_STAGGER := 0.15
const REVEAL_SLOW := 2.0    # the cards come in as the main menu's rows (RowReveal)

static func open(host: Node, caption: String, title: String, options: Array,
		on_pick: Callable, layer := 236, dismissable := true) -> ModalPopup:
	var p := ModalPopup.open(host, title, "groups", "", layer)
	p.use_hero(caption, title)
	p.dismissable = dismissable
	p.card.add_theme_stylebox_override(&"panel", StyleBoxEmpty.new())
	p.confirm_button().visible = false
	p.cancel_button().visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", int(COL_GAP))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_content(row)
	var fronts: Array[Control] = []
	for i in options.size():
		var opt: Dictionary = options[i]
		row.add_child(_option(opt, p, on_pick, i, fronts))
	# the cards come in once laid out
	(func() -> void:
		for f: Control in fronts:
			if is_instance_valid(f):
				RowReveal.play(f, REVEAL_SLOW)).call_deferred()
	return p

static func _option(opt: Dictionary, p: ModalPopup, on_pick: Callable, i: int,
		fronts: Array[Control]) -> Control:
	var col := Control.new()
	col.custom_minimum_size = Vector2(COL_W, COL_H)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# behind: the portrait, standing, its foot past the bottom
	var tex: Texture2D = opt.get("portrait", null)
	if tex != null:
		var face := TextureRect.new()
		face.texture = tex
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# pixel sprites stay sharp; the big renders scale smoothly
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if tex.get_width() <= 512 \
			else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pw := PORTRAIT_H * float(tex.get_width()) / maxf(float(tex.get_height()), 1.0)
		face.size = Vector2(pw, PORTRAIT_H)
		face.position = Vector2(COL_W * PORTRAIT_X - pw * 0.5, 0.0)
		col.add_child(face)
		face.modulate.a = 0.0
		face.create_tween().tween_property(face, "modulate:a", 1.0, PORTRAIT_IN) \
			.set_delay(i * PORTRAIT_STAGGER).set_trans(Tween.TRANS_SINE)
	# over its lower left: role, name and the card
	var front := VBoxContainer.new()
	front.add_theme_constant_override(&"separation", 2)
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(front)
	fronts.append(front)
	var cap := String(opt.get("caption", ""))
	if cap != "":
		var c := Label.new()
		c.text = cap
		c.theme_type_variation = &"SubLabel"
		HeroHeader.outline_label(c, HeroHeader.OUTLINE_PX - 1)   # over the portrait
		front.add_child(c)
	var name_l := Label.new()
	name_l.text = String(opt.get("name", ""))
	name_l.theme_type_variation = &"HeaderLabel"
	name_l.add_theme_font_size_override(&"font_size", NAME_SIZE)
	HeroHeader.outline_label(name_l)   # over the portrait
	front.add_child(name_l)
	var gap := Control.new()
	gap.custom_minimum_size.y = 4
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	front.add_child(gap)
	var card := PanelContainer.new()
	card.theme_type_variation = &"PopupCard"
	card.custom_minimum_size.x = CARD_W
	front.add_child(card)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override(&"separation", 8)
	card.add_child(inner)
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.theme_type_variation = &"PopupBody"
	body.add_theme_font_size_override(&"normal_font_size", 13)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.text = String(opt.get("body", ""))
	inner.add_child(body)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	inner.add_child(buttons)
	var b := IconButton.create(String(opt.get("button", "CHOOSE")), String(opt.get("icon", "confirm")),
		IconButton.Variant.POSITIVE)
	var id := String(opt.get("id", ""))
	b.pressed.connect(func() -> void:
		AudioManager.play("click")
		p.close()
		on_pick.call(id))
	buttons.add_child(b)
	# placed at the option's lower left once its size is known
	var place := func() -> void:
		var sz := front.get_combined_minimum_size()
		front.size = sz
		front.position = Vector2(0.0, COL_H - CARD_BOTTOM - sz.y)
	front.resized.connect(place)
	front.minimum_size_changed.connect(place)
	place.call_deferred()
	return col
