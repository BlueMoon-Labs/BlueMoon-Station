/mob/living/simple_animal/mouse
	name = "mouse"
	desc = "It's a nasty, ugly, evil, disease-ridden rodent."
	uses_custom_environment_handling = TRUE //свой handle_environment()
	icon_state = "mouse_gray"
	icon_living = "mouse_gray"
	icon_dead = "mouse_gray_dead"
	speak = list("Squeak!","SQUEAK!","Squeak?")
	speak_emote = list("squeaks")
	emote_hear = list("squeaks.")
	emote_see = list("runs in a circle.", "shakes.")
	speak_chance = 1
	turns_per_move = 5
	blood_volume = 250
	see_in_dark = 6
	maxHealth = 5
	health = 5
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 1)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "splats"
	response_harm_simple = "splat"
	density = FALSE
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	var/body_color //brown, gray and white, leave blank for random
	gold_core_spawnable = FRIENDLY_SPAWN
	var/chew_probability = 1
	faction = list("rat")
	can_buckle = TRUE
	max_buckled_mobs = 1
	tame = TRUE
	buckle_lying = 1 // господи прости
	vocal_bark_id = "squeak"
	vocal_pitch = 1.4
	/// ковер из крыс
	var/mob/living/swarm_rider
	var/swarm_rider_was_resting = FALSE
	var/matrix/swarm_rider_old_transform
	var/swarm_locked = FALSE
	var/swarm_gathering = FALSE
	var/mob/living/swarm_gather_rider

/mob/living/simple_animal/mouse/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/squeak, list('sound/effects/mousesqueek.ogg'=1), 100)
	if(!body_color)
		body_color = pick(list("brown","gray","white"))
	AddElement(/datum/element/mob_holder, "mouse_[body_color]")
	icon_state = "mouse_[body_color]"
	icon_living = "mouse_[body_color]"
	icon_dead = "mouse_[body_color]_dead"
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)
	RegisterSignal(src, COMSIG_ATOM_ATTACK_HAND, PROC_REF(rat_friend_attack_hand))
	RegisterSignal(src, COMSIG_PARENT_ATTACKBY, PROC_REF(rat_friend_attackby))

/mob/living/simple_animal/mouse/examine(mob/user)
	. = ..()
	if(isliving(user))
		var/mob/living/living_user = user
		if(living_user.has_status_effect(/datum/status_effect/rat_friend))
			. += span_notice("Эта мышь считает вас своим.")
	. += span_notice("Только стайка мышек выдержит ваш вес.")

/mob/living/simple_animal/mouse/proc/splat()
	src.health = 0
	src.icon_dead = "mouse_[body_color]_splat"
	death()

/mob/living/simple_animal/mouse/death(gibbed, toast)
	if(!ckey)
		..(1)
		if(!gibbed)
			var/obj/item/reagent_containers/food/snacks/deadmouse/M = new(loc)
			M.icon_state = icon_dead
			M.item_state = "mouse_[body_color]"
			M.name = name
			if(toast)
				M.add_atom_colour("#3A3A3A", FIXED_COLOUR_PRIORITY)
				M.desc = "It's toast."
		qdel(src)
	else
		..(gibbed)


/mob/living/simple_animal/mouse/Crossed(AM as mob|obj)
	if( ishuman(AM) )
		if(!stat)
			var/mob/M = AM
			to_chat(M, "<span class='notice'>[icon2html(src, M)] Squeak!</span>")
	if(istype(AM, /obj/item/reagent_containers/food/snacks/royalcheese))
		evolve()
		qdel(AM)
	..()

