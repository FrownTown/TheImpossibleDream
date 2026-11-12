/mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_controller
	ai_controller = /datum/ai_controller/volf
	bt_tree = null

/datum/ai_controller/volf/bt_parity_gnome
	ai_movement = /datum/ai_movement/hybrid_pathing/gnome

/mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_gnome_controller
	ai_controller = /datum/ai_controller/volf/bt_parity_gnome
	bt_tree = null

/datum/behavior_tree/node/planner/volf/bt_parity_gnome
	ai_movement = /datum/bt_movement/hybrid_pathing/gnome

/mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_gnome_tree
	bt_tree = /datum/behavior_tree/node/planner/volf/bt_parity_gnome

#define BT_PARITY_TREE_WOLF /mob/living/simple_animal/hostile/retaliate/rogue/wolf
#define BT_PARITY_CONTROLLER_WOLF /mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_controller

/proc/bt_parity_report(text)
#ifdef BT_PARITY_REPORT
	text2file("[time2text(world.realtime, "hh:mm:ss")] [text]", "data/bt_parity_report.txt")
#endif

/datum/bt_parity_run
	var/label
	var/first_target = 0
	var/first_step = 0
	var/first_attack = 0
	var/attacks = 0
	var/steps = 0
	var/list/events = list()

/datum/bt_parity_run/proc/summary()
	return "[label]: target [first_target / 10]s, step [first_step / 10]s, attack [first_attack / 10]s, [attacks] attacks, [steps] steps ([jointext(events, ",")])"

/datum/bt_parity_counter
	var/count = 0

/datum/bt_parity_counter/proc/on_attack()
	SIGNAL_HANDLER
	count++

/proc/bt_parity_prepare(mob/living/victim)
	victim.enable_client_mobs_in_contents()

/proc/bt_parity_cleanup(mob/living/victim)
	victim.clear_important_client_contents()

/proc/bt_parity_watch(mob/living/simple_animal/wolf, mob/living/victim, duration, label)
	var/datum/bt_parity_run/run = new
	run.label = label
	var/datum/bt_parity_counter/counter = new
	counter.RegisterSignal(wolf, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, TYPE_PROC_REF(/datum/bt_parity_counter, on_attack))
	var/start = world.time
	var/last_x = wolf.x
	var/last_y = wolf.y
	while(world.time < start + duration && !QDELETED(wolf))
		if(!run.first_target && wolf.ai_bb_get(BB_BASIC_MOB_CURRENT_TARGET))
			run.first_target = world.time - start
		if(counter.count != run.attacks)
			run.attacks = counter.count
			run.events += "A[world.time - start]"
			if(!run.first_attack)
				run.first_attack = world.time - start
		if(wolf.x != last_x || wolf.y != last_y)
			run.steps++
			run.events += "S[world.time - start]"
			if(!run.first_step)
				run.first_step = world.time - start
			last_x = wolf.x
			last_y = wolf.y
		if(victim && victim.getBruteLoss() > 50)
			victim.fully_heal()
		sleep(world.tick_lag)
	counter.UnregisterSignal(wolf, COMSIG_HOSTILE_PRE_ATTACKINGTARGET)
	return run

/datum/unit_test/bt_parity_volf_duel
	priority = TEST_LONGER

