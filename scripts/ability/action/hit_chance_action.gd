extends Action
class_name HitChanceAction

## The chance of success.[br]
## 0.0 = guaranteed fail, 0.5 = 50/50, 1.0 = guaranteed success.
## Can be modified by status effects through hit chance.
@export_range(0.0, 1.0, 0.05) var success_chance: float = 1.0

@export var success_action: Action

## Optional. If null, nothing happens on miss.
@export var fail_action: Action

func run(source: Character, target: Character) -> void:
	
	var calc_chance := success_chance
	if source:
		calc_chance = source.get_modified_field(StatusEffectModifier.Field.OUTGOING_ATTACK_HIT_CHANCE)
	calc_chance = source.get_modified_field(StatusEffectModifier.Field.INCOMING_ATTACK_HIT_CHANCE)
	
	var success: bool = RNG.chance(calc_chance)

	var action: Action = success_action if success else fail_action

	if action:
		await action.run(source, target)
