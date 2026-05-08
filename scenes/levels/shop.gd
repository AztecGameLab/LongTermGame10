extends TextureRect
class_name ShopController
## Shop scene logic. Attached to the root TextureRect of shop_N.tscn.
##
## Player picks 1 of 2 ability options for each of 3 characters.
## Carry-over: unpicked option carries to next shop alongside that shop's intro ability.
## Disabled options (Antidote — not built) are visible but unselectable.

@export_range(1, 3) var shop_number: int = 1
@export var next_scene: PackedScene
@onready var confirm_choice: AudioStreamPlayer = $confirm_choice

## The animation name on the AnimatedSprite2D to play after all picks.
@export var completion_animation: String = "1"

# --- Shop config ---
# For each shop, lists 2 options per character. "<carryover>" = ability not picked
# at previous shop (resolved at runtime via GameState).
const SHOP_OPTIONS := {
	1: {
		"fortune": [{"key": "reckless_slash"}, {"key": "deflect"}],
		"coralleine": [{"key": "lifesteal"}, {"key": "decoy"}],
		"umi": [{"key": "bottle_of_acid"}, {"key": "bottle_of_invisibility"}],
	},
	2: {
		"fortune": [{"key": "strengthen"}, {"key": "<carryover>"}],
		"coralleine": [{"key": "rally"}, {"key": "<carryover>"}],
		"umi": [{"key": "bottle_of_antidote"}, {"key": "<carryover>"}],
	},
	3: {
		"fortune": [{"key": "riposte"}, {"key": "<carryover>"}],
		"coralleine": [{"key": "guardian"}, {"key": "<carryover>"}],
		"umi": [{"key": "bottle_of_haste"}, {"key": "<carryover>"}],
	},
}

const CHARACTER_ORDER := ["coralleine", "fortune", "umi"]

# Runtime state
var char_options: Dictionary = {}  # char_id -> [{key, disabled, ability}, ...]
var char_slots: Dictionary = {}    # char_id -> [{texture, indicator}, {texture, indicator}]
var picks: Dictionary = {}         # char_id -> picked slot index (int)
var pick_order: Array[String] = []  # chronological order of picks for undo
var current_char_idx: int = 0
var current_slot_idx: int = 0
var locked_in: bool = false

# Scene refs (resolved in _ready)
var animated_sprite: AnimatedSprite2D
var move_name_label: RichTextLabel
var description_label: Label
var fade: Fade

func _ready() -> void:
	_resolve_scene_refs()
	# Auto-init starters if GameState empty (allows running shop scene directly).
	if not GameState.is_initialized():
		GameState.init_starters()
	_collect_slots()
	_resolve_options()
	_apply_disabled_overlays()
	current_char_idx = 0
	current_slot_idx = _first_enabled_slot(_char_id())
	_update_highlight()

func _apply_disabled_overlays() -> void:
	var gen_font: FontFile = load("res://assets/ui/GenFont_Mansalva-Regular.ttf")
	for char_id in CHARACTER_ORDER:
		var slots: Array = char_slots.get(char_id, [])
		for slot_idx in slots.size():
			var slot_data = char_options[char_id][slot_idx]
			if not slot_data["disabled"]:
				continue
			var texture: TextureRect = slots[slot_idx].get("texture")
			if texture == null:
				continue
			if texture.get_node_or_null(^"NotImplementedLabel"):
				continue
			var label := Label.new()
			label.name = "NotImplementedLabel"
			label.text = "Not Implemented"
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			if gen_font:
				label.add_theme_font_override("font", gen_font)
			label.add_theme_font_size_override("font_size", 36)
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
			label.add_theme_constant_override("outline_size", 6)
			texture.add_child(label)

