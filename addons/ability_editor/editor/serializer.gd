@tool
class_name AbilityGraphSerializer
extends RefCounted

## Bidirectional serializer between resource trees and graph nodes/connections.
## Uses property introspection instead of manual definitions.

const Registry := preload("res://addons/ability_editor/editor/node_type_registry.gd")
const Factory := preload("res://addons/ability_editor/editor/graph_node_factory.gd")

## Result of loading a resource into graph form.
class LoadResult:
	var nodes: Array[GraphNode] = []
	var connections: Array[Dictionary] = []  # {from_node, from_port, to_node, to_port}
	var root_resource: Resource


## Loads a resource tree into graph nodes and connections.
static func load_resource(resource: Resource) -> LoadResult:
	var result := LoadResult.new()
	result.root_resource = resource
	var visited := {}  # resource instance id -> node name
	_load_recursive(resource, result, visited, null, "", -1, true)
	_auto_layout(result)
	return result


static func _load_recursive(resource: Resource, result: LoadResult, visited: Dictionary,
		parent_node_name, output_port_name: String, output_port_index: int, is_root: bool = false) -> void:
	var res_id := resource.get_instance_id()

	# Check if already visited (external resource referenced multiple times)
	if visited.has(res_id):
		if parent_node_name != null:
			result.connections.append({
				"from_node": parent_node_name,
				"from_port": output_port_index,
				"to_node": visited[res_id],
				"to_port": 0,
			})
		return

	# Handle Texture2D (built-in type, no script/class_key)
	if resource is Texture2D:
		var node := Factory.create_texture_node(resource)
		var node_name := "node_%d" % result.nodes.size()
		node.name = node_name
		_restore_layout(node, resource, result.root_resource)
		result.nodes.append(node)
		visited[res_id] = node_name
		if parent_node_name != null:
			result.connections.append({
				"from_node": parent_node_name,
				"from_port": output_port_index,
				"to_node": node_name,
				"to_port": 0,
			})
		return

	var class_key := Registry.get_class_key_for_resource(resource)
	if class_key.is_empty():
		return

	var is_external := false if is_root else _is_external_resource(resource)
	var node := Factory.create_node(resource, is_external, is_root)
	if node == null:
		return

	var node_name := "node_%d" % result.nodes.size()
	node.name = node_name
	_restore_layout(node, resource, result.root_resource)

	result.nodes.append(node)
	visited[res_id] = node_name

	# Connection from parent to this node
	if parent_node_name != null:
		result.connections.append({
			"from_node": parent_node_name,
			"from_port": output_port_index,
			"to_node": node_name,
			"to_port": 0,
		})

	# Don't recurse into external resources
	if is_external:
		return

	# Discover child resources by introspecting properties
	for prop in resource.get_property_list():
		if not Registry.should_show_property(prop):
			continue
		var pname: String = str(prop.get("name", ""))

		# Single resource reference
		if Registry.is_port_resource(prop):
			var child_res = resource.get(pname)
			if child_res is Resource:
				var port_num := _find_output_port_for_property(node, pname)
				if port_num >= 0:
					_load_recursive(child_res, result, visited, node_name, pname, port_num, false)

		# Array of resources
		elif Registry.is_port_array(prop):
			var arr = resource.get(pname)
			if arr is Array:
				for i in arr.size():
					var child_res = arr[i]
					if child_res is Resource:
						var port_num := _find_output_port_for_property(node, pname, i)
						if port_num >= 0:
							_load_recursive(child_res, result, visited, node_name, pname, port_num, false)


## Find the output port number for a given property on a node.
## For dynamic (array) properties, pass the dynamic_index.
static func _find_output_port_for_property(node: GraphNode, prop_name: String, dynamic_index: int = -1) -> int:
	for child_idx in node.get_child_count():
		var child := node.get_child(child_idx)
		if dynamic_index >= 0:
			# Dynamic port row
			if (child.has_meta("dynamic_property") and child.get_meta("dynamic_property") == prop_name
					and child.has_meta("dynamic_index") and child.get_meta("dynamic_index") == dynamic_index):
				return _slot_to_output_port(node, child_idx)
		else:
			# Static output port
			if child.has_meta("output_property") and child.get_meta("output_property") == prop_name:
				return _slot_to_output_port(node, child_idx)
	return -1


## Convert a slot child index to the output port number used by GraphEdit.
static func _slot_to_output_port(node: GraphNode, slot_idx: int) -> int:
	var port_num := 0
	for i in slot_idx:
		if node.is_slot_enabled_right(i):
			port_num += 1
	return port_num


## Convert an output port number to the slot child index.
static func _output_port_to_slot(node: GraphNode, port_num: int) -> int:
	var count := 0
	for slot_idx in node.get_child_count():
		if node.is_slot_enabled_right(slot_idx):
			if count == port_num:
				return slot_idx
			count += 1
	return -1


