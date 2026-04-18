@abstract
class_name BattleTeam
## Base class for battle teams. Subclasses define how abilities are selected.

var characters: Array[BattleCharacter] = []
var battle_context: BattleContext

func _init(p_characters: Array[BattleCharacter], p_battle_context: BattleContext) -> void:
	characters = p_characters
	battle_context = p_battle_context

func is_any_alive() -> bool:
	for character in characters:
		if character.alive:
			return true
	return false

func get_alive_characters() -> Array[BattleCharacter]:
	return characters.filter(func(character): return character.alive)

## Awaitable coroutine function.
## For the player team, this should pause (with await) while the
## player is picking their abilities.
@abstract func pick_abilities() -> Array[QueuedAction];
