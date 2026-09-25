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
	heretic.gain_knowledge(/datum/eldritch_knowledge/spirit_relic)
	var/datum/eldritch_knowledge/spirit_relic/purse = heretic.get_knowledge(/datum/eldritch_knowledge/spirit_relic)
	TEST_ASSERT_EQUAL(spirit.combat_resource_max, 6, "Кошель фонаря сразу даёт вместимость 6.")
	purse.passive_level = 3
	purse.on_passive_upgrade(user)
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
		var/expiry = soul.duration
		soul.drained = soul.drain_limit
		soul.reap_at = world.time
		TEST_ASSERT(soul.finish_reap(), "Второй удар попадает при целой связи [retreat ? "вдали от души" : "рядом с душой"].")
		TEST_ASSERT(abs(victim.getBruteLoss() - (retreat ? 47 : 37)) <= DAMAGE_PRECISION, "Второй удар наносит [retreat ? 25 : 15] ушибов.")
		TEST_ASSERT(!QDELETED(soul) && !QDELETED(anchor), "После Жатвы остаётся душа для продолжения боя.")
		TEST_ASSERT_EQUAL(soul.duration, expiry, "Долгая связь сохраняет прежний срок.")
		TEST_ASSERT_EQUAL(soul.drained, soul.drain_limit, "Жатва не восстанавливает запас истощения.")
		TEST_ASSERT_EQUAL(anchor.icon_state, "spirit_soul", "Предупреждение о Жатве погасло.")
		TEST_ASSERT(!soul.finish_reap(), "Завершённый удар нельзя повторить.")
		soul.tick()
		TEST_ASSERT(abs(victim.getBruteLoss() - (retreat ? 47 : 37)) <= DAMAGE_PRECISION, "Следующая обработка не повторяет удар.")
		TEST_ASSERT(soul.arm(knowledge, 25), "Следующая способность может подготовить новую Жатву сохранённой души.")
		TEST_ASSERT(!soul.finish_reap(), "Новая Жатва тоже требует полного предупреждения.")
		qdel(victim)
	TEST_ASSERT_EQUAL(spirit.combat_resource, 3, "Жатва доступна без затрат оболов.")

/// Поздняя Жатва дожидается удара и оставляет время на сбор без обновления истощения.
/datum/unit_test/heretic_spirit_late_reap/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	for(var/knowledge_type in list(/datum/eldritch_knowledge/base_spirit, /datum/eldritch_knowledge/spell/spirit_reap, /datum/eldritch_knowledge/spirit_mark, /datum/eldritch_knowledge/spirit_relic))
		heretic.gain_knowledge(knowledge_type)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spirit_mark/mark_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spirit_mark)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.mind = allocate_mind()
	victim.mind.current = victim
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	soul.duration = world.time + 0.5 SECONDS
	soul.drained = soul.drain_limit
	TEST_ASSERT(spirit.reap(user, victim), "Жатва использует истекающую душу.")
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/heretic_spirit/separated), soul, "Жатва сохраняет существующую душу.")
	TEST_ASSERT(soul.duration >= soul.reap_at, "Связь дожидается назначенного удара.")
	sleep(1 SECONDS)
	soul.process()
	TEST_ASSERT(!QDELETED(soul) && soul.reap_at, "Истёкший первоначальный срок не отменяет предупреждение и не ускоряет удар.")
	sleep(1.5 SECONDS)
	soul.process()
	TEST_ASSERT(!QDELETED(soul) && !soul.reap_at, "Второй удар срабатывает после предупреждения.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 37) <= DAMAGE_PRECISION, "Поздняя Жатва наносит оба удара.")
	TEST_ASSERT(soul.duration > world.time + 3 SECONDS, "После попадания осталось время на продолжение комбинации.")
	TEST_ASSERT_EQUAL(soul.drained, soul.drain_limit, "Продление не восстанавливает истощение.")
	mark_knowledge.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 43) <= DAMAGE_PRECISION, "После Жатвы крюк получает бонус по сохранённой связи.")
	var/obj/item/heretic_path_relic/spirit/relic = allocate(/obj/item/heretic_path_relic/spirit)
	relic.creator = WEAKREF(user.mind)
	relic.knowledge_ref = WEAKREF(heretic.get_knowledge(/datum/eldritch_knowledge/spirit_relic))
	user.put_in_hands(relic)
	user.adjustBruteLoss(20)
	TEST_ASSERT(relic.beckon(user), "Фонарь собирает душу после завершённой Жатвы.")
	TEST_ASSERT(QDELETED(soul), "Сбор завершает продлённую связь.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 4, "Сохранённая душа приносит обол.")
	TEST_ASSERT(abs(user.getBruteLoss() - 8) <= DAMAGE_PRECISION, "Сбор фонарём лечит 12 урона после Жатвы.")

/// Новая Жатва меняет источник подготовки, а сохранённая душа по-прежнему разрывается и истекает.
/datum/unit_test/heretic_spirit_reap_followup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	for(var/knowledge_type in list(/datum/eldritch_knowledge/base_spirit, /datum/eldritch_knowledge/spell/spirit_reap, /datum/eldritch_knowledge/spell/spirit_bell))
		heretic.gain_knowledge(knowledge_type)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spell/spirit_reap/reap_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_reap)
	for(var/scenario in list("touch", "return", "expire", "knowledge"))
		var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
		var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
		TEST_ASSERT(soul.arm(reap_knowledge, 25), "Жатва подготовлена на душе от базового знания.")
		soul.reap_at = world.time
		TEST_ASSERT(soul.finish_reap(), "Жатва оставляет живую душу.")
		switch(scenario)
			if("touch")
				soul.anchor.attack_hand(victim)
			if("return")
				var/turf/origin = get_turf(victim)
				victim.forceMove(get_step(victim, NORTH))
				victim.forceMove(origin)
			if("expire")
				soul.duration = world.time - 1
				soul.process()
			if("knowledge")
				TEST_ASSERT(spirit.ring(user), "Звон продолжает комбинацию после Жатвы.")
				TEST_ASSERT(soul.reap_at > world.time && !soul.finish_reap(), "Звон заново предупреждает о втором ударе.")
				qdel(reap_knowledge)
				TEST_ASSERT(!QDELETED(soul), "Старая подготовка больше не удерживает связь.")
				qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_bell))
		TEST_ASSERT(QDELETED(soul), "Способ разрыва [scenario] действует после Жатвы.")
		qdel(victim)

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
		if(scenario == "hit" || scenario == "stay")
			TEST_ASSERT(!QDELETED(soul), "Попадание по живому оставляет связь.")
			qdel(soul)
		TEST_ASSERT(QDELETED(soul), "Сценарий [scenario] завершает связь без повторного итога Жатвы.")
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

/// Хватка, метка и серебро крюка из Метки Духа используют одну связь без продления её бюджета.
/datum/unit_test/heretic_spirit_grasp_mark_blade/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	for(var/knowledge_type in list(/datum/eldritch_knowledge/base_spirit, /datum/eldritch_knowledge/spirit_grasp, /datum/eldritch_knowledge/spirit_mark))
		heretic.gain_knowledge(knowledge_type)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spirit_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/spirit_grasp)
	var/datum/eldritch_knowledge/spirit_mark/mark_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spirit_mark)
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
	mark_knowledge.on_eldritch_blade(victim, user, TRUE)
	mark_knowledge.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 14) <= DAMAGE_PRECISION, "Крюк добавляет шесть ушибов один раз за задержку.")
	COOLDOWN_RESET(mark_knowledge, spirit_blade)
	mark_knowledge.on_eldritch_blade(victim, user, TRUE)
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

/// Дело засчитывает обол на трупе в новом отделе и оставляет след; кровать и живой не в счёт, тот же отдел повторно не идёт, а пауза дела не тратит обол.
/datum/unit_test/heretic_spirit_deed/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_SPIRIT)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	user.a_intent = INTENT_HELP
	var/obj/structure/bed/bed = allocate(/obj/structure/bed, get_step(user, NORTH))
	TEST_ASSERT(!spirit.on_mansus_grasp(bed, user, TRUE), "Кровать больше не идёт в дело пути.")
	var/mob/living/carbon/human/living = allocate(/mob/living/carbon/human, get_step(get_step(user, NORTH), NORTH))
	TEST_ASSERT(!spirit.on_mansus_grasp(living, user, TRUE), "Живому обол не кладут.")
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, get_step(user, EAST))
	corpse.death()
	COOLDOWN_START(heretic.deed, progress_cooldown, HERETIC_DEED_COOLDOWN)
	TEST_ASSERT(!spirit.on_mansus_grasp(corpse, user, TRUE), "Во время паузы обол в новом отделе не кладётся.")
	TEST_ASSERT(findtext(spirit.grasp_failure_reason, "Слишком быстро"), "Отказ называет паузу: [spirit.grasp_failure_reason]")
	TEST_ASSERT_NULL(heretic_craft_on(corpse, "spirit_obol"), "Тело осталось без обола.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(spirit.on_mansus_grasp(corpse, user, TRUE), "Обол на трупе выполняет дело пути.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Дело продвигается один раз.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in get_turf(corpse)
	TEST_ASSERT_NOTNULL(trace, "На полу остаётся видимый след.")
	allocated += trace
	TEST_ASSERT_EQUAL(trace.icon_state, "sigil_spirit", "След использует символ пути духа.")
	var/mob/living/carbon/human/neighbour = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	neighbour.death()
	TEST_ASSERT(spirit.on_mansus_grasp(neighbour, user, TRUE), "В зачтённом отделе пауза оболу не мешает.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Тот же отдел повторно не считается.")
	var/turf/morgue = locate(user.x + 2, user.y + 2, user.z)
	heretic_test_area(morgue, /area/unit_test_spirit_morgue)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, morgue)
	stranger.death()
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(spirit.place_obol(user, stranger), "Обол в новом отделе ложится.")
	TEST_ASSERT_EQUAL(length(heretic.deed.counted_keys), 2, "Новый отдел засчитан.")