## Restore position and size from resource metadata.
static func _restore_layout(node: GraphNode, resource: Resource, root_resource: Resource = null) -> void:
	# External resources (status effects, textures) store layout on the root resource
	var is_external: bool = node.get_meta("is_external", false) or resource is Texture2D
	if is_external and root_resource and root_resource.has_meta("_external_layouts"):
		var layouts: Dictionary = root_resource.get_meta("_external_layouts")
		var uid_key := _resource_uid_string(resource)
		if not uid_key.is_empty() and layouts.has(uid_key):
			var layout: Dictionary = layouts[uid_key]
			node.position_offset = Vector2(layout.get("x", 0.0), layout.get("y", 0.0))
			node.set_meta("_has_layout", true)
			var gw: float = layout.get("w", 0.0)
			var gh: float = layout.get("h", 0.0)
			if gw > 0 and gh > 0:
				node.size = Vector2(gw, gh)
			return
	if resource.has_meta("_graph_x") and resource.has_meta("_graph_y"):
		node.position_offset = Vector2(resource.get_meta("_graph_x"), resource.get_meta("_graph_y"))
		node.set_meta("_has_layout", true)
	if resource.has_meta("_graph_w") and resource.has_meta("_graph_h"):
		var gw: float = resource.get_meta("_graph_w")
		var gh: float = resource.get_meta("_graph_h")
		if gw > 0 and gh > 0:
			node.size = Vector2(gw, gh)


## Returns the uid:// string for a resource, or "" if unavailable.
static func _resource_uid_string(resource: Resource) -> String:
	if resource.resource_path.is_empty():
		return ""
	var uid := ResourceLoader.get_resource_uid(resource.resource_path)
	if uid == ResourceUID.INVALID_ID:
		return ""
	return ResourceUID.id_to_text(uid)


static func _is_external_resource(resource: Resource) -> bool:
	return not resource.resource_path.is_empty() and resource.resource_path.ends_with(".tres")


## Auto-layout nodes in a left-to-right tree if no position metadata exists.
static func _auto_layout(result: LoadResult) -> void:
	if result.nodes.is_empty():
		return

	var has_positions := false
	for node in result.nodes:
		if node.has_meta("_has_layout"):
			has_positions = true
			break

	if has_positions:
		return

	# Build adjacency
	var children_map := {}
	var parent_map := {}
	for conn in result.connections:
		if not children_map.has(conn.from_node):
			children_map[conn.from_node] = []
		children_map[conn.from_node].append(conn.to_node)
		parent_map[conn.to_node] = conn.from_node

	# Find root
	var root_name := ""
	for node in result.nodes:
		if not parent_map.has(node.name):
			root_name = node.name
			break
	if root_name.is_empty() and not result.nodes.is_empty():
		root_name = result.nodes[0].name

	# BFS layout — estimate node heights from child count for spacing
	var col_spacing := 350.0
	var row_gap := 40.0  # gap between nodes in the same column
	var positions := {}
	var col_y_offset := {}
	var node_name_map := {}
	for n in result.nodes:
		node_name_map[n.name] = n
	var queue: Array[Array] = [[root_name, 0]]
	var visited_layout := {}

	while not queue.is_empty():
		var current: Array = queue.pop_front()
		var name: String = current[0]
		var col: int = current[1]

		if visited_layout.has(name):
			continue
		visited_layout[name] = true

		if not col_y_offset.has(col):
			col_y_offset[col] = 0.0

		positions[name] = Vector2(col * col_spacing + 50, col_y_offset[col] + 50)

		# Estimate this node's height from its child count (~30px per row + header)
		var n: GraphNode = node_name_map.get(name)
		var estimated_height := 60.0
		if n:
			estimated_height = n.get_child_count() * 30.0 + 50.0
		col_y_offset[col] += estimated_height + row_gap

		var kids: Array = children_map.get(name, [])
		for kid in kids:
			queue.append([kid, col + 1])

	for node in result.nodes:
		if positions.has(node.name):
			node.position_offset = positions[node.name]


## Snapshot all port-managed properties so they can be restored on save failure.
static func snapshot_port_properties(graph_edit: GraphEdit) -> Dictionary:
	var snapshot := {}  # {Resource -> {prop_name -> value}}
	for child in graph_edit.get_children():
		if not child is GraphNode or not child.has_meta("resource"):
			continue
		if child.get_meta("is_external", false):
			continue
		if child.get_meta("resource") is Texture2D:
			continue
		var res: Resource = child.get_meta("resource")
		var props := {}
		for prop in res.get_property_list():
			if not Registry.should_show_property(prop):
				continue
			var pname: String = str(prop.get("name", ""))
			if Registry.is_port_resource(prop):
				props[pname] = res.get(pname)
			elif Registry.is_port_array(prop):
				var arr = res.get(pname)
				if arr is Array:
					props[pname] = arr.duplicate()
		if not props.is_empty():
			snapshot[res] = props
	return snapshot


## Restore port-managed properties from a snapshot (used on save failure).
static func restore_port_properties(snapshot: Dictionary) -> void:
	for res in snapshot:
		for pname in snapshot[res]:
			var value = snapshot[res][pname]
			if value is Array:
				var arr = res.get(pname)
				if arr is Array:
					arr.clear()
					for item in value:
						arr.append(item)
			else:
				res.set(pname, value)


