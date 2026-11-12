#define BT_ARENA_SIZE 9
#define BT_ARENA_SPACING 11
#define BT_ARENA_REACH 55
#ifndef BT_ARENA_RUN
#define BT_ARENA_RUN (12 SECONDS)
#endif
#ifndef BT_ARENA_RUNS
#define BT_ARENA_RUNS 6
#endif
#define BT_ARENA_Z 3.3

/datum/bt_arena_counter
	var/count = 0

/datum/bt_arena_counter/proc/on_event()
	SIGNAL_HANDLER
	count++

GLOBAL_VAR_INIT(bt_parity_spawn_controllers, FALSE)

/mob/living/simple_animal/New(loc, ...)
	if(GLOB.bt_parity_spawn_controllers && ispath(bt_tree, /datum/behavior_tree/node/planner))
		var/datum/behavior_tree/node/planner/tree = bt_tree
		var/controller_type = initial(tree.converted_from)
		if(controller_type)
			ai_controller = controller_type
			bt_tree = null
	return ..()

/proc/bt_parity_spawn_controller(mob_type, turf/where)
	GLOB.bt_parity_spawn_controllers = TRUE
	. = new mob_type(where)
	GLOB.bt_parity_spawn_controllers = FALSE

/proc/bt_parity_value_repr(value)
	if(isdatum(value))
		var/datum/D = value
		return "[D.type]"
	if(islist(value))
		var/list/L = value
		var/list/parts = list()
		for(var/key in L)
			var/part = bt_parity_value_repr(key)
			if(!isnum(key) && !isnull(L[key]))
				part += "=[bt_parity_value_repr(L[key])]"
			parts += part
		sortTim(parts, GLOBAL_PROC_REF(cmp_text_asc))
		return "list([jointext(parts, ",")])"
	return "[value]"

/proc/bt_parity_converted_types()
	var/list/types = list()
	for(var/mob_type in subtypesof(/mob/living/simple_animal))
		var/mob/living/simple_animal/candidate = mob_type
		var/tree = initial(candidate.bt_tree)
		if(!ispath(tree, /datum/behavior_tree/node/planner))
			continue
		var/datum/behavior_tree/node/planner/planner_type = tree
		if(!initial(planner_type.converted_from))
			continue
		if(findtext("[mob_type]", "bt_parity") || findtext("[mob_type]", "bt_temp"))
			continue
#ifdef BT_ARENA_FILTER
		var/wanted = FALSE
		for(var/fragment in BT_ARENA_FILTER)
			if(findtext("[mob_type]", fragment))
				wanted = TRUE
		if(!wanted)
			continue
#endif
		types += mob_type
	return types

/proc/bt_parity_one_per_tree(list/types)
	var/list/seen = list()
	var/list/picked = list()
	for(var/mob_type in types)
		var/mob/living/simple_animal/candidate = mob_type
		var/tree = initial(candidate.bt_tree)
		if(seen[tree])
			continue
		seen[tree] = TRUE
		picked += mob_type
	return picked

/proc/bt_parity_mean(list/values)
	var/total = 0
	for(var/v in values)
		total += v
	return length(values) ? total / length(values) : 0

/proc/bt_parity_variance(list/values)
	var/mean = bt_parity_mean(values)
	var/total = 0
	for(var/v in values)
		total += (v - mean) ** 2
	return length(values) > 1 ? total / (length(values) - 1) : 0

/proc/bt_parity_same(list/tree_values, list/controller_values, floor)
	var/gap = abs(bt_parity_mean(tree_values) - bt_parity_mean(controller_values))
	var/standard_error = sqrt(bt_parity_variance(tree_values) / length(tree_values) + bt_parity_variance(controller_values) / length(controller_values))
	return gap <= max(floor, BT_ARENA_Z * standard_error)

/proc/bt_parity_arena_human(turf/where, client_like = TRUE, godmode = FALSE)
	var/mob/living/carbon/human/H = new(where)
	if(godmode)
		H.status_flags |= GODMODE
	if(client_like)
		H.enable_client_mobs_in_contents()
	return H

/proc/bt_parity_hurt(mob/living/victim)
	if(QDELETED(victim))
		return 0
	. = victim.getBruteLoss() + victim.getFireLoss() + victim.getToxLoss() + victim.getOxyLoss()
	if(.)
		victim.fully_heal()

