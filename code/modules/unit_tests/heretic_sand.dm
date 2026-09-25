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
	TEST_ASSERT(!sand.stasis(user, stranger), "Стазис требует знания.")
	TEST_ASSERT(!sand.step_through(user, target), "Пересыпание требует знания.")
	TEST_ASSERT(!sand.burial(user, target), "Погребение требует знания.")
	TEST_ASSERT(!sand.burial(user, target, final_cast = TRUE), "Последний полдень требует вознесения.")
	TEST_ASSERT_EQUAL(sand.combat_resource, initial(sand.combat_resource), "Отказы не расходуют песок.")
	sand.combat_resource = 0
	TEST_ASSERT(!sand.release(user), "Осыпь не расходует отсутствующий песок.")
	TEST_ASSERT_EQUAL(length(sand.hourglasses), 0, "Отказы не оставляют часов.")

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
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_step)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_mark)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/spell/sand_step/stepping = heretic.get_knowledge(/datum/eldritch_knowledge/spell/sand_step)
	var/datum/eldritch_knowledge/sand_mark/mark = heretic.get_knowledge(/datum/eldritch_knowledge/sand_mark)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(get_turf(victim), stepping)
	TEST_ASSERT_NOTNULL(hourglass, "Изученное заклинание ставит часы.")
	stepping.on_body_lose(user)
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
	var/obj/structure/heretic_sand_anchor/craft/craft_anchor = new(get_step(user, NORTH), sand)
	var/obj/effect/proc_holder/spell/old_power = sand.combat_power
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	heretic.owner.transfer_to(new_body, TRUE)
	TEST_ASSERT_EQUAL(sand.sand_body, new_body, "Знание привязано к новому телу.")
	TEST_ASSERT(QDELETED(hourglass) && QDELETED(anchor) && QDELETED(old_power), "Старые часы, возврат и способность удалены.")
	TEST_ASSERT(!QDELETED(craft_anchor) && (craft_anchor in sand.anchors), "Засечка переживает смену тела.")
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

/datum/unit_test/heretic_sand_delayed_clock
	var/afterattack_signals = 0

/datum/unit_test/heretic_sand_delayed_clock/proc/on_relic_afterattack(datum/source)
	SIGNAL_HANDLER
	afterattack_signals++

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
	RegisterSignal(relic, COMSIG_ITEM_AFTERATTACK, PROC_REF(on_relic_afterattack))
	TEST_ASSERT(relic.afterattack(hourglass, user, FALSE), "Щелчок реликвией продлевает выбранные часы.")
	TEST_ASSERT_EQUAL(afterattack_signals, 1, "Щелчок по часам проходит через общий afterattack предмета.")
	UnregisterSignal(relic, COMSIG_ITEM_AFTERATTACK)
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

/// Стол не закрывает линию песка, а плотная машина закрывает.
/datum/unit_test/heretic_sand_line_over_table/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/target = locate(user.x + 3, user.y, user.z)
	var/mob/living/victim = allocate(/mob/living/carbon/human, target)
	allocate(/obj/structure/table, locate(user.x + 1, user.y, user.z))
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(target, sand)
	TEST_ASSERT_NOTNULL(hourglass, "Часы встают за столом.")
	hourglass.resolve()
	TEST_ASSERT(abs(victim.getBruteLoss() - 32) <= DAMAGE_PRECISION, "Цель за столом получает удар часов.")
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
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/heretic_sand_drought), "Поражённый Погребением получает Засуху.")
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
	var/obj/structure/heretic_sand_anchor/craft/craft_anchor = new(get_step(new_body, SOUTH), sand)
	var/obj/effect/proc_holder/spell/power = sand.combat_power
	qdel(heretic)
	TEST_ASSERT(QDELETED(sand), "Удаление роли освобождает знание.")
	TEST_ASSERT(QDELETED(hourglass) && QDELETED(anchor) && QDELETED(power), "Удаление роли гасит часы, возврат и действие.")
	TEST_ASSERT(QDELETED(craft_anchor), "Удаление роли снимает засечки.")

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
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/target = get_step(center, EAST)
	for(var/scenario in list("near", "far", "wall", "magic", "no_teleport", "destroy"))
		var/mob/living/victim = allocate(/mob/living/carbon/human, target)
		var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(target, sand)
		TEST_ASSERT(hourglass?.record_target(victim), "Часы запоминают врага в сценарии [scenario].")
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
		TEST_ASSERT(abs(victim.getBruteLoss() - (scenario == "near" ? 32 : 0)) <= DAMAGE_PRECISION, "Отложенный урон учитывает контрмеру [scenario].")
		TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_sand_recall), "После исхода связь с часами удалена.")
		if(protection)
			TEST_ASSERT_EQUAL(protection.charges, 2, "Возврат расходует ровно один заряд защиты.")
		QDEL_NULL(blocker)
		qdel(victim)

/// Утрата знания снимает незавершённый возврат вместе с его часами.
/datum/unit_test/heretic_sand_recall_cleanup/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_step)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/obj/structure/heretic_sand_hourglass/hourglass = sand.create_hourglass(get_turf(victim), heretic.get_knowledge(/datum/eldritch_knowledge/spell/sand_step))
	TEST_ASSERT(hourglass?.record_target(victim), "Часы запоминают врага.")
	qdel(heretic.get_knowledge(/datum/eldritch_knowledge/spell/sand_step))
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
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_sand_drought), "Последний полдень, как до переработки, Засуху не насылает.")
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
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_sand_sun, /obj/effect/abstract/heretic_particle_holder/sand_trail, /obj/effect/temp_visual/heretic_sand/stasis, /obj/structure/heretic_sand_anchor/craft))
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")

/datum/unit_test/proc/await_sand_stasis(mob/living/victim)
	var/list/budget = new_wait_budget(3 SECONDS, "песочный стазис на [victim]")
	while(!victim.has_status_effect(/datum/status_effect/heretic_sand_stasis))
		if(!wait_budget_tick(budget))
			break
	return victim.has_status_effect(/datum/status_effect/heretic_sand_stasis)

