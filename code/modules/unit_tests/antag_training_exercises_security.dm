/datum/unit_test/proc/allocate_security_trainee()
	wait_for_closing_training_arenas()
	var/datum/antag_training_session/session = new /datum/antag_training_session(/datum/antag_training_program/free, null, "crew:Security Officer")
	allocated += session
	return session

/datum/unit_test/proc/security_free_beside(atom/thing)
	for(var/direction in GLOB.alldirs)
		var/turf/open/spot = get_step(thing, direction)
		if(istype(spot) && !spot.is_blocked_turf(exclude_mobs = FALSE))
			return spot

/// «Задержание»: только для СБ; нарушитель убегает от участника, толчок дубинкой засчитывает падение, наручники и доставка в пост охраны завершают упражнение, гибель нарушителя проваливает его.
/datum/unit_test/antag_training_exercise_security_detain/Run()
	var/datum/antag_training_session/plain = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(plain.prepare(), "Полигон готов для участника без должности.")
	var/datum/antag_training_exercise/detain = GLOB.antag_training_exercises["security_detain"]
	TEST_ASSERT(!detain.available(plain), "Без должности СБ задержание недоступно.")
	var/board_text = jointext(plain.arena.zone_exercise_names(detain.sector, plain), "; ")
	TEST_ASSERT(findtext(board_text, "должность службы безопасности") && findtext(board_text, "Снаряжение и бой"), "Стенд называет причину недоступности: [board_text]")
	qdel(plain)
	allocated -= plain

	var/datum/antag_training_session/session = allocate_security_trainee()
	TEST_ASSERT(session.prepare(), "Полигон готов для офицера СБ.")
	TEST_ASSERT(detain.available(session), "Офицеру СБ задержание доступно.")
	var/mob/living/carbon/human/user = session.current_body
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	var/datum/antag_training_sector/station = enter_training_sector(session, ui, "station")
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "security_detain")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в станционном макете.")
	var/mob/living/carbon/human/target = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(target, "Упражнение ставит нарушителя.")
	var/turf/mark = station.landmark_turf("brig")
	TEST_ASSERT_EQUAL(get_turf(run.find_prop(/obj/effect/antag_training_beacon)), mark, "Маяк стоит на метке брига.")

	var/list/hall = antag_training_room_turfs(station.spawn_turf(), station)
	TEST_ASSERT(get_turf(target) in hall, "Нарушитель в зале прибытия.")
	target.forceMove(antag_training_room_center(hall))
	user.forceMove(security_free_beside(target))
	var/distance = get_dist(user, target)
	var/list/budget = new_wait_budget(3 SECONDS, "нарушитель убегает")
	while(get_dist(user, target) <= distance && wait_budget_tick(budget))
		continue
	TEST_ASSERT(get_dist(user, target) > distance, "Нарушитель убегает от участника.")

	var/obj/item/melee/baton/loaded/baton = run.find_prop(/obj/item/melee/baton/loaded)
	TEST_ASSERT(baton && !(baton in user.GetAllContents()), "Офицеру с пустым поясом упражнение кладёт дубинку у ног.")
	TEST_ASSERT(drill_hold(user, baton), "Участник держит дубинку.")
	baton.attack_self(user)
	user.forceMove(security_free_beside(target))
	baton.alt_pre_attack(target, user)
	TEST_ASSERT(wait_for_drill_step(run, 2), "Толчок дубинкой засчитан: [run.result_text]")

	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs, get_turf(user))
	TEST_ASSERT(drill_hold(user, cuffs), "Участник держит наручники.")
	cuffs.attack(target, user)
	TEST_ASSERT_EQUAL(target.handcuffed, cuffs, "Наручники надеты.")
	TEST_ASSERT(wait_for_drill_step(run, 3), "Наручники засчитаны: [run.result_text]")
	var/turf/start = get_turf(target)
	budget = new_wait_budget(2 SECONDS, "закованный стоит")
	while(wait_budget_tick(budget))
		continue
	TEST_ASSERT_EQUAL(get_turf(target), start, "Закованный нарушитель не убегает.")

	var/turf/post_spot = security_free_beside(mark)
	user.forceMove(security_free_beside(post_spot))
	user.start_pulling(target)
	TEST_ASSERT_EQUAL(user.pulling, target, "Участник тащит задержанного.")
	target.forceMove(post_spot)
	TEST_ASSERT(wait_for_var(run, "ended", TRUE), "Задержанный в посту охраны завершает упражнение.")
	TEST_ASSERT(run.success, "Упражнение выполнено: [run.result_text]")

	user.forceMove(station.spawn_turf())
	run = start_training_drill(session, ui, "security_detain")
	target = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(target, "Повтор ставит нового нарушителя.")
	target.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "задержание, а не убийство"), "Гибель нарушителя проваливает упражнение: [run.result_text]")

/// «Обыск и конфискация»: нож в кармане задержанного, изъятие через окно обыска и шкаф улик в посту охраны.
/datum/unit_test/antag_training_exercise_security_search/Run()
	var/datum/antag_training_session/session = allocate_security_trainee()
	TEST_ASSERT(session.prepare(), "Полигон готов для офицера СБ.")
	var/mob/living/carbon/human/user = session.current_body
	var/datum/tgui/ui = allocate(/datum/tgui, user, session, "AntagTraining")
	enter_training_sector(session, ui, "station")
	var/datum/antag_training_exercise_run/run = start_training_drill(session, ui, "security_search")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в станционном макете.")
	var/mob/living/carbon/human/target = run.find_prop(/mob/living/carbon/human)
	var/obj/structure/closet/secure_closet/evidence/locker = run.find_prop(/obj/structure/closet/secure_closet/evidence)
	var/obj/item/switchblade/knife = run.find_prop(/obj/item/switchblade)
	TEST_ASSERT(target && locker && knife, "Есть задержанный, шкаф улик и нож.")
	TEST_ASSERT_EQUAL(target.r_store, knife, "Нож в правом кармане задержанного.")
	TEST_ASSERT(!locker.locked, "Шкаф улик не заперт.")

	user.forceMove(security_free_beside(target))
	user.drop_all_held_items()
	var/datum/element/strippable/strippable = SSdcs.GetElement(list(/datum/element/strippable, GLOB.strippable_human_items, TYPE_PROC_REF(/mob/living/carbon/human, should_strip)))
	var/datum/strippable_item/pocket = strippable.items[STRIPPABLE_ITEM_RPOCKET]
	pocket.finish_unequip(target, user)
	TEST_ASSERT(user.is_holding(knife), "Нож изъят в руку участника.")
	TEST_ASSERT_EQUAL(run.step_index, 2, "Изъятие засчитано.")

	user.forceMove(security_free_beside(locker))
	locker.attack_hand(user)
	TEST_ASSERT(locker.opened, "Шкаф улик открыт.")
	locker.attackby(knife, user)
	TEST_ASSERT(!run.ended, "Нож у открытого шкафа ещё не убран.")
	locker.attack_hand(user)
	TEST_ASSERT_EQUAL(knife.loc, locker, "Нож в закрытом шкафу.")
	TEST_ASSERT(run.ended && run.success, "Нож в шкафу улик завершает упражнение: [run.result_text]")

	run = start_training_drill(session, ui, "security_search")
	target = run.find_prop(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(target, "Повтор ставит нового задержанного.")
	target.death()
	TEST_ASSERT(run.ended && !run.success && findtext(run.result_text, "обыск, а не расправа"), "Гибель задержанного проваливает упражнение: [run.result_text]")
