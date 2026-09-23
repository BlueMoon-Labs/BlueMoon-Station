/// Ритуальный ключ размыкает одну свою печать без возврата ресурса и изменения остальных.
/datum/unit_test/heretic_lock_selective_release/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_LOCK
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_key)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/lock_key/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/lock_key)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Создаётся ритуальный ключ.")
	var/obj/item/heretic_path_relic/lock_key/key = recipe.new_path_relic_ref.resolve()
	allocated += key
	user.put_in_hands(key)
	key.releasing_time = 0
	var/turf/center = get_step(get_step(user, EAST), EAST)
	var/obj/structure/heretic_lock_seal/selected = knowledge.create_seal(center, user)
	var/obj/structure/heretic_lock_seal/retained = knowledge.create_seal(get_step(user, NORTH), user)
	TEST_ASSERT(selected && retained, "Созданы две печати для выборочного размыкания.")
	TEST_ASSERT(!key.release_seal(user, selected), "Без знания Размыкания ключ не взрывает печать.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/lock_release)
	retained.take_damage(10, BRUTE, MELEE)
	var/integrity_before = retained.obj_integrity
	var/expiry_before = retained.expires_at
	var/keys_before = knowledge.combat_resource
	var/datum/antagonist/heretic/stranger = allocate_heretic(get_step(user, NORTHEAST))
	TEST_ASSERT(!key.release_seal(stranger.owner.current, selected), "Чужой разум не размыкает печати ключом владельца.")
	var/obj/barrier = allocate(/obj, get_step(user, EAST))
	barrier.density = TRUE
	barrier.opacity = TRUE
	TEST_ASSERT(!key.release_seal(user, selected), "За непрозрачной преградой нельзя выбрать печать.")
	qdel(barrier)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/mob/living/outside = allocate(/mob/living/carbon/human, get_step(retained, NORTH))
	TEST_ASSERT(key.release_seal(user, selected), "Ключ размыкает выбранную видимую печать.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) < DAMAGE_PRECISION, "Соседний враг получает обычный урон Размыкания.")
	TEST_ASSERT_EQUAL(outside.getBruteLoss(), 0, "Сохранившаяся печать не взрывается возле другого врага.")
	TEST_ASSERT(QDELETED(selected), "Выбранная печать израсходована.")
	TEST_ASSERT_EQUAL(length(knowledge.seals), 1, "Остальная печать сохранена.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, keys_before, "Ключ из взорванной печати не возвращается.")
	TEST_ASSERT_EQUAL(retained.obj_integrity, integrity_before, "Остальная печать не чинится.")
	TEST_ASSERT_EQUAL(retained.expires_at, expiry_before, "Срок жизни остальных печатей не обновляется.")
	TEST_ASSERT(!key.release_seal(user, retained), "Перезарядка не даёт сразу разомкнуть другую печать.")
	TEST_ASSERT(!key.can_cut(user), "Размыкание делит откат с добычей ключа из ладони.")
	key.relic_cooldown = 0
	TEST_ASSERT(!key.release_seal(user, selected), "Разрушенная печать больше не становится целью.")
	knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(retained), "Потеря тела удаляет оставшуюся печать.")

/// Печати расходуют ключи только при успешной установке и имеют общий предел.
/datum/unit_test/heretic_lock_seals/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/turf/first_place = get_step(user, EAST)
	var/obj/structure/heretic_lock_seal/first = knowledge.create_seal(first_place, user)
	TEST_ASSERT_NOTNULL(first, "Свободный пол принимает печать.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Успешная печать стоит один ключ.")
	TEST_ASSERT_EQUAL(first.max_integrity, 60, "Начальная печать имеет 60 прочности.")
	TEST_ASSERT_NULL(knowledge.create_seal(first_place, user), "На одну клетку нельзя поставить две печати.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Отклонённая установка не расходует ключ.")
	TEST_ASSERT_NULL(knowledge.create_seal(get_turf(user), user), "Нельзя создать печать на занятой мобом клетке.")
	var/obj/structure/heretic_lock_seal/second = knowledge.create_seal(get_step(user, NORTH), user)
	TEST_ASSERT_NOTNULL(second, "Второй ключ создаёт вторую печать.")
	TEST_ASSERT_NULL(knowledge.create_seal(get_step(user, NORTHEAST), user), "Пустой запас не создаёт печать.")
	knowledge.gain_combat_resource(10)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 4, "Ключи не переполняют запас.")
	knowledge.create_seal(get_step(user, NORTHEAST), user)
	knowledge.create_seal(get_step(first_place, EAST), user)
	TEST_ASSERT_EQUAL(length(knowledge.seals), 4, "Начальный предел равен четырём печатям.")
	TEST_ASSERT_NULL(knowledge.create_seal(get_step(get_step(user, NORTH), NORTH), user), "Лимит не обходится оставшимися ключами.")
	first.take_damage(100, BRUTE, MELEE)
	TEST_ASSERT(QDELETED(first), "Обычный урон разрушает печать.")
	TEST_ASSERT_EQUAL(length(knowledge.seals), 3, "Разрушение освобождает место в общем пределе.")

/// После заполнения запаса печати расходуют ключи и обновляют число на HUD до нуля.
/datum/unit_test/heretic_lock_resource_cap/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_LOCK)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/atom/movable/screen/alert/heretic_resource/indicator = user.alerts["heretic_path_resource"]
	TEST_ASSERT_NOTNULL(indicator, "Изучение Замка создаёт индикатор ключей.")
	knowledge.gain_combat_resource(10)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 4, "Запас заполнен до четырёх ключей.")
	TEST_ASSERT_EQUAL(indicator.displayed_value, 4, "HUD показывает полный запас.")
	for(var/direction in list(EAST, NORTH, NORTHEAST, EAST))
		var/obj/structure/heretic_lock_seal/seal = knowledge.create_seal(get_step(user, direction), user)
		TEST_ASSERT_NOTNULL(seal, "После заполнения запаса ключ можно потратить на печать.")
		qdel(seal)
		TEST_ASSERT_EQUAL(indicator.displayed_value, knowledge.combat_resource, "Расход немедленно обновляет числовое состояние HUD.")
		TEST_ASSERT(findtext(indicator.maptext, ">[knowledge.combat_resource]/4</div>"), "Видимый текст HUD соответствует оставшимся ключам.")
		var/list/resource = knowledge.get_combat_resource_data()
		TEST_ASSERT_EQUAL(resource["value"], knowledge.combat_resource, "Кодекс показывает тот же остаток.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Четыре печати исчерпывают запас.")
	TEST_ASSERT(!knowledge.seal_spell.can_target(get_step(user, EAST), user, TRUE), "Пустой запас блокирует создание печати.")
	knowledge.gain_combat_resource()
	TEST_ASSERT_EQUAL(indicator.displayed_value, 1, "Добыча после опустошения обновляет HUD.")
	TEST_ASSERT(knowledge.seal_spell.can_target(get_step(user, EAST), user, TRUE), "Новый ключ снова позволяет создать печать.")

