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
@export var action_target: Ability.MoveTargetType;