/datum/unit_test/bt_parity_volf_duel/Run()
	var/list/datum/bt_parity_run/runs = list()
	for(var/wolf_type in list(BT_PARITY_CONTROLLER_WOLF, BT_PARITY_TREE_WOLF, BT_PARITY_TREE_WOLF, BT_PARITY_CONTROLLER_WOLF))
		var/mob/living/simple_animal/wolf = new wolf_type(run_loc_floor_bottom_left)
		var/mob/living/carbon/human/victim = new(run_loc_floor_top_right)
		bt_parity_prepare(victim)
		if(wolf.ai_root)
			SSai.WakeUp(wolf, forced = TRUE)
		runs += bt_parity_watch(wolf, victim, 15 SECONDS, wolf.ai_root ? "tree" : "controller")
		bt_parity_cleanup(victim)
		qdel(wolf)
		qdel(victim)

	var/list/summaries = list()
	for(var/datum/bt_parity_run/run as anything in runs)
		summaries += run.summary()
	var/report = jointext(summaries, " | ")
	bt_parity_report("duel: [report]")
	for(var/datum/bt_parity_run/run as anything in runs)
		TEST_ASSERT(run.attacks > 0, "[run.label] wolf never attacked: [report]")
	var/datum/bt_parity_run/controller_a = runs[1]
	var/datum/bt_parity_run/tree_a = runs[2]
	var/datum/bt_parity_run/tree_b = runs[3]
	var/datum/bt_parity_run/controller_b = runs[4]
	var/controller_attacks = controller_a.attacks + controller_b.attacks
	var/tree_attacks = tree_a.attacks + tree_b.attacks
	TEST_ASSERT(abs(controller_attacks - tree_attacks) <= 2, "attack counts differ: [report]")
	var/controller_reaction = ((controller_a.first_attack - controller_a.first_target) + (controller_b.first_attack - controller_b.first_target)) / 2
	var/tree_reaction = ((tree_a.first_attack - tree_a.first_target) + (tree_b.first_attack - tree_b.first_target)) / 2
	TEST_ASSERT(abs(controller_reaction - tree_reaction) <= 6, "target-to-first-attack differs ([controller_reaction] vs [tree_reaction] ds): [report]")

/datum/unit_test/bt_parity_volf_duel_astar
	priority = TEST_LONGER

/datum/unit_test/bt_parity_volf_duel_astar/Run()
	var/list/datum/bt_parity_run/runs = list()
	for(var/wolf_type in list(/mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_gnome_controller, /mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_gnome_tree))
		var/mob/living/simple_animal/wolf = new wolf_type(run_loc_floor_bottom_left)
		var/mob/living/carbon/human/victim = new(run_loc_floor_top_right)
		bt_parity_prepare(victim)
		if(wolf.ai_root)
			SSai.WakeUp(wolf, forced = TRUE)
		runs += bt_parity_watch(wolf, victim, 15 SECONDS, wolf.ai_root ? "tree" : "controller")
		bt_parity_cleanup(victim)
		qdel(wolf)
		qdel(victim)
	var/list/summaries = list()
	for(var/datum/bt_parity_run/run as anything in runs)
		summaries += run.summary()
	var/report = jointext(summaries, " | ")
	bt_parity_report("duel, always A*: [report]")
	var/datum/bt_parity_run/controller_run = runs[1]
	var/datum/bt_parity_run/tree_run = runs[2]
	TEST_ASSERT(controller_run.attacks > 0 && tree_run.attacks > 0, "a wolf never attacked: [report]")
	TEST_ASSERT(abs(controller_run.attacks - tree_run.attacks) <= 1, "attack counts differ: [report]")
	var/controller_reaction = controller_run.first_attack - controller_run.first_target
	var/tree_reaction = tree_run.first_attack - tree_run.first_target
	TEST_ASSERT(abs(controller_reaction - tree_reaction) <= 6, "target-to-first-attack differs ([controller_reaction] vs [tree_reaction] ds): [report]")

/datum/unit_test/bt_parity_volf_wakes_for_moving_prey
	priority = TEST_LONGER

