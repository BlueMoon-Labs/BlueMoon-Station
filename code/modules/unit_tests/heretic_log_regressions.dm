/datum/eldritch_knowledge/flesh_grasp/ghost_poll_probe
	var/last_poll_body
	var/last_poll_duration

/datum/eldritch_knowledge/flesh_grasp/ghost_poll_probe/poll_servant_candidates(question, mob/living/body, duration)
	last_poll_body = REF(body)
	last_poll_duration = duration
	return list()

/datum/eldritch_knowledge/flesh_ghoul/ghost_poll_probe
	var/last_poll_body
	var/last_poll_duration

/datum/eldritch_knowledge/flesh_ghoul/ghost_poll_probe/poll_servant_candidates(question, mob/living/body, duration)
	last_poll_body = REF(body)
	last_poll_duration = duration
	return list()

/// Учебная Хватка поднимает тело без mind; обычная роль зовёт призраков на 10 секунд и без ответа не тратит биомассу.
/datum/unit_test/heretic_log_flesh_mindless/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/datum/eldritch_knowledge/flesh_grasp/ghost_poll_probe/probe = allocate(/datum/eldritch_knowledge/flesh_grasp/ghost_poll_probe)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	victim.death()
	TEST_ASSERT_NULL(victim.mind, "Тело изначально без разума.")
	path.combat_resource = 2
	TEST_ASSERT(probe.on_mansus_grasp(victim, heretic.owner.current, TRUE), "Обычная роль зовёт призраков в пустое тело.")
	TEST_ASSERT_EQUAL(probe.last_poll_body, REF(victim), "Опрос предлагает именно это тело.")
	TEST_ASSERT_EQUAL(probe.last_poll_duration, 10 SECONDS, "Призракам даётся 10 секунд.")
	TEST_ASSERT(!probe.ghoul_poll_pending, "Завершённый опрос снимает ожидание.")
	TEST_ASSERT_EQUAL(path.combat_resource, 2, "Без ответа духов биомасса сохраняется.")
	TEST_ASSERT(victim.stat == DEAD && isnull(victim.mind), "Без ответа духов тело остаётся мёртвым.")
	probe.ghoul_poll_pending = TRUE
	probe.last_poll_duration = null
	TEST_ASSERT(!probe.on_mansus_grasp(victim, heretic.owner.current, TRUE), "Пока идёт опрос, второй не начинается.")
	TEST_ASSERT_NULL(probe.last_poll_duration, "Повторный опрос не запущен.")
	probe.ghoul_poll_pending = FALSE
	heretic.simulated = TRUE
	TEST_ASSERT(grasp.on_mansus_grasp(victim, heretic.owner.current, TRUE), "Учебная роль поднимает пустую мишень.")
	TEST_ASSERT_NOTNULL(victim.mind, "Гулю создан разум.")
	allocated += victim.mind
	var/datum/antagonist/heretic_monster/ghoul/ghoul = victim.mind.has_antag_datum(/datum/antagonist/heretic_monster/ghoul)
	TEST_ASSERT_NOTNULL(ghoul, "Гуль получил роль слуги.")
	TEST_ASSERT(victim.stat != DEAD, "Тело ожило.")
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "Подъём расходует одну биомассу.")
	TEST_ASSERT(!grasp.on_mansus_grasp(victim, heretic.owner.current, TRUE), "Живого гуля нельзя поднять повторно.")

/// Повторное подключение ржавчины не повторяет урон и снимается при замене пола.
/datum/unit_test/heretic_log_rust_attachment/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, floor)
	var/obj/vehicle/sealed/mecha/working/ripley/mech = allocate(/obj/vehicle/sealed/mecha/working/ripley, floor)
	floor.AddElement(/datum/element/heretic_rust)
	var/integrity = mech.obj_integrity
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/rust_corruption), "Первое подключение заражает стоящего на полу.")
	floor.AddElement(/datum/element/heretic_rust)
	TEST_ASSERT_EQUAL(mech.obj_integrity, integrity, "Повторное подключение не наносит второй удар меху.")
	floor = floor.ChangeTurf(/turf/open/floor/plating)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/rust_corruption), "Замена пола снимает заражение.")
	floor.AddElement(/datum/element/heretic_rust)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/rust_corruption), "Новую поверхность можно заразить снова.")
	victim.forceMove(get_step(floor, EAST))
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/rust_corruption), "Выход с нового пола снимает заражение.")

