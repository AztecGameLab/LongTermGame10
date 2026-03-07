extends Action
class_name RepeatAction

@export_range(1, 20) var times: int = 1
@export_range(0.0, 1.0, 0.05) var hit_chance_decrease: float = 0.0
@export var action: Action
@export_range(0.0, 5.0, 0.1, "suffix:secs") var delay: float = 0.3

func run(source: Character, target: Character) -> void:
	if action:
		var hit_chance := 1.0
		for i in range(times):
			
			var calc_chance := hit_chance
			if source:
				calc_chance = source.get_modified_field(StatusEffectModifier.Field.OUTGOING_ATTACK_HIT_CHANCE)
			calc_chance = source.get_modified_field(StatusEffectModifier.Field.INCOMING_ATTACK_HIT_CHANCE)
			
			var success: bool = RNG.chance(calc_chance)
			
			if not success:
				return
			
			await action.run(source, target)
			hit_chance -= hit_chance_decrease
			if delay > 0.0 and i < times - 1:
				await Engine.get_main_loop().create_timer(delay).timeout
