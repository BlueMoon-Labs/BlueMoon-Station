/// Переправа в намерении разоружения сохраняет душу и подготовленную жатву без обновления их бюджета.
/datum/unit_test/heretic_spirit_crossing_preserves_soul/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spell/spirit_step/step_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	var/datum/eldritch_knowledge/spell/spirit_reap/reap_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	var/turf/destination = get_step(get_step(get_step(get_step(user, EAST), EAST), EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	victim.mind = allocate_mind()
	victim.mind.current = victim
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	TEST_ASSERT_NOTNULL(soul, "Создана душа для дальней переправы.")
	victim.forceMove(get_step(get_step(victim, NORTH), NORTH))
	soul.tick()
	TEST_ASSERT(soul.drained > 0, "Душа уже израсходовала часть истощения.")
	TEST_ASSERT(soul.arm(reap_knowledge, 25), "Жатва подготовлена до переправы.")
	var/expiry = soul.duration
	var/drained = soul.drained
	var/reap_at = soul.reap_at
	var/obj/structure/heretic_spirit_soul/anchor = soul.anchor
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/step/spell = step_knowledge.granted_spell
	user.a_intent = INTENT_DISARM
	TEST_ASSERT(spell.can_target(anchor, user, TRUE), "Душа доступна для дальней переправы.")
	spell.cast(list(anchor), user)
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Перевозчик достиг души.")
	TEST_ASSERT(!QDELETED(soul) && !QDELETED(anchor), "Выбранный режим сохраняет душу.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 2, "Обол потрачен, награды за сбор нет.")
	TEST_ASSERT_EQUAL(soul.duration, expiry, "Срок души не обновился.")
	TEST_ASSERT_EQUAL(soul.drained, drained, "Израсходованное истощение не восстановилось.")
	TEST_ASSERT_EQUAL(soul.reap_at, reap_at, "Предупреждение жатвы не перезапущено.")
	anchor.attack_hand(victim)
	TEST_ASSERT(!QDELETED(soul), "Жертва не возвращает душу издалека.")
	victim.forceMove(destination)
	TEST_ASSERT(QDELETED(soul) && QDELETED(anchor), "Возврат жертвы по-прежнему отменяет сохранённую душу и жатву.")

/// Разлучение сразу ранит через реальную способность и не возвращает душу до движения.
/datum/unit_test/heretic_spirit_opening/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/sever/spell = spirit.combat_power
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Живая цель доступна без подготовки.")
	spell.cast(list(victim), user)
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Разлучение сразу наносит 20 ушибов.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 15) <= DAMAGE_PRECISION, "Первый удар сразу истощает выносливость.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 2, "Способность тратит один обол.")
	var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
	TEST_ASSERT_NOTNULL(soul, "Жертва получает связь.")
	TEST_ASSERT_EQUAL(get_turf(soul.anchor), get_turf(victim), "Душа остаётся на клетке поражённого тела.")
	soul.tick()
	TEST_ASSERT(!QDELETED(soul), "Первый такт не гасит неподвижную душу.")
	TEST_ASSERT_EQUAL(soul.drained, 0, "Тело возле души не получает постоянное истощение.")
	var/obj/blocker = allocate(/obj, get_turf(victim))
	blocker.density = TRUE
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Преграда закрывает выбор цели.")
	TEST_ASSERT(!spirit.sever(user, victim), "Прямой вызов тоже учитывает преграду.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 2, "Отклонённое применение не расходует запас.")

/// Возврат и касание отменяют связь без дополнительного урона телу.
/datum/unit_test/heretic_spirit_return/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/turf/origin = get_turf(victim)
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	var/obj/structure/heretic_spirit_soul/anchor = soul.anchor
	victim.forceMove(get_step(origin, NORTH))
	TEST_ASSERT(!QDELETED(soul), "Первый отход сохраняет связь.")
	victim.forceMove(origin)
	TEST_ASSERT(QDELETED(soul) && QDELETED(anchor), "Возврат сразу гасит обе стороны связи.")
	soul = spirit.separate(victim, spirit)
	anchor = soul.anchor
	anchor.attack_hand(victim)
	TEST_ASSERT(QDELETED(soul) && QDELETED(anchor), "Свою душу можно вернуть касанием без движения.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Контрмера не ранит тело.")
	TEST_ASSERT_EQUAL(length(spirit.souls), 0, "Список знания освобождается.")

/// Истощение имеет общий предел, а повторное отделение не обновляет срок и бюджет.
/datum/unit_test/heretic_spirit_drain_budget/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	var/expiry = soul.duration
	victim.forceMove(get_step(get_step(victim, NORTH), NORTH))
	for(var/index in 1 to 30)
		soul.tick()
	TEST_ASSERT_EQUAL(soul.drained, 25, "Долгая связь расходует не больше 25 выносливости.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 25) <= DAMAGE_PRECISION, "Фактическое истощение совпадает с бюджетом.")
	TEST_ASSERT_EQUAL(spirit.separate(victim, spirit), soul, "Повторное отделение сохраняет тот же статус.")
	TEST_ASSERT_EQUAL(soul.duration, expiry, "Повторное отделение не продлевает срок.")
	soul.tick()
	TEST_ASSERT(abs(victim.getStaminaLoss() - 25) <= DAMAGE_PRECISION, "Повторное отделение не возвращает бюджет.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spirit_temper)
	var/datum/eldritch_knowledge/spirit_temper/temper = heretic.get_knowledge(/datum/eldritch_knowledge/spirit_temper)
	temper.passive_level = 3
	temper.on_passive_upgrade(user)
	TEST_ASSERT_EQUAL(soul.drain_limit, 25, "Улучшение не усиливает существующую связь.")
	qdel(soul)
	soul = spirit.separate(victim, spirit)
	TEST_ASSERT_EQUAL(soul.drain_limit, 40, "Новая связь получает улучшенный предел.")
	TEST_ASSERT_EQUAL(spirit.combat_resource_max, 8, "Улучшение расширяет вместимость.")

/// Удары по силуэту не передают раны; разрушение, жезл, стена и защита рвут связь.
/datum/unit_test/heretic_spirit_counterplay/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	var/obj/item/melee/sickly_blade/spirit/blade = allocate(/obj/item/melee/sickly_blade/spirit)
	for(var/scenario in list("blade", "destroy", "nullrod", "wall", "magic", "container", "anchor_container", "victim_death"))
		var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
		var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
		var/obj/structure/heretic_spirit_soul/anchor = soul.anchor
		var/obj/blocker
		if(scenario == "blade")
			victim.forceMove(get_step(victim, NORTH))
			anchor.attackby(blade, user)
			TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Крюк не переносит урон с души на тело.")
			qdel(anchor)
		if(scenario == "destroy")
			anchor.take_damage(100, BRUTE, MELEE)
		if(scenario == "nullrod")
			anchor.attackby(rod, victim)
		if(scenario == "wall")
			blocker = allocate(/obj, get_turf(victim))
			blocker.density = TRUE
			soul.tick()
		if(scenario == "magic")
			victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 3)
			soul.tick()
		if(scenario == "container")
			var/obj/item/storage/box/container = allocate(/obj/item/storage/box, get_turf(victim))
			victim.forceMove(container)
		if(scenario == "anchor_container")
			var/obj/item/storage/box/container = allocate(/obj/item/storage/box, get_turf(victim))
			anchor.forceMove(container)
		if(scenario == "victim_death")
			victim.stat = DEAD
			soul.tick()
		TEST_ASSERT(QDELETED(soul) && QDELETED(anchor), "Контрмера [scenario] убирает душу и статус.")
		TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Контрмера [scenario] не ранит тело.")
		QDEL_NULL(blocker)
		qdel(victim)

/// Жатва оставляет первый урон, предупреждает и наносит второй удар: полный вдали от души, ослабленный рядом с ней.
/datum/unit_test/heretic_spirit_reaping/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spell/spirit_reap/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/reap/spell = knowledge.granted_spell
	for(var/retreat in list(FALSE, TRUE))
		var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
		spell.cast(list(victim), user)
		TEST_ASSERT(abs(victim.getBruteLoss() - 22) <= DAMAGE_PRECISION, "Жатва полезна сразу без прежней души.")
		var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
		TEST_ASSERT_EQUAL(soul.anchor.icon_state, "spirit_reap", "Силуэт показывает предупреждение.")
		TEST_ASSERT(abs(soul.reap_at - world.time - 2 SECONDS) <= world.tick_lag, "Жертва получает две секунды на ответ.")
		TEST_ASSERT(!soul.finish_reap(), "Ранний вызов не обходит предупреждение.")
		TEST_ASSERT(!soul.arm(knowledge, 100), "Повторная подготовка не меняет урон и срок.")
		if(retreat)
			victim.forceMove(get_step(get_step(victim, NORTH), NORTH))
		var/obj/structure/heretic_spirit_soul/anchor = soul.anchor
		soul.reap_at = world.time
		TEST_ASSERT(soul.finish_reap(), "Второй удар попадает при целой связи [retreat ? "вдали от души" : "рядом с душой"].")
		TEST_ASSERT(abs(victim.getBruteLoss() - (retreat ? 47 : 37)) <= DAMAGE_PRECISION, "Второй удар наносит [retreat ? 25 : 15] ушибов.")
		TEST_ASSERT(QDELETED(soul) && QDELETED(anchor), "Жатва расходует связь после одного разрешения.")
		qdel(victim)
	TEST_ASSERT_EQUAL(spirit.combat_resource, 3, "Жатва доступна без затрат оболов.")

/// Антимагия отвергает выбор и прямой удар, а массовый звон расходует один заряд.
/datum/unit_test/heretic_spirit_antimagic/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_bell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 4)
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/sever/spell = spirit.combat_power
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Выбор защищённой цели отклоняется.")
	TEST_ASSERT(!spirit.sever(user, victim), "Прямое разлучение тоже учитывает антимагию.")
	TEST_ASSERT(!spirit.reap(user, victim), "Жатва не обходит антимагию.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Отклонённые направленные действия не тратят заряды.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 3, "Отказ не тратит оболы.")
	var/datum/eldritch_knowledge/spell/spirit_bell/bell_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_bell)
	bell_knowledge.granted_spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(protection.charges, 3, "Реальный массовый звон тратит один заряд защиты.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Защита поглощает первый удар.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_spirit/separated), "Защищённый не получает душу.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Звон не ранит самого перевозчика.")

/// Собственный крюк сохраняет душу и Жатву, а чужое оружие по-прежнему разрывает связь.
/datum/unit_test/heretic_spirit_own_hook/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_SPIRIT)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/item/melee/sickly_blade/spirit/hook = allocate(/obj/item/melee/sickly_blade/spirit)
	TEST_ASSERT(spirit.reap(user, victim), "Жатва подготовлена.")
	var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
	var/obj/structure/heretic_spirit_soul/anchor = soul.anchor
	victim.forceMove(get_step(victim, NORTH))
	var/expiry = soul.duration
	var/reap_at = soul.reap_at
	var/resource_before = spirit.combat_resource
	anchor.attackby(hook, user)
	TEST_ASSERT(!QDELETED(anchor) && !QDELETED(soul), "Свой крюк не разрушает связь.")
	TEST_ASSERT_EQUAL(anchor.obj_integrity, anchor.max_integrity, "Своя душа не повреждена.")
	TEST_ASSERT_EQUAL(soul.reap_at, reap_at, "Подготовленная Жатва не отменяется и не откладывается.")
	TEST_ASSERT_EQUAL(soul.duration, expiry, "Подсказка не продлевает душу.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, resource_before, "За подсказку не выдаётся обол.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 22) <= DAMAGE_PRECISION, "Клик не добавляет урона телу.")
	anchor.attackby(hook, victim)
	TEST_ASSERT(QDELETED(anchor) && QDELETED(soul), "Жертва может разрушить душу тем же оружием.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 22) <= DAMAGE_PRECISION, "Контрмера не ранит тело.")

/// Причины отказа отличают союзника, душу, контейнер, преграду и антимагию без затрат ресурса.
/datum/unit_test/heretic_spirit_target_feedback/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_SPIRIT)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/sever/spell = spirit.combat_power
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, NORTH))
	TEST_ASSERT(!spell.can_target(ally.owner.current, user, TRUE), "Боевой эффект не действует на другого еретика.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "союзник Мансуса"), "Отказ прямо называет союзника.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	TEST_ASSERT(!spell.can_target(soul.anchor, user, TRUE), "Целью выбирается тело, а не душа.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "тело живого противника"), "Подсказка объясняет выбор тела.")
	TEST_ASSERT(!spell.can_target(get_step(user, SOUTH), user, TRUE), "Пол не подходит целью.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "на пол") && !findtext(spell.heretic_failure_reason, "силуэт"), "Клик по полу объясняется полом, а не душой.")
	var/obj/item/storage/box/box = allocate(/obj/item/storage/box, get_turf(victim))
	victim.forceMove(box)
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Контейнер защищает цель.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "контейнера"), "Подсказка указывает контейнер.")
	victim.forceMove(get_step(user, EAST))
	var/obj/blocker = allocate(/obj, get_turf(victim))
	blocker.density = TRUE
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Преграда закрывает цель.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "преград"), "Подсказка указывает преграду.")
	qdel(blocker)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 3)
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Антимагия закрывает цель.")
	TEST_ASSERT_EQUAL(spell.heretic_failure_reason, "Цель защищена от магии.", "Подсказка указывает антимагию.")
	TEST_ASSERT_EQUAL(protection.charges, 3, "Проверки не расходуют защиту.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 3, "Проверки не расходуют оболы.")
	qdel(protection)
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Освобождённая цель доступна.")
	TEST_ASSERT_NULL(spell.heretic_failure_reason, "Успешная проверка убирает старую причину.")

/// Жатва пишет один итог с фактическим уроном или причиной отмены, включая смертельное попадание.
/datum/unit_test/heretic_spirit_reap_logging/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_SPIRIT)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	for(var/scenario in list("hit", "lethal", "stay", "touch", "destroy", "return"))
		var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
		user.logging[num2text(LOG_ATTACK)] = list()
		TEST_ASSERT(spirit.reap(user, victim), "Первый удар создаёт душу.")
		var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
		var/obj/structure/heretic_spirit_soul/anchor = soul.anchor
		switch(scenario)
			if("hit", "lethal")
				victim.forceMove(get_step(get_step(victim, NORTH), NORTH))
				if(scenario == "lethal")
					victim.setToxLoss(victim.getToxLoss() + victim.health - (HEALTH_THRESHOLD_DEAD + 5), forced = TRUE)
					TEST_ASSERT(victim.stat != DEAD && abs(victim.health - (HEALTH_THRESHOLD_DEAD + 5)) <= DAMAGE_PRECISION, "Цель жива и находится в пяти единицах здоровья от смерти.")
				soul.reap_at = world.time
				soul.finish_reap()
			if("stay")
				soul.reap_at = world.time
				soul.finish_reap()
			if("touch")
				anchor.attack_hand(victim)
			if("destroy")
				anchor.take_damage(100, BRUTE, MELEE)
			if("return")
				victim.forceMove(get_step(victim, NORTH))
				victim.forceMove(get_turf(anchor))
		TEST_ASSERT(QDELETED(soul), "Сценарий [scenario] завершает связь.")
		var/list/attack_log = user.logging[num2text(LOG_ATTACK)]
		TEST_ASSERT_EQUAL(length(attack_log), 2, "Есть начальный удар и ровно один итог [scenario].")
		var/list/result = attack_log[2]
		if(scenario == "hit" || scenario == "lethal")
			TEST_ASSERT(findtext(result["what"], "второй удар: 25 ушибов"), "Попадание пишет фактический урон [scenario].")
			if(scenario == "lethal")
				TEST_ASSERT_EQUAL(victim.stat, DEAD, "Второй удар действительно смертелен.")
		else if(scenario == "stay")
			TEST_ASSERT(findtext(result["what"], "второй удар: 15 ушибов"), "Цель у своей души получает ослабленный удар.")
		else
			var/list/reasons = list("touch" = "цель коснулась", "destroy" = "душа разрушена", "return" = "цель вернулась")
			TEST_ASSERT(findtext(result["what"], reasons[scenario]), "Отмена пишет причину [scenario].")
		qdel(victim)