/datum/bt_scenario
	var/name
	var/one_per_tree = TRUE
	var/list/floors = list()

/datum/bt_scenario/proc/setup(datum/unit_test/test, mob/living/simple_animal/beast, list/corner, list/arena)
	return

/datum/bt_scenario/proc/sample(mob/living/simple_animal/beast, list/arena, list/metrics, elapsed)
	return

/datum/bt_scenario/proc/finish(mob/living/simple_animal/beast, list/arena, list/metrics)
	for(var/key in floors)
		if(isnull(metrics[key]))
			metrics[key] = 0

/datum/bt_scenario/proc/turf_at(datum/unit_test/test, list/corner, dx, dy)
	return bt_test_turf(test, corner[1] + dx, corner[2] + dy)

/datum/bt_scenario/proc/count_steps(mob/living/simple_animal/beast, list/arena, list/metrics)
	if(beast.x != arena["last_x"] || beast.y != arena["last_y"])
		metrics["steps"] += 1
		arena["last_x"] = beast.x
		arena["last_y"] = beast.y

/datum/bt_scenario/proc/hook_counters(mob/living/simple_animal/beast, list/arena)
	var/datum/bt_arena_counter/attacks = new
	attacks.RegisterSignal(beast, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, TYPE_PROC_REF(/datum/bt_arena_counter, on_event))
	var/datum/bt_arena_counter/abilities = new
	abilities.RegisterSignal(beast, COMSIG_MOB_ABILITY_STARTED, TYPE_PROC_REF(/datum/bt_arena_counter, on_event))
	arena["attacks"] = attacks
	arena["abilities"] = abilities

/datum/bt_scenario/proc/read_counters(list/arena, list/metrics, elapsed)
	var/datum/bt_arena_counter/attacks = arena["attacks"]
	var/datum/bt_arena_counter/abilities = arena["abilities"]
	metrics["attacks"] = attacks?.count || 0
	metrics["abilities"] = abilities?.count || 0
	if(isnull(metrics["first_attack"]) && metrics["attacks"])
		metrics["first_attack"] = elapsed

/datum/bt_scenario/proc/fill_unreached(list/metrics, list/keys)
	for(var/key in keys)
		if(isnull(metrics[key]))
			metrics[key] = BT_ARENA_RUN

/datum/bt_scenario/combat
	name = "combat"
	one_per_tree = FALSE
	floors = list("first_target" = 3, "first_attack" = 4, "attacks" = 1, "damage" = 15, "steps" = 2, "mean_distance" = 0.5, "abilities" = 1)

/datum/bt_scenario/combat/setup(datum/unit_test/test, mob/living/simple_animal/beast, list/corner, list/arena)
	arena["victim"] = bt_parity_arena_human(turf_at(test, corner, BT_ARENA_SIZE - 2, BT_ARENA_SIZE - 2))
	hook_counters(beast, arena)

/datum/bt_scenario/combat/sample(mob/living/simple_animal/beast, list/arena, list/metrics, elapsed)
	var/mob/living/victim = arena["victim"]
	if(isnull(metrics["first_target"]) && beast.ai_bb_get(BB_BASIC_MOB_CURRENT_TARGET))
		metrics["first_target"] = elapsed
	metrics["damage"] += bt_parity_hurt(victim)
	metrics["distance_sum"] += get_dist(beast, victim)
	metrics["samples"] += 1
	count_steps(beast, arena, metrics)
	read_counters(arena, metrics, elapsed)

/datum/bt_scenario/combat/finish(mob/living/simple_animal/beast, list/arena, list/metrics)
	fill_unreached(metrics, list("first_target", "first_attack"))
	metrics["mean_distance"] = metrics["samples"] ? metrics["distance_sum"] / metrics["samples"] : 0
	return ..()

/datum/bt_scenario/combat/wounded
	name = "wounded (fleeing)"
	one_per_tree = TRUE

/datum/bt_scenario/combat/wounded/setup(datum/unit_test/test, mob/living/simple_animal/beast, list/corner, list/arena)
	. = ..()
	beast.adjustBruteLoss(beast.maxHealth * 0.7)

/datum/bt_scenario/eating
	name = "eating"
	floors = list("corpse_eaten" = 5, "food_eaten" = 5, "steps" = 2)

