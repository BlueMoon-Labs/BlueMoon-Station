/obj/item/clothing/suit/armor/blastwave
	name = "blastwave trenchcoat"
	desc = "A generic trenchcoat of the boring wars."
	icon = 'modular_bluemoon/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/blastwave_suit.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/suit_digi.dmi'
	icon_state = "blastwave_suit"
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	armor_type = /datum/armor/blastwave
	brc_mitigation_bonus = 15  // BLUEMOON ADD
	cold_protection = CHEST|GROIN|LEGS|ARMS
	heat_protection = CHEST|GROIN|LEGS|ARMS
	strip_delay = 80
	unique_reskin = list(
		"Default (Purple)" = list(
			RESKIN_ICON_STATE = "blastwave_suit",
			RESKIN_ITEM_STATE = "blastwave_suit"
		),
		"Red" = list(
			RESKIN_ICON_STATE = "blastwave_suit_r",
			RESKIN_ITEM_STATE = "blastwave_suit_r"
		),
		"Green" = list(
			RESKIN_ICON_STATE = "blastwave_suit_g",
			RESKIN_ITEM_STATE = "blastwave_suit_g"
		),
		"Blue" = list(
			RESKIN_ICON_STATE = "blastwave_suit_b",
			RESKIN_ITEM_STATE = "blastwave_suit_b"
		),
		"Yellow" = list(
			RESKIN_ICON_STATE = "blastwave_suit_y",
			RESKIN_ITEM_STATE = "blastwave_suit_y"
		)
	)
