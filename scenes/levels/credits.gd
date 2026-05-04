extends Node2D

@export var next_scene: PackedScene
@export var fade: Fade

var _advancing: bool = false
var _ready_for_input: bool = false

func _ready() -> void:
	if fade:
		fade.finished.connect(_on_fade_finished)
	else:
		_ready_for_input = true
	var anim := get_node_or_null(^"AnimationPlayer") as AnimationPlayer
	anim.animation_finished.connect(_on_anim_finished)
	anim.play(&"play")

func _on_fade_finished() -> void:
	_ready_for_input = true

func _input(event: InputEvent) -> void:
	if _advancing or not _ready_for_input:
		return
	if event.is_action_pressed(&"select_confirm") or event.is_action_pressed(&"select_back"):
		_advance()

func _on_anim_finished(_anim_name: StringName) -> void:
	_advance()

func _advance() -> void:
	if _advancing:
		return
	_advancing = true
	if fade:
		await fade.fadeout()
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
