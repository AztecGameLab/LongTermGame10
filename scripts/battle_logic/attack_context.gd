class_name AttackContext

## The original damage before any modifiers.
var damage: int

## Who dealt the damage. May be null for effect or environment damage.
var source: Character

## Who is receiving the damage.
var target: Character

func _init(p_damage: int, p_source: Character, p_target: Character) -> void:
	damage = p_damage
	source = p_source
	target = p_target