/datum/bt_scenario/eating/setup(datum/unit_test/test, mob/living/simple_animal/beast, list/corner, list/arena)
	arena["watcher"] = bt_parity_arena_human(turf_at(test, corner, 0, BT_ARENA_SIZE - 1), godmode = TRUE)
	var/mob/living/simple_animal/hostile/retaliate/rogue/bt_verdant_test/corpse = new(turf_at(test, corner, BT_ARENA_SIZE - 2, BT_ARENA_SIZE - 2))
	corpse.death()
	arena["corpse"] = corpse
	var/list/foods = beast.ai_bb_get(BB_BASIC_FOODS)
	for(var/candidate in foods)
		if(ispath(candidate, /obj/item))
			arena["food"] = new candidate(turf_at(test, corner, BT_ARENA_SIZE - 2, 1))
			break

/datum/bt_scenario/eating/sample(mob/living/simple_animal/beast, list/arena, list/metrics, elapsed)
	var/atom/movable/corpse = arena["corpse"]
	if(isnull(metrics["corpse_eaten"]) && (QDELETED(corpse) || !isturf(corpse.loc)))
		metrics["corpse_eaten"] = elapsed
	var/atom/movable/food = arena["food"]
	if(food && isnull(metrics["food_eaten"]) && (QDELETED(food) || !isturf(food.loc)))
		metrics["food_eaten"] = elapsed
	count_steps(beast, arena, metrics)

/datum/bt_scenario/eating/finish(mob/living/simple_animal/beast, list/arena, list/metrics)
	fill_unreached(metrics, list("corpse_eaten", "food_eaten"))
	return ..()

/datum/bt_scenario/summon_follow
	name = "summon follows its summoner"
	floors = list("mean_distance" = 0.5, "steps" = 2, "attacks" = 1)

/datum/bt_scenario/summon_follow/setup(datum/unit_test/test, mob/living/simple_animal/beast, list/corner, list/arena)
	var/mob/living/carbon/human/summoner = bt_parity_arena_human(turf_at(test, corner, 3, 3), godmode = TRUE)
	arena["watcher"] = summoner
	beast.AddComponent(/datum/component/conjured_minion, summoner)
	hook_counters(beast, arena)
	var/list/walk = list()
	for(var/i in 1 to 6)
		walk += list(EAST, EAST, EAST, NORTH, NORTH, NORTH, WEST, WEST, WEST, SOUTH, SOUTH, SOUTH)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(bt_parity_walk), summoner, walk, 3)

/datum/bt_scenario/summon_follow/sample(mob/living/simple_animal/beast, list/arena, list/metrics, elapsed)
	metrics["distance_sum"] += get_dist(beast, arena["watcher"])
	metrics["samples"] += 1
	count_steps(beast, arena, metrics)
	read_counters(arena, metrics, elapsed)

/datum/bt_scenario/summon_follow/finish(mob/living/simple_animal/beast, list/arena, list/metrics)
	metrics["mean_distance"] = metrics["samples"] ? metrics["distance_sum"] / metrics["samples"] : 0
	return ..()

/datum/bt_scenario/summon_order
	var/order

/datum/bt_scenario/summon_order/attack
	name = "summon ordered to attack"
	order = "attack"
	floors = list("first_attack" = 4, "attacks" = 1, "damage" = 15, "steps" = 2)

/datum/bt_scenario/summon_order/goto_turf
	name = "summon ordered to a spot"
	order = "goto"
	floors = list("arrived" = 4, "steps" = 2)

/datum/bt_scenario/summon_order/setup(datum/unit_test/test, mob/living/simple_animal/beast, list/corner, list/arena)
	var/mob/living/carbon/human/summoner = bt_parity_arena_human(turf_at(test, corner, 0, BT_ARENA_SIZE - 1), godmode = TRUE)
	arena["watcher"] = summoner
	beast.AddComponent(/datum/component/conjured_minion, summoner)
	beast.faction |= "bt_parity_minions"
	hook_counters(beast, arena)
	var/datum/action/cooldown/spell/minion_order/spell = new(summoner)
	spell.Grant(summoner)
	arena["spell"] = spell
	var/turf/destination = turf_at(test, corner, BT_ARENA_SIZE - 2, 1)
	arena["destination"] = destination
	if(order == "attack")
		var/mob/living/carbon/human/target = bt_parity_arena_human(turf_at(test, corner, BT_ARENA_SIZE - 2, BT_ARENA_SIZE - 2), client_like = FALSE)
		arena["victim"] = target
		spell.process_minions(order_type = "attack", target = target, faction_tag = "bt_parity_minions")
	else
		spell.process_minions(order_type = "goto", target_location = destination, faction_tag = "bt_parity_minions")

