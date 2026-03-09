/obj/item/gun/medbeam
	name = "Medical Beamgun"
	desc = "Don't cross the streams!"
	icon = 'icons/obj/chronos.dmi'
	icon_state = "chronogun"
	item_state = "chronogun"
	w_class = WEIGHT_CLASS_NORMAL

	var/mob/living/current_target
	var/last_check = 0
	var/check_delay = 10 //Check los as often as possible, max resolution is SSobj tick though
	var/max_range = 8
	var/active = 0
	var/datum/beam/current_beam = null
	var/mounted = 0 //Denotes if this is a handheld or mounted version

	var/main_heal = -10
	var/second_heal = -5

	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/medbeam/Destroy(mob/user)
	LoseTarget()
	return ..()

/obj/item/gun/medbeam/dropped(mob/user)
	..()
	LoseTarget()

/obj/item/gun/medbeam/equipped(mob/user)
	..()
	LoseTarget()

/obj/item/gun/medbeam/proc/LoseTarget()
	if(active)
		QDEL_NULL(current_beam)
		active = 0
		on_beam_release(current_target)
	STOP_PROCESSING(SSobj, src)
	current_target = null

/obj/item/gun/medbeam/proc/beam_died()
	SIGNAL_HANDLER
	current_beam = null
	active = FALSE //skip qdelling the beam again if we're doing this proc, because
	if(isliving(loc))
		to_chat(loc, span_warning("You lose control of the beam!"))
	LoseTarget()

/obj/item/gun/medbeam/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, stam_cost = 0)
	if(isliving(user))
		add_fingerprint(user)

	if(current_target)
		LoseTarget()
	if(!isliving(target) || (user == target))
		return

	current_target = target
	active = TRUE
	// current_beam = new(user,current_target,time=6000,beam_icon_state="medbeam",btype=/obj/effect/ebeam/medical)
	// INVOKE_ASYNC(current_beam, TYPE_PROC_REF(/datum/beam, Start))
	current_beam = user.Beam(current_target, icon_state="medbeam", time = 10 MINUTES, maxdistance = max_range, beam_type = /obj/effect/ebeam/medical)
	RegisterSignal(current_beam, COMSIG_PARENT_QDELETING, PROC_REF(beam_died))
	START_PROCESSING(SSobj, src)

	SSblackbox.record_feedback("tally", "gun_fired", 1, type)

/obj/item/gun/medbeam/process()

	var/source = loc
	if(!mounted && !isliving(source))
		LoseTarget()
		return

	if(!current_target)
		LoseTarget()
		return

	if(world.time <= last_check+check_delay)
		return

	last_check = world.time

	// if(get_dist(source, current_target)>max_range || !los_check(source, current_target))
	// 	LoseTarget()
	// 	if(isliving(source))
	// 		to_chat(source, "<span class='warning'>You lose control of the beam!</span>")
	// 	return
	if(!los_check(source, current_target))
		QDEL_NULL(current_beam)
		return

	if(current_target)
		on_beam_tick(current_target)

/obj/item/gun/medbeam/proc/los_check(atom/movable/user, mob/target)
	var/turf/user_turf = user.loc
	if(mounted)
		user_turf = get_turf(user)
	else if(!istype(user_turf))
		return FALSE
	var/obj/dummy = new(user_turf)
	dummy.pass_flags |= PASSTABLE|PASSGLASS|PASSGRILLE //Grille/Glass so it can be used through common windows
	var/turf/previous_step = user_turf
	var/first_step = TRUE
	for(var/turf/next_step as anything in (getline(user_turf, target) - user_turf))
		if(first_step)
			for(var/obj/blocker in user_turf)
				if(!blocker.density || !(blocker.flags_1 & ON_BORDER_1))
					continue
				if(blocker.CanPass(dummy, get_dir(user_turf, next_step)))
					continue
				return FALSE
			first_step = FALSE

		if(mounted && next_step == user_turf)
			continue //Mechs are dense and thus fail the check
		if(next_step.density)
			qdel(dummy)
			return FALSE
		for(var/atom/movable/AM as anything in next_step)
			if(!AM.CanPass(dummy, get_dir(next_step, previous_step)))
				qdel(dummy)
				return FALSE
		for(var/obj/effect/ebeam/medical/B in next_step)// Don't cross the str-beams!
			if(QDELETED(current_beam))
				break
			if(QDELETED(B))
				continue
			if(!B.owner)
				stack_trace("beam without an owner! [B]")
			if(B.owner.origin != current_beam.origin)
				explosion(B.loc, 0, 3, 5, 8)
				qdel(dummy)
				return FALSE
		previous_step = next_step
	qdel(dummy)
	return TRUE

/obj/item/gun/medbeam/proc/on_beam_hit(var/mob/living/target)
	return

/obj/item/gun/medbeam/proc/on_beam_tick(var/mob/living/target)
	if(target.health != target.maxHealth)
		new /obj/effect/temp_visual/heal(get_turf(target), "#80F5FF")
	target.drowsyness = max(target.drowsyness-5, 0)
	target.AdjustUnconscious(main_heal, FALSE)
	target.AdjustAllImmobility(main_heal, FALSE)
	target.adjustStaminaLoss(main_heal, FALSE)
	target.adjustBruteLoss(main_heal)
	target.adjustFireLoss(main_heal)
	target.heal_overall_damage(2,2)
	target.adjustToxLoss(second_heal, forced = TRUE)
	target.adjustOxyLoss(second_heal)
	target.adjust_disgust(second_heal)
	return

/obj/item/gun/medbeam/proc/on_beam_release(var/mob/living/target)
	return

/obj/effect/ebeam/medical
	name = "medical beam"

/obj/item/gun/medbeam/weak
	name = "Civilian Medical Beamgun"
	desc = "Just like a regular beamgun, but cheaper. Used only to stabilize patients in critical condition."

/obj/item/gun/medbeam/weak/on_beam_tick(var/mob/living/target)
	if(target.stat == DEAD)
		LoseTarget()
		return
	if(target.health != target.maxHealth)
		new /obj/effect/temp_visual/heal(get_turf(target), "#80F5FF")
	if(target.health < 50)
		target.adjustBruteLoss(main_heal/2)
		target.adjustFireLoss(main_heal/2)
		target.adjustOxyLoss(second_heal/2)
		target.adjustToxLoss(second_heal/2, forced=TRUE)
	else
		target.adjustBruteLoss(main_heal/4)
		target.adjustFireLoss(main_heal/4)
	return

//////////////////////////////Mech Version///////////////////////////////
/obj/item/gun/medbeam/mech
	mounted = TRUE
	main_heal = -20
	second_heal = -10

/obj/item/gun/medbeam/mech/Initialize(mapload)
	. = ..()
	STOP_PROCESSING(SSobj, src) //Mech mediguns do not process until installed, and are controlled by the holder obj
