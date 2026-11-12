//behavior just walks left/right randomly
/bt_idle_behavior/idle_crab_walk

	///Chance that the mob random walks per second
	var/walk_chance = 10


/bt_idle_behavior/idle_crab_walk/perform_idle_behavior(delta_time, datum/behavior_tree/node/parallel/root/controller)
	. = ..()
	// Disabled - this was measured at ~10-15% of AI CPU at 90 players. Idle movement is
	// not worth the cost. Matches the same gutting done to idle_random_walk.
	// if(controller.blackboard[BB_BASIC_MOB_FOOD_TARGET]) // this means we are likely eating a corpse
	//	return
	// var/mob/living/living_pawn = controller.pawn
	// if(prob(walk_chance) && (living_pawn.mobility_flags & MOBILITY_MOVE) && isturf(living_pawn.loc) && !living_pawn.pulledby)
	//	var/move_dir = pick(WEST, EAST) //west, east. Because they're a crab
	//	living_pawn.Move(get_step(living_pawn, move_dir), move_dir)
