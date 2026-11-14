/obj/item/hecusentry
	name = "HECU Sentry Gun (Folded)"
	desc = "A compact, folded HECU sentry gun. Use a wrench to deploy it."
	icon = 'modular_bluemoon/icons/obj/urbanism/hecusentry.dmi'
	icon_state = "sentry_notd"
	w_class = WEIGHT_CLASS_NORMAL
	var/deployed_turret_type = /obj/machinery/porta_turret/hecu

/obj/item/hecusentry/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_WRENCH)
		var/turf/deploy_turf = get_turf(user)
		if(!deploy_turf)
			return
		if(locate(/obj/machinery/porta_turret/hecu) in deploy_turf)
			to_chat(user, "<span class='warning'>A sentry gun is already deployed on this tile.</span>")
			return
		user.visible_message("<span class='notice'>[user] begins deploying the [src]...</span>", "<span class='notice'>You begin deploying the [src]...</span>")
		if(I.use_tool(src, user, 30, volume=50))
			var/obj/machinery/porta_turret/hecu/T = new deployed_turret_type(deploy_turf)
			T.update_icon()
			user.visible_message("<span class='notice'>[user] deploys the [src].</span>", "<span class='notice'>You deploy the [src].</span>")
			qdel(src)
		return
	..()

/obj/item/hecusentry/infected
	name = "HECU Infected Sentry Gun (Folded)"
	desc = "A compact, folded HECU sentry configured to target infected only. Use a wrench to deploy it."
	deployed_turret_type = /obj/machinery/porta_turret/hecu/infected

/obj/machinery/porta_turret/hecu
	name = "HECU Sentry Gun"
	desc = "An automated sentry gun used by the HECU. It has a high fire rate and low damage."
	icon = 'modular_bluemoon/icons/obj/urbanism/hecusentry.dmi'
	icon_state = "sentry_on"
	base_icon_state = "sentry"
	faction = list(FACTION_HECU)
	installation = null
	lethal_projectile = /obj/item/projectile/bullet/c10mm/hecu
	lethal_projectile_sound = 'modular_bluemoon/sound/weapons/mesa/mp5.ogg'
	shot_delay = 3
	scan_range = 7
	max_integrity = 200
	anchored = TRUE
	always_up = TRUE
	has_cover = FALSE
	on = TRUE
	turret_flags = TURRET_FLAG_SHOOT_ALL | TURRET_FLAG_SHOOT_ANOMALOUS
	mode = TURRET_LETHAL
	speed_process = TRUE
	var/beep_timer
	var/folded_item_type = /obj/item/hecusentry
	var/datum/weakref/designated_target_ref
	var/datum/weakref/targeting_user_ref

/obj/machinery/porta_turret/hecu/check_should_process()
	if (datum_flags & DF_ISPROCESSING)
		if (!on || !anchored || (machine_stat & BROKEN) || !powered())
			STOP_PROCESSING(SSfastprocess, src)
	else
		if (on && anchored && !(machine_stat & BROKEN) && powered())
			START_PROCESSING(SSfastprocess, src)

/obj/machinery/porta_turret/hecu/setup()
	return

/obj/machinery/porta_turret/hecu/AltClick(mob/user)
	if(!isliving(user) || !user.client || !can_interact(user))
		return ..()

	var/mob/living/current_targeting_user = get_targeting_user()
	if(current_targeting_user && (!current_targeting_user.client || current_targeting_user.stat == DEAD))
		clear_targeting_user()
		current_targeting_user = null

	if(current_targeting_user == user)
		clear_targeting_user()
		to_chat(user, "<span class='notice'>Target selection cancelled.</span>")
		return TRUE
	if(current_targeting_user)
		to_chat(user, "<span class='warning'>Someone else is already selecting a target for this sentry.</span>")
		return TRUE
	if(user.client.click_intercept)
		to_chat(user, "<span class='warning'>Finish your current targeting action first.</span>")
		return TRUE

	targeting_user_ref = WEAKREF(user)
	user.client.click_intercept = src
	to_chat(user, "<span class='notice'>Click a valid mob to order [src] to attack it. Alt-click the sentry again to cancel.</span>")
	return TRUE

