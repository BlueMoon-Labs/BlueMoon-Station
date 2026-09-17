/// Дальний клик клинком переносит к метке, ранит цель и запускает общую перезарядку знания.
/datum/unit_test/heretic_void_seeking_blade/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_void)
	heretic.gain_knowledge(/datum/eldritch_knowledge/void_blade_upgrade)
	var/datum/eldritch_knowledge/void_blade_upgrade/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/void_blade_upgrade)
	var/turf/origin = get_turf(user)
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(origin.x + 3, origin.y + 1, origin.z))
	var/obj/item/melee/sickly_blade/void/blade = allocate(/obj/item/melee/sickly_blade/void)
	user.put_in_active_hand(blade)
	user.a_intent = INTENT_HARM
	victim.apply_status_effect(/datum/status_effect/eldritch/void)
	blade.ranged_attack_chain(user, victim)
	TEST_ASSERT(get_turf(user) != origin && user.Adjacent(victim), "Дальний клик переносит к отмеченному врагу.")
	TEST_ASSERT(victim.getBruteLoss() > 0, "После переноса следует настоящий удар клинком.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/void), "Попадание активирует метку.")
	TEST_ASSERT(!COOLDOWN_FINISHED(upgrade, blink_cooldown), "Успешный сдвиг запускает перезарядку.")
	TEST_ASSERT_NULL(upgrade.blink_failure_reason, "Успех не оставляет причину отказа.")
	var/obj/item/melee/sickly_blade/void/second_blade = allocate(/obj/item/melee/sickly_blade/void)
	user.dropItemToGround(blade)
	user.put_in_active_hand(second_blade)
	user.forceMove(origin)
	victim.apply_status_effect(/datum/status_effect/eldritch/void)
	TEST_ASSERT(!upgrade.on_ranged_attack_eldritch_blade(victim, user), "Второй клинок не обходит перезарядку знания.")
	TEST_ASSERT(findtext(upgrade.blink_failure_reason, "восстановится через"), "Отказ объясняет оставшееся ожидание.")
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Отказ не перемещает владельца.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/void), "Отказ сохраняет метку.")
	TEST_ASSERT(findtext(jointext(second_blade.examine(user), " "), "восстановится через"), "Осмотр другого клинка показывает ту же перезарядку.")

/// Отказы сдвига объясняют метку, дальность, преграды и защиту, сохраняя готовность и цель.
/datum/unit_test/heretic_void_seeking_blade_rejections/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_void)
	heretic.gain_knowledge(/datum/eldritch_knowledge/void_blade_upgrade)
	var/datum/eldritch_knowledge/void_blade_upgrade/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/void_blade_upgrade)
	var/turf/origin = get_turf(user)
	var/turf/target_floor = locate(origin.x + 3, origin.y + 1, origin.z)
	var/mob/living/victim = allocate(/mob/living/carbon/human, target_floor)
	var/obj/item/melee/sickly_blade/void/blade = allocate(/obj/item/melee/sickly_blade/void)
	user.put_in_active_hand(blade)
	TEST_ASSERT(!upgrade.on_ranged_attack_eldritch_blade(victim, user), "Неотмеченная цель не подходит.")
	TEST_ASSERT(findtext(upgrade.blink_failure_reason, "нет Метки"), "Отказ объясняет отсутствие метки.")
	victim.apply_status_effect(/datum/status_effect/eldritch/void)
	victim.forceMove(locate(origin.x + 6, origin.y, origin.z))
	TEST_ASSERT(!upgrade.on_ranged_attack_eldritch_blade(victim, user), "Слишком далёкая цель не подходит.")
	TEST_ASSERT(findtext(upgrade.blink_failure_reason, "5 клеток"), "Отказ объясняет дальность.")
	victim.forceMove(target_floor)
	user.Stun(2 SECONDS)
	TEST_ASSERT(!upgrade.on_ranged_attack_eldritch_blade(victim, user), "Оглушение запрещает сдвиг.")
	TEST_ASSERT(findtext(upgrade.blink_failure_reason, "не можете действовать"), "Отказ объясняет оглушение.")
	user.SetStun(0)
	user.put_in_active_hand(blade)
	TEST_ASSERT_EQUAL(user.get_active_held_item(), blade, "После оглушения клинок снова в активной руке.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!upgrade.on_ranged_attack_eldritch_blade(victim, user), "Защита от магии запрещает сдвиг.")
	TEST_ASSERT(findtext(upgrade.blink_failure_reason, "Защита цели"), "Отказ объясняет защиту: [upgrade.blink_failure_reason]")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проверка не расходует заряды антимагии.")
	qdel(protection)
	var/list/barriers = list()
	for(var/direction in GLOB.cardinals)
		var/obj/barrier = allocate(/obj, get_step(victim, direction))
		barrier.density = TRUE
		barriers += barrier
	TEST_ASSERT(!upgrade.on_ranged_attack_eldritch_blade(victim, user), "Преграды вокруг цели запрещают сдвиг.")
	TEST_ASSERT(findtext(upgrade.blink_failure_reason, "нет клетки"), "Отказ объясняет отсутствие места.")
	QDEL_LIST(barriers)
	ADD_TRAIT(user, TRAIT_NO_TELEPORT, TRAIT_SOURCE_UNIT_TESTS)
	TEST_ASSERT(!upgrade.on_ranged_attack_eldritch_blade(victim, user), "Запрет телепортации останавливает сдвиг.")
	TEST_ASSERT(findtext(upgrade.blink_failure_reason, "Перемещение заблокировано"), "Отказ объясняет запрет перемещения.")
	TEST_ASSERT(COOLDOWN_FINISHED(upgrade, blink_cooldown), "Отказы не расходуют перезарядку.")
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Отказы не перемещают владельца.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss() + victim.getFireLoss(), 0, "Отказы не ранят цель.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/void), "Отказы не снимают метку.")

/// Хватка ставит метку, реальное ранение подходящим клинком снимает её и даёт ровно одну порцию ресурса.
/datum/unit_test/heretic_combat_mark_cycle/Run()
	var/list/paths = list(
		/datum/eldritch_knowledge/base_ash = list(/datum/eldritch_knowledge/ash_mark, /obj/item/melee/sickly_blade/ash, /datum/status_effect/eldritch/ash),
		/datum/eldritch_knowledge/base_rust = list(/datum/eldritch_knowledge/rust_mark, /obj/item/melee/sickly_blade/rust, /datum/status_effect/eldritch/rust),
		/datum/eldritch_knowledge/base_flesh = list(/datum/eldritch_knowledge/flesh_mark, /obj/item/melee/sickly_blade/flesh, /datum/status_effect/eldritch/flesh),
		/datum/eldritch_knowledge/base_void = list(/datum/eldritch_knowledge/void_mark, /obj/item/melee/sickly_blade/void, /datum/status_effect/eldritch/void),
	)
	for(var/path_type in paths)
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/mob/living/carbon/human/user = heretic.owner.current
		var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
		var/list/setup = paths[path_type]
		heretic.gain_knowledge(path_type)
		heretic.gain_knowledge(setup[1])
		var/datum/eldritch_knowledge/path = heretic.get_knowledge(path_type)
		var/datum/eldritch_knowledge/mark_knowledge = heretic.get_knowledge(setup[1])
		var/obj/item/melee/sickly_blade/blade = allocate(setup[2])
		path.combat_resource = 0
		mark_knowledge.on_mansus_grasp(victim, user, TRUE, null)
		TEST_ASSERT(victim.has_status_effect(setup[3]), "Хватка должна ставить метку [path_type].")
		blade.afterattack(victim, user, TRUE, null)
		TEST_ASSERT(victim.has_status_effect(setup[3]), "Один afterattack без ранения не должен снимать метку.")
		TEST_ASSERT_EQUAL(path.combat_resource, 0, "Без реального попадания ресурс не выдаётся.")
		user.a_intent = INTENT_HARM
		blade.attack(victim, user)
		TEST_ASSERT(!victim.has_status_effect(setup[3]), "Ранение соответствующим клинком должно активировать метку.")
		TEST_ASSERT_EQUAL(path.combat_resource, 1, "Одна активация метки даёт одну порцию ресурса.")
		qdel(victim)
		qdel(heretic)

/// Урон Пустоты требует настоящего ранения своим клинком и учитывает метку, знание и антимагию.
/datum/unit_test/heretic_void_blade_damage/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_void)
	heretic.gain_knowledge(/datum/eldritch_knowledge/void_mark)
	var/datum/eldritch_knowledge/void_mark/mark = heretic.get_knowledge(/datum/eldritch_knowledge/void_mark)
	var/obj/item/melee/sickly_blade/void/blade = allocate(/obj/item/melee/sickly_blade/void)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	user.a_intent = INTENT_HARM
	mark.on_mansus_grasp(victim, user, TRUE, null)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_void_chill), "Метка без активации сама по себе не сковывает цель.")
	blade.attack(victim, user)
	TEST_ASSERT(abs(victim.getFireLoss() - 15) < DAMAGE_PRECISION, "Даже без улучшения клинка метка наносит 15 ожогов.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/void), "Попадание расходует метку.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill), "Активация метки сразу замедляет цель.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/void_blade_upgrade)
	var/burn_before = victim.getFireLoss()
	victim.remove_status_effect(/datum/status_effect/heretic_void_chill)
	blade.attack(victim, user)
	TEST_ASSERT(abs(victim.getFireLoss() - burn_before - 8) < DAMAGE_PRECISION, "Улучшенный клинок добавляет восемь ожогов без метки.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_void_chill), "Улучшенный клинок замедляет и без метки.")
	var/mob/living/carbon/human/marked_victim = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	mark.on_mansus_grasp(marked_victim, user, TRUE, null)
	blade.attack(marked_victim, user)
	TEST_ASSERT(abs(marked_victim.getFireLoss() - 23) < DAMAGE_PRECISION, "Улучшение и метка складываются ровно один раз.")
	TEST_ASSERT(marked_victim.getBruteLoss() > 0, "Магический урон дополняет обычное ранение.")
	var/mob/living/carbon/human/untouched = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	mark.on_mansus_grasp(untouched, user, TRUE, null)
	blade.force = 0
	blade.attack(untouched, user)
	TEST_ASSERT_EQUAL(untouched.getFireLoss(), 0, "Удар без ранения не наносит магический урон.")
	TEST_ASSERT(untouched.has_status_effect(/datum/status_effect/eldritch/void), "Удар без ранения сохраняет метку.")
	TEST_ASSERT(!untouched.has_status_effect(/datum/status_effect/heretic_void_chill), "Удар без ранения не активирует замедление метки.")
	blade.force = initial(blade.force)
	var/datum/component/anti_magic/protection = untouched.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	blade.attack(untouched, user)
	TEST_ASSERT_EQUAL(untouched.getFireLoss(), 0, "Антимагия блокирует одновременно метку и улучшение.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Одно попадание расходует один заряд защиты.")
	TEST_ASSERT(untouched.has_status_effect(/datum/status_effect/eldritch/void), "Заблокированная метка не расходуется.")
	TEST_ASSERT(!untouched.has_status_effect(/datum/status_effect/heretic_void_chill), "Антимагия блокирует замедление метки.")
	qdel(protection)
	var/obj/item/melee/sickly_blade/rust/wrong_blade = allocate(/obj/item/melee/sickly_blade/rust)
	wrong_blade.attack(untouched, user)
	TEST_ASSERT_EQUAL(untouched.getFireLoss(), 0, "Клинок другого пути не получает усиление Пустоты.")
	TEST_ASSERT(untouched.has_status_effect(/datum/status_effect/eldritch/void), "Клинок другого пути не активирует метку Пустоты.")
	TEST_ASSERT(!untouched.has_status_effect(/datum/status_effect/heretic_void_chill), "Чужой клинок не активирует замедление Пустоты.")
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, NORTHWEST))
	blade.attack(ally.owner.current, user)
	TEST_ASSERT_EQUAL(ally.owner.current.getFireLoss(), 0, "Другой еретик защищён от магического урона клинка.")

