extends TargetAction
class_name StatusAction

# TODO: Replace with Status Effect Resource
@export var status_effect: String

func run(caster, target):
	if caster.has_method("add_status"):
		caster.add_status(status_effect)
