extends TargetAction
class_name HealAction

@export var heal_amount: int
@export var overheal: bool

func run(context: ActionContext) -> void:
	for target in resolve_targets(context):
		if overheal:
			var overflow = maxi(0, target.current_health + heal_amount - target.max_health)
			target.max_health += overflow
			BattleManager.apply_healing(heal_amount, context.source, target)

		else:
			BattleManager.apply_healing(heal_amount, context.source, target)
