## Single access point for the UI look from code. Everything comes from
## res://resources/ui/voidle_theme.tres (the project theme), so colours,
## styleboxes and fonts are edited in Godot's Theme editor — not here.
##
## Buttons: four types (Default blue, Positive green, Neutral yellow,
## Negative red), each as icon-left (IconButton) or text-centred (a plain
## Button with the type's theme variation, or IconButton.create_text).
@tool
class_name UIStyle
extends RefCounted

const THEME: Theme = preload("res://resources/ui/voidle_theme.tres")

const DEFAULT  := &"ButtonDefault"
const POSITIVE := &"ButtonPositive"
const NEUTRAL  := &"ButtonNeutral"
const NEGATIVE := &"ButtonNegative"
const FLAT     := &"ButtonFlat"

const _BUTTON_STATES := ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]
const _FONT_COLORS := ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color",
	"font_focus_color", "font_hover_pressed_color", "font_outline_color"]

## Palette colour (panel_bg, item_bg, accent, good, bad, icon, text_subtle, ...).
static func color(name: StringName) -> Color:
	return THEME.get_color(name, &"Palette")

static func box(type: StringName, name: StringName = &"panel") -> StyleBox:
	return THEME.get_stylebox(name, type)

static func font_size(type: StringName) -> int:
	return THEME.get_font_size(&"font_size", type)

## Gives an existing Button one of the four types (text-centred), dropping
## local stylebox / colour / font overrides so the theme wins.
static func style_button(b: Button, variation: StringName = DEFAULT, size: int = 0) -> void:
	for s: String in _BUTTON_STATES:
		b.remove_theme_stylebox_override(s)
	for c: String in _FONT_COLORS:
		b.remove_theme_color_override(c)
	b.remove_theme_font_override("font")
	b.remove_theme_font_size_override("font_size")
	b.remove_theme_constant_override("outline_size")
	b.flat = false
	b.theme_type_variation = variation
	b.focus_mode = Control.FOCUS_NONE
	if size > 0:
		b.add_theme_font_size_override("font_size", size)

static func style_label(l: Label, variation: StringName) -> void:
	l.remove_theme_color_override("font_color")
	l.remove_theme_font_override("font")
	l.remove_theme_font_size_override("font_size")
	l.theme_type_variation = variation

static func style_panel(p: Control, variation: StringName = &"") -> void:
	p.remove_theme_stylebox_override("panel")
	p.theme_type_variation = variation

## Icon tint for a resource id: its game colour, or the cream icon colour.
static func resource_color(id: String) -> Color:
	return Economy.color_of(id) if Economy.INFO.has(id) else color(&"icon")
