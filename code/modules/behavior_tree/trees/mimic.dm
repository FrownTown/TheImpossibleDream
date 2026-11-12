/datum/behavior_tree/node/planner/mimic
	converted_from = /datum/ai_controller/mimic

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items()

	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/simple_find_target/mimic,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/mimic,

		/datum/behavior_tree/node/subtree/find_dead_bodies/mimic,
		/datum/behavior_tree/node/subtree/eat_dead_body/mimic,
	)

	idle_behavior = /bt_idle_behavior/nothing
