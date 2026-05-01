extends BattleCharacter
class_name BattleJelly

const SELF_HEAL = preload("uid://druy3hvlfbkur")

func pick_ability(_battle_context: BattleContext) -> BaseAbility:
	var choices: Array[BaseAbility] = []
	for ability in abilities:
		if ability == SELF_HEAL and current_health > max_health * 0.5:
			continue
		choices.append(ability)
	if choices.is_empty():
		return abilities.pick_random()
	return choices.pick_random()

func play_animation(animation: String) -> void:
	if animation == "attack":
		_animated_sprite.position.x += 220
		_animated_sprite.position.y -= 30
	await super.play_animation(animation)
	if animation == "attack":
		_animated_sprite.position.x -= 220
		_animated_sprite.position.y += 30
