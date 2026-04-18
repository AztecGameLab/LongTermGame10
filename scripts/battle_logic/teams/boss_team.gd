extends BattleTeam
class_name BossTeam
## Picks a random ability and random valid target for each alive character.

func pick_abilities() -> Array[QueuedAction]:
	var actions: Array[QueuedAction] = []
	var allies := characters
	var enemies := battle_context.get_enemies(characters[0])
	for character in get_alive_characters():
		var ability: BaseAbility = character.abilities.pick_random()
		if not ability:
			print(character.name + " has no abilities and will do nothing.")
			continue
		var targets := BattleManager.get_targets(character, allies, enemies, ability.get_target_type(character))
		if targets.size() == 0:
			print(character.name + " has no valid targets and will do nothing.")
			continue
		var action := QueuedAction.new(battle_context, ability.get_action(character), character, targets, ability)
		actions.append(action)
	return actions
