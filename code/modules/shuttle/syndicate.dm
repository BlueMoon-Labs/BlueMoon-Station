#define SYNDICATE_CHALLENGE_TIMER 17500 // 20 minutes

/obj/machinery/computer/shuttle/syndicate
	name = "InteQ shuttle terminal"
	desc = "The terminal used to control the InteQ transport shuttle."
	circuit = /obj/item/circuitboard/computer/syndicate_shuttle
	icon_screen = "inteqshuttle"
	icon_keyboard = "inteq_key"
	light_color = LIGHT_COLOR_ORANGE
	req_access = list(ACCESS_INTEQ)
	shuttleId = "syndicate"
	possible_destinations = "inteq_away;syndicate_z5;syndicate_ne;syndicate_nw;syndicate_n;syndicate_se;syndicate_sw;syndicate_s;syndicate_custom"
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF

/obj/machinery/computer/shuttle/syndicate/allowed(mob/M)
	if(issilicon(M) && !(ROLE_INTEQ in M.faction))
		return FALSE
	return ..()

/obj/machinery/computer/shuttle/syndicate/ui_act(action, params)
	if(!allowed(usr))
		to_chat(usr, "<span class='danger'>Доступ запрещён.</span>")
		return
	switch(action)
		if("move")
			if(istype(src, /obj/machinery/computer/shuttle/syndicate/drop_pod))
				if(!is_centcom_level(z))
					to_chat(usr, "<span class='warning'>Под уже использован!</span>")
					return
			var/obj/item/circuitboard/computer/syndicate_shuttle/board = circuit
			if(board?.challenge && world.time < SYNDICATE_CHALLENGE_TIMER)
				to_chat(usr, "<span class='warning'>Вы объявили станции Войну! Вы должны прождать [DisplayTimeText(SYNDICATE_CHALLENGE_TIMER - world.time)] перед началом атаки.</span>")
				return
			board.moved = TRUE
			// if(board?.challenge && board.moved == TRUE)
			// 	war_music()
	return ..()

// /obj/machinery/computer/shuttle/syndicate/proc/war_music()
// 	var/static/musiclimit = 0
// 	for(var/mob/H in GLOB.player_list)
// 		if(!(H.client))
// 			continue
// 		if(musiclimit >= 1)
// 			return
// 		SEND_SOUND(H, sound('modular_bluemoon/sound/ert/Nuclear_Operations.ogg'))
// 		musiclimit++

/obj/machinery/computer/shuttle/syndicate/recall
	name = "InteQ shuttle recall terminal"
	desc = "Use this if your friends left you behind."
	possible_destinations = "inteq_away"

/obj/machinery/computer/shuttle/syndicate/drop_pod
	name = "InteQ assault pod control"
	desc = "Controls the drop pod's launch system."
	icon = 'icons/obj/terminals.dmi'
	icon_state = "dorm_available"
	icon_keyboard = null
	light_color = LIGHT_COLOR_BLUE
	req_access = list(ACCESS_INTEQ)
	shuttleId = "steel_rain"
	possible_destinations = null
	clockwork = TRUE //it'd look weird

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate
	name = "InteQ Shuttle Navigation Computer"
	desc = "Used to designate a precise transit location for the syndicate shuttle."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	shuttleId = "syndicate"
	lock_override = CAMERA_LOCK_STATION
	shuttlePortId = "syndicate_custom"
	jump_to_ports = list("syndicate_ne" = 1, "syndicate_nw" = 1, "syndicate_n" = 1, "syndicate_se" = 1, "syndicate_sw" = 1, "syndicate_s" = 1)
	view_range = 5.5
	x_offset = -7
	y_offset = -1
	space_turfs_only = FALSE
	whitelist_turfs = list(/turf/open/space, /turf/open/floor/plating, /turf/open/lava, /turf/closed/mineral)
	see_hidden = TRUE

#undef SYNDICATE_CHALLENGE_TIMER