/// Союзники и антимагия проходят через печать, проверка прохода не тратит заряды защиты.
/datum/unit_test/heretic_lock_passage/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/turf/destination = get_step(user, EAST)
	var/obj/structure/heretic_lock_seal/seal = knowledge.create_seal(destination, user)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(destination, NORTH))
	TEST_ASSERT(seal.CanPass(user, destination), "Хозяин свободно проходит через печать.")
	TEST_ASSERT(!seal.CanPass(victim, destination), "Печать удерживает обычного противника.")
	TEST_ASSERT(!victim.Move(destination, SOUTH), "Настоящее движение не проходит сквозь печать.")
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, NORTH))
	TEST_ASSERT(seal.CanPass(ally.owner.current, destination), "Другой еретик тоже проходит через печать.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(seal.CanPass(victim, destination), "Защита от магии открывает проход.")
	TEST_ASSERT(seal.CanPass(victim, destination), "Повторная проверка прохода остаётся безопасной.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проход не расходует заряды антимагии.")
	TEST_ASSERT(victim.Move(destination, SOUTH), "Защищённый противник действительно проходит через печать.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	seal.attackby(rod, victim)
	TEST_ASSERT(QDELETED(seal), "Нуль-жезл сразу разрушает печать.")

/// Хватка отпирает реальные шлюзы и шкафы, сохраняя сварку и общий интервал добычи ключей.
/datum/unit_test/heretic_lock_opening/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_grasp)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/lock_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/lock_grasp)
	knowledge.combat_resource = 0
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, get_step(user, EAST))
	door.locked = TRUE
	door.welded = TRUE
	TEST_ASSERT(!grasp.on_mansus_grasp(door, user, TRUE), "Сварка не позволяет открыть шлюз.")
	TEST_ASSERT(door.locked, "Неудачная хватка не поднимает болты.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Неудача не создаёт ключ.")
	door.welded = FALSE
	TEST_ASSERT(grasp.on_mansus_grasp(door, user, TRUE), "Хватка открывает запертый шлюз.")
	TEST_ASSERT(!door.locked && !door.density, "Болты подняты, шлюз действительно открыт.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Успешное открытие даёт ключ.")
	TEST_ASSERT(!grasp.on_mansus_grasp(door, user, TRUE), "Открытый шлюз нельзя использовать повторно.")
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, get_step(user, NORTH))
	closet.locked = TRUE
	TEST_ASSERT(grasp.on_mansus_grasp(closet, user, TRUE), "Хватка открывает запертый шкаф.")
	TEST_ASSERT(closet.opened && !closet.locked, "Шкаф открыт, а его замок снят.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Второй замок не обходит общий интервал добычи.")

/// Хватка на вреде запирает шлюз на 20 секунд, делит с отпиранием задержку ключей и снимает болты по сроку.
/datum/unit_test/heretic_lock_grasp_bolt/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_grasp)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/lock_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/lock_grasp)
	knowledge.combat_resource = 0
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, get_step(user, EAST))
	var/obj/machinery/door/airlock/second = allocate(/obj/machinery/door/airlock, get_step(user, NORTH))
	user.a_intent = INTENT_HARM
	TEST_ASSERT(grasp.on_mansus_grasp(door, user, TRUE), "Хватка на вреде запирает закрытый шлюз.")
	TEST_ASSERT(door.locked && door.density, "Шлюз остаётся закрытым на болты.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Запирание даёт ключ.")
	TEST_ASSERT(abs(timeleft(knowledge.grasp_bolts[door]) - 20 SECONDS) <= world.tick_lag, "Болты поднимутся через 20 секунд.")
	TEST_ASSERT(grasp.on_mansus_grasp(second, user, TRUE), "Второй шлюз тоже запирается.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Второе запирание не обходит общую задержку ключей.")
	knowledge.release_grasp_bolt(door)
	TEST_ASSERT(!door.locked && door.density, "По сроку болты поднимаются, шлюз остаётся закрытым.")
	TEST_ASSERT(!(door in knowledge.grasp_bolts), "Освобождённый шлюз больше не отслеживается.")
	user.a_intent = INTENT_HELP
	TEST_ASSERT(grasp.on_mansus_grasp(second, user, TRUE), "На помощи хватка открывает запертый ею шлюз.")
	TEST_ASSERT(!second.locked && !second.density, "Шлюз открыт и без болтов.")
	knowledge.release_grasp_bolt(second)
	TEST_ASSERT(!second.locked, "Срок запирания не опускает болты на уже открытом шлюзе.")
	TEST_ASSERT_EQUAL(length(knowledge.grasp_bolts), 0, "Все запирания освобождены.")

/// Направленный удар проверяет препятствия, союзников и один раз расходует антимагию при попадании.
/datum/unit_test/heretic_lock_bolt/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt/spell = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lock/bolt)
	var/turf/middle = get_step(user, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(middle, EAST))
	var/obj/structure/blocker = allocate(/obj/structure, middle)
	blocker.density = TRUE
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Даже прозрачное плотное препятствие блокирует удар.")
	spell.charge_counter = 0
	spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Невозможный выстрел возвращает заряд.")
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Сквозь препятствие нет урона.")
	qdel(blocker)
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, NORTH))
	TEST_ASSERT(!spell.can_target(ally.owner.current, user, TRUE), "Союзник не становится целью заклинания.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Видимого противника можно выбрать без расхода защиты.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Прицеливание не расходует защиту.")
	spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(protection.charges, 4, "Попадание расходует ровно один заряд антимагии.")
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Антимагия блокирует ожоги.")
	qdel(protection)
	spell.cast(list(victim), user)
	TEST_ASSERT(abs(victim.getFireLoss() - 25) < 0.001, "Незащищённая цель получает 25 ожогов.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 20) < 0.001, "Незащищённая цель получает 20 урона выносливости.")

/// Клинок активирует свою метку, добывает ключ и закрывает свободный проход позади противника.
/datum/unit_test/heretic_lock_mark/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_mark)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/lock_mark/mark_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/lock_mark)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(mark_knowledge.on_mansus_grasp(victim, user, TRUE), "Хватка накладывает метку Замка.")
	TEST_ASSERT_EQUAL(length(knowledge.marks), 1, "Знание отслеживает метку для очистки.")
	var/obj/item/melee/sickly_blade/lock/blade = allocate(/obj/item/melee/sickly_blade/lock)
	user.put_in_hands(blade)
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/lock), "Удар расходует метку.")
	TEST_ASSERT_EQUAL(length(knowledge.marks), 0, "Сработавшая метка больше не удерживается знанием.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 15) < 0.001, "Активация наносит 15 урона выносливости.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 3, "Активация возвращает один ключ.")
	TEST_ASSERT_EQUAL(length(knowledge.seals), 1, "За спиной появляется одна бесплатная печать.")
	var/obj/structure/heretic_lock_seal/seal = knowledge.seals[1]
	TEST_ASSERT_EQUAL(get_turf(seal), get_step(victim, EAST), "Печать появляется на стороне отступления от еретика.")
	TEST_ASSERT(seal.expires_at <= world.time + 8 SECONDS, "Метка создаёт короткую восьмисекундную печать.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_blade_upgrade)
	var/datum/eldritch_knowledge/lock_blade_upgrade/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/lock_blade_upgrade)
	var/damage_before = victim.getBruteLoss()
	upgrade.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT(abs(victim.getBruteLoss() - (damage_before + 5)) < 0.001, "Своя печать усиливает клинок на 5 ушибов.")

