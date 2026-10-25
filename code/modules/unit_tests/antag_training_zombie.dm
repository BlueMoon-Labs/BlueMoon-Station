/// Программа зомби обращает аватар сразу и без повторного полного лечения; когти заражают учебную цель, которая после смерти встаёт учебным зомби; снятие программы убирает заразу аватара и целей.
/datum/unit_test/antag_training_zombie/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/zombie)
	TEST_ASSERT(session.prepare(), "Полигон готовит зомби.")
	var/datum/antag_training_program/antag/zombie/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/zombie/training/role = program.role(session)
	TEST_ASSERT(istype(role), "Аватар получает учебного зомби.")
	TEST_ASSERT(iszombie_infectious(body), "Аватар обращён сразу при выдаче.")
	var/obj/item/organ/zombie_infection/avatar_infection = body.getorganslot(ORGAN_SLOT_ZOMBIE)
	TEST_ASSERT_NOTNULL(avatar_infection, "У аватара зараза в голове.")
	avatar_infection.process(SSOBJ_DT)
	TEST_ASSERT_NULL(avatar_infection.timer_id, "Живой обращённый аватар не получает повторного обращения с полным лечением.")
	var/obj/item/zombie_hand/claw = locate() in body.held_items
	TEST_ASSERT_NOTNULL(claw, "У аватара когти вместо рук.")
	TEST_ASSERT(length(program.option_hints["Цель для заражения"]), "У кнопки есть подсказка.")

	var/list/laboratory = session.arena.zones["laboratory"]
	body.forceMove(laboratory["spawn"])
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Цель для заражения"))
	var/mob/living/carbon/human/dummy = program.recent_target(session)
	TEST_ASSERT_NOTNULL(dummy, "Кнопка ставит учебную цель.")
	TEST_ASSERT(get_dist(dummy, body) <= ANTAG_TRAINING_SPAWN_RADIUS, "Цель встаёт рядом.")
	dummy.forceMove(get_step(body, EAST))
	body.a_intent = INTENT_HARM
	claw.melee_attack_chain(body, dummy)
	var/obj/item/organ/zombie_infection/dummy_infection = dummy.getorganslot(ORGAN_SLOT_ZOMBIE)
	TEST_ASSERT_NOTNULL(dummy_infection, "Удар когтями заражает учебную цель.")

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для заражения"))
	var/mob/living/carbon/human/carrier = program.recent_target(session)
	TEST_ASSERT(carrier && carrier != dummy, "Вторая цель встала.")
	carrier.forceMove(get_step(body, WEST))
	claw.melee_attack_chain(body, carrier)
	var/obj/item/organ/zombie_infection/carrier_infection = carrier.getorganslot(ORGAN_SLOT_ZOMBIE)
	TEST_ASSERT_NOTNULL(carrier_infection, "Вторая цель заражена и жива.")

	dummy.death()
	dummy_infection.process(SSOBJ_DT)
	TEST_ASSERT(dummy_infection.timer_id, "Смерть заражённой цели заводит таймер подъёма.")
	deltimer(dummy_infection.timer_id)
	dummy_infection.zombify()
	TEST_ASSERT(dummy.stat != DEAD && iszombie_infectious(dummy), "Цель встаёт зомби.")
	var/datum/antagonist/zombie/risen = dummy.mind.has_antag_datum(/datum/antagonist/zombie)
	TEST_ASSERT_EQUAL(risen?.type, /datum/antagonist/zombie/training, "Цель полигона встаёт учебным зомби, а не зомби раунда.")
	TEST_ASSERT(!risen.show_to_ghosts && !risen.show_in_roundend && risen.soft_antag, "Вставший зомби скрыт от раунда.")

	antag_training_console_act(session, console, "restart", list("program" = "[/datum/antag_training_program/free]"))
	TEST_ASSERT(istype(session.program, /datum/antag_training_program/free) && QDELETED(body), "Пульт сменил программу.")
	TEST_ASSERT(!(avatar_infection in GLOB.zombie_infection_list), "Зараза аватара уходит с программой.")
	TEST_ASSERT(!(dummy_infection in GLOB.zombie_infection_list) && !(carrier_infection in GLOB.zombie_infection_list), "Зараза учебных целей уходит с программой.")
	TEST_ASSERT(!iszombie(dummy) && isnull(dummy.mind.has_antag_datum(/datum/antagonist/zombie)), "Вставшая цель снова человек без роли зомби.")
	TEST_ASSERT_NULL(carrier.getorganslot(ORGAN_SLOT_ZOMBIE), "Живая заражённая цель вылечена.")

