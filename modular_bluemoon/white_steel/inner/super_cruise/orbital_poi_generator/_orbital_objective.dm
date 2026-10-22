//WHITE-STEEL FIX: сколько подряд на руине не должно быть живых игроков, прежде чем
//экспедиционный шаттл уедет сам. Защита от транзитного сбоя проверки.
#define MISSION_SHUTTLE_EMPTY_GRACE (30 SECONDS)

/datum/orbital_objective
	var/name = "Null Objective"
	var/datum/orbital_object/z_linked/beacon/ruin/linked_beacon
	var/payout = 0
	var/completed = FALSE
	var/min_payout = 0
	var/max_payout = 0
	var/id = 0
	var/station_name
	var/static/objective_num = 0
	//WHITE-STEEL PORT: Z-уровень сгенерированной руины миссии (выставляется генератором руин).
	//Нужен для проверки состояния экспедиционного шаттла «на миссии».
	var/objective_z_level
	//WHITE-STEEL PORT: защита от повторной отправки шаттла с миссии.
	var/mission_shuttle_dispatched = FALSE
	//WHITE-STEEL FIX: с какого момента (world.time) на руине не видно живых игроков.
	//Шаттл уедет сам, только если это длится дольше MISSION_SHUTTLE_EMPTY_GRACE.
	var/mission_shuttle_empty_since = 0
	//WHITE-STEEL PORT: ckey'и авангардцев, зафиксированные на борту шаттла в момент старта миссии.
	//null - снимок не сделан (ограничение по очкам не применяется), list() - на шаттле никого не было.
	var/list/expedition_crew_ckeys

/datum/orbital_objective/New()
	. = ..()
	id = objective_num ++
	station_name = new_station_name()

/datum/orbital_objective/Destroy()
	//WHITE-STEEL FIX: разрываем цикл objective <-> beacon. Без этого при удалении
	//задания (QDEL_NULL(SSorbits.current_objective)) живой маяк удерживал objective
	//через linked_objective, а objective удерживал маяк через linked_beacon, и оба
	//датума не собирались GC (hard del, утечка маяков/заданий).
	if(linked_beacon)
		linked_beacon.linked_objective = null
		linked_beacon = null
	//WHITE-STEEL PORT: миссия закончилась и экспедиция улетела с руины - тела погибших
	//авангардцев отправляем домой на приёмный маяк, иначе их съест аннигилятор уровня.
	fulton_dead_expeditors_home(TRUE)
	return ..()

/datum/orbital_objective/proc/on_assign(obj/machinery/computer/objective/objective_computer)
	return

/datum/orbital_objective/proc/generate_objective_stuff(turf/chosen_turf)
	return

/datum/orbital_objective/proc/check_failed()
	return TRUE

/datum/orbital_objective/proc/get_text()
	return ""

//WHITE-STEEL PORT: атом-цель задания, на который наводится пинпоинтер задания.
//null, пока цель не создана (руина ещё не сгенерирована).
/datum/orbital_objective/proc/get_target()
	return null

/datum/orbital_objective/proc/unregister_mission_body(mob/target)
	if(!ismob(target))
		return
	var/target_name = target.real_name
	if(istext(target_name))
		LAZYREMOVE(GLOB.mob_spawners[target_name], target)
		if(!LAZYLEN(GLOB.mob_spawners[target_name]))
			GLOB.mob_spawners -= target_name
/datum/orbital_objective/proc/cleanup_undelivered_body(mob/target, force_delete = FALSE)
	if(!ismob(target))
		return
	unregister_mission_body(target)
	if(QDELETED(target))
		return
	if(!force_delete && (is_station_level(target.z) || is_centcom_level(target.z)))
		return
	if(target.client)
		target.ghostize()
	qdel(target)

/datum/orbital_objective/proc/generate_payout()
	payout = rand(min_payout, max_payout)

/datum/orbital_objective/proc/generate_attached_beacon()
	linked_beacon = new
	linked_beacon.name = "(ЗАДАНИЕ) [linked_beacon.name]"
	linked_beacon.linked_objective = src

/datum/orbital_objective/proc/remove_objective()
	QDEL_NULL(SSorbits.current_objective)