/// Хватка замедляет тёплую холодостойкую цель, учитывая союзников и антимагию.
/datum/unit_test/heretic_void_grasp_slowdown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/void_grasp/grasp = allocate(/datum/eldritch_knowledge/void_grasp)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.bodytemperature = BODYTEMP_NORMAL + 100
	ADD_TRAIT(victim, TRAIT_RESISTCOLD, TRAIT_SOURCE_UNIT_TESTS)
	var/initial_slowdown = victim.cached_multiplicative_slowdown
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE, null), "Хватка действует на холодостойкую цель.")
	TEST_ASSERT(victim.bodytemperature > BODYTEMP_NORMAL, "Цель остаётся тёплой после хватки.")
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, initial_slowdown + 2, "Замедление сразу увеличивает задержку движения независимо от холода.")
	var/datum/status_effect/heretic_void_chill/chill = victim.has_status_effect(/datum/status_effect/heretic_void_chill)
	TEST_ASSERT_NOTNULL(chill, "Хватка оставляет скованность Пустоты.")
	TEST_ASSERT_NOTNULL(chill.linked_alert, "Жертва видит индикатор замедления.")
	TEST_ASSERT_EQUAL(chill.duration, world.time + 4 SECONDS, "Скованность держится четыре секунды.")
	chill.duration = world.time + 1 SECONDS
	grasp.on_mansus_grasp(victim, user, TRUE, null)
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/heretic_void_chill), chill, "Повторная хватка обновляет существующий эффект.")
	TEST_ASSERT_EQUAL(chill.duration, world.time + 4 SECONDS, "Повторная хватка восстанавливает длительность.")
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, initial_slowdown + 2, "Повторная хватка не складывает замедление.")
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, NORTH))
	TEST_ASSERT(!grasp.on_mansus_grasp(ally.owner.current, user, TRUE, null), "Хватка пропускает другого еретика.")
	TEST_ASSERT(!ally.owner.current.has_status_effect(/datum/status_effect/heretic_void_chill), "Союзник не получает скованность.")
	var/mob/living/carbon/human/protected = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!grasp.on_mansus_grasp(protected, user, TRUE, null), "Антимагия останавливает хватку.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Хватка расходует один заряд защиты.")
	TEST_ASSERT(!protected.has_status_effect(/datum/status_effect/heretic_void_chill), "Защищённая цель не замедляется.")

/// Метка продлевает скованность хватки; окончание эффекта сохраняет независимые замедления.
/datum/unit_test/heretic_void_chill_refresh_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/void_grasp/grasp = allocate(/datum/eldritch_knowledge/void_grasp)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/domain)
	var/initial_slowdown = victim.cached_multiplicative_slowdown
	grasp.on_mansus_grasp(victim, user, TRUE, null)
	var/datum/status_effect/heretic_void_chill/chill = victim.has_status_effect(/datum/status_effect/heretic_void_chill)
	TEST_ASSERT_NOTNULL(chill, "Хватка создаёт скованность.")
	chill.duration = world.time + 1 SECONDS
	var/datum/status_effect/eldritch/void/mark = victim.apply_status_effect(/datum/status_effect/eldritch/void)
	mark.on_effect()
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/heretic_void_chill), chill, "Метка обновляет скованность хватки.")
	TEST_ASSERT_EQUAL(chill.duration, world.time + 4 SECONDS, "Метка даёт четыре секунды с момента активации.")
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, initial_slowdown + 2, "Хватка и метка дают одно замедление поверх домена.")
	chill.duration = world.time - 1
	chill.process()
	TEST_ASSERT(QDELETED(chill), "Скованность удаляется по истечении времени.")
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_void_chill), "После окончания нет остаточного замедления Пустоты.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/status_effect/domain), "Независимый домен продолжает замедлять цель.")
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, initial_slowdown, "После окончания возвращается прежняя задержка движения.")
	TEST_ASSERT(!victim.alerts["heretic_void_chill"], "Индикатор скованности снимается вместе с эффектом.")
	victim.apply_status_effect(/datum/status_effect/heretic_void_chill)
	victim.remove_status_effect(/datum/status_effect/heretic_void_chill)
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, initial_slowdown, "Досрочное снятие также восстанавливает скорость.")

