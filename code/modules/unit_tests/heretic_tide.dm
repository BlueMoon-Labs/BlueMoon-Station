/// Хватка и настоящее попадание клинком дают ограниченный запас; повторный удар учитывает задержку сбора.
/datum/unit_test/heretic_tide_pressure_cycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/tide_grasp)
	heretic.gain_knowledge(/datum/eldritch_knowledge/tide_mark)
	var/mob/living/user = heretic.owner.current
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/tide_grasp/grasp = heretic.get_knowledge(/datum/eldritch_knowledge/tide_grasp)
	var/datum/eldritch_knowledge/tide_mark/mark_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/tide_mark)
	var/obj/item/melee/sickly_blade/tide/blade = allocate(/obj/item/melee/sickly_blade/tide)
	tide.combat_resource = 0
	TEST_ASSERT(grasp.on_mansus_grasp(victim, user, TRUE, null), "Хватка по противнику должна набрать давление.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 2, "Одна хватка даёт две единицы давления.")
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_drenched), "Хватка оставляет воду Пучины.")
	TEST_ASSERT(mark_knowledge.on_mansus_grasp(victim, user, TRUE, null), "Хватка должна оставить метку.")
	blade.afterattack(victim, user, TRUE, null)
	TEST_ASSERT_EQUAL(tide.combat_resource, 2, "Один afterattack без ранения не собирает давление.")
	user.a_intent = INTENT_HARM
	blade.attack(victim, user)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/tide), "Настоящее попадание гарпуном активирует метку.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 4, "Детонация и первое попадание дают по одной единице.")
	TEST_ASSERT(tide.spend_combat_resource(2), "Накопленное давление расходуется.")
	blade.attack(victim, user)
	TEST_ASSERT_EQUAL(tide.combat_resource, 2, "Второе попадание в тот же момент не обходит задержку сбора.")
	tide.gain_combat_resource(100)
	TEST_ASSERT_EQUAL(tide.combat_resource, 4, "Давление не превышает вместимость.")
	TEST_ASSERT(!tide.spend_combat_resource(5), "Нельзя потратить больше доступного запаса.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 4, "Неудачная трата сохраняет запас.")

/// Волна сдвигает врага, обходит союзников и не расходует антимагию на предварительной проверке.
/datum/unit_test/heretic_tide_release_protection/Run()
	var/turf/center = get_step(get_step(get_step(get_step(run_loc_floor_bottom_left, EAST), EAST), NORTH), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(center, EAST))
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(center, NORTH))
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(center, WEST))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/obj/effect/proc_holder/spell/pointed/heretic_tide/undertow/spell = allocate(/obj/effect/proc_holder/spell/pointed/heretic_tide/undertow)
	TEST_ASSERT(!spell.can_target(protected, user, TRUE), "Предварительный выбор распознаёт антимагию.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Выбор цели не расходует заряд защиты.")
	tide.combat_resource = 1
	TEST_ASSERT(!tide.release(user), "Без двух единиц волна не применяется.")
	TEST_ASSERT_EQUAL(protection.charges, 5, "Недостаток давления не расходует антимагию.")
	tide.combat_resource = 4
	TEST_ASSERT(tide.release(user), "Подготовленная волна должна сработать.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 2, "Сброс тратит ровно две единицы.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 18) < 0.001, "Волна наносит восемнадцать ушибов.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 24) < 0.001, "Волна наносит двадцать четыре урона выносливости.")
	TEST_ASSERT_EQUAL(get_dist(user, victim), 3, "Волна смывает соседнего врага на две клетки.")
	TEST_ASSERT(victim.IsKnockdown(), "Волна сбивает противника с ног.")
	TEST_ASSERT_EQUAL(ally.owner.current.getBruteLoss(), 0, "Волна не ранит другого еретика.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Волна не ранит создателя.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия блокирует весь урон волны.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Вся волна расходует один заряд защиты на цель.")

