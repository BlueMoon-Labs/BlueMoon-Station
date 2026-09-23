/// Сквозняк наносит урон сразу, а часы остаются на выбранной клетке.
/datum/unit_test/heretic_sand_wind_and_dodge/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_wind)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/target = get_step(center, EAST)
	var/mob/living/staying = allocate(/mob/living/carbon/human, target)
	var/mob/living/dodging = allocate(/mob/living/carbon/human, target)
	TEST_ASSERT(sand.wind(user, target), "Бесплатный Сквозняк работает сразу.")
	TEST_ASSERT(abs(staying.getBruteLoss() - 28) <= DAMAGE_PRECISION, "Первая атака наносит 28 ушибов без подготовки.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 1, "В конце линии появляются одни часы.")
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.hourglasses[1]
	TEST_ASSERT_EQUAL(get_turf(hourglass), target, "Часы обозначают конкретную клетку.")
	dodging.forceMove(get_step(target, NORTH))
	hourglass.resolve()
	TEST_ASSERT(abs(staying.getBruteLoss() - 60) <= DAMAGE_PRECISION, "Оставшийся получает ещё 32 ушиба.")
	TEST_ASSERT(abs(dodging.getBruteLoss() - 28) <= DAMAGE_PRECISION, "Незапомненная вторая цель избегает часов обычным шагом.")
	TEST_ASSERT(QDELETED(hourglass), "Разрешённые часы удаляются.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 0, "Завершение освобождает лимит.")

/// Осыпь имеет полезный первый эффект и безопасные диагонали после него.
/datum/unit_test/heretic_sand_release/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(center, NORTHEAST))
	TEST_ASSERT(sand.release(user), "Осыпь доступна с начальным запасом.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Первая осыпь поражает соседние диагонали.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 4, "Предупреждения стоят на четырёх соседних клетках.")
	for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in sand.hourglasses.Copy())
		hourglass.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 20) <= DAMAGE_PRECISION, "На диагонали нет отложенного урона.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Собственная осыпь не ранит владельца.")

/// Защита, контейнеры и новый заслон блокируют отложенный удар.
/datum/unit_test/heretic_sand_protection_and_wall/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/target = get_step(center, EAST)
	var/mob/living/protected = allocate(/mob/living/carbon/human, target)
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/datum/antagonist/heretic/ally = allocate_heretic(target)
	var/obj/item/storage/box/closet = allocate(/obj/item/storage/box, target)
	var/mob/living/hidden = allocate(/mob/living/carbon/human, closet)
	var/mob/living/dead = allocate(/mob/living/carbon/human, target)
	dead.stat = DEAD
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(target, sand)
	TEST_ASSERT(hourglass, "Часы создаются до проверки антимагии.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Предупреждение не тратит заряд защиты.")
	hourglass.resolve()
	TEST_ASSERT_EQUAL(protection.charges, 4, "Один удар тратит один заряд.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия блокирует урон.")
	TEST_ASSERT_EQUAL(ally.owner.current.getBruteLoss(), 0, "Союзник защищён.")
	TEST_ASSERT_EQUAL(hidden.getBruteLoss(), 0, "Часы не поражают содержимое контейнера.")
	TEST_ASSERT_EQUAL(dead.getBruteLoss(), 0, "Часы не бьют трупы.")
	var/turf/far_target = get_step(target, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, far_target)
	hourglass = sand.create_hourglass(far_target, sand)
	TEST_ASSERT(hourglass, "Часы создаются через открытую линию.")
	var/obj/structure/closet/crate/blocker = allocate(/obj/structure/closet/crate, target)
	TEST_ASSERT(blocker.density, "Закрытый ящик образует преграду.")
	hourglass.resolve()
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Новая преграда отменяет подготовленный удар.")

/// Разные часы используют общий предел урона и расхода антимагии.
/datum/unit_test/heretic_sand_clock_hit_limit/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/obj/structure/heretic_sand_hourglass/first = sand.create_hourglass(get_turf(victim), sand)
	TEST_ASSERT(first, "Первый таймер создан.")
	TEST_ASSERT(!sand.create_hourglass(get_turf(victim), sand), "Два таймера не занимают одну клетку.")
	first.resolve()
	var/obj/structure/heretic_sand_hourglass/second = sand.create_hourglass(get_turf(victim), sand)
	TEST_ASSERT(second, "После удара слот освобождён.")
	second.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 32) <= DAMAGE_PRECISION, "Мгновенное повторение не удваивает урон.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Повторный таймер не тратит ещё один заряд в том же интервале.")

