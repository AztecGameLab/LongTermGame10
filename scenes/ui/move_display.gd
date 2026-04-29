extends PanelContainer
class_name MoveDisplay

@export var move_name: RichTextLabel
@export var move_description: RichTextLabel

@export var select_indicator: NinePatchRect
@export var description_panel: Control

static func create(p_ability: BaseAbility, p_character: BattleCharacter) -> MoveDisplay:
	var display: MoveDisplay = load(&"uid://8dt21l5flyv3").instantiate()
	display.character = p_character
	display.ability = p_ability
	return display

var character: BattleCharacter

var ability: BaseAbility:
	set(value):
		ability = value
		update_text()

var selected: bool:
	set(value):
		selected = value
		select_indicator.visible = selected
		description_panel.visible = selected

func _ready() -> void:
	selected = false
	update_text()

func update_text():
	move_name.text = ability.get_label(character)
	move_description.text = ability.get_description(character)