/// Размыкание рядом с несколькими печатями не складывает урон и заряды антимагии.
/datum/unit_test/heretic_lock_release/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	knowledge.create_seal(get_step(user, EAST), user)
	knowledge.create_seal(get_step(user, NORTH), user)
	var/turf/target_turf = get_step(user, NORTHEAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, target_turf)
	var/mob/living/protected = allocate(/mob/living/carbon/human, target_turf)
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/datum/antagonist/heretic/ally = allocate_heretic(target_turf)
	TEST_ASSERT(knowledge.release_seals(user), "Подготовленные печати размыкаются.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) < 0.001, "Две соседние печати наносят 30 ушибов один раз.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия блокирует размыкание.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Защита расходуется один раз за всё применение.")
	TEST_ASSERT_EQUAL(ally.owner.current.getBruteLoss(), 0, "Другой еретик защищён от размыкания.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Владелец не получает урон своих печатей.")
	TEST_ASSERT_EQUAL(length(knowledge.seals), 0, "Размыкание расходует все выбранные печати.")
	TEST_ASSERT(!knowledge.release_seals(user), "Без печатей заклинание не срабатывает.")

/// Снятие оплаченной печати возвращает ключ, но бесплатные печати не создают ресурс.
/datum/unit_test/heretic_lock_reclaim/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/structure/heretic_lock_seal/paid = knowledge.create_seal(get_step(user, EAST), user)
	TEST_ASSERT_NOTNULL(paid, "Оплаченная печать создана.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Печать расходует ключ.")
	paid.on_attack_hand(user, INTENT_HELP)
	TEST_ASSERT(QDELETED(paid), "Ручное снятие убирает преграду.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Потраченный ключ возвращается.")
	var/obj/structure/heretic_lock_seal/free = knowledge.create_seal(get_step(user, NORTH), user, key_cost = 0)
	TEST_ASSERT_NOTNULL(free, "Бесплатная печать создана.")
	free.on_attack_hand(user, INTENT_HELP)
	TEST_ASSERT(QDELETED(free), "Бесплатную печать тоже можно снять.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Бесплатная печать не даёт лишний ключ.")
	var/obj/structure/heretic_lock_seal/broken = knowledge.create_seal(get_step(user, SOUTH), user)
	TEST_ASSERT_NOTNULL(broken, "Ещё одна печать создана.")
	broken.take_damage(100, BRUTE, MELEE)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Уничтожение противником не возвращает ресурс.")

/// Усиление сохраняет повреждения и срок жизни уже созданных печатей.
/datum/unit_test/heretic_lock_hinges/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/structure/heretic_lock_seal/seal = knowledge.create_seal(get_step(user, EAST), user)
	seal.take_damage(20, BRUTE, MELEE)
	var/original_expiry = seal.expires_at
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_hinges)
	TEST_ASSERT_EQUAL(seal.max_integrity, 90, "Изучение усиливает существующую печать.")
	TEST_ASSERT_EQUAL(seal.obj_integrity, 70, "Повреждение в 20 единиц сохраняется.")
	TEST_ASSERT_EQUAL(knowledge.seal_limit(), 10, "Изучение увеличивает общий предел до десяти.")
	var/datum/eldritch_knowledge/lock_hinges/hinges = heretic.get_knowledge(/datum/eldritch_knowledge/lock_hinges)
	hinges.passive_level = 3
	hinges.on_passive_upgrade(user)
	TEST_ASSERT_EQUAL(seal.max_integrity, 120, "Третий уровень даёт 120 прочности.")
	TEST_ASSERT_EQUAL(seal.obj_integrity, 100, "Покупка пассивки сохраняет прежние повреждения.")
	TEST_ASSERT_EQUAL(seal.expires_at, original_expiry, "Усиление не продлевает существование печати.")

