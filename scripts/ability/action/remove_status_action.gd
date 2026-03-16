extends TargetAction
class_name RemoveStatusAction

## The number of stacks of the effect to remove from the target.
@export var remove_stacks: int = 1

## The status effect to remove
@export var status_effect: StatusEffect

func run(_source: Character, target: Character) -> void:
	if status_effect:
		target.remove_status_effect(status_effect, remove_stacks)