/// Сдвиг сковывает врагов у обеих точек и пропускает союзников и антимагию.
/datum/unit_test/heretic_void_blink_slowdown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/turf/departure = get_turf(user)
	var/turf/destination = get_step(get_step(get_step(user, EAST), EAST), EAST)
	var/mob/living/near_departure = allocate(/mob/living/carbon/human, get_step(departure, EAST))
	var/mob/living/near_destination = allocate(/mob/living/carbon/human, get_step(destination, NORTH))
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(destination, EAST))
	ADD_TRAIT(protected, TRAIT_ANTIMAGIC, TRAIT_SOURCE_UNIT_TESTS)
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(departure, NORTH))
	var/obj/effect/proc_holder/spell/pointed/void_blink/spell = allocate(/obj/effect/proc_holder/spell/pointed/void_blink)
	spell.cast(list(destination), user)
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Сдвиг перемещает владельца к выбранной точке.")
	TEST_ASSERT(near_departure.has_status_effect(/datum/status_effect/heretic_void_chill), "Враг у точки выхода получает скованность.")
	TEST_ASSERT(near_destination.has_status_effect(/datum/status_effect/heretic_void_chill), "Враг у точки входа получает скованность.")
	TEST_ASSERT(!protected.has_status_effect(/datum/status_effect/heretic_void_chill), "Антимагия блокирует скованность сдвига.")
	TEST_ASSERT(!ally.owner.current.has_status_effect(/datum/status_effect/heretic_void_chill), "Сдвиг не сковывает союзника.")
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_void_chill), "Сдвиг не сковывает владельца.")

/// Притяжение замедляет и дальнюю цель без урона, учитывая защиту и союзников.
/datum/unit_test/heretic_void_pull_slowdown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/nearby = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/distant = allocate(/mob/living/carbon/human, get_step(get_step(get_step(user, EAST), EAST), EAST))
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	ADD_TRAIT(protected, TRAIT_ANTIMAGIC, TRAIT_SOURCE_UNIT_TESTS)
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, NORTHEAST))
	var/obj/effect/proc_holder/spell/targeted/void_pull/spell = allocate(/obj/effect/proc_holder/spell/targeted/void_pull)
	spell.cast(list(user), user)
	TEST_ASSERT(nearby.has_status_effect(/datum/status_effect/heretic_void_chill), "Ближняя цель получает скованность.")
	TEST_ASSERT(distant.has_status_effect(/datum/status_effect/heretic_void_chill), "Дальняя цель получает скованность.")
	TEST_ASSERT_EQUAL(distant.getBruteLoss(), 0, "Дальняя цель замедляется без прямого урона.")
	TEST_ASSERT(!protected.has_status_effect(/datum/status_effect/heretic_void_chill), "Защита блокирует скованность притяжения.")
	TEST_ASSERT(!ally.owner.current.has_status_effect(/datum/status_effect/heretic_void_chill), "Союзник не получает скованность притяжения.")

/// Подмена сковывает только врага после успешного обмена местами.
/datum/unit_test/heretic_void_swap_slowdown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/turf/user_start = get_turf(user)
	var/turf/victim_start = get_turf(victim)
	var/obj/effect/proc_holder/spell/pointed/boogie_woogie/spell = allocate(/obj/effect/proc_holder/spell/pointed/boogie_woogie)
	spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(get_turf(user), victim_start, "Владелец перемещается на место цели.")
	TEST_ASSERT_EQUAL(get_turf(victim), user_start, "Цель перемещается на место владельца.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_void_chill), "Успешный обмен сковывает противника.")
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_void_chill), "Обмен не сковывает владельца.")
	victim.remove_status_effect(/datum/status_effect/heretic_void_chill)
	ADD_TRAIT(victim, TRAIT_ANTIMAGIC, TRAIT_SOURCE_UNIT_TESTS)
	spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(get_turf(user), victim_start, "Заблокированный обмен сохраняет позицию владельца.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_void_chill), "Заблокированный обмен не сковывает цель.")
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, NORTH))
	var/turf/ally_start = get_turf(ally.owner.current)
	spell.cast(list(ally.owner.current), user)
	TEST_ASSERT_EQUAL(get_turf(user), ally_start, "С союзником по-прежнему можно поменяться местами.")
	TEST_ASSERT(!ally.owner.current.has_status_effect(/datum/status_effect/heretic_void_chill), "Обмен с союзником не сковывает его.")

/// Зимние поля сразу сковывают цель, не складывают силу и оставляют ограниченное послевоздействие.
/datum/unit_test/heretic_void_fields_slowdown/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	ADD_TRAIT(protected, TRAIT_ANTIMAGIC, TRAIT_SOURCE_UNIT_TESTS)
	var/initial_slowdown = victim.cached_multiplicative_slowdown
	var/list/zones = list()
	for(var/zone_type in list(/obj/effect/heretic_combat_zone/void, /obj/effect/heretic_combat_zone/void/lantern, /obj/effect/heretic_combat_zone/void/last_waltz))
		victim.remove_status_effect(/datum/status_effect/heretic_void_chill)
		var/obj/effect/heretic_combat_zone/zone = allocate(zone_type, get_turf(user), heretic.owner)
		STOP_PROCESSING(SSprocessing, zone)
		zones += zone
		TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_void_chill), "[zone_type] сковывает при создании, до тика подсистемы.")
		TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, initial_slowdown + 2, "Перекрывающиеся поля дают одно замедление.")
		TEST_ASSERT(!protected.has_status_effect(/datum/status_effect/heretic_void_chill), "Антимагия блокирует скованность поля.")
	victim.remove_status_effect(/datum/status_effect/heretic_void_chill)
	var/obj/effect/domain_expansion/domain = allocate(/obj/effect/domain_expansion, get_turf(user), 2, 20 SECONDS, list(user), FALSE)
	zones += domain
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_void_chill), "Домен сковывает при создании.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/void), "Домен сразу накладывает метку.")
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, initial_slowdown + 2, "Домен не умножает замедление других полей.")
	var/datum/status_effect/heretic_void_chill/chill = victim.has_status_effect(/datum/status_effect/heretic_void_chill)
	chill.duration = world.time + 1 SECONDS
	domain.tick_zone(user)
	TEST_ASSERT_EQUAL(chill.duration, world.time + 4 SECONDS, "Пока цель в поле, скованность обновляется.")
	victim.forceMove(run_loc_floor_top_right)
	for(var/obj/effect/heretic_combat_zone/zone as anything in zones)
		TEST_ASSERT(!victim.has_movespeed_modifier(REF(zone)), "Вышедшая цель освобождается от источника поля.")
		qdel(zone)
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, initial_slowdown + 2, "После выхода остаётся только временная скованность.")
	chill.duration = world.time - 1
	chill.process()
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_slowdown, initial_slowdown, "После окончания скованности скорость полностью восстанавливается.")

