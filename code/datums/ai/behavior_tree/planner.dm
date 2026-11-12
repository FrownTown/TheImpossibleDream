GLOBAL_LIST_EMPTY(bt_behaviors)
GLOBAL_LIST_EMPTY(bt_idle_behaviors)
GLOBAL_LIST_EMPTY(bt_subtrees)

/datum/behavior_tree/node/planner
	var/list/my_nodes = list()
	var/idle_behavior
	var/ai_movement = /datum/bt_movement/dumb
	var/list/initial_blackboard
	var/converted_from
	var/max_target_distance = 14
	var/can_climb_structures = TRUE
	var/climb_interval = 10 SECONDS
	var/continue_processing_when_client = FALSE
	var/can_idle = TRUE
	var/interesting_dist = AI_DEFAULT_INTERESTING_DIST

/datum/behavior_tree/node/planner/New()
	..()
	var/list/shared = list()
	for(var/type in my_nodes)
		shared += GET_BT_SUBTREE(type)
	my_nodes = shared
	if(idle_behavior)
		idle_behavior = GET_BT_IDLE_BEHAVIOR(idle_behavior)

/datum/behavior_tree/node/planner/Destroy()
	my_nodes = null
	return ..()

/datum/behavior_tree/node/planner/evaluate(mob/living/npc, atom/target, list/blackboard)
	return NODE_SUCCESS

/datum/behavior_tree/node/subtree

/datum/behavior_tree/node/subtree/evaluate(mob/living/npc, atom/target, list/blackboard)
	return NODE_FAILURE

/datum/behavior_tree/node/subtree/proc/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	return
/bt_behavior
	parent_type = /datum
	///What distance you need to be from the target to perform the action
	var/required_distance = 1
	var/behavior_flags = NONE
	///Cooldown between actions performances
	var/action_cooldown = 0

/bt_behavior/proc/setup(datum/behavior_tree/node/parallel/root/controller, ...)
	return TRUE

/bt_behavior/proc/get_cooldown(datum/behavior_tree/node/parallel/root/cooldown_for)
	return action_cooldown

/bt_behavior/proc/perform(delta_time, datum/behavior_tree/node/parallel/root/controller, ...)
	return

/bt_behavior/proc/finish_action(datum/behavior_tree/node/parallel/root/controller, succeeded, ...)
	LAZYREMOVE(controller.current_behaviors, src)
	controller.behavior_args -= type
	if(behavior_flags & AI_BEHAVIOR_REQUIRE_MOVEMENT)
		if(!(behavior_flags & AI_BEHAVIOR_KEEP_MOVE_TARGET_ON_FINISH))
			clear_movement_target(controller)
		if(!(behavior_flags & AI_BEHAVIOR_KEEP_MOVING_TOWARDS_TARGET_ON_FINISH))
			controller.ai_movement.stop_moving_towards(controller)

/bt_behavior/proc/set_movement_target(datum/behavior_tree/node/parallel/root/controller, atom/target, datum/bt_movement/new_movement)
	controller.set_movement_target(type, target, new_movement)

/bt_behavior/proc/clear_movement_target(datum/behavior_tree/node/parallel/root/controller)
	if(controller.movement_target_source != type || QDELETED(controller.pawn))
		return
	controller.set_movement_target(type, controller.pawn.loc)

/bt_idle_behavior
	parent_type = /datum

/bt_idle_behavior/proc/perform_idle_behavior(delta_time, datum/behavior_tree/node/parallel/root/controller)
	return
/datum/behavior_tree/node/parallel/root
	var/mob/living/pawn
	var/datum/behavior_tree/node/planner/planner

	var/list/current_behaviors
	var/list/planned_behaviors
	var/list/behavior_cooldowns = list()
	var/list/running_behaviors = list()
	var/list/behavior_args = list()
	var/failed_planning_cooldown = 0
	var/paused_until = 0
	var/failed_sneak_check = 0
	var/continue_processing_when_client = FALSE
	var/ai_traits

	var/datum/bt_movement/ai_movement
	var/atom/current_movement_target
	var/movement_target_source
	var/atom/moving_towards
	var/list/movement_path
	var/pathing_attempts = 0
	var/movement_cooldown = 0
	var/movement_delay = 0.1 SECONDS
	var/repath_cooldown = 0
	var/max_target_distance = 14
	var/can_climb_structures = TRUE
	var/next_climb_time = 0
	var/climb_interval = 10 SECONDS
	var/movement_started = 0
	var/falling_back
	var/fallback_fail = 0

