#define ANTAG_TRAINING_BEACON_LIGHT_RANGE 2
#define ANTAG_TRAINING_BEACON_LIGHT_POWER 0.6

/// Упражнение с реквизитом и учебной целью. Цель создаётся вне setup(): создание человека с формой может спать.
/datum/antag_training_exercise/drill
	/// Скафандр, инструменты и оружие нужны в руках человека.
	var/human_only = TRUE
	/// Удаление цели раньше конца проваливает прогон.
	var/target_required = TRUE

/// Тело этого типа может пройти упражнение; каталог и маршрут считают по нему упражнения программы.
/datum/antag_training_exercise/proc/fits_body(body_type)
	return TRUE

/// Почему упражнение недоступно этому участнику: игрок видит это на стенде и в отказе пульта.
/datum/antag_training_exercise/proc/unavailable_reason(datum/antag_training_session/session)
	var/datum/antag_training_program/needed = program
	if(needed && !istype(session.program, needed))
		return "это упражнение программы «[initial(needed.name)]»"
	return "не подходит ваше тело"

/datum/antag_training_exercise/drill/available(datum/antag_training_session/session)
	return ..() && fits_body(session.current_body?.type)

/datum/antag_training_exercise/drill/unavailable_reason(datum/antag_training_session/session)
	if(!program || istype(session.program, program))
		if(!fits_body(session.current_body?.type))
			return human_only ? "нужно человеческое тело" : "нужно тело, которое может коснуться цели"
	return ..()

/// Манекен и цель трогают руками или телом: бесплотному (ревенанту) это не по силам.
/datum/antag_training_exercise/drill/fits_body(body_type)
	if(human_only)
		return ispath(body_type, /mob/living/carbon/human)
	var/mob/living/body = body_type
	return ispath(body_type, /mob/living) && !initial(body.incorporeal_move)

/// Реквизит больше не обязателен: его удаление не проваливает прогон, остаток удалится вместе с прогоном.
/datum/antag_training_exercise_run/proc/release_prop(atom/movable/prop)
	if(!(prop in props))
		return
	UnregisterSignal(prop, COMSIG_PARENT_QDELETING)
	RegisterSignal(prop, COMSIG_PARENT_QDELETING, PROC_REF(on_spare_deleted))

/datum/antag_training_exercise/drill/proc/target_slot_free(datum/antag_training_session/session)
	session.arena.prune_targets()
	return length(session.arena.targets) < ANTAG_TRAINING_TARGET_LIMIT

/datum/antag_training_exercise/drill/proc/prepare_target(datum/antag_training_session/session, template_id, turf/near)
	session.preparing = TRUE
	INVOKE_ASYNC(src, PROC_REF(deliver_target), session, session.exercise_run, template_id, near)

/datum/antag_training_exercise/drill/proc/deliver_target(datum/antag_training_session/session, datum/antag_training_exercise_run/run, template_id, turf/near)
	var/mob/living/target = create_target(session, template_id, near)
	if(!QDELETED(session))
		session.preparing = FALSE
	if(QDELETED(run) || run.ended)
		if(target)
			QDEL_NULL(target.mind)
			qdel(target)
		return
	if(!run.add_prop(target, target_required))
		run.finish(FALSE, target_slot_free(session) ? "учебную цель не удалось создать, попробуйте ещё раз или сбросьте зону" : "учебная цель не создана: в лимите целей полигона нет места")
		return
	target_ready(run, target)
	run.rebind()

/datum/antag_training_exercise/drill/proc/create_target(datum/antag_training_session/session, template_id, turf/near)
	return session.arena.spawn_creature(template_id, sector, FALSE, session, near)

/datum/antag_training_exercise/drill/proc/target_ready(datum/antag_training_exercise_run/run, mob/living/target)
	return

