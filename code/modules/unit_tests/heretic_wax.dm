/// Стартовая хватка отливает расходуемую свечу для оружия и уходит на перезарядку.
/datum/unit_test/heretic_wax_candle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_wax, user), "Отливка открывается вместе с выбором пути.")
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/center = get_turf(user)
	var/obj/item/paper/paper = allocate(/obj/item/paper, center)
	var/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp/spell = allocate(/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp)
	TEST_ASSERT(spell.ChargeHand(user), "Хватка создаёт привязанную руку.")
	spell.charge_counter = 0
	spell.recharging = FALSE
	var/obj/item/melee/touch_attack/mansus_fist/hand = spell.attached_hand
	hand.afterattack(paper, user, TRUE)
	TEST_ASSERT(QDELETED(paper), "Отливка расходует бумагу.")
	TEST_ASSERT(QDELETED(hand) && spell.recharging, "Отливка расходует хватку и запускает перезарядку.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 2, "Одна свеча стоит единицу воска.")
	var/obj/item/candle/candle = locate() in center
	TEST_ASSERT_NOTNULL(candle, "На месте бумаги появляется свеча.")
	allocated += candle
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife, center)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, center)
	wax.ritual_time = 0
	TEST_ASSERT(rune.do_ritual(user, wax), "Отлитая свеча подходит для первого оружия.")
	TEST_ASSERT(QDELETED(candle) && QDELETED(knife), "Обряд расходует свечу и нож.")
	var/obj/item/melee/sickly_blade/wax/blade = locate() in center
	TEST_ASSERT_NOTNULL(blade, "Обряд создаёт оружие Воска.")
	allocated += blade

/// Отказ от отливки сохраняет бумагу, воск и подготовленную хватку.
/datum/unit_test/heretic_wax_candle_rejections/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/item/melee/touch_attack/mansus_fist/hand = allocate(/obj/item/melee/touch_attack/mansus_fist)
	var/obj/item/paper/paper = allocate(/obj/item/paper, get_turf(user))
	hand.afterattack(paper, user, TRUE)
	TEST_ASSERT(!QDELETED(paper) && !QDELETED(hand), "Без пути Воска отливка недоступна.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_wax, user), "Выбор пути доступен.")
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	wax.combat_resource = 0
	hand.afterattack(paper, user, TRUE)
	TEST_ASSERT(!QDELETED(paper) && !QDELETED(hand), "Без воска бумага и хватка сохраняются.")
	wax.combat_resource = 2
	TEST_ASSERT(user.put_in_hands(paper), "Бумагу можно взять в руку.")
	TEST_ASSERT(!wax.on_mansus_grasp(paper, user, TRUE), "Бумага в инвентаре не превращается в свечу.")
	user.dropItemToGround(paper)
	TEST_ASSERT(!wax.on_mansus_grasp(paper, user, FALSE), "Дистанционный вызов не отливает свечу.")
	paper.forceMove(get_step(get_step(user, EAST), EAST))
	TEST_ASSERT(!wax.on_mansus_grasp(paper, user, TRUE), "Бумага вне досягаемости не подходит.")
	paper.forceMove(get_turf(user))
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, get_turf(user))
	TEST_ASSERT(rune.reserve_atoms(list(paper)), "Бумага занята другим обрядом.")
	hand.afterattack(paper, user, TRUE)
	TEST_ASSERT(!QDELETED(paper) && !QDELETED(hand), "Чужая резервация сохраняет бумагу и хватку.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 2, "Отклонённые попытки не тратят воск.")
	rune.release_atoms()
	hand.afterattack(paper, user, TRUE)
	TEST_ASSERT(QDELETED(paper) && QDELETED(hand), "После снятия резервации та же хватка отливает свечу.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 1, "Успешная попытка тратит одну единицу.")
	var/obj/item/candle/candle = locate() in get_turf(user)
	TEST_ASSERT_NOTNULL(candle, "После отказов всё ещё можно изготовить свечу.")
	allocated += candle

/// Дальний выброс расходует оболочку, масштабируется от её остатка и не добавляет контроль.
/datum/unit_test/heretic_wax_shell_release/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/edge = get_step(get_step(get_step(get_step(user, EAST), EAST), EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, edge)
	var/mob/living/behind = allocate(/mob/living/carbon/human, get_step(user, WEST))
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 3)
	user.setDir(EAST)
	TEST_ASSERT(wax.raise_shell(user), "Оболочка оплачена до выброса.")
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	var/obj/structure/heretic_wax_candle/candle = shell.candles[1]
	var/obj/effect/proc_holder/spell/self/heretic_wax/release/spell = wax.combat_power
	user.a_intent = INTENT_DISARM
	spell.cast(list(user), user)
	TEST_ASSERT(QDELETED(shell) && QDELETED(candle), "Выброс расходует и оболочку, и её свечу.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_shell), "Выброс снимает вес оболочки.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 1, "Выброс оплачивается оболочкой, не дополнительным воском.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) <= DAMAGE_PRECISION, "Осколки достают дальше обычного веера и наносят тридцать ушибов.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 0, "Выброс не добавляет урон выносливости.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_wax/clinging) && !victim.has_status_effect(/datum/status_effect/heretic_wax/seal), "Выброс не добавляет замедление и печать обычной волны.")
	TEST_ASSERT_EQUAL(behind.getBruteLoss(), 0, "Веер сохраняет выбранное направление.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия останавливает осколки.")
	TEST_ASSERT_EQUAL(protection.charges, 2, "На защищённую цель потрачен один заряд.")
	TEST_ASSERT(!wax.release(user, consume_shell = TRUE), "Повторный выброс без оболочки отклоняется.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 1, "Отказ не расходует воск.")
	wax.combat_resource = 2
	wax.raise_shell(user)
	shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	shell.capacity = 15
	TEST_ASSERT(wax.release(user, consume_shell = TRUE), "Повреждённая оболочка тоже расходуется.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 40) <= DAMAGE_PRECISION, "Пятнадцать остатка прочности дают только десять урона.")

/// Первый веер немедленно работает без свечей, учитывает направление, стены и антимагию.
/datum/unit_test/heretic_wax_opening/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(get_step(run_loc_floor_bottom_left, NORTH), EAST))
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/behind = allocate(/mob/living/carbon/human, get_step(user, WEST))
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	user.setDir(EAST)
	TEST_ASSERT(wax.release(user), "Начальная волна не требует свечей.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 18) <= DAMAGE_PRECISION, "Первый удар немедленно наносит 18 ушибов.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_wax/seal), "Попадание оставляет оттиск для продолжения.")
	TEST_ASSERT_EQUAL(behind.getBruteLoss(), 0, "Цель за спиной не попадает в веер.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия останавливает волну.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Волна расходует один заряд на цель.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 2, "Волна расходует единицу.")
	var/obj/blocker = allocate(/obj, get_turf(victim))
	blocker.density = TRUE
	wax.release(user)
	TEST_ASSERT(abs(victim.getBruteLoss() - 18) <= DAMAGE_PRECISION, "Преграда закрывает повторный удар.")
	wax.combat_resource = 0
	TEST_ASSERT(!wax.release(user), "Пустой запас не выпускает волну.")

/// Первые исследования дают дальнюю атаку, за ней Сон по кукле, оболочка с канделябром, метка и Протечь.
/datum/unit_test/heretic_wax_early_imprint/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.knowledge_points = 20
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_wax, user), "Можно выбрать путь воска.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/wax_grasp, user), "Хватка остаётся второй ступенью.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/spell/wax_imprint, user), "Двойник доступен уже на третьей ступени.")
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	TEST_ASSERT(wax.imprint(user, victim), "Ранний оттиск работает без оболочки, реликвии и улучшения клинка.")
	TEST_ASSERT_NOTNULL(wax.active_effigy, "Оттиск создаёт доступного для атаки двойника.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/spell/wax_puppet_sleep, user), "Сон по кукле следует за оттиском.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/spell/wax_shell, user), "Защита и канделябр доступны на пятой ступени.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/wax_mark, user), "Метка занимает шестую ступень.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/spell/wax_leak, user), "Протечь открывается седьмой ступенью.")

/// Волна достаёт на три клетки, а краткое замедление обновляется без накопления силы.
/datum/unit_test/heretic_wax_pressure/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/edge = get_step(get_step(get_step(user, EAST), EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, edge)
	var/mob/living/outside = allocate(/mob/living/carbon/human, get_step(edge, EAST))
	var/original_slowdown = victim.cached_multiplicative_slowdown
	user.setDir(EAST)
	TEST_ASSERT(wax.release(user), "Стартовая волна доступна.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 18) <= DAMAGE_PRECISION, "Цель на третьей клетке получает полноценный удар.")
	TEST_ASSERT_EQUAL(outside.getBruteLoss(), 0, "Четвёртая клетка за пределами волны.")
	TEST_ASSERT(!outside.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_clinging), "Волна не замедляет цель за пределами дальности.")
	TEST_ASSERT(victim.cached_multiplicative_slowdown > original_slowdown, "Воск действительно замедляет движение.")
	TEST_ASSERT(!victim.incapacitated(), "Воск оставляет возможность отвечать на атаку.")
	var/datum/status_effect/heretic_wax/clinging/old_slow = victim.has_status_effect(/datum/status_effect/heretic_wax/clinging)
	var/slowed_speed = victim.cached_multiplicative_slowdown
	TEST_ASSERT(wax.release(user), "Повторное попадание обновляет воск.")
	TEST_ASSERT(QDELETED(old_slow), "Прежний статус заменён.")
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, slowed_speed, "Замедления не складываются.")
	var/datum/status_effect/heretic_wax/clinging/slow = victim.has_status_effect(/datum/status_effect/heretic_wax/clinging)
	TEST_ASSERT(abs(slow.duration - world.time - 2 SECONDS) <= world.tick_lag, "Новое попадание даёт только две секунды замедления.")
	slow.duration = world.time - world.tick_lag
	slow.process()
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_clinging), "Истечение статуса снимает замедление.")
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, original_slowdown, "После истечения возвращается исходная скорость.")

/// Преграды и антимагия останавливают контроль, а потеря знания снимает только его замедление.
/datum/unit_test/heretic_wax_pressure_counterplay/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_imprint)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	var/obj/blocker = allocate(/obj, get_step(user, EAST))
	blocker.density = TRUE
	user.setDir(EAST)
	wax.release(user)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_wax/clinging), "Преграда закрывает от замедления волной.")
	TEST_ASSERT(!wax.imprint(user, victim), "Преграда закрывает от снятия оттиска.")
	qdel(blocker)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 3)
	wax.release(user)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_wax/clinging), "Антимагия останавливает и урон, и замедление.")
	TEST_ASSERT_EQUAL(protection.charges, 2, "Одна волна расходует один заряд антимагии.")
	qdel(protection)
	victim.add_movespeed_modifier(/datum/movespeed_modifier/heretic_moon_opening)
	wax.combat_resource = 3
	TEST_ASSERT(wax.imprint(user, victim), "После снятия защиты оттиск замедляет цель.")
	qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spell/wax_imprint))
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_clinging), "Удаление знания снимает замедление оттиска.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_moon_opening), "Чужое замедление остаётся.")

/// Хватка и детонация делят задержку, а восстановление ограничено стоимостью одной оболочки.
/datum/unit_test/heretic_wax_resource/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/wax_grasp)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/wax_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/wax_grasp)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.mind = allocate_mind()
	victim.mind.current = victim
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE), "Хватка ставит печать.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 4, "Разумная цель даёт единицу.")
	wax.on_mark_detonated(user, victim)
	TEST_ASSERT_EQUAL(wax.combat_resource, 4, "Метка не обходит общую задержку.")
	COOLDOWN_RESET(wax, wax_harvest)
	wax.on_mark_detonated(user, victim)
	TEST_ASSERT_EQUAL(wax.combat_resource, 5, "Следующая детонация пополняет конечный запас.")
	wax.combat_resource = 0
	COOLDOWN_RESET(wax, wax_recovery)
	wax.on_life(user)
	TEST_ASSERT_EQUAL(wax.combat_resource, 1, "Пустой запас восстанавливается до одного.")
	COOLDOWN_RESET(wax, wax_recovery)
	wax.on_life(user)
	TEST_ASSERT_EQUAL(wax.combat_resource, 2, "Ожидание восстанавливает стоимость одной оболочки.")
	COOLDOWN_RESET(wax, wax_recovery)
	wax.on_life(user)
	TEST_ASSERT_EQUAL(wax.combat_resource, 2, "Ожидание не заполняет остальную вместимость.")
	var/mob/living/animal = allocate(/mob/living/simple_animal/mouse, get_step(user, NORTH))
	COOLDOWN_RESET(wax, wax_harvest)
	TEST_ASSERT(!wax.harvest(user, animal), "Животное не производит воск.")
	victim.stat = DEAD
	TEST_ASSERT(!wax.harvest(user, victim), "Мёртвый разум не производит воск.")

