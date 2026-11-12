/datum/behavior_tree/node/planner/mirespider
	converted_from = /datum/ai_controller/mirespider

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/target_retaliate,
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,

		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,

		/datum/behavior_tree/node/subtree/simple_self_recovery,
		/datum/behavior_tree/node/subtree/find_food,
		/datum/behavior_tree/node/subtree/eat_food,
		/datum/behavior_tree/node/subtree/being_a_minion/mirespider
	)


/datum/behavior_tree/node/planner/mirespider_lurker
	converted_from = /datum/ai_controller/mirespider_lurker

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree/mirespider_lurker,
		/datum/behavior_tree/node/subtree/find_cocoon_target,
		/datum/behavior_tree/node/subtree/cocoon_target
	)


/datum/behavior_tree/node/planner/mirespider_paralytic
	converted_from = /datum/ai_controller/mirespider_paralytic

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/find_cocoon_target,
		/datum/behavior_tree/node/subtree/cocoon_target,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree
	)


/datum/behavior_tree/node/subtree/being_a_minion/mirespider
	/// Blackboard key where we travel a place
	location_key = BB_TRAVEL_DESTINATION
	/// Who we're following
	follow_target = BB_FOLLOW_TARGET
	/// What do we do in order to travel
	travel_behavior = /bt_behavior/travel_towards/stop_on_arrival


/datum/behavior_tree/node/subtree/being_a_minion/mirespider/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, seconds_per_tick)
	. = ..()
	var/turf/travel = controller.blackboard[BB_TRAVEL_DESTINATION]
	var/mob/living/simple_animal/hostile/rogue/mirespider_lurker/following = controller.blackboard[BB_FOLLOW_TARGET]
	var/mob/living/pawn = controller.pawn

	if (travel)	// Check if travel is defined
		controller.queue_behavior(travel_behavior, BB_TRAVEL_DESTINATION)
		return SUBTREE_RETURN_FINISH_PLANNING	// end here

	else if (following)	// If we're following someone
		var/mob/target = following.ai_bb_get(BB_BASIC_MOB_CURRENT_TARGET)
		following.add_follower(pawn)

		// If the follow target has a target, stop following
		if (target)
			controller.clear_blackboard_key(BB_FOLLOW_TARGET)

		// If too far from the following target, stop following
		else if (get_dist(pawn, following) > 12)
			controller.clear_blackboard_key(BB_FOLLOW_TARGET)

		// Otherwise, continue following
		else
			controller.queue_behavior(/bt_behavior/follow_friend/mirespider, BB_FOLLOW_TARGET)

		return SUBTREE_RETURN_FINISH_PLANNING	// end here
	return	// No travel target and no one to follow, being a minion in other ways


/bt_behavior/follow_friend/mirespider
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM


/bt_behavior/follow_friend/mirespider/setup(datum/behavior_tree/node/parallel/root/controller, target_key)
	. = ..()
	var/mob/living/simple_animal/hostile/rogue/mirespider_lurker/target = controller.blackboard[target_key]
	var/mob/living/simple_animal/hostile/rogue/mirespider_lurker/target_target = target.ai_bb_get(BB_BASIC_MOB_CURRENT_TARGET)

	if (target_target)
		return FALSE

	if (QDELETED(target))
		return FALSE
	set_movement_target(controller, target)


