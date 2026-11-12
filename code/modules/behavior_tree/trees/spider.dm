/datum/behavior_tree/node/planner/spider
	converted_from = /datum/ai_controller/spider

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items(),
		BB_BASIC_MOB_TAMED	= FALSE
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/find_dead_bodies,
		/datum/behavior_tree/node/subtree/eat_dead_body,
		/datum/behavior_tree/node/subtree/find_food,
		/datum/behavior_tree/node/subtree/eat_food,
	)


/datum/behavior_tree/node/planner/spider/honeyspider
	converted_from = /datum/ai_controller/spider/honeyspider
	// Same as spider but no obstacle smashing

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items(),
		BB_BASIC_MOB_TAMED	= FALSE
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
		/datum/behavior_tree/node/subtree/find_dead_bodies,
		/datum/behavior_tree/node/subtree/eat_dead_body,
		/datum/behavior_tree/node/subtree/find_food,
		/datum/behavior_tree/node/subtree/eat_food,
	)