/// Свободные клетки пола зоны рядом с участником, ближние первыми.
/datum/antag_training_exercise/drill/proc/free_spots(datum/antag_training_session/session, count)
	. = list()
	var/turf/center = get_turf(session.current_body)
	var/list/bounds = session.arena.zones[sector]?["bounds"]
	if(!center || !bounds)
		return
	for(var/radius in 1 to ANTAG_TRAINING_SPAWN_RADIUS)
		for(var/turf/open/floor/spot in orange(radius, center))
			if(get_dist(spot, center) != radius || !session.arena.inside_bounds(spot, bounds) || spot.is_blocked_turf(exclude_mobs = FALSE))
				continue
			. += spot
			if(length(.) >= count)
				return

/proc/antag_training_reached(atom/movable/body, atom/goal)
	var/turf/spot = get_turf(body)
	var/turf/goal_spot = get_turf(goal)
	return spot && goal_spot && spot.z == goal_spot.z && get_dist(spot, goal_spot) <= 1

/// Шаг упражнения с реквизитом: гибель участника и гибель учебной цели проваливают прогон, если шаг не разрешает её смерть.
/datum/antag_training_exercise_step/drill
	/// Причина провала, которую игрок видит, когда цель погибла на этом шаге; null - шаг разрешает смерть цели (убийство или мёртвая цель по сценарию).
	var/target_death = "учебная цель погибла раньше, чем шаг был выполнен"

/datum/antag_training_exercise_step/drill/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	var/mob/living/body = participant()
	if(body)
		RegisterSignal(body, COMSIG_MOB_DEATH, PROC_REF(on_participant_death))
	var/mob/living/target = exercise_target()
	if(target_death && target)
		RegisterSignal(target, COMSIG_MOB_DEATH, PROC_REF(on_target_death))

/datum/antag_training_exercise_step/drill/proc/exercise_target()
	return run?.find_prop(/mob/living)

/datum/antag_training_exercise_step/drill/proc/on_participant_death()
	SIGNAL_HANDLER
	run?.finish(FALSE, "вы погибли")

/datum/antag_training_exercise_step/drill/proc/on_target_death()
	SIGNAL_HANDLER
	run?.finish(FALSE, target_death)

/// Шаг с реквизитом и check(), как /checked: проверка сразу после подключения, затем раз в ANTAG_TRAINING_EXERCISE_CHECK_INTERVAL, если polling; события зовут recheck().
/datum/antag_training_exercise_step/drill/checked
	var/check_timer
	var/polling = TRUE

/datum/antag_training_exercise_step/drill/checked/attach(datum/antag_training_exercise_run/owner)
	. = ..()
	schedule_check(0)

/datum/antag_training_exercise_step/drill/checked/detach()
	deltimer(check_timer)
	check_timer = null
	return ..()

/datum/antag_training_exercise_step/drill/checked/Destroy()
	deltimer(check_timer)
	check_timer = null
	return ..()

/datum/antag_training_exercise_step/drill/checked/proc/schedule_check(delay = ANTAG_TRAINING_EXERCISE_CHECK_INTERVAL)
	deltimer(check_timer)
	check_timer = addtimer(CALLBACK(src, PROC_REF(recheck)), delay, TIMER_STOPPABLE)

/datum/antag_training_exercise_step/drill/checked/proc/recheck()
	SIGNAL_HANDLER
	if(done || !run || run.ended || run.current_step() != src)
		return
	if(check())
		complete()
	else if(polling && !done && !run.ended && run.current_step() == src)
		schedule_check()

/datum/antag_training_exercise_step/drill/checked/proc/check()
	SHOULD_NOT_SLEEP(TRUE)
	return FALSE

/obj/effect/antag_training_beacon
	name = "training beacon"
	desc = "Учебный маяк полигона: сюда ведёт текущий шаг упражнения."
	icon = 'icons/obj/device.dmi'
	icon_state = "beacon"
	anchored = TRUE

/obj/effect/antag_training_beacon/lit
	light_range = ANTAG_TRAINING_BEACON_LIGHT_RANGE
	light_power = ANTAG_TRAINING_BEACON_LIGHT_POWER
	light_color = LIGHT_COLOR_GREEN

#undef ANTAG_TRAINING_BEACON_LIGHT_RANGE
#undef ANTAG_TRAINING_BEACON_LIGHT_POWER
