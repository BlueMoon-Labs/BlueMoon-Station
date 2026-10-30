/datum/antag_training_program/antag/zombie
	name = "Зомби"
	category = "Существа"
	desc = "Обращение сразу, без медленного отравления: когти, регенерация, заражение учебных целей, которые после смерти встают учебными зомби. Упражнение «Заражение и подъём» в лаборатории проводит весь цикл: удар когтями, смерть, подъём."
	icon = "biohazard"
	color = "olive"
	learn = "Когти и регенерация|Заражение ударом когтей|Смерть заражённого и подъём|Чем зомби останавливают"
	difficulty = 1
	antag_type = /datum/antagonist/zombie/training
	options = list("Цель для заражения")
	var/datum/antag_training_session/training_session

/datum/antag_training_program/antag/zombie/New()
	. = ..()
	var/obj/item/organ/zombie_infection/infection = /obj/item/organ/zombie_infection
	option_hints = list(
		"Цель для заражения" = "Рядом встанет манекен с разумом. Удар когтями заражает его; живого зараза только травит, а после смерти через [initial(infection.revive_time_min) / (1 SECONDS)]-[initial(infection.revive_time_max) / (1 SECONDS)] секунд он встаёт учебным зомби. Зараза сидит в голове: без головы тело не встанет. Из безопасного центра манекен встаёт в лаборатории. Снятие программы лечит ваши манекены, а заражённый аватар другого участника вылечится только с концом его сеанса. По шагам и с оценкой - упражнение «Заражение и подъём» в лаборатории.",
	)

/datum/antag_training_program/antag/zombie/setup(datum/antag_training_session/session)
	training_session = session
	return ..()

/datum/antag_training_program/antag/zombie/Destroy()
	cure_targets()
	training_session = null
	return ..()

/// Снятие программы лечит заразу у учебных целей участника.
/datum/antag_training_program/antag/zombie/proc/cure_targets()
	var/datum/antag_training_arena/arena = training_session?.arena
	for(var/mob/living/carbon/target in arena?.targets)
		if(target.training_owner != training_session.weak_reference)
			continue
		var/obj/item/organ/zombie_infection/infection = target.getorganslot(ORGAN_SLOT_ZOMBIE)
		if(!infection)
			continue
		infection.Remove()
		qdel(infection)

/datum/antag_training_program/antag/zombie/handle_choice(datum/antag_training_session/session, mob/living/user, option)
	if(..())
		return TRUE
	if(!role(session))
		if(!grant_role(session))
			to_chat(user, span_warning("Роль зомби не выдалась. Начните новым персонажем."))
			return FALSE
		to_chat(user, span_notice("Вы снова зомби. В раунде окончательно убитый зомби им больше не встаёт."))
	if(option == "Цель для заражения")
		place_infection_target(session, user)
	return TRUE

/datum/antag_training_program/antag/zombie/proc/place_infection_target(datum/antag_training_session/session, mob/living/user)
	var/mob/living/carbon/human/dummy = place_practice_dummy(session, user)
	if(dummy)
		to_chat(user, span_notice("[dummy.real_name] встал[dummy.ru_a()] в зоне «[dummy_zone_name(session, dummy)]»."))
	return dummy

/datum/antagonist/zombie/training
	name = "Учебный зомби"
	show_in_roundend = FALSE
	show_in_antagpanel = FALSE
	show_in_check_antagonists = FALSE
	show_name_in_check_antagonists = FALSE
	show_to_ghosts = FALSE
	soft_antag = TRUE
	prevent_roundtype_conversion = FALSE
	replace_banned = FALSE
	reminded_times_left = 0
	threat = 0
	converts_living = TRUE
	var/datum/antag_training_session/training

/datum/antagonist/zombie/training/threat()
	return 0

/datum/antagonist/zombie/training/apply_innate_effects(mob/living/mob_override)
	. = ..()
	if(zombie_organ)
		zombie_organ.converts_living = FALSE

/datum/antagonist/zombie/training/greet()
	antag_training_greet_on_login(src, CALLBACK(src, PROC_REF(brief)))

/datum/antagonist/zombie/training/proc/brief()
	to_chat(owner.current, briefing())

/datum/antagonist/zombie/training/proc/briefing()
	var/obj/item/organ/zombie_infection/infection = /obj/item/organ/zombie_infection
	var/datum/antag_training_exercise/exercise = /datum/antag_training_exercise/drill/zombie_infection
	return jointext(list(
		span_boldnotice("Тренировка зомби. Вы уже обращены: когти вместо рук, раны затягиваются сами, если вас какое-то время не бьют, а в крите вдвое быстрее. Вы медленные, зато не задыхаетесь и не чувствуете холода и давления."),
		span_notice("Удар когтями заражает человека. Живого зараза травит, а после смерти он встаёт зомби через [initial(infection.revive_time_min) / (1 SECONDS)]-[initial(infection.revive_time_max) / (1 SECONDS)] секунд. Роботов не заразить, мёртвых не-людей когти разрывают и лечат вас, двери и вещи бьют втрое сильнее."),
		span_notice("Зомби падает, но не умирает: остановить его можно наручниками, отрубленной головой или тем, что разнесёт тело. Помните об этом, когда прячете заражённых."),
		span_notice("Упражнение «[initial(exercise.name)]» в лаборатории ведёт по шагам: заразить цель, добить её и дождаться подъёма. Пульт, вкладка «Упражнения»."),
		span_notice("«Пульт полигона», раздел «Моя роль»: «Цель для заражения» ставит манекен рядом. Заражённые на полигоне встают учебными зомби, снятие программы их лечит."),
	), "<br>")

