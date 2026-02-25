extends TargetAction
class_name HealAction

@export var heal_amount: int

func run(caster, target):
	if target.has_method("heal"):
		target.heal(heal_amount)