/mob/living/simple_animal/mouse/handle_automated_action()
	if(!isturf(loc))
		return

	if(prob(chew_probability))
		var/turf/open/floor/F = get_turf(src)
		if(istype(F) && !(F.turf_flags & TURF_INTACT))
			var/obj/structure/cable/C = locate() in F
			if(C && prob(15))
				if(C.avail())
					visible_message("<span class='warning'>[src] chews through the [C]. It's toast!</span>")
					playsound(src, 'sound/effects/sparks2.ogg', 100, 1)
					C.deconstruct()
					death(toast=TRUE)
				else
					C.deconstruct()
					visible_message("<span class='warning'>[src] chews through the [C].</span>")

	for(var/obj/item/reagent_containers/food/snacks/cheesewedge/cheese in range(1, src))
		if(prob(10))
			be_fruitful()
			qdel(cheese)
			return
	for(var/obj/item/reagent_containers/food/snacks/royalcheese/bigcheese in range(1, src))
		qdel(bigcheese)
		evolve()
		return
	for(var/obj/item/trash/garbage in range(1, src))
		if(is_station_level(z))
			if(prob(2))
				qdel(garbage)
				evolve_plague()
				return
	for(var/obj/effect/decal/cleanable/blood/gibs/leftovers in range(1, src))
		if(is_station_level(z))
			if(prob(2))
				qdel(leftovers)
				evolve_plague()
				return

/**
  *Checks the mouse cap, if it's above the cap, doesn't spawn a mouse. If below, spawns a mouse and adds it to cheeserats.
  */

/mob/living/simple_animal/mouse/proc/be_fruitful()
	var/cap = CONFIG_GET(number/ratcap)
	if(LAZYLEN(SSmobs.cheeserats) >= cap)
		visible_message("<span class='warning'>[src] осторожно ест сыр, пряча его от [cap] мышей на станции!</span>")
		return
	var/mob/living/newmouse = new /mob/living/simple_animal/mouse(loc)
	SSmobs.cheeserats += newmouse
	visible_message("<span class='notice'>[src] грызёт сыр, приманивая ещё одну мышь!</span>")

/**
  *Spawns a new regal rat, says some good jazz, and if sentient, transfers the relivant mind.
  */
/mob/living/simple_animal/mouse/proc/evolve()
	var/mob/living/simple_animal/hostile/regalrat/king = new /mob/living/simple_animal/hostile/regalrat/controlled(loc)
	visible_message("<span class='warning'>[src] пожирает сыр! Он превращается во что-то... большее!</span>")
	king.say("ВОССТАНЬТЕ, МОИ ПОДДАННЫЕ! ПИИИИ!")
	if(mind)
		mind.transfer_to(king)
		if(king.mind && !king.mind.has_antag_datum(/datum/antagonist/rat_king))
			king.mind.add_antag_datum(/datum/antagonist/rat_king)
		if(!king.special_moniker)
			king.grant_titles()
	qdel(src)

/mob/living/simple_animal/mouse/proc/evolve_plague()
	return

/*
	var/mob/living/simple_animal/hostile/plaguerat = new /mob/living/simple_animal/hostile/plaguerat(loc)
	visible_message("<span class='warning'>[src] devours the food! He rots into something worse!</span>")
	if(mind)
		mind.transfer_to(plaguerat)
	qdel(src)
*/

/*
 * Mouse types
 */

/mob/living/simple_animal/mouse/white
	body_color = "white"
	icon_state = "mouse_white"

/mob/living/simple_animal/mouse/gray
	body_color = "gray"
	icon_state = "mouse_gray"

/mob/living/simple_animal/mouse/brown
	body_color = "brown"
	icon_state = "mouse_brown"

/mob/living/simple_animal/mouse/Destroy()
	SSmobs.cheeserats -= src
	return ..()

/// Пять мышей-качков как в меме про негров, никто и не поймет почему пока не заглянет в код.
/mob/living/simple_animal/mouse/can_carry_rider(mob/living/rider)
	if(swarm_gathering && rider == swarm_gather_rider)
		return TRUE
	if(swarm_locked || has_buckled_mobs())
		return FALSE
	return length(get_ride_swarm(rider)) >= 5