/// Цепочка пепла затухает; нулевые и отрицательные повторы не превращают урон в лечение.
/datum/unit_test/heretic_ash_mark_decay/Run()
	var/mob/living/carbon/human/first = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/second = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	first.apply_status_effect(/datum/status_effect/eldritch/ash, 2)
	var/datum/status_effect/eldritch/ash/mark = first.has_status_effect(/datum/status_effect/eldritch/ash)
	mark.on_effect()
	var/datum/status_effect/eldritch/ash/last_mark = second.has_status_effect(/datum/status_effect/eldritch/ash)
	TEST_ASSERT(last_mark, "Метка должна перейти к соседней цели.")
	TEST_ASSERT_EQUAL(last_mark.repetitions, 1, "При переходе остаётся на один повтор меньше.")
	last_mark.on_effect()
	TEST_ASSERT(!first.has_status_effect(/datum/status_effect/eldritch/ash), "Последняя метка не начинает новую цепочку.")
	var/burn_before = first.getFireLoss()
	first.apply_status_effect(/datum/status_effect/eldritch/ash, -5)
	mark = first.has_status_effect(/datum/status_effect/eldritch/ash)
	mark.on_effect()
	TEST_ASSERT(first.getFireLoss() > burn_before, "Некорректное число повторов никогда не должно лечить цель.")

/// Возрождение требует огня, лечит от горящего врага и не позволяет бесплатно истощать антимагию.
/datum/unit_test/heretic_ash_rebirth_targets/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/effect/proc_holder/spell/targeted/fiery_rebirth/rebirth = allocate(/obj/effect/proc_holder/spell/targeted/fiery_rebirth)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	rebirth.charge_counter = 0
	rebirth.cast(list(user), user)
	TEST_ASSERT_EQUAL(rebirth.charge_counter, rebirth.charge_max, "Без огня способность возвращает перезарядку.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Негорящий сосед не тратит защиту.")
	victim.adjust_fire_stacks(2)
	victim.IgniteMob()
	TEST_ASSERT(victim.on_fire, "Цель должна гореть перед попыткой вытянуть жар.")
	rebirth.charge_counter = 0
	rebirth.cast(list(user), user)
	TEST_ASSERT_EQUAL(protection.charges, 5, "Поиск доступного жара не расходует защиту.")
	TEST_ASSERT_EQUAL(rebirth.charge_counter, rebirth.charge_max, "Без доступного жара способность возвращает перезарядку.")
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Защита блокирует ожоги возрождения.")
	qdel(protection)
	user.adjustBruteLoss(20)
	user.adjustFireLoss(20)
	rebirth.cast(list(user), user)
	TEST_ASSERT(abs(victim.getFireLoss() - 15) < 0.001, "Горящий враг получает 15 ожогов.")
	TEST_ASSERT(abs(user.getBruteLoss() - 10) < 0.001 && abs(user.getFireLoss() - 10) < 0.001, "Одна цель восстанавливает по 10 ушибов и ожогов.")
	victim.ExtinguishMob()
	user.adjust_fire_stacks(2)
	user.IgniteMob()
	rebirth.charge_counter = 0
	rebirth.cast(list(user), user)
	TEST_ASSERT(!user.on_fire, "Без врагов способность всё ещё гасит самого владельца.")
	TEST_ASSERT_EQUAL(rebirth.charge_counter, 0, "Успешное тушение расходует перезарядку.")

/// Облако сильнее отравляет вблизи, пропускает союзников и уважает антимагию врага.
/datum/unit_test/heretic_rust_plume_falloff/Run()
	var/obj/effect/proc_holder/spell/cone/staggered/entropic_plume/plume = allocate(/obj/effect/proc_holder/spell/cone/staggered/entropic_plume)
	var/mob/living/carbon/human/nearby = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/distant = allocate(/mob/living/carbon/human)
	plume.do_mob_cone_effect(nearby, 1)
	plume.do_mob_cone_effect(distant, plume.cone_levels)
	TEST_ASSERT(abs(nearby.getToxLoss() + nearby.getFireLoss() - 10) < 0.1, "У основания облако наносит десять коррозии.")
	TEST_ASSERT(abs(distant.getToxLoss() + distant.getFireLoss() - 2) < 0.1, "На краю конуса остаётся две единицы коррозии.")
	TEST_ASSERT_EQUAL(nearby.reagents.get_reagent_amount(/datum/reagent/eldritch), 0, "Шлейф не добавляет скрытый урон эссенции поверх контроля.")
	var/datum/antagonist/heretic/ally = allocate_heretic()
	var/mob/living/ally_body = ally.owner.current
	var/datum/component/anti_magic/ally_protection = ally_body.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	plume.do_mob_cone_effect(ally_body, 1)
	TEST_ASSERT_EQUAL(ally_protection.charges, 5, "Союзник не расходует защиту на безвредное для него облако.")
	TEST_ASSERT_EQUAL(ally_body.getToxLoss(), 0, "Союзник не получает отравление.")
	var/mob/living/carbon/human/protected = allocate(/mob/living/carbon/human)
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	plume.do_mob_cone_effect(protected, 1)
	TEST_ASSERT_EQUAL(protection.charges, 4, "Враг расходует один заряд защиты.")
	TEST_ASSERT_EQUAL(protected.getToxLoss(), 0, "Антимагия блокирует отравление.")

/// Яд клинка и метки имеет явный урон без эссенции и принудительной тошноты.
/datum/unit_test/heretic_rust_damage_budget/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/rust_blade_upgrade/upgrade = allocate(/datum/eldritch_knowledge/rust_blade_upgrade)
	for(var/strike in 1 to 3)
		upgrade.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT(abs(victim.getToxLoss() + victim.getFireLoss() - 15) < 0.1, "Три попадания добавляют ровно 15 коррозии.")
	TEST_ASSERT_EQUAL(victim.reagents.get_reagent_amount(/datum/reagent/eldritch), 0, "Клинок не оставляет эссенцию, повреждающую все типы здоровья.")
	victim.setToxLoss(0)
	var/damage_before = victim.getToxLoss() + victim.getFireLoss()
	var/disgust_before = victim.disgust
	var/datum/status_effect/eldritch/rust/mark = victim.apply_status_effect(/datum/status_effect/eldritch/rust)
	mark.on_effect()
	TEST_ASSERT(abs(victim.getToxLoss() + victim.getFireLoss() - damage_before - 15) < 0.1, "Метка добавляет 15 коррозии.")
	TEST_ASSERT_EQUAL(victim.disgust, disgust_before, "Метка не добавляет отдельную волну тошноты.")

/// Распад оставляет короткое окно падения и учитывает союзников и антимагию.
/datum/unit_test/heretic_decay_control/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, NORTH))
	var/obj/item/melee/touch_attack/grasp_of_decay/hand = allocate(/obj/item/melee/touch_attack/grasp_of_decay)
	hand.afterattack(ally.owner.current, user, TRUE)
	TEST_ASSERT(!QDELETED(hand), "Касание союзника сохраняет хватку.")
	TEST_ASSERT(!ally.owner.current.has_status_effect(/datum/status_effect/corrosion_curse/lesser), "Союзник не получает распад.")
	var/mob/living/carbon/human/protected = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	hand.afterattack(protected, user, TRUE)
	TEST_ASSERT_EQUAL(protection.charges, 4, "Защита расходует один заряд.")
	TEST_ASSERT(!protected.IsKnockdown() && !protected.has_status_effect(/datum/status_effect/corrosion_curse/lesser), "Защита блокирует и падение, и проклятие.")
	qdel(protection)
	hand = allocate(/obj/item/melee/touch_attack/grasp_of_decay)
	hand.afterattack(protected, user, TRUE)
	var/datum/status_effect/incapacitating/knockdown/knockdown = protected.IsKnockdown()
	TEST_ASSERT(knockdown && knockdown.duration > world.time && knockdown.duration <= world.time + 2 SECONDS, "Успешное касание сбивает не дольше двух секунд.")
	TEST_ASSERT(protected.has_status_effect(/datum/status_effect/corrosion_curse/lesser), "После падения остаётся распад.")

/mob/living/carbon/human/heretic_decay_probe
	var/decay_effects = 0
	var/vomit_effects = 0

