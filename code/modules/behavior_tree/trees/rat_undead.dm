#define BB_RAT_SUMMON_READY "rat_summon_ready"


/datum/behavior_tree/node/planner/rat/undead
	converted_from = /datum/ai_controller/rat/undead
	ai_movement = /datum/bt_movement/hybrid_pathing
	idle_behavior = /bt_idle_behavior/idle_random_walk

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items(),
		BB_RAT_SUMMON_READY = TRUE // Checked before summoning. Offspring will have this initialized to FALSE.
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/simple_find_target/closest,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/summon_rat,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
	)


/datum/behavior_tree/node/planner/rat/undead/summoned
	converted_from = /datum/ai_controller/rat/undead/summoned
	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/simple_find_target/closest,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
	)


/datum/behavior_tree/node/subtree/summon_rat


/datum/behavior_tree/node/subtree/summon_rat/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, seconds_per_tick)
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return
	if(!controller.blackboard[BB_RAT_SUMMON_READY])
		return
	controller.queue_behavior(/bt_behavior/summon_rat, BB_BASIC_MOB_CURRENT_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING


/bt_behavior/summon_rat
	var/summon_windup = 0.5 SECONDS


/bt_behavior/summon_rat/perform(seconds_per_tick, datum/behavior_tree/node/parallel/root/controller, target_key)
	var/mob/living/simple_animal/summoner = controller.pawn
	var/atom/target = controller.blackboard[target_key]

	if(QDELETED(target) || summoner.buckled || summoner.incapacitated())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	// Instantly consume the summon charge so it can't be spammed during windup
	controller.set_blackboard_key(BB_RAT_SUMMON_READY, FALSE)

	if(do_after(summoner, summon_windup))
		summoner.visible_message(span_danger("<b>[summoner]</b> lets out a sickening screech, calling forth reinforcements!"))
		playsound(summoner, 'sound/magic/slimesquish.ogg', 75, TRUE)

		// Find an open adjacent turf to place the phantom
		var/turf/origin = get_turf(summoner)
		var/turf/spawn_turf
		var/list/dirs = GLOB.alldirs.Copy()

		while(length(dirs))
			var/picked_dir = pick_n_take(dirs)
			var/turf/T = get_step(origin, picked_dir)
			if(T && !T.is_blocked_turf(exclude_mobs = TRUE))
				spawn_turf = T
				break

		// Fallback to origin turf if all surrounding tiles are completely blocked
		if(!spawn_turf)
			spawn_turf = origin

		// Initialize the phantom with our target mob, no rot path, and custom 5 second delay
		new /obj/effect/temp_visual/hunting_phantom(spawn_turf, /mob/living/simple_animal/hostile/retaliate/rogue/bigrat/undead/summoned, null, 5 SECONDS)
	else
		// We got cancelled by something, try again.
		controller.set_blackboard_key(BB_RAT_SUMMON_READY, TRUE)

	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED


#undef BB_RAT_SUMMON_READY
