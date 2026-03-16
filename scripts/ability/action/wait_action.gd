extends TargetAction
class_name WaitAction

## The time that this should wait before the next action.
@export_range(0.0, 10.0, 0.1, "prefix:secs") var timeout: float = 1.0

func run(_source: Character, _target: Character) -> void:
	await Engine.get_main_loop().create_timer(timeout).timeout