/mob/living/carbon/human/heretic_decay_probe/adjustBruteLoss(amount, updating_health = TRUE, forced = FALSE, only_robotic = FALSE, only_organic = TRUE)
	decay_effects++

/mob/living/carbon/human/heretic_decay_probe/adjustOrganLoss(slot, amount, maximum)
	decay_effects++

/mob/living/carbon/human/heretic_decay_probe/Dizzy(amount)
	decay_effects++

/mob/living/carbon/human/heretic_decay_probe/vomit(lost_nutrition = 10, blood = FALSE, stun = TRUE, distance = 1, message = TRUE, vomit_type = VOMIT_TOXIC, harm = TRUE, force = FALSE, purge_ratio = 0.1)
	decay_effects++
	vomit_effects++

/// Тик распада не запускает второе, полное проклятие с рвотой.
/datum/unit_test/heretic_decay_single_effect/Run()
	var/mob/living/carbon/human/heretic_decay_probe/victim = allocate(/mob/living/carbon/human/heretic_decay_probe, run_loc_floor_bottom_left)
	var/datum/status_effect/corrosion_curse/lesser/curse = victim.apply_status_effect(/datum/status_effect/corrosion_curse/lesser)
	victim.decay_effects = 0
	victim.vomit_effects = 0
	curse.tick()
	TEST_ASSERT_EQUAL(victim.decay_effects, 1, "Один тик выбирает ровно один эффект независимо от результата броска.")
	TEST_ASSERT_EQUAL(victim.vomit_effects, 0, "Слабый распад не вызывает рвоту полного проклятия.")

/// Повторное наложение не оставляет старый обработчик отрисовки или несколько меток одного пути.
/datum/unit_test/heretic_mark_replacement_cleanup/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.apply_status_effect(/datum/status_effect/eldritch/ash)
	var/datum/status_effect/eldritch/old_mark = victim.has_status_effect(/datum/status_effect/eldritch/ash)
	TEST_ASSERT_NOTNULL(old_mark.linked_alert, "Жертва видит предупреждение о действующей метке.")
	victim.apply_status_effect(/datum/status_effect/eldritch/ash)
	TEST_ASSERT(QDELETED(old_mark), "Предыдущая метка удаляется при замене.")
	TEST_ASSERT_EQUAL(length(victim.has_status_effect_list(/datum/status_effect/eldritch/ash)), 1, "На цели остаётся ровно одна метка пути.")
	var/list/mark_overlays = list()
	SEND_SIGNAL(victim, COMSIG_ATOM_UPDATE_OVERLAYS, mark_overlays)
	TEST_ASSERT_EQUAL(length(mark_overlays), 1, "Отрисовка вызывается только для новой метки.")
	victim.remove_status_effect(/datum/status_effect/eldritch/ash)
	mark_overlays.Cut()
	SEND_SIGNAL(victim, COMSIG_ATOM_UPDATE_OVERLAYS, mark_overlays)
	TEST_ASSERT_EQUAL(length(mark_overlays), 0, "После снятия метки не остаётся её обработчиков отрисовки.")

/// Перенос пассивов не оставляет бессмертное старое тело и сохраняет traits из чужих источников.
/datum/unit_test/heretic_passive_body_transfer/Run()
	var/mob/living/carbon/human/old_body = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human)
	var/datum/eldritch_knowledge/cold_snap/cold = allocate(/datum/eldritch_knowledge/cold_snap)
	ADD_TRAIT(old_body, TRAIT_NOBREATH, "test_foreign_source")
	cold.on_body_gain(old_body)
	cold.on_body_gain(old_body)
	cold.on_body_lose(old_body)
	TEST_ASSERT(!HAS_TRAIT(old_body, TRAIT_RESISTCOLD), "Старое тело теряет холодостойкость пути.")
	TEST_ASSERT(HAS_TRAIT(old_body, TRAIT_NOBREATH), "Независимый источник отсутствия дыхания сохраняется.")
	cold.on_body_gain(new_body)
	TEST_ASSERT(HAS_TRAIT(new_body, TRAIT_RESISTCOLD), "Новое тело получает пассивное знание.")
	cold.on_body_lose(new_body)
	TEST_ASSERT(!HAS_TRAIT(new_body, TRAIT_NOBREATH), "Снятие роли не выдаёт отсутствие дыхания повторно.")
	var/datum/eldritch_knowledge/flame_immunity/flame = allocate(/datum/eldritch_knowledge/flame_immunity)
	flame.on_body_gain(old_body)
	flame.on_body_lose(old_body)
	TEST_ASSERT(!HAS_TRAIT(old_body, TRAIT_NOFIRE), "Защита Пепла должна сниматься вместе со знанием.")

/// Холодная область освобождает ушедшую цель и не трогает замедления от других источников.
/datum/unit_test/heretic_winter_zone_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	var/obj/effect/heretic_combat_zone/void/zone = allocate(/obj/effect/heretic_combat_zone/void, run_loc_floor_bottom_left, heretic.owner)
	STOP_PROCESSING(SSprocessing, zone)
	zone.tick_zone(user)
	TEST_ASSERT(victim.has_movespeed_modifier(REF(zone)), "Враг внутри области должен замедляться.")
	TEST_ASSERT(!user.has_movespeed_modifier(REF(zone)), "Создатель не должен замедляться в своей области.")
	victim.forceMove(run_loc_floor_top_right)
	TEST_ASSERT(!victim.has_movespeed_modifier(REF(zone)), "Выход из области снимает замедление до следующего тика.")
	victim.forceMove(get_step(run_loc_floor_bottom_left, EAST))
	zone.tick_zone(user)
	var/zone_id = REF(zone)
	qdel(zone)
	TEST_ASSERT(!victim.has_movespeed_modifier(zone_id), "Удаление области должно освобождать оставшиеся внутри цели.")

/// Исчерпанная граница распространения безопасна, работа одного тика ограничена установленным бюджетом.
/datum/unit_test/heretic_rust_frontier_budget/Run()
	// allocate() заменяет null первым тайлом фикстуры; здесь намеренно проверяем отсутствие начала.
	var/datum/rust_spread/spread = new(null)
	allocated += spread
	TEST_ASSERT_EQUAL(spread.process(), PROCESS_KILL, "Пустая очередь должна спокойно завершать обработку.")
	spread.edge_turfs += run_loc_floor_bottom_left
	spread.spread_per_tick = 1
	spread.process()
	TEST_ASSERT_EQUAL(spread.queue_index, 2, "За тик обрабатывается ровно одна разрешённая клетка.")
	TEST_ASSERT(length(spread.edge_turfs) <= 5, "Одна клетка добавляет не больше четырёх соседей.")

/// Запас пути переживает смену тела, а точечное удаление кнопки не стирает чужую однотипную способность.
/datum/unit_test/heretic_resource_body_transfer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	var/datum/eldritch_knowledge/base_ash/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	path.combat_resource = 3
	var/obj/effect/proc_holder/spell/foreign_power = allocate(/obj/effect/proc_holder/spell/self/heretic_power/ash)
	heretic.owner.AddSpell(foreign_power)
	var/obj/effect/proc_holder/spell/old_power = path.combat_power
	path.on_body_lose(user)
	TEST_ASSERT(QDELETED(old_power), "Удаляется экземпляр кнопки, принадлежащий знанию.")
	TEST_ASSERT(!QDELETED(foreign_power), "Чужая однотипная кнопка не должна удаляться.")
	path.on_body_gain(user)
	TEST_ASSERT_EQUAL(path.combat_resource, 3, "Перенос тела не обнуляет запас пути.")
	TEST_ASSERT(path.combat_power != old_power, "Кнопка восстанавливается на новом теле.")

