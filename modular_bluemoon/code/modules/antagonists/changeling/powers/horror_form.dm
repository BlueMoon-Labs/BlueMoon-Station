#define TRUE_CHANGELING_REFORM (5 MINUTES)
#define TRUE_CHANGELING_HEAL_PER_TICK 3

/// Horror Form — Skyrat modular_skyrat/modules/horrorform (adapted for MOLOT APIs).

/datum/action/changeling/horror_form
	name = "Horror Form"
	desc = "We tear apart our disguise, revealing a monstrous shell."
	helptext = "Massive melee strength and regeneration; limited ranged options. You may revert after several minutes. Costs heavy chemicals."
	button_icon_state = "horror_form"
	chemical_cost = 50
	dna_cost = 4
	req_dna = 5
	req_absorbs = 1
	req_human = TRUE
	loudness = 3

/datum/action/changeling/horror_form/sting_action(mob/user)
	var/mob/living/carbon/human/H = user
	if(!istype(H))
		return FALSE
	H.visible_message("<span class='warning'>[H] convulses as flesh spills outward!</span>", "<span class='danger'>We tear free of our shell!</span>")
	if(!do_after(H, 3 SECONDS, H))
		to_chat(H, "<span class='warning'>Our transformation was interrupted!</span>")
		return FALSE
	var/turf/T = get_turf(H)
	var/mob/living/simple_animal/hostile/true_changeling/TF = new(T)
	var/changeling_name = "Mx."
	switch(H.gender)
		if(MALE)
			changeling_name = "Mr."
		if(FEMALE)
			changeling_name = "Ms."
	changeling_name += pick(GLOB.greek_letters)
	TF.real_name = changeling_name
	TF.name = TF.real_name
	TF.stored_changeling = H
	H.status_flags |= GODMODE
	H.forceMove(TF)
	H.mind.transfer_to(TF)
	H.spawn_gibs()
	return TRUE

/mob/living/simple_animal/hostile/true_changeling
	name = "true changeling"
	real_name = "true changeling"
	desc = "An avalanche of teeth, sinew, and wrong angles."
	icon = 'icons/mob/alien.dmi'
	icon_state = "horror"
	icon_living = "horror"
	icon_dead = "horror_dead"
	mob_biotypes = MOB_ORGANIC
	maxHealth = 1500
	health = 1000
	melee_damage_lower = 35
	melee_damage_upper = 45
	attack_verb_continuous = "rends"
	attack_verb_simple = "rend"
	attack_sound = 'sound/effects/blobattack.ogg'
	move_to_delay = 5
	speed = 0
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	gold_core_spawnable = FALSE
	var/mob/living/carbon/human/stored_changeling
	var/transformed_time = 0
	var/devouring = FALSE

/mob/living/simple_animal/hostile/true_changeling/Initialize(mapload)
	. = ..()
	transformed_time = world.time
	emote("scream")
	AddElement(/datum/element/ventcrawling, given_tier = VENTCRAWLER_ALWAYS)
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
	var/datum/action/innate/true_changeling_revert/R = new
	R.Grant(src)
	var/datum/action/innate/true_changeling_devour/D = new
	D.Grant(src)
	to_chat(src, "<span class='notice'>We are unveiled. Few weapons remain — rely on brute force, vents, and Devour.</span>")

/mob/living/simple_animal/hostile/true_changeling/BiologicalLife(seconds, times_fired)
	. = ..()
	if(stat != DEAD)
		adjustBruteLoss(-TRUE_CHANGELING_HEAL_PER_TICK * seconds)

/mob/living/simple_animal/hostile/true_changeling/death(gibbed)
	. = ..()
	if(stored_changeling && mind && stored_changeling.stat != DEAD)
		addtimer(CALLBACK(src, PROC_REF(final_burst)), rand(3 SECONDS, 6 SECONDS))
	else
		addtimer(CALLBACK(src, PROC_REF(fake_revive)), 45 SECONDS)

