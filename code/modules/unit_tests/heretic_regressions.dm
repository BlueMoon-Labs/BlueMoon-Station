/// Возвращение без старого тела восстанавливает знания, а снятие роли без тела освобождает заклинания.
/datum/unit_test/heretic_bodyless_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/datum/mind/soul = heretic.owner
	var/mob/living/old_body = soul.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	heretic.gain_knowledge(/datum/eldritch_knowledge/cold_snap)
	heretic.gain_knowledge(/datum/eldritch_knowledge/flame_immunity)
	var/datum/eldritch_knowledge/spell/basic/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/effect/proc_holder/spell/old_grasp = grasp.granted_spell
	old_body.mind = null
	soul.current = null
	qdel(old_body)
	var/mob/living/new_body = allocate(/mob/living/carbon/human)
	soul.transfer_to(new_body, TRUE)
	TEST_ASSERT_EQUAL(soul.current, new_body, "Перенос завершился в новом теле.")
	TEST_ASSERT(HAS_TRAIT(new_body, TRAIT_NOBREATH) && HAS_TRAIT(new_body, TRAIT_RESISTCOLD) && HAS_TRAIT(new_body, TRAIT_NOFIRE), "Новое тело получило пассивы Пустоты и Пепла.")
	TEST_ASSERT(QDELETED(old_grasp) && !QDELETED(grasp.granted_spell), "Заклинание заменено при переносе без старого тела.")
	var/obj/effect/proc_holder/spell/new_grasp = grasp.granted_spell
	new_body.mind = null
	soul.current = null
	qdel(new_body)
	heretic.clear_heretic()
	TEST_ASSERT(heretic.role_removed && QDELETED(new_grasp), "Снятие бестелесной роли завершает очистку знаний.")

/// Проверки защиты не расходуют зарядов, а атаки учитывают обычную и психическую антимагию.
/datum/unit_test/heretic_legacy_antimagic/Run()
	var/mob/living/victim = allocate(/mob/living/carbon/human)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(victim.anti_magic_check(), "Старый вызов продолжает блокировать магию.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Старый вызов не начал расходовать заряды.")
	TEST_ASSERT(!heretic_can_affect(null, victim, chargecost = 0), "Проба еретика видит защиту.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проба не расходует заряды.")
	TEST_ASSERT(!heretic_can_affect(null, victim), "Атака еретика блокируется.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Атака еретика расходует один заряд.")
	qdel(protection)
	var/obj/item/clothing/head/foilhat/hat = allocate(/obj/item/clothing/head/foilhat)
	var/mob/living/carbon/human/human = victim
	TEST_ASSERT(human.equip_to_slot_if_possible(hat, ITEM_SLOT_HEAD), "Шапочка надета на голову.")
	TEST_ASSERT(!heretic_can_affect(null, victim, chargecost = 0), "Шапочка блокирует психическую магию еретика.")
	var/datum/component/anti_magic/psychic = hat.GetComponent(/datum/component/anti_magic)
	TEST_ASSERT_EQUAL(psychic.charges, 6, "Проверка не расходует заряд шапочки.")
	TEST_ASSERT(!heretic_can_affect(null, victim), "Атака также блокируется шапочкой.")
	TEST_ASSERT_EQUAL(psychic.charges, 5, "Настоящая атака расходует один заряд шапочки.")

