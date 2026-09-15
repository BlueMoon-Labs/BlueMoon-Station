/// Финт расходует Темп, соблюдает предупреждение и не получает усиления ответного удара.
/datum/unit_test/heretic_blade_feint/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	knowledge.combat_resource = 2
	TEST_ASSERT(!knowledge.feint(user, attacker), "До изучения Неподвижной грани финт недоступен.")
	var/datum/eldritch_knowledge/blade_guard/guard = allocate(/datum/eldritch_knowledge/blade_guard)
	heretic.researched_knowledge[guard.type] = guard
	guard.on_body_gain(user)
	var/obj/effect/proc_holder/spell/granted = guard.granted_spell
	TEST_ASSERT(istype(granted, /obj/effect/proc_holder/spell/pointed/heretic_feint), "Неподвижная грань выдаёт направленный Финт.")
	var/obj/item/occupied_hand = allocate(/obj/item)
	user.put_in_hands(occupied_hand)
	TEST_ASSERT(!knowledge.feint(user, attacker), "Финту нужна свободная вторая рука.")
	user.dropItemToGround(occupied_hand)
	TEST_ASSERT(knowledge.feint(user, attacker), "Свободная рука и Темп позволяют открыть финт.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Финт расходует ровно один Темп.")
	TEST_ASSERT(!knowledge.try_riposte(attacker, user), "Во время предупреждения усиленный удар ещё недоступен.")
	TEST_ASSERT(!knowledge.feint(user, attacker), "Второй финт не расходует ресурс поверх первого.")
	var/datum/eldritch_knowledge/blade_upgrade/upgrade = allocate(/datum/eldritch_knowledge/blade_upgrade)
	heretic.researched_knowledge[upgrade.type] = upgrade
	var/datum/eldritch_knowledge/blade_riposte/riposte = allocate(/datum/eldritch_knowledge/blade_riposte)
	heretic.researched_knowledge[riposte.type] = riposte
	heretic.ascended = TRUE
	user.apply_status_effect(/datum/status_effect/heretic_blade_dance)
	user.adjustBruteLoss(10)
	knowledge.riposte_ready_at = world.time
	TEST_ASSERT(knowledge.try_riposte(attacker, user), "После предупреждения попадание проводит финт.")
	TEST_ASSERT(abs(attacker.getBruteLoss() - 10) < DAMAGE_PRECISION, "Улучшение и вознесение не усиливают десять ушибов финта.")
	TEST_ASSERT_EQUAL(attacker.getStaminaLoss(), 0, "Финт не добавляет урон выносливости ответного удара.")
	TEST_ASSERT(!attacker.IsKnockdown(), "Финт не получает сбивание Ошибки противника.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Танец не возвращает Темп за финт.")
	TEST_ASSERT(abs(user.getBruteLoss() - 10) < DAMAGE_PRECISION, "Танец не лечит за финт.")
	TEST_ASSERT_NULL(knowledge.opening_effect, "Проведённый финт убирает видимое окно.")
	knowledge.feint_cooldown = 0
	knowledge.record_parry(user, attacker)
	var/datum/status_effect/heretic_blade_opening/strong_opening = knowledge.opening_effect
	var/resource_before = knowledge.combat_resource
	TEST_ASSERT(!knowledge.feint(user, attacker), "Финт не перезаписывает настоящий ответ после парирования.")
	TEST_ASSERT_EQUAL(knowledge.opening_effect, strong_opening, "Сильное окно остаётся тем же экземпляром.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, resource_before, "Отказ не тратит Темп.")
	TEST_ASSERT(knowledge.try_riposte(attacker, user), "Настоящий ответ остаётся доступным.")
	TEST_ASSERT(abs(attacker.getBruteLoss() - 50) < DAMAGE_PRECISION, "Ответ сохраняет все сорок дополнительных ушибов.")
	guard.on_body_lose(user)
	TEST_ASSERT(QDELETED(granted), "Смена тела удаляет выданный Финт.")

/// Утрата знания убирает финт даже без роли в mind, сохраняя настоящий ответ.
/datum/unit_test/heretic_blade_feint/cleanup/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/blade_guard/guard = allocate(/datum/eldritch_knowledge/blade_guard)
	heretic.researched_knowledge[guard.type] = guard
	guard.on_body_gain(user)
	knowledge.combat_resource = 2
	TEST_ASSERT(knowledge.feint(user, attacker), "Знание открывает финт перед потерей тела.")
	var/datum/status_effect/heretic_blade_opening/opening = knowledge.opening_effect
	guard.on_body_lose(user)
	TEST_ASSERT(QDELETED(opening) && !knowledge.feint_opening, "Потеря тела самим знанием закрывает окно финта.")
	TEST_ASSERT_EQUAL(knowledge.riposte_until, 0, "Закрытое окно не мешает новому приёму.")
	guard.on_body_gain(user)
	COOLDOWN_RESET(knowledge, feint_cooldown)
	TEST_ASSERT(knowledge.feint(user, attacker), "Повторно выданное знание создаёт новое окно.")
	opening = knowledge.opening_effect
	var/obj/effect/proc_holder/spell/granted = guard.granted_spell
	user.mind.antag_datums -= heretic
	qdel(guard)
	TEST_ASSERT(QDELETED(granted) && QDELETED(opening), "Destroy удаляет кнопку и окно после отсоединения роли от mind.")
	TEST_ASSERT(!knowledge.feint_opening && !knowledge.riposte_target, "Удалённое знание не оставляет бонус для последующего попадания.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Очистка не возвращает уже потраченный Темп.")
	user.mind.antag_datums += heretic
	guard = allocate(/datum/eldritch_knowledge/blade_guard)
	heretic.researched_knowledge[guard.type] = guard
	guard.on_body_gain(user)
	knowledge.record_parry(user, attacker)
	opening = knowledge.opening_effect
	qdel(guard)
	TEST_ASSERT_EQUAL(knowledge.opening_effect, opening, "Удаление знания финта сохраняет сильный ответ после парирования.")
	TEST_ASSERT(!QDELETED(opening) && knowledge.try_riposte(attacker, user), "Сохранённый ответ можно провести обычным попаданием.")
	TEST_ASSERT(abs(attacker.getBruteLoss() - 18) <= DAMAGE_PRECISION, "Настоящий ответ сохраняет базовые восемнадцать ушибов.")

/// Преграда, чужой владелец и потеря тела не позволяют сохранить окно финта.
/datum/unit_test/heretic_blade_feint_obstacles/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/blade_guard/guard = allocate(/datum/eldritch_knowledge/blade_guard)
	heretic.researched_knowledge[guard.type] = guard
	knowledge.combat_resource = 1
	var/turf/middle = get_step(user, EAST)
	attacker.forceMove(get_step(middle, EAST))
	var/obj/barrier = allocate(/obj, middle)
	barrier.density = TRUE
	TEST_ASSERT(!knowledge.feint(user, attacker), "Прозрачная плотная преграда перекрывает финт.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Преграда не расходует Темп.")
	qdel(barrier)
	TEST_ASSERT(!knowledge.feint(attacker, user), "Чужое тело не использует знания владельца.")
	TEST_ASSERT(knowledge.feint(user, attacker), "После удаления преграды можно раскрыть цель в двух клетках.")
	var/datum/status_effect/heretic_blade_opening/opening = knowledge.opening_effect
	knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(opening), "Потеря тела снимает окно с противника.")
	TEST_ASSERT_NULL(knowledge.riposte_target, "Потеря тела очищает цель финта.")
	TEST_ASSERT(!knowledge.feint_opening, "Потеря тела очищает состояние финта.")

