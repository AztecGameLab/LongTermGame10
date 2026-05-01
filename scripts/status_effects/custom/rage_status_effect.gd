extends BaseStatusEffect
class_name RageStatusEffect

@export_range(0.0, 2.0, 0.05, "or_greater;suffix=x") var next_attack_damage_multiplier: float = 1.5

func get_effect_description(_container: StatusEffectContainer) -> String:
	return "Power up next attack."

func get_effect_name(_container: StatusEffectContainer) -> String:
	return "Rage"

func modify_value(field: StatusEffectModifier.Field, value: float, container: StatusEffectContainer) -> float:
	if field == StatusEffectModifier.Field.OUTGOING_DAMAGE:
		container.target.remove_status_effect_instance(container)
		return value * next_attack_damage_multiplier
		
	return value
