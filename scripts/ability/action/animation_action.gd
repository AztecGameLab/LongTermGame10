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
	if not context.is_first_target:
		return
	if not context.source:
		return

	if context.ability:
		var stream := context.ability.get_audio(context.source)
		if stream:
			_play_audio(context.source, stream)

	var animation_string: String = animToString(animation)
	if context.source._animated_sprite.animation != animation_string:
		await context.source.play_animation(animation_string)

## Fire-and-forget. The audio plays in parallel with the animation and following actions.
## [QueuedAction] waits for any still-playing audio at the end of its run, so the next queued
## action won't begin until the audio finishes.
func _play_audio(source: BattleCharacter, stream: AudioStream) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"SFX"
	source.add_child(player)
	player.play()
