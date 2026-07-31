/obj/item/modkit/lapkee_arm_shield_kit
	name = "Holographic shield Kit"
	desc = "A modkit for making a arm-mounted riot shield into a Holographic shield."
	product = /obj/item/organ/cyberimp/arm/shield/sec_level/lapkee
	fromitem = list(/obj/item/organ/cyberimp/arm/shield/sec_level)

/obj/item/organ/cyberimp/arm/shield/sec_level/lapkee
	name = "Arm-mounted holographic shield"
	contents = newlist(/obj/item/shield/riot/implant/lapkee)

/obj/item/shield/riot/implant/lapkee
	name = "Holographic shield"
	desc = "Меньше вопросов! Работает и работает, не забивайте голову \"КАК\"."
	icon = 'modular_bluemoon/fluffs/icons/obj/melee.dmi'
	icon_state = "lapkee_riot_shield"
	item_state = "lapkee_riot_shield"
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/melee_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/melee_righthand.dmi'
