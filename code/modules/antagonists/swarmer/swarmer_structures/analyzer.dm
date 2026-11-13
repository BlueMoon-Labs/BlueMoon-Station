#define SWARMER_ANALYZE_DELAY(target) (iscarbon(target) ? 45 SECONDS : 15 SECONDS)

#define SWARMER_ANALYZE_NO_MIND_CARBON_MODIFIER 0.3

#define SWARMER_ANALYZE_CARBON_GAIN (rand(60, 80))
#define SWARMER_ANALYZE_HOSTILE_GAIN (rand(15, 30))
#define SWARMER_ANALYZE_LIVING_GAIN (rand(10, 20))
#define SWARMER_ANALYZE_MACHINE_GAIN (rand(50, 75))
#define SWARMER_ANALYZE_ROBOTIC_LIMB_GAIN 10
#define SWARMER_ANALYZE_IMPLANT_GAIN 10
#define SWARMER_ANALYZE_AMPUTATION_CHANCE 10
#define SWARMER_ANALYZE_FRACTURE_CHANCE 33
#define SWARMER_ANALYZE_IMPLANT_CHANCE 40

/obj/structure/swarmer/organic_analyzer
	name = "swarmer organic analyzer"
	desc = "Устройство свармеров, получающее ресурсы при анализе живых существ. Анализ может привести к перелому, потере конечности или извлечению импланта."
	swarmer_examine = "Анализирует живых существ. Не делает этого в открученном состоянии. Загрузка в эту машину происходит ПКМ по существу."
	icon_state = "bio_analyzer"
	max_integrity = 150
	var/mob/living/occupant
	var/analyze_timer
	var/gib_after_analyzing = FALSE
	var/datum/gas_mixture/air_contents = null
	var/datum/effect_system/spark_spread/spark_system
	var/datum/looping_sound/swarmer_analyzer/sound_loop

/obj/structure/swarmer/organic_analyzer/Initialize(mapload, datum/team/swarmer_team/swarm_team)
	. = ..()
	refresh_air()
	sound_loop = new(src, FALSE)
	spark_system = new
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

/obj/structure/swarmer/organic_analyzer/Destroy(force)
	if(analyze_timer)
		deltimer(analyze_timer)
	QDEL_NULL(air_contents)
	QDEL_NULL(spark_system)
	QDEL_NULL(sound_loop)
	if(occupant)
		occupant.forceMove(loc)
		occupant.SetParalyzed(0)
		occupant.SetSleeping(10 SECONDS)
	occupant = null
	return ..()

/obj/structure/swarmer/organic_analyzer/emp_act(severity)
	. = ..()
	if(QDELETED(src) || (. & EMP_PROTECT_SELF) || !occupant)
		return

	sound_loop.stop()
	addtimer(CALLBACK(sound_loop, TYPE_PROC_REF(/datum/looping_sound, start)), SWARMER_STRUCTURE_EMP_DURATION * severity, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_NO_HASH_WAIT | TIMER_DELETE_ME)

	animate(src, transform = matrix())

	var/new_delay = SWARMER_ANALYZE_DELAY(occupant) + SWARMER_STRUCTURE_EMP_DURATION * severity
	deltimer(analyze_timer)
	analyze_timer = addtimer(CALLBACK(src, PROC_REF(finish_analyzing)), new_delay, TIMER_STOPPABLE)

	occupant.SetParalyzed(new_delay + 1 SECONDS, TRUE)
	occupant.SetSleeping(new_delay + 1 SECONDS)

/obj/structure/swarmer/organic_analyzer/update_icon_state()
	icon_state = occupant ? "[initial(icon_state)]_mob" : initial(icon_state)

/obj/structure/swarmer/organic_analyzer/set_anchored(anchorvalue)
	var/was_anchored = anchored
	. = ..()
	if(was_anchored != anchored)
		team?.update_analyzer_stats()

/obj/structure/swarmer/organic_analyzer/proc/can_accept_occupant()
	return anchored && !occupant

/obj/structure/swarmer/organic_analyzer/proc/set_occupant(mob/living/new_occupant)
	occupant = new_occupant
	update_icon(UPDATE_ICON_STATE)
	team?.update_analyzer_stats()