/// Нулевой жезл разрушает часы без взрыва.
/datum/unit_test/heretic_sand_nullrod/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(get_turf(victim), sand)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, victim)
	TEST_ASSERT(hourglass, "Часы установлены рядом с защищающимся.")
	hourglass.attackby(rod, victim)
	TEST_ASSERT(QDELETED(hourglass), "Нулевой жезл гасит часы.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Разрушение не вызывает взрыв.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 0, "Разрушение освобождает место.")

/// Неизученная магия, чужое тело и пустой запас отклоняются на сервере.
/datum/unit_test/heretic_sand_authority/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/stranger = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/turf/target = get_step(user, EAST)
	TEST_ASSERT(!sand.release(stranger), "Чужое тело не вызывает Осыпь.")
	TEST_ASSERT(!sand.wind(user, target), "Сквозняк требует знания.")
	TEST_ASSERT(!sand.step_through(user, target), "Пересыпание требует знания.")
	TEST_ASSERT(!sand.burial(user, target), "Погребение требует знания.")
	TEST_ASSERT(!sand.burial(user, target, final_cast = TRUE), "Последний полдень требует вознесения.")
	TEST_ASSERT_EQUAL(sand.combat_resource, initial(sand.combat_resource), "Отказы не расходуют песок.")
	sand.combat_resource = 0
	TEST_ASSERT(!sand.release(user), "Осыпь не расходует отсутствующий песок.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 0, "Отказы не оставляют часов.")

/// Усиленный клинок сохраняет предупреждение новых часов и ускоряет зрелые.
/datum/unit_test/heretic_sand_blade_warning/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_upgrade)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_upgrade/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/sand_upgrade)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(get_turf(victim), sand)
	TEST_ASSERT(hourglass, "Часы существуют до удара.")
	upgrade.on_eldritch_blade(victim, user, TRUE, null)
	TEST_ASSERT(!QDELETED(hourglass), "Свежие часы не взрываются без предупреждения.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 8) <= DAMAGE_PRECISION, "Первый удар добавляет только урон усиления.")
	hourglass.created_at = world.time - 0.6 SECONDS
	upgrade.on_eldritch_blade(victim, user, TRUE, null)
	TEST_ASSERT(QDELETED(hourglass), "Клинок ускоряет часы после предупреждения.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 48) <= DAMAGE_PRECISION, "Два усиления и одни часы наносят 48 ушибов.")

/// Пересыпание меняет позицию без лечения и сохраняет стены полезными.
/datum/unit_test/heretic_sand_step/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_step)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	user.adjustBruteLoss(20)
	var/turf/target = get_step(get_step(center, EAST), EAST)
	var/obj/structure/closet/crate/blocker = allocate(/obj/structure/closet/crate, get_step(center, EAST))
	TEST_ASSERT(!sand.step_through(user, target), "Ящик блокирует рывок.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 2, "Неудачный рывок не расходует песок.")
	qdel(blocker)
	TEST_ASSERT(sand.step_through(user, target), "По свободной линии рывок проходит.")
	TEST_ASSERT_EQUAL(get_turf(user), target, "Тело достигает выбранной клетки.")
	TEST_ASSERT(abs(user.getBruteLoss() - 20) <= DAMAGE_PRECISION, "Рывок не возвращает здоровье.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 1, "Успешный рывок стоит единицу песка.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 1, "На старте остаются часы.")
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.hourglasses[1]
	TEST_ASSERT_EQUAL(get_turf(hourglass), center, "Часы отмечают именно прежнюю позицию.")

/// Реликвия возвращает один раз к видимой точке и не лечит владельца.
/datum/unit_test/heretic_sand_relic_return/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_relic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/sand_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Обряд создаёт личные часы.")
	var/obj/item/heretic_path_relic/sand_relic/relic = recipe.new_path_relic_ref.resolve()
	allocated += relic
	TEST_ASSERT(!recipe.on_finished_recipe(user, list(), center), "Нельзя создать вторую реликвию.")
	TEST_ASSERT(!relic.turn_hourglass(user), "Часы на полу не работают.")
	user.put_in_hands(relic)
	TEST_ASSERT(relic.turn_hourglass(user), "Часы в руке оставляют точку возврата.")
	var/obj/structure/heretic_sand_anchor/anchor = sand.anchor
	TEST_ASSERT(anchor, "Возврат имеет видимый разрушаемый объект.")
	user.forceMove(get_step(center, EAST))
	user.adjustBruteLoss(23)
	TEST_ASSERT(relic.turn_hourglass(user), "Повторное применение возвращает владельца.")
	TEST_ASSERT_EQUAL(get_turf(user), center, "Возврат достигает сохранённой клетки.")
	TEST_ASSERT(abs(user.getBruteLoss() - 23) <= DAMAGE_PRECISION, "Повреждения сохраняются.")
	TEST_ASSERT(QDELETED(anchor), "Успешный возврат удаляет точку.")
	TEST_ASSERT(!relic.turn_hourglass(user), "Перезарядка запрещает немедленно сохранить следующую точку.")

/// Потеря знания и смерть очищают связанные объекты и метки.
/datum/unit_test/heretic_sand_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_wind)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_mark)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/spell/sand_wind/wind = heretic.get_knowledge(/datum/eldritch_knowledge/spell/sand_wind)
	var/datum/eldritch_knowledge/sand_mark/mark = heretic.get_knowledge(/datum/eldritch_knowledge/sand_mark)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT(sand.wind(user, get_turf(victim)), "Изученное заклинание ставит часы.")
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.hourglasses[1]
	wind.on_body_lose(user)
	TEST_ASSERT(QDELETED(hourglass), "Потеря конкретного знания удаляет его часы.")
	TEST_ASSERT(mark.on_mansus_grasp(victim, user, TRUE, null), "Метка накладывается до смерти.")
	var/datum/status_effect/eldritch/sand/effect = victim.has_status_effect(/datum/status_effect/eldritch/sand)
	hourglass = sand.create_hourglass(get_turf(victim), sand)
	var/obj/structure/heretic_sand_anchor/anchor = new(get_turf(user), sand)
	user.stat = DEAD
	sand.on_death(user)
	TEST_ASSERT(QDELETED(hourglass) && QDELETED(anchor) && QDELETED(effect), "Смерть удаляет часы, точку возврата и метку.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses) + length(sand.marks), 0, "После смерти списки пусты.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 0, "Смерть обнуляет запас.")