## Saves graph state back into the resource tree.
static func save_to_resource(graph_edit: GraphEdit, root_node: GraphNode) -> Resource:
	if root_node == null or not root_node.has_meta("resource"):
		return null

	var root_resource: Resource = root_node.get_meta("resource")

	# Store positions and sizes in metadata
	var external_layouts := {}  # For imported resources (textures) that can't store metadata
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
		# External resources (status effects, textures) store layout on the
		# root resource so different graphs don't overwrite each other's positions.
		if child.get_meta("is_external", false) or res is Texture2D:
			var uid_key := _resource_uid_string(res)
			if not uid_key.is_empty():
				external_layouts[uid_key] = layout
		else:
			res.set_meta("_graph_x", layout["x"])
			res.set_meta("_graph_y", layout["y"])
			res.set_meta("_graph_w", layout["w"])
			res.set_meta("_graph_h", layout["h"])
	if not external_layouts.is_empty():
		root_resource.set_meta("_external_layouts", external_layouts)

	# Rebuild resource references from connections
	_rebuild_connections(graph_edit)

	return root_resource


static func _rebuild_connections(graph_edit: GraphEdit) -> void:
	# Phase 1: Build desired state from connections
	var new_state := {}  # {Resource: {prop_name: value}}

	# Initialize: every port-managed property starts as null/empty in the new state.
	# SKIP external nodes — their internal properties (e.g. StatusEffect.stacks)
	# are managed by their own graph, not this one.
	for child in graph_edit.get_children():
		if not child is GraphNode or not child.has_meta("resource"):
			continue
		if child.get_meta("is_external", false):
			continue
		if child.get_meta("resource") is Texture2D:
			continue
		var res: Resource = child.get_meta("resource")
		if new_state.has(res):
			continue
		var props := {}
		for prop in res.get_property_list():
			if not Registry.should_show_property(prop):
				continue
			var pname: String = str(prop.get("name", ""))
			if Registry.is_port_resource(prop):
				props[pname] = null
			elif Registry.is_port_array(prop):
				props[pname] = []
		if not props.is_empty():
			new_state[res] = props

	# Populate from connections, sorted by from_port for array ordering
	var connections := graph_edit.get_connection_list()
	var from_map := {}
	for conn in connections:
		var key: StringName = conn.from_node
		if not from_map.has(key):
			from_map[key] = []
		from_map[key].append(conn)

	for from_name in from_map:
		var conns: Array = from_map[from_name]
		conns.sort_custom(func(a, b): return a.from_port < b.from_port)

		var from_node: GraphNode = graph_edit.get_node(NodePath(from_name))
		if from_node == null or not from_node.has_meta("resource"):
			continue
		var from_res: Resource = from_node.get_meta("resource")
		if not new_state.has(from_res):
			continue

		for conn in conns:
			var to_node: GraphNode = graph_edit.get_node(NodePath(conn.to_node))
			if to_node == null or not to_node.has_meta("resource"):
				continue
			var to_res: Resource = to_node.get_meta("resource")

			var slot_idx := _output_port_to_slot(from_node, conn.from_port)
			if slot_idx < 0:
				continue
			var slot_child := from_node.get_child(slot_idx)

			if slot_child.has_meta("output_property"):
				var prop_name: String = slot_child.get_meta("output_property")
				if new_state[from_res].has(prop_name):
					new_state[from_res][prop_name] = to_res

			elif slot_child.has_meta("dynamic_property"):
				var prop_name: String = slot_child.get_meta("dynamic_property")
				if new_state[from_res].has(prop_name):
					new_state[from_res][prop_name].append(to_res)

	# Phase 2: Apply the new state atomically
	for res in new_state:
		for prop_name in new_state[res]:
			var value = new_state[res][prop_name]
			if value is Array:
				# Replace array contents in-place to preserve typed array type
				var arr = res.get(prop_name)
				if arr is Array:
					arr.clear()
					for item in value:
						arr.append(item)
			else:
				res.set(prop_name, value)


## Clear all resource-typed and array properties that would be managed by graph ports.
## When break_sharing is true, arrays are replaced with independent copies before
## clearing — necessary after Resource.duplicate() which shares array references.
static func _clear_port_properties(resource: Resource, break_sharing := false) -> void:
	for prop in resource.get_property_list():
		if not Registry.should_show_property(prop):
			continue
		var pname: String = str(prop.get("name", ""))
		if Registry.is_port_resource(prop):
			resource.set(pname, null)
		elif Registry.is_port_array(prop):
			var arr = resource.get(pname)
			if arr is Array:
				if break_sharing:
					# arr.duplicate() preserves the typed array type when kept as
					# Variant. Do NOT annotate as `: Array` — that strips the type
					# and set() silently fails.
					var fresh = arr.duplicate()
					fresh.clear()
					resource.set(pname, fresh)
				else:
					arr.clear()
