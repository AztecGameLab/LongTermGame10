extends TargetAction
class_name DamageAction

@export var damage_minimum: int
@export var damage_maximum: int

## Whether this attack is able to miss, based on [code]StatusEffectModifier.FIELD.*_HIT_CHANCE[/code]
## [br]
## [br]For more control, set to false and use [HitChanceAction]
@export var can_miss: bool = true

func run(source: Character, target: Character) -> void:
	if can_miss and not BattleManager.check_hit_success(source, target):
		return

	var damage_bias := 0.0
	if source:
		damage_bias = source.get_modified_field(StatusEffectModifier.Field.OUTGOING_DAMAGE_RNG_BIAS)
	var damage := RNG.curve_with_bias(damage_minimum, damage_maximum, damage_bias)

	BattleManager.apply_damage(damage, source, target)
