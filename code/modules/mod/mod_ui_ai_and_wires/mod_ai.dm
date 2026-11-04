/obj/item/mod/control/transfer_ai(interaction, mob/user, mob/living/silicon/ai/intAI, obj/item/aicard/card)
	. = ..()
	if(!.)
		return
	if(!is_open()) //mod must be open
		balloon_alert(user, "suit must be open to transfer!")
		return
	switch(interaction)
		if(AI_TRANS_TO_CARD)
			if(!ai)
				balloon_alert(user, "no AI in suit!")
				return
			if(!isAI(ai))
				balloon_alert(user, "onboard AI cannot fit in this card!")
				return
			balloon_alert(user, "transferring to card...")
			if(!do_after(user, 5 SECONDS, target = src))
				balloon_alert(user, "interrupted!")
				return
			if(!ai)
				return
			intAI = ai
			intAI.ai_restore_power()//So the AI initially has power.
			intAI.control_disabled = TRUE
			intAI.radio_enabled = FALSE
			intAI.disconnect_shell()
			intAI.forceMove(card)
			card.AI = intAI
			for(var/datum/action/action as anything in actions)
				action.Remove(intAI)
			intAI.controlled_equipment = null
			intAI.remote_control = null
			balloon_alert(intAI, "transferred to a card")
			balloon_alert(user, "AI transferred to card")
			ai = null

		if(AI_TRANS_FROM_CARD) //Using an AI card to upload to the suit.
			intAI = card.AI
			if(!intAI)
				balloon_alert(user, "no AI in card!")
				return
			if(ai)
				balloon_alert(user, "already has AI!")
				return
			if(intAI.deployed_shell) //Recall AI if shelled so it can be checked for a client
				intAI.disconnect_shell()
			if(intAI.stat || !intAI.client)
				balloon_alert(user, "AI unresponsive!")
				return
			balloon_alert(user, "transferring to suit...")
			if(!do_after(user, 5 SECONDS, target = src))
				balloon_alert(user, "interrupted!")
				return
			if(ai)
				return
			balloon_alert(user, "AI transferred to suit")
			ai_enter_mod(intAI)
			card.AI = null

/obj/item/mod/control/proc/ai_enter_mod(mob/living/silicon/ai/new_ai)
	new_ai.control_disabled = FALSE
	new_ai.radio_enabled = TRUE
	new_ai.ai_restore_power()
	new_ai.cancel_camera()
	new_ai.controlled_equipment = src
	new_ai.remote_control = src
	new_ai.forceMove(src)
	ai = new_ai
	balloon_alert(new_ai, "transferred to a suit")
	for(var/datum/action/action as anything in actions)
		action.Grant(ai)

/**
 * Simple proc to insert the pAI into the MODsuit.
 *
 * user - The person trying to put the pAI into the MODsuit.
 * card - The pAI card we're slotting in the MODsuit.
 */

/obj/item/mod/control/proc/insert_pai(mob/user, obj/item/paicard/card)
	if(!can_insert_pai(card, user))
		return FALSE
	balloon_alert(user, "transferring to suit...")
	if(!do_after(user, 5 SECONDS, target = src))
		return FALSE
	if(!can_insert_pai(card, user) || !user.transferItemToLoc(card, src))
		return FALSE
	return connect_pai(card)

/obj/item/mod/control/proc/can_insert_pai(obj/item/paicard/card, mob/user)
	if(ai || !can_install_pai || QDELETED(card) || !user.Adjacent(src))
		return FALSE
	if(!card.pai?.mind || card.pai.holoform || card.pai.loc != card)
		balloon_alert(user, "pAI must be folded and responsive!")
		return FALSE
	return user.is_holding(card)

/obj/item/mod/control/proc/connect_pai(obj/item/paicard/card)
	if(ai || !can_install_pai || QDELETED(card?.pai) || card.loc != src)
		return FALSE
	var/mob/living/silicon/pai/pai = card.pai
	card.moveToNullspace()
	ai = pai
	pai.canholo = FALSE
	pai.remote_control = src
	RegisterSignal(pai, COMSIG_PARENT_QDELETING, PROC_REF(on_pai_deleted))
	RegisterSignal(pai, COMSIG_MOB_ALTCLICKON, PROC_REF(on_ai_click))
	pai.forceMove(src)
	pai.reset_perspective()
	for(var/datum/action/item_action/mod/action in actions)
		action.Grant(pai)
	balloon_alert(pai, "transferred to a suit")
	return TRUE

