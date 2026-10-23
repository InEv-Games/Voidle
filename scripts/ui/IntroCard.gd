## IntroCard — the goal card shown after NEW GAME / PLAY DEMO
## (scenes/ui/IntroCard.tscn: texts, colours and layout are edited there).
## BEGIN emits `begun`; Esc or a click outside the panel cancels.
extends Control

signal begun

@onready var _begin: Button = %BeginButton
@onready var _save_note: Control = %SaveNote
@onready var _dim: ColorRect = %Dim

func _ready() -> void:
	_save_note.visible = GameState.demo_build   # only the browser demo loses progress
	_begin.pressed.connect(func() -> void:
		AudioManager.play("click", 0.0)
		begun.emit()
		_close())
	_dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			_close())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event as InputEventKey).keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	var layer := get_parent()
	if layer is CanvasLayer:
		layer.queue_free()
	else:
		queue_free()
