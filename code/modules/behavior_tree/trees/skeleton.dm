/datum/behavior_tree/node/planner/simple_skeleton
	converted_from = /datum/ai_controller/simple_skeleton

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/being_a_minion,
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,


	)



/datum/behavior_tree/node/planner/skeleton_spear
	converted_from = /datum/ai_controller/skeleton_spear

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/being_a_minion,
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/spacing/melee,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/spear,
	)


/datum/behavior_tree/node/planner/skeleton_ranged
	converted_from = /datum/ai_controller/skeleton_ranged

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/being_a_minion,
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree,
	)


///Key difference is minion is at the end and that it is an /event, so they will attack on the way there
/datum/behavior_tree/node/planner/simple_skeleton/event
	converted_from = /datum/ai_controller/simple_skeleton/event
	my_nodes = list(

		/datum/behavior_tree/node/subtree/simple_find_target/closest,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/opportunistic/event_loc,
		/datum/behavior_tree/node/subtree/travel_to_point/and_clear_target,
	)


/datum/behavior_tree/node/planner/skeleton_spear/event
	converted_from = /datum/ai_controller/skeleton_spear/event

	my_nodes = list(

		/datum/behavior_tree/node/subtree/simple_find_target/closest,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/opportunistic/event_loc,
		/datum/behavior_tree/node/subtree/travel_to_point/and_clear_target,
		/datum/behavior_tree/node/subtree/spacing/melee,
	)

///Try not to spawn these, the ai will be poor
/datum/behavior_tree/node/planner/skeleton_ranged/event
	converted_from = /datum/ai_controller/skeleton_ranged/event
	my_nodes = list(

		/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree,
		/datum/behavior_tree/node/subtree/simple_find_target/closest,
		/datum/behavior_tree/node/subtree/travel_to_point/and_clear_target,
		/datum/behavior_tree/node/subtree/spacing/ranged,
	)