/// Промах клинка, недоступный сдвиг и повторное касание нити не расходуют защиту.
/datum/unit_test/heretic_combat_probe_charges/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/obj/item/melee/sickly_blade/void/blade = allocate(/obj/item/melee/sickly_blade/void)
	user.a_intent = INTENT_HARM
	blade.force = 0
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(protection.charges, 5, "Удар без урона не расходует защиту от эффектов клинка.")
	blade.force = 22
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(protection.charges, 4, "Реальное ранение расходует один заряд на блокирование эффектов.")
	var/datum/eldritch_knowledge/void_blade_upgrade/blink = allocate(/datum/eldritch_knowledge/void_blade_upgrade)
	COOLDOWN_START(blink, blink_cooldown, 8 SECONDS)
	blink.on_ranged_attack_eldritch_blade(victim, user)
	TEST_ASSERT_EQUAL(protection.charges, 4, "Сдвиг на перезарядке не расходует защиту.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/datum/eldritch_knowledge/base_cosmic/cosmic = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	for(var/crossing in 1 to 3)
		TEST_ASSERT(!cosmic.cross_thread(victim), "Защита блокирует нить созвездия.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Повторные касания нити не расходуют защиту.")
	var/obj/item/heretic_relic/censer/censer = allocate(/obj/item/heretic_relic/censer)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	user.put_in_hands(censer)
	var/datum/component/anti_magic/user_protection = user.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	for(var/check_index in 1 to 3)
		TEST_ASSERT_NULL(censer.get_path(user), "Антимагия не позволяет воспользоваться реликвией.")
	TEST_ASSERT_EQUAL(user_protection.charges, 5, "Проверка реликвии не расходует защиту владельца.")
	qdel(user_protection)
	censer.stored_fire = censer.max_fire
	victim.adjust_fire_stacks(2)
	victim.IgniteMob()
	TEST_ASSERT(!censer.capture_fire(user, victim), "Полная кадильница не забирает пламя.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Полная кадильница не расходует защиту цели.")
	user.dropItemToGround(censer)
	var/obj/item/heretic_relic/suture_needle/needle = allocate(/obj/item/heretic_relic/suture_needle)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_flesh)
	user.put_in_hands(needle)
	TEST_ASSERT(!needle.can_mend(user, victim), "Проверка иглы отклоняет защищённую цель.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Проверка иглы не расходует защиту цели.")

/// Перекрывающиеся потоки одного заклинания проверяют антимагию один раз.
/datum/unit_test/heretic_fire_line_shared_protection/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/obj/effect/proc_holder/spell/pointed/nightwatchers_rite/spell = allocate(/obj/effect/proc_holder/spell/pointed/nightwatchers_rite)
	var/list/magic_checks = list()
	for(var/stream in 1 to 5)
		spell.fire_line(heretic.owner.current, list(get_turf(victim)), magic_checks)
	TEST_ASSERT_EQUAL(protection.charges, 4, "Пять потоков одного каста расходуют один заряд.")
	TEST_ASSERT_EQUAL(victim.getFireLoss(), 0, "Защита действует на все потоки каста.")

/// Истощённые тела не принимаются ни до обращения, ни после снятия роли слуги.
/datum/unit_test/heretic_flesh_exhausted_body/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NULL(heretic_conversion_block_reason(victim), "Обычное тело допускает обращение.")
	victim.become_husk("test_burn")
	TEST_ASSERT(heretic_conversion_block_reason(victim), "Обгоревшее тело не подходит для полного восстановления через обращение.")
	victim.cure_husk(list("test_burn"))
	var/datum/mind/soul = new
	allocated += soul
	soul.current = victim
	victim.mind = soul
	var/datum/antagonist/heretic_monster/ghoul/servant = allocate(/datum/antagonist/heretic_monster/ghoul)
	servant.owner = soul
	soul.antag_datums = list(servant)
	servant.silent = TRUE
	servant.health_cap = 50
	servant.apply_innate_effects(victim)
	servant.remove_innate_effects(victim)
	TEST_ASSERT(!HAS_TRAIT(victim, TRAIT_HUSK), "Снятие роли убирает принадлежащий ей внешний эффект.")
	TEST_ASSERT(heretic_conversion_block_reason(victim), "Снятие роли не позволяет повторно использовать ту же плоть.")

