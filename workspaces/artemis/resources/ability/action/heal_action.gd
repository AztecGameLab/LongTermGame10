extends TargetAction
class_name HealAction

@export var heal_amount: int

func run(caster: Character, target: Character) -> void:
	target.heal(heal_amount, caster)
	finished.emit()
