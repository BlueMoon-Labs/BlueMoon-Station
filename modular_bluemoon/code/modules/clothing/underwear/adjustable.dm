/obj/item/clothing/underwear/shirt/adjustable
	icon = null
	var/polychromic = FALSE
	var/suittoggled = FALSE
	slot_flags = ITEM_SLOT_SHIRT
	fitted = NO_FEMALE_UNIFORM
	alternate_worn_layer = (SUIT_LAYER + 1)
	body_parts_covered = NONE

/obj/item/clothing/underwear/shirt/adjustable/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/adjustable/proc/get_breasts_suffix(mob/living/carbon/human/H)
	if(!istype(H) || \
		!H.dna?.features || \
		H.dna.features["breasts_sprite_variant"] != "Old")
		return ""
	var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(!B || !B.shape)
		return ""
	var/datum/sprite_accessory/S = GLOB.breasts_shapes_list[B.shape]
	if(S?.icon_state != "pair")
		return ""
	return "_old"

/obj/item/clothing/underwear/shirt/adjustable/proc/update_sprite_visibility(datum/source, obj/item/I)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/H = source
	var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(B?.is_exposed() || H.is_chest_exposed())
		H.update_inv_w_shirt()
	else if(!HAS_TRAIT(H, TRAIT_HUMAN_NO_RENDER))
		H.remove_overlay(SHIRT_LAYER)

/obj/item/clothing/underwear/shirt/adjustable/update_icon_state()
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_SHIRT && istype(loc, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = loc
		var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
		var/suffix = get_breasts_suffix(H)
		icon_state = "[initial(icon_state)][suittoggled ? "_t" : ""]_[B?.size || 0][suffix]"
		H.update_inv_w_shirt()
	else
		icon_state = "[initial(icon_state)]"

/obj/item/clothing/underwear/shirt/adjustable/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		UnregisterSignal(H, list(COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM))
		if(slot == ITEM_SLOT_SHIRT)
			RegisterSignal(H, COMSIG_MOB_ITEM_EQUIPPED, PROC_REF(update_sprite_visibility))
			RegisterSignal(H, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(update_sprite_visibility))
	update_icon()

/obj/item/clothing/underwear/shirt/adjustable/dropped(mob/user)
	var/was_shirt = (current_equipped_slot == ITEM_SLOT_SHIRT)
	. = ..()
	if(was_shirt && ishuman(user))
		var/mob/living/carbon/human/H = user
		UnregisterSignal(H, list(COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM))
	update_icon()

//-----------------------------------------------------------//

/obj/item/clothing/underwear/shirt/adjustable/toggle
	var/togglename = null

/obj/item/clothing/underwear/shirt/adjustable/toggle/AltClick(mob/user)
	if(!user || !user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return FALSE
	. = ..()
	suit_toggle(user)
	return TRUE

/obj/item/clothing/underwear/shirt/adjustable/toggle/proc/on_toggle(mob/user)
	to_chat(user, "<span class='notice'>You toggle [src]'s [togglename].</span>")

/obj/item/clothing/underwear/shirt/adjustable/toggle/ui_action_click()
	suit_toggle(usr)

/obj/item/clothing/underwear/shirt/adjustable/toggle/proc/suit_toggle(mob/user)
	user = user || usr
	if(!togglename || \
	!user || \
	!user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return FALSE
	on_toggle(user)
	suittoggled = !suittoggled
	update_icon()
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtons()
	return TRUE

/obj/item/clothing/underwear/shirt/adjustable/toggle/examine(mob/user)
	. = ..()
	if(togglename)
		. += "Alt-click on [src] to toggle the [togglename]."

//-----------------------------------------------------------//

/obj/item/clothing/underwear/shirt/adjustable/toggle/adjustable_shirt
	name = "adjustable shirt"
	desc = "An adjustable shirt."
	icon = 'modular_bluemoon/icons/obj/clothing/adjustable_shirt.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/obj/clothing/adjustable_shirt.dmi'
	icon_state = "adjustableshirt"
	togglename = "buttons"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/underwear/shirt/adjustable/bra
	name = "adjustable bra"
	desc = "A bra that adjusts its size to fit your breasts"
	icon = 'modular_bluemoon/icons/mob/clothing/bra_overhaul.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/bra_overhaul.dmi'
	icon_state = "bra"
	alternate_worn_layer = BELT_LAYER
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	polychromic = TRUE
