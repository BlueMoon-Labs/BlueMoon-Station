
/**
 * # FrenzyGrab
 *
 * The martial art given to Bloodsuckers so they can instantly aggressively grab people.
 */
/datum/martial_art/frenzygrab
	name = "Frenzy Grab"
	id = MARTIALART_FRENZYGRAB

/datum/martial_art/frenzygrab/grab_act(mob/living/user, mob/living/target)
	if(user != target)
		target.grabbedby(user)
		target.grippedby(user, instant = TRUE)
		return TRUE
	return ..()

/**
 * # Status effect
 *
 * This is the status effect given to Bloodsuckers in a Frenzy
 * This deals with everything entering/exiting Frenzy is meant to deal with.
 */

/atom/movable/screen/alert/status_effect/frenzy
	name = "Frenzy"
	desc = "You are in a Frenzy! You are entirely Feral and, depending on your Clan, fighting for your life!"
	icon = 'modular_bluemoon/code/modules/antagonists/bloodsucker/bloodsucker_rework/icons/actions_bloodsucker.dmi'
	icon_state = "power_recover"
	alerttooltipstyle = "cult"

/datum/status_effect/frenzy
	id = "Frenzy"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	//tick() у френзи ЖИВОЙ (bloodsucker_frenzy.dm жжёт владельца каждую
	//секунду) - дефолтный tick_interval оставлен намеренно
	alert_type = /atom/movable/screen/alert/status_effect/frenzy
	///Boolean on whether they were an AdvancedToolUser, to give the trait back upon exiting.
	var/was_tooluser = FALSE
	/// The stored Bloodsucker antag datum
	var/datum/antagonist/bloodsucker/bloodsuckerdatum

/atom/movable/screen/alert/status_effect/masquerade/MouseEntered(location,control,params)
	desc = initial(desc)
	return ..()

/datum/status_effect/frenzy/on_apply()
	var/mob/living/carbon/human/user = owner
	bloodsuckerdatum = user.mind?.has_antag_datum(ANTAG_DATUM_BLOODSUCKER)

	examine_text = span_danger("SUBJECTPRONOUN выглядит лишенн[user.gender == MALE ? "ым" : "ой"] сознания и дик[user.gender == MALE ? "им" : "ой"]!")

	// Disable ALL Powers and notify their entry
	for(var/datum/action/cooldown/bloodsucker/power in bloodsuckerdatum.powers)
		if(power.active && !power.can_use_in_torpor)
			power.DeactivatePower()
	to_chat(owner, span_userdanger("<FONT size = 3>Blood! You need Blood, now! You enter a total Frenzy!"))
	to_chat(owner, span_announce("* Bloodsucker Tip: While in Frenzy, you instantly Aggresively grab, have stun resistance, cannot speak, hear, or use any powers outside of Feed and Trespass (If you have it)."))
	user.balloon_alert(owner, "you enter a frenzy!")
	SEND_SIGNAL(bloodsuckerdatum, BLOODSUCKER_ENTERS_FRENZY)

	// Give the other Frenzy effects
	ADD_TRAIT(user, TRAIT_MUTE, FRENZY_TRAIT)
	ADD_TRAIT(user, TRAIT_DEAF, FRENZY_TRAIT)

	if(HAS_TRAIT(owner, TRAIT_ADVANCEDTOOLUSER))
		was_tooluser = TRUE
		REMOVE_TRAIT(owner, TRAIT_ADVANCEDTOOLUSER, SPECIES_TRAIT)
	user.add_movespeed_modifier(/datum/movespeed_modifier/dna_vault_speedup)
	bloodsuckerdatum.frenzygrab.teach(user, TRUE)
	user.add_client_colour(/datum/client_colour/manual_heart_blood)
	var/obj/cuffs = user.get_item_by_slot(ITEM_SLOT_HANDCUFFED)
	var/obj/legcuffs = user.get_item_by_slot(ITEM_SLOT_LEGCUFFED)
	if(user.handcuffed || user.legcuffed)
		user.clear_cuffs(cuffs, TRUE)
		user.clear_cuffs(legcuffs, TRUE)
	bloodsuckerdatum.frenzied = TRUE
	user.physiology.stamina_mod *= 0.4
	return ..()

/datum/status_effect/frenzy/on_remove()
	var/mob/living/carbon/human/user = owner
	user.balloon_alert(owner, "you come back to your senses.")
	REMOVE_TRAIT(user, TRAIT_MUTE, FRENZY_TRAIT)
	REMOVE_TRAIT(user, TRAIT_DEAF, FRENZY_TRAIT)
	if(was_tooluser)
		ADD_TRAIT(owner, TRAIT_ADVANCEDTOOLUSER, SPECIES_TRAIT)
		was_tooluser = FALSE
	user.remove_movespeed_modifier(/datum/movespeed_modifier/dna_vault_speedup)
	bloodsuckerdatum.frenzygrab.remove(user)
	user.remove_client_colour(/datum/client_colour/manual_heart_blood)

	SEND_SIGNAL(bloodsuckerdatum, BLOODSUCKER_EXITS_FRENZY)
	bloodsuckerdatum.frenzied = FALSE
	user.dizziness += 30
	user.Paralyze(2 SECONDS)
	user.physiology.stamina_mod /= 0.4

	return ..()

/datum/client_colour/manual_heart_blood
	priority = 1 // Absolute
	colour = COLOR_RED
