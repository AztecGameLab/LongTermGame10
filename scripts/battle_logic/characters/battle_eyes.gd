extends BattleCharacter
class_name BattleEyes

@export var audio_player: AudioStreamPlayer

const COIL_UP = preload("uid://fbtwj6e3t3aa")
const COIL_UP_STATUS = preload("uid://dcrt047qu64c8")
const RECOVER = preload("uid://djie3akhwaspl")

const THE_EYES_ENDING = preload("uid://c34wbtc7yxi1m")

var audio_triggered: bool = false

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

func _ready() -> void:
	super._ready()
	health_updated.connect(_on_health_changed)

func _on_health_changed(_new_health: int):
	if not audio_triggered and current_health <= float(max_health) * .3:
		audio_player.stream = THE_EYES_ENDING
		audio_player.play(0.0)
		audio_triggered = true
