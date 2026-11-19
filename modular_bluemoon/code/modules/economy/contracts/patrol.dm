/// Общие отсеки, по которым ходит обход: без доступа, на любой карте.
GLOBAL_LIST_INIT(econ_patrol_area_types, typecacheof(list(
	/area/hallway/primary,
	/area/hallway/secondary/entry,
	/area/hallway/secondary/exit,
	/area/service/bar,
	/area/service/cafeteria,
)))

/// Обход СБ: пройти по названным общим отсекам станции до срока. Берут только сотрудники СБ; засчитывается отсек, где взявший побывал живым и в сознании.
/datum/econ_contract/patrol
	title = "Обход станции"
	reward = ECON_PATROL_REWARD
	/// Отсек -> пройден ли взявшим
	var/list/route
	var/check_timer

/datum/econ_contract/patrol/New(department_id)
	..()
	route = list()
	var/list/candidates = list()
	for(var/area/hall as anything in GLOB.sortedAreas)
		if(GLOB.econ_patrol_area_types[hall.type] && is_station_level(hall.z))
			candidates += hall
	while(length(candidates) && length(route) < ECON_PATROL_AREAS)
		route[pick_n_take(candidates)] = FALSE
	update_desc()

/datum/econ_contract/patrol/Destroy()
	. = ..()
	route = null

/// Обход из одного отсека - не обход.
/datum/econ_contract/patrol/postable()
	return length(route) >= 2

/datum/econ_contract/patrol/proc/update_desc()
	var/list/left = list()
	for(var/area/hall as anything in route)
		if(!route[hall])
			left += hall.name
	desc = "Пройти по отсекам станции: [jointext(left, ", ")]."

/datum/econ_contract/patrol/proc/visited()
	. = 0
	for(var/area/hall as anything in route)
		if(route[hall])
			.++

/datum/econ_contract/patrol/has_progress()
	return visited() > 0

/datum/econ_contract/patrol/progress_text()
	return "[visited()] / [length(route)]"

/datum/econ_contract/patrol/take_refusal(datum/bank_account/account)
	if(account && account.department_id != ACCOUNT_SEC)
		return "Обход берут только сотрудники службы безопасности."
	return ..()

/datum/econ_contract/patrol/take(datum/bank_account/account)
	. = ..()
	if(!.)
		return
	if(!urgent)
		set_deadline(world.time + ECON_PATROL_TIME)
	check_timer = addtimer(CALLBACK(src, PROC_REF(check)), ECON_PATROL_CHECK_INTERVAL, TIMER_STOPPABLE)

/datum/econ_contract/patrol/taken_text()
	return "Обход закреплён за вами: пройдите по названным отсекам до срока. Ваша доля - [performer_share()]% награды."

/// Без взявшего пройденное не в счёт: следующий обходчик начинает сначала.
/datum/econ_contract/patrol/release_taker()
	deltimer(check_timer)
	check_timer = null
	for(var/area/hall as anything in route)
		route[hall] = FALSE
	update_desc()
	return ..()

/datum/econ_contract/patrol/proc/check()
	check_timer = null
	if(completed || QDELETED(src) || !taker || SSeconomy.round_over())
		return
	var/mob/living/body = taker_body()
	var/area/here = body?.stat == CONSCIOUS ? get_area(body) : null
	if(here && (here in route) && !route[here])
		route[here] = TRUE
		update_desc()
		if(visited() >= length(route))
			complete(body)
			return
	check_timer = addtimer(CALLBACK(src, PROC_REF(check)), ECON_PATROL_CHECK_INTERVAL, TIMER_STOPPABLE)
