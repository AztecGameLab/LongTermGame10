extends AnimatedSprite2D

@onready var footstep: AudioStreamPlayer = $footstep
@onready var write: AudioStreamPlayer = $write


func _on_frame_changed() -> void:
	if frame < sprite_frames.get_frame_count(animation) - 1:
		if footstep:
			footstep.play()
	else:
		if write:
			write.play()