/datum/bt_scenario/summon_order/sample(mob/living/simple_animal/beast, list/arena, list/metrics, elapsed)
	read_counters(arena, metrics, elapsed)
	metrics["damage"] += bt_parity_hurt(arena["victim"])
	if(isnull(metrics["arrived"]) && get_dist(beast, arena["destination"]) <= 1)
		metrics["arrived"] = elapsed
	count_steps(beast, arena, metrics)

/datum/bt_scenario/summon_order/finish(mob/living/simple_animal/beast, list/arena, list/metrics)
	fill_unreached(metrics, list("first_attack", "arrived"))
	qdel(arena["spell"])
	return ..()

/datum/bt_scenario/raised_target
	name = "commanded target (necromancer raise)"
	floors = list("first_attack" = 4, "attacks" = 1, "damage" = 15, "steps" = 2)

/datum/bt_scenario/raised_target/setup(datum/unit_test/test, mob/living/simple_animal/beast, list/corner, list/arena)
	arena["watcher"] = bt_parity_arena_human(turf_at(test, corner, 0, BT_ARENA_SIZE - 1), godmode = TRUE)
	var/mob/living/carbon/human/target = bt_parity_arena_human(turf_at(test, corner, BT_ARENA_SIZE - 2, BT_ARENA_SIZE - 2), client_like = FALSE)
	arena["victim"] = target
	hook_counters(beast, arena)
	beast.ai_bb_set(BB_BASIC_MOB_CURRENT_TARGET, target)
	beast.ai_bb_set(BB_HIGHEST_THREAT_MOB, target)

/datum/bt_scenario/raised_target/sample(mob/living/simple_animal/beast, list/arena, list/metrics, elapsed)
	read_counters(arena, metrics, elapsed)
	metrics["damage"] += bt_parity_hurt(arena["victim"])
	count_steps(beast, arena, metrics)

/datum/bt_scenario/raised_target/finish(mob/living/simple_animal/beast, list/arena, list/metrics)
	fill_unreached(metrics, list("first_attack"))
	return ..()

/datum/bt_scenario/migration
	floors = list("arrived" = 4, "closest" = 1, "steps" = 2)

/datum/bt_scenario/migration/wander
	name = "animal migration"

/datum/bt_scenario/migration/deadite
	name = "deadite migration"

/datum/bt_scenario/migration/setup(datum/unit_test/test, mob/living/simple_animal/beast, list/corner, list/arena)
	arena["watcher"] = bt_parity_arena_human(turf_at(test, corner, 0, BT_ARENA_SIZE - 1), godmode = TRUE)
	var/turf/waypoint = turf_at(test, corner, BT_ARENA_SIZE - 2, 1)
	var/turf/destination = turf_at(test, corner, BT_ARENA_SIZE - 2, BT_ARENA_SIZE - 2)
	arena["destination"] = destination
	if(istype(src, /datum/bt_scenario/migration/wander))
		beast.ai_bb_set(BB_WANDER_POINT, destination)
		beast.ai_append_subtree(/datum/ai_planning_subtree/travel_to_point/and_clear_target/wander)
	else
		beast.ai_append_subtree(/datum/ai_planning_subtree/deadite_migration)
		beast.ai_bb_set("deadite_migration_path", list(WEAKREF(waypoint), WEAKREF(destination)))
		beast.ai_bb_set("deadite_migration_target", waypoint)
		beast.ai_bb_set("deadite_travel_target", waypoint)

/datum/bt_scenario/migration/sample(mob/living/simple_animal/beast, list/arena, list/metrics, elapsed)
	var/distance = get_dist(beast, arena["destination"])
	if(isnull(metrics["closest"]) || distance < metrics["closest"])
		metrics["closest"] = distance
	if(isnull(metrics["arrived"]) && distance <= 1)
		metrics["arrived"] = elapsed
	count_steps(beast, arena, metrics)

/datum/bt_scenario/migration/finish(mob/living/simple_animal/beast, list/arena, list/metrics)
	fill_unreached(metrics, list("arrived"))
	return ..()

