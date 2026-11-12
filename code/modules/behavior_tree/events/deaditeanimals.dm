#define BB_DEADITE_MIGRATION_PATH "deadite_migration_path"

#define BB_DEADITE_MIGRATION_TARGET "deadite_migration_target"

#define BB_DEADITE_TRAVEL_TARGET "deadite_travel_target"


/bt_behavior/find_next_deadite_migration_step
	action_cooldown = 3 SECONDS


/bt_behavior/find_next_deadite_migration_step/setup(datum/behavior_tree/node/parallel/root/controller, path_key, target_key)
	. = ..()


/bt_behavior/find_next_deadite_migration_step/perform(seconds_per_tick, datum/behavior_tree/node/parallel/root/controller, path_key, target_key)
	if(controller.blackboard[BB_DEADITE_TRAVEL_TARGET])
		//Safety check that will crash the behavior if we SOMEHOW end up here whilst we have a travel behavior going (bad)
		//This will also make any mobs that have been sufficiently distracted far enough from the migration path to stop following it.
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/list/path = controller.blackboard[path_key]
	if(!LAZYLEN(path))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/atom/current_blackboard_target = controller.blackboard[target_key]
	var/current_index = 0

	for(var/i in 1 to LAZYLEN(path))
		var/datum/weakref/ref = path[i]
		if(ref.resolve() == current_blackboard_target)
			current_index = i
			break

	var/target_path_index = 0
	if(current_index == 0)
		target_path_index = 1
	else
		target_path_index = current_index + 1

	target_path_index = min(target_path_index, LAZYLEN(path))

	var/datum/weakref/next_ref = path[target_path_index]
	var/turf/next_turf = next_ref.resolve()

	if(QDELETED(next_turf))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	controller.set_blackboard_key(target_key, next_turf)
	controller.set_blackboard_key(BB_DEADITE_TRAVEL_TARGET, next_turf)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED


/datum/behavior_tree/node/subtree/deadite_migration
	var/travel_behavior = /bt_behavior/travel_towards/stop_on_arrival


/datum/behavior_tree/node/subtree/deadite_migration/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, seconds_per_tick)
	. = ..()

	var/turf/migration_target_turf = controller.blackboard[BB_DEADITE_MIGRATION_TARGET]
	var/list/migration_path = controller.blackboard[BB_DEADITE_MIGRATION_PATH]
	var/turf/mob_turf = get_turf(controller.pawn)
	var/current_distance = get_dist(mob_turf, migration_target_turf)
	var/at_current_target = FALSE

	if(migration_target_turf && current_distance == 0)
		at_current_target = TRUE

	//If we have a target that's valid, we're not yet there, and the travel behavior hasn't finished the last point yet.
	if(migration_target_turf && !QDELETED(migration_target_turf) && !at_current_target && controller.blackboard[BB_DEADITE_TRAVEL_TARGET])
		controller.queue_behavior(travel_behavior, BB_DEADITE_TRAVEL_TARGET)
		return SUBTREE_RETURN_FINISH_PLANNING

	else
		var/current_index = 0
		if(migration_target_turf)
			for(var/i in 1 to LAZYLEN(migration_path))
				var/datum/weakref/ref = migration_path[i]
				if(ref.resolve() == migration_target_turf)
					current_index = i
					break

		if(current_index == LAZYLEN(migration_path) && LAZYLEN(migration_path) > 0)
			controller.clear_blackboard_key(BB_DEADITE_MIGRATION_PATH)
			controller.clear_blackboard_key(BB_DEADITE_MIGRATION_TARGET)
			controller.replace_planning_subtrees(initial(controller.planner.my_nodes))
			return SUBTREE_RETURN_FINISH_PLANNING

		else if(LAZYLEN(migration_path))
			controller.queue_behavior(/bt_behavior/find_next_deadite_migration_step,
				BB_DEADITE_MIGRATION_PATH,
				BB_DEADITE_MIGRATION_TARGET)
			return SUBTREE_RETURN_FINISH_PLANNING

		return SUBTREE_RETURN_FINISH_PLANNING


#undef BB_DEADITE_MIGRATION_PATH

#undef BB_DEADITE_MIGRATION_TARGET

#undef BB_DEADITE_TRAVEL_TARGET
