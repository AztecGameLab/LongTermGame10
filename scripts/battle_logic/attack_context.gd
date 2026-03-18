class_name AttackContext
## Context object for a character dealing damage to another.

## The original damage before any modifiers.
var damage: int

## Who dealt the damage. May be null for effect or environment damage.
var source: BattleCharacter

## Who is receiving the damage.
var target: BattleCharacter

func _init(p_damage: int, p_source: BattleCharacter, p_target: BattleCharacter) -> void:
	damage = p_damage
	source = p_source
	target = p_target