/datum/antagonist/zombie/training/on_removal()
	var/obj/item/organ/zombie_infection/infection = zombie_organ
	zombie_organ = null
	. = ..()
	if(!QDELETED(infection) && infection.owner)
		infection.Remove()
		qdel(infection)

/datum/antagonist/zombie/training/Destroy()
	training = null
	zombie_organ = null
	return ..()

/datum/antag_training_exercise/drill/zombie_infection
	id = "zombie_infection"
	name = "Заражение и подъём"
	desc = "Учебная цель встаёт рядом с вами в лаборатории. Заразите её ударом когтей, добейте и дождитесь, пока она встанет учебным зомби."
	sector = "laboratory"
	program = /datum/antag_training_program/antag/zombie
	difficulty = 1
	par_time = 2 MINUTES
	steps = list(/datum/antag_training_exercise_step/drill/checked/zombie/infect, /datum/antag_training_exercise_step/drill/checked/zombie/kill, /datum/antag_training_exercise_step/drill/checked/zombie/rise)

/datum/antag_training_exercise/drill/zombie_infection/setup(datum/antag_training_session/session)
	if(!target_slot_free(session))
		return FALSE
	prepare_target(session, "human", get_turf(session.current_body))
	return TRUE

/// Заражение, смерть и подъём проверяются раз в секунду: орган заразы сигнала не шлёт.
/datum/antag_training_exercise_step/drill/checked/zombie
	/// Без органа заразы в цели шаг проваливает прогон.
	var/needs_infection = TRUE

/datum/antag_training_exercise_step/drill/checked/zombie/check()
	var/mob/living/carbon/target = exercise_target()
	if(!target)
		return FALSE
	if(needs_infection && !infection(target))
		run.finish(FALSE, "зараза пропала из цели: без головы или после лечения тело не встанет")
		return FALSE
	return reached(target)

/datum/antag_training_exercise_step/drill/checked/zombie/proc/reached(mob/living/carbon/target)
	return FALSE

/datum/antag_training_exercise_step/drill/checked/zombie/proc/infection(mob/living/carbon/target)
	return istype(target) && target.getorganslot(ORGAN_SLOT_ZOMBIE)

/datum/antag_training_exercise_step/drill/checked/zombie/infect
	name = "Заразите цель ударом когтей"
	hint = "Подойдите к цели и ударьте её когтями на намерении вреда (harm): первый же удар заносит заразу в голову. Цель должна быть жива, пока заражение не засчитано."
	target_death = "цель умерла до заражения"
	needs_infection = FALSE

/datum/antag_training_exercise_step/drill/checked/zombie/infect/reached(mob/living/carbon/target)
	return infection(target)

/// Удар, который заразил цель, мог её и добить: тогда заражение засчитано, а смерть проверит следующий шаг.
/datum/antag_training_exercise_step/drill/checked/zombie/infect/on_target_death()
	if(infection(exercise_target()))
		complete()
		return
	return ..()

/datum/antag_training_exercise_step/drill/checked/zombie/kill
	name = "Добейте заражённую цель"
	hint = "Бейте цель когтями, пока она не умрёт: живого заражённого зараза только травит, встают одни мёртвые. Голову не отрывайте - зараза сидит в ней."
	target_death = null

/datum/antag_training_exercise_step/drill/checked/zombie/kill/reached(mob/living/carbon/target)
	return target.stat == DEAD

/datum/antag_training_exercise_step/drill/checked/zombie/rise
	name = "Дождитесь подъёма цели"
	hint = "Делать ничего не нужно: зараза сама поднимает мёртвого меньше чем через пару минут. Не трогайте тело, пока оно лежит."
	target_death = null

/datum/antag_training_exercise_step/drill/checked/zombie/rise/New()
	. = ..()
	var/obj/item/organ/zombie_infection/sample = /obj/item/organ/zombie_infection
	hint = "Делать ничего не нужно: зараза поднимает мёртвого через [initial(sample.revive_time_min) / (1 SECONDS)]-[initial(sample.revive_time_max) / (1 SECONDS)] секунд. Не трогайте тело, пока оно лежит. Вставшая цель - учебный зомби, снятие программы её вылечит."

/datum/antag_training_exercise_step/drill/checked/zombie/rise/reached(mob/living/carbon/target)
	return target.stat != DEAD && iszombie(target)
