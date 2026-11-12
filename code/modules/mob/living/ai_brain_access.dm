/mob/proc/has_ai_brain()
	return ai_controller || ai_root?.planner

/mob/proc/ai_blackboard()
	if(ai_controller)
		return ai_controller.blackboard
	if(ai_root?.planner)
		return ai_root.blackboard

/mob/proc/ai_bb_get(key)
	if(ai_controller)
		return ai_controller.blackboard[key]
	if(ai_root?.planner)
		return ai_root.blackboard[key]

/mob/proc/ai_bb_set(key, thing)
	if(ai_controller)
		ai_controller.set_blackboard_key(key, thing)
	else if(ai_root?.planner)
		ai_root.set_blackboard_key(key, thing)

/mob/proc/ai_bb_clear(key)
	if(ai_controller)
		ai_controller.clear_blackboard_key(key)
	else if(ai_root?.planner)
		ai_root.clear_blackboard_key(key)

/mob/proc/ai_bb_insert_lazylist(key, thing)
	if(ai_controller)
		ai_controller.insert_blackboard_key_lazylist(key, thing)
	else if(ai_root?.planner)
		ai_root.insert_blackboard_key_lazylist(key, thing)

/mob/proc/ai_cancel_actions()
	if(ai_controller)
		ai_controller.CancelActions()
	else if(ai_root?.planner)
		ai_root.CancelActions()

/mob/proc/ai_wake_for_combat()
	if(ai_controller)
		ai_controller.wake_for_combat()
	else if(ai_root?.planner)
		ai_root.wake_for_combat()

/mob/proc/ai_recalculate_idle()
	if(ai_controller)
		ai_controller.recalculate_idle()
	else if(ai_root?.planner)
		ai_root.recalculate_idle()

/mob/proc/ai_advance_movement_cooldown()
	if(ai_controller)
		ai_controller.advance_movement_cooldown()
	else if(ai_root?.planner)
		ai_root.advance_movement_cooldown()

/mob/proc/ai_remove_brain()
	if(ai_controller)
		QDEL_NULL(ai_controller)
	if(ai_root)
		SSai.Unregister(src)

/mob/living/simple_animal/ai_remove_brain()
	bt_tree = null
	return ..()

/mob/proc/ai_life_suspended()
	if(ai_controller)
		return ai_controller.ai_status == AI_STATUS_OFF
	if(ai_root?.planner)
		return ai_root.ai_status == AI_STATUS_OFF
	return FALSE

/mob/proc/ai_set_status(new_status)
	if(ai_controller)
		ai_controller.set_ai_status(new_status)
	else if(ai_root?.planner)
		ai_root.set_ai_status(new_status)

/mob/proc/ai_reset_status()
	if(ai_controller)
		ai_controller.reset_ai_status()
	else if(ai_root?.planner)
		ai_root.reset_ai_status()

/proc/ai_planner_for_controller(controller_type)
	return text2path(replacetext("[controller_type]", "/datum/ai_controller/", "/datum/behavior_tree/node/planner/"))

/mob/proc/ai_give_brain(controller_type)
	ai_controller = controller_type
	InitializeAIController()

/mob/living/simple_animal/ai_give_brain(controller_type)
	var/tree = ai_planner_for_controller(controller_type)
	if(!tree)
		return ..()
	bt_tree = tree
	init_ai_root(tree)

/mob/proc/ai_append_subtree(subtree_type)
	if(ai_controller)
		var/list/paths = list()
		for(var/datum/ai_planning_subtree/tree as anything in ai_controller.planning_subtrees)
			paths |= tree.type
		paths |= subtree_type
		ai_controller.replace_planning_subtrees(paths)
	else if(ai_root?.planner)
		var/list/paths = list()
		for(var/datum/behavior_tree/node/subtree/tree as anything in ai_root.planner.my_nodes)
			paths |= tree.type
		paths |= text2path(replacetext("[subtree_type]", "/datum/ai_planning_subtree/", "/datum/behavior_tree/node/subtree/"))
		ai_root.replace_planning_subtrees(paths)