/// Переселение передаёт прогресс, удаляя способности и часы старого тела.
/datum/unit_test/heretic_sand_body_transfer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	var/mob/living/user = heretic.owner.current
	heretic.apply_innate_effects(user)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_sustain)
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_sustain/passive = heretic.get_knowledge(/datum/eldritch_knowledge/sand_sustain)
	passive.passive_level = 3
	passive.on_passive_upgrade(user)
	TEST_ASSERT_EQUAL(sand.combat_resource_max, 7, "Третья ступень пассивки даёт ёмкость семь.")
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(get_step(user, EAST), sand)
	var/obj/structure/heretic_sand_anchor/anchor = new(get_turf(user), sand)
	var/obj/effect/proc_holder/spell/old_power = sand.combat_power
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	heretic.owner.transfer_to(new_body, TRUE)
	TEST_ASSERT_EQUAL(sand.sand_body, new_body, "Знание привязано к новому телу.")
	TEST_ASSERT(QDELETED(hourglass) && QDELETED(anchor) && QDELETED(old_power), "Старые часы, возврат и способность удалены.")
	TEST_ASSERT(sand.combat_power && sand.combat_power != old_power, "Новое тело получает новую способность.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 2, "Переселение сохраняет запас без восстановления.")
	TEST_ASSERT_EQUAL(sand.combat_resource_max, 7, "Пассивное улучшение следует за разумом.")
	TEST_ASSERT(!sand.can_use(user), "Прежнее тело больше не владеет песком.")

/// Настоящий таймер завершает отсчёт и наносит урон.
/datum/unit_test/heretic_sand_timer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.anchored = TRUE
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(get_turf(victim), sand)
	TEST_ASSERT(hourglass, "Таймер создаётся штатным вызовом.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "До истечения времени урона нет.")
	TEST_ASSERT(wait_for_qdeleted(hourglass, 4 SECONDS), "Часы разрешаются настоящим таймером.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 32) <= DAMAGE_PRECISION, "Таймер наносит обещанный урон.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 0, "После таймера слот свободен.")

/// Реликвия однократно продлевает выбранные часы за песок, сохраняя записанную цель.
/datum/unit_test/heretic_sand_delayed_clock/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_relic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/sand_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Создаётся реликвия Песка.")
	var/obj/item/heretic_path_relic/sand_relic/relic = recipe.new_path_relic_ref.resolve()
	allocated += relic
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	victim.anchored = TRUE
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(get_turf(victim), sand)
	TEST_ASSERT(hourglass.record_target(victim), "Часы сохраняют цель до изменения отсчёта.")
	var/expiry_before = hourglass.expires_at
	TEST_ASSERT(!relic.delay_hourglass(user, hourglass), "Реликвия на полу не меняет время.")
	user.put_in_hands(relic)
	sand.combat_resource = 0
	TEST_ASSERT(!relic.delay_hourglass(user, hourglass), "Без песка задержка недоступна.")
	TEST_ASSERT_EQUAL(hourglass.expires_at, expiry_before, "Неудачная задержка сохраняет прежний срок.")
	sand.combat_resource = 2
	TEST_ASSERT(relic.afterattack(hourglass, user, FALSE), "Щелчок реликвией продлевает выбранные часы.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 1, "Задержка стоит единицу песка.")
	TEST_ASSERT_EQUAL(hourglass.expires_at, expiry_before + 1.5 SECONDS, "Продление ограничено полутора секундами.")
	TEST_ASSERT_EQUAL(hourglass.recorded_second?.owner, victim, "Задержка не теряет записанную цель.")
	TEST_ASSERT(!relic.delay_hourglass(user, hourglass), "Повторная задержка тех же часов запрещена.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 1, "Повторная попытка не расходует песок.")
	sleep(1.6 SECONDS)
	TEST_ASSERT(!QDELETED(hourglass) && victim.getBruteLoss() == 0, "Старый таймер не взрывает продлённые часы.")
	TEST_ASSERT(wait_for_qdeleted(hourglass, 3 SECONDS), "Продлённые часы всё равно разрешаются таймером.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 32) <= DAMAGE_PRECISION, "Задержка не меняет урон часов.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_sand_recall), "После удара запись шага очищена.")

/// Сквозняк запоминает только противника на выбранном конце линии.
/datum/unit_test/heretic_sand_wind_endpoint/Run()
	var/turf/center = get_step(run_loc_floor_bottom_left, NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_wind)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/middle = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/turf/destination = get_step(get_step(middle, EAST), EAST)
	var/mob/living/endpoint = allocate(/mob/living/carbon/human, destination)
	TEST_ASSERT(sand.wind(user, destination), "Сквозняк проходит через две цели.")
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.hourglasses[1]
	TEST_ASSERT(middle.getBruteLoss() > 0 && endpoint.getBruteLoss() > 0, "Обе цели получают удар линии.")
	TEST_ASSERT_EQUAL(hourglass.recorded_second?.owner, endpoint, "Часы запоминают только цель на выбранной клетке.")
	TEST_ASSERT(!middle.has_status_effect(/datum/status_effect/heretic_sand_recall), "Промежуточная цель не получает возврат.")
	qdel(hourglass)
	endpoint.forceMove(get_step(destination, NORTH))
	TEST_ASSERT(sand.wind(user, destination), "Можно выбрать пустой конец линии.")
	hourglass = sand.hourglasses[1]
	TEST_ASSERT_NULL(hourglass.recorded_second, "Пустой конец линии не записывает промежуточную цель.")

/// Стол не закрывает Сквозняк, а плотная машина закрывает.
/datum/unit_test/heretic_sand_wind_over_table/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_wind)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/target = locate(user.x + 3, user.y, user.z)
	var/mob/living/victim = allocate(/mob/living/carbon/human, target)
	allocate(/obj/structure/table, locate(user.x + 1, user.y, user.z))
	TEST_ASSERT(sand.wind(user, target), "Сквозняк проходит над столом.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 28) <= DAMAGE_PRECISION, "Цель за столом получает удар.")
	var/obj/machinery/hydroponics/machine = allocate(/obj/machinery/hydroponics, locate(user.x + 2, user.y, user.z))
	TEST_ASSERT(machine.density, "Лоток гидропоники плотный.")
	TEST_ASSERT(!sand.line_clear(user, target), "Плотная машина по-прежнему закрывает линию.")

/// Погребение переполняет предел, убирая самые старые часы вне своего поля.
/datum/unit_test/heretic_sand_burial_replaces_old/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_burial)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/list/old_hourglasses = list()
	for(var/direction in list(NORTH, EAST, SOUTH))
		var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(get_step(center, direction), sand)
		TEST_ASSERT_NOTNULL(hourglass, "Старые часы стоят вне клеток нового поля.")
		old_hourglasses += hourglass
	sand.combat_resource = 4
	TEST_ASSERT(sand.burial(user, center), "Погребение не отказывает из-за часов, оставшихся на поле.")
	TEST_ASSERT(length(sand.hourglasses) <= 13, "Общее число часов не превышает предел.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 13, "Новое поле создаётся целиком.")
	for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in old_hourglasses)
		TEST_ASSERT(QDELETED(hourglass), "Старые часы уступили место новому полю.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 2, "Погребение стоит две единицы песка.")

/// Погребение угрожает центру, оставляет проходы и ограничивает число одновременных часов.
/datum/unit_test/heretic_sand_burial_and_limit/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_burial)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/victim = allocate(/mob/living/carbon/human, center)
	sand.combat_resource = 4
	TEST_ASSERT(sand.burial(user, center), "Погребение создаётся вокруг доступной точки.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 13, "Поле включает часы в выбранном центре.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 28) <= DAMAGE_PRECISION, "Первый удар работает сразу в центре.")
	var/mob/living/dodging = allocate(/mob/living/carbon/human, get_step(center, NORTH))
	var/resource_before = sand.combat_resource
	TEST_ASSERT(!sand.release(user), "При полном поле Осыпь отклоняется.")
	TEST_ASSERT_EQUAL(sand.combat_resource, resource_before, "Переполнение не тратит ресурс.")
	TEST_ASSERT(!sand.create_hourglass(get_step(center, NORTH), sand), "Прямое создание также соблюдает лимит.")
	for(var/obj/structure/heretic_sand_hourglass/hourglass as anything in sand.hourglasses.Copy())
		hourglass.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 60) <= DAMAGE_PRECISION, "Остающийся в центре получает отложенный удар.")
	TEST_ASSERT_EQUAL(dodging.getBruteLoss(), 0, "Соседняя клетка остаётся безопасным выходом от часов.")

