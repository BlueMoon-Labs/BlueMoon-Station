/// Amount of travel distance to force open tram doors while moving
#define TRAM_DOOR_RELEASE_THRESHOLD 17

// Airlock icon states, local to the airlock files
#define AIRLOCK_CLOSED 1
#define AIRLOCK_CLOSING 2
#define AIRLOCK_OPEN 3
#define AIRLOCK_OPENING 4

/obj/machinery/door/airlock/tram
	name = "tram door"
	icon = 'modular_bluemoon/icons/obj/doors/airlocks/tram/tram.dmi'
	overlays_file = 'modular_bluemoon/icons/obj/doors/airlocks/tram/tram-overlays.dmi'
	opacity = FALSE
	assemblytype = /obj/structure/door_assembly/multi_tile/door_assembly_tram
	airlock_material = "glass"
	air_tight = TRUE
	req_access = list(ACCESS_TCOMSAT)
	transport_linked_id = TRAMSTATION_LINE_1
	doorOpen = 'modular_bluemoon/sound/machines/tram/tramopen.ogg'
	doorClose = 'modular_bluemoon/sound/machines/tram/tramclose.ogg'
	autoclose = FALSE
	has_environment_lights = FALSE
	bound_width = 64
	/// Weakref to the tram we're attached
	var/datum/weakref/transport_ref
	var/retry_counter = 0
	var/crushing_in_progress = FALSE
	COOLDOWN_DECLARE(release_cooldown)

/obj/machinery/door/airlock/tram/Initialize(mapload)
	. = ..()
	if(!id_tag)
		id_tag = assign_random_name()
	SetBounds()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/door/airlock/tram/LateInitialize()
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(open))
	SStransport.doors += src
	find_tram()

/obj/machinery/door/airlock/tram/Destroy()
	SStransport.doors -= src
	if(filler)
		filler.force_destroy()
	return ..()

/obj/machinery/door/airlock/tram/SetBounds()
	bound_width = 2 * world.icon_size
	bound_height = world.icon_size
	if(!filler)
		filler = new(get_step(src, EAST), src)
	else
		filler.loc = get_step(src, EAST)
	filler.sync()

/obj/machinery/door/airlock/tram/Adjacent(atom/neighbor)
	return ..() || filler?.Adjacent(neighbor)

/obj/machinery/door/airlock/tram/narsie_act()
	return

/obj/machinery/door/airlock/tram/open(forced = DEFAULT_DOOR_CHECKS)
	if(operating || welded || locked)
		return FALSE

	if(!density)
		return TRUE

	if(forced == DEFAULT_DOOR_CHECKS && (!hasPower() || wires.is_cut(WIRE_OPEN)))
		return FALSE

	operating = TRUE
	var/rapid = forced >= BYPASS_DOOR_CHECKS
	if(!rapid)
		use_power(50)
		playsound(src, doorOpen, 40, FALSE)
		update_icon(ALL, AIRLOCK_OPENING, TRUE)
		sleep(0.9 SECONDS)
		if(QDELETED(src))
			return FALSE

	density = FALSE
	filler?.sync()
	flags_1 &= ~PREVENT_CLICK_UNDER_1
	air_update_turf(TRUE)
	sleep(rapid ? 0.2 SECONDS : 0.9 SECONDS)
	if(QDELETED(src))
		return FALSE
	layer = OPEN_DOOR_LAYER
	operating = FALSE
	update_icon(ALL, AIRLOCK_OPEN, TRUE)
	return TRUE

/obj/machinery/door/airlock/tram/close(forced = DEFAULT_DOOR_CHECKS, force_crush = FALSE)
	retry_counter++
	if(retry_counter >= 3 || force_crush || forced == BYPASS_DOOR_CHECKS)
		try_to_close(forced = BYPASS_DOOR_CHECKS)
		return

	if(retry_counter > 1)
		playsound(src, 'modular_bluemoon/sound/machines/tram/door_chime.ogg', 40, vary = FALSE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)

	addtimer(CALLBACK(src, PROC_REF(verify_status)), 2.7 SECONDS)
	try_to_close()