/// Двор создаёт только предупреждённые свободные клетки и отклоняет старую подготовку после смерти.
/datum/unit_test/heretic_lock_court/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/turf/center = get_step(get_step(user, NORTHEAST), NORTHEAST)
	user.forceMove(center)
	var/list/positions = knowledge.court_turfs(center, user)
	TEST_ASSERT_EQUAL(length(positions), 8, "Открытый двор занимает восемь клеток вокруг центра.")
	TEST_ASSERT(!knowledge.raise_court(user, positions), "Начальный предел не вмещает полный двор.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Нехватка лимита не расходует ключи.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_hinges)
	var/generation = knowledge.court_generation
	knowledge.court_busy = TRUE
	knowledge.on_death(user)
	TEST_ASSERT(!knowledge.court_busy, "Смерть освобождает признак занятого заклинания.")
	TEST_ASSERT(!knowledge.raise_court(user, positions, expected_generation = generation), "Подготовка до смерти не завершается после возвращения в сознание.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Устаревшая подготовка не расходует ключи.")
	var/turf/blocked_place = positions[1]
	var/mob/living/blocker = allocate(/mob/living/carbon/human, blocked_place)
	TEST_ASSERT(knowledge.raise_court(user, positions, expected_generation = knowledge.court_generation), "Оставшиеся свободные места принимают двор.")
	TEST_ASSERT_EQUAL(length(knowledge.seals), 7, "Занятая после предупреждения клетка остаётся свободной от печати.")
	TEST_ASSERT_EQUAL(get_turf(blocker), blocked_place, "Создание двора не выталкивает занятого моба.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Весь двор стоит два ключа.")
	for(var/obj/structure/heretic_lock_seal/seal as anything in knowledge.seals)
		TEST_ASSERT(get_turf(seal) in positions, "Печати появляются только на предупреждённых клетках.")

/// Двор на предельной дальности сохраняет дальнюю стену и пропускает занятую после предупреждения клетку.
/datum/unit_test/heretic_lock_court_edge/Run()
	var/turf/origin = locate(run_loc_floor_bottom_left.x - 1, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/turf/center = locate(origin.x + 5, origin.y, origin.z)
	var/turf/edge = get_step(center, EAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(origin)
	heretic.selected_path = PATH_LOCK
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_hinges)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	TEST_ASSERT_EQUAL(length(knowledge.court_turfs(edge, user)), 0, "Центр двора нельзя выбрать дальше пяти клеток.")
	TEST_ASSERT_NULL(knowledge.create_seal(edge, user), "Отдельная печать сохраняет прежнюю дальность.")
	var/list/positions = knowledge.court_turfs(center, user)
	TEST_ASSERT_EQUAL(length(positions), 8, "Предупреждение включает все восемь клеток ограды.")
	TEST_ASSERT(knowledge.raise_court(user, positions), "На предельной дальности создаётся полный двор.")
	TEST_ASSERT_EQUAL(length(knowledge.seals), 8, "Дальняя сторона ограды появляется вместе с остальными.")
	TEST_ASSERT(locate(/obj/structure/heretic_lock_seal) in edge, "Печать перекрывает дальний выход.")
	QDEL_LIST(knowledge.seals)
	knowledge.gain_combat_resource(2)
	var/obj/structure/closet/crate/blocker = allocate(/obj/structure/closet/crate, edge)
	TEST_ASSERT(knowledge.raise_court(user, positions), "Преграда на одной клетке не отменяет остальные печати.")
	TEST_ASSERT_EQUAL(length(knowledge.seals), 7, "Занятая после предупреждения клетка пропускается.")
	TEST_ASSERT(!(locate(/obj/structure/heretic_lock_seal) in get_turf(blocker)), "Двор не появляется внутри новой преграды.")

/// Ритуальный ключ работает при пустом запасе, оплачивается здоровьем и связан с владельцем знания.
/datum/unit_test/heretic_lock_relic/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_key)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/lock_key/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/lock_key)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Обряд создаёт ритуальный ключ.")
	var/obj/item/heretic_path_relic/lock_key/key = recipe.new_path_relic_ref.resolve()
	allocated += key
	user.put_in_hands(key)
	key.cutting_time = 0
	TEST_ASSERT(!recipe.on_finished_recipe(user, list(), get_turf(user)), "Нельзя создать вторую работающую реликвию.")
	TEST_ASSERT(!key.cut_key(user), "Непустой запас не пополняется реликвией.")
	knowledge.combat_resource = 0
	TEST_ASSERT(key.cut_key(user), "При пустом запасе реликвия создаёт ключ.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Реликвия создаёт один ключ.")
	var/paid_damage = user.getBruteLoss()
	TEST_ASSERT(abs(paid_damage - 8) < 0.001, "Реликвия причиняет 8 ушибов.")
	knowledge.combat_resource = 0
	TEST_ASSERT(!key.cut_key(user), "Повторное применение ограничено перезарядкой.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), paid_damage, "Отказ не причиняет нового урона.")
	qdel(recipe)
	TEST_ASSERT(!key.authorized(user), "Удалённое знание отключает реликвию.")

/// Потеря тела удаляет печати, метки и только собственный экземпляр заклинания.
/datum/unit_test/heretic_lock_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_mark)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/lock_mark/mark_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/lock_mark)
	var/obj/structure/heretic_lock_seal/seal = knowledge.create_seal(get_step(user, EAST), user)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	mark_knowledge.on_mansus_grasp(victim, user, TRUE)
	var/datum/status_effect/eldritch/lock/mark = victim.has_status_effect(/datum/status_effect/eldritch/lock)
	var/obj/effect/proc_holder/spell/own_spell = knowledge.seal_spell
	var/obj/effect/proc_holder/spell/foreign_spell = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lock/seal)
	heretic.owner.AddSpell(foreign_spell)
	knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(seal), "Потеря тела удаляет печать.")
	TEST_ASSERT(QDELETED(mark), "Потеря тела снимает наложенную метку с чужого тела.")
	TEST_ASSERT(QDELETED(own_spell), "Потеря тела удаляет выданное знанием заклинание.")
	TEST_ASSERT(!QDELETED(foreign_spell), "Чужой экземпляр такого же заклинания сохраняется.")
	TEST_ASSERT_NULL(knowledge.lock_body, "Ссылка на старое тело очищается.")
	TEST_ASSERT_EQUAL(length(knowledge.seals) + length(knowledge.marks), 0, "В списках не остаётся старых эффектов.")
	knowledge.on_body_gain(user)
	TEST_ASSERT_NOTNULL(knowledge.seal_spell, "Новое получение тела восстанавливает способность.")
	var/obj/structure/heretic_lock_seal/expiring = knowledge.create_seal(get_step(user, EAST), user, lifetime = 0.1 SECONDS)
	TEST_ASSERT_NOTNULL(expiring, "Короткая печать создана.")
	TEST_ASSERT(wait_for_qdeleted(expiring), "По истечении срока печать удаляется сама.")
	TEST_ASSERT_EQUAL(length(knowledge.seals), 0, "Истечение срока освобождает общий предел.")

/datum/unit_test/proc/allocate_lock_passage()
	var/turf/first_place = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/turf/second_place = get_step(get_step(get_step(get_step(first_place, EAST), EAST), EAST), EAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(first_place)
	heretic.selected_path = PATH_LOCK
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/lock_key)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/lock_key/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/lock_key)
	recipe.on_finished_recipe(user, list(), first_place)
	var/obj/item/heretic_path_relic/lock_key/key = recipe.new_path_relic_ref.resolve()
	allocated += key
	user.put_in_hands(key)
	key.passage_time = 0
	var/obj/machinery/door/airlock/first_door = allocate(/obj/machinery/door/airlock, get_step(first_place, NORTH))
	var/obj/machinery/door/airlock/second_door = allocate(/obj/machinery/door/airlock, get_step(second_place, NORTH))
	user.a_intent = INTENT_HELP
	key.melee_attack_chain(user, first_door, attackchain_flags = ATTACK_IGNORE_CLICKDELAY)
	user.forceMove(second_place)
	key.melee_attack_chain(user, second_door, attackchain_flags = ATTACK_IGNORE_CLICKDELAY)
	user.forceMove(first_place)
	return list("heretic" = heretic, "key" = key, "first_door" = first_door, "second_door" = second_door, "first_place" = first_place, "second_place" = second_place)

