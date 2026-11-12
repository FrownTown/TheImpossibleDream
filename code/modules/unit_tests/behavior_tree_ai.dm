#define BT_TEST_MAX_OFFSET 60

/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test
	icon = 'icons/roguetown/mob/monster/volf.dmi'
	icon_state = "volf_brown"
	base_intents = list(/datum/intent/simple/bite/volf)
	faction = list(FACTION_WOLFS)
	health = WOLF_HEALTH
	maxHealth = WOLF_HEALTH
	melee_damage_lower = 19
	melee_damage_upper = 29
	aggressive = 1
	AIStatus = AI_OFF
	can_have_ai = FALSE
	ai_controller = null
	bt_tree = /datum/behavior_tree/node/selector/volf_tree
	melee_cooldown = WOLF_ATTACK_SPEED
	move_base_delay = MOVEMENT_DELAY_SPD_3
	attack_aim = MOB_AIM_LOW
	anatomy_type = /datum/anatomy/quadruped/trash
	see_in_dark = 6
	move_to_delay = 3
	vision_range = 7
	aggro_vision_range = 9
	environment_smash = ENVIRONMENT_SMASH_NONE
	retreat_distance = 0
	minimum_distance = 0
	food_type = list(/obj/item/reagent_containers/food/snacks, /obj/item/natural/bone, /obj/item/natural/hide)
	STACON = 7
	STASTR = 7
	STASPD = 12
	simple_detect_bonus = 20
	deaggroprob = 0
	retreat_health = 0.3
	food = 0
	dodgetime = 30
	eat_forever = TRUE
	attack_sound = list('sound/vo/mobs/vw/attack (1).ogg')
/proc/bt_test_turf(datum/unit_test/test, dx, dy)
	var/turf/origin = test.run_loc_floor_bottom_left
	. = locate(origin.x + dx, origin.y + dy, origin.z)
	if(!.)
		test.Fail("bt_test_turf([dx], [dy]) is off the map")
		CRASH("bt_test_turf([dx], [dy]) is off the map")

/proc/bt_test_force_sleep(mob/living/M)
	M.ai_root.next_sleep_tick = 0
	SSai.GoToSleep(M)

/datum/unit_test/bt_volf_conversion

/datum/unit_test/bt_volf_conversion/Run()
	var/list/converted = list(
		/mob/living/simple_animal/hostile/retaliate/rogue/wolf,
		/mob/living/simple_animal/hostile/retaliate/rogue/wolf/dire,
		/mob/living/simple_animal/hostile/retaliate/rogue/badger,
		/mob/living/simple_animal/hostile/retaliate/rogue/bobcat,
		/mob/living/simple_animal/hostile/retaliate/rogue/fox,
		/mob/living/simple_animal/hostile/retaliate/rogue/ooze_blob,
		/mob/living/simple_animal/hostile/retaliate/rogue/raccoon,
		/mob/living/simple_animal/hostile/retaliate/rogue/werewolf_npc,
		/mob/living/simple_animal/hostile/retaliate/rogue/revenant/wolf,
	)
	for(var/mob_type in converted)
		var/mob/living/simple_animal/M = allocate(mob_type, run_loc_floor_bottom_left)
		TEST_ASSERT_NOTNULL(M.ai_root, "[mob_type] has no behavior tree")
		TEST_ASSERT_EQUAL(M.ai_root.tree_typepath, /datum/behavior_tree/node/planner/volf, "[mob_type] runs the wrong tree")
		TEST_ASSERT_NOTNULL(M.ai_root.planner, "[mob_type] tree is not a planner")
		TEST_ASSERT_NULL(M.ai_controller, "[mob_type] still has an ai_controller")
		TEST_ASSERT(M.ai_root.ai_status, "[mob_type] planner has no AI status (not started by SSai)")
		TEST_ASSERT(istype(M.ai_bb_get(BB_TARGETTING_DATUM), /datum/targetting_datum/basic), "[mob_type] has no targetting datum")
		if(!ispath(mob_type, /mob/living/simple_animal/hostile/retaliate/rogue/revenant))
			TEST_ASSERT(!M.can_have_ai && M.AIStatus == AI_OFF, "[mob_type] can still run the npcpool AI")
	for(var/base_type in converted)
		for(var/sub_type in subtypesof(base_type))
			var/mob/living/simple_animal/sub_path = sub_type
			if(initial(sub_path.ai_controller) || initial(sub_path.bt_tree) != /datum/behavior_tree/node/planner/volf)
				continue
			var/mob/living/simple_animal/M = allocate(sub_type, run_loc_floor_bottom_left)
			TEST_ASSERT(M.ai_root?.planner, "[sub_type] has no planner tree")
			TEST_ASSERT_NULL(M.ai_controller, "[sub_type] still has an ai_controller")
	for(var/mob_type in subtypesof(/mob/living))
		var/mob/living/M = mob_type
		if(initial(M.ai_controller) == /datum/ai_controller/volf && !ispath(mob_type, /mob/living/simple_animal/hostile/retaliate/rogue/wolf/bt_parity_controller))
			TEST_FAIL("[mob_type] still uses /datum/ai_controller/volf")