/datum/unit_test/proc/make_blade_fixture()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/datum/mind/user_mind = new
	allocated += user_mind
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/heretic = allocate(/datum/antagonist/heretic)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	var/datum/eldritch_knowledge/base_blade/knowledge = allocate(/datum/eldritch_knowledge/base_blade)
	knowledge.combat_resource = 0
	heretic.researched_knowledge[knowledge.type] = knowledge
	var/obj/item/melee/sickly_blade/duelist/blade = allocate(/obj/item/melee/sickly_blade/duelist, run_loc_floor_bottom_left)
	blade.bound_mind = user_mind
	user.put_in_hands(blade)
	knowledge.created_blades += WEAKREF(blade)
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	return list("user" = user, "heretic" = heretic, "knowledge" = knowledge, "blade" = blade, "attacker" = attacker)

/// Начальный Темп позволяет открыть бой выпадом; хватка восстанавливает пустой запас без парирования.
/datum/unit_test/heretic_blade_initiative/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	knowledge.combat_resource = initial(knowledge.combat_resource)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Путь начинается с Темпом для первого сближения.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blade_lunge)
	var/obj/effect/proc_holder/spell/pointed/heretic_lunge/lunge = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lunge)
	attacker.forceMove(get_step(get_step(get_step(user, EAST), EAST), EAST))
	lunge.cast(list(attacker), user)
	TEST_ASSERT(user.Adjacent(attacker), "Первый выпад работает до парирования и изучения метки.")
	TEST_ASSERT_EQUAL(attacker.AmountKnockdown(), 1.5 SECONDS, "Успешное сближение оставляет время на следующий удар.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Сближение расходует один Темп.")
	var/datum/eldritch_knowledge/blade_grasp/grasp = allocate(/datum/eldritch_knowledge/blade_grasp)
	TEST_ASSERT(grasp.on_mansus_grasp(attacker, user, TRUE), "Хватка попадает по противнику после выпада.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Хватка возвращает один Темп независимо от остатка.")
	grasp.on_mansus_grasp(attacker, user, TRUE)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 3, "Хватка пополняет запас до предела.")
	knowledge.combat_resource = 0
	TEST_ASSERT(!grasp.on_mansus_grasp(user, user, TRUE), "Нельзя получать Темп от хватки на себе.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Недопустимая цель не пополняет запас.")

