GLOBAL_LIST_EMPTY(meteor_satellites) // BLUEMOON ADD - список всех противометеоритных спутников
/// Только для вызова get_coverage() в UI, когда цель станции не выбрана (не в station_goals).
GLOBAL_DATUM_INIT(shield_goal_coverage_dummy, /datum/station_goal/station_shield, new)

//Station Shield
// A chain of satellites encircles the station
// Satellites be actived to generate a shield that will block unorganic matter from passing it.
/datum/station_goal/station_shield
	name = "Station Shield"
	var/coverage_goal = 5000 // один средне расположенный спутник покрывает больше 1000 тайлов.

/datum/station_goal/station_shield/can_be_selected()
	. = ..()
	if(SSmapping.config.planetary)
		return FALSE

/datum/station_goal/station_shield/get_report()
	return {" <b>Сооружение щитов станции</b><br>
			Станция находится в зоне, полной космического мусора.
			У нас есть прототип системы защиты, которую вы должны развернуть, чтобы уменьшить количество несчастных случаев, связанных с столкновениями.
			<br><br>
			Спутники и системы управления доступны к заказу в карго."}


/datum/station_goal/station_shield/on_report()
	//Unlock
	var/datum/supply_pack/P = SSshuttle.supply_packs[/datum/supply_pack/engineering/shield_sat]
	P.special_enabled = TRUE

	P = SSshuttle.supply_packs[/datum/supply_pack/engineering/shield_sat_control]
	P.special_enabled = TRUE

/datum/station_goal/station_shield/check_completion()
	if(..())
		return TRUE
	if(get_coverage() >= coverage_goal)
		return TRUE
	return FALSE

/datum/station_goal/proc/get_coverage()
	var/list/coverage = list()
	for(var/obj/machinery/satellite/meteor_shield/A in GLOB.machines)
		if(!A.active || !is_station_level(A.z))
			continue
		coverage |= view(A.kill_range,A)
	var/counter = 0
	counter += count_by_type(coverage, /turf/open/space)
	counter += count_by_type(coverage, /turf/open/openspace) // for multi-z stations
	return counter

/obj/machinery/computer/sat_control
	name = "satellite control"
	desc = "Used to control the satellite network."
	circuit = /obj/item/circuitboard/computer/sat_control
	var/notice

/obj/machinery/computer/sat_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SatelliteControl", name)
		ui.open()

/obj/machinery/computer/sat_control/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("toggle")
			toggle(text2num(params["id"]))
			. = TRUE

/obj/machinery/computer/sat_control/proc/toggle(id)
	for(var/obj/machinery/satellite/S in GLOB.machines)
		if(S.id == id && S.z == z)
			S.toggle()

/obj/machinery/computer/sat_control/ui_data()
	var/list/data = list()

	data["satellites"] = list()
	for(var/obj/machinery/satellite/S in GLOB.machines)
		data["satellites"] += list(list(
			"id" = S.id,
			"active" = S.active,
			"mode" = S.mode
		))
	data["notice"] = notice

	if(locate(/obj/machinery/satellite/meteor_shield) in GLOB.machines)
		data["meteor_shield"] = 1
		var/datum/station_goal/station_shield/G = SSticker.mode && locate() in SSticker.mode.station_goals
		var/datum/station_goal/station_shield/coverage_src = G || GLOB.shield_goal_coverage_dummy
		data["meteor_shield_coverage"] = coverage_src.get_coverage()
		data["meteor_shield_coverage_max"] = coverage_src.coverage_goal
	return data


/obj/machinery/satellite
	name = "\improper Defunct Satellite"
	desc = ""
	icon = 'icons/obj/machines/satellite.dmi'
	icon_state = "sat_inactive"
	anchored = FALSE
	density = TRUE
	use_power = FALSE
	armor = list(MELEE = 25, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 50, ACID = 70)
	var/mode = "NTPROBEV0.8"
	var/active = FALSE
	var/static/gid = 1
	var/id = 0
	// BLUEMOON ADD START
	var/obj/machinery/camera/emp_proof/satellite/camera = null // камера для просмотра спутника
	var/updating = FALSE
	var/camera_c_tag_prefix = "Orbital Satellite"
	var/oldLoc

	var/obj/item/radio/radio // рация и всё с ней связанное
	var/radio_key = /obj/item/encryptionkey/headset_eng
	var/engineering_channel = "Engineering"

	var/roundstart = FALSE // если спутник с начала раунда, то он сразу же активируется и его камера включается. Важно разместить спутник в космосе при этом

	var/list/destruction_quotes = list(\
	"Шанс уничтожения спутника - 100 процентов. Аварийное отключение.", "Повреждение критических систем, последняя передача.", \
	"Спутник уничтожен, рапорт отправлен.", "SOS! SYSTEM MALFUNCTION!", "Критическая потеря целостности, невозможно поддерживать работу.", \
	"Потеря спутника неминуема, требуется помощь.", "Юнит потерян.")
	// BLUEMOON ADD END

// BLUEMOON ADD START
/obj/machinery/camera/emp_proof/satellite // специальный тип камеры с увеличенным радиусом для спутников и ЭМИ защитой
	view_range = 14
	start_active = TRUE
	use_power = NO_POWER_USE // Камера в космосе не обновляется, если потребляет энергию
// BLUEMOON ADD END

/obj/machinery/satellite/Initialize(mapload)
	. = ..()
	GLOB.meteor_satellites += src
	id = gid++
	// BLUEMOON ADD START
	name = "[name] #[id]"
	radio = new (src) // спавн рации
	radio.keyslot = new radio_key
	radio.listening = 0
	radio.recalculateChannels()

	camera = new (src) // спавн камеры
	camera.c_tag = "[camera_c_tag_prefix] #[id]"
	camera.toggle_cam(null, FALSE)
	if(roundstart)
		toggle()
	oldLoc = get_turf(src)
	// BLUEMOON ADD END

// BLUEMOON ADD START
/obj/machinery/satellite/Destroy() // сообщение в рацию о нарушении целостности, а также удаление камеры
	if(active)
		radio.talk_into(src, scramble_message_replace_chars("[pick(destruction_quotes)] Координаты: [x], [y]", 5), engineering_channel)
	QDEL_NULL(camera)
	QDEL_NULL(radio)
	GLOB.meteor_satellites -= src
	explosion(loc, 1, 2, 3, 3, TRUE, TRUE)
	. = ..()

/obj/machinery/satellite/proc/malfunction(var/malfunction_type = "electrical storm")
	switch(malfunction_type)
		if("electrical storm")
			qdel(src)

/obj/machinery/satellite/examine(mob/user)
	. = ..()
	. += span_warning("It contains enough elements to keep its automatious work for ten years, but also has enough explosive power to act as a small grenade in case of destruction.")
	. += span_info("It is in [active ? "<b>active state</b>. Its space laser pokes at a side." : "<b>unactive and movable state</b>"]")
	if(active && camera)
		. += span_info("It has a small camera's bulp at its upper part. Maybe someone watch you right now.")

// Обновление камеры
/obj/machinery/satellite/Moved(oldLoc, dir)
	. = ..()
	update_camera_location(oldLoc)

/obj/machinery/satellite/forceMove(atom/destination)
	. = ..()
	//Only bother updating the camera if we actually managed to move
	if(.)
		update_camera_location(destination)

/obj/machinery/satellite/proc/update_camera_location(oldLoc)
	oldLoc = get_turf(oldLoc)
	if(!QDELETED(camera) && !updating && oldLoc != get_turf(src))
		updating = TRUE
		addtimer(CALLBACK(src, PROC_REF(update_camera), oldLoc), 10)

/obj/machinery/satellite/proc/update_camera(oldloc)
	if(!QDELETED(camera) && oldLoc != get_turf(src))
		GLOB.cameranet.updatePortableCamera(camera)
	updating = FALSE

// BLUEMOON ADD END

/obj/machinery/satellite/interact(mob/user)
	toggle(user)

/obj/machinery/satellite/proc/toggle(mob/user)
	if(!active && !isinspace())
		if(user)
			to_chat(user, "<span class='warning'>You can only activate [src] in space.</span>")
		return FALSE
	if(user)
		to_chat(user, "<span class='notice'>You [active ? "deactivate": "activate"] [src].</span>")
	active = !active
	camera.toggle_cam(null, FALSE) // BLUEMOON ADD - включение или выключение камеры
	if(active)
		animate(src, pixel_y = 2, time = 10, loop = -1)
		anchored = TRUE
	else
		animate(src, pixel_y = 0, time = 10)
		anchored = FALSE
	update_icon()

/obj/machinery/satellite/update_icon_state()
	icon_state = active ? "sat_active" : "sat_inactive"

/obj/machinery/satellite/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_MULTITOOL)
		to_chat(user, "<span class='notice'>// NTSAT-[id] // Mode : [active ? "PRIMARY" : "STANDBY"] //[(obj_flags & EMAGGED) ? "DEBUG_MODE //" : ""]</span>")
	else
		return ..()

/obj/machinery/satellite/meteor_shield
	name = "\improper Point-Defence Satellite"
	desc = "A meteor point-defense satellite. Best to place in range of 10-20 meters from the hull to have more coverage."
	mode = "M-SHIELD"
	speed_process = TRUE
	var/kill_range = 20 // BLUEMOON CHANGES (было 14)
	density = 0

	// BLUEMOON ADD START
	camera_c_tag_prefix = "Anti-Meteor Satellite"
	var/kill_counter = 0 // сколько было уничтоженных метеоритов
	var/last_major_firing_contact = 0 // Время в формате WORLD с последнего крупного метеоритного дождя
	var/list/new_contacts_quotes = list(\
	"Бомбардировка активна, открываем огонь", "Системы в норме. Ведётся обстрел", "Космические объекты в зоне видимости, открываем огонь", \
	"Орбитальная защита активирована, обнаружены цели", "Активация лазера, обнаружены цели", "Калибровка прицела, метеориты в зоне досягаемости", \
	"Защита сектора в процессе, метеоритный дождь подтверждён", "Защитные системы активированы", "Метеоритный дождь обнаружен, активация лазера", \
	"Отключение предохранителя, обнаружены метеориты", "Прекратить ВКД - активация противометеоритной защиты")
	var/list/kill_quotes = list(\
	"Ведём бой", "Метеорит уничтожен", "Цель ликвидирована", "Охлаждение лазера", "Ведётся противометеоритная борьба", "Охлаждение батареи", \
	"Метеорит расколот", "Открываю огонь", "Открытие радиаторов", "Бомбадировка продолжается", "Сканирование сектора", "Цель уничтожена")
	// BLUEMOON ADD END

// BLUEMOON ADD START - добавление спутника в глобальный список спутников
/obj/machinery/satellite/meteor_shield/Initialize(mapload)
	. = ..()
	GLOB.meteor_satellites += src
	camera.view_range = kill_range

/obj/machinery/satellite/meteor_shield/examine(mob/user)
	. = ..()
	if(active)
		. += span_info("You see a minimalistic kill-counter on its side. It says <b>\"[kill_counter]\"</b>.")
// BLUEMOON ADD END

/obj/machinery/satellite/meteor_shield/sci
	name = "\improper Meteor Shield Satellite"
	desc = "A station made meteor point-defense satellite."
	mode = "M-SHIELD"

/obj/item/disk/meteor
	name = "Meteor Shield Upgrade Disk"
	desc = "A floppy disk that allows meteor shields to fire at longer ranges and lowers meteor drawing from gravitational fields.."

/obj/machinery/satellite/meteor_shield/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/disk/meteor))
		to_chat(user, "<span class='notice'>The disk uploads better tracking and rang modification software.</span>")
		kill_range += 10 // BLUEMOON CHANGES (было = 17)
		camera.view_range = kill_range // BLUEMOON ADD - увеличение радиуса обзора камеры
	else
		return ..()

