/datum/behavior_tree/node/planner/spirit_vengeance
	converted_from = /datum/ai_controller/spirit_vengeance

	ai_movement = /datum/bt_movement/astar

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/being_a_minion,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
	)
