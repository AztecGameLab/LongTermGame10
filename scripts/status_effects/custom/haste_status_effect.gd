extends BaseStatusEffect
class_name HasteStatusEffect

func get_effect_description(_container: StatusEffectContainer) -> String:
	return "Dodge the next incoming attacks"

func get_effect_name(_container: StatusEffectContainer) -> String:
	return "Haste"

func modify_value(field: StatusEffectModifier.Field, value: float, container: StatusEffectContainer) -> float:
	match field:
		StatusEffectModifier.Field.INCOMING_ATTACK_HIT_CHANCE:
			container.stacks -= 1
			if container.stacks <= 0:
				container.target.remove_status_effect_instance(container)
			return 0.0
	return value

func get_remaining_turns(container: StatusEffectContainer) -> int:
	return container.stacks
