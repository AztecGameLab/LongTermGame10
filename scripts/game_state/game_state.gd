extends Node
## Autoload singleton tracking ability progression across battle/shop scenes.
##
## Stores per-character ability KEYS (strings). At battle load, resolves each key
## to the appropriate Ability resource at the battle's expected level.
##
## Pattern:
##   1. main_menu (or first battle) calls init_starters()
##   2. Each shop appends shop picks via add_ability()
##   3. Each battle scene reads via get_abilities_at_level() during _ready

const FORTUNE := &"fortune"
const CORALLEINE := &"coralleine"
const UMI := &"umi"

# Per-character ability key list. Mutable. Empty until init_starters() runs.
var character_keys: Dictionary = {
	FORTUNE: [],
	CORALLEINE: [],
	UMI: [],
}

# Carry-over key from previous shop (unpicked option, "" = none).
var carryover: Dictionary = {
	FORTUNE: "",
	CORALLEINE: "",
	UMI: "",
}

# Number of shops completed. 0 = before shop 1, 3 = after shop 3.
var shops_completed: int = 0

# Map ability_key -> Dictionary[level: int -> BaseAbility].
# Built at _ready. Lookups for missing levels return null.
var ABILITY_REGISTRY: Dictionary = {}

func _ready() -> void:
	_build_registry()

func _build_registry() -> void:
	ABILITY_REGISTRY = {
		# Fortune starters
		"pierce": {
			1: load("res://resources/abilities/fortune/pierce/pierce_1.tres"),
			2: load("res://resources/abilities/fortune/pierce/pierce_2.tres"),
			3: load("res://resources/abilities/fortune/pierce/pierce_3.tres"),
			4: load("res://resources/abilities/fortune/pierce/pierce_4.tres"),
		},
		"lucky_charm": {
			1: load("res://resources/abilities/fortune/lucky_charm/lucky_charm_1.tres"),
			2: load("res://resources/abilities/fortune/lucky_charm/lucky_charm_2.tres"),
			3: load("res://resources/abilities/fortune/lucky_charm/lucky_charm_3.tres"),
			4: load("res://resources/abilities/fortune/lucky_charm/lucky_charm_4.tres"),
		},
		# Fortune shop pool
		"reckless_slash": {
			2: load("res://resources/abilities/fortune/reckless_slash/reckless_slash_2.tres"),
			3: load("res://resources/abilities/fortune/reckless_slash/reckless_slash_3.tres"),
			4: load("res://resources/abilities/fortune/reckless_slash/reckless_slash_4.tres"),
		},
		"deflect": {
			2: load("res://resources/abilities/fortune/deflect/deflect_2.tres"),
			3: load("res://resources/abilities/fortune/deflect/deflect_3.tres"),
			4: load("res://resources/abilities/fortune/deflect/deflect_4.tres"),
		},
		"strengthen": {
			3: load("res://resources/abilities/fortune/strengthen/strengthen_3.tres"),
			4: load("res://resources/abilities/fortune/strengthen/strengthen_4.tres"),
		},
		"riposte": {
			4: load("res://resources/abilities/fortune/riposte/riposte_4.tres"),
		},
		# Coralleine starters
		"magic_darts": {
			1: load("res://resources/abilities/coralleine/magic darts/magic_darts_1.tres"),
			2: load("res://resources/abilities/coralleine/magic darts/magic_darts_2.tres"),
			3: load("res://resources/abilities/coralleine/magic darts/magic_darts_3.tres"),
			4: load("res://resources/abilities/coralleine/magic darts/magic_darts_4.tres"),
		},
		"magic_cannon": {
			1: load("res://resources/abilities/coralleine/magic_cannon/magic_cannon_1.tres"),
			2: load("res://resources/abilities/coralleine/magic_cannon/magic_cannon_2.tres"),
			3: load("res://resources/abilities/coralleine/magic_cannon/magic_cannon_3.tres"),
			4: load("res://resources/abilities/coralleine/magic_cannon/magic_cannon_4.tres"),
		},
		# Coralleine shop pool
		"lifesteal": {
			1: load("res://resources/abilities/coralleine/lifesteal/lifesteal_1.tres"),
			2: load("res://resources/abilities/coralleine/lifesteal/lifesteal_2.tres"),
			3: load("res://resources/abilities/coralleine/lifesteal/lifesteal_3.tres"),
			4: load("res://resources/abilities/coralleine/lifesteal/lifesteal_4.tres"),
		},
		"rally": {
			3: load("res://resources/abilities/coralleine/rally/rally_3.tres"),
			4: load("res://resources/abilities/coralleine/rally/rally_4.tres"),
		},
		"guardian": {
			4: load("res://resources/abilities/coralleine/guardian/guardian_4.tres"),
		},
		"decoy": {
			2: load("res://resources/abilities/coralleine/decoy/decoy_2.tres"),
			3: load("res://resources/abilities/coralleine/decoy/decoy_3.tres"),
			4: load("res://resources/abilities/coralleine/decoy/decoy_4.tres"),
		},
		# Umi starters
		"bottle_of_heal": {
			1: load("res://resources/abilities/umi/bottle_of_heal/bottle_of_heal_1.tres"),
			2: load("res://resources/abilities/umi/bottle_of_heal/bottle_of_heal_2.tres"),
			3: load("res://resources/abilities/umi/bottle_of_heal/bottle_of_heal_3.tres"),
			4: load("res://resources/abilities/umi/bottle_of_heal/bottle_of_heal_4.tres"),
		},
		"bottle_of_splode": {
			1: load("res://resources/abilities/umi/bottle_of_splode/bottle_of_splode_1.tres"),
			2: load("res://resources/abilities/umi/bottle_of_splode/bottle_of_splode_2.tres"),
			3: load("res://resources/abilities/umi/bottle_of_splode/bottle_of_splode_3.tres"),
			4: load("res://resources/abilities/umi/bottle_of_splode/bottle_of_splode_4.tres"),
		},
		# Umi shop pool
		"bottle_of_acid": {
			1: load("res://resources/abilities/umi/bottle_of_acid/bottle_of_acid_1.tres"),
			2: load("res://resources/abilities/umi/bottle_of_acid/bottle_of_acid_2.tres"),
			3: load("res://resources/abilities/umi/bottle_of_acid/bottle_of_acid_3.tres"),
			4: load("res://resources/abilities/umi/bottle_of_acid/bottle_of_acid_4.tres"),
		},
		"bottle_of_invisibility": {
			2: load("res://resources/abilities/umi/bottle_of_invisibility/bottle_of_invisibility_2.tres"),
			3: load("res://resources/abilities/umi/bottle_of_invisibility/bottle_of_invisibility_3.tres"),
			4: load("res://resources/abilities/umi/bottle_of_invisibility/bottle_of_invisibility_4.tres"),
		},
		"bottle_of_haste": {
			4: load("res://resources/abilities/umi/bottle_of_haste/bottle_of_haste_4.tres"),
		},
		# Antidote not implemented; intentionally absent
	}

