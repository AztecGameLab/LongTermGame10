extends Node2D
class_name Character

@export_group("Stats")
@export var max_health: int = 10

@export_group("battle")
@export var status_effects: Array[StatusEffect]

var current_health: int

func _ready() -> void:
	current_health = max_health

func damage(damage_amount):
	pass


func die():
	queue_free()
