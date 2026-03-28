@tool
extends VBoxContainer

const Factory := preload("res://addons/ability_editor/editor/graph_node_factory.gd")
const Registry := preload("res://addons/ability_editor/editor/node_type_registry.gd")
const Serializer := preload("res://addons/ability_editor/editor/serializer.gd")
const PortTypes := preload("res://addons/ability_editor/editor/port_types.gd")
const PT := PortTypes.PortType

@onready var graph_edit: GraphEdit = %GraphEdit
@onready var load_button: Button = %LoadButton
@onready var save_button: Button = %SaveButton
@onready var reload_button: Button = %ReloadButton
@onready var resource_label: Label = %ResourceLabel

var _root_resource: Resource
var _root_node: GraphNode
var _ignore_changed := 0 # Re-entrant counter: > 0 means suppress changed signals
var _dirty := false # True when graph has been modified since last save/load
var _reload_pending := false # Debounce flag for deferred reload
var _save_snapshot := {} # Backup of port properties for rollback on save failure
var _watched_resources: Array[Resource] = [] # Resources with changed signal connected
var _nav_stack: Array[Resource] = [] # Navigation history for "Back" button
var _back_button: Button
var _context_position: Vector2
var _file_dialog: FileDialog
var _undo_redo := UndoRedo.new()

# Drag-from-port state
var _pending_from_node: StringName
var _pending_from_port: int = -1
var _port_context_menu: PopupMenu

# Clipboard for copy/paste
var _clipboard_nodes := [] # [{resource, position, is_external, is_texture}]
var _clipboard_connections := [] # [{from_idx, from_port, to_idx, to_port}]


func _ready() -> void:
	if not is_inside_tree():
		return

	load_button.pressed.connect(_on_load_pressed)
	save_button.pressed.connect(_on_save_pressed)
	reload_button.pressed.connect(_on_reload_pressed)

	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	graph_edit.delete_nodes_request.connect(_on_delete_nodes_request)
	graph_edit.connection_to_empty.connect(_on_connection_to_empty)
	graph_edit.gui_input.connect(_on_graph_gui_input)

	graph_edit.snapping_enabled = true
	graph_edit.snapping_distance = 20
	_undo_redo.version_changed.connect(_on_undo_redo_version_changed)

	# Floating "Back" button overlaid on the graph
	_back_button = Button.new()
	_back_button.text = "< Back"
	_back_button.visible = false
	_back_button.pressed.connect(_on_back_pressed)
	_back_button.anchor_left = 0.0
	_back_button.anchor_top = 0.0
	_back_button.offset_left = 8
	_back_button.offset_top = 48
	_back_button.z_index = 10
	graph_edit.add_child(_back_button)

	for port_type in PortTypes.PORT_COLORS:
		graph_edit.add_valid_connection_type(port_type, port_type)

	_build_port_context_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _undo_redo:
			_undo_redo.free()


## ── Keyboard shortcuts (handled via GraphEdit's gui_input) ──

func _on_graph_gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if not event.ctrl_pressed:
		return
	# Don't intercept text editing shortcuts when a text control has focus
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner is LineEdit or focus_owner is TextEdit or focus_owner is SpinBox:
		return
	match event.keycode:
		KEY_Z:
			if event.shift_pressed:
				_undo_redo.redo()
			else:
				_undo_redo.undo()
			graph_edit.accept_event()
		KEY_Y:
			_undo_redo.redo()
			graph_edit.accept_event()
		KEY_C:
			_copy_selected()
			graph_edit.accept_event()
		KEY_V:
			_paste_unique()
			graph_edit.accept_event()
		KEY_D:
			_duplicate_selected()
			graph_edit.accept_event()


## ── Copy / Paste / Duplicate ──

func _copy_selected() -> void:
	_clipboard_nodes.clear()
	_clipboard_connections.clear()

	var selected: Array[GraphNode] = []
	var name_to_idx := {}

	for child in graph_edit.get_children():
		if child is GraphNode and child.selected and child != _root_node:
			name_to_idx[child.name] = selected.size()
			selected.append(child)

	if selected.is_empty():
		return

	for node in selected:
		_clipboard_nodes.append({
			"resource": node.get_meta("resource"),
			"position": node.position_offset,
			"size": node.size,
			"is_external": node.get_meta("is_external", false),
			"is_texture": node.get_meta("resource") is Texture2D,
		})

	# Store connections between selected nodes (as indices into the array)
	for conn in graph_edit.get_connection_list():
		if name_to_idx.has(conn.from_node) and name_to_idx.has(conn.to_node):
			_clipboard_connections.append({
				"from_idx": name_to_idx[conn.from_node],
				"from_port": conn.from_port,
				"to_idx": name_to_idx[conn.to_node],
				"to_port": conn.to_port,
			})


