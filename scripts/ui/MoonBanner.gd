## MoonBanner — "FIRST STEP ON THE MOON" (scenes/ui/MoonBanner.tscn), shown
## once per world when the first City on the Moon is founded. Texts and
## look are edited in the scene; timing here in the Inspector.
extends Control

@export var fade_in_sec := 0.8
@export var hold_sec := 3.2
@export var fade_out_sec := 1.2

func _ready() -> void:
	modulate.a = 0.0
	AudioManager.play("building_done")
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, fade_in_sec)
	tw.tween_interval(hold_sec)
	tw.tween_property(self, "modulate:a", 0.0, fade_out_sec)
	tw.tween_callback(func() -> void:
		var layer := get_parent()
		if layer is CanvasLayer:
			layer.queue_free()
		else:
			queue_free())