/// Perform a close attempt and report TRUE/FALSE if it worked
/obj/machinery/door/airlock/tram/proc/try_to_close(forced = DEFAULT_DOOR_CHECKS)
	if(operating || welded || locked)
		return FALSE
	if(density)
		return TRUE
	crushing_in_progress = TRUE
	var/hungry_door = (forced == BYPASS_DOOR_CHECKS || !safe)
	if((obj_flags & EMAGGED) || !safe)
		do_sparks(3, TRUE, src)
		playsound(src, "sparks", 75, FALSE, SHORT_RANGE_SOUND_EXTRARANGE)
	operating = TRUE
	use_power(50)
	if(forced != BYPASS_DOOR_CHECKS)
		playsound(src, doorClose, 40, FALSE)
	layer = CLOSED_DOOR_LAYER
	update_icon(ALL, AIRLOCK_CLOSING, TRUE)
	sleep(0.9 SECONDS)
	if(QDELETED(src))
		return FALSE
	if(!hungry_door)
		for(var/turf/checked_turf in locs)
			for(var/atom/movable/blocker in checked_turf)
				if(blocker.density && blocker != src && blocker != filler)
					say("Пожалуйста, отойдите от дверей!")
					playsound(src, 'sound/machines/buzz-sigh.ogg', 60, vary = FALSE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
					layer = OPEN_DOOR_LAYER
					operating = FALSE
					update_icon(ALL, AIRLOCK_OPEN, TRUE)
					return FALSE
	sleep(0.7 SECONDS)
	if(QDELETED(src))
		return FALSE
	density = TRUE
	filler?.sync()
	flags_1 |= PREVENT_CLICK_UNDER_1
	air_update_turf(TRUE)
	crush()
	crushing_in_progress = FALSE
	sleep(0.9 SECONDS)
	if(QDELETED(src))
		return FALSE
	operating = FALSE
	update_icon(ALL, AIRLOCK_CLOSED, TRUE)
	retry_counter = 0
	return TRUE

/// Crush the jerk holding up the tram from moving
/obj/machinery/door/airlock/tram/crush()
	for(var/turf/checked_turf in locs)
		for(var/mob/living/future_pancake in checked_turf)
			future_pancake.visible_message(span_warning("[capitalize(src.name)] сердито пищит и прищемляет [future_pancake]!"), span_userdanger("[capitalize(src.name)] сердито пищит и прищемляет вас!"))
			future_pancake.add_splatter_floor(checked_turf)
			log_combat(src, future_pancake, "crushed")
			future_pancake.apply_damage(DOOR_CRUSH_DAMAGE * 2, BRUTE, BODY_ZONE_CHEST, wound_bonus = 10)
			future_pancake.Paralyze(2 SECONDS)
			if(ishuman(future_pancake) && !HAS_TRAIT(future_pancake, TRAIT_ROBOTIC_ORGANISM))
				future_pancake.emote("scream")

		for(var/obj/vehicle/sealed/mecha/mech in checked_turf)
			mech.take_damage(DOOR_CRUSH_DAMAGE)
			log_combat(src, mech, "crushed")

/// After the third failed close the door crushes whoever is in the way
/obj/machinery/door/airlock/tram/proc/verify_status()
	if(density && !operating)
		return

	if(retry_counter < 2)
		close()
		return

	playsound(src, 'sound/machines/buzz-two.ogg', 60, vary = FALSE, extrarange = SHORT_RANGE_SOUND_EXTRARANGE)
	say("ВЫ ЗАДЕРЖИВАЕТЕ ТРАМВАЙ, ПРИДУРОК!")
	close(forced = BYPASS_DOOR_CHECKS)

/// Set the weakref for the tram we're attached to
/obj/machinery/door/airlock/tram/proc/find_tram()
	for(var/datum/transport_controller/linear/tram/tram as anything in SStransport.transports_by_type[TRANSPORT_TYPE_TRAM])
		if(tram.specific_transport_id == transport_linked_id)
			transport_ref = WEAKREF(tram)

/obj/machinery/door/airlock/tram/examine(mob/user)
	. = ..()
	. += span_notice("На случай аварии дверь можно открыть [EXAMINE_HINT("голыми руками")].")

/obj/machinery/door/airlock/tram/on_attack_hand(mob/user, act_intent = user?.a_intent, unarmed_attack_flags)
	if(!hasPower() && density && !operating)
		try_safety_unlock(user)
		return TRUE
	return ..()

/// Tram doors can be opened with hands when unpowered
/obj/machinery/door/airlock/tram/proc/try_safety_unlock(mob/user)
	if(!COOLDOWN_FINISHED(src, release_cooldown))
		return

	COOLDOWN_START(src, release_cooldown, 1.2 SECONDS)
	playsound(src, 'sound/machines/airlockforced.ogg', 40, FALSE)
	balloon_alert_to_viewers("дёргает аварийный рычаг!", vision_distance = COMBAT_MESSAGE_RANGE)
	if(do_after(user, 1.2 SECONDS, target = src))
		open(BYPASS_DOOR_CHECKS)

/// If you pry (bump) the doors open midtravel, open quickly so you can jump out and make a daring escape.
/obj/machinery/door/airlock/tram/bumpopen(mob/living/user)
	if(operating || !density)
		return

	if(!hasPower())
		try_safety_unlock(user)
		return

	if(!COOLDOWN_FINISHED(src, release_cooldown))
		return

	var/datum/transport_controller/linear/tram/tram_part = transport_ref?.resolve()
	add_fingerprint(user)
	if(!tram_part?.controller_active)
		return
	if(tram_part.travel_remaining < TRAM_DOOR_RELEASE_THRESHOLD || tram_part.travel_remaining > tram_part.travel_trip_length - TRAM_DOOR_RELEASE_THRESHOLD)
		return
	COOLDOWN_START(src, release_cooldown, 1.2 SECONDS)
	playsound(src, 'sound/machines/airlockforced.ogg', 40, FALSE)
	balloon_alert_to_viewers("дёргает аварийный рычаг!", vision_distance = COMBAT_MESSAGE_RANGE)
	if(do_after(user, 0.6 SECONDS, target = src, timed_action_flags = IGNORE_USER_LOC_CHANGE))
		open(BYPASS_DOOR_CHECKS)

/obj/structure/door_assembly/multi_tile/door_assembly_tram
	name = "tram door assembly"
	icon = 'modular_bluemoon/icons/obj/doors/airlocks/tram/tram.dmi'
	base_name = "tram door"
	overlays_file = 'modular_bluemoon/icons/obj/doors/airlocks/tram/tram-overlays.dmi'
	glass_type = /obj/machinery/door/airlock/tram
	airlock_type = /obj/machinery/door/airlock/tram
	glass = FALSE
	noglass = TRUE
	mineral = "titanium"
	material_type = /obj/item/stack/sheet/mineral/titanium
	width = 2

#undef TRAM_DOOR_RELEASE_THRESHOLD

#undef AIRLOCK_CLOSED
#undef AIRLOCK_CLOSING
#undef AIRLOCK_OPEN
#undef AIRLOCK_OPENING
