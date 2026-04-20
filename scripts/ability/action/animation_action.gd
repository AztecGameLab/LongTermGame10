extends Action
class_name AnimationAction

@export var animation_string: String = &"attack"

func run(context: ActionContext) -> void:
	if context.source and context.source._animated_sprite.animation != animation_string:
		await context.source.play_animation(animation_string)