func _resolve_scene_refs() -> void:
	animated_sprite = get_node_or_null(^"AnimatedSprite2D") as AnimatedSprite2D
	fade = get_node_or_null(^"Fade") as Fade
	# Move name + description live inside PanelContainer2 (bottom panel).
	# Built dynamically as a VBoxContainer with two RichTextLabels.
	var panel := get_node_or_null(^"PanelContainer2") as PanelContainer
	if panel:
		var margin := panel.get_node_or_null(^"InfoMargin") as MarginContainer
		if margin == null:
			margin = MarginContainer.new()
			margin.name = "InfoMargin"
			margin.add_theme_constant_override("margin_left", 30)
			margin.add_theme_constant_override("margin_top", 30)
			margin.add_theme_constant_override("margin_right", 30)
			margin.add_theme_constant_override("margin_bottom", 30)
			panel.add_child(margin)
		var vbox := margin.get_node_or_null(^"InfoVBox") as VBoxContainer
		if vbox == null:
			vbox = VBoxContainer.new()
			vbox.name = "InfoVBox"
			vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
			margin.add_child(vbox)
		var gen_font: FontFile = load("res://assets/ui/GenFont_Mansalva-Regular.ttf")
		move_name_label = vbox.get_node_or_null(^"MoveName") as RichTextLabel
		if move_name_label == null:
			move_name_label = RichTextLabel.new()
			move_name_label.name = "MoveName"
			move_name_label.fit_content = true
			move_name_label.bbcode_enabled = true
			if gen_font: move_name_label.add_theme_font_override("normal_font", gen_font)
			move_name_label.add_theme_font_size_override("normal_font_size", 42)
			move_name_label.add_theme_color_override("default_color", Color(0.30, 0.19, 0.09))
			vbox.add_child(move_name_label)
		description_label = vbox.get_node_or_null(^"Description") as Label
		if description_label == null:
			description_label = Label.new()
			description_label.name = "Description"
			description_label.set_script(load("res://scenes/ui/move_description.gd"))
			description_label.set("minimum_size", 14)
			description_label.set("maximum_size", 32)
			description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			description_label.clip_text = true
			if gen_font: description_label.add_theme_font_override("font", gen_font)
			description_label.add_theme_font_size_override("font_size", 32)
			description_label.add_theme_color_override("font_color", Color(0.30, 0.19, 0.09))
			description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
			vbox.add_child(description_label)

func _collect_slots() -> void:
	# Each character VBoxContainer has 2 PanelContainer children.
	# Inside each PanelContainer:
	#   TextureRect            (portrait)
	#   MarginContainer/SelectedAbilityIndicator  (selection outline)
	var hbox := self.get_node_or_null(^"PanelContainer/MarginContainer/HBoxContainer")
	if hbox == null:
		push_error("Shop: HBoxContainer not found at expected path")
		return
	for char_id in CHARACTER_ORDER:
		var char_node := hbox.get_node_or_null(NodePath(char_id.capitalize()))
		if char_node == null:
			continue
		var slots: Array = []
		for child in char_node.get_children():
			if child is PanelContainer:
				var texture: TextureRect = child.get_node_or_null(^"TextureRect") as TextureRect
				var indicator: Node = child.get_node_or_null(^"MarginContainer/SelectedAbilityIndicator")
				slots.append({"texture": texture, "indicator": indicator})
		char_slots[char_id] = slots

func _resolve_options() -> void:
	if not SHOP_OPTIONS.has(shop_number):
		push_error("Invalid shop_number: " + str(shop_number))
		return
	var shop_def: Dictionary = SHOP_OPTIONS[shop_number]
	var level: int = shop_number + 1  # next battle's level
	for char_id in CHARACTER_ORDER:
		var slots: Array = []
		for slot_def in shop_def[char_id]:
			var key: String = slot_def["key"]
			var disabled: bool = slot_def.get("disabled", false)
			if key == "<carryover>":
				key = GameState.get_carryover(char_id)
			var ability: BaseAbility = null
			if not key.is_empty():
				ability = GameState.resolve_ability(key, level)
			if ability == null:
				disabled = true
			slots.append({"key": key, "disabled": disabled, "ability": ability})
		char_options[char_id] = slots

func _char_id() -> String:
	return CHARACTER_ORDER[current_char_idx]

func _first_enabled_slot(char_id: String) -> int:
	for slot_idx in 2:
		if not char_options[char_id][slot_idx]["disabled"]:
			return slot_idx
	return 0

const CURSOR_COLOR := Color.WHITE
const LOCKED_COLOR := Color(0.35, 1.0, 0.45)  # green tint for confirmed pick

func _update_highlight() -> void:
	for char_id in CHARACTER_ORDER:
		var slots: Array = char_slots.get(char_id, [])
		for slot_idx in slots.size():
			var slot_visual = slots[slot_idx]
			var slot_data = char_options[char_id][slot_idx]
			var texture: TextureRect = slot_visual.get("texture")
			var indicator: Node = slot_visual.get("indicator")
			# Disabled portrait: dim and never highlighted.
			if slot_data["disabled"]:
				if texture: texture.modulate = Color(0.4, 0.4, 0.4, 0.6)
				_set_indicator(indicator, false, CURSOR_COLOR)
				continue
			# Already-picked character: locked outline on chosen slot, dim other.
			if picks.has(char_id):
				if picks[char_id] == slot_idx:
					if texture: texture.modulate = Color.WHITE
					_set_indicator(indicator, true, LOCKED_COLOR)
				else:
					if texture: texture.modulate = Color(0.35, 0.35, 0.35, 0.6)
					_set_indicator(indicator, false, CURSOR_COLOR)
				continue
			# Active selection cursor on current character + slot.
			if not locked_in and char_id == _char_id() and slot_idx == current_slot_idx:
				if texture: texture.modulate = Color.WHITE
				_set_indicator(indicator, true, CURSOR_COLOR)
			else:
				if texture: texture.modulate = Color.WHITE
				_set_indicator(indicator, false, CURSOR_COLOR)
	_update_description()

