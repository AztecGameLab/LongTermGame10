class_name ActionContext
## Context object for an action/chain of actions being ran

var source: BattleCharacter
var target: BattleCharacter
var battle: BattleContext

## The origin character is the character that initiated the action.
## This effects the "perspective" of the action, such that "self" refers to the origin character.
##
## [br]This is here because the source is used for stat modifiers, but for status effects we may want to
## refer to the character that originally applied it without using their stats.
var origin: BattleCharacter

## The status effect container this action was triggered from, if any.
var container: StatusEffectContainer

## The ability this action chain is part of, if it's a direct ability cast.
## Null for reactive actions (status triggers, counters, etc).
var ability: BaseAbility

var is_first_target: bool

## Multiplier applied to outgoing damage from this action chain.
## Used by RepeatAction to apply diminishing damage per iteration.
var damage_multiplier: float = 1.0

func _init(p_source: BattleCharacter = null, p_target: BattleCharacter = null, p_battle: BattleContext = null, p_origin: BattleCharacter = null, p_container: StatusEffectContainer = null, p_first_target: bool = true, p_ability: BaseAbility = null) -> void:
	source = p_source
	target = p_target
	battle = p_battle
	origin = p_origin
	container = p_container
	is_first_target = p_first_target
	ability = p_ability
