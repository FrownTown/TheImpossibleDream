/*
*/
/datum/behavior_tree/node/planner/infernal
	converted_from = /datum/ai_controller/infernal

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,

		/datum/behavior_tree/node/subtree/targeted_mob_ability/any/continue_planning,

		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree,
		/datum/behavior_tree/node/subtree/simple_self_recovery,
	)


/*
*/
/datum/behavior_tree/node/planner/infernal/harasser
	converted_from = /datum/ai_controller/infernal/harasser

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,

		/datum/behavior_tree/node/subtree/targeted_mob_ability/any/continue_planning,

		/datum/behavior_tree/node/subtree/spacing/ranged,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/spaced,
		/datum/behavior_tree/node/subtree/simple_self_recovery,
	)


/*
*/
/datum/behavior_tree/node/planner/infernal/hound
	converted_from = /datum/ai_controller/infernal/hound

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,

		/datum/behavior_tree/node/subtree/targeted_mob_ability/any/continue_planning,

		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/circler,
		/datum/behavior_tree/node/subtree/simple_self_recovery,
	)
