## Builds a recoloured copy of the project theme from one accent hue and a
## colour-harmony rule. The base theme (voidle_theme.tres) stays the single
## source of look: its blue family is sorted into the 60-30-10 roles and each
## role gets the harmony's hue; the semantic colours (positive green, neutral
## yellow, negative red, resource tints, the cream icon) are left alone.
##
##   Dominant  (60%) — panels, side panel, nav bar, inputs, scroll tracks
##   Secondary (30%) — item cards, chips, tooltips, popups, sliders
##   Accent    (10%) — borders, separators, highlighted text, buttons, badges
##   Text            — the near-white body text, tinted with the secondary hue
class_name ThemeBuilder
extends RefCounted

enum Harmony { MONOCHROMATIC, ANALOGOUS, COMPLEMENTARY, SPLIT_COMPLEMENTARY, TRIADIC, SQUARE }

const HARMONY_LABELS := {
	Harmony.MONOCHROMATIC:       "Monochromatic",
	Harmony.ANALOGOUS:           "Analogous",
	Harmony.COMPLEMENTARY:       "Complementary",
	Harmony.SPLIT_COMPLEMENTARY: "Split Complementary",
	Harmony.TRIADIC:             "Triadic",
	Harmony.SQUARE:              "Square",
}
const HARMONY_ORDER: Array[int] = [Harmony.MONOCHROMATIC, Harmony.ANALOGOUS, Harmony.COMPLEMENTARY,
	Harmony.SPLIT_COMPLEMENTARY, Harmony.TRIADIC, Harmony.SQUARE]

## Hue offsets from the accent, in degrees: [secondary, dominant].
const _OFFSETS := {
	Harmony.MONOCHROMATIC:       [0.0, 0.0],
	Harmony.ANALOGOUS:           [15.0, 30.0],
	Harmony.COMPLEMENTARY:       [180.0, 180.0],
	Harmony.SPLIT_COMPLEMENTARY: [150.0, 210.0],
	Harmony.TRIADIC:             [120.0, 240.0],
	Harmony.SQUARE:              [90.0, 180.0],
}

enum Role { NONE, DOMINANT, SECONDARY, ACCENT, TEXT }

## The base theme's recolourable family: its blues (hue 178–228°).
const _FAMILY_MIN := 178.0 / 360.0
const _FAMILY_MAX := 228.0 / 360.0
## Theme types drawn wholly in the accent (calls to action and badges).
const _ACCENT_TYPES: Array[StringName] = [&"Button", &"ButtonDefault", &"OptionButton", &"Badge", &"IconCell"]

## Hues (0–1) of the three roles for `accent_deg` under `harmony`.
static func role_hues(accent_deg: float, harmony: int) -> Dictionary:
	var off: Array = _OFFSETS.get(harmony, _OFFSETS[Harmony.ANALOGOUS])
	return {
		Role.ACCENT:    fposmod(accent_deg, 360.0) / 360.0,
		Role.SECONDARY: fposmod(accent_deg + float(off[0]), 360.0) / 360.0,
		Role.DOMINANT:  fposmod(accent_deg + float(off[1]), 360.0) / 360.0,
	}

## A copy of `base` recoloured by the harmony. `vividness` scales saturation.
static func build(base: Theme, accent_deg: float, harmony: int, vividness: float = 1.0) -> Theme:
	var hues := role_hues(accent_deg, harmony)
	var t := Theme.new()
	t.merge_with(base)
	var done := {}   # original stylebox -> recoloured copy (styleboxes are shared between types)
	for type: StringName in base.get_type_list():
		var force := type in _ACCENT_TYPES
		for name: StringName in base.get_color_list(type):
			var force_c := force or (type == &"Palette" and String(name).begins_with("badge"))
			t.set_color(name, type, map_color(base.get_color(name, type), hues, vividness, force_c))
		for name: StringName in base.get_stylebox_list(type):
			var sb := base.get_stylebox(name, type)
			if not done.has(sb):
				done[sb] = _map_stylebox(sb, hues, vividness, force)
			t.set_stylebox(name, type, done[sb])
	return t

## Slider handle: a small upright bar (px), not Godot's default 16px knob.
const GRABBER_SIZE := Vector2i(6, 16)
## The dark edge that sets the handle off from the same-coloured fill.
const GRABBER_EDGE := Color(0.02, 0.06, 0.1, 1.0)

