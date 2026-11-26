/datum/unit_test/proc/path_lesson_heretic(path_id, base_type)
	var/datum/antagonist/heretic/heretic = allocate_heretic(heretic_lead_test_spot(0, 2))
	heretic.selected_path = path_id
	heretic.gain_knowledge(base_type)
	return heretic

/datum/unit_test/proc/path_lesson_grasp(mob/living/user, atom/target)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(target, user, TRUE)

/datum/unit_test/proc/path_lesson_blade_hit(mob/living/user, obj/item/melee/sickly_blade/blade, mob/living/target)
	blade.afterattack(target, user, TRUE, null)
	user.a_intent = INTENT_HARM
	blade.attack(target, user)

/// Урок Стекла проходит пять шагов настоящими действиями: призма, луч по шагнувшей вбок мишени, раскол меткой, переход и кража сквозь стекло.
/datum/unit_test/heretic_glass_lesson/Run()
	allocate(/datum/heretic_test_station_level, run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = path_lesson_heretic(PATH_GLASS, /datum/eldritch_knowledge/base_glass)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/datum/heretic_path_lesson/glass/lesson = new(null, glass, user, target)
	allocated += lesson
	TEST_ASSERT(heretic.get_knowledge(/datum/eldritch_knowledge/glass_mark) && heretic.get_knowledge(/datum/eldritch_knowledge/glass_passage), "Урок открывает метку и переход.")
	var/obj/item/melee/sickly_blade/glass/blade = locate() in user.held_items
	TEST_ASSERT_NOTNULL(blade, "Урок даёт стеклянный клинок в руку.")
	TEST_ASSERT(glass.shards(user, heretic_lead_test_spot(1, 4)), "Призма встаёт.")
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Призма открывает следящий луч.")
	var/turf/aimed = get_turf(target)
	TEST_ASSERT(glass.release(user, target), "Луч выпущен.")
	TEST_ASSERT(wait_for_var(lesson, NAMEOF(lesson, stage), 3, 3 SECONDS), "Луч по мишени открывает раскол.")
	TEST_ASSERT(get_turf(target) != aimed, "Мишень шагнула вбок во время наводки.")
	TEST_ASSERT(target.getBruteLoss() > 0 && target.getBruteLoss() < 30, "Луч довернул за мишенью, но задел вполсилы: [target.getBruteLoss()].")
	target.forceMove(get_step(user, EAST))
	target.SetKnockdown(0)
	path_lesson_grasp(user, target)
	path_lesson_blade_hit(user, blade, target)
	TEST_ASSERT(target.IsKnockdown(), "Метка расколола мишень.")
	TEST_ASSERT_EQUAL(lesson.stage, 4, "Раскол меткой открывает переход.")
	TEST_ASSERT_EQUAL(length(lesson.panes), 2, "Урок ставит два окна.")
	var/datum/weakref/near_ref = lesson.panes[1]
	var/datum/weakref/far_ref = lesson.panes[2]
	var/obj/structure/window/near = near_ref.resolve()
	var/obj/structure/window/far = far_ref.resolve()
	TEST_ASSERT(glass.attune(near, user) && glass.attune(far, user), "Оба окна настроены.")
	TEST_ASSERT(glass.travel(user, near, far), "Переход между стёклами: [glass.glass_failure]")
	TEST_ASSERT_EQUAL(lesson.stage, 5, "Переход открывает кражу.")
	TEST_ASSERT_EQUAL(heretic.hunt_target, target.mind, "Мишень стала целью охоты.")
	TEST_ASSERT(get_dist(target, near) <= 1, "Мишень встала у другого окна.")
	var/list/doors = glass.theft_doors(user, far)
	TEST_ASSERT_EQUAL(length(doors), 1, "Цель видна сквозь стекло.")
	TEST_ASSERT(glass.steal_through(user, far, doors[1]), "Кража сквозь стекло.")
	TEST_ASSERT(lesson.finished(), "Урок пройден.")
	TEST_ASSERT_EQUAL(length(lesson.steps()), 5, "В уроке пять шагов.")
	heretic.pocket.collapse("проверка")
	qdel(lesson)
	TEST_ASSERT(QDELETED(near) && QDELETED(far) && QDELETED(blade), "Реквизит урока убирается вместе с ним.")

/// Урок Пучины: прорыв, метка, Захлёб в своей воде, Течение и уход в слив ко второму прорыву.
/datum/unit_test/heretic_tide_lesson/Run()
	var/datum/antagonist/heretic/heretic = path_lesson_heretic(PATH_TIDE, /datum/eldritch_knowledge/base_tide)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(1, 2))
	var/datum/heretic_path_lesson/tide/lesson = new(null, tide, user, target)
	allocated += lesson
	var/obj/item/melee/sickly_blade/tide/harpoon = locate() in user.held_items
	TEST_ASSERT_NOTNULL(harpoon, "Урок даёт гарпун в руку.")
	var/obj/structure/sink/first = locate() in orange(1, user)
	TEST_ASSERT_NOTNULL(first, "Урок ставит раковину рядом.")
	path_lesson_grasp(user, first)
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Прорыв открывает метку.")
	path_lesson_grasp(user, target)
	path_lesson_blade_hit(user, harpoon, target)
	TEST_ASSERT_EQUAL(lesson.stage, 3, "Взрыв метки открывает Захлёб.")
	TEST_ASSERT(tide.on_own_water(target), "Под мишенью своя вода.")
	TEST_ASSERT(tide.drown(user, target), "Захлёб начат: [tide.tide_failure]")
	TEST_ASSERT(wait_for_var(lesson, NAMEOF(lesson, stage), 4, 3 SECONDS), "Захлёб в своей воде открывает Течение.")
	TEST_ASSERT(tide.create_current(user, heretic_lead_test_spot(4, 2)), "Течение легло: [tide.tide_failure]")
	TEST_ASSERT_EQUAL(lesson.stage, 5, "Течение открывает уход в слив.")
	var/obj/structure/sink/second
	for(var/obj/structure/sink/sink in range(5, user))
		if(sink != first)
			second = sink
	TEST_ASSERT_NOTNULL(second, "Урок ставит вторую раковину.")
	user.forceMove(get_step(second, get_dir(second, user)))
	path_lesson_grasp(user, second)
	TEST_ASSERT_EQUAL(length(tide.breaches), 2, "Второй прорыв открыт.")
	user.forceMove(heretic_lead_test_spot(0, 2))
	TEST_ASSERT(tide.dive(user, first, second), "Уход в слив: [tide.tide_failure]")
	TEST_ASSERT(get_dist(user, second) <= 1, "Ученик вынырнул у второго прорыва.")
	TEST_ASSERT(lesson.finished(), "Урок пройден.")
	qdel(lesson)
	TEST_ASSERT(QDELETED(first) && QDELETED(second) && QDELETED(harpoon), "Реквизит урока убирается вместе с ним.")