/// Отлив требует знания, не действует сквозь преграду и не перемещает закреплённую цель.
/datum/unit_test/heretic_tide_undertow_obstacles/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/turf/middle = get_step(user, EAST)
	var/turf/destination = get_step(get_step(middle, EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, destination)
	TEST_ASSERT(!tide.undertow(user, victim), "Базовое знание не выдаёт неизученный Отлив.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/tide_undertow)
	var/obj/blocker = allocate(/obj, middle)
	blocker.density = TRUE
	TEST_ASSERT(!tide.undertow(user, victim), "Плотная преграда останавливает течение.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), 0, "За преградой цель не получает урон.")
	qdel(blocker)
	victim.anchored = TRUE
	TEST_ASSERT(tide.undertow(user, victim), "Закрепление не блокирует саму магическую волну.")
	TEST_ASSERT_EQUAL(get_turf(victim), destination, "Закреплённый противник остаётся на месте.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 15) < 0.001, "Отлив наносит урон даже неподвижной цели.")
	victim.anchored = FALSE
	TEST_ASSERT(tide.undertow(user, victim), "Свободную цель можно подтянуть.")
	TEST_ASSERT_EQUAL(get_dist(user, victim), 1, "Отлив переносит цель на две клетки ближе.")
	TEST_ASSERT_EQUAL(tide.combat_resource, initial(tide.combat_resource), "Отлив не создаёт и не расходует давление.")
	var/datum/eldritch_knowledge/spell/tide_undertow/spell_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/tide_undertow)
	var/obj/effect/proc_holder/spell/pointed/heretic_tide/undertow/spell = spell_knowledge.granted_spell
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	spell.charge_counter = 0
	var/stamina_before = victim.getStaminaLoss()
	spell.cast(list(victim), user)
	TEST_ASSERT_EQUAL(protection.charges, 4, "Защита, полученная после выбора цели, расходует один заряд.")
	TEST_ASSERT_EQUAL(spell.charge_counter, 0, "Оплаченный блок антимагией не возвращает перезарядку Отлива.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), stamina_before, "Заблокированный Отлив не наносит урон.")

/// Водоворот разрушается жезлом, заменяется новым и прекращает действовать вдали от владельца.
/datum/unit_test/heretic_tide_well_lifecycle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/tide_well)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/turf/center = get_step(user, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(center, EAST), EAST))
	tide.combat_resource = 4
	TEST_ASSERT(tide.create_well(user, center), "На свободном полу создаётся водоворот.")
	var/obj/structure/heretic_tide_well/first = tide.active_well
	TEST_ASSERT_EQUAL(first.obj_integrity, 60, "У водоворота конечная прочность.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 12) < 0.001, "Создание воронки сразу наносит урон.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 18) < 0.001, "Первое течение изматывает противника.")
	TEST_ASSERT_EQUAL(get_dist(first, victim), 1, "Создание воронки сразу притягивает цель.")
	TEST_ASSERT(first.pulse(), "Водоворот действует в присутствии владельца.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 24) < 0.001, "Ядро воронки наносит ещё двенадцать ушибов.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 30) < 0.001, "Ядро воронки дополнительно изматывает цель.")
	TEST_ASSERT_EQUAL(get_dist(first, victim), 0, "Пульс затягивает цель в саму воронку.")
	TEST_ASSERT(tide.create_well(user, center), "Новый водоворот заменяет старый.")
	TEST_ASSERT(QDELETED(first), "Старая воронка удаляется при создании новой.")
	var/obj/structure/heretic_tide_well/second = tide.active_well
	TEST_ASSERT(!tide.create_well(user, center), "Без давления нельзя заменить воронку.")
	TEST_ASSERT_EQUAL(tide.active_well, second, "Неудачное создание сохраняет действующую воронку.")
	var/datum/component/anti_magic/protection = victim.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	var/stamina_before = victim.getStaminaLoss()
	second.pulse()
	TEST_ASSERT_EQUAL(protection.charges, 4, "Пульс расходует один заряд антимагии.")
	TEST_ASSERT_EQUAL(victim.getStaminaLoss(), stamina_before, "Защищённый противник не получает урон пульса.")
	var/turf/original_turf = get_turf(user)
	user.forceMove(locate(original_turf.x + 10, original_turf.y, original_turf.z))
	TEST_ASSERT(!second.pulse(), "Водоворот не действует вдали от своего владельца.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Неактивная воронка не расходует защиту.")
	user.forceMove(original_turf)
	var/obj/item/nullrod/rod = allocate(/obj/item/nullrod)
	second.attackby(rod, victim)
	TEST_ASSERT(QDELETED(second), "Нулевой жезл уничтожает водоворот.")
	TEST_ASSERT_NULL(tide.active_well, "Разрушенная воронка освобождает ссылку владельца.")