/// Дальнее Погребение сохраняет полный рисунок часов и возврат с последующим ударом на краю.
/datum/unit_test/heretic_sand_burial_edge
	var/final_cast = FALSE

/datum/unit_test/heretic_sand_burial_edge/ascended
	final_cast = TRUE

/datum/unit_test/heretic_sand_burial_edge/Run()
	var/turf/origin = locate(run_loc_floor_bottom_left.x - 1, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/turf/center = locate(origin.x + 4, origin.y, origin.z)
	var/turf/edge = locate(origin.x + 6, origin.y, origin.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic(origin)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_burial)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	if(final_cast)
		heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/sand_final)
		var/datum/eldritch_knowledge/final_eldritch/sand_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/sand_final)
		heretic.ascended = TRUE
		finale.finished = TRUE
		finale.on_body_gain(user)
	var/mob/living/victim = allocate(/mob/living/carbon/human, edge)
	TEST_ASSERT(!sand.burial(user, edge, final_cast), "Дальность выбора центра остаётся пять клеток.")
	TEST_ASSERT_NULL(sand.create_hourglass(edge, sand), "Отдельные часы нельзя ставить за пределами обычной дальности.")
	TEST_ASSERT(sand.burial(user, center, final_cast), "Погребение достигает выбранной дальней области.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 13, "Дальняя сторона поля не обрезается по дальности выбора центра.")
	var/obj/structure/heretic_sand_hourglass/hourglass = locate() in edge
	TEST_ASSERT_NOTNULL(hourglass, "На краю области за пятью клетками стоят часы.")
	TEST_ASSERT_EQUAL(hourglass.recorded_second?.owner, victim, "Дальние часы запоминают цель.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Первый удар не выходит за собственный радиус.")
	victim.forceMove(get_step(edge, NORTH))
	hourglass.resolve()
	TEST_ASSERT_EQUAL(get_turf(victim), edge, "Дальние часы возвращают запомненную цель.")
	TEST_ASSERT(abs(victim.getBruteLoss() - (final_cast ? 44 : 32)) <= DAMAGE_PRECISION, "Возвращённая цель получает один удар часов.")

/// Вознесение сохраняет полный запас при переселении, а снятие роли гасит силы.
/datum/unit_test/heretic_sand_ascension_and_role_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	var/mob/living/user = heretic.owner.current
	heretic.apply_innate_effects(user)
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/sand_final)
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/final_eldritch/sand_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/sand_final)
	TEST_ASSERT(!sand.burial(user, get_turf(user), final_cast = TRUE), "Одного знания финала без обряда недостаточно.")
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	TEST_ASSERT(sand.ascension_active, "Завершённый обряд включает вознесение.")
	TEST_ASSERT_EQUAL(sand.combat_resource_max, 8, "Вознесение увеличивает вместимость.")
	sand.gain_combat_resource(20)
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	heretic.owner.transfer_to(new_body, TRUE)
	TEST_ASSERT_EQUAL(sand.combat_resource, 8, "Переход тела не обрезает полный вознесённый запас.")
	TEST_ASSERT(sand.ascension_active, "Вознесение применяется к новому телу.")
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(get_step(new_body, WEST), sand)
	var/obj/structure/heretic_sand_anchor/anchor = new(get_turf(new_body), sand)
	var/obj/effect/proc_holder/spell/power = sand.combat_power
	qdel(heretic)
	TEST_ASSERT(QDELETED(sand), "Удаление роли освобождает знание.")
	TEST_ASSERT(QDELETED(hourglass) && QDELETED(anchor) && QDELETED(power), "Удаление роли гасит часы, возврат и действие.")

