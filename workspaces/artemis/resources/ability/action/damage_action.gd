extends TargetAction
class_name DamageAction

@export var damage_minimum: int
@export var damage_maximum: int

func run(caster, target):
	if target.has_method("damage"):
		var accuracy: float = caster.get_accuracy() if caster.has_method("get_accuracy") else 0.0
		target.damage(RNG.curve_with_bias(damage_minimum, damage_maximum, accuracy))
