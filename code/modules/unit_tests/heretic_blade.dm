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
	var/datum/eldritch_knowledge/blade_riposte/riposte = allocate(/datum/eldritch_knowledge/blade_riposte)
	heretic.researched_knowledge[riposte.type] = riposte
	knowledge.ascension_active = TRUE
	user.apply_status_effect(/datum/status_effect/heretic_blade_dance)
	user.adjustBruteLoss(10)
	knowledge.riposte_ready_at = world.time
	TEST_ASSERT(knowledge.try_riposte(attacker, user), "После предупреждения попадание проводит финт.")
	TEST_ASSERT(abs(attacker.getBruteLoss() - 10) < DAMAGE_PRECISION, "Вознесение не усиливает десять ушибов финта.")
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
	TEST_ASSERT(abs(attacker.getBruteLoss() - 40) < DAMAGE_PRECISION, "Ответ сохраняет 18 ушибов и 12 от вознесения.")
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

/// Начальный Темп позволяет открыть бой выпадом; хватка базы сама Темп не даёт.
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
	TEST_ASSERT(abs(attacker.AmountKnockdown() - 1.5 SECONDS) <= world.tick_lag, "Успешное сближение оставляет время на следующий удар.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Сближение расходует один Темп.")
	TEST_ASSERT(!knowledge.on_mansus_grasp(attacker, user, TRUE), "Хватка базы ничего не делает сама.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Хватка без метки не пополняет Темп.")

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
	user.setDir(EAST)
	var/obj/item/projectile/shot = blade_test_shot(attacker, user)
	TEST_ASSERT(user.do_run_block(TRUE, shot, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS, "Выстрел спереди отбит стойкой.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Второй удар в тот же момент расходует следующий блок.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 2, "Каждое парирование даёт один Темп.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "третий удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Третий удар расходует последний блок.")
	TEST_ASSERT_NULL(knowledge.active_parry, "Обычная стойка заканчивается после трёх ударов.")
	TEST_ASSERT(!(user.do_run_block(TRUE, blade, 20, "четвёртый удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS), "После исчерпания стойки нет бесплатного блока.")

/// Живая дубинка блокируется целиком, а HUD показывает запас, помехи и окончание стойки.
/datum/unit_test/heretic_blade_baton_guard/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/melee/baton/loaded/baton = allocate(/obj/item/melee/baton/loaded, get_turf(attacker))
	baton.switch_status(TRUE, TRUE)
	TEST_ASSERT(knowledge.begin_parry(user), "Стойка должна включиться со свободной рукой.")
	var/datum/status_effect/heretic_parry/parry = knowledge.active_parry
	var/atom/movable/screen/alert/status_effect/indicator = parry.linked_alert
	TEST_ASSERT(indicator && indicator == user.alerts["heretic_parry"], "Активная стойка видна на HUD.")
	TEST_ASSERT(indicator.icon_state in icon_states(indicator.icon), "Значок стойки существует в листе иконок.")
	var/charge_before = baton.cell.charge
	TEST_ASSERT(!baton.baton_stun(user, attacker, shoving = TRUE), "Парирование должно остановить удар заряженной дубинки.")
	TEST_ASSERT_EQUAL(user.getStaminaLoss(), 0, "Перехват не пропускает урон выносливости.")
	TEST_ASSERT(!user.lying && !user.has_status_effect(STATUS_EFFECT_OFF_BALANCE), "Перехват не пропускает сбивание с ног и потерю равновесия.")
	TEST_ASSERT_EQUAL(baton.cell.charge, charge_before, "Заблокированный контакт не разряжает дубинку.")
	TEST_ASSERT_EQUAL(parry.blocks_left, 2, "Удар дубинкой расходует один блок.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Блок дубинки даёт Темп.")
	TEST_ASSERT(findtext(indicator.desc, "блоков: 2"), "HUD сразу показывает уменьшенный запас.")
	var/obj/item/offhand = allocate(/obj/item, get_turf(user))
	TEST_ASSERT(user.put_in_hands(offhand), "Вторая рука должна стать занятой.")
	parry.tick()
	TEST_ASSERT(!parry.stance_ready && findtext(indicator.desc, "Освободите вторую руку"), "HUD показывает причину неработающей защиты.")
	TEST_ASSERT(!knowledge.begin_parry(user), "Занятая рука не позволяет заново начать парирование.")
	user.dropItemToGround(offhand)
	parry.tick()
	TEST_ASSERT(parry.stance_ready, "Освобождение руки возвращает защиту в пределах прежнего окна.")
	parry.expires_at = world.time
	parry.tick()
	TEST_ASSERT_NULL(knowledge.active_parry, "По истечении времени стойка прекращается.")
	TEST_ASSERT(QDELETED(indicator) && !user.alerts["heretic_parry"], "Истёкшая стойка не оставляет ложный значок.")
	TEST_ASSERT(baton.baton_stun(user, attacker, shoving = TRUE), "После окончания стойки дубинка снова поражает цель.")
	TEST_ASSERT(user.getStaminaLoss() > 0, "Незаблокированный удар действительно наносит урон выносливости.")
	TEST_ASSERT(user.lying && user.has_status_effect(STATUS_EFFECT_OFF_BALANCE), "Незаблокированный удар сбивает с ног и лишает равновесия.")

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

/datum/unit_test/proc/ascend_blade_fixture(list/fixture)
	var/mob/living/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/final_eldritch/blade_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	heretic.researched_knowledge[finale.type] = finale
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	return finale

/// Орбита вознесения: четыре клинка, каждый целиком принимает один снаряд или удар, стойка забирает атаку себе.
/datum/unit_test/heretic_blade_orbit/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/blade = fixture["blade"]
	ascend_blade_fixture(fixture)
	var/datum/component/heretic_blade_orbit/orbit = user.GetComponent(/datum/component/heretic_blade_orbit)
	TEST_ASSERT_NOTNULL(orbit, "Вознесение даёт орбиту клинков.")
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), 4, "Орбита начинается с четырёх клинков.")
	var/shown_blades = 0
	for(var/obj/effect/heretic_orbit_blade/shown in user.vis_contents)
		shown_blades++
	TEST_ASSERT_EQUAL(shown_blades, 4, "Все четыре клинка видны на теле.")
	attacker.forceMove(get_step(get_step(get_step(user, EAST), EAST), EAST))
	var/obj/item/projectile/bullet/bullet = allocate(/obj/item/projectile/bullet, get_turf(attacker))
	bullet.damage = 20
	bullet.firer = attacker
	bullet.starting = get_turf(attacker)
	TEST_ASSERT_EQUAL(user.bullet_act(bullet, BODY_ZONE_CHEST), BULLET_ACT_BLOCK, "Клинок орбиты принимает пулю.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Принятая пуля не ранит.")
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), 3, "Пуля разбивает один клинок.")
	TEST_ASSERT(orbit.regen_timer, "Потеря клинка запускает восстановление.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Клинок орбиты принимает удар ближнего боя.")
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), 2, "Удар разбивает ещё один клинок.")
	attacker.forceMove(get_step(user, EAST))
	var/obj/item/offhand = allocate(/obj/item, get_turf(user))
	user.put_in_hands(offhand)
	TEST_ASSERT(knowledge.begin_parry(user), "После вознесения стойка не требует свободной второй руки.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Стойка отбивает удар.")
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), 2, "Пока стойка готова, клинки орбиты не расходуются.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 2, "Удар расходует блок стойки.")
	orbit.regenerate()
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), 3, "Восстановление возвращает один клинок.")
	user.dropItemToGround(offhand)
	user.adjustBruteLoss(20)
	user.a_intent = INTENT_HARM
	knowledge.riposte_target = null
	var/target_before = attacker.getBruteLoss()
	blade.melee_attack_chain(user, attacker, attackchain_flags = ATTACK_IGNORE_CLICKDELAY)
	var/dealt = attacker.getBruteLoss() - target_before
	TEST_ASSERT(dealt > 0, "Удар клинком ранит цель.")
	TEST_ASSERT(abs(user.getBruteLoss() - (20 - round(dealt * HERETIC_BLADE_LIFESTEAL))) < DAMAGE_PRECISION, "Удар клинком лечит четверть нанесённого урона.")

/// Удар без указанного нападающего стойка и орбита приписывают одному и тому же мобу, так что его берёт стойка.
/datum/unit_test/heretic_blade_parry_null_attacker/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	ascend_blade_fixture(fixture)
	var/datum/component/heretic_blade_orbit/orbit = user.GetComponent(/datum/component/heretic_blade_orbit)
	TEST_ASSERT(knowledge.begin_parry(user), "Стойка поднята.")
	var/blocks_before = knowledge.active_parry.blocks_left
	TEST_ASSERT(user.do_run_block(TRUE, attacker, 20, "удар", ATTACK_TYPE_MELEE, 0, null) & BLOCK_SUCCESS, "Удар соседа без указанного нападающего отбит.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, blocks_before - 1, "Удар принимает стойка.")
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), HERETIC_BLADE_ORBIT_MAX, "Клинки орбиты не расходуются, пока стойка готова.")

/// Дружеские касания и слуги Мансуса не тратят клинки орбиты, оглушённая стойка отдаёт атаку орбите.
/datum/unit_test/heretic_blade_orbit_filters/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/carbon/human/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/blade = fixture["blade"]
	ascend_blade_fixture(fixture)
	var/datum/component/heretic_blade_orbit/orbit = user.GetComponent(/datum/component/heretic_blade_orbit)
	var/mob/living/carbon/human/servant_body = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/datum/mind/servant_mind = new
	allocated += servant_mind
	servant_mind.current = servant_body
	servant_body.mind = servant_mind
	var/datum/antagonist/heretic_monster/servant = allocate(/datum/antagonist/heretic_monster)
	servant.owner = servant_mind
	servant.silent = TRUE
	servant_mind.antag_datums = list(servant)
	user.help_shake_act(attacker)
	user.help_shake_act(servant_body)
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), 4, "Дружеские касания экипажа и слуги не разбивают клинки.")
	TEST_ASSERT(!(user.do_run_block(TRUE, servant_body, 20, "удар", ATTACK_TYPE_MELEE, 0, null) & BLOCK_SUCCESS), "Удар слуги без указанного нападающего не тратит клинок.")
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), 4, "Слуга Мансуса не сбивает орбиту.")
	TEST_ASSERT(knowledge.begin_parry(user), "Стойка поднята.")
	user.Stun(10 SECONDS, ignore_canstun = TRUE)
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Оглушённого героя защищает орбита.")
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), 3, "Удар при неработающей стойке забирает клинок орбиты.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 3, "Неработающая стойка не тратит блок.")

/// Смена тела снимает силу вознесения даже при переносе в мёртвое тело.
/datum/unit_test/heretic_blade_orbit_transfer/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	ascend_blade_fixture(fixture)
	TEST_ASSERT(knowledge.ascension_active, "Вознесение включено.")
	var/mob/living/carbon/human/dead_body = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	dead_body.death()
	heretic.owner.transfer_to(dead_body)
	TEST_ASSERT(!knowledge.ascension_active, "Перенос в мёртвое тело снимает силу вознесения.")
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_blade_orbit), "Старое тело теряет орбиту.")
	TEST_ASSERT_NULL(dead_body.GetComponent(/datum/component/heretic_blade_orbit), "Мёртвое тело не получает орбиту.")

/// Дробины картечи - отдельные снаряды: один выстрел в упор сдирает всю орбиту.
/datum/unit_test/heretic_blade_orbit_buckshot/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	ascend_blade_fixture(fixture)
	var/datum/component/heretic_blade_orbit/orbit = user.GetComponent(/datum/component/heretic_blade_orbit)
	var/obj/item/ammo_casing/shotgun/buckshot/shell = allocate(/obj/item/ammo_casing/shotgun/buckshot, get_turf(attacker))
	TEST_ASSERT(shell.fire_casing(user, attacker, null, 0, TRUE, BODY_ZONE_CHEST, 0, null), "Патрон картечи выстреливает.")
	var/datum/component/pellet_cloud/cloud = shell.GetComponent(/datum/component/pellet_cloud)
	TEST_ASSERT_NOTNULL(cloud, "Картечь создаёт облако дробин.")
	var/list/pellets = cloud.pellets.Copy()
	TEST_ASSERT_EQUAL(length(pellets), 6, "Выстрел состоит из шести дробин.")
	for(var/obj/item/projectile/pellet as anything in pellets)
		for(var/step_index in 1 to 8)
			if(QDELETED(pellet))
				break
			pellet.process(1)
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), 0, "Одна очередь дробин сдирает все четыре клинка.")
	TEST_ASSERT(user.getBruteLoss() > 0, "Лишние дробины проходят к телу.")

