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

## The chance that this concentration will break when the character is hurt.
@export_range(0.0, 1.0, 0.05) var break_chance: float = 0.5

func get_effect_name(_container: StatusEffectContainer) -> String:
	return name

func get_effect_description(_container: StatusEffectContainer) -> String:
	return """
	The Magic Cannon ability is charging.
	"""

func on_applied(container: StatusEffectContainer) -> void:
	_set_state(container, 0)

func run_triggers(type: StatusEffectTrigger.Type, container: StatusEffectContainer) -> void:
	if type == StatusEffectTrigger.Type.ON_TURN_END:
		_iterate_state(container)