/bt_behavior/follow_friend/mirespider/perform(seconds_per_tick, datum/behavior_tree/node/parallel/root/controller, target_key)
	var/mob/living/simple_animal/hostile/rogue/mirespider_lurker/target = controller.blackboard[target_key]
	var/mob/living/simple_animal/hostile/rogue/mirespider_lurker/target_target = target.ai_bb_get(BB_BASIC_MOB_CURRENT_TARGET)

	if (target_target)
		return AI_BEHAVIOR_DELAY	// Stop following if the target has a target

	if (QDELETED(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	return AI_BEHAVIOR_DELAY


/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree/mirespider_lurker
	ranged_attack_behavior = /bt_behavior/basic_ranged_attack


/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree/mirespider_lurker/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	. = ..()
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return

	if(isliving(target))
		var/mob/living/carbon/L = target
		if(L)
			if(L.stat || L.getBruteLoss() > 500)
				controller.set_blackboard_key(BB_BASIC_MOB_COCOON_TARGET, L)
				controller.queue_behavior(/bt_behavior/cocoon_target, BB_BASIC_MOB_COCOON_TARGET)
				return SUBTREE_RETURN_FINISH_PLANNING

	var/mob/living/simple_animal/hostile/rogue/mirespider_lurker/lurker = controller.pawn
	if (lurker)
		lurker.clear_followers_if_any()

	controller.queue_behavior(ranged_attack_behavior, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	return SUBTREE_RETURN_FINISH_PLANNING


/bt_behavior/cocoon_target
	behavior_flags = AI_BEHAVIOR_REQUIRE_REACH | AI_BEHAVIOR_REQUIRE_MOVEMENT
	action_cooldown = 1 SECONDS


/bt_behavior/cocoon_target/setup(datum/behavior_tree/node/parallel/root/controller, target_key)
	. = ..()
	var/mob/living/target = controller.blackboard[target_key]
	if (!target || QDELETED(target) || !isliving(target))
		return FALSE

	set_movement_target(controller, (target))


/bt_behavior/cocoon_target/perform(seconds_per_tick, datum/behavior_tree/node/parallel/root/controller, target_key)
	var/mob/living/simple_animal/pawn = controller.pawn
	var/mob/living/target = controller.blackboard[target_key]
	if (!target || QDELETED(target) || !isliving(target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	if (istype(target.loc, /obj/structure/spider/cocoon))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

	if (target.stat)
		if (do_after(pawn, 5 SECONDS, FALSE, target))
			if (istype(target.loc, /obj/structure/spider/cocoon))
				return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
			var/turf/T = get_turf(target)
			var/cocoon = new /obj/structure/spider/cocoon(T)
			target.forceMove(cocoon)
			// Very gentle healing effect that restores a lot of bloodloss. Allows the target to break out later.
			target.apply_status_effect(/datum/status_effect/buff/healing/spider_cocoon, 0.25)
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
	return AI_BEHAVIOR_DELAY


/bt_behavior/cocoon_target/finish_action(datum/behavior_tree/node/parallel/root/controller, succeeded, target_key)
	. = ..()
	if(!succeeded)
		controller.clear_blackboard_key(target_key)
	controller.clear_blackboard_key(target_key)


/datum/behavior_tree/node/subtree/cocoon_target
	var/bt_behavior/cocoon_target/behavior = /bt_behavior/cocoon_target


/datum/behavior_tree/node/subtree/cocoon_target/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	. = ..()
	var/obj/item/target = controller.blackboard[BB_BASIC_MOB_COCOON_TARGET]
	if(QDELETED(target))
		controller.clear_blackboard_key(BB_BASIC_MOB_COCOON_TARGET)
		return
	var/mob/living/pawn = controller.pawn
	if(ismob(target) && pawn.faction_check_mob(target, FALSE))
		controller.clear_blackboard_key(BB_BASIC_MOB_COCOON_TARGET)
		return
	if(pawn.doing)
		return
	if(!istype(target, /mob/living/carbon))
		behavior = /bt_behavior/cocoon_target

	controller.queue_behavior(behavior, BB_BASIC_MOB_COCOON_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING


/datum/behavior_tree/node/subtree/find_cocoon_target
	var/vision_range = 6
	var/bt_behavior/find_and_set/cocoon_target/behavior = /bt_behavior/find_and_set/cocoon_target
	var/cocoon_target_key = BB_BASIC_MOB_COCOON_TARGET


/datum/behavior_tree/node/subtree/find_cocoon_target/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, seconds_per_tick)
	. = ..()

	var/atom/target = controller.blackboard[cocoon_target_key]
	if(!QDELETED(target))
		// Busy with something
		return

	controller.queue_behavior(behavior, cocoon_target_key, controller.blackboard[BB_BASIC_FOODS], vision_range)


/bt_behavior/find_and_set/cocoon_target
	action_cooldown = 20 SECONDS


/bt_behavior/find_and_set/cocoon_target/search_tactic(datum/behavior_tree/node/parallel/root/controller, locate_paths, search_range)
	var/list/found = list()
	var/mob/living/pawn = controller.pawn
	for(var/mob/living/carbon/mob in oview(search_range, controller.pawn))
		var/obj/structure/spider/cocoon/cocoon = mob.loc
		if(istype(cocoon, /obj/structure/spider/cocoon))
			continue
		if(mob.stat == DEAD)
			continue
		if(pawn.faction_check_mob(mob, FALSE))
			continue
		if(!mob.stat && mob.getBruteLoss() <= 500)
			continue
		found |= mob
	if(!length(found))
		return null
	return pick(found)
