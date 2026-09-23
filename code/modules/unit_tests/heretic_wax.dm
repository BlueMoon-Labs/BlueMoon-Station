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

/// Первые исследования дают дальнюю атаку, а оболочка открывается раньше своей реликвии.
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
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/wax_mark, user), "Метка следует за оттиском.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/spell/wax_shell, user), "Защита доступна на пятой ступени.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/wax_upgrade, user), "Улучшение клинка сохраняет место в развитии.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/wax_relic, user), "Канделябр открывается после оболочки.")

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
	heretic.gain_knowledge(/datum/eldritch_knowledge/wax_relic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/eldritch_knowledge/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/wax_relic)
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
	TEST_ASSERT(findtext(resource["description"], victim.real_name), "Ресурсная подсказка называет цель оттиска.")
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
	TEST_ASSERT(!findtext(resource["description"], "Двойник:"), "После разрушения подсказка не показывает старую цель.")

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
	heretic.gain_knowledge(/datum/eldritch_knowledge/wax_relic)
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
	relic.knowledge_ref = WEAKREF(heretic.get_knowledge(/datum/eldritch_knowledge/wax_relic))
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
	if(!(locate(/datum/wax_test_station_level) in allocated))
		allocated += new /datum/wax_test_station_level(run_loc_floor_bottom_left.z)
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

/// Уровень резервации не станция: на время теста он получает признак станции.
/datum/wax_test_station_level
	var/datum/space_level/level
	var/list/original_traits

/datum/wax_test_station_level/New(z)
	level = SSmapping.z_list[z]
	original_traits = level.traits
	level.traits = original_traits.Copy()
	level.traits[ZTRAIT_STATION] = TRUE

/datum/wax_test_station_level/Destroy()
	level.traits = original_traits
	level = null
	return ..()

/datum/wax_test_room
	var/area/room
	var/list/turf/moved = list()

/datum/wax_test_room/New(area_type)
	var/static/list/shared_rooms = list()
	if(!shared_rooms[area_type])
		shared_rooms[area_type] = new area_type
	room = shared_rooms[area_type]

/datum/wax_test_room/proc/take(turf/spot)
	if(moved[spot])
		return
	moved[spot] = spot.loc
	room.contents += spot

/datum/wax_test_room/Destroy()
	for(var/turf/spot as anything in moved)
		var/area/old_area = moved[spot]
		old_area.contents += spot
	moved.Cut()
	room = null
	return ..()

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
	for(var/datum/wax_test_room/lease in allocated)
		if(lease.room.type == area_type)
			lease.take(spot)
			return
	var/datum/wax_test_room/lease = new(area_type)
	allocated += lease
	lease.take(spot)

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
	var/datum/wax_test_station_level/lease = locate() in allocated
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
