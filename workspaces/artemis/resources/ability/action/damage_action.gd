extends TargetAction
class_name DamageAction

@export var damage_minimum: int
@export var damage_maximum: int

func run(caster: Character, target: Character) -> void:
	var accuracy := caster.get_accuracy() if caster else 0.0
	var raw := RNG.curve_with_bias(damage_minimum, damage_maximum, accuracy)

	target.receive_damage(raw, caster)

	finished.emit()
