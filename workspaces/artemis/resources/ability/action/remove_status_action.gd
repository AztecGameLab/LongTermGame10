extends TargetAction
class_name RemoveStatusAction

@export var status_effect: StatusEffect

func run(_caster: Character, target: Character) -> void:
	if status_effect:
		target.remove_status_effect(status_effect)
	finished.emit()