/area/unit_test_spirit_morgue
	name = "Spirit Morgue Test Room"
	requires_power = FALSE

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
/// Недостаток оболов останавливает звон до оплаты и объясняется при прямом вызове.
/datum/unit_test/heretic_spirit_bell_failure_feedback/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_bell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spell/spirit_bell/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_bell)
	var/obj/effect/proc_holder/spell/self/heretic_spirit/bell/bell = knowledge.granted_spell
	spirit.combat_resource = 1
	bell.charge_counter = bell.charge_max
	TEST_ASSERT(!bell.can_cast(user, FALSE, TRUE), "Одного обола недостаточно для звона.")
	TEST_ASSERT(findtext(bell.heretic_failure_reason, "сейчас 1"), "Отказ показывает имеющийся запас.")
	bell.charge_counter = 0
	bell.cast(list(user), user)
	TEST_ASSERT(findtext(bell.heretic_failure_reason, "нужны 2 обола"), "Прямой вызов тоже объясняет стоимость.")
	TEST_ASSERT_EQUAL(bell.charge_counter, bell.charge_max, "Отказ возвращает перезарядку.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 1, "Отказ не расходует оставшийся обол.")

/datum/unit_test/proc/spirit_ferry_victim(turf/place, with_mind = TRUE) as /mob/living/carbon/human
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, place)
	if(with_mind)
		victim.mind = allocate_mind()
		victim.mind.current = victim
	return victim

/// Вознёсшийся Дух проходит сквозь людей и столы и при потере тела снимает только добавленные флаги прохода.
/datum/unit_test/heretic_spirit_ferryman_passage/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(run_loc_floor_bottom_left)
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/spirit_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/spirit_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/spirit_final)
	var/flags_before = user.pass_flags
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(user)
	TEST_ASSERT((user.pass_flags & PASSMOB) && (user.pass_flags & PASSTABLE), "Вознесение Духа даёт проход сквозь существ и столы.")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_PASSTABLE), "Проход над столами учтён общим счётчиком.")
	var/turf/start = run_loc_floor_bottom_left
	var/turf/crowded = get_step(start, EAST)
	var/mob/living/carbon/human/blocker = allocate(/mob/living/carbon/human, crowded)
	TEST_ASSERT(user.Move(crowded, EAST), "Перевозчик проходит сквозь человека.")
	TEST_ASSERT_EQUAL(blocker.loc, crowded, "Человек остаётся на месте, обмена нет.")
	var/obj/structure/table/table = allocate(/obj/structure/table, get_step(crowded, EAST))
	TEST_ASSERT(user.Move(get_turf(table), EAST), "Перевозчик проходит сквозь стол.")
	finale.on_body_lose(user)
	TEST_ASSERT_EQUAL(user.pass_flags, flags_before, "Потеря тела возвращает прежние флаги прохода.")
	user.pass_flags |= PASSTABLE
	finale.on_body_gain(user)
	finale.on_body_lose(user)
	TEST_ASSERT(user.pass_flags & PASSTABLE, "Свой проход над столами не снимается вместе с вознесением.")
	TEST_ASSERT(!(user.pass_flags & PASSMOB), "Добавленный проход сквозь существ снят.")
	user.pass_flags &= ~PASSTABLE
	REMOVE_TRAIT(user, TRAIT_PASSTABLE, INNATE_TRAIT)
	finale.on_body_gain(user)
	passtable_on(user, "spirit_test")
	finale.on_body_lose(user)
	TEST_ASSERT(user.pass_flags & PASSTABLE, "Чужой источник прохода над столами переживает конец вознесения.")
	passtable_off(user, "spirit_test")
	TEST_ASSERT(!(user.pass_flags & PASSTABLE), "Без источников проход над столами снят.")

/// Смерть человека рядом с вознёсшимся Духом платит 2 обола и лечит 20; дальние, без разума, защищённые от магии и союзники не платят.
/datum/unit_test/heretic_spirit_ferryman_toll/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(run_loc_floor_bottom_left)
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/spirit_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/final_eldritch/spirit_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/spirit_final)
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(user)
	var/datum/component/heretic_spirit_ferryman/ferryman = user.GetComponent(/datum/component/heretic_spirit_ferryman)
	TEST_ASSERT_NOTNULL(ferryman, "Вознесение Духа делает героя перевозчиком.")
	TEST_ASSERT_EQUAL(ferryman.ferry_range, HERETIC_SPIRIT_FERRY_RANGE, "Плату собирают в семи клетках.")
	var/turf/start = run_loc_floor_bottom_left
	spirit.combat_resource = 0
	user.adjustBruteLoss(40, forced = TRUE)
	var/brute_before = user.getBruteLoss()
	var/mob/living/carbon/human/crew = spirit_ferry_victim(get_step(start, EAST))
	crew.death()
	TEST_ASSERT_EQUAL(spirit.combat_resource, HERETIC_SPIRIT_FERRY_OBOLS, "Смерть члена экипажа рядом даёт 2 обола.")
	TEST_ASSERT(abs(brute_before - user.getBruteLoss() - HERETIC_SPIRIT_FERRY_HEAL) <= DAMAGE_PRECISION, "Смерть рядом лечит 20 урона.")
	spirit.combat_resource = 0
	ferryman.ferry_range = 3
	spirit_ferry_victim(locate(start.x + 4, start.y, start.z)).death()
	TEST_ASSERT_EQUAL(spirit.combat_resource, 0, "Смерть дальше радиуса не платит.")
	ferryman.ferry_range = HERETIC_SPIRIT_FERRY_RANGE
	spirit_ferry_victim(get_step(start, NORTH), with_mind = FALSE).death()
	TEST_ASSERT_EQUAL(spirit.combat_resource, 0, "Тело без разума не платит.")
	var/mob/living/carbon/human/warded = spirit_ferry_victim(get_step(start, NORTHEAST))
	var/datum/component/anti_magic/ward = warded.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	warded.death()
	TEST_ASSERT_EQUAL(spirit.combat_resource, 0, "Смерть защищённого от магии не платит.")
	TEST_ASSERT_EQUAL(ward.charges, 5, "Проверка защиты не тратит заряды.")
	var/mob/living/carbon/human/foiled = spirit_ferry_victim(locate(start.x + 1, start.y + 2, start.z))
	foiled.AddComponent(/datum/component/anti_magic, FALSE, FALSE, TRUE, null, 5)
	foiled.death()
	TEST_ASSERT_EQUAL(spirit.combat_resource, HERETIC_SPIRIT_FERRY_OBOLS, "Защита от телепатии, как у шапочки из фольги, плату не отменяет.")
	spirit.combat_resource = 0
	var/datum/antagonist/heretic/ally = allocate_heretic(locate(start.x + 2, start.y + 2, start.z))
	ally.owner.current.death()
	TEST_ASSERT_EQUAL(spirit.combat_resource, 0, "Смерть другого еретика не платит.")
	var/list/examine_lines = list()
	SEND_SIGNAL(user, COMSIG_PARENT_EXAMINE, crew, examine_lines)
	TEST_ASSERT(findtext(jointext(examine_lines, " "), "семи клетках"), "Осмотр называет радиус сбора платы.")
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_spirit_ferryman), "Потеря тела снимает перевозчика.")
	spirit_ferry_victim(locate(start.x + 3, start.y + 1, start.z)).death()
	TEST_ASSERT_EQUAL(spirit.combat_resource, 0, "Без вознесения смерть рядом не платит.")

/datum/unit_test/proc/ascend_spirit_ferryman(turf/place)
	var/datum/antagonist/heretic/heretic = allocate_heretic(place)
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/spirit_final)
	var/datum/eldritch_knowledge/final_eldritch/spirit_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/spirit_final)
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(heretic.owner.current)
	return heretic

