extends CanvasLayer
class_name Fade

const secs := 1.0

@onready var color_rect: ColorRect = $ColorRect

signal finished

@export var audio: AudioStreamPlayer

func fadein(fade_audio: bool = true):
	visible = true
	var tween := create_tween()
	tween.tween_method(set_alpha, 1.0, 0.0, secs)
	if audio and fade_audio:
		tween.parallel().tween_property(audio, "volume_linear", 1.0, secs + 1.0)
	await tween.finished
	visible = false
	finished.emit()

func fadeout():
	visible = true
	var tween := create_tween()
	tween.tween_method(set_alpha, 0.0, 1.0, secs)
	if audio:
		tween.parallel().tween_property(audio, "volume_linear", 0.0, secs + 1.0)
		await tween.finished
	else:
		await tween.finished
		await get_tree().create_timer(1.0).timeout
	finished.emit()

func set_alpha(value: float):
	color_rect.color.a = value