/// Молчание, облик и предел здоровья слуги следуют за телом, а исходные характеристики восстанавливаются отдельно.
/datum/unit_test/heretic_servant_body_effects/Run()
	var/datum/antagonist/heretic/master = allocate_heretic()
	var/datum/antagonist/heretic/fixture = allocate_heretic(get_step(run_loc_floor_bottom_left, EAST))
	var/mob/living/carbon/human/old_body = fixture.owner.current
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human)
	var/datum/antagonist/heretic_monster/voiceless_dead/servant = allocate(/datum/antagonist/heretic_monster/voiceless_dead)
	servant.owner = fixture.owner
	fixture.owner.antag_datums += servant
	servant.silent = TRUE
	servant.health_cap = 90
	servant.set_master(master)
	old_body.setMaxHealth(150)
	new_body.setMaxHealth(180)
	servant.apply_innate_effects(old_body)
	TEST_ASSERT_EQUAL(old_body.maxHealth, 90, "Первое тело получает предел здоровья слуги.")
	TEST_ASSERT(HAS_TRAIT(old_body, TRAIT_MUTE), "Безмолвный мертвец теряет голос.")
	fixture.owner.transfer_to(new_body, TRUE)
	TEST_ASSERT_EQUAL(old_body.maxHealth, 150, "Первому телу возвращается его собственное здоровье.")
	TEST_ASSERT(!HAS_TRAIT(old_body, TRAIT_MUTE), "Молчание не остаётся в покинутом теле.")
	TEST_ASSERT_EQUAL(new_body.maxHealth, 90, "Новое тело получает тот же предел роли.")
	TEST_ASSERT(HAS_TRAIT(new_body, TRAIT_MUTE), "Молчание следует за ролью в новое тело.")
	fixture.owner.remove_antag_datum(/datum/antagonist/heretic_monster/voiceless_dead)
	TEST_ASSERT_EQUAL(new_body.maxHealth, 180, "Второму телу возвращается его здоровье, а не здоровье первого.")
	TEST_ASSERT(!HAS_TRAIT(new_body, TRAIT_MUTE), "Снятие роли освобождает голос нового тела.")

/// Кадильница забирает реальное пламя; неудачный выдох сохраняет заряд и общий запас.
/datum/unit_test/heretic_censer_resource/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/obj/item/heretic_relic/censer/censer = allocate(/obj/item/heretic_relic/censer)
	user.put_in_hands(censer)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.adjust_fire_stacks(3)
	victim.IgniteMob()
	TEST_ASSERT(censer.capture_fire(user, victim), "Кадильница должна поглотить пламя рядом.")
	TEST_ASSERT(!victim.on_fire, "Поглощение гасит источник пламени.")
	TEST_ASSERT_EQUAL(censer.stored_fire, 1, "За один источник выдаётся один заряд.")
	TEST_ASSERT(!censer.capture_fire(user, victim), "Уже погашенная цель не даёт повторный заряд.")
	path.combat_resource = 0
	TEST_ASSERT(!censer.release_fire(user), "Без уголька огненный выдох невозможен.")
	TEST_ASSERT_EQUAL(censer.stored_fire, 1, "Неудачный выдох сохраняет пламя.")
	path.combat_resource = 1
	user.setDir(EAST)
	ADD_TRAIT(victim, TRAIT_ANTIMAGIC, "test_censer")
	TEST_ASSERT(censer.release_fire(user), "Выдох расходует доступный уголёк.")
	TEST_ASSERT_EQUAL(path.combat_resource, 0, "Успешный выдох расходует одну порцию ресурса.")
	TEST_ASSERT_EQUAL(censer.stored_fire, 0, "Выдох освобождает весь запас кадильницы.")
	TEST_ASSERT(!victim.on_fire, "Огненный выдох уважает защиту от магии.")

/// Видимый край следует границе воздействия и удаляется вместе с полем.
/datum/unit_test/heretic_visible_field_boundary/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	var/obj/effect/heretic_combat_zone/void/zone = allocate(/obj/effect/heretic_combat_zone/void, center, heretic.owner)
	STOP_PROCESSING(SSprocessing, zone)
	TEST_ASSERT(length(zone.boundary) > 0, "Поле должно иметь видимый край.")
	TEST_ASSERT(length(zone.field_turfs) <= 25, "Поле радиуса 2 не выходит за область 5×5.")
	for(var/obj/effect/heretic_field_edge/edge as anything in zone.boundary)
		TEST_ASSERT(edge.loc in zone.field_turfs, "Каждая граница находится на затронутой клетке.")
		TEST_ASSERT(length(edge.overlays) > 0, "У края должен быть видимый выход.")
	var/boundary_count = length(zone.boundary)
	var/obj/effect/heretic_field_edge/removed_edge = zone.boundary[1]
	qdel(removed_edge)
	zone.refresh_boundary()
	TEST_ASSERT_EQUAL(length(zone.boundary), boundary_count, "Удалённый край восстанавливается даже без изменения поля.")
	TEST_ASSERT(!(removed_edge in zone.boundary), "Удалённый край не возвращается в пул.")
	var/timer_id = zone.expiry_timer
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[timer_id], "Поле хранит действующий остановимый таймер.")
	var/list/edges = zone.boundary.Copy()
	qdel(zone)
	TEST_ASSERT_NULL(SStimer.timer_id_dict[timer_id], "Удаление поля отменяет ожидающий таймер.")
	for(var/obj/effect/heretic_field_edge/edge as anything in edges)
		TEST_ASSERT(QDELETED(edge), "После удаления поля не остаётся ложной границы.")

/// Уничтожение посаженного сердца сразу прекращает работу поля и убирает телеграф.
/datum/unit_test/heretic_rust_seed_destruction/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_rust)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_rust)
	var/obj/item/heretic_relic/rust_seed/seed = allocate(/obj/item/heretic_relic/rust_seed)
	user.put_in_hands(seed)
	path.combat_resource = 0
	TEST_ASSERT(!seed.plant(user), "Посадка требует нарост.")
	TEST_ASSERT(!QDELETED(seed), "Неудачная посадка не уничтожает семя.")
	path.combat_resource = 1
	TEST_ASSERT(seed.plant(user), "Семя укореняется при наличии ресурса.")
	TEST_ASSERT(QDELETED(seed), "Успешная посадка расходует семя.")
	TEST_ASSERT_EQUAL(path.combat_resource, 0, "Посадка расходует один нарост.")
	var/obj/structure/heretic_rust_heart/heart = path.rust_heart
	var/obj/effect/heretic_combat_zone/zone = heart.zone
	var/list/edges = zone.boundary.Copy()
	heart.take_damage(100, BRUTE, MELEE, 0)
	TEST_ASSERT(QDELETED(heart), "Сердце можно уничтожить обычным уроном.")
	TEST_ASSERT(QDELETED(zone), "Разрушение сердца немедленно гасит поле.")
	TEST_ASSERT_NULL(path.rust_heart, "Знание освобождает ссылку на разрушенное сердце.")
	TEST_ASSERT_NULL(path.relic_zone, "Знание освобождает ссылку на погасшее поле.")
	for(var/obj/effect/heretic_field_edge/edge as anything in edges)
		TEST_ASSERT(QDELETED(edge), "Вместе с сердцем исчезает его видимая граница.")