## Gives HSlider / VSlider a small upright-bar handle (lying flat on a VSlider)
## in the slider's fill colour (the accent, so it follows the theme); a lighter
## one on hover, a dim one disabled. Icons aren't recoloured by build(), so
## they're drawn here from the theme.
static func set_slider_grabbers(t: Theme) -> void:
	var fill := t.get_stylebox(&"grabber_area", &"HSlider")
	var col: Color = (fill as StyleBoxFlat).bg_color if fill is StyleBoxFlat else Color(0.22, 0.82, 1.0)
	for type: StringName in [&"HSlider", &"VSlider"]:
		var sz := GRABBER_SIZE if type == &"HSlider" else Vector2i(GRABBER_SIZE.y, GRABBER_SIZE.x)
		t.set_icon(&"grabber", type, _bar(sz, col))
		t.set_icon(&"grabber_highlight", type, _bar(sz, col.lightened(0.3)))
		t.set_icon(&"grabber_disabled", type, _bar(sz, Color(col, 0.4)))

## A filled rectangle `size` big with a 1px GRABBER_EDGE border.
static func _bar(size: Vector2i, col: Color) -> ImageTexture:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for y in size.y:
		for x in size.x:
			var edge := x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1
			img.set_pixel(x, y, Color(GRABBER_EDGE, col.a) if edge else col)
	return ImageTexture.create_from_image(img)

## The base Palette's panel / item / accent colours as built, for a preview.
static func preview(base: Theme, accent_deg: float, harmony: int, vividness: float = 1.0) -> Array[Color]:
	var hues := role_hues(accent_deg, harmony)
	var out: Array[Color] = []
	for n: StringName in [&"panel_bg", &"item_bg", &"accent"]:
		out.append(map_color(base.get_color(n, &"Palette"), hues, vividness))
	return out

static func map_color(c: Color, hues: Dictionary, vividness: float, force_accent := false) -> Color:
	var role := _role(c, force_accent)
	if role == Role.NONE:
		return c
	var hue: float = hues[Role.SECONDARY if role == Role.TEXT else role]
	var out := Color.from_hsv(hue, clampf(c.s * vividness, 0.0, 1.0), c.v, c.a)
	# Backgrounds keep their brightness across hues (a yellow at the same value
	# reads far lighter than a blue), so high-luminance panels stay as dark as base.
	# When an accent hue has low luminance (e.g. crimson, violet), backgrounds scale down
	# proportionally to maintain contrast against text and borders.
	if role == Role.DOMINANT or role == Role.SECONDARY:
		var lum := out.get_luminance()
		if lum > 0.0001:
			var acc_lum := Color.from_hsv(hues[Role.ACCENT], clampf(0.85 * vividness, 0.0, 1.0), 0.91).get_luminance()
			var contrast_scale := clampf(acc_lum / 0.614, 0.45, 1.0)
			var scale := minf(1.0, c.get_luminance() / lum) * contrast_scale
			out = Color.from_hsv(hue, out.s, c.v * scale, c.a)
	return out

static func _role(c: Color, force_accent: bool) -> int:
	if c.s < 0.05 or c.h < _FAMILY_MIN or c.h > _FAMILY_MAX:
		return Role.NONE
	if force_accent:
		return Role.ACCENT
	if c.s < 0.45 and c.v > 0.5:
		return Role.TEXT
	if c.v >= 0.7:
		return Role.ACCENT
	return Role.DOMINANT if c.h >= 210.0 / 360.0 else Role.SECONDARY

static func _map_stylebox(sb: StyleBox, hues: Dictionary, vividness: float, force: bool) -> StyleBox:
	if sb is StyleBoxFlat:
		var f := (sb as StyleBoxFlat).duplicate() as StyleBoxFlat
		f.bg_color = map_color(f.bg_color, hues, vividness, force)
		f.border_color = map_color(f.border_color, hues, vividness, force)
		f.shadow_color = map_color(f.shadow_color, hues, vividness, force)
		return f
	if sb is StyleBoxLine:
		var l := (sb as StyleBoxLine).duplicate() as StyleBoxLine
		l.color = map_color(l.color, hues, vividness, force)
		return l
	return sb