func _set_indicator(indicator: Node, value: bool, color: Color) -> void:
	if indicator == null:
		return
	if indicator is CanvasItem:
		var ci := indicator as CanvasItem
		ci.visible = value
		ci.modulate = color
	else:
		indicator.set("visible", value)

func _update_description() -> void:
	if move_name_label == null or description_label == null:
		return
	if locked_in:
		move_name_label.text = "Onward..."
		description_label.text = ""
		return
	var char_id := _char_id()
	var slot = char_options[char_id][current_slot_idx]
	var ability: BaseAbility = slot["ability"]
	if slot["disabled"] or ability == null:
		move_name_label.text = "Coming Soon"
		description_label.text = "This ability isn't available yet."
	else:
		move_name_label.text = ability.name
		description_label.text = ability.description

func _input(event: InputEvent) -> void:
	if locked_in:
		return
	if event.is_action_pressed(&"select_up") or event.is_action_pressed(&"select_down"):
		_toggle_slot()
	elif event.is_action_pressed(&"select_left"):
		_change_character(-1)
	elif event.is_action_pressed(&"select_right"):
		_change_character(1)
	elif event.is_action_pressed(&"select_confirm"):
		_confirm_pick()
	elif event.is_action_pressed(&"select_back"):
		_undo_pick()

func _toggle_slot() -> void:
	var char_id := _char_id()
	var other := 1 - current_slot_idx
	if char_options[char_id][other]["disabled"]:
		return
	current_slot_idx = other
	_update_highlight()

func _change_character(delta: int) -> void:
	var prev_slot := current_slot_idx
	for _i in CHARACTER_ORDER.size():
		current_char_idx = (current_char_idx + delta + CHARACTER_ORDER.size()) % CHARACTER_ORDER.size()
		if not picks.has(_char_id()):
			break
	# Preserve vertical position if that slot is enabled; otherwise fall back.
	if not char_options[_char_id()][prev_slot]["disabled"]:
		current_slot_idx = prev_slot
	else:
		current_slot_idx = _first_enabled_slot(_char_id())
	_update_highlight()

func _confirm_pick() -> void:
	var char_id := _char_id()
	var slot = char_options[char_id][current_slot_idx]
	if slot["disabled"]:
		return
	if not picks.has(char_id):
		pick_order.append(char_id)
	picks[char_id] = current_slot_idx
	if picks.size() == CHARACTER_ORDER.size():
		confirm_choice.play()
		_complete_shop()
		return
	# Advance to next unpicked character
	for _i in CHARACTER_ORDER.size():
		current_char_idx = (current_char_idx + 1) % CHARACTER_ORDER.size()
		if not picks.has(_char_id()):
			break
	current_slot_idx = _first_enabled_slot(_char_id())
	confirm_choice.play()
	_update_highlight()

func _undo_pick() -> void:
	if pick_order.is_empty():
		return
	var last_picked: String = pick_order.pop_back()
	# Restore cursor to the exact slot that had been picked.
	current_slot_idx = picks[last_picked]
	picks.erase(last_picked)
	current_char_idx = CHARACTER_ORDER.find(last_picked)
	_update_highlight()

func _complete_shop() -> void:
	locked_in = true
	for char_id in CHARACTER_ORDER:
		var picked_slot: int = picks[char_id]
		var picked = char_options[char_id][picked_slot]
		var unpicked = char_options[char_id][1 - picked_slot]
		GameState.add_ability(char_id, picked["key"])
		# Carry-over only if unpicked is a real ability
		if unpicked["disabled"] or unpicked["ability"] == null:
			GameState.set_carryover(char_id, "")
		else:
			GameState.set_carryover(char_id, unpicked["key"])
	GameState.shops_completed = shop_number
	_update_highlight()
	_play_completion_animation()

func _play_completion_animation() -> void:
	if animated_sprite:
		animated_sprite.play(completion_animation)
		await animated_sprite.animation_finished
	if fade:
		await fade.fadeout()
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
