
/mob/living/silicon/robot/gib_animation()
	new /obj/effect/temp_visual/gib_animation(loc, "gibbed-r")

/mob/living/silicon/robot/dust(just_ash, drop_items, force)
	// You do not get MMI'd if you are dusted
	QDEL_NULL(mmi)
	return ..()

/mob/living/silicon/robot/spawn_dust()
	new /obj/effect/decal/remains/robot(loc)

/mob/living/silicon/robot/dust_animation()
	new /obj/effect/temp_visual/dust_animation(loc, "dust-r")

/mob/living/silicon/robot/death(gibbed)
	if(stat == DEAD)
		if(gibbed)
			dump_into_mmi()
		return
	if(gibbed)
		dump_into_mmi()
	else
		logevent("FATAL -- SYSTEM HALT")
		modularInterface.shutdown_computer()

		var/jammed = FALSE
		var/turf/position = get_turf(src)	// Проверка на воздействие джаммеров
		for(var/obj/item/jammer/jammer in GLOB.active_jammers)
			var/turf/jammer_turf = get_turf(jammer)
			if(position.z == jammer_turf.z && (get_dist(position, jammer_turf) < jammer.range))
				jammed = TRUE
				break
		if(!jammed && !emagged)	// Джаммер, или емаг акт полностью блокирует оповещения о смерти юнитов
			var/obj/machinery/announcement_system/AAS = null	// AAS my beloved
			for(var/obj/machinery/announcement_system/S in GLOB.announcement_systems)
				if(is_station_level(S.z) && S.is_operational())	// Проверка существующей на уровне станции рабочей системы оповещений
					AAS = S
					break
			if(AAS)
				var/area/A = get_area(src)
				var/message = "Зафиксирован непредвиденный отказ систем киборга в [A ? A.name : "неизвестной локации"]. Рекомендуется транспортировка в роботехнический отдел с последующим ремонтом."
				message = Gibberish(message, TRUE, 5)	// Лёгкий коррупт-эффект для вайбов, не должен мешать чтению текста
				AAS.radio?.talk_into(src, message, RADIO_CHANNEL_SCIENCE, list(SPAN_YELL))	// Броадкаст делается из радио ААС, поскольку броадкаст от имени борга натыкается на множественные ошибки, связанные с асинхронной отправкой сигнала и процессингом смерти борга
	. = ..()

	locked = FALSE //unlock cover

	update_mobility()
	if(!QDELETED(builtInCamera) && builtInCamera.status)
		builtInCamera.toggle_cam(src,0)
	toggle_headlamp(TRUE) //So borg lights are disabled when killed.

	uneq_all() // particularly to ensure sight modes are cleared

	update_icons()

	unbuckle_all_mobs(TRUE)

	SSblackbox.ReportDeath(src)