func _paste_unique() -> void:
	if _clipboard_nodes.is_empty():
		return

	var paste_offset := Vector2(60, 60)
	var new_nodes: Array[GraphNode] = []

	# Phase 1: Create and add all nodes
	_undo_redo.create_action("Paste nodes")

	for info in _clipboard_nodes:
		var original_res: Resource = info["resource"]
		var is_ext: bool = info["is_external"]
		var is_tex: bool = info["is_texture"]

		var node: GraphNode
		if is_tex:
			node = Factory.create_texture_node(original_res)
		elif is_ext:
			node = Factory.create_node(original_res, true)
		else:
			var new_res := original_res.duplicate()
			# Build the node with the duplicated resource so dynamic port rows
			# are created from the array sizes (shallow copy still has items).
			node = Factory.create_node(new_res, false)
			# Now clear port-managed properties so the duplicate doesn't share
			# sub-resource references with the original.  The graph connections
			# (from clipboard) will re-establish the correct refs on save.
			Serializer._clear_port_properties(new_res, true)

		if node == null:
			new_nodes.append(null)
			continue

		var key := node.get_meta("class_key", "Texture" if is_tex else "node")
		node.name = _generate_unique_name(key)
		node.position_offset = info["position"] + paste_offset
		var saved_size: Vector2 = info["size"]
		if saved_size.x > 0 and saved_size.y > 0:
			node.size = saved_size

		_undo_redo.add_do_method(_do_add_node.bind(node))
		_undo_redo.add_undo_method(_do_remove_node.bind(node))
		_undo_redo.add_undo_reference(node)
		new_nodes.append(node)

	_undo_redo.commit_action()

	# Phase 2: Connect after all nodes are in the tree (deferred to ensure ports are ready)
	if not _clipboard_connections.is_empty():
		var conns_to_make := []
		for conn in _clipboard_connections:
			var from_node: GraphNode = new_nodes[conn["from_idx"]]
			var to_node: GraphNode = new_nodes[conn["to_idx"]]
			if from_node == null or to_node == null:
				continue
			conns_to_make.append({
				"from": from_node.name, "from_port": conn["from_port"],
				"to": to_node.name, "to_port": conn["to_port"],
			})

		# Use call_deferred so GraphNodes have completed their layout pass
		_deferred_connect_and_select.call_deferred(conns_to_make, new_nodes)
	else:
		# No connections to make, just select pasted nodes
		for child in graph_edit.get_children():
			if child is GraphNode:
				child.selected = child in new_nodes


func _deferred_connect_and_select(conns: Array, new_nodes: Array[GraphNode]) -> void:
	_undo_redo.create_action("Paste connections")
	for conn in conns:
		_undo_redo.add_do_method(graph_edit.connect_node.bind(
			conn["from"], conn["from_port"], conn["to"], conn["to_port"]))
		_undo_redo.add_undo_method(graph_edit.disconnect_node.bind(
			conn["from"], conn["from_port"], conn["to"], conn["to_port"]))
	_undo_redo.commit_action()

	for child in graph_edit.get_children():
		if child is GraphNode:
			child.selected = child in new_nodes


func _duplicate_selected() -> void:
	_copy_selected()
	_paste_unique()


## ── Drag-from-port context menu ──

func _build_port_context_menu() -> void:
	_port_context_menu = PopupMenu.new()
	_port_context_menu.name = "PortContextMenu"
	add_child(_port_context_menu)
	_port_context_menu.id_pressed.connect(_on_port_context_id_pressed)


