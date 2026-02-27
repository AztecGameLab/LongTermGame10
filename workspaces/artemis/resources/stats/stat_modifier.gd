extends Resource
class_name StatModifier

enum Operation {
	## result = current + value
	ADD,
	## result = current * value
	MULTIPLY,
	## result = current + (current * value). Use 0.25 for +25%.
	ADD_PERCENT,
}

## Which stat this modifier affects.
@export var stat: Character.Stat

@export var operation: Operation = Operation.ADD
@export var value: float = 0.0

func apply(current_value: float) -> float:
	match operation:
		Operation.ADD:
			return current_value + value
		Operation.MULTIPLY:
			return current_value * value
		Operation.ADD_PERCENT:
			return current_value + (current_value * value)
	return current_value
