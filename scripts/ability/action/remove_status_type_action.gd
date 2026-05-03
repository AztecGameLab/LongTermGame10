extends TargetAction
class_name RemoveStatusTypeAction

## The number of stacks of each removed effect to remove from the target.
@export var remove_stacks: int = 1

## The status effect type to remove
@export var status_effect_type: BaseStatusEffect.EffectType = BaseStatusEffect.EffectType.NEGATIVE

## Number of distinct effects to remove. Set to -1 to remove all matching effects.
@export var effect_count: int = 1

func run(context: ActionContext) -> void:
	for target in resolve_targets(context):
		var effects: Array[StatusEffectContainer] = target.get_all_status_effects().filter(func(s: StatusEffectContainer): return s.effect.effect_type == status_effect_type)
		if effects.is_empty():
			continue
		var count: int = effects.size() if effect_count == -1 else mini(effect_count, effects.size())
		effects.shuffle()
		for i in count:
			target.remove_status_effect(effects[i].effect, remove_stacks)
