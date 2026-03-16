extends Label

@onready var parent: Character = self.get_parent()

func _ready() -> void:
	text = str(parent.max_health)
	parent.health_updated.connect(_on_character_health_updated)

func _on_character_health_updated(new_health: int) -> void:
	text = str(new_health)