/datum/unit_test/bt_sleeper_index

/datum/unit_test/bt_sleeper_index/Run()
	var/start_count = SSspatial_grid.ai_sleeper_count
	var/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test/volf = allocate(/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test, run_loc_floor_bottom_left)

	bt_test_force_sleep(volf)
	TEST_ASSERT(SSai.sleeping_mobs[volf], "volf did not go to sleep")
	var/datum/spatial_grid_cell/cell = SSspatial_grid.get_cell_of(volf)
	TEST_ASSERT(volf in cell.ai_sleepers, "sleeping volf is not in its cell's sleeper list")
	TEST_ASSERT_EQUAL(volf.bt_sleep_cell, cell, "bt_sleep_cell points at the wrong cell")
	TEST_ASSERT_EQUAL(SSspatial_grid.ai_sleeper_count, start_count + 1, "sleeper count not incremented")

	var/turf/far = bt_test_turf(src, SPATIAL_GRID_CELLSIZE + 2, 0)
	volf.forceMove(far)
	var/datum/spatial_grid_cell/new_cell = SSspatial_grid.get_cell_of(volf)
	TEST_ASSERT_NOTEQUAL(new_cell, cell, "test move did not change cell")
	TEST_ASSERT(!(volf in cell.ai_sleepers), "sleeper left behind in its old cell")
	TEST_ASSERT(volf in new_cell.ai_sleepers, "sleeper not added to its new cell")
	TEST_ASSERT_EQUAL(SSspatial_grid.ai_sleeper_count, start_count + 1, "sleeper count changed by a move")

	SSai.WakeUp(volf)
	TEST_ASSERT(!(volf in new_cell.ai_sleepers), "woken mob still indexed")
	TEST_ASSERT_NULL(volf.bt_sleep_cell, "woken mob still has bt_sleep_cell")
	TEST_ASSERT_EQUAL(SSspatial_grid.ai_sleeper_count, start_count, "sleeper count not decremented on wake")

	bt_test_force_sleep(volf)
	qdel(volf)
	TEST_ASSERT(!(volf in new_cell.ai_sleepers), "deleted sleeper still indexed")
	TEST_ASSERT_EQUAL(SSspatial_grid.ai_sleeper_count, start_count, "sleeper count not decremented on deletion")

/datum/unit_test/bt_wake_rules

/datum/unit_test/bt_wake_rules/Run()
	var/list/turf/opened = block(bt_test_turf(src, 25, 25), bt_test_turf(src, 30 + AI_HIBERNATION_RANGE + 4, 42))
	for(var/turf/T as anything in opened)
		T.ChangeTurf(/turf/open/floor/rogue)

	var/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test/sleeper = allocate(/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test, bt_test_turf(src, 30, 30))
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, bt_test_turf(src, 30 + AI_HIBERNATION_RANGE + 3, 30))

	bt_test_force_sleep(sleeper)
	walker.forceMove(bt_test_turf(src, 30 + AI_HIBERNATION_RANGE + 1, 30))
	TEST_ASSERT(SSai.sleeping_mobs[sleeper], "woken from outside the hibernation range")

	walker.forceMove(bt_test_turf(src, 30 + AI_HIBERNATION_RANGE, 30))
	TEST_ASSERT(SSai.active_mobs[sleeper], "not woken at the edge of the range")

	bt_test_force_sleep(sleeper)
	var/turf/wall_turf = bt_test_turf(src, 33, 30)
	var/old_wall_type = wall_turf.type
	wall_turf.ChangeTurf(/turf/closed/indestructible)
	walker.forceMove(bt_test_turf(src, 36, 30))
	TEST_ASSERT(SSai.sleeping_mobs[sleeper], "woken through an opaque wall")
	walker.forceMove(bt_test_turf(src, 36, 34))
	TEST_ASSERT(SSai.active_mobs[sleeper], "not woken with line of sight around the wall")
	wall_turf.ChangeTurf(old_wall_type)

	bt_test_force_sleep(sleeper)
	var/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test/packmate = allocate(/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test, bt_test_turf(src, 40, 40))
	packmate.forceMove(bt_test_turf(src, 34, 34))
	TEST_ASSERT(SSai.sleeping_mobs[sleeper], "woken by an allied AI mob")
	packmate.faction = list("bt_test_outsider")
	packmate.forceMove(bt_test_turf(src, 34, 35))
	TEST_ASSERT(SSai.active_mobs[sleeper], "not woken by a hostile AI mob")

	QDEL_LIST(allocated)
	for(var/turf/T as anything in opened)
		T.ChangeTurf(/turf/closed/basic)

