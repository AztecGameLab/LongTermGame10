extends Action
class_name ChanceAction

## Biases the chance towards success or failure.[br]
## -1.0 = guaranteed fail, 0.0 = 50/50, 1.0 = guaranteed success.
## Can be modified by status effects through luck.
@export_range(-1.0, 1.0, 0.05) var default_bias: float = 0.0

@export var success_action: Action

## Optional. If null, nothing happens on miss.
@export var fail_action: Action

func run(source: Character, target: Character) -> void:

	var success_bias := default_bias
	if source:
		success_bias = source.get_modified_field(StatusEffectModifier.FIELD.OUTGOING_LUCK, default_bias)
	
	var success: bool = RNG.binary_with_bias(success_bias)

	var action: Action = success_action if success else fail_action

	if action:
		action.run(source, target)
		await action.finished
	finished.emit()
