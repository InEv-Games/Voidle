## Big panel header (design: Panel Hero):
##   caption            "Terran - Level 2"
##   TITLE              planet / city name (wraps when too long)
##   ─────────────────
## The tag bar is no longer part of the header: it sits next to it in each panel scene.
## Layout: scenes/ui/components/HeroHeader.tscn. Look: SubLabel, HeaderHero, TagLabel.
@tool
class_name HeroHeader
extends VBoxContainer

const SCENE_PATH := "res://scenes/ui/components/HeroHeader.tscn"

@export var caption: String = "Planet - Level 4":
	set(v): caption = v; _sync()
@export var title: String = "LASANDA":
	set(v): title = v; _sync()

@onready var _caption: Label = $Caption
@onready var _title: Label = $Title

## `title_size` > 0 makes the title smaller than the theme's HeaderHero
## (e.g. an objective's name, which is a sentence rather than a name).
static func create(cap: String, t: String, title_size := 0) -> HeroHeader:
	var h := (load(SCENE_PATH) as PackedScene).instantiate() as HeroHeader
	h.caption = cap
	h.title = t
	if title_size > 0:
		h.set_title_size(title_size)
	return h

## Shrinks the title below the theme's HeaderHero; the scene's tight spacing is
## tuned for the big size, so it shrinks with it.
func set_title_size(title_size: int) -> void:
	_title_size = title_size
	get_node("Title").add_theme_font_size_override(&"font_size", title_size)
	_fit_spacing()

## Title size override (0 = the theme's HeaderHero, spacing from the scene).
var _title_size := 0

## Capitals with a mark on top (Turkish Ğ İ Ö Ü …) would run into the caption /
## the line above under the tight spacing (playtest 07.11: "EĞRIBUCAK").
const ACCENT_CAPS := "ĞİÖÜÂÊÎÔÛÁÉÍÓÚÀÈÌÒÙÄËÏÅÑ"

static func _has_accent_cap(t: String) -> bool:
	for ch in t.to_upper():   # titles may be uppercased by the theme
		if ACCENT_CAPS.contains(ch):
			return true
	return false

## Tight spacing for plain capitals; room for the marks when the title has them.
func _fit_spacing() -> void:
	if not is_node_ready():
		return
	var accent := _has_accent_cap(title)
	if _title_size > 0:
		_title.add_theme_constant_override(&"line_spacing", -int(_title_size * (0.15 if accent else 0.4)))
		add_theme_constant_override(&"separation", 0 if accent else -int(round(8.0 * (_title_size / 36.0) * 0.4)))
	elif accent:
		var fs := _title.get_theme_font_size(&"font_size")
		_title.add_theme_constant_override(&"line_spacing", -int(fs * 0.15))
		add_theme_constant_override(&"separation", 0)
	else:   # the scene's values
		_title.add_theme_constant_override(&"line_spacing", -16)
		add_theme_constant_override(&"separation", -8)

## A dark outline (the panel colour) round the caption and title, for a hero
## standing over a portrait: on its light parts (a white coat) the text read
## poorly. `px` for the title; the caption gets a thinner one.
const OUTLINE_PX := 3

func set_outline(px := OUTLINE_PX) -> void:
	outline_label(get_node("Title") as Label, px)
	outline_label(get_node("Caption") as Label, maxi(1, px - 1))

static func outline_label(l: Label, px := OUTLINE_PX) -> void:
	l.add_theme_constant_override(&"outline_size", px)
	l.add_theme_color_override(&"font_outline_color", UIStyle.color(&"panel_bg"))

func _ready() -> void:
	_sync()

func _sync() -> void:
	if not is_node_ready():
		return
	_caption.text = caption
	_caption.visible = caption != ""
	_title.text = title
	_fit_spacing()
