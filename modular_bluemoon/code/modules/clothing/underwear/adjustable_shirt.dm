/obj/item/clothing/underwear/shirt/adjustable_wtoggle //it should allow us to use togglename(questionmark)
	icon = 'icons/obj/clothing/suits.dmi'
	name = "This item should never be used. Ahelp if you somehow found this."
	var/togglename = null
	var/suittoggled = FALSE

/obj/item/clothing/underwear/shirt/adjustable_wtoggle/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return
	suit_toggle(user)
	return TRUE

/obj/item/clothing/underwear/shirt/adjustable_wtoggle/proc/on_toggle(mob/user)
	to_chat(usr, "<span class='notice'>You toggle [src]'s [togglename].</span>")

/obj/item/clothing/underwear/shirt/adjustable_wtoggle/ui_action_click()
	suit_toggle()

/obj/item/clothing/underwear/shirt/adjustable_wtoggle/proc/suit_toggle()
	set src in usr

	if(!can_use(usr))
		return FALSE

	on_toggle(usr)
	src.suittoggled = !src.suittoggled
	update_icon()
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtons()

/obj/item/clothing/underwear/shirt/adjustable_wtoggle/examine(mob/user)
	. = ..()
	. += "Alt-click on [src] to toggle the [togglename]."

/obj/item/clothing/underwear/shirt/adjustable_wtoggle/adjustable_shirt
	name = "adjustable shirt"
	desc = "An adjustable shirt."
	icon = 'modular_bluemoon/icons/obj/clothing/adjustable_shirt.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/obj/clothing/adjustable_shirt.dmi'
	icon_state = "adjustableshirt"
	togglename = "buttons"
	body_parts_covered = ARMS
	slot_flags = ITEM_SLOT_SHIRT
	fitted = NO_FEMALE_UNIFORM
	alternate_worn_layer = WRISTS_LAYER
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/underwear/shirt/adjustable_wtoggle/proc/update_sprite_visibility(datum/source, obj/item/I)
	var/mob/living/carbon/human/H = source
	var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(B?.is_exposed() || H.is_chest_exposed())
		H.update_inv_w_shirt()
	else if(!HAS_TRAIT(H, TRAIT_HUMAN_NO_RENDER))
		H.remove_overlay(SHIRT_LAYER)

/obj/item/clothing/underwear/shirt/adjustable_wtoggle/update_icon_state()
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_SHIRT && istype(loc, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = loc
		var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
		if(!suittoggled)
			icon_state = "[initial(icon_state)]_[B?.size || 0]"
		else if(suittoggled)
			icon_state = "[initial(icon_state)]_t_[B?.size || 0]"
		H.update_inv_w_shirt()
		H.update_body()
	else
		icon_state = "[initial(icon_state)]"

/obj/item/clothing/underwear/shirt/adjustable_wtoggle/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_SHIRT)
		var/mob/living/carbon/human/H = user
		RegisterSignal(H, COMSIG_MOB_ITEM_EQUIPPED,  PROC_REF(update_sprite_visibility))
		RegisterSignal(H, COMSIG_MOB_UNEQUIPPED_ITEM,  PROC_REF(update_sprite_visibility))
		update_icon()

/obj/item/clothing/underwear/shirt/adjustable_wtoggle/dropped(mob/user)
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_SHIRT)
		var/mob/living/carbon/human/H = user
		UnregisterSignal(H, list(COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM))
		update_icon()
