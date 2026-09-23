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
	knowledge.ascension_active = TRUE
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
	TEST_ASSERT(abs(attacker.AmountKnockdown() - 1.5 SECONDS) <= world.tick_lag, "Успешное сближение оставляет время на следующий удар.")
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