/// Урок Воска: кукла по отпечаткам, Сон по кукле сквозь стену, печать и оттиск, оболочка.
/datum/unit_test/heretic_wax_lesson/Run()
	allocate(/datum/heretic_test_station_level, run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = path_lesson_heretic(PATH_WAX, /datum/eldritch_knowledge/base_wax)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(3, 0))
	var/datum/heretic_path_lesson/wax/lesson = new(null, wax, user, target)
	allocated += lesson
	var/obj/item/pen/pen = locate() in orange(1, user)
	TEST_ASSERT_NOTNULL(pen, "Урок кладёт вещь с отпечатками рядом.")
	user.a_intent = INTENT_HELP
	path_lesson_grasp(user, pen)
	var/obj/item/heretic_wax_puppet/puppet = locate() in user.held_items
	TEST_ASSERT_EQUAL(puppet?.model_ref?.resolve(), target, "Кукла слеплена по отпечаткам мишени.")
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Кукла открывает Сон.")
	TEST_ASSERT_EQUAL(length(lesson.walls), 3, "Между учеником и мишенью встала стена.")
	TEST_ASSERT_EQUAL(heretic.hunt_target, target.mind, "Мишень стала целью охоты.")
	var/datum/weakref/wall_ref = lesson.walls[1]
	var/obj/structure/falsewall/wall = wall_ref.resolve()
	TEST_ASSERT(get_dist(user, target) > 1 && get_dist(user, wall) < get_dist(user, target), "Мишень за стеной.")
	TEST_ASSERT(wax.melt_puppet(user), "Кукла тает: [wax.wax_failure]")
	TEST_ASSERT(wait_for_var(lesson, NAMEOF(lesson, stage), 3, HERETIC_WAX_PUPPET_SLEEP_CHANNEL + 2 SECONDS), "Сон сквозь стену открывает оттиск.")
	TEST_ASSERT(target.IsSleeping(), "Мишень спит.")
	TEST_ASSERT(QDELETED(wall), "Стена уходит перед оттиском.")
	user.forceMove(get_step(target, get_dir(target, user)))
	path_lesson_grasp(user, target)
	TEST_ASSERT(wax.imprint(user, target), "Оттиск снят.")
	TEST_ASSERT_EQUAL(lesson.stage, 4, "Оттиск по печати открывает оболочку.")
	TEST_ASSERT(wax.raise_shell(user), "Оболочка поднята.")
	TEST_ASSERT(lesson.finished(), "Урок пройден.")
	qdel(lesson)
	TEST_ASSERT(QDELETED(pen), "Реквизит урока убирается вместе с ним.")