/// Стойка блокирует снаряды и ближние удары с конечным запасом блоков.
/datum/unit_test/heretic_blade_parry/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/blade = fixture["blade"]
	TEST_ASSERT(knowledge.begin_parry(user), "Клинок в руке позволяет начать стойку.")
	TEST_ASSERT(!(user.do_run_block(FALSE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS), "Предварительная проверка не должна парировать воображаемый удар.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Проверка без атаки не даёт Темп.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS, "Выстрел блокируется стойкой.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Второй удар в тот же момент расходует следующий блок.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Каждое парирование даёт один Темп.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "третий удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Третий удар расходует последний блок.")
	TEST_ASSERT_NULL(knowledge.active_parry, "Обычная стойка заканчивается после трёх ударов.")
	TEST_ASSERT(!(user.do_run_block(TRUE, blade, 20, "четвёртый удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS), "После исчерпания стойки нет бесплатного блока.")

/datum/unit_test/heretic_blade_riposte_target/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	knowledge.record_parry(user, attacker)
	knowledge.on_eldritch_blade(stranger, user, TRUE)
	TEST_ASSERT_EQUAL(stranger.getBruteLoss(), 0, "Ответный удар нельзя перенести на другого врага.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Обычный удар пополняет Темп, не расходуя ответ.")
	knowledge.on_eldritch_blade(attacker, user, TRUE)
	var/riposte_damage = attacker.getBruteLoss()
	TEST_ASSERT(abs(riposte_damage - 18) < 0.001, "Ответный удар наносит 18 дополнительных ушибов.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Ответный удар не расходует Темп.")
	knowledge.on_eldritch_blade(attacker, user, TRUE)
	TEST_ASSERT_EQUAL(attacker.getBruteLoss(), riposte_damage, "Открытие для ответного удара используется один раз.")

/// Выпад проводит единственный ответ по парированному противнику; преграды сохраняют открытие.
/datum/unit_test/heretic_blade_lunge_riposte/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blade_lunge)
	var/obj/effect/proc_holder/spell/pointed/heretic_lunge/lunge = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lunge)
	attacker.forceMove(get_step(get_step(get_step(user, EAST), EAST), EAST))
	knowledge.record_parry(user, attacker)
	var/obj/barrier = allocate(/obj, get_step(user, EAST))
	barrier.density = TRUE
	lunge.cast(list(attacker), user)
	TEST_ASSERT_EQUAL(attacker.getBruteLoss(), 0, "Ответ не проходит через преграду.")
	TEST_ASSERT_EQUAL(knowledge.riposte_target?.resolve(), attacker, "Заблокированное сближение сохраняет ответ.")
	qdel(barrier)
	lunge.cast(list(attacker), user)
	TEST_ASSERT(user.Adjacent(attacker), "После снятия преграды выпад сближается с противником.")
	TEST_ASSERT(abs(attacker.getBruteLoss() - 38) <= DAMAGE_PRECISION, "Выпад и базовый ответ вместе наносят 38 ушибов.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Выпад расходует только один Темп, полученный от парирования.")
	TEST_ASSERT_NULL(knowledge.opening_effect, "Успешный ответ снимает видимое открытие.")
	knowledge.on_eldritch_blade(attacker, user, TRUE)
	TEST_ASSERT(abs(attacker.getBruteLoss() - 38) <= DAMAGE_PRECISION, "Следующий удар не повторяет уже проведённый ответ.")

/datum/unit_test/heretic_blade_parry_cleanup/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/blade = fixture["blade"]
	TEST_ASSERT(knowledge.begin_parry(user), "Стойка должна начаться.")
	knowledge.active_parry.expires_at = world.time - 1
	TEST_ASSERT(!(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS), "Истёкшая стойка не блокирует до следующего тика удаления status effect.")
	knowledge.on_body_lose(user)
	TEST_ASSERT_NULL(knowledge.active_parry, "Переселение удаляет стойку старого тела.")
	TEST_ASSERT(!(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS), "Старое тело не должно сохранить обработчик парирования.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Истёкшее или потерянное парирование не даёт Темп.")

/datum/unit_test/heretic_blade_master_duel/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/blade = fixture["blade"]
	var/datum/eldritch_knowledge/final_eldritch/blade_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	heretic.researched_knowledge[finale.type] = finale
	heretic.ascended = TRUE
	knowledge.duel_target = WEAKREF(attacker)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, NORTH))
	TEST_ASSERT(knowledge.begin_parry(user, TRUE), "Вознесённый мастер может начать финальную стойку против цели поединка.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар сбоку", ATTACK_TYPE_MELEE, 0, stranger) & BLOCK_SUCCESS, "Финальная стойка защищает от любого противника.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 5, "Каждая атака расходует общий запас стойки.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Атака выбранного противника блокируется.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Одновременное попадание тоже расходует блок.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Четвёртый удар блокируется.")
	for(var/remaining in 1 to 2)
		TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Последние блоки расходуют остаток стойки.")
	TEST_ASSERT_NULL(knowledge.active_parry, "Финальная стойка имеет конечное число блоков.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 3, "Темп ограничен тремя единицами.")

/datum/unit_test/heretic_blade_lunge_obstacle/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/spell/blade_lunge/lunge_knowledge = allocate(/datum/eldritch_knowledge/spell/blade_lunge)
	heretic.researched_knowledge[lunge_knowledge.type] = lunge_knowledge
	var/turf/blocked_turf = get_step(run_loc_floor_bottom_left, EAST)
	attacker.forceMove(get_step(get_step(blocked_turf, EAST), EAST))
	var/obj/barrier = allocate(/obj, blocked_turf)
	barrier.density = TRUE
	barrier.anchored = TRUE
	var/obj/effect/proc_holder/spell/pointed/heretic_lunge/lunge = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lunge)
	knowledge.combat_resource = 1
	lunge.charge_counter = 0
	lunge.cast(list(attacker), user)
	TEST_ASSERT_EQUAL(get_turf(user), run_loc_floor_bottom_left, "Выпад не проходит через плотное препятствие.")
	TEST_ASSERT_EQUAL(attacker.getStaminaLoss(), 0, "Заблокированный выпад не поражает противника за препятствием.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Неудавшийся выпад возвращает Темп.")
	TEST_ASSERT_EQUAL(lunge.charge_counter, lunge.charge_max, "Перекрытый путь возвращает перезарядку выпада.")
	qdel(barrier)
	var/obj/late_barrier = allocate(/obj, get_step(blocked_turf, EAST))
	late_barrier.density = TRUE
	late_barrier.anchored = TRUE
	lunge.charge_counter = 0
	lunge.cast(list(attacker), user)
	TEST_ASSERT_EQUAL(get_turf(user), run_loc_floor_bottom_left, "Препятствие на втором шаге не даёт бесплатного частичного перемещения.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Прерванный после первого шага выпад сохраняет Темп.")
	TEST_ASSERT_EQUAL(lunge.charge_counter, lunge.charge_max, "Прерванный после первого шага выпад сохраняет перезарядку.")
	qdel(late_barrier)
	lunge.cast(list(attacker), user)
	TEST_ASSERT(user.Adjacent(attacker), "Свободный путь позволяет сблизиться с целью.")
	TEST_ASSERT_EQUAL(attacker.getStaminaLoss(), 20, "Успешный выпад поражает выносливость цели.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Успешный выпад расходует Темп.")