/// Преграды, истечение срока и запрет телепортации блокируют возврат.
/datum/unit_test/heretic_sand_relic_counterplay/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_relic)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/sand_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Реликвия создана.")
	var/obj/item/heretic_path_relic/sand_relic/relic = recipe.new_path_relic_ref.resolve()
	allocated += relic
	user.put_in_hands(relic)
	TEST_ASSERT(relic.turn_hourglass(user), "Точка сохранена.")
	var/turf/away = get_step(get_step(center, EAST), EAST)
	user.forceMove(away)
	var/obj/structure/closet/crate/blocker = allocate(/obj/structure/closet/crate, get_step(center, EAST))
	TEST_ASSERT(!relic.turn_hourglass(user), "Преграда блокирует возврат.")
	qdel(blocker)
	ADD_TRAIT(user, TRAIT_NO_TELEPORT, "sand_test")
	TEST_ASSERT(!relic.turn_hourglass(user), "Запрет телепортации блокирует возврат.")
	REMOVE_TRAIT(user, TRAIT_NO_TELEPORT, "sand_test")
	sand.anchor.expires_at = world.time
	TEST_ASSERT(!relic.turn_hourglass(user), "Просроченный возврат не проходит до обработки таймера.")
	TEST_ASSERT_EQUAL(get_turf(user), away, "Отказы не перемещают тело.")
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod, user)
	var/obj/structure/heretic_sand_anchor/anchor = sand.anchor
	anchor.attackby(rod, user)
	TEST_ASSERT(QDELETED(anchor), "Нулевой жезл уничтожает точку возврата.")
	TEST_ASSERT_NULL(sand.anchor, "Уничтоженная точка освобождает ссылку владельца.")

/// Очистка пассивки без текущего тела безопасна и не меняет запас другого тела.
/datum/unit_test/heretic_sand_passive_null_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_sustain)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_sustain/passive = heretic.get_knowledge(/datum/eldritch_knowledge/sand_sustain)
	sand.gain_combat_resource(20)
	TEST_ASSERT(!passive.on_body_lose(null), "Без тела очистка не обращается к отсутствующему знанию.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 5, "Очистка без тела не обрезает запас живого владельца.")
	TEST_ASSERT_EQUAL(sand.combat_resource_max, 5, "Очистка без тела сохраняет вместимость живого владельца.")
	TEST_ASSERT(passive.on_body_lose(user), "При наличии текущего тела пассивка снимается.")
	TEST_ASSERT_EQUAL(sand.combat_resource_max, 4, "Настоящее снятие возвращает базовую вместимость.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 4, "Настоящее снятие ограничивает запас новой вместимостью.")
	var/obj/effect/proc_holder/spell/power = sand.combat_power
	heretic.owner.current = null
	qdel(heretic)
	TEST_ASSERT(QDELETED(sand) && QDELETED(passive) && QDELETED(power), "Удаление роли без текущего тела очищает оба знания и способность.")

/// Запомненный шаг возвращается, а дальность, стены, антимагия и разрушение часов спасают цель.
/datum/unit_test/heretic_sand_stolen_second/Run()
	var/turf/center = get_step(run_loc_floor_bottom_left, NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_wind)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/target = get_step(center, EAST)
	for(var/scenario in list("near", "far", "wall", "magic", "no_teleport", "destroy"))
		var/mob/living/victim = allocate(/mob/living/carbon/human, target)
		TEST_ASSERT(sand.wind(user, target), "Сквозняк начинает сценарий [scenario].")
		var/obj/structure/heretic_sand_hourglass/hourglass = sand.hourglasses[1]
		TEST_ASSERT_EQUAL(hourglass.recorded_second?.owner, victim, "Часы запоминают поражённого врага.")
		var/turf/destination = locate(target.x, target.y + (scenario == "far" ? 4 : 2), target.z)
		victim.forceMove(destination)
		var/obj/blocker
		var/datum/component/anti_magic/protection
		if(scenario == "wall")
			blocker = allocate(/obj, get_step(target, NORTH))
			blocker.density = TRUE
		if(scenario == "magic")
			protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 3)
		if(scenario == "no_teleport")
			ADD_TRAIT(victim, TRAIT_NO_TELEPORT, "sand_test")
		if(scenario == "destroy")
			qdel(hourglass)
		else
			hourglass.resolve()
		TEST_ASSERT_EQUAL(get_turf(victim), scenario == "near" ? target : destination, "Возврат учитывает контрмеру [scenario].")
		TEST_ASSERT(abs(victim.getBruteLoss() - (scenario == "near" ? 60 : 28)) <= DAMAGE_PRECISION, "Отложенный урон учитывает контрмеру [scenario].")
		TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_sand_recall), "После исхода связь с часами удалена.")
		if(protection)
			TEST_ASSERT_EQUAL(protection.charges, 2, "Возврат расходует ровно один заряд защиты.")
		QDEL_NULL(blocker)
		qdel(victim)

/// Клинок обрывает записанный шаг, а утрата знания снимает незавершённый возврат.
/datum/unit_test/heretic_sand_recall_blade_and_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_wind)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_upgrade)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_upgrade/upgrade = heretic.get_knowledge(/datum/eldritch_knowledge/sand_upgrade)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/turf/recorded_tile = get_turf(victim)
	sand.wind(user, recorded_tile)
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.hourglasses[1]
	victim.forceMove(get_step(user, NORTHEAST))
	hourglass.created_at = world.time - 0.6 SECONDS
	upgrade.on_eldritch_blade(victim, user, TRUE)
	TEST_ASSERT(QDELETED(hourglass), "Клинок находит часы ушедшего с клетки врага.")
	TEST_ASSERT_EQUAL(get_turf(victim), recorded_tile, "Ускоренный отсчёт возвращает врага.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 68) <= DAMAGE_PRECISION, "Сквозняк, усиление и часы действуют по одному разу.")
	sand.wind(user, recorded_tile)
	hourglass = sand.hourglasses[1]
	qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spell/sand_wind))
	TEST_ASSERT(QDELETED(hourglass), "Утрата знания удаляет часы.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_sand_recall), "Утрата знания убирает предупреждение и возврат.")

/// Дальний рывок и улучшение сбора песка работают без заполнения запаса при изучении.
/datum/unit_test/heretic_sand_mobility_and_harvest/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_step)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/target = locate(user.x + 4, user.y, user.z)
	TEST_ASSERT(sand.step_through(user, target), "Рывок достигает четвёртой клетки.")
	TEST_ASSERT_EQUAL(get_turf(user), target, "Рывок перемещает тело на выбранную клетку.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 1, "Увеличенная дальность не меняет стоимость.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_sustain)
	var/datum/eldritch_knowledge/sand_sustain/sustain = heretic.get_knowledge(/datum/eldritch_knowledge/sand_sustain)
	TEST_ASSERT_EQUAL(sand.combat_resource, 1, "Изучение пассивки не заполняет запас.")
	sustain.passive_level = 3
	sustain.on_passive_upgrade(user)
	sand.harvest(user)
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(sand, resource_harvest) - 3 SECONDS) <= world.tick_lag, "Третья ступень ускоряет боевой сбор до трёх секунд.")
	sustain.on_body_lose(user)
	TEST_ASSERT_EQUAL(sand.harvest_interval, 6 SECONDS, "Снятие пассивки возвращает исходную задержку.")

