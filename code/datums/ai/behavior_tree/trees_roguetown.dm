// ==============================================================================
// ROGUETOWN BEHAVIOR TREES
// ==============================================================================

// ------------------------------------------------------------------------------
// NODE ACTIONS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/action/pick_best_target

	my_action = /bt_action/pick_best_target

/datum/behavior_tree/node/action/switch_to_aggressor

	my_action = /bt_action/switch_to_aggressor

/datum/behavior_tree/node/action/set_movement_target

	my_action = /bt_action/set_movement_target

/datum/behavior_tree/node/action/check_path_progress

	my_action = /bt_action/check_path_progress

/datum/behavior_tree/node/action/face_target

	my_action = /bt_action/face_target

/datum/behavior_tree/node/action/do_melee_attack

	my_action = /bt_action/do_melee_attack

/datum/behavior_tree/node/action/do_ranged_attack

	my_action = /bt_action/do_ranged_attack

/datum/behavior_tree/node/action/clear_target

	my_action = /bt_action/clear_target

/datum/behavior_tree/node/action/has_valid_target

	my_action = /bt_action/has_valid_target

/datum/behavior_tree/node/action/maintain_distance

	my_action = /bt_action/maintain_distance

/datum/behavior_tree/node/action/flee_target

	my_action = /bt_action/flee_target

/datum/behavior_tree/node/action/target_in_range

	my_action = /bt_action/target_in_range

/datum/behavior_tree/node/action/idle_wander

	my_action = /bt_action/idle_wander

/datum/behavior_tree/node/action/idle_chatter
	my_action = /bt_action/idle_chatter

/datum/behavior_tree/node/action/try_ranged_attack
	my_action = /bt_action/do_ranged_attack/passthrough

/datum/behavior_tree/node/action/keep_distance
	my_action = /bt_action/keep_distance

/datum/behavior_tree/node/action/move_to_target

	my_action = /bt_action/move_to_target

/datum/behavior_tree/node/action/move_to_destination

	my_action = /bt_action/move_to_destination

/datum/behavior_tree/node/action/find_food

	my_action = /bt_action/find_food

/datum/behavior_tree/node/action/eat_food

	my_action = /bt_action/eat_food

/datum/behavior_tree/node/action/check_hunger

	my_action = /bt_action/check_hunger

/datum/behavior_tree/node/action/eat_dead_body

	my_action = /bt_action/eat_dead_body

/datum/behavior_tree/node/action/find_dead_body

	my_action = /bt_action/find_dead_body

/datum/behavior_tree/node/action/destroy_path

	my_action = /bt_action/destroy_path

// ------------------------------------------------------------------------------
// SERVICES & OBSERVERS
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/decorator/service/target_scanner/hostile
	search_objects = FALSE
	scan_range = 7

/datum/behavior_tree/node/decorator/service/target_scanner/hungry
	search_objects = TRUE
	scan_range = 7

/datum/behavior_tree/node/decorator/service/aggressor_manager

/datum/behavior_tree/node/decorator/observer/aggressor_reaction
	observed_signal = COMSIG_AI_ATTACKED

/datum/behavior_tree/node/decorator/observer/pain_crit

/datum/behavior_tree/node/action/flee_while_injured
	my_action = /bt_action/flee_target/injured

/datum/behavior_tree/node/decorator/observer/self_preservation/injury_flee_wrapper
	reaction = TRUE
	child = /datum/behavior_tree/node/action/flee_while_injured

/datum/behavior_tree/node/decorator/service/lamia_sneak
	interval = 3 SECONDS

/datum/behavior_tree/node/decorator/service/lamia_sneak/service_tick(mob/living/npc, list/blackboard)
	var/mob/living/simple_animal/hostile/retaliate/rogue/lamia/L = npc
	if(!istype(L)) return
	if(L.sneaking || world.time < L.sneak_cooldown) return
	var/turf/T = get_turf(L)
	if(!T) return
	if(T.get_lumcount() < SHADOW_SPECIES_LIGHT_THRESHOLD)
		L.sneak_now()

// ------------------------------------------------------------------------------
// SUB-TREES (SEQUENCES & SELECTORS)
// ------------------------------------------------------------------------------

// TARGET ACQUISITION
/datum/behavior_tree/node/selector/acquire_target
	my_nodes = list(
		/datum/behavior_tree/node/decorator/progress_validator/target_persistence/simple_has_target_wrapped,
		/datum/behavior_tree/node/action/switch_to_aggressor,
		/datum/behavior_tree/node/action/pick_best_target
	)

