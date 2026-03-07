extends Label

func _ready() -> void:
	text = str(500)

func _on_damaged(_amount: int, context: AttackContext) -> void:
	text = str(context.target.current_health)


func _on_healed(amount: int, source: Character) -> void:
	text = str(source.current_health)
