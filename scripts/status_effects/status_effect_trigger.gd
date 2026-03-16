extends Resource
class_name StatusEffectTrigger
## A component of a Status Effect that specifies an actions to trigger at a certain point during the battle.

# The available trigger types.
enum Type {
	## Runs before the attached character acts.
	ON_TURN_START,
	## Runs after the attached character acts.
	ON_TURN_END,
	### Runs when the attached character is attacked.
	#ON_ATTACKED,
	### Runs when an ally of the attached character is attacked.
	#ON_ALLY_ATTACKED,
}

## Specifies when this trigger runs during the battle.
@export var trigger_type: Type

## The action(s) to take.[br]
## For multiple actions you may use a [GroupAction]
@export var action: Action;
