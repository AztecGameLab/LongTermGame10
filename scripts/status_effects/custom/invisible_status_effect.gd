extends BaseStatusEffect
class_name InvisibleStatusEffect
## A status effect that reduces targeting chance based on stacks.
## When the character deals damage, they always roll max damage,
## and there is a chance the effect ends.

@export var max_stacks: int = 4

## The description for the hover tooltip.
@export_multiline var description: String

## How much targeting chance to reduce per stack (as a percentage).
## e.g. 0.25 means each stack reduces targeting chance by 25%.
@export var target_reduction_per_stack: float = 0.25

## The chance (0.0 to 1.0) that the effect ends when dealing damage.
@export var break_chance: float = 0.5

func modify_value(field: StatusEffectModifier.Field, value: float, container: StatusEffectContainer) -> float:
	match field:
		StatusEffectModifier.Field.INCOMING_TARGET_CHANCE:
			# Reduce targeting chance by (reduction * stacks)
			return value + value * (-target_reduction_per_stack * container.stacks)
		StatusEffectModifier.Field.OUTGOING_DAMAGE_RNG_BIAS:
			# Always max roll while in stealth
			return 1.0
	return value

func on_damage_dealt(_context: AttackContext, container: StatusEffectContainer) -> void:
	if RNG.chance(break_chance):
		container.target.remove_status_effect_instance(container)

func stacks_to_alpha(stacks: int):
	const min_alpha := 0.5
	const max_alpha := 0.9
	var alpha = max_alpha - (float(stacks) / max_stacks) * (max_alpha - min_alpha)
	return alpha

func on_applied(container: StatusEffectContainer) -> void:
	container.target.modulate.a = stacks_to_alpha(container.stacks)
	
func on_removed(container: StatusEffectContainer) -> void:
	container.target.modulate.a = 1.0

func tick(container: StatusEffectContainer) -> bool:
	container.stacks -= 1
	container.target.modulate.a = stacks_to_alpha(container.stacks)
	return container.stacks <= 0

func on_reapplied(container: StatusEffectContainer, stacks: int, p_max_stacks: int) -> void:
	var new_stacks := container.stacks + stacks
	new_stacks = mini(new_stacks, max_stacks)
	if p_max_stacks > 0:
		new_stacks = mini(new_stacks, p_max_stacks)
	container.stacks = new_stacks
	container.target.modulate.a = stacks_to_alpha(container.stacks)

func get_effect_description(_container: StatusEffectContainer) -> String:
	return description

func get_remaining_turns(container: StatusEffectContainer) -> int:
	return container.stacks