/datum/unit_test/bt_parity_volf_wakes_for_moving_prey/Run()
	var/list/summaries = list()
	var/list/datum/bt_parity_run/runs = list()
	for(var/wolf_type in list(BT_PARITY_CONTROLLER_WOLF, BT_PARITY_TREE_WOLF))
		var/list/turf/opened = bt_parity_open(src, 5, 25, 45, 35)
		var/mob/living/simple_animal/wolf = new wolf_type(bt_test_turf(src, 12, 30))
		sleep(2 SECONDS)
		var/mob/living/carbon/human/victim = new(bt_test_turf(src, 37, 30))
		bt_parity_prepare(victim)
		var/datum/bt_parity_run/run
		var/list/walk = list()
		for(var/i in 1 to 23)
			walk += WEST
		for(var/i in 1 to 6)
			walk += list(NORTH, NORTH, SOUTH, SOUTH)
		var/datum/callback/walker = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(bt_parity_walk), victim, walk, 4)
		walker.InvokeAsync()
		run = bt_parity_watch(wolf, victim, 25 SECONDS, wolf.ai_root ? "tree" : "controller")
		runs += run
		summaries += run.summary()
		bt_parity_cleanup(victim)
		qdel(wolf)
		qdel(victim)
		bt_parity_close(opened)
	var/report = jointext(summaries, " | ")
	bt_parity_report("moving prey, no forced wake: [report]")
	var/datum/bt_parity_run/controller_run = runs[1]
	var/datum/bt_parity_run/tree_run = runs[2]
	TEST_ASSERT(controller_run.attacks > 0, "controller wolf never attacked: [report]")
	TEST_ASSERT(tree_run.attacks > 0, "tree wolf never attacked: [report]")
	TEST_ASSERT(abs(controller_run.first_target - tree_run.first_target) <= 10, "noticed the prey at different times: [report]")
	TEST_ASSERT(abs(controller_run.first_attack - tree_run.first_attack) <= 15, "first attack at different times: [report]")
	TEST_ASSERT(abs(controller_run.attacks - tree_run.attacks) <= 2, "attack counts differ: [report]")

/proc/bt_parity_walk(mob/living/walker, list/dirs, delay)
	for(var/dir in dirs)
		if(QDELETED(walker))
			return
		walker.Move(get_step(walker, dir), dir)
		sleep(delay)

/datum/unit_test/bt_parity_volf_family_attacks
	priority = TEST_LONGER

/datum/unit_test/bt_parity_volf_family_attacks/Run()
	var/list/summaries = list()
	for(var/mob_type in list(/mob/living/simple_animal/hostile/retaliate/rogue/ooze_blob, /mob/living/simple_animal/hostile/retaliate/rogue/werewolf_npc, /mob/living/simple_animal/hostile/retaliate/rogue/revenant/wolf, /mob/living/simple_animal/hostile/retaliate/rogue/badger))
		var/mob/living/simple_animal/beast = new mob_type(run_loc_floor_bottom_left)
		var/mob/living/carbon/human/victim = new(run_loc_floor_top_right)
		bt_parity_prepare(victim)
		SSai.WakeUp(beast, forced = TRUE)
		if(!beast.GetComponent(/datum/component/ai_aggro_system))
			SEND_SIGNAL(beast, COMSIG_ATOM_WAS_ATTACKED, victim, 5)
		var/datum/bt_parity_run/run = bt_parity_watch(beast, victim, 15 SECONDS, "[mob_type]")
		summaries += run.summary()
		TEST_ASSERT(run.attacks > 0, "[mob_type] never attacked: [run.summary()]")
		bt_parity_cleanup(victim)
		qdel(beast)
		qdel(victim)
	bt_parity_report("family: [jointext(summaries, " | ")]")

/proc/bt_parity_open(datum/unit_test/test, x1, y1, x2, y2)
	var/list/turf/opened = block(bt_test_turf(test, x1, y1), bt_test_turf(test, x2, y2))
	for(var/turf/T as anything in opened)
		T.ChangeTurf(/turf/open/floor/rogue)
	return opened

/proc/bt_parity_close(list/turf/opened)
	for(var/turf/T as anything in opened)
		for(var/atom/movable/AM in T)
			if(!ismob(AM))
				qdel(AM)
		T.ChangeTurf(/turf/closed/basic)

/datum/unit_test/bt_parity_volf_astar_fallback
	priority = TEST_LONGER

