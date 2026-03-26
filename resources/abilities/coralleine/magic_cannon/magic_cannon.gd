extends BaseAbility

@export var name: String;
@export_multiline() var description: String;

@export var concentration_effect: MagicCannonStatusEffect;

var can_concentration_be_broken: bool = true

func get_label(_source: BattleCharacter) -> String:
	return name
	
func get_description(_source: BattleCharacter) -> String:
	return description

func get_target_type(_source: BattleCharacter) -> BaseAbility.TargetType:
	return BaseAbility.TargetType.SELF

func get_action(_source: BattleCharacter) -> Action:
	var apply_status := ApplyStatusAction.new()
	apply_status.status_effect = concentration_effect
	return apply_status
