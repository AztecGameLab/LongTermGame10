extends Resource
class_name Ability

enum MoveTargetType {
	## Targets the character using the move.
	SELF,
	## Targets everybody on the battlefield.
	EVERYONE,
	
	## Targets a teammate
	TEAMMATE,
	## Targets a teammate, but not the character using the move.
	TEAMMATE_EXCLUDE_SELF,
	## Targets the entire team of the character using the move.
	ALL_TEAMMATES,
	
	## Targets one enemy character.
	ENEMY,
	## Targets the entire enemy team.
	ALL_ENEMIES,
};

@export var name: String;
@export_multiline() var description: String;

## What character(s) should be able to be selected when using this move?[br][br]
## This is from the perspective of the character using the move,
## i.e. "enemy" for the boss would be one of the player's characters.
@export var move_target_type: MoveTargetType = MoveTargetType.ENEMY;

## The action(s) to take.[br]
## For multiple actions, use a ParallelActionGroup or SequencedActionGroup depending on whether you want
## them to execute simultaneously, or one after another with a delay.
@export var action: Action;