/// Ритуальная вещь даёт начальный Темп ценой здоровья, с лимитом и проверкой владельца.
/datum/unit_test/heretic_blade_tuning_fork/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/blade_guard/recipe = allocate(/datum/eldritch_knowledge/blade_guard)
	heretic.researched_knowledge[recipe.type] = recipe
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Изученный обряд должен создать связанный с владельцем камертон.")
	var/obj/item/heretic_path_relic/tuning_fork/fork = recipe.new_path_relic_ref.resolve()
	allocated += fork
	TEST_ASSERT(!recipe.on_finished_recipe(user, list(), get_turf(user)), "Второй действующий камертон не создаётся.")
	user.put_in_hands(fork)
	fork.tuning_time = 0
	TEST_ASSERT(fork.tune(user), "Клинок и камертон в руках позволяют получить первый Темп.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Настройка даёт ровно один Темп.")
	TEST_ASSERT(abs(user.getBruteLoss() - 8) < 0.001, "Настройка действительно причиняет восемь ушибов.")
	TEST_ASSERT(!fork.tune(user), "Повторное применение заблокировано перезарядкой.")
	fork.relic_cooldown = 0
	TEST_ASSERT(!fork.tune(user), "Камертон не наполняет запас поверх уже имеющегося Темпа.")
	knowledge.combat_resource = 0
	user.dropItemToGround(fork)
	TEST_ASSERT(knowledge.begin_parry(user), "Для проверки взаимоисключения должна включиться стойка.")
	user.put_in_hands(fork)
	TEST_ASSERT(!fork.tune(user), "Нельзя настраивать камертон под защитой стойки.")
	knowledge.on_body_lose(user)
	user.dropItemToGround(fork)
	var/mob/living/stranger = fixture["attacker"]
	stranger.put_in_hands(fork)
	TEST_ASSERT(!fork.authorized(stranger), "Кража камертона не передаёт права на его применение.")

