/obj/item/clothing/suit/armor/hecu
	name = "Powered Combat Vest"
	desc = "An electrically charged piece of body armor, the power stiffens the suit's fibers to provide a layer of resilient armor in response to trauma received from kinetic force.  It's fitted with a geiger counter, tactical radio, a heads up display and a combat cocktail injector that allows the user to function normally even after serious injury. The concentration of mass in the lower rear side from the onboard computer makes your ass feel heavy."
	icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecucloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob_digi.dmi'
	icon_state = "hecu_vest"
	item_state = "hecu_vest"
	mutantrace_variation = STYLE_DIGITIGRADE
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	cold_protection = CHEST|GROIN|ARMS|LEGS
	unique_reskin = list(
		"Basic" = list(
			RESKIN_ICON_STATE = "hecu_vest",
			RESKIN_ITEM_STATE = "hecu_vest"
		),
		"Corpsman" = list(
			RESKIN_ICON_STATE = "hecu_vest_medic",
			RESKIN_ITEM_STATE = "hecu_vest_medic"
		),
		"Basic Black" = list(
			RESKIN_ICON_STATE = "hecu_vest_black",
			RESKIN_ITEM_STATE = "hecu_vest_black"
		),
		"Corpsman Black" = list(
			RESKIN_ICON_STATE = "hecu_vest_medic_black",
			RESKIN_ITEM_STATE = "hecu_vest_medic_black"
		),
	)

/obj/item/storage/belt/military/assault/hecu
	name = "HECU warbelt"
	icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecucloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob_digi.dmi'
	icon_state = "hecu_belt"
	item_state = "hecu_belt"

/obj/item/storage/belt/military/assault/hecu/black
	name = "Black HECU warbelt"
	icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecucloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob_digi.dmi'
	icon_state = "hecu_belt_black"
	item_state = "hecu_belt_black"

/obj/item/storage/backpack/hecu
	name = "HECU Backpack"
	icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecucloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob_digi.dmi'
	icon_state = "hecu_pack"
	item_state = "hecu_pack"

/obj/item/storage/backpack/hecu/black
	name = "Black HECU Backpack"
	icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecucloth.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/hecu/hecumob_digi.dmi'
	icon_state = "hecu_pack_black"
	item_state = "hecu_pack_black"