/// Лунная способность проходит подготовку, отмену, применение и настоящую перезарядку.
/datum/unit_test/heretic_log_moon_cooldown/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/moon = get_heretic_moon(user)
	var/obj/effect/proc_holder/spell/pointed/heretic_moon/create/spell = moon.reflection_spell
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Выданная способность готова сразу.")
	TEST_ASSERT(spell.can_cast(user), "Выданное заклинание проходит проверки применения.")
	user.ranged_ability = spell
	user.click_intercept = spell
	spell.ranged_ability_user = user
	spell.active = TRUE
	spell.Trigger(user)
	TEST_ASSERT(!spell.active, "Повторное нажатие отменяет прицеливание.")
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Отмена не расходует заряд.")
	user.ranged_ability = spell
	user.click_intercept = spell
	spell.ranged_ability_user = user
	spell.active = TRUE
	spell.InterceptClickOn(user, "", get_step(user, EAST))
	TEST_ASSERT(length(moon.reflections), "Клик создал отражение.")
	TEST_ASSERT(spell.charge_counter < spell.charge_max, "Применение расходует заряд.")
	TEST_ASSERT(spell in SSfastprocess.processing, "Перезарядка подключена к подсистеме.")
	TEST_ASSERT(wait_for_var(spell, "charge_counter", spell.charge_max, 15 SECONDS), "Подсистема завершила восьмисекундную перезарядку.")
	TEST_ASSERT(spell.can_cast(user), "После перезарядки способность снова доступна.")
	spell.remove_ranged_ability()
	moon.on_body_lose(user)
	TEST_ASSERT(QDELETED(spell), "Потеря тела удаляет старое заклинание.")
	TEST_ASSERT(!length(moon.reflections), "Старые отражения удалены.")
	moon.on_body_gain(user)
	TEST_ASSERT_EQUAL(moon.reflection_spell.charge_counter, moon.reflection_spell.charge_max, "Возврат тела выдаёт готовую способность.")

/// Размещение призм сообщает причину отказа и очищает сеть при утрате знания.
/datum/unit_test/heretic_log_glass_placement/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_GLASS
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_glass)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/datum/eldritch_knowledge/spell/glass_shards/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/glass_shards)
	var/obj/effect/proc_holder/spell/pointed/heretic_glass/shards/spell = knowledge.granted_spell
	var/turf/place = get_step(user, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, place)
	TEST_ASSERT(!spell.can_target(place, user, TRUE), "Занятый пол не подходит.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "существо"), "Причина указывает на существо.")
	victim.forceMove(get_step(user, NORTH))
	glass.combat_resource = 0
	TEST_ASSERT(!spell.can_target(place, user, TRUE), "Без грани нельзя создать призму.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "1 грань"), "Причина указывает на ресурс.")
	glass.combat_resource = 4
	TEST_ASSERT(glass.shards(user, place), "Создана первая призма.")
	TEST_ASSERT(glass.shards(user, get_step(place, EAST)), "Создана вторая призма.")
	TEST_ASSERT(glass.shards(user, get_step(place, NORTHEAST)), "Создана третья призма.")
	TEST_ASSERT(!spell.can_target(get_step(user, NORTHEAST), user, TRUE), "Четвёртая призма запрещена.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "предел"), "Причина указывает на лимит.")
	var/list/prisms = glass.prisms.Copy()
	glass.combat_resource = 0
	TEST_ASSERT(spell.can_target(prisms[1], user, TRUE), "При полном лимите и пустом запасе можно повернуть свою призму.")
	qdel(knowledge)
	TEST_ASSERT(!length(glass.prisms), "Знание отпускает все призмы.")
	for(var/obj/structure/heretic_glass_prism/prism as anything in prisms)
		TEST_ASSERT(QDELETED(prism), "Каждая призма удалена.")
		TEST_ASSERT(!(prism in SSobj.processing), "Подсистема не удерживает призму.")
		TEST_ASSERT(!length(prism.signal_procs), "Призма не удерживается сигналами.")
	prisms.Cut()

/// Потерянный кодекс возвращается, конфискованный остаётся у захватившего его игрока.
/datum/unit_test/heretic_log_codex_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/summon/book)
	var/datum/eldritch_knowledge/spell/summon/book/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/summon/book)
	var/obj/effect/proc_holder/spell/self/heretic_summon/book/spell = knowledge.granted_spell
	spell.recovery_time = 0.2 SECONDS
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book, get_step(user, EAST))
	heretic.personal_codex = WEAKREF(book)
	spell.recover_missing_item(user, heretic)
	TEST_ASSERT(book in user.GetAllContents(), "Вернулся тот же кодекс.")
	TEST_ASSERT(!spell.recovery_in_progress, "Канал завершён.")
	var/mob/living/carbon/human/holder = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	user.transferItemToLoc(book, holder, TRUE)
	TEST_ASSERT(!spell.recovery_allowed(user, heretic, heretic.personal_codex), "Чужой инвентарь блокирует возврат.")
	spell.recover_missing_item(user, heretic)
	TEST_ASSERT_EQUAL(book.loc, holder, "Чужой кодекс не вырван из инвентаря.")
	var/obj/structure/closet/locker = allocate(/obj/structure/closet, get_step(user, EAST))
	book.forceMove(locker)
	TEST_ASSERT(!spell.recovery_allowed(user, heretic, heretic.personal_codex), "Контейнер блокирует возврат.")
	book.forceMove(get_step(user, EAST))
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch, book.loc)
	GLOB.heretic_ritual_reservations[book] = rune
	var/blocked = !spell.recovery_allowed(user, heretic, heretic.personal_codex)
	GLOB.heretic_ritual_reservations -= book
	TEST_ASSERT(blocked, "Действующий обряд блокирует возврат.")
	qdel(book)
	spell.recover_missing_item(user, heretic)
	var/obj/item/forbidden_book/replacement = heretic.personal_codex?.resolve()
	TEST_ASSERT_NOTNULL(replacement, "Уничтоженный кодекс восстановлен.")
	allocated += replacement
	TEST_ASSERT(replacement in user.GetAllContents(), "Новая книга выдана владельцу.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, HERETIC_STARTING_KNOWLEDGE, "Восстановление не сбрасывает знания.")
	user.transferItemToLoc(replacement, run_loc_floor_top_right, TRUE)
	spell.recovery_time = 2 SECONDS
	addtimer(CALLBACK(replacement, TYPE_PROC_REF(/atom/movable, forceMove), holder), 0.2 SECONDS)
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(replacement.loc, holder, "Книга, подобранная во время канала, остаётся у нового держателя.")
	TEST_ASSERT(!spell.recovery_in_progress, "Сорванный канал освобождает способность.")
	replacement.forceMove(run_loc_floor_top_right)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/atom/movable, forceMove), get_step(user, EAST)), 0.2 SECONDS)
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(replacement.loc, run_loc_floor_top_right, "Движение владельца прерывает возврат.")
	TEST_ASSERT_EQUAL(heretic.personal_codex.resolve(), replacement, "Прерывания не создают дубликатов.")

