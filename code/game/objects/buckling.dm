

/atom/movable
	var/can_buckle = 0
	var/buckle_lying = -1 //bed-like behaviour, forces mob.lying = buckle_lying if != -1
	var/buckle_requires_restraints = 0 //require people to be handcuffed before being able to buckle. eg: pipes
	var/list/mob/living/buckled_mobs = null //list()
	var/max_buckled_mobs = 1
	var/buckle_prevents_pull = FALSE

//Interaction
/atom/movable/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	if(can_buckle && has_buckled_mobs())
		if(ishuman(src)) //prevent people from unbuckling fireman-carried/piggybacked people unless on disarm or harm intents
			if(act_intent == INTENT_HELP || act_intent == INTENT_GRAB)
				return
		if(buckled_mobs.len > 1)
			var/unbuckled = input(user, "Кого вы хотите отстегнуть?","Отстегнуть кого?") as null|mob in buckled_mobs
			if(user_unbuckle_mob(unbuckled,user))
				return TRUE
		else
			if(user_unbuckle_mob(buckled_mobs[1],user))
				return TRUE

/atom/movable/attackby(obj/item/attacking_item, mob/user, params)
	if(!can_buckle || !istype(attacking_item, /obj/item/riding_offhand) || !user.Adjacent(src))
		return ..()

	var/obj/item/riding_offhand/riding_item = attacking_item
	var/mob/living/carried_mob = riding_item.rider
	if(carried_mob == user) //Piggyback user.
		return
	user.unbuckle_mob(carried_mob)
	carried_mob.forceMove(get_turf(src))
	return mouse_buckle_handling(carried_mob, user)

/atom/movable/MouseDrop_T(mob/living/M, mob/living/user)
	. = ..()
	if(. & COMSIG_MOB_CANCEL_CLICKON) //SPLURT edit
		return
	return mouse_buckle_handling(M, user)

/**
 * Does some typechecks and then calls user_buckle_mob
 *
 * Arguments:
 * M - The mob being buckled to src
 * user - The mob buckling M to src
 */
/atom/movable/proc/mouse_buckle_handling(mob/living/M, mob/living/user)
	if(can_buckle && istype(M) && istype(user))
		return user_buckle_mob(M, user, check_loc = FALSE)

/atom/movable/proc/has_buckled_mobs()
	if(!buckled_mobs)
		return FALSE
	if(buckled_mobs.len)
		return TRUE

//procs that handle the actual buckling and unbuckling<b>[src]</b>
/atom/movable/proc/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	LAZYINITLIST(buckled_mobs)

	if(!istype(M))
		return FALSE

	if(check_loc && M.loc != loc && !(M.Adjacent(src) || src.Adjacent(M)))
		return FALSE

	if((!can_buckle && !force) || M.buckled || (buckled_mobs.len >= max_buckled_mobs) || (buckle_requires_restraints && !M.restrained()) || M == src)
		return FALSE
	M.buckling = src
	if(!M.can_buckle() && !force)
		if(M == usr)
			to_chat(M, "<span class='warning'>Вы не можете занять место на <b>[src]</b>!!</span>")
		else
			to_chat(usr, "<span class='warning'>Вы не в состоянии разместить <b>[M]</b> на <b>[src]</b>!</span>")
		M.buckling = null
		return FALSE

	if(M.pulledby)
		if(buckle_prevents_pull)
			M.pulledby.stop_pulling()
		else if(isliving(M.pulledby))
			var/mob/living/L = M.pulledby
			L.reset_pull_offsets(M, TRUE)

	// BLUEMOON ADD START
	if(!pre_buckle_mob(M))
		return FALSE
	// BLUEMOON ADD END

	// BLUEMOON ADD START - запрет на усаживание сверхтяжёлого персонажа посторонними
	if(M.mob_weight > MOB_WEIGHT_HEAVY) // проверка не раньше, т.к. в post_buckle_mob обратаюыватся объекты-исключения, на которые сверхтяжёлые персонажи садятся с особым эффектом
		if(istype(src, /obj/structure/bed/roller/heavy)) // простая проверка на предмет, пока не появится необходимость в большем количестве предметов-исключений
			// Всё в порядке
		else if(M != usr)
			to_chat(usr, span_warning("Слишком много весит!"))
			return FALSE
	// BLUEMOON ADD END

	// if(!check_loc && M.loc != loc)
	if(M.loc != loc)
		M.forceMove(loc)

	M.buckling = null
	M.buckled = src
	M.setDir(dir)
	buckled_mobs |= M
	M.update_mobility()
	M.throw_alert("buckled", /atom/movable/screen/alert/buckled)
	post_buckle_mob(M)

	SEND_SIGNAL(src, COMSIG_MOVABLE_BUCKLE, M, force)
	return TRUE

/obj/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	. = ..()
	if(.)
		if(resistance_flags & ON_FIRE) //Sets the mob on fire if you buckle them to a burning atom/movableect
			M.adjust_fire_stacks(1)
			M.IgniteMob()