/// Разряд дубинки расходует оболочку и пропускает только урон сверх её остатка.
/datum/unit_test/heretic_wax_baton/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/attacker = allocate(/mob/living/carbon/human, get_step(user, EAST))
	attacker.mind = allocate_mind()
	attacker.mind.current = attacker
	var/obj/item/melee/baton/loaded/baton = allocate(/obj/item/melee/baton/loaded)
	TEST_ASSERT(wax.raise_shell(user), "Оболочка создана до атаки дубинкой.")
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	var/list/preview = list()
	user.do_run_block(FALSE, baton, 0, "разряд", ATTACK_TYPE_MELEE, 0, attacker, null, preview)
	TEST_ASSERT_EQUAL(shell.capacity, 45, "Предпросмотр разряда не расходует защиту.")
	TEST_ASSERT(!baton.baton_stun(user, attacker, shoving = TRUE), "Оболочка полностью принимает первый разряд.")
	TEST_ASSERT_EQUAL(user.getStaminaLoss(), 0, "Поглощённый разряд не повреждает выносливость.")
	TEST_ASSERT(!user.IsKnockdown(), "Полный блок останавливает сбивание дубинкой.")
	TEST_ASSERT_EQUAL(shell.capacity, 10, "Разряд расходует свои 35 урона из общего запаса.")
	TEST_ASSERT_EQUAL(shell.absorbed_hostile, 0, "Разряд не создаёт запас лечения ран.")
	TEST_ASSERT(baton.baton_stun(user, attacker), "Второй разряд пробивает остаток оболочки.")
	var/mob/living/reference = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	reference.apply_damage(25, STAMINA, BODY_ZONE_CHEST)
	TEST_ASSERT(abs(user.getStaminaLoss() - reference.getStaminaLoss()) <= DAMAGE_PRECISION, "После поглощения десяти проходит ровно 25 урона.")
	TEST_ASSERT_EQUAL(shell.capacity, 0, "Оболочка исчерпана.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_shell), "Исчерпанная оболочка не мешает отступать.")
	wax.combat_resource = 2
	TEST_ASSERT(wax.raise_shell(user), "После исчерпания можно создать новую оболочку.")
	shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	baton.cell.charge = 0
	TEST_ASSERT(!baton.baton_stun(user, attacker), "Разряженная дубинка не наносит электрический удар.")
	TEST_ASSERT_EQUAL(shell.capacity, 45, "Разряженная дубинка не расходует защиту.")

/// Дизейблер использует тот же конечный запас оболочки, что и обычное оружие.
/datum/unit_test/heretic_wax_disabler/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/attacker = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/item/projectile/beam/disabler/beam = allocate(/obj/item/projectile/beam/disabler)
	beam.firer = attacker
	beam.starting = get_turf(attacker)
	TEST_ASSERT(wax.raise_shell(user), "Оболочка создана до выстрела.")
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	TEST_ASSERT_EQUAL(user.bullet_act(beam, BODY_ZONE_CHEST), BULLET_ACT_BLOCK, "Первый луч полностью поглощается.")
	TEST_ASSERT_EQUAL(user.getStaminaLoss(), 0, "Полный блок луча сохраняет выносливость.")
	TEST_ASSERT_EQUAL(shell.capacity, 15, "Луч расходует тридцать прочности.")
	user.bullet_act(beam, BODY_ZONE_CHEST)
	TEST_ASSERT(user.getStaminaLoss() > 0, "Следующий луч наносит урон сверх остатка.")
	TEST_ASSERT_EQUAL(shell.capacity, 0, "Урон по выносливости не обходит конечный запас.")
	TEST_ASSERT_EQUAL(shell.absorbed_hostile, 0, "Дизейблер не создаёт лечения ран.")

/// Оболочка использует настоящий блок, пропускает избыток и не восстанавливает израсходованную ёмкость.
/datum/unit_test/heretic_wax_shell_budget/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/attacker = allocate(/mob/living/carbon/human, get_step(user, EAST))
	attacker.mind = allocate_mind()
	attacker.mind.current = attacker
	var/obj/item/kitchen/knife/weapon = allocate(/obj/item/kitchen/knife)
	TEST_ASSERT(wax.raise_shell(user), "Оболочка доступна с начальным запасом.")
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	TEST_ASSERT_EQUAL(shell.capacity, 45, "Начальная ёмкость 45.")
	var/list/preview = list()
	user.do_run_block(FALSE, weapon, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, preview)
	TEST_ASSERT_EQUAL(shell.capacity, 45, "Предпросмотр не расходует оболочку.")
	var/list/first = list()
	TEST_ASSERT(user.mob_run_block(weapon, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, first) & BLOCK_SUCCESS, "Первый удар полностью поглощён.")
	TEST_ASSERT_EQUAL(shell.capacity, 25, "Двадцать урона снято с ёмкости.")
	var/list/second = list()
	TEST_ASSERT(!(user.mob_run_block(weapon, 50, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, second) & BLOCK_SUCCESS), "Избыточный удар не блокируется целиком.")
	TEST_ASSERT_EQUAL(block_calculate_resultant_damage(50, second), 25, "Ровно двадцать пять урона проходит дальше.")
	TEST_ASSERT_EQUAL(second[BLOCK_RETURN_PROJECTILE_BLOCK_PERCENTAGE], 50, "Частичная защита передаёт процент в масштабе 0–100.")
	TEST_ASSERT_EQUAL(shell.capacity, 0, "Ёмкость исчерпана.")
	TEST_ASSERT_EQUAL(shell.absorbed_hostile, 45, "Реликвия учитывает только действительно поглощённый урон.")
	var/list/third = list()
	user.mob_run_block(weapon, 10, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, third)
	TEST_ASSERT_EQUAL(block_calculate_resultant_damage(10, third), 10, "Исчерпанная оболочка больше не защищает.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/wax_temper)
	TEST_ASSERT_EQUAL(wax.combat_resource_max, 6, "Пассивка увеличивает вместимость.")
	TEST_ASSERT_EQUAL(shell.capacity, 0, "Изучение не чинит старую оболочку.")
	qdel(shell)
	wax.combat_resource = 3
	TEST_ASSERT(wax.raise_shell(user), "После снятия можно создать новую оболочку.")
	shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	TEST_ASSERT_EQUAL(shell.capacity, 55, "Новая оболочка получает улучшение.")
	var/list/prior_block = list(BLOCK_RETURN_SET_DAMAGE_TO = 10)
	shell.absorb_attack(user, TRUE, weapon, 100, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, prior_block)
	TEST_ASSERT_EQUAL(block_calculate_resultant_damage(100, prior_block), 0, "Оболочка сохраняет поглощение предыдущей защиты.")
	TEST_ASSERT_EQUAL(shell.capacity, 45, "Предыдущая защита не расходует воск повторно.")
	TEST_ASSERT_EQUAL(shell.absorbed_hostile, 10, "Предыдущие блоки не создают лечебный запас оболочки.")
	var/obj/item/projectile/beam/disabler/beam = allocate(/obj/item/projectile/beam/disabler)
	user.mob_run_block(beam, 30, "луч", ATTACK_TYPE_PROJECTILE, 0, attacker, BODY_ZONE_CHEST, list())
	TEST_ASSERT_EQUAL(shell.absorbed_hostile, 10, "Оглушающий луч не производит лечение ран.")
	user.Stun(2 SECONDS)
	TEST_ASSERT(!wax.can_use(user), "Оглушение запрещает новые заклинания.")
	TEST_ASSERT(user.mob_run_block(weapon, 15, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, list()) & BLOCK_SUCCESS, "Существующая оболочка защищает оглушённого носителя.")
	TEST_ASSERT_EQUAL(shell.capacity, 0, "Защита при оглушении расходует оставшуюся ёмкость.")

/// Свеча следует за шагом, но её разрушение, перенос или телепортация снимают защиту.
/datum/unit_test/heretic_wax_candle_counterplay/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	wax.raise_shell(user)
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	var/obj/structure/heretic_wax_candle/candle = shell.candles[1]
	user.forceMove(get_step(user, EAST))
	TEST_ASSERT(!QDELETED(shell), "Обычный шаг не обрывает оболочку.")
	TEST_ASSERT_EQUAL(get_turf(candle), get_turf(user), "Свеча следует на новую клетку.")
	TEST_ASSERT(!candle.density, "Спутник не мешает передвижению.")
	candle.take_damage(100, BRUTE, MELEE)
	TEST_ASSERT(QDELETED(shell), "Разрушение свечи снимает защиту.")
	wax.combat_resource = 4
	wax.raise_shell(user)
	shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	candle = shell.candles[1]
	candle.forceMove(get_step(user, NORTH))
	TEST_ASSERT(QDELETED(shell), "Отдельный перенос свечи обрывает связь.")
	wax.raise_shell(user)
	shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	user.forceMove(get_step(get_step(user, NORTH), NORTH))
	TEST_ASSERT(QDELETED(shell), "Телепортация дальше соседней клетки гасит оболочку.")

/// Нулевой жезл проходит через оболочку, а реликвия не лечит неизрасходованную защиту.
/datum/unit_test/heretic_wax_relic_and_nullrod/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/obj/item/heretic_path_relic/wax/relic = allocate(/obj/item/heretic_path_relic/wax)
	relic.creator = WEAKREF(user.mind)
	relic.knowledge_ref = WEAKREF(recipe)
	user.put_in_hands(relic)
	user.adjustBruteLoss(30)
	wax.raise_shell(user)
	TEST_ASSERT(!relic.melt(user), "Неиспользованная оболочка не лечит.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 1, "Отказ не тратит последний воск.")
	var/mob/living/attacker = allocate(/mob/living/carbon/human, get_step(user, EAST))
	attacker.mind = allocate_mind()
	attacker.mind.current = attacker
	var/obj/item/kitchen/knife/weapon = allocate(/obj/item/kitchen/knife)
	user.mob_run_block(weapon, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, list())
	TEST_ASSERT(relic.melt(user), "Поглощённый в бою урон можно переплавить.")
	TEST_ASSERT(abs(user.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Двадцать поглощённого урона лечит десять.")
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_wax/shell), "Переплавка полностью удаляет оболочку.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 1, "Переплавка не требует дополнительного воска.")
	TEST_ASSERT(!relic.melt(user), "Один поглощённый удар нельзя переплавить дважды.")
	wax.combat_resource = 2
	wax.raise_shell(user)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	TEST_ASSERT(!(user.mob_run_block(rod, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, list()) & BLOCK_SUCCESS), "Жезл не поглощается оболочкой.")
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_wax/shell), "Жезл гасит оболочку.")

/// Дальний удар расходует свою печать, а предварительный выбор не тратит антимагию.
/datum/unit_test/heretic_wax_imprint/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_imprint)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	wax.seal(victim)
	TEST_ASSERT(wax.imprint(user, victim), "Оттиск доступен по подготовленной цели.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 26) <= DAMAGE_PRECISION, "Печать усиливает первый удар до 26.")
	TEST_ASSERT_EQUAL(wax.active_effigy.effigy.obj_integrity, 45, "Печать укрепляет двойника.")
	var/datum/status_effect/heretic_wax/effigy/old_effigy = wax.active_effigy
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_wax/seal), "Усиление расходует печать.")
	TEST_ASSERT(wax.imprint(user, victim), "Неподготовленная цель тоже принимает удар.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 40) <= DAMAGE_PRECISION, "Повторный удар наносит базовые 14.")
	TEST_ASSERT(QDELETED(old_effigy), "Новый оттиск заменяет прежний.")
	TEST_ASSERT_EQUAL(wax.active_effigy.effigy.obj_integrity, 30, "Без печати остаётся базовый запас двойника.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 3)
	var/obj/effect/proc_holder/spell/pointed/heretic_wax/imprint/spell = allocate(/obj/effect/proc_holder/spell/pointed/heretic_wax/imprint)
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Выбор отклоняет защищённую цель.")
	TEST_ASSERT(!wax.imprint(user, victim), "Прямой вызов тоже проверяет защиту.")
	TEST_ASSERT_EQUAL(protection.charges, 3, "Неисполненный удар не расходует антимагию.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 1, "Защищённая цель не расходует воск.")

/// Процессия имеет конечное число импульсов и пересчитывает положение носителя.
/datum/unit_test/heretic_wax_procession/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_procession)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(wax.procession(user), "Процессия возникает без прежних свечей.")
	var/datum/status_effect/heretic_wax/procession/procession = user.has_status_effect(/datum/status_effect/heretic_wax/procession)
	TEST_ASSERT(abs(victim.getBruteLoss() - 14) <= DAMAGE_PRECISION, "Первый такт сразу наносит 14 ушибов.")
	TEST_ASSERT_EQUAL(length(procession.candles), 2, "Первый импульс расходует одну из трёх свечей.")
	qdel(procession.candles[1])
	TEST_ASSERT_EQUAL(length(procession.candles), 1, "Разрушение лишает одного будущего такта.")
	user.forceMove(get_step(user, NORTH))
	procession.tick()
	TEST_ASSERT(abs(victim.getBruteLoss() - 28) <= DAMAGE_PRECISION, "Следующий такт действует с нового положения.")
	TEST_ASSERT(QDELETED(procession), "Последняя свеча завершает процессию.")
	TEST_ASSERT_EQUAL(length(wax.effects), 2, "После завершения остаются печать и краткое замедление на жертве.")

/// Замена печати и потеря знания убирают сигналы, свечи и внешние статусы.
/datum/unit_test/heretic_wax_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.apply_innate_effects(heretic.owner.current)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	heretic.gain_knowledge(/datum/eldritch_knowledge/wax_mark)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/status_effect/heretic_wax/seal/old_seal = wax.seal(victim)
	wax.seal(victim)
	TEST_ASSERT(QDELETED(old_seal), "Повторная печать удаляет прежний статус.")
	TEST_ASSERT_EQUAL(length(wax.effects), 1, "Прежние печати не копятся в списке владельца.")
	wax.hinder(victim)
	victim.apply_status_effect(/datum/status_effect/eldritch/wax, wax)
	wax.raise_shell(user)
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	var/obj/structure/heretic_wax_candle/candle = shell.candles[1]
	user.stat = DEAD
	wax.on_death(user)
	TEST_ASSERT(QDELETED(shell) && QDELETED(candle), "Смерть удаляет оболочку и свечу.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_wax/seal), "Смерть снимает внешний оттиск.")
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_clinging), "Смерть снимает внешнее замедление.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/wax), "Смерть снимает внешнюю метку.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 0, "Смерть обнуляет запас.")
	user.stat = CONSCIOUS
	wax.combat_resource = 3
	wax.raise_shell(user)
	shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	var/obj/effect/proc_holder/spell/old_power = wax.combat_power
	var/mob/living/new_body = allocate(/mob/living/carbon/human, get_step(victim, NORTH))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(QDELETED(shell) && QDELETED(old_power), "Переселение удаляет старые эффекты и способность.")
	TEST_ASSERT_EQUAL(wax.wax_body, new_body, "Новое тело получает знание.")
	TEST_ASSERT(!wax.can_use(user) && wax.can_use(new_body), "Старое тело теряет права.")
	wax.combat_resource = 3
	wax.raise_shell(new_body)
	shell = new_body.has_status_effect(/datum/status_effect/heretic_wax/shell)
	qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spell/wax_shell))
	TEST_ASSERT(QDELETED(shell), "Удаление знания защиты гасит свечу.")
	TEST_ASSERT(!wax.raise_shell(new_body), "Удалённое знание не создаёт новую защиту.")
	wax.seal(victim)
	qdel(wax)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_wax/seal), "Удаление основы снимает оставшийся оттиск.")

/// Вознесение открывает пять конечных свечей и восстановление полного запаса.
/datum/unit_test/heretic_wax_ascension/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	TEST_ASSERT(!wax.procession(user, TRUE), "Незавершённый обряд не открывает бессмертную процессию.")
	final_knowledge.finished = TRUE
	heretic.ascended = TRUE
	final_knowledge.on_body_gain(user)
	TEST_ASSERT_EQUAL(wax.combat_resource_max, 8, "Вознесение расширяет вместимость.")
	wax.combat_resource = 2
	COOLDOWN_RESET(wax, wax_recovery)
	wax.on_life(user)
	TEST_ASSERT_EQUAL(wax.combat_resource, 3, "Вознесённый восстанавливает запас выше единицы.")
	TEST_ASSERT(wax.procession(user, TRUE), "Вознесённая процессия доступна.")
	var/datum/status_effect/heretic_wax/procession/procession = user.has_status_effect(/datum/status_effect/heretic_wax/procession)
	TEST_ASSERT_EQUAL(length(procession.candles), 4, "После первого импульса остаются четыре из пяти свечей.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 3, "Вознесённая способность не тратит воск.")
	final_knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(procession), "Утрата вознесения обрывает процессию.")
	TEST_ASSERT(!wax.ascension_active, "Флаг вознесения снимается.")

/// Боевые попадания возвращают воск с общей задержкой, не умножаясь на число целей.
/datum/unit_test/heretic_wax_combat_harvest/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_imprint)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.mind = allocate_mind()
	victim.mind.current = victim
	var/mob/living/second_victim = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	second_victim.mind = allocate_mind()
	second_victim.mind.current = second_victim
	user.setDir(EAST)
	TEST_ASSERT(wax.release(user), "Волна поражает обе цели.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 3, "Две цели возвращают только одну потраченную единицу.")
	wax.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT_EQUAL(wax.combat_resource, 3, "Клинок не обходит задержку волны.")
	COOLDOWN_RESET(wax, wax_harvest)
	wax.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT_EQUAL(wax.combat_resource, 4, "Клинок возвращает воск после задержки.")
	COOLDOWN_RESET(wax, wax_harvest)
	TEST_ASSERT(wax.imprint(user, second_victim), "Снятие оттиска поражает живую разумную цель.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 4, "Успешный оттиск возвращает свою стоимость.")
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(wax, wax_harvest) - 6 SECONDS) <= world.tick_lag, "Общая задержка составляет шесть секунд.")

/// Оттиск переносит конечный урон, соблюдает задержку клинка и исчезает после расходования.
/datum/unit_test/heretic_wax_effigy_damage_budget/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_imprint)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	var/obj/item/melee/sickly_blade/wax/blade = allocate(/obj/item/melee/sickly_blade/wax)
	user.put_in_hands(blade)
	TEST_ASSERT(wax.imprint(user, victim), "Оттиск работает без предварительной печати.")
	var/datum/status_effect/heretic_wax/effigy/effect = wax.active_effigy
	var/obj/structure/heretic_wax_effigy/effigy = effect.effigy
	TEST_ASSERT_EQUAL(effigy.icon, victim.icon, "Двойник копирует внешность цели.")
	TEST_ASSERT(effigy.name != victim.name && findtext(effigy.name, victim.name) && findtext(effigy.name, "wax effigy"), "Имя двойника выдаёт восковую копию и называет оригинал.")
	TEST_ASSERT(findtext(effigy.desc, "Восковая копия"), "Описание двойника говорит, что это копия.")
	var/list/resource = wax.get_combat_resource_data()
	TEST_ASSERT(findtext(resource["state"], victim.real_name), "Ресурсная подсказка называет цель оттиска.")
	TEST_ASSERT(findtext(jointext(effigy.examine(user), " "), "30 переносимого"), "Осмотр показывает первоначальный запас урона.")
	user.a_intent = INTENT_DISARM
	resource = wax.get_combat_resource_data()
	TEST_ASSERT_EQUAL(resource["name"], "Воск: выброс оболочки", "Режим разоружения явно предупреждает о расходе оболочки.")
	user.a_intent = INTENT_HARM
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_clinging), "Снятие оттиска сразу мешает отступлению.")
	victim.remove_status_effect(/datum/status_effect/heretic_wax/clinging)
	TEST_ASSERT(user.Adjacent(effigy) && !user.Adjacent(victim), "Двойник позволяет достать клинком удалённого врага.")
	blade.melee_attack_chain(user, effigy, null, NONE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 29) <= DAMAGE_PRECISION, "Первый удар клинком переносит пятнадцать ушибов.")
	TEST_ASSERT(findtext(jointext(effigy.examine(user), " "), "15 переносимого"), "Осмотр учитывает израсходованный ударом запас.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_clinging), "Удар через двойника снова замедляет оригинал.")
	user.FlushCurrentAction()
	blade.melee_attack_chain(user, effigy, null, NONE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 29) <= DAMAGE_PRECISION, "Повторный щелчок не обходит задержку атаки.")
	effigy.attackby(blade, user)
	TEST_ASSERT(abs(victim.getBruteLoss() - 44) <= DAMAGE_PRECISION, "Двойник переносит не больше тридцати ушибов за два удара.")
	TEST_ASSERT(QDELETED(effigy) && QDELETED(effect), "Исчерпание двойника разрывает связь.")
	TEST_ASSERT_NULL(wax.active_effigy, "Знание освобождает ссылку на израсходованный оттиск.")
	resource = wax.get_combat_resource_data()
	TEST_ASSERT(!findtext(resource["state"], "Двойник:"), "После разрушения подсказка не показывает старую цель.")

