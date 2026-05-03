extends BaseStatusEffect
class_name MagicCannonStatusEffect

const CUSTOM_STATE_KEY := &"magic_cannon"

static func _get_state(container: StatusEffectContainer) -> int:
	return container.custom_state.get(CUSTOM_STATE_KEY)
	
static func _set_state(container: StatusEffectContainer, value: int) -> void:
	container.custom_state.set(CUSTOM_STATE_KEY, value)
	
static func _iterate_state(container: StatusEffectContainer) -> int:
	var state: int = _get_state(container)
	state += 1
	_set_state(container, state)
	return state
	
static func _erase_state(container: StatusEffectContainer) -> void:
	container.custom_state.erase(CUSTOM_STATE_KEY)

## How many charges are knocked out per incoming hit. Cannon is lost when charges go below 0.
@export_range(1, 10, 1) var charges_lost_per_hit: int = 2

func get_effect_name(_container: StatusEffectContainer) -> String:
	return name

func get_effect_description(container: StatusEffectContainer) -> String:
	if container.stacks >= 3:
		return "Magic Cannon is loaded. Each turn loaded builds 1 charge for the next shot. Each incoming hit removes %d charges. The cannon dispels when charges drop below 0." % charges_lost_per_hit
	return "Magic Cannon is loaded. Any incoming hit dispels it."

func on_applied(container: StatusEffectContainer) -> void:
	_set_state(container, 0)

func on_damage_received(context: AttackContext, container: StatusEffectContainer) -> void:
	var state := _get_state(container) - charges_lost_per_hit
	if state < 0:
		context.target.remove_status_effect_instance(container)
	else:
		_set_state(container, state)

func run_triggers(type: StatusEffectTrigger.Type, container: StatusEffectContainer) -> void:
	if type == StatusEffectTrigger.Type.ON_TURN_END:
		_iterate_state(container)
		
func get_remaining_turns(container: StatusEffectContainer) -> int:
	if container.stacks >= 3:
		return _get_state(container)
	return -1
