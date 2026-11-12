/datum/behavior_tree/node/parallel/root
	var/ai_status
	var/datum/cell_tracker/our_cells
	var/can_idle = TRUE
	var/interesting_dist = AI_DEFAULT_INTERESTING_DIST

/datum/behavior_tree/node/parallel/root/proc/start_planner()
	if(ai_status || QDELETED(pawn))
		return
	if(!continue_processing_when_client && pawn.client)
		set_ai_status(AI_STATUS_OFF)
	else
		set_ai_status(AI_STATUS_ON)

	RegisterSignal(pawn, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_changed_z_level))
	if(pawn.client)
		RegisterSignal(pawn, COMSIG_MOB_LOGOUT, PROC_REF(on_sentience_lost))
	else
		RegisterSignal(pawn, COMSIG_MOB_LOGIN, PROC_REF(on_sentience_gained))
	RegisterSignal(pawn, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_changed))

	our_cells = new(interesting_dist, interesting_dist, 1)
	set_new_cells()

	RegisterSignal(pawn, COMSIG_MOVABLE_MOVED, PROC_REF(update_grid))

/datum/behavior_tree/node/parallel/root/proc/stop_planner()
	if(pawn)
		UnregisterSignal(pawn, list(COMSIG_MOVABLE_Z_CHANGED, COMSIG_MOB_LOGIN, COMSIG_MOB_LOGOUT, COMSIG_MOB_STATCHANGE, COMSIG_MOVABLE_MOVED))
	if(ai_status)
		GLOB.planners_by_status[ai_status] -= src
		stop_previous_processing()
		ai_status = null
	our_cells = null

/datum/behavior_tree/node/parallel/root/proc/set_ai_status(new_ai_status)
	if(ai_status == new_ai_status)
		return FALSE
	if(ai_status)
		GLOB.planners_by_status[ai_status] -= src
	stop_previous_processing()
	ai_status = new_ai_status
	GLOB.planners_by_status[new_ai_status] += src
	switch(ai_status)
		if(AI_STATUS_ON)
			START_PROCESSING(SSai_behaviors, src)
		if(AI_STATUS_IDLE)
			START_PROCESSING(SSidle_ai_behaviors, src)
		if(AI_STATUS_OFF)
			CancelActions()
			halt_movement()

/datum/behavior_tree/node/parallel/root/proc/stop_previous_processing()
	switch(ai_status)
		if(AI_STATUS_ON)
			STOP_PROCESSING(SSai_behaviors, src)
		if(AI_STATUS_IDLE)
			STOP_PROCESSING(SSidle_ai_behaviors, src)

/datum/behavior_tree/node/parallel/root/proc/reset_ai_status()
	set_ai_status(get_expected_ai_status())

/datum/behavior_tree/node/parallel/root/proc/get_expected_ai_status()
	if(!continue_processing_when_client && pawn.client)
		return AI_STATUS_OFF
	if(pawn.stat >= UNCONSCIOUS)
		return AI_STATUS_OFF
	var/turf/pawn_turf = get_turf(pawn)
	if(!("[pawn_turf?.z]" in GLOB.weatherproof_z_levels))
		if(SSmapping.level_has_any_trait(pawn_turf?.z, list(ZTRAIT_IGNORE_WEATHER_TRAIT)))
			GLOB.weatherproof_z_levels |= "[pawn_turf?.z]"
	if("[pawn_turf?.z]" in GLOB.weatherproof_z_levels)
		if(!length(SSmobs.clients_by_zlevel[pawn_turf?.z]))
			return AI_STATUS_OFF
	if(should_idle())
		return AI_STATUS_IDLE
	return AI_STATUS_ON

/datum/behavior_tree/node/parallel/root/proc/should_idle()
	if(!can_idle)
		return FALSE
	var/alert_until = blackboard[BB_AI_ALERT_MODE_UNTIL] || 0
	if(alert_until > world.time)
		return FALSE
	var/list/aggro_table = blackboard?[BB_MOB_AGGRO_TABLE]
	if(length(aggro_table))
		return FALSE
	for(var/datum/spatial_grid_cell/grid as anything in our_cells?.member_cells)
		if(length(grid.client_contents))
			return FALSE
	return TRUE

