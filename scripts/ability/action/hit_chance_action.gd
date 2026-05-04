extends Action
class_name HitChanceAction

## The chance of success.[br]
## 0.0 = guaranteed fail, 0.5 = 50/50, 1.0 = guaranteed success.
## Can be modified by status effects through hit chance.
@export_range(0.0, 1.0, 0.05) var success_chance: float = 1.0

@export var success_action: Action

## Optional. If null, nothing happens on miss.
@export var fail_action: Action

## Whether this represents an attack hit roll. When [code]true[/code] and the roll fails,
## the target's [signal BattleCharacter.missed] is emitted (drives the "Miss" indicator).
## Set [code]false[/code] for non-attack chances (e.g., status application rolls) so a fail
## doesn't show a misleading "Miss".
@export var is_attack: bool = true

func run(context: ActionContext) -> void:
	var calc_chance := success_chance
	if context.source:
		calc_chance = context.source.get_outgoing_hit_chance(calc_chance)
	calc_chance = context.target.get_incoming_hit_chance(calc_chance)

	var success: bool = RNG.chance(calc_chance)
	if not success and is_attack and context.target:
		context.target.missed.emit()

	var action: Action = success_action if success else fail_action

	if action:
		await action.run(context)