/datum/unit_test/bt_parity_volf_astar_fallback/Run()
	var/list/summaries = list()
	var/list/datum/bt_parity_run/runs = list()
	for(var/wolf_type in list(BT_PARITY_CONTROLLER_WOLF, BT_PARITY_TREE_WOLF))
		var/list/turf/opened = bt_parity_open(src, 25, 25, 45, 36)
		for(var/turf/T as anything in block(bt_test_turf(src, 35, 25), bt_test_turf(src, 35, 34)))
			T.ChangeTurf(/turf/closed/indestructible)
		var/mob/living/simple_animal/wolf = new wolf_type(bt_test_turf(src, 31, 29))
		var/mob/living/carbon/human/victim = new(bt_test_turf(src, 39, 29))
		bt_parity_prepare(victim)
		if(wolf.ai_root)
			SSai.WakeUp(wolf, forced = TRUE)
		var/datum/component/ai_aggro_system/aggro = wolf.GetComponent(/datum/component/ai_aggro_system)
		aggro.add_threat_to_mob(victim, 100)
		var/datum/bt_parity_run/run = bt_parity_watch(wolf, victim, 25 SECONDS, wolf.ai_root ? "tree" : "controller")
		runs += run
		summaries += run.summary()
		bt_parity_cleanup(victim)
		qdel(wolf)
		qdel(victim)
		bt_parity_close(opened)
	var/report = jointext(summaries, " | ")
	bt_parity_report("astar fallback: [report]")
	var/datum/bt_parity_run/controller_run = runs[1]
	var/datum/bt_parity_run/tree_run = runs[2]
	TEST_ASSERT(controller_run.attacks > 0, "controller wolf never got round the wall: [report]")
	TEST_ASSERT(tree_run.attacks > 0, "tree wolf never got round the wall: [report]")
	var/controller_reach = controller_run.first_attack - controller_run.first_target
	var/tree_reach = tree_run.first_attack - tree_run.first_target
	TEST_ASSERT(abs(controller_reach - tree_reach) <= 15, "time to get round the wall differs ([controller_reach] vs [tree_reach] ds): [report]")

/datum/unit_test/bt_parity_mixed_reinforcements
	priority = TEST_LONGER

/datum/unit_test/bt_parity_mixed_reinforcements/Run()
	for(var/calling_type in list(BT_PARITY_TREE_WOLF, BT_PARITY_CONTROLLER_WOLF))
		var/helper_type = calling_type == BT_PARITY_TREE_WOLF ? BT_PARITY_CONTROLLER_WOLF : BT_PARITY_TREE_WOLF
		var/mob/living/simple_animal/calling_wolf = new calling_type(run_loc_floor_bottom_left)
		var/mob/living/simple_animal/helper = new helper_type(get_step(run_loc_floor_bottom_left, NORTH))
		var/mob/living/carbon/human/victim = new(run_loc_floor_top_right)
		bt_parity_prepare(victim)
		for(var/mob/living/simple_animal/W in list(calling_wolf, helper))
			if(W.ai_root)
				SSai.WakeUp(W, forced = TRUE)
		calling_wolf.ai_bb_set(BB_BASIC_MOB_CURRENT_TARGET, victim)
		var/deadline = world.time + 5 SECONDS
		while(world.time < deadline && !(victim in helper.ai_bb_get(BB_BASIC_MOB_RETALIATE_LIST)))
			sleep(1)
		TEST_ASSERT(victim in helper.ai_bb_get(BB_BASIC_MOB_RETALIATE_LIST), "[calling_wolf.ai_root ? "tree" : "controller"] volf's call for help did not reach a [helper.ai_root ? "tree" : "controller"] volf")
		TEST_ASSERT_EQUAL(helper.ai_bb_get(BB_BASIC_MOB_REINFORCEMENT_TARGET), calling_wolf, "reinforcement target not set on the helper")
		bt_parity_cleanup(victim)
		qdel(calling_wolf)
		qdel(helper)
		qdel(victim)

/datum/unit_test/bt_parity_volf_flees
	priority = TEST_LONGER

