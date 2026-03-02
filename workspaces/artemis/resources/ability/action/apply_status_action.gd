extends TargetAction
class_name ApplyStatusAction

@export var status_effect: StatusEffect

func run(source: Character, target: Character) -> void:
	if status_effect:
		target.add_status_effect(status_effect, source)
	finished.emit()
