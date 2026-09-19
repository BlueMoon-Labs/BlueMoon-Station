/// Причины отказа Клинка различают ресурс, оружие и занятую вторую руку без расхода заряда.
/datum/unit_test/heretic_blade_failure_feedback/Run()
	var/list/fixture = make_blade_fixture()
	var/mob/living/user = fixture["user"]
	var/datum/antagonist/heretic/heretic = fixture["heretic"]
	var/datum/eldritch_knowledge/base_blade/knowledge = fixture["knowledge"]
	var/obj/item/melee/sickly_blade/blade = fixture["blade"]
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/blade_lunge)
	var/obj/effect/proc_holder/spell/pointed/heretic_lunge/lunge = allocate(/obj/effect/proc_holder/spell/pointed/heretic_lunge)
	user.mind.AddSpell(lunge)
	TEST_ASSERT(!lunge.can_cast(user, silent = TRUE), "Без Темпа выпад отклоняется.")
	TEST_ASSERT(findtext(lunge.heretic_failure_reason, "Темп"), "Отказ указывает ресурс.")
	knowledge.combat_resource = 1
	user.dropItemToGround(blade)
	TEST_ASSERT(!lunge.can_cast(user, silent = TRUE), "Без клинка выпад отклоняется.")
	TEST_ASSERT(findtext(lunge.heretic_failure_reason, "клинок"), "Отказ указывает недостающее оружие.")
	user.put_in_hands(blade)
	TEST_ASSERT(lunge.can_cast(user, silent = TRUE), "С клинком и Темпом выпад доступен.")
	TEST_ASSERT_EQUAL(knowledge.combat_resource, 1, "Проверка кнопки не расходует Темп.")
	var/obj/effect/proc_holder/spell/self/heretic_blade/parry/parry = allocate(/obj/effect/proc_holder/spell/self/heretic_blade/parry)
	user.mind.AddSpell(parry)
	var/obj/item/pen/pen = allocate(/obj/item/pen)
	user.put_in_hands(pen)
	TEST_ASSERT(!parry.can_cast(user, silent = TRUE), "Занятая вторая рука мешает стойке.")
	TEST_ASSERT(findtext(parry.heretic_failure_reason, "вторую руку"), "Отказ объясняет, какую руку освободить.")
	user.dropItemToGround(pen)
	TEST_ASSERT(parry.can_cast(user, silent = TRUE), "Свободная вторая рука разрешает стойку.")
	TEST_ASSERT_EQUAL(parry.charge_counter, parry.charge_max, "Отказы не расходуют заряд стойки.")

/// Отказ по союзнику объясняет иммунитет и сохраняет заряд и воск.
/datum/unit_test/heretic_ally_failure_feedback/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	heretic.selected_path = PATH_WAX
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_wax)
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/wax_imprint)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_wax/wax = heretic.get_knowledge(/datum/eldritch_knowledge/base_wax)
	var/datum/antagonist/heretic/ally = allocate_heretic(get_step(user, EAST))
	var/obj/effect/proc_holder/spell/pointed/heretic_wax/imprint/spell = allocate(/obj/effect/proc_holder/spell/pointed/heretic_wax/imprint)
	var/initial_resource = wax.combat_resource
	TEST_ASSERT(!spell.can_target(ally.owner.current, user, TRUE), "Союзник остаётся защищённым от оттиска.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "союзник Мансуса"), "Причина называет союзный иммунитет.")
	TEST_ASSERT_EQUAL(wax.combat_resource, initial_resource, "Отказ не расходует воск.")
	TEST_ASSERT_EQUAL(spell.charge_counter, spell.charge_max, "Отказ не расходует заряд заклинания.")
	var/mob/living/victim = allocate(/mob/living/carbon/human, get_step(user, NORTH))
	TEST_ASSERT(spell.can_target(victim, user, TRUE), "Обычный противник остаётся допустимой целью.")
	TEST_ASSERT_NULL(spell.heretic_failure_reason, "Успешный выбор убирает старую причину отказа.")
	user.Paralyze(1 SECONDS)
	TEST_ASSERT(!spell.can_target(ally.owner.current, user, TRUE), "Оглушённый пользователь не может атаковать.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "не можете действовать"), "Оглушение имеет приоритет перед иммунитетом цели.")

/// Руна показывает срок своего холода и предупреждает, когда каналу уже не хватит времени.
/datum/unit_test/heretic_void_preparation_feedback/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.selected_path = PATH_VOID
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_void)
	var/datum/eldritch_knowledge/base_void/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_void)
	var/obj/effect/eldritch/rune = allocate(/obj/effect/eldritch, get_turf(user))
	TEST_ASSERT(findtext(rune.preparation_hint(user), "сначала накройте"), "Тёплая руна подсказывает способ подготовки.")
	var/obj/effect/heretic_combat_zone/void/winter = allocate(/obj/effect/heretic_combat_zone/void, get_turf(user), heretic.owner)
	STOP_PROCESSING(SSprocessing, winter)
	winter.refresh_boundary(list(get_turf(rune)))
	knowledge.combat_zone = winter
	TEST_ASSERT(findtext(rune.preparation_hint(user), "ещё"), "Своё поле показывает оставшийся срок.")
	winter.expires_at = world.time + 1 SECONDS
	TEST_ASSERT(findtext(rune.preparation_hint(user), "недостаточно"), "Короткого остатка недостаточно для нового клинка.")