/mob/living/simple_animal/hostile/true_changeling/proc/final_burst()
	if(QDELETED(src))
		return
	if(stored_changeling && mind)
		var/turf/T = get_turf(src)
		stored_changeling.forceMove(T)
		stored_changeling.Paralyze(10 SECONDS)
		stored_changeling.adjustBruteLoss(40)
		stored_changeling.status_flags &= ~GODMODE
		mind.transfer_to(stored_changeling)
		stored_changeling.visible_message("<span class='userdanger'>[stored_changeling] erupts from the collapsing heap!</span>")
		explosion(src, 0, 1, 3, 4)
		spawn_gibs()
		qdel(src)
	else
		spawn_gibs()
		qdel(src)

/mob/living/simple_animal/hostile/true_changeling/proc/fake_revive()
	if(QDELETED(src) || stat != DEAD)
		return
	visible_message("<span class='warning'>[src] twitches violently and rises!</span>")
	revive(TRUE, TRUE)
	emote("scream")

/datum/action/innate/true_changeling_revert
	name = "Re-form Shell"
	desc = "Compress ourselves back into our original human disguise."
	button_icon_state = "change_to_human"

/datum/action/innate/true_changeling_revert/Trigger()
	if(!IsAvailable())
		return FALSE
	return Activate()

/datum/action/innate/true_changeling_revert/Activate()
	var/mob/living/simple_animal/hostile/true_changeling/T = owner
	if(!istype(T) || !T.stored_changeling)
		return FALSE
	if(T.stored_changeling.stat == DEAD)
		to_chat(owner, "<span class='warning'>Our original shell is destroyed!</span>")
		return FALSE
	if(world.time < T.transformed_time + TRUE_CHANGELING_REFORM)
		to_chat(owner, "<span class='warning'>We cannot compact ourselves yet!</span>")
		return FALSE
	T.visible_message("<span class='warning'>[T] folds inward, shedding excess biomass!</span>")
	var/mob/living/carbon/human/H = T.stored_changeling
	H.forceMove(get_turf(T))
	H.status_flags &= ~GODMODE
	T.mind.transfer_to(H)
	H.Stun(20)
	qdel(T)
	return TRUE

/datum/action/innate/true_changeling_devour
	name = "Devour"
	desc = "Rip flesh from an adjacent human."
	button_icon_state = "devour"

/datum/action/innate/true_changeling_devour/Trigger()
	if(!IsAvailable())
		return FALSE
	return Activate()

/datum/action/innate/true_changeling_devour/Activate()
	var/mob/living/simple_animal/hostile/true_changeling/T = owner
	if(!istype(T) || T.devouring)
		return FALSE
	var/list/options = list()
	for(var/mob/living/carbon/human/H in orange(1, T))
		if(H == T.stored_changeling || IS_CHANGELING(H))
			continue
		options += H
	if(!length(options))
		to_chat(T, "<span class='warning'>No prey here.</span>")
		return FALSE
	var/mob/living/carbon/human/victim = length(options) == 1 ? options[1] : tgui_input_list(T, "Choose prey", "Devour", options)
	if(!victim)
		return FALSE
	if(victim.getBruteLoss() + victim.getFireLoss() >= 200)
		to_chat(T, "<span class='warning'>Nothing nutritious remains.</span>")
		return FALSE
	T.devouring = TRUE
	T.visible_message("<span class='danger'>[T] begins ripping into [victim]!</span>")
	if(!do_after(T, 5 SECONDS, victim))
		T.devouring = FALSE
		return FALSE
	T.devouring = FALSE
	victim.adjustBruteLoss(60)
	victim.spawn_gibs()
	var/dismembered = FALSE
	for(var/obj/item/bodypart/P in victim.bodyparts)
		if(dismembered)
			break
		if(P.body_zone == BODY_ZONE_CHEST || P.body_zone == BODY_ZONE_HEAD)
			continue
		if(prob(65))
			continue
		P.dismember()
		dismembered = TRUE
	T.adjustBruteLoss(victim.nutrition >= NUTRITION_LEVEL_FAT ? -120 : -60)
	playsound(victim, 'sound/effects/splat.ogg', 60, TRUE)
	return TRUE

#undef TRUE_CHANGELING_REFORM
#undef TRUE_CHANGELING_HEAL_PER_TICK