/// Телеграф стойки и уязвимости должен исчезать вместе с соответствующим эффектом.
/datum/unit_test/heretic_blade_feedback_cleanup/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	TEST_ASSERT(knowledge.begin_parry(user), "Стойка должна включиться.")
	var/datum/status_effect/heretic_parry/parry = knowledge.active_parry
	TEST_ASSERT_NOTNULL(parry.stance_overlay, "У стойки должен быть отдельный видимый телеграф.")
	user.update_icon()
	var/stance_count = 0
	for(var/image/overlay as anything in user.overlays)
		if(overlay.icon_state == "ring_leader_effect")
			stance_count++
	TEST_ASSERT_EQUAL(stance_count, 1, "Обновление иконки не дублирует кольцо стойки.")
	knowledge.record_parry(user, attacker)
	var/datum/status_effect/heretic_blade_opening/opening = knowledge.opening_effect
	TEST_ASSERT_NOTNULL(opening.opening_overlay, "Нападавший должен видеть открывшийся ответный удар.")
	attacker.update_icon()
	knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(parry) && QDELETED(opening), "Переселение удаляет оба визуальных эффекта.")
	TEST_ASSERT_NULL(parry.stance_overlay, "Стойка освобождает свой overlay.")
	TEST_ASSERT_NULL(opening.opening_overlay, "Уязвимость освобождает свой overlay.")
	TEST_ASSERT(!attacker.has_status_effect(/datum/status_effect/heretic_blade_opening), "На противнике не остаётся ложного телеграфа после переселения еретика.")
	for(var/image/overlay as anything in user.overlays)
		TEST_ASSERT(overlay.icon_state != "ring_leader_effect", "После снятия стойки её кольцо исчезает сразу.")
	for(var/image/overlay as anything in attacker.overlays)
		TEST_ASSERT(overlay.icon_state != "sigil_blade", "После снятия уязвимости её знак исчезает сразу.")

/// Неудачный танец и стойка мастера сохраняют перезарядку и запас Темпа.
/datum/unit_test/heretic_blade_failed_casts/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/spell/blade_dance/dance_knowledge = allocate(/datum/eldritch_knowledge/spell/blade_dance)
	heretic.researched_knowledge[dance_knowledge.type] = dance_knowledge
	var/obj/effect/proc_holder/spell/self/heretic_blade/dance/dance = allocate(/obj/effect/proc_holder/spell/self/heretic_blade/dance)
	knowledge.combat_resource = 0
	TEST_ASSERT(!dance.can_cast(user, TRUE, TRUE), "Для танца требуется один Темп до начала заклинания.")
	dance.charge_counter = 0
	dance.cast(list(user), user)
	TEST_ASSERT_EQUAL(dance.charge_counter, dance.charge_max, "Недостаток Темпа возвращает перезарядку танца.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Неудачный танец не создаёт Темп.")
	var/datum/eldritch_knowledge/final_eldritch/blade_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	heretic.researched_knowledge[finale.type] = finale
	heretic.ascended = TRUE
	var/obj/effect/proc_holder/spell/self/heretic_blade/master/master = allocate(/obj/effect/proc_holder/spell/self/heretic_blade/master)
	var/obj/item/offhand = allocate(/obj/item, get_turf(user))
	user.put_in_hands(offhand)
	TEST_ASSERT(!master.can_cast(user, TRUE, TRUE), "Занятая вторая рука не позволяет включить стойку мастера.")
	master.charge_counter = 0
	master.cast(list(user), user)
	TEST_ASSERT_EQUAL(master.charge_counter, master.charge_max, "Занятая рука не расходует перезарядку стойки.")
	TEST_ASSERT_NULL(knowledge.active_parry, "Неудачное заклинание не создаёт стойку.")