/datum/unit_test/bt_grid_queries

/datum/unit_test/bt_grid_queries/Run()
	var/z = run_loc_floor_bottom_left.z
	var/list/mob/living/carbon/human/people = list()
	for(var/i in 1 to 12)
		var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human, bt_test_turf(src, rand(1, BT_TEST_MAX_OFFSET), rand(1, BT_TEST_MAX_OFFSET)))
		people += H
	var/list/fake_clients = people.Copy(1, 7)
	for(var/mob/living/carbon/human/H as anything in fake_clients)
		H.enable_client_mobs_in_contents()

	for(var/probe in 1 to 200)
		var/turf/center = bt_test_turf(src, rand(1, BT_TEST_MAX_OFFSET), rand(1, BT_TEST_MAX_OFFSET))
		var/range = pick(3, 7, AI_HIBERNATION_RANGE, 20)

		var/expected_client = FALSE
		for(var/mob/living/carbon/human/H as anything in fake_clients)
			if(H.z == z && abs(H.x - center.x) <= range && abs(H.y - center.y) <= range)
				expected_client = TRUE
				break
		TEST_ASSERT_EQUAL(SSspatial_grid.client_mob_in_square(center, range), expected_client, "client_mob_in_square disagrees at ([center.x],[center.y]) range [range]")

		var/list/expected_living = list()
		for(var/mob/living/L in GLOB.mob_living_list)
			if(L.z == z && abs(L.x - center.x) <= range && abs(L.y - center.y) <= range)
				expected_living += L
		var/list/found_living = SSspatial_grid.living_mobs_in_square(center, range)
		TEST_ASSERT(!length(found_living ^ expected_living), "living_mobs_in_square disagrees at ([center.x],[center.y]) range [range]: found [length(found_living)], expected [length(expected_living)]")

	for(var/mob/living/carbon/human/H as anything in fake_clients)
		H.clear_important_client_contents()

/datum/unit_test/bt_cell_tracker_skip

/datum/unit_test/bt_cell_tracker_skip/Run()
	for(var/ratio in list(1, 2))
		var/datum/cell_tracker/tracker = new(10, 10, ratio)
		var/list/datum/spatial_grid_cell/reference_members = list()
		var/x = 40
		var/y = 40
		for(var/step in 1 to 1500)
			x = clamp(x + rand(-1, 1), 1, BT_TEST_MAX_OFFSET)
			y = clamp(y + rand(-1, 1), 1, BT_TEST_MAX_OFFSET)
			if(prob(2))
				x = rand(1, BT_TEST_MAX_OFFSET)
				y = rand(1, BT_TEST_MAX_OFFSET)
			var/turf/center = bt_test_turf(src, x, y)

			var/list/inner = SSspatial_grid.get_cells_in_bounds(center, tracker.inner_window_x_radius, tracker.inner_window_y_radius)
			var/list/outer = SSspatial_grid.get_cells_in_bounds(center, tracker.outer_window_x_radius, tracker.outer_window_y_radius)
			var/list/ref_new = inner - reference_members
			var/list/ref_old = reference_members - outer
			reference_members -= ref_old
			reference_members += ref_new

			var/list/result = tracker.recalculate_cells(center)
			TEST_ASSERT(!length(result[1] ^ ref_new), "new cells differ at step [step] (ratio [ratio])")
			TEST_ASSERT(!length(result[2] ^ ref_old), "old cells differ at step [step] (ratio [ratio])")
			TEST_ASSERT(!length(tracker.member_cells ^ reference_members), "member cells differ at step [step] (ratio [ratio])")

