class_name Concurrently

signal _done_signal
var _is_complete: bool = false
var coroutine: Callable
var result: Variant

func fire() -> void:
	result = await coroutine.call()
	_is_complete = true
	_done_signal.emit()

func _init(incoming_coroutine: Callable) -> void:
	coroutine = incoming_coroutine
	fire()


func is_done() -> Variant:
	if not _is_complete:
		await _done_signal
	return result


static func fire_all(funcs: Array[Callable]) -> Array:
	var fired: Array[Concurrently]
	for this_func: Callable in funcs:
		var concurrent_func: Concurrently = Concurrently.new(this_func)
		fired.append(concurrent_func)
	for item: Concurrently in fired:
		await item.is_done()
	return fired
