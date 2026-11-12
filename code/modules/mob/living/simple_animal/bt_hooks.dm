/mob/living/simple_animal
	var/bt_tree

/mob/living/simple_animal/Initialize(mapload)
	. = ..()
	if(bt_tree && !ai_controller)
		init_ai_root(bt_tree)
		RegisterSignal(src, COMSIG_MOB_LOGOUT, PROC_REF(bt_on_logout))
		RegisterSignal(src, COMSIG_MOB_STATCHANGE, PROC_REF(bt_restore_tree))

/mob/living/simple_animal/proc/bt_on_logout()
	SIGNAL_HANDLER
	addtimer(CALLBACK(src, PROC_REF(bt_restore_tree)), 1)

/mob/living/simple_animal/proc/bt_restore_tree()
	SIGNAL_HANDLER
	if(QDELETED(src) || !bt_tree || ai_controller || client || stat == DEAD)
		return
	if(ai_root)
		return
	init_ai_root(bt_tree)

/mob/living/simple_animal/Destroy()
	if(ai_root)
		SSai.Unregister(src)
	return ..()

/mob/living/simple_animal/hostile/configure_ai_root()
	if(ai_root.planner)
		return
	ai_root.next_attack_delay = melee_cooldown
	bt_update_move_delay()
	RegisterSignal(src, COMSIG_MOB_MOVESPEED_UPDATED, PROC_REF(bt_update_move_delay), override = TRUE)

/mob/living/simple_animal/hostile/proc/bt_update_move_delay()
	SIGNAL_HANDLER
	if(ai_root)
		ai_root.next_move_delay = CEILING(max(cached_multiplicative_slowdown, SIMPLEMOB_MINIMUM_MOVE_DELAY), SSai_movement.wait)

/mob/living/simple_animal/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(ai_root && !ckey && !stat)
		SSai.WakeUp(src)

/mob/living/simple_animal/hostile/attacked_by(obj/item/I, mob/living/user)
	if(ai_root && !ai_root.planner && stat == CONSCIOUS && !ai_root.target && !client && user)
		ai_root.target = user
		add_aggressor(user)
	return ..()

/mob/living/simple_animal/hostile/bullet_act(obj/projectile/P, def_zone = BODY_ZONE_CHEST)
	if(ai_root && !ai_root.planner && stat == CONSCIOUS && !ai_root.target && !client)
		if(P.firer && get_dist(src, P.firer) <= aggro_vision_range)
			ai_root.target = P.firer
			add_aggressor(P.firer)
		set_ai_path_to(P.starting)
	return ..()

/mob/living/start_pulling(atom/movable/AM, state, force = pull_force, supress_message = FALSE, obj/item/item_override)
	. = ..()
	if(pulling == AM && isliving(AM))
		var/mob/living/L = AM
		if(L.ai_root)
			SSai.WakeUp(L)
