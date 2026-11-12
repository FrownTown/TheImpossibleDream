/**
 * # Targeted Mob Ability
 * Attempts to use a mob's cooldown ability on a target
 */
/bt_behavior/targeted_mob_ability
	action_cooldown = 5 SECONDS


/bt_behavior/targeted_mob_ability/perform(seconds_per_tick, datum/behavior_tree/node/parallel/root/controller, ability_key, target_key)
	//var/obj/effect/proc_holder/spell/ability = controller.blackboard[ability_key]
	var/datum/action/cooldown/ability = controller.blackboard[ability_key]
	var/mob/living/target = controller.blackboard[target_key]
	if(QDELETED(ability) || QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/mob/pawn = controller.pawn
	pawn.face_atom(target)
	ability.set_ai_aim_lock(get_turf(target))
	var/result = ability.Trigger(target = target)
	if(result)
		var/commit = ability.ai_commit_time()
		if(commit > 0)
			controller.set_blackboard_key(BB_ABILITY_COMMITTED_UNTIL, world.time + commit)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

	//var/result = ability.perform(list(target), TRUE, pawn)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

/bt_behavior/targeted_mob_ability/finish_action(datum/behavior_tree/node/parallel/root/controller, succeeded, ability_key, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if (QDELETED(target))
		controller.clear_blackboard_key(target_key)

/**
 * # Try Mob Ability and clear target
 * Attempts to use a mob's cooldown ability on a target and releases the target when the action completes
 */
/bt_behavior/targeted_mob_ability/and_clear_target

/bt_behavior/targeted_mob_ability/and_clear_target/finish_action(datum/behavior_tree/node/parallel/root/controller, succeeded, ability_key, target_key)
	. = ..()
	controller.clear_blackboard_key(target_key)

/bt_behavior/targeted_mob_ability/proc/get_ability_to_use(datum/behavior_tree/node/parallel/root/controller, ability_key)
	return controller.blackboard[ability_key]

/**
 * Attempts to move into the provided range and then use a mob's cooldown ability on a target
 */
/bt_behavior/targeted_mob_ability/min_range
	required_distance = 6
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT
	var/datum/bt_movement/new_movement

/bt_behavior/targeted_mob_ability/min_range/setup(datum/behavior_tree/node/parallel/root/controller, ability_key, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target, new_movement)
