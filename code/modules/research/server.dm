/// Общий множитель выработки сервера.
///
/// Убывающую отдачу от количества серверов в сети считает SSresearch.calculate_server_coefficient()
/// - sqrt(100/N) отдельно для каждой сети. Здесь раньше висела ВТОРАЯ такая кривая, персональная: сервера
/// с четвёртого получали ещё и личный штраф по позиции в списке. Две кривые перемножались, и
/// суммарный доход фермы переставал расти - пятый сервер давал станции МЕНЬШЕ очков, чем четыре
/// (≈40*ig против 46*ig). Отсюда и жалобы "чинится доп. серверами... а нет, не чинится".
/// Оставлен только прежний бонус, чтобы выработка одиночного сервера не изменилась.
#define RESEARCH_SERVER_OUTPUT_MULTIPLIER 1.2
/// Запас до верхней границы температуры, при которой сервер отключается.
#define RESEARCH_SERVER_TEMP_SHUTDOWN_MARGIN 50

/obj/machinery/rnd/server
	name = "\improper R&D Server"
	desc = "A computer system running a deep neural network that processes arbitrary information to produce data useable in the development of new technologies. In layman's terms, it makes research points."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "server"
	req_access = list(ACCESS_RD) //ONLY THE R&D CAN CHANGE SERVER SETTINGS.
	circuit = /obj/item/circuitboard/machine/rdserver

	idle_power_usage = 500
	var/datum/techweb/stored_research
	var/network_id = RND_NETWORK_AUTO			//AUTO: станция — science_tech, иначе — сеть сервера рядом, без него автономная изолированная (дефолт)
	var/techweb_type = /datum/techweb/isolated	//Тип техвеба нестанционной сети (фракционные подтипы)
	//Code for point mining here.
	var/working = TRUE			//temperature should break it.
	var/server_id = 0
	var/list/base_mining_income = list(TECHWEB_POINT_TYPE_GENERIC = 2)
	var/heat_gen = 1
	var/income_gen = 1
	var/heating_power = 40000
	var/delay = 5
	var/temp_tolerance_low = 50
	var/temp_tolerance_high = T20C
	var/temp_penalty_coefficient = 0.5	//1 = -1 points per degree above high tolerance. 0.5 = -0.5 points per degree above high tolerance.
	var/datum/looping_sound/server_alarm_small/alarmloop
	/// Сеть AUTO-сервера, выбранная по запросу соседа до LateInitialize; сам сервер потом встаёт в неё же.
	var/datum/techweb/early_network
	var/resolving_network = FALSE

/obj/machinery/rnd/server/Initialize(mapload)
	. = ..()
	GLOB.rndservers_list += src
	SSresearch.servers |= src
	alarmloop = new(src, !working)

	server_id = "[copytext(md5("[world.timeofday][rand()][src]"), 1, 5)]" // Генерируем серверу уникальный айди
	name += " ([uppertext(server_id)])"
	if(mapload)
		return INITIALIZE_HINT_LATELOAD

/obj/machinery/rnd/server/LateInitialize()
	. = ..()
	AddComponent(/datum/component/techweb_holder)
	RegisterSignal(src, COMSIG_ATOM_TECHWEB_CHANGED, PROC_REF(on_techweb_changed))
	SEND_SIGNAL(src, COMSIG_ATOM_SET_TECHWEB, get_rnd_network())
	early_network = null

/obj/machinery/rnd/server/process()
	if(!(machine_stat & NOPOWER) && working)
		produce_heat() //аргументов не принимает: раньше сюда уходил ключ ассоциативного списка
	if(get_env_temp() >= (temp_tolerance_high + RESEARCH_SERVER_TEMP_SHUTDOWN_MARGIN) || get_env_temp() <= temp_tolerance_low)
		if(working)
			working = FALSE
			play_alarm()
	else
		if(!working)
			working = TRUE
			alarmloop.stop()

