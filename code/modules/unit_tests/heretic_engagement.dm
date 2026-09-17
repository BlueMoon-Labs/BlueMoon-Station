/// Боевой шаг всех путей делит награды с обычным делом и ограничен ступенью и душой.
/datum/unit_test/heretic_engagement/Run()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/antagonist/heretic/heretic = allocate_deed_heretic(path_id)
		var/datum/heretic_deed/deed = heretic.deed
		TEST_ASSERT(length(deed.combat_hint), "У пути [path_id] есть условие боевого шага.")
		var/points_before = heretic.knowledge_points
		var/side_before = heretic.side_knowledge_points
		var/list/previous_souls = list()
		for(var/tier in 1 to HERETIC_DEED_TIERS)
			var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
			victim.mind = allocate_mind()
			victim.mind.current = victim
			heretic.hunt_target = victim.mind
			COOLDOWN_RESET(deed, progress_cooldown)
			TEST_ASSERT(!heretic.advance_combat_deed(victim, "wrong_path"), "Чужой приём не продвигает [path_id].")
			TEST_ASSERT(heretic.advance_combat_deed(victim, path_id), "Назначенная цель продвигает [path_id], ступень [tier].")
			TEST_ASSERT_EQUAL(deed.progress, 1, "Боевой шаг даёт ровно единицу прогресса.")
			TEST_ASSERT(!deed.get_data()["combat_available"], "Книга сообщает, что боевой шаг ступени израсходован.")
			COOLDOWN_RESET(deed, progress_cooldown)
			TEST_ASSERT(!heretic.advance_combat_deed(victim, path_id), "Повторный удар не продвигает дело.")
			TEST_ASSERT(heretic.advance_deed("ordinary:[tier]", null), "Обычное дело завершает ступень после боя.")
			previous_souls += victim.mind
			for(var/datum/mind/old_soul as anything in previous_souls)
				heretic.hunt_target = old_soul
				COOLDOWN_RESET(deed, progress_cooldown)
				TEST_ASSERT(!heretic.advance_combat_deed(old_soul.current, path_id), "Прежняя душа не даёт зачёт на новой ступени.")
		TEST_ASSERT(deed.complete(), "Три боевых и три обычных шага завершают дело [path_id].")
		TEST_ASSERT_EQUAL(heretic.knowledge_points, points_before + 3, "Боевые шаги не увеличивают общий бюджет знаний.")
		TEST_ASSERT_EQUAL(heretic.side_knowledge_points, side_before + 2, "Общий бюджет побочных знаний сохранён.")