func _on_connection_to_empty(from_node: StringName, from_port: int, release_position: Vector2) -> void:
	_pending_from_node = from_node
	_pending_from_port = from_port
	_context_position = (release_position + graph_edit.scroll_offset) / graph_edit.zoom

	var node: GraphNode = graph_edit.get_node_or_null(NodePath(from_node))
	if node == null:
		return

	var slot_idx := Serializer._output_port_to_slot(node, from_port)
	if slot_idx < 0:
		return
	var port_type: int = node.get_slot_type_right(slot_idx)

	# Always-external port types: use quick picker filtered by type
	if port_type in Registry.ALWAYS_EXTERNAL_PORT_TYPES:
		var base_types: Array[StringName] = []
		if port_type == PT.TEXTURE:
			base_types = [&"Texture2D"]
		elif port_type == PT.STATUS_EFFECT:
			base_types = [&"BaseStatusEffect"]
		elif port_type == PT.CONCENTRATION_STATUS_EFFECT:
			base_types = [&"ConcentrationStatusEffect"]
		_open_quick_link(base_types)
		return

	# Normal: show matching type menu
	var matching_types: Array = Registry.get_types_for_port_type(port_type)
	if matching_types.is_empty():
		return

	_port_context_menu.clear()
	for i in matching_types.size():
		var type_key: String = matching_types[i]
		var info: Dictionary = Registry.get_type_info(type_key)
		_port_context_menu.add_item(info.get("display_name", type_key), i)
		_port_context_menu.set_item_metadata(_port_context_menu.get_item_index(i), type_key)

	_port_context_menu.position = Vector2i(graph_edit.get_screen_position()) + Vector2i(release_position)
	_port_context_menu.popup()


func _on_port_context_id_pressed(id: int) -> void:
	var idx := _port_context_menu.get_item_index(id)
	var type_key: String = _port_context_menu.get_item_metadata(idx)
	var node := _prepare_new_node(type_key, _context_position)
	if node == null:
		return

	# Single undo action: create node + disconnect old + connect new
	_undo_redo.create_action("Create and connect %s" % type_key)
	_undo_redo.add_do_method(_do_add_node.bind(node))
	_undo_redo.add_undo_method(_do_remove_node.bind(node))
	_undo_redo.add_undo_reference(node)

	for conn in graph_edit.get_connection_list():
		if conn.from_node == _pending_from_node and conn.from_port == _pending_from_port:
			_undo_redo.add_do_method(graph_edit.disconnect_node.bind(
				conn.from_node, conn.from_port, conn.to_node, conn.to_port))
			_undo_redo.add_undo_method(graph_edit.connect_node.bind(
				conn.from_node, conn.from_port, conn.to_node, conn.to_port))
			break

	_undo_redo.add_do_method(graph_edit.connect_node.bind(
		_pending_from_node, _pending_from_port, node.name, 0))
	_undo_redo.add_undo_method(graph_edit.disconnect_node.bind(
		_pending_from_node, _pending_from_port, node.name, 0))
	_undo_redo.commit_action()


## ── Link External Resource ──

## Quick picker for always-external port types (status effects, textures).
func _open_quick_link(base_types: Array[StringName]) -> void:
	EditorInterface.popup_quick_open(_on_link_external_selected, base_types)


func _on_link_external_selected(path: String) -> void:
	var resource := ResourceLoader.load(path)
	if resource == null:
		return

	var node: GraphNode
	var key_name: String
	if resource is Texture2D:
		node = Factory.create_texture_node(resource)
		key_name = "Texture"
	else:
		var class_key := Registry.get_class_key_for_resource(resource)
		if class_key.is_empty():
			return
		node = Factory.create_node(resource, true)
		key_name = class_key

	if node == null:
		return
	node.name = _generate_unique_name(key_name)
	node.position_offset = _context_position

	_undo_redo.create_action("Link external resource")
	_undo_redo.add_do_method(_do_add_node.bind(node))
	_undo_redo.add_undo_method(_do_remove_node.bind(node))
	_undo_redo.add_undo_reference(node)

	# Auto-connect if dragged from a port
	if not _pending_from_node.is_empty() and _pending_from_port >= 0:
		for conn in graph_edit.get_connection_list():
			if conn.from_node == _pending_from_node and conn.from_port == _pending_from_port:
				_undo_redo.add_do_method(graph_edit.disconnect_node.bind(
					conn.from_node, conn.from_port, conn.to_node, conn.to_port))
				_undo_redo.add_undo_method(graph_edit.connect_node.bind(
					conn.from_node, conn.from_port, conn.to_node, conn.to_port))
				break
		_undo_redo.add_do_method(graph_edit.connect_node.bind(
			_pending_from_node, _pending_from_port, node.name, 0))
		_undo_redo.add_undo_method(graph_edit.disconnect_node.bind(
			_pending_from_node, _pending_from_port, node.name, 0))

	_undo_redo.commit_action()
	_pending_from_node = &""
	_pending_from_port = -1