/// Хватка по полу ставит засечку: дело, улика, отказ на стене и занятой клетке, предел с вытеснением, поломка и нулевой жезл; смерть засечки не трогает, удаление знания снимает.
/datum/unit_test/heretic_sand_anchor_craft/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_SAND)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	var/turf/first_spot = get_step(user, EAST)
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	var/charges_before = fist.charges
	user.a_intent = INTENT_HARM
	fist.afterattack(first_spot, user, TRUE)
	TEST_ASSERT(!QDELETED(fist) && fist.charges == charges_before, "Хватка по полу вне намерения «Помощь» не тратит заряд.")
	TEST_ASSERT_NULL(locate(/obj/structure/heretic_sand_anchor) in first_spot, "Вне намерения «Помощь» засечка не встаёт.")
	TEST_ASSERT(!sand.on_mansus_grasp(first_spot, user, TRUE), "Знание не ставит засечку в боевом намерении.")
	user.a_intent = INTENT_HELP
	fist.afterattack(first_spot, user, TRUE)
	TEST_ASSERT(QDELETED(fist) || fist.charges < charges_before, "Хватка по полу в намерении «Помощь» тратит заряд.")
	var/obj/structure/heretic_sand_anchor/craft/first = locate() in first_spot
	TEST_ASSERT_NOTNULL(first, "На полу стоят часы-засечка.")
	TEST_ASSERT_EQUAL(length(sand.anchors), 1, "Засечка попала в список.")
	TEST_ASSERT_EQUAL(sand.anchors[1], first, "В списке именно новая засечка.")
	TEST_ASSERT_EQUAL(first.max_integrity, HERETIC_SAND_ANCHOR_INTEGRITY, "Прочность засечки 30.")
	TEST_ASSERT_NOTNULL(heretic_craft_on(first, "sand_anchor"), "Засечка несёт ремесло Песка.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Засечка продвигает дело.")
	TEST_ASSERT(findtext(jointext(first.examine(crew), " "), "течёт вверх"), "Экипаж видит улику при осмотре.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(!sand.on_mansus_grasp(first_spot, user, TRUE), "На занятую клетку вторая засечка не встаёт.")
	TEST_ASSERT(findtext(sand.grasp_failure_reason, "уже стоят"), "Отказ называет занятую клетку.")
	var/turf/wall = locate(run_loc_floor_bottom_left.x - 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	TEST_ASSERT(iswallturf(wall), "Слева от резервации стена.")
	TEST_ASSERT(!sand.place_anchor(user, wall), "На стену засечка не встаёт.")
	TEST_ASSERT(findtext(sand.grasp_failure_reason, "свободном полу"), "Отказ называет свободный пол.")
	TEST_ASSERT_EQUAL(length(sand.anchors), 1, "Отказы не добавляют засечек.")
	var/obj/structure/heretic_sand_anchor/recall = new(get_turf(user), sand)
	TEST_ASSERT(!(recall in sand.anchors), "Точка возврата реликвии не считается засечкой.")
	qdel(recall)
	var/list/obj/structure/heretic_sand_anchor/placed = list(first)
	for(var/turf/spot as anything in list(get_step(user, NORTHEAST), get_step(first_spot, EAST), get_step(get_step(first_spot, EAST), EAST)))
		TEST_ASSERT(sand.place_anchor(user, spot), "Засечка встаёт на [spot].")
		placed += locate(/obj/structure/heretic_sand_anchor/craft) in spot
	TEST_ASSERT(QDELETED(first), "Засечка сверх предела вытесняет старейшую.")
	TEST_ASSERT_EQUAL(length(sand.anchors), HERETIC_SAND_ANCHOR_LIMIT, "Держатся три засечки.")
	TEST_ASSERT_EQUAL(sand.anchors[1], placed[2], "Старейшей становится следующая засечка.")
	var/obj/structure/heretic_sand_anchor/craft/broken = placed[2]
	broken.take_damage(HERETIC_SAND_ANCHOR_INTEGRITY, BRUTE, MELEE)
	TEST_ASSERT(QDELETED(broken), "Засечку можно сломать.")
	TEST_ASSERT(!(broken in sand.anchors), "Сломанная засечка уходит из списка.")
	var/obj/structure/heretic_sand_anchor/craft/rodded = placed[3]
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, rodded)
	TEST_ASSERT(QDELETED(rodded), "Нулевой жезл снимает засечку.")
	TEST_ASSERT(!(rodded in sand.anchors), "Снятая жезлом засечка уходит из списка.")
	var/obj/structure/heretic_sand_anchor/craft/last = placed[4]
	sand.on_death(user)
	TEST_ASSERT(!QDELETED(last) && (last in sand.anchors), "Смерть не снимает засечки.")
	qdel(sand)
	TEST_ASSERT(QDELETED(last), "Удаление знания снимает засечки.")

/// Сухая ладонь насылает Засуху: 8 секунд действия цели идут в полтора раза дольше, потом скорость возвращается; песок приходит как прежде.
/datum/unit_test/heretic_sand_drought/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_grasp)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/sand_grasp)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	sand.combat_resource = 0
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE), "Хватка находит врага.")
	var/datum/status_effect/heretic_sand_drought/drought = victim.has_status_effect(/datum/status_effect/heretic_sand_drought)
	TEST_ASSERT_NOTNULL(drought, "Хватка насылает Засуху.")
	TEST_ASSERT(abs(drought.duration - world.time - HERETIC_SAND_DROUGHT_DURATION) < 0.1, "Засуха длится 8 секунд.")
	TEST_ASSERT(victim.has_actionspeed_modifier(/datum/actionspeed_modifier/heretic_sand_drought), "Засуха вешает модификатор скорости действий.")
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_actions_slowdown, 1.5, "Действия идут в полтора раза дольше.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 0, "Сухая ладонь больше не бьёт по выносливости.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 2, "Хватка даёт две единицы песка.")
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE), "Повторная хватка обновляет Засуху.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 2, "Песок от хватки приходит не чаще раза в 6 секунд.")
	var/started = world.time
	TEST_ASSERT(do_after(victim, 0.4 SECONDS, victim, progress = FALSE), "Цель под Засухой заканчивает действие.")
	TEST_ASSERT(world.time - started > 0.6 SECONDS - 0.1, "do_after растянут Засухой: [world.time - started] дс.")
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, get_step(victim, EAST))
	started = world.time
	TEST_ASSERT(do_mob(victim, patient, 0.4 SECONDS, progress = FALSE), "Цель под Засухой заканчивает действие над другим.")
	TEST_ASSERT(world.time - started > 0.6 SECONDS - 0.1, "do_mob (наручники, обыск, лечение) растянут Засухой: [world.time - started] дс.")
	var/mob/living/carbon/human/protected = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!grasp.on_mansus_grasp(protected, user, TRUE), "Антимагия отталкивает Сухую ладонь.")
	TEST_ASSERT_NULL(protected.has_status_effect(/datum/status_effect/heretic_sand_drought), "Защищённый не получает Засуху.")
	drought.duration = world.time
	TEST_ASSERT(wait_for_qdeleted(drought, 3 SECONDS), "Засуха проходит.")
	TEST_ASSERT(!victim.has_actionspeed_modifier(/datum/actionspeed_modifier/heretic_sand_drought), "Модификатор снят вместе с Засухой.")
	TEST_ASSERT_EQUAL(victim.cached_multiplicative_actions_slowdown, 1, "Скорость действий вернулась.")