/// Буря клинков бьёт четырёх ближайших врагов и опустошает орбиту.
/datum/unit_test/heretic_blade_storm/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/final_eldritch/blade_final/finale = ascend_blade_fixture(fixture)
	var/datum/component/heretic_blade_orbit/orbit = user.GetComponent(/datum/component/heretic_blade_orbit)
	var/obj/effect/proc_holder/spell/self/heretic_blade/storm/storm = locate() in finale.ascension_spell_instances
	TEST_ASSERT_NOTNULL(storm, "Вознесение выдаёт Бурю клинков.")
	var/turf/origin = get_turf(user)
	var/list/victims = list(attacker)
	for(var/offset in list(list(2, 0), list(0, 2), list(3, 0)))
		victims += allocate(/mob/living/carbon/human, locate(origin.x + offset[1], origin.y + offset[2], origin.z))
	var/mob/living/carbon/human/far = allocate(/mob/living/carbon/human, locate(origin.x + 4, origin.y + 4, origin.z))
	var/mob/living/carbon/human/behind_glass = allocate(/mob/living/carbon/human, locate(origin.x + 2, origin.y + 2, origin.z))
	allocate(/obj/structure/window/fulltile, locate(origin.x + 1, origin.y + 1, origin.z))
	TEST_ASSERT(storm.can_cast(user, TRUE, TRUE), "Буря готова с полной орбитой и без клинка в руке.")
	storm.cast(list(user), user)
	for(var/mob/living/victim as anything in victims)
		TEST_ASSERT(abs(victim.getBruteLoss() - 20) < DAMAGE_PRECISION, "Буря наносит 20 ушибов каждой из четырёх ближайших целей.")
		TEST_ASSERT(abs(victim.getStaminaLoss() - 20) < DAMAGE_PRECISION, "Буря наносит 20 урона выносливости.")
	TEST_ASSERT_EQUAL(far.getBruteLoss(), 0, "Пятая цель остаётся нетронутой.")
	TEST_ASSERT_EQUAL(behind_glass.getBruteLoss(), 0, "Окно перехватывает клинок.")
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), 0, "Буря расходует всю орбиту.")
	TEST_ASSERT(orbit.regen_timer, "После бури орбита собирается заново.")
	TEST_ASSERT(!storm.can_cast(user, TRUE, TRUE), "Без клинков на орбите буря недоступна.")
	orbit.regenerate()
	storm.charge_counter = storm.charge_max
	for(var/mob/living/victim as anything in victims)
		victim.fully_heal()
	storm.cast(list(user), user)
	TEST_ASSERT(abs(attacker.getBruteLoss() - 20) < DAMAGE_PRECISION, "Единственный клинок бьёт ближайшую цель.")
	var/hit_count = 0
	for(var/mob/living/victim as anything in victims)
		if(victim.getBruteLoss() > 0)
			hit_count++
	TEST_ASSERT_EQUAL(hit_count, 1, "Один клинок на орбите - одна цель.")

/// Буря против одного врага тратит один клинок, остальные остаются на орбите.
/datum/unit_test/heretic_blade_storm_single_target/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/final_eldritch/blade_final/finale = ascend_blade_fixture(fixture)
	var/datum/component/heretic_blade_orbit/orbit = user.GetComponent(/datum/component/heretic_blade_orbit)
	var/obj/effect/proc_holder/spell/self/heretic_blade/storm/storm = locate() in finale.ascension_spell_instances
	storm.cast(list(user), user)
	TEST_ASSERT(abs(attacker.getBruteLoss() - HERETIC_BLADE_STORM_BRUTE) < DAMAGE_PRECISION, "Клинок бьёт единственную цель.")
	TEST_ASSERT_EQUAL(length(orbit.orbit_blades), HERETIC_BLADE_ORBIT_MAX - 1, "Потрачен только брошенный клинок.")
	var/shown_blades = 0
	for(var/obj/effect/heretic_orbit_blade/shown in user.vis_contents)
		shown_blades++
	TEST_ASSERT_EQUAL(shown_blades, HERETIC_BLADE_ORBIT_MAX - 1, "Оставшиеся клинки видны на теле.")
	TEST_ASSERT(orbit.regen_timer, "Брошенный клинок отрастает.")

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

/// Хватка Мансуса во второй руке не мешает включить и удерживать стойку.
/datum/unit_test/heretic_blade_parry_with_grasp/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/blade = fixture["blade"]
	var/obj/effect/proc_holder/spell/self/heretic_blade/parry/parry_spell = allocate(/obj/effect/proc_holder/spell/self/heretic_blade/parry)
	user.mind.AddSpell(parry_spell)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist, get_turf(user))
	TEST_ASSERT(user.put_in_hands(fist), "Хватка должна занять вторую руку.")
	TEST_ASSERT(!length(user.get_empty_held_indexes()), "Обе руки заняты клинком и хваткой.")
	TEST_ASSERT(parry_spell.can_cast(user, silent = TRUE), "Хватка во второй руке не мешает Выжиданию.")
	TEST_ASSERT(knowledge.begin_parry(user), "Стойка включается с хваткой во второй руке.")
	var/datum/status_effect/heretic_parry/parry = knowledge.active_parry
	parry.tick()
	TEST_ASSERT(parry.stance_ready, "Хватка во второй руке не гасит поднятую стойку.")
	TEST_ASSERT(user.do_run_block(TRUE, blade, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker) & BLOCK_SUCCESS, "Стойка с хваткой отбивает удар.")
	qdel(fist)
	var/obj/item/offhand = allocate(/obj/item, get_turf(user))
	TEST_ASSERT(user.put_in_hands(offhand), "Обычный предмет занимает вторую руку.")
	parry.tick()
	TEST_ASSERT(!parry.stance_ready, "Обычный предмет во второй руке по-прежнему гасит стойку.")

/// Неудачный танец и Буря клинков сохраняют перезарядку и запас Темпа.
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
	knowledge.ascension_active = TRUE
	var/obj/effect/proc_holder/spell/self/heretic_blade/storm/storm = allocate(/obj/effect/proc_holder/spell/self/heretic_blade/storm)
	TEST_ASSERT(!storm.can_cast(user, TRUE, TRUE), "Без орбиты буря недоступна.")
	storm.charge_counter = 0
	storm.cast(list(user), user)
	TEST_ASSERT_EQUAL(storm.charge_counter, storm.charge_max, "Буря без клинков не расходует перезарядку.")

/// Парирование отбивает настоящий снаряд спереди и требует свободной второй руки.
/datum/unit_test/heretic_blade_projectile_guard/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	attacker.forceMove(get_step(get_step(get_step(user, EAST), EAST), EAST))
	user.setDir(EAST)
	var/obj/item/projectile/bullet = blade_test_shot(attacker, user, /obj/item/projectile)
	bullet.damage = 20
	attacker.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(knowledge.begin_parry(user), "Свой клинок позволяет встретить выстрел стойкой.")
	TEST_ASSERT_EQUAL(user.bullet_act(bullet, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Настоящий снаряд отбит даже от стрелка с антимагией.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Отбитый снаряд не наносит рану.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Перехват снаряда пополняет Темп.")
	var/obj/item/offhand = allocate(/obj/item, get_turf(user))
	user.put_in_hands(offhand)
	var/obj/item/projectile/blocked_shot = blade_test_shot(attacker, user, /obj/item/projectile)
	TEST_ASSERT(!(user.do_run_block(TRUE, blocked_shot, 20, "снаряд", ATTACK_TYPE_PROJECTILE, 0, attacker) & BLOCK_SUCCESS), "Предмет во второй руке отключает уже поднятую защиту.")
	user.dropItemToGround(offhand)
	var/obj/item/projectile/turret_shot = blade_test_shot(attacker, user, /obj/item/projectile)
	turret_shot.firer = null
	TEST_ASSERT(user.do_run_block(TRUE, turret_shot, 20, "снаряд турели", ATTACK_TYPE_PROJECTILE, 0, null) & BLOCK_SUCCESS, "Защита не требует живого стрелка.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 1, "После двух перехватов остаётся один блок.")

/// Одновременный залп расходует все блоки стойки, а оставшиеся снаряды наносят урон.
/datum/unit_test/heretic_blade_projectile_guard/burst/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	heretic.gain_knowledge(/datum/eldritch_knowledge/blade_guard)
	user.setDir(EAST)
	TEST_ASSERT(knowledge.begin_parry(user), "Улучшенная стойка встречает залп четырьмя блоками.")
	for(var/shot in 1 to 6)
		var/obj/item/projectile/projectile = blade_test_shot(attacker, user, /obj/item/projectile)
		projectile.damage = 10
		var/result = user.bullet_act(projectile, BODY_ZONE_CHEST)
		if(shot <= 4)
			TEST_ASSERT_EQUAL(result, BULLET_ACT_FORCE_PIERCE, "Каждое из первых четырёх одновременных попаданий отбито.")
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
	user.setDir(EAST)
	TEST_ASSERT(knowledge.begin_parry(user), "Улучшенная стойка включается.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 4, "Улучшение даёт четвёртый блок.")
	for(var/projectile_type in list(/obj/item/projectile/energy/electrode, /obj/item/projectile/energy/electrode/security, /obj/item/projectile/beam/disabler))
		var/obj/item/projectile/projectile = blade_test_shot(attacker, user, projectile_type)
		TEST_ASSERT_EQUAL(user.bullet_act(projectile, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Стойка отбивает [projectile.type].")
		TEST_ASSERT(!user.IsKnockdown() && !user.IsStun(), "Перехват не пропускает оглушение.")
		TEST_ASSERT(!user.has_status_effect(STATUS_EFFECT_TASED) && !user.has_status_effect(STATUS_EFFECT_TASED_WEAK), "Перехват не пропускает электрический эффект.")
		TEST_ASSERT_EQUAL(user.getStaminaLoss(), 0, "Перехват не пропускает урон выносливости.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 1, "Каждый реальный снаряд расходует один блок.")

/// Первые два очка открывают сближение и ускорение, пятое - Обезоруживание; Вызов выдан с первой ступени.
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
		TEST_ASSERT(heretic.research_knowledge(path.knowledge[stage], user), "Метка и Обезоруживание доступны без подношений.")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, 0, "Пять очков оплачивают выпад, танец, метку и Обезоруживание.")
	TEST_ASSERT_NOTNULL(heretic.get_knowledge(/datum/eldritch_knowledge/blade_disarm), "Пятая ступень - Обезоруживание.")
	var/obj/effect/proc_holder/spell/pointed/heretic_blade_challenge/challenge = locate() in user.mind.spell_list
	TEST_ASSERT_NOTNULL(challenge, "Вызов выдан с первой ступени.")
	var/list/spells = list()
	heretic.collect_combat_spells(spells)
	TEST_ASSERT(challenge in spells, "Вызов доступен горячей клавишей и в кодексе.")
	knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(challenge), "Смена тела удаляет Вызов.")
	knowledge.on_body_gain(user)
	TEST_ASSERT(locate(/obj/effect/proc_holder/spell/pointed/heretic_blade_challenge) in user.mind.spell_list, "Новое тело получает Вызов заново.")

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
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, get_turf(user))
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife, get_turf(user))
	allocate(/obj/item/stack/sheet/metal, get_turf(user))
	TEST_ASSERT(!rune.do_ritual(user, knowledge), "Руна отклоняет четвёртый клинок.")
	TEST_ASSERT(!QDELETED(knife), "Отказ не расходует нож.")
	TEST_ASSERT(findtext(rune.recipe_failure_reason(knowledge, user), "предел связанных"), "Отказ руны объясняет лимит клинков.")
	qdel(fixture["blade"])
	TEST_ASSERT(knowledge.on_finished_recipe(user, list(), get_turf(user)), "Потраченный клинок можно заменить.")
	var/datum/weakref/replacement_ref = knowledge.created_blades[length(knowledge.created_blades)]
	allocated += replacement_ref.resolve()
	TEST_ASSERT_EQUAL(length(knowledge.created_blades), 3, "Удалённые клинки не занимают лимит.")

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

/// Пустой Темп вне боя возвращается до единицы через 8 секунд после последнего удара или парирования.
/datum/unit_test/heretic_blade_idle_tempo/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	knowledge.on_life(user)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Без обмена ударами пустой Темп возвращается.")
	knowledge.on_life(user)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Вне боя Темп не копится выше единицы.")
	knowledge.combat_resource = 0
	knowledge.on_life(user)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Следующая единица ждёт новые 8 секунд.")
	COOLDOWN_RESET(knowledge, idle_tempo)
	knowledge.on_eldritch_blade(attacker, user, TRUE)
	knowledge.combat_resource = 0
	knowledge.on_life(user)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Сразу после удара клинком Темп сам не восстанавливается.")
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(knowledge, idle_tempo) - 8 SECONDS) <= world.tick_lag, "Удар откладывает восстановление на 8 секунд.")
	COOLDOWN_RESET(knowledge, idle_tempo)
	knowledge.record_parry(user, attacker)
	knowledge.combat_resource = 0
	knowledge.on_life(user)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 0, "Парирование тоже считается боем.")
	COOLDOWN_RESET(knowledge, idle_tempo)
	knowledge.on_life(user)
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Через 8 секунд без боя возвращается единица.")

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
		TEST_ASSERT(findtext(lunge.heretic_failure_reason, "перекрыта"), "Отмена сохраняет причину о преграде для сообщения и журнала.")
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

