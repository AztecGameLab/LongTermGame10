class_name StatusEffectInstance
## Runtime state for a status effect on a character.
## Delegates all behavior back to the StatusEffect resource.

var effect: StatusEffect
var owner: Character
var source: Character
var remaining_turns: int

func _init(p_effect: StatusEffect, p_owner: Character, p_source: Character) -> void:
	effect = p_effect
	owner = p_owner
	source = p_source
	remaining_turns = p_effect.duration_turns

func compute_stat_modifier(stat: Character.Stat, current_value: float) -> float:
	return effect.compute_stat_modifier(stat, current_value, self)

func on_damage_received(context: DamageContext) -> void:
	effect.on_damage_received(context, self)

func on_damage_dealt(context: DamageContext) -> void:
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

func refresh_duration() -> void:
	remaining_turns = effect.duration_turns
