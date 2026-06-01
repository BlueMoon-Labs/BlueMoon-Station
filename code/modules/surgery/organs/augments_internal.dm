#define ANTI_STUN_SET_AMOUNT 40

/obj/item/organ/cyberimp
	name = "cybernetic implant"
	desc = "A state-of-the-art implant that improves a baseline's functionality."
	status = ORGAN_ROBOTIC
	organ_flags = ORGAN_SYNTHETIC
	var/implant_color = "#FFFFFF"
	var/implant_overlay
	///Makes the implant invisible to health analyzers and medical HUDs.
	var/syndicate_implant = FALSE

/obj/item/organ/cyberimp/New(var/mob/M = null)
	if(iscarbon(M))
		src.Insert(M)
	if(implant_overlay)
		var/mutable_appearance/overlay = mutable_appearance(icon, implant_overlay)
		overlay.color = implant_color
		add_overlay(overlay)
	return ..()

// В отличие от органов, имланты будут работать, только пока их можно активировать
/obj/item/organ/cyberimp/on_life(seconds, times_fired)
	return activate_allowed(silent = TRUE) && ..()

/*
/obj/item/organ/cyberimp/Insert(mob/living/carbon/organ_mob, special, drop_if_replaced)
	. = ..()
	if(!.)
		return
	for(var/datum/action/action in actions)
		RegisterSignal(action, COMSIG_ACTION_TRIGGER, PROC_REF(action_trigger))
		RegisterSignal(action, COMSIG_ACTION_ISAVAILABLE, PROC_REF(action_available))
		action.UpdateButtons(TRUE)
	if(!isnull(active_security_level))
		RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(on_sec_level_change))
		if(!activate_allowed(silent = TRUE))
			deactivate()

/obj/item/organ/cyberimp/Remove(special)
	. = ..()
	for(var/datum/action/action in actions)
		UnregisterSignal(action, list(COMSIG_ACTION_TRIGGER, COMSIG_ACTION_ISAVAILABLE))
	UnregisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED)

/obj/item/organ/cyberimp/examine(mob/user)
	. = ..()
	if(!isnull(active_security_level) || !isnull(initial(active_security_level)))
		. += span_notice("Минимальный уровень тревоги для активации: <b>[isnull(active_security_level) ? SECURITY_LEVEL_COLOR_TEXT(SEC_LEVEL_GREEN,"G&R@EE%N") : SECURITY_LEVEL_COLORED_UPPERTEXT(active_security_level)]</b>")

/obj/item/organ/cyberimp/proc/action_trigger(datum/action/source, obj/item/organ/cyberimp/target, mob/user)
	if(!activate_allowed(source, user))
		return COMPONENT_ACTION_BLOCK_TRIGGER

/obj/item/organ/cyberimp/proc/action_available(datum/action/source, obj/item/organ/cyberimp/target, mob/user, silent = TRUE)
	if(!activate_allowed(source, user, silent))
		return COMPONENT_ACTION_NOT_AVAILABLE

// action и user, могут быть null
/obj/item/organ/cyberimp/proc/activate_allowed(datum/action/action, mob/user, silent = FALSE)
	. = FALSE
	if(!isnull(active_security_level) && GLOB.security_level < active_security_level)
		if(!silent)
			to_chat(user, span_warning("<b>ОШИБКА:</b> Уровень тревоги для активации: <b>[SECURITY_LEVEL_COLORED_UPPERTEXT(active_security_level)]</b>"))
		return

	return TRUE

/obj/item/organ/cyberimp/on_life(seconds, times_fired)
	return activate_allowed(silent = TRUE) && ..()

/obj/item/organ/cyberimp/proc/on_sec_level_change(datum/source, new_level)
	SIGNAL_HANDLER
	for(var/datum/action/action in actions)
		action.UpdateButtons(TRUE)
	if(!activate_allowed(silent = TRUE))
		INVOKE_ASYNC(src, PROC_REF(deactivate))
	else if(auto_sec_level_toggle)
		INVOKE_ASYNC(src, PROC_REF(code_activate))

/obj/item/organ/cyberimp/proc/code_activate()
	return

/obj/item/organ/cyberimp/proc/deactivate(removing = FALSE)
	return

/obj/item/organ/cyberimp/emag_act()
	. = ..()
	if(active_security_level)
		active_security_level = null
		log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)] and clear sec level restrictions")
		playsound(get_turf(src), 'sound/effects/light_flicker.ogg', 100, 1)

/obj/item/organ/cyberimp/Remove(special)
	deactivate(TRUE)
	return ..()
*/

