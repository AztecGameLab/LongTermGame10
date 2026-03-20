extends BaseStatusEffect
class_name FadingStatusEffect
## A status effect with a high stack count that decays by one each turn.
## Modifiers and triggers scale by the current stack count.

@export var max_stacks: int

@export_multiline var description: String

@export var modifiers: Array[StatusEffectModifier]
@export var triggers: Array[StatusEffectTrigger]

func modify_value(field: StatusEffectModifier.Field, value: float, container: StatusEffectContainer) -> float:
	var modified_value := value
	var field_modifiers: Array[StatusEffectModifier] = modifiers.filter(func(m): return m.modifier_field == field)
	for modifier in field_modifiers:
		# Scale the modifier amount by current stacks
		var scaled_amount := modifier.modifier_amount * container.stacks
		match modifier.modifier_type:
			StatusEffectModifier.Type.ADD:
				modified_value += scaled_amount
			StatusEffectModifier.Type.ADD_PERCENT:
				modified_value += modified_value * scaled_amount
			StatusEffectModifier.Type.MULTIPLY:
				modified_value *= scaled_amount
	return modified_value

func run_triggers(type: StatusEffectTrigger.Type, container: StatusEffectContainer) -> void:
	for trigger in triggers:
		if trigger.trigger_type == type and trigger.action:
			await trigger.action.run(ActionContext.new(null, container.target, container.battle, container.source, container))

func tick(container: StatusEffectContainer) -> bool:
	container.stacks -= 1
	return container.stacks <= 0

func on_reapplied(container: StatusEffectContainer, stacks: int, p_max_stacks: int) -> void:
	var new_stacks := container.stacks + stacks
	new_stacks = mini(new_stacks, max_stacks)
	if p_max_stacks != 0:
		new_stacks = mini(new_stacks, p_max_stacks)
	container.stacks = new_stacks

func get_remaining_turns(container: StatusEffectContainer) -> int:
	return container.stacks
