	//Cybersun hardsuit

/obj/item/clothing/head/helmet/space/hardsuit/cybersun
	name = "Cybersun Hardsuit Helmet"
	desc = "Prototype hardsuit helmet with experimental armor plates, protecting from laser-based weapons very well, while giving limited protection against anything else."
	icon = 'icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'icons/mob/clothing/head.dmi'
	anthro_mob_worn_overlay = 'icons/mob/clothing/head_muzzled.dmi'
	icon_state = "hardsuit0-cybersun"
	item_state = "syndie_helm"
	hardsuit_type = "cybersun"

	armor = list("melee" = 30, "bullet" = 40, "laser" = 70, "energy" = 70, "bomb" = 30, "bio" = 100, "rad" = 60, "fire" = 60, "acid" = 60)
	strip_delay = 600
	actions_types = list()
	mutantrace_variation = STYLE_MUZZLE
	unique_reskin = null

/obj/item/clothing/suit/space/hardsuit/cybersun
	name = "Cybersun Hardsuit"
	desc = "Prototype hardsuit with experimental armor plates, protecting from laser-based weapons very well, while giving limited protection against anything else. Requires the user to activate the inner mechanism in order to unequip it, making it really difficult to take it off from somebody else."
	icon = 'icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'icons/mob/clothing/suit_digi.dmi'
	icon_state = "hardsuit-cybersun"
	item_state = "syndie_hardsuit"
	tail_state = "hos"
	hardsuit_type = "cybersun"

	armor = list("melee" = 30, "bullet" = 40, "laser" = 70, "energy" = 70, "bomb" = 30, "bio" = 100, "rad" = 60, "fire" = 60, "acid" = 60)
	strip_delay = 600
	slowdown = 0
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/cybersun
	actions_types = list(/datum/action/item_action/toggle_helmet)
	jetpack = /obj/item/tank/jetpack/suit
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_ALL_TAURIC
	unique_reskin = null

/obj/item/clothing/suit/space/hardsuit/cybersun/Initialize()
	. = ..()
	allowed = GLOB.security_hardsuit_allowed