/// Смерть снимает бонус ответа и орбиту клинков, оживление возвращает их.
/datum/unit_test/heretic_blade_ascension_death_recovery/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/datum/eldritch_knowledge/final_eldritch/blade_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/blade_final)
	heretic.researched_knowledge[finale.type] = finale
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	knowledge.record_parry(user, attacker)
	knowledge.riposte_ready_at = world.time
	TEST_ASSERT(knowledge.try_riposte(attacker, user), "Ответ после парирования проходит.")
	TEST_ASSERT(abs(attacker.getBruteLoss() - 30) < DAMAGE_PRECISION, "Вознесённый ответ наносит 30 ушибов.")
	user.death()
	heretic.handle_death(user)
	user.revive(full_heal = TRUE)
	user.put_in_hands(fixture["blade"])
	attacker.revive(full_heal = TRUE)
	TEST_ASSERT(knowledge.held_blade(user), "Оживлённый держит свой клинок.")
	knowledge.record_parry(user, attacker)
	knowledge.riposte_ready_at = world.time
	TEST_ASSERT(knowledge.try_riposte(attacker, user), "Ответ после оживления проходит.")
	TEST_ASSERT(abs(attacker.getBruteLoss() - 18) < DAMAGE_PRECISION, "Смерть сняла бонус ответа до следующей обработки жизни.")
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_blade_orbit), "Смерть сняла орбиту клинков.")
	TEST_ASSERT_NULL(locate(/obj/effect/heretic_orbit_blade) in user.vis_contents, "Смерть убрала клинки с тела.")
	finale.on_life(user)
	var/datum/component/heretic_blade_orbit/orbit = user.GetComponent(/datum/component/heretic_blade_orbit)
	TEST_ASSERT_EQUAL(length(orbit?.orbit_blades), 4, "Оживление возвращает полную орбиту.")
	TEST_ASSERT(knowledge.ascension_active, "Оживление возвращает силу вознесения.")
	attacker.revive(full_heal = TRUE)
	knowledge.record_parry(user, attacker)
	knowledge.riposte_ready_at = world.time
	TEST_ASSERT(knowledge.try_riposte(attacker, user), "Оживлённый снова отвечает.")
	TEST_ASSERT(abs(attacker.getBruteLoss() - 30) < DAMAGE_PRECISION, "Оживление возвращает бонус ответа.")

/// Выброс частиц заданного типа на клетке, которого не было в списке before.
/datum/unit_test/proc/find_vfx_burst(turf/place, particles_type, list/before)
	for(var/obj/effect/temp_visual/heretic_vfx/burst/burst in place)
		if(istype(burst.particles, particles_type) && !(burst in before))
			return burst
	return null

/datum/unit_test/proc/list_vfx_bursts(turf/place)
	. = list()
	for(var/obj/effect/temp_visual/heretic_vfx/burst/burst in place)
		. += burst

/// Клинок орбиты несёт блик и свечение кромки; удар разбивает ближайший к нему клинок со вспышкой и осколками, выросший проступает с бликами.
/datum/unit_test/heretic_blade_orbit_visuals/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	ascend_blade_fixture(fixture)
	var/datum/component/heretic_blade_orbit/orbit = user.GetComponent(/datum/component/heretic_blade_orbit)
	for(var/obj/effect/heretic_orbit_blade/blade as anything in orbit.orbit_blades)
		TEST_ASSERT(blade.steel in blade.vis_contents, "Клинок висит на плече орбиты.")
		TEST_ASSERT_EQUAL(length(blade.steel.overlays), 3, "По кромке клинка бежит блик, кромка светится в темноте.")
	var/turf/place = get_turf(user)
	attacker.forceMove(locate(place.x + 3, place.y, place.z))
	var/attack_angle = Get_Angle(place, get_turf(attacker))
	var/obj/effect/heretic_orbit_blade/expected
	var/best_gap = INFINITY
	for(var/obj/effect/heretic_orbit_blade/blade as anything in orbit.orbit_blades)
		var/gap = abs(MODULUS(blade.orbit_angle() - attack_angle + 180, 360) - 180)
		if(gap < best_gap)
			expected = blade
			best_gap = gap
	var/list/before = list_vfx_bursts(place)
	var/obj/item/projectile/bullet/bullet = allocate(/obj/item/projectile/bullet, get_turf(attacker))
	bullet.damage = 20
	bullet.firer = attacker
	bullet.starting = get_turf(attacker)
	TEST_ASSERT_EQUAL(user.bullet_act(bullet, BODY_ZONE_CHEST), BULLET_ACT_BLOCK, "Клинок орбиты принимает пулю.")
	TEST_ASSERT(!(expected in orbit.orbit_blades), "Разбивается клинок, ближайший к стороне выстрела.")
	var/obj/effect/temp_visual/heretic_blade_shatter/shatter = locate() in place
	TEST_ASSERT_NOTNULL(shatter, "Разбитый клинок вспыхивает на своём месте круга.")
	var/obj/effect/temp_visual/heretic_vfx/burst/shards = find_vfx_burst(place, /particles/heretic_ascension/blade/shatter, before)
	TEST_ASSERT_NOTNULL(shards, "Клинок разлетается осколками.")
	TEST_ASSERT(shards.pixel_x > 0 && !shards.pixel_y, "Осколки вылетают со стороны выстрела.")
	before = list_vfx_bursts(place)
	orbit.regenerate()
	var/obj/effect/temp_visual/heretic_vfx/burst/glints = find_vfx_burst(place, /particles/heretic_ascension/blade/regrow, before)
	TEST_ASSERT_NOTNULL(glints, "Выросший клинок проступает с бликами.")
	TEST_ASSERT(wait_for_qdeleted(shatter), "Вспышка разбитого клинка гаснет.")
	TEST_ASSERT(wait_for_qdeleted(shards), "Осколки долетают и эмиттер удаляется.")
	TEST_ASSERT(wait_for_qdeleted(glints), "Блики выросшего клинка гаснут.")

/// Буря: разрез, искры и вспышка приходят вместе с уроном, вдоль дуги от орбиты тают тени, и всё гаснет само.
/datum/unit_test/heretic_blade_storm_visuals/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/final_eldritch/blade_final/finale = ascend_blade_fixture(fixture)
	var/obj/effect/proc_holder/spell/self/heretic_blade/storm/storm = locate() in finale.ascension_spell_instances
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/far = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 3, origin.z))
	var/list/victims = list(attacker, far)
	storm.cast(list(user), user)
	var/list/visuals = list()
	for(var/mob/living/victim as anything in victims)
		var/turf/hit = get_turf(victim)
		TEST_ASSERT(abs(victim.getBruteLoss() - HERETIC_BLADE_STORM_BRUTE) < DAMAGE_PRECISION, "Урон Бури приходит в момент броска.")
		var/obj/effect/temp_visual/dir_setting/heretic_slash/slash = locate() in hit
		TEST_ASSERT_NOTNULL(slash, "Разрез появляется вместе с уроном.")
		var/obj/effect/temp_visual/heretic_vfx/burst/sparks = find_vfx_burst(hit, /particles/heretic_ascension/blade/sparks, list())
		TEST_ASSERT_NOTNULL(sparks, "Искры высекаются вместе с уроном.")
		visuals += list(slash, sparks)
	var/streaks = 0
	for(var/obj/effect/temp_visual/heretic_blade_streak/streak in origin)
		streaks++
		visuals += streak
	TEST_ASSERT_EQUAL(streaks, length(victims), "С орбиты уходит по клинку на каждую цель.")
	var/ghosts = 0
	for(var/obj/effect/temp_visual/heretic_blade_ghost/ghost in origin)
		ghosts++
		visuals += ghost
	TEST_ASSERT_EQUAL(ghosts, HERETIC_BLADE_STREAK_GHOSTS * length(victims), "Вдоль дуги каждого удара остаются четыре тени клинка.")
	TEST_ASSERT_NOTNULL(user.get_filter(HERETIC_VFX_PULSE_FILTER), "Бросок вспыхивает контуром на еретике.")
	for(var/datum/visual as anything in visuals)
		TEST_ASSERT(wait_for_qdeleted(visual), "[visual.type] гаснет сам.")
	TEST_ASSERT_NULL(user.get_filter(HERETIC_VFX_PULSE_FILTER), "Контур броска снимается.")

/// Смерть не обрывает орбиту: клинки опадают со своих мест и тают.
/datum/unit_test/heretic_blade_orbit_death_fade/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	ascend_blade_fixture(fixture)
	var/turf/place = get_turf(user)
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT_NULL(locate(/obj/effect/heretic_orbit_blade) in user.vis_contents, "Смерть снимает клинки с тела.")
	var/list/fading = list()
	for(var/obj/effect/temp_visual/heretic_blade_fade/blade in place)
		fading += blade
	TEST_ASSERT_EQUAL(length(fading), HERETIC_BLADE_ORBIT_MAX, "Каждый клинок орбиты опадает на месте тела.")
	for(var/obj/effect/temp_visual/heretic_blade_fade/blade as anything in fading)
		TEST_ASSERT(wait_for_qdeleted(blade), "Опавший клинок тает.")

/// Удар тёмным клинком вознесённого тянет алый поток от раны к нему, лечение прежнее.
/datum/unit_test/heretic_blade_lifesteal_visual/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/obj/item/blade = fixture["blade"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	ascend_blade_fixture(fixture)
	user.adjustBruteLoss(20)
	user.a_intent = INTENT_HARM
	knowledge.riposte_target = null
	var/turf/wound = get_turf(attacker)
	var/list/before = list_vfx_bursts(wound)
	var/target_before = attacker.getBruteLoss()
	blade.melee_attack_chain(user, attacker, attackchain_flags = ATTACK_IGNORE_CLICKDELAY)
	var/dealt = attacker.getBruteLoss() - target_before
	TEST_ASSERT(dealt > 0, "Удар клинком ранит цель.")
	TEST_ASSERT(abs(user.getBruteLoss() - (20 - round(dealt * HERETIC_BLADE_LIFESTEAL))) < DAMAGE_PRECISION, "Вампиризм лечит прежнюю четверть урона.")
	var/obj/effect/temp_visual/heretic_vfx/burst/stream = find_vfx_burst(wound, /particles/heretic_ascension/blade/lifesteal, before)
	TEST_ASSERT_NOTNULL(stream, "От раны к еретику течёт алый поток.")
	var/list/flow = stream.particles.velocity
	TEST_ASSERT(islist(flow) && flow[1] < 0 && !flow[2], "Поток течёт к еретику.")
	TEST_ASSERT(wait_for_qdeleted(stream), "Поток иссякает и эмиттер удаляется.")

/// Новые эффекты Клинка и держатель частиц создаются без аргументов и удаляются без ошибок.
/datum/unit_test/heretic_blade_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/heretic_orbit_blade, /obj/effect/abstract/heretic_orbit_steel, /obj/effect/temp_visual/heretic_blade_shatter, /obj/effect/temp_visual/heretic_blade_streak, /obj/effect/temp_visual/heretic_blade_fade, /obj/effect/temp_visual/heretic_blade_ghost, /obj/effect/abstract/heretic_particle_holder))
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")

/datum/unit_test/proc/blade_test_crew(turf/place)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, place)
	var/datum/mind/crew_mind = allocate_mind()
	crew_mind.current = crew
	crew.mind = crew_mind
	return crew

/datum/unit_test/proc/blade_test_shot(atom/firer, atom/target, projectile_type = /obj/item/projectile/bullet)
	var/obj/item/projectile/projectile = allocate(projectile_type, get_turf(firer))
	projectile.firer = firer
	projectile.starting = get_turf(firer)
	projectile.setAngle(Get_Angle(get_turf(firer), get_turf(target)))
	return projectile

/// Новый член экипажа на rival_spot принимает вызов еретика Клинка; изнанка к этому моменту снова готова.
/datum/unit_test/proc/start_blade_duel(datum/antagonist/heretic/heretic, turf/rival_spot)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	if(heretic.pocket)
		COOLDOWN_RESET(heretic.pocket, reopen_cooldown)
	var/mob/living/carbon/human/rival = blade_test_crew(rival_spot)
	blade.open_challenge(user, rival)
	return blade.accept_duel(rival) ? rival : null

/// После дуэли еретик снова стоит дома, без клейма и запрета вызовов.
/datum/unit_test/proc/reset_blade_duelist(datum/antagonist/heretic/heretic, turf/home)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	user.SetKnockdown(0)
	user.set_resting(FALSE, TRUE)
	user.forceMove(home)
	user.remove_status_effect(/datum/status_effect/heretic_blade_brand)
	COOLDOWN_RESET(blade, challenge_lockout)

/datum/unit_test/proc/blade_throat_fixture()
	var/list/fixture = make_blade_fixture()
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blade_throat)
	return fixture

/datum/unit_test/proc/seize_blade_hostage(list/fixture, mob/living/victim)
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	victim.Knockdown(5 SECONDS)
	knowledge.seize_throat(fixture["user"], victim)
	return victim.has_status_effect(/datum/status_effect/heretic_blade_throat)

/datum/unit_test/proc/await_blade_hostage(mob/living/victim)
	var/list/budget = new_wait_budget(2 SECONDS, "клинок у горла [victim]")
	while(!victim.has_status_effect(/datum/status_effect/heretic_blade_throat))
		if(!wait_budget_tick(budget))
			break
	return victim.has_status_effect(/datum/status_effect/heretic_blade_throat)

