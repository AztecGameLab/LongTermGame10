class_name AttackContext

## The original damage before any modifiers.
var damage: int

## Who dealt the damage. May be null for effect or environment damage.
var source: Character

## Who is receiving the damage.
var target: Character

func _init(p_damage: int, p_target: Character, p_source: Character) -> void:
	damage = p_damage
	target = p_target
	source = p_source
