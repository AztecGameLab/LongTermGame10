extends TargetAction
class_name StealStatusAction

const EffectType = BaseStatusEffect.EffectType

@export var stacks_to_steal: int = 1

func run(context: ActionContext) -> void:
	for target in resolve_targets(context):
		var effects = target.get_all_status_effects().filter(func(e): return e.effect.effect_type == EffectType.POSITIVE)
		if effects.is_empty():
			return
		var stolen: StatusEffectContainer = effects.pick_random()
		target.remove_status_effect(stolen.effect, stacks_to_steal)
		context.source.add_status_effect(stolen.effect, stolen.source, stacks_to_steal, 0)