/// Разрушение двойника противником, преграда, антимагия и утрата знания разрывают связь.
/datum/unit_test/heretic_wax_effigy_counterplay/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTHEAST))
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_imprint)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/obj/item/melee/sickly_blade/wax/blade = allocate(/obj/item/melee/sickly_blade/wax)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	for(var/scenario in list("destroy", "wall", "magic", "nullrod", "knowledge"))
		var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
		wax.combat_resource = 3
		TEST_ASSERT(wax.imprint(user, victim), "Оттиск создан для [scenario].")
		var/datum/status_effect/heretic_wax/effigy/effect = wax.active_effigy
		var/obj/structure/heretic_wax_effigy/effigy = effect.effigy
		var/obj/blocker
		var/datum/component/anti_magic/protection
		if(scenario == "destroy")
			effigy.take_damage(100, BRUTE, MELEE)
		if(scenario == "wall")
			blocker = allocate(/obj, get_step(user, EAST))
			blocker.density = TRUE
			effigy.attackby(blade, user)
		if(scenario == "magic")
			protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 3)
			effigy.attackby(blade, user)
		if(scenario == "nullrod")
			effigy.attackby(rod, victim)
		if(scenario == "knowledge")
			qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spell/wax_imprint))
		TEST_ASSERT(QDELETED(effect) && QDELETED(effigy), "Контрмера [scenario] убирает оттиск и связь.")
		TEST_ASSERT(abs(victim.getBruteLoss() - 14) <= DAMAGE_PRECISION, "Контрмера не переносит урон разрушения на оригинал.")
		if(protection)
			TEST_ASSERT_EQUAL(protection.charges, 2, "Одна попытка через двойника тратит один заряд антимагии.")
		QDEL_NULL(blocker)
		qdel(victim)

/// Повторная оболочка за полную цену восстанавливает защиту, а переплавка при пустом запасе сохраняет предел лечения.
/datum/unit_test/heretic_wax_shell_recast_and_melt/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	heretic.gain_knowledge(/datum/eldritch_knowledge/wax_temper)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/attacker = allocate(/mob/living/carbon/human, get_step(user, EAST))
	attacker.mind = allocate_mind()
	attacker.mind.current = attacker
	var/obj/item/kitchen/knife/weapon = allocate(/obj/item/kitchen/knife)
	wax.raise_shell(user)
	var/datum/status_effect/heretic_wax/shell/old_shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	var/full_capacity = old_shell.capacity
	user.mob_run_block(weapon, 20, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, list())
	TEST_ASSERT_EQUAL(old_shell.capacity, full_capacity - 20, "Удар снимает часть защиты.")
	wax.combat_resource = 1
	TEST_ASSERT(!wax.raise_shell(user), "Без двух воска оболочку не обновить.")
	TEST_ASSERT_EQUAL(old_shell.capacity, full_capacity - 20, "Отклонённое обновление не чинит защиту.")
	wax.combat_resource = 3
	TEST_ASSERT(wax.raise_shell(user), "Повреждённую оболочку можно обновить повторным применением.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 1, "Обновление стоит столько же, сколько новая оболочка.")
	TEST_ASSERT(QDELETED(old_shell), "Обновление убирает прежнюю оболочку.")
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	TEST_ASSERT_EQUAL(shell.capacity, full_capacity, "Обновлённая оболочка снова принимает полный урон.")
	TEST_ASSERT_EQUAL(shell.absorbed_hostile, 0, "Замена не копирует раны старой оболочки.")
	wax.combat_resource = 3
	user.mob_run_block(weapon, 60, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, list())
	user.adjustBruteLoss(10)
	user.adjustFireLoss(30)
	wax.combat_resource = 0
	var/obj/item/heretic_path_relic/wax/relic = allocate(/obj/item/heretic_path_relic/wax)
	relic.creator = WEAKREF(user.mind)
	relic.knowledge_ref = WEAKREF(heretic.get_knowledge(/datum/eldritch_knowledge/spell/wax_shell))
	user.put_in_hands(relic)
	TEST_ASSERT(relic.melt(user), "Пустой запас не запрещает переплавить уже принятые раны.")
	TEST_ASSERT(abs(user.getBruteLoss() + user.getFireLoss() - 15) <= DAMAGE_PRECISION, "Общее лечение двух типов ран ограничено двадцатью пятью.")
	TEST_ASSERT(QDELETED(shell), "Переплавка расходует оболочку вместе с запасом принятых ран.")

/// Дистанция, контейнер, смерть и смена тела удаляют внешний оттиск вместе с двойником.
/datum/unit_test/heretic_wax_effigy_lifecycle/Run()
	for(var/scenario in list("range", "container", "death", "transfer", "role"))
		var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, SOUTHWEST))
		heretic.selected_path = PATH_WAX
		var/mob/living/user = heretic.owner.current
		heretic.apply_innate_effects(user)
		heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
		heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_imprint)
		var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
		var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
		TEST_ASSERT(wax.imprint(user, victim), "Оттиск создан для проверки [scenario].")
		var/datum/status_effect/heretic_wax/effigy/effect = wax.active_effigy
		var/obj/structure/heretic_wax_effigy/effigy = effect.effigy
		if(scenario == "range")
			victim.forceMove(get_step(run_loc_floor_top_right, NORTHEAST))
			TEST_ASSERT(isfloorturf(get_turf(victim)), "Дальняя цель остаётся на открытом полу.")
			TEST_ASSERT(get_dist(user, victim) > 5, "Цель вышла за пределы связи.")
			effect.tick()
		if(scenario == "container")
			var/obj/item/storage/box/container = allocate(/obj/item/storage/box, get_turf(victim))
			victim.forceMove(container)
			effect.tick()
		if(scenario == "death")
			user.stat = DEAD
			wax.on_death(user)
		if(scenario == "transfer")
			var/mob/living/new_body = allocate(/mob/living/carbon/human, get_step(user, NORTH))
			heretic.owner.transfer_to(new_body)
		if(scenario == "role")
			qdel(heretic)
		TEST_ASSERT(QDELETED(effect) && QDELETED(effigy), "Сценарий [scenario] удаляет обе стороны связи.")
		TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_wax/effigy), "У цели не остаётся предупреждения.")
		qdel(victim)
		qdel(heretic)

/datum/unit_test/proc/allocate_wax_phylactery(turf/location)
	if(!(locate(/datum/heretic_test_station_level) in allocated))
		allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic(location)
	heretic.selected_path = PATH_WAX
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.apply_innate_effects(user)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	final_knowledge.finished = TRUE
	heretic.ascended = TRUE
	final_knowledge.on_body_gain(user)
	return heretic

/// Резервация тестов лежит в /area/space, а свеча держит жизнь только внутри станции.
/area/unit_test_wax_room
	name = "Wax Phylactery Test Room"
	requires_power = FALSE

/area/unit_test_wax_outdoors
	name = "Wax Phylactery Test Outdoors"
	requires_power = FALSE
	outdoors = TRUE

/datum/unit_test/proc/cast_wax_anchor(datum/eldritch_knowledge/base_wax/wax, mob/living/user, turf/destination, indoor = TRUE)
	var/obj/item/paper/paper = allocate(/obj/item/paper, get_turf(user))
	wax.combat_resource = wax.combat_resource_max
	if(!wax.on_mansus_grasp(paper, user, TRUE))
		return null
	var/obj/item/candle/candle = wax.anchor_candles[length(wax.anchor_candles)]
	allocated += candle
	if(indoor)
		wax_test_area(destination)
	candle.forceMove(destination)
	return candle

/datum/unit_test/proc/wax_test_area(turf/spot, area_type = /area/unit_test_wax_room)
	heretic_test_area(spot, area_type)

/datum/unit_test/proc/await_wax_phylactery(datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge)
	for(var/attempt in 1 to 50)
		if(!final_knowledge.phylactery_timer)
			return
		sleep(world.tick_lag)

/// Смерть вознёсшегося Воска переносит его к ближайшей своей свече с половиной здоровья, свеча сгорает, повтор ждёт перезарядки.
/datum/unit_test/heretic_wax_phylactery_death/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/turf/start = get_turf(user)
	var/turf/near_spot = locate(start.x + 2, start.y + 1, start.z)
	var/turf/far_spot = locate(start.x + 4, start.y + 4, start.z)
	var/obj/item/candle/far_candle = cast_wax_anchor(wax, user, far_spot)
	var/obj/item/candle/near_candle = cast_wax_anchor(wax, user, near_spot)
	TEST_ASSERT(near_candle && far_candle, "Хватка отливает свечи-якоря.")
	var/obj/structure/chair/chair = allocate(/obj/structure/chair, start)
	chair.buckle_mob(user, force = TRUE)
	TEST_ASSERT_EQUAL(user.buckled, chair, "Еретик пристёгнут к стулу.")
	user.adjustBruteLoss(300, FALSE)
	user.death()
	TEST_ASSERT(final_knowledge.phylactery_timer, "Смерть при целой свече запускает возвращение.")
	await_wax_phylactery(final_knowledge)
	TEST_ASSERT_EQUAL(user.stat, CONSCIOUS, "Еретик поднимается в сознании.")
	TEST_ASSERT_EQUAL(get_turf(user), near_spot, "Еретик поднимается у ближайшей свечи.")
	TEST_ASSERT(QDELETED(near_candle), "Свеча сгорает при возвращении.")
	TEST_ASSERT(!QDELETED(far_candle), "Дальняя свеча остаётся.")
	TEST_ASSERT(!user.buckled, "Возвращение отстёгивает от стула.")
	var/obj/effect/temp_visual/heretic_wax_doll/doll = locate() in start
	TEST_ASSERT_NOTNULL(doll, "На месте падения остаётся восковая кукла.")
	TEST_ASSERT(findtext(jointext(doll.examine(user), " "), get_area_name(near_spot)), "Осмотр куклы называет сектор, где поднялся еретик.")
	TEST_ASSERT(!COOLDOWN_FINISHED(final_knowledge, phylactery_cooldown), "Возвращение уходит на перезарядку.")
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_ascended), "После возвращения база вознесения снова действует.")
	TEST_ASSERT(wax.ascension_active, "После возвращения сила Воска снова действует.")
	TEST_ASSERT_EQUAL(user.maxHealth, HERETIC_ASCENDED_MAX_HEALTH, "Предел здоровья вознесения восстановлен.")
	TEST_ASSERT(abs(user.health - user.maxHealth * HERETIC_WAX_PHYLACTERY_HEALTH) <= 1, "Еретик поднимается с половиной здоровья: [user.health].")
	TEST_ASSERT_EQUAL(user.getOxyLoss() + user.getToxLoss(), 0, "Удушье и токсины не переносятся.")
	user.adjustBruteLoss(300, FALSE)
	user.death()
	TEST_ASSERT_NULL(final_knowledge.phylactery_timer, "Перезарядка не даёт вернуться второй раз.")
	TEST_ASSERT_EQUAL(user.stat, DEAD, "Во время перезарядки смерть окончательна.")
	TEST_ASSERT(!QDELETED(far_candle), "Неудачная попытка не тратит свечу.")

/// Хардкрит тоже возвращает к свече, снимает оглушение, захват и выносливость, но наручники остаются.
/datum/unit_test/heretic_wax_phylactery_hardcrit/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/turf/start = get_turf(user)
	var/turf/anchor_spot = locate(start.x + 3, start.y + 3, start.z)
	var/obj/item/candle/candle = cast_wax_anchor(wax, user, anchor_spot)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(user, EAST))
	crew.start_pulling(user)
	TEST_ASSERT_EQUAL(user.pulledby, crew, "Экипаж держит еретика.")
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	user.Paralyze(10 SECONDS)
	for(var/attempt in 1 to 40)
		if(user.stat != CONSCIOUS)
			break
		user.adjustBruteLoss(10)
	TEST_ASSERT_EQUAL(user.stat, UNCONSCIOUS, "Еретик падает в хардкрит, а не умирает.")
	TEST_ASSERT(final_knowledge.phylactery_timer, "Хардкрит запускает возвращение.")
	await_wax_phylactery(final_knowledge)
	TEST_ASSERT_EQUAL(user.stat, CONSCIOUS, "Еретик приходит в сознание у свечи.")
	TEST_ASSERT_EQUAL(get_turf(user), anchor_spot, "Хардкрит переносит к свече.")
	TEST_ASSERT(QDELETED(candle), "Свеча сгорает.")
	TEST_ASSERT(abs(user.health - user.maxHealth * HERETIC_WAX_PHYLACTERY_HEALTH) <= 1, "Здоровье восстановлено до половины: [user.health].")
	TEST_ASSERT(!user.IsParalyzed() && user.getStaminaLoss() == 0, "Оглушение и усталость сняты.")
	TEST_ASSERT(!user.pulledby && !crew.pulling, "Захват экипажа обрывается.")
	TEST_ASSERT_NOTNULL(user.handcuffed, "Наручники остаются.")
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_ascended), "База вознесения на месте.")

/// Без свечи на том же уровне, после разрыва тела, без мозга или сердца возвращения нет, свеча и перезарядка не тратятся.
/datum/unit_test/heretic_wax_phylactery_rejections/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	user.death()
	TEST_ASSERT_NULL(final_knowledge.phylactery_timer, "Без свечей смерть окончательна.")
	await_wax_phylactery(final_knowledge)
	TEST_ASSERT_EQUAL(user.stat, DEAD, "Без свечей еретик остаётся мёртвым.")

	heretic = allocate_wax_phylactery()
	user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/turf/start = get_turf(user)
	var/turf/elsewhere
	for(var/attempt in 1 to 10)
		var/turf/candidate = get_safe_random_station_turf()
		if(candidate && candidate.z != start.z && wax.anchor_spot_valid(candidate))
			elsewhere = candidate
			break
	TEST_ASSERT_NOTNULL(elsewhere, "На станции нашлось свободное место для свечи.")
	var/obj/item/candle/distant_candle = cast_wax_anchor(wax, user, elsewhere, indoor = FALSE)
	TEST_ASSERT_EQUAL(wax.count_anchors(elsewhere), 1, "На своём уровне эта свеча держала бы жизнь.")
	user.death()
	TEST_ASSERT_NULL(final_knowledge.phylactery_timer, "Свеча на другом уровне не держит жизнь.")
	TEST_ASSERT_EQUAL(user.stat, DEAD, "Еретик остаётся мёртвым.")
	TEST_ASSERT(!QDELETED(distant_candle), "Свеча на другом уровне не тратится.")

	heretic = allocate_wax_phylactery()
	user = heretic.owner.current
	wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/obj/item/candle/candle = cast_wax_anchor(wax, user, locate(start.x + 3, start.y, start.z))
	user.gib()
	TEST_ASSERT_NULL(final_knowledge.phylactery_timer, "Разорванное тело не возвращается.")
	await_wax_phylactery(final_knowledge)
	TEST_ASSERT(!QDELETED(candle), "Свеча не тратится на разорванное тело.")
	TEST_ASSERT(COOLDOWN_FINISHED(final_knowledge, phylactery_cooldown), "Перезарядка не начинается.")
	qdel(heretic.owner.current)

	heretic = allocate_wax_phylactery()
	user = heretic.owner.current
	wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/obj/item/candle/spared = cast_wax_anchor(wax, user, locate(start.x + 3, start.y + 1, start.z))
	var/obj/item/organ/brain/brain = user.getorganslot(ORGAN_SLOT_BRAIN)
	brain.Remove()
	allocated += brain
	if(user.stat != DEAD)
		user.death()
	await_wax_phylactery(final_knowledge)
	TEST_ASSERT_EQUAL(user.stat, DEAD, "Тело без мозга не поднимается.")
	TEST_ASSERT(!QDELETED(spared), "Свеча не тратится на тело без мозга.")
	TEST_ASSERT(COOLDOWN_FINISHED(final_knowledge, phylactery_cooldown), "Неудача без мозга не запускает перезарядку.")

	heretic = allocate_wax_phylactery()
	user = heretic.owner.current
	wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/obj/item/candle/unused = cast_wax_anchor(wax, user, locate(start.x + 3, start.y + 2, start.z))
	var/obj/item/organ/heart/heart = user.getorganslot(ORGAN_SLOT_HEART)
	heart.Remove()
	allocated += heart
	if(user.stat != DEAD)
		user.death()
	TEST_ASSERT(final_knowledge.phylactery_timer, "Свеча на месте, возвращение запрошено.")
	await_wax_phylactery(final_knowledge)
	TEST_ASSERT_EQUAL(user.stat, DEAD, "Тело без сердца не поднимается.")
	TEST_ASSERT(!QDELETED(unused), "Свеча не тратится на тело без сердца.")
	TEST_ASSERT(COOLDOWN_FINISHED(final_knowledge, phylactery_cooldown), "Неудача без сердца не запускает перезарядку.")
	TEST_ASSERT_EQUAL(get_turf(user), start, "Тело без сердца остаётся на месте.")

