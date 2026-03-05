class_name QueuedAction
## Represents an action that is going to be run by the [BattleManager].

## The [Action] that will be ran.
var action: Action

## The [Character] that the action will affect.
var target: Character

## The [Character] that the action will come from.
## [br]This may be null if it comes from a status effect, the environment, etc.
var source: Character

func _init(p_action: Action, p_source: Character, p_target: Character) -> void:
	action = p_action
	target = p_target
	source = p_source

func run():
	await action.run(source, target)
