extends BaseStatusEffect
class_name ConcentrationStatusEffect
## A status effect that represents a character concentrating on something. 
## This is used for abilities that require concentration, such as channeling or maintaining a buff.

const CONCENTRATION_STATE_KEY := &"concentration"

static func _get_state(container: StatusEffectContainer) -> ConcentrationState:
	return container.custom_state.get(CONCENTRATION_STATE_KEY)
	
static func _set_state(container: StatusEffectContainer, state: ConcentrationState) -> void:
	container.custom_state.set(CONCENTRATION_STATE_KEY, state)
	
static func _erase_state(container: StatusEffectContainer) -> void:
	container.custom_state.erase(CONCENTRATION_STATE_KEY)

@export var full_capacity_stack: StatusEffectStack

@export var half_capacity_stack: StatusEffectStack

## The chance that this concentration will break when the character is hurt.
@export_range(0.0, 1.0, 0.05) var break_chance: float = 0.5

func get_effect_description(container: StatusEffectContainer) -> String:
	var state := _get_state(container)
	var stack: StatusEffectStack = full_capacity_stack if state.full_capacity else half_capacity_stack
	return stack.description

func on_applied(container: StatusEffectContainer) -> void:
	var state := ConcentrationState.new()
	_set_state(container, state)
	
func on_reapplied(container: StatusEffectContainer, _stacks: int, _max_stacks: int) -> void:
	var state: ConcentrationState = _get_state(container)
	state._was_used = true

func on_removed(container: StatusEffectContainer) -> void:
	_erase_state(container)
	
func modify_value(field: StatusEffectModifier.Field, value: float, container: StatusEffectContainer) -> float:
	var modified_value := value
	var field_modifiers := _get_modifiers(field, container)
	for modifier in field_modifiers:
		modified_value = modifier.modify_value(modified_value)
	return modified_value

func _get_modifiers(field: StatusEffectModifier.Field, container: StatusEffectContainer) -> Array[StatusEffectModifier]:
	var state := _get_state(container)
	var stack: StatusEffectStack = full_capacity_stack if state.full_capacity else half_capacity_stack
	return stack.modifiers.filter(func(m): return m.modifier_field == field);

func run_triggers(type: StatusEffectTrigger.Type, container: StatusEffectContainer) -> void:
	var state: ConcentrationState = _get_state(container)
	if not state:
		return
	var stack: StatusEffectStack = full_capacity_stack if state.full_capacity else half_capacity_stack
	for trigger in stack.triggers:
		if trigger.trigger_type == type and trigger.action:
			await trigger.action.run(ActionContext.new(null, container.target, container.battle, container.source, container))
	
	if type == StatusEffectTrigger.Type.ON_TURN_END:
		state.turns_concentrated += 1
		if state.full_capacity != state._was_used:
			state.full_capacity = state._was_used
			state._was_used = false
		updated.emit()

func on_damage_received(_context: AttackContext, container: StatusEffectContainer) -> void:
	if RNG.chance(break_chance):
		_context.target.remove_status_effect_instance(container)