/// Стазис: отказ без Засухи, стоящей и лёгшей сами цели и под антимагией; застывшая цель не получает урона, не истекает кровью, готова к обряду и её можно тянуть; нулевой жезл и святая вода развеивают, после - минута невосприимчивости.
/datum/unit_test/heretic_sand_stasis/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_stasis)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/spell/sand_stasis/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/sand_stasis)
	TEST_ASSERT(istype(knowledge.granted_spell, /obj/effect/proc_holder/spell/pointed/heretic_sand/stasis), "Знание выдаёт заклинание Стазиса.")
	var/turf/victim_spot = get_step(get_step(user, EAST), EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, victim_spot)
	sand.combat_resource = 4
	TEST_ASSERT(!sand.stasis(user, victim), "Цель без Засухи не застывает.")
	TEST_ASSERT(findtext(sand.sand_failure, "Засух"), "Отказ называет Засуху.")
	victim.apply_status_effect(/datum/status_effect/heretic_sand_drought)
	TEST_ASSERT(!sand.stasis(user, victim), "Стоящая цель не застывает.")
	TEST_ASSERT(findtext(sand.sand_failure, "сбитая с ног"), "Отказ называет сбитую с ног цель.")
	victim.set_resting(TRUE, TRUE)
	TEST_ASSERT(!(victim.mobility_flags & MOBILITY_STAND), "Цель легла сама.")
	TEST_ASSERT(!heretic.hunt_target_ready(victim), "Добровольно лёгшая цель ещё не готова к обряду.")
	TEST_ASSERT(!sand.stasis(user, victim), "Лёгшая сама цель не застывает.")
	victim.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	TEST_ASSERT(!sand.stasis(user, victim), "Антимагия отталкивает Стазис.")
	TEST_ASSERT(findtext(sand.sand_failure, "защищена от магии"), "Отказ называет антимагию.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Проверка не тратит заряды антимагии.")
	qdel(protection)
	TEST_ASSERT_EQUAL(sand.combat_resource, 4, "Отказы не тратят песок.")
	TEST_ASSERT(sand.stasis(user, victim), "Сбитая с ног цель под Засухой застывает.")
	TEST_ASSERT_EQUAL(sand.combat_resource, 2, "Стазис стоит две единицы песка.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/heretic_sand_stasis), "Секунду песок только смыкается.")
	TEST_ASSERT_NOTNULL(locate(/obj/effect/temp_visual/heretic_sand/stasis) in victim_spot, "Смыкание песка видно заранее.")
	var/datum/status_effect/heretic_sand_stasis/stasis = await_sand_stasis(victim)
	TEST_ASSERT_NOTNULL(stasis, "После секунды цель застывает.")
	var/remaining = stasis.duration - world.time
	TEST_ASSERT(remaining < HERETIC_SAND_STASIS_DURATION + 1 && remaining > HERETIC_SAND_STASIS_DURATION - 1 SECONDS, "Стазис длится 10 секунд: осталось [remaining] дс.")
	TEST_ASSERT(victim.IsParalyzed(), "Застывшая цель не действует.")
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Застывшая цель готова к обряду.")
	TEST_ASSERT_NOTNULL(victim.has_status_effect(/datum/status_effect/grouped/stasis), "Застывшая цель в общем стазисе.")
	TEST_ASSERT(SEND_SIGNAL(victim, COMSIG_LIVING_LIFE, 1) & COMPONENT_INTERRUPT_LIFE_BIOLOGICAL, "Застывшая цель не истекает кровью.")
	victim.adjustBruteLoss(40)
	victim.apply_damage(40, BURN)
	TEST_ASSERT_EQUAL(victim.getBruteLoss() + victim.getFireLoss(), 0, "Урон по застывшей цели не проходит.")
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(victim_spot, NORTH))
	crew.start_pulling(victim)
	TEST_ASSERT(crew.pulling != victim, "Застывшую цель экипаж не утащит.")
	user.start_pulling(victim)
	TEST_ASSERT_EQUAL(user.pulling, victim, "Застывшую цель тянет её еретик.")
	user.stop_pulling()
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	crew.put_in_hands(rod)
	rod.melee_attack_chain(crew, victim)
	TEST_ASSERT(QDELETED(stasis), "Нулевой жезл развеивает стазис.")
	TEST_ASSERT(!victim.IsParalyzed(), "Развеянная цель снова может двигаться.")
	TEST_ASSERT(!(victim.status_flags & GODMODE), "Развеянная цель снова уязвима.")
	TEST_ASSERT_NULL(victim.has_status_effect(/datum/status_effect/grouped/stasis), "Общий стазис снят.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Жезл не бьёт застывшую цель.")
	TEST_ASSERT(findtext(heretic_capture_block_reason(user, victim, "sand"), "приходит в себя"), "После стазиса цель минуту невосприимчива.")
	sand.combat_resource = 4
	TEST_ASSERT(!sand.stasis(user, victim), "Повторный Стазис в течение минуты отклонён.")
	TEST_ASSERT(findtext(sand.sand_failure, "приходит в себя"), "Отказ называет невосприимчивость.")
	var/mob/living/carbon/human/drinker = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	drinker.apply_status_effect(/datum/status_effect/heretic_sand_drought)
	drinker.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)
	TEST_ASSERT(sand.stasis(user, drinker), "Вторая цель застывает.")
	stasis = await_sand_stasis(drinker)
	TEST_ASSERT_NOTNULL(stasis, "Вторая цель застыла.")
	drinker.reagents.add_reagent(/datum/reagent/water/holywater, 5)
	stasis.tick()
	TEST_ASSERT(QDELETED(stasis), "Святая вода в крови развеивает стазис.")
	TEST_ASSERT(!(drinker.status_flags & GODMODE), "После святой воды цель снова уязвима.")
	var/mob/living/carbon/human/held = allocate(/mob/living/carbon/human, get_step(user, NORTHEAST))
	stasis = held.apply_status_effect(/datum/status_effect/heretic_sand_stasis, sand)
	TEST_ASSERT_NOTNULL(stasis, "Третья цель застыла.")
	sand.on_death(user)
	TEST_ASSERT(QDELETED(stasis), "Смерть еретика обрывает стазис.")

