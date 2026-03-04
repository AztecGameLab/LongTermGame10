extends TargetAction
class_name StaticDamageAction

@export var damage: int

## Whether this attack is able to miss, based on [code]StatusEffectModifier.FIELD.*_HIT_CHANCE[/code]
## [br]
## [br]For more control, use [HitChanceAction]
@export var can_miss: bool = true

func run(source: Character, target: Character) -> void:
	if can_miss and not BattleManager.check_hit_success(source, target):
		finished.emit()
		return

	BattleManager.apply_damage(damage, source, target)
	finished.emit()
