/// Программа-существо: учебная роль в теле моба своего типа, которое пересоздаётся вместо конца сеанса.
/datum/antag_training_program/creature
	abstract_type = /datum/antag_training_program/creature
	var/mob_type
	/// Учебный датум роли: обязан переопределять attach_training().
	var/antag_type
	/// Тип моба -> подпись. Кнопка «[choice_prompt]: подпись» пересоздаёт тело этим типом.
	var/list/choices = list()
	var/choice_prompt = "Сменить вид"
	var/datum/weakref/body_ref
	var/rebuilding = FALSE
	var/last_rebuild_at = 0
	var/rapid_rebuilds = 0

/datum/antag_training_program/creature/New()
	. = ..()
	for(var/creature_type in choices)
		mob_type ||= creature_type
		options += choice_option(creature_type)

/// Привязывает учебный датум к сеансу полигона. FALSE - датум не учебный.
/datum/antagonist/proc/attach_training(datum/antag_training_session/session)
	return FALSE

/datum/antag_training_program/creature/proc/choice_option(creature_type)
	return "[choice_prompt]: [choices[creature_type]]"

/datum/antag_training_program/creature/setup(datum/antag_training_session/session)
	if(!spawn_creature_body(session))
		return FALSE
	QDEL_NULL(session.avatar)
	return TRUE

/datum/antag_training_program/creature/proc/role(datum/antag_training_session/session)
	return session.avatar_mind?.has_antag_datum(antag_type)

/datum/antag_training_program/creature/proc/creature_spawn_turf(datum/antag_training_session/session)
	var/datum/antag_training_sector/home = session.arena.sectors[sector]
	if(home?.state == ANTAG_TRAINING_SECTOR_READY)
		return home.spawn_turf()
	return session.arena.entry_turf

/// Создаёт моба роли на полигоне, выдаёт учебный датум до переноса разума и переносит в моба разум и игрока сеанса.
/datum/antag_training_program/creature/proc/spawn_creature_body(datum/antag_training_session/session, turf/where)
	var/datum/mind/soul = session.avatar_mind
	var/datum/antag_training_arena/arena = session.arena
	where ||= creature_spawn_turf(session)
	if(!mob_type || QDELETED(soul) || !soul.current || QDELETED(arena) || arena.finished || !arena.owns_area(get_area(where)))
		return null
	var/mob/body = new mob_type(where)
	body.register_training_atom()
	if(body.training_origin?.resolve() != arena)
		qdel(body)
		return null
	if(isanimal(body))
		var/mob/living/simple_animal/animal = body
		animal.toggle_ai(AI_OFF)
		animal.can_have_ai = FALSE
	var/datum/antagonist/fresh_role
	if(antag_type && !soul.has_antag_datum(antag_type))
		fresh_role = new antag_type
		fresh_role.silent = TRUE
		if(!fresh_role.attach_training(session) || !soul.add_antag_datum(fresh_role))
			stack_trace("[type]: учебный датум [antag_type] не выдан")
			qdel(fresh_role)
			qdel(body)
			return null
	var/mob/old_body = soul.current
	soul.transfer_to(body)
	if(soul.current != body)
		qdel(body)
		return null
	if(old_body?.ckey && !body.ckey)
		old_body.transfer_ckey(body, FALSE)
	body_ref = WEAKREF(body)
	deltimer(session.recovery_timer)
	session.recovery_timer = null
	refill(body)
	fresh_role?.greet()
	return body

/// Заменяет тело участника новым мобом роли и убирает прежнее, если оно было телом программы.
/datum/antag_training_program/creature/proc/replace_body(datum/antag_training_session/session, turf/where)
	if(rebuilding)
		return FALSE
	var/mob/lost = session.current_body
	var/own_body = lost && lost == body_ref?.resolve()
	var/mob/body = build_body(session, where)
	if(QDELETED(body) || session.current_body != body)
		return FALSE
	if(own_body && !QDELETED(lost))
		session.discard_body(lost)
	return TRUE

/// spawn_creature_body() под флагом rebuilding, который снимается и при рантайме.
/datum/antag_training_program/creature/proc/build_body(datum/antag_training_session/session, turf/where)
	rebuilding = TRUE
	try
		. = spawn_creature_body(session, where)
	catch(var/exception/error)
		rebuilding = FALSE
		throw error
	rebuilding = FALSE

/// Восполняет ресурс роли: здоровье, заряды, задержки способностей.
/datum/antag_training_program/creature/proc/refill(mob/body)
	return

/datum/antag_training_program/creature/rebuild_body(datum/antag_training_session/session)
	var/turf/here = get_turf(session.current_body)
	return replace_body(session, session.arena.owns_area(get_area(here)) ? here : null)

/datum/antag_training_program/creature/body_lost(datum/antag_training_session/session)
	if(rebuilding || session.finished || session.resetting || session.arena?.resetting)
		return FALSE
	rapid_rebuilds = (last_rebuild_at && world.time - last_rebuild_at < ANTAG_TRAINING_CREATURE_RAPID_WINDOW) ? rapid_rebuilds + 1 : 1
	last_rebuild_at = world.time
	if(rapid_rebuilds > ANTAG_TRAINING_CREATURE_RAPID_LIMIT)
		if(QDELETED(session.current_body))
			to_chat(session.current_body, span_warning("Тело роли теряется сразу после появления: новое не создаётся, сеанс завершён."))
		return FALSE
	if(!replace_body(session))
		return FALSE
	to_chat(session.current_body, span_notice(rebirth_message(session)))
	return TRUE

/// Что сказать участнику, когда body_lost() дал ему новое тело.
/datum/antag_training_program/creature/proc/rebirth_message(datum/antag_training_session/session)
	return "Вы восстановлены в вестибюле хаба новым телом. Можно продолжать тренировку."

/datum/antag_training_program/creature/handle_choice(datum/antag_training_session/session, mob/user, option)
	for(var/creature_type in choices)
		if(option == choice_option(creature_type))
			change_choice(session, user, creature_type)
			return TRUE
	return FALSE

/// Учебная цель рядом с существом на его площадке; null - отказ, сообщение участнику уже отправлено.
/datum/antag_training_program/creature/proc/spawn_prey_near(datum/antag_training_session/session, mob/living/body, template_id, hub_refusal)
	var/datum/antag_training_arena/arena = session.arena
	var/zone_id = arena.match_zone(body)
	if(!arena.zones[zone_id] || zone_id == "hub")
		to_chat(body, span_warning(hub_refusal))
		return null
	if(world.time < arena.next_spawn_at)
		to_chat(body, span_warning("Подождите секунду перед следующей целью."))
		return null
	arena.next_spawn_at = world.time + 1 SECONDS
	var/mob/living/prey = arena.spawn_creature(template_id, zone_id, FALSE, session, get_turf(body))
	if(!prey)
		to_chat(body, span_warning((arena.has_target_room() ? "Рядом нет свободного места для цели. Отойдите от стен и препятствий или перейдите на другую площадку." : arena.target_limit_refusal())))
	return prey

/datum/antag_training_program/creature/proc/change_choice(datum/antag_training_session/session, mob/user, creature_type)
	var/previous_type = mob_type
	mob_type = creature_type
	var/turf/here = get_turf(user)
	if(!replace_body(session, session.arena.owns_area(get_area(here)) ? here : null))
		mob_type = previous_type
		to_chat(user, span_warning("Тело не создалось. Попробуйте ещё раз в другом месте."))
		return FALSE
	log_game("[key_name(session.current_body)] на тренировочном полигоне меняет программу «[name]»: [choices[creature_type]].")
	return TRUE
