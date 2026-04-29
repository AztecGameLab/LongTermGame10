@tool
extends EditorPlugin

const GraphEditorScene := preload("res://addons/ability_editor/editor/graph_editor.tscn")

var graph_editor: Control
var _panel_visible := false


func _enter_tree() -> void:
	graph_editor = GraphEditorScene.instantiate()
	add_control_to_bottom_panel(graph_editor, "Ability Editor")
	graph_editor.visibility_changed.connect(_on_panel_visibility_changed)
	# Connect inspector for root resource edits, and editor undo/redo for sub-resource edits
	EditorInterface.get_inspector().property_edited.connect(graph_editor._on_inspector_property_edited)
	get_undo_redo().history_changed.connect(graph_editor._on_inspector_property_edited.bind(""))


func _exit_tree() -> void:
	remove_control_from_bottom_panel(graph_editor)
	if graph_editor:
		graph_editor.queue_free()


func _handles(object: Object) -> bool:
	return object is BaseAbility or object is BaseStatusEffect


func _edit(object: Object) -> void:
	if object == null:
		return
	# Only auto-load if the panel is already open
	if _panel_visible:
		graph_editor.clear_nav_stack()
		graph_editor.load_resource(object)


func _save_external_data() -> void:
	if graph_editor and graph_editor.has_resource():
		graph_editor.save_current()


func _on_panel_visibility_changed() -> void:
	_panel_visible = graph_editor.visible


func _get_plugin_name() -> String:
	return "AbilityEditor"