/// Реконструкция доступна только своей свите и не тратит биомассу на целое тело.
/datum/unit_test/heretic_suture_servant_ownership/Run()
	var/datum/antagonist/heretic/master = allocate_heretic()
	master.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/mob/living/carbon/human/user = master.owner.current
	var/datum/eldritch_knowledge/path = master.get_knowledge(/datum/eldritch_knowledge/base_flesh)
	var/obj/item/heretic_relic/suture_needle/needle = allocate(/obj/item/heretic_relic/suture_needle)
	user.put_in_hands(needle)
	var/datum/antagonist/heretic/fixture = allocate_heretic(get_step(user, EAST))
	var/mob/living/carbon/human/target = fixture.owner.current
	TEST_ASSERT(!needle.mend_servant(user, target), "Постороннего нельзя лечить как своего слугу.")
	var/datum/antagonist/heretic_monster/servant = allocate(/datum/antagonist/heretic_monster)
	servant.owner = fixture.owner
	fixture.owner.antag_datums += servant
	servant.silent = TRUE
	servant.set_master(master)
	TEST_ASSERT(!needle.mend_servant(user, target), "Целому слуге не требуется реконструкция.")
	TEST_ASSERT_EQUAL(path.combat_resource, initial(path.combat_resource), "Неудачные попытки не расходуют биомассу.")
	var/obj/item/bodypart/arm = target.get_bodypart(BODY_ZONE_L_ARM)
	arm.drop_limb()
	qdel(arm)
	TEST_ASSERT(needle.mend_servant(user, target), "Игла восстанавливает утраченную конечность своего слуги.")
	TEST_ASSERT(target.get_bodypart(BODY_ZONE_L_ARM), "Восстановленная рука действительно прикреплена к телу.")
	TEST_ASSERT_EQUAL(path.combat_resource, initial(path.combat_resource) - 1, "Реконструкция расходует одну биомассу.")

/// Фонарь следует за рукой, а выпадение гасит поле и не позволяет обойти задержку другим предметом.
/datum/unit_test/heretic_lantern_held_lifecycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_void)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	var/obj/item/heretic_relic/hush_lantern/lantern = allocate(/obj/item/heretic_relic/hush_lantern)
	TEST_ASSERT(!lantern.activate(user), "Фонарь на полу не создаёт поле.")
	user.put_in_hands(lantern)
	TEST_ASSERT(lantern.activate(user), "Фонарь в руке принимает осколок зимы.")
	var/obj/effect/heretic_combat_zone/zone = lantern.zone
	STOP_PROCESSING(SSprocessing, zone)
	var/list/original_edges = zone.boundary.Copy()
	user.forceMove(get_step(user, NORTHEAST))
	TEST_ASSERT_EQUAL(get_turf(zone), get_turf(user), "Поле движется вместе с владельцем.")
	TEST_ASSERT(length(original_edges & zone.boundary), "Перемещение поля повторно использует его видимые края.")
	user.dropItemToGround(lantern)
	TEST_ASSERT(QDELETED(zone), "Выпавший фонарь немедленно теряет поле.")
	TEST_ASSERT_NULL(path.relic_zone, "Погасший фонарь освобождает ссылку знания на поле.")
	TEST_ASSERT_EQUAL(lantern.icon_state, "lantern-blue", "Погасший фонарь меняет видимое состояние.")
	var/obj/item/heretic_relic/hush_lantern/second = allocate(/obj/item/heretic_relic/hush_lantern)
	user.put_in_hands(second)
	path.combat_resource = 1
	TEST_ASSERT(!second.activate(user), "Второй фонарь не обходит общую задержку пути.")
	TEST_ASSERT_EQUAL(path.combat_resource, 1, "Задержка не расходует новый осколок.")

/// Периодические поля учитывают антимагию, сохраняя заряды защиты.
/datum/unit_test/heretic_zone_antimagic_charges/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/list/zone_types = list(/obj/effect/heretic_combat_zone/ash, /obj/effect/heretic_combat_zone/void)
	for(var/zone_type in zone_types)
		var/obj/effect/heretic_combat_zone/zone = allocate(zone_type, get_turf(user), heretic.owner)
		STOP_PROCESSING(SSprocessing, zone)
		zone.tick_zone(user)
		zone.tick_zone(user)
		TEST_ASSERT_EQUAL(protection.charges, 5, "Периодическое поле [zone_type] не расходует заряды защиты.")
		TEST_ASSERT(!victim.on_fire && !victim.has_movespeed_modifier(REF(zone)), "Защита блокирует действие поля.")
		qdel(zone)
	TEST_ASSERT(!heretic_can_affect(user, victim), "Активная магическая атака блокируется той же защитой.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Активная атака по-прежнему расходует один заряд.")

/// Истечение печати освобождает ссылку знания, а её видимая область не захватывает космос.
/datum/unit_test/heretic_zone_owner_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_void)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	var/obj/effect/proc_holder/spell/self/heretic_power/void/power = path.combat_power
	var/turf/space = get_step(user, EAST)
	var/previous_type = space.type
	space = space.ChangeTurf(/turf/open/space)
	power.activate_power(user, path)
	var/obj/effect/heretic_combat_zone/zone = path.combat_zone
	STOP_PROCESSING(SSprocessing, zone)
	var/space_was_affected = (space in zone.field_turfs)
	space.ChangeTurf(previous_type)
	TEST_ASSERT(!space_was_affected, "Печать на полу не распространяет поле на космос.")
	qdel(zone)
	TEST_ASSERT_NULL(path.combat_zone, "Удаление печати освобождает ссылку знания сразу.")

/// Аура вознесения охлаждает и сковывает врага, учитывая антимагию без расхода зарядов.
/datum/unit_test/heretic_void_ascension_passive/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/final_eldritch/void_final/finale = allocate(/datum/eldritch_knowledge/final_eldritch/void_final)
	finale.finished = TRUE
	var/original_temperature = victim.bodytemperature
	finale.on_life(user)
	TEST_ASSERT_EQUAL(victim.silent, 0, "Пассивная аура не лишает противника голоса.")
	TEST_ASSERT(victim.bodytemperature < original_temperature, "Пассивное охлаждение продолжает действовать.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_void_chill), "Аура вознесения поддерживает скованность.")
	victim.remove_status_effect(/datum/status_effect/heretic_void_chill)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/list/current_areas = finale.storm.impacted_areas
	finale.on_life(user)
	TEST_ASSERT_EQUAL(protection.charges, 5, "Постоянная аура не тратит заряды антимагии.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_void_chill), "Антимагия защищает от скованности ауры.")
	TEST_ASSERT_EQUAL(finale.storm.impacted_areas, current_areas, "Пока владелец остаётся в области, погодная область не перестраивается.")
	finale.stop_storm()

/// Переход бури в другую область снимает прежний оверлей.
/datum/unit_test/heretic_void_storm_area_transfer/Run()
	var/area/first = new
	var/area/second = new
	allocated += first
	allocated += second
	TEST_ASSERT_NOTEQUAL(first, second, "Переход проверяется между двумя отдельными областями.")
	var/datum/weather/void_storm/heretic/storm = allocate(/datum/weather/void_storm/heretic, list(run_loc_floor_bottom_left.z), first)
	TEST_ASSERT_EQUAL(storm.followed_area, first, "Буря привязана к первой области.")
	storm.stage = MAIN_STAGE
	storm.update_areas()
	TEST_ASSERT_EQUAL(first.icon_state, storm.weather_overlay, "Буря видна в привязанной области.")
	storm.move_to_area(second)
	TEST_ASSERT_EQUAL(storm.followed_area, second, "Буря переместилась во вторую область.")
	TEST_ASSERT_EQUAL(first.icon_state, "", "Переход снимает оверлей с прежней области.")
	TEST_ASSERT_EQUAL(second.icon_state, storm.weather_overlay, "Буря появляется в новой области.")
	TEST_ASSERT_EQUAL(length(storm.impacted_areas), 1, "За владельцем следует ровно одна область.")
	storm.end()
	TEST_ASSERT_EQUAL(second.icon_state, "", "Завершение убирает последний оверлей.")

/// Кольцо Клятвы огня не тратит заряды защиты при периодическом воздействии.
/datum/unit_test/heretic_fire_sworn_antimagic/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/obj/effect/proc_holder/spell/targeted/fire_sworn/spell = allocate(/obj/effect/proc_holder/spell/targeted/fire_sworn)
	spell.current_user = user
	spell.has_fire_ring = TRUE
	spell.process()
	spell.process()
	TEST_ASSERT_EQUAL(protection.charges, 5, "Два тика кольца сохраняют все заряды защиты.")
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Антимагия блокирует прямой урон кольца.")

/// Домен сохраняет живую метку и освобождает удалённую цель из списка воздействия.
/datum/unit_test/heretic_domain_mark_lifecycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/effect/domain_expansion/domain = allocate(/obj/effect/domain_expansion, get_turf(user), 3, 20 SECONDS, list(user), FALSE)
	domain.tick_zone(user)
	var/datum/status_effect/eldritch/void/mark = victim.has_status_effect(/datum/status_effect/eldritch/void)
	TEST_ASSERT_NOTNULL(mark, "Враг внутри домена получает метку Пустоты.")
	mark.duration = world.time + 3 SECONDS
	var/original_expiry = mark.duration
	domain.tick_zone(user)
	TEST_ASSERT_EQUAL(victim.has_status_effect(/datum/status_effect/eldritch/void), mark, "Следующий тик не пересоздаёт существующую метку.")
	TEST_ASSERT_EQUAL(mark.duration, original_expiry, "Домен не продлевает срок действующей метки.")
	mark.on_effect()
	domain.tick_zone(user)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/void), "После активации метки домен может наложить следующую.")
	qdel(victim)
	TEST_ASSERT(!(victim in domain.affected), "Удалённая цель сразу освобождается из поля.")

