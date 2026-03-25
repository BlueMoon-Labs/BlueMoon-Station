/obj/machinery/computer/robotics
	name = "robotics control console"
	desc = "Used to remotely lockdown or detonate linked Cyborgs and Drones."
	icon_screen = "robot"
	icon_keyboard = "rd_key"
	req_access = list(ACCESS_ROBOTICS)
	circuit = /obj/item/circuitboard/computer/robotics
	light_color = LIGHT_COLOR_PINK
	ui_x = 500
	ui_y = 460
	var/last_praise_scold_time = 0 // (ADD) Pe4henika bluemoon / Cybernetic

/obj/machinery/computer/robotics/proc/can_control(mob/user, mob/living/silicon/robot/R)
	. = FALSE
	if(!istype(R))
		return
	if(isAI(user))
		if(R.connected_ai != user)
			return
	if(iscyborg(user))
		if(R != user)
			return
	if(R.scrambledcodes)
		return
	if(hasSiliconAccessInArea(user) && !issilicon(user))
		if(!Adjacent(user))
			return
	return TRUE

/obj/machinery/computer/robotics/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RoboticsControlConsole", name)
		ui.open()

/obj/machinery/computer/robotics/ui_data(mob/user)
	var/list/data = list()

	data["can_hack"] = FALSE
	if(issilicon(user))
		var/mob/living/silicon/S = user
		if(S.hack_software)
			data["can_hack"] = TRUE
	else if(IsAdminGhost(user))
		data["can_hack"] = TRUE

	data["can_convert"] = FALSE
	if(isAI(user) && is_servant_of_ratvar(user))
		data["can_convert"] = TRUE

	data["cyborgs"] = list()
	for(var/mob/living/silicon/robot/R in GLOB.silicon_mobs)
		if(!can_control(user, R))
			continue
		if(z != (get_turf(R)).z)
			continue
		var/list/cyborg_data = list(
			name = R.name,
			locked_down = R.locked_down,
			status = R.stat,
			charge = R.cell ? round(R.cell.percent()) : null,
			module = R.module ? "[R.module.name] Module" : "No Module Detected",
			synchronization = R.connected_ai,
			emagged =  R.emagged,
			servant = is_servant_of_ratvar(R),
			ref = REF(R)
		)
		data["cyborgs"] += list(cyborg_data)

	data["drones"] = list()
	for(var/mob/living/simple_animal/drone/D in GLOB.drones_list)
		if(D.hacked)
			continue
		if(z != (get_turf(D)).z)
			continue
		var/list/drone_data = list(
			name = D.name,
			status = D.stat,
			ref = REF(D)
		)
		data["drones"] += list(drone_data)
// (ADD) Pe4henika Bluemoon - start
// MARK: Кибернетика
	data["is_ai"] = isAI(user)

	data["cybernetics"] = list()
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		var/obj/item/organ/cyberimp/brain/ai_link/I = H.getorganslot("brain_ai_link")
		if(!I || (isAI(user) && I.linked_ai != user) || z != (get_turf(H)).z)
			continue

		data["cybernetics"] += list(list(
			name = H.name,
			status = H.stat,
			health = round(H.health),
			max_health = H.maxHealth,
			role = (H.mind && H.mind.assigned_role) ? H.mind.assigned_role : "Unknown",
			shock_cooldown = max(0, round((I.last_shock_time + 450 - world.time) / 10)),
			ref = REF(H)
		))
// (ADD) Pe4henika Bluemoon -- end

	return data

/obj/machinery/computer/robotics/ui_act(action, params)
	if(..())
		return
// (ADD) Pe4henika Bluemoon -- start
	var/mob/living/carbon/human/H = locate(params["ref"]) in GLOB.human_list
	var/obj/item/organ/cyberimp/brain/ai_link/I
	if(H)
		I = H.getorganslot("brain_ai_link")
