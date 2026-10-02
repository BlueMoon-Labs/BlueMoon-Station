/// Взыскание восполняет кровь при целых конечностях и делит предел между частичными взысканиями.
/datum/unit_test/heretic_blood_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_vigor)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/blood_vigor/vigor = heretic.get_knowledge(/datum/eldritch_knowledge/blood_vigor)
	vigor.passive_level = 2
	vigor.on_passive_upgrade(user)
	var/mob/living/victim = blood_minded_victim(get_step(user, EAST))
	user.blood_volume = BLOOD_VOLUME_NORMAL - 40
	user.integrating_blood = 0
	TEST_ASSERT(blood.release(user, victim), "Создана связь для восполнения крови.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	blood.add_debt(seal, 15)
	for(var/index in 1 to 3)
		TEST_ASSERT(blood.release(user, victim, partial = TRUE), "Начато частичное взыскание.")
		seal.collection_ready_at = world.time
		TEST_ASSERT(seal.detonate(), "Частичное взыскание завершено.")
		TEST_ASSERT(abs(user.blood_volume - (BLOOD_VOLUME_NORMAL - 40 + min(index * 5, 10))) <= DAMAGE_PRECISION, "Кровь восстанавливается на четверть урона, не более десяти за связь.")
	TEST_ASSERT_EQUAL(user.getBruteLoss() + user.getFireLoss(), 0, "Пассивка работает без ушибов и ожогов.")
	TEST_ASSERT_EQUAL(user.physiology.bleed_mod, 0.375, "Свёртывание и врождённая черта перемножаются; повторные взыскания не усиливают эффект.")
	var/obj/item/bodypart/arm = user.get_bodypart(BODY_ZONE_L_ARM)
	arm.generic_bleedstacks = 5
	var/blood_before = user.blood_volume
	user.bleed(4)
	TEST_ASSERT_EQUAL(user.blood_volume, blood_before - 1.5, "Оба эффекта уменьшают фактическую потерю крови.")
	TEST_ASSERT_EQUAL(arm.generic_bleedstacks, 5, "Пассивка не удаляет источник кровотечения.")
	TEST_ASSERT_NOTNULL(blood.blood_clot.linked_alert, "Ослабление кровотечения показано владельцу.")
	blood.blood_clot.duration = world.time - 1
	blood.blood_clot.process()
	TEST_ASSERT_NULL(blood.blood_clot, "Истёкшая пассивка удалена из знания.")
	TEST_ASSERT_EQUAL(user.physiology.bleed_mod, 0.75, "После истечения остаётся только врождённая черта.")
	user.bleed(4)
	TEST_ASSERT_EQUAL(user.blood_volume, blood_before - 4.5, "После истечения действует только врождённое снижение кровотечения.")

/// Восполнение учитывает фактический урон, норму тела и кровь, ожидающую усвоения.
/datum/unit_test/heretic_blood_recovery_limits/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/victim = blood_minded_victim(get_step(user, EAST))
	user.blood_ratio = 1.25
	var/normal_volume = BLOOD_VOLUME_NORMAL * user.blood_ratio
	user.blood_volume = normal_volume - 20
	user.integrating_blood = 0
	for(var/obj/item/bodypart/limb as anything in victim.bodyparts)
		limb.wound_damage_multiplier = 0.5
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Подготовлено взыскание с устойчивой цели.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Взыскание с устойчивой цели завершено.")
	var/actual_damage = victim.getBruteLoss()
	TEST_ASSERT(actual_damage > 0 && actual_damage < 20, "Защита действительно уменьшила полученный урон.")
	TEST_ASSERT(abs(user.blood_volume - (normal_volume - 20 + actual_damage * 0.25)) <= DAMAGE_PRECISION, "Восполнена четверть фактического урона после защиты.")
	user.blood_volume = normal_volume - 8
	user.integrating_blood = 7
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Подготовлено взыскание у нормы крови.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Взыскание у нормы крови завершено.")
	TEST_ASSERT_EQUAL(user.blood_volume + user.integrating_blood, normal_volume, "Суммарный объём не превышает норму тела.")
	TEST_ASSERT_EQUAL(user.integrating_blood, 7, "Ожидающая усвоения кровь сохранена.")
	user.blood_volume = normal_volume + 10
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Подготовлено взыскание при избытке крови.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Взыскание при избытке крови завершено.")
	TEST_ASSERT_EQUAL(user.blood_volume, normal_volume + 10, "Пассивка не добавляет и не отнимает избыточную кровь.")

/// Неуязвимость, отмена взыскания и бескровное тело не дают восполнения или свёртывания.
/datum/unit_test/heretic_blood_recovery_rejected/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = blood_minded_victim(get_step(user, EAST))
	user.blood_volume = BLOOD_VOLUME_NORMAL - 40
	user.integrating_blood = 0
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Подготовлено взыскание с неуязвимой цели.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	victim.status_flags |= GODMODE
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Неуязвимость завершает попытку взыскания.")
	TEST_ASSERT_EQUAL(user.blood_volume, BLOOD_VOLUME_NORMAL - 40, "Нулевой урон не создаёт кровь.")
	TEST_ASSERT_NULL(blood.blood_clot, "Нулевой урон не ослабляет кровотечение.")
	victim.status_flags &= ~GODMODE
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Подготовлено прерываемое взыскание.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	user.Stun(1 SECONDS)
	seal.collection_ready_at = world.time
	TEST_ASSERT(!seal.detonate(), "Оглушение срывает взыскание.")
	TEST_ASSERT(!QDELETED(seal) && seal.debt == 10 && !seal.collecting, "Прерванное взыскание сохраняет прежний долг.")
	TEST_ASSERT_EQUAL(user.blood_volume, BLOOD_VOLUME_NORMAL - 40, "Отмена не создаёт кровь.")
	TEST_ASSERT_NULL(blood.blood_clot, "Отмена не ослабляет кровотечение.")
	user.SetStun(0)
	user.set_species(/datum/species/skeleton)
	var/blood_before = user.blood_volume
	TEST_ASSERT(blood.release(user, victim), "Бескровное тело взыскивает сохранённый долг без повторной привязки.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Бескровное тело взыскивает долг.")
	TEST_ASSERT_EQUAL(user.blood_volume, blood_before, "У бескровного тела не появляется кровь.")
	TEST_ASSERT_NULL(blood.blood_clot, "Бескровное тело не получает свёртывание.")

/// Свёртывание обновляется без усиления и сохраняет чужие модификаторы при смене тела и утрате роли.
/datum/unit_test/heretic_blood_clot_lifecycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = blood_minded_victim(get_step(user, EAST))
	user.physiology.bleed_mod *= 0.25
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Подготовлено первое взыскание.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Первое взыскание завершено.")
	var/datum/status_effect/heretic_blood_clot/clot = blood.blood_clot
	TEST_ASSERT_NOTNULL(clot, "Взыскание даёт свёртывание и при полном объёме крови.")
	TEST_ASSERT_EQUAL(user.physiology.bleed_mod, 0.09375, "Свёртывание учитывает прежний модификатор и врождённую черту.")
	clot.duration = world.time + 1 SECONDS
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Подготовлено повторное взыскание.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Повторное взыскание завершено.")
	TEST_ASSERT_EQUAL(blood.blood_clot, clot, "Повторное взыскание обновляет существующий эффект.")
	TEST_ASSERT_EQUAL(clot.duration, world.time + 8 SECONDS, "Длительность обновлена до восьми секунд.")
	TEST_ASSERT_EQUAL(user.physiology.bleed_mod, 0.09375, "Повторное взыскание не усиливает снижение.")
	user.physiology.bleed_mod *= 0.1
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, get_turf(user))
	user.mind.transfer_to(new_body)
	TEST_ASSERT(QDELETED(clot), "Смена тела снимает свёртывание со старого.")
	TEST_ASSERT(abs(user.physiology.bleed_mod - 0.025) <= DAMAGE_PRECISION, "Снятие сохраняет модификатор, добавленный во время действия.")
	TEST_ASSERT_EQUAL(new_body.physiology.bleed_mod, 0.75, "Новое тело получает врождённую черту без временного свёртывания.")
	TEST_ASSERT(blood.release(new_body, victim) && blood.release(new_body, victim), "Новое тело начинает своё взыскание.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Новое тело завершает своё взыскание.")
	clot = blood.blood_clot
	TEST_ASSERT_NOTNULL(clot, "Новое тело получило свёртывание.")
	qdel(heretic)
	TEST_ASSERT(QDELETED(clot), "Удаление роли снимает свёртывание.")
	TEST_ASSERT_EQUAL(new_body.physiology.bleed_mod, 1, "После удаления роли восстановлен исходный модификатор.")