/datum/unit_test/proc/ascend_sand_fixture()
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(run_loc_floor_bottom_left, WEST))
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/sand_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/final_eldritch/sand_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/sand_final)
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	return list("user" = user, "heretic" = heretic, "finale" = finale)

/datum/unit_test/proc/sand_test_projectile(atom/firer, turf/start, projectile_type = /obj/item/projectile/bullet)
	var/obj/item/projectile/projectile = allocate(projectile_type, start)
	projectile.firer = firer
	projectile.starting = start
	projectile.fired = TRUE
	return projectile

/// Вражеский снаряд в четырёх клетках от вознёсшегося Песка один раз замедляется втрое; свои, мгновенные и дальние снаряды не трогает.
/datum/unit_test/heretic_sand_slowtime/Run()
	var/list/fixture = ascend_sand_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/sand_final/finale = fixture["finale"]
	var/turf/center = get_turf(user)
	var/turf/far_turf = locate(center.x + HERETIC_SAND_SLOW_RADIUS + 1, center.y, center.z)
	var/turf/edge_turf = locate(center.x + HERETIC_SAND_SLOW_RADIUS, center.y, center.z)
	var/turf/near_turf = locate(center.x + 1, center.y, center.z)
	TEST_ASSERT_NOTNULL(user.GetComponent(/datum/component/heretic_sand_slowtime), "Вознесение Песка замедляет время вокруг.")
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, far_turf)
	var/obj/item/projectile/bullet = sand_test_projectile(shooter, far_turf)
	var/speed = bullet.pixels_per_second
	bullet.forceMove(edge_turf)
	TEST_ASSERT(abs(bullet.pixels_per_second - speed / HERETIC_SAND_SLOW_FACTOR) < 0.01, "Пуля в четырёх клетках летит втрое медленнее.")
	TEST_ASSERT(bullet.color, "Замедленная пуля подсвечена песком.")
	bullet.forceMove(near_turf)
	bullet.forceMove(far_turf)
	bullet.forceMove(edge_turf)
	TEST_ASSERT(abs(bullet.pixels_per_second - speed / HERETIC_SAND_SLOW_FACTOR) < 0.01, "Замедление срабатывает один раз на снаряд.")
	var/obj/item/projectile/distant = sand_test_projectile(shooter, far_turf)
	distant.forceMove(locate(far_turf.x, far_turf.y + 1, far_turf.z))
	TEST_ASSERT_EQUAL(distant.pixels_per_second, speed, "Дальше четырёх клеток снаряды не замедляются.")
	var/obj/item/projectile/own = sand_test_projectile(user, far_turf)
	own.forceMove(edge_turf)
	TEST_ASSERT_EQUAL(own.pixels_per_second, speed, "Собственные выстрелы не замедляются.")
	var/obj/item/projectile/instant = sand_test_projectile(shooter, far_turf)
	instant.hitscan = TRUE
	instant.forceMove(edge_turf)
	TEST_ASSERT_EQUAL(instant.pixels_per_second, speed, "Мгновенный луч замедлить нельзя.")
	var/obj/item/projectile/flying = allocate(/obj/item/projectile/bullet, locate(center.x + HERETIC_SAND_SLOW_RADIUS + 2, center.y + 1, center.z))
	flying.firer = shooter
	flying.fire(270)
	var/steps = 0
	while(!QDELETED(flying) && get_dist(flying, center) > HERETIC_SAND_SLOW_RADIUS && steps++ < world.icon_size * 2)
		TEST_ASSERT_EQUAL(flying.pixels_per_second, speed, "До границы поля пуля летит с прежней скоростью.")
		flying.pixel_move(1)
	TEST_ASSERT(!QDELETED(flying) && get_dist(flying, center) == HERETIC_SAND_SLOW_RADIUS, "Выпущенная пуля долетает до границы поля.")
	TEST_ASSERT(abs(flying.pixels_per_second - speed / HERETIC_SAND_SLOW_FACTOR) < 0.01, "Пуля в настоящем полёте замедляется на границе поля.")
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_sand_slowtime), "Потеря тела снимает замедление.")
	var/obj/item/projectile/late = sand_test_projectile(shooter, far_turf)
	late.forceMove(edge_turf)
	TEST_ASSERT_EQUAL(late.pixels_per_second, speed, "Без вознесения снаряды летят как обычно.")

/// Слабость замедления: удар оружием в упор наносит полный урон, осмотр называет ближний бой.
/datum/unit_test/heretic_sand_slowtime_weakness/Run()
	var/list/fixture = ascend_sand_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/item/weapon = allocate(/obj/item)
	weapon.force = 20
	weapon.damtype = BRUTE
	user.attacked_by(weapon, attacker)
	var/expected = weapon.force * HERETIC_ASCENDED_DAMAGE_MOD
	TEST_ASSERT(abs(user.getBruteLoss() - expected) < 1, "Удар в упор не замедляется: ожидалось [expected], получено [user.getBruteLoss()].")
	var/list/examine_lines = list()
	SEND_SIGNAL(user, COMSIG_PARENT_EXAMINE, attacker, examine_lines)
	TEST_ASSERT(findtext(jointext(examine_lines, " "), "Ближний бой"), "Осмотр называет слабость замедления.")

