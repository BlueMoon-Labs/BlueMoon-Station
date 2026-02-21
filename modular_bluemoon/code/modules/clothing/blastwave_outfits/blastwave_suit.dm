/obj/item/clothing/suit/armor/blastwave
	name = "blastwave trenchcoat"
	desc = "A generic trenchcoat of the boring wars."
	icon = 'modular_bluemoon/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/blastwave_suit.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/suit_digi.dmi'
	icon_state = "blastwave_suit"
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	armor = list(MELEE = 40, BULLET = 40, LASER = 40, ENERGY = 50, BOMB = 25, BIO = 0, RAD = 0, FIRE = 70, ACID = 90, WOUND = 10)
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
