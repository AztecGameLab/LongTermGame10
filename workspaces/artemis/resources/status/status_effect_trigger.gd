extends Resource
class_name StatusEffectTrigger

enum TriggerType {
	## Runs before the owner acts.
	ON_TURN_START,
	## Runs after the owner acts.
	ON_TURN_END
}

## The action(s) to take.[br]
## For multiple actions, use a ParallelActionGroup or SequencedActionGroup depending on whether you want
## them to execute simultaneously, or one after another with a delay.
@export var action: Action;