/// Отказ шкафа восстанавливает замок и сохраняет запас ключей.
/datum/unit_test/heretic_lock_failed_opening/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_lock)
	var/datum/eldritch_knowledge/base_lock/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_lock)
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, get_step(user, EAST))
	closet.locked = TRUE
	var/mob/living/blocker = allocate(/mob/living/carbon/human, get_turf(closet))
	blocker.anchored = TRUE
	var/resource_before = knowledge.combat_resource
	TEST_ASSERT(!knowledge.open_lock(closet, user, TRUE), "Тяжёлый моб мешает открыть шкаф.")
	TEST_ASSERT(closet.locked && !closet.opened, "Отказ оставляет шкаф закрытым и запертым.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, resource_before, "Отказ не даёт ключ.")
	TEST_ASSERT(COOLDOWN_FINISHED(knowledge, resource_harvest), "Отказ не начинает перезарядку добычи ключа.")
	qdel(blocker)
	TEST_ASSERT(knowledge.open_lock(closet, user, TRUE), "После удаления препятствия шкаф открывается.")
	TEST_ASSERT(!closet.locked && closet.opened, "Успешное открытие снимает замок.")

/// Проклятие резервирует предметы с отпечатками на руне, но не соседние вещи.
/datum/unit_test/heretic_curse_fingerprint_anchors/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/obj/item/melee/sickly_blade/blade = allocate(/obj/item/melee/sickly_blade, get_step(user, WEST))
	var/obj/item/radio/headset/headset = allocate(/obj/item/radio/headset)
	var/obj/item/pen/ingredient = allocate(/obj/item/pen)
	blade.fingerprints = list()
	blade.fingerprints[md5(user.dna.uni_identity)] = TRUE
	headset.fingerprints = list()
	headset.fingerprints[md5(victim.dna.uni_identity)] = TRUE
	var/datum/eldritch_knowledge/curse/curse = allocate(/datum/eldritch_knowledge/curse)
	curse.required_atoms = list(/obj/item/pen)
	heretic.researched_knowledge[curse.type] = curse
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch/big)
	var/list/selected = list()
	TEST_ASSERT(rune.select_recipe_atoms(curse, list(blade, headset, ingredient), selected, list(), user), "Предмет жертвы найден после собственного клинка.")
	TEST_ASSERT(curse.fingerprints[md5(victim.dna.uni_identity)], "Объединённый список содержит отпечатки жертвы.")
	TEST_ASSERT(rune.reserve_atoms(selected), "Якоря резервируются вместе с компонентом.")
	rune.ritual_user = user
	TEST_ASSERT(rune.ritual_valid(user, curse), "Повторная проверка сохраняет якоря и отпечатки.")
	TEST_ASSERT(!(blade in selected), "Соседний клинок не стал якорем проклятия.")
	blade.forceMove(user)
	TEST_ASSERT(rune.ritual_valid(user, curse), "Поднятие соседней вещи не прерывает обряд.")
	headset.forceMove(get_step(get_turf(headset), EAST))
	TEST_ASSERT(!rune.ritual_valid(user, curse), "Перенос якоря прерывает обряд.")
	rune.release_atoms()
	curse.cleanup_atoms(selected)
	TEST_ASSERT(!QDELETED(blade) && !QDELETED(headset), "Якоря с отпечатками не расходуются.")
	TEST_ASSERT(QDELETED(ingredient), "Компонент рецепта расходуется.")

/// Смена и сброс текущей цели сохраняют историю разных душ даже с одинаковыми именами.
/datum/unit_test/heretic_hunt_assignment_history/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/datum/antagonist/heretic/first = allocate_heretic()
	var/datum/antagonist/heretic/second = allocate_heretic()
	first.owner.current.real_name = "Тестовая цель"
	second.owner.current.real_name = "Тестовая цель"
	heretic.set_hunt_target(first.owner)
	heretic.set_hunt_target(second.owner)
	heretic.set_hunt_target(first.owner)
	heretic.set_hunt_target(null)
	TEST_ASSERT_EQUAL(length(heretic.sac_targetted), 2, "История различает души и не дублирует повторное назначение.")
	TEST_ASSERT(findtext(heretic.roundend_report(), "Тестовая цель"), "Раундэнд показывает имена из истории после сброса цели.")
	TEST_ASSERT(!findtext(heretic.antag_panel(), "Тестовая цель"), "Панель текущей охоты не выдаёт историю за активную цель.")

