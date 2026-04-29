extends BaseAbility
class_name Ability

@export var name: String;
@export_multiline() var description: String;

## What character(s) should be able to be selected when using this move?[br][br]
## This is from the perspective of the character using the move,
## i.e. "enemy" for the boss would be one of the player's characters.
@export var move_target_type: BaseAbility.TargetType = BaseAbility.TargetType.ENEMY;

## The action(s) to take.[br]
## For multiple actions you may use a [GroupAction]
@export var action: Action;

func get_label(source: BattleCharacter) -> String:
	return name
	
func get_description(source: BattleCharacter) -> String:
	return description

func get_target_type(_source: BattleCharacter) -> BaseAbility.TargetType:
	return move_target_type

func get_action(_source: BattleCharacter) -> Action:
	return action
