extends Control
## Voice generator test bench: plays a VSM narrative and reads every line
## through VoiceAudioStreamPlayer using the speaker's VoiceProfile
## (res://resources/voices/<speaker>.tres). The right panel edits the profile
## of whoever is speaking, live; "Save profile" writes it back to its .tres.
## Space / Enter / Next advances; a press mid-line first reveals the full line.

const STORY_PATH := "res://resources/stories/test_voice_narrative.tres"
const VOICE_DIR := "res://resources/voices/"
const DEFAULT_VOICE := "narrator"
const BANK_DIR := "res://addons/voice-generator/sound/alphabet"
## Only voices whose language starts with this are listed (English for now).
const TTS_LANGUAGE := "en"
## Profile fields the panel never shows (fixed for now).
const HIDDEN_PROPS := ["tts_language"]

@onready var voice: VoiceAudioStreamPlayer = $Voice

var _manager := VSMManager.new()
var _profiles := {}  # lowercase name -> VoiceProfile
var _current_text := ""
var _editing := ""  # profile name shown in the panel

var _speaker_label: Label
var _body_label: Label
var _choices_box: VBoxContainer
var _next_button: Button
var _status_label: Label
var _profile_select: OptionButton
var _profile_grid: GridContainer


func _ready() -> void:
	_load_profiles()
	_build_ui()
	voice.saying_characters.connect(func(pos: int) -> void: _body_label.visible_characters = pos)
	voice.finished_saying.connect(func() -> void: _body_label.visible_characters = -1)
	_manager.dialogue_shown.connect(_on_dialogue_shown)
	_manager.choices_shown.connect(_on_choices_shown)
	_manager.story_finished.connect(_on_story_finished)
	_restart()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_next_pressed()
		get_viewport().set_input_as_handled()


func _load_profiles() -> void:
	for file in DirAccess.get_files_at(VOICE_DIR):
		file = file.trim_suffix(".remap")
		if file.get_extension() == "tres":
			var res := load(VOICE_DIR + file)
			if res is VoiceProfile:
				_profiles[file.get_basename().to_lower()] = res


func _profile_for(speaker: String) -> String:
	var key := speaker.to_lower()
	return key if _profiles.has(key) else DEFAULT_VOICE


# --- Story flow -------------------------------------------------------------

func _restart() -> void:
	voice.stop_saying()
	_clear_choices()
	_status_label.text = ""
	_manager.start(load(STORY_PATH))


func _on_dialogue_shown(speaker: String, text: String) -> void:
	_clear_choices()
	_current_text = text
	_speaker_label.text = speaker
	_next_button.disabled = false
	_status_label.text = ""
	var key := _profile_for(speaker)
	voice.apply_profile(_profiles.get(key))
	if key != _editing:
		_show_profile(key)
	_say_current()


func _on_choices_shown(choice_texts: Array[String]) -> void:
	_clear_choices()
	_next_button.disabled = true
	for i in choice_texts.size():
		var button := Button.new()
		button.text = choice_texts[i]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func() -> void:
			_clear_choices()
			_manager.choose(i))
		_choices_box.add_child(button)
	if _choices_box.get_child_count() > 0:
		(_choices_box.get_child(0) as Button).grab_focus()


func _on_story_finished(exit_name: String) -> void:
	voice.stop_saying()
	_next_button.disabled = true
	_status_label.text = "Story finished (exit: %s). Press Restart." % exit_name


func _on_next_pressed() -> void:
	if _next_button.disabled:
		return
	if voice.is_saying():
		voice.stop_saying()
		_body_label.visible_characters = -1
		return
	_manager.advance()


func _say_current() -> void:
	if _current_text.is_empty():
		return
	_body_label.text = _current_text
	_body_label.visible_characters = 0
	voice.say(_current_text)


func _clear_choices() -> void:
	for child in _choices_box.get_children():
		child.queue_free()


# --- Profile panel --------------------------------------------------------------

