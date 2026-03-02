@icon("uid://c8m84g2pnkmb4")
@abstract
extends Resource
class_name Action

signal finished();

@abstract func run(source: Character, target: Character);