/// Якорями служат три последние свечи на полу; экипаж видит это при осмотре и разбивает их ударом или жезлом.
/datum/unit_test/heretic_wax_phylactery_anchors/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/turf/start = get_turf(user)
	var/obj/item/candle/oldest = cast_wax_anchor(wax, user, locate(start.x + 1, start.y + 3, start.z))
	var/obj/item/candle/second = cast_wax_anchor(wax, user, locate(start.x + 2, start.y + 2, start.z))
	var/obj/item/candle/third = cast_wax_anchor(wax, user, locate(start.x + 3, start.y + 3, start.z))
	var/obj/item/candle/newest = cast_wax_anchor(wax, user, locate(start.x + 4, start.y + 3, start.z))
	TEST_ASSERT_EQUAL(length(wax.anchor_candles), HERETIC_WAX_PHYLACTERY_ANCHORS, "В счёт идут только три свечи.")
	TEST_ASSERT(!(oldest in wax.anchor_candles) && (newest in wax.anchor_candles), "Новая свеча вытесняет самую старую.")
	TEST_ASSERT_NOTNULL(newest.get_filter("heretic_wax_anchor"), "Свеча-якорь обведена восковым контуром.")
	TEST_ASSERT_NULL(oldest.get_filter("heretic_wax_anchor"), "Вытесненная свеча теряет контур.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/list/lines = list()
	SEND_SIGNAL(newest, COMSIG_PARENT_EXAMINE, crew, lines)
	TEST_ASSERT(findtext(jointext(lines, " "), "держит жизнь"), "Осмотр свечи-якоря говорит, что она держит жизнь еретика.")
	lines = list()
	SEND_SIGNAL(oldest, COMSIG_PARENT_EXAMINE, crew, lines)
	TEST_ASSERT(!findtext(jointext(lines, " "), "держит жизнь"), "Вытесненная свеча больше не якорь.")
	lines = list()
	SEND_SIGNAL(user, COMSIG_PARENT_EXAMINE, crew, lines)
	TEST_ASSERT(findtext(jointext(lines, " "), "свечей на этом уровне: 3"), "Осмотр еретика называет число свечей.")
	TEST_ASSERT_EQUAL(wax.nearest_anchor(user), second, "Ближайшая свеча выбирается по расстоянию.")
	crew.put_in_hands(second)
	TEST_ASSERT_EQUAL(wax.nearest_anchor(user), third, "Свеча в руках не держит жизнь.")
	crew.dropItemToGround(second)
	var/obj/item/wrench/wrench = allocate(/obj/item/wrench)
	third.attackby(wrench, user)
	TEST_ASSERT(!QDELETED(third), "Сам еретик не разбивает свою свечу случайным ударом.")
	third.attackby(wrench, crew)
	TEST_ASSERT(QDELETED(third), "Любой удар экипажа разбивает свечу-якорь.")
	var/obj/item/match/match = allocate(/obj/item/match)
	match.matchignite()
	match.force = 0
	TEST_ASSERT(match.get_temperature() > 0, "Спичка горит, но не бьёт.")
	newest.attackby(match, crew)
	TEST_ASSERT(QDELETED(newest), "Огонь разбивает свечу-якорь, а не зажигает её.")
	var/obj/item/candle/extra = cast_wax_anchor(wax, user, locate(start.x + 4, start.y + 4, start.z))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	extra.attackby(rod, crew)
	TEST_ASSERT(QDELETED(extra), "Нулевой жезл гасит свечу-якорь.")
	TEST_ASSERT(length(wax.anchor_candles) == 1 && wax.anchor_candles[1] == second, "Разбитые свечи выбывают из счёта.")
	final_knowledge.on_body_lose(user)
	lines = list()
	SEND_SIGNAL(second, COMSIG_PARENT_EXAMINE, crew, lines)
	TEST_ASSERT(!findtext(jointext(lines, " "), "держит жизнь"), "Без вознесения свеча ничего не держит.")
	TEST_ASSERT_NULL(second.get_filter("heretic_wax_anchor"), "Без вознесения контур снимается.")
	second.attackby(wrench, crew)
	TEST_ASSERT(!QDELETED(second), "Без вознесения удар не разбивает обычную свечу.")
	final_knowledge.on_body_gain(user)
	TEST_ASSERT_NOTNULL(second.get_filter("heretic_wax_anchor"), "Новое вознесение возвращает контур.")

/// Свеча держит жизнь только на свободном полу внутри станции: космос с решёткой, шкаф над свечой и внешняя зона не годятся.
/datum/unit_test/heretic_wax_phylactery_anchor_spots/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/turf/start = get_turf(user)
	var/turf/void = locate(start.x + 1, start.y + 2, start.z)
	var/obj/item/candle/drifting = cast_wax_anchor(wax, user, void)
	void = void.ChangeTurf(/turf/open/space)
	allocate(/obj/structure/lattice, void)
	var/turf/closet_spot = locate(start.x + 2, start.y + 2, start.z)
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, closet_spot)
	var/obj/item/candle/buried = cast_wax_anchor(wax, user, closet_spot)
	var/obj/item/candle/exposed = cast_wax_anchor(wax, user, locate(start.x + 3, start.y + 2, start.z), indoor = FALSE)
	TEST_ASSERT(drifting.loc == void && buried.loc == closet_spot && closet.density, "Свечи лежат на своих местах, шкаф закрыт.")
	TEST_ASSERT_EQUAL(length(wax.anchor_candles), 3, "Все три свечи в счёте.")
	TEST_ASSERT_EQUAL(wax.count_anchors(user), 0, "Космос с решёткой, шкаф и внешняя зона не держат жизнь.")
	user.death()
	TEST_ASSERT_NULL(final_knowledge.phylactery_timer, "Без годной свечи смерть окончательна.")
	TEST_ASSERT(!QDELETED(drifting) && !QDELETED(buried) && !QDELETED(exposed), "Негодные свечи не тратятся.")
	qdel(closet)
	TEST_ASSERT_EQUAL(wax.nearest_anchor(closet_spot), buried, "Без шкафа та же свеча снова годится.")
	void.ChangeTurf(/turf/open/floor/plasteel)

/// Свеча вне уровня станции не держит жизнь и не тратится.
/datum/unit_test/heretic_wax_phylactery_station_level/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/turf/start = get_turf(user)
	var/obj/item/candle/candle = cast_wax_anchor(wax, user, locate(start.x + 2, start.y + 2, start.z))
	TEST_ASSERT_EQUAL(wax.count_anchors(user), 1, "На уровне станции свеча держит жизнь.")
	var/datum/heretic_test_station_level/lease = locate() in allocated
	allocated -= lease
	qdel(lease)
	TEST_ASSERT(!is_station_level(start.z), "Уровень резервации снова не станция.")
	TEST_ASSERT(!wax.anchor_spot_valid(get_turf(candle)), "Вне уровня станции место не годится для свечи.")
	TEST_ASSERT_EQUAL(wax.count_anchors(user), 0, "Свеча вне станции не в счёте.")
	user.death()
	TEST_ASSERT_NULL(final_knowledge.phylactery_timer, "Свеча вне станции не возвращает еретика.")
	TEST_ASSERT(!QDELETED(candle), "Свеча вне станции не тратится.")

/// Свеча на столе держит жизнь, а под закрытым ящиком нет.
/datum/unit_test/heretic_wax_phylactery_table_anchor/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/start = get_turf(user)
	var/turf/table_spot = locate(start.x + 3, start.y + 3, start.z)
	var/obj/structure/table/table = allocate(/obj/structure/table, table_spot)
	var/obj/item/candle/on_table = cast_wax_anchor(wax, user, table_spot)
	TEST_ASSERT(table.density && on_table.loc == table_spot, "Свеча стоит на плотном столе.")
	TEST_ASSERT(wax.anchor_spot_valid(table_spot), "Стол годится для свечи-якоря.")
	TEST_ASSERT_EQUAL(wax.nearest_anchor(user), on_table, "Свеча на столе держит жизнь.")
	var/turf/crate_spot = locate(start.x + 1, start.y + 3, start.z)
	var/obj/structure/closet/crate/crate = allocate(/obj/structure/closet/crate, crate_spot)
	var/obj/item/candle/under_crate = cast_wax_anchor(wax, user, crate_spot)
	TEST_ASSERT(crate.density && under_crate.loc == crate_spot, "Свеча лежит под закрытым ящиком.")
	TEST_ASSERT(!wax.anchor_spot_valid(crate_spot), "Закрытый ящик прячет свечу.")
	var/turf/tank_spot = locate(start.x + 2, start.y + 1, start.z)
	allocate(/obj/structure/reagent_dispensers/watertank, tank_spot)
	cast_wax_anchor(wax, user, tank_spot)
	TEST_ASSERT(!wax.anchor_spot_valid(tank_spot), "Бак с водой прячет свечу, хоть на него и можно залезть.")
	TEST_ASSERT_EQUAL(wax.count_anchors(user), 1, "В счёте только свеча на столе.")

/// Открытое небо планетарной станции не держит жизнь, хотя там нет космоса.
/datum/unit_test/heretic_wax_phylactery_outdoor_anchor/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/turf/start = get_turf(user)
	var/turf/outside = locate(start.x + 3, start.y + 3, start.z)
	wax_test_area(outside, /area/unit_test_wax_outdoors)
	var/obj/item/candle/snowed = cast_wax_anchor(wax, user, outside, indoor = FALSE)
	var/area/outside_area = get_area(outside)
	TEST_ASSERT(outside_area.outdoors && !outside_area.considered_hull_exterior && isfloorturf(outside), "Свеча на полу под открытым небом, не в космосе.")
	TEST_ASSERT(!wax.anchor_spot_valid(outside), "Зона под открытым небом не годится для свечи.")
	TEST_ASSERT_EQUAL(wax.count_anchors(user), 0, "Свеча снаружи не в счёте.")
	user.death()
	TEST_ASSERT_NULL(final_knowledge.phylactery_timer, "Свеча снаружи не возвращает еретика.")
	TEST_ASSERT(!QDELETED(snowed), "Свеча снаружи не тратится.")

/// Сгоревший до хаска еретик поднимается у свечи уже без хаска.
/datum/unit_test/heretic_wax_phylactery_husk/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/turf/start = get_turf(user)
	var/turf/anchor_spot = locate(start.x + 2, start.y + 2, start.z)
	cast_wax_anchor(wax, user, anchor_spot)
	for(var/obj/item/bodypart/part as anything in user.bodyparts)
		part.burn_dam = part.max_damage
	user.death()
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_HUSK), "Тяжёлые ожоги делают труп хаском.")
	TEST_ASSERT(final_knowledge.phylactery_timer, "Хаск со свечой запрашивает возвращение.")
	await_wax_phylactery(final_knowledge)
	TEST_ASSERT_EQUAL(user.stat, CONSCIOUS, "Сгоревший еретик поднимается.")
	TEST_ASSERT_EQUAL(get_turf(user), anchor_spot, "Сгоревший еретик поднимается у свечи.")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_HUSK), "Вернувшийся еретик больше не хаск.")
	TEST_ASSERT(abs(user.health - user.maxHealth * HERETIC_WAX_PHYLACTERY_HEALTH) <= 1, "Ожоги снижены до половины здоровья: [user.health].")

/// Контур якоря дышит, над фитилём висит светящийся огонёк; без вознесения он гаснет, разбитая свеча уносит его с собой.
/datum/unit_test/heretic_wax_anchor_visuals/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/turf/start = get_turf(user)
	var/obj/item/candle/candle = cast_wax_anchor(wax, user, locate(start.x + 2, start.y + 1, start.z))
	TEST_ASSERT_NOTNULL(candle, "Хватка отливает свечу-якорь.")
	TEST_ASSERT_NOTNULL(candle.get_filter("heretic_wax_anchor"), "Якорь обведён контуром, как раньше.")
	var/obj/effect/abstract/heretic_vfx_attached/flame = wax.anchor_flames[candle]
	TEST_ASSERT_NOTNULL(flame, "Над фитилём якоря загорается холодный огонёк.")
	TEST_ASSERT(flame in candle.vis_contents, "Огонёк висит на самой свече.")
	TEST_ASSERT_EQUAL(flame.icon_state, "wax_anchor_flame", "Огонёк рисуется своим стейтом.")
	TEST_ASSERT(flame.glow in flame.vis_contents, "Огонёк виден в темноте.")
	TEST_ASSERT(flame.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Огонёк не мешает кликать по свече.")
	var/flame_alpha = flame.alpha
	var/full_height = flame.pixel_y
	candle.wax = 500
	candle.update_icon()
	TEST_ASSERT(flame.pixel_y < full_height, "Огонёк опускается вместе с фитилём оплывшей свечи.")
	candle.light()
	TEST_ASSERT_EQUAL(flame.alpha, 0, "Пока свеча горит своим пламенем, холодный огонёк не двоится с ним.")
	candle.put_out_candle()
	TEST_ASSERT_EQUAL(flame.alpha, flame_alpha, "Погашенная свеча снова несёт холодный огонёк.")
	final_knowledge.on_body_lose(user)
	TEST_ASSERT_NULL(candle.get_filter("heretic_wax_anchor"), "Без вознесения контур снимается, как раньше.")
	TEST_ASSERT(flame.fading, "Без вознесения огонёк гаснет плавно.")
	TEST_ASSERT_NULL(wax.anchor_flames[candle], "Погасший огонёк больше не числится за свечой.")
	TEST_ASSERT(wait_for_qdeleted(flame), "Погасший огонёк удаляется.")
	final_knowledge.on_body_gain(user)
	var/obj/effect/abstract/heretic_vfx_attached/relit = wax.anchor_flames[candle]
	TEST_ASSERT_NOTNULL(relit, "Новое вознесение снова зажигает огонёк.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/item/wrench/wrench = allocate(/obj/item/wrench)
	candle.attackby(wrench, crew)
	TEST_ASSERT(QDELETED(candle), "Удар экипажа разбивает якорь, как раньше.")
	TEST_ASSERT(QDELETED(relit), "Разбитая свеча уносит огонёк.")
	TEST_ASSERT_EQUAL(length(wax.anchor_flames), 0, "За разбитой свечой не остаётся огонька.")

/// Возвращение к свече: у куклы капает воск, свеча вспыхивает и оплывает, поднимается столб воска, тело проступает из восковой прозрачности.
/datum/unit_test/heretic_wax_phylactery_visuals/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_phylactery()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/turf/start = get_turf(user)
	var/turf/spot = locate(start.x + 3, start.y + 1, start.z)
	TEST_ASSERT_NOTNULL(cast_wax_anchor(wax, user, spot), "Хватка отливает свечу-якорь.")
	user.adjustBruteLoss(300, FALSE)
	user.death()
	await_wax_phylactery(final_knowledge)
	TEST_ASSERT_EQUAL(get_turf(user), spot, "Еретик поднимается у свечи, как раньше.")
	TEST_ASSERT(abs(user.health - user.maxHealth * HERETIC_WAX_PHYLACTERY_HEALTH) <= 1, "Половина здоровья, как раньше: [user.health].")
	var/obj/effect/temp_visual/heretic_wax_column/column = locate() in spot
	TEST_ASSERT_NOTNULL(column, "У свечи поднимается столб воска.")
	TEST_ASSERT(length(column.overlays), "Столб виден в темноте.")
	for(var/mutable_appearance/overlay as anything in column.overlays)
		TEST_ASSERT_EQUAL(overlay.icon_state, "wax_column_glow", "В темноте светятся только трещины и огонёк столба, а не весь воск.")
	TEST_ASSERT(column.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Столб не мешает кликам.")
	var/obj/effect/temp_visual/heretic_wax_melt/flare/flare = locate() in spot
	TEST_ASSERT_NOTNULL(flare, "Сгоревшая свеча вспыхивает и оплывает.")
	TEST_ASSERT(flare.glow in flare.vis_contents, "Вспышка свечи видна в темноте.")
	TEST_ASSERT(!length(flare.filters), "Вспышка не повторяет золотой контур якоря.")
	TEST_ASSERT_NOTNULL(find_vfx_burst(spot, /particles/heretic_ascension/wax, list()), "У свечи брызжет воск.")
	TEST_ASSERT_NOTNULL(user.get_filter("heretic_wax_rise"), "Тело проступает из воска.")
	var/obj/effect/temp_visual/heretic_wax_doll/doll = locate() in start
	TEST_ASSERT_NOTNULL(doll, "На месте падения остаётся кукла, как раньше.")
	TEST_ASSERT_NOTNULL(find_vfx_burst(start, /particles/heretic_ascension/wax/drip, list()), "С тающей куклы капает воск.")
	var/list/budget = new_wait_budget(2 SECONDS, "тело должно проступить из воска")
	while(user.get_filter("heretic_wax_rise"))
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT_NULL(user.get_filter("heretic_wax_rise"), "Восковой оттенок сходит с тела и снимается.")
	TEST_ASSERT(wait_for_qdeleted(column), "Столб стекает и исчезает.")
	TEST_ASSERT(wait_for_qdeleted(flare), "Оплывшая свеча исчезает.")

/// Бессмертная процессия бьёт мягкой волной и брызгами воска на каждом импульсе, первый трясёт землю; свечи тают, а не пропадают, обычная процессия без волны.
/datum/unit_test/heretic_wax_crown_visuals/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_procession)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	final_knowledge.finished = TRUE
	heretic.ascended = TRUE
	final_knowledge.on_body_gain(user)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/turf/place = get_turf(user)
	var/list/before = list_vfx_bursts(place)
	TEST_ASSERT(wax.procession(user, TRUE), "Бессмертная процессия зажигается.")
	var/datum/status_effect/heretic_wax/procession/procession = user.has_status_effect(/datum/status_effect/heretic_wax/procession)
	TEST_ASSERT(abs(victim.getBruteLoss() - 18) <= DAMAGE_PRECISION, "Первый импульс наносит 18 ушибов, как раньше.")
	TEST_ASSERT_EQUAL(length(procession.candles), 4, "Первый импульс расходует одну свечу из пяти, как раньше.")
	var/list/waves = list()
	for(var/obj/effect/temp_visual/heretic_vfx/shockwave/wave in place)
		waves += wave
	TEST_ASSERT_EQUAL(length(waves), 1, "Импульс расходится мягкой волной.")
	TEST_ASSERT_NOTNULL(find_vfx_burst(place, /particles/heretic_ascension/wax/pulse, before), "Импульс бросает капли воска.")
	TEST_ASSERT_NOTNULL(user.get_filter(HERETIC_VFX_PULSE_FILTER), "Первый импульс вспыхивает на еретике.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_wax_melt) in place, "Погасшая свеча оплывает на полу.")
	for(var/obj/structure/heretic_wax_candle/candle as anything in procession.candles)
		TEST_ASSERT_EQUAL(candle.loc, place, "Свечи идут за хозяином, как раньше.")
	procession.tick()
	TEST_ASSERT(abs(victim.getBruteLoss() - 36) <= DAMAGE_PRECISION, "Второй импульс снова наносит 18 ушибов.")
	var/wave_count = 0
	for(var/obj/effect/temp_visual/heretic_vfx/shockwave/wave in place)
		wave_count++
	TEST_ASSERT_EQUAL(wave_count, 2, "Каждый импульс расходится своей волной.")
	final_knowledge.on_body_lose(user)
	TEST_ASSERT(QDELETED(procession), "Утрата вознесения обрывает процессию, как раньше.")
	user.forceMove(locate(place.x, place.y + 3, place.z))
	var/turf/plain_place = get_turf(user)
	wax.combat_resource = 3
	TEST_ASSERT(wax.procession(user), "Обычная процессия зажигается.")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/heretic_vfx/shockwave) in plain_place, "Обычная процессия без волны вознесения.")
	for(var/obj/effect/temp_visual/heretic_vfx/shockwave/wave in place)
		TEST_ASSERT(wait_for_qdeleted(wave), "Волна гаснет сама.")

/// Новые восковые эффекты создаются без аргументов и удаляются без ошибок; снятая раньше срока вспышка не оставляет свечения.
/datum/unit_test/heretic_wax_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_wax_column, /obj/effect/temp_visual/heretic_wax_melt, /obj/effect/temp_visual/heretic_wax_melt/flare))
		qdel(new thing_type(run_loc_floor_bottom_left))
	var/obj/item/candle/model = allocate(/obj/item/candle, run_loc_floor_bottom_left)
	var/obj/effect/temp_visual/heretic_wax_melt/flare/flare = new(run_loc_floor_bottom_left, model.appearance)
	var/obj/effect/abstract/heretic_vfx_glow/glow = flare.glow
	TEST_ASSERT_NOTNULL(glow, "Вспышка свечи светится.")
	qdel(flare)
	TEST_ASSERT(QDELETED(glow), "Снятая вспышка уносит своё свечение.")
	TEST_ASSERT(!length(flare.vis_contents), "У снятой вспышки не остаётся вложенных эффектов.")

