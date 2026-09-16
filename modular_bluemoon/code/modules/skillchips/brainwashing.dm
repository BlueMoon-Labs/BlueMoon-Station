/obj/machinery/washing_machine/on_attack_hand(mob/living/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(user.pulling && user.a_intent == INTENT_GRAB && isliving(user.pulling) && !has_buckled_mobs())
		var/mob/living/L = user.pulling
		if(L.buckled || L.has_buckled_mobs())
			return
		if(state_open)
			if(iscorgi(L))
				has_corgi = 1
				L.forceMove(src)
				update_icon()
		return
	if(state_open)
		if(has_buckled_mobs())
			if(user != buckled_mobs[1])
				user_unbuckle_mob(buckled_mobs[1], user)
		else if(ishuman(user) && TryStuck(user, 10, 5))
			user.visible_message(span_danger("[user] is stuck inside \the [src]!"), span_danger("You were trying to get items from [src], but ended up being stuck in it somehow..."))
		else if(!contents.len)
			to_chat(user, "<span class='notice'>[src] is empty.</span>")
		else
			dropContents()
			color_source = null
			has_corgi = 0
			update_icon()
	else
		if(!user.canUseTopic(src))
			return
		if(bloody_mess)
			to_chat(user, "<span class='warning'>[src] must be cleaned up first.</span>")
			return
		if(HAS_TRAIT(user, TRAIT_BRAINWASHING))
			ADD_TRAIT(src, TRAIT_BRAINWASHING, SKILLCHIP_TRAIT)
		busy = TRUE
		update_icon()
		addtimer(CALLBACK(src, PROC_REF(wash_cycle)), 200)
		START_PROCESSING(SSfastprocess, src)

/obj/machinery/washing_machine/wash_cycle()
	for(var/X in contents)
		var/atom/movable/AM = X
		SEND_SIGNAL(AM, COMSIG_COMPONENT_CLEAN_ACT, CLEAN_WEAK)
		AM.clean_blood()
		AM.machine_wash(src)

	REMOVE_TRAIT(src, TRAIT_BRAINWASHING, SKILLCHIP_TRAIT)
	busy = FALSE
	if(color_source)
		qdel(color_source)
		color_source = null
	update_icon()

/obj/item/organ/brain/machine_wash(obj/machinery/washing_machine/brainwasher)
	. = ..()
	if(HAS_TRAIT(brainwasher, TRAIT_BRAINWASHING))
		setOrganDamage(0)
		cure_all_traumas(TRAUMA_RESILIENCE_LOBOTOMY)
	else
		setOrganDamage(BRAIN_DAMAGE_DEATH)