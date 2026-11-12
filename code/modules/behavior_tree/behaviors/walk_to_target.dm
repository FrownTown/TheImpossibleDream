///Moves to target then finishes
/bt_behavior/move_to_target
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT


/bt_behavior/move_to_target/perform(delta_time, datum/behavior_tree/node/parallel/root/controller)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
