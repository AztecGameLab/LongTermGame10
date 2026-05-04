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
		print(source.character_name + " using " + ability.get_label(source) + " on " + (str(targets) if targets else "no one"))
		source.used_ability.emit(ability, targets)
	var first_target := true
	for target in targets.filter(func(c): return c.alive):
		await action.run(ActionContext.new(source, target, battle_context, source, null, first_target, ability))
		first_target = false

	# Block the queue until any audio (voiceline, SFX) the source kicked off finishes,
	# so the next ability cast doesn't trample it. Group actions inside this run already
	# finished without waiting on audio.
	if source:
		for child in source.get_children():
			if child is AudioStreamPlayer:
				if child.playing:
					await child.finished
				child.queue_free()
