/datum/behavior_tree/node/planner/generic //Placeholder for mobs missing their AI Controller
	converted_from = /datum/ai_controller/generic
	can_climb_structures = FALSE //farm animals stay penned

	ai_movement = /datum/bt_movement/hybrid_pathing

	initial_blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic()

	)

	my_nodes = list(
		/datum/behavior_tree/node/subtree/find_nearest_thing_which_attacked_me_to_flee,

		/datum/behavior_tree/node/subtree/find_food,
		/datum/behavior_tree/node/subtree/eat_food/farm_animals,

		/datum/behavior_tree/node/subtree/simple_self_recovery/genericanimal,
	)

	idle_behavior = /bt_idle_behavior/idle_random_walk/less_walking


/datum/behavior_tree/node/planner/generic/goat
	converted_from = /datum/ai_controller/generic/goat
	can_climb_structures = TRUE //goats are renowned mountaineers

	my_nodes = list(
		/datum/behavior_tree/node/subtree/target_retaliate,

		/datum/behavior_tree/node/subtree/find_food,
		/datum/behavior_tree/node/subtree/eat_food/farm_animals,
		)