/// Вызов отказывает не человеку, телу без разума, еретику, без сознания, дальше 5 клеток, раненым за 10 секунд, под антимагией и скованному еретику.
/datum/unit_test/heretic_blade_challenge_rules/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLADE)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/turf/origin = run_loc_floor_bottom_left
	user.forceMove(locate(origin.x - 1, origin.y, origin.z))
	TEST_ASSERT(istype(blade.challenge_spell, /obj/effect/proc_holder/spell/pointed/heretic_blade_challenge), "База выдаёт Вызов.")
	TEST_ASSERT(blade.challenge_spell in user.mind.spell_list, "Вызов у тела еретика.")
	TEST_ASSERT_EQUAL(blade.challenge_spell.range, HERETIC_BLADE_CHALLENGE_RANGE, "Вызов наводится на 5 клеток.")
	var/mob/living/carbon/human/crew = blade_test_crew(locate(origin.x + 4, origin.y, origin.z))
	TEST_ASSERT_NULL(blade.challenge_block_reason(user, crew), "Человек в 5 клетках вне боя доступен для вызова.")
	var/mob/living/carbon/human/far = blade_test_crew(locate(origin.x + 5, origin.y, origin.z))
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, far), "не дальше [HERETIC_BLADE_CHALLENGE_RANGE] клеток"), "Дальше 5 клеток вызова нет.")
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, user), "человеку"), "Себя вызвать нельзя.")
	var/obj/item/pen/pen = allocate(/obj/item/pen, get_turf(crew))
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, pen), "человеку"), "Предмет вызвать нельзя.")
	var/mob/living/carbon/human/mindless = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y + 1, origin.z))
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, mindless), "нет того"), "Тело без разума вызов не примет.")
	var/datum/antagonist/heretic/other = allocate_heretic(locate(origin.x + 1, origin.y + 2, origin.z))
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, other.owner.current), "своих"), "Другого еретика вызвать нельзя.")
	crew.adjustBruteLoss(5)
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, crew), "в бою"), "Раненого за последние 10 секунд вызвать нельзя.")
	crew.adjustBruteLoss(-5)
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, crew), "в бою"), "Лечение не отменяет недавний урон.")
	crew.last_hurt_at = world.time - HERETIC_BLADE_CHALLENGE_CALM - 1
	TEST_ASSERT_NULL(blade.challenge_block_reason(user, crew), "Через 10 секунд без урона вызов снова доступен.")
	user.adjustStaminaLoss(5)
	TEST_ASSERT_NULL(blade.challenge_block_reason(user, crew), "Лёгкая усталость от бега и замахов боем не считается.")
	user.adjustStaminaLoss(20)
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, crew), "Вы ещё в бою"), "Еретик после удара по выносливости не вызывает.")
	user.last_hurt_at = world.time - HERETIC_BLADE_CHALLENGE_CALM - 1
	var/datum/component/anti_magic/protection = crew.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, crew), "защищена от магии"), "Антимагия защищает от вызова.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проверка вызова не тратит заряды антимагии.")
	qdel(protection)
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, crew), "наручниках"), "Скованный еретик не вызывает.")
	user.uncuff()
	crew.Unconscious(5 SECONDS)
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, crew), "в сознании"), "Бессознательного вызвать нельзя.")
	crew.SetUnconscious(0)
	TEST_ASSERT_NULL(blade.challenge_block_reason(user, crew), "Очнувшегося снова можно вызвать.")
	TEST_ASSERT(findtext(blade.combat_resource_state(), "Вызов готов"), "Состояние Темпа показывает готовый вызов.")
	heretic.pocket = new /datum/heretic_pocket(heretic)
	COOLDOWN_START(heretic.pocket, reopen_cooldown, HERETIC_POCKET_COOLDOWN)
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, crew), "затягивается"), "Пока изнанка затягивается, вызов не бросить: арены не будет.")
	COOLDOWN_RESET(heretic.pocket, reopen_cooldown)
	heretic_test_area(get_turf(crew), /area/unit_test_pocket_noteleport)
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, crew), "завесу"), "Там, где запрещены телепорты, арены нет и вызова тоже.")

/// Ответ ждёт 20 секунд, молчание и отказ ничего не стоят вызванному, но закрывают его для вызова на 5 минут; старый таймер не трогает новый вызов.
/datum/unit_test/heretic_blade_challenge_answers/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLADE)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/mob/living/carbon/human/first = blade_test_crew(get_step(get_step(user, EAST), EAST))
	var/mob/living/carbon/human/second = blade_test_crew(get_step(get_step(user, NORTH), NORTH))
	blade.open_challenge(user, first)
	TEST_ASSERT_EQUAL(blade.challenged_ref?.resolve(), first, "Вызов ждёт ответа.")
	var/datum/timedevent/timer = SStimer.timer_id_dict[blade.challenge_timer]
	TEST_ASSERT(timer && abs(timer.timeToRun - world.time - HERETIC_BLADE_CHALLENGE_TIMEOUT) < 1, "Ответ ждёт 20 секунд.")
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, second), "ждёте ответа"), "Пока ждёт один вызов, второй не бросить.")
	TEST_ASSERT(findtext(blade.combat_resource_state(), "ждёт ответа"), "Состояние Темпа показывает ждущий вызов.")
	TEST_ASSERT(!blade.accept_duel(second), "Невызванный не может принять вызов.")
	blade.challenge_expired(blade.challenge_serial)
	TEST_ASSERT_NULL(blade.challenged_ref, "Молчание закрывает вызов.")
	TEST_ASSERT_NULL(blade.challenge_timer, "Таймер ответа снят.")
	TEST_ASSERT_NULL(first.has_status_effect(/datum/status_effect/heretic_blade_oath), "Молчание ничего не стоит вызванному.")
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, first), "уже отвечал"), "Промолчавшего повторно не вызвать.")
	TEST_ASSERT(abs(blade.challenge_repeat[blade.challenge_key(first)] - world.time - HERETIC_BLADE_CHALLENGE_REPEAT) < 1, "Повторный вызов закрыт на 5 минут.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	blade.open_challenge(user, second)
	var/stale_serial = blade.challenge_serial - 1
	blade.challenge_expired(stale_serial)
	TEST_ASSERT_EQUAL(blade.challenged_ref?.resolve(), second, "Таймер прошлого вызова не закрывает новый.")
	TEST_ASSERT(blade.decline_duel(second, "отказ"), "Отказ принят.")
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, second), "уже отвечал"), "Отказавшего повторно не вызвать.")
	blade.challenge_repeat[blade.challenge_key(second)] = world.time - 1
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT_NULL(blade.challenge_block_reason(user, second), "Через 5 минут отказавшего можно вызвать снова.")