/datum/unit_test/bt_parity_all_controllers
	priority = TEST_LONGER
	var/current_step

/datum/unit_test/bt_parity_all_controllers/Run()
#ifndef BT_PARITY_FULL
	TEST_NOTICE(src, "skipped: build with BT_PARITY_FULL to run the full side-by-side parity suite")
#else
	try
		run_scenarios()
	catch(var/exception/e)
		TEST_FAIL("runtime in the parity run during [current_step]: [e.name] ([e.file]:[e.line])")
#endif

/datum/unit_test/bt_parity_all_controllers/proc/run_scenarios()
	var/list/all_types = bt_parity_converted_types()
	var/list/per_tree = bt_parity_one_per_tree(all_types)
	var/list/corners = list()
	for(var/y0 = -BT_ARENA_REACH; y0 + BT_ARENA_SIZE <= BT_ARENA_REACH; y0 += BT_ARENA_SPACING)
		for(var/x0 = -BT_ARENA_REACH; x0 + BT_ARENA_SIZE <= BT_ARENA_REACH; x0 += BT_ARENA_SPACING)
			if(x0 < 8 && x0 + BT_ARENA_SIZE > -3 && y0 < 8 && y0 + BT_ARENA_SIZE > -3)
				continue
			corners += list(list(x0, y0))
	var/list/turf/opened = list()
	for(var/list/corner as anything in corners)
		var/list/turf/arena_turfs = block(bt_test_turf(src, corner[1], corner[2]), bt_test_turf(src, corner[1] + BT_ARENA_SIZE - 1, corner[2] + BT_ARENA_SIZE - 1))
		for(var/turf/T as anything in arena_turfs)
			T.ChangeTurf(/turf/open/floor/rogue)
		opened += arena_turfs

	var/list/failures = list()
	var/scenario_count = 0
	for(var/scenario_type in subtypesof(/datum/bt_scenario))
		var/datum/bt_scenario/scenario = new scenario_type
		if(!scenario.name)
			continue
		scenario_count++
		var/list/types = scenario.one_per_tree ? per_tree : all_types
		var/list/results = list()
		var/per_batch = round(length(corners) / 2)
		for(var/run in 1 to BT_ARENA_RUNS)
			for(var/batch_start = 1; batch_start <= length(types); batch_start += per_batch)
				var/list/batch = types.Copy(batch_start, min(batch_start + per_batch, length(types) + 1))
				var/list/arenas = list()
				var/slot = 0
				for(var/mob_type in batch)
					var/list/sides = (run % 2) ? list("tree", "controller") : list("controller", "tree")
					for(var/side in sides)
						slot++
						var/list/corner = corners[slot]
						var/mob/living/simple_animal/beast
						current_step = "[scenario.name]: setting up [mob_type] ([side])"
						var/list/arena = list()
						try
							if(side == "controller")
								beast = bt_parity_spawn_controller(mob_type, bt_test_turf(src, corner[1] + 1, corner[2] + 1))
							else
								beast = new mob_type(bt_test_turf(src, corner[1] + 1, corner[2] + 1))
							if(side == "controller" && !beast.ai_controller)
								CRASH("controller spawn of [mob_type] has no controller")
							arena["last_x"] = beast.x
							arena["last_y"] = beast.y
							scenario.setup(src, beast, corner, arena)
						catch(var/exception/setup_error)
							failures |= "[scenario.name]: [mob_type] ([side]) could not be set up: [setup_error.name]"
							continue
						var/list/metrics = list()
						if(!results[mob_type])
							results[mob_type] = list("tree" = list(), "controller" = list())
						var/list/side_results = results[mob_type][side]
						side_results += list(metrics)
						arena["beast"] = beast
						arena["metrics"] = metrics
						arenas += list(arena)

				current_step = "[scenario.name]: run [run], batch from [batch_start]"
				var/start = world.time
				while(world.time < start + BT_ARENA_RUN)
					for(var/list/arena as anything in arenas)
						var/mob/living/simple_animal/beast = arena["beast"]
						if(QDELETED(beast))
							continue
						scenario.sample(beast, arena, arena["metrics"], world.time - start)
					sleep(world.tick_lag)

				current_step = "[scenario.name]: clearing run [run], batch from [batch_start]"
				for(var/list/arena as anything in arenas)
					scenario.finish(arena["beast"], arena, arena["metrics"])
					for(var/key in list("victim", "watcher"))
						var/mob/living/carbon/human/H = arena[key]
						if(H && !QDELETED(H))
							H.clear_important_client_contents()
				for(var/turf/T as anything in opened)
					for(var/atom/movable/AM in T)
						qdel(AM)
				sleep(1)

		for(var/mob_type in results)
			var/list/tree_runs = results[mob_type]["tree"]
			var/list/controller_runs = results[mob_type]["controller"]
			if(length(tree_runs) != BT_ARENA_RUNS || length(controller_runs) != BT_ARENA_RUNS)
				failures += "[scenario.name]: [mob_type]: incomplete runs ([length(tree_runs)] tree, [length(controller_runs)] controller)"
				continue
			var/list/line = list()
			var/list/differs = list()
			for(var/metric in scenario.floors)
				var/list/tree_values = list()
				var/list/controller_values = list()
				for(var/list/metrics as anything in tree_runs)
					tree_values += metrics[metric]
				for(var/list/metrics as anything in controller_runs)
					controller_values += metrics[metric]
				line += "[metric] [round(bt_parity_mean(tree_values), 0.1)]/[round(bt_parity_mean(controller_values), 0.1)] (sd [round(sqrt(bt_parity_variance(tree_values)), 0.1)]/[round(sqrt(bt_parity_variance(controller_values)), 0.1)])"
				if(!bt_parity_same(tree_values, controller_values, scenario.floors[metric]))
					differs += metric
			var/report = "[scenario.name]: [mob_type]: [jointext(line, ", ")]"
			bt_parity_report("[report][length(differs) ? " DIFFERS: [jointext(differs, ", ")]" : ""]")
			if(length(differs))
				failures += "[report] -- differs in [jointext(differs, ", ")]"

	for(var/turf/T as anything in opened)
		T.ChangeTurf(/turf/closed/basic)
	TEST_ASSERT(!length(failures), "[length(failures)] tree/controller differences across [scenario_count] scenarios ([BT_ARENA_RUNS] runs each side):\n[jointext(failures, "\n")]")