/// Пуля, вошедшая в поле посреди прохода SSprojectiles, замедляется уже в этом проходе.
/datum/unit_test/heretic_sand_slowtime_same_pass/Run()
	var/list/fixture = ascend_sand_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/turf/center = get_turf(user)
	var/turf/start = locate(center.x + HERETIC_SAND_SLOW_RADIUS + 2, center.y + 1, center.z)
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, locate(center.x, center.y + 2, center.z))
	var/obj/item/projectile/bullet = allocate(/obj/item/projectile/bullet, start)
	bullet.firer = shooter
	var/speed = bullet.pixels_per_second
	bullet.fire(270)
	var/edge_x = (center.x + HERETIC_SAND_SLOW_RADIUS) * world.icon_size
	while(!QDELETED(bullet) && bullet.trajectory.x - edge_x > world.icon_size / 2)
		bullet.pixel_move(1)
	TEST_ASSERT(!QDELETED(bullet) && get_dist(bullet, center) == HERETIC_SAND_SLOW_RADIUS + 1, "Пуля стоит у самой границы поля.")
	TEST_ASSERT_EQUAL(bullet.pixels_per_second, speed, "До поля пуля не замедлена.")
	var/full_pass = world.icon_size
	var/start_x = bullet.trajectory.x
	bullet.process((full_pass + 1) / speed)
	var/travelled = start_x - bullet.trajectory.x
	TEST_ASSERT(get_dist(bullet, center) == HERETIC_SAND_SLOW_RADIUS, "За проход пуля входит в поле.")
	TEST_ASSERT(abs(bullet.pixels_per_second - speed / HERETIC_SAND_SLOW_FACTOR) < 0.01, "Вошедшая пуля замедлена.")
	TEST_ASSERT(travelled > 0 && travelled < full_pass, "Замедление действует в том же проходе: пуля прошла [travelled] пикселей из [full_pass].")

/// Выход из шкафа на ту же клетку снова включает поле замедления.
/datum/unit_test/heretic_sand_slowtime_container/Run()
	var/list/fixture = ascend_sand_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/turf/center = get_turf(user)
	var/turf/far_turf = locate(center.x + HERETIC_SAND_SLOW_RADIUS + 1, center.y, center.z)
	var/turf/edge_turf = locate(center.x + HERETIC_SAND_SLOW_RADIUS, center.y, center.z)
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, far_turf)
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, center)
	user.forceMove(closet)
	var/obj/item/projectile/hidden = sand_test_projectile(shooter, far_turf)
	var/speed = hidden.pixels_per_second
	hidden.forceMove(edge_turf)
	TEST_ASSERT_EQUAL(hidden.pixels_per_second, speed, "Из шкафа время не замедляется.")
	user.forceMove(center)
	var/obj/item/projectile/after = sand_test_projectile(shooter, far_turf)
	after.forceMove(edge_turf)
	TEST_ASSERT(abs(after.pixels_per_second - speed / HERETIC_SAND_SLOW_FACTOR) < 0.01, "После выхода на ту же клетку поле снова работает.")

/// Повторный выход из шкафа телепортом на другую клетку не ломает поле.
/datum/unit_test/heretic_sand_slowtime_container_teleport/Run()
	var/list/fixture = ascend_sand_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/turf/center = get_turf(user)
	var/obj/structure/closet/closet = allocate(/obj/structure/closet, center)
	user.forceMove(closet)
	user.forceMove(center)
	user.forceMove(closet)
	var/turf/destination = get_step(center, NORTH)
	do_teleport(user, destination, channel = TELEPORT_CHANNEL_FREE)
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Еретик вышел из шкафа на другую клетку.")
	var/turf/far_turf = locate(destination.x + HERETIC_SAND_SLOW_RADIUS + 1, destination.y, destination.z)
	var/turf/edge_turf = locate(destination.x + HERETIC_SAND_SLOW_RADIUS, destination.y, destination.z)
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, far_turf)
	var/obj/item/projectile/bullet = sand_test_projectile(shooter, far_turf)
	var/speed = bullet.pixels_per_second
	bullet.forceMove(edge_turf)
	TEST_ASSERT(abs(bullet.pixels_per_second - speed / HERETIC_SAND_SLOW_FACTOR) < 0.01, "После второго выхода поле работает на новой клетке.")

/// Граница поля замедленного времени видна: бледное кольцо и песчинки кружат вокруг вознёсшегося; потеря тела гасит их плавно.
/datum/unit_test/heretic_sand_field_visuals/Run()
	var/list/fixture = ascend_sand_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/eldritch_knowledge/final_eldritch/sand_final/finale = fixture["finale"]
	var/datum/component/heretic_sand_slowtime/field = user.GetComponent(/datum/component/heretic_sand_slowtime)
	var/obj/effect/abstract/heretic_vfx_attached/ring = field.field_ring
	TEST_ASSERT_NOTNULL(ring, "Граница поля обозначена кольцом.")
	TEST_ASSERT(ring in user.vis_contents, "Кольцо ходит вместе с героем.")
	TEST_ASSERT_EQUAL(ring.layer, BELOW_MOB_LAYER, "Кольцо лежит под фигурами.")
	var/matrix/ring_transform = ring.transform
	TEST_ASSERT(ring_transform.a > 1, "Кольцо растянуто до радиуса поля.")
	TEST_ASSERT(ring.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Кольцо не мешает кликам.")
	var/obj/effect/abstract/heretic_particle_holder/grains = field.field_grains
	TEST_ASSERT_NOTNULL(grains, "По границе кружат песчинки.")
	TEST_ASSERT(grains in user.vis_contents, "Песчинки ходят вместе с героем.")
	TEST_ASSERT(grains.particles.count <= HERETIC_VFX_MAX_PARTICLES, "Песчинок немного.")
	var/turf/place = get_turf(user)
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_sand_slowtime), "Потеря тела снимает поле.")
	TEST_ASSERT(!QDELETED(ring) && ring.fading, "Кольцо гаснет плавно.")
	TEST_ASSERT(!(grains in user.vis_contents) && grains.loc == place, "Последние песчинки оседают на месте героя.")
	TEST_ASSERT(wait_for_qdeleted(ring), "Кольцо исчезает.")
	TEST_ASSERT(wait_for_qdeleted(grains, 4 SECONDS), "Песчинки догорают.")