/// Погребальная свеча разгорается вместе с подъёмом из пола, а не вспыхивает сразу в полную силу.
/datum/unit_test/heretic_wax_funeral_candle_light/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	wax.combat_resource = 2
	TEST_ASSERT(wax.raise_shell(user), "Оболочка поднимается, как раньше.")
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	var/obj/structure/heretic_wax_candle/candle = shell.candles[1]
	var/rising_power = candle.light_power
	TEST_ASSERT(rising_power > 0, "Свеча светит с первого мгновения.")
	var/list/budget = new_wait_budget(1 SECONDS, "разгорание свечи")
	while(candle.light_power <= rising_power)
		if(!wait_budget_tick(budget))
			break
	TEST_ASSERT(candle.light_power > rising_power, "Свет свечи набирает силу вместе с подъёмом.")

/datum/unit_test/proc/allocate_wax_crew(turf/location)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, location)
	crew.mind = allocate_mind()
	crew.mind.current = crew
	crew.dna.uni_identity = "wax_test_[REF(crew)]"
	return crew

/datum/unit_test/proc/wax_touched_item(mob/living/carbon/human/toucher, turf/location, item_type = /obj/item/pen)
	var/obj/item/thing = allocate(item_type, location)
	thing.add_fingerprint(toucher)
	return thing

/datum/unit_test/proc/make_wax_puppet(datum/eldritch_knowledge/base_wax/wax, mob/living/carbon/human/user, mob/living/carbon/human/model)
	var/obj/item/pen/pen = wax_touched_item(model, get_turf(user))
	user.a_intent = INTENT_HELP
	if(!wax.on_mansus_grasp(pen, user, TRUE))
		return null
	var/obj/item/heretic_wax_puppet/puppet = wax.puppets[length(wax.puppets)]
	allocated += puppet
	if(!user.is_holding(puppet))
		user.put_in_hands(puppet)
	return puppet

/// Воск: десять ступеней, Сон по кукле на четвёртой, Метка Воска на шестой, цены при знаниях, канделябр в Погребальной оболочке.
/datum/unit_test/heretic_wax_layout/Run()
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_WAX]
	var/list/order = list(
		/datum/eldritch_knowledge/base_wax,
		/datum/eldritch_knowledge/wax_grasp,
		/datum/eldritch_knowledge/spell/wax_imprint,
		/datum/eldritch_knowledge/spell/wax_puppet_sleep,
		/datum/eldritch_knowledge/spell/wax_shell,
		/datum/eldritch_knowledge/wax_mark,
		/datum/eldritch_knowledge/spell/wax_leak,
		/datum/eldritch_knowledge/wax_temper,
		/datum/eldritch_knowledge/spell/wax_procession,
		/datum/eldritch_knowledge/final_eldritch/wax_final,
	)
	var/list/costs = list(0, 1, 1, 2, 1, 2, 1, 2, 2)
	TEST_ASSERT_EQUAL(length(path.knowledge), length(order), "У Воска десять ступеней.")
	for(var/index in 1 to length(order))
		TEST_ASSERT_EQUAL(path.knowledge[index], order[index], "Ступень [index] Воска на своём месте.")
	for(var/index in 2 to length(costs))
		var/datum/eldritch_knowledge/knowledge_type = order[index]
		TEST_ASSERT_EQUAL(initial(knowledge_type.cost), costs[index], "Цена ступени [index] при своём знании.")
	TEST_ASSERT_NULL(text2path("/datum/eldritch_knowledge/wax_upgrade"), "Срезать лицо удалено.")
	TEST_ASSERT_NULL(text2path("/datum/eldritch_knowledge/wax_relic"), "Отдельной ступени канделябра нет.")
	var/datum/eldritch_knowledge/spell/wax_shell/shell = allocate(/datum/eldritch_knowledge/spell/wax_shell)
	TEST_ASSERT((/obj/item/candle in shell.required_atoms) && (/obj/item/stack/sheet/mineral/silver in shell.required_atoms), "Оболочка открывает обряд канделябра из свечи и серебра.")
	TEST_ASSERT(/obj/item/heretic_path_relic/wax in shell.result_atoms, "Обряд оболочки создаёт канделябр.")
	var/datum/eldritch_knowledge/spell/wax_puppet_sleep/capture = allocate(/datum/eldritch_knowledge/spell/wax_puppet_sleep)
	TEST_ASSERT_EQUAL(capture.role, HERETIC_ROLE_CAPTURE, "Сон по кукле - захват.")
	var/datum/eldritch_knowledge/spell/wax_leak/escape = allocate(/datum/eldritch_knowledge/spell/wax_leak)
	TEST_ASSERT_EQUAL(escape.role, HERETIC_ROLE_ESCAPE, "Протечь - уход.")
	var/datum/eldritch_knowledge/base_wax/base = allocate(/datum/eldritch_knowledge/base_wax)
	TEST_ASSERT_EQUAL(base.role, HERETIC_ROLE_CRAFT, "База Воска - ремесло кукол.")

/// Кукла: Хватка в «Помощи» по предмету с отпечатками живого человека с разумом лепит куклу в руку, дело считает человека один раз, держатся две куклы, экипаж видит бирку и улику.
/datum/unit_test/heretic_wax_puppet_craft/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/first = allocate_wax_crew(locate(origin.x, origin.y + 2, origin.z))
	var/mob/living/carbon/human/second = allocate_wax_crew(locate(origin.x + 2, origin.y + 2, origin.z))
	var/mob/living/carbon/human/third = allocate_wax_crew(locate(origin.x + 3, origin.y + 2, origin.z))
	var/obj/item/pen/pen = wax_touched_item(first, get_step(user, EAST))
	var/obj/item/melee/touch_attack/mansus_fist/hand = allocate(/obj/item/melee/touch_attack/mansus_fist)
	user.a_intent = INTENT_HARM
	hand.afterattack(pen, user, TRUE)
	TEST_ASSERT(!QDELETED(hand) && !length(wax.puppets), "Вне «Помощи» предмет не становится куклой, заряд хватки цел.")
	user.a_intent = INTENT_HELP
	var/obj/item/pen/clean = allocate(/obj/item/pen, get_step(user, EAST))
	TEST_ASSERT(!wax.on_mansus_grasp(clean, user, TRUE), "Без отпечатков куклы нет.")
	TEST_ASSERT(findtext(wax.grasp_failure_reason, "отпечат"), "Отказ называет отпечатки: [wax.grasp_failure_reason]")
	clean.add_fingerprint(user)
	TEST_ASSERT(!wax.on_mansus_grasp(clean, user, TRUE), "Свои отпечатки не годятся.")
	var/mob/living/carbon/human/mindless = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y + 3, origin.z))
	mindless.dna.uni_identity = "wax_test_mindless"
	var/obj/item/pen/mindless_pen = wax_touched_item(mindless, get_step(user, EAST))
	TEST_ASSERT(!wax.on_mansus_grasp(mindless_pen, user, TRUE), "Отпечатки тела без разума не годятся.")
	var/mob/living/carbon/human/corpse = allocate_wax_crew(locate(origin.x + 2, origin.y + 3, origin.z))
	var/obj/item/pen/corpse_pen = wax_touched_item(corpse, get_step(user, EAST))
	corpse.death()
	TEST_ASSERT(!wax.on_mansus_grasp(corpse_pen, user, TRUE), "Отпечатки мёртвого не годятся.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 0, "Отказы не трогают дело.")
	hand.afterattack(pen, user, TRUE)
	TEST_ASSERT(QDELETED(hand), "Кукла расходует заряд хватки.")
	TEST_ASSERT_EQUAL(length(wax.puppets), 1, "Слеплена одна кукла.")
	var/obj/item/heretic_wax_puppet/puppet = wax.puppets[1]
	allocated += puppet
	TEST_ASSERT(user.is_holding(puppet), "Кукла ложится в руку.")
	TEST_ASSERT_EQUAL(puppet.model_ref?.resolve(), first, "Кукла повторяет владельца отпечатков.")
	TEST_ASSERT(findtext(puppet.name, first.real_name), "Имя с бирки видно в названии куклы.")
	TEST_ASSERT_NOTNULL(heretic_craft_on(puppet, "wax_puppet"), "Кукла - ремесло Воска.")
	TEST_ASSERT(!QDELETED(pen), "Предмет с отпечатками остаётся целым.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Новый человек продвигает дело.")
	var/crew_view = jointext(puppet.examine(second), " ")
	TEST_ASSERT(findtext(crew_view, "по чужим отпечаткам"), "Экипаж видит улику при осмотре: [crew_view]")
	TEST_ASSERT(findtext(crew_view, first.real_name), "Бирка называет человека.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(!wax.on_mansus_grasp(pen, user, TRUE), "Вторая кукла того же человека не лепится.")
	TEST_ASSERT(findtext(wax.grasp_failure_reason, "уже"), "Отказ объясняет повтор: [wax.grasp_failure_reason]")
	var/obj/item/pen/second_pen = wax_touched_item(second, get_step(user, EAST))
	TEST_ASSERT(wax.on_mansus_grasp(second_pen, user, TRUE), "Вторая кукла лепится по другому человеку.")
	TEST_ASSERT_EQUAL(length(heretic.deed.counted_keys), 2, "Второй человек засчитан.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	var/obj/item/pen/third_pen = wax_touched_item(third, get_step(user, EAST))
	TEST_ASSERT(wax.on_mansus_grasp(third_pen, user, TRUE), "Третья кукла лепится сверх предела.")
	TEST_ASSERT_EQUAL(length(wax.puppets), HERETIC_WAX_PUPPET_LIMIT, "Держатся две куклы.")
	TEST_ASSERT(QDELETED(puppet), "Старейшая кукла вытеснена.")
	for(var/obj/item/heretic_wax_puppet/kept as anything in wax.puppets)
		allocated += kept
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(wax.on_mansus_grasp(pen, user, TRUE), "Вытесненного человека можно слепить заново.")
	allocated += wax.puppets[length(wax.puppets)]
	TEST_ASSERT_EQUAL(length(heretic.deed.counted_keys), 3, "Повторная кукла того же человека не продвигает дело.")
	var/obj/item/paper/note = wax_touched_item(second, get_turf(user), /obj/item/paper)
	wax.combat_resource = 1
	TEST_ASSERT(wax.on_mansus_grasp(note, user, TRUE), "Лист бумаги на полу по-прежнему отливает свечу.")
	TEST_ASSERT(QDELETED(note) && length(wax.anchor_candles), "Из бумаги с отпечатками выходит свеча, а не кукла.")
	allocated += wax.anchor_candles[length(wax.anchor_candles)]

/// Во время паузы дела кукла нового человека не лепится и хватка цела; уже засчитанный человек лепится.
/datum/unit_test/heretic_wax_puppet_waits_for_deed/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/first = allocate_wax_crew(locate(origin.x, origin.y + 2, origin.z))
	var/mob/living/carbon/human/second = allocate_wax_crew(locate(origin.x + 2, origin.y + 2, origin.z))
	TEST_ASSERT_NOTNULL(make_wax_puppet(wax, user, first), "Первая кукла слеплена.")
	var/obj/item/pen/second_pen = wax_touched_item(second, get_step(user, EAST))
	TEST_ASSERT(!wax.on_mansus_grasp(second_pen, user, TRUE), "Во время паузы новый человек не лепится.")
	TEST_ASSERT(findtext(wax.grasp_failure_reason, "Слишком быстро"), "Отказ называет паузу: [wax.grasp_failure_reason]")
	TEST_ASSERT_EQUAL(length(wax.puppets), 1, "Отказ не лепит куклу.")
	qdel(wax.puppets[1])
	var/obj/item/pen/shared_pen = wax_touched_item(second, get_step(user, EAST))
	shared_pen.add_fingerprint(first)
	TEST_ASSERT(wax.on_mansus_grasp(shared_pen, user, TRUE), "Во время паузы с общей вещи лепится уже засчитанный человек.")
	var/obj/item/heretic_wax_puppet/fallback = wax.puppets[length(wax.puppets)]
	allocated += fallback
	TEST_ASSERT_EQUAL(fallback.model_ref?.resolve(), first, "Пауза уступает место засчитанному человеку.")
	TEST_ASSERT_EQUAL(length(heretic.deed.counted_keys), 1, "Засчитанный человек не продвигает дело.")
	qdel(fallback)
	TEST_ASSERT_NOTNULL(make_wax_puppet(wax, user, first), "Уже засчитанный человек лепится и во время паузы.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(wax.on_mansus_grasp(second_pen, user, TRUE), "После паузы новый человек лепится.")
	allocated += wax.puppets[length(wax.puppets)]
	TEST_ASSERT_EQUAL(length(heretic.deed.counted_keys), 2, "Оба человека засчитаны по разу.")

/// Куклу уничтожают нулевой жезл, зажигалка, сварка и огонь; смерть и смена тела её не трогают, удаление основы убирает.
/datum/unit_test/heretic_wax_puppet_removal/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/model = allocate_wax_crew(locate(origin.x + 3, origin.y + 3, origin.z))
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y + 1, origin.z))
	var/list/removals = list("nullrod", "lighter", "welder", "fire")
	for(var/removal in removals)
		COOLDOWN_RESET(heretic.deed, progress_cooldown)
		var/obj/item/heretic_wax_puppet/puppet = make_wax_puppet(wax, user, model)
		TEST_ASSERT_NOTNULL(puppet, "Кукла для проверки [removal] слеплена.")
		user.dropItemToGround(puppet)
		puppet.forceMove(get_step(crew, EAST))
		switch(removal)
			if("nullrod")
				var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
				crew.put_in_hands(rod)
				rod.melee_attack_chain(crew, puppet)
				qdel(rod)
			if("lighter")
				var/obj/item/lighter/lighter = allocate(/obj/item/lighter)
				lighter.set_lit(TRUE)
				puppet.attackby(lighter, crew)
				qdel(lighter)
			if("welder")
				var/obj/item/weldingtool/welder = allocate(/obj/item/weldingtool)
				welder.welding = TRUE
				puppet.attackby(welder, crew)
				welder.welding = FALSE
				qdel(welder)
			if("fire")
				puppet.fire_act(1000, 100)
		TEST_ASSERT(QDELETED(puppet), "[removal] уничтожает куклу.")
		TEST_ASSERT(!(puppet in wax.puppets), "После [removal] кукла уходит из списка.")
	var/obj/item/heretic_wax_puppet/survivor = make_wax_puppet(wax, user, model)
	var/obj/item/pen/plain = allocate(/obj/item/pen)
	survivor.attackby(plain, crew)
	TEST_ASSERT(!QDELETED(survivor), "Обычный предмет куклу не трогает.")
	user.stat = DEAD
	wax.on_death(user)
	user.stat = CONSCIOUS
	TEST_ASSERT(!QDELETED(survivor) && (survivor in wax.puppets), "Смерть еретика куклу не трогает.")
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(!QDELETED(survivor) && (survivor in wax.puppets), "Смена тела куклу не трогает.")
	var/datum/component/heretic_craft/craft = heretic_craft_on(survivor, "wax_puppet")
	TEST_ASSERT_EQUAL(craft?.owner_ref?.resolve(), wax, "Кукла по-прежнему принадлежит основе Воска.")
	qdel(wax)
	TEST_ASSERT(QDELETED(survivor), "Удаление основы уничтожает куклы.")

/// Укол куклы: работает только у хозяина с куклой в руке, по живому человеку без защиты, перезарядка 30 секунд.
/datum/unit_test/heretic_wax_puppet_prick/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/model = allocate_wax_crew(locate(origin.x + 3, origin.y + 3, origin.z))
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y + 1, origin.z))
	var/obj/item/heretic_wax_puppet/puppet = make_wax_puppet(wax, user, model)
	TEST_ASSERT(puppet.attack_self(user), "Хозяин колет куклу.")
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(puppet, prick_cooldown) - HERETIC_WAX_PUPPET_PRICK_COOLDOWN) < 1, "Перезарядка укола 30 секунд.")
	TEST_ASSERT(!wax.prick(user, puppet), "Во время перезарядки укола нет.")
	TEST_ASSERT(findtext(wax.wax_failure, "[HERETIC_WAX_PUPPET_PRICK_COOLDOWN / (1 SECONDS)] с"), "Отказ называет остаток перезарядки: [wax.wax_failure]")
	COOLDOWN_RESET(puppet, prick_cooldown)
	user.dropItemToGround(puppet)
	TEST_ASSERT(!wax.prick(user, puppet), "Кукла на полу не колется.")
	crew.put_in_hands(puppet)
	TEST_ASSERT(!puppet.attack_self(crew), "Чужак ничего не может сделать с куклой.")
	TEST_ASSERT(COOLDOWN_FINISHED(puppet, prick_cooldown), "Попытка чужака не запускает перезарядку.")
	crew.dropItemToGround(puppet)
	user.put_in_hands(puppet)
	var/turf/home = get_turf(model)
	model.forceMove(locate(home.x, home.y, home.z > 1 ? home.z - 1 : home.z + 1))
	TEST_ASSERT(!wax.prick(user, puppet), "Человека на другом уровне кукла не достаёт.")
	TEST_ASSERT(findtext(wax.wax_failure, "уровне"), "Отказ называет уровень: [wax.wax_failure]")
	TEST_ASSERT(COOLDOWN_FINISHED(puppet, prick_cooldown), "Отказ по уровню не запускает перезарядку.")
	model.forceMove(home)
	var/datum/component/anti_magic/protection = model.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 3)
	TEST_ASSERT(!wax.prick(user, puppet), "Защита от магии гасит укол.")
	TEST_ASSERT_EQUAL(protection.charges, 3, "Проверка не тратит заряды антимагии.")
	qdel(protection)
	model.death()
	TEST_ASSERT(!wax.prick(user, puppet), "Кукла мёртвого не колется.")
	TEST_ASSERT(findtext(wax.wax_failure, "живых"), "Отказ говорит, что человека нет среди живых: [wax.wax_failure]")

