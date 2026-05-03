extends Action
class_name LuckChanceAction

## Rolls a chance with linear luck modifier.[br]
## Final chance = [code]base_chance + source's OUTGOING_LUCK[/code], clamped to 0-1.
@export_range(0.0, 1.0, 0.05) var base_chance: float = 0.5

@export var success_action: Action

## Optional. If null, nothing happens on miss.
@export var fail_action: Action

func run(context: ActionContext) -> void:
	var chance := base_chance
	if context.source:
		chance += context.source.get_modified_field(StatusEffectModifier.Field.OUTGOING_LUCK)

	var success: bool = RNG.chance(chance)

	var action: Action = success_action if success else fail_action

	if action:
		await action.run(context)
