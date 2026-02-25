@abstract
extends Action
class_name TargetAction

@export_group("Override Target")
## Whether to target the same character as the main ability.[br]
## Leave disabled to use the same target.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var override_target: bool
@export var action_target: Ability.MoveTargetType;
