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
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
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
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
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
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
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
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
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
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
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
	TEST_ASSERT(seal.detonate() && QDELETED(seal), "Обычное взыскание закрывает остаток связи.")
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
	TEST_ASSERT(wait_for_qdeleted(seal), "Настоящий таймер завершает взыскание.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) < 0.01, "Начальный долг взыскивается двадцатью ушибами.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Взысканная связь больше не числится в долге.")
	TEST_ASSERT(blood.release(user, victim), "Перед смертельным взысканием создаётся новая связь.")
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
	TEST_ASSERT(blood.pact(user), "Без связей Договор оплачивает ускорение.")
	TEST_ASSERT(blood.release(user, first), "Первая связь укладывается в предел.")
	TEST_ASSERT(blood.release(user, second), "Пассивка разрешает вторую связь.")
	var/datum/status_effect/heretic_blood_seal/first_seal = first.has_status_effect(/datum/status_effect/heretic_blood_seal)
	var/datum/status_effect/heretic_blood_seal/second_seal = second.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT(blood.invest(user, list(first_seal), 6), "Первую связь можно подготовить у предела вместимости.")
	var/previous_debt = blood.combat_resource
	var/damage_before = user.getBruteLoss()
	TEST_ASSERT(blood.pact(user), "Договор распределяет плату по двум связям.")
	var/paid = user.getBruteLoss() - damage_before
	TEST_ASSERT(abs(paid - 10) < 0.01, "Договор ранит владельца на десять.")
	TEST_ASSERT(abs(blood.combat_resource - previous_debt - paid) < 0.01, "Сумма долгов растёт ровно на одну плату.")
	TEST_ASSERT(abs(first_seal.debt - 20) < 0.01, "Старшая связь заполняется до предела.")
	TEST_ASSERT(abs(second_seal.debt - 16) < 0.01, "Младшая получает только оставшиеся шесть единиц.")
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
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
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
	TEST_ASSERT(QDELETED(seal), "Полный глоток расходует десять долга и освобождает связь.")
	TEST_ASSERT(!chalice.drink(user, victim), "Повторное питьё ограничено перезарядкой.")
	COOLDOWN_RESET(chalice, relic_cooldown)
	TEST_ASSERT(blood.release(user, victim), "Перед следующим глотком создаётся новая связь.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.debt = 5
	blood.update_debt()
	TEST_ASSERT(chalice.drink(user, victim), "Остаток долга можно потратить после перезарядки.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Остаток долга залечивает последние ушибы.")
	TEST_ASSERT_EQUAL(seal.debt, 0, "Долг нельзя потратить дважды.")
	TEST_ASSERT(QDELETED(seal), "Исчерпанная чашей связь освобождает место для новой цели.")
	TEST_ASSERT_EQUAL(length(blood.seals), 0, "Пустая связь не занимает лимит.")
	TEST_ASSERT(blood.release(user, victim), "Цель можно связать снова без пустого взыскания.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	TEST_ASSERT_NOTNULL(seal, "Первый выбор после чаши создаёт новую связь.")
	TEST_ASSERT(!seal.collecting, "Новая связь не начинает взыскание сама.")
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
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
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
	TEST_ASSERT(abs(first.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Взыскание добавляет шесть долга перед уроном с коэффициентом 2,25.")
	TEST_ASSERT(abs(second.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Каждый получает урон только своего усиленного долга.")
	TEST_ASSERT_EQUAL(bystander.getBruteLoss(), 0, "Стоящий между должниками посторонний не затронут.")
	TEST_ASSERT_EQUAL(blood.combat_resource, 0, "Взыскание очищает общий долг.")

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
	TEST_ASSERT(blood.invest(user, list(chosen), 18), "Выбранный долг подготовлен у предела.")
	TEST_ASSERT(blood.invest(user, list(donor), 6), "Вторая связь содержит отдельный долг.")
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
	seal.debt = 14
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
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(middle, EAST))
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
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
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
			TEST_ASSERT(QDELETED(seal), "Полное взыскание удаляет погашенную связь.")

/// Взыскание лечит оба вида ран, учитывает усиление и не высасывает здоровье из неуязвимой цели.
/datum/unit_test/heretic_blood_collection_siphon/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	user.adjustBruteLoss(3)
	user.adjustFireLoss(32)
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Базовый долг готов к взысканию.")
	var/datum/status_effect/heretic_blood_seal/seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Базовое взыскание наносит урон.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Начальный долг наносит двадцать ушибов.")
	TEST_ASSERT(user.getBruteLoss() <= DAMAGE_PRECISION && abs(user.getFireLoss() - 30) <= DAMAGE_PRECISION, "Пять лечения распределяются между ушибами и ожогами без удвоения.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_upgrade)
	TEST_ASSERT(blood.release(user, victim), "Новая связь доступна после взыскания.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	blood.add_debt(seal, 10)
	TEST_ASSERT(blood.release(user, victim), "Полный долг готов к усиленному взысканию.")
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Усиленное взыскание завершается.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 65) <= DAMAGE_PRECISION, "Полный усиленный долг наносит ещё сорок пять ушибов.")
	TEST_ASSERT(abs(user.getFireLoss() - 10) <= DAMAGE_PRECISION, "Усиление лечит ожоги, соблюдая предел двадцать.")
	TEST_ASSERT(blood.release(user, victim) && blood.release(user, victim), "Подготовлено взыскание с защищённой цели.")
	seal = victim.has_status_effect(/datum/status_effect/heretic_blood_seal)
	victim.status_flags |= GODMODE
	seal.collection_ready_at = world.time
	TEST_ASSERT(seal.detonate(), "Неуязвимость не оставляет вечную подготовку.")
	TEST_ASSERT(abs(user.getFireLoss() - 10) <= DAMAGE_PRECISION, "Без фактического урона лечения нет.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 65) <= DAMAGE_PRECISION, "Неуязвимая цель не получает урон.")

/// Чаша лечит ожоги через предмет, расходуя только нужную долю долга и соблюдая перезарядку.
/datum/unit_test/heretic_blood_chalice_burns/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/datum/eldritch_knowledge/blood_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/blood_relic)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
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
/// Отказы взыскания и Договора сохраняют перезарядку и объясняют недостающее условие.
/datum/unit_test/heretic_blood_failure_feedback/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_BLOOD
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blood)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_reckoning)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blood_pact)
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
	var/obj/effect/proc_holder/spell/self/heretic_blood/pact/pact = allocate(/obj/effect/proc_holder/spell/self/heretic_blood/pact)
	pact.charge_counter = 0
	pact.cast(list(user), user)
	TEST_ASSERT(findtext(pact.heretic_failure_reason, "мало здоровья"), "Опасная плата объяснена игроку.")
	TEST_ASSERT_EQUAL(pact.charge_counter, pact.charge_max, "Отказ оплаты возвращает перезарядку.")

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
	TEST_ASSERT(blood.invest(user, list(chosen), 18), "Долг выбранного у предела.")
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
