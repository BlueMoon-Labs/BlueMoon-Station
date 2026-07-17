// =====================================================
// MEDIEVAL PIRATE SHUTTLE - ВРЕЗАЕТСЯ и УНИЧТОЖАЕТ
// =====================================================

/obj/docking_port/mobile/medieval
	name = "medieval assault shuttle"
	shuttle_id = "medieval"
	dwidth = 7
	dheight = 4
	width = 15
	height = 9

/obj/docking_port/mobile/medieval/check_dock(obj/docking_port/stationary/S, silent = FALSE)
	return SHUTTLE_CAN_DOCK

/obj/docking_port/mobile/medieval/initiate_docking(obj/docking_port/stationary/S1)
	if(S1 && !istype(S1, /obj/docking_port/stationary/transit))
		var/list/old_turfs = return_ordered_turfs(x, y, z, dir)
		var/list/new_turfs = return_ordered_turfs(S1.x, S1.y, S1.z, S1.dir)
		for(var/i in 1 to old_turfs.len)
			var/turf/old_turf = old_turfs[i]
			if(!isshuttleturf(old_turf))
				continue
			var/turf/impact_turf = new_turfs[i]
			if(!impact_turf)
				continue
			for(var/obj/O in impact_turf)
				qdel(O)
			impact_turf.ChangeTurf(/turf/open/floor/plating)

	. = ..()
	if(!istype(S1, /obj/docking_port/stationary/transit))
		playsound(get_turf(src.loc), 'sound/effects/explosion1.ogg', 80, TRUE)
		for(var/mob/living/M in GLOB.player_list)
			if(M.client && (M.z in SSmapping.levels_by_trait(ZTRAIT_STATION)))
				shake_camera(M, 3, 1)

/obj/docking_port/mobile/medieval/request(obj/docking_port/stationary/S)
	if(!(z in SSmapping.levels_by_trait(ZTRAIT_STATION)))
		return ..()

// =====================================================
// БАЗОВАЯ КОНСОЛЬ (с проверкой центкома)
// =====================================================

/obj/machinery/computer/shuttle/medieval
	name = "Medieval shuttle console"
	desc = "A crudely made console covered in scratches and strange runes."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	light_color = LIGHT_COLOR_RED
	req_access = list(ACCESS_SYNDICATE)
	shuttleId = "medieval"
	possible_destinations = "medieval_home;medieval_custom"
	var/used = FALSE

/obj/machinery/computer/shuttle/medieval/ui_act(action, params)
	. = ..()
	if(action != "move")
		return
	if(!allowed(usr))
		to_chat(usr, "<span class='danger'>Доступ запрещён.</span>")
		return
	if(used || !is_centcom_level(z))
		to_chat(usr, "<span class='warning'>Шаттл уже использован или не в стартовой зоне!</span>")
		return
	used = TRUE
	return ..()

// =====================================================
// КОНСОЛЬ DROP POD (TGUI, без доступа и центкома)
// =====================================================

/obj/machinery/computer/shuttle/medieval/drop_pod
	name = "Medieval assault pod control"
	desc = "Controls the medieval shuttle's launch system. Used to crash into the station."
	icon_keyboard = null
	light_color = LIGHT_COLOR_BLUE
	shuttleId = "medieval"
	possible_destinations = null
	clockwork = TRUE

/obj/machinery/computer/shuttle/medieval/drop_pod/allowed(mob/M)
	return TRUE

/obj/machinery/computer/shuttle/medieval/drop_pod/ui_act(action, params)
	if(action == "move")
		if(!possible_destinations || possible_destinations == "")
			to_chat(usr, "<span class='warning'>Нет цели для посадки! Используйте десигнатор.</span>")
			return
		return ..()
	return ..()

// =====================================================
// КАМЕРА-НАВИГАТОР
// =====================================================

/obj/machinery/computer/camera_advanced/shuttle_docker/medieval
	name = "Medieval Shuttle Navigation Computer"
	desc = "A map of the station used to designate a precise landing location."
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	shuttleId = "medieval"
	lock_override = CAMERA_LOCK_STATION
	shuttlePortId = "medieval_custom"
	x_offset = 11
	y_offset = 1
	see_hidden = FALSE
	view_range = 5.5
	space_turfs_only = FALSE
	whitelist_turfs = list(/turf/open/space, /turf/open/floor/plating, /turf/open/lava, /turf/closed/mineral)
	jump_to_ports = list()

/obj/machinery/computer/camera_advanced/shuttle_docker/medieval/Initialize(mapload)
	. = ..()
	return INITIALIZE_HINT_NORMAL

// =====================================================
// ДЕСИГНАТОР
// =====================================================

/obj/item/assault_pod/medieval
	name = "Shuttle placement designator"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "blueprints"
	desc = "A map of the station used to select where you want to land your shuttle."
	w_class = WEIGHT_CLASS_SMALL
	shuttle_id = "medieval"
	dwidth = 7
	dheight = 4
	width = 15
	height = 9
	lz_dir = 1

/obj/item/assault_pod/medieval/attack_self(mob/living/user)
	var/target_area = input(user, "Area to land", "Select a Landing Zone", null) as null|anything in GLOB.teleportlocs
	if(!target_area)
		return

	var/area/picked_area = GLOB.teleportlocs[target_area]
	if(!picked_area)
		return

	var/turf/T = safepick(get_area_turfs(picked_area))
	if(!T)
		to_chat(user, "<span class='warning'>Не найдена подходящая зона для посадки в [target_area]!</span>")
		return

	var/obj/docking_port/stationary/landing_zone = new /obj/docking_port/stationary(T)
	landing_zone.shuttle_id = "medieval([REF(src)])"
	landing_zone.name = "Landing Zone"
	landing_zone.dwidth = dwidth
	landing_zone.dheight = dheight
	landing_zone.width = width
	landing_zone.height = height
	landing_zone.dir = lz_dir

	// УДАЛЕНО: to_chat(user, "DEBUG: Port created at [T.x],[T.y] size [width]x[height]")

	if(SSshuttle.stationary)
		SSshuttle.stationary += landing_zone
		// УДАЛЕНО: to_chat(user, "DEBUG: Port added to stationary list. Total ports: [LAZYLEN(SSshuttle.stationary)]")
	else
		// УДАЛЕНО: to_chat(user, "WARNING: SSshuttle.stationary not found!")
		to_chat(user, "<span class='warning'>Не удалось зарегистрировать зону посадки!</span>")
		qdel(landing_zone)
		return

	for(var/obj/machinery/computer/shuttle/S in GLOB.machines)
		if(S.shuttleId == shuttle_id)
			if(!S.possible_destinations)
				S.possible_destinations = ""
			if(!findtext(S.possible_destinations, landing_zone.shuttle_id))
				S.possible_destinations += "[landing_zone.shuttle_id];"
			S.updateUsrDialog()

	to_chat(user, "<span class='notice'>Зона посадки установлена! Шаттл врежется в [target_area]!</span>")
	qdel(src)
