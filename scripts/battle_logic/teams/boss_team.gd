extends BattleTeam
class_name BossTeam
## Picks a random ability and random valid target with weights for each alive character.

func pick_abilities() -> Array[QueuedAction]:
	var actions: Array[QueuedAction] = []
	var allies := characters
	var enemies := battle_context.get_enemies(characters[0]).filter(func(c): return c.alive)
	for character in get_alive_characters():
		var ability: BaseAbility = character.abilities.pick_random()
		if not ability:
			continue
		var targets: Array[BattleCharacter] = []
		if ability.get_target_type(character) == BaseAbility.TargetType.ENEMY:
			targets = [pick_weighted_target(enemies)]
		else:
			targets = BattleManager.get_targets(character, allies, enemies, ability.get_target_type(character))
		if targets.size() == 0:
			continue
		var action := QueuedAction.new(battle_context, ability.get_action(character), character, targets, ability)
		actions.append(action)
	return actions

func pick_weighted_target(targets: Array[BattleCharacter]) -> BattleCharacter:
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