/// Принятый вызов уводит обоих в изнанку без удержания, у стен и с разрывом на месте вызова; разрывы называют срок дуэли, изнанка держится с запасом; жезл по разрыву - ничья без клятвы и клейма.
/datum/unit_test/heretic_blade_duel_arena/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLADE)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/rival_spot = locate(origin.x + 4, origin.y + 2, origin.z)
	user.forceMove(locate(origin.x, origin.y + 2, origin.z))
	var/mob/living/carbon/human/crew = blade_test_crew(locate(origin.x + 4, origin.y + 4, origin.z))
	var/mob/living/carbon/human/rival = start_blade_duel(heretic, rival_spot)
	TEST_ASSERT_NOTNULL(rival, "Дуэль началась.")
	var/datum/heretic_blade_duel/duel = blade.active_duel
	var/datum/heretic_pocket/arena = heretic.pocket
	TEST_ASSERT(arena?.active && duel.arena == arena, "Дуэль идёт в изнанке еретика.")
	TEST_ASSERT(arena.contains(user) && arena.contains(rival), "Принятый вызов уводит обоих в изнанку.")
	TEST_ASSERT_EQUAL(arena.victim, rival, "Изнанка ведёт соперника как свою цель.")
	TEST_ASSERT_EQUAL(arena.entry_turf, rival_spot, "Вход изнанки - место, где приняли вызов.")
	TEST_ASSERT(!rival.IsParalyzed() && !HAS_TRAIT(rival, TRAIT_HERETIC_CAPTURE_HOLD), "Арена не держит соперника на входе.")
	var/datum/timedevent/duel_timer = SStimer.timer_id_dict[duel.end_timer]
	TEST_ASSERT(duel_timer && abs(duel_timer.timeToRun - world.time - HERETIC_BLADE_DUEL_DURATION) < 1, "Дуэль длится 60 секунд.")
	var/datum/timedevent/arena_timer = SStimer.timer_id_dict[arena.collapse_timer]
	TEST_ASSERT(arena_timer && abs(arena_timer.timeToRun - world.time - HERETIC_BLADE_ARENA_DURATION) < 1, "Арена держится срок дуэли и ещё обычный срок изнанки.")
	var/datum/timedevent/warning = SStimer.timer_id_dict[arena.warning_timer]
	TEST_ASSERT(warning && abs(warning.timeToRun - world.time - (HERETIC_BLADE_ARENA_DURATION - HERETIC_POCKET_WARNING)) < 1, "Предупреждение приходит за 10 секунд до конца арены.")
	TEST_ASSERT(abs(arena.closes_at - world.time - HERETIC_BLADE_DUEL_DURATION) < 1, "Пока идёт дуэль, изнанка показывает срок дуэли: [arena.closes_at - world.time] дс.")
	var/obj/effect/heretic_pocket_rift/rift = arena.rift
	TEST_ASSERT_EQUAL(get_turf(rift), rival_spot, "На месте вызова остаётся разрыв.")
	TEST_ASSERT(findtext(jointext(rift.examine(crew), " "), "шагнул в никуда"), "Экипаж видит улику на месте вызова.")
	var/duel_seconds = "через [HERETIC_BLADE_DUEL_DURATION / (1 SECONDS)] с"
	var/rift_text = jointext(rift.examine(user), " ")
	TEST_ASSERT(findtext(rift_text, duel_seconds), "Разрыв еретику называет срок дуэли: [rift_text]")
	var/inner_text = jointext(arena.inner_rift.examine(rival), " ")
	TEST_ASSERT(findtext(inner_text, "Через [HERETIC_BLADE_DUEL_DURATION / (1 SECONDS)] с"), "Разрыв изнутри называет сопернику срок дуэли: [inner_text]")
	var/turf/wall = locate(arena.center.x - (HERETIC_POCKET_SIZE - 1) / 2, arena.center.y, arena.center.z)
	TEST_ASSERT(isclosedturf(wall), "Арену ограничивают стены изнанки.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/innate/heretic_blade_surrender) in rival.actions, "Сопернику выдана кнопка «Сдаться».")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, rift)
	TEST_ASSERT(QDELETED(duel), "Жезл по разрыву прекращает дуэль.")
	TEST_ASSERT_NULL(blade.active_duel, "Дуэль окончена.")
	TEST_ASSERT(!arena.active && !arena.contains(user) && !arena.contains(rival), "Изнанка закрыта, оба снаружи.")
	TEST_ASSERT_EQUAL(get_turf(rival), rival_spot, "Соперник выпал у входа.")
	TEST_ASSERT_NULL(rival.has_status_effect(/datum/status_effect/heretic_blade_oath), "Закрытая снаружи арена - ничья без клятвы.")
	TEST_ASSERT(COOLDOWN_FINISHED(blade, challenge_lockout), "Ничья не закрывает вызов.")
	TEST_ASSERT_NULL(user.has_status_effect(/datum/status_effect/heretic_blade_brand), "Ничья не оставляет клейма.")
	TEST_ASSERT_NULL(locate(/datum/action/innate/heretic_blade_surrender) in rival.actions, "Кнопка «Сдаться» снята.")

/// Сбитый, сдавшийся, покинувший арену и разорвавший разрыв изнутри соперник 12 секунд скован клятвой; не цель охоты - изнанка закрывается, он у входа, еретик у разреза; клятву снимают жезл и обряд, после неё минута невосприимчивости; антимагия не даёт клятве лечь.
/datum/unit_test/heretic_blade_duel_victory/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLADE)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/home = locate(origin.x, origin.y + 2, origin.z)
	var/turf/rival_spot = locate(origin.x + 4, origin.y + 2, origin.z)
	user.forceMove(home)
	var/mob/living/carbon/human/crew = blade_test_crew(locate(origin.x + 4, origin.y + 4, origin.z))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	var/mob/living/carbon/human/rival = start_blade_duel(heretic, rival_spot)
	var/datum/heretic_blade_duel/duel = blade.active_duel
	var/datum/action/innate/heretic_blade_surrender/surrender_button = locate() in rival.actions
	TEST_ASSERT_NOTNULL(surrender_button, "Сопернику выдана кнопка «Сдаться».")
	surrender_button.asking = TRUE
	surrender_button.confirm(rival)
	TEST_ASSERT(!QDELETED(duel) && surrender_button.asking, "Второй запрос сдачи, пока висит первый, не открывается.")
	surrender_button.asking = FALSE
	TEST_ASSERT(findtext(blade.combat_resource_state(), "Идёт дуэль"), "Состояние Темпа показывает дуэль.")
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, crew), "Дуэль уже идёт"), "Во время дуэли новый вызов не бросить.")
	rival.Knockdown(2 SECONDS)
	duel.process()
	TEST_ASSERT(QDELETED(duel), "Сбитый соперник проиграл.")
	TEST_ASSERT_NULL(locate(/datum/action/innate/heretic_blade_surrender) in rival.actions, "Кнопка «Сдаться» снята.")
	var/datum/status_effect/heretic_blade_oath/oath = rival.has_status_effect(/datum/status_effect/heretic_blade_oath)
	TEST_ASSERT_NOTNULL(oath, "Проигравшего сковала клятва.")
	TEST_ASSERT(abs(oath.duration - world.time - HERETIC_BLADE_OATH_HOLD) < 1, "Клятва держит 12 секунд.")
	TEST_ASSERT(!heretic.pocket.active, "Победа над тем, кто не цель охоты, закрывает изнанку.")
	TEST_ASSERT_EQUAL(get_turf(rival), rival_spot, "Соперник выпал у входа.")
	var/distance = get_dist(user, rival_spot)
	TEST_ASSERT(!heretic.pocket.contains(user) && distance >= HERETIC_BLADE_SLASH_MIN && distance <= HERETIC_BLADE_SLASH_MAX, "Еретик выходит разрезом в 5-9 клетках от входа: [distance].")
	rival.SetKnockdown(0)
	TEST_ASSERT(rival.IsParalyzed(), "Скованный клятвой не двигается.")
	TEST_ASSERT(heretic.hunt_target_ready(rival), "Скованный клятвой готов к обряду.")
	TEST_ASSERT(findtext(jointext(rival.examine(crew), " "), "клятвой"), "Экипаж видит клятву при осмотре.")
	rod.melee_attack_chain(crew, rival)
	TEST_ASSERT(QDELETED(oath), "Нулевой жезл разрывает клятву.")
	TEST_ASSERT(!rival.IsParalyzed(), "Разорванная клятва отпускает.")
	var/datum/status_effect/heretic_capture_immunity/immunity = capture_immunity(rival, "blade_oath")
	TEST_ASSERT(immunity && abs(immunity.duration - world.time - HERETIC_CAPTURE_IMMUNITY) < 1, "После клятвы минута невосприимчивости к ней.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, rival, "sand"), "другого захвата"), "И 15 секунд к любому захвату.")
	qdel(rival)
	reset_blade_duelist(heretic, home)
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	TEST_ASSERT(!duel.surrender(user), "Сдаться может только соперник.")
	TEST_ASSERT(duel.surrender(rival), "Соперник сдаётся.")
	oath = rival.has_status_effect(/datum/status_effect/heretic_blade_oath)
	TEST_ASSERT_NOTNULL(oath, "Сдавшегося сковала клятва.")
	SEND_SIGNAL(rival, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING)
	TEST_ASSERT(QDELETED(oath), "Начало обряда снимает клятву до лечения Мансуса.")
	TEST_ASSERT_NOTNULL(capture_immunity(rival, "blade_oath"), "Невосприимчивость после обряда остаётся.")
	qdel(rival)
	reset_blade_duelist(heretic, home)
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	heretic.set_hunt_target(rival.mind)
	rival.forceMove(locate(origin.x + 5, origin.y + 2, origin.z))
	TEST_ASSERT(QDELETED(duel), "Покинувший арену соперник проиграл.")
	TEST_ASSERT_NOTNULL(rival.has_status_effect(/datum/status_effect/heretic_blade_oath), "Покинувшего арену тоже сковала клятва.")
	TEST_ASSERT(!heretic.pocket.active, "Цель охоты вне арены: держать изнанку открытой незачем.")
	heretic.set_hunt_target(null)
	qdel(rival)
	reset_blade_duelist(heretic, home)
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	var/obj/effect/heretic_pocket_rift/inner/inner = heretic.pocket.inner_rift
	rival.forceMove(get_step(inner, SOUTH))
	TEST_ASSERT(!QDELETED(duel), "Шаг внутри арены дуэль не прерывает.")
	inner.tear_time = 1
	TEST_ASSERT(inner.tear(rival), "Соперник разрывает разрыв изнутри.")
	TEST_ASSERT(QDELETED(duel), "Вырвавшийся из изнанки соперник проиграл.")
	TEST_ASSERT_NOTNULL(rival.has_status_effect(/datum/status_effect/heretic_blade_oath), "Вырвавшегося сковала клятва.")
	TEST_ASSERT(COOLDOWN_FINISHED(blade, challenge_lockout) && !user.has_status_effect(/datum/status_effect/heretic_blade_brand), "Бегство соперника - не поражение еретика.")
	TEST_ASSERT_EQUAL(get_turf(rival), rival_spot, "Вырвавшийся соперник выпал у входа.")
	qdel(rival)
	reset_blade_duelist(heretic, home)
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	rival.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	rival.Knockdown(2 SECONDS)
	duel.process()
	TEST_ASSERT(QDELETED(duel), "Сбитый под антимагией тоже проиграл.")
	TEST_ASSERT_NULL(rival.has_status_effect(/datum/status_effect/heretic_blade_oath), "Антимагия не даёт клятве лечь.")

/// Сбитый или покинувший арену еретик проигрывает: оба у входа, Темп обнулён, вызов закрыт на 5 минут, клинок выпал, на шее 5 минут клеймо; Хватка, настоящее заклинание, кроме Выжидания и призыва, и крит, закрывший арену, - тоже поражение; время и гибель соперника - ничья у входа; смена тела снимает Вызов и дуэль.
/datum/unit_test/heretic_blade_duel_defeat/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLADE)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/home = locate(origin.x, origin.y + 2, origin.z)
	var/turf/rival_spot = locate(origin.x + 4, origin.y + 2, origin.z)
	user.forceMove(home)
	var/obj/item/melee/sickly_blade/duelist/weapon = allocate(/obj/item/melee/sickly_blade/duelist)
	weapon.bound_mind = user.mind
	user.put_in_hands(weapon)
	var/mob/living/carbon/human/next = blade_test_crew(locate(origin.x + 2, origin.y + 4, origin.z))
	blade.combat_resource = 3
	var/mob/living/carbon/human/rival = start_blade_duel(heretic, rival_spot)
	var/datum/heretic_blade_duel/duel = blade.active_duel
	user.Knockdown(2 SECONDS)
	duel.process()
	TEST_ASSERT(QDELETED(duel), "Сбитый еретик проиграл.")
	TEST_ASSERT(!heretic.pocket.active, "Поражение закрывает изнанку.")
	TEST_ASSERT(get_turf(user) == rival_spot && get_turf(rival) == rival_spot, "Поражение выводит обоих к входу.")
	TEST_ASSERT_EQUAL(blade.combat_resource, 0, "Поражение обнуляет Темп.")
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(blade, challenge_lockout) - HERETIC_BLADE_DUEL_LOCKOUT) < 1, "Вызов закрыт на 5 минут.")
	var/datum/status_effect/heretic_blade_brand/brand = user.has_status_effect(/datum/status_effect/heretic_blade_brand)
	TEST_ASSERT(brand && abs(brand.duration - world.time - HERETIC_BLADE_BRAND_DURATION) < 1, "Клеймо поединка держится 5 минут.")
	var/atom/movable/screen/alert/brand_alert = user.alerts["heretic_blade_brand"]
	TEST_ASSERT(brand_alert && findtext(brand_alert.desc, "[HERETIC_BLADE_BRAND_DURATION / (1 MINUTES)] минут"), "Подсказка клейма называет его срок: [brand_alert?.desc]")
	TEST_ASSERT(findtext(jointext(user.examine(next), " "), "клеймо проигранного поединка"), "Экипаж видит клеймо на шее.")
	TEST_ASSERT(!(weapon in user.held_items), "Проигравший роняет клинок.")
	TEST_ASSERT_EQUAL(get_turf(weapon), rival_spot, "Клинок лежит у входа.")
	TEST_ASSERT_NULL(rival.has_status_effect(/datum/status_effect/heretic_blade_oath), "Победителя клятва не держит.")
	TEST_ASSERT(findtext(blade.challenge_block_reason(user, next), "вызов закрыт"), "После поражения вызов недоступен.")
	TEST_ASSERT(findtext(blade.combat_resource_state(), "закрыт"), "Состояние Темпа показывает закрытый вызов.")
	qdel(rival)
	reset_blade_duelist(heretic, home)
	blade.combat_resource = 2
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	user.forceMove(locate(origin.x - 1, origin.y + 2, origin.z))
	TEST_ASSERT(QDELETED(duel), "Покинувший арену еретик проиграл.")
	TEST_ASSERT_EQUAL(blade.combat_resource, 0, "Уход с арены тоже обнуляет Темп.")
	TEST_ASSERT_EQUAL(get_turf(rival), rival_spot, "Соперник выпал у входа.")
	qdel(rival)
	reset_blade_duelist(heretic, home)
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	var/obj/effect/proc_holder/spell/self/heretic_blade/parry/stance = allocate(/obj/effect/proc_holder/spell/self/heretic_blade/parry)
	SEND_SIGNAL(user, COMSIG_MOB_CAST_SPELL, stance)
	var/obj/effect/proc_holder/spell/self/heretic_summon/heart/summon = allocate(/obj/effect/proc_holder/spell/self/heretic_summon/heart)
	SEND_SIGNAL(user, COMSIG_MOB_CAST_SPELL, summon)
	TEST_ASSERT(!QDELETED(duel), "Выжидание и призыв сердца в дуэли разрешены.")
	var/obj/effect/proc_holder/spell/self/heretic_blade/recall/recall = allocate(/obj/effect/proc_holder/spell/self/heretic_blade/recall)
	recall.perform(list(user), FALSE, user)
	TEST_ASSERT(QDELETED(duel), "Заклинание пути в дуэли - поражение еретика.")
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_blade_brand), "Нечестный еретик тоже получает клеймо.")
	qdel(rival)
	reset_blade_duelist(heretic, home)
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	fist.afterattack(rival, user, TRUE)
	TEST_ASSERT(QDELETED(duel), "Хватка в дуэли - поражение еретика.")
	TEST_ASSERT_NULL(rival.has_status_effect(/datum/status_effect/heretic_blade_oath), "Сбитый Хваткой соперник не проигрывает.")
	qdel(rival)
	reset_blade_duelist(heretic, home)
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	user.set_stat(SOFT_CRIT)
	TEST_ASSERT(QDELETED(duel) && !heretic.pocket.active, "Крит еретика закрывает арену и дуэль.")
	TEST_ASSERT(!COOLDOWN_FINISHED(blade, challenge_lockout) && user.has_status_effect(/datum/status_effect/heretic_blade_brand), "Арену закрыл крит еретика - это его поражение, а не ничья.")
	TEST_ASSERT(get_turf(user) == rival_spot && get_turf(rival) == rival_spot, "После крита оба у входа.")
	user.set_stat(CONSCIOUS)
	qdel(rival)
	reset_blade_duelist(heretic, home)
	blade.combat_resource = 2
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	duel.expire()
	TEST_ASSERT(QDELETED(duel), "Время дуэли вышло.")
	TEST_ASSERT_EQUAL(blade.combat_resource, 2, "Ничья сохраняет Темп.")
	TEST_ASSERT(COOLDOWN_FINISHED(blade, challenge_lockout), "Ничья не закрывает вызов.")
	TEST_ASSERT_NULL(rival.has_status_effect(/datum/status_effect/heretic_blade_oath), "Ничья без клятвы.")
	TEST_ASSERT(!heretic.pocket.active && get_turf(user) == rival_spot && get_turf(rival) == rival_spot, "Ничья выводит обоих к входу.")
	qdel(rival)
	reset_blade_duelist(heretic, home)
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	rival.death()
	duel.process()
	TEST_ASSERT(QDELETED(duel), "Гибель соперника прекращает дуэль.")
	TEST_ASSERT(COOLDOWN_FINISHED(blade, challenge_lockout), "Гибель соперника не поражение еретика.")
	TEST_ASSERT(!heretic.pocket.active, "Гибель соперника закрывает изнанку.")
	qdel(rival)
	reset_blade_duelist(heretic, home)
	rival = start_blade_duel(heretic, rival_spot)
	duel = blade.active_duel
	var/obj/effect/proc_holder/spell/challenge = blade.challenge_spell
	blade.on_body_lose(user)
	TEST_ASSERT(QDELETED(duel), "Смена тела прекращает дуэль.")
	TEST_ASSERT(QDELETED(challenge), "Смена тела снимает Вызов.")
	TEST_ASSERT_EQUAL(blade.combat_resource, 2, "Смена тела - ничья, Темп сохранён.")
	TEST_ASSERT(!heretic.pocket.active, "Смена тела закрывает изнанку.")
	blade.on_body_gain(user)
	TEST_ASSERT(!QDELETED(blade.challenge_spell) && (blade.challenge_spell in user.mind.spell_list), "Новое тело получает Вызов.")
	blade.challenge_repeat.Cut()
	blade.open_challenge(user, next)
	blade.on_body_lose(user)
	TEST_ASSERT_NULL(blade.challenged_ref, "Смена тела закрывает ждущий вызов.")

