extends TargetAction
class_name RemoveStatusTypeAction

## The number of stacks of the effect to remove from the target.
@export var remove_stacks: int = 1

## The status effect type to remove
@export var status_effect_type: BaseStatusEffect.EffectType = BaseStatusEffect.EffectType.NEGATIVE

func run(context: ActionContext) -> void:
	for target in resolve_targets(context):
		var effects: Array[StatusEffectContainer] = target.get_all_status_effects().filter(func(s: StatusEffectContainer): return s.effect.effect_type == status_effect_type)
		if effects.size() > 0:
			target.remove_status_effect(effects.pick_random().effect, remove_stacks)
