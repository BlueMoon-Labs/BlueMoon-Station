/obj/machinery/rnd/server
	name = "\improper R&D Server"
	desc = "A computer system running a deep neural network that processes arbitrary information to produce data useable in the development of new technologies. In layman's terms, it makes research points."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "server"
	req_access = list(ACCESS_RD) //ONLY THE R&D CAN CHANGE SERVER SETTINGS.
	circuit = /obj/item/circuitboard/machine/rdserver

	idle_power_usage = 500
	var/datum/techweb/stored_research
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

/obj/machinery/rnd/server/Initialize(mapload)
	. = ..()
	GLOB.rndservers_list += src
	SSresearch.servers |= src
	stored_research = SSresearch.science_tech
	alarmloop = new(src, !working)

	server_id = "[copytext(md5("[world.timeofday][rand()][src]"), 1, 5)]" // Генерируем серверу уникальный айди
	name += " ([uppertext(server_id)])"

/obj/machinery/rnd/server/process()
	if(!(machine_stat & NOPOWER) && working)
		produce_heat(base_mining_income[1])
	if(get_env_temp() >= (temp_tolerance_high + 50) || get_env_temp() <= temp_tolerance_low)
		if(working)
			working = FALSE
			play_alarm()
	else
		if(!working)
			working = TRUE
			alarmloop.stop()

/obj/machinery/rnd/server/examine() // BLUEMOON ADD
	. = ..()
	if(!working)
		. += "\nThe server's status light is blinking [span_red("red")]."
	else if(machine_stat & NOPOWER)
		. += "\nThe server's status light is off."
	else
		. += "\nThe server's status light is blinking [span_green("green")]."

/obj/machinery/rnd/server/Destroy()
	SSresearch.servers -= src
	QDEL_NULL(alarmloop)
	return ..()

/obj/machinery/rnd/server/RefreshParts()
	var/tot_rating = 0
	for(var/obj/item/stock_parts/SP in src.component_parts)
		tot_rating += SP.rating
	heat_gen = initial(src.heat_gen) / max(1, tot_rating)
	income_gen = 1 + ((tot_rating - 1) * 0.2)

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
	machine_stat |= EMPED
	addtimer(CALLBACK(src, PROC_REF(unemp)), severity*9)
	refresh_working()

/obj/machinery/rnd/server/proc/unemp()
	machine_stat &= ~EMPED
	refresh_working()

/obj/machinery/rnd/server/proc/mine()
	. = base_mining_income.Copy()
	var/turf/open/floor/circuit/c_floor = get_turf(src)
	var/penalty = max((get_env_temp() - temp_tolerance_high), 0) * temp_penalty_coefficient * (c_floor ? 1 : 0.5)
	for(var/i in .)
		.[i] = max((.[i] * income_gen) - penalty, 0)

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
	var/screen = 0
	var/obj/machinery/rnd/server/temp_server
	var/list/servers = list()
	var/list/consoles = list()
	var/badmin = 0
	circuit = /obj/item/circuitboard/computer/rdservercontrol

/obj/machinery/computer/rdservercontrol/Topic(href, href_list)
	if(..())
		return

	add_fingerprint(usr)
	usr.set_machine(src)
	if(!src.allowed(usr) && !(obj_flags & EMAGGED))
		to_chat(usr, "<span class='danger'>You do not have the required access level.</span>")
		return

	if(href_list["main"])
		screen = 0

	updateUsrDialog()
	return

/obj/machinery/computer/rdservercontrol/ui_interact(mob/user)
	. = ..()
	var/dat = ""
	dat += "<html><head><title>R&D Server Control</title>"
	dat += "<style>"
	dat += "body { background-color: #000000; color: #00FF00; font-family: 'Courier New', monospace; font-size: 13px; }"
	dat += "hr { border: 1px solid #00FF00; }"
	dat += "b { color: #80FF80; }"
	dat += ".dim { color: #007700; }"
	dat += "</style></head><body>"

	switch(screen)
		if(0)
			var/total_servers = 0
			for(var/obj/machinery/rnd/server/S in GLOB.machines)
				total_servers++

			// Шапка со всяким флаффом декоративным
			dat += "<b>Nanotrasen Research Division DOS v3.4.2</b><br>"
			dat += "Copyright (C) 2565 Nanotrasen Corporation<br>"
			dat += "All Rights Reserved.<br><br>"
			dat += "Initializing system resources... <span class='dim'>OK</span><br>"
			dat += "Loading device drivers... <span class='dim'>OK</span><br>"
			dat += "Establishing uplink... <span class='dim'>CONNECTED</span><br>"
			dat += "Loading R&D server control interface... <span class='dim'>READY</span><br>"
			dat += "<hr>"
			// Реальная информация
			dat += "C:\\>Connected Servers<br><br>"
			if(total_servers == 0)
				dat += "NO SERVERS DETECTED.<br>"
			else
				var/i = 1
				for(var/obj/machinery/rnd/server/S in GLOB.machines)
					dat += "[i]. Server: [uppertext(S.server_id)]<br>"
					dat += "   Path: C:\\RND\\SERVER_[i]<br>"
					dat += "   Income stream: <b>[S.income_gen]</b> RP/tick<br><br>"
					i++
				dat += "Total servers detected: <b>[total_servers]</b><br>"

			dat += "<hr>"
			dat += "C:\\>System ready.<br>"
			dat += "C:\\>"

	dat += "</body></html>"

	user << browse(dat, "window=server_control;size=600x450")
	onclose(user, "server_control")
	return

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
