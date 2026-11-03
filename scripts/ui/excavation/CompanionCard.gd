class_name CompanionCard
extends PanelContainer

## A companion in the gallery: portrait, name, role, bonus, bio.
## Before they join: a dark silhouette and where to look.
## Layout: scenes/ui/excavation/CompanionCard.tscn.

const SCENE_PATH := "res://scenes/ui/excavation/CompanionCard.tscn"

@onready var _portrait: TextureRect = $VBox/Portrait
@onready var _name: Label = $VBox/Name
@onready var _role: Label = $VBox/Role
@onready var _bonus: Label = $VBox/Bonus
@onready var _bio: Label = $VBox/Bio

static func create(def: CompanionDef) -> CompanionCard:
	var c := (load(SCENE_PATH) as PackedScene).instantiate() as CompanionCard
	c.ready.connect(func() -> void: c._fill(def), CONNECT_ONE_SHOT)
	return c

func _fill(def: CompanionDef) -> void:
	var joined := Excavations.has_joined(def.companion_id)
	if joined:
		_portrait.texture = def.portrait_texture()
		_name.text = def.display_name.to_upper()
		_role.text = def.role
		_bonus.text = def.bonus_text()
		_bio.text = def.bio
	else:
		_portrait.modulate = Color(0.25, 0.28, 0.36)
		_name.text = "???"
		_role.visible = false
		_bonus.visible = false
		_bio.text = def.hint
