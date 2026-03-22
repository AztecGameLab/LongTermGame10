@tool
class_name AbilityGraphNodeTypeRegistry
extends RefCounted

## Minimal registry: maps type keys to script paths, display names, and categories.
## All property/port definitions are auto-discovered via Resource.get_property_list().

const _PortTypes := preload("res://addons/ability_editor/editor/port_types.gd")
const PT := _PortTypes.PortType

static var _types: Dictionary = {}

# Maps base class names (as used in @export type hints like "Action", "BaseStatusEffect")
# to port types. Used to determine output port types from resource-typed properties.
const CLASS_PORT_TYPES := {
	"Action": PT.ACTION,
	"TargetAction": PT.ACTION,
	"BaseStatusEffect": PT.STATUS_EFFECT,
	"StatusEffectStack": PT.STACK,
	"StatusEffectModifier": PT.MODIFIER,
	"StatusEffectTrigger": PT.TRIGGER,
	"Texture2D": PT.TEXTURE,
	"CompressedTexture2D": PT.TEXTURE,
	"AtlasTexture": PT.TEXTURE,
	"ImageTexture": PT.TEXTURE,
}

# Maps base class scripts to port types (by UID for rename safety).
# Used to determine INPUT port type for a resource based on its class hierarchy.
# Resolved to res:// paths at init time since script.resource_path returns res://.
const _BASE_SCRIPT_PORT_TYPE_UIDS := {
	"uid://xwcbloqu4nwu": PT.ACTION,      # action.gd
	"uid://bqrnx8xiwhciu": PT.ACTION,      # target_action.gd
	"uid://dwogyp2cbh5l1": PT.STATUS_EFFECT, # base_status_effect.gd
	"uid://c4rwprj6d61c0": PT.STATUS_EFFECT, # status_effect.gd
	"uid://dot0bfh4ojuo7": PT.STATUS_EFFECT, # fading_status_effect.gd
	"uid://dasiej7totk8c": PT.STATUS_EFFECT, # concentration_status_effect.gd
	"uid://c2ci25gmhnb4w": PT.STACK,        # status_effect_stack.gd
	"uid://w6h7oqtjl61k": PT.MODIFIER,      # status_effect_modifier.gd
	"uid://d0uvf6jnorxpw": PT.TRIGGER,      # status_effect_trigger.gd
}
static var _BASE_SCRIPT_PORT_TYPES: Dictionary = {}  # Resolved at init: res:// path -> port type


static func _ensure_types() -> void:
	if not _types.is_empty():
		return
	_build_types()


static func _build_types() -> void:
	# Resolve UID -> res:// path lookup for _BASE_SCRIPT_PORT_TYPES
	for uid in _BASE_SCRIPT_PORT_TYPE_UIDS:
		var script := load(uid) as Script
		if script:
			_BASE_SCRIPT_PORT_TYPES[script.resource_path] = _BASE_SCRIPT_PORT_TYPE_UIDS[uid]

	_reg("Ability", "Ability", "uid://ny1mjfoo1mqc", "Root")

	_reg("DamageAction", "Damage", "uid://d0rap3gi3boj5", "Actions / Target")
	_reg("StaticDamageAction", "Static Damage", "uid://bihndepd0cudw", "Actions / Target")
	_reg("ScalingDamageAction", "Scaling Damage", "uid://ba2qm14bj1fq", "Actions / Target")
	_reg("HealAction", "Heal", "uid://c84i4tkx4t6au", "Actions / Target")
	_reg("ApplyStatusAction", "Apply Status", "uid://be5ru5snax08s", "Actions / Target")
	_reg("RemoveStatusAction", "Remove Status", "uid://4uj0ujy2m4of", "Actions / Target")
	_reg("WaitAction", "Wait", "uid://bewmys3bnrfj4", "Actions / Target")

	_reg("GroupAction", "Group", "uid://da17dshmjafs6", "Actions / Flow")
	_reg("HitChanceAction", "Hit Chance", "uid://cy60nwkkhatr8", "Actions / Flow")
	_reg("LuckChanceAction", "Luck Chance", "uid://dkyoonc2qagl3", "Actions / Flow")
	_reg("RepeatAction", "Repeat", "uid://3xfxcysmuqdm", "Actions / Flow")
	_reg("RetargetAction", "Retarget", "uid://cm0yl4tfwdkhn", "Actions / Flow")

	_reg("StatusEffect", "Status Effect", "uid://c4rwprj6d61c0", "Status Effects")
	_reg("FadingStatusEffect", "Fading Status Effect", "uid://dot0bfh4ojuo7", "Status Effects")
	_reg("ConcentrationStatusEffect", "Concentration Status Effect", "uid://dasiej7totk8c", "Status Effects")

	_reg("StatusEffectStack", "Stack", "uid://c2ci25gmhnb4w", "Components")
	_reg("StatusEffectModifier", "Modifier", "uid://w6h7oqtjl61k", "Components")
	_reg("StatusEffectTrigger", "Trigger", "uid://d0uvf6jnorxpw", "Components")

	# Pre-compute input port types
	for key in _types:
		var script_path: String = _types[key].get("script_path", "")
		if not script_path.is_empty():
			var script := load(script_path) as Script
			if script:
				_types[key]["input_port_type"] = _compute_input_port_type(script)
			else:
				_types[key]["input_port_type"] = -1
		else:
			_types[key]["input_port_type"] = -1