/datum/behavior_tree/node/parallel/root/proc/recalculate_idle()
	if(ai_status == AI_STATUS_OFF)
		return
	if(should_idle())
		set_ai_status(AI_STATUS_IDLE)

/datum/behavior_tree/node/parallel/root/proc/wake_for_combat()
	if(ai_status == AI_STATUS_ON)
		return
	if(pawn.stat >= UNCONSCIOUS)
		return
	if(pawn.client && !continue_processing_when_client)
		return
	blackboard[BB_AI_ALERT_MODE_UNTIL] = world.time + 30 SECONDS
	set_ai_status(AI_STATUS_ON)

/datum/behavior_tree/node/parallel/root/proc/set_new_cells()
	var/turf/our_turf = get_turf(pawn)
	if(isnull(our_turf))
		return
	var/list/cell_collections = our_cells.recalculate_cells(our_turf)
	for(var/datum/old_grid as anything in cell_collections[2])
		UnregisterSignal(old_grid, list(SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), SPATIAL_GRID_CELL_EXITED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS)))
	for(var/datum/spatial_grid_cell/new_grid as anything in cell_collections[1])
		RegisterSignal(new_grid, SPATIAL_GRID_CELL_ENTERED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), PROC_REF(on_client_enter))
		RegisterSignal(new_grid, SPATIAL_GRID_CELL_EXITED(SPATIAL_GRID_CONTENTS_TYPE_CLIENTS), PROC_REF(on_client_exit))
	recalculate_idle()

/datum/behavior_tree/node/parallel/root/proc/update_grid(datum/source, datum/spatial_grid_cell/new_cell)
	SIGNAL_HANDLER
	set_new_cells()
	if(current_movement_target)
		check_target_max_distance()

/datum/behavior_tree/node/parallel/root/proc/on_client_enter(datum/source, atom/target)
	SIGNAL_HANDLER
	blackboard[BB_AI_ALERT_MODE_UNTIL] = world.time + 30 SECONDS
	if(ai_status == AI_STATUS_IDLE)
		if(pawn.stat >= UNCONSCIOUS)
			return
		set_ai_status(AI_STATUS_ON)
		return
	if(ai_status == AI_STATUS_OFF)
		if(pawn.stat < UNCONSCIOUS && (continue_processing_when_client || !pawn.client))
			reset_ai_status()

/datum/behavior_tree/node/parallel/root/proc/on_client_exit(datum/source, datum/exited)
	SIGNAL_HANDLER
	recalculate_idle()

/datum/behavior_tree/node/parallel/root/proc/on_changed_z_level(atom/source, old_z, new_z, same_z_layer, notify_contents)
	SIGNAL_HANDLER
	if(pawn?.client && !continue_processing_when_client)
		return
	if(new_z)
		reset_ai_status()

/datum/behavior_tree/node/parallel/root/proc/on_stat_changed(mob/living/source, new_stat)
	SIGNAL_HANDLER
	reset_ai_status()

/datum/behavior_tree/node/parallel/root/proc/on_sentience_gained()
	SIGNAL_HANDLER
	UnregisterSignal(pawn, COMSIG_MOB_LOGIN)
	if(!continue_processing_when_client)
		set_ai_status(AI_STATUS_OFF)
	RegisterSignal(pawn, COMSIG_MOB_LOGOUT, PROC_REF(on_sentience_lost))

/datum/behavior_tree/node/parallel/root/proc/on_sentience_lost()
	SIGNAL_HANDLER
	UnregisterSignal(pawn, COMSIG_MOB_LOGOUT)
	reset_ai_status()
	RegisterSignal(pawn, COMSIG_MOB_LOGIN, PROC_REF(on_sentience_gained))