/// Частичное взыскание сохраняет остаток и срок связи, предупреждение и общий предел лечения.
/datum/unit_test/heretic_blood_partial_collection/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_vigor)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/blood_vigor/vigor = heretic.get_knowledge(/datum/eldritch_knowledge/blood_vigor)
	vigor.passive_level = 2
	vigor.on_passive_upgrade(user)
	var/mob/living/victim = blood_minded_victim(get_step(user, EAST))
	user.adjustBruteLoss(30)
	TEST_ASSERT(blood.release(user, victim), "Создана исходная связь.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	blood.add_debt(seal, 15)
	var/expiry = seal.expires_at
	var/obj/effect/proc_holder/spell/pointed/heretic_blood/release/spell = blood.combat_power
	user.a_intent = INTENT_DISARM
	for(var/index in 1 to 2)
		spell.cast(list(victim), user)
		TEST_ASSERT(seal.collecting && seal.collection_amount == 10, "Разоружение выбирает только десять долга.")
		TEST_ASSERT(!seal.detonate(), "Частичное взыскание не обходит предупреждение.")
		seal.collection_ready_at = world.time
		TEST_ASSERT(seal.detonate(), "Частичное взыскание завершается.")
		TEST_ASSERT(!QDELETED(seal) && !seal.collecting, "Оставшаяся связь снова доступна.")
		TEST_ASSERT_EQUAL(seal.debt, 25 - index * 10, "Взыскание сохраняет точный остаток долга.")
		TEST_ASSERT_EQUAL(seal.expires_at, expiry, "Частичное взыскание не обновляет срок.")
		TEST_ASSERT_EQUAL(seal.seal_overlay.icon_state, "blood_mark", "Предупреждение уступает место обычной метке.")
		TEST_ASSERT(!seal.detonate(), "Завершённый таймер не взыскивает остаток повторно.")
	TEST_ASSERT(abs(user.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Две части исчерпали общий предел десять лечения.")
	seal.expires_at = world.time + 0.5 SECONDS
	var/short_expiry = seal.expires_at
	spell.charge_counter = 0
	spell.cast(list(victim), user)
	TEST_ASSERT(!seal.collecting, "Частичное взыскание не начинается без полной секунды до истечения.")
	TEST_ASSERT_EQUAL(seal.expires_at, short_expiry, "Отказ не продлевает почти истёкшую связь.")
	TEST_ASSERT_EQUAL(seal.debt, 5, "Отказ сохраняет остаток долга.")
	TEST_ASSERT_NULL(seal.collection_amount, "Отказ не фиксирует сумму взыскания.")
	TEST_ASSERT_NULL(seal.collection_ready_at, "Отказ не назначает время взыскания.")
	TEST_ASSERT_NULL(seal.collection_timer, "Отказ не создаёт отложенный таймер.")
	TEST_ASSERT_NULL(seal.collection_knowledge_ref, "Отказ не сохраняет знание взыскания.")
	TEST_ASSERT_EQUAL(seal.seal_overlay.icon_state, "blood_mark", "Отказ не показывает предупреждение о взыскании.")
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Отклонённое взыскание возвращает перезарядку.")
	seal.expires_at = world.time + 1 SECONDS
	TEST_ASSERT(!blood.release(user, victim, partial = TRUE), "Взыскание точно в момент истечения тоже отклоняется.")
	short_expiry = seal.expires_at
	user.a_intent = INTENT_HELP
	spell.cast(list(victim), user)
	TEST_ASSERT(seal.collecting && seal.expires_at > short_expiry, "Полное взыскание сохраняет продление до конца предупреждения.")
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate() && seal.spent, "Обычное взыскание закрывает остаток связи: остаётся пустая печать.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 50) <= DAMAGE_PRECISION, "Двадцать пять долга дали ровно пятьдесят ушибов.")
	TEST_ASSERT(abs(user.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Последняя часть не обходит общий предел лечения.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Взысканный долг полностью удалён из учёта.")

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
	var/mob/living/other_victim = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	TEST_ASSERT(!spell.can_target(other_victim, user, TRUE), "Занятый лимит отклоняет новую цель ещё при выборе.")
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Занятый лимит не мешает выбрать своего должника для взыскания.")
	TEST_ASSERT_EQUAL(seal.debt, 10, "Привязка создаёт десять долга.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Начальная связь не ранит владельца.")
	TEST_ASSERT_NOTNULL(seal.link_beam, "Связь имеет видимую жилу между участниками.")
	victim.update_icon()
	var/list/overlays = list()
	SEND_SIGNAL(victim, COMSIG_ATOM_UPDATE_OVERLAYS, overlays)
	TEST_ASSERT(seal.seal_overlay in overlays, "Обновление внешности сохраняет знак связи.")
	TEST_ASSERT(wait_for_var(spell, "charge_counter", spell.charge_max, 10 SECONDS), "Перезарядка завершается обработкой заклинаний.")
	TEST_ASSERT(!QDELETED(seal) && !seal.collecting, "Связь сама не начинает взыскание.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Ожидание не наносит урон должнику.")
	TEST_ASSERT(spell.cast_check(FALSE, user), "Перезарядка успевает закончиться до срока связи.")
	spell.perform(list(victim), user = user)
	TEST_ASSERT(seal.collecting, "Повторное применение осознанно начинает взыскание.")
	TEST_ASSERT(!spell.can_target(victim, user, FALSE), "Уже взыскиваемый долг нельзя выбрать повторно; подсказка отказа безопасна.")
	TEST_ASSERT(!seal.detonate(), "Прямой вызов не обходит секунду предупреждения.")
	TEST_ASSERT(wait_for_var(seal, "spent", TRUE, 5 SECONDS), "Настоящий таймер завершает взыскание.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) < 0.01, "Начальный долг взыскивается двадцатью ушибами.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Взысканная связь больше не числится в долге.")
	TEST_ASSERT(blood.release(user, victim), "Перед смертельным взысканием пустая печать снова становится связью.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	victim.setToxLoss(victim.getToxLoss() + victim.health - (HEALTH_THRESHOLD_DEAD + 3), forced = TRUE)
	TEST_ASSERT(abs(victim.health - (HEALTH_THRESHOLD_DEAD + 3)) < 0.1 && victim.stat != DEAD, "Должник жив и находится в трёх единицах здоровья от порога смерти.")
	TEST_ASSERT(blood.release(user, victim), "Можно взыскать долг живого критически раненого должника.")
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Смерть должника во время урона не обрывает завершение взыскания.")
	TEST_ASSERT_EQUAL(victim.stat, DEAD, "Взыскание действительно стало смертельным.")

/// Клинок и метка накапливают долг без саморанения, а промах не даёт ресурса.
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
	var/datum/eldritch_knowledge/blood_mark/mark = heretic.get_knowledge(/datum/eldritch_knowledge/blood_mark)
	TEST_ASSERT(mark.on_mansus_grasp(victim, user, TRUE, null), "Хватка помечает должника.")
	var/debt_before = seal.debt
	blade.afterattack(victim, user, TRUE, null)
	TEST_ASSERT_EQUAL(seal.debt, debt_before, "Afterattack без ранения не создаёт долга.")
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(seal.debt, 20, "Клинок и метка заполняют долг до предела.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Попадание и метка не ранят владельца.")
	TEST_ASSERT_EQUAL(seal.expires_at, world.time + 15 SECONDS, "Попадание обновляет короткую связь после срабатывания метки.")
	TEST_ASSERT(abs(victim.getBruteLoss() - blade.force) < 0.01, "Метка не добавляет универсального урона клинку.")
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(seal.debt, 20, "Повторное попадание не обходит предел долга.")
	seal.debt = 10
	var/datum/eldritch_knowledge/blood_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/blood_grasp)
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE, null), "Изученная хватка усиливает существующую связь.")
	TEST_ASSERT_EQUAL(seal.debt, 16, "Хватка добавляет шесть долга.")
	blood.gain_combat_resource(500)
	blood.on_mark_detonated(user, victim)
	TEST_ASSERT_EQUAL(blood.combat_resource, 16, "Общие пополнения ресурса не создают долг.")
	TEST_ASSERT(!blood.spend_combat_resource(), "Долг нельзя расходовать как обычные заряды.")
	user.adjustBruteLoss(5)
	TEST_ASSERT_EQUAL(blood.combat_resource, 16, "Внешний урон не увеличивает долг.")

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
	TEST_ASSERT(!QDELETED(seal), "Новая преграда оставляет две секунды для восстановления контакта.")
	TEST_ASSERT(!blood.release(user, victim), "Через преграду нельзя создать новую связь.")
	seal.contact_lost_at = world.time - 2 SECONDS
	seal.tick()
	TEST_ASSERT(QDELETED(seal), "Две секунды за преградой уничтожают долг.")
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

/// Натяжение атакует без подготовки, создаёт долг и уважает закрепление и преграды.
/datum/unit_test/heretic_blood_link_manipulation/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_lance)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/destination = get_step(get_step(get_step(get_step(user, EAST), EAST), EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	victim.anchored = TRUE
	TEST_ASSERT(blood.lance(user, victim), "Натяжение поражает несвязанного врага.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Натяжение не требует саморанения.")
	TEST_ASSERT_EQUAL(get_turf(victim), destination, "Закрепление предотвращает перемещение.")
	victim.anchored = FALSE
	TEST_ASSERT(blood.lance(user, victim), "Свободного должника можно подтянуть.")
	TEST_ASSERT_EQUAL(get_dist(user, victim), 1, "Натяжение притягивает на три клетки.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 36) < 0.01, "Два натяжения нанесли по восемнадцать ушибов.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_EQUAL(seal.debt, 20, "Повторное натяжение заполняет долг до предела.")
	victim.forceMove(destination)
	var/obj/blocker = allocate(/obj, get_step(user, EAST))
	blocker.density = TRUE
	var/previous_damage = user.getBruteLoss()
	TEST_ASSERT(!blood.lance(user, victim), "За стеной натяжение недоступно.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), previous_damage, "Отказ не ранит владельца.")

/// Чаша расходует боевой долг на реальный урон и лечение, сохраняя принадлежность владельцу.
/datum/unit_test/heretic_blood_refund_ledger/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/blood_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/mob/living/victim = blood_minded_victim(get_step(user, EAST))
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Обряд создаёт личную чашу.")
	var/obj/item/heretic_path_relic/blood_relic/chalice = recipe.new_path_relic_ref.resolve()
	allocated += chalice
	TEST_ASSERT(blood.release(user, victim), "Бесплатная связь даёт боевой долг.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	user.adjustBruteLoss(30)
	TEST_ASSERT(!chalice.drink(user, victim), "Чаша на полу недоступна.")
	user.put_in_hands(chalice)
	TEST_ASSERT(chalice.drink(user, victim), "Чаша лечит владельца за счёт врага.")
	TEST_ASSERT(abs(user.getBruteLoss() - 10) <= DAMAGE_PRECISION, "Чаша лечит двадцать ушибов.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Лечение сопровождается настоящим уроном врагу.")
	TEST_ASSERT(seal.spent && !(seal in blood.seals), "Полный глоток расходует десять долга и освобождает связь.")
	TEST_ASSERT(!chalice.drink(user, victim), "Повторное питьё ограничено перезарядкой.")
	COOLDOWN_RESET(chalice, relic_cooldown)
	TEST_ASSERT(blood.release(user, victim), "Перед следующим глотком пустая печать снова становится связью.")
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/heretic_blood_seal), seal, "Связь с той же целью - прежняя печать.")
	seal.debt = 5
	blood.update_debt()
	TEST_ASSERT(chalice.drink(user, victim), "Остаток долга можно потратить после перезарядки.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Остаток долга залечивает последние ушибы.")
	TEST_ASSERT_EQUAL(seal.debt, 0, "Долг нельзя потратить дважды.")
	TEST_ASSERT(seal.spent, "Исчерпанная чашей связь становится пустой печатью.")
	TEST_ASSERT_EQUAL(length(blood.seals), 0, "Пустая связь не занимает лимит.")
	TEST_ASSERT(blood.release(user, victim), "Цель можно связать снова без пустого взыскания.")
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/heretic_blood_seal), seal, "Первый выбор после чаши продлевает прежнюю печать.")
	TEST_ASSERT(!seal.spent && !seal.collecting, "Продлённая связь не начинает взыскание сама.")
	COOLDOWN_RESET(chalice, relic_cooldown)
	TEST_ASSERT(!chalice.drink(user, victim), "Здоровый владелец не расходует долг на питьё.")
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(user, NORTH))
	other.selected_path = PATH_BLOOD
	other.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	other.gain_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/datum/eldritch_knowledge/base_blood/other_blood = other.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/other_debtor = allocate(/mob/living/carbon/human, get_step(other.owner.current, NORTH))
	TEST_ASSERT(other_blood.release(other.owner.current, other_debtor), "Другой кровник подготовил собственный долг.")
	other.owner.current.adjustBruteLoss(10)
	user.dropItemToGround(chalice, TRUE)
	other.owner.current.put_in_hands(chalice)
	TEST_ASSERT(!chalice.drink(other.owner.current, other_debtor), "Чужая чаша недоступна даже с собственным долгом и ранами.")
/// Неуязвимая цель не даёт лечения, а антимагия разрывает связь до питья.
/datum/unit_test/heretic_blood_refund_roundoff/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = blood_minded_victim(get_step(user, EAST))
	TEST_ASSERT(blood.release(user, victim), "Создаётся связь с боевым долгом.")
	user.adjustBruteLoss(2)
	var/initial_wounds = user.getBruteLoss()
	victim.status_flags |= GODMODE
	TEST_ASSERT(blood.refund(user, victim), "Попытка питья расходует часть долга.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Неуязвимость предотвращает урон.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), initial_wounds, "Без реального урона лечение невозможно.")
	victim.status_flags &= ~GODMODE
	TEST_ASSERT(blood.refund(user, victim), "Уязвимая цель даёт лечение.")
	TEST_ASSERT(user.getBruteLoss() < DAMAGE_PRECISION, "Питьё залечивает небольшую рану.")
	TEST_ASSERT(abs(victim.getBruteLoss() - initial_wounds) < DAMAGE_PRECISION, "Небольшая рана требует столько же урона цели.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	user.adjustBruteLoss(2)
	var/user_damage_before = user.getBruteLoss()
	var/victim_damage_before = victim.getBruteLoss()
	TEST_ASSERT(!blood.refund(user, victim), "Антимагия прекращает питьё.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Разрыв связи расходует ровно один заряд антимагии.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), user_damage_before, "Антимагия не допускает лечения.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), victim_damage_before, "Антимагия не допускает нового урона.")
/// Массовое взыскание бьёт каждую связь по 2 ушиба за долг и на 4 секунды обескровливает взысканных: замедление и размытие; посторонний не затронут.
/datum/unit_test/heretic_blood_reckoning/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_vigor)
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
	TEST_ASSERT_NULL(first.has_status_effect(/datum/status_effect/heretic_blood_exsanguinated), "До удара никто не обескровлен.")
	first_seal.collection_ready_at = world.time
	second_seal.collection_ready_at = world.time
	TEST_ASSERT(first_seal.detonate(), "Первая связь взыскивается.")
	TEST_ASSERT(second_seal.detonate(), "Вторая связь взыскивается.")
	TEST_ASSERT(abs(first.getBruteLoss() - 32) <= DAMAGE_PRECISION, "Взыскание добавляет шесть долга перед уроном по 2 ушиба за единицу.")
	TEST_ASSERT(abs(second.getBruteLoss() - 32) <= DAMAGE_PRECISION, "Каждый получает урон только своего долга.")
	TEST_ASSERT_EQUAL(bystander.getBruteLoss(), 0, "Стоящий между должниками посторонний не затронут.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Взыскание очищает общий долг.")
	for(var/mob/living/debtor as anything in list(first, second))
		var/datum/status_effect/heretic_blood_exsanguinated/pale = debtor.has_status_effect(/datum/status_effect/heretic_blood_exsanguinated)
		TEST_ASSERT_NOTNULL(pale, "Взысканный обескровлен.")
		TEST_ASSERT(abs(pale.duration - world.time - HERETIC_BLOOD_EXSANGUINE_DURATION) < 1, "Обескровливание длится 4 секунды.")
		TEST_ASSERT(debtor.has_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_exsanguinated), "Обескровленный замедлен.")
		TEST_ASSERT(debtor.eye_blurry > 0, "Обескровленный видит размыто.")
	TEST_ASSERT_NULL(bystander.has_status_effect(/datum/status_effect/heretic_blood_exsanguinated), "Посторонний не обескровлен.")
	var/datum/status_effect/heretic_blood_exsanguinated/faded = first.has_status_effect(/datum/status_effect/heretic_blood_exsanguinated)
	faded.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(faded, 1 SECONDS), "Обескровливание заканчивается по сроку.")
	TEST_ASSERT(!first.has_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_exsanguinated), "Замедление снимается.")
	TEST_ASSERT(blood.release(user, bystander), "Новый должник связан.")
	TEST_ASSERT(blood.release(user, bystander), "Обычное взыскание начато.")
	var/datum/status_effect/heretic_blood_seal/plain = bystander.has_status_effect(/datum/status_effect/heretic_blood_seal)
	plain.collection_ready_at = world.time
	TEST_ASSERT(plain.detonate(), "Обычное взыскание завершено.")
	TEST_ASSERT_NULL(bystander.has_status_effect(/datum/status_effect/heretic_blood_exsanguinated), "Обычное взыскание не обескровливает.")

/// Вознесение переносит долг без копирования и сохраняет предел выбранной жертвы.
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
	TEST_ASSERT(blood.add_debt(chosen, 18), "Выбранный долг подготовлен у предела.")
	TEST_ASSERT(blood.add_debt(donor, 6), "Вторая связь содержит отдельный долг.")
	var/original_debt = blood.combat_resource
	TEST_ASSERT(blood.coronation(user, first), "Приговор переносит часть второго долга в выбранную связь.")
	TEST_ASSERT(abs(chosen.debt - 30) < 0.01, "Выбранный долг ограничен тридцатью.")
	TEST_ASSERT(abs(blood.combat_resource - original_debt) < 0.01, "Перенос сохраняет общую сумму долга.")
	TEST_ASSERT(donor.debt > 0, "Не вместившийся остаток сохраняется у прежнего должника.")
	TEST_ASSERT(chosen.collecting && !donor.collecting, "Взыскивается только выбранная связь.")
	var/obj/effect/proc_holder/spell/crown = final_knowledge.ascension_spell_instances[1]
	qdel(final_knowledge)
	TEST_ASSERT(QDELETED(chosen) && QDELETED(donor), "Отзыв финального знания отменяет его связи и подготовку.")
	TEST_ASSERT(QDELETED(crown), "Отзыв финального знания удаляет активку.")
	TEST_ASSERT(!blood.can_use_ascension(user), "Отозванное вознесение не оставляет полномочий.")
	TEST_ASSERT_EQUAL(blood.link_limit, 2, "После отзыва остаётся вместимость обычной пассивки.")