// (ADD) Pe4henika Bluemoon -- end
	switch(action)
		if("killbot")
			if(allowed(usr))
				var/mob/living/silicon/robot/R = locate(params["ref"]) in GLOB.silicon_mobs
				if(can_control(usr, R))
					var/turf/T = get_turf(R)
					message_admins("<span class='notice'>[ADMIN_LOOKUPFLW(usr)] detonated [key_name_admin(R, R.client)] at [ADMIN_VERBOSEJMP(T)]!</span>")
					log_game("[key_name(usr)] detonated [key_name(R)]!")
					if(R.connected_ai)
						to_chat(R.connected_ai, "<br><br><span class='alert'>ALERT - Cyborg detonation detected: [R.name]</span><br>")
					R.self_destruct()
			else
				to_chat(usr, "<span class='danger'>Access Denied.</span>")
		if("stopbot")
			if(allowed(usr))
				var/mob/living/silicon/robot/R = locate(params["ref"]) in GLOB.silicon_mobs
				if(can_control(usr, R))
					message_admins("<span class='notice'>[ADMIN_LOOKUPFLW(usr)] [!R.locked_down ? "locked down" : "released"] [ADMIN_LOOKUPFLW(R)]!</span>")
					log_game("[key_name(usr)] [!R.locked_down ? "locked down" : "released"] [key_name(R)]!")
					R.SetLockdown(!R.locked_down)
					to_chat(R, "[!R.locked_down ? "<span class='notice'>Your lockdown has been lifted!" : "<span class='alert'>You have been locked down!"]</span>")
					if(R.connected_ai)
						to_chat(R.connected_ai, "[!R.locked_down ? "<span class='notice'>NOTICE - Cyborg lockdown lifted" : "<span class='alert'>ALERT - Cyborg lockdown detected"]: <a href='?src=[REF(R.connected_ai)];track=[html_encode(R.name)]'>[R.name]</a></span><br>")
			else
				to_chat(usr, "<span class='danger'>Access Denied.</span>")
		if("magbot")
			var/mob/living/silicon/S = usr
			if((istype(S) && S.hack_software) || IsAdminGhost(usr))
				var/mob/living/silicon/robot/R = locate(params["ref"]) in GLOB.silicon_mobs
				if(istype(R) && !R.emagged && (R.connected_ai == usr || IsAdminGhost(usr)) && !R.scrambledcodes && can_control(usr, R))
					log_game("[key_name(usr)] emagged [key_name(R)] using robotic console!")
					message_admins("[ADMIN_LOOKUPFLW(usr)] emagged cyborg [key_name_admin(R)] using robotic console!")
					R.SetEmagged(TRUE)

		if("convert")
			if(isAI(usr) && is_servant_of_ratvar(usr))
				var/mob/living/silicon/robot/R = locate(params["ref"]) in GLOB.silicon_mobs
				if(istype(R) && !is_servant_of_ratvar(R) && R.connected_ai == usr)
					log_game("[key_name(usr)] converted [key_name(R)] using robotic console!")
					message_admins("[ADMIN_LOOKUPFLW(usr)] converted cyborg [key_name_admin(R)] using robotic console!")
					add_servant_of_ratvar(R)

		if("killdrone")
			if(allowed(usr))
				var/mob/living/simple_animal/drone/D = locate(params["ref"]) in GLOB.mob_list
				if(D.hacked)
					to_chat(usr, "<span class='danger'>ERROR: [D] is not responding to external commands.</span>")
				else
					var/turf/T = get_turf(D)
					message_admins("[ADMIN_LOOKUPFLW(usr)] detonated [key_name_admin(D)] at [ADMIN_VERBOSEJMP(T)]!")
					log_game("[key_name(usr)] detonated [key_name(D)]!")
					var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
					s.set_up(3, TRUE, D)
					s.start()
					D.visible_message("<span class='danger'>\the [D] self-destructs!</span>")
					D.gib()
// (ADD) Pe4henika bluemoon -- start
// MARK: Кибернетика
		if("shock_cyber")
			if(!allowed(usr) || !I)
				return
			if(isAI(usr) && I.linked_ai != usr)
				return
			if(world.time < I.last_shock_time + 450)
				to_chat(usr, "<span class='warning'>Система перегружена. Повторный импульс через [round((I.last_shock_time + 450 - world.time)/10)] сек.</span>")
				return
			I.last_shock_time = world.time
			H.electrocute_act(15, "neural AI link", 1)
			H.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5)
			H.Paralyze(60)
			do_sparks(3, TRUE, H)
			to_chat(H, "<span class='userdanger'>НЕЙРОИНТЕРФЕЙС: Перегрузка системы питания!</span>")
			log_game("[key_name(usr)] shocked [key_name(H)] via robotics console.")

		if("praise_cyber")
			if(!isAI(usr) || !I || I.linked_ai != usr)
				return
			if(world.time < last_praise_scold_time + 1200) // 1200 тиков = 120 секунд
				to_chat(usr, "<span class='warning'>Протоколы взаимодействия восстанавливаются. Подождите [round((last_praise_scold_time + 1200 - world.time)/10)] сек.</span>")
				return

			last_praise_scold_time = world.time
			to_chat(H, "<span class='greenannounce'>Ваш Мастер-ИИ доволен вами. Так держать.</span>")
			to_chat(usr, "<span class='notice'>Вы выразили одобрение [H.name].</span>")
			SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "ai_praise", /datum/mood_event/ai_praise)

		if("scold_cyber")
			if(!isAI(usr) || !I || I.linked_ai != usr)
				return
			if(world.time < last_praise_scold_time + 1200)
				to_chat(usr, "<span class='warning'>Протоколы взаимодействия перезагружаются. Подождите [round((last_praise_scold_time + 1200 - world.time)/10)] сек.</span>")
				return

			last_praise_scold_time = world.time
			to_chat(H, "<span class='boldannounce'><span class='danger'>ВНИМАНИЕ: Ваш Мастер-ИИ крайне недоволен вашей работой!</span></span>")
			to_chat(usr, "<span class='boldannounce'><span class='danger'>Вы отправили дисциплинарное предупреждение [H.name].</span></span>")
			SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "ai_scold", /datum/mood_event/ai_scold)

	return TRUE
// (ADD) Pe4henika Bluemoon -- end
