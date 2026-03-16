extends Action
class_name RepeatAction

## The maximum number of times this should run.
@export_range(1, 20) var times: int = 1

## The decrease in hit chance for each subsequent action.[br]
## For example, if this is 0.1, the first action will have a 100% hit chance, the second will have 90%, the third will have 80%, etc.
@export_range(0.0, 1.0, 0.05) var hit_chance_decrease: float = 0.0

## If true, the sequence will stop if any of the actions miss. If false, it will run all [code]times[/code] regardless of hit success.
@export var stop_on_miss: bool

## The action to repeat.[br]
## For multiple actions you may use a [GroupAction]
@export var action: Action

func run(source: Character, target: Character) -> void:
	if action:
		var hit_chance := 1.0
		for i in range(times):
			var calc_chance := hit_chance
			if source:
				calc_chance = source.get_modified_field(StatusEffectModifier.Field.OUTGOING_ATTACK_HIT_CHANCE)
			calc_chance = source.get_modified_field(StatusEffectModifier.Field.INCOMING_ATTACK_HIT_CHANCE)

			var success: bool = RNG.chance(calc_chance)
			
			if (not success):
				if stop_on_miss:
					return
				continue
			
			await action.run(source, target)
			hit_chance -= hit_chance_decrease
