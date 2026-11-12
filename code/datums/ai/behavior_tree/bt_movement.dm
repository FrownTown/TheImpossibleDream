GLOBAL_LIST_EMPTY(bt_movements)

/datum/bt_movement
	var/list/moving_controllers = list()
	var/max_pathing_attempts
	var/max_path_distance = 30

/datum/bt_movement/proc/start_moving_towards(datum/behavior_tree/node/parallel/root/controller, atom/current_movement_target, min_distance)
	controller.pathing_attempts = 0
	controller.set_blackboard_key(BB_CURRENT_MIN_MOVE_DISTANCE, min_distance)
	if(!moving_controllers.len)
		START_PROCESSING(SSai_movement, src)
	moving_controllers[controller] = current_movement_target
	controller.moving_towards = current_movement_target

/datum/bt_movement/proc/stop_moving_towards(datum/behavior_tree/node/parallel/root/controller)
	controller.pathing_attempts = 0
	controller.moving_towards = null
	moving_controllers -= controller
	if(!moving_controllers.len)
		STOP_PROCESSING(SSai_movement, src)

/datum/bt_movement/proc/charge_diagonal_step(datum/behavior_tree/node/parallel/root/controller, turf/from)
	if(!from)
		return
	var/turf/landed = get_turf(controller.pawn)
	if(!landed || landed.z != from.z)
		return
	if(landed.x != from.x && landed.y != from.y)
		controller.movement_cooldown += controller.movement_delay
		controller.pawn.set_glide_size(DELAY_TO_GLIDE_SIZE(controller.movement_delay * 2))

/datum/bt_movement/process(delta_time)
	for(var/datum/behavior_tree/node/parallel/root/controller as anything in moving_controllers)
		move_tick(controller)

/datum/bt_movement/proc/move_tick(datum/behavior_tree/node/parallel/root/controller)
	return
/datum/bt_movement/hybrid_pathing
	max_pathing_attempts = 12
	max_path_distance = 30
	var/repath_anticipation_distance = 5
	var/future_path_blackboard_key = BB_FUTURE_MOVEMENT_PATH
	var/max_basic_failures = 3
	var/always_advanced = FALSE

/datum/bt_movement/hybrid_pathing/gnome
	max_path_distance = 100
	max_basic_failures = 2
	always_advanced = TRUE

