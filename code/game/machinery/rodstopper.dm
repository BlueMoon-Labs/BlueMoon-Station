/obj/item/circuitboard/machine/rodstopper
	name = "Rodstopper (Machine Board)"
	icon_state = "generic"
	build_path = /obj/machinery/rodstopper
	req_components = list(
		/obj/item/stock_parts/matter_bin = 1,
		/obj/item/stack/sheet/plasteel = 1,
	)

/obj/machinery/rodstopper
	name = "rodstopper"
	desc = "Продвинутая машина, способная остановить неподвижный стержень."
	icon = 'icons/obj/rodstopper.dmi'
	icon_state = "rodstopper"
	density = TRUE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/rodstopper
	layer = BELOW_OBJ_LAYER

/obj/machinery/rodstopper/examine(mob/user)
	. = ..()
	. += span_warning("При остановке стержня она вызовет локальный коллапс реальности - держитесь подальше!")

/obj/machinery/rodstopper/Initialize(mapload)
	. = ..()
	warn_area()

/obj/machinery/rodstopper/proc/warn_area()
	playsound(src, 'sound/misc/bloblarm_alt.ogg', 100)
	say("Внимание! Освободите помещение! Неисполнение этого требования приведёт к вашему немедленному уничтожению!")
	addtimer(CALLBACK(src, PROC_REF(warn_area)), 15 SECONDS, TIMER_OVERRIDE|TIMER_UNIQUE) // the sound is 7 seconds, however.