/// Плата ограничена общей задержкой, разумной целью и конечным запасом.
/datum/unit_test/heretic_spirit_harvest/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.mind = allocate_mind()
	victim.mind.current = victim
	user.adjustStaminaLoss(30)
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	TEST_ASSERT(spirit.collect(user, soul), "Сбор души разумного врага выдаёт плату.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 4, "Одна душа даёт один обол.")
	TEST_ASSERT(abs(user.getStaminaLoss() - 15) <= DAMAGE_PRECISION, "Сбор восстанавливает 15 выносливости.")
	soul = spirit.separate(victim, spirit)
	TEST_ASSERT(!spirit.collect(user, soul), "Повторный сбор в задержке не выдаёт плату.")
	TEST_ASSERT(QDELETED(soul), "Собранная без платы душа всё равно исчезает.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 4, "Быстрый повтор не копит оболы.")
	COOLDOWN_RESET(spirit, spirit_harvest)
	TEST_ASSERT(spirit.collect(user, spirit.separate(victim, spirit)), "По завершении задержки плата снова доступна.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 5, "Вместимость достигнута.")
	COOLDOWN_RESET(spirit, spirit_harvest)
	spirit.collect(user, spirit.separate(victim, spirit))
	TEST_ASSERT_EQUAL(spirit.combat_resource, 5, "Запас не переполняется.")
	var/mob/living/animal = allocate(/mob/living/simple_animal/mouse, get_step(user, NORTH))
	COOLDOWN_RESET(spirit, spirit_harvest)
	TEST_ASSERT(!spirit.collect(user, spirit.separate(animal, spirit)), "Животное не производит оболы.")
	spirit.combat_resource = 0
	for(var/index in 1 to 4)
		COOLDOWN_RESET(spirit, spirit_recovery)
		spirit.on_life(user)
	TEST_ASSERT_EQUAL(spirit.combat_resource, 2, "Ожидание возвращает только два обола.")

/// Переправа проверяет диагональные преграды и ограничения тела.
/datum/unit_test/heretic_spirit_crossing_collision/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/turf/origin = get_turf(user)
	var/turf/destination = get_step(user, NORTHEAST)
	var/datum/eldritch_knowledge/spell/spirit_step/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/step/spell = knowledge.granted_spell
	var/obj/blocker = allocate(/obj, get_step(user, EAST))
	blocker.density = TRUE
	TEST_ASSERT(!spell.can_target(destination, user, TRUE), "Диагональный угол закрывает выбор.")
	TEST_ASSERT(!spirit.cross(user, destination), "Прямое перемещение не срезает угол.")
	qdel(blocker)
	user.anchored = TRUE
	TEST_ASSERT(!spirit.cross(user, destination), "Закреплённое тело не перемещается.")
	user.anchored = FALSE
	var/obj/structure/bed/bed = allocate(/obj/structure/bed, origin)
	user.buckled = bed
	TEST_ASSERT(!spirit.cross(user, destination), "Пристёгнутое тело не перемещается.")
	user.buckled = null
	ADD_TRAIT(user, TRAIT_NO_TELEPORT, TRAIT_GENERIC)
	TEST_ASSERT(!spirit.cross(user, destination), "Запрет телепортации действует.")
	REMOVE_TRAIT(user, TRAIT_NO_TELEPORT, TRAIT_GENERIC)
	TEST_ASSERT_EQUAL(spirit.combat_resource, 3, "Отказы не тратят оболы.")
	user.adjustStaminaLoss(20)
	TEST_ASSERT(spell.can_target(destination, user, TRUE), "Свободная клетка доступна.")
	spell.cast(list(destination), user)
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Реальная способность перемещает тело.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 2, "Успешная переправа стоит один обол.")
	TEST_ASSERT(abs(user.getStaminaLoss() - 5) <= DAMAGE_PRECISION, "Переправа восстанавливает 15 выносливости.")

/// Своя душа расширяет дальность переправы и собирается после прибытия.
/datum/unit_test/heretic_spirit_crossing_soul/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/turf/destination = get_step(get_step(get_step(get_step(user, EAST), EAST), EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	victim.mind = allocate_mind()
	victim.mind.current = victim
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	TEST_ASSERT_NOTNULL(soul, "Дальняя душа создана.")
	victim.forceMove(get_step(victim, NORTH))
	var/obj/structure/heretic_spirit_soul/anchor = soul.anchor
	TEST_ASSERT(spirit.cross(user, anchor), "Собственная душа даёт дальнюю переправу.")
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Перевозчик достигает души.")
	TEST_ASSERT(QDELETED(soul) && QDELETED(anchor), "Прибытие собирает душу.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 3, "Плата за душу компенсирует стоимость перехода.")

/// Фонарь перемещает только души, лечит с общим пределом и требует своего владельца.
/datum/unit_test/heretic_spirit_lantern/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spirit_relic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/item/heretic_path_relic/spirit/relic = allocate(/obj/item/heretic_path_relic/spirit)
	relic.creator = WEAKREF(user.mind)
	relic.knowledge_ref = WEAKREF(heretic.get_knowledge(/datum/eldritch_knowledge/spirit_relic))
	user.put_in_hands(relic)
	user.adjustBruteLoss(8)
	user.adjustFireLoss(12)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	victim.mind = allocate_mind()
	victim.mind.current = victim
	var/turf/body_position = get_turf(victim)
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	TEST_ASSERT(!relic.beckon(victim), "Посторонний не пользуется фонарём.")
	TEST_ASSERT(relic.beckon(user), "Фонарь подтягивает и собирает душу.")
	TEST_ASSERT_EQUAL(get_turf(victim), body_position, "Тело не сдвинулось вместе с душой.")
	TEST_ASSERT(QDELETED(soul), "Собранная душа освобождает жертву.")
	TEST_ASSERT(abs(user.getBruteLoss() + user.getFireLoss() - 8) <= DAMAGE_PRECISION, "Суммарно вылечено ровно 12 урона.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 4, "Фонарь выдаёт обычную плату.")
	TEST_ASSERT(!relic.beckon(user), "Перезарядка предотвращает повтор.")
	COOLDOWN_RESET(relic, relic_cooldown)
	spirit.separate(victim, spirit)
	TEST_ASSERT(relic.beckon(user), "Душу можно убрать и в задержке платы.")
	TEST_ASSERT(abs(user.getBruteLoss() + user.getFireLoss() - 8) <= DAMAGE_PRECISION, "Задержка платы предотвращает повторное лечение.")

/// Смерть, смена тела, удаление роли и знания убирают души, метки и способности.
/datum/unit_test/heretic_spirit_lifecycle/Run()
	for(var/scenario in list("death", "transfer", "role", "knowledge", "base"))
		var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
		heretic.selected_path = PATH_SPIRIT
		var/mob/living/user = heretic.owner.current
		heretic.apply_innate_effects(user)
		heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
		heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
		heretic.gain_knowledge(/datum/eldritch_knowledge/spirit_mark)
		var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
		var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
		spirit.reap(user, victim)
		var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
		var/obj/structure/heretic_spirit_soul/anchor = soul.anchor
		var/datum/status_effect/eldritch/spirit/mark = victim.apply_status_effect(/datum/status_effect/eldritch/spirit, spirit)
		var/obj/effect/proc_holder/spell/old_power = spirit.combat_power
		if(scenario == "death")
			user.stat = DEAD
			spirit.on_death(user)
			TEST_ASSERT_EQUAL(spirit.combat_resource, 0, "Смерть обнуляет оболы.")
		if(scenario == "transfer")
			var/mob/living/new_body = allocate(/mob/living/carbon/human, get_step(user, NORTH))
			heretic.owner.transfer_to(new_body)
			TEST_ASSERT(QDELETED(old_power), "Старая способность удаляется при переселении.")
			TEST_ASSERT_EQUAL(spirit.spirit_body, new_body, "Знание привязано к новому телу.")
			TEST_ASSERT(!spirit.can_use(user) && spirit.can_use(new_body), "Старое тело теряет права.")
		if(scenario == "role")
			qdel(heretic)
		if(scenario == "knowledge")
			qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_reap))
			qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spirit_mark))
			TEST_ASSERT(!spirit.reap(user, victim), "Удалённое знание не позволяет создать новую жатву.")
		if(scenario == "base")
			qdel(spirit)
		TEST_ASSERT(QDELETED(soul) && QDELETED(anchor), "Сценарий [scenario] убирает обе стороны связи.")
		TEST_ASSERT(QDELETED(mark), "Сценарий [scenario] убирает внешнюю метку.")
		qdel(victim)
		qdel(heretic)

/// Число душ ограничено, а предел расстояния и удаление знания подготовки очищают связи.
/datum/unit_test/heretic_spirit_limits/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, SOUTHWEST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/status_effect/heretic_spirit/separated/first_soul
	for(var/index in 1 to 4)
		var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
		var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
		if(index == 1)
			first_soul = soul
	TEST_ASSERT(QDELETED(first_soul), "Четвёртая душа заменяет самую раннюю.")
	TEST_ASSERT_EQUAL(length(spirit.souls), 3, "Одновременно существуют только три души.")
	var/datum/status_effect/heretic_spirit/separated/armed = spirit.souls[1]
	var/datum/eldritch_knowledge/spell/spirit_reap/required = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	TEST_ASSERT(armed.arm(required, 25), "Жатва использует душу от другого знания.")
	qdel(required)
	TEST_ASSERT(QDELETED(armed), "Удаление знания подготовки гасит чужую по происхождению душу.")
	var/datum/status_effect/heretic_spirit/separated/distant = spirit.souls[1]
	var/mob/living/distant_body = distant.owner
	distant_body.forceMove(get_step(run_loc_floor_top_right, NORTHEAST))
	TEST_ASSERT(get_dist(user, distant_body) > 5, "Цель действительно вышла из дальности.")
	TEST_ASSERT(QDELETED(distant), "Переход дальше пяти клеток сразу рвёт связь.")

/// Хватка, метка и улучшенный крюк используют одну связь без продления её бюджета.
/datum/unit_test/heretic_spirit_grasp_mark_blade/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	for(var/knowledge_type in list(/datum/eldritch_knowledge/base_spirit, /datum/eldritch_knowledge/spirit_grasp, /datum/eldritch_knowledge/spirit_mark, /datum/eldritch_knowledge/spirit_upgrade))
		heretic.gain_knowledge(knowledge_type)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spirit_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/spirit_grasp)
	var/datum/eldritch_knowledge/spirit_mark/mark_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spirit_mark)
	var/datum/eldritch_knowledge/spirit_upgrade/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/spirit_upgrade)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE), "Хватка отделяет душу.")
	var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
	mark_knowledge.on_mansus_grasp(victim, user, TRUE)
	var/datum/status_effect/eldritch/spirit/old_mark = victim.has_status_effect(/datum/status_effect/eldritch/spirit)
	mark_knowledge.on_mansus_grasp(victim, user, TRUE)
	TEST_ASSERT(QDELETED(old_mark), "Повторная метка удаляет старую.")
	TEST_ASSERT_EQUAL(length(spirit.marks), 1, "Старые метки не копятся.")
	var/datum/status_effect/eldritch/spirit/mark = victim.has_status_effect(/datum/status_effect/eldritch/spirit)
	mark.on_effect()
	TEST_ASSERT(abs(victim.getBruteLoss() - 8) <= DAMAGE_PRECISION, "Метка добавляет восемь ушибов.")
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/heretic_spirit/separated), soul, "Детонация сохраняет прежнюю связь.")
	upgrade.on_eldritch_blade(victim, user, TRUE)
	upgrade.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 14) <= DAMAGE_PRECISION, "Крюк добавляет шесть ушибов один раз за задержку.")
	COOLDOWN_RESET(upgrade, spirit_blade)
	upgrade.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) <= DAMAGE_PRECISION, "После задержки крюк снова добавляет шесть ушибов.")
	qdel(grasp)
	TEST_ASSERT(QDELETED(soul), "Удаление источника хватки гасит её душу.")