/obj/structure/swarmer/organic_analyzer/proc/try_load_mob(mob/living/target, gib_on_end = FALSE)
	if(!can_accept_occupant() || QDELETED(target))
		return FALSE

	set_occupant(target)
	gib_after_analyzing = gib_on_end
	var/delay = SWARMER_ANALYZE_DELAY(occupant)
	analyze_timer = addtimer(CALLBACK(src, PROC_REF(finish_analyzing)), delay, TIMER_STOPPABLE)
	occupant.Paralyze(delay + 1 SECONDS, TRUE)
	occupant.Sleeping(delay + 1 SECONDS)
	occupant.forceMove(src)

	spark_system.start()
	sound_loop.start()
	return TRUE

/obj/structure/swarmer/organic_analyzer/proc/finish_analyzing()
	analyze_timer = null
	sound_loop.stop()
	if(QDELETED(occupant) || !(occupant in contents))
		set_occupant(null)
		return
	if(swarmer_actions_blocked(src))
		var/mob/living/patient = occupant
		set_occupant(null)
		patient.SetParalyzed(0)
		patient.SetSleeping(0)
		patient.forceMove(drop_location())
		return

	balloon_alert_to_viewers("обработано!")
	refresh_air()
	sound_loop.stop()
	animate(src, transform = matrix())
	adjust_resources()

	if(gib_after_analyzing)
		occupant.gib()
		set_occupant(null)
		return

	if(iscarbon(occupant))
		var/mob/living/carbon/patient = occupant
		injure_random_limb(patient)
		extract_random_implant(patient)
	teleport_to_safe()
	if(iscarbon(occupant))
		var/mob/living/carbon/target = occupant
		if(target.handcuffed)
			target.clear_cuffs(target.handcuffed)

	set_occupant(null)

/obj/structure/swarmer/organic_analyzer/proc/adjust_resources()
	if(HAS_TRAIT(occupant, TRAIT_ROBOTIC_ORGANISM))
		return team?.adjust_metal(SWARMER_ANALYZE_MACHINE_GAIN)
	if(iscarbon(occupant))
		var/modifier = occupant.mind ? 1 : SWARMER_ANALYZE_NO_MIND_CARBON_MODIFIER
		return team?.adjust_organic(SWARMER_ANALYZE_CARBON_GAIN * modifier)
	if(ishostile(occupant))
		return team?.adjust_organic(SWARMER_ANALYZE_HOSTILE_GAIN)
	if(isliving(occupant))
		return team?.adjust_organic(SWARMER_ANALYZE_LIVING_GAIN)

/obj/structure/swarmer/organic_analyzer/proc/extract_random_implant(mob/living/carbon/patient)
	if(!prob(SWARMER_ANALYZE_IMPLANT_CHANCE))
		return

	var/list/eligible_implants = list()
	for(var/obj/item/organ/implant as anything in patient.internal_organs)
		if(implant.owner != patient || (implant.organ_flags & ORGAN_UNREMOVABLE) || istype(implant, /obj/item/organ/cyberimp/arm/power_cord))
			continue
		if(istype(implant, /obj/item/organ/cyberimp) || istype(implant, /obj/item/organ/organic_implants))
			eligible_implants += implant

	if(!length(eligible_implants))
		return
	var/obj/item/organ/chosen_implant = pick(eligible_implants)
	chosen_implant.Remove()
	qdel(chosen_implant)
	team?.adjust_metal(SWARMER_ANALYZE_IMPLANT_GAIN)