/// Парирование останавливает настоящий снаряд и требует свободной второй руки.
/datum/unit_test/heretic_blade_projectile_guard/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	attacker.forceMove(get_step(get_step(get_step(user, EAST), EAST), EAST))
	var/obj/item/projectile/bullet = allocate(/obj/item/projectile, get_turf(attacker))
	bullet.damage = 20
	bullet.firer = attacker
	bullet.starting = get_turf(attacker)
	attacker.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(knowledge.begin_parry(user), "Свой клинок позволяет встретить выстрел стойкой.")
	TEST_ASSERT_EQUAL(user.bullet_act(bullet, BODY_ZONE_CHEST), BULLET_ACT_BLOCK, "Настоящий снаряд блокируется даже от стрелка с антимагией.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Заблокированный снаряд не наносит рану.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Перехват снаряда пополняет Темп.")
	var/obj/item/offhand = allocate(/obj/item, get_turf(user))
	user.put_in_hands(offhand)
	TEST_ASSERT(!(user.do_run_block(TRUE, bullet, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS), "Предмет во второй руке отключает уже поднятую защиту.")
	user.dropItemToGround(offhand)
	TEST_ASSERT(user.do_run_block(TRUE, bullet, 20, "снаряд турели", ATTACK_TYPE_PROJECTILE, 0, null) & BLOCK_SUCCESS, "Защита не требует живого стрелка.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 1, "После двух перехватов остаётся один блок.")

/// Одновременный залп расходует все блоки стойки, а оставшиеся снаряды наносят урон.
/datum/unit_test/heretic_blade_projectile_guard/burst/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	heretic.gain_knowledge(/datum/eldritch_knowledge/blade_guard)
	TEST_ASSERT(knowledge.begin_parry(user), "Улучшенная стойка встречает залп четырьмя блоками.")
	for(var/shot in 1 to 6)
		var/obj/item/projectile/projectile = allocate(/obj/item/projectile, get_turf(attacker))
		projectile.damage = 10
		projectile.firer = attacker
		projectile.starting = get_turf(attacker)
		var/result = user.bullet_act(projectile, BODY_ZONE_CHEST)
		if(shot <= 4)
			TEST_ASSERT_EQUAL(result, BULLET_ACT_BLOCK, "Каждое из первых четырёх одновременных попаданий блокируется.")
			TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "До исчерпания блоков залп не наносит урон.")
		else
			TEST_ASSERT_EQUAL(result, BULLET_ACT_HIT, "Избыточные снаряды пробивают исчерпанную стойку.")
	TEST_ASSERT_NULL(knowledge.active_parry, "Четвёртый снаряд завершает стойку.")
	TEST_ASSERT(abs(user.getBruteLoss() - 20) < DAMAGE_PRECISION, "Последние два снаряда наносят полный урон.")

/// Парирование останавливает электроды без прямого урона и получает дополнительный блок от улучшения.
/datum/unit_test/heretic_blade_electrode_guard/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	heretic.gain_knowledge(/datum/eldritch_knowledge/blade_guard)
	TEST_ASSERT(knowledge.begin_parry(user), "Улучшенная стойка включается.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 4, "Улучшение даёт четвёртый блок.")
	for(var/projectile_type in list(/obj/item/projectile/energy/electrode, /obj/item/projectile/energy/electrode/security, /obj/item/projectile/beam/disabler))
		var/obj/item/projectile/projectile = allocate(projectile_type, get_turf(attacker))
		projectile.firer = attacker
		projectile.starting = get_turf(attacker)
		TEST_ASSERT_EQUAL(user.bullet_act(projectile, BODY_ZONE_CHEST), BULLET_ACT_BLOCK, "Стойка блокирует [projectile.type].")
		TEST_ASSERT(!user.IsKnockdown() && !user.IsStun(), "Перехват не пропускает оглушение.")
		TEST_ASSERT(!user.has_status_effect(STATUS_EFFECT_TASED) && !user.has_status_effect(STATUS_EFFECT_TASED_WEAK), "Перехват не пропускает электрический эффект.")
		TEST_ASSERT_EQUAL(user.getStaminaLoss(), 0, "Перехват не пропускает урон выносливости.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 1, "Каждый реальный снаряд расходует один блок.")

/// Первые два очка открывают сближение и ускорение, а пятое даёт удар по окружению.
/datum/unit_test/heretic_blade_early_actions/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.knowledge_points = 5
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_BLADE]
	for(var/stage in 1 to 3)
		TEST_ASSERT(heretic.research_knowledge(path.knowledge[stage], user), "Начальные приёмы доступны без подношений.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, 3, "Выпад и танец вместе стоят два очка.")
	TEST_ASSERT(locate(/obj/effect/proc_holder/spell/self/heretic_blade/parry) in user.mind.spell_list, "Парирование доступно сразу.")
	var/obj/effect/proc_holder/spell/self/heretic_blade/dance/dance = locate() in user.mind.spell_list
	var/obj/effect/proc_holder/spell/pointed/heretic_lunge/lunge = locate() in user.mind.spell_list
	TEST_ASSERT(dance && lunge, "Оба ранних активных приёма выданы телу.")
	var/datum/eldritch_knowledge/base_blade/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/obj/item/melee/sickly_blade/duelist/blade = allocate(/obj/item/melee/sickly_blade/duelist)
	blade.bound_mind = user.mind
	user.put_in_hands(blade)
	dance.cast(list(user), user)
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_blade_dance), "Танец запускается на начальном запасе.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "После танца остаётся Темп на выпад.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	lunge.cast(list(victim), user)
	TEST_ASSERT(user.Adjacent(victim) && victim.getBruteLoss() > 0, "Начального запаса хватает на танец с настоящим выпадом.")
	for(var/stage in 4 to 5)
		TEST_ASSERT(heretic.research_knowledge(path.knowledge[stage], user), "Метка и круговой разрез доступны без подношений.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, 0, "Пять очков оплачивают все четыре боевых действия и метку.")
	var/obj/effect/proc_holder/spell/self/heretic_blade/sweep/sweep = locate() in user.mind.spell_list
	TEST_ASSERT_NOTNULL(sweep, "Вызов выдаёт круговой разрез.")
	var/datum/eldritch_knowledge/blade_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/blade_grasp)
	grasp.on_body_lose(user)
	TEST_ASSERT(QDELETED(sweep), "Смена тела удаляет выданный разрез.")
	grasp.on_body_gain(user)
	TEST_ASSERT(locate(/obj/effect/proc_holder/spell/self/heretic_blade/sweep) in user.mind.spell_list, "Новое тело получает разрез заново.")

/// Три связанных клинка допускаются, четвёртый запрещён; разрушенный освобождает место.
/datum/unit_test/heretic_blade_weapon_reserve/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	for(var/index in 1 to 2)
		TEST_ASSERT(knowledge.on_finished_recipe(user, list(), get_turf(user)), "Можно создать второй и третий клинок.")
		var/datum/weakref/blade_ref = knowledge.created_blades[length(knowledge.created_blades)]
		var/obj/item/melee/sickly_blade/duelist/blade = blade_ref.resolve()
		allocated += blade
		TEST_ASSERT_EQUAL(blade.bound_mind, user.mind, "Резервный клинок привязан к создателю.")
	TEST_ASSERT(!knowledge.on_finished_recipe(user, list(), get_turf(user)), "Четвёртый клинок не создаётся.")
	qdel(fixture["blade"])
	TEST_ASSERT(knowledge.on_finished_recipe(user, list(), get_turf(user)), "Потраченный клинок можно заменить.")
	var/datum/weakref/replacement_ref = knowledge.created_blades[length(knowledge.created_blades)]
	allocated += replacement_ref.resolve()
	TEST_ASSERT_EQUAL(length(knowledge.created_blades), 3, "Удалённые клинки не занимают лимит.")

/// Круговой разрез поражает нескольких врагов, уважает стены и антимагию, не работает без своего клинка.
/datum/unit_test/heretic_blade_sweep/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/victim = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	user.forceMove(get_step(get_step(get_step(get_step(user, NORTH), NORTH), EAST), EAST))
	victim.forceMove(get_step(user, EAST))
	var/turf/old_place = get_turf(victim)
	var/mob/living/second = allocate(/mob/living/carbon/human, get_step(user, SOUTH))
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/mob/living/blocked = allocate(/mob/living/carbon/human, get_step(user, WEST))
	var/obj/structure/closet/crate/barrier = allocate(/obj/structure/closet/crate, get_turf(blocked))
	heretic.gain_knowledge(/datum/eldritch_knowledge/blade_grasp)
	var/datum/eldritch_knowledge/blade_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/blade_grasp)
	var/obj/effect/proc_holder/spell/self/heretic_blade/sweep/sweep = grasp.granted_spell
	knowledge.combat_resource = 2
	sweep.cast(list(user), user)
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) <= DAMAGE_PRECISION && abs(second.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Один разрез наносит раны обоим соседним врагам.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 25, "Разрез истощает цель.")
	TEST_ASSERT(get_dist(user, victim) == 2 && get_turf(victim) != old_place, "Разрез освобождает соседнюю клетку.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия блокирует раны.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Разрез расходует один заряд антимагии.")
	TEST_ASSERT_EQUAL(blocked.getBruteLoss(), 0, "Плотная преграда перекрывает разрез.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Число жертв не умножает расход Темпа.")
	qdel(barrier)
	user.dropItemToGround(fixture["blade"])
	sweep.charge_counter = 0
	sweep.cast(list(user), user)
	TEST_ASSERT_EQUAL(blocked.getBruteLoss(), 0, "Без клинка разрез не проходит.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Неудачный разрез сохраняет Темп.")
	TEST_ASSERT_EQUAL(sweep.charge_counter, sweep.charge_max, "Неудачный разрез возвращает перезарядку.")

