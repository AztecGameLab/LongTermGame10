extends ScalingStatusEffect
class_name DamageTakenBasedStatusEffect
## Records damage received to be used by triggers or actions.

const DAMAGE_KEY = "stored_damage"

func _setup_container(container: StatusEffectContainer) -> void:
	super._setup_container(container)
	container.custom_state[DAMAGE_KEY] = 0.0

func on_damage_received(context: AttackContext, container: StatusEffectContainer) -> void:
	# Records the final damage value from the attack context
	if container.custom_state.has(DAMAGE_KEY):
		container.custom_state[DAMAGE_KEY] += context.final_damage 

func run_triggers(type: StatusEffectTrigger.Type, container: StatusEffectContainer) -> void:
	# This allows the effect to fire actions (like StoredDamageAction)
	for trigger in triggers:
		if trigger.trigger_type == type and trigger.action:
			await trigger.action.run(ActionContext.new(null, container.target, container.battle, container.source, container))
