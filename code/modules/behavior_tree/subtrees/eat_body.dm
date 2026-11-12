/datum/behavior_tree/node/subtree/eat_dead_body
	var/bt_behavior/eat_dead_body/behavior = /bt_behavior/eat_dead_body
	var/corpse_key = BB_BASIC_MOB_CORPSE_TARGET


/datum/behavior_tree/node/subtree/eat_dead_body/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	. = ..()
	var/atom/target = controller.blackboard[corpse_key]
	if(QDELETED(target) || !ismob(target)) //Bodies only
		controller.clear_blackboard_key(corpse_key)
		return FALSE
	var/mob/living/pawn = controller.pawn
	if(pawn.doing)
		return
	controller.queue_behavior(behavior, corpse_key, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	return SUBTREE_RETURN_FINISH_PLANNING //we are going to eat...no distractions.



/datum/behavior_tree/node/subtree/eat_dead_body/bog_troll
	behavior = /bt_behavior/eat_dead_body/bog_troll


/datum/behavior_tree/node/subtree/eat_dead_body/mimic
	behavior = /bt_behavior/eat_dead_body/mimic
