extends BaseStatusEffect
class_name StatusEffect
## A basic status effect.
## [br]You can give this any number of stacks, 
## each with its own modifiers and triggers.

@export var stacks: Array[StatusEffectStack]

@export_group("Limited Duration")
## Disable for effects that last until explicitly removed.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var limited_duration: bool = true
@export var duration_turns: int = 3

var max_stack:
	get:
		return stacks.size()

func run_triggers(type: StatusEffectTrigger.Type, _instance: StatusEffectContainer) -> void:
	# Get the current stack
	var stack := stacks[_instance.stacks - 1]
	for trigger in stack.triggers:
		if trigger.trigger_type == type and trigger.action:
			await trigger.action.run(ActionContext.new(null, _instance.target, _instance.battle, _instance.source, _instance))

func modify_value(field: StatusEffectModifier.Field, value: float, _instance: StatusEffectContainer) -> float:
	var modified_value := value
	var field_modifiers := _get_modifiers(field, _instance)
	for modifier in field_modifiers:
		modified_value = modifier.modify_value(modified_value)
	return modified_value

func _get_modifiers(field: StatusEffectModifier.Field, _instance: StatusEffectContainer) -> Array[StatusEffectModifier]:
	var stack := stacks[_instance.stacks - 1]
	return stack.modifiers.filter(func(m): return m.modifier_field == field);

# --- Overrides ---

func tick(container: StatusEffectContainer) -> bool:
	if not limited_duration:
		return false
	container.remaining_turns -= 1
	return container.remaining_turns <= 0

func on_reapplied(container: StatusEffectContainer, p_stacks: int, p_max_stacks: int) -> void:
	var new_stacks = mini(container.stacks + p_stacks, max_stack)
	if p_max_stacks > 0:
		new_stacks = mini(new_stacks, p_max_stacks)
	container.stacks = maxi(new_stacks, container.stacks)
	container.remaining_turns = duration_turns

func _setup_container(container: StatusEffectContainer) -> void:
	container.remaining_turns = duration_turns

func get_effect_description(container: StatusEffectContainer) -> String:
	return stacks[container.stacks - 1].description

func get_remaining_turns(container: StatusEffectContainer) -> int:
	if not limited_duration:
		return -1
	return container.remaining_turns

# --- Virtual Methods ---
# Override these in a custom script for effects that need special behavior.

## Override to react to the attached character taking damage.
func on_damage_received(_context: AttackContext, _instance: StatusEffectContainer) -> void:
	pass

## Override to react to the attached character dealing damage.
func on_damage_dealt(_context: AttackContext, _instance: StatusEffectContainer) -> void:
	pass

## Override to run logic when the effect is first applied.
func on_applied(_instance: StatusEffectContainer) -> void:
	pass

## Override to clean up when the effect is removed.
func on_removed(_instance: StatusEffectContainer) -> void:
	pass
