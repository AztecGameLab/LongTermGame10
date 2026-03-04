class_name StatusEffectContainer
## Runtime state for a status effect on a character.
## Delegates all behavior back to the StatusEffect resource.

var effect: StatusEffect
var source: Character
var target: Character
var remaining_turns: int

var stacks: int = 1

## Used by custom effect scripts to store arbitrary state. 
var custom_state: Dictionary = {}

func _init(p_effect: StatusEffect, p_source: Character, p_target: Character) -> void:
	effect = p_effect
	source = p_source
	target = p_target
	remaining_turns = p_effect.duration_turns

func modify_value(field: StatusEffectModifier.FIELD, value: float) -> float:
	return effect.modify_value(field, value, self)

func on_damage_received(context: AttackContext) -> void:
	effect.on_damage_received(context, self)

func on_damage_dealt(context: AttackContext) -> void:
	effect.on_damage_dealt(context, self)

func on_applied() -> void:
	effect.on_applied(self)

func on_removed() -> void:
	effect.on_removed(self)

## Ticks down duration. Returns true if the effect has expired.
func tick_duration() -> bool:
	if not effect.limited_duration:
		return false
	remaining_turns -= 1
	return remaining_turns <= 0

func add_stack() -> void:
	if stacks < effect.max_stacks:
		stacks += 1
	remaining_turns = effect.duration_turns