/// Отзыв пассивки уничтожает лишние связи вместе с их долгами.
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
	TEST_ASSERT_EQUAL(removed.debt, 0, "Удалённая связь не оставляет долга.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 10, "В HUD остаётся только долг первой связи.")

/// Смерть, перенос разума и удаление знания отменяют связи, лучи и предупреждения.
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

/// Бескровные виды платят за Скользкую кровь реальным здоровьем; порог учитывает фактический maxHealth и усиление ран.
/datum/unit_test/heretic_blood_bloodless_payment/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_slip)
	var/mob/living/carbon/human/user = heretic.owner.current
	user.set_species(/datum/species/skeleton)
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/original_blood = user.blood_volume
	TEST_ASSERT(blood.release(user, victim), "Скелет может оплатить связь.")
	var/brute_before = user.getBruteLoss()
	TEST_ASSERT(blood.slip(user), "Скелет может оплатить Скользкую кровь.")
	TEST_ASSERT(abs(user.getBruteLoss() - brute_before - HERETIC_BLOOD_SLIP_PAYMENT) <= DAMAGE_PRECISION, "Скелет платит десятью ушибами.")
	TEST_ASSERT_EQUAL(user.blood_volume, original_blood, "Система не трогает blood_volume.")
	user.setToxLoss(user.getToxLoss() + user.health - 34, forced = TRUE)
	for(var/obj/item/bodypart/bodypart as anything in user.bodyparts)
		bodypart.wound_damage_multiplier = 2
	var/health_before = user.health
	TEST_ASSERT(abs(health_before - 34) < 0.1, "Предусловие учитывает настоящее здоровье вида.")
	TEST_ASSERT(blood.can_use(user), "Низкое здоровье само по себе ещё не лишает кредитора способности действовать.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_NOTNULL(seal, "Перед отказом существует действующая связь.")
	seal.debt = 14
	TEST_ASSERT(seal.debt < blood.debt_cap && seal.validate_link(), "Связь допускает новую плату по геометрии и вместимости.")
	var/debt_before = seal.debt
	TEST_ASSERT(!blood.slip(user), "Опасная плата усиленными ранами запрещена.")
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

/// Первый удар клинком создаёт связь без предварительного заклинания и соблюдает задержку добычи.
/datum/unit_test/heretic_blood_blade_opening/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/item/melee/sickly_blade/blood/blade = allocate(/obj/item/melee/sickly_blade/blood)
	blade.wound_bonus = CANT_WOUND
	blade.bare_wound_bonus = CANT_WOUND
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_NOTNULL(seal, "Первое попадание само создаёт связь.")
	TEST_ASSERT_EQUAL(seal.debt, 16, "Первое попадание даёт начальный долг и шесть за клинок.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Базовый боевой цикл не требует собственного здоровья.")
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(seal.debt, 16, "Серия быстрых ударов не обходит задержку добычи.")
	COOLDOWN_RESET(blood, resource_harvest)
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(seal.debt, 20, "После задержки долг растёт до предела.")

/// Антимагия блокирует самостоятельное Натяжение одним зарядом и не создаёт связь.
/datum/unit_test/heretic_blood_lance_protection/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_lance)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/destination = get_step(get_step(user, EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(blood.lance(user, victim), "Защищённая цель принимает заблокированный каст.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Каст расходует ровно один заряд защиты.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Антимагия блокирует урон.")
	TEST_ASSERT_EQUAL(victim.loc, destination, "Антимагия блокирует притяжение.")
	TEST_ASSERT_EQUAL(length(blood.seals), 0, "Заблокированный каст не создаёт долг.")
	qdel(protection)
	TEST_ASSERT(blood.release(user, victim), "До новой антимагии создана связь.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 1)
	TEST_ASSERT(blood.lance(user, victim), "Последний заряд блокирует натяжение готовой связи.")
	TEST_ASSERT_EQUAL(protection.charges, 0, "Защита расходует свой последний заряд.")
	TEST_ASSERT(QDELETED(seal), "Даже последний заряд антимагии немедленно разрывает связь.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Последний заряд полностью предотвращает урон.")

/// Последний заряд антимагии рвёт связь до удара клинком и блокирует её повторное создание.
/datum/unit_test/heretic_blood_blade_last_charge/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(blood.release(user, victim), "До антимагии существует кровная связь.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 1)
	var/obj/item/melee/sickly_blade/blood/blade = allocate(/obj/item/melee/sickly_blade/blood)
	blade.wound_bonus = CANT_WOUND
	blade.bare_wound_bonus = CANT_WOUND
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	TEST_ASSERT(abs(victim.getBruteLoss() - blade.force) < 0.01, "Антимагия не отменяет обычный физический удар.")
	TEST_ASSERT_EQUAL(protection.charges, 0, "Удар расходует единственный заряд защиты.")
	TEST_ASSERT(QDELETED(seal), "Последний заряд немедленно обрывает старую связь.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_blood_seal), "Заблокированный удар не создаёт новую связь после расхода заряда.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Уничтоженная связь не оставляет доступного долга.")

/// Короткая потеря контакта сохраняет долг, но блокирует его использование и не позволяет продлить срок обходом проверки.
/datum/unit_test/heretic_blood_contact_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_relic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_reckoning)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/middle = get_step(user, EAST)
	var/mob/living/victim = blood_minded_victim(get_step(middle, EAST))
	TEST_ASSERT(blood.release(user, victim), "Привязка создаёт долг.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/obj/blocker = allocate(/obj, middle)
	blocker.density = TRUE
	TEST_ASSERT(!seal.validate_link(), "Закрытая связь недоступна для действий.")
	TEST_ASSERT(!QDELETED(seal), "Долг сохраняется во время короткой потери видимости.")
	TEST_ASSERT_NULL(seal.link_beam, "Жила не рисуется сквозь преграду.")
	TEST_ASSERT(!blood.add_debt(seal, 6, renew = TRUE), "Через стену нельзя увеличить или продлить долг.")
	TEST_ASSERT(!blood.reckoning(user), "Массовое взыскание не обходит укрытие.")
	user.adjustFireLoss(10)
	var/burn_before_refund = user.getFireLoss()
	TEST_ASSERT(!blood.refund(user, victim), "Чаша не лечит сквозь стену.")
	blocker.density = FALSE
	TEST_ASSERT(seal.validate_link(), "Возвращение видимости восстанавливает ту же связь.")
	TEST_ASSERT_EQUAL(seal.debt, 10, "Короткий разрыв не создаёт и не расходует долг.")
	TEST_ASSERT_NOTNULL(seal.link_beam, "Видимая жила возвращается вместе с контактом.")
	user.Stun(1 SECONDS)
	TEST_ASSERT(!seal.validate_link() && !QDELETED(seal), "Короткое оглушение сохраняет неиспользуемый долг.")
	TEST_ASSERT(!blood.release(user, victim), "Оглушённый владелец не может начать взыскание.")
	user.SetStun(0)
	TEST_ASSERT(seal.validate_link(), "После короткого оглушения можно продолжить бой.")
	blocker.density = TRUE
	seal.validate_link()
	seal.contact_lost_at = world.time - 2 SECONDS
	blocker.density = FALSE
	TEST_ASSERT(!seal.validate_link() && QDELETED(seal), "Возвращение после двух секунд не оживляет просроченную связь.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Потеря контакта не взыскивает долг автоматически.")
	TEST_ASSERT_EQUAL(user.getFireLoss(), burn_before_refund, "Недоступная чаша не дала лечения.")
	TEST_ASSERT(blood.release(user, victim), "После потери долга доступна новая связь.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	user.Stun(5 SECONDS)
	seal.tick()
	TEST_ASSERT(wait_for_qdeleted(seal, max_wait = 4 SECONDS), "Долгое оглушение рвёт связь через настоящий обработчик статусов.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Истечение отсрочки очищает долг в HUD.")

/// Укрытие и длительное оглушение уничтожают долг и отменяют взыскание вместе с лечением.
/datum/unit_test/heretic_blood_collection_interruption/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	user.adjustBruteLoss(20)
	for(var/interrupt_with_wall in list(TRUE, FALSE))
		TEST_ASSERT(blood.release(user, victim), "Цель связана до взыскания.")
		var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
		TEST_ASSERT(blood.release(user, victim), "Взыскание начинает предупреждение.")
		var/obj/blocker
		if(interrupt_with_wall)
			blocker = allocate(/obj, get_step(user, EAST))
			blocker.density = TRUE
		else
			user.Stun(5 SECONDS)
			TEST_ASSERT(!seal.validate_link() && !QDELETED(seal), "Контроль сначала отменяет взыскание с сохранением долга.")
			seal.contact_lost_at = world.time - 2 SECONDS
		TEST_ASSERT(!seal.validate_link() && QDELETED(seal), "Укрытие или истечение отсрочки уничтожает связь.")
		TEST_ASSERT(!seal.detonate(), "Отменённый таймер не наносит запоздалый урон.")
		qdel(blocker)
		user.SetStun(0)
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Оба способа защищают должника от урона.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 20, "Сорванные взыскания не лечат владельца.")

/// Краткий контроль отменяет полное и частичное взыскание, сохраняя долг для новой попытки.
/datum/unit_test/heretic_blood_collection_stun_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = blood_minded_victim(get_step(user, EAST))
	for(var/partial in list(FALSE, TRUE))
		victim.fully_heal()
		user.fully_heal()
		user.adjustBruteLoss(20)
		TEST_ASSERT(blood.release(user, victim), "Создана кровная связь.")
		var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
		blood.add_debt(seal, 6)
		var/original_expiry = seal.expires_at
		TEST_ASSERT(blood.release(user, victim, partial), "Взыскание началось с шестнадцатью единицами долга.")
		user.Stun(1 SECONDS)
		TEST_ASSERT(!seal.validate_link() && !QDELETED(seal), "Оглушение сохраняет связь без возможности действовать.")
		TEST_ASSERT(!seal.collecting, "Оглушение отменяет начатое взыскание.")
		TEST_ASSERT_EQUAL(seal.debt, 16, "Весь накопленный долг сохранён.")
		TEST_ASSERT_EQUAL(blood.combat_resource, 16, "HUD сохраняет доступный после восстановления долг.")
		TEST_ASSERT_EQUAL(seal.expires_at, original_expiry, "Прерывание не продлевает срок связи.")
		TEST_ASSERT_NULL(seal.collection_timer, "Таймер прерванного взыскания отменён.")
		TEST_ASSERT_NULL(seal.collection_knowledge_ref, "Знание прерванного взыскания освобождено.")
		TEST_ASSERT(!blood.release(user, victim), "Оглушённый еретик не может начать новое взыскание.")
		TEST_ASSERT(!blood.add_debt(seal, 6, renew = TRUE), "Оглушение не позволяет пополнить или продлить долг.")
		user.SetStun(0)
		TEST_ASSERT(seal.validate_link(), "Восстановление возвращает ту же связь.")
		sleep(1.2 SECONDS)
		TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Старый таймер не наносит урон после восстановления.")
		TEST_ASSERT(abs(user.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Прерванное взыскание не лечит владельца.")
		TEST_ASSERT(blood.release(user, victim, partial), "После восстановления взыскание начинается заново.")
		TEST_ASSERT(!seal.detonate(), "Новая попытка требует полного предупреждения.")
		seal.collection_ready_at = world.time
		TEST_ASSERT(seal.detonate(), "Повторное взыскание завершается после предупреждения.")
		TEST_ASSERT(abs(victim.getBruteLoss() - (partial ? 20 : 32)) <= DAMAGE_PRECISION, "Взыскивается только выбранная сумма долга.")
		if(partial)
			TEST_ASSERT_EQUAL(seal.debt, 6, "Частичное взыскание сохраняет остаток долга.")
			qdel(seal)
		else
			TEST_ASSERT(seal.spent && !(seal in blood.seals), "Полное взыскание освобождает связь, оставляя пустую печать.")

/// Взыскание лечит оба вида ран, с одной цели не больше десяти за все связи и не высасывает здоровье из неуязвимой цели.
/datum/unit_test/heretic_blood_collection_siphon/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = blood_minded_victim(get_step(user, EAST))
	user.adjustBruteLoss(3)
	user.adjustFireLoss(32)
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Базовый долг готов к взысканию.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Базовое взыскание наносит урон.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Начальный долг наносит двадцать ушибов.")
	TEST_ASSERT(user.getBruteLoss() <= DAMAGE_PRECISION && abs(user.getFireLoss() - 30) <= DAMAGE_PRECISION, "Пять лечения распределяются между ушибами и ожогами без удвоения.")
	TEST_ASSERT(blood.release(user, victim), "После взыскания цель можно связать снова.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	blood.add_debt(seal, 10)
	TEST_ASSERT(blood.release(user, victim), "Полный долг готов к взысканию.")
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Взыскание полного долга завершается.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 60) <= DAMAGE_PRECISION, "Двадцать долга наносят ещё сорок ушибов.")
	TEST_ASSERT(abs(user.getFireLoss() - 25) <= DAMAGE_PRECISION, "С одной цели лечится не больше десяти и за новую связь: [user.getFireLoss()].")
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Подготовлено взыскание с защищённой цели.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	victim.status_flags |= GODMODE
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Неуязвимость не оставляет вечную подготовку.")
	TEST_ASSERT(abs(user.getFireLoss() - 25) <= DAMAGE_PRECISION, "Без фактического урона лечения нет.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 60) <= DAMAGE_PRECISION, "Неуязвимая цель не получает урон.")

/// Чаша лечит ожоги через предмет, расходуя только нужную долю долга и соблюдая перезарядку.
/datum/unit_test/heretic_blood_chalice_burns/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/blood_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/mob/living/victim = blood_minded_victim(get_step(user, EAST))
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Обряд создаёт чашу.")
	var/obj/item/heretic_path_relic/blood_relic/chalice = recipe.new_path_relic_ref.resolve()
	allocated += chalice
	user.put_in_hands(chalice)
	user.adjustFireLoss(7)
	TEST_ASSERT(blood.release(user, victim), "У владельца есть должник.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	chalice.afterattack(victim, user, TRUE, null)
	TEST_ASSERT(user.getFireLoss() <= DAMAGE_PRECISION, "Щелчок чашей лечит чистый ожог.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 7) <= DAMAGE_PRECISION, "Лечение требует семь реального урона.")
	TEST_ASSERT(abs(seal.debt - 6.5) <= DAMAGE_PRECISION, "На небольшой ожог расходуется только три с половиной долга.")
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(chalice, relic_cooldown) - 12 SECONDS) <= world.tick_lag, "Успешный глоток включает двенадцатисекундную перезарядку.")
	user.adjustFireLoss(7)
	TEST_ASSERT(!chalice.drink(user, victim), "Новая рана не обходит перезарядку.")

/// Клинок повторно накапливает долг через две секунды, продлевает полную связь и не учащает пополнение при спаме.
/datum/unit_test/heretic_blood_blade_tempo/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/item/melee/sickly_blade/blood/blade = allocate(/obj/item/melee/sickly_blade/blood)
	blade.wound_bonus = CANT_WOUND
	blade.bare_wound_bonus = CANT_WOUND
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_NOTNULL(seal, "Первое настоящее попадание заводит связь.")
	TEST_ASSERT_EQUAL(seal.debt, 16, "Первое попадание сразу даёт шестнадцать долга.")
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(seal.debt, 16, "Немедленный второй удар не обходит ограничение пополнения.")
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(blood, resource_harvest) - 2 SECONDS) <= world.tick_lag, "Долг пополняется с двухсекундной перезарядкой.")
	COOLDOWN_RESET(blood, resource_harvest)
	seal.expires_at = world.time + 1 SECONDS
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(seal.debt, 20, "Следующее попадание заполняет долг до предела.")
	TEST_ASSERT_EQUAL(seal.expires_at, world.time + 15 SECONDS, "Продолжение боя сохраняет накопленный долг.")
/// Отказы взыскания и Скользкой крови сохраняют перезарядку и объясняют недостающее условие.
/datum/unit_test/heretic_blood_failure_feedback/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_reckoning)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_slip)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/obj/effect/proc_holder/spell/self/heretic_blood/reckoning/reckoning = allocate(/obj/effect/proc_holder/spell/self/heretic_blood/reckoning)
	reckoning.charge_counter = 0
	reckoning.cast(list(user), user)
	TEST_ASSERT(findtext(reckoning.heretic_failure_reason, "Нет кровных связей"), "Отказ объясняет отсутствие связей.")
	TEST_ASSERT_EQUAL(reckoning.charge_counter, reckoning.charge_max, "Неудачное взыскание возвращает перезарядку.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(blood.release(user, victim), "Создана кровная связь.")
	TEST_ASSERT(blood.reckoning(user), "Первое взыскание началось.")
	TEST_ASSERT_NULL(blood.ability_failure, "Успешное взыскание очищает предыдущую причину отказа.")
	TEST_ASSERT(!blood.reckoning(user), "Повторное взыскание во время предупреждения отклоняется.")
	TEST_ASSERT(findtext(blood.ability_failure, "уже взыскивается"), "Отказ объясняет уже начатое взыскание.")
	user.health = 30
	var/obj/effect/proc_holder/spell/self/heretic_blood/slip/slip = allocate(/obj/effect/proc_holder/spell/self/heretic_blood/slip)
	slip.charge_counter = 0
	slip.cast(list(user), user)
	TEST_ASSERT(findtext(slip.heretic_failure_reason, "мало здоровья"), "Опасная плата объяснена игроку.")
	TEST_ASSERT_EQUAL(slip.charge_counter, slip.charge_max, "Отказ оплаты возвращает перезарядку.")

/// Разрыв взыскания расстоянием сохраняет точную причину для сообщения и журнала.
/datum/unit_test/heretic_blood_link_loss_reason/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, SOUTHWEST))
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(blood.release(user, victim), "Создана кровная связь.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(blood.release(user, victim), "Начато взыскание.")
	victim.forceMove(get_step(run_loc_floor_top_right, NORTHEAST))
	TEST_ASSERT(get_dist(user, victim) > 5, "Цель выведена за пределы дальности связи.")
	TEST_ASSERT(QDELETED(seal), "Уход за пределы дальности разрывает взыскание.")
	TEST_ASSERT_EQUAL(seal.link_end_reason, "должник дальше пяти клеток", "Причина не смешивает расстояние с оглушением.")

/// Адресные силы Крови различают препятствия и защиту, не расходуя заряд при проверке цели.
/datum/unit_test/heretic_blood_target_feedback/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	for(var/spell_type in list(/obj/effect/proc_holder/spell/pointed/heretic_blood/release, /obj/effect/proc_holder/spell/pointed/heretic_blood/lance))
		var/obj/effect/proc_holder/spell/pointed/heretic_blood/spell = allocate(spell_type)
		TEST_ASSERT(spell.can_target(victim, user, TRUE), "Открытая живая цель доступна для [spell.name].")
		TEST_ASSERT(!spell.can_target(get_turf(victim), user, TRUE), "Пол не заменяет противника.")
		TEST_ASSERT(findtext(spell.heretic_failure_reason, "пол и предметы"), "Промах клика объяснён отдельно.")
		var/obj/structure/closet/closet = allocate(/obj/structure/closet, get_turf(victim))
		victim.forceMove(closet)
		TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Цель внутри контейнера недоступна.")
		TEST_ASSERT(findtext(spell.heretic_failure_reason, "внутри контейнера"), "Укрытие объяснено отдельно.")
		victim.forceMove(get_turf(closet))
		qdel(closet)
		var/obj/structure/table/barrier = allocate(/obj/structure/table, get_step(user, EAST))
		TEST_ASSERT(!blood.valid_victim(user, victim), "Преграда закрывает цель для механики связи.")
		TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Прицел соблюдает ту же преграду.")
		TEST_ASSERT(findtext(spell.heretic_failure_reason, "перекрыта"), "Преграда не выдаётся за антимагию.")
		qdel(barrier)
		TEST_ASSERT(victim.put_in_hands(rod), "Цель держит источник антимагии.")
		TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Антимагия защищает цель.")
		TEST_ASSERT(findtext(spell.heretic_failure_reason, "защищена от магии"), "Антимагия объяснена отдельно.")
		victim.dropItemToGround(rod)
		TEST_ASSERT(spell.can_target(victim, user, TRUE), "После снятия защиты цель снова доступна.")
		TEST_ASSERT_NULL(spell.heretic_failure_reason, "Допустимая цель очищает старый отказ.")
		TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Проверки не расходуют перезарядку.")
		TEST_ASSERT_EQUAL(length(blood.seals), 0, "Проверки не создают связей.")

/// Чужая связь, занятый предел и начатое взыскание дают разные отказы без изменения долга.
/datum/unit_test/heretic_blood_seal_feedback/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/other_victim = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/datum/antagonist/heretic/other_heretic = allocate_deed_heretic(PATH_BLOOD)
	var/datum/eldritch_knowledge/base_blood/other_blood = other_heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	TEST_ASSERT(blood.release(user, victim), "Создана связь владельца.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/obj/effect/proc_holder/spell/pointed/heretic_blood/release/release = allocate(/obj/effect/proc_holder/spell/pointed/heretic_blood/release)
	TEST_ASSERT(!release.can_target(other_victim, user, TRUE), "Занятый предел запрещает новую связь.")
	TEST_ASSERT(findtext(release.heretic_failure_reason, "Связи заняты"), "Отказ называет занятый предел.")
	qdel(seal)
	TEST_ASSERT(other_blood.release(other_heretic.owner.current, victim), "Создана чужая кровная связь.")
	var/list/spells = list(release, allocate(/obj/effect/proc_holder/spell/pointed/heretic_blood/lance))
	for(var/obj/effect/proc_holder/spell/pointed/heretic_blood/spell as anything in spells)
		TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Чужую связь нельзя забрать проверкой цели.")
		TEST_ASSERT(findtext(spell.heretic_failure_reason, "другому еретику"), "Отказ называет владельца связи.")
	qdel(victim.has_status_effect(/datum/status_effect/heretic_blood_seal))
	TEST_ASSERT(blood.release(user, victim), "Снова создана своя связь.")
	for(var/obj/effect/proc_holder/spell/pointed/heretic_blood/spell as anything in spells)
		TEST_ASSERT(spell.can_target(victim, user, TRUE), "Свой должник доступен при занятом пределе.")
	TEST_ASSERT(blood.release(user, victim), "Начато взыскание со своего должника.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	for(var/obj/effect/proc_holder/spell/pointed/heretic_blood/spell as anything in spells)
		TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Начатое взыскание нельзя запустить повторно.")
		TEST_ASSERT(findtext(spell.heretic_failure_reason, "Взыскание уже началось"), "Отказ объясняет ожидание удара.")
		TEST_ASSERT_EQUAL(seal.debt, 10, "Проверки сохраняют накопленный долг.")
		TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Отказы не расходуют перезарядку.")

/datum/unit_test/proc/blood_tide_bleeder(turf/place)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, place)
	var/obj/item/bodypart/arm = victim.get_bodypart(BODY_ZONE_L_ARM)
	arm.generic_bleedstacks = 5
	victim.blood_volume = BLOOD_VOLUME_NORMAL
	return victim

/datum/unit_test/proc/blood_tide_cut(turf/place, bandaged = FALSE)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, place)
	var/obj/item/bodypart/arm = victim.get_bodypart(BODY_ZONE_R_ARM)
	var/datum/wound/slash/moderate/cut = new
	cut.apply_wound(arm, silent = TRUE)
	if(bandaged)
		arm.apply_gauze(allocate(/obj/item/stack/medical/gauze, place))
	victim.blood_volume = BLOOD_VOLUME_NORMAL
	return victim

/datum/unit_test/proc/blood_tide_stain(turf/place, stain_type = /obj/effect/decal/cleanable/blood/splatter, donor = "unit test donor")
	var/obj/effect/decal/cleanable/blood/stain = new stain_type(place)
	var/list/signature = list()
	signature[donor] = "O+"
	stain.add_blood_DNA(signature)
	return stain

/datum/unit_test/proc/ascend_blood_tide(datum/antagonist/heretic/heretic)
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/blood_final)
	var/datum/eldritch_knowledge/final_eldritch/blood_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/blood_final)
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(heretic.owner.current)
	return finale

/// Вознёсшаяся Кровь раз в тик жизни повторяет текущее кровотечение врагов в трёх клетках, не трогая сами раны; перевязанная рана ничего не добавляет.
/datum/unit_test/heretic_blood_tide_bleeding/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/crew = blood_tide_bleeder(locate(start.x + 2, start.y + 2, start.z))
	var/mob/living/carbon/human/distant = blood_tide_bleeder(locate(start.x + 4, start.y, start.z))
	var/mob/living/carbon/human/cut = blood_tide_cut(locate(start.x + 2, start.y, start.z))
	var/mob/living/carbon/human/bandaged = blood_tide_cut(locate(start.x + 1, start.y, start.z), bandaged = TRUE)
	var/mob/living/carbon/human/warded = blood_tide_bleeder(locate(start.x, start.y + 1, start.z))
	var/datum/component/anti_magic/ward = warded.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/datum/antagonist/heretic/ally = allocate_heretic(locate(start.x + 3, start.y + 3, start.z))
	var/mob/living/carbon/human/ally_body = ally.owner.current
	var/obj/item/bodypart/ally_arm = ally_body.get_bodypart(BODY_ZONE_L_ARM)
	ally_arm.generic_bleedstacks = 5
	var/datum/eldritch_knowledge/final_eldritch/blood_final/finale = ascend_blood_tide(heretic)
	TEST_ASSERT_NOTNULL(user.GetComponent(/datum/component/heretic_blood_tide), "Вознесение Крови включает кровавый прилив.")
	var/rate = crew.get_total_bleed_rate() * crew.physiology.bleed_mod
	var/cut_rate = cut.get_total_bleed_rate() * cut.physiology.bleed_mod
	TEST_ASSERT(rate > 0 && cut_rate > 0, "Раненые враги кровоточат.")
	TEST_ASSERT_EQUAL(bandaged.get_total_bleed_rate(), 0, "Повязка останавливает кровь из раны.")
	var/crew_blood = crew.blood_volume
	var/cut_blood = cut.blood_volume
	var/distant_blood = distant.blood_volume
	var/bandaged_blood = bandaged.blood_volume
	var/warded_blood = warded.blood_volume
	var/ally_blood = ally_body.blood_volume
	SEND_SIGNAL(user, COMSIG_LIVING_LIFE, 2, 1)
	TEST_ASSERT(abs(crew.blood_volume - (crew_blood - rate)) <= DAMAGE_PRECISION, "Враг в трёх клетках теряет за тик ещё столько же крови, сколько от своих ран.")
	TEST_ASSERT(abs(cut.blood_volume - (cut_blood - cut_rate)) <= DAMAGE_PRECISION, "Открытый порез тоже кровоточит вдвое.")
	var/obj/item/bodypart/crew_arm = crew.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT_EQUAL(crew_arm.generic_bleedstacks, 5, "Сами раны не меняются.")
	TEST_ASSERT_EQUAL(distant.blood_volume, distant_blood, "Враг дальше трёх клеток кровоточит как обычно.")
	TEST_ASSERT_EQUAL(bandaged.blood_volume, bandaged_blood, "Перевязанная рана ничего не добавляет.")
	TEST_ASSERT_EQUAL(warded.blood_volume, warded_blood, "Защита от магии не даёт удвоить кровотечение.")
	TEST_ASSERT_EQUAL(ward.charges, 5, "Проверка защиты не тратит заряды.")
	TEST_ASSERT_EQUAL(ally_body.blood_volume, ally_blood, "Другой еретик не затронут.")
	var/list/examine_lines = list()
	SEND_SIGNAL(user, COMSIG_PARENT_EXAMINE, crew, examine_lines)
	TEST_ASSERT(findtext(jointext(examine_lines, " "), "трёх клеток"), "Осмотр называет радиус прилива.")
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_blood_tide), "Смерть снимает кровавый прилив.")
	crew_blood = crew.blood_volume
	SEND_SIGNAL(user, COMSIG_LIVING_LIFE, 2, 2)
	TEST_ASSERT_EQUAL(crew.blood_volume, crew_blood, "Мёртвый не удваивает кровотечение.")
	user.revive(full_heal = TRUE)
	finale.on_life(user)
	TEST_ASSERT_NOTNULL(user.GetComponent(/datum/component/heretic_blood_tide), "Оживление возвращает кровавый прилив.")
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_blood_tide), "Потеря тела снимает кровавый прилив.")
	SEND_SIGNAL(user, COMSIG_LIVING_LIFE, 2, 3)
	TEST_ASSERT_EQUAL(crew.blood_volume, crew_blood, "Без вознесения кровотечение не удваивается.")