/// Сон по кукле: 5 секунд жара без воды и без ухода дальше 9 клеток - цель охоты спит 8 секунд, готова к обряду, кукла цела до пробуждения, невосприимчивость отсчитывается от пробуждения; не цель охоты только дремлет 3 секунды.
/datum/unit_test/heretic_wax_puppet_sleep/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_puppet_sleep)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/spell/wax_puppet_sleep/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/wax_puppet_sleep)
	var/obj/effect/proc_holder/spell/self/heretic_wax/puppet_sleep/spell = knowledge.granted_spell
	TEST_ASSERT(istype(spell), "Знание выдаёт Сон по кукле.")
	TEST_ASSERT_EQUAL(spell.charge_max, HERETIC_WAX_PUPPET_SLEEP_COOLDOWN, "Перезарядка 60 секунд.")
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/model = allocate_wax_crew(locate(origin.x + 3, origin.y + 3, origin.z))
	TEST_ASSERT(!wax.melt_puppet(user), "Без куклы в руке сна нет.")
	TEST_ASSERT(findtext(wax.wax_failure, "кукл"), "Отказ просит куклу: [wax.wax_failure]")
	var/obj/item/heretic_wax_puppet/puppet = make_wax_puppet(wax, user, model)
	var/datum/component/anti_magic/protection = model.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 3)
	TEST_ASSERT(!wax.melt_puppet(user), "Защита от магии спасает от сна.")
	TEST_ASSERT(findtext(wax.wax_failure, "защищена от магии"), "Отказ называет антимагию: [wax.wax_failure]")
	TEST_ASSERT_EQUAL(protection.charges, 3, "Проверка не тратит заряды антимагии.")
	qdel(protection)
	model.fire_stacks = -1
	TEST_ASSERT(!wax.melt_puppet(user), "Мокрого человека воск не берёт.")
	TEST_ASSERT(findtext(wax.wax_failure, "Вода"), "Отказ называет воду: [wax.wax_failure]")
	model.fire_stacks = 0
	var/turf/home = get_turf(model)
	model.forceMove(locate(origin.x + HERETIC_WAX_PUPPET_SLEEP_RANGE + 1, origin.y, origin.z))
	TEST_ASSERT(!wax.melt_puppet(user), "Дальше 9 клеток сон не начинается.")
	TEST_ASSERT(findtext(wax.wax_failure, "не дальше [HERETIC_WAX_PUPPET_SLEEP_RANGE] клеток"), "Отказ называет дальность: [wax.wax_failure]")
	model.forceMove(locate(home.x, home.y, home.z > 1 ? home.z - 1 : home.z + 1))
	TEST_ASSERT(!wax.melt_puppet(user), "С другого уровня сон не начинается.")
	TEST_ASSERT(findtext(wax.wax_failure, "на вашем уровне"), "Отказ называет уровень: [wax.wax_failure]")
	model.forceMove(home)
	heretic.set_hunt_target(model.mind)
	TEST_ASSERT(!capture_immunity(model, "wax"), "Отказы до начала сна не дают невосприимчивости.")
	TEST_ASSERT(wax.melt_puppet(user), "Кукла начинает таять.")
	var/datum/status_effect/heretic_wax_melting/melting = model.has_status_effect(/datum/status_effect/heretic_wax_melting)
	TEST_ASSERT_NOTNULL(melting, "Человек чувствует жар.")
	TEST_ASSERT(abs(melting.duration - world.time - HERETIC_WAX_PUPPET_SLEEP_CHANNEL) < 1, "Жар длится 5 секунд.")
	TEST_ASSERT(melting.steam && (melting.steam in model.vis_contents), "Над человеком поднимается пар.")
	TEST_ASSERT(!model.IsSleeping(), "Во время жара человек ещё не спит.")
	TEST_ASSERT(!wax.melt_puppet(user), "Вторая плавка на того же человека не начинается.")
	melting.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(melting, 1 SECONDS), "Жар заканчивается по сроку.")
	TEST_ASSERT(model.IsSleeping(), "Досмотревший жар человек спит.")
	TEST_ASSERT(model.AmountSleeping() > HERETIC_WAX_PUPPET_SLEEP_TIME - 1 SECONDS && model.AmountSleeping() <= HERETIC_WAX_PUPPET_SLEEP_TIME + DAMAGE_PRECISION, "Сон длится 8 секунд: [model.AmountSleeping()] дс.")
	TEST_ASSERT_EQUAL(model.voluntary_sleep_until, 0, "Сон не добровольный.")
	TEST_ASSERT(heretic.hunt_target_ready(model), "Спящий готов к обряду.")
	TEST_ASSERT(!QDELETED(puppet) && puppet.doll_sleep, "Пока человек спит, кукла цела и держит его сон.")
	var/datum/status_effect/heretic_capture_immunity/immunity = capture_immunity(model, "wax")
	TEST_ASSERT(immunity && abs(immunity.duration - world.time - HERETIC_WAX_PUPPET_SLEEP_TIME - HERETIC_CAPTURE_IMMUNITY) < 1, "Минута невосприимчивости отсчитывается от пробуждения.")
	var/datum/status_effect/heretic_capture_immunity/shared = capture_immunity(model, "shared")
	TEST_ASSERT(shared && abs(shared.duration - world.time - HERETIC_WAX_PUPPET_SLEEP_TIME - HERETIC_CAPTURE_SHARED_IMMUNITY) < 1, "Общий пол 15 секунд отсчитывается от пробуждения.")
	var/datum/status_effect/heretic_capture_knockout/knockout = puppet.doll_sleep
	knockout.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(puppet, 2 SECONDS), "К пробуждению кукла трескается.")
	TEST_ASSERT(!(puppet in wax.puppets), "Треснувшая кукла уходит из списка.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	make_wax_puppet(wax, user, model)
	TEST_ASSERT(!wax.melt_puppet(user), "Невосприимчивого человека не усыпить.")
	TEST_ASSERT(findtext(wax.wax_failure, "приходит в себя"), "Отказ называет невосприимчивость: [wax.wax_failure]")

/// Сон по кукле рвут уход дальше 9 клеток, другой уровень, выпитая и вылитая вода, святая вода, нулевой жезл по цели или по еретику, выпущенная кукла, оглушение еретика и начало обряда; сорванный сон тоже даёт минуту невосприимчивости.
/datum/unit_test/heretic_wax_puppet_sleep_breaks/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_puppet_sleep)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, locate(origin.x + 1, origin.y + 1, origin.z))
	var/turf/far = locate(origin.x + HERETIC_WAX_PUPPET_SLEEP_RANGE + 1, origin.y, origin.z)
	var/turf/elsewhere = locate(origin.x, origin.y, origin.z > 1 ? origin.z - 1 : origin.z + 1)
	TEST_ASSERT(far && elsewhere, "Для проверки есть дальняя клетка и другой уровень.")
	for(var/scenario in list("range", "zlevel", "drink", "splash", "holy", "rod_target", "rod_caster", "drop", "stun", "sacrifice"))
		COOLDOWN_RESET(heretic.deed, progress_cooldown)
		var/mob/living/carbon/human/model = allocate_wax_crew(locate(origin.x + 3, origin.y + 3, origin.z))
		var/obj/item/heretic_wax_puppet/puppet = make_wax_puppet(wax, user, model)
		TEST_ASSERT(wax.melt_puppet(user), "Жар начат для проверки [scenario].")
		var/datum/status_effect/heretic_wax_melting/melting = model.has_status_effect(/datum/status_effect/heretic_wax_melting)
		switch(scenario)
			if("range")
				model.forceMove(far)
			if("zlevel")
				model.forceMove(elsewhere)
			if("drink")
				model.reagents.add_reagent(/datum/reagent/water, 5)
				melting.tick()
			if("splash")
				var/datum/reagents/bucket = new(10)
				bucket.add_reagent(/datum/reagent/water, 10)
				bucket.reaction(model, TOUCH)
				qdel(bucket)
			if("holy")
				model.reagents.add_reagent(/datum/reagent/water/holywater, 5)
				melting.tick()
			if("rod_target", "rod_caster")
				var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
				crew.put_in_hands(rod)
				crew.a_intent = INTENT_HARM
				rod.melee_attack_chain(crew, scenario == "rod_target" ? model : user)
				crew.a_intent = INTENT_HELP
				qdel(rod)
				if(scenario == "rod_target")
					TEST_ASSERT_EQUAL(model.getBruteLoss(), 0, "Жезл по цели гасит жар, не раня.")
				else
					TEST_ASSERT(user.getBruteLoss() > 0, "Жезл по еретику бьёт его как обычно.")
					user.adjustBruteLoss(-user.getBruteLoss())
			if("drop")
				user.dropItemToGround(puppet)
			if("stun")
				user.Stun(2 SECONDS)
				melting.tick()
			if("sacrifice")
				melting.duration = world.time - 1
				SEND_SIGNAL(model, COMSIG_LIVING_HERETIC_SACRIFICE_STARTING)
		TEST_ASSERT(QDELETED(melting), "[scenario] обрывает жар.")
		TEST_ASSERT(!model.IsSleeping(), "После [scenario] человек не спит.")
		TEST_ASSERT(!QDELETED(puppet), "Сорванный сон не ломает куклу ([scenario]).")
		var/datum/status_effect/heretic_capture_immunity/immunity = capture_immunity(model, "wax")
		TEST_ASSERT(immunity && immunity.duration - world.time >= HERETIC_CAPTURE_MIN_IMMUNITY - 1 && immunity.duration - world.time < HERETIC_CAPTURE_IMMUNITY, "Сорванный сразу сон ([scenario]) даёт короткую невосприимчивость: [immunity?.duration - world.time] дс.")
		user.SetStun(0)
		user.forceMove(origin)
		qdel(puppet)
		qdel(model)

/// Протечь не обрывает Бессмертную процессию: её свечи бьют и под лужицей, а обычная процессия под лужицей гаснет; Бессмертная процессия колдуется, как прежде.
/datum/unit_test/heretic_wax_crown_ignores_leak/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_leaker()
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_procession)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	wax.combat_resource = 4
	TEST_ASSERT(wax.procession(user), "Обычная процессия идёт.")
	var/datum/status_effect/heretic_wax/procession/procession = user.has_status_effect(/datum/status_effect/heretic_wax/procession)
	TEST_ASSERT(wax.start_leak(user), "Еретик растекается во время обычной процессии.")
	procession.tick()
	TEST_ASSERT(QDELETED(procession), "Лужица гасит обычную процессию.")
	var/datum/status_effect/heretic_wax_leak/leak = wax.leak
	leak.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(leak, 1 SECONDS), "Лужица собирается обратно.")
	var/datum/eldritch_knowledge/final_eldritch/wax_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/wax_final)
	final_knowledge.finished = TRUE
	heretic.ascended = TRUE
	final_knowledge.on_body_gain(user)
	var/obj/effect/proc_holder/spell/self/heretic_wax/crown/crown_spell = locate() in final_knowledge.ascension_spell_instances
	TEST_ASSERT_NOTNULL(crown_spell, "Вознесение выдаёт Бессмертную процессию.")
	TEST_ASSERT(crown_spell.can_cast(user, FALSE, TRUE), "Бессмертная процессия колдуется, как прежде.")
	crown_spell.cast(list(user), user)
	procession = user.has_status_effect(/datum/status_effect/heretic_wax/procession)
	TEST_ASSERT(procession?.crown, "Идёт Бессмертная процессия.")
	TEST_ASSERT(wax.start_leak(user), "Еретик растекается во время Бессмертной процессии.")
	victim.remove_status_effect(/datum/status_effect/heretic_wax/clinging)
	var/brute_before = victim.getBruteLoss()
	procession.tick()
	TEST_ASSERT(!QDELETED(procession), "Лужица не гасит Бессмертную процессию.")
	TEST_ASSERT(abs(victim.getBruteLoss() - brute_before - 18) <= DAMAGE_PRECISION, "Свеча под лужицей бьёт на прежние 18: [victim.getBruteLoss() - brute_before].")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_wax/clinging), "Свеча под лужицей по-прежнему замедляет.")

/datum/unit_test/proc/allocate_wax_leaker()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_leak)
	return heretic