/obj/machinery/satellite/meteor_shield/sci/toggle(user)
	if(!..(user))
		return FALSE
	if(obj_flags & EMAGGED)
		if(active)
			change_meteor_chance(8)
		else
			change_meteor_chance(0.125)

/obj/machinery/satellite/meteor_shield/proc/space_los(meteor)
	for(var/turf/T in getline(src,meteor))
		if(!isspaceturf(T))
			return FALSE
	return TRUE

/obj/machinery/satellite/meteor_shield/process()
	if(!active)
		return
	for(var/obj/effect/meteor/M in GLOB.meteor_list)
		if(M.z != z)
			continue
		if(get_dist(M,src) > kill_range)
			continue
		if(!(obj_flags & EMAGGED) && space_los(M))
			Beam(get_turf(M),icon_state="sat_beam",time=5,maxdistance=kill_range)
			// BLUEMOON ADD START - добавление сообщения в рацию после каждых 3 уничтоженных метеоритов
			kill_counter++
			if(kill_counter % 3 == 0) // За каждые 3 уничтоженных метеорита - оповещение о начале шторма
				if(world.time >= last_major_firing_contact + 20 MINUTES)
					radio.talk_into(src, "[pick(new_contacts_quotes)].", engineering_channel)
					last_major_firing_contact = world.time
				else if(kill_counter % 6 == 0) // Каждые 6 уничтоженных метеорита - оповещение
					radio.talk_into(src, "[pick(kill_quotes)].", engineering_channel)
			// BLUEMOON ADD END
			qdel(M)
			break // BLUEMOON ADD - по 1 метеориту за тик

/obj/machinery/satellite/meteor_shield/toggle(user)
	if(!..(user))
		return FALSE
	if(obj_flags & EMAGGED)
		if(active)
			change_meteor_chance(2)
		else
			change_meteor_chance(0.5)

/obj/machinery/satellite/meteor_shield/proc/change_meteor_chance(mod)
	var/datum/round_event_control/E = locate(/datum/round_event_control/meteor_wave) in SSevents.control
	if(E)
		E.weight *= mod

/obj/machinery/satellite/meteor_shield/Destroy()
	. = ..()
	if(active && (obj_flags & EMAGGED))
		change_meteor_chance(0.5)

/obj/machinery/satellite/meteor_shield/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	obj_flags |= EMAGGED
	to_chat(user, "<span class='notice'>You access the satellite's debug mode, increasing the chance of meteor strikes.</span>")
	if(active)
		change_meteor_chance(4)
	return TRUE