/// Вознёсшаяся Кровь выпивает свежую чужую лужу под ногами не чаще раза в секунду и лечит 3 ушиба, затем ожоги; засохшая, своя, следы обуви и кровь ксеноморфов не годятся.
/datum/unit_test/heretic_blood_tide_pools/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/blood_final/finale = ascend_blood_tide(heretic)
	var/datum/component/heretic_blood_tide/blood_tide = user.GetComponent(/datum/component/heretic_blood_tide)
	var/turf/pool = locate(start.x + 1, start.y, start.z)
	var/obj/effect/decal/cleanable/blood/splatter = blood_tide_stain(pool)
	var/obj/effect/decal/cleanable/blood/drip = blood_tide_stain(pool, /obj/effect/decal/cleanable/blood/drip)
	var/turf/prints_turf = locate(start.x, start.y + 1, start.z)
	blood_tide_stain(prints_turf, /obj/effect/decal/cleanable/blood/footprints)
	var/turf/xeno_turf = locate(start.x + 1, start.y + 1, start.z)
	var/obj/effect/decal/cleanable/blood/xeno = blood_tide_stain(xeno_turf, /obj/effect/decal/cleanable/blood/xeno)
	var/turf/own_turf = locate(start.x + 2, start.y, start.z)
	var/obj/effect/decal/cleanable/blood/own = blood_tide_stain(own_turf, donor = user.dna.unique_enzymes)
	var/turf/old_turf = locate(start.x + 2, start.y + 1, start.z)
	var/obj/effect/decal/cleanable/blood/old = blood_tide_stain(old_turf, /obj/effect/decal/cleanable/blood/old)
	var/turf/loaded_turf = locate(start.x + 3, start.y, start.z)
	var/obj/effect/decal/cleanable/blood/loaded = blood_tide_stain(loaded_turf)
	loaded.PersistenceLoad(list())
	var/turf/burn_turf = locate(start.x + 3, start.y + 1, start.z)
	var/obj/effect/decal/cleanable/blood/burn_pool = blood_tide_stain(burn_turf)
	user.forceMove(pool)
	TEST_ASSERT(!QDELETED(splatter) && !QDELETED(drip), "Без ран кровь остаётся на полу.")
	user.forceMove(start)
	user.adjustBruteLoss(20, forced = TRUE)
	var/brute = user.getBruteLoss()
	for(var/turf/refused as anything in list(prints_turf, xeno_turf, own_turf, old_turf, loaded_turf))
		user.forceMove(refused)
		TEST_ASSERT_EQUAL(user.getBruteLoss(), brute, "Непригодная кровь не лечит: [refused.x - start.x],[refused.y - start.y].")
	TEST_ASSERT(!QDELETED(xeno) && !QDELETED(own) && !QDELETED(old) && !QDELETED(loaded), "Непригодная кровь остаётся на полу.")
	TEST_ASSERT(loaded.dried, "Пятно из прошлого раунда засохло.")
	user.forceMove(pool)
	TEST_ASSERT(abs(brute - user.getBruteLoss() - HERETIC_BLOOD_TIDE_POOL_HEAL) <= DAMAGE_PRECISION, "Лужа под ногами лечит 3.")
	TEST_ASSERT(QDELETED(splatter) != QDELETED(drip), "За шаг выпита ровно одна лужа.")
	user.forceMove(start)
	user.forceMove(pool)
	TEST_ASSERT(abs(brute - user.getBruteLoss() - HERETIC_BLOOD_TIDE_POOL_HEAL) <= DAMAGE_PRECISION, "Повторный шаг в ту же секунду не лечит.")
	TEST_ASSERT(QDELETED(splatter) != QDELETED(drip), "Вторая лужа ждёт конца перезарядки.")
	COOLDOWN_RESET(blood_tide, pool_heal)
	user.forceMove(start)
	user.forceMove(pool)
	TEST_ASSERT(abs(brute - user.getBruteLoss() - HERETIC_BLOOD_TIDE_POOL_HEAL * 2) <= DAMAGE_PRECISION, "После перезарядки выпита вторая лужа.")
	TEST_ASSERT(QDELETED(splatter) && QDELETED(drip), "Обе лужи выпиты.")
	user.adjustBruteLoss(-user.getBruteLoss(), forced = TRUE)
	user.adjustFireLoss(10, forced = TRUE)
	var/burn = user.getFireLoss()
	COOLDOWN_RESET(blood_tide, pool_heal)
	user.forceMove(burn_turf)
	TEST_ASSERT(abs(burn - user.getFireLoss() - HERETIC_BLOOD_TIDE_POOL_HEAL) <= DAMAGE_PRECISION, "Без ушибов лужа лечит ожоги.")
	TEST_ASSERT(QDELETED(burn_pool), "Лужа для ожогов выпита.")
	finale.on_body_lose(user)
	var/obj/effect/decal/cleanable/blood/late = blood_tide_stain(start)
	burn = user.getFireLoss()
	user.forceMove(start)
	TEST_ASSERT_EQUAL(user.getFireLoss(), burn, "Без вознесения кровь не лечит.")
	TEST_ASSERT(!QDELETED(late), "Без вознесения лужа остаётся.")

/// Удвоенное кровотечение тянется тонкой струйкой от раненого к вознёсшемуся; без зрителей её нет, кровопотеря прежняя.
/datum/unit_test/heretic_blood_tide_stream_visual/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/crew = blood_tide_bleeder(locate(start.x + 2, start.y + 2, start.z))
	ascend_blood_tide(heretic)
	var/datum/component/heretic_blood_tide/blood_tide = user.GetComponent(/datum/component/heretic_blood_tide)
	var/turf/crew_turf = get_turf(crew)
	var/list/before = list_vfx_bursts(crew_turf)
	var/rate = crew.get_total_bleed_rate() * crew.physiology.bleed_mod
	var/blood_before = crew.blood_volume
	SEND_SIGNAL(user, COMSIG_LIVING_LIFE, 2, 1)
	TEST_ASSERT(abs(crew.blood_volume - (blood_before - rate)) <= DAMAGE_PRECISION, "Кровопотеря прежняя.")
	TEST_ASSERT_NULL(find_vfx_burst(crew_turf, /particles/heretic_ascension/blood/tide_stream, before), "Без зрителей рядом струйка не рисуется.")
	blood_tide.drain(crew, TRUE)
	var/obj/effect/temp_visual/heretic_vfx/burst/stream = find_vfx_burst(crew_turf, /particles/heretic_ascension/blood/tide_stream, before)
	TEST_ASSERT_NOTNULL(stream, "Кровь раненого тянется струйкой.")
	var/list/flow = stream.particles.velocity
	TEST_ASSERT(flow[1] < 0 && flow[2] < 0, "Струйка течёт к вознёсшемуся.")
	TEST_ASSERT(stream.particles.count <= 10, "Струйка тонкая.")
	TEST_ASSERT(wait_for_qdeleted(stream, 4 SECONDS), "Струйка иссякает.")