/// Шаг сквозь человека или стол оставляет полупрозрачный шлейф и огоньки; пустая клетка проходом не считается.
/datum/unit_test/heretic_spirit_passage_visuals/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = ascend_spirit_ferryman(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/component/heretic_spirit_ferryman/ferryman = user.GetComponent(/datum/component/heretic_spirit_ferryman)
	TEST_ASSERT(!ferryman.passing_through(user), "На пустой клетке герой ни сквозь что не проходит.")
	var/turf/crowded = get_step(start, EAST)
	allocate(/mob/living/carbon/human, crowded)
	TEST_ASSERT(user.Move(crowded, EAST), "Перевозчик проходит сквозь человека, как раньше.")
	TEST_ASSERT(ferryman.passing_through(user), "Клетка с человеком - проход сквозь него.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_vfx/ghost) in start, "Без зрителей рядом шлейф не рисуется.")
	var/obj/structure/table/table = allocate(/obj/structure/table, get_step(crowded, EAST))
	TEST_ASSERT(user.Move(get_turf(table), EAST), "Перевозчик проходит сквозь стол, как раньше.")
	TEST_ASSERT(ferryman.passing_through(user), "Клетка со столом - тоже проход.")
	TEST_ASSERT(ferryman.stepped_through(user, crowded), "Шаг на соседнюю клетку сквозь стол оставляет шлейф.")
	TEST_ASSERT(!ferryman.stepped_through(user, start), "Прыжок через клетку на стол - перенос, а не проход сквозь него.")
	var/list/before = list_vfx_bursts(get_turf(user))
	ferryman.show_passage(crowded, EAST)
	var/obj/effect/temp_visual/heretic_vfx/ghost/trail = locate() in crowded
	TEST_ASSERT_NOTNULL(trail, "Шлейф остаётся там, откуда герой шагнул.")
	TEST_ASSERT(trail.glow in trail.vis_contents, "Шлейф светится в темноте.")
	TEST_ASSERT(trail.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Шлейф не мешает кликам.")
	var/obj/effect/temp_visual/heretic_vfx/burst/wisps = find_vfx_burst(get_turf(user), /particles/heretic_ascension/spirit/passage, before)
	TEST_ASSERT_NOTNULL(wisps, "Сквозь пройденное поднимаются огоньки.")
	user.alpha = 100
	ferryman.show_passage(start, EAST)
	var/obj/effect/temp_visual/heretic_vfx/ghost/pale_trail = locate() in start
	TEST_ASSERT(trail.peak_alpha > pale_trail?.peak_alpha, "Полупрозрачный герой оставляет шлейф бледнее: [trail.peak_alpha] и [pale_trail?.peak_alpha].")
	TEST_ASSERT_EQUAL(pale_trail?.peak_alpha, round(trail.peak_alpha * 100 / 255), "Шлейф бледнеет в той же доле, что и герой.")
	user.alpha = 255
	TEST_ASSERT(wait_for_qdeleted(trail) && wait_for_qdeleted(wisps, 3 SECONDS), "Шлейф и огоньки гаснут.")

/// Смерть рядом с перевозчиком: душа летит из тела в героя и гаснет в нём бледной вспышкой; плата прежняя.
/datum/unit_test/heretic_spirit_toll_visuals/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = ascend_spirit_ferryman(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	spirit.combat_resource = 0
	user.adjustBruteLoss(40, forced = TRUE)
	var/brute_before = user.getBruteLoss()
	var/turf/death_turf = locate(start.x + 3, start.y + 1, start.z)
	var/mob/living/carbon/human/crew = spirit_ferry_victim(death_turf)
	var/list/lights_before = list()
	for(var/obj/effect/dummy/lighting_obj/light in start)
		lights_before += light
	crew.death()
	TEST_ASSERT_EQUAL(spirit.combat_resource, HERETIC_SPIRIT_FERRY_OBOLS, "Смерть рядом платит 2 обола, как раньше.")
	TEST_ASSERT(abs(brute_before - user.getBruteLoss() - HERETIC_SPIRIT_FERRY_HEAL) <= DAMAGE_PRECISION, "Смерть рядом лечит 20, как раньше.")
	TEST_ASSERT_NOTNULL(user.get_filter(HERETIC_VFX_PULSE_FILTER), "Плата вспыхивает на герое в миг смерти.")
	var/obj/effect/abstract/heretic_spirit_toll_soul/soul = locate() in user.vis_contents
	TEST_ASSERT_NOTNULL(soul, "Душа летит к перевозчику.")
	TEST_ASSERT_EQUAL(soul.from_x, 3 * world.icon_size, "Душа вылетает из тела умершего.")
	TEST_ASSERT_EQUAL(soul.from_y, world.icon_size, "Душа вылетает из тела умершего.")
	TEST_ASSERT(length(soul.overlays), "Душа светится в темноте.")
	TEST_ASSERT(wait_for_qdeleted(soul, 2 SECONDS), "Душа долетает и гаснет.")
	TEST_ASSERT(!(soul in user.vis_contents), "Долетевшая душа не остаётся на герое.")
	var/flashes = 0
	for(var/obj/effect/dummy/lighting_obj/light in start)
		if(!(light in lights_before))
			flashes++
	TEST_ASSERT(flashes > 0, "Душа гаснет в герое бледной вспышкой.")

/// Последний рейс: звон и свет фонаря, бледная волна, души по спирали к перевозчику, земля дрожит; урон прежний, пустые клетки не вспыхивают.
/datum/unit_test/heretic_spirit_last_voyage_visuals/Run()
	var/turf/start = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = ascend_spirit_ferryman(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/turf/victim_turf = locate(start.x + 2, start.y, start.z)
	var/turf/empty_turf = locate(start.x, start.y + 2, start.z)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, victim_turf)
	var/list/before = list_vfx_bursts(start)
	TEST_ASSERT(spirit.ring(user, TRUE), "Последний рейс звучит.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) <= DAMAGE_PRECISION, "Первый удар прежний: 30 ушибов.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 25) <= DAMAGE_PRECISION, "Выносливость прежняя: 25.")
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = locate() in start
	TEST_ASSERT_NOTNULL(wave, "От перевозчика идёт бледная волна.")
	var/obj/effect/temp_visual/heretic_vfx/converge/spiral = locate() in start
	TEST_ASSERT_NOTNULL(spiral, "Души по спирали стягиваются к перевозчику.")
	var/obj/effect/temp_visual/heretic_vfx/burst/souls = find_vfx_burst(start, /particles/heretic_ascension/spirit, before)
	TEST_ASSERT_NOTNULL(souls, "Души вырываются вспышкой.")
	TEST_ASSERT_NOTNULL(user.get_filter(HERETIC_VFX_RAYS_FILTER), "Фонарь перевозчика светит лучами.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_spirit/burst) in victim_turf, "Задетый враг вспыхивает.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_spirit/burst) in empty_turf, "Пустые клетки не вспыхивают по одной.")
	TEST_ASSERT(wait_for_qdeleted(wave) && wait_for_qdeleted(spiral, 3 SECONDS), "Волна и спираль гаснут.")

/datum/unit_test/heretic_spirit_visual_types_create_and_destroy/Run()
	var/atom/movable/thing = new /obj/effect/abstract/heretic_spirit_toll_soul(run_loc_floor_bottom_left)
	qdel(thing)
	TEST_ASSERT(QDELETED(thing), "/obj/effect/abstract/heretic_spirit_toll_soul удаляется без ошибок.")

/datum/unit_test/proc/spirit_corpse(turf/place, with_mind = FALSE) as /mob/living/carbon/human
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, place)
	if(with_mind)
		corpse.mind = allocate_mind()
		corpse.mind.current = corpse
	corpse.death()
	return corpse

/// Обол на глаза: до трёх оболов, новый вытесняет старый; улика видна экипажу, нулевой жезл снимает обол, смерть и смена тела еретика оболы не трогают, удаление базы снимает все.
/datum/unit_test/heretic_spirit_obol_craft/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_SPIRIT)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/list/corpses = list()
	for(var/index in 1 to HERETIC_SPIRIT_OBOL_LIMIT + 1)
		corpses += spirit_corpse(get_step(user, EAST))
	var/mob/living/carbon/human/first = corpses[1]
	user.a_intent = INTENT_HARM
	TEST_ASSERT(!spirit.on_mansus_grasp(first, user, TRUE), "Вне «Помощи» обол не кладётся.")
	TEST_ASSERT(findtext(spirit.grasp_failure_reason, "Помощь"), "Отказ подсказывает намерение: [spirit.grasp_failure_reason]")
	user.a_intent = INTENT_HELP
	TEST_ASSERT(spirit.on_mansus_grasp(first, user, TRUE), "Обол лёг на глаза трупа.")
	TEST_ASSERT_NOTNULL(heretic_craft_on(first, "spirit_obol"), "Обол - ремесло на теле.")
	TEST_ASSERT(!spirit.on_mansus_grasp(first, user, TRUE), "Второй обол на то же тело не ложится.")
	TEST_ASSERT(findtext(spirit.grasp_failure_reason, "уже лежит"), "Отказ объясняет, что обол уже лежит.")
	for(var/index in 2 to HERETIC_SPIRIT_OBOL_LIMIT + 1)
		TEST_ASSERT(spirit.on_mansus_grasp(corpses[index], user, TRUE), "Обол [index] лёг.")
	TEST_ASSERT_NULL(heretic_craft_on(first, "spirit_obol"), "Новый обол вытеснил самый старый.")
	TEST_ASSERT_EQUAL(length(spirit.obols), HERETIC_SPIRIT_OBOL_LIMIT, "Держатся три обола.")
	TEST_ASSERT(findtext(spirit.combat_resource_state(), "[HERETIC_SPIRIT_OBOL_LIMIT] из [HERETIC_SPIRIT_OBOL_LIMIT]"), "Состояние запаса считает оболы на глазах: [spirit.combat_resource_state()]")
	var/mob/living/carbon/human/second = corpses[2]
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	TEST_ASSERT(findtext(jointext(second.examine(crew), " "), "монеты"), "Экипаж видит монеты на глазах трупа.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, second)
	TEST_ASSERT_NULL(heretic_craft_on(second, "spirit_obol"), "Нулевой жезл снимает обол.")
	TEST_ASSERT(!(second in spirit.obols), "Знание забывает снятый обол.")
	user.stat = DEAD
	spirit.on_death(user)
	user.stat = CONSCIOUS
	var/mob/living/carbon/human/third = corpses[3]
	TEST_ASSERT_NOTNULL(heretic_craft_on(third, "spirit_obol"), "Смерть еретика обол не снимает.")
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT_NOTNULL(heretic_craft_on(third, "spirit_obol"), "Смена тела обол не снимает.")
	qdel(corpses[4])
	TEST_ASSERT_EQUAL(length(spirit.obols), 1, "Удалённое тело уходит из списка оболов.")
	qdel(spirit)
	TEST_ASSERT_NULL(heretic_craft_on(third, "spirit_obol"), "Удаление базы снимает оставшиеся оболы.")

/// Последний миг читается из лога атак тела после настоящего удара ножом: кто последним ранил (имя по внешности), чем, когда и где; схвативший без урона не считается, без записей смерть тихая.
/datum/unit_test/heretic_spirit_obol_last_moment/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_SPIRIT)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/carbon/human/quiet = spirit_corpse(get_step(user, EAST))
	TEST_ASSERT(findtext(spirit.last_moment(quiet), "смерть пришла тихо"), "Без записей смерть тихая: [spirit.last_moment(quiet)]")
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/mob/living/carbon/human/killer = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	var/mob/living/carbon/human/orderly = allocate(/mob/living/carbon/human, get_step(get_step(user, NORTH), NORTH))
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife)
	killer.name = "Человек в противогазе"
	orderly.name = "Санитар"
	killer.put_in_hands(knife)
	killer.a_intent = INTENT_HARM
	knife.melee_attack_chain(killer, victim)
	TEST_ASSERT(victim.getBruteLoss() > 0, "Нож ранил жертву.")
	log_combat(orderly, victim, "хватает")
	victim.death()
	var/text = spirit.last_moment(victim)
	TEST_ASSERT(findtext(text, killer.name), "Назван ранивший по внешности: [text]")
	TEST_ASSERT(!findtext(text, orderly.name), "Схвативший без урона не назван: [text]")
	TEST_ASSERT(findtext(text, knife.name), "Названо оружие: [text]")
	TEST_ASSERT(findtext(text, get_area_name(victim, TRUE)), "Названо место: [text]")
	TEST_ASSERT(findtext(text, "только что"), "Названо время: [text]")
	var/list/entries = victim.logging[num2text(LOG_VICTIM)]
	for(var/list/entry as anything in entries)
		entry["timestamp"] -= 2 MINUTES
	text = spirit.last_moment(victim)
	TEST_ASSERT(findtext(text, "2 минуты назад"), "Время называется давностью: [text]")
	TEST_ASSERT_EQUAL(spirit.log_weapon("has been shot by ckey/(Стрелок) при помощи \[pistol bullet\] (NEWHP: 40)"), "pistol bullet", "Снаряд в квадратных скобках тоже называется.")