/datum/behavior_tree/node/decorator/progress_validator/target_persistence/simple_has_target_wrapped
	child = /datum/behavior_tree/node/action/has_valid_target
	persistence_time = 4 SECONDS

// ATTACK SEQUENCE
/datum/behavior_tree/node/sequence/attack_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/face_target,
		/datum/behavior_tree/node/action/target_in_range,
		/datum/behavior_tree/node/action/do_melee_attack
	)

// ENGAGE TARGET
/datum/behavior_tree/node/selector/engage_target
	my_nodes = list(
		/datum/behavior_tree/node/action/keep_distance,
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/try_ranged_attack,
		/datum/behavior_tree/node/action/move_to_target,
		/datum/behavior_tree/node/sequence/simple_pursue_search
	)

// Pursue/Search Sequence
/datum/behavior_tree/node/sequence/simple_pursue_search
	my_nodes = list(
		/datum/behavior_tree/node/decorator/timeout/simple_pursue_last_known,
		/datum/behavior_tree/node/decorator/timeout/simple_search_area_wrapped
	)

/datum/behavior_tree/node/action/simple_animal_pursue_last_known_action
	my_action = /bt_action/simple_animal_pursue_last_known

/datum/behavior_tree/node/action/simple_animal_search_area_action
	my_action = /bt_action/simple_animal_search_area

/datum/behavior_tree/node/decorator/timeout/simple_pursue_last_known
	child = /datum/behavior_tree/node/action/simple_animal_pursue_last_known_action
	limit = 10 SECONDS

/datum/behavior_tree/node/decorator/timeout/simple_search_area_wrapped
	child = /datum/behavior_tree/node/action/simple_animal_search_area_action
	limit = 10 SECONDS

// COMBAT LOOP
/datum/behavior_tree/node/sequence/combat
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/selector/engage_target
	)

// IDLE LOOP
/datum/behavior_tree/node/sequence/idle
	my_nodes = list(
		/datum/behavior_tree/node/action/idle_chatter,
		/datum/behavior_tree/node/action/idle_wander
	)

// SCAVENGE LOOP
/datum/behavior_tree/node/sequence/scavenge
	my_nodes = list(
		/datum/behavior_tree/node/action/check_hunger,
		/datum/behavior_tree/node/action/find_food,
		/datum/behavior_tree/node/action/eat_food
	)

/datum/behavior_tree/node/sequence/corpse_scavenge
	my_nodes = list(
		/datum/behavior_tree/node/action/find_dead_body,
		/datum/behavior_tree/node/action/eat_dead_body
	)

// ------------------------------------------------------------------------------
// SPECIALIZED SEQUENCES
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/selector/attack_choice_direbear
	my_nodes = list(
		/datum/behavior_tree/node/action/use_ability,
		/datum/behavior_tree/node/action/do_melee_attack
	)

/datum/behavior_tree/node/sequence/attack_sequence_direbear
	my_nodes = list(
		/datum/behavior_tree/node/action/target_in_range,
		/datum/behavior_tree/node/selector/attack_choice_direbear
	)

/datum/behavior_tree/node/selector/engage_target_direbear
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence_direbear,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_direbear
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_direbear_wrapped
	)

/datum/behavior_tree/node/decorator/observer/target_death/engage_direbear_wrapped
	child = /datum/behavior_tree/node/selector/engage_target_direbear

/datum/behavior_tree/node/selector/engage_target_ranged
	my_nodes = list(
		/datum/behavior_tree/node/action/do_ranged_attack,
		/datum/behavior_tree/node/sequence/attack_sequence, // Fallback
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_ranged
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_ranged_wrapped
	)

/datum/behavior_tree/node/decorator/observer/target_death/engage_ranged_wrapped
	child = /datum/behavior_tree/node/selector/engage_target_ranged

/datum/behavior_tree/node/sequence/idle_mimic
	my_nodes = list(
		/datum/behavior_tree/node/action/mimic_disguise,
		/datum/behavior_tree/node/action/pick_best_target
	)

/datum/behavior_tree/node/sequence/combat_mimic
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/action/mimic_undisguise,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_mimic_wrapped
	)

/datum/behavior_tree/node/decorator/observer/target_death/engage_mimic_wrapped
	child = /datum/behavior_tree/node/selector/engage_target

/datum/behavior_tree/node/action/maintain_distance_hold2
	my_action = /bt_action/maintain_distance/hold2

