/// Attack something which is already adjacent to us, without ending planning
/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/opportunistic
	melee_attack_behavior = /bt_behavior/basic_melee_attack/opportunistic
	end_planning = FALSE	
	var/travelling


///If on this, clears the walk travel target upon first contact with enemy
/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/opportunistic/event_loc
	travelling = BB_TRAVEL_DESTINATION


/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/opportunistic/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, seconds_per_tick)
	. = ..()
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target) || !controller.pawn.Adjacent(target))
		return
	if (isliving(controller.pawn))
		var/mob/living/pawn = controller.pawn
		if (LAZYLEN(pawn.do_afters))
			return
			
	if(travelling && controller.blackboard[travelling])
		controller.clear_blackboard_key(travelling)
	controller.queue_behavior(melee_attack_behavior, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)


/// Attack something which is already adjacent to us without moving
/bt_behavior/basic_melee_attack/opportunistic
	action_cooldown = 0.2 SECONDS // We gotta check unfortunately often because we're in a race condition with nextmove
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	sidesteps_after = FALSE


/bt_behavior/basic_melee_attack/opportunistic/setup(datum/behavior_tree/node/parallel/root/controller, target_key, targeting_strategy_key, hiding_location_key)
	if (!controller.blackboard_key_exists(targeting_strategy_key))
		CRASH("No target datum was supplied in the blackboard for [controller.pawn]")
	return controller.blackboard_key_exists(target_key)


/bt_behavior/basic_melee_attack/opportunistic/perform(seconds_per_tick, datum/behavior_tree/node/parallel/root/controller, target_key, targeting_strategy_key, hiding_location_key)
	var/atom/movable/atom_pawn = controller.pawn
	if(!atom_pawn.CanReach(controller.blackboard[target_key]))
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED // Don't clear target
	. = ..()
	return . | AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED // Try doing something else
