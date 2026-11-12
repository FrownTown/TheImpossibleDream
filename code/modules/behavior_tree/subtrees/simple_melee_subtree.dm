/datum/behavior_tree/node/subtree/basic_melee_attack_subtree
	var/bt_behavior/basic_melee_attack/melee_attack_behavior = /bt_behavior/basic_melee_attack
	var/end_planning = TRUE


/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	. = ..()
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return
	controller.queue_behavior(melee_attack_behavior, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	if (end_planning)
		return SUBTREE_RETURN_FINISH_PLANNING //we are going into battle...no distractions.

	

//If you give this to something without the element you are a dumbass.
/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree
	var/bt_behavior/basic_ranged_attack/ranged_attack_behavior = /bt_behavior/basic_ranged_attack


/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	. = ..()
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target))
		return
	controller.queue_behavior(ranged_attack_behavior, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	return SUBTREE_RETURN_FINISH_PLANNING //we are going into battle...no distractions.


/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree/opportunistic
	ranged_attack_behavior = /bt_behavior/opportunistic_ranged_attack


/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree/opportunistic/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	var/mob/living/simple_animal/hostile/pawn = controller.pawn
	if(!istype(pawn) || !pawn.ranged || pawn.ranged_cooldown > world.time)
		return
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target) || pawn.Adjacent(target))
		return
	controller.queue_behavior(ranged_attack_behavior, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)



/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/bog_troll
	melee_attack_behavior = /bt_behavior/basic_melee_attack/bog_troll


/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/mimic
	melee_attack_behavior = /bt_behavior/basic_melee_attack/mimic


/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/spear //Spacing takes care of our movement
	melee_attack_behavior = /bt_behavior/static_melee_attack


/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/spaced //Spacing takes care of our movement
	melee_attack_behavior = /bt_behavior/static_melee_attack


/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/circler
	melee_attack_behavior = /bt_behavior/basic_melee_attack/circler
