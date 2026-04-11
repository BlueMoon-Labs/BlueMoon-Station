/obj/effect/spawner/xeno_egg_delivery
	name = "xeno egg delivery"
	icon = 'icons/Xeno/Effects.dmi'
	icon_state = "egg_hugger1"
	var/announcement_time = 10000

/obj/effect/spawner/xeno_egg_delivery/Initialize(mapload)
	. = ..()
	if(GLOB.master_mode == "Extended")
		var/turf/T = get_turf(src)

		new /obj/structure/alien/egg(T)
		new /obj/item/book_of_babel(T)
		new /obj/item/book_of_babel(T)
		new /obj/effect/temp_visual/gravpush(T)
		playsound(T, 'sound/items/party_horn.ogg', 50, 1, -1)

		message_admins("An alien egg has been delivered to [ADMIN_VERBOSEJMP(T)].")
		log_game("An alien egg has been delivered to [AREACOORD(T)]")
		var/message = "Внимание, [station_name()]. К вашему сектору были закреплены яйца ксеноморфов с изменениями под проект Ксено-Горничных, в том числе частичная пацификация в виде смягчённой агрессии. Примерное местоположение - [get_area_name(T, TRUE)]. Соблюдайте все меры предосторожности при работе с образцом."
		SSticker.OnRoundstart(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(_addtimer), CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(print_command_report), message), announcement_time))
		return INITIALIZE_HINT_QDEL
	else
		return
