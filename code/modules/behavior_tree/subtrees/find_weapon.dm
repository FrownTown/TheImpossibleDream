/datum/behavior_tree/node/subtree/find_weapon
	var/vision_range = 9


/datum/behavior_tree/node/subtree/find_weapon/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, seconds_per_tick)
	. = ..()
	var/atom/target = controller.blackboard[BB_MOB_EQUIP_TARGET]
	if(!QDELETED(target))
		// Busy with something
		return

	if(ai_npc_has_weapon(controller.pawn))
		return

	controller.queue_behavior(/bt_behavior/find_and_set/better_weapon, BB_MOB_EQUIP_TARGET, null, vision_range)
