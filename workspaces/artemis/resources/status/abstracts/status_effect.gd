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

@export_group("Limited Duration")
## Disable for effects that last until explicitly removed.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var limited_duration: bool = true
@export var duration_turns: int = 3

@export_group("Stat Modifiers")
## Stat changes that are active while this effect is on a character.
@export var stat_modifiers: Array[StatModifier]

@export_group("Trigger")
## Enable to run an action in response to a game event.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var has_trigger: bool = false
@export var trigger_type: TriggerType = TriggerType.ON_TURN_START
@export var trigger_action: Action


# --- Virtual Methods ---
# Override these in a custom script for effects that need special behavior.

## Override to customize how this effect modifies stats.
## Default just applies the stat_modifiers array.
func compute_stat_modifier(stat: Character.Stat, current_value: float, _instance: StatusEffectInstance) -> float:
	for modifier in stat_modifiers:
		if modifier.stat == stat:
			current_value = modifier.apply(current_value)
	return current_value

## Override to react to the owner taking damage.
func on_damage_received(_context: DamageContext, _instance: StatusEffectInstance) -> void:
	pass

## Override to react to the owner dealing damage.
func on_damage_dealt(_context: DamageContext, _instance: StatusEffectInstance) -> void:
	pass

## Override to run logic when the effect is first applied.
func on_applied(_instance: StatusEffectInstance) -> void:
	pass

## Override to clean up when the effect is removed.
func on_removed(_instance: StatusEffectInstance) -> void:
	pass
