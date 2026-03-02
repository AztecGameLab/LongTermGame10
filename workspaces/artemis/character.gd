extends Node2D
class_name Character
## Basic Character Class. Not Final.

enum Stat {
	DAMAGE_MULTIPLIER,
	DEFENSE,
	ACCURACY,
	DODGE,
	LUCK,
	DANGER
}

# --- Signals ---

signal damaged(amount: int, source: Character)
signal healed(amount: int, source: Character)
signal died()
signal status_effect_added(instance: StatusEffectContainer)
signal status_effect_removed(instance: StatusEffectContainer)

# --- Exports ---

@export var max_health: int = 50

@export var abilities: Array[Ability]

# --- Runtime State ---

var current_health: int
var _status_effects: Array[StatusEffectContainer] = []

func _ready() -> void:
	current_health = max_health


# --- Stat Pipeline ---

func get_default_field(field: StatusEffectModifier.FIELD) -> float:
	match field:
		StatusEffectModifier.FIELD.OUTGOING_ATTACK_HIT_CHANCE:
			return 1.0
		StatusEffectModifier.FIELD.INCOMING_ATTACK_HIT_CHANCE:
			return 1.0
		StatusEffectModifier.FIELD.OUTGOING_LUCK:
			return 0.0
		StatusEffectModifier.FIELD.OUTGOING_DAMAGE_RNG_BIAS:
			return 0.0
		_:
			return 0.0

func get_modified_field(field: StatusEffectModifier.FIELD, value: float = get_default_field(field)) -> float:
	var modified := value
	for instance in _status_effects:
		modified = instance.modify_value(field, modified)
	return modified

## Gets the effective value of a stat, after all status effect modifiers.
func get_stat(stat: Stat) -> float:
	# TODO: Use new stats
	return 0.0


# --- Damage/Heal Pipeline ---

func deal_outgoing_damage(damage: int, target: Character):
	var context := AttackContext.new(target)
	context.damage = damage
	context.source = self
	target.receive_damage(damage, self)
	for instance in _status_effects.duplicate():
		instance.on_damage_dealt(context)
	pass

func receive_incoming_damage(damage: int, source: Character = null) -> void:
	
	pass

func receive_incoming_heal(amount: int, source: Character = null) -> void:

	pass

func send_outgoing_heal(amount: int, target: Character):
	target.receive_incoming_heal(amount, self)

## Runs incoming damage through the full pipeline and applies it.
func receive_damage(raw_amount: int, source: Character = null) -> AttackContext:
	var context := AttackContext.new(self)
	context.damage = raw_amount
	context.source = source
	# Source's outgoing damage multiplier
	if source:
		var multiplier := source.get_stat(Stat.DAMAGE_MULTIPLIER)
		context.final_amount = roundi(context.final_amount * multiplier)

	# Target's defense reduction
	var defense := get_stat(Stat.DEFENSE)
	if defense > 0.0:
		context.final_amount = roundi(context.final_amount * (1.0 - clampf(defense, 0.0, 1.0)))

	# Status effect intercepts
	for instance in _status_effects.duplicate():
		instance.on_damage_received(context)
	if source:
		for instance in source._status_effects.duplicate():
			instance.on_damage_dealt(context)

	# Apply final damage
	context.final_amount = maxi(context.final_amount, 0)
	current_health -= context.final_amount
	current_health = maxi(current_health, 0)

	damaged.emit(context.final_amount, source)

	if current_health <= 0:
		die()

	return context

## Restores health, capped at max_health.
func heal(amount: int, source: Character = null) -> void:
	var actual := mini(amount, max_health - current_health)
	current_health += actual
	healed.emit(actual, source)


# --- Status Effect Management ---

## Applies a status effect. If already active, refreshes the duration instead.
func add_status_effect(effect: StatusEffect, source: Character = null) -> StatusEffectContainer:
	var existing := get_status_effect(effect)

	if existing:
		existing.refresh_duration()
		return existing

	var instance := StatusEffectContainer.new(effect, self , source)
	_status_effects.append(instance)
	instance.on_applied()
	status_effect_added.emit(instance)
	return instance

func remove_status_effect(effect: StatusEffect) -> bool:
	var instance := get_status_effect(effect)
	if instance:
		_remove_effect_instance(instance)
		return true
	return false

func remove_status_effect_instance(instance: StatusEffectContainer) -> void:
	if instance in _status_effects:
		_remove_effect_instance(instance)

func get_status_effect(effect: StatusEffect) -> StatusEffectContainer:
	for instance in _status_effects:
		if instance.effect == effect:
			return instance
	return null

func has_status_effect(effect: StatusEffect) -> bool:
	return get_status_effect(effect) != null

func get_all_status_effects() -> Array[StatusEffectContainer]:
	return _status_effects.duplicate()


# --- Turn Lifecycle ---

## Called by the battle system right before this character acts.
func on_turn_started() -> void:
	for instance in _status_effects.duplicate():
		_run_effect_trigger(instance, StatusEffect.TriggerType.ON_TURN_START)

## Called by the battle system right after this character acts.
## Ticks down durations and removes expired effects.
func on_turn_ended() -> void:
	var expired: Array[StatusEffectContainer] = []
	for instance in _status_effects.duplicate():
		_run_effect_trigger(instance, StatusEffect.TriggerType.ON_TURN_END)
		if instance.tick_duration():
			expired.append(instance)

	for instance in expired:
		_remove_effect_instance(instance)


# --- Internals ---

func _remove_effect_instance(instance: StatusEffectContainer) -> void:
	_status_effects.erase(instance)
	instance.on_removed()
	status_effect_removed.emit(instance)

func _run_effect_trigger(instance: StatusEffectContainer, trigger: StatusEffect.TriggerType) -> void:
	if instance.effect.has_trigger and instance.effect.trigger_type == trigger and instance.effect.trigger_action:
		# Has no "source" since they are not directly caused by an ability.
		instance.effect.trigger_action.run(null, instance.owner)


func die() -> void:
	died.emit()
	# TODO: Change from `queue_free()` to a proper death system later on.
	queue_free()
