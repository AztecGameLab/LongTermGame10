@tool
class_name AbilityGraphNodeFactory
extends RefCounted

## Builds GraphNodes by introspecting a Resource's property list — no manual
## definitions needed. Resource-typed properties become output ports, arrays of
## resources become dynamic output ports, everything else becomes inline controls.

const PortTypes := preload("res://addons/ability_editor/editor/port_types.gd")
const PT := PortTypes.PortType
const Registry := preload("res://addons/ability_editor/editor/node_type_registry.gd")


## Creates a GraphNode by introspecting the given resource.
## Set is_root to suppress the input port (root nodes have nothing connecting to them).
static func create_node(resource: Resource, is_external: bool = false, is_root: bool = false) -> GraphNode:
	var class_key := Registry.get_class_key_for_resource(resource)
	var type_info := Registry.get_type_info(class_key)
	var display_name: String = type_info.get("display_name", class_key)

	var node := GraphNode.new()
	node.set_meta("class_key", class_key)
	node.set_meta("resource", resource)
	node.resizable = true
	node.custom_minimum_size = Vector2(220, 0)
	node.add_theme_constant_override("separation", 4)

	if is_external:
		node.set_meta("is_external", true)
		var filename := resource.resource_path.get_file() if resource else ""
		node.title = "%s  [%s]" % [display_name, filename]
		_build_external_node(node, resource)
	else:
		node.title = display_name
		_build_inline_node(node, resource, is_root)

	_apply_node_color(node, resource)
	return node


# ── External node (read-only, just input port + open button) ──

static func _build_external_node(node: GraphNode, resource: Resource) -> void:
	var input_pt := Registry.get_input_port_type_for_resource(resource)
	var has_input := input_pt >= 0

	var btn := Button.new()
	btn.text = "Open in Graph"
	btn.custom_minimum_size.y = 26
	if resource:
		btn.set_meta("open_external_path", resource.resource_path)
	node.add_child(btn)

	if has_input:
		node.set_slot(0, true, input_pt, PortTypes.get_color(input_pt), false, 0, Color.WHITE)
	else:
		node.set_slot(0, false, 0, Color.WHITE, false, 0, Color.WHITE)


# ── Inline node (full introspection) ──

