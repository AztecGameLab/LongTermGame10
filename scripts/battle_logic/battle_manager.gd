extends Node2D
class_name BattleManager
## Contains logic for the actual battle management.

## --- Static/Helper Methods ---

## Checks if an attack hits successfully. Returns [code]true[/code] if it hits, [code]false[/code] if it misses.
## Emits [signal BattleCharacter.missed] on the target when the attack misses.
static func check_hit_success(source: BattleCharacter, target: BattleCharacter) -> bool:
	var hit_chance := 1.0
	if source:
		hit_chance = source.get_outgoing_hit_chance(hit_chance)
	hit_chance = target.get_incoming_hit_chance(hit_chance)
	var success := RNG.chance(hit_chance)
	if not success:
		target.missed.emit()
	return success

## Applies damage from [param source] to [param target]. 
## Also triggers the appropriate signals on both characters.
static func apply_damage(damage: int, source: BattleCharacter, target: BattleCharacter) -> void:
	var original_damage = damage
	if source:
		damage = source.get_outgoing_damage(damage)
	var true_damage = damage
	damage = target.get_incoming_damage(damage)

	var context := AttackContext.new(damage, source, target, original_damage, true_damage)

	if source:
		source.on_damage_dealt(context)
	await target.on_damage_received(context)
	await target.on_attacked(context)

static func apply_healing(healing: int, source: BattleCharacter, target: BattleCharacter) -> void:
	if source:
		healing = source.get_outgoing_healing(healing)
	healing = target.get_incoming_healing(healing)
	target.heal(healing, source)

static func pick_weighted_target(team: Array[BattleCharacter]) -> BattleCharacter:
	var targets: Array[BattleCharacter] = team.filter(func(character): return character.alive)
	var weights: Array[float] = []
	for target in targets:
		var weight := target.get_modified_field(StatusEffectModifier.Field.INCOMING_TARGET_CHANCE, 1.0)
		weights.append(maxf(weight, 0.0))

	# weighted random selection
	var total: float = 0.0
	for weight in weights:
		total += weight
	if total <= 0.0:
		# If all characters have no weight, pick randomly.
		return targets.pick_random()

	var roll := randf() * total
	for i in targets.size():
		roll -= weights[i]
		if roll <= 0.0:
			return targets[i]
	return targets[-1]

static func get_targets(source: BattleCharacter, source_team: Array[BattleCharacter], target_team: Array[BattleCharacter], move_target_type: BaseAbility.TargetType) -> Array[BattleCharacter]:
	var targets: Array[BattleCharacter] = []
	match move_target_type:
		BaseAbility.TargetType.SELF:
			targets = [source]
		BaseAbility.TargetType.ALL_TEAMMATES:
			targets = source_team
		BaseAbility.TargetType.ALL_TEAMMATES_EXCLUDE_SELF:
			targets = source_team.filter(func(teammate): return teammate != source)
		BaseAbility.TargetType.ATTACKER:
			if source and source.last_attacker and source.last_attacker.alive:
				targets = [source.last_attacker]
		BaseAbility.TargetType.ENEMY:
			targets = [pick_weighted_target(target_team)]
		BaseAbility.TargetType.TEAMMATE:
			var alive_teammates := source_team.filter(func(teammate): return teammate.alive)
			if alive_teammates.size() > 0:
				targets = [alive_teammates.pick_random()]
		BaseAbility.TargetType.TEAMMATE_EXCLUDE_SELF:
			var alive_teammates_ex := source_team.filter(func(teammate): return teammate.alive and teammate != source)
			if alive_teammates_ex.size() > 0:
				targets = [alive_teammates_ex.pick_random()]
		BaseAbility.TargetType.ALL_ENEMIES:
			targets = target_team
		BaseAbility.TargetType.EVERYONE:
			targets.append_array(source_team)
			targets.append_array(target_team)
			
	return targets.filter(func(target): return target and target.alive)

## --- Main Class ---

signal battle_ready

signal round_started
signal round_ended
signal game_ended(did_player_win: bool)

@export var player_team: Array[BattleCharacter]
@export var boss_team: Array[BattleCharacter]

## Optional: scene to load when the player wins this battle. Leave null
## to skip auto-transition.
@export var next_scene_on_win: PackedScene

## Optional: scene to load when the player loses this battle.
## Typically points at lose_screen.tscn.
@export var next_scene_on_loss: PackedScene

var _queued_actions: Array[QueuedAction]

var turn: int = 0

var battle_running: bool = true

var battle_context: BattleContext

var _player_battle_team: PlayerTeam
var _boss_battle_team: BossTeam

func _ready() -> void:
	_queued_actions = []
	battle_context = BattleContext.new(player_team, boss_team)
	for character in player_team:
		character.battle = battle_context
		character.battle_init()
	for character in boss_team:
		character.battle = battle_context
		character.battle_init()
	_player_battle_team = PlayerTeam.new(player_team, battle_context)
	_boss_battle_team = BossTeam.new(boss_team, battle_context)
	game_ended.connect(_on_game_ended)
	battle_ready.emit()
	run_turn()

func _on_game_ended(did_player_win: bool) -> void:
	var target: PackedScene = next_scene_on_win if did_player_win else next_scene_on_loss
	if target == null:
		return
	# Brief result pause, then fade and transition.
	await get_tree().create_timer(1.5).timeout
	var fade := get_node_or_null(^"Fade") as Fade
	if fade:
		await fade.fadeout()
	get_tree().change_scene_to_packed(target)

func insert_next_action(actions: QueuedAction):
	_queued_actions.insert(0, actions)

func _run_actions(after_each_action: Callable):
	while _queued_actions.size() > 0 and battle_running:
		var action := _queued_actions[0]
		_queued_actions.remove_at(0)
		var source := action.source
		if (not source or source.alive):
			await action.run()
		after_each_action.call()
		await get_tree().create_timer(0.35).timeout

func check_player_win():
	if not _boss_battle_team.is_any_alive():
		print("Player Wins!")
		battle_running = false
		game_ended.emit(true)
		
func check_boss_win():
	if not _player_battle_team.is_any_alive():
		print("Boss Wins!")
		battle_running = false
		game_ended.emit(false)

func run_turn():
	if not battle_running:
		return
	turn += 1
	
	# Player picks moves before turn starts
	_queued_actions.append_array(await _player_battle_team.pick_abilities())
	
	print("Turn " + str(turn))
	round_started.emit()
	for character in _player_battle_team.get_alive_characters():
		await character.on_turn_started()
	for character in _boss_battle_team.get_alive_characters():
		await character.on_turn_started()
		
	# Run all player actions
	await _run_actions(check_player_win)
	if not battle_running:
		return
		
	# Boss picks moves *after* player actions run.
	# This allows invisibility and others to take effect.
	_queued_actions.append_array(_boss_battle_team.pick_abilities())
	# Run all boss actions
	await _run_actions(check_boss_win)
	if not battle_running:
		return
		
	print("Turn Over")
	for character in _player_battle_team.get_alive_characters():
		await character.on_turn_ended()
	for character in _boss_battle_team.get_alive_characters():
		await character.on_turn_ended()
	round_ended.emit()
	check_player_win()
	check_boss_win()
	if not battle_running:
		return
	run_turn()
