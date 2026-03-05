extends Resource
class_name StatusEffectStack

@export var modifiers: Array[StatusEffectModifier]
@export var triggers: Array[StatusEffectTrigger]

## The description to show when the effect has this stack.
@export_multiline() var description: String
