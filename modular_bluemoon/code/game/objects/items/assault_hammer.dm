/obj/item/melee/breaching_hammer
	name = "D-4 tactical hammer"
	desc = "A metallic-plastic composite breaching hammer, looks like a whack with this would severly harm or tire someone. You can pry a door alone, but each swing is about twice as slow as when two people with two hammers work in tandem."
	icon = 'modular_bluemoon/icons/obj/assault_items.dmi'
	icon_state = "assault_hammer"
	item_state = "assault_hammer"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/assault_baton_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/assault_baton_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	force = 20
	throwforce = 10
	w_class = WEIGHT_CLASS_NORMAL
	attack_verb_continuous = list("whacks","breaches","bulldozes","flings","thwachs")
	attack_verb_simple = list("breach","hammer","whack","slap","thwach","fling")
	siemens_coefficient = 0
	permeability_coefficient = 0.05
	/// Delay between door hits
	var/breaching_delay = 2 SECONDS
	/// The door we aim to breach
	var/breaching_target = null
	/// If we are in the process of breaching
	var/breaching = FALSE
	/// If we are tracking the door and ourselves
	var/registered = FALSE
	/// The person breaching , initially us but we receive a signal with another one
	var/breacher = null
	/// the amount that the force is multiplied by , that is then applied as damage to the door.
	var/breaching_multipler = 2.5
	/// TRUE while only one person is on the job — [breaching_delay] is doubled
	var/solo_breaching = FALSE

/obj/item/melee/breaching_hammer/Initialize(mapload)
	. = ..()
//	AddElement(/datum/element/kneecapping)

/obj/item/melee/breaching_hammer/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return
	if(istype(target, /obj/machinery/door))
		user.changeNext_move(5 SECONDS)
		if(!registered)
			RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(remove_track), FALSE)
			RegisterSignal(target, COMSIG_BREACHING, PROC_REF(try_breaching), TRUE)
			to_chat(user, text = "You prepare to forcefully strike the door")
			registered = TRUE
		if(!breacher)
			breacher = user
		breaching_target = target
		SEND_SIGNAL(target, COMSIG_BREACHING, user)

/// Removes any form of tracking from the user and the item , make sure to call it on he proper item
/obj/item/melee/breaching_hammer/proc/remove_track(mob/living/carbon/human/user)
	SIGNAL_HANDLER
	if(!registered)
		return FALSE
	registered = FALSE
	breaching = FALSE
	solo_breaching = FALSE
	to_chat(user, text = "You relax yourself , and lay down the breaching hammer")
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(breaching_target, COMSIG_BREACHING)
	breaching_target = null
	breacher = null

/// first hit: start solo (slow) breach; a second person (with a hammer) starts paired breach
/obj/item/melee/breaching_hammer/proc/try_breaching(obj/target, mob/living/carbon/human/user)
	SIGNAL_HANDLER
	// first striker — begin breaching alone (2x do_after) until a partner joins
	if(user == breacher)
		if(!breaching)
			breaching = TRUE
			solo_breaching = TRUE
			INVOKE_ASYNC(src, TYPE_PROC_REF(/obj/item/melee/breaching_hammer, breaching_loop), user, target)
		return FALSE
	if(breaching && !solo_breaching)
		return FALSE
	if(!(user.Adjacent(target)))
		remove_track(user)
		return NONE
	var/mob/living/carbon/human/breach_buddy = breacher
	if(!istype(breach_buddy))
		return FALSE
	var/target_item = breach_buddy.held_items.Find(src, 1, 0)
	if(!target_item)
		// not the breacher's mallet in hand — e.g. partner's own hammer; no-op on this /datum
		return FALSE
	var/obj/item/melee/breaching_hammer/second_hammer = breach_buddy.held_items[target_item]
	if(!istype(second_hammer, /obj/item/melee/breaching_hammer))
		return FALSE
	// Partner joins: first breacher's loop keeps going (now 1x delay); add a second loop on partner's hammer only
	solo_breaching = FALSE
	second_hammer.solo_breaching = FALSE
	var/obj/item/melee/breaching_hammer/buddy_hammer
	for(var/obj/item/melee/breaching_hammer/H in list(user.get_active_held_item(), user.get_inactive_held_item()))
		if(istype(H))
			buddy_hammer = H
			break
	if(!buddy_hammer)
		remove_track(user)
		return FALSE
	buddy_hammer.solo_breaching = FALSE
	INVOKE_ASYNC(buddy_hammer, TYPE_PROC_REF(/obj/item/melee/breaching_hammer, breaching_loop), user, target)
	to_chat(breacher , text = "You begin forcefully smashing the [target]")
	to_chat(user, text = "You begin forcefully smashing the [target]")

/// Keeps looping under the door is no more , or someone moves , gets shot , dies , incapacitated , stunned , etc
/obj/item/melee/breaching_hammer/proc/breaching_loop(mob/living/user, obj/target)
	if(user.stat || !target)
		remove_track(user)
		return FALSE
	if(!(user.Adjacent(target)))
		remove_track(user)
		return FALSE
	if(target.obj_integrity < 1)
		do_smoke(3, target.loc)
		remove_track(user)
		qdel(target, TRUE)
	var/mob/living/carbon/human/silly = breacher
	if(!silly)
		remove_track(user)
		return FALSE
	if(!(silly.Adjacent(target)))
		remove_track(user)
		return FALSE
	var/effective_delay = solo_breaching ? 2 * breaching_delay : breaching_delay
	if(do_after(user, effective_delay))
		if(QDELETED(target))
			return FALSE
		target.take_damage(force*breaching_multipler)
		playsound(target, 'sound/weapons/sonic_jackhammer.ogg', 70)
		visible_message("[user] smashes the [target] forcefully with the [src]")
		user.do_attack_animation(target, used_item = src)
		breaching_loop(user, target)
		return TRUE
	remove_track(user)

