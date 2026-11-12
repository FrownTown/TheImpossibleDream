/datum/behavior_tree/node/subtree/generic_resist/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, seconds_per_tick)
	var/mob/living/living_pawn = controller.pawn

	if(controller.blackboard[BB_RESISTING])
		controller.queue_behavior(/bt_behavior/resist)
		if(isliving(living_pawn.pulledby))
			controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, living_pawn.pulledby)
			controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, living_pawn.pulledby)
		return // Don't block planning — melee and kick subtrees run after this.
	if(SHOULD_RESIST(living_pawn))
		controller.queue_behavior(/bt_behavior/resist)
		if(isliving(living_pawn.pulledby))
			controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, living_pawn.pulledby)
			controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, living_pawn.pulledby)
		return // Resist + fight, don't block combat.


/bt_behavior/resist/perform(seconds_per_tick, datum/behavior_tree/node/parallel/root/controller)
	var/mob/living/living_pawn = controller.pawn
	living_pawn.ai_bb_set(BB_RESISTING, TRUE)
	living_pawn.execute_resist()
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED


/bt_behavior/resist/finish_action(datum/behavior_tree/node/parallel/root/controller, succeeded, ...)
	. = ..()
	var/mob/living/living_pawn = controller.pawn
	if(QDELETED(living_pawn))
		return
	if(SHOULD_RESIST(living_pawn))
		living_pawn.ai_bb_set(BB_RESISTING, TRUE)
	else
		living_pawn.ai_bb_set(BB_RESISTING, FALSE)
