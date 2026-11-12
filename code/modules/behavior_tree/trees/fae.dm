/*
*/
/datum/behavior_tree/node/planner/fae
	converted_from = /datum/ai_controller/fae

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
	Weave in and out of attacks
*/
/datum/behavior_tree/node/planner/fae/skirmisher/melee
	converted_from = /datum/ai_controller/fae/skirmisher/melee

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,

		/datum/behavior_tree/node/subtree/targeted_mob_ability/any/continue_planning,

		/datum/behavior_tree/node/subtree/spacing/circling/melee,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/spaced,
		/datum/behavior_tree/node/subtree/simple_self_recovery,
	)


/*
*/
/datum/behavior_tree/node/planner/fae/skirmisher/melee/reactive
	converted_from = /datum/ai_controller/fae/skirmisher/melee/reactive

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,

		/datum/behavior_tree/node/subtree/targeted_mob_ability/any/continue_planning,

		/datum/behavior_tree/node/subtree/spacing/circling/reactive,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/spaced,
		/datum/behavior_tree/node/subtree/simple_self_recovery,
	)
