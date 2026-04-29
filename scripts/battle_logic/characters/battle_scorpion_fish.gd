extends BattleCharacter
class_name BattleScorpionFish

const OBSESSION = preload("uid://crrdd0sksf7sc")
const OBSESSION_STATUS = preload("uid://dxc0t8yyfcofy")

const RAGE = preload("uid://8b7mh30psvls")
const RAGE_EFFECT = preload("uid://dv6tt3p3oh6bg")

func pick_ability(battle_context: BattleContext) -> BaseAbility:
	var choices: Array[BaseAbility] = []
	for ability in abilities:
		if ability == OBSESSION and battle_context.get_enemies(self).any(func(c): return c.get_status_effect(OBSESSION_STATUS)):
			continue;
		if ability == RAGE and get_status_effect(RAGE_EFFECT):
			continue;
		choices.append(ability)
	return choices.pick_random()