/datum/unit_test/bt_parity_starting_blackboards

/datum/unit_test/bt_parity_starting_blackboards/Run()
	var/list/differences = list()
	for(var/mob_type in bt_parity_converted_types())
		var/mob/living/simple_animal/controller_mob = bt_parity_spawn_controller(mob_type, run_loc_floor_bottom_left)
		var/mob/living/simple_animal/tree_mob = new mob_type(run_loc_floor_top_right)
		if(!controller_mob.ai_controller || !tree_mob.ai_root?.planner)
			differences += "[mob_type]: spawned without the expected AI (controller [controller_mob.ai_controller], tree [tree_mob.ai_root?.planner])"
		else
			var/list/controller_board = controller_mob.ai_controller.blackboard
			var/list/tree_board = tree_mob.ai_root.blackboard
			for(var/key in controller_board | tree_board)
				var/controller_value = bt_parity_value_repr(controller_board[key])
				var/tree_value = bt_parity_value_repr(tree_board[key])
				if(controller_value != tree_value)
					differences += "[mob_type]: [key] is [controller_value] on the controller, [tree_value] on the tree"
			if(controller_mob.ai_controller.ai_status != tree_mob.ai_root.ai_status)
				differences += "[mob_type]: starts [controller_mob.ai_controller.ai_status] on the controller, [tree_mob.ai_root.ai_status] on the tree"
		qdel(controller_mob)
		qdel(tree_mob)
	TEST_ASSERT(!length(differences), "[length(differences)] starting differences:\n[jointext(differences, "\n")]")

/datum/unit_test/bt_no_simple_controllers_left

/datum/unit_test/bt_no_simple_controllers_left/Run()
	for(var/mob_type in subtypesof(/mob/living/simple_animal))
		var/mob/living/simple_animal/candidate = mob_type
		if(findtext("[mob_type]", "bt_parity") || findtext("[mob_type]", "bt_temp"))
			continue
		if(initial(candidate.ai_controller))
			TEST_FAIL("[mob_type] still uses [initial(candidate.ai_controller)]")

#undef BT_ARENA_SIZE
#undef BT_ARENA_SPACING
#undef BT_ARENA_REACH
#undef BT_ARENA_RUN
#undef BT_ARENA_RUNS
#undef BT_ARENA_Z
