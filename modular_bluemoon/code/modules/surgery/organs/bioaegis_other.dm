//BIOAEGIS MODULES
//OTHER

/obj/item/organ/darkveil
	name = "Darkveil ossmodula"
	desc = "A special gland which was made out of artificial bacteria via nanites. In this case, they are programmed to harden skin and prevent harm from light, and can be removed afterwards."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "darkveil"
	slot = ORGAN_SLOT_THRUSTERS
	w_class = WEIGHT_CLASS_NORMAL
	zone = BODY_ZONE_CHEST

/obj/item/organ/darkveil/Insert(mob/living/carbon/M, drop_if_replaced = TRUE)
	..()
	if(M.has_quirk(/datum/quirk/less_nightmare))
		M.remove_quirk(/datum/quirk/less_nightmare, STATUS_EFFECT_TRAIT)
	if(M.has_quirk(/datum/quirk/lightless))
		M.remove_quirk(/datum/quirk/lightless, STATUS_EFFECT_TRAIT)
		to_chat(owner, "<span class = 'notice'>Вы ощущаете как ваш покров становится крепче. Кажется, свет вам более не страшен..</span>\n")
		SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "out of shadows", /datum/mood_event/shadowless)
	else
		to_chat(owner, "<span class = 'notice'>А...в чём был смысл?...</span>\n")

/datum/mood_event/shadowless
	description = "<span class='nicegreen'>Свет стал таким приятным...</span>\n"
	mood_change = 4 //You just removed a heavy burden from yourself, at least for a time being.
	timeout = 1 MINUTES //You are happy, but not for long. You are still mortal.

/obj/item/organ/optisia
	name = "Optisia ossmodula"
	desc = "A special gland which was made out of artificial bacteria via nanites. In this case, they are programmed to rewire some parts of neural system and can be removed afterwards."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "optisia"
	slot = ORGAN_SLOT_THRUSTERS
	w_class = WEIGHT_CLASS_NORMAL
	zone = BODY_ZONE_CHEST

/obj/item/organ/optisia/Insert(mob/living/carbon/M, drop_if_replaced = TRUE)
	..()
	M.remove_quirk(/datum/quirk/mute, STATUS_EFFECT_TRAIT)
	M.remove_quirk(/datum/quirk/unstable, STATUS_EFFECT_TRAIT)
	M.remove_quirk(/datum/quirk/no_smell, STATUS_EFFECT_TRAIT)
	M.remove_quirk(/datum/quirk/social_anxiety, STATUS_EFFECT_TRAIT)
	M.remove_quirk(/datum/quirk/prosopagnosia, STATUS_EFFECT_TRAIT)
	M.remove_quirk(/datum/quirk/nyctophobia, STATUS_EFFECT_TRAIT)
	M.remove_quirk(/datum/quirk/monophobia, STATUS_EFFECT_TRAIT)
	M.remove_quirk(/datum/quirk/depression, STATUS_EFFECT_TRAIT)
	M.remove_quirk(/datum/quirk/brainproblems, STATUS_EFFECT_TRAIT)
	M.remove_quirk(/datum/quirk/insanity, STATUS_EFFECT_TRAIT) //Cockroaches in the head were silenced
	to_chat(owner, "<span class='synth'>Странное ощущение спокойствия......</span>\n")
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "serenity of mind", /datum/mood_event/serenityofmind)

/datum/mood_event/serenityofmind
	description = "<span class='synth'>Секунда стала вечностью, и мой разум нашёл своё место в этом мире.</span>\n"
	mood_change = 3 //You managed to make yourself less of a whimp and more of a decent person, good job.

/obj/item/organ/eyes/night_vision/aegis
	name = "Adaptive eyes"
	desc = "Not-so-spooky set of eyes that can see in the dark."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "adaptiveeyes"
	see_in_dark = 8
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	actions_types = list(/datum/action/item_action/organ_action/use)

/obj/item/organ/eyes/night_vision/aegis/ui_action_click()
	sight_flags = initial(sight_flags)
	switch(lighting_alpha)
		if (LIGHTING_PLANE_ALPHA_VISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
		if (LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
		if (LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_INVISIBLE
		else
			lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
			sight_flags &= ~SEE_BLACKNESS
	owner.update_sight()

/obj/item/organ/eyes/thermalaegis
	name = "Thermographic eyes"
	desc = "These modified eyes are...intersting, since they provide thermal oversight while not succumbing to flashy lights. These also help with..'lights'..."
	icon = 'modular_bluemoon/icons/obj/surgery.dmi'
	icon_state = "thermalaegis"
	see_in_dark = 8
	sight_flags = SEE_MOBS
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	flash_protect = 2
	actions_types = list(/datum/action/item_action/organ_action/use)
	var/night_vision = TRUE

/obj/item/organ/eyes/thermalaegis/ui_action_click()
	sight_flags = initial(sight_flags)
	switch(lighting_alpha)
		if (LIGHTING_PLANE_ALPHA_VISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
		if (LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
		if (LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE)
			lighting_alpha = LIGHTING_PLANE_ALPHA_INVISIBLE
		else
			lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
			sight_flags &= ~SEE_BLACKNESS
	owner.update_sight()

/obj/item/organ/vocal_cords/babyloncords
	name = "Babylon's Vocal Cords"
	desc = "They carry the voice of everyone who has ever lived."
	icon_state = "babylon_cords"
	decay_factor = 0

/obj/item/organ/vocal_cords/babyloncords/Insert(mob/living/carbon/M, drop_if_replaced = TRUE)
	to_chat(owner, "<span class='synth'>Ваши уста вещают тысячи голосов......</span>\n")
	M.grant_all_languages(source = LANGUAGE_CURATOR)
	M.remove_blocked_language(GLOB.all_languages, source=LANGUAGE_ALL)
