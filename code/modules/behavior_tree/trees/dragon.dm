/*
	Melee dragon can 'leap'
	Caster dragon can emit a fire cone. Technically it also has leap but AI won't use it.
*/
/datum/behavior_tree/node/planner/dragon
	converted_from = /datum/ai_controller/dragon

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()
	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,

		/datum/behavior_tree/node/subtree/targeted_mob_ability/any/continue_planning,

		/datum/behavior_tree/node/subtree/spacing,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/spaced,
		/datum/behavior_tree/node/subtree/simple_self_recovery/dragon

	)