## ── Node creation ──

## Creates a node without adding to tree or registering undo. Used by callers
## that need to batch node creation with other operations in a single undo action.
func _prepare_new_node(type_key: String, position: Vector2 = Vector2.ZERO) -> GraphNode:
	var info := Registry.get_type_info(type_key)
	if info.is_empty():
		return null

	var script_path: String = info.get("script_path", "")
	var resource: Resource = null
	if not script_path.is_empty():
		var script := load(script_path) as Script
		if script:
			resource = script.new()

	if resource == null:
		return null

	var node := Factory.create_node(resource)
	if node == null:
		return null

	node.name = _generate_unique_name(type_key)
	node.position_offset = position
	return node


func _generate_unique_name(base: String) -> String:
	var idx := 0
	var node_name := base + "_" + str(idx)
	while graph_edit.has_node(NodePath(node_name)):
		idx += 1
		node_name = base + "_" + str(idx)
	return node_name


## ── Undo/Redo helpers ──

func _do_add_node(node: GraphNode) -> void:
	graph_edit.add_child(node)
	if not node.has_meta("_signals_connected"):
		_connect_node_signals(node)
		node.set_meta("_signals_connected", true)


func _do_remove_node(node: GraphNode) -> void:
	var nname := node.name
	for conn in graph_edit.get_connection_list():
		if conn.from_node == nname or conn.to_node == nname:
			graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
	graph_edit.remove_child(node)


func _do_restore_node(node: GraphNode, connections: Array) -> void:
	graph_edit.add_child(node)
	if not node.has_meta("_signals_connected"):
		_connect_node_signals(node)
		node.set_meta("_signals_connected", true)
	for conn in connections:
		graph_edit.connect_node(conn["from_node"], conn["from_port"], conn["to_node"], conn["to_port"])


## ── Connection handling ──

func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	if from_node == to_node:
		return
	if _would_create_cycle(from_node, to_node):
		return

	_undo_redo.create_action("Connect")

	# Single-connection input: disconnect existing
	for conn in graph_edit.get_connection_list():
		if conn.to_node == to_node and conn.to_port == to_port:
			_undo_redo.add_do_method(graph_edit.disconnect_node.bind(
				conn.from_node, conn.from_port, conn.to_node, conn.to_port))
			_undo_redo.add_undo_method(graph_edit.connect_node.bind(
				conn.from_node, conn.from_port, conn.to_node, conn.to_port))
			break

	# Single-connection output: disconnect existing
	for conn in graph_edit.get_connection_list():
		if conn.from_node == from_node and conn.from_port == from_port:
			_undo_redo.add_do_method(graph_edit.disconnect_node.bind(
				conn.from_node, conn.from_port, conn.to_node, conn.to_port))
			_undo_redo.add_undo_method(graph_edit.connect_node.bind(
				conn.from_node, conn.from_port, conn.to_node, conn.to_port))
			break

	_undo_redo.add_do_method(graph_edit.connect_node.bind(from_node, from_port, to_node, to_port))
	_undo_redo.add_undo_method(graph_edit.disconnect_node.bind(from_node, from_port, to_node, to_port))
	_undo_redo.commit_action()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	_undo_redo.create_action("Disconnect")
	_undo_redo.add_do_method(graph_edit.disconnect_node.bind(from_node, from_port, to_node, to_port))
	_undo_redo.add_undo_method(graph_edit.connect_node.bind(from_node, from_port, to_node, to_port))
	_undo_redo.commit_action()


func _would_create_cycle(from_node: StringName, to_node: StringName) -> bool:
	var visited := {}
	var queue: Array[StringName] = [to_node]

	while not queue.is_empty():
		var current: StringName = queue.pop_front()
		if current == from_node:
			return true
		if visited.has(current):
			continue
		visited[current] = true

		for conn in graph_edit.get_connection_list():
			if conn.from_node == current:
				queue.append(conn.to_node)

	return false


## ── Node deletion ──