/// Обрушение расходует запас один раз и не расширяется на клетки, открытые после предупреждения.
/datum/unit_test/heretic_tide_deluge_telegraph/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/tide_deluge)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/turf/hidden = get_step(center, EAST)
	var/obj/blocker = allocate(/obj, hidden)
	blocker.density = TRUE
	var/list/warned = tide.deluge_turfs(user, center)
	TEST_ASSERT(center in warned, "Центр входит в предупреждённую область.")
	TEST_ASSERT(!(hidden in warned), "Клетка за преградой не получает предупреждение.")
	qdel(blocker)
	var/mob/living/unwarned = allocate(/mob/living/carbon/human, hidden)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(center, NORTH))
	var/mob/living/protected = allocate(/mob/living/carbon/human, get_step(center, WEST))
	var/datum/component/anti_magic/protection = protected.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	tide.combat_resource = 4
	TEST_ASSERT(!tide.deluge(user, center, list(), tide.tide_generation), "Без предупреждённых клеток обрушения нет.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 4, "Отказ сохраняет давление.")
	TEST_ASSERT(tide.deluge(user, center, warned, tide.tide_generation), "Подготовленное обрушение должно завершиться.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 44) < 0.001, "Четыре единицы дают сорок четыре ушиба.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 32) < 0.001, "Четыре единицы дают тридцать два урона выносливости.")
	TEST_ASSERT(victim.IsKnockdown(), "Обрушение сбивает противника.")
	TEST_ASSERT_EQUAL(unwarned.getBruteLoss(), 0, "Открытие прохода не добавляет непредупреждённую цель.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия защищает от обрушения.")
	TEST_ASSERT_EQUAL(protection.charges, 4, "Обрушение расходует один заряд защиты.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 0, "Обрушение расходует весь исходный запас.")
	TEST_ASSERT(!tide.deluge(user, center, warned, tide.tide_generation), "Без нового запаса повторить удар нельзя.")
	var/original_generation = tide.tide_generation
	tide.on_death(user)
	tide.combat_resource = 4
	TEST_ASSERT(!tide.deluge(user, center, warned, original_generation), "Даже после быстрого оживления старое предупреждение теряет силу.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 4, "Отменённая смертью подготовка сохраняет новый запас.")
	original_generation = tide.tide_generation
	tide.on_body_lose(user)
	tide.on_body_gain(user)
	TEST_ASSERT(!tide.deluge(user, center, warned, original_generation), "Уход из тела и возврат не восстанавливают старую подготовку.")

/// Замена воды передаёт её новому источнику, а удаление роли снимает только собственные эффекты.
/datum/unit_test/heretic_tide_drenched_cleanup/Run()
	var/datum/antagonist/heretic/first = allocate_heretic()
	var/datum/antagonist/heretic/second = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	first.selected_path = PATH_TIDE
	second.selected_path = PATH_TIDE
	first.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	second.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/base_tide/first_tide = first.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/base_tide/second_tide = second.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	first_tide.soak(victim)
	victim.apply_status_effect(/datum/status_effect/eldritch/tide, first_tide)
	TEST_ASSERT_EQUAL(length(first_tide.marks), 1, "Знание отслеживает собственную метку.")
	TEST_ASSERT_EQUAL(length(first_tide.drenched), 1, "Знание отслеживает собственную воду.")
	second_tide.soak(victim)
	TEST_ASSERT_EQUAL(length(first_tide.drenched), 0, "Замена снимает эффект из списка прежнего владельца.")
	TEST_ASSERT_EQUAL(length(second_tide.drenched), 1, "Новая вода принадлежит второму еретику.")
	TEST_ASSERT_EQUAL(length(victim.has_status_effect_list(/datum/status_effect/heretic_drenched)), 1, "Вода не складывается на одной цели.")
	qdel(first)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_drenched), "Удаление первой роли не снимает чужую воду.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/tide), "Удаление первой роли снимает её собственную метку.")
	victim.remove_status_effect(/datum/status_effect/heretic_drenched)
	TEST_ASSERT_EQUAL(length(second_tide.drenched), 0, "Обычное снятие статуса освобождает список владельца.")
	second_tide.soak(victim)
	victim.apply_status_effect(/datum/status_effect/eldritch/tide, second_tide)
	qdel(second)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_drenched), "Удаление роли снимает оставшуюся воду.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/tide), "Удаление роли снимает оставшуюся метку.")

