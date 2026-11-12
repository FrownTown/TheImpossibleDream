/// Base human NPC controller. Holds infrastructure shared by all humanoid NPC archetypes:
/// movement settings, targeting, common subtrees, and signal wiring. Do not assign this
/// controller directly — use /melee or /archer subtypes.
/datum/behavior_tree/node/planner/human_npc
	converted_from = /datum/ai_controller/human_npc
	max_target_distance = 13
	ai_movement = /datum/bt_movement/hybrid_pathing
	initial_blackboard = list(
		BB_WEAPON_TYPE = /obj/item/rogueweapon,
		BB_ARMOR_CLASS = 2,
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic(),
		BB_PET_TARGETING_DATUM = new /datum/targetting_datum/basic/not_friends(),

		BB_HUMAN_NPC_SWINGS_TAKEN = 0,			// swings this engagement, gates the special opener
		BB_HUMAN_NPC_SWINGS_TARGET = null,		// who the above is counting against
		BB_HUMAN_NPC_ZONE_COMMIT_COUNTER = 0,	// swings spent on the current self-picked zone
		BB_HUMAN_NPC_LAST_ATTACK_ZONE = null,	// last zone we attacked
		BB_HUMAN_NPC_WEAKPOINT = null,			// cached weakpoint zone if we found one
		BB_HUMAN_NPC_JUMP_COOLDOWN = 0,		// world.time when we can next jump
		BB_HUMAN_NPC_HARASS_MODE = FALSE,		// TRUE when in hit-and-run mode
		BB_HUMAN_NPC_HARASS_RETREATING = FALSE,// TRUE when in the back-off phase of harass
		BB_HUMAN_NPC_HARASS_COOLDOWN = 0,		// world.time before we can dart in again
	)
	/// Subtrees shared by all human NPC archetypes. Subtypes prepend archetype-specific
	/// subtrees via their own planning_subtrees list.
	my_nodes = list(
		// /datum/behavior_tree/node/subtree/pet_planning, - TEMP COMMENT OUT
		/datum/behavior_tree/node/subtree/being_a_minion,
		/datum/behavior_tree/node/subtree/call_for_help,
		/datum/behavior_tree/node/subtree/generic_break_restraints,
		/datum/behavior_tree/node/subtree/use_throwable,
		/datum/behavior_tree/node/subtree/generic_wield,
		/datum/behavior_tree/node/subtree/kick_attack,
		/datum/behavior_tree/node/subtree/generic_resist,
		/datum/behavior_tree/node/subtree/generic_stand,
		/datum/behavior_tree/node/subtree/flee_target,
		/datum/behavior_tree/node/subtree/tree_climb,
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/leap_attack,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/human_npc,
		/datum/behavior_tree/node/subtree/find_weapon,
		/datum/behavior_tree/node/subtree/equip_item,
		/datum/behavior_tree/node/subtree/loot,
	)


/// Melee-only human NPC. Same as base — the base class is already melee-focused since it
/datum/behavior_tree/node/planner/human_npc/melee
	converted_from = /datum/ai_controller/human_npc/melee


/// Archer human NPC. Adds archer-specific planning subtrees and blackboard keys on top of
/// the base. Uses the same melee subtree as a fallback when out of ammo / in melee range.
/datum/behavior_tree/node/planner/human_npc/archer
	converted_from = /datum/ai_controller/human_npc/archer
	initial_blackboard = list(
		BB_WEAPON_TYPE = /obj/item/rogueweapon,
		BB_ARMOR_CLASS = 2,
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic(),
		BB_PET_TARGETING_DATUM = new /datum/targetting_datum/basic/not_friends(),

		BB_HUMAN_NPC_SWINGS_TAKEN = 0,
		BB_HUMAN_NPC_SWINGS_TARGET = null,
		BB_HUMAN_NPC_ZONE_COMMIT_COUNTER = 0,
		BB_HUMAN_NPC_LAST_ATTACK_ZONE = null,
		BB_HUMAN_NPC_WEAKPOINT = null,
		BB_HUMAN_NPC_JUMP_COOLDOWN = 0,
		BB_HUMAN_NPC_HARASS_MODE = FALSE,
		BB_HUMAN_NPC_HARASS_RETREATING = FALSE,
		BB_HUMAN_NPC_HARASS_COOLDOWN = 0,

		// Archer-specific state — only relevant to mobs that carry a bow
		BB_ARCHER_NPC_BOW = null,
		BB_ARCHER_NPC_QUIVER = null,
		BB_ARCHER_NPC_EQUIPMENT_CACHE_EXPIRY = 0,
		BB_ARCHER_NPC_TARGET_ARROW = null,
		BB_ARCHER_NPC_STASHED_WEAPON = null,
		BB_ARCHER_NPC_NEXT_SHOT = 0,
		BB_ARCHER_NPC_REPOSITION_TURF = null,
		BB_ARCHER_NPC_REPOSITION_UNTIL = 0,
	)
	my_nodes = list(
		/datum/behavior_tree/node/subtree/being_a_minion,
		/datum/behavior_tree/node/subtree/call_for_help,
		/datum/behavior_tree/node/subtree/generic_break_restraints,
		/datum/behavior_tree/node/subtree/use_throwable,
		/datum/behavior_tree/node/subtree/generic_wield,
		/datum/behavior_tree/node/subtree/kick_attack,
		/datum/behavior_tree/node/subtree/generic_resist,
		/datum/behavior_tree/node/subtree/generic_stand,
		/datum/behavior_tree/node/subtree/flee_target,
		/datum/behavior_tree/node/subtree/tree_climb,
		/datum/behavior_tree/node/subtree/archer_base, // Archer only
		/datum/behavior_tree/node/subtree/retrieve_arrows, // Archer only
		/datum/behavior_tree/node/subtree/ranged_attack_subtree, // Archer only
		/datum/behavior_tree/node/subtree/aggro_find_target,
		/datum/behavior_tree/node/subtree/attack_obstacle_in_path,
		/datum/behavior_tree/node/subtree/leap_attack,
		/datum/behavior_tree/node/subtree/basic_melee_attack_subtree/human_npc,
		/datum/behavior_tree/node/subtree/find_weapon,
		/datum/behavior_tree/node/subtree/equip_item,
		/datum/behavior_tree/node/subtree/loot,
	)
