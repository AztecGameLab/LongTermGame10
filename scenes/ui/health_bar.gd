extends Control

@onready var parent: BattleCharacter = self.get_parent()
@onready var health: ColorRect = %Health
@onready var status_effect_container: HBoxContainer = %StatusEffectContainer

const HEALING_INDICATOR = preload("uid://byw85r65ecmbx")
const DAMAGE_INDICATOR = preload("uid://klj5y6jekyep")
const MISS_INDICATOR = preload("res://scenes/ui/miss_indicator.tscn")
const STATUS_EFFECT_DISPLAY = preload("uid://bcnnbba8ajdx6")

## Minimum seconds between consecutive indicators on this health bar.
const INDICATOR_MIN_GAP: float = 0.25

var _last_indicator_time: float = 0.0

func _ready() -> void:
	update_display()
	parent.health_updated.connect(_on_character_health_updated)
	parent.healed.connect(_on_healed)
	parent.damaged.connect(_on_damaged)
	parent.missed.connect(_on_missed)

	update_status_effects()
	parent.status_effects_updated.connect(update_status_effects)

func update_display() -> void:
	health.scale.x = float(parent.current_health) / parent.max_health

func _on_character_health_updated(_new_health: int) -> void:
	update_display()

func _on_healed(amount: int, _source: BattleCharacter):
	_show_indicator(HEALING_INDICATOR, "+" + str(amount))

func _on_damaged(amount: int, _context: AttackContext):
	_show_indicator(DAMAGE_INDICATOR, "-" + str(amount))

func _on_missed():
	_show_indicator(MISS_INDICATOR, "Miss")

## Schedules an indicator so consecutive ones are spaced by at least [code]INDICATOR_MIN_GAP[/code] seconds.
func _show_indicator(scene: PackedScene, text: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var scheduled := maxf(now, _last_indicator_time + INDICATOR_MIN_GAP)
	var delay := scheduled - now
	_last_indicator_time = scheduled
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	var indicator: RichTextLabel = scene.instantiate()
	indicator.text = text
	add_child(indicator)

func update_status_effects() -> void:
	for child in status_effect_container.get_children():
		child.queue_free()
	
	for status_effect in parent.get_all_status_effects().filter(func(s): return s.get_icon()):
		var display: StatusEffectDisplay = STATUS_EFFECT_DISPLAY.instantiate()
		display.container = status_effect
		status_effect_container.add_child(display)