/datum/behavior_tree/node/action/target_in_range_reach2
	my_action = /bt_action/target_in_range/reach2

/datum/behavior_tree/node/sequence/attack_sequence_spacing
	my_nodes = list(
		/datum/behavior_tree/node/action/maintain_distance_hold2,
		/datum/behavior_tree/node/action/target_in_range_reach2,
		/datum/behavior_tree/node/action/do_melee_attack
	)

/datum/behavior_tree/node/selector/engage_target_skeleton
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/selector/engage_target_skeleton_spear
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence_spacing,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_skeleton
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_skeleton_wrapped
	)

/datum/behavior_tree/node/decorator/observer/target_death/engage_skeleton_wrapped
	child = /datum/behavior_tree/node/selector/engage_target_skeleton

/datum/behavior_tree/node/sequence/combat_skeleton_spear
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_skeleton_spear_wrapped
	)

/datum/behavior_tree/node/decorator/observer/target_death/engage_skeleton_spear_wrapped
	child = /datum/behavior_tree/node/selector/engage_target_skeleton_spear

/datum/behavior_tree/node/selector/engage_target_orc
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_orc
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/action/call_reinforcements,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_orc_wrapped
	)

/datum/behavior_tree/node/decorator/observer/target_death/engage_orc_wrapped
	child = /datum/behavior_tree/node/selector/engage_target_orc

/datum/behavior_tree/node/selector/engage_target_orc_spear
	my_nodes = list(
		/datum/behavior_tree/node/sequence/attack_sequence_spacing,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_orc_spear
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_orc_spear_wrapped
	)

/datum/behavior_tree/node/decorator/observer/target_death/engage_orc_spear_wrapped
	child = /datum/behavior_tree/node/selector/engage_target_orc_spear

/datum/behavior_tree/node/sequence/combat_volf
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/decorator/cooldown/call_reinforcements_wrapper,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_volf_wrapped
	)

/datum/behavior_tree/node/decorator/cooldown/call_reinforcements_wrapper
	child = /datum/behavior_tree/node/action/call_reinforcements
	cooldown_time = 2 SECONDS

/datum/behavior_tree/node/decorator/observer/target_death/engage_volf_wrapped
	child = /datum/behavior_tree/node/selector/engage_target

// ------------------------------------------------------------------------------
// HOSTILE TREES
// ------------------------------------------------------------------------------

// GENERIC HOSTILE
/datum/behavior_tree/node/selector/generic_hostile_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/hostile_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/hostile_wrapper
	child = /datum/behavior_tree/node/decorator/service/chatter/hostile_chatter

/datum/behavior_tree/node/decorator/service/chatter/hostile_chatter
	child = /datum/behavior_tree/node/selector/generic_hostile_tree_logic

/datum/behavior_tree/node/selector/generic_hostile_tree_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/self_preservation/flee_wrapper,
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper
	reaction = TRUE
	child = /datum/behavior_tree/node/action/clear_target // Force re-eval

/datum/behavior_tree/node/decorator/observer/self_preservation/flee_wrapper
	reaction = TRUE
	child = /datum/behavior_tree/node/action/flee_target // Run away!

/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper
	reaction = TRUE
	child = /datum/behavior_tree/node/action/destroy_path

// GENERIC HUNGRY HOSTILE
/datum/behavior_tree/node/selector/generic_hungry_hostile_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/hungry_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/hungry_wrapper
	child = /datum/behavior_tree/node/decorator/service/chatter/hungry_chatter

/datum/behavior_tree/node/decorator/service/chatter/hungry_chatter
	child = /datum/behavior_tree/node/selector/generic_hungry_logic

/datum/behavior_tree/node/selector/generic_hungry_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/corpse_scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

// GENERIC FRIENDLY (Just needs aggressor manager maybe? Or minimal scanner)
// Friendly usually means "defends owner" or "flees" or "wanders"
/datum/behavior_tree/node/selector/generic_friendly_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile // Scan for threats
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/friendly_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/friendly_wrapper
	child = /datum/behavior_tree/node/decorator/service/chatter/friendly_chatter

/datum/behavior_tree/node/decorator/service/chatter/friendly_chatter
	child = /datum/behavior_tree/node/selector/generic_friendly_logic

/datum/behavior_tree/node/selector/generic_friendly_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

// ------------------------------------------------------------------------------
// SPECIALIZED TREES (WRAPPED)
// ------------------------------------------------------------------------------

