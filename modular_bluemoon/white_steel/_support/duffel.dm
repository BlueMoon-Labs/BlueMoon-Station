//WHITE-STEEL PORT - Модернизация дюфелей

/obj/item/storage/backpack/duffelbag/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/duffel_anti_slow) && slowdown > 0)
		slowdown = 0
		playsound(user, 'sound/items/equip/toolbelt_equip.ogg', 100, TRUE)
		to_chat(user, span_notice("Прикрепляю разгрузочно-подвесную систему к [src]."))
		add_overlay(/obj/item/duffel_anti_slow/overlay)
		qdel(W)
	else
		. = ..()

/obj/item/duffel_anti_slow
	name = "разгрузочная система для сумок"
	desc = "Разгрузочно-подвесная система для больших вещмешков, равномерно распределяющая вес и тем самым снижая нагрузку на пользователя."
	icon = 'modular_bluemoon/white/Feline/icons/duffel_anti_slow.dmi'
	icon_state = "duffel_upgrade"

/obj/item/duffel_anti_slow/overlay
	name = "разгрузочная система для сумок"
	desc = "Крепление разгрузочной системы к вещмешку."
	icon = 'modular_bluemoon/white/Feline/icons/duffel_anti_slow.dmi'
	icon_state = "duffel_overlay"
	layer = LYING_MOB_LAYER

/datum/crafting_recipe/duffel_anti_slow
	name = "Разгрузочная система для сумок"
	result = /obj/item/duffel_anti_slow
	time = 80
	reqs = list(/obj/item/stack/sheet/durathread = 2, /obj/item/stack/sheet/cloth = 4, /obj/item/stack/cable_coil = 10)
	tools = list(TOOL_WIRECUTTER, TOOL_SCREWDRIVER)
	category = CAT_CLOTHING
