extends TargetAction
class_name DamageTakenBasedAttackAction
## Deals damage based on the accumulated value in a DamageTakenBasedStatusEffect.

@export var reflection_multiplier_per_stack: float = 0.01
@export var clear_damage_after_use: bool = true

func run(context: ActionContext) -> void:
	# Retrieve the container from the context
	var container = context.status_container
	
	# Verify the container exists and has the expected damage key
	if not container or not container.custom_state.has(DamageTakenBasedStatusEffect.DAMAGE_KEY):
		return
		
	# Get the stored damage and apply the multiplier
	var stored_damage = container.custom_state[DamageTakenBasedStatusEffect.DAMAGE_KEY]
	var stack_count := context.container.stacks if context.container else 1
	var total_damage := (int)(stored_damage * reflection_multiplier_per_stack * stack_count)
	
	if total_damage <= 0:
		return

	# Apply damage to all resolved targets
	for target in resolve_targets(context):
		BattleManager.apply_damage(total_damage, context.source, target)
	
	# Clear the buffer after reflecting
	if clear_damage_after_use:
		container.custom_state[DamageTakenBasedStatusEffect.DAMAGE_KEY] = 0.0