/datum/unit_test/bt_parity_volf_flees/Run()
	var/list/results = list()
	for(var/wolf_type in list(BT_PARITY_CONTROLLER_WOLF, BT_PARITY_TREE_WOLF))
		var/list/turf/opened = bt_parity_open(src, 25, 25, 45, 35)
		var/mob/living/simple_animal/wolf = new wolf_type(bt_test_turf(src, 34, 30))
		var/mob/living/carbon/human/victim = new(bt_test_turf(src, 32, 30))
		bt_parity_prepare(victim)
		if(wolf.ai_root)
			SSai.WakeUp(wolf, forced = TRUE)
		var/datum/component/ai_aggro_system/aggro = wolf.GetComponent(/datum/component/ai_aggro_system)
		aggro.add_threat_to_mob(victim, 100)
		wolf.adjustBruteLoss(wolf.maxHealth * 0.7)
		var/fleeing = wolf.ai_bb_get(BB_BASIC_MOB_FLEEING)
		sleep(3 SECONDS)
		var/label = wolf.ai_root ? "tree" : "controller"
		results += "[label]: fleeing [fleeing], distance [get_dist(wolf, victim)]"
		bt_parity_report("flee: [results[length(results)]]")
		TEST_ASSERT(fleeing, "[label] volf did not start fleeing")
		TEST_ASSERT(get_dist(wolf, victim) >= 4, "[label] volf did not run away: [jointext(results, " | ")]")
		bt_parity_cleanup(victim)
		qdel(wolf)
		qdel(victim)
		bt_parity_close(opened)

/datum/unit_test/bt_parity_volf_eats_corpse
	priority = TEST_LONGER

/datum/unit_test/bt_parity_volf_eats_corpse/Run()
	var/list/results = list()
	for(var/wolf_type in list(BT_PARITY_CONTROLLER_WOLF, BT_PARITY_TREE_WOLF))
		var/mob/living/simple_animal/hostile/retaliate/rogue/wolf = new wolf_type(run_loc_floor_bottom_left)
		var/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test/corpse = new(run_loc_floor_top_right)
		corpse.death()
		var/mob/living/carbon/human/watcher = new(get_step(run_loc_floor_top_right, WEST))
		watcher.status_flags |= GODMODE
		bt_parity_prepare(watcher)
		if(wolf.ai_root)
			SSai.WakeUp(wolf, forced = TRUE)
		var/start = world.time
		var/eaten_at = 0
		while(world.time < start + 25 SECONDS)
			if(QDELETED(corpse) || !isturf(corpse.loc))
				eaten_at = world.time - start
				break
			sleep(1)
		var/label = wolf.ai_root ? "tree" : "controller"
		results += "[label]: eaten at [eaten_at / 10]s"
		bt_parity_report("corpse: [results[length(results)]]")
		TEST_ASSERT(eaten_at, "[label] volf did not eat the corpse in 25 s: [jointext(results, " | ")]")
		bt_parity_cleanup(watcher)
		qdel(wolf)
		qdel(watcher)
		if(!QDELETED(corpse))
			qdel(corpse)

/datum/unit_test/bt_parity_volf_bashes_door
	priority = TEST_LONGER

/datum/unit_test/bt_parity_volf_bashes_door/Run()
	var/list/results = list()
	for(var/wolf_type in list(BT_PARITY_CONTROLLER_WOLF, BT_PARITY_TREE_WOLF))
		var/list/turf/opened = bt_parity_open(src, 25, 30, 35, 30)
		var/obj/structure/mineral_door/wood/door = new(bt_test_turf(src, 30, 30))
		door.locked = TRUE
		var/mob/living/simple_animal/wolf = new wolf_type(bt_test_turf(src, 28, 30))
		var/mob/living/carbon/human/victim = new(bt_test_turf(src, 32, 30))
		bt_parity_prepare(victim)
		var/start_integrity = door.obj_integrity
		if(wolf.ai_root)
			SSai.WakeUp(wolf, forced = TRUE)
		var/datum/component/ai_aggro_system/aggro = wolf.GetComponent(/datum/component/ai_aggro_system)
		aggro.add_threat_to_mob(victim, 100)
		sleep(10 SECONDS)
		var/label = wolf.ai_root ? "tree" : "controller"
		var/damage = QDELETED(door) ? start_integrity : start_integrity - door.obj_integrity
		results += "[label]: door took [damage] damage"
		bt_parity_report("door: [results[length(results)]]")
		TEST_ASSERT(damage > 0, "[label] volf never damaged the door: [jointext(results, " | ")]")
		bt_parity_cleanup(victim)
		qdel(wolf)
		qdel(victim)
		bt_parity_close(opened)

