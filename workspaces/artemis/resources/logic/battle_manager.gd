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


## --- Main Class ---

var _queued_actions: Array[QueuedAction]

var _current_action_index: int

func insert_next_action(action: QueuedAction):
	_queued_actions.insert(_current_action_index + 1, action)

func _run_actions():
	_current_action_index = 0;
	while (_current_action_index < _queued_actions.size()):
		var action := _queued_actions[_current_action_index]
		action.run()
		await action.finished