## Rebuilds the controls from the profile's exported properties, so new
## VoiceProfile fields show up here automatically.
func _show_profile(key: String) -> void:
	_editing = key
	var names := _profiles.keys()
	_profile_select.select(names.find(key))
	for child in _profile_grid.get_children():
		child.queue_free()
	var profile: VoiceProfile = _profiles[key]
	var tts := profile.voice_engine == VoiceProfile.VoiceEngine.SYSTEM_TTS
	var group := ""
	for prop in profile.get_property_list():
		var usage: int = prop.usage
		if usage & PROPERTY_USAGE_GROUP:
			group = prop.name
			if _group_visible(group, tts):
				_add_header(group)
			continue
		if not (usage & PROPERTY_USAGE_EDITOR) or not (usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if not _group_visible(group, tts) or prop.name in HIDDEN_PROPS:
			continue
		# In TTS mode the babble voice settings (bank, pitch, …) do nothing.
		if tts and group == "Voice" and prop.name != "voice_engine":
			continue
		match prop.type:
			TYPE_FLOAT, TYPE_INT:
				if prop.hint == PROPERTY_HINT_ENUM:
					_add_enum(profile, prop)
				else:
					_add_slider(profile, prop)
			TYPE_BOOL:
				_add_check(profile, prop)
			TYPE_STRING:
				match prop.name:
					"sample_dir":
						_add_bank(profile)
					"tts_voice_id":
						_add_tts_voice(profile)
					_:
						_add_line_edit(profile, prop)


## TTS shows only the engine picker and the System TTS group; babble engines
## hide the System TTS group.
func _group_visible(group: String, tts: bool) -> bool:
	if group == "Voice":
		return true
	if group == "Resource":  # Godot's own Resource fields
		return false
	return (group == "System TTS") == tts


func _on_profile_changed() -> void:
	if _profile_for(_speaker_label.text) == _editing:
		voice.apply_profile(_profiles[_editing])


func _add_header(title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(0.6, 0.8, 1.0)
	_profile_grid.add_child(label)
	_profile_grid.add_child(Control.new())
	_profile_grid.add_child(Control.new())


func _add_label(text: String) -> void:
	var label := Label.new()
	label.text = text.capitalize()
	_profile_grid.add_child(label)


func _add_slider(profile: VoiceProfile, prop: Dictionary) -> void:
	var range_parts: PackedStringArray = String(prop.hint_string).split(",")
	if prop.hint != PROPERTY_HINT_RANGE or range_parts.size() < 2:
		return
	var is_int: bool = prop.type == TYPE_INT
	var step := float(range_parts[2]) if range_parts.size() > 2 else (1.0 if is_int else 0.01)
	_add_label(prop.name)
	var slider := HSlider.new()
	slider.min_value = float(range_parts[0])
	slider.max_value = float(range_parts[1])
	slider.step = step
	slider.value = profile.get(prop.name)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size.x = 160
	_profile_grid.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 56
	value_label.text = _format(slider.value, is_int)
	_profile_grid.add_child(value_label)
	slider.value_changed.connect(func(v: float) -> void:
		value_label.text = _format(v, is_int)
		profile.set(prop.name, int(v) if is_int else v)
		_on_profile_changed())


func _add_check(profile: VoiceProfile, prop: Dictionary) -> void:
	_add_label(prop.name)
	var check := CheckBox.new()
	check.button_pressed = profile.get(prop.name)
	check.toggled.connect(func(on: bool) -> void:
		profile.set(prop.name, on)
		_on_profile_changed())
	_profile_grid.add_child(check)
	_profile_grid.add_child(Control.new())


func _add_enum(profile: VoiceProfile, prop: Dictionary) -> void:
	_add_label(prop.name)
	var option := OptionButton.new()
	for item in String(prop.hint_string).split(","):
		option.add_item(item.get_slice(":", 0).capitalize())
	option.select(profile.get(prop.name))
	option.item_selected.connect(func(i: int) -> void:
		profile.set(prop.name, i)
		_on_profile_changed()
		if prop.name == "voice_engine":
			_show_profile.call_deferred(_editing))
	_profile_grid.add_child(option)
	_profile_grid.add_child(Control.new())


func _add_bank(profile: VoiceProfile) -> void:
	_add_label("Sample bank")
	var option := OptionButton.new()
	var banks: Array[String] = [BANK_DIR]
	for sub in DirAccess.get_directories_at(BANK_DIR):
		banks.append(BANK_DIR + "/" + sub)
	for i in banks.size():
		option.add_item("root" if banks[i] == BANK_DIR else banks[i].get_file())
		if banks[i] == profile.sample_dir.trim_suffix("/"):
			option.select(i)
	option.item_selected.connect(func(i: int) -> void:
		profile.sample_dir = banks[i]
		_on_profile_changed())
	_profile_grid.add_child(option)
	_profile_grid.add_child(Control.new())


func _add_tts_voice(profile: VoiceProfile) -> void:
	_add_label("TTS voice")
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.fit_to_longest_item = false
	var ids: Array[String] = [""]
	option.add_item("Auto (best English voice)")
	if VoiceAudioStreamPlayer.is_tts_available():
		var voices := DisplayServer.tts_get_voices().filter(func(v: Dictionary) -> bool:
			return String(v.language).begins_with(TTS_LANGUAGE))
		voices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return [a.language, a.name] < [b.language, b.name])
		for v in voices:
			ids.append(v.id)
			option.add_item("%s (%s)" % [v.name, v.language])
	else:
		option.add_item("— system TTS unavailable —")
		option.set_item_disabled(1, true)
	option.select(maxi(ids.find(profile.tts_voice_id), 0))
	option.item_selected.connect(func(i: int) -> void:
		if i < ids.size():
			profile.tts_voice_id = ids[i]
			_on_profile_changed())
	_profile_grid.add_child(option)
	_profile_grid.add_child(Control.new())


func _add_line_edit(profile: VoiceProfile, prop: Dictionary) -> void:
	_add_label(prop.name)
	var edit := LineEdit.new()
	edit.text = profile.get(prop.name)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(func(t: String) -> void:
		profile.set(prop.name, t)
		_on_profile_changed())
	_profile_grid.add_child(edit)
	_profile_grid.add_child(Control.new())


func _format(v: float, is_int: bool) -> String:
	return str(int(v)) if is_int else "%.3f" % v


func _save_profile() -> void:
	var profile: VoiceProfile = _profiles[_editing]
	var err := ResourceSaver.save(profile, profile.resource_path)
	_status_label.text = ("Saved %s" % profile.resource_path) if err == OK \
			else ("Save failed (%s)" % error_string(err))


# --- UI -------------------------------------------------------------------------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 32)
	margin.add_child(root)

	# Story column
	var story := VBoxContainer.new()
	story.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story.size_flags_stretch_ratio = 1.4
	story.add_theme_constant_override("separation", 16)
	root.add_child(story)

	var title := Label.new()
	title.text = "Voice Generator Test — " + STORY_PATH.get_file()
	title.modulate = Color(1, 1, 1, 0.5)
	story.add_child(title)

	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 28)
	story.add_child(_speaker_label)

	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.add_theme_font_size_override("font_size", 24)
	_body_label.custom_minimum_size.y = 140
	story.add_child(_body_label)

	_choices_box = VBoxContainer.new()
	story.add_child(_choices_box)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story.add_child(spacer)

	_status_label = Label.new()
	_status_label.modulate = Color(1, 1, 1, 0.6)
	story.add_child(_status_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	story.add_child(buttons)
	_add_button(buttons, "Restart", _restart)
	_add_button(buttons, "Replay line", _say_current)
	_next_button = _add_button(buttons, "Next  ▸", _on_next_pressed)

	# Profile column
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 10)
	root.add_child(side)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	side.add_child(header)
	var header_label := Label.new()
	header_label.text = "Voice profile"
	header.add_child(header_label)
	_profile_select = OptionButton.new()
	_profile_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for key in _profiles:
		_profile_select.add_item(String(key).capitalize())
	_profile_select.item_selected.connect(func(i: int) -> void: _show_profile(_profiles.keys()[i]))
	header.add_child(_profile_select)
	_add_button(header, "Save profile", _save_profile)

	var hint := Label.new()
	hint.text = "Follows the current speaker. Changes apply from the next line — use Replay line to hear them."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.modulate = Color(1, 1, 1, 0.5)
	side.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)

	_profile_grid = GridContainer.new()
	_profile_grid.columns = 3
	_profile_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_grid.add_theme_constant_override("h_separation", 12)
	_profile_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_profile_grid)


func _add_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
