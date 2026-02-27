class_name DamageContext

## The original damage before any modifiers.
var raw_amount: int

## The current damage value as it moves through the pipeline.
## Status effects can read/write this to modify damage.
var final_amount: int

## Who dealt the damage. May be null for effect or environment damage.
var source: Character

## Who is receiving the damage.
var target: Character

## True when damage is reflected (e.g. Riposte).
## Check this in reflection effects to prevent infinite loops.
var is_reflected: bool = false

func _init(p_raw_amount: int, p_source: Character, p_target: Character) -> void:
	raw_amount = p_raw_amount
	final_amount = p_raw_amount
	source = p_source
	target = p_target