/// Связанные шлюзы переносят владельца между выбранными сторонами без открытия дверей и сквозь помещения.
/datum/unit_test/heretic_lock_threshold_passage/Run()
	var/list/fixture = allocate_lock_passage()
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/item/heretic_path_relic/lock_key/key = fixture["key"]
	var/obj/machinery/door/airlock/first_door = fixture["first_door"]
	var/obj/machinery/door/airlock/second_door = fixture["second_door"]
	TEST_ASSERT_EQUAL(length(knowledge.thresholds), 2, "Касание ключом создаёт два порога.")
	TEST_ASSERT(first_door.density && second_door.density, "Разметка ключом не открывает шлюзы обычным взаимодействием.")
	var/obj/structure/blocker = allocate(/obj/structure, get_step(fixture["first_place"], EAST))
	blocker.density = TRUE
	blocker.opacity = TRUE
	first_door.bolt()
	second_door.bolt()
	knowledge.gain_combat_resource(2)
	var/atom/movable/screen/alert/heretic_resource/indicator = user.alerts["heretic_path_resource"]
	TEST_ASSERT_EQUAL(indicator.displayed_value, 4, "Перед переходом HUD показывает полный запас.")
	var/keys_before = knowledge.combat_resource
	user.a_intent = INTENT_HARM
	key.melee_attack_chain(user, first_door, attackchain_flags = ATTACK_IGNORE_CLICKDELAY)
	TEST_ASSERT_EQUAL(get_turf(user), fixture["second_place"], "Выход ведёт на выбранную при связывании сторону.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, keys_before - 1, "Успешный переход тратит один ключ.")
	TEST_ASSERT_EQUAL(indicator.displayed_value, 3, "Переход уменьшает полный запас на HUD.")
	TEST_ASSERT(first_door.locked && first_door.density && second_door.locked && second_door.density, "Переход не открывает и не отпирает обычные шлюзы.")
	TEST_ASSERT(!key.traverse(user, second_door), "Обратный переход соблюдает общий интервал.")
	COOLDOWN_RESET(key, passage_cooldown)
	TEST_ASSERT(key.traverse(user, second_door), "После интервала пара работает в обратную сторону.")
	TEST_ASSERT_EQUAL(get_turf(user), fixture["first_place"], "Обратный переход возвращает на исходную сторону шлюза.")
	TEST_ASSERT_EQUAL(length(knowledge.thresholds), 2, "Переход не расходует сами пороги.")
	user.a_intent = INTENT_HELP
	key.melee_attack_chain(user, first_door, attackchain_flags = ATTACK_IGNORE_CLICKDELAY)
	TEST_ASSERT_EQUAL(length(knowledge.thresholds), 1, "Повторное нажатие на помощи снимает метку.")

/// Сварка, занятый выход, запрет телепортации, чужой ключ и перенос двери блокируют проход без оплаты.
/datum/unit_test/heretic_lock_threshold_safety/Run()
	var/list/fixture = allocate_lock_passage()
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/item/heretic_path_relic/lock_key/key = fixture["key"]
	var/obj/machinery/door/airlock/first_door = fixture["first_door"]
	var/obj/machinery/door/airlock/second_door = fixture["second_door"]
	TEST_ASSERT_EQUAL(length(knowledge.thresholds), 2, "Для проверки нужны два порога.")
	var/keys_before = knowledge.combat_resource
	user.forceMove(get_step(fixture["first_place"], EAST))
	TEST_ASSERT(!key.traverse(user, first_door), "Соседняя с меткой клетка не позволяет перейти.")
	user.forceMove(fixture["first_place"])
	knowledge.spend_combat_resource(keys_before)
	TEST_ASSERT(!key.traverse(user, first_door), "Ритуальный предмет не заменяет ключ в запасе пути.")
	knowledge.gain_combat_resource(keys_before)
	second_door.welded = TRUE
	TEST_ASSERT(!key.traverse(user, first_door), "Сварка выходного шлюза запирает проход.")
	second_door.welded = FALSE
	var/obj/structure/blocker = allocate(/obj/structure, fixture["second_place"])
	blocker.density = TRUE
	TEST_ASSERT(!key.traverse(user, first_door), "Плотный предмет на выходе запирает проход.")
	qdel(blocker)
	ADD_TRAIT(user, TRAIT_NO_TELEPORT, "unit_test")
	TEST_ASSERT(!key.traverse(user, first_door), "Запрет телепортации на владельце сохраняется.")
	REMOVE_TRAIT(user, TRAIT_NO_TELEPORT, "unit_test")
	var/area/place_area = get_area(user)
	var/original_flags = place_area.area_flags
	place_area.area_flags |= NOTELEPORT
	var/blocked_by_area = !key.traverse(user, first_door)
	place_area.area_flags = original_flags
	TEST_ASSERT(blocked_by_area, "Запрет телепортации области сохраняется.")
	var/turf/door_place = get_turf(second_door)
	second_door.forceMove(get_step(door_place, EAST))
	TEST_ASSERT(!key.traverse(user, first_door), "Перемещённый шлюз не оставляет работающий выход на прежнем месте.")
	second_door.forceMove(door_place)
	heretic.selected_path = PATH_TIDE
	TEST_ASSERT(!key.traverse(user, first_door), "Выбор другого пути отключает проход.")
	heretic.selected_path = PATH_LOCK
	heretic.role_removed = TRUE
	TEST_ASSERT(!key.traverse(user, first_door), "Снятая роль отключает проход.")
	heretic.role_removed = FALSE
	user.dropItemToGround(key)
	TEST_ASSERT(!key.traverse(user, first_door), "Ключ на полу не открывает проход.")
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(user, SOUTH))
	other.selected_path = PATH_LOCK
	other.owner.current.put_in_hands(key)
	TEST_ASSERT(!key.traverse(other.owner.current, first_door), "Чужой разум не может воспользоваться ключом.")
	other.owner.current.dropItemToGround(key)
	user.put_in_hands(key)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, keys_before, "Отклонённые переходы не расходуют ключи.")
	TEST_ASSERT_EQUAL(get_turf(user), fixture["first_place"], "Отклонённые переходы не перемещают владельца.")
	TEST_ASSERT(key.traverse(user, first_door), "После снятия помех подготовленная пара снова работает.")

/// Разрушение порога во время подготовки отменяет переход; удаление знания и смерть очищают якоря.
/datum/unit_test/heretic_lock_threshold_cleanup/Run()
	var/list/fixture = allocate_lock_passage()
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/item/heretic_path_relic/lock_key/key = fixture["key"]
	var/obj/machinery/door/airlock/first_door = fixture["first_door"]
	var/obj/machinery/door/airlock/second_door = fixture["second_door"]
	TEST_ASSERT_EQUAL(length(knowledge.thresholds), 2, "Для проверки нужны два порога.")
	var/obj/structure/heretic_lock_threshold/destination = knowledge.threshold_destination(user, first_door)
	var/keys_before = knowledge.combat_resource
	key.passage_time = 1 SECONDS
	QDEL_IN(destination, 0.1 SECONDS)
	TEST_ASSERT(!key.traverse(user, first_door), "Разрушение выхода во время подготовки отменяет переход.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, keys_before, "Отмена подготовки не расходует ключ.")
	TEST_ASSERT_EQUAL(get_turf(user), fixture["first_place"], "Отмена оставляет владельца у входа.")
	TEST_ASSERT(!key.busy, "После отмены ключ освобождается для следующего действия.")
	user.forceMove(fixture["second_place"])
	TEST_ASSERT(knowledge.bind_threshold(user, second_door), "Вместо разрушенного порога можно создать новый.")
	var/obj/structure/heretic_lock_threshold/first = knowledge.thresholds[1]
	var/obj/structure/heretic_lock_threshold/second = knowledge.thresholds[2]
	knowledge.on_death(user)
	TEST_ASSERT(QDELETED(first) && QDELETED(second), "Смерть удаляет оба порога.")
	TEST_ASSERT_EQUAL(length(knowledge.thresholds), 0, "Смерть освобождает список якорей.")
	TEST_ASSERT(knowledge.bind_threshold(user, second_door), "После очистки можно начать новую пару.")
	var/datum/eldritch_knowledge/lock_key/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/lock_key)
	qdel(recipe)
	TEST_ASSERT_EQUAL(length(knowledge.thresholds), 0, "Удаление Ключницы убирает оставшийся порог.")
	TEST_ASSERT(!key.authorized(user), "Потеря знания отключает ритуальный ключ.")

/datum/unit_test/proc/ascend_lock_fixture()
	var/datum/antagonist/heretic/heretic = allocate_heretic(run_loc_floor_bottom_left)
	heretic.selected_path = PATH_LOCK
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/lock_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/lock_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/lock_final)
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(user)
	return list("user" = user, "heretic" = heretic, "finale" = finale, "knowledge" = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock))

/datum/unit_test/proc/lock_keeper_turf(offset_x, offset_y)
	return locate(run_loc_floor_bottom_left.x + offset_x, run_loc_floor_bottom_left.y + offset_y, run_loc_floor_bottom_left.z)

