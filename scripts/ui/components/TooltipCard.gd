## Tooltip card (design: Tooltip.png):
##   [icon] TITLE
##   ═══════════
##   body text (BBCode)
##   InfoRow nodes under Rows        — placed in the scene, not built in code
##   ═══════════ COST  value
##   buttons under Actions (optional)
## Layout: scenes/ui/components/TooltipCard.tscn. Look: TooltipPanel, TooltipBody.
@tool
class_name TooltipCard
extends PanelContainer

@export var title: String = "RESOURCE TOOLTIP":
	set(v): title = v; _sync()
## UIIcons name; empty hides the icon.
@export var icon_name: String = "unknown":
	set(v): icon_name = v; _sync()
@export_multiline var body: String = "":
	set(v): body = v; _body_from_parts = false; _sync()
## Cost line; empty hides the cost box.
@export var cost: String = "":
	set(v): cost = v; _sync()

## Rich footer instead of "Cost  value" (playtest 31.10): what it makes on the
## left, the cost with icons at the bottom right (BBCode both; right empty: off).
var footer_left: String = ""
var footer_right: String = ""
var _foot_l: RichTextLabel = null
var _foot_r: RichTextLabel = null

## Top-right corner of the header (BBCode, e.g. "37K / 50K"; empty hides it)
## and a detail block under the body behind a separator (playtest 31.10).
var corner: String = ""
var detail: String = ""
var _corner: RichTextLabel = null
var _detail_sep: HSeparator = null
var _detail: RichTextLabel = null

## A [url] term in the body or detail is hovered / left (nested tips).
signal term_hovered(term: String)
signal term_left(term: String)

## set_body_parts filled the Body; _sync must not overwrite it with `body`.
var _body_from_parts := false

func set_corner(c: String) -> void:
	corner = c
	_sync()

func set_detail(d: String) -> void:
	detail = d
	_sync()

## Terms can be hovered only while the tip is locked (it no longer follows the mouse).
func set_terms_active(on: bool) -> void:
	var f := Control.MOUSE_FILTER_PASS if on else Control.MOUSE_FILTER_IGNORE
	($VBox/Body as Control).mouse_filter = f
	if _detail != null:
		_detail.mouse_filter = f

func _hook_terms(l: RichTextLabel) -> void:
	l.meta_hover_started.connect(func(m: Variant) -> void: term_hovered.emit(String(m)))
	l.meta_hover_ended.connect(func(m: Variant) -> void: term_left.emit(String(m)))

func set_footer(left: String, right: String) -> void:
	footer_left = left
	footer_right = right
	_sync()

func _foot_label() -> RichTextLabel:
	var l := RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.theme_type_variation = &"TooltipBody"
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l

func _ready() -> void:
	if not Engine.is_editor_hint():
		_hook_terms($VBox/Body as RichTextLabel)
	_sync()

func _sync() -> void:
	if not is_node_ready():
		return
	($VBox/Header/Title as Label).text = title
	var ic := $VBox/Header/Icon as TextureRect
	ic.visible = icon_name != ""
	if ic.visible:
		ic.texture = UIIcons.get_icon(icon_name)
	if not _body_from_parts:
		var b := $VBox/Body as RichTextLabel
		b.text = body
		b.visible = body != ""
	if corner != "" and _corner == null:
		var header := $VBox/Header as HBoxContainer
		var gap := Control.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(gap)
		_corner = _foot_label()
		header.add_child(_corner)
	if _corner != null:
		_corner.text = corner
		_corner.get_parent().get_child(_corner.get_index() - 1).visible = corner != ""
		_corner.visible = corner != ""
	if detail != "" and _detail == null:
		var vb := $VBox as VBoxContainer
		_detail_sep = HSeparator.new()
		_detail_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_detail = _foot_label()
		_detail.size_flags_vertical = Control.SIZE_FILL
		var at := ($VBox/Body as Node).get_index() + 1
		vb.add_child(_detail_sep)
		vb.move_child(_detail_sep, at)
		vb.add_child(_detail)
		vb.move_child(_detail, at + 1)
		if not Engine.is_editor_hint():
			_hook_terms(_detail)
	if _detail != null:
		_detail.text = detail
		_detail.visible = detail != ""
		_detail_sep.visible = detail != ""
	($VBox/Rows as Control).visible = ($VBox/Rows as Node).get_child_count() > 0
	var rich := footer_right != "" or footer_left != ""
	($VBox/CostBox as Control).visible = cost != "" or rich
	($VBox/CostBox/Cost/Value as Label).text = cost
	($VBox/CostBox/Cost/Key as Control).visible = not rich
	($VBox/CostBox/Cost/Value as Control).visible = not rich
	if rich and _foot_l == null:
		var row := $VBox/CostBox/Cost as HBoxContainer
		_foot_l = _foot_label()
		_foot_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_foot_r = _foot_label()
		row.add_child(_foot_l)
		row.add_child(_foot_r)
	if _foot_l != null:
		_foot_l.visible = rich
		_foot_r.visible = rich
		_foot_l.text = footer_left
		_foot_r.text = footer_right
	($VBox/Actions as Control).visible = ($VBox/Actions as Node).get_child_count() > 0

## Body from mixed parts: Strings (BBCode) and Texture2D icons drawn inline.
func set_body_parts(parts: Array, icon_size: int = 13) -> void:
	_body_from_parts = true
	var b := $VBox/Body as RichTextLabel
	b.clear()
	for part in parts:
		if part is String:
			b.append_text(part)
		elif part is Texture2D:
			b.add_image(part, icon_size, icon_size)
	b.visible = not parts.is_empty()
