extends Node2D
class_name BattleManager
## Contains logic for the actual battle management.

## --- Static/Helper Methods ---

## Checks if an attack hits successfully. Returns [code]true[/code] if it hits, [code]false[/code] if it misses.
static func check_hit_success(source: BattleCharacter, target: BattleCharacter) -> bool:
	var hit_chance := 1.0
	if source:
		hit_chance = source.get_outgoing_hit_chance(hit_chance)
	hit_chance = target.get_incoming_hit_chance(hit_chance)
	return RNG.chance(hit_chance)

## Applies damage from [param source] to [param target]. 
## Also triggers the appropriate signals on both characters.
static func apply_damage(damage: int, source: BattleCharacter, target: BattleCharacter) -> void:
	if source:
		damage = source.get_outgoing_damage(damage)
	damage = target.get_incoming_damage(damage)

	var context := AttackContext.new(damage, source, target)

	if source:
		source.on_damage_dealt(context)
	target.on_damage_received(context)

static func apply_healing(healing: int, source: BattleCharacter, target: BattleCharacter) -> void:
	if source:
		healing = source.get_outgoing_healing(healing)
	healing = target.get_incoming_healing(healing)
	target.heal(healing, source)

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
			if source.last_attacker and source.last_attacker.alive:
				targets = [source.last_attacker]
		BaseAbility.TargetType.ENEMY:
			var alive_enemies := target_team.filter(func(enemy): return enemy.alive)
			if alive_enemies.size() > 0:
				targets = [alive_enemies.pick_random()]
		BaseAbility.TargetType.ALL_ENEMIES:
			targets = target_team
		BaseAbility.TargetType.EVERYONE:
			targets.append_array(source_team)
			targets.append_array(target_team)
	return targets.filter(func(target): return target and target.alive)

static func get_actions(battle_context: BattleContext, source_team: Array[BattleCharacter], target_team: Array[BattleCharacter]) -> Array[QueuedAction]:
	var actions: Array[QueuedAction] = []
	for character in source_team:
		if not character.alive:
			continue
		var ability: BaseAbility = character.abilities.pick_random()
		if not ability:
			print(character.name + " has no abilities and will do nothing.")
			continue
		var targets := get_targets(character, source_team, target_team, ability.get_target_type(character))
		if targets.size() == 0:
			print(character.name + " has no valid targets and will do nothing.")
			continue
		var action := QueuedAction.new(battle_context, ability.get_action(character), character, targets, ability)
		actions.append(action)
	return actions

## --- Main Class ---

signal round_started
signal round_ended
signal game_ended

@export var player_team: Array[BattleCharacter]
@export var boss_team: Array[BattleCharacter]

var _queued_actions: Array[QueuedAction]

var turn: int = 0

var _battle_running: bool = true

var _battle_context: BattleContext

func _ready() -> void:
	_queued_actions = []
	_battle_context = BattleContext.new(player_team, boss_team)
	for character in player_team:
		character.battle = _battle_context
	for character in boss_team:
		character.battle = _battle_context

func insert_next_action(actions: QueuedAction):
	_queued_actions.insert(0, actions)

func _run_actions():
	round_started.emit()
	while (_queued_actions.size() > 0):
		var action := _queued_actions[0]
		_queued_actions.remove_at(0)
		var source := action.source
		if (not source) or source.alive:
			await action.run()
		# FIXME: Temporary timeout to wait after each turn.
		# This is here mainly since we have no animations yet.
		await get_tree().create_timer(0.5).timeout
	round_ended.emit()

func check_team_alive(team: Array[BattleCharacter]) -> bool:
	for character in team:
		if not character.alive:
			return false
	return true

func run_turn():
	if not _battle_running:
		return
	turn += 1
	print("Turn " + str(turn))
	_queued_actions.append_array(get_actions(_battle_context, player_team, boss_team))
	_queued_actions.append_array(get_actions(_battle_context, boss_team, player_team))
	await _run_actions()
	if (!check_team_alive(player_team)):
		print("Boss Wins!")
		_battle_running = false
		game_ended.emit()
	if (!check_team_alive(boss_team)):
		print("Player Wins!")
		_battle_running = false
		game_ended.emit()