/// Неудачное затмение сохраняет копии, перезарядку и состояние врагов.
/datum/unit_test/heretic_moon_eclipse_failed_placement/Run()
	var/mob/living/user = make_moon_heretic(run_loc_floor_bottom_left)
	var/datum/eldritch_knowledge/base_moon/knowledge = get_heretic_moon(user)
	TEST_ASSERT(knowledge.create_reflection(user, get_step(user, EAST)), "Первая копия создана.")
	TEST_ASSERT(knowledge.create_reflection(user, get_step(user, NORTH)), "Вторая копия создана.")
	var/list/mob/living/simple_animal/hostile/illusion/heretic_moon/original_reflections = knowledge.reflections.Copy()
	var/obj/machinery/door/airlock/blocker = allocate(/obj/machinery/door/airlock, get_turf(user))
	TEST_ASSERT(!knowledge.valid_reflection_turf(get_turf(user), user), "Закрытый шлюз блокирует место для отражения.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	var/obj/effect/proc_holder/spell/self/heretic_moon/eclipse/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_moon/eclipse)
	spell.charge_counter = 0
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Неудачное размещение возвращает перезарядку.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections & original_reflections), 2, "Старые отражения не удалены.")
	TEST_ASSERT(!user.has_status_effect(/datum/status_effect/heretic_moon_shroud), "Неудача не даёт саван.")
	TEST_ASSERT_EQUAL(victim.confused, 0, "Неудача не ослепляет и не путает врагов.")
	qdel(blocker)
	spell.charge_counter = 0
	spell.cast(list(user), user)
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Успешное затмение расходует перезарядку.")
	TEST_ASSERT_EQUAL(length(knowledge.reflections), knowledge.reflection_limit(), "Замена на пределе сохраняет число копий.")
	TEST_ASSERT(QDELETED(original_reflections[1]), "После создания новой копии удаляется самая старая.")
	TEST_ASSERT(user.has_status_effect(/datum/status_effect/heretic_moon_shroud), "Успешное затмение даёт саван.")

/// Мелкие животные не получают метку и не дают ресурс после удара клинком.
/datum/unit_test/heretic_small_animal_marks/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_ash)
	heretic.gain_knowledge(/datum/eldritch_knowledge/ash_mark)
	var/datum/eldritch_knowledge/base_ash/path = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/datum/eldritch_knowledge/mark = heretic.get_knowledge(/datum/eldritch_knowledge/ash_mark)
	var/mob/living/simple_animal/mouse/mouse = allocate(/mob/living/simple_animal/mouse)
	var/obj/item/melee/sickly_blade/ash/blade = allocate(/obj/item/melee/sickly_blade/ash)
	path.combat_resource = 0
	mark.on_mansus_grasp(mouse, user, TRUE)
	TEST_ASSERT(!mouse.has_status_effect(/datum/status_effect/eldritch/ash), "Хватка не ставит метку на мышь.")
	user.a_intent = INTENT_HARM
	blade.attack(mouse, user)
	TEST_ASSERT_EQUAL(path.combat_resource, 0, "Удар по мыши не даёт уголёк.")

