/obj/item/clothing/head/helmet/space/hardsuit/ert/alert/hsc
	name = "HSC security unit helmet"
	desc = "Looking nice helmet for the HSC team."
	mob_overlay_icon = 'modular_bluemoon/phenyamomota/icon/mob/clothing/head.dmi'
	icon = 'modular_bluemoon/phenyamomota/icon/obj/clothing/head.dmi'
	icon_state = "hsc_helmet"
	item_state = "hsc_helmet"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	actions_types = null

/obj/item/clothing/suit/space/hardsuit/ert/alert/hsc
	name = "HSC security suit"
	desc = "Cool designed suit for the HSC team."
	mob_overlay_icon = 'modular_bluemoon/phenyamomota/icon/mob/clothing/suits.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/phenyamomota/icon/mob/clothing/suits_digi.dmi'
	icon = 'modular_bluemoon/phenyamomota/icon/obj/clothing/suits.dmi'
	icon_state = "hsc_suit"
	item_state = "hsc_suit"
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/ert/alert/hsc
	mutantrace_variation = STYLE_DIGITIGRADE
	flags_inv = HIDEGLOVES|HIDESHOES|HIDEJUMPSUIT

/obj/item/clothing/head/helmet/space/hardsuit/ert/alert/hsc/medical
	name = "HSC medical unit helmet"
	desc = "Looking nice helmet for the HSC team."
	icon_state = "hsc_helmet_med"
	item_state = "hsc_helmet_med"

/obj/item/clothing/suit/space/hardsuit/ert/alert/hsc/medical
	name = "HSC medical suit"
	desc = "Cool designed suit for the HSC team."
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/ert/alert/hsc/medical

/obj/item/clothing/head/helmet/space/hardsuit/ert/alert/hsc/assistant
	name = "HSC assistant unit helmet"
	desc = "Looking nice helmet for the HSC team."
	icon_state = "hsc_helmet_as"
	item_state = "hsc_helmet_as"

/obj/item/clothing/suit/space/hardsuit/ert/alert/hsc/assistant
	name = "HSC assistant suit"
	desc = "Cool designed suit for the HSC team."
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/ert/alert/hsc/assistant

/obj/item/clothing/mask/gas/sechailer/hsc
	name = "HSC breath mask"
	desc = "Protective breath mask."
	mob_overlay_icon = 'modular_bluemoon/phenyamomota/icon/mob/clothing/mask.dmi'
	icon = 'modular_bluemoon/phenyamomota/icon/obj/clothing/mask.dmi'
	icon_state = "hsc_mask"
	item_state = "hsc_mask"
	actions_types = list(/datum/action/item_action/halt)

/obj/item/clothing/glasses/hud/hsc
	name = "HSC advanced HUD"
	desc = "Really expensive and progressive next-generation hud-interface with combined analyzers."
	mob_overlay_icon = 'modular_bluemoon/phenyamomota/icon/mob/clothing/glasses.dmi'
	icon = 'modular_bluemoon/phenyamomota/icon/obj/clothing/glasses.dmi'
	icon_state = "hsc_hud"
	item_state = "hsc_hud"
	glass_colour_type = /datum/client_colour/glass_colour/lightblue
	var/list/hudlist = list(DATA_HUD_MEDICAL_ADVANCED, DATA_HUD_DIAGNOSTIC_ADVANCED, DATA_HUD_SECURITY_ADVANCED)

/obj/item/clothing/glasses/hud/hsc/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_EYES)
		return
	if(ishuman(user))
		for(var/hud in hudlist)
			var/datum/atom_hud/H = GLOB.huds[hud]
			H.add_hud_to(user)

/obj/item/clothing/glasses/hud/hsc/dropped(mob/user)
	. = ..()
	if(ishuman(user))
		for(var/hud in hudlist)
			var/datum/atom_hud/H = GLOB.huds[hud]
			H.remove_hud_from(user)

/obj/item/clothing/gloves/color/latex/nitrile/hsc
	name = "HSC nitrile gloves"
	desc = "Expensive sterile gloves that are stronger than kevlar. Transfers advanced paramedical knowledge to the wearer via the use of nanochips."
	mob_overlay_icon = 'modular_bluemoon/phenyamomota/icon/mob/clothing/gloves.dmi'
	icon = 'modular_bluemoon/phenyamomota/icon/obj/clothing/gloves.dmi'
	icon_state = "hsc_gloves_med"
	item_state = "hsc_gloves_med"
	transfer_prints = FALSE
	carrytrait = TRAIT_QUICKER_CARRY

/obj/item/storage/belt/military/hsc
	name = "HSC belt"
	desc = "A set of tactical webbing worn by Health Safety Control groups."
	mob_overlay_icon = 'modular_bluemoon/phenyamomota/icon/mob/clothing/belt.dmi'
	icon = 'modular_bluemoon/phenyamomota/icon/obj/clothing/belt.dmi'
	icon_state = "hsc_belt"
	item_state = "hsc_belt"
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
