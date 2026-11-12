/datum/behavior_tree/node/subtree/simple_find_target


/datum/behavior_tree/node/subtree/simple_find_target/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_potential_targets, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)


/datum/behavior_tree/node/subtree/simple_find_target/rat


/datum/behavior_tree/node/subtree/simple_find_target/rat/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_potential_targets/rat, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)


/datum/behavior_tree/node/subtree/simple_find_target/spider


/datum/behavior_tree/node/subtree/simple_find_target/rat/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_potential_targets/spider, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)



/datum/behavior_tree/node/subtree/simple_find_target/mimic


/datum/behavior_tree/node/subtree/simple_find_target/mimic/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_potential_targets/mimic, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)


/datum/behavior_tree/node/subtree/simple_find_target/mole


/datum/behavior_tree/node/subtree/simple_find_target/mole/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_potential_targets/mole, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)


/datum/behavior_tree/node/subtree/simple_find_target/troll


/datum/behavior_tree/node/subtree/simple_find_target/troll/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_potential_targets/troll, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)


/datum/behavior_tree/node/subtree/simple_find_target/bog_troll


/datum/behavior_tree/node/subtree/simple_find_target/bog_troll/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_potential_targets/bog_troll, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)


/datum/behavior_tree/node/subtree/simple_find_target/closest //nearest


/datum/behavior_tree/node/subtree/simple_find_target/closest/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_potential_targets/nearest, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)


/datum/behavior_tree/node/subtree/aggro_find_target


/datum/behavior_tree/node/subtree/aggro_find_target/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_aggro_targets, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)


/datum/behavior_tree/node/subtree/aggro_find_target/bum


/datum/behavior_tree/node/subtree/aggro_find_target/bum/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_aggro_targets/bum, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)


/datum/behavior_tree/node/subtree/aggro_find_target/species_hostile


/datum/behavior_tree/node/subtree/aggro_find_target/species_hostile/SelectBehaviors(datum/behavior_tree/node/parallel/root/controller, delta_time)
	controller.queue_behavior(/bt_behavior/find_aggro_targets/species_hostile, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