static func _build_inline_node(node: GraphNode, resource: Resource, is_root: bool = false) -> void:
	var input_pt := Registry.get_input_port_type_for_resource(resource)
	var has_input := input_pt >= 0 and not is_root
	var doc := _parse_all_doc_comments(resource.get_script())

	# ── Pass 1: classify properties ──
	var inlines := []    # [{prop, group, tooltip}]
	var outputs := []    # [{name, port_type, tooltip}]
	var dynamics := []   # [{name, port_type, label_prefix, tooltip}]
	var current_group := ""

	for prop in resource.get_property_list():
		var prop_type := int(prop.get("type", 0))
		var prop_usage := int(prop.get("usage", 0))
		var prop_name: String = str(prop.get("name", ""))
		var prop_hint := int(prop.get("hint", 0))
		var prop_hint_string: String = str(prop.get("hint_string", ""))

		# Group/category header
		if prop_type == TYPE_NIL:
			if prop_usage & PROPERTY_USAGE_GROUP:
				current_group = prop_name
			elif prop_usage & PROPERTY_USAGE_CATEGORY:
				# New class boundary (e.g., parent class properties start) — reset group
				current_group = ""
			continue

		# Only editor-visible properties, skip Resource built-ins
		if not Registry.should_show_property(prop):
			continue

		var tooltip: String = doc.get(prop_name, "")

		# Resource reference → output port
		if Registry.is_port_resource(prop):
			outputs.append({"name": prop_name, "port_type": Registry.get_port_type_for_hint(prop_hint_string), "tooltip": tooltip})
			continue

		# Array of resources → dynamic ports
		if Registry.is_port_array(prop):
			var cls := Registry.parse_array_element_class(prop_hint_string)
			var pt := Registry.get_port_type_for_hint(cls)
			dynamics.append({"name": prop_name, "port_type": pt, "label_prefix": Registry.label_from_class(cls), "tooltip": tooltip})
			continue

		# Skip non-port resource properties
		if prop_type == TYPE_OBJECT:
			continue

		# Inline control
		inlines.append({"prop": prop, "group": current_group, "tooltip": tooltip})

	# ── Pass 1b: separate inlines into regular vs toggle-group members ──
	# Toggle groups go at the bottom so hidden rows don't break port cache.
	var regular_inlines := []
	var toggle_inlines := []  # [{prop, group, tooltip, is_controller}]
	var group_first_bool := {}  # group_name -> toggle_prop_name

	# First pass: identify which groups have a bool controller
	for info in inlines:
		var prop: Dictionary = info["prop"]
		var group: String = info["group"]
		if not group.is_empty() and int(prop.get("type", 0)) == TYPE_BOOL and not group_first_bool.has(group):
			group_first_bool[group] = str(prop.get("name", ""))

	# Second pass: split into regular vs toggle
	for info in inlines:
		var group: String = info["group"]
		if not group.is_empty() and group_first_bool.has(group):
			toggle_inlines.append(info)
		else:
			regular_inlines.append(info)

	# Hoist 'name' and 'description' to the top (in that order)
	var hoisted := []
	var rest := []
	for info in regular_inlines:
		var pn: String = str(info["prop"].get("name", ""))
		if pn == "name" or pn == "description":
			hoisted.append(info)
		else:
			rest.append(info)
	# Ensure name comes before description
	hoisted.sort_custom(func(a, b):
		return str(a["prop"].get("name", "")) == "name"
	)
	regular_inlines = hoisted + rest

	# Hoist 'icon' output port to the top so it appears right after name/description
	var hoisted_outputs := []
	var rest_outputs := []
	for out in outputs:
		if out["name"] == "icon":
			hoisted_outputs.append(out)
		else:
			rest_outputs.append(out)
	outputs = hoisted_outputs + rest_outputs

	# ── Pass 2: build the node ──
	# Order: regular inlines → output ports → dynamic ports → toggle groups
	# This ensures hidden toggle rows are always at the bottom and can't break port positions.
	var slot := 0
	var toggle_controls := {}   # toggle_prop_name -> Array[Control]

	# Regular inline controls
	for info in regular_inlines:
		var hbox := _create_property_control(info["prop"], resource, info["tooltip"])
		node.add_child(hbox)
		_set_slot_input(node, slot, has_input and slot == 0, input_pt)
		slot += 1

	# Static output ports
	for out in outputs:
		var label := _create_port_label(out["name"], out["tooltip"])
		label.set_meta("output_property", out["name"])
		node.add_child(label)

		var left := has_input and slot == 0
		var pt: int = out["port_type"]
		node.set_slot(slot,
			left, input_pt if left else 0, PortTypes.get_color(input_pt) if left else Color.WHITE,
			true, pt, PortTypes.get_color(pt))
		slot += 1

	# Dynamic port sections
	for dyn in dynamics:
		var before_count := node.get_child_count()
		_add_dynamic_port_section(node, dyn, resource)
		var added := node.get_child_count() - before_count
		for i in added:
			var child_idx := before_count + i
			var child := node.get_child(child_idx)
			var is_port_row: bool = child.has_meta("dynamic_index")
			var pt: int = dyn["port_type"]
			var left := has_input and slot == 0
			node.set_slot(slot,
				left, input_pt if left else 0, PortTypes.get_color(input_pt) if left else Color.WHITE,
				is_port_row, pt if is_port_row else 0, PortTypes.get_color(pt) if is_port_row else Color.WHITE)
			slot += 1

	# Toggle group rows (at the bottom — hidden rows won't affect port positions)
	for info in toggle_inlines:
		var prop: Dictionary = info["prop"]
		var prop_name: String = str(prop.get("name", ""))
		var group: String = info["group"]
		var hbox := _create_property_control(prop, resource, info["tooltip"])
		node.add_child(hbox)

		if group_first_bool.get(group, "") == prop_name:
			pass  # This is the toggle controller — always visible
		else:
			# This is a dependent — track for toggle wiring
			var toggle_name: String = group_first_bool[group]
			if not toggle_controls.has(toggle_name):
				toggle_controls[toggle_name] = []
			toggle_controls[toggle_name].append(hbox)

		_set_slot_input(node, slot, has_input and slot == 0, input_pt)
		slot += 1

	# If no slots were created but we need an input port
	if slot == 0 and has_input:
		var spacer := Control.new()
		spacer.custom_minimum_size.y = 10
		node.add_child(spacer)
		node.set_slot(0, true, input_pt, PortTypes.get_color(input_pt), false, 0, Color.WHITE)

	# Wire toggle visibility
	_wire_toggles(node, resource, toggle_controls)


