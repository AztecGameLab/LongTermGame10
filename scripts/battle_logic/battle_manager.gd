extends Node2D
class_name BattleManager
## Contains logic for the actual battle management.

## --- Static/Helper Methods ---

## Checks if an attack hits successfully. Returns [code]true[/code] if it hits, [code]false[/code] if it misses.
static func check_hit_success(source: Character, target: Character) -> bool:
	var hit_chance := 1.0
	if source:
		hit_chance = source.get_outgoing_hit_chance(hit_chance)
	hit_chance = target.get_incoming_hit_chance(hit_chance)
	return RNG.chance(hit_chance)

## Applies damage from [param source] to [param target]. 
## Also triggers the appropriate signals on both characters.
static func apply_damage(damage: int, source: Character, target: Character) -> void:
	if source:
		damage = source.get_outgoing_damage(damage)
	damage = target.get_incoming_damage(damage)

	var context := AttackContext.new(damage, source, target)

	if source:
		source.on_damage_dealt(context)
	target.on_damage_received(context)

static func apply_healing(healing: int, source: Character, target: Character) -> void:
	if source:
		healing = source.get_outgoing_healing(healing)
	healing = target.get_incoming_healing(healing)
	target.heal(healing, source)

## --- Main Class ---

@export var player_team: Array[Character]
@export var boss_team: Array[Character]

var _queued_actions: Array[QueuedAction]

var turn: int = 0

var _battle_running: bool = true

func insert_next_action(action: QueuedAction):
	_queued_actions.insert(0, action)

func _run_actions():
	while (_queued_actions.size() > 0):
		var action := _queued_actions[0]
		_queued_actions.remove_at(0)
		if (not action.source) or action.source.alive:
			await action.run()

func check_team_alive(team: Array[Character]) -> bool:
	for character in team:
		if not character.alive:
			return false
	return true

func run_turn():
	if not _battle_running:
		return
	turn += 1
	print("Turn " + str(turn))
	for character in player_team:
		if not character.alive:
			continue
		await character.on_turn_started()
		var ability: Ability = character.abilities.pick_random()
		if not ability:
			print(character.name + " using Nothing")
			continue
		print(character.name + " using " + ability.name)
		if ability.move_target_type == Ability.MoveTargetType.SELF:
			_queued_actions.append(QueuedAction.new(ability.action, character, character))
		else:
			var target: Character = boss_team.pick_random()
			_queued_actions.append(QueuedAction.new(ability.action, character, target))
		await character.on_turn_ended()
	for character in boss_team:
		if not character.alive:
			continue
		await character.on_turn_started()
		var ability: Ability = character.abilities.pick_random()
		if not ability:
			print(character.name + " using Nothing")
			continue
		print(character.name + " using " + ability.name)
		if ability.move_target_type == Ability.MoveTargetType.SELF:
			_queued_actions.append(QueuedAction.new(ability.action, character, character))
		else:
			var target: Character = player_team.pick_random()
			_queued_actions.append(QueuedAction.new(ability.action, character, target))
		await character.on_turn_ended()
	await _run_actions()
	if (!check_team_alive(player_team)):
		print("Boss Wins!")
		_battle_running = false
	if (!check_team_alive(boss_team)):
		print("Player Wins!")
		_battle_running = false