/// Протечь: 4 секунды лужицей - неуязвим, медленнее, выскальзывает из захвата, вползает под шлюз на болтах и выходит из проёма на свободную клетку; наручники и щит разума не дают растечься.
/datum/unit_test/heretic_wax_leak/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_leaker()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/spell/wax_leak/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/wax_leak)
	var/obj/effect/proc_holder/spell/self/heretic_wax/leak/spell = knowledge.granted_spell
	TEST_ASSERT(istype(spell), "Знание выдаёт Протечь.")
	TEST_ASSERT_EQUAL(spell.charge_max, HERETIC_WAX_LEAK_COOLDOWN, "Перезарядка 60 секунд.")
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 1, origin.z))
	grabber.start_pulling(user)
	grabber.setGrabState(GRAB_AGGRESSIVE)
	TEST_ASSERT(user.incapacitated(), "Агрессивный захват сковывает еретика.")
	TEST_ASSERT(spell.can_cast(user, FALSE, TRUE), "Протечь доступна в чужой хватке.")
	var/alpha_before = user.alpha
	TEST_ASSERT(wax.start_leak(user), "Еретик растекается.")
	TEST_ASSERT_NULL(user.pulledby, "Лужица выскальзывает из захвата.")
	var/datum/status_effect/heretic_wax_leak/leak = user.has_status_effect(/datum/status_effect/heretic_wax_leak)
	TEST_ASSERT_NOTNULL(leak, "Еретик стал лужицей.")
	TEST_ASSERT(abs(leak.duration - world.time - HERETIC_WAX_LEAK_DURATION) < 1, "Лужица держится 4 секунды.")
	grabber.start_pulling(user)
	TEST_ASSERT_NULL(user.pulledby, "Лужицу не схватить заново.")
	user.apply_damage(30, BRUTE)
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Лужица неуязвима.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_leak), "Лужица медленнее.")
	TEST_ASSERT(!wax.start_leak(user), "Повторно растечься нельзя.")
	var/obj/effect/abstract/heretic_wax_puddle/puddle = leak.puddle
	TEST_ASSERT(puddle && (puddle in user.vis_contents) && user.alpha == 0, "Вместо тела видна лужица воска.")
	var/obj/machinery/door/airlock/airlock = allocate(/obj/machinery/door/airlock, locate(origin.x + 1, origin.y, origin.z))
	airlock.bolt()
	TEST_ASSERT(airlock.density && airlock.locked, "Шлюз закрыт на болты.")
	TEST_ASSERT(!airlock.CanPass(grabber, get_turf(airlock)), "Обычного человека закрытый шлюз не пускает.")
	TEST_ASSERT(airlock.CanPass(user, get_turf(airlock)), "Лужица проходит под шлюзом на болтах.")
	TEST_ASSERT(step(user, EAST), "Лужица вползает под шлюз.")
	TEST_ASSERT_EQUAL(get_turf(user), get_turf(airlock), "Лужица под шлюзом.")
	leak.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(leak, 1 SECONDS), "Лужица собирается обратно по сроку.")
	var/turf/exit = get_turf(user)
	TEST_ASSERT(exit != get_turf(airlock) && !exit.is_blocked_turf(exclude_mobs = TRUE), "Застывшая в проёме лужица выходит на свободную клетку.")
	TEST_ASSERT(!airlock.CanPass(user, get_turf(airlock)), "Собравшийся еретик больше не проходит под шлюзом.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_leak) && user.alpha == alpha_before, "Облик и скорость возвращаются.")
	TEST_ASSERT(QDELETED(puddle) && !(puddle in user.vis_contents), "Лужица убрана с тела.")
	user.apply_damage(10, BRUTE)
	TEST_ASSERT(user.getBruteLoss() > 0, "После лужицы еретик снова уязвим.")
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(!wax.start_leak(user), "В наручниках растечься нельзя.")
	TEST_ASSERT(findtext(wax.wax_failure, "наручниках"), "Отказ называет наручники: [wax.wax_failure]")
	user.uncuff()
	ADD_TRAIT(user, TRAIT_MINDSHIELD, "wax_test")
	TEST_ASSERT(!wax.start_leak(user), "Под щитом разума растечься нельзя.")
	TEST_ASSERT(findtext(wax.wax_failure, "Щит разума"), "Отказ называет щит разума: [wax.wax_failure]")
	REMOVE_TRAIT(user, TRAIT_MINDSHIELD, "wax_test")

/// Лужица проходит под пожарной заслонкой и стеклянной дверцей в обе стороны, но не сквозь гермозаслон, окно, стену, неразрушимую и кодовую дверь.
/datum/unit_test/heretic_wax_leak_doors/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_leaker()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 1, origin.z))
	TEST_ASSERT(wax.start_leak(user), "Еретик растекается.")
	var/obj/machinery/door/firedoor/closed/firedoor = allocate(/obj/machinery/door/firedoor/closed, locate(origin.x + 2, origin.y + 2, origin.z))
	TEST_ASSERT(firedoor.density && firedoor.CanPass(user, get_turf(firedoor)), "Лужица проходит под пожарной заслонкой.")
	var/obj/machinery/door/window/windoor = allocate(/obj/machinery/door/window, locate(origin.x + 3, origin.y + 2, origin.z))
	TEST_ASSERT(windoor.density && windoor.CanPass(user, get_step(windoor, windoor.dir)), "Лужица проходит под стеклянной дверцей.")
	TEST_ASSERT(windoor.CheckExit(user, get_step(windoor, windoor.dir)) && !windoor.CheckExit(crew, get_step(windoor, windoor.dir)), "Из-под стеклянной дверцы лужица выползает наружу, человек нет.")
	var/obj/machinery/door/poddoor/blast = allocate(/obj/machinery/door/poddoor, locate(origin.x + 2, origin.y + 3, origin.z))
	TEST_ASSERT(blast.density && !blast.CanPass(user, get_turf(blast)), "Гермозаслон лужицу не пускает.")
	var/obj/structure/window/fulltile/window = allocate(/obj/structure/window/fulltile, locate(origin.x + 3, origin.y + 3, origin.z))
	TEST_ASSERT(!window.CanPass(user, get_turf(window)), "Окно лужицу не пускает.")
	var/turf/wall = locate(origin.x - 2, origin.y, origin.z)
	TEST_ASSERT(isclosedturf(wall) && !wall.Enter(user), "Стена лужицу не пускает.")
	var/obj/machinery/door/airlock/vault = allocate(/obj/machinery/door/airlock, locate(origin.x + 1, origin.y + 3, origin.z))
	vault.resistance_flags |= INDESTRUCTIBLE
	TEST_ASSERT(vault.density && !vault.CanPass(user, get_turf(vault)), "Неразрушимая дверь лужицу не пускает.")
	var/obj/machinery/door/password/puzzle = allocate(/obj/machinery/door/password, locate(origin.x, origin.y + 3, origin.z))
	puzzle.resistance_flags &= ~INDESTRUCTIBLE
	TEST_ASSERT(puzzle.density && !puzzle.CanPass(user, get_turf(puzzle)), "Кодовая дверь руин лужицу не пускает.")

/// Лужица не кликает, не включает вещь в руке, не применяет способности Воска и не колдует чужие заклинания; после лужицы всё снова доступно.
/datum/unit_test/heretic_wax_leak_cannot_act/Run()
	var/datum/antagonist/heretic/heretic = allocate_wax_leaker()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/obj/effect/proc_holder/spell/self/basic_heal/heal = new
	allocated += heal
	user.mind.AddSpell(heal)
	TEST_ASSERT(heal.can_cast(user, FALSE, TRUE), "Чужое заклинание до лужицы доступно.")
	var/obj/item/flashlight/light = allocate(/obj/item/flashlight)
	TEST_ASSERT(user.put_in_active_hand(light), "Фонарик в руке.")
	TEST_ASSERT(wax.start_leak(user), "Еретик растекается с фонариком в руке.")
	TEST_ASSERT(SEND_SIGNAL(user, COMSIG_MOB_CLICKON, light, "") & COMSIG_MOB_CANCEL_CLICKON, "Лужица не бьёт и не кликает.")
	TEST_ASSERT(user.is_holding(light) && !user.execute_mode(light, user.active_hand_index) && !light.on, "Лужица держит вещь, но не включает её.")
	TEST_ASSERT(!heal.cast_check(FALSE, user), "Лужица не колдует и чужие заклинания.")
	TEST_ASSERT_EQUAL(heal.charge_counter, heal.charge_max, "Отказ не тратит заряд чужого заклинания.")
	TEST_ASSERT(!wax.can_use(user), "Лужица не применяет способности Воска.")
	qdel(user.has_status_effect(/datum/status_effect/heretic_wax_leak))
	TEST_ASSERT(wax.can_use(user), "Способности Воска снова доступны.")
	TEST_ASSERT(heal.can_cast(user, FALSE, TRUE), "Чужое заклинание снова доступно.")
	TEST_ASSERT(user.execute_mode(light, user.active_hand_index) && light.on, "Собравшийся еретик снова включает вещь в руке.")

/// Числа в текстах кукол, Сна по кукле, Протечь и дела Воска совпадают с дефайнами.
/datum/unit_test/heretic_wax_texts/Run()
	var/datum/eldritch_knowledge/base_wax/base = allocate(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/spell/wax_puppet_sleep/capture = allocate(/datum/eldritch_knowledge/spell/wax_puppet_sleep)
	var/datum/eldritch_knowledge/spell/wax_leak/escape = allocate(/datum/eldritch_knowledge/spell/wax_leak)
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_WAX]
	TEST_ASSERT(findtext(base.desc, "Держатся [HERETIC_WAX_PUPPET_LIMIT] куклы"), "База называет предел кукол.")
	TEST_ASSERT(findtext(base.desc, "перезарядка [HERETIC_WAX_PUPPET_PRICK_COOLDOWN / (1 SECONDS)] секунд"), "База называет перезарядку укола.")
	TEST_ASSERT(findtext(capture.desc, "растопите её [HERETIC_WAX_PUPPET_SLEEP_CHANNEL / (1 SECONDS)] секунд"), "Сон называет время жара.")
	TEST_ASSERT(findtext(capture.desc, "в [HERETIC_WAX_PUPPET_SLEEP_RANGE] клетках уснёт на [HERETIC_WAX_PUPPET_SLEEP_TIME / (1 SECONDS)] секунд"), "Сон называет дальность и длительность.")
	TEST_ASSERT(findtext(capture.desc, "Перезарядка [HERETIC_WAX_PUPPET_SLEEP_COOLDOWN / (1 SECONDS)] секунд"), "Сон называет перезарядку.")
	TEST_ASSERT(findtext(escape.desc, "На [HERETIC_WAX_LEAK_DURATION / (1 SECONDS)] секунды"), "Протечь называет длительность.")
	TEST_ASSERT(findtext(escape.desc, "Перезарядка [HERETIC_WAX_LEAK_COOLDOWN / (1 SECONDS)] секунд"), "Протечь называет перезарядку.")
	var/obj/effect/proc_holder/spell/self/heretic_wax/puppet_sleep/sleep_spell = /obj/effect/proc_holder/spell/self/heretic_wax/puppet_sleep
	TEST_ASSERT(findtext(initial(sleep_spell.desc), "[HERETIC_WAX_PUPPET_SLEEP_RANGE] клетках") && findtext(initial(sleep_spell.desc), "спит [HERETIC_WAX_PUPPET_SLEEP_TIME / (1 SECONDS)] секунд"), "Кнопка сна называет дальность и длительность.")
	var/obj/effect/proc_holder/spell/self/heretic_wax/leak/leak_spell = /obj/effect/proc_holder/spell/self/heretic_wax/leak
	TEST_ASSERT(findtext(initial(leak_spell.desc), "На [HERETIC_WAX_LEAK_DURATION / (1 SECONDS)] секунды"), "Кнопка Протечь называет длительность.")
	TEST_ASSERT(findtext(path.capture_summary, "[HERETIC_WAX_PUPPET_SLEEP_TIME / (1 SECONDS)] секунд") && findtext(path.capture_summary, "[HERETIC_WAX_PUPPET_SLEEP_RANGE] клетках"), "Модель пути называет сон и дальность.")
	TEST_ASSERT(findtext(path.escape_summary, "[HERETIC_WAX_LEAK_DURATION / (1 SECONDS)] секунды"), "Модель пути называет длительность лужицы.")
	TEST_ASSERT(findtext(path.craft_summary, "[HERETIC_WAX_PUPPET_LIMIT] куклы"), "Модель пути называет предел кукол.")
	var/datum/heretic_deed/wax/deed = new
	allocated += deed
	TEST_ASSERT(findtext(deed.desc, "Каждый человек засчитывается один раз"), "Дело считает людей.")
	TEST_ASSERT(findtext(deed.desc, "Между зачётами Мансусу нужно [HERETIC_DEED_COOLDOWN / (1 SECONDS)] с"), "Дело Воска называет паузу между зачётами.")
	TEST_ASSERT(findtext(path.combat_practice, "Протечь") && findtext(path.combat_practice, "кукл"), "Полигон учит куклам и Протечь.")
	TEST_ASSERT(findtext(path.combat_practice, "[HERETIC_WAX_PUPPET_SLEEP_CHANNEL / (1 SECONDS)] секунд держите куклу") && findtext(path.combat_practice, "дальше [HERETIC_WAX_PUPPET_SLEEP_RANGE] клеток"), "Полигон называет дальность и время сна.")
	TEST_ASSERT(findtext(deed.hint, "Держатся [HERETIC_WAX_PUPPET_LIMIT] куклы"), "Подсказка дела называет предел кукол.")
	TEST_ASSERT(findtext(path.strengths, "в [HERETIC_WAX_PUPPET_SLEEP_RANGE] клетках даже за стеной") && findtext(path.weaknesses, "ухода дальше [HERETIC_WAX_PUPPET_SLEEP_RANGE] клеток"), "Стороны пути называют дальность сна.")
	TEST_ASSERT(!findtext(path.escape_summary, "любой") && findtext(path.weaknesses, "неразрушимые двери"), "Уход не обещает любую дверь.")
	TEST_ASSERT(findtext(capture.desc, "[HERETIC_CAPTURE_IMMUNITY / (1 SECONDS)] секунд невосприимчив к Сну и [HERETIC_CAPTURE_SHARED_IMMUNITY / (1 SECONDS)] секунд к любому захвату"), "Сон называет сроки невосприимчивости.")
	var/dollhouse_text = "[replacetext("[HERETIC_WAX_DOLLHOUSE_TIME / (1 SECONDS)]", ".", ",")] секунды"
	var/shake_text = "растолкать за [HERETIC_CAPTURE_SHAKE_TIME / (1 SECONDS)] секунды"
	TEST_ASSERT(findtext(capture.desc, "за [dollhouse_text] утягивает") && findtext(initial(sleep_spell.desc), "за [dollhouse_text] утянет"), "Тексты Сна называют время кукольного дома.")
	TEST_ASSERT(findtext(capture.desc, "нулевым жезлом или [shake_text]") && findtext(initial(sleep_spell.desc), "нулевым жезлом или [shake_text]"), "Тексты Сна называют, что будит спящего.")
	TEST_ASSERT(findtext(capture.desc, "вода сон уже не рвёт") && findtext(initial(sleep_spell.desc), "вода сон уже не рвёт"), "Тексты Сна говорят, что вода рвёт только жар.")
	var/datum/status_effect/doll_sleep = /datum/status_effect/heretic_capture_knockout/wax_doll
	TEST_ASSERT(findtext(initial(doll_sleep.examine_text), "нулевым жезлом или [shake_text]"), "Спящий по кукле при осмотре подсказывает, что его будит.")
	TEST_ASSERT(findtext(base.desc, "человек на вашем уровне чувствует укол"), "Укол ограничен уровнем.")
	TEST_ASSERT(findtext(escape.desc, "неразрушимые и кодовые двери"), "Протечь называет запертые для неё двери.")
	TEST_ASSERT(findtext(initial(sleep_spell.desc), "Перезарядка [HERETIC_WAX_PUPPET_SLEEP_COOLDOWN / (1 SECONDS)] секунд") && findtext(initial(leak_spell.desc), "Перезарядка [HERETIC_WAX_LEAK_COOLDOWN / (1 SECONDS)] секунд"), "Кнопки называют перезарядку.")
	var/atom/movable/screen/alert/status_effect/heretic_wax_melting/melting_alert = /atom/movable/screen/alert/status_effect/heretic_wax_melting
	TEST_ASSERT(findtext(initial(melting_alert.desc), "через [HERETIC_WAX_PUPPET_SLEEP_CHANNEL / (1 SECONDS)] секунд вы уснёте"), "Предупреждение о жаре называет срок жара.")
	TEST_ASSERT(findtext(capture.desc, "Кто не цель охоты, лишь задремлет на [HERETIC_WAX_PUPPET_DOZE_TIME / (1 SECONDS)] секунды"), "Сон говорит, что полный сон - только цели охоты.")
	var/atom/movable/screen/alert/status_effect/heretic_wax_leak/leak_alert = /atom/movable/screen/alert/status_effect/heretic_wax_leak
	TEST_ASSERT(findtext(initial(leak_alert.desc), "на [HERETIC_WAX_LEAK_DURATION / (1 SECONDS)] секунды"), "Значок лужицы называет срок.")
	var/atom/movable/screen/alert/status_effect/heretic_wax_seal/seal_alert = /atom/movable/screen/alert/status_effect/heretic_wax_seal
	TEST_ASSERT(!findtext(initial(seal_alert.desc), "Улучшенный клинок"), "Печать больше не ссылается на удалённый клинок.")

