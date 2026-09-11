/// Короткая перезарядка позволяет повторно указать должника; настоящий таймер взыскивает только после решения владельца.
/datum/unit_test/heretic_blood_deliberate_collection/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/obj/effect/proc_holder/spell/pointed/heretic_blood/release/spell = blood.combat_power
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Должника можно выбрать через pointed spell.")
	TEST_ASSERT(spell.cast_check(FALSE, user), "Первая привязка проходит общую проверку заклинания.")
	spell.perform(list(victim), user = user)
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_NOTNULL(seal, "Заклинание создаёт длительную связь.")
	TEST_ASSERT(abs(seal.debt - 4) < 0.01, "Привязка вкладывает четыре оплаченных ушиба.")
	TEST_ASSERT(abs(user.getBruteLoss() - seal.debt) < 0.01, "Начальный долг равен настоящей плате.")
	TEST_ASSERT_NOTNULL(seal.link_beam, "Связь имеет видимую жилу между участниками.")
	victim.update_icon()
	var/list/overlays = list()
	SEND_SIGNAL(victim, COMSIG_ATOM_UPDATE_OVERLAYS, overlays)
	TEST_ASSERT(seal.seal_overlay in overlays, "Обновление внешности сохраняет знак связи.")
	sleep(3 SECONDS)
	TEST_ASSERT(!QDELETED(seal) && !seal.collecting, "Связь сама не начинает взыскание.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Ожидание не наносит урон должнику.")
	TEST_ASSERT(spell.cast_check(FALSE, user), "Перезарядка успевает закончиться до срока связи.")
	spell.perform(list(victim), user = user)
	TEST_ASSERT(seal.collecting, "Повторное применение осознанно начинает взыскание.")
	TEST_ASSERT(!seal.detonate(), "Прямой вызов не обходит секунду предупреждения.")
	TEST_ASSERT(wait_for_qdeleted(seal), "Настоящий таймер завершает взыскание.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 6) < 0.01, "Четыре долга взыскиваются шестью ушибами.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Взысканная связь больше не числится в долге.")
	TEST_ASSERT(blood.release(user, victim), "Перед смертельным взысканием создаётся новая связь.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	victim.setToxLoss(victim.getToxLoss() + victim.health - (HEALTH_THRESHOLD_DEAD + 3), forced = TRUE)
	TEST_ASSERT(abs(victim.health - (HEALTH_THRESHOLD_DEAD + 3)) < 0.1 && victim.stat != DEAD, "Должник жив и находится в трёх единицах здоровья от порога смерти.")
	TEST_ASSERT(blood.release(user, victim), "Можно взыскать долг живого критически раненого должника.")
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Смерть должника во время урона не обрывает завершение взыскания.")
	TEST_ASSERT_EQUAL(victim.stat, DEAD, "Взыскание действительно стало смертельным.")

/// Ранящий клинок вкладывает собственные ушибы, а метка продлевает существующую связь без бонусного урона.
/datum/unit_test/heretic_blood_blade_and_mark/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_mark)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_grasp)
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/obj/item/melee/sickly_blade/blood/blade = allocate(/obj/item/melee/sickly_blade/blood)
	blade.wound_bonus = CANT_WOUND
	blade.bare_wound_bonus = CANT_WOUND
	TEST_ASSERT(blood.release(user, victim), "Первая привязка создаёт долг.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.expires_at = world.time + 2 SECONDS
	var/previous_expiry = seal.expires_at
	var/datum/eldritch_knowledge/blood_mark/mark = heretic.get_knowledge(/datum/eldritch_knowledge/blood_mark)
	TEST_ASSERT(mark.on_mansus_grasp(victim, user, TRUE, null), "Хватка помечает должника.")
	var/debt_before = seal.debt
	blade.afterattack(victim, user, TRUE, null)
	TEST_ASSERT_EQUAL(seal.debt, debt_before, "Afterattack без ранения не создаёт долга.")
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	TEST_ASSERT(abs(seal.debt - 7) < 0.01, "Настоящий удар добавляет три оплаченных ушиба.")
	TEST_ASSERT(abs(user.getBruteLoss() - 7) < 0.01, "Каждая единица долга оплачена владельцем.")
	TEST_ASSERT_EQUAL(seal.expires_at, previous_expiry + 5 SECONDS, "Метка продлевает свою связь на пять секунд.")
	TEST_ASSERT(abs(victim.getBruteLoss() - blade.force) < 0.01, "Метка не добавляет универсального урона клинку.")
	blade.attack(victim, user)
	TEST_ASSERT(abs(seal.debt - 7) < 0.01, "Повторное попадание не обходит задержку платы.")
	var/datum/eldritch_knowledge/blood_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/blood_grasp)
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE, null), "Изученная хватка вкладывает плату в существующую связь.")
	TEST_ASSERT(abs(seal.debt - 11) < 0.01, "Хватка добавляет четыре ушиба, а не бесплатные заряды.")
	blood.gain_combat_resource(500)
	blood.on_mark_detonated(user, victim)
	TEST_ASSERT(abs(blood.combat_resource - 11) < 0.01, "Общие пополнения ресурса не создают необеспеченного долга.")
	TEST_ASSERT(!blood.spend_combat_resource(), "Долг нельзя расходовать как обычные заряды.")
	user.adjustBruteLoss(5)
	TEST_ASSERT(abs(blood.combat_resource - 11) < 0.01, "Внешний урон не увеличивает долг.")