func _on_delete_nodes_request(nodes: Array[StringName]) -> void:
	var any_deleted := false
	for node_name in nodes:
		var node: GraphNode = graph_edit.get_node_or_null(NodePath(node_name))
		if node == null or node == _root_node:
			continue

		# Capture connections for undo
		var conns := []
		for conn in graph_edit.get_connection_list():
			if conn.from_node == node_name or conn.to_node == node_name:
				conns.append({"from_node": conn.from_node, "from_port": conn.from_port,
					"to_node": conn.to_node, "to_port": conn.to_port})

		if not any_deleted:
			_undo_redo.create_action("Delete nodes")
			any_deleted = true

		_undo_redo.add_do_method(_do_remove_node.bind(node))
		_undo_redo.add_undo_method(_do_restore_node.bind(node, conns))
		_undo_redo.add_do_reference(node)

	if any_deleted:
		_undo_redo.commit_action()


## ── Load / Save ──

func _on_load_pressed() -> void:
	if _file_dialog:
		_file_dialog.queue_free()

	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_file_dialog.filters = PackedStringArray(["*.tres ; Godot Resource"])
	_file_dialog.file_selected.connect(_on_file_selected_load)
	_file_dialog.min_size = Vector2i(700, 500)
	add_child(_file_dialog)
	_file_dialog.popup_centered()


func _on_file_selected_load(path: String) -> void:
	var resource := ResourceLoader.load(path)
	if resource == null:
		push_warning("AbilityEditor: Failed to load resource at '%s'" % path)
		return
	_nav_stack.clear()
	load_resource(resource)


func load_resource(resource: Resource) -> void:
	# Block re-entrant loads (changed signals can fire during add_child)
	_ignore_changed += 1
	_clear_graph()
	_root_resource = resource

	var result := Serializer.load_resource(resource)

	for node in result.nodes:
		graph_edit.add_child(node)
		_connect_node_signals(node)
		node.set_meta("_signals_connected", true)
		_watch_resource(node)

	for conn in result.connections:
		graph_edit.connect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)

	if not result.nodes.is_empty():
		_root_node = result.nodes[0]

	var res_path := resource.resource_path
	if res_path.is_empty():
		res_path = "(inline)"
	resource_label.text = res_path
	_dirty = false
	_ignore_changed -= 1
	_clipboard_nodes.clear()
	_clipboard_connections.clear()
	_update_button_states()


func _watch_resource(node: GraphNode) -> void:
	if not node.has_meta("resource"):
		return
	var res: Resource = node.get_meta("resource")
	if res == null:
		return
	if not res.changed.is_connected(_on_resource_changed_externally):
		res.changed.connect(_on_resource_changed_externally)
	if not res.property_list_changed.is_connected(_on_resource_changed_externally):
		res.property_list_changed.connect(_on_resource_changed_externally)
	_watched_resources.append(res)


func _unwatch_all_resources() -> void:
	for res in _watched_resources:
		if not is_instance_valid(res):
			continue
		if res.changed.is_connected(_on_resource_changed_externally):
			res.changed.disconnect(_on_resource_changed_externally)
		if res.property_list_changed.is_connected(_on_resource_changed_externally):
			res.property_list_changed.disconnect(_on_resource_changed_externally)
	_watched_resources.clear()


func _on_inspector_property_edited(_property: String) -> void:
	if _ignore_changed > 0:
		return
	if _root_resource == null:
		return
	if not is_visible_in_tree():
		return
	# Only reload if the inspector is editing one of our watched resources
	var edited := EditorInterface.get_inspector().get_edited_object()
	if edited == null:
		return
	var is_ours := edited == _root_resource
	if not is_ours:
		for res in _watched_resources:
			if edited == res:
				is_ours = true
				break
	if not is_ours:
		return
	# Debounce: defer the reload so multiple signals in the same frame only reload once
	if not _reload_pending:
		_reload_pending = true
		_deferred_reload.call_deferred()


func _deferred_reload() -> void:
	_reload_pending = false
	if _root_resource != null and is_visible_in_tree():
		load_resource(_root_resource)


func _on_undo_redo_version_changed() -> void:
	# Don't mark dirty during load (clear_history fires version_changed)
	if _ignore_changed > 0:
		return
	_dirty = true


func _on_resource_changed_externally() -> void:
	if _ignore_changed > 0:
		return
	if _root_resource == null:
		return
	# If the change came from our own graph controls, just mark dirty
	var focus_owner := graph_edit.get_viewport().gui_get_focus_owner()
	if focus_owner and graph_edit.is_ancestor_of(focus_owner):
		_dirty = true
		return
	# External change (e.g. inspector) — reload the graph
	load_resource(_root_resource)


