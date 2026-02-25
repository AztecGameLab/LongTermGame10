@abstract
extends Resource
class_name Action

signal finished();

@abstract func run(caster: Node2D, target: Node2D);
