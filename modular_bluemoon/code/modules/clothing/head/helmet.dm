/obj/item/clothing/head/helmet/hephaestus
	desc = "A hephaestus made by Hephaestus Industries. Comfy, reliable and, most importantly, fucking stylish! You can also apply a helmet cover for free."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "hephaestus"
	item_state = "hephaestus"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	flags_cover = null
	unique_reskin = list(
		"Basic" = list(
			RESKIN_ICON_STATE = "hephaestus",
			RESKIN_ITEM_STATE = "hephaestus"
		),
		"Green" = list(
			RESKIN_ICON_STATE = "hephaestus_green",
			RESKIN_ITEM_STATE = "hephaestus_green"
		),
		"Tan" = list(
			RESKIN_ICON_STATE = "hephaestus_tan",
			RESKIN_ITEM_STATE = "hephaestus_tan"
		),
		"Navy" = list(
			RESKIN_ICON_STATE = "hephaestus_navy",
			RESKIN_ITEM_STATE = "hephaestus_navy"
		),
		"NanoTrasen" = list(
			RESKIN_ICON_STATE = "hephaestus_nt",
			RESKIN_ITEM_STATE = "hephaestus_nt"
		),
		"PCRC" = list(
			RESKIN_ICON_STATE = "hephaestus_pcrc",
			RESKIN_ITEM_STATE = "hephaestus_pcrc"
		),
		"SAARE" = list(
			RESKIN_ICON_STATE = "hephaestus_saare",
			RESKIN_ITEM_STATE = "hephaestus_saare"
		),
		"Peacekeeper" = list(
			RESKIN_ICON_STATE = "hephaestus_peace",
			RESKIN_ITEM_STATE = "hephaestus_peace"
		),
		"Flektarn" = list(
			RESKIN_ICON_STATE = "hephaestus_flektarn",
			RESKIN_ITEM_STATE = "hephaestus_flektarn"
		),
		"Multicam" = list(
			RESKIN_ICON_STATE = "hephaestus_multicam",
			RESKIN_ITEM_STATE = "hephaestus_multicam"
		),
	)

/obj/item/clothing/head/helmet/biker
	name = "biker helmet"
	desc = "A durable biker helmet. You suddenly get unusual subtle neon retrowave vibes with a smell of blood."
	armor = list("melee" = 25, "bullet" = 10, "laser" = 30, "energy" = 30, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 30, "acid" = 0)
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "biker"
	item_state = "biker"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	flags_inv = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	flags_cover = HEADCOVERSEYES|HEADCOVERSMOUTH
	color = "#66FFFF"

/obj/item/clothing/head/helmet/biker/Initialize(mapload)
	. = ..()
	update_icon()

/obj/item/clothing/head/helmet/biker/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/spraycan_paintable)

/obj/item/clothing/head/helmet/biker/update_overlays()
	. = ..()
	var/mutable_appearance/biker_overlay = mutable_appearance(icon='modular_bluemoon/icons/obj/clothing/hats.dmi', icon_state = "biker_overlay")
	biker_overlay.appearance_flags = RESET_COLOR
	. += biker_overlay
