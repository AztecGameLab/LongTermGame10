extends Label

@onready var parent: BattleCharacter = self.get_parent()

var timer: Timer

func _ready() -> void:
	parent.used_ability.connect(_on_character_used_ability)
	timer = Timer.new()
	timer.autostart = false
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timeout)
	add_child(timer)

func _on_character_used_ability(ability: Ability, _targets: Array[BattleCharacter]) -> void:
	text = ability.name
	timer.start()

func _on_timeout() -> void:
	text = ""