/// Вознесение открывает бесплатный массовый рейс, расширяет запас и снимается вместе с эффектами.
/datum/unit_test/heretic_spirit_ascension/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/spirit_final)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/final_eldritch/spirit_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/spirit_final)
	TEST_ASSERT(!spirit.ring(user, TRUE), "Знание обряда без завершения не открывает рейс.")
	final_knowledge.finished = TRUE
	heretic.ascended = TRUE
	final_knowledge.on_body_gain(user)
	TEST_ASSERT_EQUAL(spirit.combat_resource_max, 8, "Вознесение расширяет кошель.")
	spirit.combat_resource = 3
	COOLDOWN_RESET(spirit, spirit_recovery)
	spirit.on_life(user)
	TEST_ASSERT_EQUAL(spirit.combat_resource, 4, "Вознесённый восстанавливает оболы выше обычного предела.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/effect/proc_holder/spell/self/heretic_spirit/crown/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_spirit/crown)
	spell.cast(list(user), user)
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) <= DAMAGE_PRECISION, "Последний рейс сразу наносит 30 ушибов.")
	var/datum/status_effect/heretic_spirit/separated/soul = victim.has_status_effect(/datum/status_effect/heretic_spirit/separated)
	TEST_ASSERT_EQUAL(soul.reap_damage, 40, "Вознесённая жатва имеет усиленный второй удар.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 4, "Вознесённая способность бесплатна.")
	final_knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(soul), "Утрата вознесения убирает подготовленную жатву.")
	TEST_ASSERT(!spirit.ascension_active, "Флаг вознесения снят.")
	TEST_ASSERT(!spirit.ring(user, TRUE), "Повторный рейс после утраты вознесения запрещён.")

