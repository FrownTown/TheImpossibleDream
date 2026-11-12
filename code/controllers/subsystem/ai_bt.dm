GLOBAL_LIST_EMPTY(ai_init_queue)
GLOBAL_LIST_EMPTY(npc_list)

PROCESSING_SUBSYSTEM_DEF(ai)
	name = "AI (behavior trees)"
	priority = SS_PRIORITY_AI
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_GAME
	wait = 1

	var/list/active_mobs = list()
	var/list/sleeping_mobs = list()
	var/list/unregister_queue = list()
	var/list/sleep_queue = list()

	var/alist/claimed_turfs
	var/path_searches = 0

/datum/controller/subsystem/processing/ai/Initialize()
	. = ..()
	claimed_turfs = alist()

	for(var/mob/living/M as anything in GLOB.ai_init_queue)
		if(!QDELETED(M))
			Register(M)
	GLOB.ai_init_queue.Cut()

/datum/controller/subsystem/processing/ai/proc/Register(mob/living/M)
	if(!initialized)
		GLOB.ai_init_queue |= M
		return

	if(M?.ai_root?.planner)
		M.ai_root.start_planner()
		return

	if(M && M.ai_root && !sleeping_mobs[M]) // Only register if it's not already sleeping.
		if(!M.ai_root.blackboard)
			M.ai_root.blackboard = new
		active_mobs[M] = TRUE
		SSspatial_grid.remove_ai_sleeper(M)
		M.ai_root.next_think_tick = world.time + M.ai_root.next_think_delay
		M.ai_root.next_move_tick = world.time + M.ai_root.next_move_delay
		GLOB.npc_list |= M

/datum/controller/subsystem/processing/ai/proc/Unregister(mob/living/M)
	if(!M)
		return
	GLOB.ai_init_queue -= M

	active_mobs -= M
	sleeping_mobs -= M
	SSspatial_grid.remove_ai_sleeper(M)
	GLOB.npc_list -= M
	if(!M.ai_root)
		return
	if(M.ai_root.move_destination)
		M.set_ai_path_to(null)
	QDEL_NULL(M.ai_root)

/datum/controller/subsystem/processing/ai/proc/WakeUp(mob/living/M, forced = FALSE)
	if(!M || !M.ai_root)
		return
	if(forced)
		M.ai_root.ai_flags &= ~AI_FLAG_FORCESLEEP
	if(M.ai_root.ai_flags & AI_FLAG_FORCESLEEP)
		return
	if(!sleeping_mobs[M])
		return
	sleeping_mobs -= M
	SSspatial_grid.remove_ai_sleeper(M)

	active_mobs[M] = TRUE
	if(M.ai_root.blackboard)
		M.ai_root.blackboard -= AIBLK_HIBERNATION_TIMER
	M.ai_root.next_think_tick = world.time // Let it think immediately
	M.ai_root.next_sleep_tick = world.time + M.ai_root.next_sleep_delay

/datum/controller/subsystem/processing/ai/proc/GoToSleep(mob/living/M, forced = FALSE)
	if(!active_mobs[M])
		return
	if(forced)
		M.ai_root.ai_flags |= AI_FLAG_FORCESLEEP
	if(M.ai_root.next_sleep_tick < world.time)
		sleeping_mobs[M] = TRUE
		active_mobs -= M
		SSspatial_grid.add_ai_sleeper(M)

/datum/controller/subsystem/processing/ai/fire(resumed)
	var/current_time = world.time

	for(var/mob/living/M as anything in active_mobs)
		if(QDELETED(M) || M.stat == DEAD || M.client)
			unregister_queue |= M
			continue

		var/turf/T = get_turf(M)
		if(!T)
			unregister_queue |= M
			continue

		// Check if enough time has passed for the mob to think/move again.
		if(current_time >= M.ai_root.next_think_tick || current_time >= M.ai_root.next_move_tick)
			if(!(M.ai_root.ai_flags & (AI_FLAG_PERSISTENT|AI_FLAG_ASSUMEDIRECTCONTROL|AI_FLAG_FORCESLEEP)))
				if(!SSspatial_grid.client_mob_in_square(T, AI_HIBERNATION_RANGE))
					if(M.ai_root.blackboard)
						if(!M.ai_root.blackboard[AIBLK_HIBERNATION_TIMER])
							M.ai_root.blackboard[AIBLK_HIBERNATION_TIMER] = current_time + AI_HIBERNATION_DELAY

						if(current_time >= M.ai_root.blackboard[AIBLK_HIBERNATION_TIMER])
							sleep_queue |= M
							continue
				else if(M.ai_root.blackboard?[AIBLK_HIBERNATION_TIMER])
					M.ai_root.blackboard -= AIBLK_HIBERNATION_TIMER

			if(M.ai_root.run_started && current_time - M.ai_root.run_started < 5 SECONDS)
				continue
			INVOKE_ASYNC(M, TYPE_PROC_REF(/mob/living, RunAI))

	for(var/mob/living/M as anything in unregister_queue)
		Unregister(M)

	for(var/mob/living/M as anything in sleep_queue)
		GoToSleep(M)

	unregister_queue.len = 0
	sleep_queue.len = 0

/datum/controller/subsystem/processing/ai/proc/wake_sleepers_near(mob/living/mover)
	var/list/sleepers = SSspatial_grid.ai_sleepers_in_square(get_turf(mover), AI_HIBERNATION_RANGE)
	if(!sleepers)
		return
	var/mover_is_ai = (mover.ai_root || mover.ai_controller) ? TRUE : FALSE
	for(var/mob/living/sleeper as anything in sleepers)
		if(sleeper == mover || !sleeper.ai_root)
			continue
		if(mover_is_ai && mover.faction_check_mob(sleeper))
			continue
		if(los_blocked(mover, sleeper))
			continue
		WakeUp(sleeper)
// PATHFINDING CLAIM SYSTEM
/datum/controller/subsystem/processing/ai/proc/hash_turf(turf/T)
	if(!T)
		return 0
	var/hash = 5381
	hash = (hash << 5) + hash + T.x
	hash = (hash << 5) + hash + T.y
	hash = (hash << 5) + hash + T.z
	return hash & 0xFFFFFF

/datum/controller/subsystem/processing/ai/proc/claim_turf(turf/T, mob/living/claimer)
	if(!T || !claimer)
		return
	var/datum/weakref/weakclaimer = WEAKREF(claimer)
	if(!weakclaimer)
		return
	claimed_turfs[hash_turf(T)] = weakclaimer

/datum/controller/subsystem/processing/ai/proc/unclaim_turf(turf/T, mob/living/claimer)
	if(!T)
		return
	claimed_turfs -= hash_turf(T)

/datum/controller/subsystem/processing/ai/proc/turf_claimed_by(turf/T, mob/living/exclude)
	if(!T)
		return null
	var/datum/weakref/weakclaimer = claimed_turfs[hash_turf(T)]
	if(!weakclaimer)
		return null
	var/mob/living/hardclaimer = weakclaimer.resolve()
	if(hardclaimer && hardclaimer != exclude && !QDELETED(hardclaimer))
		return hardclaimer
	return null
/mob/living/var/datum/spatial_grid_cell/bt_sleep_cell

/// Per-tick cache of this mob's visibility scans (see ai_visibility_scan).
/mob/var/ai_view_cache_time = 0
/mob/var/list/ai_view_cache

/mob/living/Moved(atom/OldLoc, Dir)
	. = ..()
	if(bt_sleep_cell)
		SSspatial_grid.update_ai_sleeper(src)
	if(SSspatial_grid.ai_sleeper_count)
		SSai.wake_sleepers_near(src)
