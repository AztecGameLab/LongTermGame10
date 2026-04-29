@abstract
@icon("uid://ds4qxgv6y0gbu")
extends Resource
class_name BaseAbility

enum TargetType {
	## Targets the character using the move.
	SELF,
	## Targets everybody on the battlefield.
	EVERYONE,
	## Targets the last character that attacked the character using this move.
	ATTACKER,
	
	## Targets a teammate
	TEAMMATE,
	## Targets a teammate, but not the character using the move.
	TEAMMATE_EXCLUDE_SELF,
	## Targets everyone on the team except for the character using the move.
	ALL_TEAMMATES_EXCLUDE_SELF,
	## Targets the entire team of the character using the move.
	ALL_TEAMMATES,
	
	## Targets one enemy character.
	ENEMY,
	## Targets the entire enemy team.
	ALL_ENEMIES,
};

@abstract func get_label(source: BattleCharacter) -> String;
	
@abstract func get_description(source: BattleCharacter) -> String;

@abstract func get_target_type(source: BattleCharacter) -> BaseAbility.TargetType;

@abstract func get_action(source: BattleCharacter) -> Action;
