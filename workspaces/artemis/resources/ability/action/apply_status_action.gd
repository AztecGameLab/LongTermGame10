extends TargetAction
class_name ApplyStatusAction

@export var status_effect: StatusEffect

func run(caster: Character, target: Character) -> void:
	if status_effect:
		target.add_status_effect(status_effect, caster)
	finished.emit()
