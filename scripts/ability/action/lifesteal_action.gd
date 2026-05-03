extends TargetAction
class_name LifestealAction

@export var damage_minimum: int
@export var damage_maximum: int
@export var can_miss: bool = true

## Percent of damage to heal back (0.0 - 1.0)
@export_range(0.0, 1.0, 0.05) var lifesteal_percent: float = 0.5

func run(context: ActionContext) -> void:
	var damage := RNG.curve_with_bias(damage_minimum, damage_maximum, 0.0)
	var heal = roundi(damage * lifesteal_percent)
	for target in resolve_targets(context):
		await BattleManager.apply_damage(damage, context.source, target)
	await BattleManager.apply_healing(heal, context.source, context.source)
