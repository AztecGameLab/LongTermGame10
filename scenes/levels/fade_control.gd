extends Node

@onready var parent: Fade = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("start")

func start():
	await parent.fadein(false)
	parent.audio.play()
