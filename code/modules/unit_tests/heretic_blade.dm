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
	TEST_ASSERT(!(user.do_run_block(TRUE, blade, 20, "быстрый удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS), "Быстрая серия обходит внутреннюю задержку парирования.")
	knowledge.active_parry.next_block = world.time - 1
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Второй удар должен быть парирован после задержки.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Каждое парирование даёт один Темп.")
	TEST_ASSERT_NULL(knowledge.active_parry, "Обычная стойка заканчивается после двух ударов.")
	TEST_ASSERT(!(user.do_run_block(TRUE, blade, 20, "второй удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS), "Вторая атака не получает бесплатного блока.")

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
	knowledge.active_parry.next_block = world.time - 1
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Атака выбранного противника блокируется.")
	TEST_ASSERT(!(user.do_run_block(TRUE, blade, 20, "быстрый удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS), "Быстрый второй удар обходит внутреннюю перезарядку.")
	knowledge.active_parry.next_block = world.time - 1
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "После задержки можно блокировать второй удар.")
	knowledge.active_parry.next_block = world.time - 1
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Четвёртый удар блокируется.")
	for(var/remaining in 1 to 2)
		knowledge.active_parry.next_block = world.time - 1
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
	knowledge.combat_resource = 1
	TEST_ASSERT(!dance.can_cast(user, TRUE, TRUE), "Для танца требуется два Темпа до начала заклинания.")
	dance.charge_counter = 0
	dance.cast(list(user), user)
	TEST_ASSERT_EQUAL(dance.charge_counter, dance.charge_max, "Недостаток Темпа возвращает перезарядку танца.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Неудачный танец сохраняет Темп.")
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
	knowledge.active_parry.next_block = world.time - 1
	TEST_ASSERT(!(user.do_run_block(TRUE, bullet, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS), "Предмет во второй руке отключает уже поднятую защиту.")
	user.dropItemToGround(offhand)
	TEST_ASSERT(user.do_run_block(TRUE, bullet, 20, "снаряд турели", ATTACK_TYPE_PROJECTILE, 0, null) & BLOCK_SUCCESS, "Защита не требует живого стрелка.")
	TEST_ASSERT_NULL(knowledge.active_parry, "Два перехвата полностью расходуют обычную стойку.")

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
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 2, "Дружеское касание не расходует стойку.")
	attacker.UnarmedAttack(user, TRUE, INTENT_HARM)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Настоящий удар кулаком вызывает успешное парирование.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 1, "Один кулак расходует один блок.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Парированный кулак не причиняет рану.")
