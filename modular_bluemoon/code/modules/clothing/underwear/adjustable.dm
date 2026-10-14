/obj/item/clothing/underwear/shirt/adjustable //it should allow us to use togglename(questionmark)
	icon = 'icons/obj/clothing/suits.dmi'
	name = "This item should never be used. Ahelp if you somehow found this."
	var/togglename = null
	var/suittoggled = FALSE
	var/polychromic = FALSE
	fitted = NO_FEMALE_UNIFORM

/obj/item/clothing/underwear/shirt/adjustable/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/adjustable/proc/get_breasts_suffix(mob/living/carbon/human/H)
	if(!istype(H) || !H.dna)
		return ""
	if(H.dna.features["breasts_sprite_variant"] != "Old")
		return ""
	var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(!B)
		return ""
	var/datum/sprite_accessory/S = GLOB.breasts_shapes_list[B.shape]
	if(S?.icon_state != "pair")
		return ""
	return "_old"

/obj/item/clothing/underwear/shirt/adjustable/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
		return
	suit_toggle(user)
	return TRUE

/obj/item/clothing/underwear/shirt/adjustable/proc/on_toggle(mob/user)
	to_chat(usr, "<span class='notice'>You toggle [src]'s [togglename].</span>")

/obj/item/clothing/underwear/shirt/adjustable/ui_action_click()
	suit_toggle()

/obj/item/clothing/underwear/shirt/adjustable/proc/suit_toggle(mob/user)
	if(togglename)
		if(!user)
			user = usr
		if(!can_use(user))
			return FALSE
		on_toggle(user)
		suittoggled = !suittoggled
		update_icon()
		for(var/X in actions)
			var/datum/action/A = X
			A.UpdateButtons()

/obj/item/clothing/underwear/shirt/adjustable/examine(mob/user)
	. = ..()
	. += "Alt-click on [src] to toggle the [togglename]."

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
		if(!suittoggled)
			icon_state = "[initial(icon_state)]_[B?.size || 0][suffix]"
		else
			icon_state = "[initial(icon_state)]_t_[B?.size || 0][suffix]"
		H.update_inv_w_shirt()
	else
		icon_state = "[initial(icon_state)]"

/obj/item/clothing/underwear/shirt/adjustable/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_SHIRT)
		var/mob/living/carbon/human/H = user
		RegisterSignal(H, COMSIG_MOB_ITEM_EQUIPPED,  PROC_REF(update_sprite_visibility))
		RegisterSignal(H, COMSIG_MOB_UNEQUIPPED_ITEM,  PROC_REF(update_sprite_visibility))
		update_icon()

/obj/item/clothing/underwear/shirt/adjustable/dropped(mob/user)
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_SHIRT)
		var/mob/living/carbon/human/H = user
		UnregisterSignal(H, list(COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM))
		update_icon()

/obj/item/clothing/underwear/shirt/adjustable/adjustable_shirt
	name = "adjustable shirt"
	desc = "An adjustable shirt."
	icon = 'modular_bluemoon/icons/obj/clothing/adjustable_shirt.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/obj/clothing/adjustable_shirt.dmi'
	icon_state = "adjustableshirt"
	togglename = "buttons"
	can_toggle = TRUE
	body_parts_covered = ARMS
	slot_flags = ITEM_SLOT_SHIRT
	alternate_worn_layer = GENITALS_EXPOSED_LAYER
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/underwear/shirt/adjustable/top/adjustable_bra
	name = "adjustable bra"
	desc = "A bra that adjusts its size to fit your breasts"
	icon = 'modular_bluemoon/icons/mob/clothing/bra_overhaul.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/bra_overhaul.dmi'
	icon_state = "bra"
	body_parts_covered = NONE
	alternate_worn_layer = GENITALS_EXPOSED_LAYER
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	polychromic = TRUE