/// Колокол принадлежит создателю, переключает направление волны и допускает замену только после уничтожения.
/datum/unit_test/heretic_tide_bell/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/tide_bell)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/tide_bell/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/tide_bell)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Обряд создаёт колокол.")
	var/obj/item/heretic_path_relic/tide_bell/bell = recipe.new_path_relic_ref.resolve()
	allocated += bell
	TEST_ASSERT(!recipe.on_finished_recipe(user, list(), get_turf(user)), "Второй колокол нельзя создать, пока первый существует.")
	TEST_ASSERT(!bell.ring(user), "Колокол на полу не подчиняется мысленному приказу.")
	user.put_in_hands(bell)
	TEST_ASSERT(bell.ring(user), "Создатель может позвонить колоколом в руке.")
	TEST_ASSERT(tide.inward_tide, "Звон переключает отталкивание на притяжение.")
	TEST_ASSERT(!bell.ring(user), "Повторный звон ограничен перезарядкой.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	tide.combat_resource = 2
	TEST_ASSERT(tide.release(user), "Переключённая волна расходует обычный запас.")
	TEST_ASSERT_EQUAL(get_dist(user, victim), 1, "Прилив действительно притягивает противника на клетку.")
	var/datum/antagonist/heretic/stranger = allocate_heretic(get_step(user, NORTH))
	user.dropItemToGround(bell, TRUE)
	stranger.owner.current.put_in_hands(bell)
	COOLDOWN_RESET(bell, relic_cooldown)
	TEST_ASSERT(!bell.ring(stranger.owner.current), "Другой еретик не может настроить чужой колокол.")
	qdel(bell)
	TEST_ASSERT(recipe.new_path_relic_available(), "Разбитый колокол освобождает рецепт.")

/// Пассивка расширяет вместимость без бесплатного ресурса; смерть убирает воронку, воду и запас.
/datum/unit_test/heretic_tide_capacity_and_death/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/tide_depth)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/tide_well)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/tide_depth/depth = heretic.get_knowledge(/datum/eldritch_knowledge/tide_depth)
	TEST_ASSERT_EQUAL(tide.combat_resource_max, 5, "Первая ступень пассивки расширяет вместимость до пяти.")
	TEST_ASSERT_EQUAL(tide.combat_resource, initial(tide.combat_resource), "Изучение не заполняет дополнительную вместимость.")
	depth.passive_level = 3
	depth.on_passive_upgrade(user)
	TEST_ASSERT_EQUAL(tide.combat_resource_max, 7, "Третья ступень пассивки расширяет вместимость до семи.")
	TEST_ASSERT_EQUAL(tide.combat_resource, initial(tide.combat_resource), "Улучшение также не создаёт давление.")
	heretic.ascended = TRUE
	tide.update_capacity()
	TEST_ASSERT_EQUAL(tide.combat_resource_max, 8, "После вознесения вмещаются восемь единиц.")
	tide.combat_resource = 1
	TEST_ASSERT(!tide.release(user), "Даже вознесённый обычный сброс требует две единицы.")
	tide.combat_resource = 4
	TEST_ASSERT(tide.create_well(user, get_turf(user)), "Перед смертью существует воронка.")
	var/obj/structure/heretic_tide_well/well = tide.active_well
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, EAST))
	tide.soak(victim)
	victim.apply_status_effect(/datum/status_effect/eldritch/tide, tide)
	user.stat = DEAD
	tide.on_death(user)
	TEST_ASSERT(QDELETED(well), "Смерть немедленно убирает водоворот.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 0, "Смерть сбрасывает накопленное давление.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_drenched), "Смерть освобождает противника от воды.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/tide), "Смерть убирает метку с чужого тела.")
	TEST_ASSERT(!tide.release(user, ascended_wave = TRUE), "Мёртвый владелец не выпускает бесплатную волну.")
	var/obj/effect/proc_holder/spell/power = tide.combat_power
	tide.on_body_lose(user)
	TEST_ASSERT(QDELETED(power), "Отвязка тела удаляет исходную способность.")
	TEST_ASSERT_NULL(tide.tide_body, "Отвязка освобождает ссылку на старое тело.")

