extends Node2D
## Credits scene. Auto-returns to next_scene after display_duration (or when
## the optional AnimationPlayer "scroll" animation finishes, if present).
## Player can press confirm to skip early.

@export var next_scene: PackedScene
@export var fade: Fade
## Fallback duration (seconds) if no AnimationPlayer is present.
@export var display_duration: float = 30.0

var _advancing: bool = false
var _ready_for_input: bool = false

func _ready() -> void:
	if fade:
		fade.finished.connect(_on_fade_finished)
	else:
		_ready_for_input = true
	var anim := get_node_or_null(^"AnimationPlayer") as AnimationPlayer
	if anim and anim.has_animation(&"scroll"):
		anim.animation_finished.connect(_on_anim_finished)
		anim.play(&"scroll")
	else:
		var timer := Timer.new()
		timer.wait_time = display_duration
		timer.one_shot = true
		timer.timeout.connect(_advance)
		add_child(timer)
		timer.start()

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