/// Протечь из агрессивной хватки через горячую клавишу проходит путь заклинания и уходит на перезарядку; лужица сбрасывает того, кого еретик нёс.
/datum/unit_test/heretic_wax_leak_hotkey/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_leak)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/spell/wax_leak/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/wax_leak)
	var/obj/effect/proc_holder/spell/self/heretic_wax/leak/spell = knowledge.granted_spell
	heretic.collect_combat_spells(list())
	var/slot = heretic.ability_hotkey_types.Find(/obj/effect/proc_holder/spell/self/heretic_wax/leak)
	TEST_ASSERT(slot, "У Протечь есть слот горячей клавиши.")
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/grabber = allocate(/mob/living/carbon/human, locate(origin.x, origin.y + 1, origin.z))
	grabber.start_pulling(user)
	grabber.setGrabState(GRAB_AGGRESSIVE)
	TEST_ASSERT(user.incapacitated(), "Агрессивный захват сковывает еретика.")
	TEST_ASSERT(user.activate_ability_hotkey(slot), "Хоткей Протечь обработан.")
	TEST_ASSERT_NOTNULL(user.has_status_effect(/datum/status_effect/heretic_wax_leak), "В захвате хоткей растекает еретика.")
	TEST_ASSERT_NULL(user.pulledby, "Хоткей Протечь разрывает захват.")
	TEST_ASSERT(spell.charge_counter < spell.charge_max, "Протечь уходит на перезарядку.")
	grabber.stop_pulling()
	qdel(user.has_status_effect(/datum/status_effect/heretic_wax_leak))
	var/mob/living/carbon/human/rider = allocate(/mob/living/carbon/human, origin)
	user.buckle_mob(rider, TRUE, buckle_type = RIDING_FIREMAN, auto_by_type = TRUE)
	TEST_ASSERT(user.has_buckled_mobs(), "Еретик несёт человека на плечах.")
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	TEST_ASSERT(wax.start_leak(user), "Еретик с ношей растекается.")
	TEST_ASSERT(!user.has_buckled_mobs(), "Лужица сбрасывает того, кого несла.")

/// Обряд канделябра из свечи и слитка серебра на настоящей руне идёт от Погребальной оболочки и расходует компоненты.
/datum/unit_test/heretic_wax_candelabrum_ritual/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/spell/wax_shell/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/spell/wax_shell)
	recipe.ritual_time = 0
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big, get_turf(user))
	var/obj/item/candle/candle = allocate(/obj/item/candle, get_turf(rune))
	var/obj/item/stack/sheet/mineral/silver/silver = allocate(/obj/item/stack/sheet/mineral/silver, get_turf(rune))
	TEST_ASSERT(rune.do_ritual(user, recipe), "Обряд канделябра завершается на руне.")
	TEST_ASSERT(QDELETED(candle) && QDELETED(silver), "Обряд расходует свечу и серебро.")
	var/obj/item/heretic_path_relic/wax/relic = locate() in get_turf(rune)
	TEST_ASSERT_NOTNULL(relic, "Руна создаёт канделябр.")
	allocated += relic
	TEST_ASSERT_EQUAL(relic.knowledge_ref?.resolve(), recipe, "Канделябр привязан к знанию оболочки.")
	TEST_ASSERT(!recipe.recipe_snowflake_check(list(), get_turf(rune), list(), user), "Пока жив первый канделябр, второй не создаётся.")

/datum/unit_test/proc/wax_sleep_by_puppet(datum/eldritch_knowledge/base_wax/wax, mob/living/carbon/human/user, mob/living/carbon/human/model)
	var/obj/item/heretic_wax_puppet/puppet = make_wax_puppet(wax, user, model)
	if(!puppet || !wax.melt_puppet(user))
		return null
	var/datum/status_effect/heretic_wax_melting/melting = model.has_status_effect(/datum/status_effect/heretic_wax_melting)
	melting.duration = world.time
	if(!wait_for_qdeleted(melting, 1 SECONDS))
		return null
	return puppet

/// Кукольный дом: пока цель охоты спит от куклы, кукла цела, одна «Помощь» сон не снимает; дальше 9 клеток, с другого уровня и после пробуждения кукла не утягивает, а к пробуждению трескается; в 9 клетках за 1,5 секунды утягивает спящего в изнанку и рассыпается.
/datum/unit_test/heretic_wax_dollhouse/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_puppet_sleep)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/turf/home = locate(origin.x + 3, origin.y + 3, origin.z)
	var/mob/living/carbon/human/wanderer = allocate_wax_crew(home)
	heretic.set_hunt_target(wanderer.mind)
	var/notice = wax.doll_sleep_notice(user, wanderer)
	TEST_ASSERT(findtext(notice, "куклу в руке") && findtext(notice, "за [replacetext("[HERETIC_WAX_DOLLHOUSE_TIME / (1 SECONDS)]", ".", ",")] секунды"), "Уснувшая цель охоты: сообщение велит взять куклу в руку и называет время: [notice]")
	var/mob/living/carbon/human/bystander = allocate_wax_crew(locate(origin.x + 1, origin.y + 3, origin.z))
	notice = wax.doll_sleep_notice(user, bystander)
	TEST_ASSERT(!findtext(notice, "изнанк") && findtext(notice, "треснет"), "Не цели охоты кукольный дом не обещан: [notice]")
	var/obj/item/heretic_wax_puppet/puppet = wax_sleep_by_puppet(wax, user, wanderer)
	TEST_ASSERT(puppet && wanderer.IsSleeping(), "Цель охоты спит от куклы.")
	TEST_ASSERT(!QDELETED(puppet) && puppet.doll_sleep, "Пока цель спит, кукла цела.")
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, get_step(home, SOUTH))
	wanderer.help_shake_act(helper)
	TEST_ASSERT(wanderer.IsSleeping(), "Одна «Помощь» не будит спящего по кукле.")
	TEST_ASSERT(LAZYFIND(helper.do_afters, wanderer), "«Помощь» начинает расталкивать спящего.")
	qdel(helper)
	wanderer.forceMove(locate(origin.x + HERETIC_WAX_PUPPET_SLEEP_RANGE + 1, origin.y, origin.z))
	TEST_ASSERT(!wax.pull_into_dollhouse(user, puppet), "Дальше 9 клеток кукла не утягивает.")
	TEST_ASSERT(findtext(wax.wax_failure, "не дальше [HERETIC_WAX_PUPPET_SLEEP_RANGE] клеток"), "Отказ называет дальность: [wax.wax_failure]")
	wanderer.forceMove(get_turf(GET_ERROR_ROOM))
	TEST_ASSERT(!wax.pull_into_dollhouse(user, puppet), "С другого уровня кукла не утягивает.")
	TEST_ASSERT(findtext(wax.wax_failure, "на вашем уровне"), "Отказ называет уровень: [wax.wax_failure]")
	wanderer.forceMove(home)
	TEST_ASSERT(!heretic.pocket?.active && !QDELETED(puppet), "Отказы не открывают изнанку и не ломают куклу.")
	wanderer.SetSleeping(0)
	TEST_ASSERT(!wax.pull_into_dollhouse(user, puppet), "Проснувшегося кукла не утягивает.")
	TEST_ASSERT(findtext(wax.wax_failure, "не спит"), "Отказ называет пробуждение: [wax.wax_failure]")
	TEST_ASSERT(wait_for_qdeleted(puppet, 2 SECONDS), "К пробуждению кукла трескается.")
	qdel(wanderer)
	var/mob/living/carbon/human/model = allocate_wax_crew(home)
	heretic.set_hunt_target(model.mind)
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	puppet = wax_sleep_by_puppet(wax, user, model)
	TEST_ASSERT(puppet && model.IsSleeping(), "Новая цель охоты спит от куклы.")
	var/started = world.time
	puppet.attack_self(user)
	TEST_ASSERT(heretic.pocket_holds(model), "Спящего утянуло в изнанку: [world.time - started] дс, [wax.dollhouse_block_reason(user, puppet)] / [heretic.pocket_pull_reason(user, model, home)].")
	TEST_ASSERT(world.time - started >= HERETIC_WAX_DOLLHOUSE_TIME - 1, "Кукла утягивает [HERETIC_WAX_DOLLHOUSE_TIME / (1 SECONDS)] с: [world.time - started] дс.")
	TEST_ASSERT(heretic.pocket.contains(user), "Еретик вошёл следом.")
	TEST_ASSERT_EQUAL(heretic.pocket.entry_turf, home, "Разрыв остаётся там, где спал человек.")
	TEST_ASSERT(QDELETED(puppet), "После утягивания кукла рассыпается.")
	TEST_ASSERT(model.IsSleeping(), "В изнанке человек ещё спит.")

/// Сон по кукле кончается от 2 секунд растолкать, нулевого жезла по спящему, его смерти и удаления, и вместе со сном трескается кукла; вода спящего не будит.
/datum/unit_test/heretic_wax_doll_sleep_ends/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_puppet_sleep)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/turf/home = locate(origin.x + 3, origin.y + 3, origin.z)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(home, SOUTH))
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	for(var/scenario in list("water", "shake", "rod", "death", "deleted"))
		COOLDOWN_RESET(heretic.deed, progress_cooldown)
		var/mob/living/carbon/human/model = allocate_wax_crew(home)
		var/obj/item/heretic_wax_puppet/puppet = wax_sleep_by_puppet(wax, user, model)
		TEST_ASSERT(puppet && model.IsSleeping() && puppet.doll_sleep, "Человек спит от куклы ([scenario]).")
		switch(scenario)
			if("water")
				model.reagents.add_reagent(/datum/reagent/water, 5)
				var/datum/reagents/bucket = new(10)
				bucket.add_reagent(/datum/reagent/water, 10)
				bucket.reaction(model, TOUCH)
				qdel(bucket)
				puppet.doll_sleep.tick()
				TEST_ASSERT(model.IsSleeping() && !QDELETED(puppet), "Вода спящего по кукле не будит.")
				qdel(model)
			if("shake")
				TEST_ASSERT(heretic_capture_shake(crew, model), "Две секунды растолкать доходят до конца.")
			if("rod")
				crew.a_intent = INTENT_HARM
				rod.melee_attack_chain(crew, model)
				crew.a_intent = INTENT_HELP
				TEST_ASSERT_EQUAL(model.getBruteLoss(), 0, "Жезл будит, не раня.")
			if("death")
				model.death()
			if("deleted")
				qdel(model)
		TEST_ASSERT(QDELETED(puppet), "Кончился сон - кукла треснула сразу ([scenario]).")
		TEST_ASSERT(!(puppet in wax.puppets), "Треснувшая кукла ушла из списка ([scenario]).")
		if(!QDELETED(model) && model.stat != DEAD)
			TEST_ASSERT(!model.IsSleeping(), "Человек проснулся ([scenario]).")

/// Кукла по личной вещи: ID-карта и КПК с именем живого человека лепят его куклу, как отпечатки, с тем же делом; вещь с чужим или своим именем - нет.
/datum/unit_test/heretic_wax_puppet_personal/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/owner = allocate_wax_crew(locate(origin.x + 3, origin.y + 3, origin.z))
	var/mob/living/carbon/human/clerk = allocate_wax_crew(locate(origin.x + 2, origin.y + 3, origin.z))
	owner.real_name = "Wax Owner [REF(owner)]"
	clerk.real_name = "Wax Clerk [REF(clerk)]"
	user.a_intent = INTENT_HELP
	var/obj/item/card/id/nobody = allocate(/obj/item/card/id, get_step(user, EAST))
	nobody.registered_name = "Nobody At All"
	TEST_ASSERT(!wax.on_mansus_grasp(nobody, user, TRUE), "Карта без живого владельца куклы не даёт.")
	var/obj/item/card/id/own = allocate(/obj/item/card/id, get_step(user, EAST))
	own.registered_name = user.real_name
	TEST_ASSERT(!wax.on_mansus_grasp(own, user, TRUE), "Своя карта куклы не даёт.")
	var/obj/item/card/id/card = allocate(/obj/item/card/id, get_step(user, EAST))
	card.registered_name = owner.real_name
	TEST_ASSERT(wax.on_mansus_grasp(card, user, TRUE), "ID-карта лепит куклу владельца: [wax.grasp_failure_reason]")
	var/obj/item/heretic_wax_puppet/puppet = wax.puppets[length(wax.puppets)]
	allocated += puppet
	TEST_ASSERT_EQUAL(puppet.model_ref?.resolve(), owner, "Кукла повторяет владельца карты.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Владелец карты идёт в дело.")
	var/datum/component/heretic_craft/craft = heretic_craft_on(puppet, "wax_puppet")
	TEST_ASSERT(findtext(craft?.clue, "по чужой вещи с именем"), "Улика называет вещь с именем: [craft?.clue]")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	var/obj/item/pen/pen = wax_touched_item(owner, get_step(user, EAST))
	TEST_ASSERT(!wax.on_mansus_grasp(pen, user, TRUE), "Вторая кукла того же человека по отпечаткам не лепится.")
	var/obj/item/modular_computer/pda/pda = allocate(/obj/item/modular_computer/pda, get_step(user, EAST))
	pda.saved_identification = clerk.real_name
	TEST_ASSERT(wax.on_mansus_grasp(pda, user, TRUE), "КПК лепит куклу владельца: [wax.grasp_failure_reason]")
	var/obj/item/heretic_wax_puppet/second = wax.puppets[length(wax.puppets)]
	allocated += second
	TEST_ASSERT_EQUAL(second.model_ref?.resolve(), clerk, "Кукла повторяет владельца КПК.")
	TEST_ASSERT_EQUAL(length(wax.puppets), HERETIC_WAX_PUPPET_LIMIT, "Куклы по вещам в том же пределе.")
	TEST_ASSERT_EQUAL(length(heretic.deed.counted_keys), 2, "Дело считает людей по вещам так же, как по отпечаткам.")

/// Выходы Воска: свои свечи на полу станции; свеча в руке и чужая свеча - нет.
/datum/unit_test/heretic_wax_pocket_exits/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/obj/item/candle/floor_candle = cast_wax_anchor(wax, user, locate(origin.x + 3, origin.y + 2, origin.z))
	var/obj/item/candle/held_candle = cast_wax_anchor(wax, user, locate(origin.x + 1, origin.y + 3, origin.z))
	TEST_ASSERT(floor_candle && held_candle, "Две свечи отлиты.")
	user.put_in_hands(held_candle)
	var/datum/antagonist/heretic/rival = allocate_deed_heretic(PATH_WAX)
	var/datum/eldritch_knowledge/base_wax/rival_wax = rival.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/obj/item/candle/foreign = cast_wax_anchor(rival_wax, rival.owner.current, locate(origin.x + 4, origin.y + 4, origin.z))
	TEST_ASSERT(foreign, "Чужая свеча отлита.")
	var/list/exits = wax.pocket_exits(user)
	TEST_ASSERT_EQUAL(length(exits), 1, "Выход - только своя свеча на полу.")
	for(var/label in exits)
		TEST_ASSERT(findtext(label, "Свеча - "), "Выход подписан свечой и отделом: [label]")
		TEST_ASSERT(get_dist(exits[label], floor_candle) <= 1, "Выход у своей свечи: [label]")
	var/listed = FALSE
	for(var/label in heretic.pocket_exits(user))
		if(findtext(label, "Свеча - "))
			listed = TRUE
	TEST_ASSERT(listed, "Изнанка предлагает выход к свече.")
	qdel(floor_candle)
	TEST_ASSERT_EQUAL(length(wax.pocket_exits(user)), 0, "Погасшая свеча больше не выход.")

/// Сон по кукле на человеке, который не цель охоты: только 3 секунды дрёмы, кукла трескается к пробуждению, невосприимчивость считается от него.
/datum/unit_test/heretic_wax_puppet_doze/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_WAX)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_puppet_sleep)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/turf/origin = get_turf(user)
	var/mob/living/carbon/human/model = allocate_wax_crew(locate(origin.x + 3, origin.y + 3, origin.z))
	make_wax_puppet(wax, user, model)
	TEST_ASSERT(model.mind != heretic.hunt_target, "Модель куклы - не цель охоты.")
	TEST_ASSERT(wax.melt_puppet(user), "Кукла начинает таять.")
	var/datum/status_effect/heretic_wax_melting/melting = model.has_status_effect(/datum/status_effect/heretic_wax_melting)
	melting.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(melting, 1 SECONDS), "Жар заканчивается по сроку.")
	TEST_ASSERT(model.IsSleeping(), "Не цель охоты тоже засыпает.")
	TEST_ASSERT(model.AmountSleeping() <= HERETIC_WAX_PUPPET_DOZE_TIME + DAMAGE_PRECISION, "Не цель охоты дремлет не дольше 3 секунд: [model.AmountSleeping()] дс.")
	var/datum/status_effect/heretic_capture_immunity/immunity = capture_immunity(model, "wax")
	TEST_ASSERT(immunity && abs(immunity.duration - world.time - HERETIC_WAX_PUPPET_DOZE_TIME - HERETIC_CAPTURE_IMMUNITY) < 1, "Невосприимчивость отсчитывается от конца дрёмы.")