// DIREBEAR
/datum/behavior_tree/node/selector/direbear_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/direbear_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/direbear_wrapper
	child = /datum/behavior_tree/node/selector/direbear_logic

/datum/behavior_tree/node/selector/direbear_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_direbear,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

// DEEPONE MELEE
/datum/behavior_tree/node/selector/deepone_melee_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/deepone_melee_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/deepone_melee_wrapper
	child = /datum/behavior_tree/node/selector/deepone_melee_logic

/datum/behavior_tree/node/selector/deepone_melee_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

// DEEPONE RANGED
/datum/behavior_tree/node/selector/deepone_ranged_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/deepone_ranged_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/deepone_ranged_wrapper
	child = /datum/behavior_tree/node/selector/deepone_ranged_logic

/datum/behavior_tree/node/selector/deepone_ranged_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_ranged,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

// HAUNT
/datum/behavior_tree/node/selector/haunt_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/haunt_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/haunt_wrapper
	child = /datum/behavior_tree/node/selector/haunt_logic

/datum/behavior_tree/node/selector/haunt_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

// MIMIC
/datum/behavior_tree/node/selector/mimic_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/mimic_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/mimic_wrapper
	child = /datum/behavior_tree/node/selector/mimic_logic

/datum/behavior_tree/node/selector/mimic_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_mimic,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle_mimic
	)

// DREAMFIEND
// SKELETON
/datum/behavior_tree/node/selector/skeleton_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/skeleton_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/skeleton_wrapper
	child = /datum/behavior_tree/node/selector/skeleton_logic

/datum/behavior_tree/node/selector/skeleton_logic
	my_nodes = list(
		/datum/behavior_tree/node/action/minion_follow,
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/combat_skeleton,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

// SKELETON SPEAR
/datum/behavior_tree/node/selector/skeleton_spear_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/skeleton_spear_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/skeleton_spear_wrapper
	child = /datum/behavior_tree/node/selector/skeleton_spear_logic

/datum/behavior_tree/node/selector/skeleton_spear_logic
	my_nodes = list(
		/datum/behavior_tree/node/action/minion_follow,
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/combat_skeleton_spear,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

// ORC
/datum/behavior_tree/node/selector/orc_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/orc_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/orc_wrapper
	child = /datum/behavior_tree/node/decorator/service/chatter/orc_chatter

/datum/behavior_tree/node/decorator/service/chatter/orc_chatter
	child = /datum/behavior_tree/node/selector/orc_logic

/datum/behavior_tree/node/selector/orc_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/combat_orc,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

// ORC SPEAR/ELITE
/datum/behavior_tree/node/selector/orc_spear_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/orc_spear_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/orc_spear_wrapper
	child = /datum/behavior_tree/node/decorator/service/chatter/orc_spear_chatter

/datum/behavior_tree/node/decorator/service/chatter/orc_spear_chatter
	child = /datum/behavior_tree/node/selector/orc_spear_logic

/datum/behavior_tree/node/selector/orc_spear_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/combat_orc_spear,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

// VOLF
/datum/behavior_tree/node/selector/volf_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/volf_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/volf_wrapper
	child = /datum/behavior_tree/node/decorator/service/health_monitor/volf_health_wrapper

/datum/behavior_tree/node/decorator/service/health_monitor/volf_health_wrapper
	threshold = 0.4
	child = /datum/behavior_tree/node/decorator/service/chatter/volf_chatter

/datum/behavior_tree/node/decorator/service/chatter/volf_chatter
	child = /datum/behavior_tree/node/selector/volf_logic

/datum/behavior_tree/node/selector/volf_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/self_preservation/injury_flee_wrapper,
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/combat_volf,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/corpse_scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

// BIGRAT
/datum/behavior_tree/node/selector/bigrat_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/bigrat_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/bigrat_wrapper
	child = /datum/behavior_tree/node/decorator/service/health_monitor/bigrat_health_wrapper

/datum/behavior_tree/node/decorator/service/health_monitor/bigrat_health_wrapper
	threshold = 0.3
	child = /datum/behavior_tree/node/decorator/service/chatter/bigrat_chatter

/datum/behavior_tree/node/decorator/service/chatter/bigrat_chatter
	child = /datum/behavior_tree/node/selector/bigrat_logic

/datum/behavior_tree/node/selector/bigrat_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/self_preservation/injury_flee_wrapper,
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/corpse_scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

// SUMMONS (Colossus, Behemoth, etc)
// Assuming they use target scanner too (to find stuff to smash/kill)

/datum/behavior_tree/node/selector/leyline_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/leyline_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/leyline_wrapper
	child = /datum/behavior_tree/node/selector/leyline_logic

/datum/behavior_tree/node/selector/leyline_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_leyline,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/engage_target_leyline
	my_nodes = list(
		/datum/behavior_tree/node/action/leyline_teleport,
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_leyline
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_leyline_wrapped
	)

/datum/behavior_tree/node/decorator/observer/target_death/engage_leyline_wrapped
	child = /datum/behavior_tree/node/selector/engage_target_leyline

/datum/behavior_tree/node/selector/obelisk_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/obelisk_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/obelisk_wrapper
	child = /datum/behavior_tree/node/selector/obelisk_logic

/datum/behavior_tree/node/selector/obelisk_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat_obelisk,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

/datum/behavior_tree/node/selector/engage_target_obelisk
	my_nodes = list(
		/datum/behavior_tree/node/action/obelisk_activate,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_obelisk
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_obelisk_wrapped
	)

/datum/behavior_tree/node/decorator/observer/target_death/engage_obelisk_wrapped
	child = /datum/behavior_tree/node/selector/engage_target_obelisk

// CHICKEN
// MIRESPIDER
/datum/behavior_tree/node/selector/mirespider_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/mirespider_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/mirespider_wrapper
	child = /datum/behavior_tree/node/decorator/service/chatter/mirespider_chatter

/datum/behavior_tree/node/decorator/service/chatter/mirespider_chatter
	child = /datum/behavior_tree/node/selector/mirespider_logic

/datum/behavior_tree/node/action/follow_lurker
	my_action = /bt_action/follow_target/mirespider

/datum/behavior_tree/node/selector/mirespider_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/action/follow_lurker,
		/datum/behavior_tree/node/sequence/idle
	)

// MIRESPIDER LURKER
/datum/behavior_tree/node/action/find_cocoon_target
	my_action = /bt_action/find_cocoon_target

/datum/behavior_tree/node/action/mark_cocoon_target
	my_action = /bt_action/mark_cocoon_target

/datum/behavior_tree/node/action/cocoon_target
	my_action = /bt_action/cocoon_target

/datum/behavior_tree/node/sequence/cocoon_current_target_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/mark_cocoon_target,
		/datum/behavior_tree/node/action/cocoon_target
	)