/datum/behavior_tree/node/parallel/root/proc/setup_planner(typepath, mob/living/owner)
	pawn = owner
	planner = new typepath()
	main_node = planner
	my_nodes = list(planner)
	ai_movement = GET_BT_MOVEMENT(planner.ai_movement)
	blackboard = list()
	for(var/key in planner.initial_blackboard)
		blackboard[key] = planner.initial_blackboard[key]
	max_target_distance = planner.max_target_distance
	can_climb_structures = planner.can_climb_structures
	climb_interval = planner.climb_interval
	continue_processing_when_client = planner.continue_processing_when_client
	can_idle = planner.can_idle
	interesting_dist = planner.interesting_dist
	RegisterSignal(owner, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_pawn_attacked))
	RegisterSignal(owner, COMSIG_MOB_MOVESPEED_UPDATED, PROC_REF(on_movespeed_updated))
	owner.update_move_intent_slowdown()
	recalculate_movement_delay()

/datum/behavior_tree/node/parallel/root/proc/on_pawn_attacked(mob/living/source, atom/attacker, damage)
	SIGNAL_HANDLER
	blackboard[BB_LAST_HIT_TIME] = world.time
	wake_for_combat()

/datum/behavior_tree/node/parallel/root/proc/on_movespeed_updated(mob/living/source)
	SIGNAL_HANDLER
	recalculate_movement_delay()

/datum/behavior_tree/node/parallel/root/Destroy()
	if(planner)
		if(pawn)
			UnregisterSignal(pawn, list(COMSIG_ATOM_WAS_ATTACKED, COMSIG_MOB_MOVESPEED_UPDATED))
		stop_planner()
		CancelActions()
		ai_movement?.stop_moving_towards(src)
		halt_movement()
		planner = null
	pawn = null
	return ..()

/datum/behavior_tree/node/parallel/root/proc/recalculate_movement_delay()
	movement_delay = CEILING(max(pawn.cached_multiplicative_slowdown, SIMPLEMOB_MINIMUM_MOVE_DELAY), SSai_movement.wait)

/datum/behavior_tree/node/parallel/root/proc/advance_movement_cooldown()
	movement_cooldown += movement_delay
	if(movement_cooldown < world.time)
		movement_cooldown = world.time + movement_delay

/datum/behavior_tree/node/parallel/root/proc/able_to_run()
	if(world.time < paused_until)
		return FALSE
	if(pawn.stat >= UNCONSCIOUS)
		return FALSE
	return TRUE

/datum/behavior_tree/node/parallel/root/proc/PauseAi(time)
	paused_until = world.time + time

/datum/behavior_tree/node/parallel/root/proc/can_move()
	if(QDELETED(pawn))
		return
	if(pawn.client && !continue_processing_when_client)
		return FALSE
	if(pawn.incapacitated())
		return FALSE
	if(ai_traits & STOP_MOVING_WHEN_PULLED && pawn.pulledby)
		return FALSE
	if(!isturf(pawn.loc))
		return FALSE
	if(!(pawn.mobility_flags & MOBILITY_MOVE))
		return FALSE
	if(pawn.pulledby?.grab_state > GRAB_PASSIVE)
		return FALSE
	return TRUE

/datum/behavior_tree/node/parallel/root/proc/get_access()
	return

/datum/behavior_tree/node/parallel/root/proc/nudge_target_scan()
	for(var/bt_behavior/behavior as anything in behavior_cooldowns)
		if(behavior.bt_is_target_scan())
			behavior_cooldowns[behavior] = world.time

/bt_behavior/proc/bt_is_target_scan()
	return FALSE

/bt_behavior/find_potential_targets/bt_is_target_scan()
	return TRUE

/bt_behavior/find_aggro_targets/bt_is_target_scan()
	return TRUE

