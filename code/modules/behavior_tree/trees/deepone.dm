/datum/behavior_tree/node/planner/deepone
	converted_from = /datum/ai_controller/deepone

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
	)


/datum/behavior_tree/node/planner/deepone_ranged
	converted_from = /datum/ai_controller/deepone_ranged

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/spacing/ranged,
		/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree,
	)


/datum/behavior_tree/node/planner/deepone_hound
	converted_from = /datum/ai_controller/deepone_hound
	ai_movement = /datum/bt_movement/hybrid_pathing
	idle_behavior = /bt_idle_behavior/idle_random_walk

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items(),
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/simple_find_target/closest,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/targeted_mob_ability/any,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree
	)
