@tool
extends BaseAbility
class_name MagicCannon

@export var status_effect: MagicCannonStatusEffect;

@export_range(1, 4, 1) var level: int = 1:
	set(value):
		level = value
		notify_property_list_changed() # This is needed to make `_validate_property(...)` update when the level changes.
@export_range(0, 1, 1, "or_greater") var base_damage: int = 10
@export_range(0, 1, 1, "or_greater") var damage_per_cannon_charge = 2

## Audio played when firing the loaded cannon. Falls back to [code]audio[/code] (load sound) if unset.
@export var release_audio: AudioStream

func get_audio(source: BattleCharacter) -> AudioStream:
	var container := source.get_status_effect(status_effect)
	if container != null and release_audio:
		return release_audio
	return audio

func get_label(_source: BattleCharacter) -> String:
	return &"Magic Cannon"
	
func get_description(_source: BattleCharacter) -> String:
	var break_pct := int(round(status_effect.break_chance * 100.0)) if status_effect else 0
	var description := "1st cast loads the cannon. "
	if has_extra_shots():
		description += "Each turn it stays loaded builds 1 charge. "
		description += "2nd cast fires for %d damage plus %d per charge." % [base_damage, damage_per_cannon_charge]
		description += "\nEach incoming hit has a %d%% chance to remove 1 charge, dispelling the cannon if charges drop below 0. Luck makes the chance lower." % break_pct
	else:
		description += "2nd cast fires for %d damage." % base_damage
		description += "\nEach incoming hit has a %d%% chance to dispel the cannon. Luck makes the chance lower." % break_pct
	return description

func get_target_type(source: BattleCharacter) -> BaseAbility.TargetType:
	var container := source.get_status_effect(status_effect)
	if container == null:
		return BaseAbility.TargetType.SELF
	return BaseAbility.TargetType.ENEMY

func get_action(source: BattleCharacter) -> Action:
	var container := source.get_status_effect(status_effect)
	
	var group := GroupAction.new()
	
	if container == null:
		var status_animation := AnimationAction.new()
		status_animation.animation = AnimationAction.Anim.STATUS
		group.actions.append(status_animation)
		
		var apply_status := ApplyStatusAction.new()
		apply_status.status_effect = status_effect
		apply_status.applied_stacks = level
		group.actions.append(apply_status)
		return group
		
	var damage := base_damage
	
	if has_extra_shots():
		damage += damage_per_cannon_charge * MagicCannonStatusEffect._get_state(container)
	
	var animation := AnimationAction.new()
	animation.animation = AnimationAction.Anim.ATTACK
	group.actions.append(animation)
	
	var action := StaticDamageAction.new()
	action.damage = damage
	group.actions.append(action)
	
	var remove_status := RemoveStatusAction.new()
	remove_status.status_effect = status_effect
	remove_status.override_target = true
	remove_status.action_target = TargetType.SELF
	remove_status.remove_stacks = -1
	group.actions.append(remove_status)
	
	return group

func has_extra_shots() -> bool:
	return level >= 3

func _validate_property(property: Dictionary) -> void:
	# Hide the cannon shot property in the inspector if the ability isn't at that level.
	if property.name == "damage_per_cannon_charge":
		if level < 3:
			property.usage = PROPERTY_USAGE_NO_EDITOR
