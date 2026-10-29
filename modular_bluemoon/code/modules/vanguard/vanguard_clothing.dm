// ============================================
// Базовые наборы брони
// ============================================

/obj/item/clothing/suit/space/vanguard
	name = "vanguard EVA suit"
	desc = "Укреплённый тонколистыми сплавами и молитвами стандартный костюм для иследования космоса эксадронов Авангарда"
	armor_type = /datum/armor/spacesuit_vanguard
	icon_state = "hardsuit-explorer"
	item_state = "hardsuit-explorer"
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/suit_digi.dmi'
	tail_state = "bombsuit_sci"
	slowdown = 0.2

/obj/item/clothing/suit/space/vanguard/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/storage = AddComponent(/datum/component/storage/concrete)
	storage.max_items = 5

/obj/item/clothing/head/helmet/space/vanguard
	name = "vanguard EVA helmet"
	desc = "Укреплённый тонколистыми сплавами и молитвами стандартный шлем для иследования космоса эксадронов Авангарда"
	icon_state = "hardsuit0-explorer"
	item_state = "hardsuit0-explorer"
	armor_type = /datum/armor/spacesuit_vanguard
	mob_overlay_icon = 'modular_sand/icons/mob/clothing/head.dmi'
	icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi'
	anthro_mob_worn_overlay = 'modular_sand/icons/mob/clothing/head_muzzled.dmi'

/obj/item/clothing/head/helmet/space/hardsuit/exploration
	name = "ranger hardsuit helmet"
	desc = "Выдвижной шлем скафандра Авангарда для истинных интровертов эскадрона."
	icon_state = "hardsuit0-exploration"
	item_state = "hardsuit0-exploration"
	armor_type = /datum/armor/hardsuit_security
	brightness_on = 12
	hardsuit_type = "exploration"
	obj_flags = NOT_VISIBLE_IN_STORAGE
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/hats.dmi'

/obj/item/clothing/suit/space/hardsuit/exploration
	icon_state = "hardsuit-exploration"
	item_state = "hardsuit-exploration"
	name = "Ranger hardsuit"
	desc = "Продвинутый скафандр для защиты от космоса, его угроз, шальных пуль членов эскадрона и пролитого виски."
	slowdown = 0.5
	armor_type = /datum/armor/hardsuit_security
	brc_mitigation_bonus = 10  // BLUEMOON ADD
	allowed = list(/obj/item/gun, /obj/item/ammo_box, /obj/item/ammo_casing, /obj/item/melee/baton, /obj/item/melee/transforming/energy/sword/saber, /obj/item/restraints/handcuffs, /obj/item/tank/internals)
	helmettype = /obj/item/clothing/head/helmet/space/hardsuit/exploration
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/suit.dmi'

/obj/item/clothing/suit/space/hardsuit/exploration/ComponentInitialize()
	. = ..()
	var/datum/component/storage/concrete/storage = AddComponent(/datum/component/storage/concrete/ranger_hardsuit)
	storage.max_items = 5

/obj/item/clothing/suit/armor/vanguard
	name = "combined suit"
	desc = "Комбенизон для эскадронов Авангарда. Комбинирование подвижных пластин и кевлара сделало его одинаково убогим что против пуль, что против ударов, но это лучше, чем ничего."
	icon_state = "combined"
	item_state = "combined"
	slowdown = 0.1
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS
	armor_type = /datum/armor/clothing_vanguard
	brc_mitigation_bonus = 15  // BLUEMOON ADD
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'

/obj/item/clothing/head/helmet/vanguard
	name = "combined helmet"
	desc = "Кто-то просто взял старый Алтын, перекрасил, и присобачил ударопрочное стекло?"
	icon_state = "combined"
	item_state = "combined"
	can_flashlight = 0
	toggle_message = "Вы опустили визор"
	alt_toggle_message = "Вы подняли визор"
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
	armor_type = /datum/armor/clothing_vanguard
	is_edible = 0
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/head.dmi'
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'

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

/datum/component/storage/concrete/ranger_hardsuit/attackby(datum/source, obj/item/I, mob/user, params)
	if(istype(I, /obj/item/slimepotion) && user?.a_intent == INTENT_HARM)
		return FALSE
	return ..()

/datum/component/storage/concrete/ranger_hardsuit/can_be_inserted(obj/item/I, stop_messages = FALSE, mob/M)
	var/obj/item/clothing/suit/space/hardsuit/H = parent
	if(I == H.helmet || I == H.jetpack)
		return FALSE
	var/list/external = list()
	if(H.helmet)
		external += H.helmet
	if(H.jetpack)
		external += H.jetpack
	var/atom/real = real_location()
	var/list/remove_list = external & real.contents
	for(var/atom/movable/A in remove_list)
		A.moveToNullspace()
	. = ..()
	for(var/atom/movable/A in remove_list)
		A.forceMove(real)
	return .

/obj/item/clothing/suit/space/hardsuit/exploration/Initialize(mapload)
	. = ..()
	if(jetpack)
		jetpack.obj_flags |= NOT_VISIBLE_IN_STORAGE

/obj/item/clothing/suit/space/hardsuit/exploration/attackby(obj/item/I, mob/user, params)
	. = ..()
	if(jetpack)
		jetpack.obj_flags |= NOT_VISIBLE_IN_STORAGE
