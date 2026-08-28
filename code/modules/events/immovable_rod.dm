/*
Immovable rod random event.
The rod will spawn at some location outside the station, and travel in a straight line to the opposite side of the station.
*/

/// "What the fuck was that?!"
/obj/effect/immovablerod
	name = "immovable rod"
	desc = "What the fuck is that?"
	icon = 'icons/obj/objects.dmi'
	icon_state = "immrod"
	throwforce = 100
	move_force = INFINITY
	move_resist = INFINITY
	pull_force = INFINITY
	density = TRUE
	anchored = TRUE
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	movement_type = PHASING | FLYING
	/// The turf we're looking to coast to.
	var/turf/destination_turf
	/// Whether we notify ghosts.
	var/notify = TRUE
	/// We can designate a specific target to aim for, in which case we'll try to snipe them rather than just flying in a random direction
	var/atom/special_target
	/// How many mobs we've penetrated one way or another
	var/num_mobs_hit = 0
	/// How many mobs we've hit with clients
	var/num_sentient_mobs_hit = 0
	/// How many people we've hit with clients
	var/num_sentient_people_hit = 0
	/// The rod levels up with each kill, increasing in size and auto-renaming itself.
	var/dnd_style_level_up = TRUE
	/// Whether the rod can loop across other z-levels. The rod will still loop when the z-level is self-looping even if this is FALSE.
	var/loopy_rod = FALSE
	/// Guard against double-catching by a rodstopper.
	var/being_caught = FALSE

/obj/effect/immovablerod/Initialize(mapload, atom/target_atom, atom/specific_target, force_looping = FALSE)
	. = ..()
	SSaugury.register_doom(src, 2000)

	var/turf/real_destination = get_turf(target_atom)
	destination_turf = real_destination
	src.special_target = specific_target
	loopy_rod ||= force_looping

	ADD_TRAIT(src, TRAIT_FREE_HYPERSPACE_MOVEMENT, INNATE_TRAIT)

	GLOB.poi_list += src

	RegisterSignal(src, COMSIG_ATOM_ENTERING, PROC_REF(on_entering_atom))

	if(special_target)
		walk_towards(src, special_target, 1)
	else if(real_destination && real_destination.z == z)
		destination_turf = real_destination
		SSmove_manager.move_towards(src, real_destination)

/obj/effect/immovablerod/Destroy(force)
	UnregisterSignal(src, COMSIG_ATOM_ENTERING)
	SSaugury.unregister_doom(src) //метеоры так и делают, род забывал
	//walk_towards() из New() заводит внутренний цикл BYOND, а тот держит ссылку на
	//движимое и продолжает тикать после qdel - род так и не доходит до сборщика.
	walk(src, 0)
	SSmove_manager.stop_looping(src)
	GLOB.poi_list -= src
	special_target = null
	destination_turf = null
	return ..()

/obj/effect/immovablerod/examine(mob/user)
	. = ..()
	if(!isobserver(user))
		return

	if(!num_mobs_hit)
		. += span_notice("Пока что этот стержень никого не задел.")
		return

	. += "\t<span class='notice'>Пока что этот стержень задел: \n\
		\t\t[num_mobs_hit] существ всего, \n\
		\t\tиз них [num_sentient_mobs_hit] разумных, \n\
		\t\tи [num_sentient_people_hit] из них - разумные люди</span>"

/obj/effect/immovablerod/Topic(href, href_list)
	if(href_list["orbit"])
		var/mob/dead/observer/ghost = usr
		if(istype(ghost))
			ghost.ManualFollow(src)

