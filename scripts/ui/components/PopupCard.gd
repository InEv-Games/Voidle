## Popup / modal card (design: PopUp _ Panel.png):
##   [icon] TITLE ........................ [x]
##   ═══════════════════════════════════════
##   body (mono, BBCode)
##   Content: list items, info rows, tags  — placed in the scene
##   Buttons: IconButtons                  — placed in the scene (Cancel + Confirm by default)
## Layout: scenes/ui/components/PopupCard.tscn. Look: PopupCard, PopupBody.
@tool
class_name PopupCard
extends PanelContainer

signal close_pressed

@export var title: String = "POPUP / PANEL":
	set(v): title = v; _sync()
## UIIcons name; empty hides the icon.
@export var icon_name: String = "alert":
	set(v): icon_name = v; _sync()
@export_multiline var body: String = "":
	set(v): body = v; _sync()

func _ready() -> void:
	_sync()
	if not Engine.is_editor_hint():
		($VBox/Header/Close as Button).pressed.connect(func() -> void: close_pressed.emit())

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
	($VBox/Content as Control).visible = ($VBox/Content as Node).get_child_count() > 0
