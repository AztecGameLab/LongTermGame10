extends BaseStatusEffect
class_name ConcentrationStatusEffect
## A status effect that represents a character concentrating on something. 
## This is used for abilities that require concentration, such as channeling or maintaining a buff.

## This is the "key" that is used to track
## the state of the character's concentration.
## [br]This should be unique.
@export var concentration_label: String

## The description of the effect for the hover tooltip.
@export_multiline var description: String

func get_effect_description(_container: StatusEffectContainer) -> String:
	return description

func on_applied(container: StatusEffectContainer) -> void:
	if not concentration_label:
		push_warning("No concentration label set for " + get_effect_name(container))
	
	# FIXME: For now, just setting to "true". However, any dict or class can 
	# be put here when the system is more defined.
	container.custom_state.set(concentration_label, true)

func on_removed(container: StatusEffectContainer) -> void:
	if not concentration_label:
		push_warning("No concentration label set for " + get_effect_name(container))
	
	# FIXME: For now, just setting to "true". However, any dict or class can 
	# be put here when the system is more defined.
	container.custom_state.erase(concentration_label)