## Returns true if a resource is loaded and can be saved.
func has_resource() -> bool:
	return _root_resource != null and _root_node != null


func _update_button_states() -> void:
	var has_res := has_resource()
	save_button.disabled = not has_res
	reload_button.disabled = not has_res
	_back_button.visible = not _nav_stack.is_empty()


func _on_back_pressed() -> void:
	if _nav_stack.is_empty():
		return
	var prev := _nav_stack.pop_back()
	load_resource(prev)


func _on_reload_pressed() -> void:
	if _root_resource == null:
		return
	# Reload from disk to discard in-memory changes
	var path := _root_resource.resource_path
	if path.is_empty():
		return
	var fresh := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if fresh:
		load_resource(fresh)


## Public entry point for auto-saving (used by plugin._save_external_data).
## Only does a full save if the graph has been modified; otherwise saves layout only.
func save_current() -> void:
	if _root_node == null or _root_resource == null:
		return
	if _dirty:
		_on_save_pressed()
	else:
		_save_layout_only()


func _on_save_pressed() -> void:
	if _root_node == null or _root_resource == null:
		return

	# Snapshot port properties BEFORE rebuild
	_save_snapshot = Serializer.snapshot_port_properties(graph_edit)
	_ignore_changed += 1
	Serializer.save_to_resource(graph_edit, _root_node)
	_ignore_changed -= 1

	# Validate: check that no arrays lost items compared to snapshot.
	# If data would be lost, refuse to save and restore the snapshot.
	var loss := _validate_no_data_loss()
	if not loss.is_empty():
		push_error("AbilityEditor: SAVE ABORTED — data loss detected! Restoring backup.")
		for msg in loss:
			push_error("  " + msg)
		Serializer.restore_port_properties(_save_snapshot)
		_save_snapshot = {}
		return

	var path := _root_resource.resource_path
	if path.is_empty():
		if _file_dialog:
			_file_dialog.queue_free()
		_file_dialog = FileDialog.new()
		_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		_file_dialog.access = FileDialog.ACCESS_RESOURCES
		_file_dialog.filters = PackedStringArray(["*.tres ; Godot Resource"])
		_file_dialog.file_selected.connect(_on_file_selected_save)
		_file_dialog.min_size = Vector2i(700, 500)
		add_child(_file_dialog)
		_file_dialog.popup_centered()
	else:
		_do_save(path)


func _on_file_selected_save(path: String) -> void:
	if _root_resource == null:
		return
	_do_save(path)


## Validate that the rebuild didn't lose any connections the graph still has.
## Counts outgoing connections per (node, property) in the graph and compares
## against the resource's array sizes after rebuild. Returns error messages if
## the rebuild produced fewer items than the graph expects.
func _validate_no_data_loss() -> Array[String]:
	# Count expected array sizes from graph connections
	var expected := {} # {Resource: {prop_name: count}}
	for conn in graph_edit.get_connection_list():
		var from_node: GraphNode = graph_edit.get_node_or_null(NodePath(conn.from_node))
		if from_node == null or not from_node.has_meta("resource"):
			continue
		if from_node.get_meta("is_external", false):
			continue
		var slot_idx := Serializer._output_port_to_slot(from_node, conn.from_port)
		if slot_idx < 0:
			continue
		var slot_child := from_node.get_child(slot_idx)
		if not slot_child.has_meta("dynamic_property"):
			continue
		var res: Resource = from_node.get_meta("resource")
		var prop_name: String = slot_child.get_meta("dynamic_property")
		if not expected.has(res):
			expected[res] = {}
		expected[res][prop_name] = expected[res].get(prop_name, 0) + 1

	# Compare expected vs actual
	var errors: Array[String] = []
	for res in expected:
		for prop_name in expected[res]:
			var expect_count: int = expected[res][prop_name]
			var arr = res.get(prop_name)
			var actual_count: int = arr.size() if arr is Array else 0
			if actual_count < expect_count:
				var res_name: String = ""
				if "name" in res:
					res_name = str(res.get("name"))
				errors.append(
					"%s.%s: graph has %d connections, but resource has %d items" % [
						res_name if not res_name.is_empty() else str(res),
						prop_name, expect_count, actual_count])
	return errors