/// Выпитая лужа стягивается воронкой к ногам вознёсшегося, а не пропадает; лечение прежнее.
/datum/unit_test/heretic_blood_pool_drink_visual/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	ascend_blood_tide(heretic)
	var/turf/pool = locate(start.x + 1, start.y, start.z)
	var/obj/effect/decal/cleanable/blood/stain = blood_tide_stain(pool)
	user.adjustBruteLoss(20, forced = TRUE)
	var/brute = user.getBruteLoss()
	user.forceMove(pool)
	TEST_ASSERT(QDELETED(stain), "Лужа выпита, как раньше.")
	TEST_ASSERT(abs(brute - user.getBruteLoss() - HERETIC_BLOOD_TIDE_POOL_HEAL) <= DAMAGE_PRECISION, "Лужа лечит 3, как раньше.")
	var/obj/effect/temp_visual/heretic_vfx/ghost/swirl = locate() in pool
	TEST_ASSERT_NOTNULL(swirl, "Лужа стягивается воронкой, а не пропадает.")
	TEST_ASSERT_EQUAL(swirl.icon, stain.icon, "Воронка повторяет саму лужу.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_vfx/converge) in pool, "Капли стекаются к вознёсшемуся.")
	TEST_ASSERT_NOTNULL(user.get_filter(HERETIC_VFX_PULSE_FILTER), "Выпитая кровь вспыхивает на вознёсшемся.")
	TEST_ASSERT(wait_for_qdeleted(swirl), "Воронка уходит.")

/// Кровный приговор: нити крови других должников сходятся в выбранного, кольцо смыкается к удару, удар - багровая волна; перенос и урон прежние.
/datum/unit_test/heretic_blood_verdict_visuals/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	ascend_blood_tide(heretic)
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/chosen_turf = locate(start.x + 2, start.y, start.z)
	var/turf/donor_turf = locate(start.x, start.y + 3, start.z)
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human, chosen_turf)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, donor_turf)
	TEST_ASSERT(blood.release(user, first) && blood.release(user, second), "Оба должника связаны.")
	var/datum/status_effect/heretic_blood_seal/chosen = first.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/status_effect/heretic_blood_seal/donor = second.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(blood.add_debt(chosen, 18), "Долг выбранного у предела.")
	var/total = blood.combat_resource
	var/list/before = list_vfx_bursts(donor_turf)
	TEST_ASSERT(blood.coronation(user, first), "Приговор вынесен.")
	TEST_ASSERT(abs(chosen.debt - 30) < 0.01 && abs(blood.combat_resource - total) < 0.01, "Перенос прежний: 30 у выбранного, общий долг сохранён.")
	var/obj/effect/temp_visual/heretic_vfx/thread/thread = locate() in donor_turf
	TEST_ASSERT_NOTNULL(thread, "От другого должника тянется нить крови.")
	TEST_ASSERT_EQUAL(round(thread.angle), round(Get_Angle(donor_turf, chosen_turf)), "Нить сходится в выбранного.")
	TEST_ASSERT(thread.settled, "Нить втягивается в выбранного.")
	TEST_ASSERT_NOTNULL(find_vfx_burst(donor_turf, /particles/heretic_ascension/blood/verdict, before), "По нити бежит кровь.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_vfx/gather) in chosen_turf, "Кольцо смыкается на выбранном.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in chosen_turf, "Волны до удара нет.")
	var/debt = chosen.debt
	var/brute_before = first.getBruteLoss()
	var/list/budget = new_wait_budget(3 SECONDS, "удар приговора")
	while(first.getBruteLoss() <= brute_before)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(abs(first.getBruteLoss() - brute_before - debt * 2) <= DAMAGE_PRECISION, "Удар приговора прежний: 2 ушиба за единицу долга.")
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = locate() in chosen_turf
	TEST_ASSERT_NOTNULL(wave, "Удар приговора - багровая волна.")
	TEST_ASSERT(QDELETED(thread), "Нить втянулась до удара.")
	TEST_ASSERT(!QDELETED(donor), "Остаток долга у другого должника сохранён.")
	TEST_ASSERT(wait_for_qdeleted(wave), "Волна гаснет.")

/area/unit_test_blood_slick
	name = "Blood Slick Test Room"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY

/datum/unit_test/proc/blood_drain_heretic(turf/place)
	var/datum/antagonist/heretic/heretic = allocate_heretic(place)
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_drain)
	return heretic

/datum/unit_test/proc/blood_debtor(datum/eldritch_knowledge/base_blood/blood, turf/place, debt = HERETIC_BLOOD_DRAIN_DEBT)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, place)
	victim.blood_volume = BLOOD_VOLUME_NORMAL
	if(!blood.release(blood.blood_body, victim))
		return victim
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.debt = debt
	blood.update_debt()
	return victim

/// Хватка в «Помощи» читает чужую кровь на полу: метка с уликой, след к владельцу, дело и лечение; три метки с вытеснением; жезл, швабра и космочист снимают метку; смерть и смена тела её не трогают, удаление знания снимает.
/datum/unit_test/heretic_blood_sign_craft/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, locate(origin.x + 4, origin.y + 4, origin.z))
	crew.dna.unique_enzymes = "blood sign crew"
	var/turf/pool_turf = locate(origin.x + 1, origin.y, origin.z)
	var/obj/effect/decal/cleanable/blood/pool = blood_tide_stain(pool_turf, donor = crew.dna.unique_enzymes)
	user.adjustBruteLoss(10)
	user.a_intent = INTENT_HARM
	TEST_ASSERT(!blood.on_mansus_grasp(pool, user, TRUE, null), "Вне «Помощи» кровь не читается и не тратит хватку.")
	TEST_ASSERT_NULL(blood.grasp_failure_reason, "Промах вне «Помощи» не жалуется.")
	TEST_ASSERT_NULL(heretic_craft_on(pool, "blood_sign"), "Вне «Помощи» метки нет.")
	user.a_intent = INTENT_HELP
	TEST_ASSERT(blood.on_mansus_grasp(pool, user, TRUE, null), "Хватка в «Помощи» читает чужую кровь.")
	TEST_ASSERT_NOTNULL(heretic_craft_on(pool, "blood_sign"), "Пятно стало ремеслом Крови.")
	TEST_ASSERT(pool in blood.signs, "Пятно попало в список меток.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Новый человек засчитан делу.")
	TEST_ASSERT(abs(user.getBruteLoss() - 5) <= DAMAGE_PRECISION, "Дело лечит 5 ушибов: [user.getBruteLoss()].")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/decal/cleanable/heretic_trace) in pool_turf, "След дела лежит у пятна.")
	var/datum/status_effect/heretic_blood_trail/trail = user.has_status_effect(/datum/status_effect/heretic_blood_trail)
	TEST_ASSERT_NOTNULL(trail, "Прочитанная кровь даёт след.")
	TEST_ASSERT_EQUAL(trail.quarry_ref?.resolve(), crew, "След ведёт к владельцу крови.")
	var/mob/living/carbon/human/witness = allocate(/mob/living/carbon/human, locate(origin.x + 2, origin.y, origin.z))
	TEST_ASSERT(findtext(jointext(pool.examine(witness), " "), "не засыхает и медленно пульсирует"), "Экипаж видит улику при осмотре.")
	TEST_ASSERT(findtext(jointext(pool.examine(user), " "), "Ваше ремесло"), "Еретик узнаёт свою метку.")
	TEST_ASSERT(blood.on_mansus_grasp(pool, user, TRUE, null), "Свою метку можно прочитать снова ради следа.")
	TEST_ASSERT_EQUAL(length(blood.signs), 1, "Повторное чтение не ставит вторую метку.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Уже прочитанный человек не засчитывается снова.")
	var/list/pools = list(pool)
	for(var/index in 2 to HERETIC_BLOOD_SIGN_LIMIT + 1)
		var/obj/effect/decal/cleanable/blood/more = blood_tide_stain(locate(origin.x + index - 1, origin.y + 2, origin.z), donor = crew.dna.unique_enzymes)
		TEST_ASSERT(blood.read_blood(user, more), "Пятно [index] читается.")
		pools += more
	TEST_ASSERT_EQUAL(length(blood.signs), HERETIC_BLOOD_SIGN_LIMIT, "Держится не больше [HERETIC_BLOOD_SIGN_LIMIT] меток.")
	TEST_ASSERT_NULL(heretic_craft_on(pool, "blood_sign"), "Новая метка вытесняет самую старую.")
	TEST_ASSERT(!QDELETED(pool), "Вытесненная кровь остаётся на полу.")
	TEST_ASSERT_EQUAL(blood.signs[1], pools[2], "Старейшей становится следующая метка.")
	var/obj/effect/decal/cleanable/blood/rodded = pools[2]
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	witness.put_in_hands(rod)
	rod.melee_attack_chain(witness, rodded)
	TEST_ASSERT_NULL(heretic_craft_on(rodded, "blood_sign"), "Нулевой жезл снимает метку.")
	TEST_ASSERT(!(rodded in blood.signs), "Снятая жезлом метка уходит из списка.")
	TEST_ASSERT(!QDELETED(rodded), "Жезл снимает метку, а не кровь.")
	var/obj/effect/decal/cleanable/blood/mopped = pools[3]
	var/obj/item/mop/mop = allocate(/obj/item/mop)
	mop.reagents.add_reagent(/datum/reagent/water, 10)
	mop.clean(get_turf(mopped), witness)
	TEST_ASSERT(QDELETED(mopped), "Швабра смывает помеченную кровь.")
	TEST_ASSERT(!(mopped in blood.signs), "Смытая шваброй метка уходит из списка.")
	var/obj/effect/decal/cleanable/blood/sprayed = pools[4]
	var/datum/reagent/cleaner = GLOB.chemical_reagents_list[/datum/reagent/space_cleaner]
	cleaner.reaction_turf(get_turf(sprayed), 10)
	TEST_ASSERT(QDELETED(sprayed), "Космочист смывает помеченную кровь.")
	TEST_ASSERT_EQUAL(length(blood.signs), 0, "Уборка и жезл сняли все метки.")
	var/obj/effect/decal/cleanable/blood/kept = blood_tide_stain(locate(origin.x + 3, origin.y + 3, origin.z), donor = crew.dna.unique_enzymes)
	TEST_ASSERT(blood.read_blood(user, kept), "Новая метка ставится.")
	blood.on_death(user)
	TEST_ASSERT(kept in blood.signs, "Смерть еретика не снимает метку.")
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, origin)
	heretic.owner.transfer_to(new_body, TRUE)
	TEST_ASSERT(kept in blood.signs, "Смена тела не снимает метку.")
	TEST_ASSERT_NULL(user.has_status_effect(/datum/status_effect/heretic_blood_trail), "След не остаётся на прежнем теле.")
	qdel(blood)
	TEST_ASSERT_NULL(heretic_craft_on(kept, "blood_sign"), "Удаление знания снимает метку.")

/// Кровь читается с окровавленного предмета и из шприца; своя, засохшая кровь отказывают без траты хватки; во время паузы дела новый человек ждёт, уже прочитанный читается; кровь без владельца метится без следа.
/datum/unit_test/heretic_blood_sign_sources/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y, origin.z))
	first.dna.unique_enzymes = "blood source first"
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y + 3, origin.z))
	second.dna.unique_enzymes = "blood source second"
	user.a_intent = INTENT_HELP
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife, origin)
	knife.add_mob_blood(first)
	TEST_ASSERT(blood.on_mansus_grasp(knife, user, TRUE, null), "Окровавленный нож читается.")
	var/datum/status_effect/heretic_blood_trail/trail = user.has_status_effect(/datum/status_effect/heretic_blood_trail)
	TEST_ASSERT_EQUAL(trail?.quarry_ref?.resolve(), first, "Кровь на ноже ведёт к её владельцу.")
	TEST_ASSERT_EQUAL(length(blood.signs), 0, "Предмет не становится меткой.")
	TEST_ASSERT(first.dna.unique_enzymes in heretic.deed.counted_keys, "Кровь на предмете засчитывается делу.")
	var/obj/item/reagent_containers/syringe/syringe = allocate(/obj/item/reagent_containers/syringe, origin)
	syringe.reagents.add_reagent(/datum/reagent/blood, 5, list("blood_DNA" = second.dna.unique_enzymes, "blood_type" = "O+"))
	TEST_ASSERT(!blood.on_mansus_grasp(syringe, user, TRUE, null), "Во время паузы дела кровь нового человека не читается.")
	TEST_ASSERT(findtext(blood.grasp_failure_reason, "Слишком быстро"), "Отказ называет паузу: [blood.grasp_failure_reason]")
	TEST_ASSERT(findtext(blood.grasp_failure_reason, "[HERETIC_DEED_COOLDOWN / (1 SECONDS)] с"), "Отказ называет остаток паузы: [blood.grasp_failure_reason]")
	TEST_ASSERT_EQUAL(trail.quarry_ref?.resolve(), first, "Отказ не меняет след.")
	TEST_ASSERT(blood.on_mansus_grasp(knife, user, TRUE, null), "Уже прочитанного человека пауза не держит.")
	trail = user.has_status_effect(/datum/status_effect/heretic_blood_trail)
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(blood.on_mansus_grasp(syringe, user, TRUE, null), "Шприц с чужой кровью читается.")
	TEST_ASSERT(QDELETED(trail), "Новый след заменяет прежний.")
	trail = user.has_status_effect(/datum/status_effect/heretic_blood_trail)
	TEST_ASSERT_EQUAL(trail?.quarry_ref?.resolve(), second, "Кровь из шприца ведёт к её владельцу.")
	TEST_ASSERT(second.dna.unique_enzymes in heretic.deed.counted_keys, "Кровь из шприца засчитывается делу.")
	var/obj/item/kitchen/knife/own_knife = allocate(/obj/item/kitchen/knife, origin)
	own_knife.add_mob_blood(user)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	var/charges_before = fist.charges
	fist.afterattack(own_knife, user, TRUE)
	TEST_ASSERT(!QDELETED(fist) && fist.charges == charges_before, "Своя кровь не тратит хватку.")
	TEST_ASSERT(findtext(blood.grasp_failure_reason, "нет чужой подписи"), "Отказ называет свою кровь: [blood.grasp_failure_reason]")
	var/obj/effect/decal/cleanable/blood/old = blood_tide_stain(locate(origin.x + 1, origin.y + 1, origin.z), /obj/effect/decal/cleanable/blood/old, first.dna.unique_enzymes)
	TEST_ASSERT(!blood.read_blood(user, old), "Засохшая кровь не читается.")
	TEST_ASSERT(findtext(blood.grasp_failure_reason, "Засохшая"), "Отказ называет засохшую кровь: [blood.grasp_failure_reason]")
	TEST_ASSERT_EQUAL(length(blood.signs), 0, "Засохшая кровь не становится меткой.")
	var/obj/effect/decal/cleanable/blood/stranger = blood_tide_stain(locate(origin.x + 2, origin.y + 1, origin.z), donor = "blood source nobody")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(blood.read_blood(user, stranger), "Кровь без живого владельца всё равно читается.")
	TEST_ASSERT(stranger in blood.signs, "Такая кровь тоже становится меткой.")
	TEST_ASSERT_EQUAL(user.has_status_effect(/datum/status_effect/heretic_blood_trail), trail, "Без владельца след не меняется.")

/// След держится 3 минуты и раз в 2 секунды называет сторону и примерную дальность до владельца; на другом уровне след уходит, у удалённого владельца обрывается.
/datum/unit_test/heretic_blood_trail/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/quarry = allocate(/mob/living/carbon/human, locate(origin.x + 4, origin.y, origin.z))
	var/datum/status_effect/heretic_blood_trail/trail = user.apply_status_effect(/datum/status_effect/heretic_blood_trail, quarry)
	TEST_ASSERT(abs(trail.duration - world.time - HERETIC_BLOOD_TRAIL_DURATION) < 1, "След держится 3 минуты.")
	TEST_ASSERT_EQUAL(trail.tick_interval, HERETIC_BLOOD_TRAIL_INTERVAL, "След обновляется раз в 2 секунды.")
	TEST_ASSERT(findtext(trail.trail_text, "рядом") && findtext(trail.trail_text, "на востоке"), "Близкий владелец рядом на востоке: [trail.trail_text]")
	TEST_ASSERT(findtext(trail.linked_alert.desc, "на востоке"), "Значок называет сторону: [trail.linked_alert.desc]")
	TEST_ASSERT_EQUAL(trail.linked_alert.dir, EAST, "Стрелка значка смотрит на владельца.")
	TEST_ASSERT_EQUAL(trail.linked_alert.icon_state, "blood_trail_close", "Близкий след рисуется своей стрелкой.")
	var/north = origin.y + 25 <= world.maxy
	quarry.forceMove(locate(origin.x, north ? origin.y + 12 : origin.y - 12, origin.z))
	trail.update_trail()
	TEST_ASSERT(findtext(trail.trail_text, "недалеко"), "На двенадцати клетках владелец недалеко: [trail.trail_text]")
	quarry.forceMove(locate(origin.x, north ? origin.y + 25 : origin.y - 25, origin.z))
	trail.update_trail()
	TEST_ASSERT(findtext(trail.trail_text, "далеко") && !findtext(trail.trail_text, "недалеко"), "На двадцати пяти клетках владелец далеко: [trail.trail_text]")
	TEST_ASSERT(findtext(trail.trail_text, north ? "на севере" : "на юге"), "Сторона сменилась: [trail.trail_text]")
	quarry.forceMove(locate(origin.x, origin.y, origin.z > 1 ? origin.z - 1 : origin.z + 1))
	trail.update_trail()
	TEST_ASSERT(findtext(trail.trail_text, "ушёл с уровня"), "На другом уровне след уходит: [trail.trail_text]")
	qdel(quarry)
	trail.update_trail()
	TEST_ASSERT(findtext(trail.trail_text, "оборвался"), "У удалённого владельца след обрывается: [trail.trail_text]")