/datum/behavior_tree/node/parallel/root/proc/modify_cooldown(bt_behavior/behavior, new_cooldown)
	behavior_cooldowns[behavior] = new_cooldown
/datum/behavior_tree/node/parallel/root/proc/able_to_plan()
	. = TRUE
	for(var/bt_behavior/current_behavior as anything in current_behaviors)
		if(!(current_behavior.behavior_flags & AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION))
			return FALSE

/datum/behavior_tree/node/parallel/root/proc/plan_tick(delta_time)
	if(!COOLDOWN_FINISHED(src, failed_planning_cooldown))
		return
	if(!able_to_plan())
		return
	SelectBehaviors(delta_time)
	if(!LAZYLEN(current_behaviors))
		failed_planning_cooldown = world.time + AI_FAILED_PLANNING_COOLDOWN

/datum/behavior_tree/node/parallel/root/proc/SelectBehaviors(delta_time)
	SHOULD_NOT_SLEEP(TRUE)
	LAZYINITLIST(current_behaviors)
	LAZYCLEARLIST(planned_behaviors)

	for(var/datum/behavior_tree/node/subtree/subtree as anything in planner.my_nodes)
		if(subtree.SelectBehaviors(src, delta_time) == SUBTREE_RETURN_FINISH_PLANNING)
			break

	for(var/bt_behavior/current_behavior as anything in current_behaviors)
		if(LAZYACCESS(planned_behaviors, current_behavior))
			continue
		var/list/arguments = list(src, FALSE)
		var/list/stored_arguments = behavior_args[type]
		if(stored_arguments)
			arguments += stored_arguments
		current_behavior.finish_action(arglist(arguments))

/datum/behavior_tree/node/parallel/root/proc/queue_behavior(behavior_type, ...)
	var/bt_behavior/behavior = GET_BT_BEHAVIOR(behavior_type)
	if(!behavior)
		CRASH("Behavior [behavior_type] not found.")
	var/list/arguments = args.Copy()
	arguments[1] = src

	if(LAZYACCESS(current_behaviors, behavior))
		LAZYADDASSOCLIST(planned_behaviors, behavior, TRUE)
		return

	if(!behavior.setup(arglist(arguments)))
		return

	LAZYADDASSOCLIST(current_behaviors, behavior, TRUE)
	LAZYADDASSOCLIST(planned_behaviors, behavior, TRUE)

	arguments.Cut(1, 2)
	if(length(arguments))
		behavior_args[behavior_type] = arguments
	else
		behavior_args -= behavior_type

/datum/behavior_tree/node/parallel/root/process(delta_time)
	if(ai_status == AI_STATUS_IDLE && !LAZYLEN(current_behaviors) && !planner?.idle_behavior && world.time >= paused_until)
		return
	process_tick(delta_time)

