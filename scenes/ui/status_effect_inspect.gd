extends CanvasLayer
class_name StatusEffectInspect

@export var battle_manager: BattleManager
@export var ability_select: CanvasLayer

@onready var _icon: TextureRect = $MarginContainer/PaperPanel/MarginContainer/VBoxContainer/Name/TextureRect
@onready var _name_label: Label = $MarginContainer/PaperPanel/MarginContainer/VBoxContainer/Name/NameLabel
@onready var _stacks_label: Label = $MarginContainer/PaperPanel/MarginContainer/VBoxContainer/Name/MarginContainer/VBoxContainer/StacksLabel
@onready var _description_label: Label = $MarginContainer/PaperPanel/MarginContainer/VBoxContainer/Description/MarginContainer/DescriptionLabel

var _inspecting: bool = false
var _entries: Array[Dictionary] = []
var _focus_index: int = 0
var _characters: Array[BattleCharacter] = []

func _ready() -> void:
	visible = false
	if battle_manager:
		battle_manager.battle_ready.connect(_setup)

func _setup() -> void:
	var all: Array[BattleCharacter] = []
	all.append_array(battle_manager._player_battle_team.characters)
	all.append_array(battle_manager.boss_team)
	all.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	_characters = all

	for character in _characters:
		character.status_effects_updated.connect(_on_status_effects_updated)

	_clear_indicators()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"select_inspect"):
		if _inspecting:
			_exit()
		elif _can_enter():
			_enter()
		get_viewport().set_input_as_handled()
		return

	if not _inspecting:
		return

	if event.is_action_pressed(&"select_back"):
		_exit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"select_left"):
		_move_focus(-1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"select_right"):
		_move_focus(1)
		get_viewport().set_input_as_handled()

func _can_enter() -> bool:
	if not ability_select:
		return false
	return ability_select.margin_container.visible and not ability_select.selecting_target

func _enter() -> void:
	_inspecting = true
	if ability_select:
		ability_select.margin_container.visible = false
		ability_select.set_process_input(false)
		if ability_select.selected_character:
			ability_select.selected_character.selected = false
	visible = true
	_build_entries()
	_focus_index = 0
	_refresh_focus()

func _exit() -> void:
	_inspecting = false
	visible = false
	_clear_indicators()
	if ability_select:
		ability_select.margin_container.visible = true
		ability_select.set_process_input(true)
		if ability_select.selected_character:
			ability_select.selected_character.selected = true

func _build_entries() -> void:
	_entries.clear()
	for character in _characters:
		if not character.alive:
			continue
		for container in character.get_all_status_effects():
			if container.get_icon():
				_entries.append({"character": character, "container": container})

func _move_focus(delta: int) -> void:
	if _entries.is_empty():
		return
	_focus_index = (_focus_index + delta) % _entries.size()
	if _focus_index < 0:
		_focus_index += _entries.size()
	_refresh_focus()

func _refresh_focus() -> void:
	_clear_indicators()
	if _entries.is_empty():
		_show_empty()
		return

	var entry := _entries[_focus_index]
	var character: BattleCharacter = entry["character"]
	var container: StatusEffectContainer = entry["container"]

	var display := _find_display(character, container)
	if display:
		var indicator: Node = display.get_node_or_null("MarginContainer/SelectedStatusIndicator")
		if indicator:
			indicator.visible = true

	_icon.texture = container.get_icon()
	_name_label.text = container.effect.get_effect_name(container)
	_description_label.text = container.effect.get_effect_description(container)
	var turns := container.get_remaining_turns()
	if turns > 0:
		_stacks_label.text = "%s: %d" % [container.effect.get_remaining_label(container), turns]
		_stacks_label.visible = true
	else:
		_stacks_label.visible = false

func _show_empty() -> void:
	_icon.texture = null
	_name_label.text = "No status effects"
	_description_label.text = "There are no active status effects to inspect."
	_stacks_label.visible = false

func _clear_indicators() -> void:
	for character in _characters:
		var bar := character.get_node_or_null("HealthBar")
		if not bar:
			continue
		for child in bar.status_effect_container.get_children():
			if child is StatusEffectDisplay:
				var indicator: Node = child.get_node_or_null("MarginContainer/SelectedStatusIndicator")
				if indicator:
					indicator.visible = false

func _find_display(character: BattleCharacter, container: StatusEffectContainer) -> StatusEffectDisplay:
	var bar := character.get_node_or_null("HealthBar")
	if not bar:
		return null
	for child in bar.status_effect_container.get_children():
		if child is StatusEffectDisplay and child.container == container and not child.is_queued_for_deletion():
			return child
	return null

func _on_status_effects_updated() -> void:
	if not _inspecting:
		return

	var prev_container: StatusEffectContainer = null
	if _focus_index < _entries.size():
		prev_container = _entries[_focus_index]["container"]

	_build_entries()

	if _entries.is_empty():
		_refresh_focus()
		return

	if prev_container:
		for i in _entries.size():
			if _entries[i]["container"] == prev_container:
				_focus_index = i
				_refresh_focus()
				return

	_focus_index = mini(_focus_index, _entries.size() - 1)
	_refresh_focus()
