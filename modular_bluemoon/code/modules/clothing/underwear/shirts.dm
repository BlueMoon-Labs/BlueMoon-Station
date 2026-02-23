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

/obj/item/clothing/underwear/shirt/blouse_female
	name = "feminie blouse"
	desc = "A feminie blouse."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "blouse_female"
	under_type = /obj/item/clothing/underwear/shirt
	body_parts_covered = CHEST | ARMS
	slot_flags = ITEM_SLOT_SHIRT
	fitted = NO_FEMALE_UNIFORM

/obj/item/clothing/underwear/shirt/longsleeve_croptop
	name = "longsleeve croptop"
	desc = "A longsleeve croptop."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "longsleeve_croptop"
	under_type = /obj/item/clothing/underwear/shirt
	body_parts_covered = CHEST | ARMS
	slot_flags = ITEM_SLOT_SHIRT

/obj/item/clothing/underwear/shirt/longsleeve_croptop_female
	name = "feminie longsleeve croptop"
	desc = "A longsleeve croptop. This variation is made for females."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "longsleeve_croptop_female"
	under_type = /obj/item/clothing/underwear/shirt
	body_parts_covered = CHEST | ARMS
	slot_flags = ITEM_SLOT_SHIRT
	fitted = NO_FEMALE_UNIFORM

/obj/item/clothing/underwear/shirt/formalshirt
	name = "formal shirt"
	desc = "A formal shirt."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "formalshirt"
	body_parts_covered = CHEST | ARMS

/obj/item/clothing/underwear/shirt/poly_shirt
	name = "polychromic shirt"
	desc = "A polychromic shirt with long sleeves."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "poly_shirt"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_shirt/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_lightshirt
	name = "polychromic light shirt"
	desc = "A light polychromic shirt without long sleeves."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "poly_lightshirt"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_lightshirt/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/formalshirt_light
	name = "light formal shirt"
	desc = "A light formal shirt without sleeves."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "formalshirt_light"
	body_parts_covered = CHEST

/obj/item/clothing/underwear/shirt/transparent_top
	name = "transparent top"
	desc = "A transparent top, made for concubines and belly dancers!"
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "transparent_top"
	body_parts_covered = CHEST

/obj/item/clothing/underwear/shirt/poly_corset
	name = "polychromic corset"
	desc = "A polychromic corset. Nanotrasen is not resposible for any organ damage."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "poly_corset"
	body_parts_covered = CHEST
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_corset/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/revealing_shirt
	name = "revealing shirt"
	desc = "A sexy office uniform, that has a low cropped front to show off some chest, or bra."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "revealing_shirt"
	body_parts_covered = ARMS
	fitted = NO_FEMALE_UNIFORM

/obj/item/clothing/underwear/shirt/poly_shortertop
	name = "polychromic short top"
	desc = "A short polychromic top."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "poly_shortertop"
	body_parts_covered = CHEST
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_shortertop/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/formalshirt_thin
	name = "thin formal shirt"
	desc = "A formal shirt made out of thin material."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "formalshirt_thin"
	body_parts_covered = CHEST | ARMS