/datum/behavior_tree/node/parallel/root/proc/process_tick(delta_time)
	if(!able_to_run())
		walk(pawn, 0)
		return

	if(!LAZYLEN(current_behaviors) && ai_status == AI_STATUS_ON && should_idle())
		set_ai_status(AI_STATUS_IDLE)
		return

	if(!LAZYLEN(current_behaviors) && planner.idle_behavior)
		var/bt_idle_behavior/idle = planner.idle_behavior
		idle.perform_idle_behavior(delta_time, src)
		return

	for(var/bt_behavior/current_behavior as anything in current_behaviors)
		if(!(current_behavior.behavior_flags & AI_BEHAVIOR_EXECUTE_ALONGSIDE))
			continue
		if(behavior_cooldowns[current_behavior] > world.time)
			continue
		ProcessBehavior(max(current_behavior.get_cooldown(src) * 0.1, delta_time), current_behavior)

	for(var/bt_behavior/current_behavior as anything in current_behaviors)
		if(current_behavior.behavior_flags & AI_BEHAVIOR_REQUIRE_MOVEMENT)
			if(isnull(current_movement_target))
				fail_behavior(current_behavior)
				return

			var/mob/living/moving_pawn = pawn
			var/obj/item/held_for_reach = null
			if(iscarbon(moving_pawn))
				var/mob/living/carbon/carbon_pawn = moving_pawn
				held_for_reach = carbon_pawn.get_active_held_item()
			var/can_reach = !(current_behavior.behavior_flags & AI_BEHAVIOR_REQUIRE_REACH) || moving_pawn.CanReach(current_movement_target, held_for_reach)

			if(isliving(current_movement_target))
				var/mob/living/living_target = current_movement_target
				if(living_target.rogue_sneaking)
					if(!moving_pawn.npc_detect_sneak(living_target, 0))
						failed_sneak_check++
				else
					failed_sneak_check = 0

			if(prob(8))
				moving_pawn.emote("cidle")

			var/effective_required_distance = current_behavior.required_distance
			if(iscarbon(moving_pawn) && isliving(current_movement_target))
				var/mob/living/carbon/carbon_pawn = moving_pawn
				var/intent_reach = carbon_pawn.used_intent?.reach || 1
				if(intent_reach > effective_required_distance)
					effective_required_distance = intent_reach
			if(((can_reach && effective_required_distance >= get_dist(moving_pawn, current_movement_target))) || failed_sneak_check > 4)
				if(moving_towards == current_movement_target)
					ai_movement.stop_moving_towards(src)

				if(failed_sneak_check > 4)
					ai_movement.stop_moving_towards(src)
				failed_sneak_check = 0

				if(behavior_cooldowns[current_behavior] > world.time)
					continue
				ProcessBehavior(max(current_behavior.get_cooldown(src) * 0.1, delta_time), current_behavior)
				return

			else if(moving_towards != current_movement_target)
				ai_movement.start_moving_towards(src, current_movement_target)

			if(current_behavior.behavior_flags & AI_BEHAVIOR_MOVE_AND_PERFORM)
				if(behavior_cooldowns[current_behavior] > world.time)
					continue
				ProcessBehavior(max(current_behavior.get_cooldown(src) * 0.1, delta_time), current_behavior)
				return
		else
			if(behavior_cooldowns[current_behavior] > world.time)
				continue
			ProcessBehavior(max(current_behavior.get_cooldown(src) * 0.1, delta_time), current_behavior)
			return

/datum/behavior_tree/node/parallel/root/proc/ProcessBehavior(delta_time, bt_behavior/behavior)
	if(pawn.doing)
		return
	var/list/arguments = list(delta_time, src)
	var/list/stored_arguments = behavior_args[behavior.type]
	if(stored_arguments)
		arguments += stored_arguments

	var/entered_at = running_behaviors[behavior]
	if(entered_at && world.time - entered_at < AI_BEHAVIOR_REENTRY_TIMEOUT)
		return
	running_behaviors[behavior] = world.time
	var/process_flags = behavior.perform(arglist(arguments))
	if(QDELETED(src))
		return
	running_behaviors -= behavior

	if(process_flags & AI_BEHAVIOR_DELAY)
		behavior_cooldowns[behavior] = world.time + behavior.get_cooldown(src)
	if(process_flags & AI_BEHAVIOR_FAILED)
		arguments[1] = src
		arguments[2] = FALSE
		behavior.finish_action(arglist(arguments))
	else if(process_flags & AI_BEHAVIOR_SUCCEEDED)
		arguments[1] = src
		arguments[2] = TRUE
		behavior.finish_action(arglist(arguments))

/datum/behavior_tree/node/parallel/root/proc/CancelActions()
	if(!LAZYLEN(current_behaviors))
		return
	for(var/bt_behavior/current_behavior as anything in current_behaviors)
		fail_behavior(current_behavior)

/datum/behavior_tree/node/parallel/root/proc/fail_behavior(bt_behavior/current_behavior)
	var/list/arguments = list(src, FALSE)
	var/list/stored_arguments = behavior_args[current_behavior.type]
	if(stored_arguments)
		arguments += stored_arguments
	current_behavior.finish_action(arglist(arguments))
