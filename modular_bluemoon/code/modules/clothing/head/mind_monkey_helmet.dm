/obj/item/clothing/head/helmet/monkey_sentience
	name = "monkey mind magnification helmet"
	desc = "A fragile, circuitry-embedded helmet for boosting the intelligence of a monkey. Several warning labels are plastered on the side..."
	icon = 'modular_bluemoon/icons/obj/clothing/head/monkeymind.dmi'
	icon_state = "monkeymind"
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/head/monkeymind.dmi'
	strip_delay = 10 SECONDS
	var/mob/living/carbon/monkey/magnification
	var/polling = FALSE
	var/light_colors = 1
	var/rage_chance = -7

/obj/item/clothing/head/helmet/monkey_sentience/Initialize(mapload)
	. = ..()
	light_colors = rand(1, 3)
	update_icon()

/obj/item/clothing/head/helmet/monkey_sentience/update_icon()
	. = ..()
	icon_state = "[initial(icon_state)][light_colors][magnification ? "up" : ""]"

/obj/item/clothing/head/helmet/monkey_sentience/examine(mob/user)
	. = ..()
	. += span_boldwarning("---WARNING: REMOVAL OF HELMET ON SUBJECT, OR REPEATED SENTIENCE GENERATION FAILURES MAY LEAD TO:---")
	. += span_warning("BLOOD RAGE")
	. += span_warning("BRAIN DEATH")
	. += span_warning("PRIMAL GENE ACTIVATION")
	. += span_warning("GENETIC MAKEUP MASS SUSCEPTIBILITY")
	. += span_notice("Warranty voided if helmet is placed after more than ") + span_boldnotice("two") + span_notice(" mind magnification failures.")
	. += span_boldnotice("Ask your CMO if mind magnification is right for you!")

/obj/item/clothing/head/helmet/monkey_sentience/equipped(mob/user, slot)
	. = ..()
	if(!(slot & ITEM_SLOT_HEAD))
		return
	if(!ismonkey(user) || user.ckey)
		var/mob/living/something = user
		to_chat(something, span_boldnotice("You feel a stabbing pain in the back of your head for a moment."))
		something.apply_damage(5, BRUTE, BODY_ZONE_HEAD, FALSE, FALSE, FALSE)
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
		return
	var/mob/living/carbon/monkey/monkey_target = user
	set_magnification_target(monkey_target)
	visible_message(span_warning("[src] powers up!"))
	playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
	polling = TRUE
	var/list/candidates = pollCandidatesForMob("Do you want to play as a mind-magnified monkey?", ROLE_SENTIENCE, null, ROLE_SENTIENCE, 5 SECONDS, magnification, POLL_IGNORE_MONKEY_HELMET, priority_check = FALSE)
	polling = FALSE
	if(!magnification)
		return
	if(!LAZYLEN(candidates))
		clear_magnification_target()
		visible_message(span_notice("[src] falls silent and drops on the floor. Maybe you should try again later?"))
		handle_magnification_failure(monkey_target)
		return
	if((rage_chance > 0) && prob(rage_chance))
		malfunction(monkey_target)
		if(!QDELETED(monkey_target))
			monkey_target.dropItemToGround(src)
		clear_magnification_target()
		return
	var/mob/dead/observer/chosen = pick(candidates)
	magnification.transfer_ckey(chosen, FALSE)
	magnification.grant_all_languages(UNDERSTOOD_LANGUAGE, grant_omnitongue = FALSE, source = LANGUAGE_ATOM)
	playsound(src, 'sound/machines/microwave/microwave-end.ogg', 100, FALSE)
	to_chat(magnification, span_notice("You're a mind magnified monkey! Protect your helmet with your life — if you lose it, your sentience goes with it!"))
	update_icon()
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_head()

/obj/item/clothing/head/helmet/monkey_sentience/proc/handle_magnification_failure(mob/living/carbon/monkey/user)
	switch(rage_chance)
		if(-7 to 0)
			user.visible_message(span_notice("[src] falls silent and drops on the floor. Try again later?"))
			playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
		if(7 to 13)
			user.visible_message(span_notice("[src] sparkles momentarily, then falls silent and drops on the floor. Maybe you should try again later?"))
			playsound(src, SFX_SPARKS, 30, TRUE)
			do_sparks(2, FALSE, src)
		if(14 to 21)
			user.visible_message(span_notice("[src] sparkles and shatters ominously, then falls silent and drops on the floor. Maybe you shouldn't try again later."))
			do_sparks(4, FALSE, src)
			playsound(src, SFX_SPARKS, 15, TRUE)
			playsound(src, SFX_SHATTER, 30, TRUE)
		if(21 to INFINITY)
			user.visible_message(span_notice("[src] buzzes and smokes heavily, then falls silent and drops on the floor. This is clearly a bad idea."))
			do_sparks(6, FALSE, src)
			playsound(src, 'sound/machines/buzz-two.ogg', 30, TRUE)
	rage_chance += 7

/obj/item/clothing/head/helmet/monkey_sentience/Destroy()
	disconnect()
	return ..()

/obj/item/clothing/head/helmet/monkey_sentience/proc/set_magnification_target(mob/living/carbon/monkey/target)
	clear_magnification_target()
	magnification = target
	RegisterSignal(magnification, COMSIG_PARENT_QDELETING, PROC_REF(on_magnification_deleting))

/obj/item/clothing/head/helmet/monkey_sentience/proc/clear_magnification_target()
	if(magnification && !QDELETED(magnification))
		UnregisterSignal(magnification, COMSIG_PARENT_QDELETING)
	magnification = null

/obj/item/clothing/head/helmet/monkey_sentience/proc/on_magnification_deleting(datum/source)
	SIGNAL_HANDLER
	if(source != magnification)
		return
	magnification = null

/obj/item/clothing/head/helmet/monkey_sentience/proc/disconnect()
	if(!magnification)
		return
	if(QDELETED(magnification))
		magnification = null
		return
	var/mob/living/carbon/monkey/target = magnification
	clear_magnification_target()
	if(!polling && !QDELETED(target) && target.client)
		to_chat(target, span_userdanger("You feel your flicker of sentience ripped away from you, as everything becomes dim..."))
		target.ghostize(FALSE)
		if(prob(10) && !QDELETED(target))
			malfunction(target)
	playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
	playsound(src, SFX_SPARKS, 100, TRUE)
	visible_message(span_warning("[src] fizzles and breaks apart!"))
	new /obj/effect/decal/cleanable/ash(drop_location())

/obj/item/clothing/head/helmet/monkey_sentience/proc/malfunction(mob/living/carbon/target)
	switch(rand(1, 4))
		if(1)
			if(ismonkey(target))
				var/mob/living/carbon/monkey/M = target
				M.aggressive = TRUE
		if(2)
			target.apply_damage(500, BRAIN, BODY_ZONE_HEAD, FALSE, FALSE, FALSE)
		if(3)
			target.gorillize()
		if(4)
			target.gib()

/obj/item/clothing/head/helmet/monkey_sentience/dropped(mob/user)
	. = ..()
	if(magnification || polling)
		qdel(src)