/// Сброс боевого искусства не снимает вознесение и не оставляет уязвимость после его удаления.
/datum/unit_test/heretic_ascension_martial_reset/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/knowledge = allocate(/datum/eldritch_knowledge/final_eldritch)
	knowledge.finished = TRUE
	knowledge.on_body_gain(user)
	var/datum/martial_art/the_sleeping_carp/carp = allocate(/datum/martial_art/the_sleeping_carp)
	TEST_ASSERT(carp.teach(user), "Боевой стиль изучен после вознесения.")
	carp.remove(user)
	user.apply_damage(20, BRUTE, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	user.apply_damage(20, BURN, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	TEST_ASSERT(abs(user.getBruteLoss() - 20 * knowledge.damage_modifier) < 0.01, "Снятие стиля сохраняет защиту от ушибов.")
	TEST_ASSERT(abs(user.getFireLoss() - 20 * knowledge.damage_modifier) < 0.01, "Снятие стиля сохраняет защиту от ожогов.")
	knowledge.on_body_lose(user)
	var/brute_before = user.getBruteLoss()
	var/burn_before = user.getFireLoss()
	user.apply_damage(20, BRUTE, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	user.apply_damage(20, BURN, BODY_ZONE_CHEST, wound_bonus = CANT_WOUND)
	TEST_ASSERT(abs(user.getBruteLoss() - brute_before - 20) < 0.01, "Снятие вознесения не оставляет множитель 1 / 0.75.")
	TEST_ASSERT(abs(user.getFireLoss() - burn_before - 20) < 0.01, "Ожоги также возвращаются к обычному урону.")

/// Внешнее изменение максимума здоровья не мешает снять ограничение слуги.
/datum/unit_test/heretic_servant_health_cap_change/Run()
	var/datum/antagonist/heretic/fixture = allocate_heretic()
	var/mob/living/body = fixture.owner.current
	var/datum/antagonist/heretic_monster/servant = allocate(/datum/antagonist/heretic_monster)
	servant.owner = fixture.owner
	fixture.owner.antag_datums += servant
	servant.health_cap = 50
	body.setMaxHealth(100)
	servant.apply_health_cap(body)
	body.setMaxHealth(60)
	servant.restore_health_cap(body)
	TEST_ASSERT_EQUAL(body.maxHealth, 100, "Частичное внешнее повышение не оставляет тело с урезанным максимумом.")
	servant.apply_health_cap(body)
	body.setMaxHealth(150)
	servant.restore_health_cap(body)
	TEST_ASSERT_EQUAL(body.maxHealth, 150, "Повышение сверх исходного максимума сохраняется.")
	TEST_ASSERT_EQUAL(servant.pre_conversion_max_health, 0, "Запас старого тела очищен для переноса роли.")

/// Мёртвое тело не получает расширенный предел лунных отражений.
/datum/unit_test/heretic_moon_dead_ascension/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_moon)
	var/datum/eldritch_knowledge/base_moon/moon = heretic.get_knowledge(/datum/eldritch_knowledge/base_moon)
	var/datum/eldritch_knowledge/final_eldritch/moon_final/final_knowledge = allocate(/datum/eldritch_knowledge/final_eldritch/moon_final)
	final_knowledge.finished = TRUE
	var/mob/living/user = heretic.owner.current
	user.stat = DEAD
	final_knowledge.on_body_gain(user)
	TEST_ASSERT_NULL(final_knowledge.applied_body, "Общий эффект не применился к мёртвому телу.")
	TEST_ASSERT(!moon.ascension_active, "Лунный предел тоже не применился.")

/// Картовая руна остаётся размером с тайл, ритуальная сохраняет увеличенный масштаб.
/datum/unit_test/heretic_map_rune_scale/Run()
	var/obj/effect/eldritch/huge/map_rune = allocate(/obj/effect/eldritch/huge)
	var/obj/effect/eldritch/big/ritual_rune = allocate(/obj/effect/eldritch/big)
	var/matrix/map_transform = map_rune.transform
	var/matrix/ritual_transform = ritual_rune.transform
	TEST_ASSERT_EQUAL(map_transform.a, 1, "Картовая руна не растягивается по горизонтали.")
	TEST_ASSERT_EQUAL(map_transform.e, 1, "Картовая руна не растягивается по вертикали.")
	TEST_ASSERT_EQUAL(ritual_transform.a, HERETIC_RUNE_SCALE, "Ритуальная руна сохраняет свой масштаб.")

/// Очаг возвращается к открывшимся клеткам и лечит владельца с нулевым жезлом.
/datum/unit_test/heretic_rust_reopened_field/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/obj/effect/heretic_combat_zone/rust/zone = allocate(/obj/effect/heretic_combat_zone/rust, get_turf(user), heretic.owner)
	STOP_PROCESSING(SSprocessing, zone)
	var/turf/first = get_turf(user)
	var/turf/hidden = get_step(user, EAST)
	var/turf/newly_visible = get_step(user, NORTH)
	zone.refresh_boundary(list(first, hidden))
	zone.refresh_boundary(list(first))
	zone.tick_zone(user, list(user))
	TEST_ASSERT(istype(first, /turf/open/floor/plating/rust), "Видимый пол покрывается ржавчиной.")
	TEST_ASSERT(!istype(hidden, /turf/open/floor/plating/rust), "Закрытый пол не затронут.")
	zone.refresh_boundary(list(first, hidden, newly_visible))
	zone.tick_zone(user, list(user))
	TEST_ASSERT(istype(hidden, /turf/open/floor/plating/rust), "Повторно открывшийся пол не потерян.")
	TEST_ASSERT(istype(newly_visible, /turf/open/floor/plating/rust), "Пол, закрытый при создании очага, тоже обрабатывается.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	user.put_in_hands(rod)
	TEST_ASSERT(user.check_magic_resistance(chargecost = 0), "Владелец действительно защищён нулевым жезлом.")
	user.adjustBruteLoss(10)
	zone.tick_zone(user, list(user))
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 7, "Жезл не отключает лечение самого владельца.")