/// Дело принимает настоящую кровать, оставляет след и не считает тот же отдел повторно.
/datum/unit_test/heretic_spirit_deed/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_SPIRIT)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/structure/bed/bed = allocate(/obj/structure/bed, get_step(user, EAST))
	var/obj/item/flashlight/wrong_target = allocate(/obj/item/flashlight, get_step(user, NORTH))
	TEST_ASSERT(!spirit.on_mansus_grasp(wrong_target, user, TRUE), "Обычный предмет не выполняет дело.")
	TEST_ASSERT(spirit.on_mansus_grasp(bed, user, TRUE), "Кровать выполняет дело пути.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Дело продвигается один раз.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(!spirit.on_mansus_grasp(bed, user, TRUE), "Тот же отдел повторно не считается.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in get_turf(bed)
	TEST_ASSERT_NOTNULL(trace, "На полу остаётся видимый след.")
	allocated += trace
	TEST_ASSERT_EQUAL(trace.icon_state, "sigil_spirit", "След использует символ пути духа.")

/// Душа под хозяином пропускает клики, а удар крюком и рука перевозчика по ней достаются лежащему телу.
/datum/unit_test/heretic_spirit_soul_click_through/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/item/melee/sickly_blade/spirit/hook = allocate(/obj/item/melee/sickly_blade/spirit)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	var/obj/structure/heretic_spirit_soul/anchor = soul.anchor
	TEST_ASSERT_EQUAL(anchor.mouse_opacity, MOUSE_OPACITY_TRANSPARENT, "Душа под хозяином не перехватывает клики.")
	victim.Paralyze(10 SECONDS)
	TEST_ASSERT_EQUAL(victim.body_position, LYING_DOWN, "Цель лежит на своей душе.")
	user.a_intent = INTENT_HARM
	hook.melee_attack_chain(user, anchor)
	TEST_ASSERT(victim.getBruteLoss() > 0, "Удар крюком по душе под телом ранит тело.")
	TEST_ASSERT(!QDELETED(soul) && !QDELETED(anchor), "Удар по телу не собирает и не разбивает душу.")
	user.a_intent = INTENT_HELP
	anchor.attack_hand(user)
	TEST_ASSERT(!QDELETED(soul), "Рука перевозчика достаётся телу, а не собирает душу под ним.")
	victim.forceMove(get_step(victim, NORTH))
	TEST_ASSERT_EQUAL(anchor.mouse_opacity, MOUSE_OPACITY_OPAQUE, "Оставленную телом душу снова можно выбрать.")

/// Удар крюком по связанному телу даёт обол раз в 6 секунд, а взрыв метки приносит ещё один.
/datum/unit_test/heretic_spirit_combat_income/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spirit_mark)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spirit_mark/mark_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spirit_mark)
	var/obj/item/melee/sickly_blade/spirit/hook = allocate(/obj/item/melee/sickly_blade/spirit)
	hook.force = 5
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	user.a_intent = INTENT_HARM
	spirit.combat_resource = 0
	hook.attack(victim, user)
	TEST_ASSERT(victim.getBruteLoss() > 0, "Крюк ранит цель.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 0, "Удар по телу без связи оболов не даёт.")
	TEST_ASSERT_NOTNULL(spirit.separate(victim, spirit), "Связь создана.")
	hook.attack(victim, user)
	TEST_ASSERT_EQUAL(spirit.combat_resource, 1, "Удар по связанному телу даёт обол.")
	hook.attack(victim, user)
	TEST_ASSERT_EQUAL(spirit.combat_resource, 1, "Повторный удар в пределах 6 секунд обол не даёт.")
	mark_knowledge.on_mansus_grasp(victim, user, TRUE)
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/eldritch/spirit), "Метка поставлена.")
	hook.attack(victim, user)
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/eldritch/spirit), "Крюк взрывает метку.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 2, "Взрыв метки даёт обол даже в задержке удара.")
	COOLDOWN_RESET(spirit, spirit_hook_income)
	hook.attack(victim, user)
	TEST_ASSERT_EQUAL(spirit.combat_resource, 3, "После задержки удар снова даёт обол.")

