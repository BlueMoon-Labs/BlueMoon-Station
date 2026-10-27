/datum/unit_test/proc/antag_training_revenant_in_sector(datum/antag_training_session/session)
	var/datum/antag_training_sector/sector = session.arena.sectors["dark"]
	var/list/budget = new_wait_budget(30 SECONDS, "ревенант в тёмном секторе")
	while(!(sector.state == ANTAG_TRAINING_SECTOR_READY && session.arena.inside_bounds(get_turf(session.current_body), sector.bounds)) && wait_budget_tick(budget))
		continue
	return sector.state == ANTAG_TRAINING_SECTOR_READY && session.arena.inside_bounds(get_turf(session.current_body), sector.bounds)

/datum/unit_test/proc/antag_training_revenant_roles(mob/living/body)
	. = 0
	for(var/datum/antagonist/revenant/held in body.mind?.antag_datums)
		.++

/datum/unit_test/proc/antag_training_admin_ping(mob/caster)
	for(var/text in GLOB.unit_test_admin_messages)
		if(findtext(text, "[caster] cast spell"))
			return TRUE
	return FALSE

/// Учебный ревенант в тёмном секторе: скрытый датум без целей, кнопки пульта, жатва манекена в крите кликом даёт эссенцию, речь не выходит за полигон и не слышит ревенанта станции.
/datum/unit_test/antag_training_revenant/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/revenant)
	TEST_ASSERT(session.prepare(), "Полигон готовит ревенанта.")
	TEST_ASSERT(antag_training_revenant_in_sector(session), "Ревенант появляется в тёмном секторе.")
	var/datum/antag_training_program/creature/revenant/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	var/mob/living/simple_animal/revenant/training/body = session.current_body
	TEST_ASSERT(istype(body) && body.mind == session.avatar_mind, "Разум участника в учебном ревенанте.")
	var/datum/antagonist/revenant/training/role = program.role(session)
	TEST_ASSERT(istype(role) && role.training == session && !length(role.objectives), "Учебный датум ревенанта привязан к сеансу и без целей.")
	TEST_ASSERT_EQUAL(antag_training_revenant_roles(body), 1, "Настоящий датум ревенанта не добавляется.")
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	for(var/option in program.options)
		TEST_ASSERT(length(program.option_hints[option]), "У кнопки «[option]» есть подсказка.")

	var/obj/effect/proc_holder/spell/aoe_turf/revenant/malfunction/malfunction = locate() in body.mob_spell_list
	TEST_ASSERT_NOTNULL(malfunction, "У ревенанта есть Malfunction.")
	body.essence = 1
	antag_training_console_act(session, console, "heal", list())
	TEST_ASSERT_EQUAL(body.essence, body.essence_regen_cap, "Восстановление из пульта доводит эссенцию до предела, а не выше.")
	body.essence = 1
	body.essence_excess = 0
	body.drained_mobs += body
	malfunction.charge_counter = 0
	antag_training_console_act(session, console, "program_option", list("option" = "Эссенция до максимума"))
	TEST_ASSERT_EQUAL(body.essence, body.essence_regen_cap, "Кнопка доводит эссенцию до предела.")
	TEST_ASSERT(!length(body.drained_mobs), "Кнопка забывает выпитые души.")
	TEST_ASSERT(malfunction.can_cast(body), "Самую дорогую способность можно открыть сразу.")

	antag_training_console_act(session, console, "program_option", list("option" = "Лампы для перегрузки"))
	var/list/lamps = list()
	for(var/obj/machinery/light/floor/lamp in range(2, body))
		if(lamp.training_owner?.resolve() == session)
			lamps += lamp
	TEST_ASSERT(length(lamps), "Вокруг ревенанта стоят лампы участника.")
	var/list/budget = new_wait_budget(5 SECONDS, "лампы загораются")
	var/lit = FALSE
	while(!lit && wait_budget_tick(budget))
		lit = TRUE
		for(var/obj/machinery/light/floor/lamp as anything in lamps)
			lit = lit && lamp.on
	TEST_ASSERT(lit, "Лампы горят и годятся для перегрузки.")

	antag_training_console_act(session, console, "program_option", list("option" = "Цель для жатвы"))
	var/mob/living/carbon/human/prey
	for(var/mob/living/carbon/human/candidate in arena.targets)
		if(candidate.training_owner?.resolve() == session)
			prey = candidate
	TEST_ASSERT_NOTNULL(prey, "Цель для жатвы создана и принадлежит участнику.")
	TEST_ASSERT_EQUAL(arena.match_zone(prey), "dark", "Цель встаёт в секторе ревенанта.")
	TEST_ASSERT_EQUAL(prey.stat, SOFT_CRIT, "Цель в критическом состоянии.")
	body.forceMove(get_turf(prey))
	var/stolen_before = body.essence_accumulated
	var/cap_before = body.essence_regen_cap
	body.ClickOn(prey)
	budget = new_wait_budget(20 SECONDS, "жатва манекена")
	while(!(prey in body.drained_mobs) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(prey in body.drained_mobs, "Клик по манекену в крите выпивает его душу.")
	TEST_ASSERT(body.essence_accumulated > stolen_before, "Жатва даёт украденную эссенцию.")
	TEST_ASSERT(body.essence_regen_cap > cap_before, "Живая душа поднимает предел эссенции.")
	TEST_ASSERT_EQUAL(prey.stat, DEAD, "Выпитый манекен умирает.")

	var/mob/dead/observer/outsider = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	var/mob/dead/observer/watcher = allocate(/mob/dead/observer, run_loc_floor_bottom_left)
	watcher.forceMove(get_turf(body))
	var/mob/living/simple_animal/revenant/station_revenant = allocate(/mob/living/simple_animal/revenant, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/revenant/station_partner = allocate(/mob/living/simple_animal/revenant, run_loc_floor_bottom_left)
	GLOB.unit_test_chat_capture = list()
	body.say("Учебный зов ревенанта")
	station_revenant.say("Зов ревенанта станции")
	var/partner_heard_station = antag_training_chat_heard(station_partner, "Зов ревенанта станции")
	var/self_heard = antag_training_chat_heard(body, "Учебный зов ревенанта")
	var/watcher_heard = antag_training_chat_heard(watcher, "Учебный зов ревенанта")
	var/outsider_heard_training = antag_training_chat_heard(outsider, "Учебный зов ревенанта")
	var/station_heard_training = antag_training_chat_heard(station_revenant, "Учебный зов ревенанта")
	var/training_heard_station = antag_training_chat_heard(body, "Зов ревенанта станции")
	var/outsider_heard_station = antag_training_chat_heard(outsider, "Зов ревенанта станции")
	GLOB.unit_test_chat_capture = null
	TEST_ASSERT(self_heard && watcher_heard, "Речь учебного ревенанта слышат он сам и наблюдатель на полигоне.")
	TEST_ASSERT(!outsider_heard_training, "Наблюдатель вне полигона не слышит учебного ревенанта.")
	TEST_ASSERT(!station_heard_training, "Ревенант станции не слышит учебного.")
	TEST_ASSERT(!training_heard_station, "Учебный ревенант не слышит ревенанта станции.")
	TEST_ASSERT(outsider_heard_station, "Речь ревенанта станции по-прежнему слышат наблюдатели.")
	TEST_ASSERT(partner_heard_station, "Ревенанты станции по-прежнему слышат друг друга.")

	var/obj/effect/proc_holder/spell/targeted/night_vision/revenant/training_sight = locate() in body.mob_spell_list
	var/obj/effect/proc_holder/spell/targeted/night_vision/revenant/station_sight = locate() in station_revenant.mob_spell_list
	station_revenant.mind_initialize()
	allocated += station_revenant.mind
	var/training_alpha = body.lighting_alpha
	GLOB.unit_test_admin_messages = list()
	usr = body
	training_sight.action.Trigger()
	var/training_pinged = antag_training_admin_ping(body)
	usr = station_revenant
	station_sight.action.Trigger()
	usr = null
	var/station_pinged = antag_training_admin_ping(station_revenant)
	GLOB.unit_test_admin_messages = null
	TEST_ASSERT(body.lighting_alpha != training_alpha, "Учебный ревенант переключает ночное зрение кнопкой.")
	TEST_ASSERT(!training_pinged, "Ночное зрение учебного ревенанта не пишет администраторам.")
	TEST_ASSERT(station_pinged, "Ночное зрение ревенанта станции по-прежнему видно администраторам.")
	pass(view(0, run_loc_floor_bottom_left))

/// Смерть учебного ревенанта оставляет эктоплазму, через несколько секунд тот же ревенант собирается в центре сектора без призрака и опроса, а рассеянная эктоплазма даёт новое тело.
/datum/unit_test/antag_training_revenant_reform/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/revenant)
	TEST_ASSERT(session.prepare(), "Полигон готовит ревенанта.")
	TEST_ASSERT(antag_training_revenant_in_sector(session), "Ревенант появляется в тёмном секторе.")
	var/datum/antag_training_program/creature/revenant/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	var/mob/living/simple_animal/revenant/training/body = session.current_body
	var/turf/home = program.creature_spawn_turf(session)
	body.forceMove(sector.target_turf())
	var/mob/living/carbon/human/attacker = arena.spawn_creature("human", "dark", FALSE, session, get_turf(body))
	TEST_ASSERT_NOTNULL(attacker, "Рядом есть манекен с ящиком для инструментов.")
	var/obj/item/storage/toolbox/mechanical/toolbox = new(get_turf(attacker))
	attacker.put_in_active_hand(toolbox)
	attacker.a_intent = INTENT_HARM
	var/dead_before = length(GLOB.dead_mob_list)

	body.reveal(10 SECONDS)
	body.essence = 1
	toolbox.melee_attack_chain(attacker, body)
	TEST_ASSERT(body.stasis && body.invisibility == INVISIBILITY_ABSTRACT, "Удар по раскрытому ревенанту без эссенции его рассыпает.")
	var/obj/item/ectoplasm/revenant/training/residue = locate() in get_turf(body)
	TEST_ASSERT(residue && residue.revenant == body, "На месте смерти остаётся учебная эктоплазма.")
	TEST_ASSERT_EQUAL(residue.training_origin?.resolve(), arena, "Эктоплазма принадлежит полигону.")
	TEST_ASSERT_EQUAL(session.defeats, 1, "Смерть ревенанта учитывается в счётчике.")
	TEST_ASSERT(!session.finished && body.mind == session.avatar_mind, "Разум остаётся в ревенанте, сеанс идёт.")
	TEST_ASSERT_EQUAL(length(GLOB.dead_mob_list), dead_before, "Смерть ревенанта не создаёт призрака.")
	var/list/budget = new_wait_budget(10 SECONDS, "сборка ревенанта из эктоплазмы")
	while(!QDELETED(residue) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(QDELETED(residue), "Эктоплазма собирается в ревенанта.")
	TEST_ASSERT(!session.finished && session.current_body == body && !QDELETED(body), "Сеанс продолжается в том же ревенанте.")
	TEST_ASSERT(!body.stasis && !body.revealed && body.invisibility == INVISIBILITY_REVENANT, "Собранный ревенант снова невидим и подвижен.")
	TEST_ASSERT_EQUAL(body.essence, body.essence_regen_cap, "Собранный ревенант с полной эссенцией.")
	TEST_ASSERT_EQUAL(get_turf(body), home, "Ревенант собирается в центре сектора.")
	TEST_ASSERT_EQUAL(body.mind, session.avatar_mind, "Сборка не ищет игрока среди мёртвых и не зовёт призраков.")
	TEST_ASSERT_EQUAL(length(GLOB.dead_mob_list), dead_before, "Сборка не трогает список мёртвых.")
	TEST_ASSERT_EQUAL(antag_training_revenant_roles(body), 1, "После сборки у разума один учебный датум ревенанта.")

	body.forceMove(get_turf(attacker))
	body.reveal(10 SECONDS)
	body.essence = 1
	toolbox.melee_attack_chain(attacker, body)
	residue = locate() in get_turf(body)
	TEST_ASSERT_NOTNULL(residue, "Вторая смерть снова оставляет эктоплазму.")
	residue.attack_self(attacker)
	TEST_ASSERT(QDELETED(residue) && QDELETED(body), "Рассеянная эктоплазма уносит прежнее тело.")
	var/mob/living/simple_animal/revenant/training/rebuilt = session.current_body
	TEST_ASSERT(istype(rebuilt) && !QDELETED(rebuilt) && rebuilt.mind == session.avatar_mind, "Вместо рассеянного появляется новый ревенант с разумом участника.")
	TEST_ASSERT_EQUAL(get_turf(rebuilt), home, "Новый ревенант появляется в центре сектора.")
	TEST_ASSERT(!session.finished, "Сеанс продолжается.")
	TEST_ASSERT_EQUAL(length(GLOB.dead_mob_list), dead_before, "Новое тело не оставляет призрака.")
	pass(view(0, run_loc_floor_bottom_left))

/// Сброс тёмного сектора или пополнение эссенции, пока ревенант рассыпан, возвращают того же ревенанта, и сеанс не завершается.
/datum/unit_test/antag_training_revenant_reset/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/revenant)
	TEST_ASSERT(session.prepare(), "Полигон готовит ревенанта.")
	TEST_ASSERT(antag_training_revenant_in_sector(session), "Ревенант появляется в тёмном секторе.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	var/mob/living/simple_animal/revenant/training/body = session.current_body
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	var/mob/living/carbon/human/attacker = arena.spawn_creature("human", "dark", FALSE, session, get_turf(body))
	TEST_ASSERT_NOTNULL(attacker, "Рядом есть манекен с ящиком для инструментов.")
	var/obj/item/storage/toolbox/mechanical/toolbox = new(get_turf(attacker))
	attacker.put_in_active_hand(toolbox)
	attacker.a_intent = INTENT_HARM

	body.reveal(10 SECONDS)
	body.essence = 1
	toolbox.melee_attack_chain(attacker, body)
	TEST_ASSERT(body.stasis, "Ревенант рассыпан.")
	antag_training_console_act(session, console, "program_option", list("option" = "Эссенция до максимума"))
	TEST_ASSERT(!body.stasis && !(locate(/obj/item/ectoplasm/revenant/training) in get_turf(body)), "Пополнение собирает рассыпанного ревенанта на месте.")
	var/turf/spot = get_turf(body)
	var/list/budget = new_wait_budget(10 SECONDS, "таймер восстановления после пополнения")
	while(session.recovery_timer && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!session.recovery_timer && !session.finished, "Таймер восстановления отработал, сеанс идёт.")
	TEST_ASSERT(session.current_body == body && get_turf(body) == spot, "Таймер восстановления не заменяет уже собранного ревенанта.")

	body.reveal(10 SECONDS)
	body.essence = 1
	toolbox.melee_attack_chain(attacker, body)
	var/obj/item/ectoplasm/revenant/training/residue = locate() in get_turf(body)
	TEST_ASSERT_NOTNULL(residue, "Смерть оставляет эктоплазму.")
	antag_training_console_act(session, console, "reset_zone", list("zone" = "dark"))
	budget = new_wait_budget(30 SECONDS, "сброс тёмного сектора")
	while(!session.finished && (!QDELETED(residue) || arena.resetting || sector.state != ANTAG_TRAINING_SECTOR_READY) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!session.finished, "Сброс сектора, пока ревенант рассыпан, не завершает сеанс.")
	TEST_ASSERT(QDELETED(residue) && !arena.resetting && sector.state == ANTAG_TRAINING_SECTOR_READY, "Сектор сброшен вместе с эктоплазмой.")
	TEST_ASSERT(!session.finished && session.current_body == body && !QDELETED(body) && body.mind == session.avatar_mind, "Сброс сектора не завершает сеанс и оставляет ревенанта с разумом участника.")
	TEST_ASSERT(!body.stasis && body.invisibility == INVISIBILITY_REVENANT, "Ревенант после сброса собран.")
	budget = new_wait_budget(10 SECONDS, "таймер восстановления после сброса")
	while(session.recovery_timer && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!session.finished && session.current_body == body && !QDELETED(body), "После таймера восстановления участник в том же ревенанте.")