/// Откат: при засечке в 25 клетках еретик 3 секунды кружится в песке замедленным и переносится к ближайшей; наручники срывают перенос; без засечек рядом реликвия ставит прежнюю точку возврата.
/datum/unit_test/heretic_sand_rewind_to_anchor/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_relic)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/sand_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Обряд создаёт часы.")
	var/obj/item/heretic_path_relic/sand_relic/relic = recipe.new_path_relic_ref.resolve()
	allocated += relic
	user.put_in_hands(relic)
	var/turf/far_spot = locate(center.x + 3, center.y - 2, center.z)
	var/turf/near_spot = locate(center.x, center.y + 2, center.z)
	TEST_ASSERT(sand.place_anchor(user, far_spot), "Дальняя засечка стоит.")
	TEST_ASSERT(sand.place_anchor(user, near_spot), "Ближняя засечка стоит.")
	TEST_ASSERT(relic.turn_hourglass(user), "Часы в руке начинают Откат.")
	TEST_ASSERT(abs(COOLDOWN_TIMELEFT(relic, relic_cooldown) - 30 SECONDS) < 1, "Перезарядка Отката 30 секунд с начала: [COOLDOWN_TIMELEFT(relic, relic_cooldown)] дс.")
	var/datum/status_effect/heretic_sand_rewind/rewind = user.has_status_effect(/datum/status_effect/heretic_sand_rewind)
	TEST_ASSERT_NOTNULL(rewind, "Идёт Откат.")
	TEST_ASSERT_EQUAL(get_turf(user), center, "Перенос происходит не сразу.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_sand_rewind), "Во время Отката еретик замедлен.")
	TEST_ASSERT_NOTNULL(rewind.vortex, "Вокруг еретика кружится песок.")
	TEST_ASSERT_NULL(sand.anchor, "Откат не ставит точку возврата.")
	TEST_ASSERT(wait_for_qdeleted(rewind, 5 SECONDS), "Откат завершается.")
	TEST_ASSERT_EQUAL(get_turf(user), near_spot, "Откат переносит к ближайшей засечке.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_sand_rewind), "Замедление снято.")
	TEST_ASSERT(!relic.turn_hourglass(user), "Перезарядка не пускает второй Откат сразу.")
	COOLDOWN_RESET(relic, relic_cooldown)
	user.forceMove(center)
	TEST_ASSERT(relic.turn_hourglass(user), "После перезарядки Откат снова начинается.")
	rewind = user.has_status_effect(/datum/status_effect/heretic_sand_rewind)
	TEST_ASSERT_NOTNULL(rewind, "Второй Откат идёт.")
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(wait_for_qdeleted(rewind, 5 SECONDS), "Откат в наручниках заканчивается.")
	TEST_ASSERT_EQUAL(get_turf(user), center, "Наручники срывают перенос.")
	user.uncuff()
	user.put_in_hands(relic)
	COOLDOWN_RESET(relic, relic_cooldown)
	var/mob/living/carbon/human/host = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/datum/status_effect/heretic_sand_rewind/lost = host.apply_status_effect(/datum/status_effect/heretic_sand_rewind, sand)
	TEST_ASSERT(lost.duration != -1 && lost.duration - world.time < 6 SECONDS, "У Отката есть запасной срок: [lost.duration - world.time] дс.")
	var/obj/effect/abstract/heretic_vfx_attached/lost_vortex = lost.vortex
	TEST_ASSERT_NOTNULL(lost_vortex, "Вихрь Отката виден.")
	qdel(host)
	TEST_ASSERT(QDELETED(lost) && QDELETED(lost_vortex), "Удалённое посреди Отката тело не оставляет вихрь.")
	heretic_test_area(center, /area/unit_test_sand_noteleport)
	TEST_ASSERT(!relic.begin_rewind(user, sand), "Из зоны без телепортации Откат не начинается.")
	TEST_ASSERT(COOLDOWN_FINISHED(relic, relic_cooldown), "Отказ не тратит перезарядку.")
	heretic_test_area(near_spot, /area/unit_test_sand_noteleport)
	heretic_test_area(far_spot, /area/unit_test_sand_noteleport)
	TEST_ASSERT_NULL(sand.nearest_anchor(user), "Засечки в зоне без телепортации не годятся для Отката.")
	var/turf/beyond = locate(center.x + HERETIC_SAND_REWIND_RANGE + 1, center.y, center.z)
	TEST_ASSERT_NOTNULL(beyond, "За пределом Отката есть клетка.")
	for(var/obj/structure/heretic_sand_anchor/craft/anchor as anything in sand.anchors)
		anchor.forceMove(beyond)
	TEST_ASSERT_NULL(sand.nearest_anchor(user), "Засечка дальше 25 клеток не годится.")
	user.forceMove(get_step(center, SOUTH))
	TEST_ASSERT(relic.turn_hourglass(user), "Без засечек рядом часы работают по-старому.")
	TEST_ASSERT_NULL(user.has_status_effect(/datum/status_effect/heretic_sand_rewind), "Без засечек Откат не начинается.")
	TEST_ASSERT_NOTNULL(sand.anchor, "Ставится прежняя точка возврата.")
	TEST_ASSERT(!(sand.anchor in sand.anchors), "Точка возврата не засечка.")

/area/unit_test_sand_noteleport
	name = "Sand No-Teleport Test Room"
	requires_power = FALSE
	area_flags = NOTELEPORT

/obj/effect/eldritch/big/sand_haste_fixture
	var/observed_visual_lifetime

/obj/effect/eldritch/big/sand_haste_fixture/ritual_valid(mob/living/user, datum/eldritch_knowledge/ritual)
	if(isnull(observed_visual_lifetime))
		observed_visual_lifetime = ritual_visual?.duration
	return ..()

/// Течение часа: у своей засечки обряд, черчение руны и обряд сердцем идут вдвое быстрее; вдали, без знания и у чужого - как обычно.
/datum/unit_test/heretic_sand_haste/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/anchor_spot = get_step(user, NORTH)
	TEST_ASSERT(sand.place_anchor(user, anchor_spot), "Засечка стоит у места обряда.")
	var/turf/far_spot = locate(anchor_spot.x + HERETIC_SAND_HASTE_RANGE + 1, anchor_spot.y, anchor_spot.z)
	TEST_ASSERT_EQUAL(heretic_ritual_speed_multiplier(user, get_turf(user)), 1, "Без Течения часа засечка не ускоряет.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_haste)
	TEST_ASSERT_EQUAL(heretic_ritual_speed_multiplier(user, get_turf(user)), 0.5, "У засечки обряды вдвое быстрее.")
	TEST_ASSERT_EQUAL(heretic_ritual_speed_multiplier(user, far_spot), 1, "Дальше пяти клеток ускорения нет.")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human, get_step(user, EAST))
	TEST_ASSERT_EQUAL(heretic_ritual_speed_multiplier(stranger, get_turf(user)), 1, "Чужому засечка не помогает.")
	qdel(stranger)
	var/turf/rune_center = get_step(user, NORTHEAST)
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	user.put_in_hands(book)
	INVOKE_ASYNC(book, TYPE_PROC_REF(/obj/item/forbidden_book, draw_rune), rune_center, user)
	var/obj/effect/temp_visual/heretic_ritual/trace = locate() in rune_center
	TEST_ASSERT_NOTNULL(trace, "Начертание руны видно.")
	TEST_ASSERT_EQUAL(trace.duration, 4 SECONDS + 1 SECONDS, "Черчение у засечки длится 4 секунды вместо 8.")
	TEST_ASSERT(wait_for_var(book, NAMEOF(book, drawing), FALSE, 6 SECONDS), "Черчение заканчивается.")
	var/obj/effect/eldritch/big/drawn = locate() in rune_center
	TEST_ASSERT_NOTNULL(drawn, "Руна начерчена.")
	qdel(drawn)
	var/obj/effect/eldritch/big/sand_haste_fixture/rune = allocate(/obj/effect/eldritch/big/sand_haste_fixture, get_turf(user))
	allocate(/obj/item/pen, get_turf(user))
	var/datum/eldritch_knowledge/recipe = allocate(/datum/eldritch_knowledge)
	recipe.required_atoms = list(/obj/item/pen)
	recipe.result_atoms = list(/obj/item/stack/sheet/metal)
	recipe.ritual_time = 2 SECONDS
	heretic.researched_knowledge[recipe.type] = recipe
	var/started = world.time
	TEST_ASSERT(rune.do_ritual(user, recipe), "Обряд у засечки завершается.")
	TEST_ASSERT(world.time - started < recipe.ritual_time, "Обряд у засечки короче обычного: [world.time - started] дс.")
	TEST_ASSERT_EQUAL(rune.observed_visual_lifetime, recipe.ritual_time * 0.5 + 1 SECONDS, "Печать обряда рассчитана на вдвое более короткий обряд.")
	allocated += locate(/obj/item/stack/sheet/metal) in get_turf(user)
	heretic.researched_knowledge -= recipe.type
	qdel(rune)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/spell/basic/hunt_ritual = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, get_turf(user))
	TEST_ASSERT(heart.bind(heretic.owner), "Сердце привязано к еретику.")
	user.put_in_hands(heart)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	heretic.set_hunt_target(soul)
	victim.handcuffed = allocate(/obj/item/restraints/handcuffs, victim)
	victim.update_handcuffed()
	TEST_ASSERT_EQUAL(heretic.heart_rite_time(victim), hunt_ritual.ritual_time * 0.5, "Обряд сердцем у засечки вдвое короче.")
	TEST_ASSERT_EQUAL(heretic.heart_rite_time(far_spot), hunt_ritual.ritual_time, "Вдали от засечки обряд сердцем обычной длины.")
	TEST_ASSERT(findtext(jointext(heart.examine(user), " "), "займёт [DisplayTimeText(hunt_ritual.ritual_time * 0.5, 1)]"), "Сердце называет настоящую длину обряда.")
	var/turf/rite_turf = get_turf(victim)
	INVOKE_ASYNC(heretic, TYPE_PROC_REF(/datum/antagonist/heretic, begin_heart_rite), user, victim, heart)
	var/obj/effect/eldritch/big/heart_rite/circle = locate() in rite_turf
	TEST_ASSERT_NOTNULL(circle, "Под целью проступил круг.")
	TEST_ASSERT_EQUAL(circle.ritual_visual?.duration, hunt_ritual.ritual_time * 0.5 + 1 SECONDS, "Обряд сердцем у засечки вдвое короче.")
	victim.forceMove(get_step(rite_turf, EAST))
	TEST_ASSERT(wait_for_qdeleted(circle, 3 SECONDS), "Прерванный обряд убирает круг.")
	heretic.set_hunt_target(null)

/// Стазис кончается до лечения Мансуса: обессиленная и задохнувшаяся жертва входит в Дом здоровой, невосприимчивость остаётся.
/datum/unit_test/heretic_sand_stasis_sacrifice/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_stasis)
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(heretic.owner.current, EAST))
	var/datum/mind/soul = allocate_mind()
	soul.current = victim
	victim.mind = soul
	victim.adjustStaminaLoss(500)
	victim.adjustOxyLoss(30)
	TEST_ASSERT(IS_STAMCRIT(victim), "Жертва обессилена.")
	var/datum/status_effect/heretic_sand_stasis/stasis = victim.apply_status_effect(/datum/status_effect/heretic_sand_stasis, sand)
	TEST_ASSERT_NOTNULL(stasis, "Жертва застыла.")
	var/datum/heretic_mansus_visit/visit = allocate(/datum/heretic_mansus_visit/mansus_fixture)
	TEST_ASSERT(visit.prepare(victim, run_loc_floor_top_right, run_loc_floor_top_right), "Комната готова.")
	TEST_ASSERT(visit.start(), "Жертва входит в Мансус.")
	TEST_ASSERT(QDELETED(stasis), "Вход в Мансус снимает стазис.")
	TEST_ASSERT(!(victim.status_flags & GODMODE), "Жертва в Доме снова уязвима.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 0, "Мансус снимает обессиленность: [victim.getStaminaLoss()].")
	TEST_ASSERT_EQUAL(victim.getOxyLoss(), 0, "Мансус снимает удушье: [victim.getOxyLoss()].")
	TEST_ASSERT_NOTNULL(capture_immunity(victim, "sand"), "После стазиса невосприимчивость остаётся.")

/// Стазис берёт под Засухой только сбитую с ног или обессиленную цель: лёгшая сама и спящая не подходят.
/datum/unit_test/heretic_sand_stasis_readiness/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_stasis)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	sand.combat_resource = 4
	var/mob/living/carbon/human/rester = allocate(/mob/living/carbon/human, locate(user.x + 1, user.y + 2, user.z))
	rester.apply_status_effect(/datum/status_effect/heretic_sand_drought)
	rester.set_resting(TRUE, silent = TRUE)
	TEST_ASSERT(findtext(sand.stasis_block_reason(user, rester), "сбитая с ног"), "Лёгшая сама цель не застывает.")
	var/mob/living/carbon/human/sleeper = allocate(/mob/living/carbon/human, locate(user.x + 2, user.y + 1, user.z))
	sleeper.apply_status_effect(/datum/status_effect/heretic_sand_drought)
	sleeper.SetSleeping(10 SECONDS)
	TEST_ASSERT(findtext(sand.stasis_block_reason(user, sleeper), "сбитая с ног"), "Спящая цель не застывает.")
	var/mob/living/carbon/human/knocked = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y + 1, user.z))
	knocked.apply_status_effect(/datum/status_effect/heretic_sand_drought)
	knocked.DefaultCombatKnockdown(2 SECONDS, override_stamdmg = 0)
	TEST_ASSERT_NULL(sand.stasis_block_reason(user, knocked), "Сбитая с ног цель застывает.")
	var/mob/living/carbon/human/exhausted = allocate(/mob/living/carbon/human, locate(user.x + 3, user.y + 2, user.z))
	exhausted.apply_status_effect(/datum/status_effect/heretic_sand_drought)
	exhausted.adjustStaminaLoss(500)
	TEST_ASSERT(IS_STAMCRIT(exhausted), "Цель в стамкрите.")
	TEST_ASSERT_NULL(sand.stasis_block_reason(user, exhausted), "Обессиленная цель застывает.")
	var/mob/living/carbon/human/dry = allocate(/mob/living/carbon/human, locate(user.x + 2, user.y + 3, user.z))
	dry.DefaultCombatKnockdown(2 SECONDS, override_stamdmg = 0)
	TEST_ASSERT(findtext(sand.stasis_block_reason(user, dry), "Засух"), "Без Засухи сбитая цель не застывает.")

