extends TargetAction
class_name HealAction

@export var heal_amount: int

func run(source: Character, target: Character) -> void:
	if source:
		source.send_outgoing_heal(heal_amount, target)
	else:
		target.receive_incoming_heal(heal_amount, null)
	finished.emit()