/obj/structure/swarmer/organic_analyzer/proc/injure_random_limb(mob/living/carbon/patient)
	var/naga_anatomy = HAS_TRAIT(patient, TRAIT_NAGA_ANATOMY)
	var/list/eligible_limbs = list()
	for(var/obj/item/bodypart/limb as anything in patient.bodyparts)
		if(limb.body_zone == BODY_ZONE_HEAD || limb.body_zone == BODY_ZONE_CHEST)
			continue
		if(naga_anatomy && (limb.body_zone == BODY_ZONE_L_LEG || limb.body_zone == BODY_ZONE_R_LEG) && !istype(limb, /obj/item/bodypart/l_leg/naga_tail))
			continue
		eligible_limbs += limb

	if(prob(SWARMER_ANALYZE_AMPUTATION_CHANCE) && amputate_random_limb(patient, eligible_limbs))
		return
	if(!ishuman(patient))
		return
	for(var/obj/item/bodypart/limb as anything in shuffle(eligible_limbs))
		if(!prob(SWARMER_ANALYZE_FRACTURE_CHANCE))
			continue
		if(limb.status == BODYPART_ROBOTIC)
			team?.adjust_metal(SWARMER_ANALYZE_ROBOTIC_LIMB_GAIN)
		var/datum/wound/blunt/severe/fracture = new
		fracture.apply_wound(limb)
		break

/obj/structure/swarmer/organic_analyzer/proc/amputate_random_limb(mob/living/carbon/patient, list/eligible_limbs)
	// При отсечении руки имплант ушёл бы вместе с ней, поэтому защищаем и саму руку.
	var/obj/item/organ/cyberimp/arm/power_cord/power_cord = locate() in patient.internal_organs
	var/protected_zone = power_cord ? check_zone(power_cord.zone) : null
	var/list/amputation_candidates = list()
	for(var/obj/item/bodypart/limb as anything in eligible_limbs)
		if(limb.dismemberable && limb.body_zone != protected_zone)
			amputation_candidates += limb
	if(!length(amputation_candidates))
		return FALSE

	var/obj/item/bodypart/chosen_limb = pick(amputation_candidates)
	var/is_robotic = chosen_limb.status == BODYPART_ROBOTIC
	if(!chosen_limb.dismember())
		return FALSE

	if(!QDELETED(chosen_limb))
		var/turf/limb_turf = get_turf(chosen_limb)
		for(var/obj/item/organ/organ in chosen_limb)
			organ.forceMove(limb_turf)
		qdel(chosen_limb)
	if(is_robotic)
		team?.adjust_metal(SWARMER_ANALYZE_ROBOTIC_LIMB_GAIN)
	return TRUE

/obj/structure/swarmer/organic_analyzer/proc/teleport_to_safe()
	var/mob/living/target = occupant
	var/turf/safe_turf = team?.find_disperse_turf(target)
	if(safe_turf)
		playsound(src, 'sound/effects/sparks4.ogg', 50, TRUE)
		target.SetSleeping(5 SECONDS)
		team.teleport_disperse_target(target, safe_turf)
	if(!QDELETED(target) && target.loc == src)
		target.forceMove(drop_location())

/obj/structure/swarmer/organic_analyzer/return_air()
	return air_contents

/obj/structure/swarmer/organic_analyzer/return_analyzable_air()
	return air_contents

/obj/structure/swarmer/organic_analyzer/proc/refresh_air()
	QDEL_NULL(air_contents)
	// Стандартный объём даёт достаточно молей кислорода для дыхания простых мобов.
	air_contents = new(CELL_VOLUME)
	air_contents.set_temperature(T20C)
	air_contents.set_moles(GAS_O2, MOLES_O2STANDARD)
	air_contents.set_moles(GAS_N2, MOLES_N2STANDARD)

/obj/structure/swarmer/organic_analyzer/swarmer_grab_act(mob/living/simple_animal/hostile/swarmer/swarmer)
	if(!occupant)
		return ..()

	swarmer.balloon_alert(swarmer, "не открутить, работает!")
	return FALSE

#undef SWARMER_ANALYZE_DELAY
#undef SWARMER_ANALYZE_NO_MIND_CARBON_MODIFIER
#undef SWARMER_ANALYZE_CARBON_GAIN
#undef SWARMER_ANALYZE_HOSTILE_GAIN
#undef SWARMER_ANALYZE_LIVING_GAIN
#undef SWARMER_ANALYZE_MACHINE_GAIN
#undef SWARMER_ANALYZE_ROBOTIC_LIMB_GAIN
#undef SWARMER_ANALYZE_IMPLANT_GAIN
#undef SWARMER_ANALYZE_AMPUTATION_CHANCE
#undef SWARMER_ANALYZE_FRACTURE_CHANCE
#undef SWARMER_ANALYZE_IMPLANT_CHANCE