/// Отказ Отката называет причину: остаток перезарядки или наручники.
/datum/unit_test/heretic_sand_rewind_refusal/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_relic)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/sand_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Обряд создаёт часы.")
	var/obj/item/heretic_path_relic/sand_relic/relic = recipe.new_path_relic_ref.resolve()
	allocated += relic
	user.put_in_hands(relic)
	TEST_ASSERT(sand.place_anchor(user, locate(center.x, center.y + 2, center.z)), "Засечка стоит.")
	COOLDOWN_START(relic, relic_cooldown, 30 SECONDS)
	TEST_ASSERT(!relic.begin_rewind(user, sand), "На перезарядке Откат не начинается.")
	TEST_ASSERT(findtext(sand.sand_failure, "осталось"), "Отказ называет остаток перезарядки: [sand.sand_failure]")
	COOLDOWN_RESET(relic, relic_cooldown)
	user.handcuffed = allocate(/obj/item/restraints/handcuffs, user)
	user.update_handcuffed()
	TEST_ASSERT(!relic.begin_rewind(user, sand), "В наручниках Откат не начинается.")
	TEST_ASSERT(findtext(sand.sand_failure, "наручник"), "Отказ называет наручники: [sand.sand_failure]")
	user.uncuff()
	TEST_ASSERT(relic.begin_rewind(user, sand), "Без помех Откат начинается.")
	qdel(user.has_status_effect(/datum/status_effect/heretic_sand_rewind))

