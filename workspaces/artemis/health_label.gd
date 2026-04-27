extends Label

@onready var parent: BattleCharacter = self.get_parent()

func _ready() -> void:
	text = str(parent.max_health)
	parent.health_updated.connect(_on_character_health_updated)

func _on_character_health_updated(new_health: int) -> void:
	var current_health: int = text.to_int()
	text = str(new_health)
	if new_health < current_health:
		var scene: PackedScene = load("res://scenes/ui/damage_display.tscn")
		var display: RichTextLabel = scene.instantiate()
		display.text = str(current_health - new_health)
		add_child(display)