/// Договор распределяет одну реальную плату между связями и не размножает её на каждую жертву.
/datum/unit_test/heretic_blood_shared_payment/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_vigor)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_pact)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/first = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/second = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	TEST_ASSERT(!blood.pact(user), "Без связей Договор не ранит владельца.")
	TEST_ASSERT(blood.release(user, first), "Первая связь укладывается в предел.")
	TEST_ASSERT(blood.release(user, second), "Пассивка разрешает вторую связь.")
	var/datum/status_effect/heretic_blood_seal/first_seal = first.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/status_effect/heretic_blood_seal/second_seal = second.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(blood.invest(user, list(first_seal), 12), "Первую связь можно подготовить у предела вместимости.")
	var/previous_debt = blood.combat_resource
	var/damage_before = user.getBruteLoss()
	TEST_ASSERT(blood.pact(user), "Договор распределяет плату по двум связям.")
	var/paid = user.getBruteLoss() - damage_before
	TEST_ASSERT(abs(paid - 10) < 0.01, "Договор ранит владельца на десять.")
	TEST_ASSERT(abs(blood.combat_resource - previous_debt - paid) < 0.01, "Сумма долгов растёт ровно на одну плату.")
	TEST_ASSERT(abs(first_seal.debt - 20) < 0.01, "Старшая связь заполняется до предела.")
	TEST_ASSERT(abs(second_seal.debt - 10) < 0.01, "Младшая получает только оставшиеся шесть единиц.")
	TEST_ASSERT(abs(first_seal.refundable_debt + second_seal.refundable_debt - blood.combat_resource) < 0.01, "Возвратные кредиты также не размножаются.")
	TEST_ASSERT_EQUAL(first.getBruteLoss() + second.getBruteLoss(), 0, "Вложения не атакуют ни одного должника.")