/obj/effect/immovablerod/proc/on_entering_atom(datum/source, atom/destination, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	if(destination.density && isturf(destination))
		Bump(destination)

/obj/effect/immovablerod/Moved(atom/old_loc, movement_dir, forced)
	if(!loc)
		return ..()

	for(var/atom/movable/to_bump in loc)
		if((to_bump != src) && !QDELETED(to_bump) && (to_bump.density || isliving(to_bump)))
			Bump(to_bump)

	// If we have a special target, we should definitely make an effort to go find them.
	if(special_target)
		var/turf/target_turf = get_turf(special_target)

		// Did they escape the z-level? Let's see if we can chase them down!
		if(target_turf.z != z)
			var/direction = target_turf.z > z ? UP : DOWN
			var/turf/target_z_turf = get_step_multiz(src, direction)

			visible_message(span_danger("[src] выныривает из реальности."))

			if(!do_teleport(src, target_z_turf))
				// We failed to teleport. Might as well admit defeat.
				qdel(src)
				return ..()

			visible_message(span_danger("[src] ныряет обратно в реальность."))
			walk(src, 0)
			walk_towards(src, special_target, 1)

		if(loc == target_turf)
			complete_trajectory()

		return ..()

	// If we have a destination turf, let's make sure it's also still valid.
	if(destination_turf)

		// If the rod is a loopy_rod, run complete_trajectory() to get a new edge turf to fly to.
		// Otherwise, qdel the rod.
		if(destination_turf.z != z)
			if(loopy_rod)
				complete_trajectory()
				return ..()

			qdel(src)
			return ..()

		// Did we reach our destination? We're probably on Icebox. Let's get rid of ourselves.
		// Ordinarily this won't happen as the average destination is the edge of the map and
		// the rod will auto transition to a new z-level.
		// If the rod is parallel to the destination at the world border, it is likely stuck (once again, icebox)
		if((loc == destination_turf) || ((y == destination_turf.y || x == destination_turf.x) && (y == world.maxy || x == world.maxx || x == 1 || y == 1)))
			qdel(src)
			return ..()

	return ..()

/obj/effect/immovablerod/proc/complete_trajectory()
	// We hit what we wanted to hit, time to go.
	special_target = null
	walk_in_direction(dir)

/obj/effect/immovablerod/singularity_act()
	return

/obj/effect/immovablerod/singularity_pull(atom/singularity, current_size)
	return

/obj/effect/immovablerod/ex_act(severity, target, origin)
	return FALSE //стержень движется сквозь взрывы, как и сквозь всё остальное

/obj/effect/immovablerod/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	return TRUE

/obj/effect/immovablerod/Bump(atom/clong)
	if(!clong)
		return
	if(prob(10))
		playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
		audible_message(span_danger("Вы слышите КЛАНГ!"))

	if(special_target && clong == special_target)
		complete_trajectory()

	// If rod meets rod, they collapse into a singularity. Yes, this means that if two wizard rods collide,
	// they ALSO collapse into a singulo.
	if(istype(clong, /obj/effect/immovablerod))
		visible_message(span_danger("[src] сталкивается с [clong]! Ничего хорошего из этого не выйдет."))
		do_smoke(2, get_turf(src))
		var/obj/singularity/bad_luck = new(get_turf(src))
		bad_luck.energy = 800
		qdel(clong)
		qdel(src)
		return

	// If we Bump into a turf, turf go boom.
	if(isturf(clong))
		if(clong.density)
			clong.ex_act(EXPLODE_HEAVY)
		return ..()

	// If we Bump into an object, smash it as usual.
	if(isobj(clong))
		//rodstopper catches the rod at the cost of itself
		if(istype(clong, /obj/machinery/rodstopper))
			catch_rod(clong)
			return ..()

		var/obj/clong_obj = clong
		clong_obj.take_damage(INFINITY, BRUTE, NONE, TRUE, dir, INFINITY)
		return ..()

	// If we Bump into a living thing, living thing goes splat.
	if(isliving(clong))
		penetrate(clong)
		return ..()

	// If we Bump into anything else, anything goes boom.
	if(isatom(clong))
		clong.ex_act(EXPLODE_HEAVY)
		return ..()

	CRASH("[src] Bump()ed into non-atom thing [clong] ([clong.type])")

/**
 * Called when the rod runs into a rodstopper.
 * The machine holds the rod in place for a few seconds before reality collapses on both of them.
 */
/obj/effect/immovablerod/proc/catch_rod(obj/machinery/rodstopper/stopper)
	if(being_caught)
		return
	being_caught = TRUE
	visible_message(span_boldwarning("[src] с визгом врезается в [stopper], увязая в нём!"))
	playsound(get_turf(src), 'sound/effects/supermatter.ogg', 200, TRUE)
	walk(src, 0)
	SSmove_manager.stop_looping(src)
	visible_message(span_boldwarning("У вас есть пять секунд, чтобы отойти подальше перед локальным коллапсом реальности!"))
	addtimer(CALLBACK(src, PROC_REF(reality_collapse), stopper), 5 SECONDS)

/obj/effect/immovablerod/proc/reality_collapse(obj/machinery/rodstopper/stopper)
	var/turf/collapse_turf = get_turf(stopper)
	if(!QDELETED(stopper))
		stopper.visible_message(span_boldwarning("[stopper] не выдерживает и схлопывается вместе со стержнем!"))
		new /obj/effect/anomaly/flux(collapse_turf)
		explosion(collapse_turf, light_impact_range = 2, flame_range = 2)
		qdel(stopper)
	if(!QDELETED(src))
		qdel(src)

/obj/effect/immovablerod/proc/penetrate(mob/living/smeared_mob)
	smeared_mob.visible_message(span_danger("[smeared_mob] протаранен неподвижным стержнем!") , span_userdanger("Стержень пронзает вас насквозь!") , span_danger("Вы слышите КЛАНГ!"))

	if(smeared_mob.stat != DEAD)
		num_mobs_hit++
		if(smeared_mob.client)
			num_sentient_mobs_hit++
			if(iscarbon(smeared_mob))
				num_sentient_people_hit++
			if(dnd_style_level_up)
				transform = transform.Scale(1.005, 1.005)
				name = "[initial(name)] убийцы разумных +[num_sentient_mobs_hit]"

	if(ishuman(smeared_mob))
		smeared_mob.apply_damage(100, BRUTE, spread_damage = TRUE)
		smeared_mob.apply_damage(60, BRUTE, BODY_ZONE_CHEST, wound_bonus = 20, sharpness = SHARP_POINTY)
	else
		smeared_mob.adjustBruteLoss(160)

	if(smeared_mob.density || prob(10))
		smeared_mob.ex_act(EXPLODE_HEAVY)

/obj/effect/immovablerod/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return

	// Стержень может суплекснуть тот, кто умеет это делать (трейт), либо директор исследований - по старой традиции.
	if(!(HAS_MIND_TRAIT(user, TRAIT_ROD_SUPLEX) || user.job == "Research Director"))
		return

	playsound(src, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	for(var/mob/living/nearby_mob in urange(8, src))
		if(nearby_mob.stat != CONSCIOUS)
			continue
		shake_camera(nearby_mob, 2, 3)

	return suplex_rod(user)

/**
 * Called when someone manages to suplex the rod.
 *
 * Arguments
 * * strongman - the suplexer of the rod.
 */
/obj/effect/immovablerod/proc/suplex_rod(mob/living/strongman)
	strongman.client?.give_award(/datum/award/achievement/misc/feat_of_strength, strongman)
	strongman.visible_message(
		span_boldwarning("[strongman] суплексит [src], впечатывая его в пол!"),
		span_warning("Когда вы суплексите [src] в пол, ваше тело наполняется силой!")
		)
	sound_to_playing_players('sound/items/handling/lead_pipe/lead_pipe_drop.ogg')
	new /obj/structure/festivus/anchored(drop_location())
	new /obj/effect/anomaly/flux(drop_location())

	strongman.apply_status_effect(/datum/status_effect/exercised) //time for a nap, you earned it

	qdel(src)
	return TRUE

/* Ниже - админские вспомогательные проки для работы с мемными стержнями. */
/**
 * Stops your rod's automated movement. Sit... Stay... Good rod!
 */
/obj/effect/immovablerod/proc/sit_stay_good_rod()
	walk(src, 0)
	SSmove_manager.stop_looping(src)

/**
 * Allows your rod to release restraint level zero and go for a walk.
 *
 * If walkies_location is set, rod will move towards the location, chasing it across z-levels if necessary.
 * If walkies_location is not set, rod will call complete_trajectory() and follow the logic from that proc.
 *
 * Arguments:
 * * walkies_location - Any atom that the immovable rod will now chase down as a special target.
 */
/obj/effect/immovablerod/proc/go_for_a_walk(walkies_location = null)
	if(walkies_location)
		special_target = walkies_location
		walk(src, 0)
		walk_towards(src, special_target, 1)
		return

	complete_trajectory()

/**
 * Rod will walk towards edge turf in the specified direction.
 *
 * Arguments:
 * * direction - The direction to walk the rod towards: NORTH, SOUTH, EAST, WEST.
 */
/obj/effect/immovablerod/proc/walk_in_direction(direction)
	destination_turf = get_edge_target_turf(src, direction)
	walk(src, 0)
	SSmove_manager.move_towards(src, destination_turf)

/datum/round_event_control/immovable_rod
	name = "Immovable Rod"
	typepath = /datum/round_event/immovable_rod
	min_players = 50
	max_occurrences = 1
	category = EVENT_CATEGORY_SPACE
	description = "The station passes through an immovable rod."
	admin_setup = list(/datum/event_admin_setup/set_location/immovable_rod, /datum/event_admin_setup/question/immovable_rod)

/datum/round_event/immovable_rod
	announce_when = 5
	/// Admins can pick a spot the rod will aim for.
	var/atom/special_target
	/// Admins can also force it to loop around forever, or at least until the RD gets their hands on it.
	var/force_looping = FALSE

/datum/round_event/immovable_rod/announce(fake)
	priority_announce("Что это за хуета?!", "Приоритетная Тревога!", 'sound/announcer/classic/irod.ogg')

/datum/round_event/immovable_rod/start()
	var/startside = pick(GLOB.cardinals)
	var/z = pick(SSmapping.levels_by_trait(ZTRAIT_STATION))
	var/turf/end_turf = spaceDebrisFinishLoc(startside, z)
	var/turf/start_turf = spaceDebrisStartLoc(startside, z)
	var/atom/rod = new /obj/effect/immovablerod(start_turf, end_turf, special_target, force_looping)
	announce_to_ghosts(rod)

/// Admins can pick a spot the rod will aim for
/datum/event_admin_setup/set_location/immovable_rod
	input_text = "Aimed at current location?"

/datum/event_admin_setup/set_location/immovable_rod/apply_to_event(datum/round_event/immovable_rod/event)
	event.special_target = chosen_turf

/// Admins can also force it to loop around forever, or at least until the RD gets their hands on it.
/datum/event_admin_setup/question/immovable_rod
	input_text = "Would you like this rod to force-loop across space z-levels?"

/datum/event_admin_setup/question/immovable_rod/apply_to_event(datum/round_event/immovable_rod/event)
	event.force_looping = chosen
	var/log_message = "[key_name_admin(usr)] направил неподвижный стержень [event.force_looping ? "(с принудительным зацикливанием) " : ""]в [event.special_target ? AREACOORD(event.special_target) : "случайную точку"]."
	message_admins(log_message)
	log_admin(log_message)
