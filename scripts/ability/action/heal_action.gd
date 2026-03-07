extends TargetAction
class_name HealAction

@export var heal_amount: int

func run(source: Character, target: Character) -> void:
	BattleManager.apply_healing(heal_amount, source, target)
