/datum/unit_test/proc/demon_crawl_cast(mob/living/simple_animal/slaughter/body)
	var/obj/effect/proc_holder/spell/bloodcrawl/crawl = locate() in body.mob_spell_list
	usr = body
	crawl.action.Trigger()
	usr = null

/// Ждёт готовности Blood Crawl и кастует его так, как кнопка действия; TRUE, когда моб сменил loc.
/datum/unit_test/proc/demon_crawl(mob/living/simple_animal/slaughter/body, description)
	var/obj/effect/proc_holder/spell/bloodcrawl/crawl = locate() in body.mob_spell_list
	var/list/budget = new_wait_budget(5 SECONDS, "перезарядка Blood Crawl: [description]")
	while((crawl.charge_counter < crawl.charge_max || body.mob_transforming) && wait_budget_tick(budget))
		continue
	var/atom/start = body.loc
	INVOKE_ASYNC(src, PROC_REF(demon_crawl_cast), body)
	budget = new_wait_budget(5 SECONDS, description)
	while(body.loc == start && wait_budget_tick(budget))
		continue
	return body.loc != start

/datum/unit_test/proc/demon_pool_press(datum/antag_training_session/session, datum/tgui/console)
	var/datum/antag_training_program/creature/slaughter/program = session.program
	var/list/before = program.blood_pools.Copy()
	session.next_supply_at = 0
	antag_training_console_act(session, console, "program_option", list("option" = "Лужи крови рядом"))
	var/list/fresh = list()
	for(var/datum/weakref/pool_ref as anything in program.blood_pools - before)
		fresh += pool_ref.resolve()
	return fresh

