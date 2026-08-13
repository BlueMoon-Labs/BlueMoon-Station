// Buffs
/obj/item/crowbar/red
	desc = "A crowbar with blood-red coloring. It looks pretty robust and seems to have sharper edges than regular crowbar."
	toolspeed = 0.9

// Fix of sprite change
/obj/item/crowbar/power/syndicate/attack_self(mob/user)
	playsound(get_turf(user), 'sound/items/change_jaws.ogg', 50, 1)
	var/obj/item/wirecutters/power/syndicate/cutjaws = new /obj/item/wirecutters/power/syndicate(drop_location())
	cutjaws.name = name
	to_chat(user, "<span class='notice'>You attach the cutting jaws to [src].</span>")
	qdel(src)
	user.put_in_active_hand(cutjaws)

//////////////////////////////////////////////

// Перенос с оффов ТГ (Скайратов) Т2 инструментов для учёных от nopeingeneer и доделано мною.
/obj/item/crowbar/power/science
	name = "hybrid cutters"
	desc = "Quite similar to the jaws of life, this tool combines the utility of a crowbar and a set of wirecutters without the hydraulic force required to pry open doors."
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'
	icon_state = "jaws_sci_pry"
	item_state = "jaws_sci"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_righthand.dmi'
	toolspeed = 0.5
	can_force_powered = FALSE

/obj/item/crowbar/power/science/attack_self(mob/user)
	playsound(get_turf(user), 'sound/items/change_jaws.ogg', 50, 1)
	var/obj/item/wirecutters/power/science/cutjaws = new /obj/item/wirecutters/power/science(drop_location())
	cutjaws.name = name
	to_chat(user, "<span class='notice'>You attach the cutting jaws to [src].</span>")
	qdel(src)
	user.put_in_active_hand(cutjaws)

//////////////////////////////////////////////
