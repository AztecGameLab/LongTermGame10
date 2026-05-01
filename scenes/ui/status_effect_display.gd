extends PanelContainer
class_name StatusEffectDisplay

@onready var texture_rect: TextureRect = $TextureRect
@onready var rich_text_label: RichTextLabel = $RichTextLabel

var container: StatusEffectContainer

func _ready() -> void:
	update_display()

func update_display():
	if container and rich_text_label and texture_rect:
		rich_text_label.text = str(container.get_remaining_turns()) if container.get_remaining_turns() > 0 else ""
		texture_rect.texture = container.get_icon()
