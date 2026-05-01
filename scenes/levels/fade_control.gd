extends Node
class_name FadeControl

@onready var parent: Fade = get_parent()

@export var music_after_fade := true
@export_range(-80.0, 0.0, 0.5) var music_in_db := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("start")

func start():
	await parent.fadein(!music_after_fade, music_in_db)
	if music_after_fade and parent.audio:
		parent.audio.play()
