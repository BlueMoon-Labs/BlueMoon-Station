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

/// Потерянный и запертый в шкафу кодекс возвращается, книга в чужом инвентаре остаётся у захватившего.
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
	TEST_ASSERT(findtext(spell.recovery_failure, "инвентаре"), "Отказ объясняет, что книгу держит существо.")
	spell.recover_missing_item(user, heretic)
	TEST_ASSERT_EQUAL(book.loc, holder, "Чужой кодекс не вырван из инвентаря.")
	var/obj/structure/closet/locker = allocate(/obj/structure/closet, get_step(user, EAST))
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, locker)
	book.forceMove(bag)
	TEST_ASSERT(spell.recovery_allowed(user, heretic, heretic.personal_codex), "Шкаф с сумкой не запирает кодекс навсегда.")
	spell.container_recovery_time = 0.2 SECONDS
	spell.recover_missing_item(user, heretic)
	TEST_ASSERT(book in user.GetAllContents(), "Кодекс вытянут из сумки в шкафу.")
	book.forceMove(get_step(user, EAST))
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch, book.loc)
	GLOB.heretic_ritual_reservations[book] = rune
	var/blocked = !spell.recovery_allowed(user, heretic, heretic.personal_codex)
	var/ritual_reason = spell.recovery_failure
	GLOB.heretic_ritual_reservations -= book
	TEST_ASSERT(blocked, "Действующий обряд блокирует возврат.")
	TEST_ASSERT(findtext(ritual_reason, "обрядом"), "Отказ предлагает освободить книгу из обряда.")
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

/// Предмет, взятый в руку во время канала, не срывает возврат кодекса и сердца.
/datum/unit_test/heretic_log_recovery_ignores_held_item/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/summon/book)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	var/datum/eldritch_knowledge/spell/summon/book/book_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/summon/book)
	var/obj/effect/proc_holder/spell/self/heretic_summon/book/book_spell = book_knowledge.granted_spell
	book_spell.recovery_time = 1 SECONDS
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book, run_loc_floor_top_right)
	heretic.personal_codex = WEAKREF(book)
	var/obj/item/pen/first_pen = allocate(/obj/item/pen)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, put_in_active_hand), first_pen), 0.3 SECONDS)
	book_spell.recover_missing_item(user, heretic)
	TEST_ASSERT(book in user.GetAllContents(), "Кодекс вернулся, хотя в руке сменился предмет.")
	user.dropItemToGround(first_pen)
	user.dropItemToGround(book)
	var/datum/eldritch_knowledge/spell/heart_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	var/obj/effect/proc_holder/spell/self/heretic_summon/heart/heart_spell = heart_knowledge.granted_spell
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_top_right)
	heart.bind(heretic.owner)
	var/obj/item/pen/second_pen = allocate(/obj/item/pen)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, put_in_active_hand), second_pen), 1 SECONDS)
	heart_spell.cast(list(user), user)
	TEST_ASSERT(heart in user.GetAllContents(), "Сердце вернулось, хотя в руке сменился предмет.")

/// Все пути получают боевую подсказку, результат по-прежнему определяется здоровьем цели.
/datum/unit_test/heretic_log_training_guidance/Run()
	var/datum/antag_training_session/session = allocate_training_session()
	TEST_ASSERT(session.prepare(), "Полигон подготовлен.")
	session.update_safety()
	TEST_ASSERT(session.current_body.alerts["antag_training_safe"], "В центре показан индикатор защиты.")
	var/datum/antag_training_session/guest = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(guest.prepare(session.arena), "Соперник без иммунитета Мансуса входит на полигон.")
	var/datum/antagonist/heretic/attacker = allocate_heretic(get_turf(session.current_body))
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	TEST_ASSERT(!fist.try_grasp(guest.current_body, attacker.owner.current, TRUE), "Безопасный центр сохраняет заряд хватки.")
	guest.current_body.forceMove(session.arena.zones["melee"]["spawn"])
	guest.update_safety()
	TEST_ASSERT(fist.try_grasp(guest.current_body, attacker.owner.current, TRUE), "За пределами центра хватка расходует заряд на противника.")
	session.current_body.forceMove(session.arena.zones["melee"]["spawn"])
	session.update_safety()
	TEST_ASSERT(!session.current_body.alerts["antag_training_safe"], "Выход на арену снимает индикатор защиты.")
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

