@abstract
extends Action
class_name TargetAction
## Any action type that acts [i]on[/i] a target. 
## This includes healing, damage, applying statuses, etc.

@export_group("Override Target")
## Whether to target the same character as the main ability.[br]
## Leave disabled to use the same target.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var override_target: bool
## Applies if overriding the target
@export var action_target: BaseAbility.TargetType;

func resolve_targets(context: ActionContext) -> Array[BattleCharacter]:
	if not override_target:
		return [context.target]
	if context.source != null:
		return BattleManager.get_targets(
			context.source,
			context.battle.get_allies(context.source),
			context.battle.get_enemies(context.source),
			action_target
		)
	else:
		# FIXME: I'm not sure what the actual best thing to do here.
		# 
		# This makes it so that status effect actions pick the target from the perspective 
		# of the attached character, which makes them work for what we need.
		return BattleManager.get_targets(
			context.target,
			context.battle.player_team,
			context.battle.boss_team,
			action_target
		)
