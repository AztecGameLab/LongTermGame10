@abstract
extends Resource
class_name Action

signal finished();

@abstract func run(caster: Character, target: Character);
