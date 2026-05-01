extends BattleCharacter
class_name BattleEyes

const COIL_UP = preload("uid://fbtwj6e3t3aa")
const COIL_UP_STATUS = preload("uid://dcrt047qu64c8")
const RECOVER = preload("uid://djie3akhwaspl")

func pick_ability(_battle_context: BattleContext) -> BaseAbility:
	var choices: Array[BaseAbility] = []
	for ability in abilities:
		if ability == COIL_UP and has_status_effect(COIL_UP_STATUS):
			continue
		if ability == RECOVER and current_health > max_health * 0.7:
			continue
		choices.append(ability)
	if choices.is_empty():
		return abilities.pick_random()
	return choices.pick_random()