/datum/unit_test/bt_parity_ai_status
	priority = TEST_LONGER

/proc/bt_parity_status(mob/living/M)
	return M.ai_controller ? M.ai_controller.ai_status : M.ai_root?.ai_status

/datum/unit_test/bt_parity_ai_status/Run()
	var/list/turf/opened = bt_parity_open(src, 5, 25, 55, 35)
	var/mob/living/simple_animal/controller_wolf = allocate(BT_PARITY_CONTROLLER_WOLF, bt_test_turf(src, 10, 30))
	var/mob/living/simple_animal/tree_wolf = allocate(BT_PARITY_TREE_WOLF, bt_test_turf(src, 10, 31))
	var/list/log = list()
	var/list/mobs = list(controller_wolf, tree_wolf)
	#define CHECK_STATUS(step) \
		log += "[step]: [bt_parity_status(controller_wolf)]/[bt_parity_status(tree_wolf)]"; \
		TEST_ASSERT_EQUAL(bt_parity_status(tree_wolf), bt_parity_status(controller_wolf), "status differs after [step]: [jointext(log, ", ")]")

	sleep(1 SECONDS)
	CHECK_STATUS("spawn alone")
	TEST_ASSERT_EQUAL(bt_parity_status(tree_wolf), AI_STATUS_IDLE, "a volf alone did not go idle: [jointext(log, ", ")]")

	var/mob/living/carbon/human/visitor = allocate(/mob/living/carbon/human, bt_test_turf(src, 50, 30))
	bt_parity_prepare(visitor)
	sleep(1)
	CHECK_STATUS("player-like mob far away")
	visitor.forceMove(bt_test_turf(src, 14, 30))
	sleep(1)
	CHECK_STATUS("player-like mob arrives")
	TEST_ASSERT_EQUAL(bt_parity_status(tree_wolf), AI_STATUS_ON, "the volf did not wake for a nearby player: [jointext(log, ", ")]")

	bt_parity_cleanup(visitor)
	visitor.forceMove(bt_test_turf(src, 50, 30))
	for(var/mob/living/M as anything in mobs)
		var/list/bb = M.ai_blackboard()
		bb[BB_AI_ALERT_MODE_UNTIL] = 0
		var/list/aggro = bb[BB_MOB_AGGRO_TABLE]
		aggro?.Cut()
		M.ai_cancel_actions()
		M.ai_bb_clear(BB_BASIC_MOB_CURRENT_TARGET)
		M.ai_bb_clear(BB_HIGHEST_THREAT_MOB)
	sleep(2)
	for(var/mob/living/M as anything in mobs)
		M.ai_recalculate_idle()
	CHECK_STATUS("player-like mob leaves")

	for(var/mob/living/M as anything in mobs)
		SEND_SIGNAL(M, COMSIG_ATOM_WAS_ATTACKED, visitor, 5)
	CHECK_STATUS("attacked")

	for(var/mob/living/M as anything in mobs)
		M.Unconscious(5 SECONDS)
	CHECK_STATUS("knocked out")
	for(var/mob/living/M as anything in mobs)
		M.SetUnconscious(0)
	CHECK_STATUS("comes to")

	var/datum/behavior_tree/node/parallel/root/root = tree_wolf.ai_root
	for(var/mob/living/M as anything in mobs)
		M.death()
	CHECK_STATUS("dies")
	TEST_ASSERT_EQUAL(tree_wolf.ai_root, root, "the dead volf lost its tree")
	TEST_ASSERT_NOTNULL(tree_wolf.ai_bb_get(BB_BASIC_FOODS), "the dead volf lost its blackboard")
	for(var/mob/living/M as anything in mobs)
		M.revive(full_heal = TRUE)
	CHECK_STATUS("revived")

	for(var/mob/living/M as anything in mobs)
		SEND_SIGNAL(M, COMSIG_MOB_LOGIN)
	CHECK_STATUS("possessed")
	for(var/mob/living/M as anything in mobs)
		SEND_SIGNAL(M, COMSIG_MOB_LOGOUT)
	sleep(2)
	CHECK_STATUS("logged out")
	TEST_ASSERT_EQUAL(tree_wolf.ai_root, root, "the volf got a new tree after logout")
	#undef CHECK_STATUS
	QDEL_LIST(allocated)
	bt_parity_close(opened)

