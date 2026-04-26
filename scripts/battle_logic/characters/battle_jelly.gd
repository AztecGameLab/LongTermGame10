extends BattleCharacter
class_name BattleJelly

func play_animation(animation: String) -> void:
	if animation == "attack":
		_animated_sprite.position.x += 220
		_animated_sprite.position.y -= 30
	await super.play_animation(animation)
	if animation == "attack":
		_animated_sprite.position.x -= 220
		_animated_sprite.position.y += 30
