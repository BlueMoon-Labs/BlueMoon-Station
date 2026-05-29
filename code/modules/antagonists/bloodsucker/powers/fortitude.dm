



/datum/action/cooldown/bloodsucker/fortitude
	name = "Fortitude"
	desc = "Позволяет выдерживать тяжелейшие физические повреждения и оставаться на ногах после атак, которые оглушили бы, пронзили или разорвали на части более слабых существ. Пока активно, вы не можете бежать."
	button_icon_state = "power_fortitude"
	bloodcost = 60
	cooldown_time = 200
	bloodsucker_can_buy = TRUE
	amToggle = TRUE
	warn_constant_cost = TRUE
	var/was_running

	var/fortitude_resist // So we can raise and lower your brute resist based on what your level_current WAS.

/datum/action/cooldown/bloodsucker/fortitude/ActivatePower()
	var/datum/antagonist/bloodsucker/B = owner.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
	var/mob/living/user = owner
//	to_chat(user, "<span class='notice'>Your flesh, skin, and muscles become as steel.</span>") // BLUEMOON REMOVAL - передвинуто ниже
	// Traits & Effects
	ADD_TRAIT(user, TRAIT_PIERCEIMMUNE, "fortitude")
	ADD_TRAIT(user, TRAIT_NODISMEMBER, "fortitude")
	ADD_TRAIT(user, TRAIT_STUNIMMUNE, "fortitude")
	ADD_TRAIT(user, TRAIT_NORUNNING, "fortitude")
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		fortitude_resist = max(0.3, 0.7 - level_current * 0.1)
		H.physiology.brute_mod *= fortitude_resist
		H.physiology.burn_mod *= fortitude_resist
		to_chat(user, "<span class='notice'>Ваша плоть, кожа и мускулы становятся как сталь. У вас есть [(1 - fortitude_resist) * 100]% защиты к ушибам и ожогам.</span>") // BLUEMOON ADD
	was_running = (user.m_intent == MOVE_INTENT_RUN)
	if(was_running)
		user.toggle_move_intent()
	while(B && ContinueActive(user) || user.m_intent == MOVE_INTENT_RUN)
		if(istype(user.buckled, /obj/vehicle)) //We dont want people using fortitude being able to use vehicles
			var/obj/vehicle/V = user.buckled
			var/datum/component/riding/VRD = V.GetComponent(/datum/component/riding)
			if(VRD)
				VRD.force_dismount(user)
				to_chat(user, "<span class='notice'>Вы слетаете с [V], ваши мышцы слишком тяжёлые, чтобы он мог вас выдержать.</span>")
			else
				V.unbuckle_mob(user, force = TRUE)
				to_chat(user, "<span class='notice'>Вы падаете с [V], ваш вес слишком велик, чтобы он мог вас выдержать.</span>")
		// Pay Blood Toll (if awake)
		if(user.stat == CONSCIOUS)
			B.AddBloodVolume(-0.5)
		sleep(20) // Check every few ticks that we haven't disabled this power
	// Return to Running (if you were before)

/datum/action/cooldown/bloodsucker/fortitude/DeactivatePower(mob/living/user = owner, mob/living/target)
	..()
	// Restore Traits & Effects
	REMOVE_TRAIT(user, TRAIT_PIERCEIMMUNE, "fortitude")
	REMOVE_TRAIT(user, TRAIT_NODISMEMBER, "fortitude")
	REMOVE_TRAIT(user, TRAIT_STUNIMMUNE, "fortitude")
	REMOVE_TRAIT(user, TRAIT_NORUNNING, "fortitude")
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.physiology.brute_mod /= fortitude_resist
	H.physiology.burn_mod /= fortitude_resist
	if(was_running && user.m_intent == MOVE_INTENT_WALK)
		user.toggle_move_intent()

