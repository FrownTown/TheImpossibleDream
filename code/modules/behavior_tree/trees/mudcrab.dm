/datum/behavior_tree/node/planner/mudcrab
	converted_from = /datum/ai_controller/mudcrab

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()

	)

	my_nodes = list(

		//datum/behavior_tree/node/subtree/simple_find_target,
		//datum/behavior_tree/node/subtree/target_retaliate,
		//datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
		//datum/behavior_tree/node/subtree/eat_food,
	)
