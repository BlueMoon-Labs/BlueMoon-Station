/obj/item/clothing/under/blastwave
	name = "blastwave uniform"
	desc = "An utilitarian uniform of rugged warfare."
	icon = 'modular_bluemoon/icons/obj/clothing/blastwave_uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniform.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/uniform_digi.dmi'
	icon_state = "blastwave_uniform"
	armor = list("melee" = 10, "bullet" = 5, "laser" = 5,"energy" = 5, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 20, "acid" = 30, "wound" = 10)
	can_adjust = FALSE
	strip_delay = 50
	alt_covers_chest = TRUE
	sensor_mode = SENSOR_COORDS
	unique_reskin = list(
		"Default (Purple)" = list(
			RESKIN_ICON_STATE = "blastwave_uniform",
			RESKIN_ITEM_STATE = "blastwave_uniform"
		),
		"Red" = list(
			RESKIN_ICON_STATE = "blastwave_uniform_r",
			RESKIN_ITEM_STATE = "blastwave_uniform_r"
		),
		"Green" = list(
			RESKIN_ICON_STATE = "blastwave_uniform_g",
			RESKIN_ITEM_STATE = "blastwave_uniform_g"
		),
		"Blue" = list(
			RESKIN_ICON_STATE = "blastwave_uniform_b",
			RESKIN_ITEM_STATE = "blastwave_uniform_b"
		),
		"Yellow" = list(
			RESKIN_ICON_STATE = "blastwave_uniform_y",
			RESKIN_ITEM_STATE = "blastwave_uniform_y"
		)
	)
