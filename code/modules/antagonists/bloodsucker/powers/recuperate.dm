/datum/action/cooldown/bloodsucker/vassal/recuperate
	name = "Sanguine Recuperation"
	desc = "Медленно залечивайте физический урон, пока способность активирована. Этот процесс утомителен и требует немного крови вашего хозяина."
	button_icon_state = "power_recup"
	amToggle = TRUE
	bloodcost = 15
	cooldown_time = 200

/datum/action/cooldown/bloodsucker/vassal/recuperate/CheckCanUse(display_error)
	. = ..()
	if(!.)
		return
	if (owner.stat >= DEAD)
		return FALSE
	return TRUE

/datum/action/cooldown/bloodsucker/vassal/recuperate/ActivatePower()
	to_chat(owner, "<span class='notice'>Твои мышцы сжимаются, а по коже бегут мурашки, когда бессмертная кровь твоего хозяина затягивает твои раны и придает тебе выносливости.</span>")
	var/mob/living/carbon/C = owner
	var/mob/living/carbon/human/H
	if(ishuman(owner))
		H = owner
	while(ContinueActive(owner))
		C.adjustBruteLoss(-1.5)
		C.adjustFireLoss(-0.5)
		C.adjustToxLoss(-2, forced = TRUE)
		C.blood_volume -= 0.2
		C.adjustStaminaLoss(-15)
		// Stop Bleeding
		if(istype(H) && H.is_bleeding() && rand(20) == 0)
			for(var/obj/item/bodypart/part in H.bodyparts)
				part.generic_bleedstacks --
		C.Jitter(5)
		sleep(10)
	// DONE!
	//DeactivatePower(owner)

/datum/action/cooldown/bloodsucker/vassal/recuperate/ContinueActive(mob/living/user, mob/living/target)
	return ..() && user.stat <= DEAD && user.blood_volume > 500
