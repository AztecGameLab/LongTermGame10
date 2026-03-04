extends Action
class_name RepeatAction

@export_range(1, 20) var times: int = 1
@export var action: Action
@export_range(0.0, 5.0, 0.1, "suffix:secs") var delay: float = 0.3

func run(source: Character, target: Character) -> void:
	if action:
		for i in range(times):
			await action.run(source, target)
			if delay > 0.0 and i < times - 1:
				await Engine.get_main_loop().create_timer(delay).timeout
