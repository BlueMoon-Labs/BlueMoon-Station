/obj/item/clothing/neck/bm
	icon = 'modular_bluemoon/icons/obj/clothing/neck.dmi'
	mob_overlay_icon =  'modular_bluemoon/icons/mob/clothing/neck.dmi'

/obj/item/clothing/neck/stole/AltClick()
	. = ..()
	body_parts_covered = body_parts_covered ? NONE : CHEST|GROIN
	to_chat(usr, "<span class='notice'>Your [src] is [body_parts_covered ? "now covering your chest and groin" : "no longer covering anything"].</span>")
	return TRUE

/obj/item/clothing/neck/mantle/AltClick()
	. = ..()
	body_parts_covered = body_parts_covered ? NONE : CHEST|GROIN
	to_chat(usr, "<span class='notice'>Your [src] is [body_parts_covered ? "now covering your chest and groin" : "no longer covering anything"].</span>")
	return TRUE

/obj/item/clothing/neck/scarf/cow
	name = "Holly's scarf"
	desc = "A stylish scarf."
	icon = 'modular_bluemoon/icons/obj/clothing/neck.dmi'
	mob_overlay_icon =  'modular_bluemoon/icons/mob/clothing/neck.dmi'
	icon_state = "m_hollyN"

/obj/item/clothing/neck/petcollar
	w_class = WEIGHT_CLASS_SMALL
	var/obj/item/card/id/access_id = null
	var/list/collar_access

/obj/item/clothing/neck/petcollar/Destroy()
	QDEL_NULL(access_id)
	return ..()

/obj/item/clothing/neck/petcollar/get_examine_string(mob/user, thats)
	. = ..()
	if(access_id)
		//. += " with [icon2html(access_id.get_cached_flat_icon(), user)] \a [access_id] clipped onto it."
		. += " with \a [access_id.get_examine_string(user)] clipped onto it"

/obj/item/clothing/neck/petcollar/Entered(atom/movable/AM)
	. = ..()
	if(istype(AM, /obj/item/card/id))
		access_id = AM
		refreshID()

/obj/item/clothing/neck/petcollar/Exited(atom/movable/AM)
	. = ..()
	if(istype(AM, /obj/item/card/id))
		access_id = null
		refreshID()

/obj/item/clothing/neck/petcollar/proc/refreshID()
	if(ishuman(loc))
		var/mob/living/carbon/human/H = loc
		if(H.wear_neck == src)
			H.sec_hud_set_ID()

/obj/item/clothing/neck/petcollar/GetAccess()
	return access_id ? access_id.GetAccess() : ..()

/obj/item/clothing/neck/petcollar/GetID()
	return access_id ? access_id : ..()

/obj/item/clothing/neck/petcollar/equipped(mob/user, slot)
	. = ..()
	if((slot == ITEM_SLOT_NECK) && (type in list(/obj/item/clothing/neck/petcollar, /obj/item/clothing/neck/petcollar/locked, /obj/item/clothing/neck/necklace/cowbell)))
		var/mob/living/carbon/human/H = user
		RegisterSignal(H, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))

/obj/item/clothing/neck/petcollar/proc/on_move(atom/old_loc, dir)
	SIGNAL_HANDLER
	if((current_equipped_slot == ITEM_SLOT_NECK))
		if(prob(25)) //roughly every 4th step
			playsound(loc, pick('modular_bluemoon/sound/items/collarbell1.ogg','modular_bluemoon/sound/items/collarbell2.ogg','modular_bluemoon/sound/items/collarbell3.ogg', 'modular_bluemoon/sound/items/collarbell4.ogg'), 10)

/obj/item/clothing/neck/petcollar/dropped(mob/user)
	. = ..()
	if((current_equipped_slot == ITEM_SLOT_NECK) && (type in list(/obj/item/clothing/neck/petcollar, /obj/item/clothing/neck/petcollar/locked, /obj/item/clothing/neck/necklace/cowbell)))
		var/mob/living/carbon/human/H = user
		UnregisterSignal(H, COMSIG_MOVABLE_MOVED)

/obj/item/clothing/neck/petcollar/locked
	interactable_in_strip_menu = TRUE

/obj/item/clothing/neck/petcollar/locked/equipped(mob/user, slot)
	. = ..()
	if(lock)
		if(slot == ITEM_SLOT_NECK)
			ADD_TRAIT(src, TRAIT_NODROP, CLOTHING_TRAIT)
