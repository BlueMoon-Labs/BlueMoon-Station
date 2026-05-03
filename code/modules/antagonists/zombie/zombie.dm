/datum/antagonist/zombie
	name = "Zombie"
	antagpanel_category = "Zombie"
	antag_hud_name = "zombie"
	antag_hud_type = ANTAG_HUD_ZOMBIE
	show_to_ghosts = TRUE
	var/converts_living = FALSE
	var/obj/item/organ/zombie_infection/zombie_organ
	var/zombie_organ_type = /obj/item/organ/zombie_infection
	var/const/intro_text = "Теперь вы зомби!\n\
		Не стремитесь вылечиться, никоим образом не помогайте людям, не являющимся зомби, не причиняйте вреда своим собратьям-зомби и распространяйте болезнь, убивая других.\n\
		Вы - порождение голода и насилия!"

/datum/antagonist/zombie/greet()
	. = ..()
	var/msg = span_userdanger("ВЫ ГОЛОДНЫ!")
	msg += span_redtext("\n"+intro_text)
	to_chat(owner, examine_block(msg))

/datum/antagonist/zombie/farewell()
	. = ..()
	to_chat(owner, span_greenannounce("Вы излечились от вируса зомби!"))

/datum/antagonist/zombie/admin_add(datum/mind/new_owner, mob/admin)
	converts_living = TRUE
	return ..()

/datum/antagonist/zombie/apply_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/C = mob_override || owner.current
	add_antag_hud(antag_hud_type, antag_hud_name, C)
	if(!istype(C))
		return
	var/obj/item/organ/zombie_infection/ZI = C.getorganslot(ORGAN_SLOT_ZOMBIE)
	if(!ZI)
		ZI = new zombie_organ_type
		if(converts_living)
			ZI.converts_living = TRUE
		ZI.Insert(C)
		ZI.zombify()
	zombie_organ = ZI

/datum/antagonist/zombie/admin_remove(mob/user)
	if(!user)
		return
	if(zombie_organ)
		zombie_organ.Remove()
		QDEL_NULL(zombie_organ)
	return ..()

/datum/antagonist/zombie/remove_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/C = mob_override || owner.current
	remove_antag_hud(antag_hud_type, C)