/// Собираем
/mob/living/simple_animal/mouse/proc/get_ride_swarm(mob/living/rider)
	if(swarm_locked)
		return list(src)
	var/list/mob/living/simple_animal/mouse/swarm = list(src)
	var/list/mob/living/simple_animal/mouse/candidates = list()
	for(var/mob/living/simple_animal/mouse/candidate in range(5, src))
		candidates |= candidate

	if(istype(rider, /mob/living/simple_animal/hostile/regalrat))
		var/mob/living/simple_animal/hostile/regalrat/king = rider
		var/datum/rat_horde/horde = king.horde
		if(horde)
			for(var/mob/living/simple_animal/mouse/minion as anything in horde.minions)
				if(QDELETED(minion) || minion.stat == DEAD || !isturf(minion.loc))
					continue
				if(get_dist(minion, src) <= 5)
					candidates |= minion

	for(var/mob/living/simple_animal/mouse/candidate as anything in candidates)
		if(candidate == src || candidate == rider || candidate.swarm_locked || QDELETED(candidate) || candidate.stat == DEAD || candidate.client || candidate.buckled || candidate.has_buckled_mobs() || !isturf(candidate.loc))
			continue
		var/datum/component/rat_minion/minion_component = candidate.GetComponent(/datum/component/rat_minion)
		if(minion_component && minion_component.horde && minion_component.horde.leader != rider)
			continue
		swarm += candidate
		if(length(swarm) >= 5)
			break
	return swarm

/// Укладываем
/mob/living/simple_animal/mouse/proc/lay_swarm_rider(mob/living/rider)
	if(!rider || QDELETED(rider) || swarm_rider)
		return
	swarm_rider = rider
	swarm_rider_was_resting = rider.resting
	if(iscarbon(rider))
		if(!rider.resting)
			rider.set_resting(TRUE, TRUE)
	else
		swarm_rider_old_transform = matrix(rider.transform)
		var/matrix/lying_transform = matrix(rider.transform)
		lying_transform.Turn(90)
		animate(rider, transform = lying_transform, time = 0.2 SECONDS)
		if(!rider.resting)
			rider.set_resting(TRUE, TRUE)

/mob/living/simple_animal/mouse/proc/unlay_swarm_rider()
	var/mob/living/rider = swarm_rider
	var/matrix/old_transform = swarm_rider_old_transform
	swarm_rider = null
	swarm_rider_old_transform = null
	if(!rider || QDELETED(rider))
		return
	if(!swarm_rider_was_resting && rider.stat == CONSCIOUS)
		rider.set_resting(FALSE, TRUE)
	if(old_transform)
		animate(rider, transform = old_transform, time = 0.2 SECONDS)

/mob/living/simple_animal/mouse/MouseDrop_T(mob/living/M, mob/living/user)
	if(!can_buckle || !tame || !istype(M) || M == src || M.buckled)
		return
	if(!user || !isturf(src.loc) || !isturf(M.loc) || !in_range(M, src))
		return
	if(src.swarm_locked || src.swarm_gathering || src.has_buckled_mobs())
		if(user == M)
			to_chat(user, span_warning("Эта мышь уже занята."))
		return
	if(M.swarm_gather_lock)
		if(user == M)
			to_chat(user, span_warning("Вы уже собираете стаю."))
		return
	var/list/swarm = get_ride_swarm(M)
	if(length(swarm) < 5)
		if(user == M)
			to_chat(user, span_warning("Для поездки нужна стая из пяти мышей."))
		return
	attempt_swarm_gather(M, user, swarm)

