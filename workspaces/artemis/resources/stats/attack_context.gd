class_name AttackContext

## The original damage before any modifiers.
var damage: int

var did_miss: bool = false

## Who dealt the damage. May be null for effect or environment damage.
var source: Character

## Who is receiving the damage.
var target: Character

## Initializes a new attack context.[br]
## Instead of doing this directly, use [AttackContext.Builder]
func _init(p_target: Character) -> void:
	self.target = p_target

class Builder:
	var raw_damage: int
	var can_miss: bool = false

	var source: Character
	var target: Character

	func _init(p_raw_damage: int, p_target: Character) -> void:
		self.raw_damage = p_raw_damage
		self.target = p_target

	func with_source(source: Character) -> Builder:
		self.source = source
		return self

	func with_missable(missable: bool = true) -> Builder:
		self.can_miss = missable
		return self

	func calculate() -> AttackContext:
		var context := AttackContext.new(target)
		context.source = source
		var did_miss := false
		if can_miss and target:
			var hit_chance := 1.0
			if source:
				hit_chance *= source.get_modified_field(StatusEffectModifier.FIELD.OUTGOING_ATTACK_HIT_CHANCE)
			hit_chance *= target.get_modified_field(StatusEffectModifier.FIELD.INCOMING_ATTACK_HIT_CHANCE)
			
			did_miss = clampf(hit_chance, 0.0, 1.0) < randf()
		
		if did_miss:
			context.damage = 0
			context.did_miss = true
		else:
			var calc_damage := raw_damage
			if source:
				calc_damage = source.get_modified_field(StatusEffectModifier.FIELD.OUTGOING_DAMAGE, calc_damage)
			calc_damage = target.get_modified_field(StatusEffectModifier.FIELD.INCOMING_DAMAGE, calc_damage)
			context.damage = calc_damage
			context.did_miss = false

		return context