//[[[[BRAIN]]]]

/obj/item/organ/cyberimp/brain
	name = "cybernetic brain implant"
	desc = "Injectors of extra sub-routines for the brain."
	icon_state = "brain_implant"
	implant_overlay = "brain_implant_overlay"
	zone = BODY_ZONE_HEAD
	w_class = WEIGHT_CLASS_TINY

/obj/item/organ/cyberimp/brain/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	var/stun_amount = 2*severity
	owner.Stun(stun_amount)
	to_chat(owner, "<span class='warning'>Your body seizes up!</span>")

/obj/item/organ/cyberimp/brain/anti_drop
	name = "Anti-Drop implant"
	desc = "This cybernetic brain implant will allow you to force your hand muscles to contract, preventing item dropping. Twitch ear to toggle."
	var/active = 0
	var/list/stored_items = list()
	implant_color = "#DE7E00"
	slot = ORGAN_SLOT_BRAIN_ANTIDROP
	actions_types = list(/datum/action/item_action/organ_action/toggle)

/obj/item/organ/cyberimp/brain/anti_drop/ui_action_click()
	active = !active
	if(active)
		for(var/obj/item/I in owner.held_items)
			stored_items += I

		var/list/L = owner.get_empty_held_indexes()
		if(LAZYLEN(L) == owner.held_items.len)
			to_chat(owner, "<span class='notice'>You are not holding any items, your hands relax...</span>")
			active = 0
			stored_items = list()
		else
			for(var/obj/item/I in stored_items)
				to_chat(owner, "<span class='notice'>Your [owner.get_held_index_name(owner.get_held_index_of_item(I))]'s grip tightens.</span>")
				ADD_TRAIT(I, TRAIT_NODROP, ANTI_DROP_IMPLANT_TRAIT)

	else
		release_items()
		to_chat(owner, "<span class='notice'>Your hands relax...</span>")

/obj/item/organ/cyberimp/brain/anti_drop/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	var/range = severity/10
	var/atom/A
	if(active)
		release_items()
	for(var/obj/item/I in stored_items)
		A = pick(oview(range))
		I.throw_at(A, range, 2)
		to_chat(owner, "<span class='warning'>Your [owner.get_held_index_name(owner.get_held_index_of_item(I))] spasms and throws the [I.name]!</span>")
	stored_items = list()

/obj/item/organ/cyberimp/brain/anti_drop/proc/release_items()
	for(var/obj/item/I in stored_items)
		REMOVE_TRAIT(I, TRAIT_NODROP, ANTI_DROP_IMPLANT_TRAIT)
	stored_items = list()

/obj/item/organ/cyberimp/brain/anti_drop/deactivate(removing)
	. = ..()
	if(active)
		ui_action_click()

/obj/item/organ/cyberimp/brain/anti_drop/sec_level
	name = "Corporate Anti-Drop implant"
	implant_color = "#ab6509"
	active_security_level = ANTI_DROP_SEC_LEVEL

/obj/item/organ/cyberimp/brain/anti_stun
	name = "CNS Rebooter implant"
	desc = "This implant will automatically give you back control over your central nervous system, reducing downtime when stunned."
	implant_color = "#FFFF00"
	slot = ORGAN_SLOT_BRAIN_ANTISTUN

