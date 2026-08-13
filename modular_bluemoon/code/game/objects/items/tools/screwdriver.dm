// Перенос с оффов ТГ (Скайратов) Т2 инструментов для учёных от nopeingeneer и доделано мною.
/obj/item/screwdriver/power/science
	name = "research hand dril"
	desc = "This one sports a nifty science paintjob, but is otherwise normal."
	icon = 'modular_bluemoon/phenyamomota/icon/obj/tools.dmi'
	icon_state = "drill_sci_screw"
	item_state = "drill_sci"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/equipment/tools_righthand.dmi'
	toolspeed = 0.5

/obj/item/screwdriver/power/science/attack_self(mob/user)
	playsound(get_turf(user),'sound/items/change_drill.ogg',50,1)
	var/obj/item/wrench/power/science/s_drill = new /obj/item/wrench/power/science(drop_location())
	to_chat(user, "<span class='notice'>You attach the bolt driver bit to [src].</span>")
	qdel(src)
	user.put_in_active_hand(s_drill)

//////////////////////////////////////////////
