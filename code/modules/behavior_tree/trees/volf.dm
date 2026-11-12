/datum/behavior_tree/node/planner/volf
	converted_from = /datum/ai_controller/volf

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic(),
		BB_BASIC_MOB_TAMED = FALSE,
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/flee_target,
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/call_reinforcements,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/circler,

		/datum/behavior_tree/node/subtree/find_dead_bodies,
		/datum/behavior_tree/node/subtree/eat_dead_body,
		/datum/behavior_tree/node/subtree/find_food,
		/datum/behavior_tree/node/subtree/eat_food,

	)
