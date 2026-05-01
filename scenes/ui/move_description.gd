# grabbed from here: https://forum.godotengine.org/t/is-there-auto-font-size-like-in-unity/41243
extends Label

## Smallest possible font size text can be in the label.
@export var minimum_size := 10

## Largest possible font size text can be in the label, also default font size when there is not much text.
@export var maximum_size := 32


func _set(property, value):
	if property == "text" and text != value:
		text = value
		add_theme_font_size_override("font_size", maximum_size)
		call_deferred("update_font_size")
		return true
	
	return false


func update_font_size():
	var font_size = get_theme_font_size("font_size")
	
	while get_visible_line_count() < get_line_count() and font_size >= minimum_size:
		font_size -= 1
		add_theme_font_size_override("font_size", font_size)
		
		await get_tree().process_frame
