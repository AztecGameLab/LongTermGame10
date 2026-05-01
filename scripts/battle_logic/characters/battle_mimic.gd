extends BattleCharacter
class_name BattleMimic

@onready var ink_spray: AnimatedSprite2D = $InkSpray

func spray_ink():
	ink_spray.play()
	await ink_spray.animation_finished

func play_animation(animation: String) -> void:
	if animation == &"status":
		await spray_ink()
	else:
		await super.play_animation(animation)