/// Каскад доходит до внешнего кольца и показывает огонь без атмосферного топлива.
/datum/unit_test/heretic_fire_cascade_wave/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	var/mob/living/user = heretic.owner.current
	var/turf/outer = locate(center.x + 3, center.y, center.z)
	var/mob/living/victim = allocate(/mob/living/carbon/human, outer)
	var/obj/effect/proc_holder/spell/aoe_turf/fire_cascade/spell = allocate(/obj/effect/proc_holder/spell/aoe_turf/fire_cascade)
	spell.fire_cascade(user, 3)
	TEST_ASSERT(victim.getFireLoss() >= 15, "Внешнее кольцо каскада наносит ожоги.")
	TEST_ASSERT(victim.on_fire, "Внешнее кольцо поджигает противника.")
	var/visible_flame = FALSE
	for(var/obj/effect/temp_visual/visual in outer)
		if(visual.icon == 'icons/effects/turf_fire.dmi' && visual.icon_state == "red_big")
			visible_flame = TRUE
	TEST_ASSERT(visible_flame, "Огонь каскада виден на обычном полу без горючего газа.")

/// Клятва поддерживает видимое кольцо и после завершения перезарядки.
/datum/unit_test/heretic_fire_sworn_lifecycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/turf/nearby = get_step(user, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, nearby)
	var/obj/effect/proc_holder/spell/targeted/fire_sworn/spell = allocate(/obj/effect/proc_holder/spell/targeted/fire_sworn)
	spell.cast(list(user), user)
	TEST_ASSERT_NOTEQUAL(spell.process(), PROCESS_KILL, "Действующее кольцо не останавливается вместе с перезарядкой.")
	spell.process()
	TEST_ASSERT_EQUAL(round(victim.getFireLoss(), DAMAGE_PRECISION), 4, "Кольцо наносит урон повторно.")
	var/visible_flame = FALSE
	for(var/obj/effect/temp_visual/visual in nearby)
		if(visual.icon == 'icons/effects/turf_fire.dmi' && visual.icon_state == "red_big")
			visible_flame = TRUE
	TEST_ASSERT(visible_flame, "Клятва показывает огонь без горючего газа.")
	spell.remove()
	TEST_ASSERT_EQUAL(spell.process(), PROCESS_KILL, "Закончившееся кольцо без перезарядки прекращает обработку.")
	TEST_ASSERT_NULL(spell.current_user, "Завершение освобождает владельца кольца.")

/// Полный запуск домена создаёт поле 7×7 и повторно отмечает врага после активации метки.
/datum/unit_test/heretic_domain_cast_area/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(center.x + 3, center.y, center.z))
	var/obj/effect/proc_holder/spell/aoe_turf/domain_expansion/spell = allocate(/obj/effect/proc_holder/spell/aoe_turf/domain_expansion)
	spell.cast(list(center), user)
	var/obj/effect/domain_expansion/domain = spell.active_domain
	TEST_ASSERT_NOTNULL(domain, "После сосредоточения появляется домен.")
	TEST_ASSERT_EQUAL(length(domain.field_turfs), 49, "Без преград домен покрывает все 49 клеток.")
	TEST_ASSERT_EQUAL(length(domain.boundary), 24, "Граница окружает всю область 7×7.")
	domain.process()
	var/datum/status_effect/eldritch/void/mark = victim.has_status_effect(/datum/status_effect/eldritch/void)
	TEST_ASSERT_NOTNULL(mark, "Домен отмечает врага на внешней клетке.")
	TEST_ASSERT(victim.has_movespeed_modifier(REF(domain)), "Домен замедляет врага на внешней клетке.")
	mark.on_effect()
	domain.process()
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/eldritch/void), "Следующая обработка накладывает новую метку.")
	qdel(domain)
	TEST_ASSERT_NULL(spell.active_domain, "Удаление домена освобождает заклинание.")
	TEST_ASSERT(!victim.has_movespeed_modifier(REF(domain)), "Удаление домена снимает замедление поля.")

/// Оба червя вырастают ровно на один связанный сегмент за порцию пищи.
/datum/unit_test/heretic_armsy_growth/Run()
	for(var/worm_type in list(/mob/living/simple_animal/hostile/eldritch/armsy, /mob/living/simple_animal/hostile/eldritch/armsy/prime))
		var/mob/living/simple_animal/hostile/eldritch/armsy/worm = allocate(worm_type, run_loc_floor_bottom_left, FALSE)
		TEST_ASSERT_NULL(worm.back, "Одиночный сегмент создаётся без цепочки.")
		worm.current_stacks = worm.stacks_to_grow - 1
		worm.heal()
		TEST_ASSERT_NOTNULL(worm.back, "Пища должна создавать хвост без ошибки аргументов New.")
		TEST_ASSERT_EQUAL(worm.back.type, worm_type, "Хвост сохраняет разновидность червя.")
		TEST_ASSERT_EQUAL(worm.back.front, worm, "Новый хвост связан с прежним сегментом.")
		TEST_ASSERT_NULL(worm.back.back, "Рост не порождает дополнительную начальную цепочку.")
		TEST_ASSERT_EQUAL(worm.current_stacks, 0, "Пища расходуется на один сегмент.")
		worm.back.current_stacks = worm.back.stacks_to_grow - 1
		worm.heal()
		TEST_ASSERT_EQUAL(worm.get_length(), 3, "Следующая порция удлиняет именно конец цепочки.")

/// Удаление многорукой оболочки выпускает все тела и снимает их стазис.
/datum/unit_test/heretic_armsy_releases_contents/Run()
	var/mob/living/simple_animal/hostile/eldritch/armsy/shell = allocate(/mob/living/simple_animal/hostile/eldritch/armsy, run_loc_floor_bottom_left, FALSE)
	var/list/bodies = list()
	for(var/index in 1 to 2)
		var/mob/living/carbon/human/body = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
		body.forceMove(shell)
		body.apply_status_effect(STATUS_EFFECT_STASIS, STASIS_ASCENSION_EFFECT)
		bodies += body
	qdel(shell)
	for(var/mob/living/body as anything in bodies)
		TEST_ASSERT(!QDELETED(body), "Удаление оболочки не удаляет ни одно из тел.")
		TEST_ASSERT_EQUAL(get_turf(body), run_loc_floor_bottom_left, "Каждое тело возвращается на пол.")
		TEST_ASSERT(!body.has_status_effect(STATUS_EFFECT_STASIS), "Каждое освобождённое тело выходит из стазиса.")
