/obj/item/clothing/head/helmet/hecu
	name = "Powered Combat Helmet"
	desc = "A deprecated combat helmet developed during the early 21th century in Sol-3, with protections rated level III-A. Contains attachment points for AN/PVS night vision goggles."
	icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecucloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob_muzzled.dmi'
	icon_state = "hecu_helm"
	item_state = "hecu_helm"
	mutantrace_variation = STYLE_MUZZLE
	flags_cover = null // Doesn't cover eyes.
	unique_reskin = list(
		"Basic" = list(
			RESKIN_ICON_STATE = "hecu_helm",
			RESKIN_ITEM_STATE = "hecu_helm"
		),
		"Corpsman" = list(
			RESKIN_ICON_STATE = "hecu_helm_medic",
			RESKIN_ITEM_STATE = "hecu_helm_medic"
		),
		"Basic Black" = list(
			RESKIN_ICON_STATE = "hecu_helm_black",
			RESKIN_ITEM_STATE = "hecu_helm_black"
		),
		"Corpsman Black" = list(
			RESKIN_ICON_STATE = "hecu_helm_medic_black",
			RESKIN_ITEM_STATE = "hecu_helm_medic_black"
		),
	)

/obj/item/clothing/mask/gas/german
	name = "Black Gas Mask"
	desc = "A black gas mask. Are you my Mummy?"
	icon_state = "m38_mask"
	item_state = "m38_mask"
	flags_inv = HIDEEARS|HIDEEYES|HIDEFACE|HIDEFACIALHAIR|HIDESNOUT
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/mask/gas/soviet
	name = "Soviet Gas Mask"
	desc = "A white gas mask with a green filter, there's a small sticker attached saying it's not got Asbestos anymore."
	alternate_screams = RUSSIAN_SCREAMS
	icon_state = "gp5_mask"
	item_state = "gp5_mask"
	flags_inv = HIDEEARS|HIDEEYES|HIDEFACE|HIDEFACIALHAIR|HIDEHAIR|HIDESNOUT
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/mask/gas/hecu
	name = "M40 gas mask"
	desc = "A deprecated field protective mask developed during the 20th century in Sol-3. It's designed to protect from chemical agents, biological agents, and nuclear fallout particles. It does not protect the user from ammonia or from lack of oxygen, though the filter can be replaced with a tube for any air tank."
	icon_state = "hecu"
	item_state = "hecu"
	flags_inv = HIDEEARS|HIDEEYES|HIDEFACE|HIDEFACIALHAIR|HIDESNOUT