static func _set_slot_input(node: GraphNode, slot: int, has_input: bool, input_pt: int) -> void:
	node.set_slot(slot,
		has_input, input_pt if has_input else 0,
		PortTypes.get_color(input_pt) if has_input else Color.WHITE,
		false, 0, Color.WHITE)


# ── Property controls (auto-generated from property hints) ──

static func _create_property_control(prop: Dictionary, resource: Resource, tooltip: String) -> HBoxContainer:
	var prop_name: String = str(prop.get("name", ""))
	var prop_type := int(prop.get("type", 0))
	var prop_hint := int(prop.get("hint", 0))
	var prop_hint_string: String = str(prop.get("hint_string", ""))

	var clean_tooltip := _strip_bbcode(tooltip) if not tooltip.is_empty() else ""

	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size.y = 26
	hbox.set_meta("prop_name", prop_name)
	if not clean_tooltip.is_empty():
		hbox.tooltip_text = clean_tooltip

	var label := Label.new()
	label.text = prop_name.capitalize()
	label.custom_minimum_size.x = 80
	if not clean_tooltip.is_empty():
		label.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.add_child(label)

	var control: Control
	match prop_type:
		TYPE_INT:
			if prop_hint == PROPERTY_HINT_ENUM:
				control = _create_enum_control(prop, resource)
			else:
				var spin := SpinBox.new()
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				spin.rounded = true
				if prop_hint == PROPERTY_HINT_RANGE and not prop_hint_string.is_empty():
					_apply_range_hint(spin, prop_hint_string)
				else:
					spin.min_value = -99999
					spin.max_value = 99999
					spin.step = 1
				if prop_name in resource:
					spin.value = resource.get(prop_name)
				spin.value_changed.connect(func(val: float): _on_value_changed(hbox, prop_name, int(val)))
				control = spin
		TYPE_FLOAT:
			var spin := SpinBox.new()
			spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if prop_hint == PROPERTY_HINT_RANGE and not prop_hint_string.is_empty():
				_apply_range_hint(spin, prop_hint_string)
			else:
				spin.min_value = -999.0
				spin.max_value = 999.0
				spin.step = 0.01
			if prop_name in resource:
				spin.value = resource.get(prop_name)
			spin.value_changed.connect(func(val: float): _on_value_changed(hbox, prop_name, val))
			control = spin
		TYPE_BOOL:
			var check := CheckBox.new()
			check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if prop_name in resource:
				check.button_pressed = resource.get(prop_name)
			check.set_meta("prop_name", prop_name)
			check.toggled.connect(func(val: bool): _on_value_changed(hbox, prop_name, val))
			control = check
		TYPE_STRING:
			if prop_hint == PROPERTY_HINT_MULTILINE_TEXT:
				var text_edit := TextEdit.new()
				text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				text_edit.custom_minimum_size = Vector2(120, 60)
				text_edit.scroll_fit_content_height = true
				if prop_name in resource:
					text_edit.text = str(resource.get(prop_name))
				text_edit.text_changed.connect(func(): _on_value_changed(hbox, prop_name, text_edit.text))
				hbox.custom_minimum_size.y = 60
				control = text_edit
			else:
				var line := LineEdit.new()
				line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				if prop_name in resource:
					line.text = str(resource.get(prop_name))
				line.text_changed.connect(func(val: String): _on_value_changed(hbox, prop_name, val))
				control = line
		_:
			# Fallback: read-only label showing the value
			var fallback := Label.new()
			fallback.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if prop_name in resource:
				fallback.text = str(resource.get(prop_name))
			control = fallback

	hbox.add_child(control)
	return hbox


