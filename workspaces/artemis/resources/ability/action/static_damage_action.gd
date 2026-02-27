extends TargetAction
class_name StaticDamageAction

@export var damage: int

func run(caster: Character, target: Character) -> void:
	target.receive_damage(damage, caster)
	finished.emit()
