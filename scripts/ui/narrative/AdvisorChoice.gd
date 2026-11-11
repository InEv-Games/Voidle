class_name AdvisorChoice
extends RefCounted

## The opening's choice (docs/design/narrative/SCENES.md, opening_intro): the two
## caretakers side by side, the same portrait, role and bonus a Companions card
## shows, each with what they say they can do and APPOINT. A choice is required:
## no close button, Esc does nothing. `on_pick(advisor_id)` runs on APPOINT.

const LAYER := 236
const IDS := ["mother_superior", "high_father"]

static func open(host: Node, on_pick: Callable) -> ModalPopup:
	var p := ModalPopup.open(host, "Choose your advisor", "groups", "", LAYER)
	p.dismissable = false
	p.use_hero("Facilitator  //  Year 2465", "YOUR ADVISOR")
	p.confirm_button().visible = false
	p.cancel_button().visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	for id: String in IDS:
		var def := CompanionDef.find(id)
		if def != null:
			row.add_child(_card(def, p, on_pick))
	p.add_content(row)
	return p

static func _card(def: CompanionDef, p: ModalPopup, on_pick: Callable) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = &"ItemPanel"
	card.custom_minimum_size = Vector2(250, 0)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 6)
	card.add_child(col)
	var face := TextureRect.new()
	face.texture = def.portrait_texture()
	face.custom_minimum_size = Vector2(0, 200)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	col.add_child(face)
	var name_l := Label.new()
	name_l.text = def.display_name
	name_l.theme_type_variation = &"HeaderLabel"
	col.add_child(name_l)
	var role := Label.new()
	role.text = def.role
	role.theme_type_variation = &"SubLabel"
	col.add_child(role)
	var pitch := RichTextLabel.new()
	pitch.bbcode_enabled = true
	pitch.fit_content = true
	pitch.scroll_active = false
	pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pitch.theme_type_variation = &"PopupBody"
	pitch.add_theme_font_size_override(&"normal_font_size", 12)
	pitch.text = "[i]%s[/i]\n\n%s\n[color=#%s]Serves at least five years once appointed.[/color]" % [
		def.pitch, def.bonus_bb(13), UIStyle.hex(&"text_subtle")]
	col.add_child(pitch)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(gap)
	var appoint := IconButton.create("APPOINT", "confirm", IconButton.Variant.POSITIVE)
	appoint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cid := def.companion_id
	appoint.pressed.connect(func() -> void:
		AudioManager.play("click")
		p.close()
		on_pick.call(cid))
	col.add_child(appoint)
	return card