/datum/unit_test/bt_volf_attacks
	priority = TEST_LONGER

/datum/unit_test/bt_volf_attacks/Run()
	var/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test/volf = allocate(/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	volf.ai_root.ai_flags |= AI_FLAG_PERSISTENT
	SSai.WakeUp(volf, forced = TRUE)
	var/start_brute = victim.getBruteLoss()

	var/deadline = world.time + 20 SECONDS
	while(world.time < deadline && victim.getBruteLoss() <= start_brute)
		sleep(2)

	TEST_ASSERT_EQUAL(volf.ai_root?.target, victim, "volf never targeted the human")
	TEST_ASSERT(victim.getBruteLoss() > start_brute, "volf never hurt the human (brute [victim.getBruteLoss()])")

/datum/unit_test/bt_unreachable_target
	priority = TEST_LONGER

/datum/unit_test/bt_unreachable_target/Run()
	var/list/turf/pocket_a = block(bt_test_turf(src, 25, 25), bt_test_turf(src, 29, 29))
	var/list/turf/pocket_b = block(bt_test_turf(src, 31, 25), bt_test_turf(src, 35, 29))
	for(var/turf/T as anything in pocket_a + pocket_b)
		T.ChangeTurf(/turf/open/floor/rogue)

	var/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test/volf = allocate(/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test, bt_test_turf(src, 29, 27))
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, bt_test_turf(src, 31, 27))
	volf.ai_root.ai_flags |= AI_FLAG_PERSISTENT
	SSai.WakeUp(volf, forced = TRUE)
	volf.bt_give_target(victim)

	var/start_searches = SSai.path_searches
	sleep(10 SECONDS)
	var/searches = SSai.path_searches - start_searches
	TEST_NOTICE(src, "unreachable target: [searches] A* searches in 10 seconds")
	TEST_ASSERT(searches <= 10, "[searches] A* searches in 10 seconds for an unreachable target")

	QDEL_LIST(allocated)
	for(var/turf/T as anything in pocket_a + pocket_b)
		T.ChangeTurf(/turf/closed/basic)

/datum/unit_test/bt_tree_restored

/datum/unit_test/bt_tree_restored/Run()
	var/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test/volf = allocate(/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test, run_loc_floor_bottom_left)

	volf.death()
	SSai.Unregister(volf)
	TEST_ASSERT_NULL(volf.ai_root, "dead volf kept its tree")
	volf.revive(full_heal = TRUE)
	TEST_ASSERT_NOTNULL(volf.ai_root, "revived volf did not get its tree back")
	TEST_ASSERT(SSai.active_mobs[volf] || SSai.sleeping_mobs[volf], "revived volf not registered with SSai")

	SSai.Unregister(volf)
	SEND_SIGNAL(volf, COMSIG_MOB_LOGOUT)
	sleep(2)
	TEST_ASSERT_NOTNULL(volf.ai_root, "volf did not get its tree back after logout")

/datum/unit_test/bt_mob_hooks

/datum/unit_test/bt_mob_hooks/Run()
	var/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test/volf = allocate(/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))

	bt_test_force_sleep(volf)
	volf.adjustBruteLoss(5)
	TEST_ASSERT(SSai.active_mobs[volf], "damage did not wake the volf")
	TEST_ASSERT(attacker in volf.ai_root.blackboard[AIBLK_AGGRESSORS], "nearby human not made an aggressor on damage")
	TEST_ASSERT(length(volf.resolve_enemies()), "legacy Retaliate no longer fills enemies (taming gate)")

	volf.ai_root.target = null
	var/obj/item/stick = allocate(/obj/item/natural/stone, get_turf(attacker))
	volf.attacked_by(stick, attacker)
	TEST_ASSERT_EQUAL(volf.ai_root.target, attacker, "being hit did not target the attacker")

	bt_test_force_sleep(volf)
	attacker.start_pulling(volf)
	TEST_ASSERT_EQUAL(attacker.pulling, volf, "test grab failed")
	TEST_ASSERT(SSai.active_mobs[volf], "being grabbed did not wake the volf")

#undef BT_TEST_MAX_OFFSET