/// Призрак тела с оболом 5 минут шепчет только положившему обол: глагол выдаётся и снимается, шёпот пишется в лог, чужой призрак, истёкший срок и снятый обол не пропускают шёпот.
/datum/unit_test/heretic_spirit_obol_whisper/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_SPIRIT)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/carbon/human/corpse = spirit_corpse(get_step(user, EAST), with_mind = TRUE)
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer, get_turf(corpse))
	ghost.mind = corpse.mind
	var/whisper_verb = /mob/dead/observer/proc/heretic_spirit_whisper
	user.a_intent = INTENT_HELP
	TEST_ASSERT(spirit.on_mansus_grasp(corpse, user, TRUE), "Обол лёг на глаза.")
	TEST_ASSERT(!(whisper_verb in ghost.verbs), "Призраку без клиента шёпот не открывается.")
	spirit.open_whisper(corpse, ghost)
	TEST_ASSERT(whisper_verb in ghost.verbs, "Призрак тела получил шёпот.")
	TEST_ASSERT(abs(spirit.obols[corpse] - world.time - HERETIC_SPIRIT_WHISPER_TIME) < 1, "Шёпот открыт на 5 минут.")
	var/mob/dead/observer/stranger = allocate(/mob/dead/observer, get_turf(corpse))
	TEST_ASSERT(!spirit.deliver_whisper(stranger, "Я тоже хочу"), "Чужой призрак не шепчет.")
	ghost.logging[num2text(LOG_SAY)] = list()
	TEST_ASSERT(spirit.deliver_whisper(ghost, "Меня убил повар"), "Шёпот доставлен еретику.")
	var/list/say_log = ghost.logging[num2text(LOG_SAY)]
	var/list/last_entry = length(say_log) ? say_log[length(say_log)] : null
	TEST_ASSERT(last_entry && findtext(last_entry["what"], "Меня убил повар"), "Шёпот записан в лог.")
	TEST_ASSERT(!spirit.deliver_whisper(ghost, "Ещё раз"), "Шёпот сразу следом не доходит.")
	TEST_ASSERT(findtext(spirit.whisper_failure, "Слишком часто"), "Отказ называет паузу: [spirit.whisper_failure]")
	spirit.whisper_ready[corpse] = world.time
	TEST_ASSERT(spirit.deliver_whisper(ghost, "Ещё раз"), "После паузы шёпот снова доходит.")
	spirit.obols[corpse] = world.time
	TEST_ASSERT(!spirit.deliver_whisper(ghost, "Поздно"), "После срока шёпот не доходит.")
	TEST_ASSERT(findtext(spirit.whisper_failure, "вышло"), "Отказ называет истёкший срок: [spirit.whisper_failure]")
	spirit.open_whisper(corpse, ghost)
	qdel(heretic_craft_on(corpse, "spirit_obol"))
	TEST_ASSERT(!(whisper_verb in ghost.verbs), "Снятый обол закрывает шёпот.")
	TEST_ASSERT(!spirit.deliver_whisper(ghost, "После"), "Без обола шёпот не доходит.")

/datum/unit_test/proc/spirit_hold_heretic()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_hold)
	return heretic

/datum/unit_test/proc/seize_spirit_soul(datum/eldritch_knowledge/base_spirit/spirit, mob/living/user, mob/living/victim)
	spirit.separate(victim, spirit)
	spirit.seize_soul(user, victim)
	return victim.has_status_effect(/datum/status_effect/heretic_spirit_hold)

