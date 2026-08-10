/obj/item/wirecutters/red
	desc = "A pair of wirecutters with extra sharp blades..."
	icon_state = "cutters_map"
	force = 9
	toolspeed = 0.9
	random_color = FALSE

// Fix of sprite change
/obj/item/wirecutters/power/syndicate/attack_self(mob/user)
	playsound(get_turf(user), 'sound/items/change_jaws.ogg', 50, 1)
	var/obj/item/crowbar/power/syndicate/pryjaws = new /obj/item/crowbar/power/syndicate(drop_location())
	pryjaws.name = name
	to_chat(user, "<span class='notice'>You attach the pry jaws to [src].</span>")
	qdel(src)
	user.put_in_active_hand(pryjaws)

//////////////////////////////////////////////

// Перенос с оффов ТГ (Скайратов) Т2 инструментов для учёных от nopeingeneer и доделано мною.
/obj/item/wirecutters/power/science
	name = "hybrid cutters"
	desc = "Quite similar to the jaws of life, this tool combines the utility of a crowbar and a set of wirecutters without the hydraulic force required to pry open doors."
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'
	icon_state = "jaws_sci_cutter"
	item_state = "jaws_sci"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_righthand.dmi'
	toolspeed = 0.5

/obj/item/wirecutters/power/science/attack_self(mob/user)
	playsound(get_turf(user), 'sound/items/change_jaws.ogg', 50, 1)
	var/obj/item/crowbar/power/science/pryjaws = new /obj/item/crowbar/power/science(drop_location())
	pryjaws.name = name
	to_chat(user, "<span class='notice'>You attach the pry jaws to [src].</span>")
	qdel(src)
	user.put_in_active_hand(pryjaws)

//////////////////////////////////////////////
