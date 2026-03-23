/obj/item/clothing/mask/durak
	name = "Fools Village Clown Mask"
	desc = "For the Samogon!"
	icon_state = "durak"
	item_state = "durak"

/obj/item/clothing/mask/kindle
	name = "Kindred`s mask"
	desc = "Wooden mask with strange blue glow"
	icon = 'modular_bluemoon/icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/masks.dmi'
	icon_state = "kindle"

/obj/item/clothing/mask/balaclava/breath/hijab
	name = "Polychromic Hijab"
	desc = "Inshallah"
	icon_state = "hijab_he"
	item_state = "hijab"
	icon = 'modular_bluemoon/icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/masks.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/mask_muzzled.dmi'
	flags_inv = HIDEFACE|HIDEFACIALHAIR|HIDEEARS|HIDEHAIR
	visor_flags_inv = HIDEFACE|HIDEFACIALHAIR
	mutantrace_variation = STYLE_MUZZLE|STYLE_NO_ANTHRO_ICON
	clothing_flags = ALLOWINTERNALS
	actions_types = list(/datum/action/item_action/adjust)
	var/list/poly_colors = list("#ffffff")

/obj/item/clothing/mask/balaclava/breath/hijab/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/polychromic, poly_colors, 1)

/obj/item/clothing/mask/muzzle/mouthring
	name = "Mouth ring"
	desc = "Provides oral plessure without partner`s consent."
	icon = 'modular_bluemoon/icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/masks.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/mask_muzzled.dmi'
	icon_state = "mouthring"
	item_state = "mouthring"
	flags_cover = null // рот открыт

/obj/item/clothing/mask/gas/sechailer/mopp
	mutantrace_variation = STYLE_MUZZLE
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/mask_muzzled.dmi'

/obj/item/clothing/mask/transparent_mask
	name = "transparent mask"
	desc = "A transparent mask, made for concubines and belly dancers!"
	icon = 'modular_bluemoon/icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/mask.dmi'
	icon_state = "transparent_mask"

/obj/item/clothing/mask/carnival
	name = "carnival mask"
	desc = "For special occasions!"
	icon = 'modular_bluemoon/icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/mask.dmi'
	icon_state = "carnival"
	flags_inv = HIDEFACE
	visor_flags_inv = HIDEFACE

/obj/item/clothing/mask/muzzle/rag_gag
	name = "rag gag"
	desc = "To stop that awful noise, but dirty."
	icon = 'modular_bluemoon/icons/obj/clothing/masks.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/mask.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/mask.dmi'
	icon_state = "raggag"
	item_state = "raggag"

/obj/item/clothing/mask/muzzle/rag_gag/verb/make_rag()
	set name = "Make rag"
	set category = "Object"
	set src in usr
	if(iscarbon(usr) && usr.get_item_by_slot(ITEM_SLOT_MASK) == src)
		to_chat(span_notice("You must take it off first!"))
		return
	else
		new /obj/item/reagent_containers/rag(usr.loc)
		qdel(src)

/obj/item/reagent_containers/rag/verb/make_gag()
	set name = "Make gag"
	set category = "Object"
	set src in usr

	new /obj/item/clothing/mask/muzzle/rag_gag(usr.loc)
	qdel(src)