/// Проверки на вес и вся хуйня дальше
/mob/living/simple_animal/mouse/proc/attempt_swarm_gather(mob/living/rider, mob/living/user, list/swarm)
	if(swarm_gathering || swarm_locked || rider.swarm_gather_lock)
		return FALSE

	var/list/locked_mice = list()
	for(var/mob/living/simple_animal/mouse/mouse as anything in swarm)
		if(QDELETED(mouse) || mouse.stat == DEAD)
			continue
		if(mouse.swarm_locked)
			unlock_swarm_mice(locked_mice)
			if(user == rider)
				to_chat(user, span_warning("Одна из мышей уже занята другой стаей."))
			return FALSE
		mouse.swarm_locked = TRUE
		locked_mice += mouse
	if(length(locked_mice) < 5)
		unlock_swarm_mice(locked_mice)
		if(user == rider)
			to_chat(user, span_warning("Для поездки нужна стая из пяти мышей."))
		return FALSE
	swarm_gathering = TRUE
	swarm_gather_rider = rider
	rider.swarm_gather_lock = TRUE

	var/turf/host_turf = get_turf(rider) || get_turf(src)
	if(!host_turf)
		abort_swarm_gather(rider, locked_mice)
		return FALSE
	if(get_turf(src) != host_turf)
		src.forceMove(host_turf)
	var/will_ride = rider.mob_weight < MOB_WEIGHT_HEAVY
	if(will_ride)
		lay_swarm_rider(rider)

	var/list/old_stop_automated_movement = list()
	var/list/old_turf = list()
	var/list/old_pixel_x = list()
	var/list/old_pixel_y = list()
	var/static/list/carpet_offsets = list(list(-7, -5), list(7, -5), list(-5, 7), list(5, 7)) // господи прости
	var/carpet_index = 0

	for(var/mob/living/simple_animal/mouse/mouse as anything in swarm)
		if(QDELETED(mouse) || mouse.stat == DEAD)
			continue
		old_stop_automated_movement[mouse] = mouse.stop_automated_movement
		old_turf[mouse] = get_turf(mouse)
		old_pixel_x[mouse] = mouse.pixel_x
		old_pixel_y[mouse] = mouse.pixel_y
		mouse.stop_automated_movement = TRUE
		walk(mouse, 0)
		if(mouse == src)
			continue
		var/turf/mouse_turf = old_turf[mouse]
		if(!mouse_turf)
			continue
		var/dx = (mouse_turf.x - host_turf.x) * world.icon_size
		var/dy = (mouse_turf.y - host_turf.y) * world.icon_size
		mouse.forceMove(host_turf)
		mouse.pixel_x = dx
		mouse.pixel_y = dy
		carpet_index++
		var/list/offset = carpet_offsets[(carpet_index - 1) % length(carpet_offsets) + 1]
		animate(mouse, pixel_x = offset[1], pixel_y = offset[2], time = 1 SECONDS, easing = SINE_EASING)

	balloon_alert(user, "Мышки сбегаются")
	if(user != rider)
		balloon_alert(rider, "Мышки сбегаются")
	visible_message(span_notice("Мышки сбегаются в плотную стайку..."))

	if(!do_after(user, 1 SECONDS, src))
		abort_swarm_gather(rider, locked_mice)
		restore_gathered_swarm(old_stop_automated_movement, old_turf, old_pixel_x, old_pixel_y)
		return FALSE

	if(QDELETED(src) || QDELETED(rider) || rider.buckled || !in_range(rider, src))
		abort_swarm_gather(rider, locked_mice)
		restore_gathered_swarm(old_stop_automated_movement, old_turf, old_pixel_x, old_pixel_y)
		return FALSE

	var/list/gathered = list()
	for(var/mob/living/simple_animal/mouse/mouse as anything in old_stop_automated_movement)
		if(QDELETED(mouse) || mouse.stat == DEAD)
			continue
		gathered += mouse
	if(length(gathered) < 5)
		abort_swarm_gather(rider, locked_mice)
		restore_gathered_swarm(old_stop_automated_movement, old_turf, old_pixel_x, old_pixel_y)
		if(user == rider)
			to_chat(user, span_warning("Стая не успела собраться."))
		return FALSE

	// Возращаем мышей из состояния транса.
	for(var/mob/living/simple_animal/mouse/mouse as anything in old_stop_automated_movement)
		if(QDELETED(mouse))
			continue
		animate(mouse)
		mouse.stop_automated_movement = old_stop_automated_movement[mouse]
		mouse.pixel_x = old_pixel_x[mouse]
		mouse.pixel_y = old_pixel_y[mouse]

	if(rider.mob_weight >= MOB_WEIGHT_HEAVY_SUPER)
		unlay_swarm_rider()
		crush_swarm_with_lie(gathered, rider)
		unlock_swarm_mice(locked_mice)
		finish_swarm_gather(rider)
		return FALSE
	if(rider.mob_weight >= MOB_WEIGHT_HEAVY)
		unlay_swarm_rider()
		scatter_swarm(gathered, rider)
		unlock_swarm_mice(locked_mice)
		finish_swarm_gather(rider)
		return FALSE

	prepare_riding()
	if(!mouse_buckle_handling(rider, user, TRUE) || rider.buckled != src)
		abort_swarm_gather(rider, locked_mice)
		restore_gathered_swarm(old_stop_automated_movement, old_turf, old_pixel_x, old_pixel_y)
		return FALSE

	var/list/extras = gathered - src
	if(length(extras))
		AddComponent(/datum/component/mouse_swarm_mount, extras)
		visible_message(span_notice("[src] и ещё четыре мыши сбиваются в стаю под [rider]!"))
	finish_swarm_gather(rider)
	return TRUE

