extends TargetAction
class_name StaticDamageAction

@export var damage: int

func run(source: Character, target: Character) -> void:
	if source:
		source.deal_outgoing_damage(damage, target)
	else:
		target.receive_incoming_damage(damage, null)
	finished.emit()
