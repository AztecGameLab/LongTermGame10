@abstract
@icon("uid://b230jcebk6c8q")
extends Resource
class_name BaseStatusEffect
## Base class for all status effect types.
## Subclasses override only the methods relevant to their behavior.

signal updated

## The name shown in the hover tooltip.
@export var name: String

## The icon to show next to the character.
@export var icon: Texture2D

## Type of status effect
enum EffectType {
	POSITIVE,
	NEGATIVE,
	LOCKED
}

## Whether this effect is positive, negative, or locked (cannot be transferred).
@export var effect_type: EffectType = EffectType.NEGATIVE

# --- Virtual Methods ---
# Override in subclasses to customize behavior.

## Runs any triggers of the given type on this effect.
func run_triggers(_type: StatusEffectTrigger.Type, _container: StatusEffectContainer) -> void:
	pass

## Modifies a value based on this effect's modifiers. Returns the value unchanged by default.
func modify_value(_field: StatusEffectModifier.Field, value: float, _container: StatusEffectContainer) -> float:
	return value

## Called when the attached character takes damage.
func on_damage_received(_context: AttackContext, _container: StatusEffectContainer) -> void:
	pass

## Called when the attached character deals damage.
func on_damage_dealt(_context: AttackContext, _container: StatusEffectContainer) -> void:
	pass

## Called when the effect is first applied.
func on_applied(_container: StatusEffectContainer) -> void:
	pass

## Called when the effect is removed.
func on_removed(_container: StatusEffectContainer) -> void:
	pass

## Ticks the effect each turn. Returns [code]true[/code] if the effect has expired.
func tick(_container: StatusEffectContainer) -> bool:
	return false

## Called when the effect is reapplied to a character that already has it.
func on_reapplied(_container: StatusEffectContainer, _stacks: int, _max_stacks: int) -> void:
	pass

## Called by the container's [code]_init[/code] to set initial state.
func _setup_container(_container: StatusEffectContainer) -> void:
	pass

## Returns the display name for this effect.
func get_effect_name(_container: StatusEffectContainer) -> String:
	return name

## Returns the description for this effect.
@abstract func get_effect_description(_container: StatusEffectContainer) -> String;

## Returns the remaining turns for display purposes. Returns [code]-1[/code] if no duration to display.
func get_remaining_turns(_container: StatusEffectContainer) -> int:
	return -1
