/bt_behavior/perform_emote


/bt_behavior/perform_emote/perform(delta_time, datum/behavior_tree/node/parallel/root/controller, emote)
	var/mob/living/living_pawn = controller.pawn
	if(!istype(living_pawn))
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_FAILED
	living_pawn.emote(emote)
	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED
