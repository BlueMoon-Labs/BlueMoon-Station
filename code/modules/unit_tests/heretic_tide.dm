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
	TEST_ASSERT_EQUAL(round(victim.AmountKnockdown(), 0.01), 2.5 SECONDS, "Сброс оставляет время на продолжение атаки или отход.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched), "Волна замедляет намокшую цель.")
	TEST_ASSERT_EQUAL(ally.owner.current.getBruteLoss(), 0, "Волна не ранит другого еретика.")
	TEST_ASSERT_EQUAL(user.getBruteLoss(), 0, "Волна не ранит создателя.")
	TEST_ASSERT_EQUAL(protected.getBruteLoss(), 0, "Антимагия блокирует весь урон волны.")
	TEST_ASSERT(!protected.has_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched), "Антимагия защищает и от замедления.")
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
	TEST_ASSERT_EQUAL(round(victim.AmountKnockdown(), 0.01), 2 SECONDS, "Отлив удерживает противника на полу после сближения.")
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

/// Стол между еретиком и целью не закрывает Отлив, а отказ отличает пустой выбор от преграды.
/datum/unit_test/heretic_tide_undertow_table/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/tide_undertow)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/spell/tide_undertow/spell_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/tide_undertow)
	var/obj/effect/proc_holder/spell/pointed/heretic_tide/undertow/spell = spell_knowledge.granted_spell
	var/turf/table_place = locate(user.x + 2, user.y, user.z)
	var/mob/living/victim = allocate(/mob/living/carbon/human, locate(user.x + 4, user.y, user.z))
	allocate(/obj/structure/table, table_place)
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Стол не закрывает выбор цели.")
	TEST_ASSERT(tide.undertow(user, victim), "Отлив действует через стол.")
	TEST_ASSERT(victim.getBruteLoss() >= 15, "Цель за столом получает урон Отлива.")
	TEST_ASSERT(get_dist(user, victim) < 4, "Течение подтягивает цель к столу.")
	TEST_ASSERT(!spell.can_target(locate(user.x + 1, user.y, user.z), user, TRUE), "Пустой пол не становится целью Отлива.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "Цели нет"), "Отказ без цели так и называется.")
	var/obj/machinery/hydroponics/machine = allocate(/obj/machinery/hydroponics, locate(user.x + 1, user.y, user.z))
	TEST_ASSERT(machine.density, "Лоток гидропоники плотный.")
	TEST_ASSERT(!spell.can_target(victim, user, TRUE), "Плотная машина закрывает линию.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "преграда"), "Отказ называет преграду, а не отсутствие цели.")

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
	ADD_TRAIT(victim, TRAIT_NOSLIPWATER, REF(src))
	tide.combat_resource = 4
	TEST_ASSERT(tide.create_well(user, center), "На свободном полу создаётся водоворот.")
	var/obj/structure/heretic_tide_well/first = tide.active_well
	TEST_ASSERT_EQUAL(first.obj_integrity, 60, "У водоворота конечная прочность.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 12) < 0.001, "Создание воронки сразу наносит урон.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 18) < 0.001, "Первое течение изматывает противника.")
	TEST_ASSERT_EQUAL(get_dist(first, victim), 1, "Создание воронки сразу притягивает цель.")
	TEST_ASSERT_EQUAL(round(victim.AmountKnockdown(), 0.01), 1.5 SECONDS, "Первый удар воронки даёт время воспользоваться притяжением.")
	victim.SetKnockdown(0)
	TEST_ASSERT(first.pulse(), "Водоворот действует в присутствии владельца.")
	TEST_ASSERT_EQUAL(round(victim.AmountKnockdown(), 0.01), 0.6 SECONDS, "Повторный пульс оставляет возможность выбраться между ударами.")
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

/// Реальная подготовка допускает шаг в пределах двух клеток и отменяет дальний отход.
/datum/unit_test/heretic_tide_deluge_movement/Run()
	var/turf/origin = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(origin)
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/tide_deluge)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/obj/effect/proc_holder/spell/pointed/heretic_tide/deluge/spell = allocate(/obj/effect/proc_holder/spell/pointed/heretic_tide/deluge)
	var/turf/center = get_step(get_step(origin, EAST), EAST)
	var/mob/living/victim = allocate(/mob/living/carbon/human, center)
	var/turf/nearby = get_step(get_step(origin, NORTH), NORTH)
	tide.combat_resource = 4
	addtimer(CALLBACK(user, TYPE_PROC_REF(/atom/movable, forceMove), nearby), 0.2 SECONDS)
	spell.cast(list(center), user)
	TEST_ASSERT_EQUAL(user.loc, nearby, "Игрок действительно сместился во время подготовки.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 44) <= DAMAGE_PRECISION, "Две клетки движения сохраняют полный удар по прежней области.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 0, "Успешный удар расходует давление.")
	user.forceMove(origin)
	tide.combat_resource = 4
	var/turf/distant = get_step(nearby, NORTH)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/atom/movable, forceMove), distant), 0.2 SECONDS)
	spell.cast(list(center), user)
	TEST_ASSERT_EQUAL(user.loc, distant, "Игрок вышел за допустимые две клетки.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 44) <= DAMAGE_PRECISION, "Прерванный удар не наносит дополнительного урона.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 4, "Прерывание сохраняет запас.")
	user.forceMove(origin)
	var/obj/blocker = allocate(/obj, get_step(origin, EAST))
	blocker.density = TRUE
	TEST_ASSERT(!tide.can_prepare_deluge(user, origin, center, tide.tide_generation), "Преграда разрывает подготовку даже в пределах шага.")
	qdel(blocker)
	user.Paralyze(1 SECONDS)
	TEST_ASSERT(!tide.can_prepare_deluge(user, origin, center, tide.tide_generation), "Оглушение по-прежнему прерывает подготовку.")

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
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched), "Замена воды сохраняет замедление нового владельца.")
	qdel(first)
	TEST_ASSERT(victim.has_status_effect(/datum/status_effect/heretic_drenched), "Удаление первой роли не снимает чужую воду.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/tide), "Удаление первой роли снимает её собственную метку.")
	victim.remove_status_effect(/datum/status_effect/heretic_drenched)
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched), "Окончание намокания снимает замедление.")
	TEST_ASSERT_EQUAL(length(second_tide.drenched), 0, "Обычное снятие статуса освобождает список владельца.")
	second_tide.soak(victim)
	victim.apply_status_effect(/datum/status_effect/eldritch/tide, second_tide)
	qdel(second)
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_drenched), "Удаление роли снимает оставшуюся воду.")
	TEST_ASSERT(!victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched), "Удаление владельца не оставляет замедление на цели.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/tide), "Удаление роли снимает оставшуюся метку.")

/// Нескользящая обувь не блокирует течение, а иммунитет к оглушению сохраняется.
/datum/unit_test/heretic_tide_undertow_obstacles/nonslip/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/tide_undertow)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(get_step(user, EAST), EAST))
	ADD_TRAIT(victim, TRAIT_NOSLIPALL, TRAIT_SOURCE_UNIT_TESTS)
	TEST_ASSERT(tide.undertow(user, victim), "Нескользящая цель поддаётся Отливу.")
	TEST_ASSERT_EQUAL(round(victim.AmountKnockdown(), 0.01), 2 SECONDS, "Прямое опрокидывание не зависит от обуви.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched), "Нескользящая цель замедляется после волны.")
	victim.SetKnockdown(0)
	ADD_TRAIT(victim, TRAIT_STUNIMMUNE, TRAIT_SOURCE_UNIT_TESTS)
	TEST_ASSERT(tide.undertow(user, victim), "Иммунитет к оглушению не отменяет саму волну.")
	TEST_ASSERT(!victim.IsKnockdown(), "Отлив не обходит иммунитет к оглушению.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched), "Замедление позволяет продолжить бой с устойчивой целью.")

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

/// Колокол обращает существующую воронку наружу без дополнительного пульса и падения.
/datum/unit_test/heretic_tide_outward_well/Run()
	var/turf/center = get_step(get_step(run_loc_floor_bottom_left, NORTHEAST), NORTHEAST)
	var/datum/antagonist/heretic/heretic = allocate_heretic(get_step(center, WEST))
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/tide_bell)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/tide_well)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/tide_bell/recipe = heretic.get_knowledge(/datum/eldritch_knowledge/tide_bell)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), get_turf(user)), "Создаётся личный колокол.")
	var/obj/item/heretic_path_relic/tide_bell/bell = recipe.new_path_relic_ref.resolve()
	allocated += bell
	user.put_in_hands(bell)
	TEST_ASSERT(tide.create_well(user, center), "Создаётся воронка.")
	var/obj/structure/heretic_tide_well/well = tide.active_well
	var/expiry_before = well.expires_at
	var/pulse_before = well.well_pulse
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(center, EAST))
	TEST_ASSERT(bell.afterattack(well, user, FALSE), "Колокол выбирает именно существующую воронку.")
	TEST_ASSERT(well.outward, "Воронка переходит в режим отвода.")
	TEST_ASSERT_EQUAL(well.expires_at, expiry_before, "Переключение сохраняет срок жизни.")
	TEST_ASSERT_EQUAL(well.well_pulse, pulse_before, "Переключение сохраняет расписание пульсов.")
	TEST_ASSERT_EQUAL(victim.getBruteLoss(), 0, "Переключение не создаёт мгновенный удар.")
	TEST_ASSERT(well.pulse(), "Следующий пульс использует наружное течение.")
	TEST_ASSERT_EQUAL(get_dist(well, victim), 2, "Наружный поток отодвигает на одну клетку.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 6) <= DAMAGE_PRECISION, "Наружный пульс использует слабый урон края.")
	TEST_ASSERT(!victim.IsKnockdown(), "Наружный пульс не сбивает с ног.")
	var/obj/blocker = allocate(/obj, get_step(victim, EAST))
	blocker.density = TRUE
	TEST_ASSERT(well.pulse(), "Преграда останавливает наружное перемещение.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 12) <= DAMAGE_PRECISION, "Преграда не добавляет столкновительный урон.")
	TEST_ASSERT(!victim.IsKnockdown(), "Упор в стену не превращает отвод в повторяющееся падение.")
	TEST_ASSERT(!bell.redirect_well(user, well), "Повторное переключение ограничено перезарядкой колокола.")
	COOLDOWN_RESET(bell, relic_cooldown)
	TEST_ASSERT(bell.redirect_well(user, well) && !well.outward, "Колокол возвращает обычное притяжение.")

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
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	var/datum/eldritch_knowledge/final_eldritch/tide_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
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
	heretic.handle_death(user)
	TEST_ASSERT(QDELETED(well), "Смерть немедленно убирает водоворот.")
	TEST_ASSERT_EQUAL(tide.combat_resource, 0, "Смерть сбрасывает накопленное давление.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/heretic_drenched), "Смерть освобождает противника от воды.")
	TEST_ASSERT(!victim.has_status_effect(/datum/status_effect/eldritch/tide), "Смерть убирает метку с чужого тела.")
	TEST_ASSERT(!tide.release(user, ascended_wave = TRUE), "Мёртвый владелец не выпускает бесплатную волну.")
	TEST_ASSERT_EQUAL(tide.combat_resource_max, 7, "Смерть возвращает вместимость пассивки.")
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

/// Смерть снимает силу вознесения Пучины при сохранённом вознесении роли, оживление возвращает её.
/datum/unit_test/heretic_tide_ascension_death_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/final_eldritch/tide_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	heretic.ascended = TRUE
	finale.finished = TRUE
	finale.on_body_gain(user)
	TEST_ASSERT_EQUAL(tide.combat_resource_max, 8, "Вознесение даёт запас давления 8.")
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT_EQUAL(tide.combat_resource_max, initial(tide.combat_resource_max), "Смерть возвращает обычный запас давления.")
	TEST_ASSERT(heretic.ascended, "Смерть не отменяет само вознесение роли.")
	user.revive(full_heal = TRUE)
	finale.on_life(user)
	TEST_ASSERT_EQUAL(tide.combat_resource_max, 8, "Оживление возвращает запас давления 8.")
	TEST_ASSERT(tide.release(user, ascended_wave = TRUE), "Оживлённый снова выпускает Голос Пучины.")

/datum/unit_test/proc/tide_flood_puddles(turf/place)
	. = 0
	for(var/obj/effect/heretic_tide_puddle/puddle in place)
		.++

/// Вознёсшаяся Пучина заливает пол в двух клетках без дублей и без скользкой воды, не пропускает её за окна, мочит врагов в воде и в следе и ускоряет героя на своей воде.
/datum/unit_test/heretic_tide_flood/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/final_eldritch/tide_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	var/turf/near = locate(start.x + 1, start.y + 1, start.z)
	var/turf/edge = locate(start.x + 2, start.y, start.z)
	var/turf/dry = locate(start.x + 3, start.y, start.z)
	var/turf/far = locate(start.x + 4, start.y, start.z)
	var/turf/glazed = locate(start.x, start.y + 1, start.z)
	var/turf/behind_glass = locate(start.x, start.y + 2, start.z)
	allocate(/obj/structure/window/fulltile, glazed)
	var/mob/living/carbon/human/crew = allocate(/mob/living/carbon/human, near)
	var/mob/living/carbon/human/distant = allocate(/mob/living/carbon/human, dry)
	var/mob/living/carbon/human/sheltered = allocate(/mob/living/carbon/human, behind_glass)
	var/mob/living/carbon/human/pursuer = allocate(/mob/living/carbon/human, locate(start.x + 4, start.y + 2, start.z))
	var/mob/living/carbon/human/warded = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y + 2, start.z))
	var/datum/component/anti_magic/ward = warded.AddComponent(/datum/component/anti_magic, TRUE, FALSE, FALSE, null, 5)
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(user)
	var/datum/component/heretic_tide_flood/flood = user.GetComponent(/datum/component/heretic_tide_flood)
	TEST_ASSERT_NOTNULL(flood, "Вознесение Пучины заливает пол вокруг героя.")
	flood.flood()
	TEST_ASSERT_EQUAL(tide_flood_puddles(start), 1, "Под героем одна лужа, повторный прилив её обновляет.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(near), 1, "Соседняя клетка залита один раз.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(edge), 1, "Вода доходит до двух клеток.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(dry), 0, "Третья клетка остаётся сухой.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(glazed) + tide_flood_puddles(behind_glass), 0, "Окно не пропускает воду ни на свою клетку, ни за себя.")
	TEST_ASSERT(!sheltered.has_status_effect(/datum/status_effect/heretic_drenched), "Враг за окном сух.")
	TEST_ASSERT_NULL(near.GetComponent(/datum/component/wet_floor), "Прилив не делает пол скользким.")
	var/obj/effect/heretic_tide_puddle/puddle = locate() in near
	TEST_ASSERT(puddle.expires_at > world.time && puddle.expires_at <= world.time + HERETIC_TIDE_FLOOD_LIFETIME, "Лужа живёт недолго и уходит без обновления.")
	var/datum/status_effect/heretic_drenched/water = crew.has_status_effect(/datum/status_effect/heretic_drenched)
	TEST_ASSERT_NOTNULL(water, "Враг в воде намокает.")
	TEST_ASSERT(!distant.has_status_effect(/datum/status_effect/heretic_drenched), "Враг дальше двух клеток сух.")
	TEST_ASSERT(!warded.has_status_effect(/datum/status_effect/heretic_drenched), "Защита от магии не даёт намокнуть.")
	TEST_ASSERT_EQUAL(ward.charges, 5, "Проверка защиты не тратит заряды.")
	water.duration = world.time + 1
	flood.flood()
	TEST_ASSERT_EQUAL(crew.has_status_effect(/datum/status_effect/heretic_drenched), water, "Стоящего в воде прилив не перемачивает заново.")
	TEST_ASSERT_EQUAL(water.duration, world.time + initial(water.duration), "Намокание продлевается на полный срок.")
	distant.forceMove(edge)
	TEST_ASSERT(distant.has_status_effect(/datum/status_effect/heretic_drenched), "Шаг в воду сразу мочит врага.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow), "На своей воде герой быстрее.")
	user.forceMove(dry)
	TEST_ASSERT_EQUAL(tide_flood_puddles(dry), 1, "Шаг героя оставляет лужу.")
	user.forceMove(far)
	TEST_ASSERT_EQUAL(tide_flood_puddles(far), 1, "След тянется за героем без дублей.")
	TEST_ASSERT(user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow), "На ходу герой остаётся в своей воде.")
	pursuer.forceMove(dry)
	TEST_ASSERT(pursuer.has_status_effect(/datum/status_effect/heretic_drenched), "Преследователь в следе намокает.")
	qdel(locate(/obj/effect/heretic_tide_puddle) in far)
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow), "Ушедшая из-под ног вода снимает ускорение.")
	var/list/examine_lines = list()
	SEND_SIGNAL(user, COMSIG_PARENT_EXAMINE, crew, examine_lines)
	TEST_ASSERT(findtext(jointext(examine_lines, " "), "двух клеток"), "Осмотр называет радиус воды.")
	user.death()
	heretic.handle_death(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_tide_flood), "Смерть снимает прилив.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow), "Смерть снимает ускорение.")
	user.revive(full_heal = TRUE)
	finale.on_life(user)
	flood = user.GetComponent(/datum/component/heretic_tide_flood)
	TEST_ASSERT_NOTNULL(flood, "Оживление возвращает прилив.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(far), 1, "Ожившего снова окружает вода.")
	finale.on_body_lose(user)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_tide_flood), "Потеря тела снимает прилив.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(far), 0, "Потеря тела убирает воду.")
	TEST_ASSERT(!user.has_movespeed_modifier(/datum/movespeed_modifier/heretic_tide_flow), "Потеря тела снимает ускорение.")
	TEST_ASSERT(!tide.ascension_active, "Потеря тела снимает флаг вознесения.")

/// Направленное окно держит воду только со своей стороны, а окно и перила на клетке героя не глушат прилив.
/datum/unit_test/heretic_tide_flood_edges/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = allocate_heretic(start)
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/final_eldritch/tide_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	var/turf/north = locate(start.x, start.y + 1, start.z)
	var/turf/east = locate(start.x + 1, start.y, start.z)
	var/turf/beyond_east = locate(start.x + 2, start.y, start.z)
	var/turf/diagonal = locate(start.x + 1, start.y + 1, start.z)
	var/obj/structure/window/own_pane = allocate(/obj/structure/window, start)
	own_pane.setDir(NORTH)
	var/obj/structure/railing/rail = allocate(/obj/structure/railing, start)
	rail.setDir(EAST)
	var/obj/structure/window/far_pane = allocate(/obj/structure/window, east)
	far_pane.setDir(EAST)
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(user)
	var/datum/component/heretic_tide_flood/flood = user.GetComponent(/datum/component/heretic_tide_flood)
	flood.flood()
	TEST_ASSERT_EQUAL(tide_flood_puddles(start), 1, "Окно и перила на клетке героя не мешают луже под ним.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(east), 1, "Перила и окно на северной грани пропускают воду на восток.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(north), 0, "Окно на клетке героя держит воду со своей стороны.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(diagonal), 1, "Вода обтекает окно через соседнюю клетку.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(beyond_east), 0, "Окно на дальней грани соседней клетки не пропускает воду дальше.")
	TEST_ASSERT(tide.line_clear(start, east), "Цель за перилами на открытой линии.")
	TEST_ASSERT(!tide.line_clear(start, beyond_east), "Окно на дальней грани соседней клетки закрывает линию.")

/// Перенос разума в мёртвое тело снимает прилив и флаг вознесения со старого тела.
/datum/unit_test/heretic_tide_flood_transfer/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/final_eldritch/tide_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(user)
	TEST_ASSERT(tide.ascension_active, "Вознесение включено.")
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	corpse.death()
	heretic.owner.transfer_to(corpse)
	TEST_ASSERT_NULL(user.GetComponent(/datum/component/heretic_tide_flood), "Старое тело больше не заливает пол.")
	TEST_ASSERT_NULL(corpse.GetComponent(/datum/component/heretic_tide_flood), "Мёртвое тело не получает прилив.")
	TEST_ASSERT(!tide.ascension_active, "Флаг вознесения снят, хотя разум уже в другом теле.")

/datum/unit_test/proc/ascend_tide_flood(turf/place)
	var/datum/antagonist/heretic/heretic = allocate_heretic(place)
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	var/datum/eldritch_knowledge/final_eldritch/tide_final/finale = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/tide_final)
	finale.finished = TRUE
	heretic.ascended = TRUE
	finale.on_body_gain(heretic.owner.current)
	return heretic

/// Лужи прилива: срок прежний, ушедшая вода в срок и раньше стекает отпечатком, шаг по своей воде даёт брызги не чаще раза в 0.3 с и только при зрителях.
/datum/unit_test/heretic_tide_puddle_visuals/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = ascend_tide_flood(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/component/heretic_tide_flood/flood = user.GetComponent(/datum/component/heretic_tide_flood)
	flood.flood()
	var/turf/near = locate(start.x + 1, start.y + 1, start.z)
	var/obj/effect/heretic_tide_puddle/puddle = locate() in near
	TEST_ASSERT_NOTNULL(puddle, "Прилив заливает пол, как раньше.")
	TEST_ASSERT(timeleft(puddle.expiry_timer) <= HERETIC_TIDE_FLOOD_LIFETIME + DAMAGE_PRECISION, "Лужа живёт прежние 4 секунды.")
	TEST_ASSERT(puddle.mouse_opacity == MOUSE_OPACITY_TRANSPARENT, "Лужа не мешает кликам.")
	qdel(puddle)
	TEST_ASSERT_EQUAL(tide_flood_puddles(near), 0, "Сама лужа убрана сразу.")
	var/obj/effect/temp_visual/heretic_vfx/ghost/drain = locate() in near
	TEST_ASSERT_NOTNULL(drain, "Убранная раньше срока вода стекает, а не пропадает.")
	TEST_ASSERT_EQUAL(drain.plane, FLOOR_PLANE, "Стекающий отпечаток лежит на полу.")
	TEST_ASSERT(wait_for_qdeleted(drain), "Отпечаток стекает до конца.")
	var/turf/far = run_loc_floor_top_right
	var/obj/effect/heretic_tide_puddle/expiring = new(far, flood)
	TEST_ASSERT(wait_for_qdeleted(expiring, HERETIC_TIDE_FLOOD_LIFETIME + 1 SECONDS), "Лужа без хозяина рядом уходит по сроку.")
	var/obj/effect/temp_visual/heretic_vfx/ghost/expired_drain = locate() in far
	TEST_ASSERT_NOTNULL(expired_drain, "Вода, ушедшая в срок, тоже стекает отпечатком.")
	var/turf/place = get_turf(user)
	var/list/before = list_vfx_bursts(place)
	flood.splash_step(place)
	var/obj/effect/temp_visual/heretic_vfx/burst/splash = find_vfx_burst(place, /particles/heretic_ascension/tide/step, before)
	TEST_ASSERT_NOTNULL(splash, "Из-под шага по своей воде летят брызги.")
	TEST_ASSERT_NULL(splash.glow, "Брызги не светятся сами.")
	TEST_ASSERT(!COOLDOWN_FINISHED(flood, step_splash), "Брызги не чаще раза в 0.3 секунды.")
	var/turf/next = get_step(place, EAST)
	var/list/next_before = list_vfx_bursts(next)
	COOLDOWN_RESET(flood, step_splash)
	user.forceMove(next)
	TEST_ASSERT_NULL(find_vfx_burst(next, /particles/heretic_ascension/tide/step, next_before), "Без зрителей рядом брызги не рисуются.")
	TEST_ASSERT_EQUAL(tide_flood_puddles(next), 1, "Шаг оставляет лужу, как раньше.")
	TEST_ASSERT(wait_for_qdeleted(splash), "Брызги опадают.")

/// С намокшего капает вода вместо лужи-наклейки под ним; замена воды не копит капли, снятие отпускает последние.
/datum/unit_test/heretic_tide_drenched_drips/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_TIDE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_tide)
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))
	tide.soak(victim)
	var/datum/status_effect/heretic_drenched/water = victim.has_status_effect(/datum/status_effect/heretic_drenched)
	TEST_ASSERT_NOTNULL(water, "Вода Пучины мочит цель, как раньше.")
	TEST_ASSERT(victim.has_movespeed_modifier(/datum/movespeed_modifier/heretic_drenched), "Замедление прежнее.")
	var/obj/effect/abstract/heretic_particle_holder/drips = water.drips
	TEST_ASSERT_NOTNULL(drips, "С намокшего капает вода.")
	TEST_ASSERT(drips in victim.vis_contents, "Капли идут от самой цели.")
	TEST_ASSERT(drips.particles.count <= 10, "Капель немного.")
	TEST_ASSERT_NULL(drips.glow, "Капли не светятся сами.")
	for(var/mutable_appearance/overlay as anything in victim.overlays)
		TEST_ASSERT(overlay.icon_state != "tide_puddle", "Под намокшим больше нет лужи-наклейки.")
	tide.soak(victim)
	var/holders = 0
	for(var/obj/effect/abstract/heretic_particle_holder/holder in victim.vis_contents)
		holders++
	TEST_ASSERT_EQUAL(holders, 1, "Повторное намокание не копит капли.")
	TEST_ASSERT(QDELETED(drips) || drips.loc == get_turf(victim), "Прежние капли падают на пол.")
	var/datum/status_effect/heretic_drenched/fresh_water = victim.has_status_effect(/datum/status_effect/heretic_drenched)
	var/obj/effect/abstract/heretic_particle_holder/last_drips = fresh_water.drips
	victim.remove_status_effect(/datum/status_effect/heretic_drenched)
	TEST_ASSERT(!(last_drips in victim.vis_contents), "Высохшая цель больше не капает.")
	TEST_ASSERT(QDELETED(last_drips) || !last_drips.particles.spawning, "Новые капли не появляются.")
	TEST_ASSERT(wait_for_qdeleted(last_drips), "Последние капли падают и исчезают.")

/// Голос Пучины: вода встаёт короной вокруг героя, волна и пена расходятся, пол дрожит; урон прежний.
/datum/unit_test/heretic_tide_voice_visuals/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/datum/antagonist/heretic/heretic = ascend_tide_flood(start)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_tide/tide = heretic.get_knowledge(/datum/eldritch_knowledge/base_tide)
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, locate(start.x + 2, start.y, start.z))
	var/list/before = list_vfx_bursts(start)
	TEST_ASSERT(tide.release(user, ascended_wave = TRUE), "Голос Пучины звучит.")
	TEST_ASSERT(abs(victim.getBruteLoss() - 30) <= DAMAGE_PRECISION, "Урон прежний: 30 ушибов.")
	TEST_ASSERT(abs(victim.getStaminaLoss() - 40) <= DAMAGE_PRECISION, "Выносливость прежняя: 40.")
	var/obj/effect/temp_visual/heretic_tide_swell/back = locate() in start
	var/obj/effect/temp_visual/heretic_tide_swell/front/front = locate() in start
	TEST_ASSERT_NOTNULL(back, "Вода встаёт короной за героем.")
	TEST_ASSERT_NOTNULL(front, "Вода встаёт короной перед героем.")
	TEST_ASSERT(back.layer < MOB_LAYER && front.layer > MOB_LAYER, "Корона обнимает героя спереди и сзади.")
	var/obj/effect/temp_visual/heretic_vfx/shockwave/wave = locate() in start
	TEST_ASSERT_NOTNULL(wave, "От героя идёт волна.")
	var/obj/effect/temp_visual/heretic_vfx/burst/foam = find_vfx_burst(start, /particles/heretic_ascension/tide/foam, before)
	TEST_ASSERT_NOTNULL(foam, "Пена разлетается.")
	TEST_ASSERT(wait_for_qdeleted(back) && wait_for_qdeleted(front) && wait_for_qdeleted(wave), "Корона и волна опадают.")
	TEST_ASSERT(wait_for_qdeleted(foam, 3 SECONDS), "Пена оседает.")

/datum/unit_test/heretic_tide_visual_types_create_and_destroy/Run()
	for(var/thing_type in list(/obj/effect/temp_visual/heretic_tide_swell, /obj/effect/temp_visual/heretic_tide_swell/front))
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] удаляется без ошибок.")
