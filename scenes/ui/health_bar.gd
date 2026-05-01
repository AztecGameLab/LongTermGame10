extends Control

@onready var parent: BattleCharacter = self.get_parent()
@onready var health: ColorRect = %Health
@onready var status_effect_container: HBoxContainer = %StatusEffectContainer

const HEALING_INDICATOR = preload("uid://byw85r65ecmbx")
const DAMAGE_INDICATOR = preload("uid://klj5y6jekyep")
const STATUS_EFFECT_DISPLAY = preload("uid://bcnnbba8ajdx6")

func _ready() -> void:
	update_display()
	parent.health_updated.connect(_on_character_health_updated)
	parent.healed.connect(_on_healed)
	parent.damaged.connect(_on_damaged)
	
	update_status_effects()
	parent.status_effects_updated.connect(update_status_effects)

func update_display() -> void:
	health.scale.x = float(parent.current_health) / parent.max_health

func _on_character_health_updated(_new_health: int) -> void:
	update_display()
	
func _on_healed(amount: int, _source: BattleCharacter):
	var healing: RichTextLabel = HEALING_INDICATOR.instantiate()
	healing.text = "+" + str(amount)
	add_child(healing)

func _on_damaged(amount: int, _context: AttackContext):
	var damage: RichTextLabel = DAMAGE_INDICATOR.instantiate()
	damage.text = "-" + str(amount)
	add_child(damage)

func update_status_effects() -> void:
	for child in status_effect_container.get_children():
		child.queue_free()
	
	for status_effect in parent.get_all_status_effects().filter(func(s): return s.get_icon()):
		var display: StatusEffectDisplay = STATUS_EFFECT_DISPLAY.instantiate()
		display.container = status_effect
		status_effect_container.add_child(display)