/datum/behavior_tree/node/sequence/cocoon_sequence
	my_nodes = list(
		/datum/behavior_tree/node/action/find_cocoon_target,
		/datum/behavior_tree/node/action/cocoon_target
	)

/datum/behavior_tree/node/selector/engage_target_mirespider_lurker
	my_nodes = list(
		/datum/behavior_tree/node/sequence/cocoon_current_target_sequence,
		/datum/behavior_tree/node/action/do_ranged_attack,
		/datum/behavior_tree/node/sequence/attack_sequence,
		/datum/behavior_tree/node/action/move_to_target
	)

/datum/behavior_tree/node/sequence/combat_mirespider_lurker
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/decorator/observer/target_death/engage_mirespider_lurker_wrapped
	)

/datum/behavior_tree/node/decorator/observer/target_death/engage_mirespider_lurker_wrapped
	child = /datum/behavior_tree/node/selector/engage_target_mirespider_lurker

/datum/behavior_tree/node/decorator/service/lurker_clear_followers
	interval = 2 SECONDS

/datum/behavior_tree/node/decorator/service/lurker_clear_followers/service_tick(mob/living/npc, list/blackboard)
	var/mob/living/simple_animal/hostile/rogue/mirespider_lurker/L = npc
	if(!istype(L)) return
	if(npc.ai_root.target)
		L.clear_followers_if_any()

/datum/behavior_tree/node/selector/mirespider_lurker_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/mirespider_lurker_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/mirespider_lurker_wrapper
	child = /datum/behavior_tree/node/decorator/service/chatter/mirespider_lurker_chatter

/datum/behavior_tree/node/decorator/service/chatter/mirespider_lurker_chatter
	child = /datum/behavior_tree/node/decorator/service/lurker_clear_followers/mirespider_lurker_clear_wrapper

/datum/behavior_tree/node/decorator/service/lurker_clear_followers/mirespider_lurker_clear_wrapper
	child = /datum/behavior_tree/node/selector/mirespider_lurker_logic

/datum/behavior_tree/node/selector/mirespider_lurker_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/sequence/cocoon_sequence,
		/datum/behavior_tree/node/sequence/combat_mirespider_lurker,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

