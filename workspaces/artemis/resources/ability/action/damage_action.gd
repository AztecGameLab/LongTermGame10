extends TargetAction
class_name DamageAction

@export var damage_minimum: int
@export var damage_maxiumum: int

func run(caster, target):
	if target.has_method("damage"):
		target.damage(randi_range(damage_minimum, damage_maxiumum))