GLOBAL_LIST_EMPTY(bt_parity_idle_calls)

/datum/idle_behavior/bt_parity_count/perform_idle_behavior(delta_time, datum/ai_controller/controller)
	GLOB.bt_parity_idle_calls[controller.pawn] += 1

/bt_idle_behavior/bt_parity_count/perform_idle_behavior(delta_time, datum/behavior_tree/node/parallel/root/controller)
	GLOB.bt_parity_idle_calls[controller.pawn] += 1

/datum/ai_controller/volf/bt_parity_idle
	idle_behavior = /datum/idle_behavior/bt_parity_count

/mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_idle_controller
	ai_controller = /datum/ai_controller/volf/bt_parity_idle
	bt_tree = null

/datum/behavior_tree/node/planner/volf/bt_parity_idle
	idle_behavior = /bt_idle_behavior/bt_parity_count

/mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_idle_tree
	bt_tree = /datum/behavior_tree/node/planner/volf/bt_parity_idle

/datum/unit_test/bt_parity_idle_processing
	priority = TEST_LONGER

/datum/unit_test/bt_parity_idle_processing/Run()
	var/list/turf/opened = bt_parity_open(src, 5, 25, 55, 35)
	var/mob/living/simple_animal/controller_wolf = allocate(/mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_idle_controller, bt_test_turf(src, 10, 30))
	var/mob/living/simple_animal/tree_wolf = allocate(/mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_idle_tree, bt_test_turf(src, 40, 30))
	GLOB.bt_parity_idle_calls.Cut()
	sleep(31 SECONDS)
	var/controller_idle = GLOB.bt_parity_idle_calls[controller_wolf]
	var/tree_idle = GLOB.bt_parity_idle_calls[tree_wolf]
	bt_parity_report("idle, nobody near, 31 s: controller [controller_idle] calls, tree [tree_idle] calls ([bt_parity_status(controller_wolf)]/[bt_parity_status(tree_wolf)])")
	TEST_ASSERT_EQUAL(bt_parity_status(tree_wolf), AI_STATUS_IDLE, "tree volf not idle with nobody around")
	TEST_ASSERT(controller_idle >= 2 && controller_idle <= 4, "controller idle calls off the 10 s cadence: [controller_idle]")
	TEST_ASSERT(abs(controller_idle - tree_idle) <= 1, "idle cadence differs: controller [controller_idle], tree [tree_idle]")

	GLOB.bt_parity_idle_calls.Cut()
	var/mob/living/carbon/human/near_controller = allocate(/mob/living/carbon/human, bt_test_turf(src, 12, 34))
	var/mob/living/carbon/human/near_tree = allocate(/mob/living/carbon/human, bt_test_turf(src, 42, 34))
	for(var/mob/living/carbon/human/H as anything in list(near_controller, near_tree))
		H.status_flags |= GODMODE
		bt_parity_prepare(H)
	sleep(3 SECONDS)
	controller_idle = GLOB.bt_parity_idle_calls[controller_wolf]
	tree_idle = GLOB.bt_parity_idle_calls[tree_wolf]
	bt_parity_report("idle, player near, 3 s: controller [controller_idle] calls, tree [tree_idle] calls ([bt_parity_status(controller_wolf)]/[bt_parity_status(tree_wolf)])")
	TEST_ASSERT_EQUAL(bt_parity_status(tree_wolf), AI_STATUS_ON, "tree volf not on with a player near")
	TEST_ASSERT(abs(controller_idle - tree_idle) <= max(3, controller_idle / 5), "awake idle calls differ: controller [controller_idle], tree [tree_idle]")
	for(var/mob/living/carbon/human/H as anything in list(near_controller, near_tree))
		bt_parity_cleanup(H)
	QDEL_LIST(allocated)
	bt_parity_close(opened)

#undef BT_PARITY_TREE_WOLF
#undef BT_PARITY_CONTROLLER_WOLF