/atom/movable/proc/unbuckle_mob(mob/living/buckled_mob, force=FALSE)
	if(!isliving(buckled_mob))
		CRASH("Non-living [buckled_mob] thing called unbuckle_mob() for source.")
	if(buckled_mob.buckled != src)
		CRASH("[buckled_mob] called unbuckle_mob() for source while having buckled as [buckled_mob.buckled].")
	if(!force && !buckled_mob.can_unbuckle())
		return
	. = buckled_mob
	buckled_mob.buckled = null
	buckled_mob.anchored = initial(buckled_mob.anchored)
	buckled_mob.update_mobility()
	buckled_mob.clear_alert("buckled")
	buckled_mob.set_glide_size(DELAY_TO_GLIDE_SIZE(buckled_mob.total_multiplicative_slowdown()))
	buckled_mobs -= buckled_mob
	SEND_SIGNAL(src, COMSIG_MOVABLE_UNBUCKLE, buckled_mob, force)

	post_unbuckle_mob(.)

/atom/movable/proc/unbuckle_all_mobs(force=FALSE)
	if(!has_buckled_mobs())
		return
	for(var/m in buckled_mobs)
		unbuckle_mob(m, force)

//Handle any extras after buckling

// BLUEMOON ADD START - взаимодействие с объектами до момента, пока моб считается севшим на него.
/atom/movable/proc/pre_buckle_mob(mob/living/M)
	return TRUE
// BLUEMOON ADD END

//Called on buckle_mob()
/atom/movable/proc/post_buckle_mob(mob/living/M)
	if(!HAS_TRAIT(M, IGNORE_FAKE_Z_AXIS))
		M.pseudo_z_axis = get_fake_z()
		M.pixel_z = M.pseudo_z_axis

//same but for unbuckle
/atom/movable/proc/post_unbuckle_mob(mob/living/M)
	if(!HAS_TRAIT(M, IGNORE_FAKE_Z_AXIS))
		M.pseudo_z_axis = get_fake_z()
		M.pixel_z = M.pseudo_z_axis

//Wrapper procs that handle sanity and user feedback
/atom/movable/proc/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(!in_range(user, src) || !isturf(user.loc) || user.incapacitated() || M.anchored || !user.can_buckle_others(M, src))
		return FALSE

	add_fingerprint(user)
	. = buckle_mob(M, check_loc = check_loc)
	if(.)
		if(M == user)
			// BLUEMOON CHANGES AHEAD - нарративный комментарий, что садится/ложится сверхтяжёлый персонаж
			M.visible_message(\
				"<span class='notice'>[M] занимает место на <b>[src]</b>. \
				[M.mob_weight > MOB_WEIGHT_NORMAL ? "Слышится скрип при попытки удержать вес." : ""]</span>",\
				"<span class='notice'>Вы занимаете место на <b>[src]</b>. \
				[M.mob_weight > MOB_WEIGHT_NORMAL ? "Слышится скрип при попытки удержать вес." : ""]</span>",\
				"<span class='italics'>Вы слышите металлический лязг.</span>")
		else
			M.visible_message(\
				"<span class='warning'>[user] размещает <b>[M]</b> на <b>[src]</b>! \
				[M.mob_weight > MOB_WEIGHT_NORMAL ? "Слышится скрип при попытки удержать вес." : ""]</span>",\
				"<span class='warning'>[user] размещает вас на <b>[src]</b>! \
				[M.mob_weight > MOB_WEIGHT_NORMAL ? "Слышится скрип при попытки удержать вес." : ""]</span>",\
				"<span class='italics'>Вы слышите металлический лязг.</span>")
			// BLUEMOON CHANGES END

/atom/movable/proc/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	var/mob/living/M = unbuckle_mob(buckled_mob)
	if(M)
		if(M != user)
			M.visible_message(\
				"<span class='notice'>[user] поднимает <b>[M]</b> с <b>[src]</b>.</span>",\
				"<span class='notice'>[user] поднимает вас с <b>[src]</b>.</span>",\
				"<span class='italics'>Вы слышите металлический лязг.</span>")
		else
			M.visible_message(\
				"<span class='notice'>[M] поднимается с <b>[src]</b>.</span>",\
				"<span class='notice'>Вы поднимаетесь с <b>[src]</b>.</span>",\
				"<span class='italics'>Вы слышите металлический лязг.</span>")
		add_fingerprint(user)
	if(isliving(M.pulledby))
		var/mob/living/L = M.pulledby
		L.set_pull_offsets(M, L.grab_state)
	return M

/atom/movable/proc/precise_user_unbuckle_mob(mob/user)
	if(!buckled_mobs)
		return
	else if(length(buckled_mobs) == 1)
		return user_unbuckle_mob(buckled_mobs[1], user)
	else
		var/unbuckled = input(user, "Кого вы хотите отстегнуть?","Отстегнуть кого?") as null|mob in buckled_mobs
		return user_unbuckle_mob(unbuckled, user)

