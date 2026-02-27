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
signal status_effect_added(instance: StatusEffectInstance)
signal status_effect_removed(instance: StatusEffectInstance)

# --- Exports ---

@export var max_health: int = 50

@export var abilities: Array[Ability]

@export_group("Stats")
## Outgoing damage scaling. 1.0 = normal damage.
@export var base_damage_multiplier: float = 1.0

## Percentage of incoming damage reduced. 0.0 = no reduction, 1.0 = immune.
@export_range(0.0, 1.0, 0.05) var base_defense: float = 0.0

## Biases damage rolls toward max or min value.[br]
## -1.0 = always min, 0.0 = centered, 1.0 = always max.
@export_range(-1.0, 1.0, 0.05) var base_accuracy: float = 0.0

## Chance to completely avoid an incoming hit.
@export_range(0.0, 1.0, 0.05) var base_dodge: float = 0.0

## Used by ability-specific RNG checks.
@export_range(-1.0, 1.0, 0.05) var base_luck: float = 0.0

## Used by the AI to determine which character to target. Higher danger = more likely to be targeted.
@export_range(0.0, 10.0, 0.1) var base_danger: float = 1.0

# --- Runtime State ---

var current_health: int
var _status_effects: Array[StatusEffectInstance] = []

func _ready() -> void:
	current_health = max_health


# --- Stat Pipeline ---

## Gets the effective value of a stat, after all status effect modifiers.
func get_stat(stat: Stat) -> float:
	var value: float
	match stat:
		Stat.DAMAGE_MULTIPLIER: value = base_damage_multiplier
		Stat.DEFENSE: value = base_defense
		Stat.ACCURACY: value = base_accuracy
		Stat.DODGE: value = base_dodge
		Stat.LUCK: value = base_luck
		Stat.DANGER: value = base_danger
		_: value = 0.0
	for instance in _status_effects:
		value = instance.compute_stat_modifier(stat, value)
	return value


# --- Damage/Heal Pipeline ---

## Runs incoming damage through the full pipeline and applies it.
func receive_damage(raw_amount: int, source: Character = null, is_reflected: bool = false) -> DamageContext:
	var context := DamageContext.new(raw_amount, source, self )
	context.is_reflected = is_reflected

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
func add_status_effect(effect: StatusEffect, source: Character = null) -> StatusEffectInstance:
	var existing := get_status_effect(effect)

	if existing:
		existing.refresh_duration()
		return existing

	var instance := StatusEffectInstance.new(effect, self , source)
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

func remove_status_effect_instance(instance: StatusEffectInstance) -> void:
	if instance in _status_effects:
		_remove_effect_instance(instance)

func get_status_effect(effect: StatusEffect) -> StatusEffectInstance:
	for instance in _status_effects:
		if instance.effect == effect:
			return instance
	return null

func has_status_effect(effect: StatusEffect) -> bool:
	return get_status_effect(effect) != null

func get_all_status_effects() -> Array[StatusEffectInstance]:
	return _status_effects.duplicate()


# --- Turn Lifecycle ---

## Called by the battle system right before this character acts.
func on_turn_started() -> void:
	for instance in _status_effects.duplicate():
		_run_effect_trigger(instance, StatusEffect.TriggerType.ON_TURN_START)

## Called by the battle system right after this character acts.
## Ticks down durations and removes expired effects.
func on_turn_ended() -> void:
	var expired: Array[StatusEffectInstance] = []
	for instance in _status_effects.duplicate():
		_run_effect_trigger(instance, StatusEffect.TriggerType.ON_TURN_END)
		if instance.tick_duration():
			expired.append(instance)

	for instance in expired:
		_remove_effect_instance(instance)


# --- Internals ---

func _remove_effect_instance(instance: StatusEffectInstance) -> void:
	_status_effects.erase(instance)
	instance.on_removed()
	status_effect_removed.emit(instance)

func _run_effect_trigger(instance: StatusEffectInstance, trigger: StatusEffect.TriggerType) -> void:
	if instance.effect.has_trigger and instance.effect.trigger_type == trigger and instance.effect.trigger_action:
		# Has no "Caster" since they run automatically on certain events, instead of being activated by a character.
		instance.effect.trigger_action.run(null, instance.owner)


func die() -> void:
	died.emit()
	# TODO: Change from `queue_free()` to a proper death system later on.
	queue_free()