/// Удержать душу берёт свою отделённую душу рядом с еретиком; дальняя, без души, без свободной руки, под антимагией и в наручниках - отказ; через секунду тело пустеет на 12 секунд и готово к обряду, а душа лежит в руке.
/datum/unit_test/heretic_spirit_hold/Run()
	var/datum/antagonist/heretic/heretic = spirit_hold_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spell/spirit_hold/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_hold)
	var/obj/effect/proc_holder/spell/pointed/heretic_spirit/hold/spell = knowledge.granted_spell
	TEST_ASSERT(istype(spell), "Знание выдаёт Удержать душу.")
	TEST_ASSERT_EQUAL(spell.charge_max, HERETIC_SPIRIT_HOLD_COOLDOWN, "Перезарядка 40 секунд.")
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(findtext(spirit.hold_block_reason(user, victim), "отделённ"), "Без отделённой души захвата нет: [spirit.hold_block_reason(user, victim)]")
	var/datum/status_effect/heretic_spirit/separated/soul = spirit.separate(victim, spirit)
	user.forceMove(get_step(origin, WEST))
	TEST_ASSERT(findtext(spirit.hold_block_reason(user, soul.anchor), "рядом"), "Душу в двух клетках рукой не взять.")
	user.forceMove(origin)
	TEST_ASSERT_NULL(spirit.hold_block_reason(user, soul.anchor), "Соседняя своя душа годится.")
	victim.forceMove(get_step(get_step(origin, EAST), NORTH))
	TEST_ASSERT_NULL(spirit.hold_block_reason(user, victim), "Тело, чья душа рядом, тоже годится.")
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Способность принимает клик по телу.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(findtext(spirit.hold_block_reason(user, soul.anchor), "защищена от магии"), "Антимагия спасает цель.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проверка не тратит заряды антимагии.")
	qdel(protection)
	var/obj/item/pen/left = allocate(/obj/item/pen)
	var/obj/item/pen/right = allocate(/obj/item/pen)
	user.put_in_hands(left)
	user.put_in_hands(right)
	TEST_ASSERT(findtext(spirit.hold_block_reason(user, soul.anchor), "Освободите руку"), "Душу держат в свободной руке.")
	user.dropItemToGround(right)
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(findtext(spirit.hold_block_reason(user, soul.anchor), "наручниках"), "Скованный еретик не берёт душу.")
	user.uncuff()
	var/started = world.time
	TEST_ASSERT(spirit.grab_soul(user, soul.anchor), "Перевозчик тянется к душе.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_spirit_hold), "Секунду душа только тянется к руке.")
	var/list/budget = new_wait_budget(3 SECONDS, "удержание души")
	while(!victim.has_status_effect(/datum/status_effect/heretic_spirit_hold))
		if(!wait_budget_tick(budget))
			break
	var/datum/status_effect/heretic_spirit_hold/hold = victim.has_status_effect(/datum/status_effect/heretic_spirit_hold)
	TEST_ASSERT_NOTNULL(hold, "Душа в руке перевозчика.")
	TEST_ASSERT(world.time - started >= HERETIC_SPIRIT_HOLD_TELEGRAPH - world.tick_lag, "Захват ждёт секунду: [world.time - started] дс.")
	var/remaining = hold.duration - world.time
	TEST_ASSERT(remaining <= HERETIC_SPIRIT_HOLD_DURATION + 1 && remaining > HERETIC_SPIRIT_HOLD_DURATION - 2 SECONDS, "Удержание до 12 секунд: осталось [remaining] дс.")
	TEST_ASSERT(QDELETED(soul), "Отделённая душа ушла в руку.")
	TEST_ASSERT(istype(hold.soul_item) && (hold.soul_item in user.held_items), "Душа лежит в руке еретика.")
	TEST_ASSERT(victim.IsParalyzed(), "Пустое тело не двигается.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Пустое тело готово к обряду.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(origin, NORTH))
	TEST_ASSERT(findtext(jointext(victim.examine(crew), " "), "пуст"), "Окружающие видят пустое тело.")
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human, get_step(origin, NORTHEAST))
	var/datum/status_effect/heretic_spirit/separated/other_soul = spirit.separate(other, spirit)
	TEST_ASSERT(findtext(spirit.hold_block_reason(user, other_soul.anchor), "уже держите"), "Вторую душу не взять.")
	TEST_ASSERT(!spirit.become_incorporeal(user), "С чужой душой в руке бесплотным не стать.")
	TEST_ASSERT(findtext(spirit.incorporeal_failure_reason, "держите"), "Отказ называет душу в руке: [spirit.incorporeal_failure_reason]")
	qdel(other_soul)
	hold.held_since = world.time - HERETIC_SPIRIT_HOLD_DURATION
	hold.soul_item.attack_self(user)
	TEST_ASSERT(QDELETED(hold), "Отпущенная душа возвращается.")
	TEST_ASSERT(!victim.IsParalyzed(), "Тело снова двигается.")
	var/datum/status_effect/heretic_capture_immunity/immunity = capture_immunity(victim, "spirit_hold")
	TEST_ASSERT(immunity && abs(immunity.duration - world.time - HERETIC_CAPTURE_IMMUNITY) < 1, "После захвата минута невосприимчивости.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "sand"), "другого захвата"), "И 15 секунд к любому захвату.")
	var/datum/status_effect/heretic_spirit/separated/again = spirit.separate(victim, spirit)
	TEST_ASSERT(findtext(spirit.hold_block_reason(user, again.anchor), "приходит в себя"), "Повторное удержание ждёт минуту.")

/// Душа возвращается от удара 15+ по еретику, оглушения, выпущенной души, жезла по телу или еретику, смерти тела, начала обряда, конца срока и смерти еретика; после каждого - невосприимчивость.
/datum/unit_test/heretic_spirit_hold_breaks/Run()
	var/datum/antagonist/heretic/heretic = spirit_hold_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/turf/victim_spot = get_step(user, EAST)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	for(var/method in list("удар", "оглушение", "душу выпустили", "жезл по телу", "жезл по еретику", "смерть тела", "обряд", "срок", "еретик погиб"))
		var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, victim_spot)
		var/datum/status_effect/heretic_spirit_hold/hold = seize_spirit_soul(spirit, user, victim)
		TEST_ASSERT_NOTNULL(hold, "Душа взята ([method]).")
		var/obj/item/soul_item = hold.soul_item
		switch(method)
			if("удар")
				user.adjustBruteLoss(HERETIC_SPIRIT_HOLD_BREAK_DAMAGE - 1)
				TEST_ASSERT(!QDELETED(hold), "Удар слабее 15 не возвращает душу.")
				sleep(world.tick_lag)
				user.adjustBruteLoss(HERETIC_SPIRIT_HOLD_BREAK_DAMAGE - 1)
				TEST_ASSERT(!QDELETED(hold), "Слабые удары в разные тики не складываются.")
				sleep(world.tick_lag)
				user.adjustBruteLoss(HERETIC_SPIRIT_HOLD_BREAK_DAMAGE)
			if("оглушение")
				user.Knockdown(2 SECONDS)
				hold.tick()
			if("душу выпустили")
				user.dropItemToGround(soul_item)
			if("жезл по телу")
				rod.melee_attack_chain(crew, victim)
			if("жезл по еретику")
				rod.melee_attack_chain(crew, user)
			if("смерть тела")
				victim.death()
			if("обряд")
				SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING)
			if("срок")
				hold.duration = world.time
				hold.restraint.duration = world.time
				TEST_ASSERT(wait_for_qdeleted(hold, 1 SECONDS), "Срок удержания истёк.")
			if("еретик погиб")
				spirit.on_death(user)
		TEST_ASSERT(QDELETED(hold), "Душа вернулась: [method].")
		TEST_ASSERT(QDELETED(soul_item), "Душа исчезла из руки: [method].")
		if(victim.stat != DEAD)
			TEST_ASSERT(!victim.IsParalyzed(), "Тело снова двигается: [method].")
		TEST_ASSERT_NOTNULL(capture_immunity(victim, "spirit_hold"), "После захвата невосприимчивость: [method].")
		TEST_ASSERT_NULL(spirit.soul_hold, "Знание забыло душу: [method].")
		user.fully_heal()
		user.SetKnockdown(0)
		user.set_resting(FALSE, TRUE)
		spirit.combat_resource = 3
		qdel(victim)