/// Враг, ступивший в метку, пока еретик в пяти клетках без преград, связывается с 6 долга; своего должника метка пополняет на 6; раз в 10 секунд на метку; занятые связи, дальний еретик и антимагия ловушку не запускают.
/datum/unit_test/heretic_blood_sign_trap/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/origin = get_turf(user)
	var/turf/trap_turf = locate(origin.x + 5, origin.y, origin.z)
	var/turf/beside = locate(origin.x + 5, origin.y + 1, origin.z)
	var/obj/effect/decal/cleanable/blood/pool = blood_tide_stain(trap_turf, donor = "blood trap donor")
	user.a_intent = INTENT_HELP
	TEST_ASSERT(blood.read_blood(user, pool), "Пятно помечено.")
	var/datum/heretic_blood_sign/sign = blood.signs[pool]
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, beside)
	victim.forceMove(trap_turf)
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_NOTNULL(seal, "Ступивший в метку связан.")
	TEST_ASSERT_EQUAL(seal?.debt, HERETIC_BLOOD_TRAP_DEBT, "Метка даёт 6 долга.")
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(sign, trap_cooldown) - HERETIC_BLOOD_TRAP_COOLDOWN) <= world.tick_lag, "Метка перезаряжается 10 секунд.")
	victim.forceMove(beside)
	victim.forceMove(trap_turf)
	TEST_ASSERT_EQUAL(seal.debt, HERETIC_BLOOD_TRAP_DEBT, "Повторный шаг до конца перезарядки не срабатывает.")
	COOLDOWN_RESET(sign, trap_cooldown)
	victim.forceMove(beside)
	victim.forceMove(trap_turf)
	TEST_ASSERT_EQUAL(seal.debt, HERETIC_BLOOD_TRAP_DEBT * 2, "Своего должника метка пополняет на 6.")
	COOLDOWN_RESET(sign, trap_cooldown)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, locate(origin.x + 4, origin.y + 1, origin.z))
	second.forceMove(trap_turf)
	TEST_ASSERT_NULL(second.has_status_effect(/datum/status_effect/heretic_blood_seal), "При занятой связи метка никого не связывает.")
	TEST_ASSERT(COOLDOWN_FINISHED(sign, trap_cooldown), "Несработавшая метка не уходит на перезарядку.")
	qdel(seal)
	second.forceMove(beside)
	user.forceMove(locate(origin.x - 1, origin.y, origin.z))
	second.forceMove(trap_turf)
	TEST_ASSERT_NULL(second.has_status_effect(/datum/status_effect/heretic_blood_seal), "Еретик дальше пяти клеток ловушку не запускает.")
	user.forceMove(origin)
	second.forceMove(beside)
	var/datum/component/anti_magic/protection = second.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	second.forceMove(trap_turf)
	TEST_ASSERT_NULL(second.has_status_effect(/datum/status_effect/heretic_blood_seal), "Антимагия защищает от ловушки.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Ловушка не тратит заряды антимагии.")
	qdel(protection)
	second.forceMove(beside)
	second.forceMove(trap_turf)
	TEST_ASSERT_NOTNULL(second.has_status_effect(/datum/status_effect/heretic_blood_seal), "Без защиты и рядом с еретиком ловушка срабатывает.")

/// Кровопускание: отказы без связи, при долге меньше 16 и под антимагией; секунда предупреждения, затем 6 секунд поводок в три клетки, сбитая речь и до 15% крови; весь долг списан; досмотренное - обморок 10 секунд, цель готова к обряду и невосприимчива от пробуждения.
/datum/unit_test/heretic_blood_drain/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = blood_drain_heretic(locate(start.x + 1, start.y, start.z))
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/spell/blood_drain/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/blood_drain)
	var/obj/effect/proc_holder/spell/pointed/heretic_blood/drain/spell = knowledge.granted_spell
	TEST_ASSERT(istype(spell), "Знание выдаёт Кровопускание.")
	TEST_ASSERT_EQUAL(spell.charge_max, HERETIC_BLOOD_DRAIN_COOLDOWN, "Перезарядка 40 секунд.")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, locate(start.x + 3, start.y + 2, start.z))
	TEST_ASSERT(!blood.drain(user, stranger), "Несвязанную цель не обескровить.")
	TEST_ASSERT(findtext(blood.ability_failure, "должника"), "Отказ просит должника: [blood.ability_failure]")
	var/mob/living/carbon/human/victim = blood_debtor(blood, locate(start.x + 3, start.y, start.z), HERETIC_BLOOD_DRAIN_DEBT - 1)
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_NOTNULL(seal, "Цель связана.")
	TEST_ASSERT(!blood.drain(user, victim), "Долга меньше [HERETIC_BLOOD_DRAIN_DEBT] мало.")
	TEST_ASSERT(findtext(blood.ability_failure, "[HERETIC_BLOOD_DRAIN_DEBT] долга"), "Отказ называет долг: [blood.ability_failure]")
	seal.debt = HERETIC_BLOOD_DRAIN_DEBT + 4
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!blood.drain(user, victim), "Антимагия защищает от Кровопускания.")
	TEST_ASSERT(findtext(blood.ability_failure, "защищена от магии"), "Отказ называет антимагию: [blood.ability_failure]")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проверка не тратит заряды антимагии.")
	qdel(protection)
	TEST_ASSERT_EQUAL(seal.debt, HERETIC_BLOOD_DRAIN_DEBT + 4, "Отказы не тратят долг.")
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Должник выбирается.")
	TEST_ASSERT(blood.drain(user, victim), "Должник под Кровопусканием.")
	TEST_ASSERT_EQUAL(seal.debt, 0, "Долг списан целиком.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Индикатор долга обнулён.")
	var/datum/status_effect/heretic_blood_drain/drain = victim.has_status_effect(/datum/status_effect/heretic_blood_drain)
	TEST_ASSERT_NOTNULL(drain, "Цель под Кровопусканием.")
	TEST_ASSERT(!drain.channel_started, "Сначала только предупреждение.")
	TEST_ASSERT(abs(drain.channel_starts_at - world.time - HERETIC_BLOOD_DRAIN_TELEGRAPH) < 1, "Предупреждение длится секунду.")
	TEST_ASSERT_EQUAL(seal.seal_overlay.icon_state, "blood_warning", "Нить краснеет.")
	TEST_ASSERT(!blood.drain(user, victim), "Второе Кровопускание не накладывается.")
	TEST_ASSERT(step(victim, EAST) && step(victim, EAST), "Во время предупреждения цель ходит свободно.")
	TEST_ASSERT_EQUAL(get_dist(victim, user), 4, "Цель отошла на четыре клетки.")
	TEST_ASSERT(abs(timeleft(drain.channel_timer) - HERETIC_BLOOD_DRAIN_TELEGRAPH) < 1, "Кровь начинает уходить по таймеру через секунду: [timeleft(drain.channel_timer)] дс.")
	var/obj/item/radio/headset/echo_ring_probe/headset = allocate(/obj/item/radio/headset/echo_ring_probe)
	TEST_ASSERT(victim.equip_to_slot_if_possible(headset, ITEM_SLOT_EARS_LEFT), "Цель надевает гарнитуру.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_MUTE), "Во время предупреждения цель ещё говорит.")
	drain.start_channel()
	TEST_ASSERT(drain.channel_started, "После предупреждения кровь уходит.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_MUTE), "На время канала цель немеет полностью.")
	victim.say(";Помогите!", language = /datum/language/common, ignore_spam = TRUE)
	TEST_ASSERT_EQUAL(headset.transmissions, 0, "Немая цель не зовёт по рации.")
	TEST_ASSERT(SEND_SIGNAL(victim, COMSIG_MOVABLE_USING_RADIO, headset) & COMPONENT_CANNOT_USE_RADIO, "Рация глушится на время канала.")
	TEST_ASSERT_NULL(drain.channel_timer, "Таймер предупреждения снят.")
	TEST_ASSERT(abs(drain.duration - drain.channel_starts_at - HERETIC_BLOOD_DRAIN_DURATION) < 1, "Кровопускание длится 6 секунд: [drain.duration - drain.channel_starts_at] дс.")
	TEST_ASSERT(seal.expires_at >= drain.duration, "Связь переживает конец Кровопускания.")
	TEST_ASSERT(get_dist(victim, user) <= HERETIC_BLOOD_DRAIN_LEASH, "Нить подтянула цель на три клетки: [get_dist(victim, user)].")
	var/turf/held = get_turf(victim)
	TEST_ASSERT(!step(victim, EAST), "Дальше трёх клеток цель не уходит.")
	TEST_ASSERT_EQUAL(get_turf(victim), held, "Цель осталась на месте.")
	user.forceMove(start)
	TEST_ASSERT(get_dist(victim, user) <= HERETIC_BLOOD_DRAIN_LEASH, "Отошедший еретик тянет цель за собой: [get_dist(victim, user)].")
	TEST_ASSERT(abs(drain.drain_goal - BLOOD_VOLUME_NORMAL * HERETIC_BLOOD_DRAIN_FRACTION) <= DAMAGE_PRECISION, "За всё Кровопускание уходит 15% крови: [drain.drain_goal].")
	drain.channel_starts_at = world.time - HERETIC_BLOOD_DRAIN_DURATION / 2
	drain.tick()
	TEST_ASSERT(abs(drain.drained - drain.drain_goal / 2) <= 1, "За половину срока уходит половина: [drain.drained].")
	TEST_ASSERT(abs(victim.blood_volume - (BLOOD_VOLUME_NORMAL - drain.drained)) <= 3, "Кровь цели убывает: [victim.blood_volume].")
	drain.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(drain, 1 SECONDS), "Кровопускание заканчивается по сроку.")
	TEST_ASSERT(abs(victim.blood_volume - BLOOD_VOLUME_NORMAL * (1 - HERETIC_BLOOD_DRAIN_FRACTION)) <= 3, "Итог - минус 15% крови: [victim.blood_volume].")
	TEST_ASSERT(victim.blood_volume >= BLOOD_VOLUME_SAFE, "Полная кровь не опускается ниже безопасного уровня: [victim.blood_volume].")
	TEST_ASSERT(victim.IsUnconscious(), "Цель в обмороке.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_MUTE), "После канала немота снята.")
	TEST_ASSERT(!(SEND_SIGNAL(victim, COMSIG_MOVABLE_USING_RADIO, headset) & COMPONENT_CANNOT_USE_RADIO), "После канала рация снова работает.")
	TEST_ASSERT(abs(victim.AmountUnconscious() - HERETIC_BLOOD_DRAIN_FAINT) < 1 SECONDS, "Обморок 10 секунд: [victim.AmountUnconscious()] дс.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Цель в обмороке готова к обряду.")
	TEST_ASSERT(victim.stat != DEAD, "Кровопускание не убивает.")
	TEST_ASSERT(!QDELETED(seal), "Связь пережила Кровопускание.")
	TEST_ASSERT_EQUAL(seal.seal_overlay.icon_state, "blood_mark", "Нить снова обычная.")
	var/datum/status_effect/heretic_capture_immunity/immunity = capture_immunity(victim, "blood")
	TEST_ASSERT(abs(immunity?.duration - world.time - victim.AmountUnconscious() - HERETIC_CAPTURE_IMMUNITY) < 1, "Минута невосприимчивости отсчитывается от пробуждения: [immunity?.duration - world.time] дс.")
	var/reason = heretic_capture_block_reason(user, victim, "sand")
	TEST_ASSERT(findtext(reason, "осталось [(HERETIC_BLOOD_DRAIN_FAINT + HERETIC_CAPTURE_SHARED_IMMUNITY) / (1 SECONDS)] с"), "Общая передышка тоже от пробуждения: [reason]")
	seal.debt = HERETIC_BLOOD_DRAIN_DEBT
	TEST_ASSERT(!blood.drain(user, victim), "Невосприимчивую цель не обескровить.")
	TEST_ASSERT(findtext(blood.ability_failure, "приходит в себя"), "Отказ называет невосприимчивость: [blood.ability_failure]")

/// Кровопускание обрывают стена, дальность, антимагия, нулевой жезл, переливание крови, оглушение еретика, начало обряда и смерть еретика: без обморока, с минутой невосприимчивости.
/datum/unit_test/heretic_blood_drain_breaks/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = blood_drain_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/victim_turf = locate(start.x + 2, start.y, start.z)
	for(var/method in list("стена", "дальность", "антимагия", "нулевой жезл", "переливание", "оглушение", "обряд", "смерть еретика"))
		var/mob/living/carbon/human/victim = blood_debtor(blood, victim_turf)
		TEST_ASSERT(blood.drain(user, victim), "Кровопускание начато ([method]).")
		var/datum/status_effect/heretic_blood_drain/drain = victim.has_status_effect(/datum/status_effect/heretic_blood_drain)
		drain.start_channel()
		TEST_ASSERT(drain.channel_started, "Кровь уходит ([method]).")
		var/obj/blocker
		var/datum/component/anti_magic/protection
		switch(method)
			if("стена")
				blocker = allocate(/obj, get_step(user, EAST))
				blocker.density = TRUE
				drain.tick()
			if("дальность")
				victim.forceMove(locate(start.x + 6, start.y, start.z))
				drain.tick()
			if("антимагия")
				protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
				drain.tick()
			if("нулевой жезл")
				var/mob/living/carbon/human/chaplain = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y + 1, start.z))
				var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
				chaplain.put_in_hands(rod)
				rod.melee_attack_chain(chaplain, victim)
				TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Жезл не бьёт цель.")
				qdel(chaplain)
			if("переливание")
				victim.blood_volume += 20
				drain.tick()
			if("оглушение")
				user.Stun(1 SECONDS)
				drain.tick()
			if("обряд")
				drain.duration = world.time - 1
				SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING)
			if("смерть еретика")
				blood.on_death(user)
		TEST_ASSERT(QDELETED(drain), "Кровопускание обрывается: [method].")
		TEST_ASSERT(!victim.IsUnconscious(), "После срыва ([method]) обморока нет.")
		TEST_ASSERT_NOTNULL(capture_immunity(victim, "blood"), "После срыва ([method]) цель минуту невосприимчива.")
		qdel(blocker)
		qdel(protection)
		user.SetStun(0)
		qdel(victim)

