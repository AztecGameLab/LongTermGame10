extends TargetAction
class_name ScalingDamageAction
## Deals damage that scales with the triggering status effect container's stack count.

@export var damage_per_stack: int

## Whether this attack is able to miss, based on [code]StatusEffectModifier.FIELD.*_HIT_CHANCE[/code]
@export var can_miss: bool = true

func run(context: ActionContext) -> void:
	for target in resolve_targets(context):
		if can_miss and not BattleManager.check_hit_success(context.source, target):
			return

		var stack_count := context.container.stacks if context.container else 1
		var total_damage := damage_per_stack * stack_count

		BattleManager.apply_damage(total_damage, context.source, target)