/// Бесплотность 3 секунды: работает в чужом захвате и вырывает из него, пули и удары проходят сквозь еретика, он проходит сквозь людей и столы и бежит быстрее; удар и заклинание пропадают и возвращают плоть, клик по полу - нет; в наручниках отказ; перезарядка 60 секунд.
/datum/unit_test/heretic_spirit_incorporeal/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_bell)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spell/spirit_incorporeal/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	var/obj/effect/proc_holder/spell/self/heretic_spirit/incorporeal/spell = knowledge.granted_spell
	TEST_ASSERT(istype(spell), "Знание выдаёт Бесплотность.")
	TEST_ASSERT_EQUAL(spell.charge_max, HERETIC_SPIRIT_INCORPOREAL_COOLDOWN, "Перезарядка 60 секунд.")
	var/flags_before = user.pass_flags
	var/alpha_before = user.alpha
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human, locate(start.x, start.y + 1, start.z))
	grabber.start_pulling(user)
	grabber.setGrabState(GRAB_AGGRESSIVE)
	TEST_ASSERT(user.incapacitated(), "Агрессивный захват сковывает еретика.")
	TEST_ASSERT(spell.can_cast(user, FALSE, TRUE), "Бесплотность доступна в чужой хватке.")
	TEST_ASSERT(spirit.become_incorporeal(user), "Еретик становится бесплотным.")
	var/datum/status_effect/heretic_spirit_incorporeal/effect = user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	TEST_ASSERT(effect && abs(effect.duration - world.time - HERETIC_SPIRIT_INCORPOREAL_DURATION) < 1, "Бесплотность длится 3 секунды.")
	TEST_ASSERT_NULL(user.pulledby, "Бесплотного не удержать.")
	grabber.start_pulling(user)
	TEST_ASSERT_NULL(user.pulledby, "Бесплотного не схватить заново.")
	TEST_ASSERT(!spirit.become_incorporeal(user), "Бесплотность не накладывается дважды.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_spirit_incorporeal), "Бесплотный бежит быстрее.")
	TEST_ASSERT(user.alpha < alpha_before, "Бесплотный полупрозрачен.")
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, locate(start.x + 3, start.y, start.z))
	var/obj/item/projectile/bullet/bullet = blade_test_shot(shooter, user)
	bullet.damage = 20
	TEST_ASSERT_EQUAL(user.bullet_act(bullet, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Пуля проходит сквозь бесплотного.")
	var/obj/item/storage/toolbox/toolbox = allocate(/obj/item/storage/toolbox)
	shooter.forceMove(locate(start.x + 1, start.y, start.z))
	shooter.put_in_hands(toolbox)
	shooter.a_intent = INTENT_HARM
	toolbox.melee_attack_chain(shooter, user)
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Ни пуля, ни ящик не ранят бесплотного.")
	TEST_ASSERT(!QDELETED(effect), "Чужие удары бесплотность не рвут.")
	var/turf/crowded = locate(start.x + 1, start.y, start.z)
	TEST_ASSERT(user.Move(crowded, EAST), "Бесплотный проходит сквозь человека.")
	var/obj/structure/table/table = allocate(/obj/structure/table, locate(start.x + 2, start.y, start.z))
	TEST_ASSERT(user.Move(get_turf(table), EAST), "Бесплотный проходит сквозь стол.")
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife)
	user.put_in_hands(knife)
	user.a_intent = INTENT_HARM
	user.CommonClickOn(shooter, "left=1")
	TEST_ASSERT(QDELETED(effect), "Попытка удара возвращает плоть.")
	TEST_ASSERT_EQUAL(shooter.getBruteLoss(), 0, "Удар бесплотного пропадает.")
	TEST_ASSERT_EQUAL(user.pass_flags, flags_before, "Флаги прохода возвращены.")
	TEST_ASSERT(!HAS_TRAIT_FROM(user, TRAIT_PASSTABLE, "heretic_spirit_incorporeal"), "Проход над столами снят.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_spirit_incorporeal), "Ускорение снято.")
	TEST_ASSERT_EQUAL(user.alpha, alpha_before, "Прозрачность возвращена.")
	user.dropItemToGround(knife)
	user.a_intent = INTENT_HELP
	TEST_ASSERT(spirit.become_incorporeal(user), "Бесплотность снова доступна при прямом вызове.")
	effect = user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	user.CommonClickOn(get_step(user, NORTH), "left=1")
	TEST_ASSERT(!QDELETED(effect), "Клик по полу бесплотность не рвёт.")
	var/datum/eldritch_knowledge/spell/spirit_bell/bell_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_bell)
	var/obj/effect/proc_holder/spell/self/heretic_spirit/bell/bell = bell_knowledge.granted_spell
	spirit.combat_resource = 3
	bell.Trigger(user, FALSE)
	TEST_ASSERT(QDELETED(effect), "Попытка заклинания возвращает плоть.")
	TEST_ASSERT_EQUAL(spirit.combat_resource, 3, "Звон не состоялся: оболы целы.")
	TEST_ASSERT_EQUAL(shooter.getBruteLoss(), 0, "Звон никого не ударил.")
	TEST_ASSERT_EQUAL(bell.charge_counter, bell.charge_max, "Перезарядка звона не началась.")
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/grasp = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	TEST_ASSERT(grasp.ChargeHand(user), "Хватка в руке.")
	TEST_ASSERT(spirit.become_incorporeal(user), "Бесплотность с Хваткой в руке.")
	effect = user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	user.CommonClickOn(shooter, "left=1")
	TEST_ASSERT(QDELETED(effect), "Хватка по живому возвращает плоть.")
	TEST_ASSERT_EQUAL(shooter.getBruteLoss(), 0, "Хватка бесплотного пропадает.")
	TEST_ASSERT_NOTNULL(grasp.attached_hand, "Пропавшая Хватка не тратит заряд.")
	user.CommonClickOn(shooter, "left=1")
	TEST_ASSERT(shooter.getBruteLoss() > 0, "Во плоти та же Хватка попадает.")
	TEST_ASSERT(spirit.become_incorporeal(user), "Бесплотность снова доступна.")
	effect = user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	effect.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(effect, 1 SECONDS), "Бесплотность кончается по сроку.")
	grabber.forceMove(locate(user.x, user.y + 1, user.z))
	grabber.start_pulling(user)
	TEST_ASSERT_EQUAL(user.pulledby, grabber, "После срока еретика снова можно схватить.")
	grabber.stop_pulling()
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(!spirit.become_incorporeal(user), "В наручниках Бесплотность недоступна.")
	TEST_ASSERT(findtext(spirit.incorporeal_failure_reason, "наручниках"), "Отказ называет наручники: [spirit.incorporeal_failure_reason]")
	TEST_ASSERT(!spell.can_cast(user, FALSE, TRUE), "Кнопка в наручниках не срабатывает.")
	user.uncuff()
	var/flags_plain = user.pass_flags
	TEST_ASSERT(spirit.become_incorporeal(user), "Бесплотность перед вознесением.")
	effect = user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	var/datum/component/heretic_spirit_ferryman/ferryman = user.AddComponent(/datum/component/heretic_spirit_ferryman, spirit)
	effect.end("проверка")
	TEST_ASSERT(user.pass_flags & PASSMOB, "Конец Бесплотности не отнимает у перевозчика проход сквозь людей.")
	qdel(ferryman)
	TEST_ASSERT_EQUAL(user.pass_flags, flags_plain, "Без обоих источников флаги прохода прежние.")

/// Удержать душу на четвёртой ступени, Бесплотность на пятой, Метка Духа на шестой, Фонарь с Кошелём на восьмой; цены при знаниях.
/datum/unit_test/heretic_spirit_layout/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_SPIRIT]
	TEST_ASSERT_EQUAL(path.knowledge[4], /datum/eldritch_knowledge/spell/spirit_hold, "Удержать душу на четвёртой ступени.")
	TEST_ASSERT_EQUAL(path.knowledge[5], /datum/eldritch_knowledge/spell/spirit_incorporeal, "Бесплотность на пятой ступени.")
	TEST_ASSERT_EQUAL(path.knowledge[6], /datum/eldritch_knowledge/spirit_mark, "Метка Духа на шестой ступени.")
	TEST_ASSERT_EQUAL(path.knowledge[8], /datum/eldritch_knowledge/spirit_relic, "Фонарь на восьмой ступени.")
	var/datum/eldritch_knowledge/hold = allocate(/datum/eldritch_knowledge/spell/spirit_hold)
	var/datum/eldritch_knowledge/incorporeal = allocate(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	var/datum/eldritch_knowledge/mark = allocate(/datum/eldritch_knowledge/spirit_mark)
	TEST_ASSERT_EQUAL(hold.cost, 2, "Захват стоит 2.")
	TEST_ASSERT_EQUAL(incorporeal.cost, 2, "Уход стоит 2.")
	TEST_ASSERT_EQUAL(mark.cost, 2, "Метка стоит 2.")
	var/datum/eldritch_knowledge/spirit_relic/relic = allocate(/datum/eldritch_knowledge/spirit_relic)
	TEST_ASSERT_EQUAL(relic.cost, 1, "Фонарь стоит 1.")
	TEST_ASSERT_EQUAL(jointext(relic.passive_values, "/"), "6/7/8", "Кошель утонувших качается в Фонаре.")

/// Тексты Духа называют числа из правил.
/datum/unit_test/heretic_spirit_texts/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_SPIRIT]
	var/datum/eldritch_knowledge/base_spirit/base = allocate(/datum/eldritch_knowledge/base_spirit)
	for(var/fragment in list("[HERETIC_SPIRIT_OBOL_LIMIT] обол", "[HERETIC_SPIRIT_WHISPER_TIME / (1 MINUTES)] минут", "«Помощи»"))
		TEST_ASSERT(findtext(base.desc, fragment), "Описание базы называет «[fragment]».")
	var/datum/eldritch_knowledge/hold = allocate(/datum/eldritch_knowledge/spell/spirit_hold)
	var/obj/effect/proc_holder/spell/hold_spell = /obj/effect/proc_holder/spell/pointed/heretic_spirit/hold
	for(var/fragment in list("[HERETIC_SPIRIT_HOLD_DURATION / (1 SECONDS)] секунд", "[HERETIC_SPIRIT_HOLD_BREAK_DAMAGE]+", "[HERETIC_SPIRIT_HOLD_COOLDOWN / (1 SECONDS)] секунд", "[HERETIC_SPIRIT_HOLD_TELEGRAPH / (1 SECONDS)] секунд", "растолкать за [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунды", "за [HERETIC_POCKET_PULL_TIME / (1 SECONDS)] секунд"))
		TEST_ASSERT(findtext(hold.desc, fragment), "Описание Удержать душу называет «[fragment]».")
		TEST_ASSERT(findtext(initial(hold_spell.desc), fragment), "Кнопка Удержать душу называет «[fragment]».")
	var/datum/eldritch_knowledge/incorporeal = allocate(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	var/obj/effect/proc_holder/spell/incorporeal_spell = /obj/effect/proc_holder/spell/self/heretic_spirit/incorporeal
	for(var/fragment in list("[HERETIC_SPIRIT_INCORPOREAL_DURATION / (1 SECONDS)] секунд", "[HERETIC_SPIRIT_INCORPOREAL_COOLDOWN / (1 SECONDS)] секунд"))
		TEST_ASSERT(findtext(incorporeal.desc, fragment), "Описание Бесплотности называет «[fragment]».")
		TEST_ASSERT(findtext(initial(incorporeal_spell.desc), fragment), "Кнопка Бесплотности называет «[fragment]».")
	var/datum/eldritch_knowledge/mark = allocate(/datum/eldritch_knowledge/spirit_mark)
	for(var/fragment in list("[HERETIC_SPIRIT_BLADE_BONUS] ушиб", "[HERETIC_SPIRIT_BLADE_COOLDOWN / (1 SECONDS)] секунд"))
		TEST_ASSERT(findtext(mark.desc, fragment), "Описание Метки Духа называет «[fragment]».")
	TEST_ASSERT(findtext(path.capture_summary, "[HERETIC_SPIRIT_HOLD_DURATION / (1 SECONDS)] секунд"), "Модель пути называет срок захвата.")
	TEST_ASSERT(findtext(path.escape_summary, "[HERETIC_SPIRIT_INCORPOREAL_DURATION / (1 SECONDS)] секунд"), "Модель пути называет срок ухода.")
	var/datum/heretic_deed/spirit/deed = allocate(/datum/heretic_deed/spirit)
	TEST_ASSERT(findtext(deed.desc, "отдел"), "Дело называет отделы.")
	TEST_ASSERT(findtext(deed.hint, "[HERETIC_SPIRIT_WHISPER_TIME / (1 MINUTES)] минут"), "Подсказка дела называет срок шёпота.")

/// Хоткей Бесплотности срабатывает в агрессивном захвате и вырывает из него.
/datum/unit_test/heretic_spirit_incorporeal_hotkey/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.collect_combat_spells(list())
	var/slot = heretic.ability_hotkey_types.Find(/obj/effect/proc_holder/spell/self/heretic_spirit/incorporeal)
	TEST_ASSERT(slot, "У Бесплотности есть слот горячей клавиши.")
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	grabber.start_pulling(user)
	grabber.setGrabState(GRAB_AGGRESSIVE)
	TEST_ASSERT(user.activate_ability_hotkey(slot), "Хоткей Бесплотности обработан.")
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal), "В захвате хоткей делает еретика бесплотным.")
	TEST_ASSERT_NULL(user.pulledby, "Бесплотность разрывает захват.")