/// Ключник перечисляет шлюзы в радиусе без двойников, заваренных и запретных помещений и выводит на клетку выбранного.
/datum/unit_test/heretic_lock_keeper_passage/Run()
	var/list/fixture = ascend_lock_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_lock/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/final_eldritch/lock_final/finale = fixture["finale"]
	var/obj/effect/proc_holder/spell/self/heretic_lock/keeper/spell = locate() in finale.ascension_spell_instances
	TEST_ASSERT_NOTNULL(spell, "Вознесение Замка даёт Ключника.")
	TEST_ASSERT_EQUAL(spell.charge_max, HERETIC_LOCK_KEEPER_COOLDOWN, "Ключник перезаряжается 10 секунд.")
	var/obj/machinery/door/airlock/north_exit = allocate(/obj/machinery/door/airlock, lock_keeper_turf(0, 4))
	TEST_ASSERT_EQUAL(length(knowledge.keeper_destinations(user)), 0, "Без шлюза рядом Ключник не открывает переходов.")
	var/obj/machinery/door/airlock/entry = allocate(/obj/machinery/door/airlock, lock_keeper_turf(1, 0))
	var/obj/machinery/door/airlock/far_exit = allocate(/obj/machinery/door/airlock, lock_keeper_turf(4, 2))
	var/obj/machinery/door/airlock/twin = allocate(/obj/machinery/door/airlock, lock_keeper_turf(4, 3))
	var/obj/machinery/door/airlock/same_label = allocate(/obj/machinery/door/airlock, lock_keeper_turf(2, 4))
	var/obj/machinery/door/airlock/welded = allocate(/obj/machinery/door/airlock, lock_keeper_turf(3, 0))
	welded.welded = TRUE
	var/list/destinations = knowledge.keeper_destinations(user)
	var/list/doors = list()
	var/list/labels = list()
	for(var/label in destinations)
		doors += destinations[label]
		labels[destinations[label]] = label
	TEST_ASSERT((north_exit in doors) && (far_exit in doors), "Шлюзы в радиусе доступны для выхода.")
	TEST_ASSERT(!(entry in doors), "Шлюз, у которого стоит еретик, не предлагается выходом.")
	TEST_ASSERT(!(twin in doors), "Соседняя створка того же проёма не дублирует выход.")
	TEST_ASSERT(!(welded in doors), "Заваренный шлюз не становится выходом.")
	TEST_ASSERT(same_label in doors, "Отдельный шлюз с тем же направлением и расстоянием сохраняется.")
	TEST_ASSERT(findtext(labels[north_exit], "север") && findtext(labels[north_exit], "4 кл."), "Подпись выхода называет направление и расстояние: [labels[north_exit]].")
	TEST_ASSERT(findtext(labels[same_label], "(2)"), "Совпадающая подпись получает номер: [labels[same_label]].")
	TEST_ASSERT(!(far_exit in knowledge.keeper_destinations(user, 3)), "Шлюз дальше радиуса не предлагается.")
	var/area/room = get_area(user)
	var/original_flags = room.area_flags
	room.area_flags |= NOTELEPORT
	var/area_destinations = length(knowledge.keeper_destinations(user))
	var/area_teleport = knowledge.keeper_teleport(user, north_exit)
	room.area_flags = original_flags
	TEST_ASSERT_EQUAL(area_destinations, 0, "Помещение без телепортации закрыто для Ключника.")
	TEST_ASSERT(!area_teleport, "Запрет телепортации не пропускает переход.")
	TEST_ASSERT(knowledge.keeper_teleport(user, north_exit), "Ключник выводит через выбранный шлюз.")
	TEST_ASSERT_EQUAL(get_turf(user), get_turf(north_exit), "Еретик стоит на клетке выбранного шлюза.")
	addtimer(VARSET_CALLBACK(far_exit, welded, TRUE), 0.2 SECONDS)
	TEST_ASSERT(!knowledge.keeper_travel(user, far_exit), "Сварка выхода во время подготовки срывает переход.")
	TEST_ASSERT_EQUAL(get_turf(user), get_turf(north_exit), "Сорванный переход оставляет еретика на месте.")
	far_exit.welded = FALSE
	TEST_ASSERT(knowledge.keeper_travel(user, far_exit), "Секунда подготовки у шлюза открывает переход.")
	TEST_ASSERT_EQUAL(get_turf(user), get_turf(far_exit), "Переход с подготовкой приводит к выбранному шлюзу.")
	finale.on_body_lose(user)
	TEST_ASSERT(!knowledge.keeper_teleport(user, north_exit), "Без вознесения Ключник не работает.")

/// Шлюз за спиной вознёсшегося Замка закрывается на болты на 8 секунд; проём с человеком и чужие болты не трогаются.
/datum/unit_test/heretic_lock_keeper_bolts/Run()
	var/list/fixture = ascend_lock_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/lock_final/finale = fixture["finale"]
	var/datum/component/heretic_lock_keeper/keeper = user.GetComponent(/datum/component/heretic_lock_keeper)
	TEST_ASSERT_NOTNULL(keeper, "Вознесение Замка запирает шлюзы за героем.")
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, lock_keeper_turf(1, 0))
	door.machine_stat &= ~NOPOWER
	door.open(2)
	TEST_ASSERT(!door.density, "Шлюз открыт перед проходом.")
	user.forceMove(get_turf(door))
	user.forceMove(lock_keeper_turf(2, 0))
	TEST_ASSERT(wait_for_var(door, "locked", TRUE, 3 SECONDS), "Пройденный шлюз закрывается и опускает болты.")
	TEST_ASSERT(door.density, "Запертый за героем шлюз закрыт.")
	var/remaining = timeleft(keeper.bolted[door])
	TEST_ASSERT(remaining > HERETIC_LOCK_KEEPER_BOLT_TIME - 1 SECONDS && remaining <= HERETIC_LOCK_KEEPER_BOLT_TIME + world.tick_lag, "Болты держатся 8 секунд, осталось [remaining].")
	keeper.release_bolt(door)
	TEST_ASSERT(!door.locked && door.density, "По сроку болты поднимаются, шлюз остаётся закрытым.")
	TEST_ASSERT(!(door in keeper.bolted), "Освобождённый шлюз больше не отслеживается.")
	TEST_ASSERT(keeper.seal_behind(door), "Закрытый пустой шлюз запирается сразу.")
	door.unbolt()
	TEST_ASSERT(!(door in keeper.bolted), "Поднятые кем угодно болты больше не считаются болтами еретика.")
	door.bolt()
	keeper.release_bolt(door)
	TEST_ASSERT(door.locked, "Срок не поднимает болты, опущенные после этого кем-то другим.")
	door.unbolt()
	var/mob/living/carbon/human/bystander = allocate(/mob/living/carbon/human, get_turf(door))
	TEST_ASSERT(!keeper.seal_behind(door), "Шлюз с человеком в проёме не запирается.")
	TEST_ASSERT(!door.locked, "Болты не опускаются на человека.")
	bystander.forceMove(lock_keeper_turf(2, 2))
	var/list/examine_lines = list()
	SEND_SIGNAL(user, COMSIG_PARENT_EXAMINE, bystander, examine_lines)
	TEST_ASSERT(findtext(jointext(examine_lines, " "), "мультитул"), "Осмотр подсказывает, как снять болты.")
	TEST_ASSERT(keeper.seal_behind(door), "Опустевший проём снова запирается.")
	keeper.release_bolt(door)
	door.machine_stat |= NOPOWER
	TEST_ASSERT(!keeper.seal_behind(door), "Шлюз без питания не запирается.")
	TEST_ASSERT(!door.locked, "Болты шлюза без питания не опускаются.")
	door.machine_stat &= ~NOPOWER
	TEST_ASSERT(keeper.seal_behind(door), "С питанием шлюз снова запирается.")
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_lock_keeper), "Потеря тела снимает Ключника.")
	TEST_ASSERT(!door.locked, "Потеря тела поднимает болты Ключника.")

