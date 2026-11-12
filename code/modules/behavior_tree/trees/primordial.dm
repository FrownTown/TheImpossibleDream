/*
*/
/datum/behavior_tree/node/planner/primordial
	converted_from = /datum/ai_controller/primordial

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/being_a_minion,
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,

		/datum/behavior_tree/node/subtree/targeted_mob_ability/any/continue_planning,

		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/opportunistic,
		/datum/behavior_tree/node/subtree/basic_ranged_attack_subtree/opportunistic,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
		/datum/behavior_tree/node/subtree/simple_self_recovery,
	)
