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

func on_reapplied(container: StatusEffectContainer, p_stacks: int, p_max_stacks: int) -> void:
	var new_stacks := container.stacks + p_stacks
	if p_max_stacks > 0:
		new_stacks = mini(new_stacks, p_max_stacks)
	container.stacks = new_stacks