/obj/machinery/rnd/server/examine() // BLUEMOON ADD
	. = ..()
	if (obj_flags & EMAGGED)
		. += "\nThe server's status light is blinking <font color='yellow'>yellow</font>."
	else if(!working)
		. += "\nThe server's status light is blinking [span_red("red")]."
	else if(machine_stat & NOPOWER)
		. += "\nThe server's status light is off."
	else
		. += "\nThe server's status light is blinking [span_green("green")]."
	if(stored_research)
		. += span_notice("Исследовательская сеть: <b>[stored_research.organization]</b>. Мультитул с пустым буфером копирует её с сервера, после чего клик по консоли или машине РнД подключает их к этой сети.")

/obj/machinery/rnd/server/Destroy()
	early_network = null
	SSresearch.servers -= src
	GLOB.rndservers_list -= src
	QDEL_NULL(alarmloop)
	return ..()

/obj/machinery/rnd/server/RefreshParts()
	var/tot_rating = 0
	for(var/obj/item/stock_parts/SP in src.component_parts)
		tot_rating += SP.rating
	heat_gen = initial(src.heat_gen) / max(1, tot_rating)
	income_gen = 1 + ((tot_rating - 1) * 0.2)
	if(obj_flags & EMAGGED) // Если емагнуто, то будет отрицательное
		income_gen *= -1

/obj/machinery/rnd/server/proc/on_techweb_changed(datum/source, datum/techweb/new_web)
	SIGNAL_HANDLER

	stored_research = new_web

/// Сеть сервера. До LateInitialize фракционная берётся по ID, AUTO выбирается сразу и запоминается: соседи при загрузке карты не зависят от порядка.
/obj/machinery/rnd/server/proc/get_rnd_network()
	if(stored_research)
		return stored_research
	if(network_id)
		return SSresearch.get_rnd_network(network_id, techweb_type)
	if(!early_network && !resolving_network)
		resolving_network = TRUE // два AUTO-сервера рядом иначе спрашивали бы друг друга по кругу
		early_network = SSresearch.get_rnd_network_for(src, network_id, techweb_type)
		resolving_network = FALSE
	return early_network

/// Сеть ближайшего РНД-сервера на любом этаже связки источника (сам источник не в счёт), либо null.
/proc/find_nearest_rnd_techweb(atom/source, max_range = INFINITY)
	var/turf/source_turf = get_turf(source)
	if(!source_turf)
		return null
	var/list/levels = SSmapping.get_connected_levels(source_turf.z)
	var/datum/techweb/nearest
	var/best_dist = INFINITY
	for(var/obj/machinery/rnd/server/S as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/rnd/server))
		if(S == source || QDELETED(S))
			continue
		var/turf/server_turf = get_turf(S)
		if(!server_turf || !(server_turf.z in levels))
			continue
		var/dist = max(abs(server_turf.x - source_turf.x), abs(server_turf.y - source_turf.y)) + abs(server_turf.z - source_turf.z)
		if(dist > max_range || dist > best_dist)
			continue
		var/datum/techweb/web = S.get_rnd_network()
		if(!web)
			continue
		best_dist = dist
		nearest = web
	return nearest

/// Авто-подключение устройства к сети: ближайший сервер на этажах связки,
/// иначе на станции — глобальная научная сеть (как раньше), вне станции — null (подключается вручную).
/proc/find_rnd_network_for_object(atom/source)
	var/datum/techweb/nearest = find_nearest_rnd_techweb(source)
	if(nearest)
		return nearest
	var/turf/source_turf = get_turf(source)
	if(source_turf && is_station_level(source_turf.z))
		return SSresearch.science_tech
	return null
//BLUEMOON ADD END

/obj/machinery/rnd/server/attackby(obj/item/W, mob/user, params)
	. = ..()
	if(. || !istype(W))
		return
	//BLUEMOON ADD: клик предметом с исследовательской сетью перепривязывает его к сети сервера
	if(istype(W, /obj/item/computermath) || istype(W, /obj/item/strangerock))
		var/datum/techweb/current_web = W.vars["linked_techweb"]
		if(current_web == stored_research)
			to_chat(user, span_notice("[W] уже подключён к [stored_research.organization]."))
		else
			W.vars["linked_techweb"] = stored_research
			to_chat(user, span_notice("Вы подключаете [W] к сети сервера [stored_research.organization]."))
		return TRUE
	return .

/obj/machinery/rnd/server/power_change()
	. = ..()
	if(machine_stat & NOPOWER)
		working = FALSE
	else
		working = TRUE