func _do_save(path: String) -> void:
	_take_ownership_recursive(_root_resource)

	var err := ResourceSaver.save(_root_resource, path,
		ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS)
	if err != OK:
		push_warning("AbilityEditor: Failed to save resource: %s" % error_string(err))
		# Rollback: restore the port properties that _rebuild_connections cleared
		if not _save_snapshot.is_empty():
			Serializer.restore_port_properties(_save_snapshot)
			push_warning("AbilityEditor: Rolled back in-memory changes.")
	else:
		if _root_resource.resource_path != path:
			_root_resource.resource_path = path
		resource_label.text = path + " (saved)"
		_dirty = false
	_save_snapshot = {}


## Save only node positions/sizes to resource metadata (in-memory only).
## The metadata will be persisted on the next full save. No disk write here —
## writing the full resource just for layout risks data loss if in-memory state
## was corrupted by a failed rebuild.
func _save_layout_only() -> void:
	var external_layouts := {}
	for child in graph_edit.get_children():
		if not child is GraphNode or not child.has_meta("resource"):
			continue
		var res: Resource = child.get_meta("resource")
		var layout := {
			"x": snapped(child.position_offset.x, 0.5),
			"y": snapped(child.position_offset.y, 0.5),
			"w": snapped(child.size.x, 0.5),
			"h": snapped(child.size.y, 0.5),
		}
		if child.get_meta("is_external", false) or res is Texture2D:
			var uid_key := Serializer._resource_uid_string(res)
			if not uid_key.is_empty():
				external_layouts[uid_key] = layout
		else:
			res.set_meta("_graph_x", layout["x"])
			res.set_meta("_graph_y", layout["y"])
			res.set_meta("_graph_w", layout["w"])
			res.set_meta("_graph_h", layout["h"])
	if not external_layouts.is_empty() and _root_resource:
		_root_resource.set_meta("_external_layouts", external_layouts)


## Recursively clear resource_path on inline sub-resources so they serialize inline.
func _take_ownership_recursive(resource: Resource) -> void:
	for prop in resource.get_property_list():
		if not Registry.should_show_property(prop):
			continue
		var pname: String = str(prop.get("name", ""))
		var ptype := int(prop.get("type", 0))
		var phint := int(prop.get("hint", 0))
		if ptype == TYPE_OBJECT and phint == PROPERTY_HINT_RESOURCE_TYPE:
			var child = resource.get(pname)
			if child is Resource and child.resource_path.is_empty():
				_take_ownership_recursive(child)
		elif ptype == TYPE_ARRAY:
			var arr = resource.get(pname)
			if arr is Array:
				for item in arr:
					if item is Resource and item.resource_path.is_empty():
						_take_ownership_recursive(item)


## Public entry point for clearing the graph (used by plugin on resource deselection).
func clear_graph() -> void:
	_clear_graph()


## Clear navigation stack (used by plugin when selecting a new top-level resource).
func clear_nav_stack() -> void:
	_nav_stack.clear()


func _clear_graph() -> void:
	_unwatch_all_resources()
	graph_edit.clear_connections()
	# Collect first — removing children during iteration skips nodes due to index shift
	var to_remove: Array[GraphNode] = []
	for child in graph_edit.get_children():
		if child is GraphNode:
			to_remove.append(child)
	for child in to_remove:
		graph_edit.remove_child(child)
		child.free()
	_root_node = null
	_root_resource = null
	_undo_redo.clear_history()
	resource_label.text = "No resource loaded"
	_update_button_states()


## ── Drag and drop from FileSystem dock ──

static func _is_image_file(path: String) -> bool:
	var ext := path.get_extension().to_lower()
	return ext in ["png", "jpg", "jpeg", "svg", "webp"]


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary and data.get("type") == "files":
		var files: PackedStringArray = data.get("files", PackedStringArray())
		for file in files:
			if file.ends_with(".tres") or _is_image_file(file):
				return true
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return
	var files: PackedStringArray = data.get("files", PackedStringArray())
	var offset := 0.0
	for file in files:
		var resource := ResourceLoader.load(file)
		if resource == null:
			continue

		var node: GraphNode
		var key_name: String

		if resource is Texture2D:
			node = Factory.create_texture_node(resource)
			key_name = "Texture"
		else:
			if not file.ends_with(".tres"):
				continue
			var class_key := Registry.get_class_key_for_resource(resource)
			if class_key.is_empty():
				continue

			if _root_node == null and (resource is BaseAbility or resource is BaseStatusEffect):
				load_resource(resource)
				return

			node = Factory.create_node(resource, true)
			key_name = class_key

		if node == null:
			continue

		var drop_pos := (at_position + graph_edit.scroll_offset) / graph_edit.zoom
		drop_pos.y += offset
		node.name = _generate_unique_name(key_name)
		node.position_offset = drop_pos

		_undo_redo.create_action("Drop external resource")
		_undo_redo.add_do_method(_do_add_node.bind(node))
		_undo_redo.add_undo_method(_do_remove_node.bind(node))
		_undo_redo.add_undo_reference(node)
		_undo_redo.commit_action()
		offset += 80.0


