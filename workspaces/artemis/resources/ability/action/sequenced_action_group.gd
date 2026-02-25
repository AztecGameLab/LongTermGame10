extends Action
class_name SequencedActionGroup

## The sequence of actions to execute in order.
@export var actions: Array[Action];

## The seconds to wait between one action finishing,
## and the next one starting.
@export_range(0.0, 5.0, 0.1, "suffix:secs") var delay: float = 1.0

func run(caster, target):
	for action in actions:
		action.run(caster, target)
		await action.finished
		if delay > 0.0:
			await Engine.get_main_loop().create_timer(delay).timeout
	finished.emit()