/// Кровопускание не опускает кровь ниже безопасного уровня, даже если цель истекает кровью во время захвата: обескровленная цель не теряет ничего, но падает в обморок; кровь не пускают у не-людей и бескровных.
/datum/unit_test/heretic_blood_drain_floor/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = blood_drain_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	for(var/list/scenario in list(list(-112, -112), list(20, 20), list(20, 5)))
		var/surplus = scenario[1]
		var/bled_surplus = scenario[2]
		var/mob/living/carbon/human/victim = blood_debtor(blood, locate(start.x + 2, start.y, start.z))
		victim.blood_volume = BLOOD_VOLUME_SAFE + surplus
		TEST_ASSERT(blood.drain(user, victim), "Кровопускание начато при запасе [surplus].")
		var/datum/status_effect/heretic_blood_drain/drain = victim.has_status_effect(/datum/status_effect/heretic_blood_drain)
		drain.start_channel()
		TEST_ASSERT(abs(drain.drain_goal - max(0, surplus)) <= DAMAGE_PRECISION, "Уходит только кровь выше безопасного уровня: [drain.drain_goal].")
		victim.blood_volume = BLOOD_VOLUME_SAFE + bled_surplus
		drain.duration = world.time
		TEST_ASSERT(wait_for_qdeleted(drain, 1 SECONDS), "Кровопускание заканчивается.")
		TEST_ASSERT(victim.blood_volume >= min(BLOOD_VOLUME_SAFE, BLOOD_VOLUME_SAFE + bled_surplus) - DAMAGE_PRECISION, "Кровь не ниже безопасного уровня при запасе [surplus] и [bled_surplus] после кровотечения: [victim.blood_volume].")
		if(surplus < 0)
			TEST_ASSERT(victim.blood_volume <= BLOOD_VOLUME_SAFE + surplus + 3, "Обескровленная цель не теряет кровь: [victim.blood_volume].")
		TEST_ASSERT(victim.stat != DEAD, "Цель жива.")
		TEST_ASSERT(victim.IsUnconscious(), "Цель в обмороке.")
		qdel(victim)
	var/mob/living/carbon/monkey/monkey = allocate(/mob/living/carbon/monkey, locate(start.x + 2, start.y + 1, start.z))
	TEST_ASSERT(blood.release(user, monkey), "Обезьяна связана.")
	var/datum/status_effect/heretic_blood_seal/monkey_seal = monkey.has_status_effect(/datum/status_effect/heretic_blood_seal)
	monkey_seal.debt = HERETIC_BLOOD_DRAIN_DEBT
	TEST_ASSERT(!blood.drain(user, monkey), "Не-человека не обескровить.")
	TEST_ASSERT(findtext(blood.ability_failure, "нет крови"), "Отказ называет кровь: [blood.ability_failure]")
	qdel(monkey)
	var/mob/living/carbon/human/skeleton = blood_debtor(blood, locate(start.x + 2, start.y, start.z))
	skeleton.set_species(/datum/species/skeleton)
	TEST_ASSERT(!blood.drain(user, skeleton), "Бескровного не обескровить.")
	TEST_ASSERT(findtext(blood.ability_failure, "нет крови"), "Отказ бескровному называет кровь: [blood.ability_failure]")
	TEST_ASSERT_NULL(skeleton.has_status_effect(/datum/status_effect/heretic_blood_drain), "Отказ не накладывает Кровопускание.")

/// Нить не тянет цель на клетку без опоры: у космоса подтягивание останавливается, на полу продолжается.
/datum/unit_test/heretic_blood_drain_safe_pull/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = blood_drain_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/far_spot = locate(start.x + 4, start.y, start.z)
	var/mob/living/carbon/human/victim = blood_debtor(blood, far_spot)
	TEST_ASSERT(blood.drain(user, victim), "Кровопускание начато.")
	var/datum/status_effect/heretic_blood_drain/drain = victim.has_status_effect(/datum/status_effect/heretic_blood_drain)
	var/turf/gap = locate(start.x + 3, start.y, start.z)
	var/previous_type = gap.type
	gap = gap.ChangeTurf(/turf/open/space)
	drain.start_channel()
	var/stayed = get_turf(victim) == far_spot
	var/still_draining = !QDELETED(drain) && drain.channel_started
	gap = gap.ChangeTurf(previous_type)
	TEST_ASSERT(still_draining, "Космос на линии не рвёт связь.")
	TEST_ASSERT(stayed, "Нить не тянет цель в космос.")
	drain.pull_close()
	TEST_ASSERT_EQUAL(get_dist(victim, user), HERETIC_BLOOD_DRAIN_LEASH, "На полу нить подтягивает цель на три клетки.")

/// Хоткей Скользкой крови срабатывает в агрессивном захвате, а адресная способность в захвате по-прежнему отказывает по своим правилам.
/datum/unit_test/heretic_blood_slip_hotkey/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_slip)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.collect_combat_spells(list())
	var/slip_slot = heretic.ability_hotkey_types.Find(/obj/effect/proc_holder/spell/self/heretic_blood/slip)
	var/release_slot = heretic.ability_hotkey_types.Find(/obj/effect/proc_holder/spell/pointed/heretic_blood/release)
	TEST_ASSERT(slip_slot && release_slot, "У Скользкой крови и основной способности есть слоты.")
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human, get_step(user, EAST))
	grabber.start_pulling(user)
	grabber.setGrabState(GRAB_AGGRESSIVE)
	TEST_ASSERT(user.incapacitated(), "Агрессивный захват сковывает еретика.")
	var/obj/effect/proc_holder/spell/pointed/heretic_blood/release/release = blood.combat_power
	TEST_ASSERT(user.activate_ability_hotkey(release_slot), "Хоткей основной способности обработан.")
	TEST_ASSERT(user.ranged_ability != release, "Адресная способность в захвате не готовится: её собственные условия не пускают.")
	TEST_ASSERT_EQUAL(release.charge_counter, release.charge_max, "Отказ не тратит заряд.")
	TEST_ASSERT(user.activate_ability_hotkey(slip_slot), "Хоткей Скользкой крови обработан.")
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_blood_slip), "В захвате хоткей применяет Скользкую кровь.")
	TEST_ASSERT_NULL(user.pulledby, "Хоткей Скользкой крови разрывает захват.")

/// Скользкая кровь: за 10 ушибов и в чужой хватке вырывает из агрессивного захвата и не даёт схватить заново 5 секунд, ускоряет и оставляет след, на котором бегущий враг падает, а сам еретик и идущий шагом - нет; в наручниках отказ; перезарядка 30 секунд.
/datum/unit_test/heretic_blood_slip/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_slip)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/spell/blood_slip/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/blood_slip)
	var/obj/effect/proc_holder/spell/self/heretic_blood/slip/spell = knowledge.granted_spell
	TEST_ASSERT(istype(spell), "Знание выдаёт Скользкую кровь.")
	TEST_ASSERT_EQUAL(spell.charge_max, HERETIC_BLOOD_SLIP_COOLDOWN, "Перезарядка 30 секунд.")
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human, locate(start.x + 1, start.y, start.z))
	grabber.start_pulling(user)
	TEST_ASSERT_EQUAL(user.pulledby, grabber, "Стражник хватает еретика.")
	grabber.setGrabState(GRAB_AGGRESSIVE)
	TEST_ASSERT(user.incapacitated(), "Агрессивный захват сковывает еретика.")
	TEST_ASSERT(spell.can_cast(user, FALSE, TRUE), "Скользкая кровь доступна в чужой хватке.")
	TEST_ASSERT(blood.slip(user), "Еретик выскальзывает.")
	TEST_ASSERT(abs(user.getBruteLoss() - HERETIC_BLOOD_SLIP_PAYMENT) <= DAMAGE_PRECISION, "Скользкая кровь стоит 10 ушибов.")
	TEST_ASSERT_NULL(user.pulledby, "Захват разорван.")
	TEST_ASSERT_NULL(grabber.pulling, "Стражник больше никого не держит.")
	var/datum/status_effect/heretic_blood_slip/slip = user.has_status_effect(/datum/status_effect/heretic_blood_slip)
	TEST_ASSERT(abs(slip.duration - world.time - HERETIC_BLOOD_SLIP_DURATION) < 1, "Скользкая кровь длится 5 секунд.")
	grabber.start_pulling(user)
	TEST_ASSERT_NULL(user.pulledby, "Скользкого еретика не схватить заново.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_slip), "Еретик бежит быстрее.")
	heretic_test_area(start, /area/unit_test_blood_slick)
	var/turf/north = locate(start.x, start.y + 1, start.z)
	user.forceMove(north)
	var/obj/effect/heretic_blood_slick/slick = locate() in start
	TEST_ASSERT_NOTNULL(slick, "За еретиком тянется скользкая кровь.")
	TEST_ASSERT(abs(timeleft(slick.expiry_timer) - HERETIC_BLOOD_SLICK_LIFETIME) <= world.tick_lag, "Скользкая кровь впитывается через 10 секунд.")
	var/mob/living/carbon/human/walker = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y, start.z))
	walker.m_intent = MOVE_INTENT_WALK
	walker.forceMove(start)
	TEST_ASSERT(!heretic_capture_downed(walker), "Идущий шагом по следу не падает.")
	walker.forceMove(locate(start.x + 2, start.y, start.z))
	var/mob/living/carbon/human/runner = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y + 1, start.z))
	runner.m_intent = MOVE_INTENT_RUN
	runner.combat_flags |= COMBAT_FLAG_SPRINT_ACTIVE
	runner.forceMove(start)
	TEST_ASSERT(heretic_capture_downed(runner), "Бегущий враг падает на скользкой крови.")
	user.m_intent = MOVE_INTENT_RUN
	user.combat_flags |= COMBAT_FLAG_SPRINT_ACTIVE
	user.forceMove(start)
	TEST_ASSERT(!heretic_capture_downed(user), "Сам еретик на своём следе не скользит.")
	slip.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(slip, 1 SECONDS), "Скользкая кровь заканчивается по сроку.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_blood_slip), "Ускорение снято.")
	grabber.start_pulling(user)
	TEST_ASSERT_EQUAL(user.pulledby, grabber, "После срока еретика снова можно схватить.")
	grabber.stop_pulling()
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(!blood.slip(user), "В наручниках Скользкая кровь недоступна.")
	TEST_ASSERT(findtext(blood.ability_failure, "наручниках"), "Отказ называет наручники: [blood.ability_failure]")
	TEST_ASSERT(!spell.can_cast(user, FALSE, TRUE), "Кнопка в наручниках не срабатывает.")
	user.uncuff()

/// Дверь Крови: цель в обмороке от своего Кровопускания клик «Помощи» не будит, изнанка принимает её, хоть общая передышка захватов идёт, а 2 секунды растолкать приводят в себя; готовая цель - только на крови; выходы - свои метки, стёртые не в счёт.
/datum/unit_test/heretic_blood_pocket_door/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = blood_drain_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	victim.blood_volume = BLOOD_VOLUME_NORMAL
	TEST_ASSERT_NULL(blood.pocket_door(user, victim), "Стоящую цель Кровь не уводит.")
	TEST_ASSERT(blood.release(user, victim), "Цель связана кровью.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.debt = HERETIC_BLOOD_DRAIN_DEBT
	blood.update_debt()
	TEST_ASSERT(blood.drain(user, victim), "Должник под Кровопусканием.")
	var/datum/status_effect/heretic_blood_drain/drain = victim.has_status_effect(/datum/status_effect/heretic_blood_drain)
	drain.start_channel()
	drain.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(drain, 1 SECONDS), "Кровопускание досмотрено.")
	TEST_ASSERT(victim.IsUnconscious(), "Цель в обмороке.")
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, get_step(spot, NORTH))
	var/faint_left = victim.AmountUnconscious()
	victim.help_shake_act(helper)
	helper.forceMove(get_step(helper, EAST))
	TEST_ASSERT(victim.IsUnconscious() && victim.AmountUnconscious() >= faint_left - 1, "Клик «Помощи» не укорачивает обморок: [victim.AmountUnconscious()] дс.")
	TEST_ASSERT_NULL(locate(/obj/effect/decal/cleanable/blood) in spot, "Под целью нет крови.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "sand"), "другого захвата"), "Общая передышка захватов идёт.")
	var/list/door = blood.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Цель в обмороке от своего Кровопускания Кровь уводит.")
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Изнанка принимает цель в обмороке, несмотря на передышку.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	TEST_ASSERT(victim.IsUnconscious(), "В изнанке цель без сознания.")
	heretic.pocket.collapse("проверка")
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, helper)
	TEST_ASSERT(!victim.IsUnconscious(), "Растолканная цель приходит в себя.")

	var/turf/clean_spot = get_step(user, NORTH)
	var/mob/living/carbon/human/cuffed = allocate(/mob/living/carbon/human, clean_spot)
	cuffed.handcuffed = allocate(/obj/item/restraints/handcuffs, cuffed)
	cuffed.update_handcuffed()
	TEST_ASSERT(heretic.hunt_target_ready(cuffed), "Скованная цель готова к обряду.")
	TEST_ASSERT_NULL(blood.pocket_door(user, cuffed), "Готовую цель на чистом полу Кровь не уводит.")
	allocated += blood_tide_stain(clean_spot)
	TEST_ASSERT_NOTNULL(blood.pocket_door(user, cuffed), "Готовую цель на крови Кровь уводит.")

	var/turf/sign_spot = locate(start.x + 4, start.y + 4, start.z)
	var/obj/effect/decal/cleanable/blood/pool = blood_tide_stain(sign_spot)
	allocated += pool
	TEST_ASSERT(blood.mark_sign(user, pool), "Пятно стало меткой.")
	var/list/exits = blood.pocket_exits(user)
	TEST_ASSERT_EQUAL(length(exits), 1, "Выход - своя метка.")
	TEST_ASSERT(findtext(exits[1], "Кровь - "), "Выход подписан кровью и отделом: [exits[1]]")
	TEST_ASSERT_EQUAL(exits[exits[1]], sign_spot, "Выход у своей метки.")
	blood.unmark_sign(pool)
	TEST_ASSERT_EQUAL(length(blood.pocket_exits(user)), 0, "Стёртая метка больше не выход.")

/datum/status_effect/heretic_blood_seal/warn_probe
	var/warnings = 0

/datum/status_effect/heretic_blood_seal/warn_probe/warn_owner(datum/eldritch_knowledge/base_blood/blood)
	warnings++
	return ..()

/datum/unit_test/proc/blood_minded_victim(turf/place)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, place)
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	return victim