/// Тащит учебную цель в лужу и ждёт конца пира: демон в крови, цель внутри, здоровье полное.
/datum/unit_test/proc/demon_feast(datum/antag_training_session/session, datum/tgui/console, mob/living/simple_animal/slaughter/body)
	antag_training_console_act(session, console, "program_option", list("option" = "Цель для утаскивания"))
	var/mob/living/carbon/human/prey
	for(var/mob/living/carbon/human/candidate in session.arena.targets)
		if(candidate.training_owner?.resolve() == session && candidate.stat == UNCONSCIOUS)
			prey = candidate
	TEST_ASSERT_NOTNULL(prey, "Цель для утаскивания создана без сознания и принадлежит участнику.")
	TEST_ASSERT(body.Adjacent(prey), "Цель лежит рядом с демоном.")
	body.CtrlClickOn(prey)
	TEST_ASSERT_EQUAL(body.pulling, prey, "Демон берёт цель.")
	body.adjustHealth(body.maxHealth / 2)
	TEST_ASSERT(demon_crawl(body, "погружение с целью"), "Демон погружается в лужу вместе с целью.")
	var/list/budget = new_wait_budget(15 SECONDS, "пир демона")
	while(!((prey in body.consumed_mobs) && abs(body.health - body.maxHealth) < 0.1) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(istype(body.loc, /obj/effect/dummy/phased_mob/slaughter), "Демон с добычей в крови.")
	TEST_ASSERT_EQUAL(prey.loc, body, "Цель утащена внутрь демона.")
	TEST_ASSERT(abs(body.health - body.maxHealth) < 0.1, "Пир полностью лечит демона.")
	TEST_ASSERT(prey in session.arena.targets, "Съеденная цель остаётся в лимите целей.")
	return prey

/// Демон резни ныряет в учебную лужу и выходит из другой, пир утащенной цели лечит его, после смерти съеденные выпадают без сердца демона, а демон появляется заново в тёмном секторе.
/datum/unit_test/antag_training_slaughter/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/slaughter)
	TEST_ASSERT(session.prepare(), "Полигон готовит демона резни.")
	var/datum/antag_training_program/creature/slaughter/program = session.program
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["dark"]
	var/mob/living/simple_animal/slaughter/training/body = session.current_body
	TEST_ASSERT(istype(body), "Тело сеанса - учебный демон резни.")
	var/list/budget = new_wait_budget(30 SECONDS, "демон в тёмном секторе")
	while(!(sector.state == ANTAG_TRAINING_SECTOR_READY && arena.inside_bounds(get_turf(body), sector.bounds)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT_EQUAL(get_turf(body), sector.spawn_turf(), "Демон начинает в центре тёмного сектора.")
	var/obj/effect/dummy/phased_mob/slaughter/start_holder = body.loc
	TEST_ASSERT(istype(start_holder) && body.holder == start_holder, "По умолчанию демон начинает в крови.")
	var/datum/tgui/console = allocate(/datum/tgui, body, session, "AntagTraining")
	for(var/option in program.options)
		TEST_ASSERT(length(program.option_hints[option]), "У кнопки «[option]» есть подсказка.")

	antag_training_console_act(session, console, "move", list("zone" = "melee"))
	TEST_ASSERT_EQUAL(body.loc, start_holder, "Перенос пультом не вытаскивает демона из крови.")
	TEST_ASSERT_EQUAL(get_turf(body), arena.zones["melee"]["spawn"], "Демон в крови переносится вместе с кровью.")
	var/list/first_pools = demon_pool_press(session, console)
	TEST_ASSERT(length(first_pools), "Кнопка разливает лужи и из крови.")
	var/obj/effect/decal/cleanable/blood/under = locate() in get_turf(body)
	TEST_ASSERT((under in first_pools) && under.can_bloodcrawl_in(), "Под демоном пригодная лужа.")
	TEST_ASSERT_EQUAL(under.training_owner?.resolve(), session, "Лужи принадлежат участнику.")
	TEST_ASSERT(demon_crawl(body, "выход из крови"), "Blood Crawl выводит демона из крови.")
	TEST_ASSERT(isturf(body.loc) && !body.holder && QDELETED(start_holder), "Демон проявился, кровь-носитель убрана.")
	TEST_ASSERT((locate(/obj/effect/decal/cleanable/blood) in body.loc) in first_pools, "Демон выходит у лужи.")

	var/mob/living/carbon/human/prey = demon_feast(session, console, body)
	TEST_ASSERT_NOTNULL(prey, "Пир учебной цели состоялся.")
	TEST_ASSERT_EQUAL(prey.stat, DEAD, "Демон резни съедает цель.")
	var/obj/effect/dummy/phased_mob/slaughter/holder = body.loc
	for(var/step in 1 to 4)
		holder.relaymove(body, WEST)
	var/turf/drifted = get_turf(body)
	TEST_ASSERT(get_dist(drifted, arena.zones["melee"]["spawn"]) >= 3, "Демон плывёт в крови.")
	var/list/second_pools = demon_pool_press(session, console)
	TEST_ASSERT(demon_crawl(body, "выход у другой лужи"), "Демон выходит из крови снова.")
	var/obj/effect/decal/cleanable/blood/exit_pool = locate() in body.loc
	TEST_ASSERT(isturf(body.loc) && (exit_pool in second_pools), "Демон выходит у другой лужи.")

	body.death()
	TEST_ASSERT_EQUAL(session.defeats, 1, "Смерть демона учитывается.")
	TEST_ASSERT_EQUAL(prey.loc, get_turf(body), "Съеденная цель выпадает рядом с трупом.")
	TEST_ASSERT(!length(body.consumed_mobs), "Внутри мёртвого демона никого не осталось.")
	for(var/turf/near in range(2, body))
		TEST_ASSERT_NULL(locate(/obj/item/organ/heart/demon) in near, "Сердце демона не выпадает.")
	TEST_ASSERT(antag_training_wait_new_body(session, body, "демон после смерти"), "После смерти появляется новый демон.")
	var/mob/living/simple_animal/slaughter/training/reborn = session.current_body
	TEST_ASSERT(QDELETED(body), "Труп прежнего демона убран.")
	TEST_ASSERT(istype(reborn) && reborn.stat == CONSCIOUS && reborn.mind == session.avatar_mind, "Новый демон жив и с разумом участника.")
	TEST_ASSERT_EQUAL(get_turf(reborn), sector.spawn_turf(), "Новый демон в центре тёмного сектора.")
	TEST_ASSERT(istype(reborn.loc, /obj/effect/dummy/phased_mob/slaughter), "Новый демон снова в крови.")
	TEST_ASSERT(prey in arena.targets, "Выпавшая цель остаётся на полигоне.")

	antag_training_console_act(session, console, "program_option", list("option" = "Начало: проявленным"))
	var/mob/living/simple_animal/slaughter/training/manifest = session.current_body
	TEST_ASSERT(manifest != reborn && QDELETED(reborn), "Выбор начала пересоздаёт демона.")
	TEST_ASSERT(isturf(manifest.loc) && !manifest.holder, "Демон появляется проявленным.")
	TEST_ASSERT_EQUAL(get_turf(manifest), sector.spawn_turf(), "Проявленный демон в центре сектора.")

	for(var/press in 1 to 5)
		demon_pool_press(session, console)
	var/live_pools = 0
	for(var/datum/weakref/pool_ref as anything in program.blood_pools)
		var/obj/effect/decal/cleanable/blood/pool = pool_ref.resolve()
		if(!QDELETED(pool))
			live_pools++
	TEST_ASSERT_EQUAL(live_pools, program.pool_cap, "Луж программы не больше предела.")
	TEST_ASSERT(QDELETED(under), "Новые лужи убирают самые старые.")
	pass(view(0, run_loc_floor_bottom_left))

/// Демон смеха после смерти выпускает обнятую цель живой, котёнок не остаётся.
/datum/unit_test/antag_training_laughter/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/slaughter/laughter)
	TEST_ASSERT(session.prepare(), "Полигон готовит демона смеха.")
	var/datum/tgui/console = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Начало: проявленным"))
	var/mob/living/simple_animal/slaughter/laughter/training/body = session.current_body
	TEST_ASSERT(istype(body) && isturf(body.loc), "Демон смеха стоит проявленным.")
	antag_training_console_act(session, console, "move", list("zone" = "melee"))
	TEST_ASSERT(length(demon_pool_press(session, console)), "Рядом с демоном лужи.")
	var/mob/living/carbon/human/prey = demon_feast(session, console, body)
	TEST_ASSERT_NOTNULL(prey, "Пир учебной цели состоялся.")
	TEST_ASSERT_EQUAL(prey.stat, DEAD, "Обнятая цель внутри мертва.")

	body.death()
	TEST_ASSERT_EQUAL(prey.loc, get_turf(body), "Обнятая цель выходит рядом с трупом.")
	TEST_ASSERT(prey.stat != DEAD && abs(prey.health - prey.maxHealth) < 0.1, "Демон смеха выпускает цель живой и здоровой.")
	for(var/turf/near in range(2, body))
		TEST_ASSERT_NULL(locate(/mob/living/simple_animal/pet/cat/kitten) in near, "Котёнок не появляется.")
	TEST_ASSERT(antag_training_wait_new_body(session, body, "демон смеха после смерти"), "После смерти появляется новый демон смеха.")
	TEST_ASSERT(istype(session.current_body, /mob/living/simple_animal/slaughter/laughter/training), "Новое тело - демон смеха.")
	pass(view(0, run_loc_floor_bottom_left))

/// Удалённая из пульта съеденная цель не остаётся в демоне, а тело другого участника выпадает сразу после пира.
/datum/unit_test/antag_training_slaughter_victims/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/creature/slaughter)
	TEST_ASSERT(session.prepare(), "Полигон готовит демона резни.")
	var/datum/tgui/console = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, console, "program_option", list("option" = "Начало: проявленным"))
	var/mob/living/simple_animal/slaughter/training/body = session.current_body
	antag_training_console_act(session, console, "move", list("zone" = "melee"))
	TEST_ASSERT(length(demon_pool_press(session, console)), "Рядом с демоном лужи.")
	var/mob/living/carbon/human/prey = demon_feast(session, console, body)
	TEST_ASSERT_NOTNULL(prey, "Пир учебной цели состоялся.")
	antag_training_console_act(session, console, "target_delete", list("id" = REF(prey)))
	TEST_ASSERT(QDELETED(prey), "Пульт удаляет съеденную цель.")
	TEST_ASSERT(!(prey in body.consumed_mobs), "Удалённая цель не остаётся в демоне.")
	TEST_ASSERT(demon_crawl(body, "выход после пира"), "Демон выходит из крови.")

	var/datum/antag_training_session/second = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(second.prepare(), "Второй участник входит на полигон.")
	var/mob/living/carbon/human/rival = second.current_body
	var/turf/beside
	for(var/turf/open/spot in orange(1, body))
		if(!spot.is_blocked_turf(exclude_mobs = FALSE))
			beside = spot
			break
	TEST_ASSERT_NOTNULL(beside, "Рядом с демоном есть место.")
	rival.forceMove(beside)
	rival.Unconscious(1 MINUTES, TRUE, TRUE)
	body.CtrlClickOn(rival)
	TEST_ASSERT_EQUAL(body.pulling, rival, "Демон берёт другого участника.")
	TEST_ASSERT(demon_crawl(body, "погружение с участником"), "Демон уходит в кровь с участником.")
	TEST_ASSERT_EQUAL(rival.loc, body, "Участник утащен внутрь демона.")
	var/list/budget = new_wait_budget(15 SECONDS, "пир участником")
	while(body.mob_transforming && wait_budget_tick(budget))
		continue
	TEST_ASSERT_EQUAL(rival.stat, DEAD, "Пир участником состоялся.")
	TEST_ASSERT(rival.loc != body && !(rival in body.consumed_mobs), "Тело участника выпадает сразу после пира.")
	TEST_ASSERT_EQUAL(second.current_body, rival, "Участник остаётся в своём теле.")

	var/atom/rival_spot = rival.loc
	var/list/nearby = list()
	for(var/mob/living/carbon/human/person in range(2, body))
		nearby += person
	body.death()
	var/list/after = list()
	for(var/mob/living/carbon/human/person in range(2, body))
		after += person
	TEST_ASSERT(!length(after - nearby), "После смерти демона рядом никто не появился.")
	TEST_ASSERT_EQUAL(rival.loc, rival_spot, "Смерть демона не переносит другого участника.")
	TEST_ASSERT(antag_training_wait_new_body(session, body, "демон после смерти"), "Демон появляется заново.")
	qdel(second)
	pass(view(0, run_loc_floor_bottom_left))