/// Замедленный снаряд тянет песчаный след назад по курсу, со смертью снаряда след оседает; замедление прежнее.
/datum/unit_test/heretic_sand_trail_visuals/Run()
	var/list/fixture = ascend_sand_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/turf/center = get_turf(user)
	var/turf/far_turf = locate(center.x + HERETIC_SAND_SLOW_RADIUS + 1, center.y, center.z)
	var/turf/edge_turf = locate(center.x + HERETIC_SAND_SLOW_RADIUS, center.y, center.z)
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, far_turf)
	var/obj/item/projectile/bullet = sand_test_projectile(shooter, far_turf)
	bullet.setAngle(270)
	var/speed = bullet.pixels_per_second
	bullet.forceMove(edge_turf)
	TEST_ASSERT(abs(bullet.pixels_per_second - speed / HERETIC_SAND_SLOW_FACTOR) < 0.01, "Замедление прежнее.")
	var/obj/effect/abstract/heretic_particle_holder/sand_trail/trail = locate() in bullet.vis_contents
	TEST_ASSERT_NOTNULL(trail, "Замедленный снаряд тянет песчаный след.")
	var/list/drift = trail.particles.velocity
	TEST_ASSERT(drift[1] > 0 && abs(drift[2]) < 0.01, "Песчинки срываются назад по курсу снаряда.")
	bullet.forceMove(far_turf)
	bullet.forceMove(edge_turf)
	var/trails = 0
	for(var/obj/effect/abstract/heretic_particle_holder/sand_trail/candidate in bullet.vis_contents)
		trails++
	TEST_ASSERT_EQUAL(trails, 1, "На снаряд приходится один след.")
	var/turf/last_place = get_turf(bullet)
	qdel(bullet)
	TEST_ASSERT(!QDELETED(trail) && trail.loc == last_place, "След оседает там, где погиб снаряд.")
	TEST_ASSERT_EQUAL(trail.particles.spawning, 0, "Погибший снаряд больше не сыплет песком.")
	TEST_ASSERT(wait_for_qdeleted(trail), "След догорает.")

/// Последний полдень: над целью вспыхивает солнце, идёт волна песка и взлетают песчинки; урон прежний.
/datum/unit_test/heretic_sand_last_noon_visuals/Run()
	var/list/fixture = ascend_sand_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/target = locate(user.x + 3, user.y, user.z)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, target)
	var/list/before = list_vfx_bursts(target)
	TEST_ASSERT(sand.burial(user, target, final_cast = TRUE), "Последний полдень звучит.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 40) <= DAMAGE_PRECISION, "Первый удар наносит прежние 40 ушибов.")
	var/obj/effect/temp_visual/heretic_sand_sun/sun = locate() in target
	TEST_ASSERT_NOTNULL(sun, "Над целью вспыхивает солнце.")
	TEST_ASSERT_NOTNULL(sun.get_filter(HERETIC_VFX_RAYS_FILTER), "Солнце бьёт лучами.")
	TEST_ASSERT(sun.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Солнце не мешает кликам.")
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = locate() in target
	TEST_ASSERT_NOTNULL(wave, "По песку идёт волна.")
	var/obj/effect/temp_visual/heretic_vfx/burst/grains = find_vfx_burst(target, /particles/heretic_ascension/sand, before)
	TEST_ASSERT_NOTNULL(grains, "Взлетают песчинки.")
	TEST_ASSERT(wait_for_qdeleted(sun), "Солнце тает.")
	TEST_ASSERT(wait_for_qdeleted(wave), "Волна гаснет.")
	TEST_ASSERT(wait_for_qdeleted(grains, 4 SECONDS), "Песчинки оседают.")

/// Поле замедления - круг в радиусе четырёх клеток: углы квадрата за кольцом не замедляют снаряд и не дают ему след.
/datum/unit_test/heretic_sand_slowtime_circle/Run()
	var/list/fixture = ascend_sand_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	var/turf/center = get_turf(user)
	var/turf/far_turf = locate(center.x + HERETIC_SAND_SLOW_RADIUS + 1, center.y, center.z)
	var/mob/living/carbon/human/shooter = allocate(/mob/living/carbon/human, far_turf)
	for(var/list/offset as anything in list(list(4, 3), list(4, 4)))
		var/obj/item/projectile/corner = sand_test_projectile(shooter, far_turf)
		var/corner_speed = corner.pixels_per_second
		corner.forceMove(locate(center.x + offset[1], center.y + offset[2], center.z))
		TEST_ASSERT_EQUAL(corner.pixels_per_second, corner_speed, "Клетка ([offset[1]], [offset[2]]) за кольцом не замедляет.")
		TEST_ASSERT_NULL(locate(/obj/effect/abstract/heretic_particle_holder/sand_trail) in corner.vis_contents, "Снаряд за кольцом не тянет след.")
	var/obj/item/projectile/inside = sand_test_projectile(shooter, far_turf)
	var/speed = inside.pixels_per_second
	inside.forceMove(locate(center.x + 3, center.y + 3, center.z))
	TEST_ASSERT(abs(inside.pixels_per_second - speed / HERETIC_SAND_SLOW_FACTOR) < 0.01, "Диагональ (3, 3) внутри кольца замедляет.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/abstract/heretic_particle_holder/sand_trail) in inside.vis_contents, "Замедленный снаряд тянет след.")

/datum/unit_test/heretic_sand_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_sand_sun, /obj/effect/abstract/heretic_particle_holder/sand_trail))
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")
