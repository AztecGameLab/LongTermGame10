extends TargetAction
class_name HealAction

@export var heal_amount: int

func run(context: ActionContext) -> void:
	for target in resolve_targets(context):
		BattleManager.apply_healing(heal_amount, context.source, target)
