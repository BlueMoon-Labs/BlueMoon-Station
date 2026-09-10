/obj/item/choice_beacon/box/plushie/remove_bad_plushies(list/plushies)
	var/list/returned_plushies = ..()
	returned_plushies -= list(/obj/item/toy/plush/goatplushie,
		/obj/item/toy/plush/goatplushie/angry,
		/obj/item/toy/plush/goatplushie/angry/realgoat,
		/obj/item/toy/plush/realgoat,
		/obj/item/toy/plush/goatplushie/angry/kinggoat,
		/obj/item/toy/plush/goatplushie/angry/kinggoat/ascendedkinggoat,
		/obj/item/toy/plush/goatplushie/angry/guardgoat,
		/obj/item/toy/plush/goatplushie/angry/guardgoat/masterguardgoat,
		/obj/item/toy/plush/lizardplushie/saliith,
		/obj/item/toy/plush/carpplushie/dehy_carp
		)
	return returned_plushies

/obj/item/toy/plush
	obj_flags = UNIQUE_RENAME
	COOLDOWN_DECLARE(petting_heart_cooldown)

/// cube guy thing. beware, very silly
/obj/item/toy/plush/cube
	name = "Cubical plushie"
	desc = "That's one weird looking plushie."
	icon = 'modular_sand/icons/obj/plushes.dmi'
	icon_state = "cube"
	lefthand_file = 'modular_sand/icons/mob/inhands/misc/plushes_lefthand.dmi'
	righthand_file = 'modular_sand/icons/mob/inhands/misc/plushes_righthand.dmi'
	squeak_override = list('sound/effects/footstep/rustystep1.ogg' = 1)