/obj/machinery/rnd/server/proc/refresh_working()
	if(machine_stat & EMPED)
		working = FALSE
	else
		working = TRUE

/obj/machinery/rnd/server/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	set_machine_stat(machine_stat | EMPED)
	addtimer(CALLBACK(src, PROC_REF(unemp)), severity*9)
	refresh_working()

/obj/machinery/rnd/server/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED || !panel_open)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	to_chat(user, "<span class='warning'>You messed with [src] research templates.</span>")
	playsound(src, "sparks", 80, 1)
	income_gen *= -1
	obj_flags |= EMAGGED
	return TRUE

/obj/machinery/rnd/server/proc/unemp()
	set_machine_stat(machine_stat & ~EMPED)
	refresh_working()

/obj/machinery/rnd/server/syndicate
	network_id = RND_NETWORK_SYNDICATE
	techweb_type = /datum/techweb/syndicate_isolated
	heating_power = 0

/obj/machinery/rnd/server/tarkoff
	network_id = RND_NETWORK_TARKON
	techweb_type = /datum/techweb/tarkoff
	heating_power = 0

/obj/machinery/rnd/server/inteq
	network_id = RND_NETWORK_INTEQ
	techweb_type = /datum/techweb/inteq
	heating_power = 0

/obj/machinery/rnd/server/proc/mine()
	. = base_mining_income.Copy()
	//Раньше множитель штрафа зависел от "схемного пола" под сервером, но DM не проверяет тип при
	//присваивании турфа в типизированную переменную - ветка была истинной на любом полу и не
	//работала ни дня. Включать скрытую механику задним числом - отдельное балансное решение.
	var/penalty = max((get_env_temp() - temp_tolerance_high), 0) * temp_penalty_coefficient
	for(var/point_type as anything in .)
		.[point_type] = max(((.[point_type] * income_gen) - penalty) * RESEARCH_SERVER_OUTPUT_MULTIPLIER, 0)

/obj/machinery/rnd/server/proc/get_env_temp()
	var/datum/gas_mixture/environment = loc.return_air()
	return environment.return_temperature()

/obj/machinery/rnd/server/proc/produce_heat()
	if(!(machine_stat & (NOPOWER|BROKEN))) //Blatently stolen from space heater.
		var/turf/L = loc
		if(istype(L))
			var/datum/gas_mixture/env = L.return_air()
			env.adjust_heat((heating_power * heat_gen)*0.8)
			air_update_turf()

/proc/fix_noid_research_servers()
	var/list/no_id_servers = list()
	var/list/server_ids = list()
	for(var/obj/machinery/rnd/server/S in GLOB.machines)
		switch(S.server_id)
			if(-1)
				continue
			if(0)
				no_id_servers += S
			else
				server_ids += S.server_id

	for(var/obj/machinery/rnd/server/S in no_id_servers)
		var/num = 1
		while(!S.server_id)
			if(num in server_ids)
				num++
			else
				S.server_id = num
				server_ids += num
		no_id_servers -= S

/obj/machinery/rnd/server/proc/play_alarm()
	if(!working)
		alarmloop.start()
		addtimer(CALLBACK(src, PROC_REF(play_alarm)), 10 SECONDS)

/datum/looping_sound/server_alarm_small // BLUEMOON ADD Ввиду того что данное будет использоваться только для серверов, располагаю немодульно. Следует модулить, если будут ещё loop'ы от нас
	mid_sounds = 'modular_bluemoon/kovac_shitcode/sound/ambience/enc/alarm_small_09.ogg'
	mid_length = 60
	volume = 5

//////////////////////////

/obj/machinery/computer/rdservercontrol
	name = "R&D Server Controller"
	desc = "Used to manage access to research and manufacturing databases."
	icon_screen = "generic"
	icon_keyboard = "rd_key"
	circuit = /obj/item/circuitboard/computer/rdservercontrol

/obj/machinery/computer/rdservercontrol/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RDServerControl", name)
		ui.open()

/// Единый предикат доступности сервера: статус карточки и счётчик онлайн-серверов
/// должны использовать одно и то же условие, иначе обесточенный сервер с working = TRUE
/// попадёт в сводку как работающий.
/obj/machinery/computer/rdservercontrol/proc/is_server_online(obj/machinery/rnd/server/server)
	return server.working && !(server.machine_stat & (NOPOWER|BROKEN|EMPED))

