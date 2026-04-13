extends ScalingStatusEffect
class_name DamageTakenBasedStatusEffect
## Records damage received to be used by triggers or actions.

const DAMAGE_KEY = "stored_damage"

## Type of damage recorded
enum DamageType {
	ORIGINAL_DAMAGE,
	TRUE_DAMAGE,
	FINAL_DAMAGE
}

## Whether this effect is positive, negative, or locked (cannot be transferred).
@export var damage_type: DamageType = DamageType.TRUE_DAMAGE

func _setup_container(container: StatusEffectContainer) -> void:
	super._setup_container(container)
	container.custom_state[DAMAGE_KEY] = 0.0

func on_damage_received(context: AttackContext, container: StatusEffectContainer) -> void:
	# Records the final damage value from the attack context
	if damage_type==DamageType.ORIGINAL_DAMAGE:
		container.custom_state[DAMAGE_KEY] += context.original_damage
	if damage_type==DamageType.TRUE_DAMAGE:
		container.custom_state[DAMAGE_KEY] += context.true_damage
	if damage_type==DamageType.FINAL_DAMAGE:
		container.custom_state[DAMAGE_KEY] += context.damage

func run_triggers(type: StatusEffectTrigger.Type, container: StatusEffectContainer) -> void:
	# This allows the effect to fire actions (like StoredDamageAction)
	for trigger in triggers:
		if trigger.trigger_type == type and trigger.action:
			await trigger.action.run(ActionContext.new(null, container.target, container.battle, container.source, container))