/// Неназначенная цель, антимагия, снятая роль и общая задержка не дают боевого прогресса.
/datum/unit_test/heretic_engagement/deed_guards/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_TIDE)
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.mind = allocate_mind()
	victim.mind.current = victim
	TEST_ASSERT(!heretic.advance_combat_deed(victim, PATH_TIDE), "Посторонний не заменяет цель охоты.")
	heretic.hunt_target = victim.mind
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, victim)
	victim.put_in_hands(rod)
	TEST_ASSERT(!heretic.advance_combat_deed(victim, PATH_TIDE), "Защищённая цель не засчитывается.")
	qdel(rod)
	heretic.role_removed = TRUE
	TEST_ASSERT(!heretic.advance_combat_deed(victim, PATH_TIDE), "Снятая роль не продвигает дело.")
	heretic.role_removed = FALSE
	TEST_ASSERT(heretic.advance_deed("ordinary", null), "Обычный шаг начинает общую задержку.")
	TEST_ASSERT(!heretic.advance_combat_deed(victim, PATH_TIDE), "Бой не обходит общую задержку.")
	TEST_ASSERT_EQUAL(length(heretic.deed.combat_tiers), 0, "Отклонённый шаг не расходует возможность.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	tide.combat_resource = tide.combat_resource_max
	TEST_ASSERT(tide.release(user), "Применяется настоящая волна Пучины.")
	TEST_ASSERT(victim.getBruteLoss() > 0, "Волна попала в цель.")
	TEST_ASSERT_EQUAL(heretic.deed.tier, 1, "Попадание волны завершает ступень.")
	TEST_ASSERT(1 in heretic.deed.combat_tiers, "Зачёт относится к завершённой, а не следующей ступени.")

/// Раннее смещение души сохраняет срок и бюджет связи и даёт противнику прежние контрмеры.
/datum/unit_test/heretic_engagement/spirit_shift/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spirit_grasp)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spirit_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/spirit_grasp)
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/shift/spell = grasp.granted_spell
	TEST_ASSERT(istype(spell), "Второе знание даёт активное смещение.")
	var/turf/origin = get_step(get_step(get_step(get_step(user, EAST), EAST), EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, origin)
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	var/expiry = soul.duration
	var/budget = soul.drain_limit
	var/resource_before = spirit.combat_resource
	TEST_ASSERT(spell.can_target(soul.anchor, user, TRUE), "Собственная душа доступна в четырёх клетках.")
	spell.cast(list(soul.anchor), user)
	TEST_ASSERT(soul.shifted, "Способность сместила душу после подготовки.")
	TEST_ASSERT_EQUAL(get_dist(origin, soul.anchor), 2, "Душа сместилась ровно на две клетки.")
	TEST_ASSERT_EQUAL(get_turf(victim), origin, "Способность не перемещает тело жертвы.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, resource_before - 1, "Потрачен один обол.")
	TEST_ASSERT_EQUAL(soul.duration, expiry, "Срок связи не обновился.")
	TEST_ASSERT_EQUAL(soul.drain_limit, budget, "Предел истощения не увеличился.")
	soul.tick()
	TEST_ASSERT(soul.drained > 0, "Тело у прежней позиции теперь истощается.")
	TEST_ASSERT(!spirit.shift_soul(user, soul.anchor), "Одну душу нельзя смещать повторно.")
	victim.forceMove(get_turf(soul.anchor))
	TEST_ASSERT(QDELETED(soul), "Возврат к перемещённой душе обрывает связь.")
	grasp.on_body_lose(user)
	TEST_ASSERT(QDELETED(spell), "Потеря знания снимает новый приём с тела.")

/// Движение прерывает смещение без расхода обола и не лишает права повторить попытку.
/datum/unit_test/heretic_engagement/spirit_interrupt/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spirit_grasp)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(get_step(user, EAST), EAST), EAST))
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	var/turf/origin = get_turf(soul.anchor)
	var/resource_before = spirit.combat_resource
	INVOKE_ASYNC(spirit, TYPE_PROC_REF(/datum/eldritch_knowledge/base_spirit, shift_soul), user, soul.anchor)
	TEST_ASSERT(soul.shifting, "Подготовка началась.")
	TEST_ASSERT(!spirit.shift_soul(user, soul.anchor), "Вторая подготовка той же души отвергается.")
	user.forceMove(get_step(user, NORTH))
	TEST_ASSERT(wait_for_var(soul, NAMEOF(soul, shifting), FALSE), "Движение завершает отменённую попытку.")
	TEST_ASSERT(!soul.shifted, "Смещение не состоялось.")
	TEST_ASSERT_EQUAL(get_turf(soul.anchor), origin, "Душа осталась на месте.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, resource_before, "Отмена не расходует обол.")
	TEST_ASSERT(spirit.can_shift_soul(user, soul.anchor), "Можно повторить попытку.")
	qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spirit_grasp))
	TEST_ASSERT(!spirit.can_shift_soul(user, soul.anchor), "Потеря знания запрещает повторную попытку.")

