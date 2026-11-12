/mob/living/simple_animal/hostile/retaliate/Retaliate()
	if(ai_root && !ai_root.planner)
		bt_retaliate()
	return ..()

/mob/living/simple_animal/hostile/retaliate/proc/bt_retaliate()
	SSai.WakeUp(src)
	if(!ai_root?.blackboard)
		return
	var/list/around = get_nearby_entities(src, vision_range)

	if(!ai_root.blackboard[AIBLK_AGGRESSORS])
		ai_root.blackboard[AIBLK_AGGRESSORS] = list()

	var/list/new_aggressors = list()
	for(var/mob/living/L as anything in around)
		if(faction_check_mob(L) && attack_same || !faction_check_mob(L))
			ai_root.blackboard[AIBLK_AGGRESSORS] |= L
			new_aggressors |= L

	for(var/mob/living/simple_animal/hostile/retaliate/H in around)
		if(faction_check_mob(H) && !attack_same && !H.attack_same)
			if(!H.ai_root?.blackboard)
				continue
			if(!H.ai_root.blackboard[AIBLK_AGGRESSORS])
				H.ai_root.blackboard[AIBLK_AGGRESSORS] = list()
			H.ai_root.blackboard[AIBLK_AGGRESSORS] |= new_aggressors
