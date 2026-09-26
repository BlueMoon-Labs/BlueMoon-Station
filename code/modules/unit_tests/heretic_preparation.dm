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

/// Все пути получают одну дозу; повторная выдача и смена тела не восстанавливают расходник.
/datum/unit_test/heretic_starter_essence/Run()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		heretic.selected_path = path_id
		var/mob/living/carbon/human/user = heretic.owner.current
		heretic.equip_cultist()
		var/obj/item/reagent_containers/hypospray/medipen/eldritch/injector = locate() in user.GetAllContents()
		TEST_ASSERT_NOTNULL(injector, "[path_id]: стартовый инъектор доступен владельцу.")
		TEST_ASSERT_EQUAL(injector.reagents.total_volume, 10, "[path_id]: выдано ровно 10u.")
		qdel(injector)
		heretic.equip_cultist()
		TEST_ASSERT(!(locate(/obj/item/reagent_containers/hypospray/medipen/eldritch) in user.GetAllContents()), "[path_id]: потраченный инъектор не выдаётся заново.")
		var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human)
		heretic.owner.current = new_body
		heretic.equip_cultist()
		TEST_ASSERT(!(locate(/obj/item/reagent_containers/hypospray/medipen/eldritch) in new_body.GetAllContents()), "[path_id]: новое тело не получает вторую дозу.")
		heretic.owner.current = user

/// При занятых руках инъектор остаётся на полу, а чужое тело не расходует право на выдачу.
/datum/unit_test/heretic_starter_essence_fallback/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	heretic.give_starter_essence(stranger)
	TEST_ASSERT(!heretic.starter_essence_given, "Чужое тело не получает расходник.")
	user.put_in_hands(allocate(/obj/item/pen))
	user.put_in_hands(allocate(/obj/item/pen))
	heretic.equip_cultist()
	var/obj/item/reagent_containers/hypospray/medipen/eldritch/injector = locate() in get_turf(user)
	TEST_ASSERT_NOTNULL(injector, "При отсутствии слотов инъектор не пропадает.")
	allocated += injector
	TEST_ASSERT_EQUAL(injector.reagents.total_volume, 10, "На полу остаётся полная доза.")
	heretic.equip_cultist()
	var/count = 0
	for(var/obj/item/reagent_containers/hypospray/medipen/eldritch/remaining in get_turf(user))
		count++
	TEST_ASSERT_EQUAL(count, 1, "Повторная выдача не создаёт дубликат на полу.")

/// Инъекция через одежду лечит органику и синтетиков, расходуется и сохраняет яд для непосвящённых.
/datum/unit_test/heretic_starter_essence_metabolism/Run()
	for(var/species_type in list(/datum/species/human, /datum/species/synthliz))
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/mob/living/carbon/human/user = heretic.owner.current
		user.set_species(species_type)
		var/obj/item/clothing/suit/space/hardsuit/suit = allocate(/obj/item/clothing/suit/space/hardsuit)
		user.equip_to_slot_or_del(suit, ITEM_SLOT_OCLOTHING)
		user.adjustBruteLoss(20)
		user.adjustFireLoss(20)
		user.adjustStaminaLoss(40)
		user.Paralyze(10 SECONDS)
		var/brute_before = user.getBruteLoss()
		var/burn_before = user.getFireLoss()
		var/stamina_before = user.getStaminaLoss()
		var/paralysis_before = user.AmountParalyzed()
		var/obj/item/reagent_containers/hypospray/medipen/eldritch/injector = allocate(/obj/item/reagent_containers/hypospray/medipen/eldritch)
		injector.attack(user, user)
		TEST_ASSERT_EQUAL(user.reagents.get_reagent_amount(/datum/reagent/eldritch/stabilized), 10, "[species_type]: вся доза вводится через скафандр.")
		TEST_ASSERT_EQUAL(injector.reagents.total_volume, 0, "[species_type]: инъектор опустошён.")
		injector.cyborg_recharge(null)
		injector.attack(user, user)
		TEST_ASSERT_EQUAL(user.reagents.get_reagent_amount(/datum/reagent/eldritch/stabilized), 10, "Пустой инъектор не создаёт новую дозу.")
		user.reagents.metabolize(user, SSMOBS_DT, 1, liverless = TRUE)
		TEST_ASSERT_EQUAL(user.getBruteLoss(), brute_before - 6, "[species_type]: лечение ушибов работает без печени.")
		TEST_ASSERT_EQUAL(user.getFireLoss(), burn_before - 6, "[species_type]: лечение ожогов работает.")
		TEST_ASSERT_EQUAL(user.getStaminaLoss(), stamina_before - 30, "[species_type]: возвращается 30 выносливости.")
		TEST_ASSERT(abs(user.AmountParalyzed() - (paralysis_before - 8 SECONDS)) < 0.01 SECONDS, "[species_type]: обездвиживание сокращается на 8 секунд.")
		TEST_ASSERT_EQUAL(user.reagents.get_reagent_amount(/datum/reagent/eldritch/stabilized), 9, "[species_type]: за усвоение расходуется 1u.")
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human)
	stranger.reagents.add_reagent(/datum/reagent/eldritch/stabilized, 10)
	stranger.reagents.metabolize(stranger, SSMOBS_DT, 1)
	TEST_ASSERT(stranger.getBruteLoss() > 0 && stranger.getFireLoss() > 0 && stranger.getToxLoss() > 0, "Для непосвящённого эссенция остаётся ядом.")