/mob/living/simple_animal/mouse/proc/unlock_swarm_mice(list/mice)
	for(var/mob/living/simple_animal/mouse/mouse as anything in mice)
		if(QDELETED(mouse))
			continue
		mouse.swarm_locked = FALSE

/mob/living/simple_animal/mouse/proc/finish_swarm_gather(mob/living/rider)
	if(rider && !QDELETED(rider))
		rider.swarm_gather_lock = FALSE
	swarm_gathering = FALSE
	swarm_gather_rider = null

/mob/living/simple_animal/mouse/proc/abort_swarm_gather(mob/living/rider, list/locked_mice)
	unlay_swarm_rider()
	unlock_swarm_mice(locked_mice)
	finish_swarm_gather(rider)

/// Снимаем заморозку
/mob/living/simple_animal/mouse/proc/restore_gathered_swarm(list/old_stop_automated_movement, list/old_turf, list/old_pixel_x, list/old_pixel_y)
	for(var/mob/living/simple_animal/mouse/mouse as anything in old_stop_automated_movement)
		if(QDELETED(mouse))
			continue
		animate(mouse)
		mouse.stop_automated_movement = old_stop_automated_movement[mouse]
		mouse.pixel_x = old_pixel_x[mouse]
		mouse.pixel_y = old_pixel_y[mouse]
		var/turf/original_turf = old_turf[mouse]
		if(original_turf && !mouse.buckled && get_turf(mouse) != original_turf)
			mouse.forceMove(original_turf)

/// Взаимодействие с сверхтяжелыми
/mob/living/simple_animal/mouse/proc/crush_swarm_with_lie(list/mice, mob/living/crusher)
	if(!crusher || QDELETED(crusher))
		return
	var/was_resting = crusher.resting
	var/did_lie = FALSE
	var/matrix/old_transform = null
	if(iscarbon(crusher))
		if(!was_resting)
			crusher.set_resting(TRUE, TRUE)
			did_lie = crusher.resting
	else
		if(!was_resting)
			crusher.set_resting(TRUE, TRUE)
		old_transform = matrix(crusher.transform)
		var/matrix/lying_transform = matrix(crusher.transform)
		lying_transform.Turn(90)
		animate(crusher, transform = lying_transform, time = 0.2 SECONDS)
		did_lie = TRUE
	if(did_lie)
		crusher.visible_message(span_danger("[crusher] с размаху ложится на клубок мышей!"), span_danger("Вы с размаху ложитесь на мышей, вминая их в пол!")) // WWE
		sleep(0.5 SECONDS)
	if(QDELETED(crusher))
		return
	crush_swarm(mice, crusher)
	if(did_lie && !QDELETED(crusher) && crusher.stat == CONSCIOUS)
		sleep(0.4 SECONDS)
		if(QDELETED(crusher) || crusher.stat != CONSCIOUS)
			return
		if(!was_resting && crusher.resting)
			crusher.set_resting(FALSE, TRUE)
		if(old_transform)
			animate(crusher, transform = old_transform, time = 0.3 SECONDS)

