@icon("uid://b230jcebk6c8q")
extends Resource
class_name StatusEffect

enum TriggerType {
	## Runs before the owner acts. Good for regen/buffs.
	ON_TURN_START,
	## Runs after the owner acts. Good for Poison/Bleed.
	ON_TURN_END,
	## Runs when the owner takes damage.
	ON_DAMAGED,
	## Runs when the owner is targeted by an attack (before damage).
	ON_ATTACKED,
	## Runs when an ally of the owner is attacked.
	ON_ALLY_ATTACKED,
}

@export var name: String
@export_multiline var description: String

@export var stacks: Array[StatusEffectStack]

@export_group("Limited Duration")
## Disable for effects that last until explicitly removed.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var limited_duration: bool = true
@export var duration_turns: int = 3

var max_stacks:
	get:
		return stacks.size()

func run_triggers(type: StatusEffectTrigger.Type, _instance: StatusEffectContainer) -> void:
	# Get the current stack
	var stack := stacks[_instance.stacks - 1]
	for trigger in stack.triggers:
		if trigger.trigger_type == type and trigger.action:
			await trigger.action.run(null, _instance.target)

func modify_value(field: StatusEffectModifier.Field, value: float, _instance: StatusEffectContainer) -> float:
	var modified_value := value
	var field_modifiers := _get_modifiers(field, _instance)
	for modifier in field_modifiers:
		modified_value = modifier.modify_value(modified_value)
	return modified_value

func _get_modifiers(field: StatusEffectModifier.Field, _instance: StatusEffectContainer) -> Array[StatusEffectModifier]:
	var stack := stacks[_instance.stacks - 1]
	return stack.modifiers.filter(func(m): return m.modifier_field == field);

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