/// Смешивание двух эссенций не удваивает лечение при любом порядке и на последней единице.
/datum/unit_test/heretic_essence_mixture/Run()
	for(var/stabilized_first in list(FALSE, TRUE))
		for(var/amount in list(1, 10))
			var/datum/antagonist/heretic/heretic = allocate_heretic()
			var/mob/living/carbon/human/user = heretic.owner.current
			user.adjustBruteLoss(30)
			var/brute_before = user.getBruteLoss()
			var/first_type = stabilized_first ? /datum/reagent/eldritch/stabilized : /datum/reagent/eldritch
			var/second_type = stabilized_first ? /datum/reagent/eldritch : /datum/reagent/eldritch/stabilized
			user.reagents.add_reagent(first_type, amount)
			user.reagents.add_reagent(second_type, amount)
			user.reagents.metabolize(user, SSMOBS_DT, 1)
			TEST_ASSERT_EQUAL(user.getBruteLoss(), brute_before - 6, "Порядок [stabilized_first], доза [amount]: только один лечебный эффект.")
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/synthetic = heretic.owner.current
	synthetic.set_species(/datum/species/synthliz)
	synthetic.adjustBruteLoss(30)
	var/brute_before = synthetic.getBruteLoss()
	synthetic.reagents.add_reagent(/datum/reagent/eldritch, 10)
	synthetic.reagents.add_reagent(/datum/reagent/eldritch/stabilized, 10)
	synthetic.reagents.metabolize(synthetic, SSMOBS_DT, 1)
	TEST_ASSERT_EQUAL(synthetic.getBruteLoss(), brute_before - 6, "Обычная эссенция не подавляет стабилизированную в синтетике.")

/// Кнопка есть у клинков всех путей, требует клинок в руке и не даёт побег постороннему.
/datum/unit_test/heretic_escape_action_paths/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/stranger = allocate(/mob/living/carbon/human)
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/knowledge_type = path.knowledge[1]
		var/datum/eldritch_knowledge/knowledge = new knowledge_type
		allocated += knowledge
		for(var/blade_type in knowledge.result_atoms)
			if(!ispath(blade_type, /obj/item/melee/sickly_blade))
				continue
			var/obj/item/melee/sickly_blade/blade = allocate(blade_type)
			user.put_in_hands(blade)
			var/datum/action/item_action/heretic_escape/action = locate() in blade.actions
			TEST_ASSERT_NOTNULL(action, "[path_id]: кнопка отхода создана.")
			TEST_ASSERT_EQUAL(action.owner, user, "[path_id]: кнопка выдана владельцу.")
			TEST_ASSERT(action.IsAvailable(TRUE), "[path_id]: клинок в руке готов к побегу.")
			user.Stun(10 SECONDS)
			TEST_ASSERT(!action.Trigger(), "[path_id]: оглушение блокирует нажатие.")
			TEST_ASSERT(!QDELETED(blade), "[path_id]: отказ не ломает оружие.")
			user.SetStun(0)
			user.dropItemToGround(blade)
			TEST_ASSERT(!action.Trigger(), "[path_id]: брошенный клинок нельзя активировать кнопкой.")
			stranger.put_in_hands(blade)
			TEST_ASSERT(!action.IsAvailable(TRUE), "[path_id]: посторонний не может сбежать.")
			qdel(blade)
			TEST_ASSERT(QDELETED(action), "[path_id]: кнопка удаляется вместе с клинком.")

/// Кнопка сохраняет клинок при запрете и потере оружия, а успешный перенос расходует его.
/datum/unit_test/heretic_escape_action/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/turf/origin = get_turf(user)
	var/obj/item/melee/sickly_blade/escape_fixture/blade = allocate(/obj/item/melee/sickly_blade/escape_fixture)
	blade.destination = get_step(user, EAST)
	user.put_in_hands(blade)
	var/datum/action/item_action/heretic_escape/action = locate() in blade.actions
	ADD_TRAIT(user, TRAIT_NO_TELEPORT, TRAIT_GENERIC)
	action.Trigger()
	TEST_ASSERT_EQUAL(blade.search_count, 0, "Кнопка соблюдает запрет телепортации.")
	TEST_ASSERT(!QDELETED(blade), "Запрет сохраняет клинок.")
	REMOVE_TRAIT(user, TRAIT_NO_TELEPORT, TRAIT_GENERIC)
	action.Trigger()
	TEST_ASSERT_EQUAL(get_turf(user), origin, "Потерявший клинок во время поиска не телепортируется.")
	TEST_ASSERT(!QDELETED(blade), "Потеря клинка отменяет побег.")
	user.put_in_hands(blade)
	blade.drop_during_search = FALSE
	var/turf/destination = blade.destination
	action.Trigger()
	TEST_ASSERT_EQUAL(get_turf(user), destination, "Кнопка запускает штатный перенос.")
	TEST_ASSERT(QDELETED(blade) && QDELETED(action), "Успех расходует клинок вместе с кнопкой.")