/area/hallway/primary/heretic_public_fixture
	requires_power = FALSE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/area/hallway/primary/heretic_public_fixture/second

/area/security/heretic_restricted_fixture
	requires_power = FALSE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED

/// Стартовые разломы выбирают разные общие коридоры, даже если рядом есть доступная генератору зона СБ.
/datum/unit_test/heretic_public_influence_placement
	var/list/previous_areas
	var/list/previous_traits
	var/datum/space_level/test_level
	var/datum/turf_reservation/test_reservation
	var/list/original_areas = list()

/datum/unit_test/heretic_public_influence_placement/Destroy()
	if(previous_areas)
		GLOB.the_station_areas = previous_areas
	if(previous_traits)
		test_level.traits = previous_traits
	for(var/turf/tile as anything in original_areas)
		var/area/original = original_areas[tile]
		original.contents += tile
	QDEL_NULL(test_reservation)
	return ..()

/datum/unit_test/heretic_public_influence_placement/Run()
	test_reservation = SSmapping.RequestBlockReservation(36, 7, border_type_override = /turf/closed/wall)
	TEST_ASSERT_NOTNULL(test_reservation, "Для размещения разломов нужна отдельная арена.")
	test_level = SSmapping.get_level(test_reservation.bottom_left_coords[3])
	previous_traits = test_level.traits
	test_level.traits = previous_traits.Copy()
	test_level.traits[ZTRAIT_STATION] = TRUE
	previous_areas = GLOB.the_station_areas
	GLOB.the_station_areas = list(/area/hallway/primary/heretic_public_fixture, /area/hallway/primary/heretic_public_fixture/second, /area/security/heretic_restricted_fixture)
	for(var/index in 1 to 3)
		var/area_type = GLOB.the_station_areas[index]
		var/area/fixture_area = new area_type
		allocated += fixture_area
		GLOB.sortedAreas |= fixture_area
		var/turf/tile = locate(test_reservation.bottom_left_coords[1] + 2 + (index - 1) * 14, test_reservation.bottom_left_coords[2] + 3, test_reservation.bottom_left_coords[3])
		tile = tile.ChangeTurf(/turf/open/floor/plasteel)
		original_areas[tile] = get_area(tile)
		fixture_area.contents += tile
	var/datum/reality_smash_tracker/tracker = allocate(/datum/reality_smash_tracker)
	TEST_ASSERT(tracker.RandomSpawnSmash(TRUE, TRUE), "Первый общедоступный разлом появляется.")
	TEST_ASSERT(tracker.RandomSpawnSmash(TRUE, TRUE), "Второй общедоступный разлом появляется.")
	var/obj/effect/reality_smash/first = tracker.smashes[1]
	var/obj/effect/reality_smash/second = tracker.smashes[2]
	TEST_ASSERT(istype(get_area(first), /area/hallway/primary), "Первый разлом находится в общем коридоре.")
	TEST_ASSERT(istype(get_area(second), /area/hallway/primary), "Второй разлом находится в общем коридоре.")
	TEST_ASSERT_NOTEQUAL(get_area(first), get_area(second), "При наличии выбора разломы расходятся по разным районам.")
	TEST_ASSERT(get_dist(first, second) >= 12, "Стартовые разломы не образуют тесную группу.")
	TEST_ASSERT(!tracker.RandomSpawnSmash(TRUE, TRUE), "Исчерпание общих коридоров не подменяет стартовую гарантию зоной СБ.")

/// Частичная стартовая выдача сохраняет возможность досоздать недостающие разломы.
/datum/unit_test/heretic_influence_partial_start/Run()
	var/datum/reality_smash_tracker/influence_schedule_fixture/tracker = allocate_influence_tracker()
	var/list/locations = tracker.spawn_locations.Copy()
	tracker.spawn_locations = list(locations[1])
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	tracker.AddMind(heretic.owner)
	TEST_ASSERT_EQUAL(length(tracker.smashes), 1, "Пока доступна только одна точка.")
	TEST_ASSERT(!tracker.initial_influences_seeded, "Одна точка не считается полной стартовой выдачей.")
	tracker.spawn_locations = locations
	tracker.next_influence_at = world.time
	tracker.spawn_scheduled_influence()
	TEST_ASSERT_EQUAL(length(tracker.smashes), 3, "Следующая попытка достраивает ровно стартовую тройку.")
	TEST_ASSERT(tracker.initial_influences_seeded, "Полная тройка завершает стартовую выдачу.")