static func _create_enum_control(prop: Dictionary, resource: Resource) -> OptionButton:
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var entries: PackedStringArray = str(prop.hint_string).split(",")
	for i in entries.size():
		var entry: String = entries[i].strip_edges()
		var colon := entry.find(":")
		if colon >= 0:
			option.add_item(entry.substr(0, colon), entry.substr(colon + 1).to_int())
		else:
			option.add_item(entry, i)
	if prop.name in resource:
		var val = resource.get(prop.name)
		if val is int:
			option.select(val)
	option.item_selected.connect(func(idx: int): _on_value_changed(option.get_parent(), prop.name, idx))
	return option


static func _apply_range_hint(spin: SpinBox, hint_string: String) -> void:
	var parts := hint_string.split(",")
	if parts.size() >= 1 and parts[0].is_valid_float():
		spin.min_value = parts[0].to_float()
	if parts.size() >= 2 and parts[1].is_valid_float():
		spin.max_value = parts[1].to_float()
	if parts.size() >= 3 and parts[2].strip_edges().is_valid_float():
		spin.step = parts[2].strip_edges().to_float()


static func _create_port_label(text: String, tooltip: String = "") -> Label:
	var label := Label.new()
	label.text = text.capitalize()
	label.custom_minimum_size.y = 26
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if not tooltip.is_empty():
		label.tooltip_text = _strip_bbcode(tooltip)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
	return label


# ── Texture node (external resource with preview) ──

## Creates a GraphNode showing a texture preview. Used for @export Texture2D properties.
static func create_texture_node(texture: Texture2D) -> GraphNode:
	var node := GraphNode.new()
	node.set_meta("resource", texture)
	node.set_meta("is_external", true)
	node.resizable = true
	node.add_theme_constant_override("separation", 4)
	node.title = "Texture  [%s]" % texture.resource_path.get_file()

	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(64, 64)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tex_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tex_rect.texture = texture
	node.add_child(tex_rect)

	node.set_slot(0, true, PT.TEXTURE, PortTypes.get_color(PT.TEXTURE), false, 0, Color.WHITE)
	_apply_titlebar_color(node, PortTypes.get_color(PT.TEXTURE))
	return node


# ── Node coloring ──

## Colors the node titlebar based on its input port type (what it plugs into).
static func _apply_node_color(node: GraphNode, resource: Resource) -> void:
	var input_pt := Registry.get_input_port_type_for_resource(resource)
	if input_pt < 0:
		return  # Root nodes keep the default color
	_apply_titlebar_color(node, PortTypes.get_color(input_pt))


