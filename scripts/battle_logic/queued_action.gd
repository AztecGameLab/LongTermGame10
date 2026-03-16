class_name QueuedAction
## Represents a set of action that is going to be run by the [BattleManager].

## The [Action] that will be ran.
var action: Action

## The [Character] that the action will affect.
var target: Character

## The [Character] that the action will come from.
## [br]This may be null if it comes from a status effect, the environment, etc.
var source: Character = null

## The ability these actions come from, if it is a character's direct turn.
## This will be null if it is a reactive action, for instance a revenge when getting hit.
var ability: Ability = null

func _init(p_action: Action, p_source: Character, p_target: Character, p_ability: Ability) -> void:
	action = p_action
	target = p_target
	source = p_source
	ability = p_ability

func run():
	print(ability.name)
	if source and ability:
		await source.on_turn_started()
		source.used_ability.emit(ability, target)
	await action.run(source, target)
	if source and ability:
		await source.on_turn_ended()
