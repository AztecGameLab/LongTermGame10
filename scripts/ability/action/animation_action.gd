extends Action
class_name AnimationAction

enum Anim {
	IDLE,
	ATTACK,
	STATUS
}

static func animToString(value: AnimationAction.Anim) -> String:
	match value:
		Anim.ATTACK: return "attack"
		Anim.STATUS: return "status"
		_: return "idle"

@export var animation: AnimationAction.Anim = AnimationAction.Anim.ATTACK

func run(context: ActionContext) -> void:
	var animation_string: String = animToString(animation)
	if context.source and context.source._animated_sprite.animation != animation_string:
		await context.source.play_animation(animation_string)