## Sets a tinted StyleBoxFlat on the GraphNode's titlebar.
static func _apply_titlebar_color(node: GraphNode, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.4)
	style.border_color = color.darkened(0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	node.add_theme_stylebox_override("titlebar", style)

	var selected_style := style.duplicate()
	selected_style.bg_color = color.darkened(0.2)
	selected_style.border_color = color
	selected_style.set_border_width_all(2)
	node.add_theme_stylebox_override("titlebar_selected", selected_style)


# ── Toggle visibility ──

static func _wire_toggles(node: GraphNode, resource: Resource, toggle_controls: Dictionary) -> void:
	for toggle_name in toggle_controls:
		var is_on: bool = false
		if resource and toggle_name in resource:
			is_on = resource.get(toggle_name)

		var dependents: Array = toggle_controls[toggle_name]
		for dep in dependents:
			dep.visible = is_on

		var check := _find_checkbox(node, toggle_name)
		if check:
			check.toggled.connect(func(val: bool):
				for d in dependents:
					d.visible = val
				# Force GraphNode to re-layout so port positions update correctly
				node.reset_size()
			)


static func _find_checkbox(node: GraphNode, prop_name: String) -> CheckBox:
	for child in node.get_children():
		if child is HBoxContainer and child.has_meta("prop_name") and child.get_meta("prop_name") == prop_name:
			for sub in child.get_children():
				if sub is CheckBox:
					return sub
	return null


# ── Dynamic array ports ──

static func _add_dynamic_port_section(node: GraphNode, dyn: Dictionary, resource: Resource) -> void:
	var property_name: String = dyn["name"]
	var port_type: int = dyn["port_type"]
	var label_prefix: String = dyn["label_prefix"]

	# Existing items from resource
	if resource and property_name in resource:
		var arr = resource.get(property_name)
		if arr is Array:
			for i in arr.size():
				_add_dynamic_port_row(node, label_prefix, i, port_type, property_name)

	# Add button row (no port)
	var add_row := HBoxContainer.new()
	add_row.custom_minimum_size.y = 24
	add_row.set_meta("dynamic_add_row", property_name)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(spacer)

	var add_btn := Button.new()
	add_btn.text = "+ %s" % label_prefix
	add_btn.custom_minimum_size.x = 90
	add_btn.set_meta("dynamic_property", property_name)
	add_btn.set_meta("dynamic_port_type", port_type)
	add_btn.set_meta("dynamic_label_prefix", label_prefix)
	add_row.add_child(add_btn)

	node.add_child(add_row)


static func _make_dynamic_row(property_name: String, index: int, label_prefix: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 26
	row.set_meta("dynamic_property", property_name)
	row.set_meta("dynamic_index", index)

	var row_label := Label.new()
	row_label.text = "%s %d" % [label_prefix, index]
	row_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(row_label)

	var remove_btn := Button.new()
	remove_btn.text = "×"
	remove_btn.custom_minimum_size.x = 30
	row.add_child(remove_btn)
	return row


static func _add_dynamic_port_row(node: GraphNode, label_prefix: String, index: int, port_type: int, property_name: String) -> void:
	node.add_child(_make_dynamic_row(property_name, index, label_prefix))


# ── Value changed callback ──

static func _on_value_changed(control: Control, prop_name: String, value: Variant) -> void:
	var parent := control
	while parent and not parent is GraphNode:
		parent = parent.get_parent()
	if parent and parent is GraphNode and parent.has_meta("resource"):
		var res: Resource = parent.get_meta("resource")
		if res and prop_name in res:
			res.set(prop_name, value)
			res.emit_changed()


# ── Public helpers for graph_editor ──

## Adds one dynamic port to an existing node at runtime.
## Inserts before the "+ Add" button row so it stays at the bottom.
static func append_dynamic_port(node: GraphNode, property_name: String, port_type: int, label_prefix: String) -> int:
	var port_color := PortTypes.get_color(port_type)
	var count := _count_dynamic_rows(node, property_name)
	var add_row_idx := _find_add_row(node, property_name)

	var row := _make_dynamic_row(property_name, count, label_prefix)

	if add_row_idx >= 0:
		node.add_child(row)
		node.move_child(row, add_row_idx)
	else:
		node.add_child(row)

	var slot_idx := row.get_index()
	node.set_slot(slot_idx, false, 0, Color.WHITE, true, port_type, port_color)

	# The add-button row shifted — keep its slot portless
	if add_row_idx >= 0:
		var new_add_idx := add_row_idx + 1
		if new_add_idx < node.get_child_count():
			node.set_slot(new_add_idx, false, 0, Color.WHITE, false, 0, Color.WHITE)

	return slot_idx


## Removes a dynamic port row by its dynamic_index.
static func remove_dynamic_port_row(node: GraphNode, property_name: String, remove_index: int) -> void:
	var target_child: Control = null
	for child in node.get_children():
		if child.has_meta("dynamic_property") and child.get_meta("dynamic_property") == property_name:
			if child.has_meta("dynamic_index") and child.get_meta("dynamic_index") == remove_index:
				target_child = child
				break

	if target_child == null:
		return

	# Capture the slot config of every child *after* the one being removed,
	# because GraphNode doesn't shift internal slot data on remove_child.
	var removed_idx := target_child.get_index()
	var child_count := node.get_child_count()
	var saved_slots := []
	for i in range(removed_idx + 1, child_count):
		saved_slots.append(_read_slot(node, i))

	# Clear slot at removed index and remove the child
	node.set_slot(removed_idx, false, 0, Color.WHITE, false, 0, Color.WHITE)
	node.remove_child(target_child)
	target_child.queue_free()

	# Re-apply saved slot configs at their new (shifted) indices
	for i in saved_slots.size():
		var s: Dictionary = saved_slots[i]
		var new_idx := removed_idx + i
		node.set_slot(new_idx,
			s["left_enabled"], s["left_type"], s["left_color"],
			s["right_enabled"], s["right_type"], s["right_color"])

	# Re-index remaining dynamic rows for this property
	var idx := 0
	for child in node.get_children():
		if child.has_meta("dynamic_property") and child.get_meta("dynamic_property") == property_name and child.has_meta("dynamic_index"):
			child.set_meta("dynamic_index", idx)
			for sub in child.get_children():
				if sub is Label:
					sub.text = "%s %d" % [_get_label_prefix(node, property_name), idx]
					break
			idx += 1


## Read the current slot configuration for a given child index.
static func _read_slot(node: GraphNode, slot_idx: int) -> Dictionary:
	return {
		"left_enabled": node.is_slot_enabled_left(slot_idx),
		"left_type": node.get_slot_type_left(slot_idx),
		"left_color": node.get_slot_color_left(slot_idx),
		"right_enabled": node.is_slot_enabled_right(slot_idx),
		"right_type": node.get_slot_type_right(slot_idx),
		"right_color": node.get_slot_color_right(slot_idx),
	}


static func _count_dynamic_rows(node: GraphNode, property_name: String) -> int:
	var count := 0
	for child in node.get_children():
		if child.has_meta("dynamic_property") and child.get_meta("dynamic_property") == property_name and child.has_meta("dynamic_index"):
			count += 1
	return count


static func _find_add_row(node: GraphNode, property_name: String) -> int:
	for i in node.get_child_count():
		var child := node.get_child(i)
		if child.has_meta("dynamic_add_row") and child.get_meta("dynamic_add_row") == property_name:
			return i
	return -1


static func _get_label_prefix(node: GraphNode, property_name: String) -> String:
	# Find the add button for this property and read its label_prefix meta
	for child in node.get_children():
		if child.has_meta("dynamic_add_row") and child.get_meta("dynamic_add_row") == property_name:
			for sub in child.get_children():
				if sub is Button and sub.has_meta("dynamic_label_prefix"):
					return sub.get_meta("dynamic_label_prefix")
	return "Item"


# ── BBCode stripping ──

static var _bbcode_regex: RegEx

## Converts BBCode doc comments to clean plain text for tooltips.
static func _strip_bbcode(text: String) -> String:
	var result := text
	result = result.replace("[br]", "\n")
	if _bbcode_regex == null:
		_bbcode_regex = RegEx.new()
		_bbcode_regex.compile("\\[/?\\w+\\]")
	result = _bbcode_regex.sub(result, "", true)
	while result.contains("\n\n\n"):
		result = result.replace("\n\n\n", "\n\n")
	return result.strip_edges()


# ── Doc comment parsing ──

## Parses ## doc comments from a script and all its parent scripts.
## Returns {property_name: "tooltip text"}.
static func _parse_all_doc_comments(script: Script) -> Dictionary:
	var result := {}
	var s := script
	while s:
		var comments := _parse_script_doc_comments(s)
		for key in comments:
			if not result.has(key):  # Child class comments take priority
				result[key] = comments[key]
		s = s.get_base_script()
	return result


static func _parse_script_doc_comments(script: Script) -> Dictionary:
	var result := {}
	if script == null:
		return result
	var source := script.source_code
	if source.is_empty():
		return result

	var lines := source.split("\n")
	var comment_lines := PackedStringArray()

	for line in lines:
		var stripped := line.strip_edges()
		if stripped.begins_with("##"):
			var content := stripped.substr(2).strip_edges()
			# Empty ## line acts as a paragraph break (like [br])
			if content.is_empty():
				comment_lines.append("[br]")
			else:
				comment_lines.append(content)
		elif not comment_lines.is_empty():
			var var_name := _extract_var_name(stripped)
			if not var_name.is_empty():
				result[var_name] = " ".join(comment_lines)
			comment_lines.clear()
		else:
			comment_lines.clear()

	return result


static func _extract_var_name(line: String) -> String:
	var var_pos := line.find("var ")
	if var_pos < 0:
		return ""
	var rest := line.substr(var_pos + 4).strip_edges()
	var end := 0
	while end < rest.length():
		var c := rest[end]
		if c == ":" or c == " " or c == "=":
			break
		end += 1
	if end > 0:
		return rest.substr(0, end)
	return ""
