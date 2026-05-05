extends CanvasLayer

@onready var settings_button: TextureButton = $VBoxContainer/SettingsButton

@onready var music: HBoxContainer = $VBoxContainer/Music
@onready var music_slider: HSlider = music.get_node("HSlider")

@onready var sfx: HBoxContainer = $VBoxContainer/SFX
@onready var sfx_slider: HSlider = sfx.get_node("HSlider")
@onready var sfx_preview_timer: Timer = sfx.get_node("HSlider/Timer")
@onready var sfx_preview_player: AudioStreamPlayer = sfx.get_node("AudioStreamPlayer")

@onready var music_bus := AudioServer.get_bus_index("Music")
@onready var sfx_bus := AudioServer.get_bus_index("SFX")

var is_showing := false

func _ready() -> void:
	settings_button.pressed.connect(_on_press_button)
	
	music_slider.set_value_no_signal(AudioServer.get_bus_volume_linear(music_bus))
	music_slider.value_changed.connect(_on_music_slider_changed)
	
	sfx_slider.set_value_no_signal(AudioServer.get_bus_volume_linear(sfx_bus))
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	sfx_preview_timer.timeout.connect(sfx_preview_player.play)

func _on_press_button() -> void:
	is_showing = !is_showing
	#settings_button.disabled = true
	music.visible = is_showing
	sfx.visible = is_showing
	#var tween := create_tween()
	#tween.tween_property(settings_button, "rotation_degrees", 0 if settings_button.rotation_degrees == 90 else 90, 0.5)
	#await tween.finished
	#settings_button.disabled = false

func _on_music_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(music_bus, value)
	
func _on_sfx_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(sfx_bus, value)
	sfx_preview_timer.start()
