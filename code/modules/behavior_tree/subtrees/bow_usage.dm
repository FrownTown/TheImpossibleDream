/datum/behavior_tree/node/subtree/ranged_attack_subtree
	parent_type = /datum/behavior_tree/node/subtree/archer_base


/datum/behavior_tree/node/subtree/ranged_attack_subtree/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	if(!validate_archer_equipment(controller))
		return
	var/mob/living/carbon/human/pawn = controller.pawn
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(!isliving(target))
		_restore_stashed_weapon(controller, pawn)
		return

	var/obj/item/quiver/Q = controller.blackboard[BB_ARCHER_NPC_QUIVER]
	var/obj/item/gun/ballistic/revolver/grenadelauncher/bow = controller.blackboard[BB_ARCHER_NPC_BOW]
	if(!length(Q?.arrows) && !bow?.chambered)
		AI_THINK(pawn, "BOW: out of arrows - falling back to melee")
		_restore_stashed_weapon(controller, pawn)
		return

	if(get_dist(pawn, target) <= ARCHER_NPC_KITE_FLOOR && !_archer_retreat_turf(pawn, target))
		AI_THINK(pawn, "BOW: boxed in at dist [get_dist(pawn, target)], no retreat turf - drawing steel")
		_restore_stashed_weapon(controller, pawn)
		return

	controller.queue_behavior(/bt_behavior/ranged_attack_bow, BB_BASIC_MOB_CURRENT_TARGET)
	if(LAZYACCESS(controller.current_behaviors, GET_BT_BEHAVIOR(/bt_behavior/ranged_attack_bow)))
		return SUBTREE_RETURN_FINISH_PLANNING
	AI_THINK(pawn, "BOW: ranged_attack_bow setup FAILED - could not enter bow stance")
	_restore_stashed_weapon(controller, pawn)


// Make the archer kite away in a burst of movement, stand still after a shot, and continue doing so, which should reduce player frustration with stutterstepping that makes it nearly impossible to hit
/bt_behavior/ranged_attack_bow
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION | AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_MOVE_AND_PERFORM
	action_cooldown = 0.2 SECONDS
	required_distance = 0


/bt_behavior/ranged_attack_bow/setup(datum/behavior_tree/node/parallel/root/controller, target_key)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/target = controller.blackboard[target_key]
	if(!isliving(target))
		return FALSE
	if(pawn.incapacitated())
		return FALSE

	var/obj/item/gun/ballistic/revolver/grenadelauncher/bow = _find_archer_bow(pawn)
	if(!bow)
		AI_THINK(pawn, "BOW-STANCE: _find_archer_bow found nothing (bow not in hands/worn)")
		return FALSE

	if(pawn.get_active_held_item() != bow)
		_enter_bow_stance(controller, pawn, bow)
		var/obj/item/blocker = pawn.get_active_held_item()
		if(blocker != bow)
			AI_THINK(pawn, "BOW-STANCE: could not draw bow, active hand blocked by [blocker || "nothing"][blocker && HAS_TRAIT(blocker, TRAIT_NODROP) ? " (NODROP)" : ""]")
			return FALSE

	var/turf/retreat
	if(get_dist(pawn, target) <= ARCHER_NPC_KITE_RANGE)
		retreat = _archer_retreat_turf(pawn, target)
		if(retreat)
			_archer_commit_burst(controller, pawn, retreat)
	set_movement_target(controller, retreat || get_turf(pawn))
	SEND_SIGNAL(controller.pawn, COMSIG_COMBAT_TARGET_SET, TRUE)
	if(istype(bow, /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow))
		controller.set_blackboard_key(BB_ARCHER_NPC_NEXT_SHOT, world.time)
	else
		if(!_chamber_from_quiver(pawn, bow))
			return FALSE
		if(controller.blackboard[BB_ARCHER_NPC_NEXT_SHOT] < world.time) // a future stamp is a draw already in progress - replanning must not restart it
			controller.set_blackboard_key(BB_ARCHER_NPC_NEXT_SHOT, world.time + bow.get_npc_chargetime(pawn))
	return TRUE