/// Все пути получают боевую подсказку, результат по-прежнему определяется здоровьем цели.
/datum/unit_test/heretic_log_training_guidance/Run()
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	TEST_ASSERT(session.start_practice("combat"), "Боевая мишень создана.")
	var/datum/antagonist/heretic/heretic = IS_HERETIC(session.current_body)
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT(length(path.combat_practice), "Путь [path_id] имеет подсказку.")
		heretic.selected_path = path_id
		session.update_practice()
		TEST_ASSERT(findtext(session.practice_hint, path.combat_practice), "Подсказка [path_id] показана в активном упражнении.")
		TEST_ASSERT(!session.practice_complete, "Чтение подсказки не завершает упражнение.")
	var/mob/living/target = session.practice_target.resolve()
	target.adjustOxyLoss(150)
	session.update_practice()
	TEST_ASSERT(session.practice_complete, "Реальный крит завершает упражнение.")

/// Незавершённый ритуал даёт призракам 10 секунд и без ответа не тратит биомассу.
/datum/unit_test/heretic_log_flesh_silent_dead_poll/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_FLESH
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/base_flesh/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_ghoul/ghost_poll_probe/ritual = allocate(/datum/eldritch_knowledge/flesh_ghoul/ghost_poll_probe)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	victim.death()
	path.combat_resource = 2
	TEST_ASSERT(!ritual.on_finished_recipe(heretic.owner.current, list(victim), get_turf(victim)), "Без ответа духов ритуал не поднимает тело.")
	TEST_ASSERT_EQUAL(ritual.last_poll_body, REF(victim), "Опрос предлагает тело с руны.")
	TEST_ASSERT_EQUAL(ritual.last_poll_duration, 10 SECONDS, "Призракам даётся 10 секунд, как и при других призывах.")
	TEST_ASSERT_EQUAL(path.combat_resource, 2, "Без ответа духов биомасса сохраняется.")
	TEST_ASSERT(victim.stat == DEAD, "Тело остаётся мёртвым.")
