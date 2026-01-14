/obj/machinery/jukebox
	name = "jukebox"
	desc = "A classic music player."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "jukebox"
	verb_say = "states"
	density = TRUE
	req_one_access = list(ACCESS_BAR)
	payment_department = ACCOUNT_SRV
	var/jukebox_type = /datum/component/jukebox

/obj/machinery/jukebox/ComponentInitialize()
	. = ..()
	AddComponent(jukebox_type, TRUE)

/obj/machinery/jukebox/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	if(isinspace())
		return
	default_unfasten_wrench(user, I, 1 SECONDS)
	return TRUE

/obj/machinery/jukebox/disco
	name = "radiant dance machine mark IV"
	desc = "The first three prototypes were discontinued after mass casualty incidents."
	icon_state = "disco"
	anchored = FALSE
	jukebox_type = /datum/component/jukebox/disco

/obj/machinery/jukebox/disco/indestructible
	name = "radiant dance machine mark V"
	desc = "Now redesigned with data gathered from the extensive disco and plasma research."
	req_one_access = null
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	flags_1 = NODECONSTRUCT_1


//////////////////// Handled ////////////////////

/obj/item/jukebox
	name = "Handled Jukebox"
	desc = "Переносная колонка для крутых."
	icon = 'modular_citadel/icons/obj/boombox.dmi'
	righthand_file = 'modular_citadel/icons/obj/boombox_righthand.dmi'
	lefthand_file = 'modular_citadel/icons/obj/boombox_lefthand.dmi'
	item_state = "raiqbawks"
	icon_state = "raiqbawks"
	verb_say = "states"
	density = FALSE
	unique_reskin = list(
		"Black" = list(
			"icon_state" = "raiqbawks_black",
			"item_state" = "raiqbawks_black"
		)
	)

/obj/item/jukebox/ComponentInitialize()
	AddComponent(/datum/component/jukebox, FALSE, 100)
	. = ..()

/obj/item/jukebox/emagged
	name = "Handled Jukebox"
	desc = "Переносная колонка для крутых. ТЕПЕРЬ ВЗЛОМАННАЯ."
	obj_flags = EMAGGED

/obj/item/sign/moniq
	name = "Muz-TV"
	desc = "Самые топовые хиты этого сезона."
	icon = 'modular_bluemoon/icons/obj/machines/moniq.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_righthand.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/items/items_lefthand.dmi'
	item_state = "moniq"
	icon_state = "moniq"
	sign_path = /obj/structure/sign/moniq
	verb_say = "states"
	density = FALSE
	pixel_x = -8

/obj/item/sign/moniq/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/jukebox, FALSE, 100)

/obj/structure/sign/moniq
	name = "Muz-tv"
	desc = "Самые топовые хиты этого сезона."
	icon = 'modular_bluemoon/icons/obj/machines/moniq.dmi'
	icon_state = "moniq_wallmount"
	verb_say = "states"
	density = FALSE
	pixel_x = -8

/obj/structure/sign/moniq/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/jukebox, FALSE, 70)

/obj/structure/sign/moniq/MouseDrop(over_object, src_location, over_location)
	. = ..()
	if(over_object == usr && Adjacent(usr))
		if(!usr.canUseTopic(src, be_close = TRUE, no_dextery = TRUE))
			return
		usr.visible_message(span_notice("[usr] grabs and takes \the [src.name]."), span_notice("You grab and take \the [src.name]."))
		var/obj/item/moniq_item = new /obj/item/sign/moniq(loc)
		TransferComponents(moniq_item)
		usr.put_in_hands(moniq_item)
		qdel(src)
