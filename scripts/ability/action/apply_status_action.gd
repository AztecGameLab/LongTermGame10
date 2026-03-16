extends TargetAction
class_name ApplyStatusAction

## The number of stacks of the effect to apply on the [b]first[/b] application.
@export var applied_stacks: int = 1
## The number of stacks of the effect to apply [b]after[/b] the first application.
## [br]i.e. if the target has 1 stack and this is set to 2, the target will then have 3 stacks.
@export var upgrade_stacks: int = 1

## The status effect to apply
@export var status_effect: StatusEffect

## The maximum stacks this action can set it to. 
## [br]Even if the effect has higher stacks, it will be capped from this action.
## [br]Set to [code]0[/code] to have no limit.
@export var max_stacks: int = 0

func run(source: Character, target: Character) -> void:
	if status_effect:
		target.add_status_effect(status_effect, source, applied_stacks, max_stacks)
