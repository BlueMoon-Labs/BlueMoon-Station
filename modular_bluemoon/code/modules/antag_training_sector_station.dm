/area/antag_training/sector/station
	name = "Training Station Mockup"
	requires_power = TRUE
	dynamic_lighting = DYNAMIC_LIGHTING_ENABLED
	area_flags = NO_ALERTS | UNIQUE_AREA | VALID_TERRITORY | BLOBS_ALLOWED | CULTMAGIC_BYPASS

/datum/antag_training_sector
	/// Метки мест для ролей: id метки -> смещение клетки от угла слота.
	var/list/landmark_offsets = list()
	/// Метки сторон сценария: сторона -> список смещений.
	var/list/side_offsets = list()

/// Запоминает, где в шаблоне стоят метки мест для ролей и сторон сценария, и убирает сами метки.
/datum/antag_training_sector/proc/collect_landmarks()
	landmark_offsets = list()
	side_offsets = list()
	for(var/turf/tile as anything in turfs)
		for(var/obj/effect/landmark/antag_training/mark in tile)
			var/list/offset = list(tile.x - origin_x, tile.y - origin_y)
			var/obj/effect/landmark/antag_training/side/side_mark = mark
			if(istype(side_mark))
				if(!side_offsets[side_mark.side])
					side_offsets[side_mark.side] = list()
				side_offsets[side_mark.side] += list(offset)
			else
				landmark_offsets[mark.mark_id] = offset
			qdel(mark)

/// Клетка метки места для роли или null, если метки нет или сектор не готов.
/datum/antag_training_sector/proc/landmark_turf(mark_id)
	var/list/offset = landmark_offsets[mark_id]
	if(!offset || state != ANTAG_TRAINING_SECTOR_READY || !arena?.private_level)
		return null
	return locate(origin_x + offset[1], origin_y + offset[2], arena.private_level.z_value)

/datum/antag_training_sector/station
	id = "station"
	name = "Станционный макет"
	desc = "Учебная станция «Эхо-7»: коридоры с вывесками отделов, обжитые кабинеты, кабинет главы, хранилище, серверная, ядро ИИ, ритуальный зал и отсек корабля абдукторов. Место для ролей, которым нужна станция."
	map_path = "_maps/templates/antag_training/station.dmm"
	area_type = /area/antag_training/sector/station
	origin_x = 106
	origin_y = 36
	spawn_offset = list(17, 4)
	target_offset = list(21, 11)

/obj/effect/landmark/antag_training
	name = "training mark"
	var/mark_id

/obj/effect/landmark/antag_training/Initialize(mapload)
	. = ..()
	// Метки полигона не станционные: их собирает сектор, общий список их не видит.
	GLOB.landmarks_list -= src

/obj/effect/landmark/antag_training/vault
	name = "training mark: vault"
	mark_id = "vault"

/obj/effect/landmark/antag_training/ai_core
	name = "training mark: AI core"
	mark_id = "ai_core"

/obj/effect/landmark/antag_training/ritual
	name = "training mark: ritual"
	mark_id = "ritual"

/obj/effect/landmark/antag_training/head_office
	name = "training mark: head office"
	mark_id = "head_office"

/obj/effect/landmark/antag_training/abductor
	name = "training mark: abductor bay"
	mark_id = "abductor"

/obj/effect/landmark/antag_training/server
	name = "training mark: server room"
	mark_id = "server"

/obj/machinery/camera/training
	name = "training camera"
	desc = "Камера станционного макета. Изображение идёт только на учебные консоли полигона. Срезать её нельзя, а разбитая камера рамки не оставляет."
	network = list("training")

// Рамку или сборку можно было бы собрать заново и подключить к станционной сети.
/obj/machinery/camera/training/deconstruct(disassembled = TRUE)
	qdel(src)

/obj/machinery/camera/training/welder_act(mob/living/user, obj/item/tool)
	if(!panel_open)
		return FALSE
	to_chat(user, span_warning("Учебная камера вварена в стену макета: её можно только разбить."))
	return TRUE

/// Камера, собранная на полигоне, подключается только к учебной сети.
/obj/structure/camera_assembly/proc/build_training_camera(mob/user)
	state = 4
	var/obj/machinery/camera/training/built = new(loc, src)
	forceMove(built)
	built.setDir(dir)
	var/area/place = get_area(built)
	built.c_tag = "[place.name] ([rand(1, 999)])"
	GLOB.cameranet.invalidate_camera_cache()
	to_chat(user, span_notice("Камера полигона подключается только к учебной сети."))

/obj/machinery/camera/training/attackby(obj/item/held_item, mob/living/user, params)
	if((istype(held_item, /obj/item/paper) || istype(held_item, /obj/item/modular_computer/pda)) && isliving(user))
		to_chat(user, span_notice("Учебная камера не передаёт записки ИИ: её видят только консоли полигона."))
		user.DelayNextAction(CLICK_CD_MELEE)
		return
	return ..()

/obj/machinery/computer/security/training
	name = "training camera console"
	desc = "Показывает учебные камеры станционного макета. Станционная сеть отсюда не видна."
	network = list("training")

/obj/item/kirbyplants/training

/obj/item/kirbyplants/training/Initialize(mapload)
	// Без находки в горшке: в общем пуле лежит ложный ядерный диск, который улетает на станцию.
	return ..(FALSE)

/obj/structure/showcase/machinery/training_server
	name = "server rack"
	desc = "Стойка-макет серверной. Внутри пусто: к сети исследований она не подключена."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "server-on"