/datum/bt_movement/hybrid_pathing/move_tick(datum/behavior_tree/node/parallel/root/controller)
	if(!(future_path_blackboard_key in controller.blackboard))
		controller.add_blackboard_key(future_path_blackboard_key, null)
	if(!COOLDOWN_FINISHED(controller, movement_cooldown))
		return
	controller.advance_movement_cooldown()

	if(!controller.can_move())
		return

	var/atom/movable/movable_pawn = controller.pawn

	var/turf/target_turf = get_step_towards(movable_pawn, controller.current_movement_target)
	var/turf/end_turf = get_turf(controller.current_movement_target)
	var/advanced = TRUE
	var/turf/current_turf = get_turf(movable_pawn)

	var/mob/cliented_mob = controller.current_movement_target
	var/cliented = FALSE
	if(istype(cliented_mob))
		if(cliented_mob.client)
			cliented = TRUE

	if(length(controller.movement_path) && controller.movement_path[1])
		var/turf/next_step = controller.movement_path[1]
		if(next_step.z > current_turf.z)
			var/turf/above = GET_TURF_ABOVE(current_turf)
			var/can_go_up = FALSE
			if(above && !above.density)
				for(var/obj/structure/stairs/S in current_turf.contents)
					var/turf/dest = get_step(above, S.dir)
					if(dest == next_step || get_step(dest, S.dir) == next_step)
						can_go_up = TRUE
						break
			if(!can_go_up)
				controller.movement_path = null
				controller.clear_blackboard_key(future_path_blackboard_key)
				if(!isnull(controller.falling_back))
					controller.falling_back = FALSE
				controller.fallback_fail = 0
				return

	// Basic movement for targets on the same z-level with no existing path
	if(end_turf?.z == movable_pawn?.z && !length(controller.movement_path) && !cliented && !always_advanced)
		advanced = FALSE
		var/can_move = controller.can_move()
		var/current_loc = get_turf(movable_pawn)

		if(!is_type_in_typecache(target_turf, GLOB.dangerous_turfs) && can_move)
			step_to(movable_pawn, target_turf, controller.blackboard[BB_CURRENT_MIN_MOVE_DISTANCE])

			if(current_loc != get_turf(movable_pawn))
				charge_diagonal_step(controller, current_loc)
				controller.pathing_attempts = 0
				controller.falling_back = null
				controller.fallback_fail = 0
			else
				controller.pathing_attempts++
				if(controller.pathing_attempts >= max_basic_failures)
					advanced = TRUE
					controller.movement_path = null
					controller.clear_blackboard_key(future_path_blackboard_key)
					controller.falling_back = TRUE
					SEND_SIGNAL(movable_pawn, COMSIG_AI_GENERAL_CHANGE, "Unable to Basic Move after [max_basic_failures] attempts, swapping to AStar.")

				if(controller.pathing_attempts >= max_pathing_attempts)
					controller.CancelActions()
					SEND_SIGNAL(movable_pawn, COMSIG_AI_GENERAL_CHANGE, "Failed pathfinding cancelling.")

	if(!advanced)
		return

	var/minimum_distance = controller.max_target_distance
	for(var/bt_behavior/iter_behavior as anything in controller.current_behaviors)
		if(iter_behavior.required_distance < minimum_distance)
			minimum_distance = iter_behavior.required_distance

	if(get_dist(movable_pawn, controller.current_movement_target) <= minimum_distance)
		return

	var/generate_path = FALSE
	var/list/future_path = controller.blackboard[future_path_blackboard_key]

	if(length(controller.movement_path))
		var/turf/last_turf = controller.movement_path[length(controller.movement_path)]
		var/turf/next_step = controller.movement_path[1]
		var/remaining_path_length = length(controller.movement_path)

		if(next_step.z != movable_pawn.z)
			var/can_transition = FALSE
			if(next_step.z > movable_pawn.z)
				for(var/obj/structure/stairs/S in current_turf.contents)
					var/turf/above = GET_TURF_ABOVE(current_turf)
					if(above)
						var/turf/dest = get_step(above, S.dir)
						if(dest == next_step)
							can_transition = TRUE
							break
			else if(next_step.z < movable_pawn.z)
				var/turf/below = GET_TURF_BELOW(current_turf)
				if(below == next_step)
					can_transition = TRUE
				else
					for(var/obj/structure/stairs/S in current_turf.contents)
						var/turf/dest = get_step(below, turn(S.dir, 180))
						if(dest == next_step)
							can_transition = TRUE
							break

			if(can_transition)
				movable_pawn.Move(next_step)
				charge_diagonal_step(controller, current_turf)
			else
				generate_path = TRUE
				controller.clear_blackboard_key(future_path_blackboard_key)
		else
			var/move_dir = get_dir(movable_pawn, next_step)
			var/stepped = step(movable_pawn, move_dir)
			if(stepped)
				charge_diagonal_step(controller, current_turf)
			if(!stepped && controller.can_climb_structures && world.time >= controller.next_climb_time)
				var/obj/structure/struct_target
				var/obj/machinery/mach_target
				for(var/obj/structure/S in next_step)
					if(S.climbable)
						struct_target = S
						break
				if(!struct_target)
					for(var/obj/machinery/M in next_step)
						if(M.climbable)
							mach_target = M
							break
				if(!struct_target && !mach_target)
					for(var/obj/structure/S in current_turf)
						if(S.climbable)
							struct_target = S
							break
				if(!struct_target && !mach_target)
					for(var/obj/machinery/M in current_turf)
						if(M.climbable)
							mach_target = M
							break
				if(struct_target)
					controller.next_climb_time = world.time + controller.climb_interval
					struct_target.climb_structure(movable_pawn)
				else if(mach_target)
					controller.next_climb_time = world.time + controller.climb_interval
					mach_target.climb_structure(movable_pawn)

		if(QDELETED(controller))
			return

		if(last_turf != get_turf(controller.current_movement_target))
			if(future_path && length(future_path) && future_path[length(future_path)] == get_turf(controller.current_movement_target))
				controller.movement_path = future_path.Copy()
				controller.clear_blackboard_key(future_path_blackboard_key)
				SEND_SIGNAL(controller.pawn, COMSIG_AI_PATH_SWAPPED, controller.movement_path)
			else
				generate_path = TRUE
				controller.clear_blackboard_key(future_path_blackboard_key)

		if(isnull(controller.falling_back))
			controller.falling_back = TRUE
		if(get_turf(movable_pawn) == next_step || (istransparentturf(next_step) && get_turf(movable_pawn) == get_step_multiz(next_step, DOWN)))
			var/path_len = length(controller.movement_path)
			if(path_len)
				var/cuts = 1
				if(path_len >= 2 && get_turf(movable_pawn) == controller.movement_path[2])
					cuts = 2
				controller.movement_path.Cut(1, cuts + 1)

			if(!length(controller.movement_path) && controller.falling_back)
				controller.falling_back = FALSE
				controller.pathing_attempts = 0
		else
			if(!controller.falling_back)
				generate_path = TRUE
				controller.clear_blackboard_key(future_path_blackboard_key)
			else
				controller.fallback_fail++
				if(controller.fallback_fail >= 2)
					controller.fallback_fail = 0
					generate_path = TRUE
					controller.falling_back = FALSE
					controller.clear_blackboard_key(future_path_blackboard_key)

		if(!generate_path && remaining_path_length <= repath_anticipation_distance && !future_path && COOLDOWN_FINISHED(controller, repath_cooldown))
			if(QDELETED(controller.current_movement_target) || controller.current_movement_target.loc == movable_pawn)
				return
			COOLDOWN_START(controller, repath_cooldown, 0.3 SECONDS)
			SSai.path_searches++
			var/list/new_future_path = get_path_to(movable_pawn, controller.current_movement_target, TYPE_PROC_REF(/turf, Heuristic_cardinal_3d),
				max_path_distance + 1, max_path_distance + 1, minimum_distance, id=controller.get_access())
			if(QDELETED(controller))
				return
			if(length(new_future_path) && new_future_path[1] == get_turf(movable_pawn))
				new_future_path.Cut(1, 2)
			controller.set_blackboard_key(future_path_blackboard_key, new_future_path)
			SEND_SIGNAL(controller.pawn, COMSIG_AI_FUTURE_PATH_GENERATED, new_future_path)
	else
		generate_path = TRUE

	if(generate_path)
		if(!COOLDOWN_FINISHED(controller, repath_cooldown))
			return
		controller.pathing_attempts++
		if(controller.pathing_attempts >= max_pathing_attempts)
			controller.CancelActions()
			return
		if(QDELETED(controller.current_movement_target) || controller.current_movement_target.loc == movable_pawn)
			return
		COOLDOWN_START(controller, repath_cooldown, 0.5 SECONDS)
		SSai.path_searches++
		var/list/new_path = get_path_to(movable_pawn, controller.current_movement_target, TYPE_PROC_REF(/turf, Heuristic_cardinal_3d),
			max_path_distance + 1, max_path_distance + 1, minimum_distance, id=controller.get_access())
		if(QDELETED(controller))
			return
		controller.movement_path = new_path
		if(length(controller.movement_path) && controller.movement_path[1] == get_turf(movable_pawn))
			controller.movement_path.Cut(1, 2)
		controller.clear_blackboard_key(future_path_blackboard_key)
		SEND_SIGNAL(controller.pawn, COMSIG_AI_PATH_GENERATED, controller.movement_path)