/obj/machinery/porta_turret/hecu/proc/clear_targeting_user()
	var/mob/living/current_targeting_user = get_targeting_user()
	if(current_targeting_user && current_targeting_user.client && current_targeting_user.client.click_intercept == src)
		current_targeting_user.client.click_intercept = null
	targeting_user_ref = null

/obj/machinery/porta_turret/hecu/proc/get_targeting_user()
	if(!targeting_user_ref)
		return null
	return targeting_user_ref.resolve()

/obj/machinery/porta_turret/hecu/proc/can_designate_target(mob/living/target)
	return target && !QDELETED(target) && target.stat != DEAD && !in_faction(target) \
		&& get_dist(base, target) <= scan_range && can_see(base, target, scan_range)

/obj/machinery/porta_turret/hecu/proc/get_designated_target()
	if(!designated_target_ref)
		return null
	var/mob/living/target = designated_target_ref.resolve()
	if(!can_designate_target(target))
		designated_target_ref = null
		return null
	return target

/obj/machinery/porta_turret/hecu/scan_for_targets()
	var/mob/living/target = get_designated_target()
	if(target)
		return list(target)
	return ..()

/obj/machinery/porta_turret/hecu/InterceptClickOn(mob/living/caller, params, atom/A)
	if(caller != get_targeting_user() || !caller.client || caller.client.click_intercept != src)
		return FALSE
	if(!isliving(A))
		to_chat(caller, "<span class='warning'>Choose a living mob in the sentry's line of sight.</span>")
		return TRUE
	var/mob/living/chosen_target = A
	if(!can_designate_target(chosen_target))
		to_chat(caller, "<span class='warning'>That mob cannot be targeted by this sentry.</span>")
		return TRUE

	designated_target_ref = WEAKREF(chosen_target)
	cache_targets(list(chosen_target))
	to_chat(caller, "<span class='notice'>[src] is now targeting [chosen_target].</span>")
	clear_targeting_user()
	return TRUE

/obj/machinery/porta_turret/hecu/infected
	name = "HECU Infected Sentry Gun"
	desc = "A HECU automated sentry configured to target infected and their subtypes, leaving ordinary players alone."
	lethal_projectile = /obj/item/projectile/bullet/c10mm/hecu/infected
	turret_flags = 0
	folded_item_type = /obj/item/hecusentry/infected
	max_integrity = 400

/obj/machinery/porta_turret/hecu/infected/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_WRENCH)
		to_chat(user, "<span class='warning'>This sentry cannot be folded.</span>")
		return
	return ..()

/obj/machinery/porta_turret/hecu/infected/bullet_act(obj/item/projectile/P)
	if(P && istype(P.firer, /obj/machinery/porta_turret))
		return BULLET_ACT_FORCE_PIERCE
	return ..()

/obj/machinery/porta_turret/hecu/infected/can_designate_target(mob/living/target)
	if(!istype(target, /mob/living/simple_animal/hostile/infected))
		return FALSE
	return ..()

/obj/machinery/porta_turret/hecu/infected/scan_for_targets()
	var/mob/living/designated = get_designated_target()
	if(designated)
		return list(designated)

	var/list/targets = list()
	for(var/mob/living/simple_animal/hostile/infected/target in view(scan_range, base))
		if(target.stat || target.invisibility > SEE_INVISIBLE_LIVING || in_faction(target))
			continue
		if(!can_see(base, target, scan_range))
			continue
		targets += target
	return targets

/obj/machinery/porta_turret/hecu/Initialize()
	. = ..()
	beep_timer = addtimer(CALLBACK(src, PROC_REF(beep)), 1 SECONDS, TIMER_STOPPABLE)

/obj/machinery/porta_turret/hecu/Destroy()
	clear_targeting_user()
	designated_target_ref = null
	if(beep_timer)
		deltimer(beep_timer)
	return ..()

/obj/machinery/porta_turret/hecu/proc/beep()
	if(QDELETED(src))
		return
	if(on && !(machine_stat & (BROKEN | NOPOWER)))
		playsound(src, 'modular_bluemoon/sound/weapons/mesa/turretping.ogg', 70, FALSE)
	beep_timer = addtimer(CALLBACK(src, PROC_REF(beep)), 1 SECONDS, TIMER_STOPPABLE)

