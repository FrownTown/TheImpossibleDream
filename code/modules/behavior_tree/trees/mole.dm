/datum/behavior_tree/node/planner/mole
	converted_from = /datum/ai_controller/mole

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items()

	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,

		/datum/behavior_tree/node/subtree/find_dead_bodies/mole,
		/datum/behavior_tree/node/subtree/eat_dead_body,
		/datum/behavior_tree/node/subtree/find_food,
		/datum/behavior_tree/node/subtree/eat_food,
	)
