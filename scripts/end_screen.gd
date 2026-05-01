extends Node2D
## Generic full-screen end screen (win/lose). Shows an image, waits for confirm,
## fades, and loads the configured next scene.

@export var next_scene: PackedScene
@export var fade: Fade

var _advancing: bool = false
var _ready_for_input: bool = false

func _ready() -> void:
	# Block confirm until the entry fadein has finished, otherwise pressing
	# confirm too quickly starts a fadeout tween that fights the fadein.
	if fade:
		fade.finished.connect(_on_fade_finished)
	else:
		_ready_for_input = true

func _on_fade_finished() -> void:
	_ready_for_input = true

func _input(event: InputEvent) -> void:
	if _advancing or not _ready_for_input:
		return
	if event.is_action_pressed(&"select_confirm"):
		_advancing = true
		await _advance()

func _advance() -> void:
	if fade:
		await fade.fadeout()
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