//=====================
// WHITE-STEEL PORT: эвакуация экспедиции с миссии
//=====================
//Авто-возврат экспедиционного шаттла с ЛЮБОЙ миссии, если все игроки на руине мертвы, и
//фултон их тел на мостик шаттла. Вызывается каждый тик из SSorbits для текущего задания.
//Раньше эта логика существовала только у headhunt.
/datum/orbital_objective/proc/handle_mission_shuttle()
	if(!objective_z_level || mission_shuttle_dispatched)
		return
	var/obj/docking_port/mobile/exploration = SSshuttle.getShuttle("exploration")
	if(!exploration || exploration.mode != SHUTTLE_IDLE || exploration.z != objective_z_level)
		return
	var/atom/movable/npc_target = get_target()
	//Считаем живых игроков на руине (цель-непись миссии игнорируем). Намеренно НЕ требуем
	//наличия client: живой игрок мог на миг потерять соединение или уйти в SSD — оставлять
	//его на руине, посчитав команду мёртвой, нельзя.
	var/found_alive = FALSE
	for(var/mob/living/carbon/human/H as() in GLOB.human_list)
		if(QDELETED(H) || H.z != objective_z_level || H.stat == DEAD || !H.mind)
			continue
		if(H == npc_target)
			continue
		found_alive = TRUE
		break
	if(found_alive)
		mission_shuttle_empty_since = 0
		return
	//WHITE-STEEL FIX: никого живого не видно. Не улетаем по одному «пустому» тику — ждём
	//grace-период, иначе транзитный сбой проверки (игрок в Move(), моргнувший client и т.п.)
	//оставлял человека на руине без шаттла.
	if(!mission_shuttle_empty_since)
		mission_shuttle_empty_since = world.time
		var/list/who = list()
		for(var/mob/living/carbon/human/H as() in GLOB.human_list)
			if(QDELETED(H) || H.z != objective_z_level)
				continue
			who += "[key_name(H)] ([H.stat == DEAD ? "мёртв" : "жив"][H.client ? "" : ", нет клиента"])"
		log_game("[name]: на руине (z=[objective_z_level]) не видно живых игроков (на уровне: [length(who) ? who.Join("; ") : "никого"]), повторная проверка через [MISSION_SHUTTLE_EMPTY_GRACE / (1 SECONDS)]с.")
		return
	if(world.time - mission_shuttle_empty_since < MISSION_SHUTTLE_EMPTY_GRACE)
		return
	mission_shuttle_dispatched = TRUE
	log_game("[name]: вся команда на руине (z=[objective_z_level]) мертва, шаттл авангарда возвращается на базу.")
	//Тела погибших — на приёмный маяк авангарда (а если маяка на карте нет, то на мостик шаттла),
	//чтобы уехали домой и не были зачищены аннигилятором уровня.
	fulton_dead_expeditors_home()
	SSzclear.temp_keep_z(exploration.z)
	var/obj/docking_port/stationary/home_port = SSshuttle.getDock("exploration_home")
	if(home_port)
		SSzclear.temp_keep_z(home_port.z)
	if(SSshuttle.moveShuttle("exploration", "exploration_home", 1) == 0)
		broadcast_auto_return()

//WHITE-STEEL PORT: фултон тел погибших на приёмный маяк авангарда (/obj/structure/fulton_beacon),
//который игрок ставит на карте. Если маяка на карте нет - старое поведение: тела едут на мостик
//экспедиционного шаттла. Тело перемещаем СРАЗУ (до moveShuttle), чтобы оно гарантированно уехало
//домой вместе с шаттлом; фултон-эффект — отдельная визуалка на месте гибели.
//require_departure - доставлять тела только если экспедиция уже улетела с руины (шаттл ещё
//стоит на её Z-уровне - тела пока оставляем на месте).
/datum/orbital_objective/proc/fulton_dead_expeditors_home(require_departure = FALSE)
	if(!objective_z_level)
		return
	if(require_departure)
		var/obj/docking_port/mobile/exploration = SSshuttle.getShuttle("exploration")
		if(exploration && exploration.z == objective_z_level)
			return
	var/obj/structure/fulton_beacon/beacon = get_expedition_body_beacon()
	var/turf/bridge = null
	if(!beacon)
		bridge = get_exploration_bridge_turf()
	if(!beacon && !bridge)
		return
	var/atom/movable/npc_target = get_target()
	for(var/mob/living/carbon/human/H as() in GLOB.human_list)
		if(QDELETED(H) || H == npc_target || H.z != objective_z_level)
			continue
		if(H.stat != DEAD || !H.mind)
			continue
		//Только авангард: трупы живцов руины и цель миссии на маяк не летят.
		if(!is_expedition_crew(H))
			continue
		//Тело уходит на маяк (на свободный пол рядом с ним) или, если маяка нет, на мостик шаттла.
		var/turf/destination = beacon ? beacon.get_delivery_turf() : bridge
		if(!destination)
			continue
		var/turf/start = get_turf(H)
		H.forceMove(destination)
		fulton_launch_effect(start)

