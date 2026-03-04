extends Action
class_name ParallelActionGroup

@export_group("Action Group")
@export var actions: Array[Action];

func run(source: Character, target: Character) -> void:
	var coroutines: Array[Callable] = []
	for action in actions:
		coroutines.append(func(): await action.run(source, target))
	await Concurrently.fire_all(coroutines)
