extends CanvasLayer

const MOVE_DISPLAY = preload("uid://8dt21l5flyv3")

@onready var character_name: RichTextLabel = %Name
@onready var margin_container: MarginContainer = %MarginContainer
@onready var move_container: VBoxContainer = %MoveContainer
@onready var confirm_choice: AudioStreamPlayer = $confirm_choice
@onready var select_move: AudioStreamPlayer = $select_move

@export var battle_manager: BattleManager
var player_team: PlayerTeam

var original_order: Array[BattleCharacter] = []
var selectable_characters: Array[BattleCharacter] = []
var character_index: int = 0
var selected_character: BattleCharacter:
	get():
		if selectable_characters.size() <= 0:
			return null
		return selectable_characters[character_index]


var selectable_targets: Array[Array] = []
var target_index: int = 0
var selected_targets: Array[BattleCharacter]:
	get():
		if selectable_targets.size() <= 0:
			return []
		var targets: Array[BattleCharacter] = []
		targets.assign(selectable_targets[target_index])
		return targets

var moves: Array[MoveDisplay] = []
var move_index: int = 0
var selected_move: MoveDisplay:
	get():
		if moves.size() <= 0:
			return null
		return moves[move_index]

var selecting_target: bool = false:
	set(value):
		selecting_target = value
		margin_container.modulate = Color.DIM_GRAY if selecting_target else Color.WHITE

func _ready() -> void:
	battle_manager.battle_ready.connect(_setup_battle)

func _setup_battle() -> void:
	player_team = battle_manager._player_battle_team
	player_team.selection_phase_started.connect(_on_selection_phase_started)
	player_team.selection_phase_ended.connect(_on_selection_phase_ended)

func _on_selection_phase_started(characters: Array[BattleCharacter]):
	margin_container.visible = true
	original_order = characters.duplicate()
	load_characters(characters)
	select_character_for_abilities()
	
func _on_selection_phase_ended():
	margin_container.visible = false
	
func _input(event: InputEvent) -> void:
	if selectable_characters.size() <= 0:
		return
	if event.is_action_pressed(&"select_left"):
		if not selecting_target:
			selected_character.selected = false
			character_index += 1
			if character_index >= selectable_characters.size():
				character_index = 0
			select_character_for_abilities()
		else:
			for target in selected_targets:
				target.selected = false
			target_index += 1
			if target_index >= selectable_targets.size():
				target_index = 0
			for target in selected_targets:
				target.selected = true
	
	if event.is_action_pressed(&"select_right"):
		if not selecting_target:
			selected_character.selected = false
			character_index -= 1
			if character_index < 0:
				character_index = selectable_characters.size() - 1
			select_character_for_abilities()
		else:
			for target in selected_targets:
				target.selected = false
			target_index -= 1
			if target_index < 0:
				target_index = selectable_targets.size() - 1
			for target in selected_targets:
				target.selected = true
	
	if event.is_action_pressed(&"select_up"):
		if not selecting_target:
			selected_move.selected = false
			move_index -= 1
			if move_index < 0:
				move_index = moves.size() - 1
			selected_move.selected = true
		else:
			stop_selecting_targets()
		
	if event.is_action_pressed(&"select_down"):
		if not selecting_target:
			selected_move.selected = false
			move_index += 1
			if move_index >= moves.size():
				move_index = 0
			selected_move.selected = true
		else:
			stop_selecting_targets()

	if event.is_action_pressed(&"select_confirm"):
		if not selecting_target:
			select_move.play()
			start_selecting_targets()
		else:
			confirm_choice.play()
			var remaining_characters := player_team.submit_action(selected_character, selected_move.ability, selected_targets)
			load_characters(remaining_characters)
			stop_selecting_targets()
			
	if event.is_action_pressed(&"select_back"):
		if not selecting_target:
			var character := player_team.undo_last_pick()
			if character == null:
				return
			if selected_character:
				selected_character.selected = false
			var original_idx := original_order.find(character)
			var insert_idx := selectable_characters.size()
			for i in selectable_characters.size():
				if original_order.find(selectable_characters[i]) > original_idx:
					insert_idx = i
					break
			selectable_characters.insert(insert_idx, character)
			character_index = insert_idx
			select_character_for_abilities()
		else:
			stop_selecting_targets()
			

func _load_abilities(character: BattleCharacter):
	for move in moves:
		move.queue_free()
	moves = []
	
	for ability in character.abilities:
		var move_display := MoveDisplay.create(ability, character)
		moves.append(move_display)
		move_container.add_child(move_display)
	
	if move_index >= moves.size():
		move_index = 0
	selected_move.selected = true
	
func load_characters(characters: Array[BattleCharacter]):
	selectable_characters = characters.duplicate()
	character_index = 0

func select_character_for_abilities():
	if not selected_character:
		return
	selected_character.selected = true
	character_name.text = selected_character.character_name
	_load_abilities(selected_character)

func start_selecting_targets():
	selected_character.selected = false
	match selected_move.ability.get_target_type(selected_character):
		BaseAbility.TargetType.SELF:
			selectable_targets = [[selected_character]]
		BaseAbility.TargetType.ATTACKER:
			var targets: Array[BattleCharacter] = []
			if selected_character.last_attacker:
				targets.append(selected_character.last_attacker)
			selectable_targets = [targets]
		BaseAbility.TargetType.EVERYONE:
			var targets: Array[BattleCharacter] = player_team.characters.duplicate()
			targets.append_array(battle_manager.boss_team)
			selectable_targets = [targets]
		BaseAbility.TargetType.TEAMMATE:
			var target_groups: Array[Array] = []
			for character in player_team.characters:
				target_groups.append([character])
			selectable_targets = target_groups
		BaseAbility.TargetType.TEAMMATE_EXCLUDE_SELF:
			var target_groups: Array[Array] = []
			for character in player_team.characters.duplicate().filter(func(c): return c != selected_character):
				target_groups.append([character])
			selectable_targets = target_groups
		BaseAbility.TargetType.ALL_TEAMMATES:
			var targets: Array[BattleCharacter] = player_team.characters.duplicate()
			selectable_targets = [targets]
		BaseAbility.TargetType.ALL_TEAMMATES_EXCLUDE_SELF:
			var targets: Array[BattleCharacter] = player_team.characters.duplicate().filter(func(c): return c != selected_character)
			selectable_targets = [targets]
		BaseAbility.TargetType.ENEMY:
			var target_groups: Array[Array] = []
			for character in battle_manager.boss_team:
				target_groups.append([character])
			selectable_targets = target_groups
		BaseAbility.TargetType.ALL_ENEMIES:
			var targets: Array[BattleCharacter] = battle_manager.boss_team.duplicate()
			selectable_targets = [targets]
		_:
			push_error("A target type was used that is not covered by the Ability Picker!")
	
	selectable_targets.assign(selectable_targets.map(func(a): return a.filter(func(c): return c.alive)).filter(func(a): return not a.is_empty()))
	
	target_index = 0
	selecting_target = true
	for target in selected_targets:
		target.selected = true

func stop_selecting_targets():
	for target in selected_targets:
		target.selected = false
	select_character_for_abilities()
	selecting_target = false
