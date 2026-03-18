extends TargetAction
class_name StaticDamageAction

@export var damage: int

## Whether this attack is able to miss, based on [code]StatusEffectModifier.FIELD.*_HIT_CHANCE[/code]
## [br]
## [br]For more control, use [HitChanceAction]
@export var can_miss: bool = true

func run(context: ActionContext) -> void:
	for target in resolve_targets(context):
		if can_miss and not BattleManager.check_hit_success(context.source, target):
			return

		BattleManager.apply_damage(damage, context.source, target)
