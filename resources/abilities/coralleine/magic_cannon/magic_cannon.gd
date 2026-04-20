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

func get_label(_source: BattleCharacter) -> String:
	return &"Magic Cannon"
	
func get_description(_source: BattleCharacter) -> String:
	var description := &"Take one turn to charge the spell. Use it a second time to deal high damage."
	if has_extra_shots():
		description += &"\nEvery turn you don't activate it, you gain one extra cannon shot worth a small amount of damage."
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
	group.actions.append(remove_status)
	
	return group

func has_extra_shots() -> bool:
	return level >= 3

func _validate_property(property: Dictionary) -> void:
	# Hide the cannon shot property in the inspector if the ability isn't at that level.
	if property.name == "damage_per_cannon_charge":
		if level < 3:
			property.usage = PROPERTY_USAGE_NO_EDITOR
