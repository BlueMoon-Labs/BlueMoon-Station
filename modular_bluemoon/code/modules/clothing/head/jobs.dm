/obj/item/clothing/head/utilcover
	name = "utility cover"
	desc = "An utility cover used by various forces. Uses reinforced fabric to offer sufficient protection."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/head_muzzled.dmi'
	icon_state = "utilcovergrey"
	armor_type = /datum/armor/armored_headgear
	strip_delay = 60
	dog_fashion = null
	unique_reskin = list(
		"Urban" = list(
			RESKIN_ICON_STATE = "utilcovergrey",
			RESKIN_ITEM_STATE = "utilcovergrey"
		),
		"Green" = list(
			RESKIN_ICON_STATE = "utilcovergreen",
			RESKIN_ITEM_STATE = "utilcovergreen"
		),
		"Tan" = list(
			RESKIN_ICON_STATE = "utilcovertan",
			RESKIN_ITEM_STATE = "utilcovertan"
		),
		"Navy" = list(
			RESKIN_ICON_STATE = "utilcovernavy",
			RESKIN_ITEM_STATE = "utilcovernavy"
		),
	)
