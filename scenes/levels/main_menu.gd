extends Node2D

const level_1 := &"uid://cev3aj77jpniw"
const credits := &"uid://bh8ipn2dy8ivj"

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(level_1)

func _on_games_pressed() -> void:
	OS.shell_open("https://aztec-game-lab.itch.io/")

func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(credits)
