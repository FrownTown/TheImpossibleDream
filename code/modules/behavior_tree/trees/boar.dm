/datum/behavior_tree/node/planner/boar
	converted_from = /datum/ai_controller/boar
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
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
		/datum/behavior_tree/node/subtree/find_food,
		/datum/behavior_tree/node/subtree/eat_food,
	)