/// «Заражение и подъём»: удар когтями, смерть заражённой цели и её подъём учебным зомби засчитываются по шагам; смерть до заражения проваливает упражнение.
/datum/unit_test/antag_training_zombie_exercise/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/antag/zombie)
	TEST_ASSERT(session.prepare(), "Полигон готовит зомби.")
	var/datum/antag_training_program/antag/zombie/program = session.program
	var/mob/living/carbon/human/body = session.current_body
	var/datum/antagonist/zombie/training/role = program.role(session)
	TEST_ASSERT(findtext(role.briefing(), "Заражение и подъём"), "Приветствие называет упражнение.")
	var/obj/item/zombie_hand/claw = locate() in body.held_items
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	antag_training_console_act(session, console, "move", list("zone" = "laboratory"))
	var/datum/antag_training_exercise_run/run = start_training_drill(session, console, "zombie_infection")
	TEST_ASSERT(run && !run.ended, "Упражнение зомби стартует в лаборатории.")
	var/mob/living/carbon/human/dummy = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT(dummy?.mind && (dummy.mind in session.arena.target_minds), "Цель упражнения - учебный манекен.")

	dummy.forceMove(get_step(body, EAST))
	body.a_intent = INTENT_HARM
	claw.melee_attack_chain(body, dummy)
	TEST_ASSERT(wait_for_drill_step(run, 2), "Удар когтями засчитан как заражение.")
	var/obj/item/organ/zombie_infection/infection = dummy.getorganslot(ORGAN_SLOT_ZOMBIE)
	TEST_ASSERT_NOTNULL(infection, "В цели зараза.")

	var/list/zones = list(BODY_ZONE_CHEST, BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	for(var/hit in 1 to 60)
		if(dummy.stat == DEAD)
			break
		body.zone_selected = zones[(hit % length(zones)) + 1]
		claw.melee_attack_chain(body, dummy)
	TEST_ASSERT_EQUAL(dummy.stat, DEAD, "Когти добивают цель.")
	TEST_ASSERT(wait_for_drill_step(run, 3), "Смерть заражённой цели засчитана: [run.result_text]")
	if(!infection.timer_id)
		infection.process(SSOBJ_DT)
	TEST_ASSERT(infection.timer_id, "Смерть заражённой цели заводит таймер подъёма.")
	TEST_ASSERT(!run.ended, "До подъёма упражнение идёт.")
	deltimer(infection.timer_id)
	infection.zombify()
	TEST_ASSERT(wait_for_drill_step(run, 4) && run.ended && run.success, "Подъём цели завершает упражнение: [run.result_text]")
	var/datum/antagonist/zombie/risen = dummy.mind.has_antag_datum(/datum/antagonist/zombie)
	TEST_ASSERT_EQUAL(risen?.type, /datum/antagonist/zombie/training, "Цель встала учебным зомби.")

	run = start_training_drill(session, console, "zombie_infection")
	TEST_ASSERT(run && !run.ended, "Упражнение начинается заново.")
	TEST_ASSERT(QDELETED(dummy), "Вставший зомби прошлого прогона убран.")
	dummy = run.find_prop(/mob/living/carbon/human)
	dummy.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "до заражения"), "Смерть цели до заражения проваливает упражнение: [run.result_text]")
