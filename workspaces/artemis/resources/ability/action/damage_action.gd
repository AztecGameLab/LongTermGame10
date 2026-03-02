extends TargetAction
class_name DamageAction

@export var damage_minimum: int
@export var damage_maximum: int

func run(source: Character, target: Character) -> void:
	var damage_bias := 0.0;
	if source:
		damage_bias = source.get_modified_field(StatusEffectModifier.FIELD.OUTGOING_DAMAGE_RNG_BIAS)		
	var damage := RNG.curve_with_bias(damage_minimum, damage_maximum, damage_bias)

	if source:
		source.deal_outgoing_damage(damage, target)
	else:
		target.receive_incoming_damage(damage, null)

	finished.emit()