static func _reg(key: String, display_name: String, script_uid: String, category: String) -> void:
	# Resolve UID to res:// path for runtime comparisons with script.resource_path
	var script := load(script_uid) as Script
	var resolved_path := script.resource_path if script else script_uid
	_types[key] = {
		"display_name": display_name,
		"script_path": resolved_path,
		"category": category,
	}


static func _compute_input_port_type(script: Script) -> int:
	while script:
		if _BASE_SCRIPT_PORT_TYPES.has(script.resource_path):
			return _BASE_SCRIPT_PORT_TYPES[script.resource_path]
		script = script.get_base_script()
	return -1


## Get info dict for a type key: {display_name, script_path, category, input_port_type}.
static func get_type_info(type_key: String) -> Dictionary:
	_ensure_types()
	return _types.get(type_key, {})


## Get all types grouped by category name.
static func get_categories() -> Dictionary:
	_ensure_types()
	var categories := {}
	for key in _types:
		var cat: String = _types[key].get("category", "Other")
		if not categories.has(cat):
			categories[cat] = []
		categories[cat].append(key)
	return categories


## Find the type key for a resource instance by matching its script path.
static func get_class_key_for_resource(resource: Resource) -> String:
	_ensure_types()
	var script := resource.get_script() as Script
	if script == null:
		return ""
	var res_path := script.resource_path
	for key in _types:
		if _types[key].get("script_path", "") == res_path:
			return key
	return ""


## Get the input port type for a resource (walks class hierarchy).
static func get_input_port_type_for_resource(resource: Resource) -> int:
	var key := get_class_key_for_resource(resource)
	if not key.is_empty():
		return _types[key].get("input_port_type", -1)
	var script := resource.get_script() as Script
	while script:
		if _BASE_SCRIPT_PORT_TYPES.has(script.resource_path):
			return _BASE_SCRIPT_PORT_TYPES[script.resource_path]
		script = script.get_base_script()
	return -1


## Map a class name from @export type hints (e.g., "Action") to a port type.
static func get_port_type_for_hint(class_name_str: String) -> int:
	return CLASS_PORT_TYPES.get(class_name_str, -1)


## Get all type keys whose input port matches the given port type.
static func get_types_for_port_type(port_type: int) -> Array:
	_ensure_types()
	var result := []
	for key in _types:
		if _types[key].get("input_port_type", -1) == port_type:
			result.append(key)
	return result


# Port types that should always reference external .tres files (never inline).
const ALWAYS_EXTERNAL_PORT_TYPES := [PT.STATUS_EFFECT, PT.TEXTURE]


# ── Property introspection utilities (shared with factory + serializer) ──

# Properties to skip — Resource built-ins and engine internals.
const _SKIP_PROPS := ["resource_local_to_scene", "resource_path", "resource_name", "script",
	"resource_set_path"]

## Returns true if a property from get_property_list() should be shown in the graph.
static func should_show_property(prop: Dictionary) -> bool:
	var pname: String = str(prop.get("name", ""))
	if pname in _SKIP_PROPS:
		return false
	if pname.begins_with("metadata/"):
		return false
	var usage := int(prop.get("usage", 0))
	if usage & PROPERTY_USAGE_EDITOR == 0:
		return false
	return true


## Check if a property dict describes a resource reference that should be a port.
static func is_port_resource(prop: Dictionary) -> bool:
	return (int(prop.get("type", 0)) == TYPE_OBJECT
		and int(prop.get("hint", 0)) == PROPERTY_HINT_RESOURCE_TYPE
		and get_port_type_for_hint(str(prop.get("hint_string", ""))) >= 0)


## Check if a property dict describes an array of resources that should be dynamic ports.
static func is_port_array(prop: Dictionary) -> bool:
	if int(prop.get("type", 0)) != TYPE_ARRAY:
		return false
	var cls := parse_array_element_class(str(prop.get("hint_string", "")))
	return not cls.is_empty() and get_port_type_for_hint(cls) >= 0


## Parse the element class name from an Array property's hint_string.
## Returns "" if not a resource array.
static func parse_array_element_class(hint_string: String) -> String:
	if hint_string.is_empty():
		return ""
	# Format: "TYPE_OBJECT/PROPERTY_HINT_RESOURCE_TYPE:ClassName"
	# e.g., "24/17:Action"
	var colon := hint_string.find(":")
	if colon < 0:
		return ""
	var prefix := hint_string.substr(0, colon)
	if prefix.contains(str(TYPE_OBJECT)):
		return hint_string.substr(colon + 1)
	return ""


## Derive a short label from a class name (e.g., "StatusEffectStack" → "Stack").
static func label_from_class(class_name_str: String) -> String:
	for prefix in ["StatusEffect"]:
		if class_name_str.begins_with(prefix) and class_name_str.length() > prefix.length():
			return class_name_str.substr(prefix.length())
	return class_name_str
