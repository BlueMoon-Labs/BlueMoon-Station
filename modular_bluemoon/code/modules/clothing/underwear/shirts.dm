//Copypaste from clothing/suit/toggle but for underwear.

/obj/item/clothing/underwear/shirt/toggle //it should allow us to use togglename(questionmark)
    icon = 'icons/obj/clothing/suits.dmi'
    name = "This item should never be used. Ahelp if you somehow found this."
    var/togglename = null
    var/suittoggled = FALSE

/obj/item/clothing/underwear/shirt/toggle/AltClick(mob/user)
    . = ..()
    if(!user.canUseTopic(src, BE_CLOSE, ismonkey(user)))
        return
    suit_toggle(user)
    return TRUE

/obj/item/clothing/underwear/shirt/toggle/proc/on_toggle(mob/user) // override this, not suit_toggle, which does checks
    to_chat(usr, "<span class='notice'>You toggle [src]'s [togglename].</span>")

/obj/item/clothing/underwear/shirt/toggle/ui_action_click()
    suit_toggle()

/obj/item/clothing/underwear/shirt/toggle/proc/suit_toggle()
    set src in usr

    if(!can_use(usr))
        return FALSE

    on_toggle(usr)
    if(src.suittoggled)
        src.icon_state = "[initial(icon_state)]"
        src.suittoggled = FALSE
    else if(!src.suittoggled)
        src.icon_state = "[initial(icon_state)]_t"
        src.suittoggled = TRUE
    usr.update_inv_wear_suit()
    for(var/X in actions)
        var/datum/action/A = X
        A.UpdateButtons()

/obj/item/clothing/underwear/shirt/toggle/examine(mob/user)
    . = ..()
    . += "Alt-click on [src] to toggle the [togglename]."

//Copypaste ends

/obj/item/clothing/underwear/shirt/shoulderless_shirt
	name = "shoulderless shirt"
	desc = "Really shoulderless shirt."
	icon = 'modular_bluemoon/icons/obj/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "shoulderless_shirt"
	item_state = "shoulderless_shirt"

/obj/item/clothing/underwear/shirt/garland_bra
	name = "garland bra"
	desc = "X-mas garland bra."
	icon = 'modular_bluemoon/icons/obj/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mutantrace_variation = STYLE_NO_ANTHRO_ICON
	icon_state = "garland_shirt"
	item_state = "garland_shirt"

/obj/item/clothing/underwear/shirt/cheese
	name = "cheese-kini bra"
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "bra_cheese-kini"

//Лифчик, который не сжимает грудь до состояния доски

/obj/item/clothing/underwear/shirt/bra/bra_adjustable
	name = "adjustable bra"
	desc = "A bra that adjusts its size to fit your breasts"
	icon = 'modular_bluemoon/icons/mob/clothing/bra_overhaul.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/bra_overhaul.dmi'
	icon_state = "bra"
	body_parts_covered = NONE
	fitted = NO_FEMALE_UNIFORM
	alternate_worn_layer = BACK_LAYER
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/proc/update_sprite_visibility(datum/source, obj/item/I)
	var/mob/living/carbon/human/H = source
	var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(B?.is_exposed() || H.is_chest_exposed())
		H.update_inv_w_shirt()
	else if(!HAS_TRAIT(H, TRAIT_HUMAN_NO_RENDER))
		H.remove_overlay(SHIRT_LAYER)

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/update_icon_state()
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_SHIRT && istype(loc, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = loc
		var/obj/item/organ/genital/breasts/B = H.getorganslot(ORGAN_SLOT_BREASTS)
		icon_state = "[initial(icon_state)]_[B?.size || 0]"
		H.update_inv_w_shirt()
		H.update_body()
	else
		icon_state = "[initial(icon_state)]"

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_SHIRT)
		var/mob/living/carbon/human/H = user
		RegisterSignal(H, COMSIG_MOB_ITEM_EQUIPPED,  PROC_REF(update_sprite_visibility))
		RegisterSignal(H, COMSIG_MOB_UNEQUIPPED_ITEM,  PROC_REF(update_sprite_visibility))
		update_icon()

/obj/item/clothing/underwear/shirt/bra/bra_adjustable/dropped(mob/user)
	. = ..()
	if(current_equipped_slot == ITEM_SLOT_SHIRT)
		var/mob/living/carbon/human/H = user
		UnregisterSignal(H, list(COMSIG_MOB_ITEM_EQUIPPED, COMSIG_MOB_UNEQUIPPED_ITEM))
		update_icon()
