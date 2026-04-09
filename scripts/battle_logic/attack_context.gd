class_name AttackContext
## Context object for a character dealing damage to another.

## The damage after any modifiers.
var damage: int

## The original damage before any modifiers.
var original_damage: int

## The damage after source modifiers bur before target modifiers.
var true_damage: int

## Who dealt the damage. May be null for effect or environment damage.
var source: BattleCharacter

## Who is receiving the damage.
var target: BattleCharacter

func _init(p_damage: int, p_source: BattleCharacter, p_target: BattleCharacter, p_original_damage: int = -1, p_true_damage: int = -1) -> void:
	damage = p_damage
	source = p_source
	target = p_target
	
	# If no original damage was provided, assume it's the same as the initial damage
	if p_original_damage == -1:
		original_damage = p_damage
	else:
		original_damage = p_original_damage
	
	# If no true damage was provided, assume it's the same as the initial damage
	if p_true_damage == -1:
		true_damage = p_damage
	else:
		true_damage = p_true_damage