/// Точка возврата без засечек называет причину каждого отказа и не работает в зонах, закрытых для телепортации.
/datum/unit_test/heretic_sand_relic_point_reasons/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_relic)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/sand_relic/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/sand_relic)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), center), "Обряд создаёт часы.")
	var/obj/item/heretic_path_relic/sand_relic/relic = recipe.new_path_relic_ref.resolve()
	allocated += relic
	user.put_in_hands(relic)
	var/turf/closed_spot = get_step(center, WEST)
	heretic_test_area(closed_spot, /area/unit_test_sand_noteleport)
	user.forceMove(closed_spot)
	TEST_ASSERT(!relic.turn_hourglass(user), "В зоне без телепортации точка возврата не ставится.")
	TEST_ASSERT(findtext(sand.sand_failure, "телепорт"), "Отказ называет зону: [sand.sand_failure]")
	TEST_ASSERT_NULL(sand.anchor, "Точка не появилась.")
	TEST_ASSERT(COOLDOWN_FINISHED(relic, relic_cooldown), "Отказ не тратит перезарядку.")
	user.forceMove(center)
	TEST_ASSERT(relic.turn_hourglass(user), "На обычном полу точка ставится.")
	var/turf/away = get_step(get_step(center, EAST), EAST)
	user.forceMove(away)
	ADD_TRAIT(user, TRAIT_NO_TELEPORT, TRAIT_SOURCE_UNIT_TESTS)
	TEST_ASSERT(!relic.turn_hourglass(user), "Запрет телепортации держит на месте.")
	TEST_ASSERT(findtext(sand.sand_failure, "держит"), "Отказ называет помеху: [sand.sand_failure]")
	REMOVE_TRAIT(user, TRAIT_NO_TELEPORT, TRAIT_SOURCE_UNIT_TESTS)
	var/obj/machinery/hydroponics/machine = allocate(/obj/machinery/hydroponics, get_step(center, EAST))
	TEST_ASSERT(!relic.turn_hourglass(user), "Плотная машина закрывает путь к точке.")
	TEST_ASSERT(findtext(sand.sand_failure, "линия"), "Отказ называет линию: [sand.sand_failure]")
	qdel(machine)
	heretic_test_area(away, /area/unit_test_sand_noteleport)
	TEST_ASSERT(!relic.turn_hourglass(user), "Из зоны без телепортации к точке не вернуться.")
	TEST_ASSERT(findtext(sand.sand_failure, "телепорт"), "Отказ называет зону: [sand.sand_failure]")
	TEST_ASSERT_EQUAL(get_turf(user), away, "Отказы не переносят.")
	var/turf/near_point = locate(center.x, center.y + 1, center.z)
	user.forceMove(near_point)
	var/area/point_area = get_area(center)
	heretic_test_area(center, /area/unit_test_sand_noteleport)
	TEST_ASSERT(!relic.turn_hourglass(user), "К точке в зоне без телепортации не вернуться.")
	TEST_ASSERT(findtext(sand.sand_failure, "телепорт"), "Отказ называет зону точки: [sand.sand_failure]")
	TEST_ASSERT_EQUAL(get_turf(user), near_point, "Отказ у закрытой точки не переносит.")
	point_area.contents += center
	TEST_ASSERT_EQUAL(get_area(center), point_area, "Клетка точки вернулась в обычную зону.")
	user.forceMove(locate(center.x, center.y + 2, center.z))
	sand.anchor.expires_at = world.time
	TEST_ASSERT(!relic.turn_hourglass(user), "Истёкшая точка не принимает.")
	TEST_ASSERT(findtext(sand.sand_failure, "рассыпалась"), "Отказ называет истёкшую точку: [sand.sand_failure]")
	QDEL_NULL(sand.anchor)
	TEST_ASSERT(!relic.turn_hourglass(user), "Новая точка ждёт перезарядки.")
	TEST_ASSERT(findtext(sand.sand_failure, "осталось"), "Отказ называет остаток перезарядки: [sand.sand_failure]")

/datum/unit_test/proc/sand_cog_count(mob/living/worker)
	. = 0
	for(var/obj/effect/overlay/vis/overlay in worker.vis_contents)
		if(overlay.icon_state == "cog")
			.++

/datum/unit_test/proc/sand_interrupt_action(mob/living/worker)
	worker.forceMove(get_step(worker, NORTH))
	for(var/attempt in 1 to 10)
		if(!LAZYLEN(worker.do_afters))
			return
		sleep(world.tick_lag)