/obj/machinery/porta_turret/hecu/assess_perp(mob/living/carbon/human/perp)
	if(in_faction(perp))
		return FALSE
	return 10

/obj/machinery/porta_turret/hecu/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_WRENCH)
		if(machine_stat & BROKEN)
			to_chat(user, "<span class='warning'>The [src] is too damaged to be folded!</span>")
			return
		user.visible_message("<span class='notice'>[user] begins folding the [src]...</span>", "<span class='notice'>You begin folding the [src]...</span>")
		if(I.use_tool(src, user, 30, volume=50))
			user.visible_message("<span class='notice'>[user] folds the [src].</span>", "<span class='notice'>You fold the [src].</span>")
			new folded_item_type(get_turf(src))
			qdel(src)
		return
	return ..()

/obj/machinery/porta_turret/hecu/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "sentry_broken"
		return
	if(on && !(machine_stat & NOPOWER))
		icon_state = "sentry_on"
	else
		icon_state = "sentry_off"

/obj/item/projectile/bullet/c10mm/hecu
	name = "small caliber bullet"
	damage = 10
	simple_mob_damage_multiplier = 2

/obj/item/projectile/bullet/c10mm/hecu/infected
	simple_mob_damage_multiplier = 2.5

/obj/item/hecusentry_remote
	name = "HECU Sentry Remote"
	desc = "A remote control for HECU sentry guns. Use on a sentry to link it."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-syndie"
	var/list/obj/machinery/porta_turret/hecu/linked_sentries = list()

/obj/item/hecusentry_remote/attack_self(mob/user)
	if(!linked_sentries.len)
		to_chat(user, "<span class='warning'>No sentries linked!</span>")
		return

	var/any_on = FALSE
	var/i = 1
	while(i <= linked_sentries.len)
		var/obj/machinery/porta_turret/hecu/T = linked_sentries[i]
		if(QDELETED(T))
			linked_sentries.Cut(i, i+1)
			continue
		if(T.on)
			any_on = TRUE
		i++

	if(!linked_sentries.len)
		to_chat(user, "<span class='warning'>All linked sentries were destroyed!</span>")
		return

	var/target_state = !any_on

	for(var/obj/machinery/porta_turret/hecu/T in linked_sentries)
		T.setState(target_state, TURRET_LETHAL, FALSE)

	to_chat(user, "<span class='notice'>You [target_state ? "activate" : "deactivate"] [linked_sentries.len] linked sentries.</span>")
	playsound(user, 'sound/machines/click.ogg', 50, TRUE)

/obj/item/hecusentry_remote/afterattack(atom/target, mob/user, proximity_flag)
	if(istype(target, /obj/machinery/porta_turret/hecu/infected))
		if(!istype(src, /obj/item/hecusentry_remote/infected))
			return ..()
	else if(istype(target, /obj/machinery/porta_turret/hecu) && istype(src, /obj/item/hecusentry_remote/infected))
		return ..()

	if(istype(target, /obj/machinery/porta_turret/hecu))
		var/obj/machinery/porta_turret/hecu/T = target
		if(T in linked_sentries)
			UnregisterSignal(T, COMSIG_PARENT_QDELETING)
			linked_sentries -= T
			to_chat(user, "<span class='notice'>Sentry unlinked.</span>")
		else
			linked_sentries += T
			RegisterSignal(T, COMSIG_PARENT_QDELETING, PROC_REF(on_sentry_qdeleting))
			to_chat(user, "<span class='notice'>Sentry linked.</span>")
		return
	..()

/obj/item/hecusentry_remote/infected
	name = "HECU Infected Sentry Remote"
	desc = "A dedicated remote for linking and toggling HECU sentries configured to target infected."

/obj/item/hecusentry_remote/proc/on_sentry_qdeleting(datum/source, forced)
	SIGNAL_HANDLER
	linked_sentries -= source

/obj/item/hecusentry_remote/Destroy()
	for(var/obj/machinery/porta_turret/hecu/T as anything in linked_sentries)
		UnregisterSignal(T, COMSIG_PARENT_QDELETING)
	linked_sentries.Cut()
	return ..()