/// Урок Крови: связь, Метка Крови на втором должнике, частичное взыскание в «Разоружении» и путы в «Захвате».
/datum/unit_test/heretic_blood_lesson/Run()
	var/datum/antagonist/heretic/heretic = path_lesson_heretic(PATH_BLOOD, /datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/datum/heretic_path_lesson/blood/lesson = new(null, blood, user, target)
	allocated += lesson
	var/obj/effect/proc_holder/spell/pointed/heretic_blood/release/release = blood.combat_power
	release.cast(list(target), user)
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Связь открывает Метку Крови.")
	var/mob/living/second = lesson.second_ref?.resolve()
	TEST_ASSERT_NOTNULL(second, "Рядом встал второй должник.")
	path_lesson_grasp(user, second)
	TEST_ASSERT_EQUAL(lesson.stage, 3, "Метка Крови открывает взыскание.")
	TEST_ASSERT(QDELETED(second), "Второй должник уходит.")
	var/datum/status_effect/heretic_blood_seal/seal = target.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_EQUAL(seal?.debt, 20, "Долг мишени полон.")
	user.a_intent = INTENT_DISARM
	TEST_ASSERT(findtext(blood.release_mode(), "до"), "Подпись значка в «Разоружении» - частичное взыскание: [blood.release_mode()]")
	release.cast(list(target), user)
	TEST_ASSERT(wait_for_var(lesson, NAMEOF(lesson, stage), 4, 3 SECONDS), "Частичное взыскание открывает путы.")
	TEST_ASSERT(seal.debt > 0, "Остаток долга держит связь.")
	user.a_intent = INTENT_GRAB
	release.cast(list(target), user)
	TEST_ASSERT(target.has_status_effect(/datum/status_effect/heretic_blood_tether), "Путы на мишени.")
	TEST_ASSERT(lesson.finished(), "Урок пройден.")
	TEST_ASSERT_EQUAL(length(lesson.steps()), 4, "В уроке четыре шага.")

/// Связь мишени истекла до Метки: Хватка по второму должнику не съедает шаг, урок перевязывает мишень и просит повторить.
/datum/unit_test/heretic_blood_lesson_lapsed_bond/Run()
	var/datum/antagonist/heretic/heretic = path_lesson_heretic(PATH_BLOOD, /datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/datum/heretic_path_lesson/blood/lesson = new(null, blood, user, target)
	allocated += lesson
	var/obj/effect/proc_holder/spell/pointed/heretic_blood/release/release = blood.combat_power
	release.cast(list(target), user)
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Связь открывает Метку Крови.")
	var/mob/living/second = lesson.second_ref?.resolve()
	TEST_ASSERT_NOTNULL(second, "Рядом встал второй должник.")
	target.remove_status_effect(/datum/status_effect/heretic_blood_seal)
	path_lesson_grasp(user, second)
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Обычная связь со вторым шаг не засчитывает.")
	TEST_ASSERT(heretic_lead_test_wait(CALLBACK(target, TYPE_PROC_REF(/mob/living, has_status_effect), /datum/status_effect/heretic_blood_seal), 2 SECONDS, "связь мишени"), "Урок снова связал мишень.")
	TEST_ASSERT_NULL(second.has_status_effect(/datum/status_effect/heretic_blood_seal), "Случайная связь со вторым снята.")
	path_lesson_grasp(user, second)
	TEST_ASSERT_EQUAL(lesson.stage, 3, "Повторная Хватка ставит Метку и открывает взыскание.")

/// На шаге Метки связь мишени не истекает, пока ученик ждёт перезарядку Хватки.
/datum/unit_test/heretic_blood_lesson_holds_bond/Run()
	var/datum/antagonist/heretic/heretic = path_lesson_heretic(PATH_BLOOD, /datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(3, 2))
	var/datum/heretic_path_lesson/blood/lesson = new(null, blood, user, target)
	allocated += lesson
	var/obj/effect/proc_holder/spell/pointed/heretic_blood/release/release = blood.combat_power
	release.cast(list(target), user)
	TEST_ASSERT_EQUAL(lesson.stage, 2, "Связь открывает Метку Крови.")
	var/datum/status_effect/heretic_blood_seal/seal = target.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_NOTNULL(seal, "Мишень связана.")
	var/started = seal.expires_at
	var/list/budget = new_wait_budget(5 SECONDS, "продление связи на уроке")
	while(!QDELETED(seal) && seal.expires_at < started + 2 SECONDS)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(!QDELETED(seal) && seal.expires_at >= started + 2 SECONDS, "Связь мишени продлевается на шаге Метки: [seal.expires_at - started] дс.")

/// Учебный стрелок Свинца не ранит: непойманная пуля только толкает, а выбывшего стрелка урок заменяет.
/datum/unit_test/heretic_lead_lesson_drill/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LEAD)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.forceMove(heretic_lead_test_spot(0, 2))
	var/datum/eldritch_knowledge/base_lead/lead = heretic.get_knowledge(/datum/eldritch_knowledge/base_lead)
	var/mob/living/carbon/human/target = heretic_lead_test_crew(heretic_lead_test_spot(2, 4))
	var/datum/heretic_lead_lesson/lesson = new(null, lead, user, target)
	allocated += lesson
	lesson.set_stage(6)
	var/mob/living/gunner = lesson.gunner_ref?.resolve()
	TEST_ASSERT_NOTNULL(gunner, "На шаге ловли выходит учебный стрелок.")
	var/obj/item/projectile/bullet = lesson.drill_shot()
	TEST_ASSERT_NOTNULL(bullet, "Стрелок стреляет.")
	heretic_lead_test_fly(bullet)
	TEST_ASSERT(QDELETED(bullet), "Учебная пуля долетела.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Непойманная учебная пуля не ранит.")
	TEST_ASSERT_EQUAL(lesson.stage, 6, "Непойманная пуля шаг не засчитывает.")
	gunner.death()
	lesson.drill()
	var/mob/living/fresh = lesson.gunner_ref?.resolve()
	TEST_ASSERT(fresh && fresh != gunner && fresh.stat == CONSCIOUS, "Вместо выбывшего стрелка выходит новый.")
	TEST_ASSERT(QDELETED(gunner), "Выбывший стрелок убран.")
	qdel(lesson)
	TEST_ASSERT(QDELETED(fresh), "Стрелок уходит вместе с уроком.")

/datum/unit_test/proc/check_training_path_lesson(path_id, lesson_id, step_count)
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	TEST_ASSERT(!session.start_practice(lesson_id), "Без пути урока [lesson_id] нет.")
	TEST_ASSERT(session.prepare_path(path_id, 1), "Подготовлен путь [path_id].")
	session.arena.next_spawn_at = 0
	TEST_ASSERT(session.start_practice(lesson_id), "Урок [lesson_id] начинается.")
	var/datum/heretic_path_lesson/lesson = session.path_lesson
	TEST_ASSERT(istype(lesson, GLOB.heretic_path_lessons[lesson_id]), "Сеанс держит урок [lesson_id].")
	TEST_ASSERT(session.practice_available(lesson_id), "Упражнение урока доступно в списке сектора.")
	var/list/data = session.ui_data(session.current_body)
	var/list/button = data["path_lesson"]
	TEST_ASSERT_EQUAL(button?["id"], lesson_id, "Панель показывает кнопку урока.")
	var/list/practice = data["practice"]
	TEST_ASSERT_EQUAL(length(practice["steps"]), step_count, "Панель показывает шаги урока.")
	TEST_ASSERT(findtext(session.practice_hint, "Шаг 1 из [step_count]"), "Подсказка упражнения - первый шаг урока.")
	var/list/atom/movable/props = list()
	for(var/datum/weakref/prop_ref as anything in lesson.props)
		props += prop_ref.resolve()
	session.stop_practice()
	TEST_ASSERT(QDELETED(lesson), "Конец упражнения убирает урок.")
	for(var/atom/movable/prop as anything in props)
		TEST_ASSERT(QDELETED(prop), "Конец упражнения убирает [prop].")

/datum/unit_test/antag_training_glass_lesson/Run()
	check_training_path_lesson(PATH_GLASS, "glass", 5)

/datum/unit_test/antag_training_tide_lesson/Run()
	check_training_path_lesson(PATH_TIDE, "tide", 5)

/datum/unit_test/antag_training_wax_lesson/Run()
	check_training_path_lesson(PATH_WAX, "wax", 4)

/datum/unit_test/antag_training_blood_lesson/Run()
	check_training_path_lesson(PATH_BLOOD, "blood", 4)

/datum/unit_test/antag_training_dusk_lesson/Run()
	check_training_path_lesson(PATH_DUSK, "dusk", 10)

/// После урока подготовка пути доводит его до девятой ступени: ступени, выданные уроком, не запирают следующие.
/datum/unit_test/proc/check_lesson_path_stage(path_id, lesson_id)
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	TEST_ASSERT(!session.prepare_path(1, 1) && !session.issue_kit(1) && !session.issue_equipment(1, session.current_body), "Нетекстовые id пути, набора и снаряжения отвергаются.")
	TEST_ASSERT(isnull(session.build_structure(1, session.current_body)) && isnull(session.arena.spawn_creature(1, 1)), "Нетекстовые id постройки и цели отвергаются.")
	TEST_ASSERT(session.prepare_path(path_id, 1), "Подготовлен путь [path_id].")
	session.arena.next_spawn_at = 0
	TEST_ASSERT(!session.start_practice(1), "Нетекстовый id упражнения отвергается.")
	TEST_ASSERT(session.start_practice(lesson_id), "Урок [lesson_id] начинается.")
	session.next_supply_at = 0
	TEST_ASSERT(session.prepare_path(path_id, 9), "Путь [path_id] готовится до девятой ступени.")
	var/datum/antagonist/heretic/heretic = IS_HERETIC(session.current_body)
	TEST_ASSERT_EQUAL(heretic?.path_stage, 9, "После урока [lesson_id] путь доходит до девятой ступени.")
	session.stop_practice()

/datum/unit_test/antag_training_glass_lesson_stage/Run()
	check_lesson_path_stage(PATH_GLASS, "glass")

/datum/unit_test/antag_training_tide_lesson_stage/Run()
	check_lesson_path_stage(PATH_TIDE, "tide")

/datum/unit_test/antag_training_wax_lesson_stage/Run()
	check_lesson_path_stage(PATH_WAX, "wax")

/datum/unit_test/antag_training_blood_lesson_stage/Run()
	check_lesson_path_stage(PATH_BLOOD, "blood")

/datum/unit_test/antag_training_dusk_lesson_stage/Run()
	check_lesson_path_stage(PATH_DUSK, "dusk")

/datum/unit_test/antag_training_sand_lesson_stage/Run()
	check_lesson_path_stage(PATH_SAND, "sand")

/datum/unit_test/antag_training_spirit_lesson_stage/Run()
	check_lesson_path_stage(PATH_SPIRIT, "spirit")

/datum/unit_test/antag_training_dance_lesson_stage/Run()
	check_lesson_path_stage(PATH_DANCE, "dance")

/datum/unit_test/antag_training_lead_lesson_stage/Run()
	check_lesson_path_stage(PATH_LEAD, "lead")

/// Числа боевых советов полигона совпадают с дефайнами механик.
/datum/unit_test/heretic_combat_practice_numbers/Run()
	var/shake = HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)
	var/list/fragments = list(
		PATH_RUST = list("держат до [HERETIC_RUST_ROOTS_DURATION / (1 SECONDS)] секунд"),
		PATH_FLESH = list("ползун в [HERETIC_FLESH_LATCH_REACH] клетках вцепляется в неё и держит до [HERETIC_FLESH_LATCH_DURATION / (1 SECONDS)] секунд", "за [HERETIC_FLESH_SHED_COST] биомассу уводит вас в самого дальнего слугу в [HERETIC_FLESH_SHED_RANGE] клетках"),
		PATH_BLADE = list("замрёт до [HERETIC_BLADE_THROAT_DURATION / (1 SECONDS)] секунд"),
		PATH_COSMIC = list("через [HERETIC_COSMIC_LEASH_TIME / (1 SECONDS)] секунды привязь", "через [HERETIC_COSMIC_ROAD_CHANNEL / (1 SECONDS)] секунды на месте", "в [HERETIC_COSMIC_ORBIT_RANGE] клетках от своей звезды: [HERETIC_COSMIC_ORBIT_DURATION / (1 SECONDS)] секунд"),
		PATH_LOCK = list("мишень в [HERETIC_LOCK_SHACKLES_RANGE] клетках: через полсекунды она [HERETIC_LOCK_SHACKLES_OTHER / (1 SECONDS)] секунды", "проводит [HERETIC_LOCK_SHACKLES_DURATION / (1 SECONDS)] секунд"),
		PATH_BLOOD = list("[HERETIC_BLOOD_TETHER_COST] долга уходят на путы: [HERETIC_BLOOD_TETHER_DURATION / (1 SECONDS)] секунды"),
		PATH_ECHO = list("[HERETIC_ECHO_LULLABY_DROWSE / (1 SECONDS)] секунды она идёт на [HERETIC_ECHO_LULLABY_SLOWDOWN * 100]% медленнее", "Тишину на [HERETIC_ECHO_HUSH_DURATION / (1 SECONDS)] секунды", "вырывает за [HERETIC_ECHO_HUSH_GRAB_COST] резонанса"),
		PATH_WAX = list("[HERETIC_WAX_PUPPET_SLEEP_CHANNEL / (1 SECONDS)] секунд держите куклу", "дальше [HERETIC_WAX_PUPPET_SLEEP_RANGE] клеток"),
		PATH_SPIRIT = list("замрёт до [HERETIC_SPIRIT_HOLD_DURATION / (1 SECONDS)] секунд", "Бесплотность на [HERETIC_SPIRIT_INCORPOREAL_DURATION / (1 SECONDS)] секунды"),
	)
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/text = path.combat_practice
		if(findtext(text, "растолкает"))
			TEST_ASSERT(findtext(text, "за [shake] секунды"), "Совет пути [path_id]: растолкать за [shake] секунды.")
		for(var/fragment in fragments[path_id])
			TEST_ASSERT(findtext(text, fragment), "Совет пути [path_id] расходится с дефайном: нет «[fragment]».")
