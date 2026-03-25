class_name QueuedAction
## Represents a set of action that is going to be run by the [BattleManager].

## This is used to store references for the battle, like teams.
var battle_context: BattleContext

## The [Action] that will be ran.
var action: Action

## The [BattleCharacter](s) that the action will affect.
var targets: Array[BattleCharacter]

## The [BattleCharacter] that the action will come from.
## [br]This may be null if it comes from a status effect, the environment, etc.
var source: BattleCharacter = null

## The ability these actions come from, if it is a character's direct turn.
## This will be null if it is a reactive action, for instance a revenge when getting hit.
var ability: BaseAbility = null

func _init(p_battle_context: BattleContext, p_action: Action, p_source: BattleCharacter, p_target: Array[BattleCharacter], p_ability: BaseAbility) -> void:
	battle_context = p_battle_context
	action = p_action
	targets = p_target
	source = p_source
	ability = p_ability

func run():
	if source and ability:
		print(source.name + " using " + ability.name)
		await source.on_turn_started()
		source.used_ability.emit(ability, targets)
	for target in targets:
		await action.run(ActionContext.new(source, target, battle_context, source))
	if source and ability:
		await source.on_turn_ended()