/datum/behavior_tree/node/parallel/root/proc/set_movement_target(source, atom/target, datum/bt_movement/new_movement)
	if(current_movement_target)
		UnregisterSignal(current_movement_target, list(COMSIG_MOVABLE_MOVED, COMSIG_PARENT_PREQDELETED))
	if(!isnull(target) && !isatom(target))
		stack_trace("[pawn]'s current movement target is not an atom, rather a [target.type]! Did you accidentally set it to a weakref?")
		CancelActions()
		return
	movement_target_source = source
	current_movement_target = target
	if(!isnull(current_movement_target))
		RegisterSignal(current_movement_target, COMSIG_MOVABLE_MOVED, PROC_REF(on_movement_target_move))
		RegisterSignal(current_movement_target, COMSIG_PARENT_PREQDELETED, PROC_REF(on_movement_target_delete))
	if(new_movement)
		change_ai_movement_type(new_movement)

/datum/behavior_tree/node/parallel/root/proc/change_ai_movement_type(datum/bt_movement/new_movement)
	if(istype(ai_movement) && moving_towards)
		ai_movement.stop_moving_towards(src)
	ai_movement = GET_BT_MOVEMENT(new_movement)

/datum/behavior_tree/node/parallel/root/proc/halt_movement()
	if(moving_towards)
		ai_movement.stop_moving_towards(src)
	movement_path = null
	if(blackboard[BB_FUTURE_MOVEMENT_PATH])
		clear_blackboard_key(BB_FUTURE_MOVEMENT_PATH)
	if(current_movement_target)
		set_movement_target(type, null)
	if(!QDELETED(pawn))
		walk(pawn, 0)

/datum/behavior_tree/node/parallel/root/proc/on_movement_target_move(atom/source)
	SIGNAL_HANDLER
	check_target_max_distance()

/datum/behavior_tree/node/parallel/root/proc/check_target_max_distance()
	if(get_dist_3d(pawn, current_movement_target) <= max_target_distance)
		return
	var/last_hit = blackboard["bb_last_ranged_hit_time"] || 0
	var/mob/last_shooter = blackboard["bb_last_ranged_attacker"]
	var/commanded_travel = (current_movement_target == blackboard[BB_TRAVEL_DESTINATION])
	if(commanded_travel || (last_shooter == current_movement_target && (world.time - last_hit < 15 SECONDS)))
		return
	CancelActions()

/datum/behavior_tree/node/parallel/root/proc/on_movement_target_delete(atom/source)
	SIGNAL_HANDLER
	set_movement_target(source = type, target = null)
/datum/behavior_tree/node/parallel/root/proc/replace_planning_subtrees(list/typepaths_of_new_subtrees)
	var/list/shared = list()
	for(var/type in typepaths_of_new_subtrees)
		shared += GET_BT_SUBTREE(type)
	planner.my_nodes = shared

/datum/behavior_tree/node/parallel/root/proc/add_to_top(datum/behavior_tree/node/subtree/tree)
	var/list/new_trees = list()
	new_trees += tree
	for(var/datum/behavior_tree/node/subtree/listed_tree as anything in planner.my_nodes)
		new_trees |= listed_tree.type
	replace_planning_subtrees(new_trees)

/datum/behavior_tree/node/parallel/root/proc/get_inventory()
	RETURN_TYPE(/datum/component/ai_inventory_manager)
	return pawn?.GetComponent(/datum/component/ai_inventory_manager)

/datum/behavior_tree/node/parallel/root/proc/ai_can_interact()
	return !QDELETED(pawn)

/datum/behavior_tree/node/parallel/root/proc/ai_interact(target, combat_mode, nextmove = FALSE, list/modifiers)
	if(!ai_can_interact())
		return FALSE
	var/atom/final_target = isdatum(target) ? target : blackboard[target]
	if(QDELETED(final_target))
		return FALSE
	var/mob/living/living_pawn = pawn
	if(final_target == living_pawn)
		return FALSE
	if(nextmove && living_pawn.next_move > world.time)
		return FALSE
	var/params = list2params(modifiers)
	if(isnull(combat_mode))
		SEND_SIGNAL(living_pawn, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, final_target)
		living_pawn.ClickOn(final_target, params)
		return TRUE
	var/old_combat_mode = living_pawn.cmode
	living_pawn.cmode = combat_mode
	SEND_SIGNAL(living_pawn, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, final_target)
	living_pawn.ClickOn(final_target, params)
	living_pawn.cmode = old_combat_mode
	return TRUE