func is_initialized() -> bool:
	return character_keys[FORTUNE].size() > 0

func init_starters() -> void:
	character_keys = {
		FORTUNE: ["pierce", "lucky_charm"],
		CORALLEINE: ["magic_darts", "magic_cannon"],
		UMI: ["bottle_of_heal", "bottle_of_splode"],
	}
	carryover = {
		FORTUNE: "",
		CORALLEINE: "",
		UMI: "",
	}
	shops_completed = 0

func reset() -> void:
	character_keys = {FORTUNE: [], CORALLEINE: [], UMI: []}
	carryover = {FORTUNE: "", CORALLEINE: "", UMI: ""}
	shops_completed = 0

func add_ability(character_id: String, ability_key: String) -> void:
	if ability_key.is_empty():
		return
	if not character_keys[character_id].has(ability_key):
		character_keys[character_id].append(ability_key)

func set_carryover(character_id: String, ability_key: String) -> void:
	carryover[character_id] = ability_key

func get_carryover(character_id: String) -> String:
	return carryover.get(character_id, "")

## Returns ability resource for the key at given level, or null if missing.
## Falls back to the highest level <= requested if exact level missing.
func resolve_ability(ability_key: String, level: int) -> BaseAbility:
	if not ABILITY_REGISTRY.has(ability_key):
		return null
	var levels: Dictionary = ABILITY_REGISTRY[ability_key]
	if levels.has(level):
		return levels[level]
	var available: Array = levels.keys()
	available.sort()
	var best := -1
	for l in available:
		if l <= level:
			best = l
	if best > 0:
		return levels[best]
	return null

## Returns abilities for a character at the given battle level.
func get_abilities_at_level(character_id: String, level: int) -> Array[BaseAbility]:
	var result: Array[BaseAbility] = []
	for key in character_keys.get(character_id, []):
		var ability := resolve_ability(key, level)
		if ability:
			result.append(ability)
	return result

## Maps a character_name (e.g. "Fortune") to internal id key.
static func character_id_from_name(char_name: String) -> String:
	var lower := char_name.to_lower()
	if lower.begins_with("fortune"):
		return FORTUNE
	if lower.begins_with("coral"):
		return CORALLEINE
	if lower.begins_with("umi"):
		return UMI
	return ""