/// Переправа укорачивает дальнюю клетку до трёх, встаёт рядом с занятым телом и собирает душу под хозяином.
/datum/unit_test/heretic_spirit_crossing_landing/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spell/spirit_step/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/step/spell = knowledge.granted_spell
	var/turf/origin = get_turf(user)
	var/turf/far_floor = locate(origin.x + 5, origin.y, origin.z)
	TEST_ASSERT(spell.can_target(far_floor, user, TRUE), "Дальняя клетка пола доступна для укороченного перехода.")
	spell.cast(list(far_floor), user)
	TEST_ASSERT_EQUAL(get_turf(user), locate(origin.x + 3, origin.y, origin.z), "Переход укорочен до трёх клеток по линии.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 2, "Укороченный переход стоит один обол.")
	user.forceMove(origin)
	var/mob/living/enemy = allocate(/mob/living/carbon/human, locate(origin.x + 2, origin.y, origin.z))
	TEST_ASSERT(spell.can_target(enemy, user, TRUE), "Тело врага подходит целью перехода.")
	spell.cast(list(enemy), user)
	TEST_ASSERT_EQUAL(get_turf(user), locate(origin.x + 1, origin.y, origin.z), "Перевозчик встаёт рядом с телом со своей стороны.")
	qdel(enemy)
	user.forceMove(origin)
	spirit.combat_resource = 3
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(origin.x + 4, origin.y, origin.z))
	victim.mind = allocate_mind()
	victim.mind.current = victim
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Тело на своей душе даёт дальний переход к ней.")
	spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(get_turf(user), locate(origin.x + 3, origin.y, origin.z), "Перевозчик встаёт рядом с хозяином души.")
	TEST_ASSERT(QDELETED(soul), "Душа под телом собрана по прибытии.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 3, "Плата за душу возвращает потраченный обол.")
	user.forceMove(origin)
	var/obj/blocker = allocate(/obj, locate(origin.x + 2, origin.y, origin.z))
	blocker.density = TRUE
	TEST_ASSERT(!spell.can_target(get_turf(blocker), user, TRUE), "Плотный предмет на месте прибытия останавливает переход.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "плотным предметом"), "Отказ называет занятое место.")
	TEST_ASSERT(!spirit.cross(user, get_turf(blocker)), "Прямой вызов тоже не проходит сквозь предмет.")
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Отказ не перемещает перевозчика.")

/// Переправа переносит лежащую жертву, которую тащит перевозчик, и сохраняет захват; запрет телепортации и стоящих не трогает.
/datum/unit_test/heretic_spirit_crossing_passenger/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/spell/spirit_step/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/step/spell = knowledge.granted_spell
	var/turf/origin = get_turf(user)
	var/turf/destination = locate(origin.x + 3, origin.y, origin.z)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(origin, WEST))
	victim.Paralyze(30 SECONDS)
	user.start_pulling(victim)
	TEST_ASSERT_EQUAL(user.pulling, victim, "Перевозчик тащит жертву.")
	user.setGrabState(GRAB_AGGRESSIVE)
	spell.cast(list(destination), user)
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Перевозчик переправился.")
	TEST_ASSERT_EQUAL(get_dist(victim, user), 1, "Жертва оказалась рядом с местом прибытия.")
	TEST_ASSERT_EQUAL(user.pulling, victim, "Захват сохранён.")
	TEST_ASSERT_EQUAL(user.grab_state, GRAB_AGGRESSIVE, "Сила захвата не сбрасывается.")
	ADD_TRAIT(victim, TRAIT_NO_TELEPORT, TRAIT_GENERIC)
	var/turf/victim_turf = get_turf(victim)
	spell.cast(list(origin), user)
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Перевозчик вернулся без жертвы.")
	TEST_ASSERT_EQUAL(get_turf(victim), victim_turf, "Запрет телепортации оставляет жертву на месте.")
	var/mob/living/bystander = allocate(/mob/living/carbon/human, get_step(origin, SOUTH))
	user.start_pulling(bystander)
	TEST_ASSERT_EQUAL(user.pulling, bystander, "Перевозчик тащит стоящего.")
	var/turf/bystander_turf = get_turf(bystander)
	spell.cast(list(destination), user)
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Переправа без пассажира всё равно проходит.")
	TEST_ASSERT_EQUAL(get_turf(bystander), bystander_turf, "Стоящего на ногах Переправа не переносит.")

/// Стол не закрывает линию Духа, окно поперёк линии и полное окно закрывают, окно вдоль линии — нет.
/datum/unit_test/heretic_spirit_line_obstacles/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/sever/spell = spirit.combat_power
	var/turf/middle = get_step(get_step(user, EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(middle, EAST), EAST))
	var/obj/structure/table/table = allocate(/obj/structure/table, middle)
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Стол между перевозчиком и целью не закрывает линию.")
	spell.cast(list(victim), user)
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Разлучение через стол ранит цель.")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_spirit/separated), "Связь через стол держится.")
	qdel(table)
	var/obj/structure/window/side_window = allocate(/obj/structure/window, middle, NORTH)
	TEST_ASSERT(spirit.line_clear(user, victim), "Окно вдоль линии её не закрывает.")
	qdel(side_window)
	var/obj/structure/window/facing_window = allocate(/obj/structure/window, middle, EAST)
	TEST_ASSERT(!spirit.line_clear(user, victim), "Окно поперёк линии её закрывает.")
	qdel(facing_window)
	var/obj/structure/window/fulltile/full_window = allocate(/obj/structure/window/fulltile, middle)
	TEST_ASSERT(!spirit.line_clear(user, victim), "Полное окно закрывает линию.")
	qdel(full_window)