/// Шестерёнку do_mob и do_after решает исходное время: под Засухой действие короче секунды её не показывает.
/datum/unit_test/heretic_sand_drought_cog/Run()
	var/mob/living/carbon/human/worker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, get_step(worker, EAST))
	worker.apply_status_effect(/datum/status_effect/heretic_sand_drought)
	TEST_ASSERT_EQUAL(worker.cached_multiplicative_actions_slowdown, 1.5, "Засуха растягивает действия.")
	var/cogs = sand_cog_count(worker)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(do_mob), worker, patient, 0.8 SECONDS)
	var/mob_cog = sand_cog_count(worker) > cogs
	sand_interrupt_action(worker)
	cogs = sand_cog_count(worker)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(do_after), worker, 0.8 SECONDS, patient)
	var/after_cog = sand_cog_count(worker) > cogs
	sand_interrupt_action(worker)
	cogs = sand_cog_count(worker)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(do_mob), worker, patient, 1 SECONDS)
	var/long_cog = sand_cog_count(worker) > cogs
	sand_interrupt_action(worker)
	TEST_ASSERT(!after_cog, "do_after короче секунды не показывает шестерёнку.")
	TEST_ASSERT(!mob_cog, "do_mob короче секунды тоже не показывает шестерёнку.")
	TEST_ASSERT(long_cog, "Секундное действие показывает шестерёнку.")

/datum/unit_test/proc/sand_progress_goal(mob/living/worker, atom/target)
	var/list/bars = LAZYACCESS(worker.progressbars, target)
	if(!length(bars))
		return null
	var/datum/progressbar/bar = bars[length(bars)]
	return bar.goal

/datum/unit_test/proc/sand_await_action_end(mob/living/worker, atom/target, max_wait)
	var/list/budget = new_wait_budget(max_wait, "конец действия [worker] над [target]")
	while(LAZYFIND(worker.do_afters, target))
		if(!wait_budget_tick(budget))
			break
	return !LAZYFIND(worker.do_afters, target)

/// do_mob растягивает только Засуха: наручники и попытка растолкать под ней идут в полтора раза дольше, а настроение do_mob не меняет ни в какую сторону.
/datum/unit_test/heretic_sand_drought_do_mob_scope/Run()
	var/mob/living/carbon/human/worker = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, get_step(worker, EAST))
	var/turf/work_spot = get_turf(worker)
	worker.add_actionspeed_modifier(/datum/actionspeed_modifier/low_sanity)
	TEST_ASSERT_EQUAL(worker.cached_multiplicative_actions_slowdown, 1.25, "Плохое настроение замедляет действия.")
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(do_mob), worker, patient, 1 SECONDS)
	TEST_ASSERT_EQUAL(sand_progress_goal(worker, patient), 1 SECONDS, "Плохое настроение не растягивает do_mob.")
	sand_interrupt_action(worker)
	worker.forceMove(work_spot)
	worker.remove_actionspeed_modifier(ACTIONSPEED_ID_SANITY)
	worker.add_actionspeed_modifier(/datum/actionspeed_modifier/high_sanity)
	TEST_ASSERT(worker.cached_multiplicative_actions_slowdown < 1, "Хорошее настроение ускоряет действия.")
	var/started = world.time
	TEST_ASSERT(do_mob(worker, patient, 1 SECONDS, progress = FALSE), "Довольный заканчивает действие над другим.")
	TEST_ASSERT(world.time - started > 1 SECONDS - 0.1, "Хорошее настроение не укорачивает do_mob: [world.time - started] дс.")
	worker.remove_actionspeed_modifier(ACTIONSPEED_ID_SANITY)
	worker.add_actionspeed_modifier(/datum/actionspeed_modifier/low_sanity)
	worker.apply_status_effect(/datum/status_effect/heretic_sand_drought)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(do_mob), worker, patient, 1 SECONDS)
	TEST_ASSERT_EQUAL(sand_progress_goal(worker, patient), 1.5 SECONDS, "Под Засухой do_mob растягивает только она, настроение не добавляется.")
	sand_interrupt_action(worker)
	worker.forceMove(work_spot)
	worker.remove_actionspeed_modifier(ACTIONSPEED_ID_SANITY)
	var/obj/item/restraints/handcuffs/cuffs = allocate(/obj/item/restraints/handcuffs)
	TEST_ASSERT(worker.put_in_active_hand(cuffs), "Наручники в руке.")
	started = world.time
	INVOKE_ASYNC(cuffs, TYPE_PROC_REF(/obj/item, attack), patient, worker)
	TEST_ASSERT_EQUAL(sand_progress_goal(worker, patient), 4.5 SECONDS, "Засуха растягивает наручники с 3 до 4,5 секунды.")
	TEST_ASSERT(sand_await_action_end(worker, patient, 6 SECONDS), "Надевание наручников заканчивается.")
	TEST_ASSERT_NOTNULL(patient.handcuffed, "Наручники надеты.")
	TEST_ASSERT(world.time - started > 4.5 SECONDS - 0.1, "Наручники под Засухой надеваются не быстрее 4,5 секунды: [world.time - started] дс.")
	heretic_capture_hold(patient, "sand_scope")
	started = world.time
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(heretic_capture_shake), worker, patient)
	TEST_ASSERT_EQUAL(sand_progress_goal(worker, patient), HERETIC_CAPTURE_SHAKE_TIME * 1.5, "Засуха растягивает попытку растолкать в полтора раза.")
	TEST_ASSERT(sand_await_action_end(worker, patient, HERETIC_CAPTURE_SHAKE_TIME * 2), "Попытка растолкать заканчивается.")
	TEST_ASSERT(world.time - started > HERETIC_CAPTURE_SHAKE_TIME * 1.5 - 0.1, "Под Засухой растолкать не быстрее 3 секунд: [world.time - started] дс.")
	heretic_capture_unhold(patient, "sand_scope")

