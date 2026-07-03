// ============================================
// Базовые наборы брони
// ============================================

/obj/item/clothing/suit/space/space/eva/vanguard
	name = "Vanguard EVA suit"
	desc = "Укреплённый тонколистыми сплавами и молитвами стандартный костюм для иследования космоса эксадронов Авангарда"
	armor = list(MELEE = 20, BULLET = 15, LASER = 15, ENERGY = 0, BOMB = 35, BIO = 100, RAD = 20, FIRE = 50, ACID = 65, WOUND = 20)
	icon_state = "vanguard_eva"
	item_state = "hardsuit-explorer"
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/suit_digi.dmi'
	tail_state = "bombsuit_sci"


/obj/item/clothing/head/helmet/space/eva/vanguard
	name = "Vanguard EVA helmet"
	desc = "Укреплённый тонколистыми сплавами и молитвами стандартный щлем для иследования космоса эксадронов Авангарда"
	desc = "A lightweight space suit with the basic ability to protect the wearer from the vacuum of space during emergencies."
	icon_state = "hardsuit0-explorer"
	item_state = "hardsuit0-explorer"
	armor = list(MELEE = 20, BULLET = 15, LASER = 15, ENERGY = 0, BOMB = 35, BIO = 100, RAD = 20, FIRE = 50, ACID = 65, WOUND = 20)
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/head.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/head_muzzled.dmi'

/obj/item/clothing/head/helmet/space/hardsuit/exploration
	name = "шлем рейнджера"
	desc = "Продвинутый шлем, который спасёт от космоса и других угроз."
	icon_state = "hardsuit0-exploration"
	item_state = "hardsuit0-exploration"
	armor = list(MELEE = 35, BULLET = 25, LASER = 25, ENERGY = 10, BOMB = 50, BIO = 100, RAD = 50, FIRE = 75, ACID = 65, WOUND = 35)
	brightness_on = 12
	hardsuit_type = "exploration"
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi''
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'

/obj/item/clothing/suit/space/hardsuit/exploration
	icon_state = "hardsuit-exploration"
	item_state = "hardsuit-exploration"
	name = "костюм рейнджера"
	desc = "Продвинутый костюм, который спасёт от космоса и других угроз."
	armor = list(MELEE = 35, BULLET = 25, LASER = 25, ENERGY = 10, BOMB = 50, BIO = 100, RAD = 50, FIRE = 75, ACID = 65, WOUND = 35)
	allowed = list(/obj/item/gun, /obj/item/ammo_box, /obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/transforming/energy/sword/saber, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/exploration
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
