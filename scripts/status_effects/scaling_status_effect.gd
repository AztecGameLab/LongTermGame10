extends BaseStatusEffect
class_name ScalingStatusEffect

@export_multiline() var description: String

@export_group("Scaling")
## The base modifiers to apply. Their values are multiplied by the current stack count.
@export var base_modifiers: Array[StatusEffectModifier]
## The triggers the effect should apply.
@export var triggers: Array[StatusEffectTrigger]
@export var max_stacks: int = 100

@export_group("Duration")
## How many turns this effect lasts.
@export var duration_turns: int = 3

func modify_value(field: StatusEffectModifier.Field, value: float, container: StatusEffectContainer) -> float:
	var modified_value := value
	var field_modifiers = base_modifiers.filter(func(m): return m.modifier_field == field)
	
	for modifier in field_modifiers:
		# Power = Base Amount * Stack Count
		var scaled_amount = modifier.modifier_amount * container.stacks
		
		match modifier.modifier_type:
			StatusEffectModifier.Type.ADD:
				modified_value += scaled_amount
			StatusEffectModifier.Type.ADD_PERCENT:
				modified_value += modified_value * scaled_amount
			StatusEffectModifier.Type.MULTIPLY:
				modified_value *= scaled_amount
				
	return modified_value

func tick(container: StatusEffectContainer) -> bool:
	# Decrement timer, NOT stacks
	container.remaining_turns -= 1
	return container.remaining_turns <= 0

func on_reapplied(container: StatusEffectContainer, p_stacks: int, p_max_stacks: int) -> void:
	var limit = mini(max_stacks, p_max_stacks) if p_max_stacks > 0 else max_stacks
	container.stacks = mini(container.stacks + p_stacks, limit)
	container.remaining_turns = duration_turns

func _setup_container(container: StatusEffectContainer) -> void:
	container.remaining_turns = duration_turns

func get_remaining_turns(container: StatusEffectContainer) -> int:
	return container.remaining_turns

func get_effect_description(_container: StatusEffectContainer) -> String:
	return description
