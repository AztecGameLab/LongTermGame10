extends TargetAction
class_name ApplyStatusAction

## The number of stacks of the effect to apply.
## [br]Only applies to the first application, any ones after will only add 1 stack.
@export var applied_stacks: int = 1
@export var status_effect: StatusEffect

func run(source: Character, target: Character) -> void:
	if status_effect:
		target.add_status_effect(status_effect, source, applied_stacks)