/bt_behavior/ranged_attack_bow/perform(delta_time, datum/behavior_tree/node/parallel/root/controller, target_key)
	var/mob/living/carbon/human/pawn = controller.pawn
	var/mob/living/target = controller.blackboard[target_key]

	if(pawn.incapacitated())
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	if(!isliving(target) || target.stat == DEAD)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/obj/item/gun/ballistic/revolver/grenadelauncher/bow = pawn.get_active_held_item()
	if(!istype(bow))
		bow = _find_archer_bow(pawn)
		if(!bow)
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
		_enter_bow_stance(controller, pawn, bow)
		if(pawn.get_active_held_item() != bow)
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/dist = get_dist(pawn, target)
	var/is_crossbow = istype(bow, /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow)

	if(!bow.chambered)
		if(is_crossbow)
			if(!_quiver_has_ammo(pawn))
				return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
			if(!_reload_crossbow(controller, pawn, bow, target))
				return AI_BEHAVIOR_DELAY
		else if(!_chamber_from_quiver(pawn, bow))
			return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	pawn.face_atom(target)

	var/has_lane = _archer_has_firing_lane(get_turf(pawn), target)
	var/has_los = can_see(pawn, target, ARCHER_NPC_SHOOT_RANGE)

	if(has_lane && bow.chambered && world.time >= controller.blackboard[BB_ARCHER_NPC_NEXT_SHOT] && has_los)
		var/release_at = controller.blackboard[BB_ARCHER_NPC_AIM_RELEASE]
		if(!release_at)
			controller.set_blackboard_key(BB_ARCHER_NPC_AIM_LOCK_TURF, get_turf(target))
			controller.set_blackboard_key(BB_ARCHER_NPC_AIM_RELEASE, world.time + pawn.get_ranged_aim_window())
		else if(world.time >= release_at)
			_loose_arrow(pawn, target, bow, controller.blackboard[BB_ARCHER_NPC_AIM_LOCK_TURF])
			controller.clear_blackboard_key(BB_ARCHER_NPC_AIM_LOCK_TURF)
			controller.clear_blackboard_key(BB_ARCHER_NPC_AIM_RELEASE)
			if(is_crossbow)
				controller.set_blackboard_key(BB_ARCHER_NPC_NEXT_SHOT, world.time)
			else
				controller.set_blackboard_key(BB_ARCHER_NPC_NEXT_SHOT, world.time + bow.get_npc_chargetime(pawn))
			if(dist > ARCHER_NPC_JUKE_MIN_DIST)
				var/turf/juke = _archer_reposition_turf(pawn, target)
				if(juke)
					_archer_commit_burst(controller, pawn, juke)

	var/draw_slow = _bow_draw_slowdown(bow)
	if(draw_slow && !is_crossbow)
		pawn.add_movespeed_modifier(MOVESPEED_ID_CHARGING, update = TRUE, priority = 100, override = TRUE, multiplicative_slowdown = draw_slow, movetypes = GROUND)
	else
		pawn.remove_movespeed_modifier(MOVESPEED_ID_CHARGING)

	if(!has_lane)
		controller.clear_blackboard_key(BB_ARCHER_NPC_AIM_LOCK_TURF)
		controller.clear_blackboard_key(BB_ARCHER_NPC_AIM_RELEASE)
		var/turf/lane = _archer_firing_lane_turf(pawn, target)
		if(lane)
			set_movement_target(controller, lane)
			return AI_BEHAVIOR_DELAY

	if(dist > ARCHER_NPC_SHOOT_RANGE)
		set_movement_target(controller, target)
		return AI_BEHAVIOR_DELAY
	var/turf/juke_to = controller.blackboard[BB_ARCHER_NPC_REPOSITION_TURF]
	if(juke_to && world.time < controller.blackboard[BB_ARCHER_NPC_REPOSITION_UNTIL] && get_turf(pawn) != juke_to && !juke_to.is_blocked_turf(exclude_mobs = TRUE))
		set_movement_target(controller, juke_to)
		return AI_BEHAVIOR_DELAY
	if(juke_to)
		_archer_end_burst(controller, dist > ARCHER_NPC_KITE_FLOOR)

	if(!has_los && dist > ARCHER_NPC_KITE_RANGE)
		var/turf/vantage = _archer_los_turf(pawn, target)
		set_movement_target(controller, vantage || target) // sight blocked - sidestep for an angle, or push in until one opens
		return AI_BEHAVIOR_DELAY

	var/plant_until = controller.blackboard[BB_ARCHER_NPC_HOLD_UNTIL]
	if(plant_until && dist > ARCHER_NPC_KITE_FLOOR)
		if(world.time < plant_until)
			controller.ai_movement.stop_moving_towards(controller)
			return AI_BEHAVIOR_DELAY
		controller.clear_blackboard_key(BB_ARCHER_NPC_HOLD_UNTIL)

	if(dist > ARCHER_NPC_KITE_RANGE)
		controller.ai_movement.stop_moving_towards(controller) // in the pocket (kite < dist <= shoot) - hold and loose
		return AI_BEHAVIOR_DELAY
	var/turf/retreat = _archer_retreat_turf(pawn, target)
	if(retreat)
		_archer_commit_burst(controller, pawn, retreat)
		set_movement_target(controller, retreat)
	else if(dist <= ARCHER_NPC_KITE_FLOOR)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED // boxed in with the foe adjacent - draw steel
	else
		controller.ai_movement.stop_moving_towards(controller) // boxed in but they're not adjacent - stand and shoot
	return AI_BEHAVIOR_DELAY


/bt_behavior/ranged_attack_bow/finish_action(datum/behavior_tree/node/parallel/root/controller, succeeded, target_key)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	controller.clear_blackboard_key(BB_ARCHER_NPC_AIM_LOCK_TURF)
	controller.clear_blackboard_key(BB_ARCHER_NPC_AIM_RELEASE)
	controller.clear_blackboard_key(BB_ARCHER_NPC_HOLD_UNTIL)
	_archer_end_burst(controller, FALSE)
	_restore_stashed_weapon(controller, pawn)