/datum/unit_test/heretic_blade_arena_rite
	var/list/previous_sacrificed

/datum/unit_test/heretic_blade_arena_rite/Destroy()
	if(previous_sacrificed)
		GLOB.heretic_sacrificed_minds = previous_sacrificed
	return ..()

/// Победа над целью охоты оставляет арену открытой на обычный срок изнанки заново: клятва держит цель, и обряд сердцем там проходит.
/datum/unit_test/heretic_blade_arena_rite/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	previous_sacrificed = GLOB.heretic_sacrificed_minds.Copy()
	var/turf/origin = run_loc_floor_bottom_left
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 2, origin.z))
	var/datum/mind/user_mind = allocate_mind()
	user_mind.current = user
	user.mind = user_mind
	var/datum/antagonist/heretic/ritual_fixture/heretic = allocate(/datum/antagonist/heretic/ritual_fixture)
	heretic.owner = user_mind
	heretic.silent = TRUE
	user_mind.antag_datums = list(heretic)
	heretic.test_return_turf = run_loc_floor_top_right
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_BLADE]
	TEST_ASSERT(heretic.research_knowledge(path.knowledge[1], user), "Путь Клинка выбран.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/spell/basic/ritual = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	ritual.ritual_time = 1 SECONDS
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, origin)
	TEST_ASSERT(heart.bind(user_mind), "Сердце привязано к еретику.")
	user.put_in_hands(heart)
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/mob/living/carbon/human/rival = allocate_hunt_victim(heretic, locate(origin.x + 3, origin.y + 2, origin.z))
	blade.open_challenge(user, rival)
	TEST_ASSERT(blade.accept_duel(rival), "Цель охоты принимает вызов.")
	var/datum/heretic_pocket/arena = heretic.pocket
	var/datum/heretic_blade_duel/duel = blade.active_duel
	rival.Knockdown(2 SECONDS)
	duel.process()
	TEST_ASSERT(QDELETED(duel), "Цель охоты проиграла дуэль.")
	TEST_ASSERT(arena.active && arena.contains(user) && arena.contains(rival), "Победа над целью охоты оставляет обоих в изнанке.")
	var/datum/timedevent/collapse = SStimer.timer_id_dict[arena.collapse_timer]
	TEST_ASSERT(collapse && abs(collapse.timeToRun - world.time - HERETIC_POCKET_DURATION) < 1, "После победы изнанка держится обычный срок заново: [collapse ? collapse.timeToRun - world.time : "нет таймера"] дс.")
	var/datum/timedevent/warning = SStimer.timer_id_dict[arena.warning_timer]
	TEST_ASSERT(warning && abs(warning.timeToRun - world.time - (HERETIC_POCKET_DURATION - HERETIC_POCKET_WARNING)) < 1, "Предупреждение - за 10 секунд до нового конца.")
	TEST_ASSERT(abs(arena.closes_at - world.time - HERETIC_POCKET_DURATION) < 1, "Разрыв показывает новый срок изнанки.")
	TEST_ASSERT_NOTNULL(rival.has_status_effect(/datum/status_effect/heretic_blade_oath), "Клятва держит цель в изнанке.")
	rival.SetKnockdown(0)
	TEST_ASSERT(heretic.begin_heart_rite(user, rival, heart), "Обряд сердцем в арене проходит.")
	TEST_ASSERT_EQUAL(heretic.total_sacrifices, 1, "Обряд в арене засчитан.")
	var/datum/heretic_mansus_visit/visit = GLOB.heretic_mansus_visits[rival.mind]
	TEST_ASSERT_NOTNULL(visit, "Жертва уходит в Мансус.")
	allocated += visit
	TEST_ASSERT(arena.active, "Обряд не закрывает арену.")

/// Клятва дуэли - общий захват: клик «Помощи» не укорачивает её, 2 секунды растолкать снимают.
/datum/unit_test/heretic_blade_oath_shake/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLADE)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/turf/origin = run_loc_floor_bottom_left
	user.forceMove(locate(origin.x, origin.y + 2, origin.z))
	var/mob/living/carbon/human/rival = start_blade_duel(heretic, locate(origin.x + 4, origin.y + 2, origin.z))
	TEST_ASSERT(blade.active_duel?.surrender(rival), "Соперник сдаётся.")
	var/datum/status_effect/heretic_blade_oath/oath = rival.has_status_effect(/datum/status_effect/heretic_blade_oath)
	TEST_ASSERT_NOTNULL(oath, "Сдавшегося держит клятва.")
	TEST_ASSERT(HAS_TRAIT(rival, TRAIT_HERETIC_CAPTURE_HOLD), "Клятва держит как общий захват.")
	var/held_until = oath.restraint.duration
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, get_step(rival, NORTH))
	rival.help_shake_act(helper)
	TEST_ASSERT(!QDELETED(oath) && oath.restraint.duration == held_until, "Клик «Помощи» не укорачивает клятву.")
	TEST_ASSERT(LAZYFIND(helper.do_afters, rival), "«Помощь» начинает расталкивать.")
	TEST_ASSERT(wait_for_qdeleted(oath, HERETIC_CAPTURE_SHAKE_TIME * 2), "Две секунды растолкать снимают клятву.")
	TEST_ASSERT(!rival.IsParalyzed() && !HAS_TRAIT(rival, TRAIT_HERETIC_CAPTURE_HOLD), "Растолканный свободен.")
	TEST_ASSERT_NOTNULL(capture_immunity(rival, "blade_oath"), "После клятвы цель невосприимчива.")

/datum/action/innate/heretic_blade_surrender/prompt_fixture
	var/datum/callback/during_prompt

/datum/action/innate/heretic_blade_surrender/prompt_fixture/wants_surrender(mob/living/fighter)
	during_prompt?.Invoke()
	return TRUE

/datum/action/innate/heretic_blade_surrender/prompt_fixture/Destroy()
	during_prompt = null
	return ..()

/// Сдача проверяет дуэль после окна: еретик, сваленный пока окно было открыто, проигрывает, и клятва на соперника не ложится.
/datum/unit_test/heretic_blade_surrender_prompt/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLADE)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	var/turf/origin = run_loc_floor_bottom_left
	user.forceMove(locate(origin.x, origin.y + 2, origin.z))
	var/mob/living/carbon/human/rival = start_blade_duel(heretic, locate(origin.x + 4, origin.y + 2, origin.z))
	var/datum/heretic_blade_duel/duel = blade.active_duel
	var/datum/action/innate/heretic_blade_surrender/prompt_fixture/button = allocate(/datum/action/innate/heretic_blade_surrender/prompt_fixture, duel)
	button.Grant(rival)
	button.during_prompt = CALLBACK(user, TYPE_PROC_REF(/mob/living, Knockdown), 2 SECONDS)
	button.confirm(rival)
	TEST_ASSERT(QDELETED(duel), "Дуэль окончена.")
	TEST_ASSERT_NULL(rival.has_status_effect(/datum/status_effect/heretic_blade_oath), "Сдача после падения еретика не засчитана.")
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_blade_brand), "Сваленный во время окна еретик проиграл.")

