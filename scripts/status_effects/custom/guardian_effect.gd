extends BaseStatusEffect
class_name GuardianStatusEffect
## Modified from the task list. Instead of half/full concentration, simply applies for the duration of the round that it's cast in.
## It gives the character 50% incoming damage, and no new negative effects.

@export_group("Limited Duration")
## Disable for effects that last until explicitly removed.
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var limited_duration: bool = true
@export var duration_turns: int = 3

func get_effect_description(_container: StatusEffectContainer) -> String:
	return "Take less damage, and don't receive negative effects."

func get_effect_name(_container: StatusEffectContainer) -> String:
	return "Guardian"

func should_apply_effect(status_effect: BaseStatusEffect) -> bool:
	return status_effect.effect_type != BaseStatusEffect.EffectType.NEGATIVE

func modify_value(field: StatusEffectModifier.Field, value: float, _container: StatusEffectContainer) -> float:
	if field == StatusEffectModifier.Field.INCOMING_DAMAGE:
		return value / 2
		
	return value

func tick(container: StatusEffectContainer) -> bool:
	if not limited_duration:
		return false
	container.remaining_turns -= 1
	return container.remaining_turns <= 0

func on_reapplied(container: StatusEffectContainer, p_stacks: int, p_max_stacks: int) -> void:
	container.remaining_turns = duration_turns

func _setup_container(container: StatusEffectContainer) -> void:
	container.remaining_turns = duration_turns

func get_remaining_turns(container: StatusEffectContainer) -> int:
	if not limited_duration:
		return -1
	return container.remaining_turns
