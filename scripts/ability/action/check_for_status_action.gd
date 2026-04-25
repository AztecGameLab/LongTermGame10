extends TargetAction
class_name CheckForStatusAction

## The status effect to check for
@export var status_effect: BaseStatusEffect

## What happens if the status exists. Optional. If null, nothing happens on miss.
@export var success_action: Action

## What happens if the status doesn't exist. Optional. If null, nothing happens on miss.
@export var fail_action: Action

func run(context: ActionContext) -> void:
	for target in resolve_targets(context):
		## Selects action based on whether the status exists
		var action: Action = success_action if target.get_status_effect(status_effect) else fail_action
		## Calls the action
		if action:
			await action.run(context)
