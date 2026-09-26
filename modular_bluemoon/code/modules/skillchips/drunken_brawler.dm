/mob/living/carbon/human/UnarmedAttack(atom/A, proximity, intent = a_intent, attackchain_flags = NONE)

	if(!has_active_hand()) //can't attack without a hand.
		to_chat(src, "<span class='notice'>You look at your arm and sigh.</span>")
		return

	var/obj/item/bodypart/check_arm = get_active_hand()
	if(check_arm && check_arm.is_disabled() == BODYPART_DISABLED_WOUND)
		to_chat(src, "<span class='warning'>The damage in your [check_arm.name] is preventing you from using it! Get it fixed, or at least splinted!</span>")
		if(has_pain(check_arm))
			emote("agony")
		return

	. = attackchain_flags
	// Special glove functions:
	// If the gloves do anything, have them return TRUE to stop
	// normal attack_hand() here.
	var/obj/item/clothing/gloves/G = gloves // not typecast specifically enough in defines
	if(proximity && istype(G))
		. |= G.Touch(A, TRUE)
		if(. & INTERRUPT_UNARMED_ATTACK)
			return

	for(var/datum/mutation/human/HM in dna.mutations)
		. |= HM.on_attack_hand(A, proximity, intent, .)

	if(. & INTERRUPT_UNARMED_ATTACK)
		return

	SEND_SIGNAL(src, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, A)
	. |= A.attack_hand(src, intent, .)

	if(intent == INTENT_HARM && drunkenness > 0 && HAS_TRAIT(src, TRAIT_DRUNKEN_BRAWLER) && isliving(A))
		var/mob/living/target = A
		var/hurt = getBruteLoss() + getFireLoss()
		var/bonus = clamp(hurt / 5, 3, 15)
		var/obj/item/bodypart/affecting
		if(ishuman(target))
			affecting = target.get_bodypart(ran_zone(zone_selected))
		target.apply_damage(bonus, BRUTE, affecting)
		to_chat(src, span_userdanger("Пьяная ярость придаёт вашему удару невероятную силу!"))

/mob/living/do_resist_grab(moving_resist, forced, silent = FALSE)
	. = FALSE
	var/escchance
	if(HAS_TRAIT(src, TRAIT_GARROTED))
		escchance = 3
	else if(istype(mind, /datum/mind) && istype(mind.martial_art, /datum/martial_art) && mind.martial_art.can_use(src))
		escchance = mind.martial_art.resist_grab_chance
	else // Обычно БИ будет всегда и "базовому" уже выставлено 30, фейлчек для ТЕОРЕТИЧЕСКИХ случаев отсутствия
		escchance = 30
	if(ishuman(pulledby))
		var/mob/living/carbon/human/grabber = pulledby
		if(HAS_TRAIT(grabber, TRAIT_DRUNKEN_BRAWLER) && grabber.drunkenness)
			escchance = round(escchance * 0.6)
	if(pulledby.grab_state > GRAB_PASSIVE)
		if(CHECK_MOBILITY(src, MOBILITY_RESIST) && prob(escchance/pulledby.grab_state))
			pulledby.visible_message(span_danger("[src] вырывается из захвата [pulledby]!"),
				span_danger("[src] вырывается из вашего захвата!"), target = src,
				target_message = span_danger("Вы вырываетесь из захвата [pulledby]!"))
			pulledby.stop_pulling()
			return TRUE
		else if(moving_resist && client) //we resisted by trying to move
			client.move_delay = world.time + 20
		pulledby.visible_message(span_danger("[src] не может вырваться из захвата [pulledby]!"),
			span_danger("[src] не может вырваться из вашего захвата!"), target = src,
			target_message = span_danger("Вы не можете вырваться из захвата [pulledby]!"))
	else
		pulledby.stop_pulling()
		return TRUE