/datum/bt_movement/astar
	max_pathing_attempts = 4
	max_path_distance = 30

/datum/bt_movement/astar/start_moving_towards(datum/behavior_tree/node/parallel/root/controller, atom/current_movement_target, min_distance)
	controller.movement_path = null
	return ..()

/datum/bt_movement/astar/stop_moving_towards(datum/behavior_tree/node/parallel/root/controller)
	controller.movement_path = null
	return ..()

/datum/bt_movement/astar/move_tick(datum/behavior_tree/node/parallel/root/controller)
	if(!COOLDOWN_FINISHED(controller, movement_cooldown))
		return
	controller.advance_movement_cooldown()

	var/atom/movable/movable_pawn = controller.pawn
	if(!movable_pawn)
		stop_moving_towards(controller)
		return
	if(!controller.can_move())
		return

	var/minimum_distance = controller.max_target_distance
	for(var/bt_behavior/iter_behavior as anything in controller.current_behaviors)
		if(iter_behavior.required_distance < minimum_distance)
			minimum_distance = iter_behavior.required_distance
	if(get_dist(movable_pawn, controller.current_movement_target) <= minimum_distance)
		return

	var/generate_path = FALSE
	if(length(controller.movement_path))
		var/turf/next_step = controller.movement_path[1]
		var/dir_to_move = get_dir(movable_pawn, next_step)
		var/turf/pre_step = get_turf(movable_pawn)
		if(step(movable_pawn, dir_to_move))
			charge_diagonal_step(controller, pre_step)
		if(get_turf(movable_pawn) == next_step && length(controller.movement_path))
			controller.movement_path.Cut(1, 2)
		else
			generate_path = TRUE
	else
		generate_path = TRUE

	if(generate_path)
		if(!COOLDOWN_FINISHED(controller, repath_cooldown))
			return
		controller.pathing_attempts++
		if(controller.pathing_attempts >= max_pathing_attempts)
			controller.CancelActions()
			return
		COOLDOWN_START(controller, repath_cooldown, 2 SECONDS)
		SSai.path_searches++
		var/list/new_path = get_path_to(movable_pawn, controller.current_movement_target, TYPE_PROC_REF(/turf, Heuristic_cardinal_3d), max_path_distance, max_path_distance, minimum_distance, adjacent = TYPE_PROC_REF(/turf, reachableTurftest3d), id=controller.get_access())
		if(QDELETED(controller))
			return
		controller.movement_path = new_path
		if(length(controller.movement_path) && controller.movement_path[1] == get_turf(movable_pawn))
			controller.movement_path.Cut(1, 2)