/// Обычный удар поддерживает Темп без меток и парирований, но серия не даёт бесконечный запас.
/datum/unit_test/heretic_blade_strike_tempo/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	knowledge.on_eldritch_blade(attacker, user, TRUE)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Обычный удар даёт Темп при пустом запасе.")
	knowledge.on_eldritch_blade(attacker, user, TRUE)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Быстрые удары соблюдают общий интервал пополнения.")
	knowledge.next_strike_tempo = world.time - 1
	knowledge.on_eldritch_blade(attacker, user, TRUE)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "После задержки удар снова пополняет Темп.")

/// Обычный кулак проходит через проверку блока с нулевым предварительным уроном.
/datum/unit_test/heretic_blade_unarmed_guard/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	TEST_ASSERT(knowledge.begin_parry(user), "Перед ударом кулака должна включиться стойка.")
	user.attack_hand(attacker, INTENT_HELP)
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 3, "Дружеское касание не расходует стойку.")
	attacker.UnarmedAttack(user, TRUE, INTENT_HARM)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Настоящий удар кулаком вызывает успешное парирование.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 2, "Один кулак расходует один блок.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Парированный кулак не причиняет рану.")
/// Стол и лоток перекрывают прямой выпад, но узкий проход между лотками остаётся проходимым.
/datum/unit_test/heretic_blade_lunge_hydroponics/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blade_lunge)
	var/obj/effect/proc_holder/spell/pointed/heretic_lunge/lunge = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lunge)
	attacker.forceMove(get_step(get_step(get_step(user, EAST), EAST), EAST))
	knowledge.combat_resource = 1
	for(var/barrier_type in list(/obj/structure/table, /obj/machinery/hydroponics))
		var/obj/barrier = allocate(barrier_type, get_step(user, EAST))
		lunge.charge_counter = 0
		lunge.cast(list(attacker), user)
		TEST_ASSERT_EQUAL(get_turf(user), run_loc_floor_bottom_left, "Выпад не перемещает через [barrier_type].")
		TEST_ASSERT_EQUAL(attacker.getBruteLoss(), 0, "За [barrier_type] цель не получает урон.")
		TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Преграда сохраняет Темп.")
		TEST_ASSERT_EQUAL(lunge.charge_counter, lunge.charge_max, "Преграда сохраняет готовность выпада.")
		qdel(barrier)
	var/turf/corridor = get_turf(user)
	for(var/step_index in 1 to 3)
		allocate(/obj/machinery/hydroponics, get_step(corridor, NORTH))
		allocate(/obj/machinery/hydroponics, get_step(corridor, SOUTH))
		corridor = get_step(corridor, EAST)
	lunge.cast(list(attacker), user)
	TEST_ASSERT(user.Adjacent(attacker), "Выпад проходит по свободной клетке между рядами лотков.")
	TEST_ASSERT(abs(attacker.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Успешное сближение наносит обычный урон выпада.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Успех расходует один Темп.")

/// Уход цели за лоток после первого шага прерывает выпад без дистанционного урона и возврата Темпа.
/datum/unit_test/heretic_blade_lunge_evading_target
	var/datum/weakref/evading_target
	var/turf/escape_turf

/datum/unit_test/heretic_blade_lunge_evading_target/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blade_lunge)
	var/obj/effect/proc_holder/spell/pointed/heretic_lunge/lunge = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lunge)
	attacker.forceMove(get_step(get_step(get_step(user, EAST), EAST), EAST))
	var/turf/blocked_turf = get_step(user, NORTH)
	allocate(/obj/machinery/hydroponics, blocked_turf)
	allocate(/obj/machinery/hydroponics, get_step(blocked_turf, EAST))
	escape_turf = get_step(get_step(get_step(blocked_turf, NORTH), NORTH), EAST)
	evading_target = WEAKREF(attacker)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_lunge_step))
	knowledge.combat_resource = 1
	lunge.charge_counter = 0
	lunge.cast(list(attacker), user)
	TEST_ASSERT_EQUAL(get_turf(attacker), escape_turf, "Цель сменила позицию во время движения еретика.")
	TEST_ASSERT_EQUAL(get_turf(user), get_step(run_loc_floor_bottom_left, EAST), "Выпад останавливается у преграды после первого шага.")
	TEST_ASSERT_EQUAL(attacker.getBruteLoss(), 0, "Ушедший противник не получает урон сквозь преграду.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Частичное перемещение расходует Темп.")
	TEST_ASSERT_EQUAL(lunge.charge_counter, 0, "Частичное перемещение не отменяет перезарядку.")

/datum/unit_test/heretic_blade_lunge_evading_target/proc/on_lunge_step(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)
	var/mob/living/target = evading_target.resolve()
	target.forceMove(escape_turf)