/// Дверь Духа: своя удержанная душа цели охоты в руке и живое сердце во второй переправляют пустое тело рядом в изнанку за секунду, душа остаётся в руке; без удержания, с чужой душой, с занятой второй рукой и вдали от тела - нет; одна «Помощь» душу не возвращает, 2 секунды растолкать - возвращают.
/datum/unit_test/heretic_spirit_pocket_door/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = spirit_hold_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/turf/origin = get_turf(user)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, origin)
	var/obj/item/storage/toolbox/toolbox = allocate(/obj/item/storage/toolbox, origin)
	TEST_ASSERT(user.put_in_hands(heart), "Сердце в руке.")
	TEST_ASSERT_NULL(spirit.pocket_door(user, victim), "Без удержанной души двери нет.")
	var/datum/status_effect/heretic_spirit_hold/hold = seize_spirit_soul(spirit, user, other)
	TEST_ASSERT_NOTNULL(hold, "В руке душа другого человека.")
	TEST_ASSERT_NULL(spirit.pocket_door(user, victim), "Чужая душа в руке цель не переправляет.")
	hold.release("проверка")
	user.dropItemToGround(heart)
	TEST_ASSERT(user.put_in_hands(toolbox), "Вторая рука занята ящиком.")
	hold = seize_spirit_soul(spirit, user, victim)
	TEST_ASSERT_NOTNULL(hold, "Душа цели охоты в руке.")
	TEST_ASSERT(findtext(spirit.ferry_hands_reason(user), "живое сердце"), "Отказ просит сердце во второй руке: [spirit.ferry_hands_reason(user)]")
	TEST_ASSERT_NULL(spirit.pocket_door(user, victim), "С занятой второй рукой двери нет.")
	user.dropItemToGround(toolbox)
	TEST_ASSERT_NULL(spirit.ferry_hands_reason(user), "Пустая вторая рука готова принять сердце.")
	TEST_ASSERT(user.put_in_hands(heart), "Сердце во второй руке.")
	var/list/door = spirit.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Душа в руке и сердце во второй переправляют тело.")
	TEST_ASSERT_EQUAL(door["name"], "за реку", "Дверь подписана.")
	TEST_ASSERT_EQUAL(door["time"], HERETIC_POCKET_PULL_TIME, "Переправа занимает [HERETIC_POCKET_PULL_TIME / (1 SECONDS)] с.")
	user.forceMove(get_step(origin, WEST))
	TEST_ASSERT_NULL(spirit.pocket_door(user, victim), "Вдали от тела двери нет.")
	user.forceMove(origin)
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Дверь Духа уводит тело в изнанку.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Тело в изнанке.")
	TEST_ASSERT(!QDELETED(hold) && (hold.soul_item in user.held_items), "Душа остаётся в руке и в изнанке.")
	heretic.pocket.collapse("проверка")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(victim, SOUTH))
	victim.help_shake_act(crew)
	TEST_ASSERT(!QDELETED(hold) && victim.IsParalyzed(), "Одна «Помощь» душу не возвращает.")
	TEST_ASSERT(LAZYFIND(crew.do_afters, victim), "«Помощь» начинает расталкивать пустое тело.")
	TEST_ASSERT(wait_for_qdeleted(hold, HERETIC_CAPTURE_SHAKE_TIME * 2), "Две секунды растолкать возвращают душу.")
	TEST_ASSERT(!victim.IsParalyzed(), "Растолканное тело снова двигается.")

/// Выходы Духа: свои тела с оболом на станции, на соседней с телом клетке, где разрешены телепорты; чужой и снятый обол - нет.
/datum/unit_test/heretic_spirit_pocket_exits/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_SPIRIT)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/turf/origin = get_turf(user)
	var/datum/antagonist/heretic/rival = allocate_deed_heretic(PATH_SPIRIT)
	var/datum/eldritch_knowledge/base_spirit/rival_spirit = rival.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/carbon/human/corpse = spirit_corpse(locate(origin.x + 3, origin.y + 2, origin.z))
	var/mob/living/carbon/human/foreign = spirit_corpse(locate(origin.x + 1, origin.y + 4, origin.z))
	var/turf/sealed = get_step(corpse, NORTH)
	heretic_test_area(sealed, /area/unit_test_moon_noteleport)
	TEST_ASSERT_EQUAL(length(spirit.pocket_exits(user)), 0, "Без оболов выходов нет.")
	TEST_ASSERT(spirit.place_obol(user, corpse), "Свой обол лёг: [spirit.grasp_failure_reason]")
	TEST_ASSERT(rival_spirit.place_obol(rival.owner.current, foreign), "Чужой обол лёг: [rival_spirit.grasp_failure_reason]")
	var/list/exits = spirit.pocket_exits(user)
	TEST_ASSERT_EQUAL(length(exits), 1, "Выход - только своё тело с оболом.")
	for(var/label in exits)
		var/turf/exit = exits[label]
		TEST_ASSERT(findtext(label, "Обол - "), "Выход подписан оболом и отделом: [label]")
		TEST_ASSERT_EQUAL(get_dist(exit, corpse), 1, "Выход на соседней с телом клетке: [label]")
		TEST_ASSERT(heretic_pocket_landable(exit), "Выход - свободный пол: [label]")
		TEST_ASSERT(exit != sealed && heretic_pocket_exit_allowed(exit), "Соседняя клетка без телепортов пропущена: [label]")
	var/listed = FALSE
	for(var/label in heretic.pocket_exits(user))
		if(findtext(label, "Обол - "))
			listed = TRUE
	TEST_ASSERT(listed, "Изнанка предлагает выход к оболу.")
	qdel(heretic_craft_on(corpse, "spirit_obol"))
	TEST_ASSERT_EQUAL(length(spirit.pocket_exits(user)), 0, "Снятый обол больше не выход.")

