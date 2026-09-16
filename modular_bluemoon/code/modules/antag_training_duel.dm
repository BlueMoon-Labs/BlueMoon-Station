/datum/antag_training_arena
	var/datum/antag_training_duel/duel

/datum/antag_training_session/proc/request_duel(datum/antag_training_session/opponent, to_death = FALSE)
	if(!can_control(current_body) || !opponent || opponent == src || !(opponent in arena.members) || !opponent.can_control(opponent.current_body) || arena.duel || arena.resetting || preparing || opponent.preparing || world.time < next_duel_at)
		return FALSE
	if(current_body.stat != CONSCIOUS || opponent.current_body.stat != CONSCIOUS)
		practice_message("Оба участника должны быть в сознании.")
		return FALSE
	if(!iscarbon(current_body) || !iscarbon(opponent.current_body))
		practice_message("Для дуэли нужны обычные тела участников. Вернитесь из формы существа через смену программы.")
		return FALSE
	next_duel_at = world.time + ANTAG_TRAINING_DUEL_INVITE
	arena.duel = new(arena, src, opponent, to_death)
	return TRUE

/datum/antag_training_duel
	var/datum/antag_training_arena/arena
	var/datum/antag_training_session/challenger
	var/datum/antag_training_session/opponent
	var/phase = "invite"
	var/to_death = FALSE
	var/deadline
	var/started_at
	var/datum/antag_training_measurement/first_measurement
	var/datum/antag_training_measurement/second_measurement

/datum/antag_training_duel/New(datum/antag_training_arena/location, datum/antag_training_session/first, datum/antag_training_session/second, lethal)
	arena = location
	challenger = first
	opponent = second
	to_death = lethal
	deadline = world.time + ANTAG_TRAINING_DUEL_INVITE
	START_PROCESSING(SSprocessing, src)
	opponent.practice_message("[challenger.current_body.real_name] приглашает на дуэль [to_death ? "до смерти" : "до крита"]. Примите вызов в пульте: используются ваши текущие вещи и способности, лечение кнопкой завершает бой.")

/datum/antag_training_duel/proc/includes(datum/antag_training_session/member)
	return member == challenger || member == opponent

/datum/antag_training_duel/proc/accept(datum/antag_training_session/member)
	if(phase != "invite" || member != opponent || world.time >= deadline || arena.resetting || challenger.preparing || opponent.preparing)
		return FALSE
	if(!challenger.can_control(challenger.current_body) || !opponent.can_control(opponent.current_body))
		return FALSE
	if(challenger.current_body.stat != CONSCIOUS || opponent.current_body.stat != CONSCIOUS)
		return FALSE
	for(var/datum/antag_training_session/visitor as anything in arena.members)
		if(!includes(visitor) && arena.match_zone(visitor.current_body) == "melee")
			member.practice_message("Арена ближнего боя занята. Попросите остальных участников освободить её.")
			return FALSE
	for(var/mob/living/target as anything in arena.targets)
		if(arena.match_zone(target) == "melee")
			member.practice_message("Уберите цели с арены ближнего боя перед дуэлью.")
			return FALSE
	var/turf/first_start = arena.zones["melee"]["spawn"]
	var/turf/second_start = arena.zones["melee"]["target"]
	var/list/fighters = list(challenger.current_body, opponent.current_body)
	if(first_start.is_blocked_turf(ignore_atoms = fighters) || second_start.is_blocked_turf(ignore_atoms = fighters))
		member.practice_message("Стартовые клетки заняты. Освободите площадку или согласуйте её сброс.")
		return FALSE
	challenger.stop_practice()
	opponent.stop_practice()
	challenger.heal_self()
	opponent.heal_self()
	challenger.current_body.forceMove(first_start)
	opponent.current_body.forceMove(second_start)
	phase = "countdown"
	deadline = world.time + ANTAG_TRAINING_DUEL_COUNTDOWN
	for(var/datum/antag_training_session/fighter as anything in list(challenger, opponent))
		fighter.last_duel_result = null
		RegisterSignal(fighter.current_body, list(COMSIG_CARBON_UPDATEHEALTH, COMSIG_MOB_DEATH, COMSIG_MOVABLE_MOVED), PROC_REF(on_fighter_changed))
		fighter.practice_message("Дуэль начнётся через 3 секунды. Дождитесь сообщения «Бой». Уход с арены, восстановление или изменение подготовки через пульт завершат попытку.")
	return TRUE