/// Снос в преграду наносит один удар и не проталкивает противника сквозь неё.
/datum/unit_test/heretic_tide_wave_collision/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, EAST), NORTH)
	var/datum/antagonist/heretic/heretic = allocate_heretic(center)
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/turf/victim_place = get_step(user, EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, victim_place)
	var/obj/blocker = allocate(/obj, get_step(victim, EAST))
	blocker.density = TRUE
	TEST_ASSERT(tide.release(user), "Начального давления хватает на волну без подготовительных ударов.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 26) < 0.001, "Волна и одно столкновение дают 26 ушибов.")
	TEST_ASSERT_EQUAL(get_turf(victim), victim_place, "Преграда останавливает снос.")
	TEST_ASSERT(victim.IsKnockdown(), "Столкновение сбивает противника.")
	TEST_ASSERT_NOTNULL(center.GetComponent(/datum/component/wet_floor), "Волна действительно оставляет скользкий пол.")

/// Давление восстанавливается без противника, а защита от воды переходит вместе с ролью.
/datum/unit_test/heretic_tide_regeneration_and_water/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_NOSLIPWATER), "Путь сразу защищает от мокрого пола.")
	tide.combat_resource = 0
	COOLDOWN_RESET(tide, ascended_pressure)
	tide.on_life(user)
	TEST_ASSERT_EQUAL(tide.combat_resource, 1, "Без противника восстанавливается единица давления.")
	tide.on_life(user)
	TEST_ASSERT_EQUAL(tide.combat_resource, 1, "Повторный life соблюдает задержку восстановления.")
	ADD_TRAIT(user, TRAIT_NOSLIPWATER, "unit_test")
	var/mob/living/new_body = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	heretic.owner.transfer_to(new_body)
	TEST_ASSERT(HAS_TRAIT(new_body, TRAIT_NOSLIPWATER), "Новое тело получает защиту от воды.")
	TEST_ASSERT(HAS_TRAIT(user, TRAIT_NOSLIPWATER), "Независимый источник защиты старого тела сохраняется.")
	REMOVE_TRAIT(user, TRAIT_NOSLIPWATER, "unit_test")
	TEST_ASSERT(!HAS_TRAIT(user, TRAIT_NOSLIPWATER), "Источник роли снят со старого тела.")
	qdel(tide)
	TEST_ASSERT(!HAS_TRAIT(new_body, TRAIT_NOSLIPWATER), "Удаление знания снимает его защиту.")

/// Волны обновляют короткую лужу без накопления срока и без сокращения уже разлитой воды.
/datum/unit_test/heretic_tide_puddle_duration/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/turf/open/place = get_turf(heretic.owner.current)
	place.ClearWet()
	tide.wet_floor(place)
	var/datum/component/wet_floor/water = place.GetComponent(/datum/component/wet_floor)
	TEST_ASSERT_NOTNULL(water, "Магия оставляет компонент мокрого пола.")
	for(var/pulse_index in 1 to 6)
		tide.wet_floor(place)
	TEST_ASSERT_EQUAL(water.max_time_left(), 15 SECONDS, "Повторные волны не складывают время одной лужи.")
	water.time_left_list["[TURF_WET_WATER]"] = 3 SECONDS
	tide.wet_floor(place)
	TEST_ASSERT_EQUAL(water.max_time_left(), 15 SECONDS, "Подсыхающая лужа обновляется до пятнадцати секунд.")
	place.MakeSlippery(TURF_WET_WATER, min_wet_time = 1 MINUTES)
	tide.wet_floor(place)
	TEST_ASSERT_EQUAL(water.max_time_left(), 1 MINUTES, "Чужая вода с большим сроком не высыхает от волны раньше.")
