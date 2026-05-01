extends Resource
class_name StatusEffectStack

## The icon to use for this stack instead of the effect's default.
## Leave empty to use the default.
@export var icon_override: Texture2D

## The description to show when the effect has this stack.
@export_multiline() var description: String

@export var modifiers: Array[StatusEffectModifier]
@export var triggers: Array[StatusEffectTrigger]