//WHITE-STEEL PORT: авангардовец ли это? (по профессии). Цель миссии и прочие живцы руины - нет.
/datum/orbital_objective/proc/is_expedition_crew(mob/living/carbon/human/H)
	if(H == get_target())
		return FALSE
	if(!H.mind || !H.mind.assigned_role)
		return FALSE
	return istype(SSjob.GetJob(H.mind.assigned_role), /datum/job/expeditor)

//WHITE-STEEL PORT: приёмный маяк для тел экспедиции. Приоритет у маяков на станции (их ставит
//игрок на карте сам), если таких нет - берём любой маяк. null - маяков на карте нет вообще.
//Цель миссии (npc_target) сюда не попадает: её труп разбирает сам тип задания.
/datum/orbital_objective/proc/get_expedition_body_beacon()
	var/obj/structure/fulton_beacon/fallback
	for(var/obj/structure/fulton_beacon/beacon in GLOB.expedition_body_beacons)
		if(QDELETED(beacon))
			continue
		if(is_station_level(beacon.z))
			return beacon
		if(!fallback)
			fallback = beacon
	return fallback

//WHITE-STEEL PORT: тайл мостика экспедиционного шаттла (по консоли полёта).
/datum/orbital_objective/proc/get_exploration_bridge_turf()
	for(var/obj/machinery/computer/shuttle_flight/exploration/flight_console in GLOB.machines)
		var/turf/T = get_turf(flight_console)
		if(T)
			return T
	return null

//WHITE-STEEL PORT: визуальный запуск фултона (шарик вверх) на месте гибели — упрощённая
//копия анимации /obj/item/extraction_pack без маяка и предмета.
//Глобальный proc (а не метод датума): эффект зовём и из Destroy() задания, где датум уже умирает.
/proc/fulton_launch_effect(turf/launch_turf)
	set waitfor = FALSE
	if(QDELETED(launch_turf))
		return
	playsound(launch_turf, 'sound/items/fultext_launch.wav', 50, 1, -3)
	var/obj/effect/extraction_holder/holder = new(launch_turf)
	var/mutable_appearance/balloon = mutable_appearance('icons/obj/fulton_balloon.dmi', "fulton_balloon")
	balloon.pixel_y = 10
	balloon.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	holder.add_overlay(balloon)
	animate(holder, pixel_z = 1000, time = 25)
	sleep(25)
	qdel(holder)

//WHITE-STEEL PORT: сообщение в общий канал от консоли шаттла при авто-возврате.
/datum/orbital_objective/proc/broadcast_auto_return()
	for(var/obj/machinery/computer/shuttle_flight/exploration/console in GLOB.machines)
		console.speak_common("Потеряна связь с датчиками экспедиции, возвращаюсь на станцию.")
		break

//WHITE-STEEL PORT: есть ли живой подключённый игрок вне шаттла на руине текущей миссии.
//Используется консолью шаттла, чтобы запретить запуск, пока часть состава снаружи.
/datum/orbital_objective/proc/expedition_crew_left_behind()
	if(!objective_z_level)
		return FALSE
	var/obj/docking_port/mobile/exploration = SSshuttle.getShuttle("exploration")
	if(!exploration)
		return FALSE
	//WHITE-STEEL FIX: гейт нужен, только когда шаттл СТОИТ на руине миссии (тогда запуск =
	//бросок экипажа). Если шаттл уже у базы, запуск — это отправка на спасение, блокировать нельзя.
	if(exploration.z != objective_z_level)
		return FALSE
	var/atom/movable/npc_target = get_target()
	for(var/mob/living/carbon/human/H as() in GLOB.human_list)
		if(QDELETED(H) || H.z != objective_z_level || H.stat == DEAD || !H.mind)
			continue
		if(H == npc_target)
			continue
		var/area/A = get_area(H)
		if(!A)
			continue
		if(A in exploration.shuttle_areas)
			continue
		return TRUE
	return FALSE

//WHITE-STEEL PORT: голосование призраков за гостроль (ВИП/цель охоты). В отличие от
//notify_ghosts + клика по телу, это полноценный опрос (SSpolling) с HUD-иконкой.
//Опрос блокирующий (UNTIL), поэтому запускаем через INVOKE_ASYNC; если тело так и
//не заняли игроком — повторяем каждые 30 секунд, пока тело свободно и задание живо.
/datum/orbital_objective/proc/start_ghost_role_poll(mob/target, question, ignore_category, role_text, takeover_message)
	if(QDELETED(target) || target.key || target.client)
		return
	INVOKE_ASYNC(src, PROC_REF(run_ghost_role_poll), target, question, ignore_category, role_text, takeover_message)

