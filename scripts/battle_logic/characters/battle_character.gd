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
## Fires when an attack against this character misses.
signal missed()

signal health_updated(new_health: int)
signal died()

signal used_ability(ability: BaseAbility, targets: Array[BattleCharacter])

signal status_effect_added(instance: StatusEffectContainer)
signal status_effect_removed(instance: StatusEffectContainer)
signal status_effects_updated()

# --- Exports ---

@export var character_name: String = ""

@export var max_health: int = 50

@export var abilities: Array[BaseAbility]

@export var initial_status_effects: Array[ApplyStatusAction]

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

var selected: bool:
	set(value):
		if _selection_box:
			_selection_box.visible = value
		selected = value

# --- Component Nodes ---
var _animated_sprite: AnimatedSprite2D
var _selection_box: NinePatchRect

## If set on the scene's character node, abilities will be loaded from GameState
## at this level when GameState is initialized. Falls back to scene-defined abilities
## when GameState is empty (direct-launch testing).
@export var battle_level: int = 0


# --- Normal Functions ---
func _ready() -> void:
	_animated_sprite = get_node_or_null("AnimatedSprite2D")
	if _animated_sprite:
		# Return to the idle animation when any animation finishes (attack or status)
		_animated_sprite.animation_finished.connect(play_animation.bind("idle"))
		# Reset visual state in case shader/modulate was mutated by a prior battle's die().
		# ShaderMaterial may be a shared resource that retains parameter changes across scenes.
		_animated_sprite.modulate = Color.WHITE
		var sm := _animated_sprite.material
		if sm and sm is ShaderMaterial:
			sm.set_shader_parameter("saturation", 1.0)
	_selection_box = get_node_or_null("SelectedIndicator")
	if _selection_box:
		selected = false

	_load_abilities_from_state()
	current_health = max_health

## Override scene-defined abilities with GameState's progression if available.
func _load_abilities_from_state() -> void:
	if battle_level <= 0:
		return
	var gs := get_node_or_null(^"/root/GameState")
	if gs == null or not gs.is_initialized():
		return
	var character_id: String = gs.character_id_from_name(character_name)
	if character_id.is_empty():
		return
	var resolved: Array[BaseAbility] = gs.get_abilities_at_level(character_id, battle_level)
	if resolved.size() > 0:
		abilities = resolved

func battle_init() -> void:
	for apply_status_action in initial_status_effects:
		add_status_effect(apply_status_action.status_effect, self, apply_status_action.applied_stacks, apply_status_action.max_stacks)

## Returns true if an animation was started, false otherwise
func play_animation(animation: String) -> void:
	if _animated_sprite:
		_animated_sprite.play(animation)
		await _animated_sprite.animation_finished

func die() -> void:
	#visible = false
	if _animated_sprite:
		_animated_sprite.stop()
		_animated_sprite.modulate = Color(0.35, 0.35, 0.35)
		var shader_material := _animated_sprite.material
		if shader_material and shader_material is ShaderMaterial:
			shader_material.set_shader_parameter("saturation", 0.1)
	died.emit()


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
	for instance in _status_effects.duplicate():
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
	var actual := mini(maxi(0, amount), max_health - current_health)
	current_health += actual
	healed.emit(actual, source)


# --- Status Effect Management ---

## Applies a status effect. If already active, delegates reapplication to the effect.
func add_status_effect(effect: BaseStatusEffect, source: BattleCharacter, stacks: int = 1, max_stacks: int = -1) -> StatusEffectContainer:
	for current_effect in _status_effects:
		if not current_effect.effect.should_apply_effect(effect):
			return
	
	var existing := get_status_effect(effect)

	if existing:
		existing.effect.on_reapplied(existing, stacks, max_stacks)
		status_effects_updated.emit()
		return existing

	var instance := StatusEffectContainer.new(effect, source, self, battle, stacks)
	_status_effects.append(instance)
	instance.on_applied()
	status_effect_added.emit(instance)
	status_effects_updated.emit()
	return instance

func remove_status_effect(effect: BaseStatusEffect, stacks: int) -> void:
	var instance := get_status_effect(effect)
	if instance:
		if stacks == -1 or stacks >= instance.stacks:
			_remove_effect_instance(instance)
		else:
			instance.stacks -= stacks
		status_effects_updated.emit()
			
func remove_all_effects(effect_type: BaseStatusEffect.EffectType):
	var effects = _status_effects.duplicate()
	if effect_type:
		effects = effects.filter(func(e): return e.effect_type == effect_type)
	for effect in effects:
		remove_status_effect(effect, -1)

func remove_status_effect_instance(instance: StatusEffectContainer) -> void:
	if instance in _status_effects:
		_remove_effect_instance(instance)
		status_effects_updated.emit()

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
		
	status_effects_updated.emit()

func on_damage_dealt(attackContext: AttackContext):
	for instance in _status_effects.duplicate():
		instance.on_damage_dealt(attackContext)
		
func on_damage_received(attackContext: AttackContext):
	if attackContext.source != null and attackContext.source != self:
		last_attacker = attackContext.source

	var damage := maxi(attackContext.damage, 0)
	current_health -= damage
	current_health = maxi(current_health, 0)
	
	for instance in _status_effects.duplicate():
		instance.on_damage_received(attackContext)

	damaged.emit(damage, attackContext)

	if current_health <= 0:
		die()

func on_attacked(attackContext: AttackContext):
	for instance in _status_effects.duplicate():
		await instance.on_attacked(attackContext)

# --- Internals ---

func _remove_effect_instance(instance: StatusEffectContainer) -> void:
	_status_effects.erase(instance)
	instance.on_removed()
	status_effect_removed.emit(instance)
