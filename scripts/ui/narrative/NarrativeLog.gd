class_name NarrativeLog
extends RefCounted

## The Narrative Log (docs/design/narrative/UI.md): every line and answer the
## player has been shown, in order, grouped under the scene it came from, the
## newest at the bottom. Reading it never runs a scene or pays anything; closing
## it goes back to the line on screen.

const LAYER := 238   # over the dialogue panel (Narrative.LAYER)

static func open(host: Node) -> ModalPopup:
	var p := ModalPopup.open(host, "Narrative Log", "notes", "", LAYER)
	host.get_viewport().gui_release_focus()   # keys must not reach a box under it (the City's name)
	p.confirm_button().visible = false
	p.cancel_button().label_text = "CLOSE"
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.theme_type_variation = &"PopupBody"
	text.add_theme_font_size_override(&"normal_font_size", 12)
	text.text = _compose()
	scroll.add_child(text)
	p.add_content(scroll)
	# open at the newest line
	scroll.get_v_scroll_bar().changed.connect(func() -> void:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value), CONNECT_ONE_SHOT)
	return p

static func _compose() -> String:
	if GameState.narrative_log.is_empty():
		return "[color=#%s]Nothing has been said yet.[/color]" % UIStyle.hex(&"text_subtle")
	var muted := UIStyle.hex(&"text_subtle")
	var accent := UIStyle.hex(&"accent")
	var out: Array[String] = []
	var last_scene: Variant = null   # no scene heading written yet
	for e: Dictionary in GameState.narrative_log:
		var scene := String(e.get("s", ""))
		if scene != last_scene:
			if not out.is_empty():
				out.append("")
			out.append("[color=#%s]//  %s[/color]" % [muted, _scene_title(scene)])
			last_scene = scene
		var who := String(e.get("n", ""))
		var line := String(e.get("t", ""))
		if String(e.get("k", "line")) == "choice":
			out.append("[color=#%s]>  %s[/color]" % [accent, line])
		elif who == "" or who == "Narrator":
			out.append("[i]%s[/i]" % line)
		else:
			out.append("[b]%s[/b]   %s" % [who, line])
	return "\n".join(out)

## "opening_intro" → "Opening intro"; ids are shown only as section headings.
static func _scene_title(id: String) -> String:
	if id == "":
		return "Remarks"
	return id.replace("_", " ").capitalize()