/obj/item/mod/control/proc/extract_pai(mob/user, forced = FALSE, feedback = TRUE)
	if(!ispAI(ai))
		return FALSE
	var/mob/living/silicon/pai/current_pai = ai
	if(!forced)
		if(!user || !user.Adjacent(src) || !is_open())
			if(user && feedback)
				balloon_alert(user, "open the suit panel!")
			return FALSE
		if(!do_after(user, 5 SECONDS, target = src))
			return FALSE
		if(ai != current_pai || !is_open() || !user.Adjacent(src))
			return FALSE
	remove_pai(feedback)
	if(feedback && user)
		balloon_alert(user, "pAI removed from the suit")
	return TRUE

/obj/item/mod/control/proc/remove_pai(feedback = FALSE)
	if(!ispAI(ai))
		return FALSE
	var/mob/living/silicon/pai/pai = ai
	disconnect_pai(pai)
	var/obj/item/paicard/card = pai.card
	if(!QDELETED(card))
		card.forceMove(drop_location())
		pai.forceMove(card)
	pai.reset_perspective()
	if(feedback)
		balloon_alert(pai, "removed from a suit")
	return TRUE

/obj/item/mod/control/proc/disconnect_pai(mob/living/silicon/pai/pai)
	UnregisterSignal(pai, list(COMSIG_PARENT_QDELETING, COMSIG_MOB_ALTCLICKON))
	for(var/datum/action/item_action/mod/action in actions)
		if(action.owner == pai)
			action.Remove(pai)
	remove_module_actions(pai)
	SStgui.close_user_uis(pai, src)
	pai.remote_control = null
	pai.canholo = TRUE
	ai = null

/obj/item/mod/control/proc/on_pai_deleted(mob/living/silicon/pai/source)
	SIGNAL_HANDLER
	disconnect_pai(source)

/obj/item/mod/control/proc/on_ai_click(mob/source, atom/target)
	SIGNAL_HANDLER
	if(source != ai || source.incapacitated() || !selected_module?.active || !selected_module.have_shortcut_activation)
		return
	INVOKE_ASYNC(src, PROC_REF(use_ai_module), source, target)
	return COMSIG_MOB_CANCEL_CLICKON

/obj/item/mod/control/proc/use_ai_module(mob/user, atom/target)
	if(user != ai || user.incapacitated() || !selected_module?.active || !selected_module.have_shortcut_activation)
		return FALSE
	return selected_module.on_select_use(target)

#define MOVE_DELAY 2
#define WEARER_DELAY 1
#define LONE_DELAY 5
#define CELL_PER_STEP (DEFAULT_CHARGE_DRAIN * 2.5)
#define AI_FALL_TIME (1 SECONDS)

/obj/item/mod/control/relaymove(mob/user, direction)
	if((!is_active() && wearer) || !check_charge(CELL_PER_STEP)  || user != ai || !COOLDOWN_FINISHED(src, cooldown_mod_move) || (wearer?.pulledby?.grab_state > GRAB_PASSIVE))
		return FALSE
	var/timemodifier = MOVE_DELAY * (ISDIAGONALDIR(direction) ? SQRT_2 : 1) * (wearer ? WEARER_DELAY : LONE_DELAY)
	if(wearer && !wearer.Process_Spacemove(direction))
		return FALSE
	else if(!wearer && (!has_gravity() || !isturf(loc)))
		return FALSE
	COOLDOWN_START(src, cooldown_mod_move, movedelay * timemodifier + slowdown)
	subtract_charge(CELL_PER_STEP)
	playsound(src, 'sound/mecha/mechmove01.ogg', 25, TRUE)
	if(ismovable(wearer?.loc))
		return wearer.loc.relaymove(wearer, direction)
	else if(wearer)
		ADD_TRAIT(wearer, TRAIT_MOBILITY_NOREST, MOD_TRAIT)
		addtimer(CALLBACK(src, PROC_REF(ai_fall)), AI_FALL_TIME, TIMER_UNIQUE | TIMER_OVERRIDE)
	var/atom/movable/mover = wearer || src
	return step(mover, direction)

#undef MOVE_DELAY
#undef WEARER_DELAY
#undef LONE_DELAY
#undef CELL_PER_STEP
#undef AI_FALL_TIME

/obj/item/mod/control/proc/ai_fall()
	if(!wearer)
		return
	REMOVE_TRAIT(wearer, TRAIT_MOBILITY_NOREST, MOD_TRAIT)

/obj/item/mod/control/ui_state(mob/user)
	if(user == ai)
		return GLOB.contained_state
	return ..()