/obj/machinery/computer/rdservercontrol/ui_data(mob/user)
	var/list/data = list()
	var/list/server_data = list()
	var/list/networks = list()
	var/list/working_servers_by_network = list()
	var/list/income_by_network = list()
	var/online_servers = 0
	var/total_income = 0
	var/index = 0

	// Считаем работающие серверы по сетям и доход по тем же правилам, что SSresearch.fire().
	for(var/obj/machinery/rnd/server/server in GLOB.machines)
		if(QDELETED(server) || !server.working || !server.stored_research)
			continue
		var/datum/techweb/web = server.stored_research
		working_servers_by_network[web] = (working_servers_by_network[web] || 0) + 1
		if(!SSresearch.multiserver_calculation)
			continue
		var/list/mining_result = server.mine()
		income_by_network[web] = (income_by_network[web] || 0) + (mining_result[TECHWEB_POINT_TYPE_GENERIC] || 0)

	if(SSresearch.multiserver_calculation)
		for(var/datum/techweb/web as anything in income_by_network)
			income_by_network[web] *= SSresearch.calculate_server_coefficient(working_servers_by_network[web])
	else
		for(var/datum/techweb/web as anything in working_servers_by_network)
			income_by_network[web] = SSresearch.single_server_income[TECHWEB_POINT_TYPE_GENERIC] || 0

	for(var/obj/machinery/rnd/server/server in GLOB.machines)
		if(QDELETED(server))
			continue
		index++
		var/turf/server_turf = get_turf(server)
		var/datum/techweb/web = server.stored_research
		var/connected = !!web
		var/is_online = is_server_online(server)
		var/income = 0
		if(connected && is_online)
			// fire() начисляет доход на всю сеть, поэтому на карточку приходится доля сервера.
			income = round((income_by_network[web] || 0) / (working_servers_by_network[web] || 1), 0.1)
		if(is_online)
			online_servers++
		if(connected)
			networks[web] = TRUE
		total_income += income

		var/status = "online"
		if(server.machine_stat & BROKEN)
			status = "broken"
		else if(server.machine_stat & NOPOWER)
			status = "no_power"
		else if(server.machine_stat & EMPED)
			status = "emp"
		else if(!server.working)
			status = "bad_temp"
		else if(server.obj_flags & EMAGGED)
			status = "emagged"

		var/env_temp = server.get_env_temp()
		server_data += list(list(
			"id" = uppertext(server.server_id),
			"path" = "C:\\RND\\SERVER_[index]",
			"network" = connected ? (web.organization || "НЕИЗВЕСТНО") : "НЕ ПОДКЛЮЧЕН",
			"connected" = connected,
			"location" = server_turf ? "([server_turf.x], [server_turf.y], [server_turf.z])" : "НЕИЗВЕСТНО",
			"income" = income,
			"temperature" = round(env_temp - T0C),
			"temp_high" = round(server.temp_tolerance_high - T0C),
			"temp_critical" = round(server.temp_tolerance_high + RESEARCH_SERVER_TEMP_SHUTDOWN_MARGIN - T0C),
			"status" = status,
		))

	data["servers"] = server_data
	data["total_servers"] = length(server_data)
	data["online_servers"] = online_servers
	data["network_count"] = length(networks)
	data["total_income"] = round(total_income, 0.1)
	data["emagged"] = !!(obj_flags & EMAGGED)
	return data

/obj/machinery/computer/rdservercontrol/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("refresh")
			return TRUE

/obj/machinery/computer/rdservercontrol/attackby(obj/item/D, mob/user, params)
	. = ..()
	src.updateUsrDialog()

/obj/machinery/computer/rdservercontrol/emag_act(mob/user)
	. = ..()
	if(obj_flags & EMAGGED)
		return
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	playsound(src, "sparks", 75, 1)
	obj_flags |= EMAGGED
	to_chat(user, "<span class='notice'>You disable the security protocols.</span>")
	return TRUE

#undef RESEARCH_SERVER_OUTPUT_MULTIPLIER
#undef RESEARCH_SERVER_TEMP_SHUTDOWN_MARGIN