/obj/item/clothing/underwear/shirt/poly_mesh
	name = "polychromic mesh top"
	desc = "A transparent polychromic top made for those, who love to reveal their chest with style. Great with pantyhose!"
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "poly_mesh"
	body_parts_covered = CHEST
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_mesh/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_sweater
	name = "polychromic sweater"
	desc = "A polychromic sweater."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "poly_sweater"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_sweater/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_sweater/verb/worn_layer()
	set name = "Change worn layer"
	set category = "Object"
	set src in usr
	if(iscarbon(usr) && usr.get_item_by_slot(ITEM_SLOT_SHIRT) == src)
		to_chat(span_notice("You must take it off first!"))
		return
	else
		var/choice = tgui_alert(usr, "Select worn layer.", "Layer", list("Accessory", "Undershirt",  "Uniform"))
		switch(choice)
			if("Accessory")
				new /obj/item/clothing/accessory/poly_sweater(usr.loc)
				for(var/obj/item/clothing/accessory/poly_sweater/C in usr.loc)
					C.color = src.color
					C.name = src.name
					C.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Undershirt")
				new /obj/item/clothing/underwear/shirt/poly_sweater(usr.loc)
				for(var/obj/item/clothing/underwear/shirt/poly_sweater/A in usr.loc)
					A.color = src.color
					A.name = src.name
					A.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Uniform")
				new /obj/item/clothing/under/poly_sweater(usr.loc)
				for(var/obj/item/clothing/under/poly_sweater/U in usr.loc)
					U.color = src.color
					U.name = src.name
					U.desc = src.desc
				to_chat(usr, span_notice("Now wearing as uniform!"))
				qdel(src)

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderless
	name = "shoulderless polychromic sweater"
	desc = "A polychromic sweater made for the girls, who like to flash their shoulders."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "poly_sweater_shoulderless"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderless/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderless/verb/worn_layer()
	set name = "Change worn layer"
	set category = "Object"
	set src in usr
	if(iscarbon(usr) && usr.get_item_by_slot(ITEM_SLOT_SHIRT) == src)
		to_chat(span_notice("You must take it off first!"))
		return
	else
		var/choice = tgui_alert(usr, "Select worn layer.", "Layer", list("Accessory", "Undershirt",  "Uniform"))
		switch(choice)
			if("Accessory")
				new /obj/item/clothing/accessory/poly_sweater_shoulderless(usr.loc)
				for(var/obj/item/clothing/accessory/poly_sweater_shoulderless/C in usr.loc)
					C.color = src.color
					C.name = src.name
					C.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Undershirt")
				new /obj/item/clothing/underwear/shirt/poly_sweater_shoulderless(usr.loc)
				for(var/obj/item/clothing/underwear/shirt/poly_sweater_shoulderless/A in usr.loc)
					A.color = src.color
					A.name = src.name
					A.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Uniform")
				new /obj/item/clothing/under/poly_sweater_shoulderless(usr.loc)
				for(var/obj/item/clothing/under/poly_sweater_shoulderless/U in usr.loc)
					U.color = src.color
					U.name = src.name
					U.desc = src.desc
				to_chat(usr, span_notice("Now wearing as uniform!"))
				qdel(src)

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderlessalt
	name = "shoulderless polychromic sweater alt"
	desc = "A polychromic sweater made for the girls, who like to flash their shoulders."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "poly_sweater_shoulderlessalt"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderlessalt/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_sweater_shoulderlessalt/verb/worn_layer()
	set name = "Change worn layer"
	set category = "Object"
	set src in usr
	if(iscarbon(usr) && usr.get_item_by_slot(ITEM_SLOT_SHIRT) == src)
		to_chat(span_notice("You must take it off first!"))
		return
	else
		var/choice = tgui_alert(usr, "Select worn layer.", "Layer", list("Accessory", "Undershirt",  "Uniform"))
		switch(choice)
			if("Accessory")
				new /obj/item/clothing/accessory/poly_sweater_shoulderlessalt(usr.loc)
				for(var/obj/item/clothing/accessory/poly_sweater_shoulderlessalt/C in usr.loc)
					C.color = src.color
					C.name = src.name
					C.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Undershirt")
				new /obj/item/clothing/underwear/shirt/poly_sweater_shoulderlessalt(usr.loc)
				for(var/obj/item/clothing/underwear/shirt/poly_sweater_shoulderlessalt/A in usr.loc)
					A.color = src.color
					A.name = src.name
					A.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Uniform")
				new /obj/item/clothing/under/poly_sweater_shoulderlessalt(usr.loc)
				for(var/obj/item/clothing/under/poly_sweater_shoulderlessalt/U in usr.loc)
					U.color = src.color
					U.name = src.name
					U.desc = src.desc
				to_chat(usr, span_notice("Now wearing as uniform!"))
				qdel(src)

/obj/item/clothing/underwear/shirt/poly_keyholesweater
	name = "polychromic keyhole sweater"
	desc = "What is the point of this, anyway?"
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	icon_state = "poly_keyholesweater"
	body_parts_covered = CHEST | ARMS
	var/polychromic = TRUE

/obj/item/clothing/underwear/shirt/poly_keyholesweater/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/shirt/poly_keyholesweater/verb/worn_layer()
	set name = "Change worn layer"
	set category = "Object"
	set src in usr
	if(iscarbon(usr) && usr.get_item_by_slot(ITEM_SLOT_SHIRT) == src)
		to_chat(span_notice("You must take it off first!"))
		return
	else
		var/choice = tgui_alert(usr, "Select worn layer.", "Layer", list("Accessory", "Undershirt",  "Uniform"))
		switch(choice)
			if("Accessory")
				new /obj/item/clothing/accessory/poly_keyholesweater(usr.loc)
				for(var/obj/item/clothing/accessory/poly_keyholesweater/C in usr.loc)
					C.color = src.color
					C.name = src.name
					C.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Undershirt")
				new /obj/item/clothing/underwear/shirt/poly_keyholesweater(usr.loc)
				for(var/obj/item/clothing/underwear/shirt/poly_keyholesweater/A in usr.loc)
					A.color = src.color
					A.name = src.name
					A.desc = src.desc
				to_chat(usr, span_notice("Now wearing as undershirt!"))
				qdel(src)
			if("Uniform")
				new /obj/item/clothing/under/poly_keyholesweater(usr.loc)
				for(var/obj/item/clothing/under/poly_keyholesweater/U in usr.loc)
					U.color = src.color
					U.name = src.name
					U.desc = src.desc
				to_chat(usr, span_notice("Now wearing as uniform!"))
				qdel(src)