/obj/item/organ/cyberimp/brain/anti_stun/on_life()
	. = ..()
	if(!. || crit_fail)
		return
	owner.adjustStaminaLoss(-3.5, FALSE) //Citadel edit, makes it more useful in Stamina based combat
	owner.HealAllImmobilityUpTo(ANTI_STUN_SET_AMOUNT)

/obj/item/organ/cyberimp/brain/anti_stun/emp_act(severity)
	. = ..()
	if(crit_fail || (organ_flags & ORGAN_FAILING) || . & EMP_PROTECT_SELF)
		return
	crit_fail = TRUE
	organ_flags |= ORGAN_FAILING
	addtimer(CALLBACK(src, PROC_REF(reboot)), 0.9 * severity)

/obj/item/organ/cyberimp/brain/anti_stun/proc/reboot()
	crit_fail = FALSE
	organ_flags &= ~ORGAN_FAILING

/obj/item/organ/cyberimp/brain/anti_stun/sec_level
	name = "Corporate CNS Rebooter implant"
	implant_color = "#c0c000"
	active_security_level = CNS_REBOOTER_SEC_LEVEL

/obj/item/organ/cyberimp/brain/robot_radshielding
	name = "ECC System Guard implant"
	desc = "This implant can counteract the effects of harmful radiation in robots, effectively increasing their radiation tolerance significantly."
	implant_color = "#0066ff"
	slot = ORGAN_SLOT_BRAIN_ROBOT_RADSHIELDING

/obj/item/organ/cyberimp/brain/robot_radshielding/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(!HAS_TRAIT(owner, TRAIT_ROBOTIC_ORGANISM))
		return //Why did you even get yourself implanted this if you aren't a robot?
	owner.adjustToxLoss(severity / 10, toxins_type = TOX_SYSCORRUPT)
	to_chat(owner, span_warning("<b>ECC-имплантат</b> внезапно начинает вести себя очень нестабильно, нарушая работу вашей системы."))

/obj/item/organ/cyberimp/brain/robot_radshielding/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	. = ..()
	if(!.)
		return
	code_activate()

/obj/item/organ/cyberimp/brain/robot_radshielding/code_activate()
	. = ..()
	ADD_TRAIT(owner, TRAIT_ROBOT_RADSHIELDING, ROBOT_RADSHIELDING_IMPLANT_TRAIT) //Organics can get this, but it does literally nothing for them except cause more pain if EMPd, so uh, good on you?
	to_chat(owner, span_nicegreen("<b>ECC-имплантат</b> активируется, обеспечивая защиту от радиации."))

/obj/item/organ/cyberimp/brain/robot_radshielding/deactivate(removing)
	. = ..()
	REMOVE_TRAIT(owner, TRAIT_ROBOT_RADSHIELDING, ROBOT_RADSHIELDING_IMPLANT_TRAIT)
	if(!removing)
		to_chat(owner, span_warning("<b>ECC-имплантат</b> отключаяется, вы больше не защищены от радиации."))

//[[[[MOUTH]]]]
/obj/item/organ/cyberimp/mouth
	zone = BODY_ZONE_PRECISE_MOUTH

/obj/item/organ/cyberimp/mouth/breathing_tube
	name = "breathing tube implant"
	desc = "This simple implant adds an internals connector to your back, allowing you to use internals without a mask and protecting you from being choked."
	icon_state = "implant_mask"
	slot = ORGAN_SLOT_BREATHING_TUBE
	w_class = WEIGHT_CLASS_TINY

/obj/item/organ/cyberimp/mouth/breathing_tube/emp_act(severity)
	. = ..()
	if(!owner || . & EMP_PROTECT_SELF)
		return
	if(prob(0.6*severity))
		to_chat(owner, "<span class='warning'>Your breathing tube suddenly closes!</span>")
		owner.losebreath += 8

#undef ANTI_STUN_SET_AMOUNT