/// В агрессивном захвате Бесплотность называет настоящую причину отказа: для способности, доступной в захвате, хватка не причина.
/datum/unit_test/heretic_spirit_grabbed_refusal_reason/Run()
	var/datum/antagonist/heretic/heretic = spirit_hold_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_bell)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/datum/eldritch_knowledge/spell/spirit_incorporeal/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	var/obj/effect/proc_holder/spell/self/heretic_spirit/incorporeal/spell = knowledge.granted_spell
	var/datum/eldritch_knowledge/spell/spirit_bell/bell_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_bell)
	var/obj/effect/proc_holder/spell/self/heretic_spirit/bell/bell = bell_knowledge.granted_spell
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT_NOTNULL(seize_spirit_soul(spirit, user, victim), "Душа в руке.")
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	grabber.start_pulling(user)
	grabber.setGrabState(GRAB_AGGRESSIVE)
	TEST_ASSERT(user.incapacitated(), "Агрессивный захват сковывает еретика.")
	TEST_ASSERT(!spell.can_cast(user, FALSE, TRUE), "С душой в руке Бесплотность недоступна.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "душу"), "Отказ называет душу в руке, а не хватку: [spell.heretic_failure_reason]")
	TEST_ASSERT(!bell.can_cast(user, FALSE, TRUE), "Звон в захвате недоступен.")
	TEST_ASSERT(findtext(bell.heretic_failure_reason, "не можете действовать"), "Способность без работы в захвате называет хватку: [bell.heretic_failure_reason]")

/// Бесплотный удар предметом по двери, машине или соседней стене пропадает и возвращает плоть; пустая рука в «Вреде» открывает дверь, а дальний клик по стене и игрушка, уложенная в кровать, плоть не возвращают.
/datum/unit_test/heretic_spirit_incorporeal_objects/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	heretic.selected_path = PATH_SPIRIT
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_spirit)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, locate(start.x + 1, start.y, start.z))
	door.machine_stat &= ~NOPOWER
	var/obj/machinery/space_heater/heater = allocate(/obj/machinery/space_heater, locate(start.x, start.y + 1, start.z))
	var/obj/structure/bed/bed = allocate(/obj/structure/bed, locate(start.x, start.y - 1, start.z))
	var/turf/wall = locate(start.x - 2, start.y, start.z)
	TEST_ASSERT(isclosedturf(wall), "За полом резервации стоит стена.")
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife)
	user.put_in_hands(knife)
	user.a_intent = INTENT_HARM
	var/door_integrity = door.obj_integrity
	TEST_ASSERT(spirit.become_incorporeal(user), "Еретик бесплотен.")
	var/datum/status_effect/heretic_spirit_incorporeal/effect = user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	user.CommonClickOn(door, "left=1")
	TEST_ASSERT(QDELETED(effect), "Удар ножом по двери возвращает плоть.")
	TEST_ASSERT_EQUAL(door.obj_integrity, door_integrity, "Удар бесплотного по двери пропадает.")
	TEST_ASSERT(spirit.become_incorporeal(user), "Бесплотность перед дальним кликом по стене.")
	effect = user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	user.CommonClickOn(wall, "left=1")
	TEST_ASSERT(!QDELETED(effect), "Клик ножом по стене через клетку плоть не возвращает.")
	user.forceMove(locate(start.x - 1, start.y, start.z))
	user.CommonClickOn(wall, "left=1")
	TEST_ASSERT(QDELETED(effect), "Удар ножом по соседней стене возвращает плоть.")
	user.dropItemToGround(knife)
	user.forceMove(start)
	user.a_intent = INTENT_HELP
	var/obj/item/storage/toolbox/toolbox = allocate(/obj/item/storage/toolbox)
	user.put_in_hands(toolbox)
	var/heater_integrity = heater.obj_integrity
	TEST_ASSERT(spirit.become_incorporeal(user), "Бесплотность перед ударом по машине.")
	effect = user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	user.CommonClickOn(heater, "left=1")
	TEST_ASSERT(QDELETED(effect), "Удар ящиком по машине и в «Помощи» возвращает плоть.")
	TEST_ASSERT_EQUAL(heater.obj_integrity, heater_integrity, "Удар бесплотного по машине пропадает.")
	user.dropItemToGround(toolbox)
	var/obj/item/toy/plush/carpplushie/plush = allocate(/obj/item/toy/plush/carpplushie)
	user.put_in_hands(plush)
	TEST_ASSERT(spirit.become_incorporeal(user), "Бесплотность перед укладкой игрушки.")
	effect = user.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	user.CommonClickOn(bed, "left=1")
	TEST_ASSERT_EQUAL(plush.loc, bed.loc, "Игрушка уложена в кровать.")
	TEST_ASSERT(!QDELETED(effect), "Игрушка в кровати плоть не возвращает.")
	user.a_intent = INTENT_HARM
	user.CommonClickOn(door, "left=1")
	TEST_ASSERT(!QDELETED(effect), "Пустая рука в «Вреде» у двери плоть не возвращает.")
	var/list/budget = new_wait_budget(2 SECONDS, "бесплотный открывает дверь")
	while(door.density)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(!door.density, "Бесплотный открывает дверь рукой.")
	qdel(effect)

/// Удаление тела посреди удержания души и удаление бесплотного еретика проходят без рантайма и снимают оба состояния.
/datum/unit_test/heretic_spirit_hold_victim_deleted/Run()
	var/datum/antagonist/heretic/heretic = spirit_hold_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/status_effect/heretic_spirit_hold/hold = seize_spirit_soul(spirit, user, victim)
	TEST_ASSERT_NOTNULL(hold, "Душа в руке.")
	var/datum/status_effect/restraint = hold.restraint
	var/obj/item/soul_item = hold.soul_item
	TEST_ASSERT(victim.IsParalyzed(), "Пустое тело не двигается.")
	qdel(victim)
	TEST_ASSERT(QDELETED(hold) && QDELETED(restraint), "Удаление тела снимает удержание и паралич.")
	TEST_ASSERT(QDELETED(soul_item), "Душа исчезает из руки.")
	TEST_ASSERT_NULL(spirit.soul_hold, "Знание забывает удержание.")
	var/datum/antagonist/heretic/ghost = spirit_hold_heretic()
	ghost.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_incorporeal)
	var/mob/living/carbon/human/ghost_body = ghost.owner.current
	var/datum/eldritch_knowledge/base_spirit/ghost_spirit = ghost.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	TEST_ASSERT(ghost_spirit.become_incorporeal(ghost_body), "Второй еретик бесплотен.")
	var/datum/status_effect/heretic_spirit_incorporeal/effect = ghost_body.has_status_effect(/datum/status_effect/heretic_spirit_incorporeal)
	qdel(ghost_body)
	TEST_ASSERT(QDELETED(effect), "Удалённый бесплотный еретик не оставляет состояния.")

/// Паралич пустого тела, продлённый чужим Paralyze, переживает конец удержания души, а свой - уходит вместе с ним.
/datum/unit_test/heretic_spirit_hold_foreign_paralyze/Run()
	var/datum/antagonist/heretic/heretic = spirit_hold_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_spirit/spirit = heretic.get_knowledge(/datum/eldritch_knowledge/base_spirit)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/status_effect/heretic_spirit_hold/hold = seize_spirit_soul(spirit, user, victim)
	TEST_ASSERT_NOTNULL(hold, "Душа в руке.")
	var/datum/status_effect/restraint = hold.restraint
	victim.Paralyze(HERETIC_SPIRIT_HOLD_DURATION * 2)
	TEST_ASSERT(restraint.duration > hold.duration, "Чужой Paralyze продлил паралич удержания.")
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN)
	TEST_ASSERT(QDELETED(hold), "Растолканное тело возвращает душу.")
	TEST_ASSERT(!QDELETED(restraint) && victim.IsParalyzed(), "Продлённый чужим оглушением паралич остаётся.")
	qdel(restraint)
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		qdel(immunity)
	hold = seize_spirit_soul(spirit, user, victim)
	TEST_ASSERT_NOTNULL(hold, "Душа снова в руке.")
	restraint = hold.restraint
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN)
	TEST_ASSERT(QDELETED(hold) && QDELETED(restraint) && !victim.IsParalyzed(), "Непродлённый паралич уходит вместе с удержанием.")

/// Пустое тело в руке перевозчика немо: ни голосом, ни по рации не позвать; вернувшаяся душа снова говорит.
/datum/unit_test/heretic_spirit_hold_mutes/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/base_spirit/spirit = allocate(/datum/eldritch_knowledge/base_spirit)
	var/datum/status_effect/heretic_spirit_hold/hold = victim.apply_status_effect(/datum/status_effect/heretic_spirit_hold, user, spirit)
	TEST_ASSERT_NOTNULL(hold, "Душа в руке перевозчика.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_MUTE), "Пустое тело немо.")
	TEST_ASSERT(!victim.can_speak_vocal(), "Пустое тело не может говорить.")
	qdel(hold)
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_MUTE), "Вернувшаяся душа снова говорит.")