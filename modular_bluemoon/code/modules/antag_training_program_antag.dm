/// Программа учебной роли раунда: выдаёт учебный подтип датума с выбором, сделанным до выдачи.
/datum/antag_training_program/antag
	abstract_type = /datum/antag_training_program/antag
	var/antag_type
	/// Ключ выбора -> подпись. Кнопка «[choice_prompt]: подпись» перевыдаёт роль с этим выбором.
	var/list/choices = list()
	var/choice
	var/choice_prompt
	var/datum/weakref/recent_target_ref

/datum/antag_training_program/antag/New()
	. = ..()
	for(var/key in choices)
		choice ||= key
		options += choice_option(key)

/datum/antag_training_program/antag/proc/choice_option(key)
	return "[choice_prompt]: [choices[key]]"

/datum/antag_training_program/antag/setup(datum/antag_training_session/session)
	return grant_role(session)

/datum/antag_training_program/antag/proc/grant_role(datum/antag_training_session/session)
	if(!antag_type || QDELETED(session.avatar_mind) || !session.avatar_mind.current)
		return FALSE
	var/datum/antagonist/role = new antag_type
	if("training" in role.vars)
		role.vars["training"] = session
	apply_choice(role)
	return !!session.avatar_mind.add_antag_datum(role)

/// Переносит выбор программы в датум до on_gain().
/datum/antag_training_program/antag/proc/apply_choice(datum/antagonist/role)
	return

/datum/antag_training_program/antag/proc/role(datum/antag_training_session/session)
	return session.current_body?.mind?.has_antag_datum(antag_type)

/datum/antag_training_program/antag/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	for(var/key in choices)
		if(option == choice_option(key))
			change_choice(session, user, key)
			return TRUE
	return FALSE

/datum/antag_training_program/antag/proc/change_choice(datum/antag_training_session/session, mob/living/user, key)
	if(QDELETED(session.avatar_mind))
		return FALSE
	session.avatar_mind.remove_antag_datum(antag_type)
	choice = key
	if(!grant_role(session))
		to_chat(user, span_warning("Роль не выдалась. Начните новым персонажем."))
		return FALSE
	log_game("[key_name(user)] на тренировочном полигоне меняет программу «[name]»: [choices[key]].")
	return TRUE

/datum/antag_training_program/antag/target_created(datum/antag_training_session/session, mob/living/carbon/human/target)
	if(target.mind)
		recent_target_ref = WEAKREF(target)

/// Последняя отмеченная живая учебная цель участника, иначе последняя созданная.
/datum/antag_training_program/antag/proc/recent_target(datum/antag_training_session/session)
	var/mob/living/carbon/human/dummy = recent_target_ref?.resolve()
	if(practice_dummy(session, dummy))
		return dummy
	for(var/index in length(session.arena.targets) to 1 step -1)
		dummy = session.arena.targets[index]
		if(practice_dummy(session, dummy))
			return dummy
	return null

/datum/antag_training_program/antag/proc/practice_dummy(datum/antag_training_session/session, mob/living/carbon/human/dummy)
	return ishuman(dummy) && dummy.mind && dummy.stat != DEAD && session.can_manage_target(dummy)

/// Манекен с разумом рядом с участником, из центра и коридора - в лаборатории; сообщение об успехе - за вызывающим.
/datum/antag_training_program/antag/proc/place_practice_dummy(datum/antag_training_session/session, mob/living/user, failure = "Манекен не встал: достигнут предел целей, идёт сброс или дуэль. Удалите ненужную цель или перейдите в другую зону.")
	var/datum/antag_training_arena/arena = session.arena
	if(world.time < arena.next_spawn_at)
		to_chat(user, span_warning("Подождите секунду перед следующей целью."))
		return null
	arena.next_spawn_at = world.time + 1 SECONDS
	var/zone_id = arena.match_zone(user)
	var/turf/near = get_turf(user)
	if(!arena.zones[zone_id] || zone_id == "hub")
		zone_id = "laboratory"
		near = null
	var/mob/living/carbon/human/dummy = arena.spawn_creature("human", zone_id, FALSE, session, near)
	if(!dummy)
		to_chat(user, span_warning(failure))
		return null
	target_created(session, dummy)
	return dummy

/datum/antag_training_program/antag/proc/dummy_zone_name(datum/antag_training_session/session, mob/living/dummy)
	var/list/zone = session.arena.zones[session.arena.match_zone(dummy)]
	return zone ? zone["name"] : "Коридор"

/// Учебное задание: в окне роли отмечается выполненным, но раунд его не засчитывает (отчёт, метадоллары) и цель не перевыбирает.
/datum/objective/antag_training
	name = "training task"

/datum/objective/antag_training/check_completion()
	return FALSE

/datum/objective/antag_training/find_target(dupe_search_range, blacklist)
	return null

/datum/objective/antag_training/find_target_by_role(role, role_type = 0, invert = 0)
	return null

/// Причина отказа привязать карту к счёту станции, пока карта на тренировочном полигоне, иначе null.
/obj/item/card/id/proc/training_bank_refusal()
	var/turf/spot = get_turf(src)
	if(spot && SSmapping.level_trait(spot.z, ZTRAIT_ANTAG_TRAINING))
		return "На тренировочном полигоне карта не привязывается к счетам станции."
	return null

/// Приветствие учебной роли доходит до игрока: тело полигона получает клиента позже выдачи роли.
/proc/antag_training_greet_on_login(datum/antagonist/role, datum/callback/greeting)
	var/mob/body = role?.owner?.current
	if(!body)
		return
	if(body.client)
		greeting.InvokeAsync()
		return
	new /datum/antag_training_greeting(role, body, greeting)

/datum/antag_training_greeting
	var/datum/antagonist/role
	var/mob/body
	var/datum/callback/greeting

/datum/antag_training_greeting/New(datum/antagonist/role, mob/body, datum/callback/greeting)
	src.role = role
	src.body = body
	src.greeting = greeting
	RegisterSignal(body, COMSIG_MOB_CLIENT_LOGIN, PROC_REF(on_login))
	RegisterSignal(body, COMSIG_PARENT_QDELETING, PROC_REF(on_gone))
	RegisterSignal(role, COMSIG_PARENT_QDELETING, PROC_REF(on_gone))

/datum/antag_training_greeting/proc/on_login(mob/source)
	SIGNAL_HANDLER
	var/datum/callback/pending = greeting
	qdel(src)
	pending.InvokeAsync()

/datum/antag_training_greeting/proc/on_gone(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/antag_training_greeting/Destroy()
	role = null
	body = null
	greeting = null
	return ..()