/// Дверь Песка: застывшая в своём Стазисе цель уводится в изнанку, где её держит вход; без Стазиса двери нет; клик «Помощи» Стазис не снимает, 2 секунды растолкать - снимают; выходы - свои засечки, снятые и чужие не в счёт.
/datum/unit_test/heretic_sand_pocket_door/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_stasis)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/datum/eldritch_knowledge/spell/basic/ritual = heretic.get_knowledge(/datum/eldritch_knowledge/spell/basic)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	victim.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)
	TEST_ASSERT(heretic.hunt_target_ready(victim), "Сбитая цель готова к обряду.")
	TEST_ASSERT_NULL(sand.pocket_door(user, victim), "Без своего Стазиса двери Песка нет.")
	var/datum/status_effect/heretic_sand_stasis/stasis = victim.apply_status_effect(/datum/status_effect/heretic_sand_stasis, sand)
	TEST_ASSERT_NOTNULL(stasis, "Цель застыла.")
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, get_step(spot, NORTH))
	victim.help_shake_act(helper)
	helper.forceMove(get_step(helper, EAST))
	TEST_ASSERT(!QDELETED(stasis) && victim.IsParalyzed(), "Клик «Помощи» не снимает Стазис.")
	var/list/door = sand.pocket_door(user, victim)
	TEST_ASSERT_NOTNULL(door, "Застывшую цель Песок уводит в изнанку.")
	TEST_ASSERT_EQUAL(door["time"], HERETIC_POCKET_PULL_TIME, "Дверь Песка занимает [HERETIC_POCKET_PULL_TIME / (1 SECONDS)] с.")
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, door["time"], door["check"], door["text"]), "Дверь Песка уводит цель.")
	TEST_ASSERT(heretic.pocket_holds(victim), "Цель в изнанке.")
	var/datum/timedevent/release = SStimer.timer_id_dict[heretic.pocket.entry_hold_timer]
	TEST_ASSERT(victim.IsParalyzed() && abs(release?.timeToRun - world.time - HERETIC_POCKET_ENTRY_HOLD) < 1, "Вход держит цель [HERETIC_POCKET_ENTRY_HOLD / (1 SECONDS)] с: [release?.timeToRun - world.time] дс.")
	TEST_ASSERT_NULL(heretic.heart_rite_refusal_reason(victim, ritual), "Обряд сердцем над удержанной целью начинается.")
	heretic.pocket.collapse("проверка")
	qdel(stasis)
	for(var/datum/status_effect/heretic_capture_immunity/immunity as anything in victim.has_status_effect_list(/datum/status_effect/heretic_capture_immunity))
		qdel(immunity)
	stasis = victim.apply_status_effect(/datum/status_effect/heretic_sand_stasis, sand)
	TEST_ASSERT_NOTNULL(stasis, "Цель застыла снова.")
	SEND_SIGNAL(victim, COMSIG_LIVING_HERETIC_CAPTURE_SHAKEN, helper)
	TEST_ASSERT(QDELETED(stasis), "Растолканную цель Стазис отпускает.")

	var/obj/structure/heretic_sand_anchor/craft/own = new(locate(spot.x + 2, spot.y + 2, spot.z), sand)
	allocated += own
	var/datum/antagonist/heretic/rival = allocate_heretic(locate(spot.x + 3, spot.y + 4, spot.z))
	rival.selected_path = PATH_SAND
	rival.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	var/datum/eldritch_knowledge/base_sand/rival_sand = rival.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/obj/structure/heretic_sand_anchor/craft/foreign = new(locate(spot.x + 3, spot.y + 3, spot.z), rival_sand)
	allocated += foreign
	var/list/exits = sand.pocket_exits(user)
	TEST_ASSERT_EQUAL(length(exits), 1, "Выход - только своя засечка.")
	TEST_ASSERT(findtext(exits[1], "Часы - "), "Выход подписан часами и отделом: [exits[1]]")
	TEST_ASSERT_EQUAL(exits[exits[1]], get_turf(own), "Выход у своих часов.")
	qdel(own)
	TEST_ASSERT_EQUAL(length(sand.pocket_exits(user)), 0, "Разбитая засечка больше не выход.")

/// Стазис рвёт чужую хватку, отстёгивает цель и не даёт никому, кроме еретика, тянуть её или пристегнуть к каталке; после Стазиса запрет снят.
/datum/unit_test/heretic_sand_stasis_lock/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/sand_stasis)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, spot)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, get_step(spot, NORTH))
	var/obj/structure/bed/roller/bed = allocate(/obj/structure/bed/roller, get_step(spot, EAST))
	victim.DefaultCombatKnockdown(5 SECONDS, override_stamdmg = 0)
	crew.start_pulling(victim)
	TEST_ASSERT_EQUAL(crew.pulling, victim, "Экипаж держит сбитую цель до Стазиса.")
	var/datum/status_effect/heretic_sand_stasis/stasis = victim.apply_status_effect(/datum/status_effect/heretic_sand_stasis, sand)
	TEST_ASSERT_NOTNULL(stasis, "Цель застыла.")
	TEST_ASSERT(crew.pulling != victim, "Стазис рвёт хватку экипажа, взятую заранее.")
	crew.start_pulling(victim)
	TEST_ASSERT(crew.pulling != victim, "Застывшую цель экипаж не схватит заново.")
	TEST_ASSERT(!bed.user_buckle_mob(victim, crew), "Застывшую цель экипаж не пристегнёт к каталке.")
	TEST_ASSERT_NULL(victim.buckled, "Цель не пристёгнута.")
	user.start_pulling(victim)
	TEST_ASSERT_EQUAL(user.pulling, victim, "Свой еретик тянет застывшую цель.")
	user.stop_pulling()
	qdel(stasis)
	TEST_ASSERT(!LAZYLEN(victim.heretic_pull_owners), "Конец Стазиса снимает запрет.")
	crew.start_pulling(victim)
	TEST_ASSERT_EQUAL(crew.pulling, victim, "После Стазиса экипаж снова может тянуть цель.")
	crew.stop_pulling()

/// Течение часа в изнанке: обряд внутри идёт как у входа - вход у своей засечки ускоряет вдвое, засечка дальше пяти клеток от входа - нет.
/datum/unit_test/heretic_sand_haste_pocket/Run()
	allocated += new /datum/heretic_test_station_level(run_loc_floor_bottom_left.z)
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_SAND
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_sand)
	heretic.gain_knowledge(/datum/eldritch_knowledge/sand_haste)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_sand/sand = heretic.get_knowledge(/datum/eldritch_knowledge/base_sand)
	var/turf/spot = get_step(user, EAST)
	var/mob/living/carbon/human/victim = allocate_hunt_victim(heretic, spot)
	TEST_ASSERT(sand.place_anchor(user, get_step(user, NORTH)), "Засечка у места засады.")
	var/obj/structure/heretic_sand_anchor/anchor = sand.anchors[1]
	TEST_ASSERT(heretic.pocket_pull(user, victim, spot, 0), "Цель в изнанке.")
	TEST_ASSERT(heretic.pocket.contains(user) && heretic.pocket_holds(victim), "Еретик и цель внутри.")
	TEST_ASSERT_EQUAL(heretic_ritual_speed_multiplier(user, get_turf(victim)), 0.5, "Вход у засечки: обряд в изнанке вдвое быстрее.")
	anchor.forceMove(locate(spot.x + HERETIC_SAND_HASTE_RANGE + 1, spot.y, spot.z))
	TEST_ASSERT_EQUAL(heretic_ritual_speed_multiplier(user, get_turf(victim)), 1, "Засечка дальше пяти клеток от входа изнанку не ускоряет.")
	heretic.pocket.collapse("проверка")