/// После полного взыскания или разрыва контакта пустая печать 15 секунд помнит, сколько вылечено с цели: связь и удар клинком по ней продлевают печать, лечение с цели не больше 10; по сроку печать уходит; цель без разума не лечит ни взысканием, ни чашей.
/datum/unit_test/heretic_blood_spent_seal/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/victim = blood_minded_victim(get_step(user, EAST))
	user.adjustBruteLoss(60)
	var/healed_total = 0
	var/datum/status_effect/heretic_blood_seal/first
	for(var/cycle in 1 to 3)
		TEST_ASSERT(blood.release(user, victim), "Цель связана, круг [cycle].")
		var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
		first ||= seal
		TEST_ASSERT_EQUAL(seal, first, "Связь с той же целью - прежняя печать, круг [cycle].")
		TEST_ASSERT(!seal.spent && (seal in blood.seals), "Продлённая печать снова занимает связь.")
		seal.debt = blood.debt_cap
		blood.update_debt()
		var/brute_before = user.getBruteLoss()
		TEST_ASSERT(blood.release(user, victim), "Взыскание начато, круг [cycle].")
		seal.collection_ready_at = world.time
		TEST_ASSERT(seal.detonate(), "Взыскание завершено, круг [cycle].")
		healed_total += brute_before - user.getBruteLoss()
		TEST_ASSERT(!QDELETED(seal) && seal.spent, "После полного взыскания остаётся пустая печать.")
		TEST_ASSERT(!(seal in blood.seals) && (seal in blood.spent_seals), "Пустая печать не занимает связь.")
		TEST_ASSERT(abs(seal.expires_at - world.time - HERETIC_BLOOD_SPENT_LIFETIME) < 1, "Пустая печать живёт [HERETIC_BLOOD_SPENT_LIFETIME / (1 SECONDS)] секунд.")
	TEST_ASSERT(victim.getBruteLoss() > 100, "Урон взысканием остаётся каждый круг: [victim.getBruteLoss()].")
	TEST_ASSERT(abs(healed_total - 10) <= DAMAGE_PRECISION, "С одной цели лечится не больше 10 за все круги: [healed_total].")
	TEST_ASSERT_EQUAL(HERETIC_BLOOD_SPENT_LIFETIME, 15 SECONDS, "Пустая печать держится 15 секунд.")
	victim.fully_heal()
	TEST_ASSERT(blood.release(user, victim) && !first.spent, "Пустая печать снова стала связью.")
	first.contact_lost_at = world.time - HERETIC_BLOOD_CONTACT_GRACE
	TEST_ASSERT(!first.validate_link(), "Без контакта 2 секунды связь рвётся.")
	TEST_ASSERT(!QDELETED(first) && first.spent, "Разорванная связь, с которой лечились, остаётся пустой печатью.")
	TEST_ASSERT(first.siphoned >= 10, "Разрыв контакта не обнуляет вылеченное с цели: [first.siphoned].")
	TEST_ASSERT(abs(first.expires_at - world.time - HERETIC_BLOOD_SPENT_LIFETIME) < 1, "После разрыва печать помнит цель [HERETIC_BLOOD_SPENT_LIFETIME / (1 SECONDS)] секунд.")
	COOLDOWN_RESET(blood, resource_harvest)
	blood.on_eldritch_blade(victim, user, TRUE, null)
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/heretic_blood_seal), first, "Удар клинком продлевает пустую печать, а не создаёт новую связь.")
	TEST_ASSERT(!first.spent && first.debt == 16, "Продлённая ударом печать получает долг новой связи и удара: [first.debt].")
	TEST_ASSERT(first.siphoned >= 10, "Счётчик лечения с цели сохранён: [first.siphoned].")
	first.debt = blood.debt_cap
	var/brute_capped = user.getBruteLoss()
	TEST_ASSERT(blood.release(user, victim), "Взыскание начато.")
	first.collection_ready_at = world.time
	TEST_ASSERT(first.detonate() && first.spent, "Печать снова пуста.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), brute_capped, "После разрыва и новой связи предел лечения с цели всё ещё исчерпан.")
	first.expires_at = world.time
	first.tick()
	TEST_ASSERT(QDELETED(first), "По сроку пустая печать уходит.")
	TEST_ASSERT(blood.release(user, victim), "Через 15 секунд цель связывается заново.")
	var/datum/status_effect/heretic_blood_seal/fresh = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(fresh != first && fresh.siphoned == 0, "Новая связь начинает счёт лечения заново.")
	qdel(fresh)
	var/datum/status_effect/heretic_blood_seal/warn_probe/probe = victim.apply_status_effect(/datum/status_effect/heretic_blood_seal/warn_probe, blood)
	TEST_ASSERT_EQUAL(probe?.warnings, 1, "Новая связь предупреждает цель о кровяной жиле.")
	probe.spend()
	TEST_ASSERT(probe.revive(10), "Пустая печать снова стала связью.")
	TEST_ASSERT_EQUAL(probe.warnings, 2, "Возвращённая связь снова предупреждает цель о кровяной жиле.")
	qdel(probe)

	var/mob/living/carbon/human/mindless = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	user.blood_volume = BLOOD_VOLUME_NORMAL - 40
	user.integrating_blood = 0
	TEST_ASSERT(blood.release(user, mindless), "Цель без разума связывается.")
	var/datum/status_effect/heretic_blood_seal/empty = mindless.has_status_effect(/datum/status_effect/heretic_blood_seal)
	empty.debt = blood.debt_cap
	blood.update_debt()
	var/brute_before = user.getBruteLoss()
	TEST_ASSERT(blood.release(user, mindless), "Взыскание с цели без разума начато.")
	empty.collection_ready_at = world.time
	TEST_ASSERT(empty.detonate(), "Взыскание с цели без разума завершено.")
	TEST_ASSERT(mindless.getBruteLoss() > 0, "Цель без разума получает урон.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), brute_before, "Цель без разума не лечит.")
	TEST_ASSERT_EQUAL(user.blood_volume, BLOOD_VOLUME_NORMAL - 40, "Цель без разума не восполняет кровь.")
	qdel(empty)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_relic)
	TEST_ASSERT(blood.release(user, mindless), "Цель без разума связана снова.")
	TEST_ASSERT(!blood.refund(user, mindless), "Чаша не пьёт из цели без разума.")
	var/datum/status_effect/heretic_blood_seal/kept = mindless.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_EQUAL(kept.debt, 10, "Отказ чаши не тратит 10 долга новой связи: [kept.debt].")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), brute_before, "Отказ чаши не лечит.")

/// Дверь Крови открывается со второй секунды Кровопускания, если еретик в трёх клетках; в изнанке связь цела, цель немая, и канал доигрывает до обморока внутри.
/datum/unit_test/heretic_blood_pocket_drain/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = blood_drain_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, locate(start.x + 2, start.y, start.z))
	victim.blood_volume = BLOOD_VOLUME_NORMAL
	TEST_ASSERT(blood.release(user, victim), "Цель связана кровью.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.debt = HERETIC_BLOOD_DRAIN_DEBT
	blood.update_debt()
	TEST_ASSERT(blood.drain(user, victim), "Должник под Кровопусканием.")
	var/datum/status_effect/heretic_blood_drain/drain = victim.has_status_effect(/datum/status_effect/heretic_blood_drain)
	TEST_ASSERT_NULL(blood.pocket_door(user, victim), "В начале Кровопускания двери нет.")
	drain.start_channel()
	TEST_ASSERT_NULL(blood.pocket_door(user, victim), "До второй секунды двери нет.")
	drain.started_at = world.time - HERETIC_BLOOD_DRAIN_DOOR_DELAY
	TEST_ASSERT_EQUAL(HERETIC_BLOOD_DRAIN_DOOR_DELAY, 2 SECONDS, "Дверь открывается со второй секунды.")
	TEST_ASSERT_EQUAL(HERETIC_BLOOD_DRAIN_DOOR_RANGE, 3, "Еретику хватает трёх клеток.")
	TEST_ASSERT_NOTNULL(blood.pocket_door(user, victim), "Со второй секунды цель в двух клетках уводится.")
	victim.forceMove(locate(start.x + HERETIC_BLOOD_DRAIN_DOOR_RANGE + 1, start.y, start.z))
	TEST_ASSERT_NULL(blood.pocket_door(user, victim), "Дальше трёх клеток двери нет.")
	victim.forceMove(locate(start.x + HERETIC_BLOOD_DRAIN_DOOR_RANGE, start.y, start.z))
	var/list/door = blood.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "В трёх клетках дверь есть.")
	TEST_ASSERT(heretic.pocket_pull(user, victim, get_turf(victim), door["time"], door["check"], door["text"]), "Дверь Крови уводит цель посреди канала.")
	TEST_ASSERT(heretic.pocket_holds(victim) && heretic.pocket.contains(user), "Еретик и цель в изнанке.")
	TEST_ASSERT(!QDELETED(seal) && seal.validate_link(), "В изнанке кровная связь цела.")
	var/turf/inside = get_turf(user)
	user.forceMove(start)
	TEST_ASSERT(seal.validate_link(), "Пока цель в изнанке, связь цела и с еретиком по ту сторону стены.")
	user.forceMove(inside)
	TEST_ASSERT(!QDELETED(drain), "Кровопускание продолжается в изнанке.")
	TEST_ASSERT(HAS_TRAIT(victim, TRAIT_MUTE), "В изнанке цель по-прежнему немая.")
	drain.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(drain, 1 SECONDS), "Кровопускание досмотрено в изнанке.")
	TEST_ASSERT(victim.IsUnconscious(), "Цель падает в обморок в изнанке.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в обмороке остаётся в изнанке.")
	heretic.pocket.collapse("проверка")

/// Пустая печать одного еретика не мешает другому еретику связать ту же цель.
/datum/unit_test/heretic_blood_spent_seal_foreign/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/victim = blood_minded_victim(get_step(user, EAST))
	user.adjustBruteLoss(20)
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Взыскание начато.")
	var/datum/status_effect/heretic_blood_seal/spent = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	spent.collection_ready_at = world.time
	TEST_ASSERT(spent.detonate() && spent.spent, "После взыскания на цели пустая печать.")
	var/datum/antagonist/heretic/rival = allocate_heretic(get_step(victim, EAST))
	rival.selected_path = PATH_BLOOD
	rival.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/base_blood/rival_blood = rival.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/obj/effect/proc_holder/spell/pointed/heretic_blood/release/spell = rival_blood.combat_power
	TEST_ASSERT(spell.can_target(victim, rival.owner.current, TRUE), "Чужая пустая печать не мешает выбрать цель.")
	TEST_ASSERT(rival_blood.release(rival.owner.current, victim), "Другой еретик связывает цель поверх чужой пустой печати.")
	var/datum/status_effect/heretic_blood_seal/rival_seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(rival_seal != spent && rival_seal.blood_ref?.resolve() == rival_blood && !rival_seal.spent, "На цели связь другого еретика.")
	TEST_ASSERT(!length(blood.spent_seals), "Пустая печать первого еретика снята.")

/// В изнанке оглушение еретика по-прежнему рвёт Кровопускание и взыскание: пропускаются только дальность и линия.
/datum/unit_test/heretic_blood_pocket_stun/Run()
	var/turf/start = run_loc_floor_bottom_left
	allocated += new /datum/heretic_test_station_level(start.z)
	var/datum/antagonist/heretic/heretic = blood_drain_heretic(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, locate(start.x + 2, start.y, start.z))
	victim.blood_volume = BLOOD_VOLUME_NORMAL
	TEST_ASSERT(blood.release(user, victim), "Цель связана кровью.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.debt = HERETIC_BLOOD_DRAIN_DEBT
	blood.update_debt()
	TEST_ASSERT(blood.drain(user, victim), "Должник под Кровопусканием.")
	var/datum/status_effect/heretic_blood_drain/drain = victim.has_status_effect(/datum/status_effect/heretic_blood_drain)
	drain.start_channel()
	drain.started_at = world.time - HERETIC_BLOOD_DRAIN_DOOR_DELAY
	var/list/door = blood.pocket_door(user, victim)
	TEST_ASSERT(heretic.pocket_pull(user, victim, get_turf(victim), door["time"], door["check"], door["text"]), "Дверь Крови уводит цель посреди канала.")
	TEST_ASSERT(!QDELETED(drain), "В изнанке Кровопускание идёт.")
	user.Stun(2 SECONDS)
	drain.tick()
	TEST_ASSERT(QDELETED(drain), "Оглушение еретика в изнанке рвёт Кровопускание.")
	TEST_ASSERT(!victim.IsUnconscious(), "Сорванное Кровопускание не роняет в обморок.")
	user.SetStun(0)
	TEST_ASSERT(seal.validate_link(), "Очнувшийся за 2 секунды еретик возвращает связь.")
	seal.debt = HERETIC_BLOOD_DRAIN_DEBT
	TEST_ASSERT(blood.release(user, victim) && seal.collecting, "В изнанке взыскание начинается.")
	user.Stun(2 SECONDS)
	TEST_ASSERT(!seal.validate_link() && !seal.collecting, "Оглушение еретика в изнанке срывает взыскание.")
	user.SetStun(0)
	heretic.pocket.collapse("проверка")

/// Во время паузы дела пятно с кровью нескольких людей читается по уже прочитанному человеку, а новый ждёт конца паузы.
/datum/unit_test/heretic_blood_mixed_pool_pause/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y, origin.z))
	first.dna.unique_enzymes = "mixed pool first"
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y + 3, origin.z))
	second.dna.unique_enzymes = "mixed pool second"
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife, origin)
	knife.add_mob_blood(first)
	TEST_ASSERT(blood.read_blood(user, knife), "Кровь первого человека прочитана.")
	var/progress = heretic.deed.progress
	var/obj/effect/decal/cleanable/blood/pool = blood_tide_stain(locate(origin.x + 1, origin.y, origin.z), donor = second.dna.unique_enzymes)
	var/list/first_signature = list()
	first_signature[first.dna.unique_enzymes] = "O+"
	pool.add_blood_DNA(first_signature)
	TEST_ASSERT(blood.read_blood(user, pool), "Во время паузы смешанное пятно читается: [blood.grasp_failure_reason]")
	var/datum/status_effect/heretic_blood_trail/trail = user.has_status_effect(/datum/status_effect/heretic_blood_trail)
	TEST_ASSERT_EQUAL(trail?.quarry_ref?.resolve(), first, "След ведёт к уже прочитанному человеку.")
	TEST_ASSERT(!(second.dna.unique_enzymes in heretic.deed.counted_keys), "Новый человек во время паузы не засчитан.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, progress, "Пауза не продвигает дело.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(blood.read_blood(user, pool), "После паузы то же пятно читается.")
	TEST_ASSERT(second.dna.unique_enzymes in heretic.deed.counted_keys, "После паузы новый человек засчитан.")

/datum/unit_test/heretic_blood_cap_survives_death/proc/collect_all(datum/eldritch_knowledge/base_blood/blood, mob/living/user, mob/living/victim, datum/status_effect/heretic_blood_seal/seal)
	seal.debt = blood.debt_cap
	blood.update_debt()
	if(!blood.release(user, victim))
		return FALSE
	seal.collection_ready_at = world.time
	return seal.detonate()

/// Предел лечения с цели переживает смерть и оживление цели, смену тела и смерть еретика: печать пустеет, а не пропадает.
/datum/unit_test/heretic_blood_cap_survives_death/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/carbon/human/victim = blood_minded_victim(get_step(user, EAST))
	user.adjustBruteLoss(60)
	TEST_ASSERT(blood.release(user, victim), "Цель связана.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	victim.adjustOxyLoss(victim.health - HEALTH_THRESHOLD_DEAD - 20)
	TEST_ASSERT(victim.stat != DEAD, "До взыскания цель жива.")
	var/brute_before = user.getBruteLoss()
	TEST_ASSERT(collect_all(blood, user, victim, seal), "Взыскание завершено.")
	TEST_ASSERT(victim.stat == DEAD, "Взыскание добило цель: здоровье [victim.health], ушибы [victim.getBruteLoss()], удушье [victim.getOxyLoss()].")
	TEST_ASSERT(!QDELETED(seal) && seal.spent, "Смерть должника оставляет пустую печать.")
	var/healed = brute_before - user.getBruteLoss()
	TEST_ASSERT(healed > 0 && abs(seal.siphoned - healed) <= DAMAGE_PRECISION, "Пустая печать помнит лечение с добивающего удара: [seal.siphoned] из [healed].")
	seal.tick()
	TEST_ASSERT(!QDELETED(seal), "На трупе пустая печать доживает свой срок.")
	victim.revive(full_heal = TRUE)
	TEST_ASSERT(blood.release(user, victim), "Оживлённая цель связывается снова.")
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/heretic_blood_seal), seal, "Связь с оживлённой целью - прежняя печать.")
	brute_before = user.getBruteLoss()
	TEST_ASSERT(collect_all(blood, user, victim, seal), "Взыскание с оживлённой цели завершено.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), brute_before, "Смерть и оживление цели не обнуляют предел лечения.")
	victim.fully_heal()
	TEST_ASSERT(blood.release(user, victim) && !seal.spent, "Цель связана перед сменой тела.")
	blood.clear_blood()
	TEST_ASSERT(!QDELETED(seal) && seal.spent, "Смена тела еретика оставляет пустую печать.")
	TEST_ASSERT(blood.release(user, victim) && !seal.spent, "После смены тела та же печать снова становится связью.")
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT(!QDELETED(seal) && seal.spent, "Смерть еретика оставляет пустую печать.")
	user.revive(full_heal = TRUE)
	user.adjustBruteLoss(40)
	TEST_ASSERT(blood.release(user, victim), "Оживлённый еретик связывает цель снова.")
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/heretic_blood_seal), seal, "Связь после смерти еретика - прежняя печать.")
	brute_before = user.getBruteLoss()
	TEST_ASSERT(collect_all(blood, user, victim, seal), "Взыскание после смерти еретика завершено.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), brute_before, "Смерть еретика не обнуляет предел лечения.")
