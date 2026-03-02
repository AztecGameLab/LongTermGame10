extends Resource
class_name StatusEffectModifier
## A component of a Status Effect that specifies a modification to a value of a character's action

enum FIELD {
	## Modifies the raw amount of damage done by any actions from this character.
	OUTGOING_DAMAGE,
	
	## Modifies the raw amount of damage done by any actions towards this character.
	INCOMING_DAMAGE,
	
	## Modifies the chance that an outgoing attack action is successful.[br]
	## This field is a value from [code]0.0[/code] to [code]1.0[/code], which defaults to [code]1.0[/code].
	OUTGOING_ATTACK_HIT_CHANCE,
	
	## Modifies the chance that an incoming attack action is successful.[br]
	## This field is a float from [code]0.0[/code] to [code]1.0[/code], which defaults to [code]1.0[/code].
	INCOMING_ATTACK_HIT_CHANCE,
	
	## Modifies the "luck" of any actions taken by a character.[br]
	## This field is a float from [code]-1.0[/code] to [code]1.0[/code], which defaults to [code]0.0[/code]
	OUTGOING_LUCK,
	
	## Modifies the chance that an attack action hits towards the minimum or maximum ends of its damage range.[br]
	## This field is a float from [code]-1.0[/code] to [code]1.0[/code], which defaults to [code]0.0[/code]
	OUTGOING_DAMAGE_RNG_BIAS,
	
	## Modifies the raw amount of healing done by any actions from this character.
	INCOMING_HEALING,
	
	## Modifies the raw amount of healing done by any actions towards this character.
	OUTGOING_HEALING
}

enum TYPE {
	## Adds the modifier to the value.[br]
	## Use negative numbers to subtract.
	ADD,
	## Multiplies the value by the modifier.[br]
	## Use values <1 to divide, i.e. [code]30% = value * 0.3[/code]
	MULTIPLY
}

@export var modifier_field: FIELD
@export var modifier_type: TYPE
@export var modifier_amount: float


func modify_value(value: float) -> float:
	match modifier_type:
		TYPE.ADD:
			return value + modifier_amount;
		TYPE.MULTIPLY:
			return value * modifier_amount;
		_:
			# Default case, should never fire.
			return value
