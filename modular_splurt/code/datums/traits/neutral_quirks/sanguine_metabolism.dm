// Lite version of Bloodflege
// Removes all special powers
/datum/quirk/bloodfledge_lite
	name = "Метаболизм Cангвина"
	desc = "Вы - немагический молодой кровосос, не обладающий никакими особыми способностями. Только кровь утолит ваш голод, а святая энергия заставит вашу плоть обуглиться."
	value = 0
	medical_record_text = "Пациент демонстрирует необычайно слабое сангвиническое проклятие."
	mob_trait = TRAIT_BLOODFLEDGE_LITE
	gain_text = span_notice("Вы ощущаете сангвиническую жажду.")
	lose_text = span_notice("Вы чувствуете, как угасает жажда крови.")

/datum/quirk/bloodfledge_lite/add()
	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = quirk_holder

	// Add quirk traits
	ADD_TRAIT(quirk_mob,TRAIT_NO_PROCESS_FOOD,ROUNDSTART_TRAIT)
	ADD_TRAIT(quirk_mob,TRAIT_NOTHIRST,ROUNDSTART_TRAIT)

	// Add full trait to preserve bite, holy weakness, and examine functionality
	ADD_TRAIT(quirk_mob,TRAIT_BLOODFLEDGE,ROUNDSTART_TRAIT)

	// Lite version does not set skin tone or grant the language

	// Register examine text
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(quirk_examine_bloodfledge_lite))

/datum/quirk/bloodfledge_lite/post_add()
	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = quirk_holder

	// Define and grant ability Bite
	var/datum/action/cooldown/bloodfledge/bite/act_bite = new
	act_bite.Grant(quirk_mob)

	// Lite version does not grant the revive ability

/datum/quirk/bloodfledge_lite/remove()
	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = quirk_holder

	// Remove quirk traits
	REMOVE_TRAIT(quirk_mob, TRAIT_NO_PROCESS_FOOD, ROUNDSTART_TRAIT)
	REMOVE_TRAIT(quirk_mob, TRAIT_NOTHIRST, ROUNDSTART_TRAIT)
	REMOVE_TRAIT(quirk_mob, TRAIT_BLOODFLEDGE, ROUNDSTART_TRAIT)

	// Remove quirk ability action datums
	var/datum/action/cooldown/bloodfledge/bite/act_bite = locate() in quirk_mob.actions
	act_bite.Remove(quirk_mob)

	// Unregister examine text
	UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)

/datum/quirk/bloodfledge_lite/proc/quirk_examine_bloodfledge_lite(atom/examine_target, mob/living/carbon/human/examiner, list/examine_list, anonymous = FALSE)
	SIGNAL_HANDLER

	// Check if human examiner exists
	if(!istype(examiner))
		return

	// Check if examiner is a non-Fledgling
	if(!isbloodfledge(examiner))
		// Return with no effects
		return

	// Check if examiner is dumb
	if(HAS_TRAIT(examiner, TRAIT_DUMB))
		// Return with no effects
		return

	// Define quirk mob
	var/mob/living/carbon/human/quirk_mob = quirk_holder

	// Define hunger texts
	var/examine_hunger

	// Check hunger levels
	switch(quirk_mob.nutrition)
		// Hungry
		if(NUTRITION_LEVEL_STARVING to NUTRITION_LEVEL_HUNGRY)
			examine_hunger = "[anonymous ? "He" : quirk_holder.p_they(TRUE)] [anonymous ? "is" : quirk_holder.p_are()] blood starved!"

		// Starving
		if(0 to NUTRITION_LEVEL_STARVING)
			examine_hunger = "[anonymous ? "He" : quirk_holder.p_they(TRUE)] [anonymous ? "is" : quirk_holder.p_are()] in dire need of blood!"

		// Invalid hunger
		else
			// Return with no message
			return

	// Add detection text
	examine_list += span_info("[anonymous ? "His" : quirk_holder.p_their(TRUE)] hunger allows you to identify [anonymous ? "him" : quirk_holder.p_them()] as a lesser Bloodsucker Fledgling!")

	// Add hunger text
	examine_list += span_warning(examine_hunger)
