/bt_behavior/equip_target
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH


/bt_behavior/equip_target/setup(datum/behavior_tree/node/parallel/root/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)


/bt_behavior/equip_target/perform(seconds_per_tick, datum/behavior_tree/node/parallel/root/controller, target_key)
	var/obj/item/target = controller.blackboard[target_key]
	var/mob/living/carbon/human/pawn = controller.pawn
	if(pawn.incapacitated())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(!isturf(target.loc))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(pawn.put_in_hands(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED


/bt_behavior/equip_target/finish_action(datum/behavior_tree/node/parallel/root/controller, succeeded, target_key)
	. = ..()
	controller.clear_blackboard_key(target_key)