/// Антимагия, стены, дистанция и истечение срока уничтожают долг без автоматического удара.
/datum/unit_test/heretic_blood_counterplay/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/middle = get_step(user, EAST)
	var/turf/destination = get_step(middle, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	var/obj/effect/proc_holder/spell/pointed/heretic_blood/release/spell = blood.combat_power
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Выбор распознаёт антимагию.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Выбор не расходует защиту.")
	TEST_ASSERT(blood.release(user, victim), "Реальная попытка считается применением при блоке антимагией.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Реальный блок расходует один заряд.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Блок не принимает плату за несуществующую связь.")
	qdel(protection)
	TEST_ASSERT(blood.release(user, victim), "Незащищённая цель получает связь.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/obj/blocker = allocate(/obj, middle)
	blocker.density = TRUE
	seal.tick()
	TEST_ASSERT(QDELETED(seal), "Новая преграда рвёт действующую связь.")
	TEST_ASSERT(!blood.release(user, victim), "Через преграду нельзя создать новую связь.")
	qdel(blocker)
	TEST_ASSERT(blood.release(user, victim), "После открытия прохода доступна новая привязка.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(blood.release(user, victim), "Владелец начинает взыскание.")
	victim.forceMove(locate(user.x + 6, user.y, user.z))
	TEST_ASSERT(QDELETED(seal), "Выход за радиус сразу отменяет даже подготовленное взыскание.")
	victim.forceMove(destination)
	TEST_ASSERT(blood.release(user, victim), "Владелец создаёт третью связь.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	seal.tick()
	TEST_ASSERT(QDELETED(seal), "Полученная позже антимагия рвёт связь.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Разрыв расходует ровно один новый заряд.")
	qdel(protection)
	TEST_ASSERT(blood.release(user, victim), "Перед истечением существует ещё одна связь.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.expires_at = world.time
	seal.tick()
	TEST_ASSERT(QDELETED(seal), "Не востребованная связь истекает.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Все способы разорвать связь защищают от урона.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Разорванные долги не сохраняются в HUD.")

/// Натяжение работает только по своей связи и уважает закрепление и преграды.
/datum/unit_test/heretic_blood_link_manipulation/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_lance)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/destination = get_step(get_step(get_step(user, EAST), EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	TEST_ASSERT(!blood.lance(user, victim), "Натяжение не стало универсальным снарядом по несвязанным врагам.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Нет связи — нет платы.")
	TEST_ASSERT(blood.release(user, victim), "Должник связан перед натяжением.")
	victim.anchored = TRUE
	TEST_ASSERT(blood.lance(user, victim), "Закреплённому должнику можно увеличить долг.")
	TEST_ASSERT_EQUAL(get_turf(victim), destination, "Закрепление предотвращает перемещение.")
	victim.anchored = FALSE
	TEST_ASSERT(blood.lance(user, victim), "Свободного должника можно подтянуть.")
	TEST_ASSERT_EQUAL(get_dist(user, victim), 2, "Натяжение сдвигает ровно на клетку.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Натяжение не наносит прямого урона.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(abs(seal.debt - 16) < 0.01, "Два натяжения добавляют двенадцать реально оплаченных ушибов.")
	var/obj/blocker = allocate(/obj, get_step(user, EAST))
	blocker.density = TRUE
	var/previous_damage = user.getBruteLoss()
	TEST_ASSERT(!blood.lance(user, victim), "За стеной натяжение недоступно.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), previous_damage, "Отказ не ранит владельца.")

/// Чаша возвращает только собственную ещё не залеченную плату, сжигая соответствующий долг.
/datum/unit_test/heretic_blood_refund_ledger/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/blood_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Обряд создаёт личную чашу.")
	var/obj/item/heretic_path_relic/blood_relic/chalice = recipe.new_path_relic_ref.resolve()
	allocated += chalice
	user.adjustBruteLoss(10)
	TEST_ASSERT(blood.release(user, victim), "Связь получает четыре оплаченных ушиба поверх внешней раны.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(!chalice.drink(user, victim), "Чаша на полу недоступна.")
	user.put_in_hands(chalice)
	TEST_ASSERT(chalice.drink(user, victim), "Чаша возвращает оплаченную часть.")
	TEST_ASSERT(abs(user.getBruteLoss() - 10) < 0.01, "Внешняя рана остаётся; вернулись только четыре собственных ушиба.")
	TEST_ASSERT_EQUAL(seal.debt, 0, "Возвращённую плату нельзя ещё и взыскать.")
	TEST_ASSERT_EQUAL(seal.refundable_debt, 0, "Возвратный кредит израсходован.")
	TEST_ASSERT(!blood.release(user, victim), "Пустой долг не запускает взыскание.")
	TEST_ASSERT(blood.invest(user, list(seal), 6), "В пустую связь можно вложить новую плату.")
	user.adjustBruteLoss(-6, forced = TRUE, only_organic = FALSE)
	TEST_ASSERT_EQUAL(seal.refundable_debt, 0, "Внешнее лечение погашает возвратный кредит.")
	user.adjustBruteLoss(12)
	COOLDOWN_RESET(chalice, relic_cooldown)
	TEST_ASSERT(!chalice.drink(user, victim), "Новая чужая рана не восстанавливает уже залеченный кредит.")
	TEST_ASSERT(abs(seal.debt - 6) < 0.01, "Лечение не уничтожает право взыскания исторически оплаченного долга.")
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(user, NORTH))
	other.selected_path = PATH_BLOOD
	other.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	other.gain_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/datum/eldritch_knowledge/base_blood/other_blood = other.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/other_debtor = allocate(/mob/living/carbon/human, get_step(other.owner.current, NORTH))
	TEST_ASSERT(other_blood.release(other.owner.current, other_debtor), "Другой кровник подготовил собственный оплаченный долг.")
	user.dropItemToGround(chalice, TRUE)
	other.owner.current.put_in_hands(chalice)
	TEST_ASSERT(!chalice.drink(other.owner.current, other_debtor), "Другой кровник не использует чужую чашу даже со своим долгом и ранами.")

/// Учёт лечения сохраняет дробный кредит и убирает остаток меньше точности урона.
/datum/unit_test/heretic_blood_refund_roundoff/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	TEST_ASSERT(blood.release(user, victim), "Связь создаёт оплаченный долг.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/original_debt = seal.debt
	seal.refundable_debt = 4
	blood.last_brute_loss = user.getBruteLoss() + 3.5
	blood.sync_refundable_debt()
	TEST_ASSERT_EQUAL(seal.refundable_debt, 0.5, "Непогашенный дробный кредит сохраняется.")
	blood.last_brute_loss = user.getBruteLoss() + seal.refundable_debt - DAMAGE_PRECISION / 100
	blood.sync_refundable_debt()
	TEST_ASSERT_EQUAL(seal.refundable_debt, 0, "Погрешность подсчёта урона не оставляет возвратный кредит.")
	TEST_ASSERT_EQUAL(seal.debt, original_debt, "Погашение кредита не меняет долг для взыскания.")

/// Массовое взыскание выбирает связи, а усиление меняет только коэффициент их долга.
/datum/unit_test/heretic_blood_reckoning_and_upgrade/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_vigor)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_upgrade)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_reckoning)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/first = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/second = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/mob/living/bystander = allocate(/mob/living/carbon/human, get_step(first, NORTH))
	TEST_ASSERT(blood.release(user, first), "Первый должник связан.")
	TEST_ASSERT(blood.release(user, second), "Второй должник связан.")
	var/datum/status_effect/heretic_blood_seal/first_seal = first.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/status_effect/heretic_blood_seal/second_seal = second.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/paid = user.getBruteLoss()
	TEST_ASSERT(blood.reckoning(user), "Взыскание запускается по обеим связям.")
	TEST_ASSERT(first_seal.collecting && second_seal.collecting, "Каждый должник получает собственное предупреждение.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), paid, "Взыскание не создаёт новую плату.")
	first_seal.collection_ready_at = world.time
	second_seal.collection_ready_at = world.time
	TEST_ASSERT(first_seal.detonate(), "Первая связь взыскивается.")
	TEST_ASSERT(second_seal.detonate(), "Вторая связь взыскивается.")
	TEST_ASSERT(abs(first.getBruteLoss() - 7) < 0.01, "Усиление взыскивает четыре долга с коэффициентом1,75.")
	TEST_ASSERT(abs(second.getBruteLoss() - 7) < 0.01, "Каждый получает урон только своего долга.")
	TEST_ASSERT_EQUAL(bystander.getBruteLoss(), 0, "Стоящий между должниками посторонний не затронут.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Взыскание очищает общий долг.")

/// Вознесение переносит долги и возвратные кредиты между связями без копирования и сохраняет предел выбранной жертвы.
/datum/unit_test/heretic_blood_ascension_transfer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_vigor)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/blood_final)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/final_eldritch/blood_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/blood_final)
	var/mob/living/first = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/second = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	heretic.ascended = TRUE
	TEST_ASSERT(!blood.coronation(user, first), "Флаг роли не заменяет завершённое вознесение.")
	final_knowledge.finished = TRUE
	final_knowledge.on_body_gain(user)
	TEST_ASSERT_EQUAL(blood.link_limit, 3, "Вознесение разрешает три связи.")
	TEST_ASSERT_EQUAL(blood.debt_cap, 30, "Каждая вознесённая связь вмещает тридцать долга.")
	TEST_ASSERT(blood.release(user, first), "Первый должник связан.")
	TEST_ASSERT(blood.release(user, second), "Второй должник связан.")
	var/datum/status_effect/heretic_blood_seal/chosen = first.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/status_effect/heretic_blood_seal/donor = second.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(blood.invest(user, list(chosen), 24), "Выбранный долг подготовлен у предела.")
	TEST_ASSERT(blood.invest(user, list(donor), 6), "Вторая связь содержит отдельный долг.")
	var/original_debt = blood.combat_resource
	var/original_credit = chosen.refundable_debt + donor.refundable_debt
	TEST_ASSERT(blood.coronation(user, first), "Приговор переносит часть второго долга в выбранную связь.")
	TEST_ASSERT(abs(chosen.debt - 30) < 0.01, "Выбранный долг ограничен тридцатью.")
	TEST_ASSERT(abs(blood.combat_resource - original_debt) < 0.01, "Перенос сохраняет общую сумму долга.")
	TEST_ASSERT(abs(chosen.refundable_debt + donor.refundable_debt - original_credit) < 0.01, "Возвратный кредит не копируется.")
	TEST_ASSERT(donor.debt > 0, "Не вместившийся остаток сохраняется у прежнего должника.")
	TEST_ASSERT(chosen.collecting && !donor.collecting, "Взыскивается только выбранная связь.")
	var/obj/effect/proc_holder/spell/crown = final_knowledge.ascension_spell_instances[1]
	qdel(final_knowledge)
	TEST_ASSERT(QDELETED(chosen) && QDELETED(donor), "Отзыв финального знания отменяет его связи и подготовку.")
	TEST_ASSERT(QDELETED(crown), "Отзыв финального знания удаляет активку.")
	TEST_ASSERT(!blood.can_use_ascension(user), "Отозванное вознесение не оставляет полномочий.")
	TEST_ASSERT_EQUAL(blood.link_limit, 2, "После отзыва остаётся вместимость обычной пассивки.")

/// Пассивка меняет число связей и предел долга; её отзыв уничтожает лишние связи вместе с кредитами.
/datum/unit_test/heretic_blood_capacity/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_vigor)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/blood_vigor/vigor = heretic.get_knowledge(/datum/eldritch_knowledge/blood_vigor)
	TEST_ASSERT_EQUAL(blood.link_limit, 2, "Первая ступень даёт две связи.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Изучение не создаёт долг.")
	vigor.passive_level = 2
	vigor.on_passive_upgrade(user)
	TEST_ASSERT_EQUAL(blood.debt_cap, 25, "Второй уровень увеличивает предел долга.")
	vigor.passive_level = 3
	vigor.on_passive_upgrade(user)
	TEST_ASSERT_EQUAL(blood.link_limit, 3, "Третий уровень даёт третью связь при том же пределе.")
	var/mob/living/first = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/second = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	TEST_ASSERT(blood.release(user, first), "Создаётся первая связь.")
	TEST_ASSERT(blood.release(user, second), "Создаётся вторая связь.")
	var/datum/status_effect/heretic_blood_seal/removed = second.has_status_effect(/datum/status_effect/heretic_blood_seal)
	qdel(vigor)
	TEST_ASSERT_EQUAL(blood.link_limit, 1, "Отзыв пассивки возвращает одну связь.")
	TEST_ASSERT(QDELETED(removed), "Лишняя связь удаляется.")
	TEST_ASSERT_EQUAL(removed.debt + removed.refundable_debt, 0, "Удалённая связь не оставляет долга или возвратного кредита.")
	TEST_ASSERT(abs(blood.combat_resource - 4) < 0.01, "В HUD остаётся только долг первой связи.")

/// Смерть, перенос разума и удаление знания отменяют связи, лучи, предупреждения и платёжные кредиты.
/datum/unit_test/heretic_blood_lifecycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_reckoning)
	var/mob/living/user = heretic.owner.current
	heretic.apply_innate_effects(user)
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(blood.release(user, victim), "Перед смертью существует связь.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/beam/beam = seal.link_beam
	blood.on_death(user)
	TEST_ASSERT(QDELETED(seal) && QDELETED(beam), "Смерть удаляет связь и её видимую жилу.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Смерть уничтожает долг.")
	TEST_ASSERT(blood.release(user, victim), "После очистки создаётся новая связь.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(blood.reckoning(user), "Перед переносом начинается взыскание.")
	var/obj/effect/proc_holder/spell/old_power = blood.combat_power
	var/mob/living/new_body = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(QDELETED(seal), "Перенос не уносит долг в здоровое тело.")
	TEST_ASSERT(QDELETED(old_power), "Перенос отзывает старый экземпляр активки.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Новое тело начинает без долга.")
	TEST_ASSERT(!blood.can_use(user), "Старое тело не управляет связями.")
	TEST_ASSERT(blood.release(new_body, victim), "Новое тело может заключить своё обязательство.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(blood.reckoning(new_body), "Новое тело начинает своё взыскание.")
	qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spell/blood_reckoning))
	TEST_ASSERT(QDELETED(seal), "Удаление знания отменяет начатое им взыскание.")
	TEST_ASSERT(blood.release(new_body, victim), "Базовая связь остаётся доступной после отзыва массового взыскания.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	qdel(heretic)
	TEST_ASSERT(QDELETED(seal), "Удаление роли снимает последнюю связь.")
	TEST_ASSERT_EQUAL(length(blood.visuals), 0, "Удаление роли не оставляет визуальные эффекты.")

/// Бескровные виды платят реальным здоровьем; порог учитывает фактический maxHealth и усиление ран.
/datum/unit_test/heretic_blood_bloodless_payment/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_pact)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.set_species(/datum/species/skeleton)
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/original_blood = user.blood_volume
	TEST_ASSERT(blood.release(user, victim), "Скелет может оплатить связь.")
	TEST_ASSERT(blood.pact(user), "Скелет может вкладывать ушибы в долг.")
	TEST_ASSERT_EQUAL(user.blood_volume, original_blood, "Система не трогает blood_volume.")
	user.setToxLoss(user.getToxLoss() + user.health - 34, forced = TRUE)
	for(var/obj/item/bodypart/bodypart as anything in user.bodyparts)
		bodypart.wound_damage_multiplier = 2
	var/health_before = user.health
	TEST_ASSERT(abs(health_before - 34) < 0.1, "Предусловие учитывает настоящее здоровье вида.")
	TEST_ASSERT(blood.can_use(user), "Низкое здоровье само по себе ещё не лишает кредитора способности действовать.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_NOTNULL(seal, "Перед отказом существует действующая связь.")
	TEST_ASSERT(seal.debt < blood.debt_cap && seal.validate_link(), "Связь допускает новую плату по геометрии и вместимости.")
	var/debt_before = seal.debt
	TEST_ASSERT(!blood.pact(user), "Опасная плата усиленными ранами запрещена.")
	TEST_ASSERT_EQUAL(user.health, health_before, "Отклонённая плата сохраняет здоровье.")
	TEST_ASSERT_EQUAL(seal.debt, debt_before, "Отклонённая плата не увеличивает долг.")

/// Чужой кровник не перехватывает связь, а смерть или недееспособность участника освобождает её.
/datum/unit_test/heretic_blood_ownership/Run()
	var/datum/antagonist/heretic/first = allocate_heretic()
	var/datum/antagonist/heretic/second = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	first.selected_path = PATH_BLOOD
	second.selected_path = PATH_BLOOD
	first.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	second.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/base_blood/first_blood = first.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/base_blood/second_blood = second.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT(first_blood.release(first.owner.current, victim), "Первый кровник заключает обязательство.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(!second_blood.release(second.owner.current, victim), "Чужой кровник не перехватывает чужой долг.")
	TEST_ASSERT_EQUAL(second.owner.current.getBruteLoss(), 0, "Отказ не принимает чужую плату.")
	first.owner.current.stat = UNCONSCIOUS
	seal.tick()
	TEST_ASSERT(QDELETED(seal), "Недееспособность кредитора рвёт связь.")
	TEST_ASSERT(second_blood.release(second.owner.current, victim), "Освободившуюся жертву можно связать заново.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	victim.death()
	TEST_ASSERT(QDELETED(seal), "Смерть должника немедленно снимает его связь.")
	TEST_ASSERT_EQUAL(second_blood.combat_resource, 0, "Умерший должник не оставляет пригодного долга.")