/// Смена облика сохраняет перезарядку, здоровье и оставшиеся сегменты Повелителя Ночи.
/datum/unit_test/heretic_log_flesh_transformation/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/human = heretic.owner.current
	heretic.selected_path = PATH_FLESH
	heretic.apply_innate_effects(human)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/touch_of_madness)
	var/datum/eldritch_knowledge/spell/touch_of_madness/madness = heretic.get_knowledge(/datum/eldritch_knowledge/spell/touch_of_madness)
	madness.granted_spell.charge_counter = 0
	madness.granted_spell.start_recharge()
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/flesh_final)
	var/datum/eldritch_knowledge/final_eldritch/flesh_final/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/flesh_final)
	knowledge.finished = TRUE
	knowledge.on_body_gain(human)
	var/obj/effect/proc_holder/spell/targeted/shed_human_form/spell = knowledge.ascension_spell_instances[1]
	spell.charge_counter = 0
	spell.perform(list(human), TRUE, human)
	var/mob/living/simple_animal/hostile/eldritch/armsy/prime/worm = heretic.owner.current
	TEST_ASSERT(istype(worm), "Смена облика создаёт Повелителя Ночи.")
	allocated += worm
	spell = knowledge.ascension_spell_instances[1]
	TEST_ASSERT(spell.charge_counter < spell.charge_max, "Новое тело не обнуляет перезарядку.")
	TEST_ASSERT(spell in SSfastprocess.processing, "Перезарядка нового тела обрабатывается подсистемой.")
	TEST_ASSERT(!spell.can_cast(worm), "Мгновенное обратное превращение недоступно.")
	TEST_ASSERT(madness.granted_spell.charge_counter < madness.granted_spell.charge_max, "Смена тела не сбрасывает откат Касания безумия.")
	TEST_ASSERT(wait_for_var(spell, "charge_counter", spell.charge_max, 15 SECONDS), "Перезарядка действительно завершается.")
	worm.adjustBruteLoss(30)
	worm.back.adjustBruteLoss(15)
	qdel(worm.back.back)
	var/head_health = worm.health
	var/tail_health = worm.back.health
	spell.charge_counter = 0
	spell.perform(list(worm), TRUE, worm)
	TEST_ASSERT_EQUAL(heretic.owner.current, human, "Разум возвращается в прежнее тело.")
	TEST_ASSERT(madness.granted_spell.charge_counter < madness.granted_spell.charge_max, "Возврат в человека не обходит трёхминутный откат.")
	TEST_ASSERT_EQUAL(length(knowledge.shed_form_health), 2, "Сохранены ровно два уцелевших сегмента.")
	spell = knowledge.ascension_spell_instances[1]
	TEST_ASSERT(spell.charge_counter < spell.charge_max, "Обратное превращение тоже сохраняет откат.")
	spell.charge_counter = spell.charge_max
	spell.cast(list(human), human)
	worm = heretic.owner.current
	allocated += worm
	TEST_ASSERT_EQUAL(worm.health, head_health, "Повторное превращение не лечит голову.")
	TEST_ASSERT_EQUAL(worm.back.health, tail_health, "Повторное превращение не лечит хвост.")
	TEST_ASSERT_NULL(worm.back.back, "Повторное превращение не отращивает потерянные сегменты.")
	worm.adjustBruteLoss(20)
	head_health = worm.health
	qdel(worm)
	TEST_ASSERT_EQUAL(heretic.owner.current, human, "Удаление оболочки возвращает разум в тело.")
	TEST_ASSERT_EQUAL(knowledge.shed_form_health[1], head_health, "Принудительная потеря оболочки тоже сохраняет раны.")

/// Священный меч защищает только в руках; обычный нулевой жезл сохраняет защиту в кармане.
/datum/unit_test/heretic_log_holy_sword_slots/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	TEST_ASSERT(user.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING), "Надета форма для поясного слота.")
	var/obj/item/nullrod/claymore/sword = allocate(/obj/item/nullrod/claymore)
	TEST_ASSERT(user.put_in_hands(sword), "Меч взят в руку.")
	TEST_ASSERT(user.anti_magic_check(), "Меч в руке блокирует магию.")
	for(var/slot in list(ITEM_SLOT_BELT, ITEM_SLOT_BACK))
		user.temporarilyRemoveItemFromInventory(sword, TRUE)
		TEST_ASSERT(user.equip_to_slot_if_possible(sword, slot), "Меч помещён в слот [slot].")
		TEST_ASSERT(!user.anti_magic_check(), "Убранный меч не даёт пассивную антимагию.")
		user.temporarilyRemoveItemFromInventory(sword, TRUE)
		TEST_ASSERT(user.put_in_hands(sword), "Меч снова взят в руку.")
		TEST_ASSERT(user.anti_magic_check(), "Защита возвращается вместе с мечом в руке.")
	user.dropItemToGround(sword, TRUE)
	TEST_ASSERT(!user.anti_magic_check(), "Брошенный меч больше не защищает.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	TEST_ASSERT(user.equip_to_slot_if_possible(rod, ITEM_SLOT_LPOCKET), "Жезл помещён в карман.")
	TEST_ASSERT(user.anti_magic_check(), "Обычный жезл сохраняет прежние правила защиты.")