// MIRESPIDER PARALYTIC
/datum/behavior_tree/node/selector/mirespider_paralytic_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/mirespider_paralytic_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/mirespider_paralytic_wrapper
	child = /datum/behavior_tree/node/decorator/service/chatter/mirespider_paralytic_chatter

/datum/behavior_tree/node/decorator/service/chatter/mirespider_paralytic_chatter
	child = /datum/behavior_tree/node/selector/mirespider_paralytic_logic

/datum/behavior_tree/node/selector/mirespider_paralytic_logic
	my_nodes = list(
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/cocoon_sequence,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

// MOSSBACK
/datum/behavior_tree/node/selector/mossback_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hungry
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/mossback_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/mossback_wrapper
	child = /datum/behavior_tree/node/decorator/service/chatter/mossback_chatter

/datum/behavior_tree/node/decorator/service/chatter/mossback_chatter
	child = /datum/behavior_tree/node/selector/mossback_logic

/datum/behavior_tree/node/selector/mossback_logic
	my_nodes = list(
		/datum/behavior_tree/node/action/minion_follow,
		/datum/behavior_tree/node/decorator/observer/aggressor_reaction/reaction_wrapper,
		/datum/behavior_tree/node/decorator/observer/path_blocked/smash_wrapper,
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/scavenge,
		/datum/behavior_tree/node/sequence/idle
	)

// WOLF UNDEAD
/datum/behavior_tree/node/selector/wolf_undead_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/wolf_undead_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/wolf_undead_wrapper
	child = /datum/behavior_tree/node/selector/wolf_undead_logic

/datum/behavior_tree/node/selector/wolf_undead_logic
	my_nodes = list(
		/datum/behavior_tree/node/sequence/combat,
		/datum/behavior_tree/node/action/deadite_migrate,
		/datum/behavior_tree/node/decorator/retry/move_to_dest_retry,
		/datum/behavior_tree/node/sequence/idle
	)

// LAMIA
/datum/behavior_tree/node/selector/lamia_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/lamia_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/lamia_wrapper
	child = /datum/behavior_tree/node/decorator/service/chatter/lamia_chatter

/datum/behavior_tree/node/decorator/service/chatter/lamia_chatter
	child = /datum/behavior_tree/node/decorator/service/lamia_sneak/lamia_sneak_wrapper

/datum/behavior_tree/node/decorator/service/lamia_sneak/lamia_sneak_wrapper
	child = /datum/behavior_tree/node/selector/generic_hostile_tree_logic

// INSANE CLOWN
/datum/behavior_tree/node/selector/insane_clown_tree
	parent_type = /datum/behavior_tree/node/decorator/service/target_scanner/hostile
	child = /datum/behavior_tree/node/decorator/service/aggressor_manager/clown_wrapper

/datum/behavior_tree/node/decorator/service/aggressor_manager/clown_wrapper
	child = /datum/behavior_tree/node/selector/insane_clown_logic

/datum/behavior_tree/node/selector/insane_clown_logic
	my_nodes = list(
		/datum/behavior_tree/node/selector/acquire_target,
		/datum/behavior_tree/node/sequence/idle
	)

// ------------------------------------------------------------------------------
// HELPER NODES
// ------------------------------------------------------------------------------

/datum/behavior_tree/node/action/simple_animal_pursue_last_known_action
	my_action = /bt_action/simple_animal_pursue_last_known

/datum/behavior_tree/node/action/simple_animal_search_area_action
	my_action = /bt_action/simple_animal_search_area

/datum/behavior_tree/node/action/minion_follow
	my_action = /bt_action/minion_follow

/datum/behavior_tree/node/action/deadite_migrate
	my_action = /bt_action/deadite_migrate

/datum/behavior_tree/node/action/leyline_teleport
	my_action = /bt_action/leyline_teleport

/datum/behavior_tree/node/action/obelisk_activate
	my_action = /bt_action/obelisk_activate

/datum/behavior_tree/node/action/mimic_disguise
	my_action = /bt_action/mimic_disguise

/datum/behavior_tree/node/action/mimic_undisguise
	my_action = /bt_action/mimic_undisguise

/datum/behavior_tree/node/action/use_ability
	my_action = /bt_action/use_ability

/datum/behavior_tree/node/action/call_reinforcements
	my_action = /bt_action/call_reinforcements

/datum/behavior_tree/node/decorator/retry/move_to_dest_retry
	child = /datum/behavior_tree/node/action/move_to_destination
	cooldown = 5 SECONDS
	max_failures = 1