/// Ответ и взрыв метки с Обезоруживанием выбивают предмет из активной руки на 2 клетки от еретика, не чаще раза в 6 секунд; преграда останавливает предмет, приросший не выпадает.
/datum/unit_test/heretic_blade_disarm/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/carbon/human/attacker = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/melee/classic_baton/baton = allocate(/obj/item/melee/classic_baton)
	attacker.put_in_active_hand(baton)
	knowledge.record_parry(user, attacker)
	TEST_ASSERT(knowledge.try_riposte(attacker, user), "Ответ проходит.")
	TEST_ASSERT_EQUAL(attacker.get_active_held_item(), baton, "Без Обезоруживания ответ оружие не выбивает.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/blade_disarm)
	knowledge.record_parry(user, attacker)
	TEST_ASSERT(knowledge.try_riposte(attacker, user), "Второй ответ проходит.")
	TEST_ASSERT_NULL(attacker.get_active_held_item(), "Ответ выбивает дубинку из руки.")
	TEST_ASSERT_EQUAL(get_turf(baton), locate(attacker.x + HERETIC_BLADE_DISARM_DISTANCE, attacker.y, attacker.z), "Дубинка отлетает на 2 клетки от еретика.")
	TEST_ASSERT(abs(knowledge.disarm_ready_at[REF(attacker)] - world.time - HERETIC_BLADE_DISARM_COOLDOWN) < 1, "Следующее обезоруживание этой цели - через 6 секунд.")
	TEST_ASSERT(knowledge.throat_ready(attacker), "Обезоруженная ответом цель годится для Клинка у горла.")
	var/obj/item/shield/riot/shield = allocate(/obj/item/shield/riot)
	attacker.put_in_active_hand(shield)
	knowledge.record_parry(user, attacker)
	knowledge.try_riposte(attacker, user)
	TEST_ASSERT_EQUAL(attacker.get_active_held_item(), shield, "Цель не обезоружить второй раз за 6 секунд.")
	knowledge.disarm_ready_at.Cut()
	var/obj/barrier = allocate(/obj, locate(attacker.x + 2, attacker.y, attacker.z))
	barrier.density = TRUE
	barrier.anchored = TRUE
	var/datum/eldritch_knowledge/blade_disarm/disarm = heretic.get_knowledge(/datum/eldritch_knowledge/blade_disarm)
	disarm.on_mark_detonated(user, attacker)
	TEST_ASSERT_NULL(attacker.get_active_held_item(), "Взрыв метки выбивает щит.")
	TEST_ASSERT_EQUAL(get_turf(shield), locate(attacker.x + 1, attacker.y, attacker.z), "Преграда останавливает щит раньше.")
	knowledge.disarm_ready_at.Cut()
	var/obj/item/pen/stuck = allocate(/obj/item/pen)
	attacker.put_in_active_hand(stuck)
	ADD_TRAIT(stuck, TRAIT_NODROP, "unit_test")
	TEST_ASSERT(!knowledge.disarm(user, attacker), "Приросший к руке предмет не выпадает.")
	TEST_ASSERT_EQUAL(attacker.get_active_held_item(), stuck, "Приросший предмет остался в руке.")
	REMOVE_TRAIT(stuck, TRAIT_NODROP, "unit_test")
	attacker.dropItemToGround(stuck)
	var/obj/item/abstract_hand = allocate(/obj/item)
	abstract_hand.item_flags |= ABSTRACT | HAND_ITEM
	attacker.put_in_active_hand(abstract_hand)
	TEST_ASSERT(!knowledge.disarm(user, attacker), "Рука-предмет не выбивается.")
	TEST_ASSERT_EQUAL(attacker.get_active_held_item(), abstract_hand, "Рука-предмет осталась на месте.")
	attacker.dropItemToGround(abstract_hand)
	var/obj/item/vanishing = new(get_turf(attacker))
	vanishing.item_flags |= DROPDEL
	attacker.put_in_active_hand(vanishing)
	TEST_ASSERT(!knowledge.disarm(user, attacker), "Предмет, исчезающий при падении, не считается выбитым.")
	TEST_ASSERT(QDELETED(vanishing), "Такой предмет исчез, а не улетел.")
	TEST_ASSERT_NULL(knowledge.disarm_ready_at[REF(attacker)], "Исчезнувший предмет не запускает перезарядку.")

/// Клинок у горла не берёт вооружённую стоящую, дальнюю, защищённую цель и без клинка; сбитую или обезоруженную ответом через полсекунды держит 12 секунд, она готова к обряду и идёт за еретиком шагом.
/datum/unit_test/heretic_blade_throat/Run()
	var/list/fixture = blade_throat_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/carbon/human/victim = fixture["attacker"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/blade = fixture["blade"]
	var/datum/eldritch_knowledge/spell/blade_throat/throat = heretic.get_knowledge(/datum/eldritch_knowledge/spell/blade_throat)
	TEST_ASSERT(istype(throat.granted_spell, /obj/effect/proc_holder/spell/pointed/heretic_blade_throat), "Знание выдаёт Клинок у горла.")
	TEST_ASSERT_EQUAL(throat.granted_spell.charge_max, HERETIC_BLADE_THROAT_COOLDOWN, "Перезарядка 45 секунд.")
	var/obj/item/pen/pen = allocate(/obj/item/pen)
	victim.put_in_active_hand(pen)
	knowledge.last_riposte_victim = WEAKREF(victim)
	knowledge.last_riposte_at = world.time
	TEST_ASSERT(findtext(knowledge.throat_block_reason(user, victim), "сбитой с ног"), "Вооружённая стоящая цель не годится даже после ответа.")
	victim.dropItemToGround(pen)
	TEST_ASSERT_NULL(knowledge.throat_block_reason(user, victim), "Цель с пустой рукой сразу после ответа годится.")
	knowledge.last_riposte_at = world.time - HERETIC_BLADE_THROAT_WINDOW - 1
	TEST_ASSERT(findtext(knowledge.throat_block_reason(user, victim), "сбитой с ног"), "Ответ старше 3 секунд уже не в счёт.")
	knowledge.last_riposte_victim = null
	victim.Knockdown(5 SECONDS)
	TEST_ASSERT_NULL(knowledge.throat_block_reason(user, victim), "Сбитая с ног цель годится.")
	victim.forceMove(get_step(get_step(user, EAST), EAST))
	TEST_ASSERT(findtext(knowledge.throat_block_reason(user, victim), "вплотную"), "Цель должна стоять вплотную.")
	victim.forceMove(get_step(user, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(findtext(knowledge.throat_block_reason(user, victim), "защищена от магии"), "Антимагия спасает цель.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проверка не тратит заряды антимагии.")
	qdel(protection)
	user.dropItemToGround(blade)
	TEST_ASSERT(findtext(knowledge.throat_block_reason(user, victim), "клинок"), "Без своего клинка в руке захвата нет.")
	user.put_in_hands(blade)
	var/started = world.time
	TEST_ASSERT(knowledge.draw_throat(user, victim), "Замах начался.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_blade_throat), "Полсекунды клинок только заносится.")
	var/datum/status_effect/heretic_blade_throat/hold = await_blade_hostage(victim)
	TEST_ASSERT_NOTNULL(hold, "После замаха цель - заложник.")
	TEST_ASSERT(world.time - started >= HERETIC_BLADE_THROAT_TELEGRAPH - world.tick_lag, "Захват ждёт полсекунды замаха: [world.time - started] дс.")
	var/remaining = hold.duration - world.time
	TEST_ASSERT(remaining <= 12 SECONDS + 1 && remaining > 12 SECONDS - 1 SECONDS, "Захват держит 12 секунд: осталось [remaining] дс.")
	var/restraint_left = hold.restraint.duration - world.time
	TEST_ASSERT(restraint_left <= 12 SECONDS + 1, "Паралич заложника не дольше 12 секунд: [restraint_left] дс.")
	victim.SetKnockdown(0)
	TEST_ASSERT(victim.IsParalyzed(), "Заложник не двигается сам.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Заложник готов к обряду.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	TEST_ASSERT(findtext(jointext(victim.examine(crew), " "), "заложник"), "Окружающие видят заложника.")
	TEST_ASSERT(findtext(knowledge.throat_block_reason(user, crew), "уже держите"), "Второго заложника не взять.")
	var/turf/left_spot = get_turf(user)
	TEST_ASSERT(user.Move(get_step(user, WEST), WEST), "Еретик делает шаг прочь.")
	TEST_ASSERT_EQUAL(get_turf(victim), left_spot, "Заложник идёт за еретиком шагом.")
	TEST_ASSERT(!QDELETED(hold), "Шаг не срывает захват.")
	user.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(QDELETED(hold), "Отошедший дальше клетки еретик теряет заложника.")
	TEST_ASSERT(!victim.IsParalyzed(), "Отпущенный заложник снова двигается.")
	var/datum/status_effect/heretic_capture_immunity/immunity = capture_immunity(victim, "blade_throat")
	TEST_ASSERT(immunity && abs(immunity.duration - world.time - HERETIC_CAPTURE_IMMUNITY) < 1, "После захвата минута невосприимчивости.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "sand"), "другого захвата"), "И 15 секунд к любому захвату.")
	TEST_ASSERT(findtext(knowledge.throat_block_reason(user, victim), "приходит в себя"), "Повторный клинок у горла ждёт минуту.")

/// Заложника под клинком одного еретика второй еретик Клинка не берёт ни отказом цели, ни прямым наложением.
/datum/unit_test/heretic_blade_throat_foreign/Run()
	var/list/fixture = blade_throat_fixture()
	var/mob/living/carbon/human/victim = fixture["attacker"]
	var/list/second = blade_throat_fixture()
	var/mob/living/carbon/human/second_user = second["user"]
	var/datum/eldritch_knowledge/base_blade/second_blade = second["knowledge"]
	qdel(second["attacker"])
	second_user.forceMove(get_step(victim, NORTH))
	var/datum/status_effect/heretic_blade_throat/hold = seize_blade_hostage(fixture, victim)
	TEST_ASSERT_NOTNULL(hold, "Первый еретик взял заложника.")
	var/reason = second_blade.throat_block_reason(second_user, victim)
	TEST_ASSERT(findtext(reason, "уже держат"), "Второй еретик не берёт чужого заложника: [reason]")
	TEST_ASSERT(!second_blade.seize_throat(second_user, victim), "Чужой заложник не переходит ко второму еретику.")
	TEST_ASSERT_NULL(second_blade.throat_hold, "Второй еретик не держит заложника.")
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/heretic_blade_throat), hold, "Заложник остаётся у первого еретика.")

/// Заложника освобождают удар 15+ по еретику, оглушение, выпавший клинок, нулевой жезл по любому из двоих, уведённый заложник, начало обряда и 2 секунды растолкать; после каждого - невосприимчивость.
/datum/unit_test/heretic_blade_throat_breaks/Run()
	var/list/fixture = blade_throat_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/blade = fixture["blade"]
	qdel(fixture["attacker"])
	var/turf/victim_spot = get_step(user, EAST)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	for(var/method in list("удар", "оглушение", "клинок выпал", "жезл по заложнику", "жезл по еретику", "заложника увели", "обряд", "растолкали"))
		var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, victim_spot)
		var/datum/status_effect/heretic_blade_throat/hold = seize_blade_hostage(fixture, victim)
		TEST_ASSERT_NOTNULL(hold, "Заложник взят ([method]).")
		switch(method)
			if("удар")
				user.adjustBruteLoss(HERETIC_BLADE_THROAT_BREAK_DAMAGE - 1)
				TEST_ASSERT(!QDELETED(hold), "Удар слабее 15 не срывает захват.")
				sleep(world.tick_lag)
				user.adjustBruteLoss(HERETIC_BLADE_THROAT_BREAK_DAMAGE - 1)
				TEST_ASSERT(!QDELETED(hold), "Слабые удары в разные тики не складываются.")
				sleep(world.tick_lag)
				user.adjustBruteLoss(HERETIC_BLADE_THROAT_BREAK_DAMAGE)
			if("оглушение")
				user.Knockdown(2 SECONDS)
				hold.tick()
			if("клинок выпал")
				user.dropItemToGround(blade)
				hold.tick()
			if("жезл по заложнику")
				rod.melee_attack_chain(crew, victim)
			if("жезл по еретику")
				rod.melee_attack_chain(crew, user)
			if("заложника увели")
				victim.forceMove(get_step(victim_spot, EAST))
			if("обряд")
				SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING)
			if("растолкали")
				TEST_ASSERT(HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "Заложника «Помощь» не будит: держит захват.")
				SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, crew)
		TEST_ASSERT(QDELETED(hold), "Захват сорван: [method].")
		TEST_ASSERT(!victim.IsParalyzed(), "Отпущенный заложник снова двигается: [method].")
		TEST_ASSERT_NOTNULL(capture_immunity(victim, "blade_throat"), "После захвата невосприимчивость: [method].")
		TEST_ASSERT_NULL(knowledge.throat_hold, "Знание забыло заложника: [method].")
		user.fully_heal()
		user.SetKnockdown(0)
		user.set_resting(FALSE, TRUE)
		if(!knowledge.held_blade(user))
			user.put_in_hands(blade)
		qdel(victim)

/area/security/unit_test_blade_slash
	name = "Blade Slash Test Security"
	requires_power = FALSE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/// Дверь Клинка: цель охоты под своим клинком у горла уводится разрезом за 1,5 секунды, без своего удержания двери нет; «Помощь» заложника не освобождает, 2 секунды растолкать - освобождают; разрез выводит на безопасный пол в 5-9 клетках от входа и не в охрану.
/datum/unit_test/heretic_blade_throat_door/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/list/fixture = blade_throat_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	qdel(fixture["attacker"])
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	TEST_ASSERT_NULL(knowledge.pocket_door(user, victim), "Без клинка у горла двери Клинка нет.")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/datum/status_effect/heretic_blade_throat/stranger_hold = seize_blade_hostage(fixture, stranger)
	TEST_ASSERT_NOTNULL(stranger_hold, "Заложником взят посторонний.")
	TEST_ASSERT_NULL(knowledge.pocket_door(user, victim), "Чужой заложник не открывает дверь к цели.")
	qdel(stranger_hold)
	var/datum/status_effect/heretic_blade_throat/hold = seize_blade_hostage(fixture, victim)
	TEST_ASSERT_NOTNULL(hold, "Цель охоты - заложник.")
	TEST_ASSERT_NULL(knowledge.pocket_door(stranger, victim), "Держит не он: дверь только у своего удержания.")
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, get_step(spot, NORTH))
	victim.help_shake_act(helper)
	helper.forceMove(get_step(helper, EAST))
	TEST_ASSERT(!QDELETED(hold) && victim.IsParalyzed(), "Клик «Помощи» не освобождает заложника.")
	var/list/door = knowledge.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Свою цель у горла Клинок уводит разрезом.")
	TEST_ASSERT_EQUAL(door["time"], HERETIC_BLADE_THROAT_DOOR_TIME, "Разрез занимает 1,5 секунды.")
	var/started = world.time
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Разрез уводит цель в изнанку.")
	TEST_ASSERT(world.time - started >= HERETIC_BLADE_THROAT_DOOR_TIME - world.tick_lag, "Разрез длится 1,5 секунды: [world.time - started] дс.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	TEST_ASSERT(victim.IsParalyzed(), "Вход держит цель.")
	var/list/exits = knowledge.pocket_exits(user)
	TEST_ASSERT_EQUAL(length(exits), 1, "Свой выход Клинка - один разрез.")
	var/label = exits[1]
	TEST_ASSERT(findtext(label, "Разрез"), "Выход подписан разрезом: [label]")
	var/list/all_exits = heretic.pocket_exits(user)
	TEST_ASSERT(all_exits[label], "Разрез есть в списке выходов изнанки.")
	for(var/roll in 1 to 10)
		var/turf/slash = knowledge.slash_exit(spot)
		var/distance = get_dist(slash, spot)
		TEST_ASSERT(slash && distance >= HERETIC_BLADE_SLASH_MIN && distance <= HERETIC_BLADE_SLASH_MAX, "Разрез в 5-9 клетках от входа: [distance].")
		TEST_ASSERT(is_safe_turf(slash) && heretic_pocket_exit_allowed(slash), "Разрез выводит на безопасный пол станции.")
	var/list/candidates = list()
	for(var/turf/open/floor/candidate in RANGE_TURFS(HERETIC_BLADE_SLASH_MAX, spot))
		if(get_dist(candidate, spot) >= HERETIC_BLADE_SLASH_MIN && is_safe_turf(candidate) && heretic_pocket_landable(candidate) && heretic_pocket_exit_allowed(candidate))
			candidates += candidate
	TEST_ASSERT(length(candidates) >= 2, "Для проверки разреза есть хотя бы две клетки пола.")
	var/turf/open_spot = candidates[1]
	for(var/turf/secured as anything in candidates - open_spot)
		heretic_test_area(secured, /area/security/unit_test_blade_slash)
	for(var/roll in 1 to 10)
		TEST_ASSERT_EQUAL(knowledge.slash_exit(spot), open_spot, "Разрез не выводит в охрану и командование.")
	heretic_test_area(open_spot, /area/security/unit_test_blade_slash)
	TEST_ASSERT_NULL(knowledge.slash_exit(spot), "Без разрешённого пола разреза нет.")
	heretic.pocket.collapse("проверка")
	TEST_ASSERT_NULL(knowledge.pocket_exits(user), "Без открытой изнанки разреза нет.")
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		qdel(immunity)
	hold = seize_blade_hostage(fixture, victim)
	TEST_ASSERT_NOTNULL(hold, "Цель снова заложник.")
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, helper)
	TEST_ASSERT(QDELETED(hold), "Растолканного заложника клинок отпускает.")
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HERETIC_CAPTURE_HOLD), "После клинка у горла удержание снято.")

