/////////////////////
///  PHASE SHIFT  ///
/////////////////////

/obj/effect/temp_visual/shadekin
	randomdir = FALSE
	duration = 0.5 SECONDS
	icon = 'icons/effects/shadekin.dmi'

/obj/effect/temp_visual/shadekin/phase_in
	icon_state = "tp_in"

/obj/effect/temp_visual/shadekin/phase_out
	icon_state = "tp_out"

/datum/action/shadekin/phase_shift
	name = "Фазовый переход (100)"
	desc = "Переход в темное пространство для перемещения"
	cost = 100

	button_icon_state = "phase_shift"
	var/in_phase = FALSE

//Ненужное дублирование кода, но типо уэээ
/datum/action/shadekin/phase_shift/proc/get_dark_level()
	var/turf/T = get_turf(owner)
	var/darkness = 1
	if(!T)
		return 0

	var/brightness = T.get_lumcount()
	darkness = 1-brightness
	if(darkness >= 0.5)
		return darkness
	return 0

/datum/action/shadekin/phase_shift/proc/get_cost()
	var/ability_cost = cost
	var/darkness = get_dark_level()

	var/watcher = 0
	for(var/mob/living/thing in orange(7, owner)) //Fun fact, doing two typed loops is faster than doing one untyped loop. Check it with Tracy!
		if(istype(thing, /mob/living/carbon/human))
			var/mob/living/carbon/human/watchers = thing
			if(watchers in oviewers(7,owner))
				var/datum/component/shadekin/watcher_SK = watchers.GetComponent(/datum/component/shadekin)
				if(!watcher_SK && !(watchers.stat) && !isbelly(watchers.loc) && !istype(watchers.loc, /obj/item/storage))	// And they are alive and not being held by someone...
					watcher++	//They are watching us!
		if(istype(thing, /mob/living/silicon/robot))
			var/mob/living/silicon/robot/watchers = thing
			var/datum/component/shadekin/watcher_SK = watchers.GetComponent(/datum/component/shadekin)
			if(watchers in oviewers(7,owner))
				if(!watcher_SK && !watchers.stat && !isbelly(watchers.loc))
					watcher++	//The robot is watching us!
	/* Думоть буду
	if(SK.camera_counts_as_watcher)
		for(var/obj/machinery/camera/watchers in orange(7, sownerrc))
			if(watchers.can_use())
				if(owner in watchers.can_see())
					watcher++	//The camera is watching us!
	*/
	ability_cost = clamp(ability_cost/(0.01+darkness*2),50, 80)//This allows for 1 watcher in full light

	ability_cost += 15 * watcher

	return ability_cost

/datum/action/shadekin/phase_shift/use()
	if(HAS_TRAIT(owner, TRAIT_IN_PHASE_SHIFT))
		return phase_in()
	return phase_out()

/datum/action/shadekin/phase_shift/proc/phase_in()
	ADD_TRAIT(owner, TRAIT_IN_PHASE_SHIFT, NONE)
	owner.movement_type &= ~PHASING
	owner.invisibility = initial(owner.invisibility)
	owner.see_invisible = initial(owner.see_invisible)
	owner.alpha = initial(owner.alpha)

	var/obj/effect/temp_visual/shadekin/phase_in/temp = new(owner.loc)

/datum/action/shadekin/phase_shift/proc/phase_out()
	REMOVE_TRAIT(owner, TRAIT_IN_PHASE_SHIFT, NONE)
	owner.movement_type |= PHASING
	owner.invisibility = INVISIBILITY_SHADEKIN
	owner.see_invisible = SEE_INVISIBILITY_SHADEKIN
	owner.alpha = 127

	var/obj/effect/temp_visual/shadekin/phase_out/temp = new(owner.loc)
