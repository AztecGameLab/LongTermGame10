extends Resource
class_name StatusEffectTrigger
## A component of a Status Effect that specifies an action to trigger at a certain point during the battle.

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
## For multiple actions, use a ParallelActionGroup or SequencedActionGroup depending on whether you want
## them to execute simultaneously, or one after another with a delay.
@export var action: Action;
