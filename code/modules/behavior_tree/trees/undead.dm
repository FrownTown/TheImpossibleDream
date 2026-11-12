/datum/behavior_tree/node/planner/undead
	converted_from = /datum/ai_controller/undead

	ai_movement = /datum/bt_movement/basic_avoidance

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/being_a_minion,
		/datum/behavior_tree/node/subtree/simple_find_target/closest,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
	)



/datum/behavior_tree/node/planner/undead/wolf
	converted_from = /datum/ai_controller/undead/wolf


/datum/behavior_tree/node/planner/undead/fox
	converted_from = /datum/ai_controller/undead/fox


/datum/behavior_tree/node/planner/undead/cabbit
	converted_from = /datum/ai_controller/undead/cabbit
