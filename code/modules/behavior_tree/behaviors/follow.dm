/// This behavior involves attacking a target.
/bt_behavior/follow
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM
	required_distance = 1


/bt_behavior/follow/perform(delta_time, datum/behavior_tree/node/parallel/root/controller)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn) || !isturf(living_pawn.loc))
		return AI_BEHAVIOR_DELAY

	var/atom/movable/follow_target = controller.blackboard[BB_FOLLOW_TARGET]
	if(!follow_target || get_dist(living_pawn, follow_target) > controller.blackboard[BB_VISION_RANGE])
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/mob/living/living_target = follow_target
	if(istype(living_target) && (living_target.stat == DEAD))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

	set_movement_target(controller, (living_target))
	return AI_BEHAVIOR_DELAY


/bt_behavior/follow/finish_action(datum/behavior_tree/node/parallel/root/controller, succeeded)
	. = ..()
	controller.clear_blackboard_key(BB_FOLLOW_TARGET)