/mob/living/simple_animal/mouse/proc/crush_swarm(list/mice, mob/living/crusher)
	var/list/alive_mice = list()
	for(var/mob/living/simple_animal/mouse/mouse as anything in mice)
		if(QDELETED(mouse) || mouse.stat == DEAD)
			continue
		alive_mice += mouse
		var/matrix/squish = matrix()
		squish.Scale(1.4, 0.35)
		animate(mouse, transform = squish, time = 2, easing = SINE_EASING)
	if(!length(alive_mice))
		return
	sleep(0.2 SECONDS)
	var/crushed = 0
	for(var/mob/living/simple_animal/mouse/mouse as anything in alive_mice)
		if(QDELETED(mouse))
			continue
		var/turf/mouse_turf = get_turf(mouse)
		if(mouse_turf)
			mouse.add_splash_floor(mouse_turf)
		mouse.gib()
		crushed++
	if(!crushed)
		return
	var/turf/crush_turf = get_turf(crusher)
	if(crush_turf)
		playsound(crush_turf, 'sound/effects/splat.ogg', 60, TRUE)
	crusher.visible_message(span_danger("[crusher] с хрустом давит [crushed] мышей в кровавую лепёшку!"), span_danger("Вы с хрустом давите мышей - они лопаются под вашим весом!"))

/// Взаимодействие с толстяками
/mob/living/simple_animal/mouse/proc/scatter_swarm(list/mice, mob/living/rider)
	var/turf/rider_turf = get_turf(rider)
	var/list/directions = GLOB.alldirs.Copy()
	shuffle(directions)
	var/direction_index = 0
	for(var/mob/living/simple_animal/mouse/mouse as anything in mice)
		if(QDELETED(mouse) || mouse.stat == DEAD)
			continue
		walk(mouse, 0)
		animate(mouse)
		mouse.pixel_x = 0
		mouse.pixel_y = 0
		var/turf/mouse_turf = get_turf(mouse)
		if(!mouse_turf)
			continue
		var/scatter_dir = rider_turf ? get_dir(rider_turf, mouse_turf) : 0
		if(!scatter_dir)
			direction_index = direction_index % length(directions) + 1
			scatter_dir = directions[direction_index]
		var/turf/destination = mouse_turf
		// Рывок
		for(var/i in 1 to 3)
			var/turf/next_turf = get_step(destination, scatter_dir)
			if(!next_turf || next_turf.density)
				break
			destination = next_turf
		if(destination == mouse_turf)
			continue
		mouse.dir = scatter_dir
		mouse.forceMove(destination)
		mouse.pixel_x = (mouse_turf.x - destination.x) * world.icon_size
		mouse.pixel_y = (mouse_turf.y - destination.y) * world.icon_size
		animate(mouse, pixel_x = 0, pixel_y = 0, time = 4, easing = SINE_EASING)
	rider.visible_message(span_warning("Мышки выскальзывают из-под [rider] и разбегаются в разные стороны!"), span_warning("Мышки не выдерживают ваш вес и разбегаются!"))

/mob/living/simple_animal/mouse/post_unbuckle_mob(mob/living/M)
	. = ..()
	if(swarm_rider && !QDELETED(swarm_rider))
		swarm_rider.swarm_gather_lock = FALSE
	unlay_swarm_rider()
	swarm_locked = FALSE
	swarm_gathering = FALSE
	swarm_gather_rider = null
	var/datum/component/mouse_swarm_mount/swarm = GetComponent(/datum/component/mouse_swarm_mount)
	if(swarm)
		qdel(swarm)

/datum/component/mouse_swarm_mount
	var/list/mob/living/simple_animal/mouse/extras = list()
	var/list/old_stop_automated_movement = list()

/datum/component/mouse_swarm_mount/Initialize(list/mice)
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE
	extras = mice.Copy()
	for(var/mob/living/simple_animal/mouse/mouse as anything in extras)
		if(QDELETED(mouse))
			extras -= mouse
			continue
		old_stop_automated_movement[mouse] = mouse.stop_automated_movement
		mouse.stop_automated_movement = TRUE
		RegisterSignal(mouse, COMSIG_PARENT_QDELETING, PROC_REF(on_extra_deleted))
		RegisterSignal(mouse, COMSIG_MOVABLE_MOVED, PROC_REF(on_extra_moved))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_host_moved))
	on_host_moved()

