extends BattleCharacter
class_name BattleMimic

@onready var ink_spray: AnimatedSprite2D = $InkSpray

func spray_ink():
	ink_spray.play()
	await ink_spray.animation_finished
