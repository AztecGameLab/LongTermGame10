extends BattleTeam
class_name PlayerTeam
## Awaits player input for ability and target selection.
## Characters can be selected in any order.

# --- Signals ---

## Emitted when the team is ready for ability selection.
## [br]The UI should display selection controls for the given characters.
signal selection_phase_started(characters: Array[BattleCharacter])

## Emitted when all characters have submitted their actions.
signal selection_phase_ended

# --- Runtime State ---

var _pending_actions: Array[QueuedAction] = []
var _remaining_characters: Array[BattleCharacter] = []
var _original_order: Array[BattleCharacter] = []

# --- Selection ---

## Awaits player input for all alive characters, then returns queued actions.
func pick_abilities() -> Array[QueuedAction]:
	_pending_actions = []
	_remaining_characters = get_alive_characters()
	_original_order = _remaining_characters.duplicate()
	selection_phase_started.emit(_remaining_characters.duplicate())
	await selection_phase_ended
	return _pending_actions

## Called by the UI when the player has chosen an ability and target for a character.
## [br]The action order matches the order the player submits.
func submit_action(p_character: BattleCharacter, p_ability: BaseAbility, p_targets: Array[BattleCharacter]) -> Array[BattleCharacter]:
	var action := QueuedAction.new(battle_context, p_ability.get_action(p_character), p_character, p_targets, p_ability)
	_pending_actions.append(action)
	_remaining_characters.erase(p_character)
	if _remaining_characters.is_empty():
		selection_phase_ended.emit()
	return _remaining_characters
	
func undo_last_pick() -> BattleCharacter:
	if _pending_actions.is_empty():
		return null
	var character: BattleCharacter = _pending_actions.pop_back().source
	var original_idx := _original_order.find(character)
	var insert_idx := _remaining_characters.size()
	for i in _remaining_characters.size():
		if _original_order.find(_remaining_characters[i]) > original_idx:
			insert_idx = i
			break
	_remaining_characters.insert(insert_idx, character)
	return character

# --- Target Helpers ---

## Returns valid targets for manual selection, filtered to alive characters.
func get_valid_targets(p_character: BattleCharacter, p_target_type: BaseAbility.TargetType) -> Array[BattleCharacter]:
	var allies := battle_context.get_allies(p_character)
	var enemies := battle_context.get_enemies(p_character)
	match p_target_type:
		BaseAbility.TargetType.ENEMY:
			return enemies.filter(func(enemy): return enemy.alive)
		BaseAbility.TargetType.TEAMMATE:
			return allies.filter(func(ally): return ally.alive)
		BaseAbility.TargetType.TEAMMATE_EXCLUDE_SELF:
			return allies.filter(func(ally): return ally.alive and ally != p_character)
		_:
			return []

## Returns auto-resolved targets for target types that don't need manual selection.
func get_auto_targets(p_character: BattleCharacter, p_ability: BaseAbility) -> Array[BattleCharacter]:
	return BattleManager.get_targets(
		p_character,
		battle_context.get_allies(p_character),
		battle_context.get_enemies(p_character),
		p_ability.get_target_type(p_character)
	)
