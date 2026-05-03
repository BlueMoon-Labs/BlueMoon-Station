


// 		WITHOUT THIS POWER:
//
//	- Mid-Blood: SHOW AS PALE
//	- Low-Blood: SHOW AS DEAD
//	- No Heartbeat
//  - Examine shows actual blood
//	- Thermal homeostasis (ColdBlooded)



// 		WITH THIS POWER:
//	- Normal body temp -- remove Cold Blooded (return on deactivate)
//	-


/datum/action/cooldown/bloodsucker/masquerade
	name = "Masquerade"
	desc = "Имитировать жизненные особенности бытия смертных, чтобы скрыть, каким монстром на самом деле являешься."
	button_icon_state = "power_human"
	bloodcost = 20 // BLUEMOON EDIT - было 50
	cooldown_time = 200
	amToggle = TRUE
	bloodsucker_can_buy = TRUE
	warn_constant_cost = TRUE
	can_use_in_torpor = TRUE // Masquerade is maybe the only one that can do this. It stops your healing.
	cooldown_static = TRUE
	must_be_concious = FALSE

// NOTE: Firing off vulgar powers disables your Masquerade!

/*/datum/action/cooldown/bloodsucker/masquerade/CheckCanUse(display_error)
	if(!..(display_error))// DEFAULT CHECKS
		return FALSE
	// DONE!
	return TRUE
*/


/datum/action/cooldown/bloodsucker/masquerade/ActivatePower()

	var/mob/living/user = owner
	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)

	to_chat(user, "<span class='notice'>Твое сердце фальшиво бьется в твоей безжизненной груди. Ты все еще можешь сойти за смертного.</span>")
	to_chat(user, "<span class='warning'>Ваше вампирское исцеление приостанавливается при имитации жизни.</span>")


	// Remove ColdBlooded & Hard/SoftCrit
	REMOVE_TRAIT(user, TRAIT_COLDBLOODED, "bloodsucker")
	REMOVE_TRAIT(user, TRAIT_NOHARDCRIT, "bloodsucker")
	REMOVE_TRAIT(user, TRAIT_NOSOFTCRIT, "bloodsucker")
	REMOVE_TRAIT(user, TRAIT_VIRUSIMMUNE, "bloodsucker")
	if(!HAS_TRAIT(user, TRAIT_DEATHCOMA)) // BLUEMOON ADD если вампир в торпоре, то он не начнет задыхаться, пока маскируется под живого
		REMOVE_TRAIT(user, TRAIT_NOBREATH, "bloodsucker")
	var/obj/item/organ/heart/vampheart/H = user.getorganslot(ORGAN_SLOT_HEART)
	var/obj/item/organ/eyes/vassal/bloodsucker/E = user.getorganslot(ORGAN_SLOT_EYES)
	E.flash_protect = 0

	// WE ARE ALIVE! //
	bloodsuckerdatum.poweron_masquerade = TRUE
	while(bloodsuckerdatum && ContinueActive(user))

		// HEART
		if(istype(H))
			H.FakeStart()

		// 		PASSIVE (done from LIFE)
		// Don't Show Pale/Dead on low blood
		// Don't vomit food
		// Don't Heal

		// Pay Blood Toll (if awake)
		if(user.stat == CONSCIOUS)
			bloodsuckerdatum.AddBloodVolume(-0.2)

		sleep(20) // Check every few ticks that we haven't disabled this power


/datum/action/cooldown/bloodsucker/masquerade/ContinueActive(mob/living/user)
	// Disable if unable to use power anymore.
	//if (user.stat == DEAD || user.blood_volume <= 0) // not conscious or soft critor uncon, just dead
	//	return FALSE
	return ..() // Active, and still Antag


/datum/action/cooldown/bloodsucker/masquerade/DeactivatePower(mob/living/user = owner, mob/living/target)
	..() // activate = FALSE

	var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)
	bloodsuckerdatum.poweron_masquerade = FALSE

	ADD_TRAIT(user, TRAIT_COLDBLOODED, "bloodsucker")
	ADD_TRAIT(user, TRAIT_NOHARDCRIT, "bloodsucker")
	ADD_TRAIT(user, TRAIT_NOSOFTCRIT, "bloodsucker")
	ADD_TRAIT(user, TRAIT_VIRUSIMMUNE, "bloodsucker")
	ADD_TRAIT(user, TRAIT_NOBREATH, "bloodsucker")

	// HEART
	var/obj/item/organ/heart/H = user.getorganslot(ORGAN_SLOT_HEART)
	var/obj/item/organ/eyes/vassal/bloodsucker/E = user.getorganslot(ORGAN_SLOT_EYES)
	H.Stop()

	E.flash_protect = 2

	to_chat(user, "<span class='notice'>Твое сердце бьется в последний раз, в то время как твоя кожа высыхает и к тебе возвращается ледяная бледность.</span>")
