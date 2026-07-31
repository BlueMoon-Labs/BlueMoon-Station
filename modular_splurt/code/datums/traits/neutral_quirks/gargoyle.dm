/datum/quirk/gargoyle //Mmmm yes stone time
	name = "Горгулья"
	desc = "Вы относитесь к какому-то виду горгульи! Вы можете выходить из каменной формы на определенное время, но вам придётся в неё вернуться, чтобы восстановить энергию. С другой стороны, вы лечитесь, будучи в камне!"
	value = 0
	processing_quirk = TRUE
	var/energy = 0
	var/transformed = 0
	var/cooldown = 0
	var/paused = 0
	var/turf/position
	var/obj/structure/statue/gargoyle/current = null

/datum/quirk/gargoyle/add()
	.=..()
	var/mob/living/carbon/human/H = quirk_holder
	if (!H)
		return
	var/datum/action/gargoyle/transform/T = new
	var/datum/action/gargoyle/check/C = new
	var/datum/action/gargoyle/pause/P = new
	energy = 100
	cooldown = 30
	T.Grant(H)
	C.Grant(H)
	P.Grant(H)

/datum/quirk/gargoyle/on_process()
	.=..()
	var/mob/living/carbon/human/H = quirk_holder

	if (!H)
		return

	if(paused && H.loc != position)
		paused = 0
		energy -= 20

	if(cooldown > 0)
		cooldown--

	if(!transformed && !paused && energy > 0)
		energy -= 0.05

	if(transformed)
		energy = min(energy + 0.3, 100)
		if (H.getBruteLoss() > 0 || H.getFireLoss() > 0)
			H.adjustBruteLoss(-0.5, forced = TRUE)
			H.adjustFireLoss(-0.5, forced = TRUE)
		else if (H.getOxyLoss() > 0 || H.getToxLoss() > 0)
			H.adjustToxLoss(-0.3, forced = TRUE)
			H.adjustOxyLoss(-0.5, forced = TRUE) //oxyloss heals by itself, doesn't need a nerfed heal
		else if (H.getCloneLoss() > 0)
			H.adjustCloneLoss(-0.3, forced = TRUE)
		else if (current && current.obj_integrity < current.max_integrity) //health == maxHealth is true since we checked all damages above
			current.obj_integrity = min(current.obj_integrity + 0.1, current.max_integrity)

	if(!transformed && energy <= 0)
		var/datum/action/gargoyle/transform/T = locate() in H.actions
		if (!T)
			T = new
			T.Grant(H)
		cooldown = 0
		T?.Trigger()

/datum/quirk/gargoyle/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if (!H)
		return ..()
	var/datum/action/gargoyle/transform/T = locate() in H.actions
	var/datum/action/gargoyle/check/C = locate() in H.actions
	var/datum/action/gargoyle/pause/P = locate() in H.actions
	T?.Remove(H)
	C?.Remove(H)
	P?.Remove(H)
	. = ..()

//
// Quirk: Gargoyle
//

/datum/action/gargoyle/transform
	name = "Transform"
	desc = "Transform into a statue, regaining energy in the process. Additionally, you will slowly heal while in statue form."
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "ling_camouflage"
	required_mobility_flags = NONE
	var/obj/structure/statue/gargoyle/current = null


/datum/action/gargoyle/transform/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/H = owner
	var/datum/quirk/gargoyle/T = locate() in H.roundstart_quirks
	if(!T)
		return FALSE
	if(!T.cooldown)
		if(!T.transformed)
			if(!isturf(H.loc))
				return 0
			var/obj/structure/statue/gargoyle/S = new(H.loc, H)
			S.name = "statue of [H.name]"
			H.bleedsuppress = 1
			S.copy_overlays(H)
			var/newcolor = list(rgb(77,77,77), rgb(150,150,150), rgb(28,28,28), rgb(0,0,0))
			S.add_atom_colour(newcolor, FIXED_COLOUR_PRIORITY)
			current = S
			T.current = S
			T.transformed = 1
			T.cooldown = 30
			T.paused = 0
			S.dir = H.dir
			return 1
		else
			if(current)
				qdel(current)
			T.transformed = 0
			T.current = null
			current = null
			T.cooldown = 30
			T.paused = 0
			H.visible_message(span_warning("[H]'s skin rapidly softens, returning them to normal!"), span_userdanger("Your skin softens, freeing your movement once more!"))
	else
		to_chat(H, span_warning("You have transformed too recently; you cannot yet transform again!"))
		return 0

/datum/action/gargoyle/check
	name = "Check"
	desc = "Check your current energy levels."
	icon_icon = 'icons/mob/actions/actions_clockcult.dmi'
	button_icon_state = "Linked Vanguard"

/datum/action/gargoyle/check/Trigger()
	.=..()
	var/mob/living/carbon/human/H = owner
	var/datum/quirk/gargoyle/T = locate() in H.roundstart_quirks
	to_chat(H, span_warning("You have [T.energy]/100 energy remaining!"))

/datum/action/gargoyle/pause
	name = "Preserve"
	desc = "Become near-motionless, thusly conserving your energy until you move from your current tile. Note, you will lose a chunk of energy when you inevitably move from your current position, so you cannot abuse this!"
	icon_icon = 'icons/mob/actions/actions_flightsuit.dmi'
	button_icon_state = "flightsuit_lock"

/datum/action/gargoyle/pause/Trigger()
	.=..()
	var/mob/living/carbon/human/H = owner
	var/datum/quirk/gargoyle/T = locate() in H.roundstart_quirks

	if(!T.paused)
		T.paused = 1
		T.position = H.loc
		to_chat(H, span_warning("You are now conserving your energy; this effect will end the moment you move from your current position!"))
		return
	else
		to_chat(H, span_warning("You are already conserving your energy!"))