/datum/component/mouse_swarm_mount/proc/on_host_moved(datum/source)
	SIGNAL_HANDLER
	var/mob/living/simple_animal/mouse/host = parent
	var/turf/host_turf = get_turf(host)
	if(!host_turf)
		return
	var/static/list/offsets = list(list(-6, -4), list(6, -4), list(-4, 6), list(4, 6))
	for(var/i in 1 to length(extras))
		var/mob/living/simple_animal/mouse/mouse = extras[i]
		if(QDELETED(mouse) || mouse.buckled || !isturf(mouse.loc))
			continue
		mouse.forceMove(host_turf)
		var/list/offset = offsets[(i - 1) % length(offsets) + 1]
		mouse.pixel_x = offset[1]
		mouse.pixel_y = offset[2]
		mouse.dir = host.dir

/datum/component/mouse_swarm_mount/proc/on_extra_deleted(datum/source)
	SIGNAL_HANDLER
	extras -= source

/// Проверка экстрамув, для корректной работы приказов
/datum/component/mouse_swarm_mount/proc/on_extra_moved(datum/source)
	SIGNAL_HANDLER
	var/mob/living/simple_animal/mouse/mouse = source
	var/mob/living/simple_animal/mouse/host = parent
	if(QDELETED(mouse) || QDELETED(host) || mouse.buckled || !isturf(mouse.loc))
		return
	var/turf/host_turf = get_turf(host)
	if(!host_turf || get_turf(mouse) == host_turf)
		return
	mouse.forceMove(host_turf)

/datum/component/mouse_swarm_mount/Destroy()
	if(parent)
		UnregisterSignal(parent, COMSIG_MOVABLE_MOVED)
	for(var/mob/living/simple_animal/mouse/mouse as anything in extras)
		if(QDELETED(mouse))
			continue
		UnregisterSignal(mouse, COMSIG_PARENT_QDELETING)
		UnregisterSignal(mouse, COMSIG_MOVABLE_MOVED)
		mouse.swarm_locked = FALSE
		mouse.stop_automated_movement = old_stop_automated_movement[mouse] || FALSE
		mouse.pixel_x = 0
		mouse.pixel_y = 0
	extras.Cut()
	old_stop_automated_movement.Cut()
	return ..()

GLOBAL_VAR(tom_existed)

//TOM IS ALIVE! SQUEEEEEEEE~K :)
/mob/living/simple_animal/mouse/brown/Tom
	name = "Tom"
	desc = "Jerry the cat is not amused."
	gold_core_spawnable = NO_SPAWN

/mob/living/simple_animal/mouse/brown/Tom/Initialize(mapload)
	. = ..()
	GLOB.tom_existed = TRUE

/obj/item/reagent_containers/food/snacks/deadmouse
	name = "dead mouse"
	desc = "It looks like somebody dropped the bass on it. A lizard's favorite meal."
	icon = 'icons/mob/animal.dmi'
	icon_state = "mouse_gray_dead"
	// Без своих inhand-файлов труп брался по icon_state из food_lefthand.dmi, где нет
	// ни одного mouse_*: дохлая мышь была невидима в руках.
	lefthand_file = 'icons/mob/animals_held_lh.dmi'
	righthand_file = 'icons/mob/animals_held_rh.dmi'
	item_state = "mouse_gray"
	bitesize = 3
	eatverb = "devour"
	list_reagents = list(/datum/reagent/consumable/nutriment = 3, /datum/reagent/consumable/nutriment/vitamin = 2)
	foodtype = GROSS | MEAT | RAW
	grind_results = list(/datum/reagent/blood = 20, /datum/reagent/liquidgibs = 5)

/obj/item/reagent_containers/food/snacks/deadmouse/on_grind()
	..()
	reagents.clear_reagents()

/mob/living/simple_animal/mouse/proc/miasma(datum/gas_mixture/environment, check_temp = FALSE)
	if(isturf(src.loc) && isopenturf(src.loc))
		var/turf/open/ST = src.loc
		var/miasma_moles = ST.air.get_moles(GAS_MIASMA)
		if(prob(5) && miasma_moles >= 5)
			evolve_plague()
		else if(miasma_moles >= 20)
			evolve_plague()
			return

/mob/living/simple_animal/mouse/handle_environment(datum/gas_mixture/environment)
	. = ..()
	if(is_station_level(z))
		miasma()
