/// Проклятие ограничивает группу, даёт передышку и не продлевается повторным наложением.
/datum/unit_test/necropolis_curse_pressure/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	victim.apply_necropolis_curse(CURSE_SPAWNING, 7 MINUTES)
	var/datum/status_effect/necropolis_curse/curse = victim.has_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE)
	TEST_ASSERT_NOTNULL(curse.linked_alert, "Проклятие должно показывать статус жертве.")
	STOP_PROCESSING(SSstatus_effects, curse)
	var/expiry = curse.duration
	victim.apply_necropolis_curse(CURSE_SPAWNING, 7 MINUTES)
	TEST_ASSERT_EQUAL(curse.duration, expiry, "Повторное проклятие не отодвигает освобождение.")
	for(var/index in 1 to 4)
		curse.effect_last_activation = world.time
		curse.tick()
	TEST_ASSERT_EQUAL(length(curse.curse_masses), 2, "Одновременно преследуют не более двух масс.")
	for(var/mob/living/simple_animal/hostile/asteroid/curseblob/mass as anything in curse.curse_masses.Copy())
		mass.death()
	TEST_ASSERT_EQUAL(length(curse.curse_masses), 0, "Уничтоженные массы освобождают места сразу.")
	TEST_ASSERT(curse.next_mass_at >= world.time + 20 SECONDS, "После уничтожения группы есть двадцать секунд передышки.")
	curse.effect_last_activation = world.time
	curse.tick()
	TEST_ASSERT_EQUAL(length(curse.curse_masses), 0, "Очередной тик не обходит передышку.")
	curse.next_mass_at = world.time
	curse.effect_last_activation = world.time
	curse.tick()
	TEST_ASSERT_EQUAL(length(curse.curse_masses), 1, "После передышки преследование возобновляется по одной массе.")
	var/mob/living/simple_animal/hostile/asteroid/curseblob/remaining = curse.curse_masses[1]
	victim.remove_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE)
	TEST_ASSERT(QDELETED(remaining), "Снятие проклятия удаляет оставшихся преследователей.")
	TEST_ASSERT_NULL(remaining.move_timer, "Удаление отменяет таймер движения.")
	TEST_ASSERT_NULL(remaining.timerid, "Удаление отменяет таймер срока жизни.")
	TEST_ASSERT_NULL(victim.alerts["necrocurse"], "Снятое проклятие убирает значок.")

/// Замедление меняет срок следующего шага, а союзник может повредить массу своей цели.
/datum/unit_test/necropolis_curse_counterplay/Run()
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/helper = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/turf/spawn_turf = locate(victim.x + 4, victim.y, victim.z)
	var/mob/living/simple_animal/hostile/asteroid/curseblob/mass = allocate(/mob/living/simple_animal/hostile/asteroid/curseblob, spawn_turf)
	mass.set_target = victim
	mass.GiveTarget()
	var/datum/timedevent/normal_step = SStimer.timer_id_dict[mass.move_timer]
	var/normal_wait = normal_step.wait
	var/turf/after_first_step = get_turf(mass)
	var/first_timer = mass.move_timer
	mass.move_loop()
	TEST_ASSERT_EQUAL(get_turf(mass), after_first_step, "Повторное планирование ИИ не делает лишний шаг.")
	TEST_ASSERT_EQUAL(mass.move_timer, first_timer, "Повторный запуск не заменяет живой таймер.")
	deltimer(mass.move_timer)
	mass.move_timer = null
	var/datum/movespeed_modifier/slowdown = new
	allocated += slowdown
	slowdown.id = REF(src)
	slowdown.multiplicative_slowdown = 3
	mass.add_movespeed_modifier(slowdown)
	mass.move_loop()
	var/datum/timedevent/slowed_step = SStimer.timer_id_dict[mass.move_timer]
	TEST_ASSERT(slowed_step.wait > normal_wait, "Замедление увеличивает паузу между шагами преследования.")
	var/obj/item/kitchen/knife/knife = allocate(/obj/item/kitchen/knife, helper)
	var/health_before = mass.health
	mass.attacked_by(knife, helper)
	TEST_ASSERT(mass.health < health_before, "Обычный удар союзника повреждает чужую массу.")
	TEST_ASSERT_EQUAL(mass.set_target, victim, "Помощь союзника не переводит на него проклятие.")

/// Святая вода снимает уже развившееся проклятие, сохраняя роль еретика.
/datum/unit_test/necropolis_curse_holywater/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	user.apply_necropolis_curse(CURSE_SPAWNING)
	user.reagents.add_reagent(/datum/reagent/water/holywater, 10)
	var/datum/reagent/water/holywater/water = user.reagents.has_reagent(/datum/reagent/water/holywater)
	TEST_ASSERT_NOTNULL(water, "Святая вода должна попасть в организм.")
	water.data = list("misc" = 8)
	water.on_mob_life(user)
	TEST_ASSERT(user.has_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE), "Очищение требует времени метаболизма.")
	water.on_mob_life(user)
	TEST_ASSERT_NULL(user.has_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE), "После нужного времени проклятие снимается.")
	TEST_ASSERT_EQUAL(IS_HERETIC(user), heretic, "Очищение от проклятия не снимает роль.")
