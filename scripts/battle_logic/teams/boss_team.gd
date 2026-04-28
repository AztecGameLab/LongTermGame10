extends BattleTeam
class_name BossTeam
## Picks a random ability and random valid target with weights for each alive character.

func pick_abilities() -> Array[QueuedAction]:
	var actions: Array[QueuedAction] = []
	var allies := characters
	var enemies := battle_context.get_enemies(characters[0]).filter(func(c): return c.alive)
	for character in get_alive_characters():
		var ability: BaseAbility = character.pick_ability(battle_context) if character.has_method(&"pick_ability") else character.abilities.pick_random()
		if not ability:
			continue
			
		var targets := BattleManager.get_targets(character, allies, enemies, ability.get_target_type(character))
		if targets.size() == 0:
			continue
		
		var action := QueuedAction.new(battle_context, ability.get_action(character), character, targets, ability)
		actions.append(action)
	return actions