/datum/bt_movement/basic_avoidance
	max_pathing_attempts = 10

/datum/bt_movement/basic_avoidance/backstep

/datum/bt_movement/basic_avoidance/move_tick(datum/behavior_tree/node/parallel/root/controller)
	if(!COOLDOWN_FINISHED(controller, movement_cooldown))
		return
	controller.advance_movement_cooldown()

	var/atom/movable/movable_pawn = controller.pawn
	if(!controller.can_move())
		return

	var/current_loc = get_turf(movable_pawn)
	var/turf/target_turf = get_step_towards(movable_pawn, controller.current_movement_target)

	if(target_turf?.can_traverse_safely(movable_pawn))
		if(istype(movable_pawn, /mob/living/simple_animal))
			var/dir_to_target = get_dir(current_loc, target_turf)
			var/turf/step_turf = get_step(movable_pawn, dir_to_target)
			var/climbed = FALSE
			for(var/obj/structure/S in step_turf)
				if(S.density && S.climbable)
					S.climb_structure(movable_pawn)
					climbed = TRUE
					break
			if(!climbed)
				for(var/obj/machinery/M in step_turf)
					if(M.density && M.climbable)
						M.climb_structure(movable_pawn)
						break
		step_to(movable_pawn, controller.current_movement_target, controller.blackboard[BB_CURRENT_MIN_MOVE_DISTANCE])

	if(QDELETED(controller))
		return
	if(current_loc == get_turf(movable_pawn))
		controller.pathing_attempts++
		if(controller.pathing_attempts >= max_pathing_attempts)
			controller.CancelActions()
	else
		charge_diagonal_step(controller, current_loc)
/datum/bt_movement/dumb
	max_pathing_attempts = 16

/datum/bt_movement/dumb/move_tick(datum/behavior_tree/node/parallel/root/controller)
	if(!COOLDOWN_FINISHED(controller, movement_cooldown))
		return
	controller.advance_movement_cooldown()
	var/atom/movable/movable_pawn = controller.pawn
	if(!controller.can_move())
		return

	var/current_loc = get_turf(movable_pawn)
	var/turf/target_turf = get_step_towards(movable_pawn, controller.current_movement_target)

	if(target_turf?.can_traverse_safely(movable_pawn))
		movable_pawn.Move(target_turf, get_dir(current_loc, target_turf))

	if(QDELETED(controller))
		return
	if(current_loc == get_turf(movable_pawn))
		controller.pathing_attempts++
		if(controller.pathing_attempts >= max_pathing_attempts)
			controller.CancelActions()
	else
		charge_diagonal_step(controller, current_loc)