## ── Node signal wiring ──

func _connect_node_signals(node: GraphNode) -> void:
	for child in node.get_children():
		_connect_buttons_recursive(node, child)


func _connect_buttons_recursive(graph_node: GraphNode, control: Control) -> void:
	if control is Button:
		# Dynamic add button
		if control.has_meta("dynamic_property") and control.text.begins_with("+"):
			var prop: String = control.get_meta("dynamic_property")
			var port_type: int = control.get_meta("dynamic_port_type")
			var label_prefix: String = control.get_meta("dynamic_label_prefix")
			control.pressed.connect(_on_add_dynamic_port.bind(graph_node, prop, port_type, label_prefix))

		# Dynamic remove button (x inside a dynamic row)
		elif control.text == "×" and control.get_parent().has_meta("dynamic_index"):
			var row: Control = control.get_parent()
			# Read index from row meta at press time (not bind time) so it
			# stays correct after other rows are removed and re-indexed.
			control.pressed.connect(func():
				var current_idx: int = row.get_meta("dynamic_index")
				var prop: String = row.get_meta("dynamic_property")
				_on_remove_dynamic_port(graph_node, prop, current_idx)
			)

		# Open external resource button
		elif control.has_meta("open_external_path"):
			var path: String = control.get_meta("open_external_path")
			control.pressed.connect(_on_open_external.bind(path))

	for sub_child in control.get_children():
		if sub_child is Control:
			_connect_buttons_recursive(graph_node, sub_child)


func _on_add_dynamic_port(graph_node: GraphNode, property_name: String, port_type: int, label_prefix: String) -> void:
	var slot_idx := Factory.append_dynamic_port(graph_node, property_name, port_type, label_prefix)
	var child := graph_node.get_child(slot_idx)
	if child:
		_connect_buttons_recursive(graph_node, child)


func _on_remove_dynamic_port(graph_node: GraphNode, property_name: String, remove_index: int) -> void:
	var slot_idx := -1
	for child_idx in graph_node.get_child_count():
		var child := graph_node.get_child(child_idx)
		if child.has_meta("dynamic_property") and child.get_meta("dynamic_property") == property_name:
			if child.has_meta("dynamic_index") and child.get_meta("dynamic_index") == remove_index:
				slot_idx = child_idx
				break

	if slot_idx < 0:
		return

	var removed_port := Serializer._slot_to_output_port(graph_node, slot_idx)

	# Collect all outgoing connections from this node
	var surviving_conns := []
	for conn in graph_edit.get_connection_list():
		if conn.from_node == graph_node.name:
			if conn.from_port == removed_port:
				continue # Skip the removed port's connection
			var new_port: int = conn.from_port
			if conn.from_port > removed_port:
				new_port -= 1
			surviving_conns.append({
				"from": conn.from_node, "from_port": new_port,
				"to": conn.to_node, "to_port": conn.to_port,
			})

	# Disconnect all outgoing connections
	for conn in graph_edit.get_connection_list():
		if conn.from_node == graph_node.name:
			graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)

	# Remove the row (this shifts slot indices and port cache)
	Factory.remove_dynamic_port_row(graph_node, property_name, remove_index)

	# Defer reconnection so GraphNode port caches are rebuilt
	_deferred_reconnect.call_deferred(surviving_conns)


func _deferred_reconnect(conns: Array) -> void:
	for conn in conns:
		graph_edit.connect_node(conn["from"], conn["from_port"], conn["to"], conn["to_port"])


func _on_open_external(path: String) -> void:
	var resource := ResourceLoader.load(path)
	if resource:
		# Push current resource onto nav stack so "Back" can return to it
		if _root_resource:
			_nav_stack.append(_root_resource)
		# Defer to avoid freeing the button node during its own pressed signal
		load_resource.call_deferred(resource)
