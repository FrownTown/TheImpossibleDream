
/datum/behavior_tree/node/planner/reiver_rider
	converted_from = /datum/ai_controller/reiver_rider
	ai_movement = /datum/bt_movement/hybrid_pathing
	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/simple_find_target/closest,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/opportunistic/event_loc,
		/datum/behavior_tree/node/subtree/travel_to_point/and_clear_target,
	)


/datum/behavior_tree/node/planner/reiver_rider/lance
	converted_from = /datum/ai_controller/reiver_rider/lance

	ai_movement = /datum/bt_movement/hybrid_pathing
	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/simple_find_target/closest,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/opportunistic/event_loc,
		/datum/behavior_tree/node/subtree/travel_to_point/and_clear_target,
		/datum/behavior_tree/node/subtree/spacing/melee,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/spear,
	)


/datum/behavior_tree/node/planner/reiver_crossbow
	converted_from = /datum/ai_controller/reiver_crossbow

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(

		/datum/behavior_tree/node/subtree/being_a_minion,
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree,
	)
