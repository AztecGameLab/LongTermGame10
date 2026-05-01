extends Node
class_name FadeControl

@onready var parent: Fade = get_parent()

@export var music_after_fade := true
@export_range(-80.0, 0.0, 0.5) var music_in_db := 0.0

func _enter_tree() -> void:
	# Force the parent Fade visible and fully opaque BEFORE the first frame
	# renders. Doing this in _ready can be too late: scenes that override
	# `visible = false` on the Fade instance briefly show un-faded content
	# for one frame between scene load and the first fadein tween update.
	# Only scenes with a FadeControl child get this treatment, so scenes that
	# intentionally skip fade-in (e.g., main_menu) are unaffected.
	var fade_node: Fade = get_parent()
	if fade_node:
		fade_node.visible = true
		var rect := fade_node.get_node_or_null(^"ColorRect") as ColorRect
		if rect:
			rect.color.a = 1.0

func _ready() -> void:
	call_deferred("start")

func start():
	await parent.fadein(!music_after_fade, music_in_db)
	if music_after_fade and parent.audio:
		parent.audio.play()
