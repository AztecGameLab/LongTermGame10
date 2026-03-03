extends TargetAction
class_name StaticDamageAction

@export var damage: int

## Whether this attack is able to miss, based on [code]StatusEffectModifier.FIELD.*_HIT_CHANCE[/code]
## [br]
## [br]For more control, use [HitChanceAction]
@export var can_miss: bool = true

func run(source: Character, target: Character) -> void:
	if can_miss:
		var hit_chance := 1.0
		if source:
			hit_chance = source.get_outgoing_hit_chance(hit_chance)
		hit_chance = target.get_incoming_hit_chance(hit_chance)
		if RNG.chance(hit_chance) == false:
			# Missed
			finished.emit()
			return
	
	if source:
		damage = source.get_outgoing_damage(damage)
	damage = target.get_incoming_damage(damage)
	
	var context := AttackContext.new(damage, target, source)
	
	if source:
		source.on_damage_dealt(context)
	target.on_damage_received(context)

	finished.emit()
