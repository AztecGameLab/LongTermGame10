extends Node2D

@onready var fade: Fade = $Fade

const level_1 := &"uid://cev3aj77jpniw"
const credits := &"uid://bh8ipn2dy8ivj"

@onready var credits_button: Button = $EyesBelowTitleScreen/PaperPanel/Button
@onready var start_button: Button = $EyesBelowTitleScreen/PaperPanel2/Button
@onready var more_games_button: Button = $EyesBelowTitleScreen/PaperPanel3/Button

func _on_start_pressed() -> void:
	# Reset progression state so each new game starts fresh.
	if has_node(^"/root/GameState"):
		get_node(^"/root/GameState").reset()
	await fade_to_scene(level_1)

func _on_quit_pressed() -> void:
	await fade_out()
	get_tree().quit()

func _on_credits_pressed() -> void:
	await fade_to_scene(credits)

func fade_to_scene(scene: String):
	await fade_out()
	get_tree().change_scene_to_file(scene)

func fade_out():
	credits_button.disabled = true
	start_button.disabled = true
	more_games_button.disabled = true
	await fade.fadeout()