/datum/orbital_objective/proc/run_ghost_role_poll(mob/target, question, ignore_category, role_text, takeover_message)
	set waitfor = FALSE
	if(QDELETED(src) || QDELETED(target) || target.key || target.client)
		return
	var/list/candidates = pollGhostCandidates(question, null, null, 0, 30 SECONDS, ignore_category, FALSE, 1, FALSE, role_text)
	for(var/mob/candidate as anything in candidates)
		if(QDELETED(src) || QDELETED(target) || target.key || target.client)
			return
		if(!candidate?.client)
			continue
		candidate.transfer_ckey(target, FALSE)
		target.client?.init_verbs()
		if(takeover_message)
			to_chat(target, span_boldnotice(takeover_message))
		log_game("Orbital objective: [key_name(target)] занял гостроль '[role_text]' через голосование ([REF(target)]).")
		return
	// Никто не откликнулся — повторяем опрос, пока тело по-прежнему свободно.
	if(!QDELETED(src) && !QDELETED(target) && !target.key && !target.client)
		addtimer(CALLBACK(src, PROC_REF(run_ghost_role_poll), target, question, ignore_category, role_text, takeover_message), 30 SECONDS)

/datum/orbital_objective/proc/snapshot_expedition_crew()
	var/obj/docking_port/mobile/exploration = SSshuttle.getShuttle("exploration")
	if(!exploration)
		expedition_crew_ckeys = list()
		return
	expedition_crew_ckeys = list()
	for(var/mob/living/carbon/human/H as() in GLOB.human_list)
		if(QDELETED(H) || H.stat == DEAD || !H.mind || !H.ckey)
			continue
		var/area/A = get_area(H)
		if(!A || !(A in exploration.shuttle_areas))
			continue
		expedition_crew_ckeys += H.ckey

/datum/orbital_objective/proc/complete_objective()
	if(completed)
		//Delete
		QDEL_NULL(SSorbits.current_objective)
		return
	completed = TRUE
	//Handle payout
	var/rangers_count = 0
	for(var/I in SSjob.occupations)
		var/datum/job/J = I
		if(istype(J, /datum/job/expeditor))
			rangers_count = J.current_positions

	var/israel = 0
	if(rangers_count)
		israel = round((payout / 2) / rangers_count)
	var/goyam  = round((payout / 2) / max(SSeconomy.generated_accounts.len, 1))
	for(var/B in SSeconomy.bank_accounts_by_id)
		var/datum/bank_account/A = SSeconomy.bank_accounts_by_id[B]
		if(istype(A.account_job, /datum/job/expeditor))
			A.bank_card_talk("Было получено [israel] кредитов за выполнение задания.")
			A.adjust_money(israel)
		else
			A.bank_card_talk("Было получено [goyam] кредитов за содействие выполнению поручений NanoTrasen.")
			A.adjust_money(goyam)
	//WHITE-STEEL PORT: очки задания. Половина пула начисляется на общий счёт карго,
	//каждый действующий авангард дополнительно получает В ДВА раза больше очков на свой ID.
	var/cargo_share = round(payout / 2)
	GLOB.cargo_objective_points += cargo_share
	for(var/mob/living/carbon/human/H as() in GLOB.human_list)
		if(!H.mind)
			continue
		var/is_vanguard = FALSE
		var/datum/job/J = SSjob.GetJob(H.mind.assigned_role)
		if(istype(J, /datum/job/expeditor))
			is_vanguard = TRUE
		var/obj/item/card/id/id_card = H.get_idcard(TRUE)
		if(!is_vanguard && id_card)
			var/assign = lowertext(id_card.get_assignment_name() || "")
			if(findtext(assign, "vanguard") || findtext(assign, "expeditor"))
				is_vanguard = TRUE
		if(!is_vanguard && H.mind.assigned_role)
			var/role_txt = lowertext(H.mind.assigned_role)
			if(findtext(role_txt, "vanguard") || findtext(role_txt, "expeditor"))
				is_vanguard = TRUE
		if(!is_vanguard)
			continue
		if(!isnull(expedition_crew_ckeys) && (!H.ckey || !(H.ckey in expedition_crew_ckeys)))
			continue
		if(!id_card)
			id_card = H.get_idcard(TRUE)
		if(!id_card)
			continue
		id_card.contraband_points += cargo_share * 2
		to_chat(H, span_notice("Вы получили [cargo_share * 2] очков Авангарда за выполнение задания."))
	//WHITE-STEEL PORT: на счёт карго дополнительно поступают деньги в полуторном размере от награды за задание.
	var/datum/bank_account/department/cargo_dep = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(cargo_dep)
		var/cargo_money = round(payout * 1.5)
		cargo_dep.adjust_money(cargo_money)
	//Delete
	QDEL_NULL(SSorbits.current_objective)
