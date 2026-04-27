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

## An action that happens if the full sequence completes (meaning everything hits)
@export var sequence_complete_action: Action

func run(context: ActionContext) -> void:
	if action:
		var action_successful := true 
		var hit_chance := 1.0
		for i in range(times):
			var calc_chance := hit_chance
			if context.source:
				calc_chance = context.source.get_outgoing_hit_chance(calc_chance)
			calc_chance = context.target.get_incoming_hit_chance(calc_chance)

			var success: bool = RNG.chance(calc_chance)
			
			if (not success):
				print("dart miss")
				action_successful = false
				if stop_on_miss:
					print("stopping...")
					return
				continue
			
			print("dart hit!")
			await action.run(context)
			hit_chance -= hit_chance_decrease
		
		# if the sequence fully completes, run sequence_complete_action
		if action_successful and sequence_complete_action:
			print("activating successful sequence action")
			await sequence_complete_action.run(context)
