extends Action
class_name ChanceAction

## Base probability of hitting before stat modifications.
@export_range(0.0, 1.0, 0.01) var base_hit_chance: float = 1.0

@export var hit_action: Action

## Optional. If null, nothing happens on miss.
@export var miss_action: Action

func run(caster: Character, target: Character) -> void:
	var accuracy := caster.get_stat(Character.Stat.ACCURACY) if caster else 0.0
	var dodge := target.get_stat(Character.Stat.DODGE)

	var effective_chance := clampf(base_hit_chance + accuracy - dodge, 0.0, 1.0)
	var roll := randf()

	var chosen: Action = hit_action if roll <= effective_chance else miss_action

	if chosen:
		chosen.run(caster, target)
		await chosen.finished
	finished.emit()