/// Выбор Ключника держится до конца перехода: за секунду подготовки второй выбор не открыть, после перехода идёт перезарядка.
/datum/unit_test/heretic_lock_keeper_choice_lock/Run()
	var/list/fixture = ascend_lock_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_lock/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/final_eldritch/lock_final/finale = fixture["finale"]
	var/obj/effect/proc_holder/spell/self/heretic_lock/keeper/spell = locate() in finale.ascension_spell_instances
	allocate(/obj/machinery/door/airlock, lock_keeper_turf(1, 0))
	var/obj/machinery/door/airlock/exit = allocate(/obj/machinery/door/airlock, lock_keeper_turf(4, 2))
	spell.charge_counter = spell.charge_max
	TEST_ASSERT(spell.can_cast(user, FALSE, TRUE), "У шлюза Ключник готов.")
	INVOKE_ASYNC(spell, TYPE_PROC_REF(/obj/effect/proc_holder/spell/self/heretic_lock/keeper, pass_through), user, knowledge, exit)
	TEST_ASSERT(spell.choosing, "Во время подготовки выбор ещё не закрыт.")
	TEST_ASSERT(!spell.can_cast(user, FALSE, TRUE), "Во время подготовки второй выбор не открыть.")
	TEST_ASSERT(wait_for_var(spell, "choosing", FALSE, 3 SECONDS), "Переход завершается.")
	TEST_ASSERT_EQUAL(get_turf(user), get_turf(exit), "Еретик вышел из выбранного шлюза.")
	TEST_ASSERT(spell.charge_counter < spell.charge_max, "После перехода идёт перезарядка.")

/// Без знания пути Замка вознесение не вешает на тело запирание шлюзов.
/datum/unit_test/heretic_lock_final_requires_path/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(run_loc_floor_bottom_left)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/lock_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/lock_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/lock_final)
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_lock_keeper), "Без Тайны привратника шлюзы за спиной не запираются.")
	finale.on_body_lose(user)

