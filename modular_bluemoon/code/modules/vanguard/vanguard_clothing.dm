// ============================================
// Базовые наборы брони
// ============================================

/obj/item/clothing/suit/space/vanguard
	name = "Vanguard EVA suit"
	desc = "Укреплённый тонколистыми сплавами и молитвами стандартный костюм для иследования космоса эксадронов Авангарда"
	armor = list(MELEE = 20, BULLET = 15, LASER = 15, ENERGY = 0, BOMB = 35, BIO = 100, RAD = 20, FIRE = 50, ACID = 65, WOUND = 20)
	icon_state = "hardsuit-explorer"
	item_state = "hardsuit-explorer"
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/suit_digi.dmi'
	tail_state = "bombsuit_sci"
	slowdown = 0.2


/obj/item/clothing/head/helmet/space/vanguard
	name = "Vanguard EVA helmet"
	desc = "Укреплённый тонколистыми сплавами и молитвами стандартный щлем для иследования космоса эксадронов Авангарда"
	icon_state = "hardsuit0-explorer"
	item_state = "hardsuit0-explorer"
	armor = list(MELEE = 20, BULLET = 15, LASER = 15, ENERGY = 0, BOMB = 35, BIO = 100, RAD = 20, FIRE = 50, ACID = 65, WOUND = 20)
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/head.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/head_muzzled.dmi'

/obj/item/clothing/head/helmet/space/hardsuit/exploration
	name = "Ranger hardsuit helmet"
	desc = "An advanced helmet that will protect you from space and other threats."
	icon_state = "hardsuit0-exploration"
	item_state = "hardsuit0-exploration"
	armor = list(MELEE = 35, BULLET = 30, LASER = 30, ENERGY = 10, BOMB = 50, BIO = 100, RAD = 50, FIRE = 75, ACID = 65, WOUND = 35)
	brightness_on = 12
	hardsuit_type = "exploration"
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/hats.dmi'

/obj/item/clothing/suit/space/hardsuit/exploration
	icon_state = "hardsuit-exploration"
	item_state = "hardsuit-exploration"
	name = "Ranger hardsuit"
	desc = "An advanced suit that will protect you from space and other threats."
	slowdown = 0
	armor = list(MELEE = 35, BULLET = 30, LASER = 30, ENERGY = 10, BOMB = 50, BIO = 100, RAD = 50, FIRE = 75, ACID = 65, WOUND = 35)
	allowed = list(/obj/item/gun, /obj/item/ammo_box, /obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/transforming/energy/sword/saber, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/exploration
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/suit.dmi'

/obj/item/clothing/suit/armor/vanguard
	name = "Combined suit "
	desc = "A combined armor set used by the Vanguard squadrons. The combination of movable plates and kevlar fabrics made it equally ineffective against firearms and blunt force, but it’s better than nothing."
	icon_state = "combined"
	item_state = "combined"
	slowdown = 0.1
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	armor = list(MELEE = 35, BULLET = 35, LASER = 35, ENERGY = 35, BOMB = 25, BIO = 0, RAD = 0, FIRE = 80, ACID = 80, WOUND = 30)
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'

/obj/item/clothing/head/helmet/vanguard
	name = "Combined helmet"
	desc = "Someone just take old Altyn helmet, recolor it, and strap some shutter-proof glass,"
	icon_state = "combined"
	item_state = "combined"
	can_flashlight = 0
	toggle_message = "You pull the visor down on"
	alt_toggle_message = "You push the visor up on"
	can_toggle = 1
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	strip_delay = 80
	actions_types = list(/datum/action/item_action/toggle)
	visor_flags_inv = HIDEFACE
	toggle_cooldown = 0
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	visor_flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	clothing_flags = null
	dynamic_hair_suffix = ""
	dynamic_fhair_suffix = ""
	dog_fashion = null
	mutantrace_variation = STYLE_MUZZLE
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/head_muzzled.dmi'
	armor = list(MELEE = 35, BULLET = 35, LASER = 35, ENERGY = 35, BOMB = 25, BIO = 0, RAD = 0, FIRE = 80, ACID = 80, WOUND = 30)
	is_edible = 0
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/head.dmi'
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'

// я не знаю куда пихать наборы классов, поэтому пихну их сюда

/obj/item/storage/belt/military/assault/demolition/PopulateContents()
	new /obj/item/wrench/caravan(src)
	new /obj/item/screwdriver/caravan(src)
	new /obj/item/wirecutters/caravan(src)
	new /obj/item/crowbar/red/caravan(src)
	new /obj/item/weldingtool/hugetank(src)
	new /obj/item/multitool(src)

/obj/item/storage/belt/military/assault/surgeon/PopulateContents()
	new /obj/item/scalpel/upgraded_t2(src)
	new /obj/item/circular_saw/upgraded_t2(src)
	new /obj/item/retractor/upgraded_t2(src)
	new /obj/item/hemostat/upgraded_t2(src)
	new /obj/item/cautery/upgraded_t2(src)
	new /obj/item/surgical_drapes(src)

/obj/item/armorkit/vanguard/vest
	name = "Combined armor kit"
	desc = "Стандартизированный эскадронами Авангарда набор гибких бронепластин и тюбиков нано-клея. Данная вариация предназначена для укрепления верхней одежды."
	parent_armor_type = /obj/item/clothing/suit/armor/vanguard
	kit_slot_flag = ITEM_SLOT_OCLOTHING
	kit_prefix = "combined"

/obj/item/armorkit/vanguard/helmet
	name = "Combined headgear kit"
	desc = "Стандартизированный эскадронами Авангарда набор гибких бронепластин и тюбиков нано-клея. Данная вариация предназначена для укрепления головных уборов."
	parent_armor_type = /obj/item/clothing/head/helmet/vanguard
	kit_slot_flag = ITEM_SLOT_HEAD
	kit_prefix = "combined"
