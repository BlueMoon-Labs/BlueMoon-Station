/**
  * omen.dm: For when you want someone to have a really bad day
  *
  * When you attach an omen component to someone, they start running the risk of all sorts of bad environmental injuries, like nearby vending machines randomly falling on you,
  * or hitting your head really hard when you slip and fall, or... well, for now those two are all I have. More will come.
  *
  * Omens are removed once the victim is either maimed by one of the possible injuries, or if they receive a blessing (read: bashing with a bible) from the chaplain.
  */
/datum/component/omen
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Whatever's causing the omen, if there is one. Destroying the vessel won't stop the omen, but we destroy the vessel (if one exists) upon the omen ending
	var/obj/vessel
	/// If the omen is permanent, it will never go away
	var/permanent = FALSE
	/// Base probability of negative events. Cursed are half as unlucky.
	var/luck_mod = 1
	/// Base damage from negative events. Cursed take 25% less damage.
	var/damage_mod = 1

/datum/component/omen/Initialize(silent=FALSE, vessel)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/person = parent
	if(!silent)
		to_chat(person, "<span class='warning'>У вас плохое предчувствие...</span>")
	src.vessel = vessel

/datum/component/omen/Destroy(force, silent)
	var/mob/living/person = parent
	to_chat(person, span_nicegreen("Вы чувствуете, что ужасное проклятие было снято!"))

	if(vessel)
		vessel.visible_message("<span class='warning'>[vessel] burns up in a sinister flash, taking an evil energy with it...</span>")
		vessel = null
	return ..()

/datum/component/omen/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(check_accident))
	RegisterSignal(parent, COMSIG_ON_CARBON_SLIP, PROC_REF(check_slip))
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(check_death))

/datum/component/omen/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ON_CARBON_SLIP, COMSIG_MOVABLE_MOVED, COMSIG_LIVING_DEATH))

/**
  * check_accident() is called each step we take
  *
  * While we're walking around, roll to see if there's any environmental hazards (currently only vending machines) on one of the adjacent tiles we can trigger.
  * We do the prob() at the beginning to A. add some tension for /when/ it will strike, and B. (more importantly) ameliorate the fact that we're checking up to 5 turfs's contents each time
  */
/datum/component/omen/proc/check_accident(atom/movable/our_guy)
	//SIGNAL_HANDLER

	if(!isliving(our_guy))
		return

	var/mob/living/living_guy = our_guy

	if(!prob(15 * luck_mod))
		return

	var/our_guy_pos = get_turf(living_guy)

	for(var/turf_content in our_guy_pos)
		if(istype(turf_content, /obj/machinery/door/airlock))
			to_chat(living_guy, span_warning("Злая сила приводит в действие механизм двери..."))
			var/obj/machinery/door/airlock/darth_airlock = turf_content
			living_guy.apply_status_effect(STATUS_EFFECT_PARALYZED, 10)
			var/b = darth_airlock.safe
			darth_airlock.safe = FALSE
			INVOKE_ASYNC(darth_airlock, TYPE_PROC_REF(/obj/machinery/door/airlock, close), TRUE)
			INVOKE_ASYNC(darth_airlock, TYPE_PROC_REF(/obj/machinery/door/airlock, crush), TRUE)
			darth_airlock.safe = b
			if(!permanent)
				qdel(src)
			return

	for(var/t in get_adjacent_open_turfs(living_guy))

		var/turf/the_turf = t

		if(living_guy.can_z_move(DOWN, the_turf, null, ZMOVE_FALL_FLAGS))
			to_chat(living_guy, "<span class='warning'>Злая воля влечёт вас к краю...</span>")
			living_guy.throw_at(the_turf, 1, 10, force = MOVE_FORCE_EXTREMELY_STRONG)
			if(!permanent)
				qdel(src)
			return

		for(var/obj/machinery/vending/darth_vendor in the_turf)
			if(darth_vendor.tiltable)
				darth_vendor.tilt(living_guy)
				if(!permanent)
					qdel(src)
				return

/// If we get knocked down, see if we have a really bad slip and bash our head hard
/datum/component/omen/proc/check_slip(mob/living/our_guy, amount)
	SIGNAL_HANDLER

	if(prob(30)) // AAAA
		INVOKE_ASYNC(our_guy, TYPE_PROC_REF(/mob, emote), "scream")
		to_chat(our_guy, span_warning("Какая ужасная ночь для того, чтобы быть проклятым!"))

	//if(amount <= 0 || prob(50)) // 50% chance to bonk our head
	//	return

	if(prob(30 * luck_mod))
		var/obj/item/bodypart/the_head = our_guy.get_bodypart(BODY_ZONE_HEAD)
		if(!the_head)
			return

		playsound(get_turf(our_guy), "sound/effects/tableheadsmash.ogg", 90, TRUE)
		our_guy.visible_message("<span class='danger'>[our_guy] сильно ударяется головой при падении!</span>", "<span class='userdanger'>Ты сильно ударяешься головой при падении!</span>")
		the_head.receive_damage(75 * damage_mod)
		our_guy.adjustOrganLoss(ORGAN_SLOT_BRAIN, 100 * damage_mod)
		if(!permanent)
			qdel(src)

/// Severe deaths. Normally lifts the curse.
/datum/component/omen/proc/check_death(mob/living/our_guy)
	SIGNAL_HANDLER
	var/datum/component/mood/M = our_guy.GetComponent(/datum/component/mood)

	if(!("blessing" in M.mood_events))
		return

	/*if (!("blessing" in our_guy.mob_mood.mood_events))
		return*/

	qdel(src)

/// Creates a localized explosion that shakes the camera
/datum/component/omen/proc/death_explode(mob/living/our_guy)
	explosion(our_guy)

	for(var/mob/witness in view(2, our_guy))
		shake_camera(witness, 1 SECONDS, 2)

/**
 * The quirk omen. Permanent.
 * Has only a 50% chance of bad things happening, and takes only 25% of normal damage.
 */
/datum/component/omen/quirk
	permanent = TRUE
	luck_mod = 0.5 // 50% chance of bad things happening
	damage_mod = 0.25 // 25% of normal damage

/datum/component/omen/quirk/check_death(mob/living/our_guy)
	/*if(!iscarbon(our_guy))
		our_guy.gib()
		return*/

	// нет, мы не взрываемся
	/*
	// Don't explode if buckled to a stasis bed
	if(our_guy.buckled)
		var/obj/machinery/stasis/stasis_bed = our_guy.buckled
		if(istype(stasis_bed))
			return

	death_explode(our_guy)
	var/mob/living/carbon/player = our_guy
	player.spread_bodyparts()
	player.spawn_gibs()
	*/

	return
