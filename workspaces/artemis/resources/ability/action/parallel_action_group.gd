extends Action
class_name ParallelActionGroup

@export_group("Action Group")
@export var actions: Array[Action];

func run(caster, target):
	for action in actions:
		action.run(caster, target)
	var signals: Array[Signal] = []
	for action in actions:
		signals.append(action.finished)
	await Signals.all(signals)
	finished.emit()
