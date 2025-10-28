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
	button_icon_state = "phase_shift"
	cost = 100

	var/in_phase = FALSE
	var/doing_phase = FALSE

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

/datum/action/shadekin/phase_shift/not_enough_energy_handler()
	owner.balloon_alert(owner, "недостаточно энергии!")

/datum/action/shadekin/phase_shift/use()
	if(!get_turf(owner))
		to_chat(owner, span_alertwarning("Вы не можете тут это сделать!"))
		return FALSE

	var/area/temp_area = get_area(owner)
	if(!check_rights_for(owner?.client, R_HOLDER) && temp_area.area_flags & BLOCK_PHASE_SHIFT)
		to_chat(owner, span_alertwarning("Что-то вам мешает преодолеть границу реальности!"))
		return FALSE

	if(HAS_TRAIT(owner, TRAIT_IN_PHASE_SHIFT)) //БЕСПЛАТНО!?!?!??!
		return phase_in()

	var/fucking_cost = get_cost()

	if(dark_energy < fucking_cost)
		not_enough_energy_handler()
		to_chat(owner, span_warning("Кажется вам что-то мешает совершить фазовый переход!"))
		return FALSE

	return phase_out()

/datum/action/shadekin/phase_shift/proc/spawn_phase_effect(phase_effect_type)
	var/obj/effect/temp_visual/shadekin/phase_in/temp = new phase_effect_type(owner.loc)
	var/mob/living/temp_owner = owner
	var/matrix/M = matrix()

	M.Scale(temp_owner.size_multiplier, temp_owner.size_multiplier)

	temp.pixel_y = (temp_owner.size_multiplier - 1) * 16 // Pixel shift for the animation placement
	temp.dir = temp_owner.dir
	temp.transform = M

/datum/action/shadekin/phase_shift/proc/phase_in()
	//owner.emote("phases in!")
	var/dchatmsg = "<span class='emote'><b>[owner]</b> phases in!</span>"
	owner.visible_message(dchatmsg, runechat_popup = TRUE, rune_msg = "phases in!")
	UnregisterSignal(owner, COMSIG_GUN_EXTERNAL_GUN_CHECK)

	REMOVE_TRAIT(owner, TRAIT_IN_PHASE_SHIFT, NONE)
	owner.movement_type &= ~PHASING
	owner.invisibility = initial(owner.invisibility)
	owner.see_invisible = initial(owner.see_invisible)
	owner.alpha = initial(owner.alpha)

	spawn_phase_effect(/obj/effect/temp_visual/shadekin/phase_in)

/datum/action/shadekin/phase_shift/proc/phase_out()
	//owner.emote("phases out!")
	var/dchatmsg = "<span class='emote'><b>[owner]</b> phases out!</span>"
	owner.visible_message(dchatmsg, runechat_popup = TRUE, rune_msg = "phases out!")

	RegisterSignal(owner, COMSIG_GUN_EXTERNAL_GUN_CHECK, PROC_REF(no_gun_allowed))

	ADD_TRAIT(owner, TRAIT_IN_PHASE_SHIFT, NONE)
	owner.movement_type |= PHASING
	owner.invisibility = INVISIBILITY_SHADEKIN
	owner.see_invisible = SEE_INVISIBILITY_SHADEKIN
	owner.alpha = 127

	spawn_phase_effect(/obj/effect/temp_visual/shadekin/phase_out)

	//if(SEND_SIGNAL(src, COMSIG_ATOM_ATTACK_HAND, user) & COMPONENT_NO_ATTACK_HAND)

/datum/action/shadekin/proc/no_hand_attack(datum/source, mob/user)

/datum/action/shadekin/phase_shift/proc/no_gun_allowed(datum/source)
	SIGNAL_HANDLER
	owner.balloon_alert(owner, "тут это нельзя!")
	return TRUE