/// Ключник: у обоих шлюзов открываются скважины, их связывает нить; переход рассыпает героя у входа и собирает у выхода, сорванный переход гасит порталы.
/datum/unit_test/heretic_lock_keeper_visuals/Run()
	var/list/fixture = ascend_lock_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_lock/knowledge = fixture["knowledge"]
	var/obj/machinery/door/airlock/entry = allocate(/obj/machinery/door/airlock, lock_keeper_turf(1, 0))
	var/obj/machinery/door/airlock/exit = allocate(/obj/machinery/door/airlock, lock_keeper_turf(4, 2))
	var/turf/origin = get_turf(user)
	INVOKE_ASYNC(knowledge, TYPE_PROC_REF(/datum/eldritch_knowledge/base_lock, keeper_travel), user, exit)
	var/obj/effect/temp_visual/heretic_lock_portal/entry_portal = locate() in get_turf(entry)
	var/obj/effect/temp_visual/heretic_lock_portal/exit_portal = locate() in get_turf(exit)
	TEST_ASSERT_NOTNULL(entry_portal, "У входного шлюза открывается скважина.")
	TEST_ASSERT_NOTNULL(exit_portal, "У выходного шлюза открывается скважина.")
	TEST_ASSERT(entry_portal.ring in entry_portal.vis_contents, "Вокруг скважины щёлкает зубчатое колесо.")
	TEST_ASSERT(length(entry_portal.overlays) && length(entry_portal.ring.overlays), "Портал светится в темноте.")
	TEST_ASSERT(entry_portal.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Портал не мешает кликам.")
	var/obj/effect/temp_visual/heretic_vfx/thread/thread = locate() in get_turf(entry)
	TEST_ASSERT_NOTNULL(thread, "Порталы связаны золотой нитью.")
	TEST_ASSERT_EQUAL(round(thread.angle), round(Get_Angle(get_turf(entry), get_turf(exit))), "Нить тянется к выходу.")
	TEST_ASSERT(!entry_portal.closing && !thread.settled, "Пока идёт подготовка, портал открыт и нить натянута.")
	TEST_ASSERT(wait_for_var(entry_portal, "closing", TRUE, 3 SECONDS), "Переход закрывает портал.")
	TEST_ASSERT_EQUAL(get_turf(user), get_turf(exit), "Герой вышел из выбранного шлюза, как раньше.")
	var/obj/effect/temp_visual/heretic_vfx/ghost/dissolve = locate() in origin
	TEST_ASSERT_NOTNULL(dissolve, "У входа герой рассыпается золотым призраком.")
	var/obj/effect/temp_visual/heretic_vfx/ghost/reform = locate() in get_turf(exit)
	TEST_ASSERT_NOTNULL(reform, "У выхода герой собирается из золота.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_vfx/converge) in get_turf(exit), "Ключи и искры стягиваются к выходу.")
	TEST_ASSERT(exit_portal.closing && thread.settled, "Второй портал и нить сходятся вместе с переходом.")
	TEST_ASSERT(wait_for_qdeleted(entry_portal) && wait_for_qdeleted(exit_portal), "Порталы исчезают.")
	TEST_ASSERT(wait_for_qdeleted(thread) && wait_for_qdeleted(dissolve) && wait_for_qdeleted(reform), "Нить и призраки гаснут.")
	var/obj/machinery/door/airlock/second_exit = allocate(/obj/machinery/door/airlock, lock_keeper_turf(0, 4))
	INVOKE_ASYNC(knowledge, TYPE_PROC_REF(/datum/eldritch_knowledge/base_lock, keeper_travel), user, second_exit)
	var/obj/effect/temp_visual/heretic_lock_portal/doomed = locate() in get_turf(second_exit)
	TEST_ASSERT_NOTNULL(doomed, "Новый переход снова открывает скважину.")
	second_exit.welded = TRUE
	TEST_ASSERT(wait_for_var(doomed, "closing", TRUE, 3 SECONDS), "Сорванный переход гасит портал.")
	TEST_ASSERT_EQUAL(get_turf(user), get_turf(exit), "Сорванный переход оставляет героя на месте.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_vfx/ghost) in get_turf(second_exit), "Без перехода никто не собирается у выхода.")
	TEST_ASSERT(wait_for_qdeleted(doomed), "Погасший портал исчезает.")

/// Болты Ключника и хватки щёлкают над шлюзом замком-глифом с золотыми искрами.
/datum/unit_test/heretic_lock_bolt_visuals/Run()
	var/list/fixture = ascend_lock_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_lock/knowledge = fixture["knowledge"]
	var/datum/component/heretic_lock_keeper/keeper = user.GetComponent(/datum/component/heretic_lock_keeper)
	var/obj/machinery/door/airlock/door = allocate(/obj/machinery/door/airlock, lock_keeper_turf(1, 0))
	door.machine_stat &= ~NOPOWER
	var/turf/door_turf = get_turf(door)
	var/list/before = list_vfx_bursts(door_turf)
	TEST_ASSERT(keeper.seal_behind(door), "Шлюз за героем запирается, как раньше.")
	TEST_ASSERT(door.locked, "Болты опущены.")
	var/obj/effect/temp_visual/heretic_lock_click/click = locate() in door_turf
	TEST_ASSERT_NOTNULL(click, "Над шлюзом щёлкает замок.")
	TEST_ASSERT(length(click.overlays), "Замок светится в темноте.")
	TEST_ASSERT(click.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Замок не мешает кликам.")
	var/obj/effect/temp_visual/heretic_vfx/burst/sparks = find_vfx_burst(door_turf, /particles/heretic_ascension/lock/click, before)
	TEST_ASSERT_NOTNULL(sparks, "Щелчок выбивает золотые искры.")
	var/obj/machinery/door/airlock/second = allocate(/obj/machinery/door/airlock, lock_keeper_turf(0, 1))
	TEST_ASSERT(knowledge.bolt_door(second, user), "Хватка на вреде запирает шлюз, как раньше.")
	var/obj/effect/temp_visual/heretic_lock_click/grasp_click = locate() in get_turf(second)
	TEST_ASSERT_NOTNULL(grasp_click, "Запирание хваткой тоже щёлкает замком.")
	TEST_ASSERT(wait_for_qdeleted(click) && wait_for_qdeleted(grasp_click), "Замки гаснут.")
	TEST_ASSERT(wait_for_qdeleted(sparks, 3 SECONDS), "Искры догорают.")
	knowledge.release_grasp_bolt(second)
	keeper.release_bolt(door)

/// Дом без стен: над героем проворачивается ключ, по готовности печати поднимаются, идёт золотая волна; сорванный обряд гасит ключ без печатей.
/datum/unit_test/heretic_lock_house_visuals/Run()
	var/list/fixture = ascend_lock_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_lock/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/final_eldritch/lock_final/finale = fixture["finale"]
	var/obj/effect/proc_holder/spell/self/heretic_lock/house/spell = locate() in finale.ascension_spell_instances
	user.forceMove(lock_keeper_turf(2, 2))
	var/turf/center = get_turf(user)
	var/list/before = list_vfx_bursts(center)
	INVOKE_ASYNC(spell, TYPE_PROC_REF(/obj/effect/proc_holder/spell, cast), list(user), user)
	var/obj/effect/temp_visual/heretic_lock_house_key/key = locate() in center
	TEST_ASSERT_NOTNULL(key, "Над героем появляется ключ Дома.")
	TEST_ASSERT(key.pixel_y > 0, "Ключ висит над головой.")
	TEST_ASSERT(length(key.overlays), "Ключ светится в темноте.")
	TEST_ASSERT(!key.released, "Пока идёт подготовка, ключ проворачивается.")
	TEST_ASSERT(wait_for_var(knowledge, "court_busy", FALSE, 4 SECONDS), "Дом поднимается.")
	TEST_ASSERT_EQUAL(length(knowledge.seals), 16, "Печатей шестнадцать, как раньше.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, knowledge.combat_resource_max, "Ключи восполнены, как раньше.")
	TEST_ASSERT(key.released, "Ключ доворачивается и уходит в героя.")
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = locate() in center
	TEST_ASSERT_NOTNULL(wave, "От героя идёт золотая волна.")
	var/obj/effect/temp_visual/heretic_vfx/burst/sparks = find_vfx_burst(center, /particles/heretic_ascension/lock, before)
	TEST_ASSERT_NOTNULL(sparks, "Ключи и искры разлетаются.")
	TEST_ASSERT(wait_for_qdeleted(key) && wait_for_qdeleted(wave), "Ключ и волна гаснут.")
	knowledge.clear_lock_effects()
	spell.charge_counter = spell.charge_max
	INVOKE_ASYNC(spell, TYPE_PROC_REF(/obj/effect/proc_holder/spell, cast), list(user), user)
	var/obj/effect/temp_visual/heretic_lock_house_key/doomed = locate() in center
	TEST_ASSERT_NOTNULL(doomed, "Новый обряд снова поднимает ключ.")
	user.forceMove(lock_keeper_turf(1, 2))
	TEST_ASSERT(wait_for_var(doomed, "released", TRUE, 4 SECONDS), "Сорванный обряд гасит ключ.")
	TEST_ASSERT_EQUAL(length(knowledge.seals), 0, "Сорванный обряд не ставит печатей.")
	TEST_ASSERT(wait_for_qdeleted(doomed), "Погасший ключ исчезает.")

/datum/unit_test/heretic_lock_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_lock_portal, /obj/effect/abstract/heretic_lock_portal_ring, /obj/effect/temp_visual/heretic_lock_click, /obj/effect/temp_visual/heretic_lock_house_key))
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")

/// Колесо скважины сразу щёлкает на первый зубец, ключ доворачивает его вперёд от него; полупрозрачный герой собирается у выхода бледнее.
/datum/unit_test/heretic_lock_passage_ghost_and_wheel/Run()
	var/obj/effect/abstract/heretic_lock_portal_ring/ring = allocate(/obj/effect/abstract/heretic_lock_portal_ring)
	ring.spun_at = world.time
	TEST_ASSERT_EQUAL(ring.current_tooth(), 1, "Первый щелчок ставит колесо на первый зубец.")
	var/datum/eldritch_knowledge/base_lock/lock = allocate(/datum/eldritch_knowledge/base_lock)
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, origin)
	var/turf/solid_landing = locate(origin.x + 2, origin.y, origin.z)
	var/turf/pale_landing = locate(origin.x + 4, origin.y, origin.z)
	lock.keeper_passage_fx(user, origin, solid_landing)
	var/obj/effect/temp_visual/heretic_vfx/ghost/solid = locate() in solid_landing
	TEST_ASSERT_NOTNULL(solid, "У выхода герой собирается из золота.")
	user.alpha = 100
	lock.keeper_passage_fx(user, origin, pale_landing)
	var/obj/effect/temp_visual/heretic_vfx/ghost/pale = locate() in pale_landing
	TEST_ASSERT(solid.peak_alpha > pale?.peak_alpha, "Полупрозрачный герой собирается бледнее: [solid.peak_alpha] и [pale?.peak_alpha].")
	TEST_ASSERT_EQUAL(pale?.peak_alpha, round(solid.peak_alpha * 100 / 255), "Призрак бледнеет в той же доле, что и герой.")
	TEST_ASSERT(wait_for_qdeleted(solid) && wait_for_qdeleted(pale), "Призраки гаснут.")
