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
	set(v): body = v; _sync()
## Cost line; empty hides the cost box.
@export var cost: String = "":
	set(v): cost = v; _sync()

func _ready() -> void:
	_sync()

func _sync() -> void:
	if not is_node_ready():
		return
	($VBox/Header/Title as Label).text = title
	var ic := $VBox/Header/Icon as TextureRect
	ic.visible = icon_name != ""
	if ic.visible:
		ic.texture = UIIcons.get_icon(icon_name)
	var b := $VBox/Body as RichTextLabel
	b.text = body
	b.visible = body != ""
	($VBox/Rows as Control).visible = ($VBox/Rows as Node).get_child_count() > 0
	($VBox/CostBox as Control).visible = cost != ""
	($VBox/CostBox/Cost/Value as Label).text = cost
	($VBox/Actions as Control).visible = ($VBox/Actions as Node).get_child_count() > 0

## Body from mixed parts: Strings (BBCode) and Texture2D icons drawn inline.
func set_body_parts(parts: Array, icon_size: int = 13) -> void:
	var b := $VBox/Body as RichTextLabel
	b.clear()
	for part in parts:
		if part is String:
			b.append_text(part)
		elif part is Texture2D:
			b.add_image(part, icon_size, icon_size)
	b.visible = not parts.is_empty()
