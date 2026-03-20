extends BaseStatusEffect
class_name ConcentrationStatusEffect
## A status effect that represents a character concentrating on something. 
## This is used for abilities that require concentration, such as channeling or maintaining a buff.

@export_multiline var description: String

@export var ability: Ability

func get_effect_description(_container: StatusEffectContainer) -> String:
	return description
