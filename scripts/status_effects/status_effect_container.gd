class_name StatusEffectContainer
## Runtime state for a status effect on a character.
## Delegates all behavior back to the BaseStatusEffect resource.

var effect: BaseStatusEffect
var source: BattleCharacter
var target: BattleCharacter
var remaining_turns: int

var battle: BattleContext

var stacks: int = 1

## Used by custom effect scripts to store arbitrary state.
var custom_state: Dictionary = {}

func _init(p_effect: BaseStatusEffect, p_source: BattleCharacter, p_target: BattleCharacter, p_battle: BattleContext, p_stack: int = 1) -> void:
	effect = p_effect
	source = p_source
	target = p_target
	battle = p_battle
	stacks = p_stack
	effect._setup_container(self)

func modify_value(field: StatusEffectModifier.Field, value: float) -> float:
	return effect.modify_value(field, value, self)

func run_triggers(trigger: StatusEffectTrigger.Type) -> void:
	return effect.run_triggers(trigger, self)

func on_damage_received(context: AttackContext) -> void:
	effect.on_damage_received(context, self)

func on_damage_dealt(context: AttackContext) -> void:
	effect.on_damage_dealt(context, self)

func on_applied() -> void:
	effect.on_applied(self)

func on_removed() -> void:
	effect.on_removed(self)

## Ticks the effect. Returns true if the effect has expired.
func tick() -> bool:
	return effect.tick(self)