/// Отбить пулю: Выжидание уводит пулю и лазер спереди вбок, а не в стрелка; выстрел сбоку, сзади и мгновенный луч стойка гасит. Каждый выстрел тратит блок.
/datum/unit_test/heretic_blade_deflect/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/attacker = fixture["attacker"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	attacker.forceMove(locate(user.x + 3, user.y, user.z))
	user.setDir(EAST)
	TEST_ASSERT(knowledge.begin_parry(user), "Стойка поднята.")
	var/obj/item/projectile/bullet/bullet = blade_test_shot(attacker, user)
	bullet.damage = 20
	var/angle_before = bullet.Angle
	TEST_ASSERT_EQUAL(user.bullet_act(bullet, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Пуля спереди отбита и летит дальше.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Отбитая пуля не ранит.")
	var/turn = abs(MODULUS(bullet.Angle - angle_before + 180, 360) - 180)
	TEST_ASSERT(abs(turn - HERETIC_BLADE_DEFLECT_TURN) < 1, "Пуля уходит вбок, а не в стрелка: поворот [turn] градусов.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 2, "Отбитая пуля тратит блок.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Отбитая пуля даёт Темп.")
	var/obj/item/projectile/beam/laser/laser = blade_test_shot(attacker, user, /obj/item/projectile/beam/laser)
	TEST_ASSERT_EQUAL(user.bullet_act(laser, BODY_ZONE_CHEST), BULLET_ACT_FORCE_PIERCE, "Лазер спереди отбит.")
	TEST_ASSERT_EQUAL(user.getFireLoss(), 0, "Отбитый лазер не жжёт.")
	TEST_ASSERT_EQUAL(knowledge.active_parry.blocks_left, 1, "Лазер тоже тратит блок.")
	var/list/absorbed = list()
	user.setDir(NORTH)
	var/obj/item/projectile/bullet/side = blade_test_shot(attacker, user)
	side.damage = 10
	absorbed["сбоку"] = side
	user.setDir(WEST)
	var/obj/item/projectile/bullet/back = blade_test_shot(attacker, user)
	back.damage = 10
	absorbed["сзади"] = back
	var/obj/item/projectile/bullet/instant = blade_test_shot(attacker, user)
	instant.damage = 10
	instant.hitscan = TRUE
	absorbed["мгновенный луч спереди"] = instant
	for(var/label in absorbed)
		var/obj/item/projectile/shot = absorbed[label]
		if(label == "сзади")
			user.setDir(WEST)
		else if(label == "сбоку")
			user.setDir(NORTH)
		else
			user.setDir(EAST)
		if(QDELETED(knowledge.active_parry))
			TEST_ASSERT(knowledge.begin_parry(user), "Новая стойка поднята ([label]).")
		var/blocks_before = knowledge.active_parry.blocks_left
		var/shot_angle = shot.Angle
		TEST_ASSERT_EQUAL(user.bullet_act(shot, BODY_ZONE_CHEST), BULLET_ACT_BLOCK, "Выстрел [label] стойка гасит.")
		TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Погашенный выстрел [label] не ранит.")
		TEST_ASSERT_EQUAL(shot.Angle, shot_angle, "Выстрел [label] не уводится вбок.")
		TEST_ASSERT(QDELETED(knowledge.active_parry) || knowledge.active_parry.blocks_left == blocks_before - 1, "Выстрел [label] тратит блок.")
	attacker.forceMove(locate(user.x + 3, user.y + 2, user.z))
	user.setDir(EAST)
	var/obj/item/projectile/bullet/diagonal = blade_test_shot(attacker, user)
	TEST_ASSERT(heretic_blade_deflectable(user, diagonal), "Выстрел спереди наискось ещё в секторе 90 градусов.")
	user.setDir(NORTH)
	attacker.forceMove(locate(user.x + 3, user.y + 1, user.z))
	var/obj/item/projectile/bullet/wide = blade_test_shot(attacker, user)
	TEST_ASSERT(!heretic_blade_deflectable(user, wide), "Выстрел почти сбоку вне сектора.")

/// Числа в текстах Клинка совпадают с правилами.
/datum/unit_test/heretic_blade_texts/Run()
	var/datum/eldritch_knowledge/base_blade/base = allocate(/datum/eldritch_knowledge/base_blade)
	var/datum/eldritch_knowledge/spell/blade_throat/throat = allocate(/datum/eldritch_knowledge/spell/blade_throat)
	var/datum/eldritch_knowledge/blade_disarm/disarm = allocate(/datum/eldritch_knowledge/blade_disarm)
	var/door_time = replacetext("[HERETIC_BLADE_THROAT_DOOR_TIME / (1 SECONDS)]", ".", ",")
	for(var/fragment in list("не дальше [HERETIC_BLADE_CHALLENGE_RANGE] клеток", "[HERETIC_BLADE_CHALLENGE_CALM / (1 SECONDS)] секунд без урона", "[HERETIC_BLADE_CHALLENGE_TIMEOUT / (1 SECONDS)] секунд", "изнанку на [HERETIC_BLADE_DUEL_DURATION / (1 SECONDS)] секунд", "[HERETIC_BLADE_OATH_HOLD / (1 SECONDS)] секунд", "[HERETIC_BLADE_BRAND_DURATION / (1 MINUTES)] минут на вашей шее", "кроме Выжидания и призыва сердца или кодекса", "где откроется изнанка", "[HERETIC_BLADE_DEFLECT_ARC] градусов"))
		TEST_ASSERT(findtext(base.desc, fragment), "Описание базы называет «[fragment]».")
	for(var/fragment in list("[HERETIC_BLADE_THROAT_DURATION / (1 SECONDS)] секунд", "[HERETIC_BLADE_THROAT_WINDOW / (1 SECONDS)] секунд", "[HERETIC_BLADE_THROAT_BREAK_DAMAGE]+ урона", "[HERETIC_BLADE_THROAT_COOLDOWN / (1 SECONDS)] секунд", "за [door_time] секунды", "растолкать - [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунды", "обряд сердцем над ним работает"))
		TEST_ASSERT(findtext(throat.desc, fragment), "Описание Клинка у горла называет «[fragment]».")
	for(var/fragment in list("[HERETIC_BLADE_DISARM_DISTANCE] клетки", "[HERETIC_BLADE_DISARM_COOLDOWN / (1 SECONDS)] секунд", "[HERETIC_BLADE_THROAT_WINDOW / (1 SECONDS)] секунды"))
		TEST_ASSERT(findtext(disarm.desc, fragment), "Описание Обезоруживания называет «[fragment]».")
	var/obj/effect/proc_holder/spell/pointed/heretic_blade_challenge/challenge = /obj/effect/proc_holder/spell/pointed/heretic_blade_challenge
	for(var/fragment in list("не дальше [HERETIC_BLADE_CHALLENGE_RANGE] клеток", "[HERETIC_BLADE_CHALLENGE_CALM / (1 SECONDS)] секунд должны быть без урона", "ответ у него [HERETIC_BLADE_CHALLENGE_TIMEOUT / (1 SECONDS)] секунд", "изнанку на [HERETIC_BLADE_DUEL_DURATION / (1 SECONDS)] секунд", "клятвой на [HERETIC_BLADE_OATH_HOLD / (1 SECONDS)] секунд", "на [HERETIC_BLADE_BRAND_DURATION / (1 MINUTES)] минут оставляет на шее", "закрывает вызовы на [HERETIC_BLADE_DUEL_LOCKOUT / (1 MINUTES)] минут", "вызвать только через [HERETIC_BLADE_CHALLENGE_REPEAT / (1 MINUTES)] минут", "кроме призыва сердца или кодекса", "только там, где может открыться изнанка", "вырвавшийся из изнанки, проиграл"))
		TEST_ASSERT(findtext(initial(challenge.desc), fragment), "Кнопка Вызова называет «[fragment]».")
	var/obj/effect/proc_holder/spell/pointed/heretic_blade_throat/throat_spell = /obj/effect/proc_holder/spell/pointed/heretic_blade_throat
	for(var/fragment in list("за [door_time] секунды", "[HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунды растолкать", "Перезарядка [HERETIC_BLADE_THROAT_COOLDOWN / (1 SECONDS)] секунд", "обряд сердцем над ней работает"))
		TEST_ASSERT(findtext(initial(throat_spell.desc), fragment), "Кнопка Клинка у горла называет «[fragment]».")
	TEST_ASSERT(findtext(base.desc, "закрывает вызовы на [HERETIC_BLADE_DUEL_LOCKOUT / (1 MINUTES)] минут"), "База называет срок запрета после поражения.")
	TEST_ASSERT(findtext(base.desc, "вызвать только через [HERETIC_BLADE_CHALLENGE_REPEAT / (1 MINUTES)] минут"), "База отдельно называет срок до повторного вызова того же человека.")
	var/datum/action/innate/heretic_blade_surrender/surrender = /datum/action/innate/heretic_blade_surrender
	TEST_ASSERT(findtext(initial(surrender.desc), "[HERETIC_BLADE_OATH_HOLD / (1 SECONDS)] секунд"), "Кнопка «Сдаться» называет срок клятвы.")
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_BLADE]
	TEST_ASSERT(findtext(path.craft_summary, "[HERETIC_BLADE_OATH_HOLD / (1 SECONDS)] секунд"), "Модель пути называет срок клятвы.")
	TEST_ASSERT(findtext(path.capture_summary, "[HERETIC_BLADE_THROAT_DURATION / (1 SECONDS)] секунд"), "Модель пути называет срок захвата.")
	TEST_ASSERT(findtext(path.escape_summary, "[HERETIC_BLADE_SLASH_MIN]-[HERETIC_BLADE_SLASH_MAX] клетках"), "Модель пути называет дальность разреза.")
	TEST_ASSERT(findtext(path.combat_practice, "за [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунды") && findtext(path.combat_practice, "изнанки нет"), "Полигон называет «растолкать» и изнанку только на станции.")
	TEST_ASSERT(findtext(path.weaknesses, "шаг дальше клетки"), "Слабые стороны: заложника срывает шаг дальше клетки, а не любой шаг.")
	TEST_ASSERT(!findtext(throat.desc, "а «Помощь» - нет"), "Знание не спорит само с собой о «Помощи».")
	var/datum/status_effect/heretic_blade_oath/oath = /datum/status_effect/heretic_blade_oath
	var/atom/movable/screen/alert/status_effect/heretic_blade_oath/oath_alert = /atom/movable/screen/alert/status_effect/heretic_blade_oath
	for(var/oath_text in list(initial(oath.examine_text), initial(oath_alert.desc), jointext(base.details, " ")))
		TEST_ASSERT(findtext(oath_text, "[HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунд"), "Клятва называет «растолкать»: [oath_text]")
	var/atom/movable/screen/alert/status_effect/heretic_parry/parry_alert = /atom/movable/screen/alert/status_effect/heretic_parry
	TEST_ASSERT_EQUAL(initial(parry_alert.name), "Выжидание", "Значок стойки зовётся как кнопка.")
	var/datum/eldritch_knowledge/blade_guard/guard = allocate(/datum/eldritch_knowledge/blade_guard)
	TEST_ASSERT(findtext(guard.desc, "от [guard.passive_values[1]] выносливости"), "Неподвижная грань называет нижнюю планку выносливости.")
	var/datum/heretic_deed/blade/deed = /datum/heretic_deed/blade
	TEST_ASSERT(!findtext(initial(deed.trace_desc), "круг"), "След дела не описывает снятый круг поединка.")
	TEST_ASSERT_EQUAL(path.knowledge[4], /datum/eldritch_knowledge/spell/blade_throat, "Клинок у горла на четвёртой ступени.")
	TEST_ASSERT_EQUAL(path.knowledge[8], /datum/eldritch_knowledge/blade_mark, "Метка поединка на восьмой ступени.")

/// Удаление базы Клинка снимает кнопку Вызова, ждущий вызов, идущую дуэль с ареной и заложника в ней.
/datum/unit_test/heretic_blade_destroy_cleanup/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLADE)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blade/blade = heretic.get_knowledge(/datum/eldritch_knowledge/base_blade)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blade_throat)
	var/turf/origin = run_loc_floor_bottom_left
	var/turf/rival_spot = locate(origin.x + 4, origin.y + 2, origin.z)
	user.forceMove(locate(origin.x, origin.y + 2, origin.z))
	var/obj/item/melee/sickly_blade/duelist/weapon = allocate(/obj/item/melee/sickly_blade/duelist)
	weapon.bound_mind = user.mind
	user.put_in_hands(weapon)
	var/mob/living/carbon/human/rival = start_blade_duel(heretic, rival_spot)
	TEST_ASSERT_NOTNULL(rival, "Дуэль началась.")
	var/datum/heretic_blade_duel/duel = blade.active_duel
	var/datum/heretic_pocket/arena = heretic.pocket
	var/mob/living/carbon/human/hostage = allocate(/mob/living/carbon/human, get_step(user, SOUTH))
	var/datum/status_effect/heretic_blade_throat/hold = seize_blade_hostage(list("knowledge" = blade, "user" = user), hostage)
	TEST_ASSERT_NOTNULL(hold, "Заложник взят в изнанке.")
	var/mob/living/carbon/human/pending = blade_test_crew(locate(origin.x + 2, origin.y + 4, origin.z))
	blade.open_challenge(user, pending)
	var/challenge_timer = blade.challenge_timer
	var/obj/effect/proc_holder/spell/challenge = blade.challenge_spell
	heretic.researched_knowledge -= blade.type
	qdel(blade)
	TEST_ASSERT(QDELETED(challenge), "Кнопка Вызова снята.")
	TEST_ASSERT_NULL(blade.challenged_ref, "Ждущий вызов закрыт.")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[challenge_timer], "Таймер ответа снят.")
	TEST_ASSERT(QDELETED(duel), "Дуэль прекращена.")
	TEST_ASSERT(!arena.active && !arena.contains(user) && !arena.contains(rival), "Арена закрыта, дуэлянты снаружи.")
	TEST_ASSERT_NULL(rival.has_status_effect(/datum/status_effect/heretic_blade_oath), "Удаление - не победа: клятвы нет.")
	TEST_ASSERT(QDELETED(hold), "Заложник отпущен.")
	TEST_ASSERT(!hostage.IsParalyzed(), "Отпущенный заложник снова двигается.")
	TEST_ASSERT_NULL(locate(/datum/action/innate/heretic_blade_surrender) in rival.actions, "Кнопка «Сдаться» снята.")