/// Ползун доступен со вторым знанием, выполняет приказы и требует биомассу для продления жизни.
/datum/unit_test/heretic_engagement/flesh_orders/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_FLESH)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_flesh/flesh = heretic.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/datum/eldritch_knowledge/flesh_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/flesh_grasp)
	var/obj/item/organ/organ = allocate(/obj/item/organ/heart, get_step(user, EAST))
	TEST_ASSERT(flesh.grow_fleshling(user, organ), "Ползун создаётся до Незавершённого ритуала.")
	var/mob/living/simple_animal/heretic_fleshling/crawler = flesh.fleshling
	STOP_PROCESSING(SSfastprocess, crawler)
	user.a_intent = INTENT_DISARM
	crawler.attack_hand(user)
	TEST_ASSERT(crawler.holding_position, "Разоружение оставляет ползуна ждать.")
	var/turf/place = get_turf(crawler)
	user.forceMove(get_step(user, NORTH))
	crawler.process()
	TEST_ASSERT_EQUAL(get_turf(crawler), place, "Ожидающий ползун не следует за хозяином.")
	user.a_intent = INTENT_HELP
	crawler.attack_hand(user)
	TEST_ASSERT(!crawler.holding_position, "Помощь возвращает режим следования.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(crawler, EAST))
	victim.mind = allocate_mind()
	victim.mind.current = victim
	heretic.hunt_target = victim.mind
	grasp.granted_spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(crawler.prey_ref?.resolve(), victim, "Живой шов задаёт цель.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 0, "Сам шов не выполняет боевой шаг Плоти.")
	crawler.process()
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Собственное попадание ползуна выполняет боевой шаг.")
	flesh.combat_resource = 1
	crawler.expires_at = world.time + 50 SECONDS
	TEST_ASSERT(grasp.granted_spell.can_target(crawler, user, TRUE), "Здорового ползуна с истекающим сроком можно поддержать рядом.")
	grasp.granted_spell.cast(list(crawler), user)
	TEST_ASSERT_EQUAL(crawler.expires_at, world.time + 90 SECONDS, "Поддержка обновляет срок до 90 секунд.")
	TEST_ASSERT_EQUAL(flesh.combat_resource, 0, "Поддержка расходует одну биомассу.")
	TEST_ASSERT_NULL(crawler.prey_ref, "Поддержка отзывает ползуна из погони.")
	flesh.combat_resource = 1
	crawler.expires_at = world.time
	TEST_ASSERT(!grasp.granted_spell.can_target(crawler, user, TRUE), "Истёкшего ползуна уже нельзя продлить.")
	crawler.process()
	TEST_ASSERT(QDELETED(crawler), "Истёкший ползун распадается.")

/// Открывающий удар размыкает одну печать до изучения позднего Размыкания.
/datum/unit_test/heretic_engagement/lock_bolt/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_LOCK
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lock_bolt)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lock/lock = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/spell/lock_bolt/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/lock_bolt)
	var/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt/spell = knowledge.granted_spell
	var/obj/structure/heretic_lock_seal/seal = lock.create_seal(get_step(get_step(user, EAST), EAST), user)
	var/obj/structure/heretic_lock_seal/retained = lock.create_seal(get_step(user, NORTH), user)
	TEST_ASSERT(seal && retained, "Две собственные печати установлены.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(seal, EAST))
	var/keys_before = lock.combat_resource
	TEST_ASSERT(spell.can_target(seal, user, TRUE), "Ранний удар принимает свою печать.")
	spell.cast(list(seal), user)
	TEST_ASSERT(QDELETED(seal), "Выбранная печать израсходована.")
	TEST_ASSERT(!QDELETED(retained), "Другая печать сохранена.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) < DAMAGE_PRECISION, "Ближняя цель получила обычные 30 ушибов.")
	TEST_ASSERT_EQUAL(lock.combat_resource, keys_before, "Взрыв не возвращает ключ.")
	INVOKE_ASYNC(spell, TYPE_PROC_REF(/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt, cast), list(retained), user)
	TEST_ASSERT(spell.opening_seal, "Вторая печать готовится к размыканию.")
	user.forceMove(get_step(user, WEST))
	TEST_ASSERT(wait_for_var(spell, NAMEOF(spell, opening_seal), FALSE), "Движение отменило подготовку.")
	TEST_ASSERT(!QDELETED(retained), "Прерванная подготовка не расходует печать.")
	TEST_ASSERT_EQUAL(lock.combat_resource, keys_before, "Прерывание не возвращает ключ.")
	qdel(knowledge)
	TEST_ASSERT(QDELETED(spell), "Потеря знания снимает способность.")
