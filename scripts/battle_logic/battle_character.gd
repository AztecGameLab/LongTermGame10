extends Node2D
class_name BattleCharacter
## Basic BattleCharacter Class. Not Final.

enum Stat {
	DAMAGE_MULTIPLIER,
	DEFENSE,
	ACCURACY,
	DODGE,
	LUCK,
	DANGER
}

# --- Signals ---

## Fires when the character is attacked. 
## [br][param amount] is the actual damage dealt until zero. [param context] contains the source and the raw damage.
signal damaged(amount: int, context: AttackContext)
signal healed(amount: int, source: BattleCharacter)

signal health_updated(new_health: int)
signal died()

signal used_ability(ability: Ability, targets: Array[BattleCharacter])

signal status_effect_added(instance: StatusEffectContainer)
signal status_effect_removed(instance: StatusEffectContainer)

# --- Exports ---

@export var max_health: int = 50

@export var abilities: Array[Ability]

# --- Runtime State ---

var current_health: int = 0:
	set(value):
		current_health = value
		health_updated.emit(current_health)
	get():
		return current_health

var alive: bool:
	get():
		return current_health > 0
var _status_effects: Array[StatusEffectContainer] = []

var last_attacker: BattleCharacter = null

var battle: BattleContext

func _ready() -> void:
	current_health = max_health


# --- Stat Pipeline ---

func get_default_field(field: StatusEffectModifier.Field) -> float:
	match field:
		StatusEffectModifier.Field.OUTGOING_ATTACK_HIT_CHANCE:
			return 1.0
		StatusEffectModifier.Field.INCOMING_ATTACK_HIT_CHANCE:
			return 1.0
		StatusEffectModifier.Field.OUTGOING_LUCK:
			return 0.0
		StatusEffectModifier.Field.OUTGOING_DAMAGE_RNG_BIAS:
			return 0.0
		_:
			return 0.0

func get_modified_field(field: StatusEffectModifier.Field, value: float = get_default_field(field)) -> float:
	var modified := value
	for instance in _status_effects:
		modified = instance.modify_value(field, modified)
	return modified
	
func get_outgoing_hit_chance(value: float) -> float:
	return get_modified_field(StatusEffectModifier.Field.OUTGOING_ATTACK_HIT_CHANCE, value)
	
func get_incoming_hit_chance(value: float) -> float:
	return get_modified_field(StatusEffectModifier.Field.INCOMING_ATTACK_HIT_CHANCE, value)
	
func get_outgoing_damage(value: int) -> int:
	return roundi(get_modified_field(StatusEffectModifier.Field.OUTGOING_DAMAGE, value))
	
func get_incoming_damage(value: int) -> int:
	return roundi(get_modified_field(StatusEffectModifier.Field.INCOMING_DAMAGE, value))

func get_outgoing_healing(value: int) -> int:
	return roundi(get_modified_field(StatusEffectModifier.Field.OUTGOING_HEALING, value))
	
func get_incoming_healing(value: int) -> int:
	return roundi(get_modified_field(StatusEffectModifier.Field.INCOMING_HEALING, value))

# --- Damage/Heal Pipeline ---

## Restores health, capped at max_health.
func heal(amount: int, source: BattleCharacter = null) -> void:
	var actual := mini(amount, max_health - current_health)
	current_health += actual
	healed.emit(actual, source)


# --- Status Effect Management ---

## Applies a status effect. If already active, delegates reapplication to the effect.
func add_status_effect(effect: BaseStatusEffect, source: BattleCharacter, stacks: int, max_stacks: int) -> StatusEffectContainer:
	var existing := get_status_effect(effect)

	if existing:
		existing.effect.on_reapplied(existing, stacks, max_stacks)
		return existing

	var instance := StatusEffectContainer.new(effect, source, self, battle, stacks)
	_status_effects.append(instance)
	instance.on_applied()
	status_effect_added.emit(instance)
	return instance

func remove_status_effect(effect: BaseStatusEffect, stacks: int) -> void:
	var instance := get_status_effect(effect)
	if instance:
		if stacks >= instance.stacks:
			_remove_effect_instance(instance)
		else:
			instance.stacks -= stacks

func remove_status_effect_instance(instance: StatusEffectContainer) -> void:
	if instance in _status_effects:
		_remove_effect_instance(instance)

func get_status_effect(effect: BaseStatusEffect) -> StatusEffectContainer:
	for instance in _status_effects:
		if instance.effect == effect:
			return instance
	return null

func has_status_effect(effect: BaseStatusEffect) -> bool:
	return get_status_effect(effect) != null

func get_all_status_effects() -> Array[StatusEffectContainer]:
	return _status_effects.duplicate()


# --- Turn Lifecycle ---

## Called by the battle system right before this character acts.
func on_turn_started() -> void:
	for instance in _status_effects.duplicate():
		await instance.run_triggers(StatusEffectTrigger.Type.ON_TURN_START)

## Called by the battle system right after this character acts.
## Ticks down durations and removes expired effects.
func on_turn_ended() -> void:
	var expired: Array[StatusEffectContainer] = []
	for instance in _status_effects.duplicate():
		await instance.run_triggers(StatusEffectTrigger.Type.ON_TURN_END)
		if instance.tick():
			expired.append(instance)

	for instance in expired:
		_remove_effect_instance(instance)

func on_damage_dealt(attackContext: AttackContext):
	for instance in _status_effects:
		instance.on_damage_dealt(attackContext)
		
func on_damage_received(attackContext: AttackContext):
	if attackContext.source != null and attackContext.source != self:
		last_attacker = attackContext.source

	var damage := maxi(attackContext.damage, 0)
	current_health -= damage
	current_health = maxi(current_health, 0)
	
	for instance in _status_effects:
		instance.on_damage_received(attackContext)

	damaged.emit(damage, attackContext)

	if current_health <= 0:
		die()

# --- Internals ---

func _remove_effect_instance(instance: StatusEffectContainer) -> void:
	_status_effects.erase(instance)
	instance.on_removed()
	status_effect_removed.emit(instance)


func die() -> void:
	died.emit()