/datum/antag_training_duel/proc/on_fighter_changed()
	SIGNAL_HANDLER
	check_outcome()

/datum/antag_training_duel/proc/check_outcome()
	if(phase == "invite" || phase == "ended")
		return
	for(var/datum/antag_training_session/fighter as anything in list(challenger, opponent))
		if(QDELETED(fighter.current_body) || arena.match_zone(fighter.current_body) != "melee")
			finish("Дуэль завершена: участник покинул арену или потерял тело.")
			return
		if(phase == "countdown" && (fighter.current_body.health < fighter.current_body.maxHealth || fighter.current_body.stat != CONSCIOUS))
			finish("Дуэль отменена: повреждение до команды «Бой».")
			return
		if(phase == "active" && (fighter.current_body.stat == DEAD || (!to_death && fighter.current_body.health <= HEALTH_THRESHOLD_CRIT)))
			var/datum/antag_training_session/winner = fighter == challenger ? opponent : challenger
			finish("Победитель: [winner.current_body.real_name]. Время: [round((world.time - started_at) / (1 SECONDS), 0.1)] с.")
			return

/datum/antag_training_duel/process()
	if(QDELETED(arena) || arena.finished || arena.resetting || challenger.finished || opponent.finished)
		finish("Дуэль завершена: полигон или сеанс участника закрыт.")
		return PROCESS_KILL
	if((challenger.connected && !challenger.current_body?.client) || (opponent.connected && !opponent.current_body?.client))
		finish("Дуэль завершена: участник отключился.")
		return PROCESS_KILL
	check_outcome()
	if(QDELETED(src) || world.time < deadline)
		return
	if(phase == "countdown")
		phase = "active"
		started_at = world.time
		deadline = world.time + ANTAG_TRAINING_DUEL_DURATION
		first_measurement = new(challenger.current_body)
		second_measurement = new(opponent.current_body)
		challenger.practice_message("Бой! Лимит времени — 3 минуты.")
		opponent.practice_message("Бой! Лимит времени — 3 минуты.")
	else
		finish(phase == "invite" ? "Время приглашения истекло." : "Дуэль завершена по лимиту времени.")

/datum/antag_training_duel/proc/finish(message)
	if(phase == "ended")
		return
	phase = "ended"
	first_measurement?.sample(challenger.current_body)
	second_measurement?.sample(opponent.current_body)
	var/index = 0
	for(var/datum/antag_training_session/fighter as anything in list(challenger, opponent))
		index++
		if(!QDELETED(fighter))
			var/datum/antag_training_measurement/result = index == 1 ? first_measurement : second_measurement
			fighter.last_duel_result = "[message][result ? " Получено урона: [round(result.damage, 0.1)]; восстановлено здоровья: [round(result.healing, 0.1)]." : ""]"
			fighter.practice_message(fighter.last_duel_result)
	qdel(src)

/datum/antag_training_duel/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	for(var/datum/antag_training_session/fighter as anything in list(challenger, opponent))
		if(fighter?.current_body)
			UnregisterSignal(fighter.current_body, list(COMSIG_CARBON_UPDATEHEALTH, COMSIG_MOB_DEATH, COMSIG_MOVABLE_MOVED))
	QDEL_NULL(first_measurement)
	QDEL_NULL(second_measurement)
	if(arena?.duel == src)
		arena.duel = null
	arena = null
	challenger = null
	opponent = null
	return ..()
