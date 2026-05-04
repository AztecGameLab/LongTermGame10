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

## Chance per incoming hit to knock out a charge. Reduced by the holder's Luck.
@export_range(0.0, 1.0, 0.05) var break_chance: float = 0.5

func get_effect_name(_container: StatusEffectContainer) -> String:
	return name

func get_effect_description(container: StatusEffectContainer) -> String:
	var pct := int(round(break_chance * 100.0))
	if container.stacks >= 3:
		return "Magic Cannon is loaded. Each turn loaded builds 1 charge for the next shot. Each incoming hit has a %d%% chance to remove 1 charge, dispelling the cannon if charges drop below 0. Luck makes the chance lower." % pct
	return "Magic Cannon is loaded. Each incoming hit has a %d%% chance to dispel it. Luck makes the chance lower." % pct

func on_applied(container: StatusEffectContainer) -> void:
	_set_state(container, 0)

func on_damage_received(_context: AttackContext, container: StatusEffectContainer) -> void:
	var modified_break := break_chance
	if container.target:
		modified_break -= container.target.get_modified_field(StatusEffectModifier.Field.OUTGOING_LUCK)
	if not RNG.chance(modified_break):
		return
	var state := _get_state(container) - 1
	if state < 0:
		container.target.remove_status_effect_instance(container)
	else:
		_set_state(container, state)

func run_triggers(type: StatusEffectTrigger.Type, container: StatusEffectContainer) -> void:
	if type == StatusEffectTrigger.Type.ON_TURN_END:
		_iterate_state(container)
		
func get_remaining_turns(container: StatusEffectContainer) -> int:
	if container.stacks >= 3:
		return _get_state(container)
	return -1
