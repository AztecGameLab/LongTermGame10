extends TargetAction
class_name RetargetAction

## The action to run on the new target(s)
@export var action: Action

func run(context: ActionContext) -> void:
	for target in resolve_targets(context):
		var new_context: ActionContext = context.duplicate()
		new_context.target = target
		action.run(new_context)
