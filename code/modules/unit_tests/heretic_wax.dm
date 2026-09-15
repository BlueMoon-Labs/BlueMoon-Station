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
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_clinging), "Снятие оттиска сразу мешает отступлению.")
	victim.remove_status_effect(/datum/status_effect/heretic_wax/clinging)
	TEST_ASSERT(user.Adjacent(effigy) && !user.Adjacent(victim), "Двойник позволяет достать клинком удалённого врага.")
	blade.melee_attack_chain(user, effigy, null, NONE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 29) <= DAMAGE_PRECISION, "Первый удар клинком переносит пятнадцать ушибов.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_wax_clinging), "Удар через двойника снова замедляет оригинал.")
	user.FlushCurrentAction()
	blade.melee_attack_chain(user, effigy, null, NONE)
	TEST_ASSERT(abs(victim.getBruteLoss() - 29) <= DAMAGE_PRECISION, "Повторный щелчок не обходит задержку атаки.")
	effigy.attackby(blade, user)
	TEST_ASSERT(abs(victim.getBruteLoss() - 44) <= DAMAGE_PRECISION, "Двойник переносит не больше тридцати ушибов за два удара.")
	TEST_ASSERT(QDELETED(effigy) && QDELETED(effect), "Исчерпание двойника разрывает связь.")
	TEST_ASSERT_NULL(wax.active_effigy, "Знание освобождает ссылку на израсходованный оттиск.")

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

/// Исчерпанную оболочку можно заменить, а переплавка при пустом запасе сохраняет предел лечения.
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
	wax.combat_resource = 3
	TEST_ASSERT(!wax.raise_shell(user), "Активную защиту нельзя бесплатно обновить.")
	TEST_ASSERT_EQUAL(wax.combat_resource, 3, "Отклонённая замена не тратит ресурс.")
	user.mob_run_block(weapon, 60, "удар", ATTACK_TYPE_MELEE, 0, attacker, BODY_ZONE_CHEST, list())
	TEST_ASSERT(wax.raise_shell(user), "Исчерпанная оболочка заменяется без ожидания её удаления.")
	TEST_ASSERT(QDELETED(old_shell), "Замена убирает прежнюю оболочку.")
	var/datum/status_effect/heretic_wax/shell/shell = user.has_status_effect(/datum/status_effect/heretic_wax/shell)
	TEST_ASSERT_EQUAL(shell.absorbed_hostile, 0, "Замена не копирует раны старой оболочки.")
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
