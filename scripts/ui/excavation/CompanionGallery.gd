class_name CompanionGallery
extends Control

## Every companion of the game, joined or not (CompanionCard).
## Layout: scenes/ui/excavation/CompanionGallery.tscn.

const SCENE_PATH := "res://scenes/ui/excavation/CompanionGallery.tscn"
const LAYER := 240

static func open(host: Node) -> void:
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	host.get_tree().root.add_child(layer)
	layer.add_child((load(SCENE_PATH) as PackedScene).instantiate())
	AudioManager.play("click")

func _ready() -> void:
	var all := CompanionDef.all()
	($Center/VBox/Count as Label).text = "%d / %d joined" % [Excavations.joined_count(), all.size()]
	for def: CompanionDef in all:
		$Center/VBox/Grid.add_child(CompanionCard.create(def))
	($Center/VBox/Close as Button).pressed.connect(_close)
	($Shade as Control).gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
			_close())

func _close() -> void:
	get_parent().queue_free()
