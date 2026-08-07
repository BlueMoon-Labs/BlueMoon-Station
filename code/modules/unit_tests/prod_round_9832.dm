/// Регрессии по прод-раундам 9831/9832 (2026-07-30).

/// В GLOB.species_list не должно быть ключа null. Такой ключ появляется от опечатки в пути
/// модульного оверрайда: DM создаёт тип из определения прока, у фантома id остаётся null, и
/// дальше он роняет любой пикер видов рантаймом "Null in a tgui_input_list() items"
/// (раунд 9832, админский set species). До фикса фантомов было четыре: /datum/species/zombies
/// с двумя подтипами и /datum/species/golems.
/datum/unit_test/species_list_has_no_null_id

/datum/unit_test/species_list_has_no_null_id/Run()
	TEST_ASSERT(length(GLOB.species_list) > 0, "GLOB.species_list пуст - тест ничего не проверяет")
	TEST_ASSERT(!(null in GLOB.species_list), "В GLOB.species_list есть ключ null: какой-то /datum/species остался без id (ищи опечатку в пути типа)")
	TEST_ASSERT(!(null in GLOB.species_datums), "В GLOB.species_datums есть ключ null")

	for(var/species_id in GLOB.species_list)
		var/datum/species/species_datum = GLOB.species_datums[species_id]
		TEST_ASSERT_NOTNULL(species_datum, "У вида с id \"[species_id]\" нет датума в GLOB.species_datums")

/// Патч modular_sand должен был дать всем големам CAN_BE_OPERATED_WITHOUT_PAIN, но лежал на
/// несуществующем пути /datum/species/golems и не применялся ни к одному из них.
/datum/unit_test/golem_species_can_be_operated_without_pain

/datum/unit_test/golem_species_can_be_operated_without_pain/Run()
	var/datum/species/golem/golem = GLOB.species_datums[SPECIES_GOLEM]
	TEST_ASSERT_NOTNULL(golem, "В GLOB.species_datums нет вида голема по id [SPECIES_GOLEM]")
	TEST_ASSERT(CAN_BE_OPERATED_WITHOUT_PAIN in golem.inherent_traits, "Голем без CAN_BE_OPERATED_WITHOUT_PAIN: модульный патч снова не применяется")

	// Идемпотентность: сколько бы раз добавление ни отработало на одном списке, трейт обязан
	// остаться в одном экземпляре (LAZYADD этого не гарантировал).
	var/datum/species/golem/second = new /datum/species/golem()
	var/copies = 0
	for(var/trait in second.inherent_traits)
		if(trait == CAN_BE_OPERATED_WITHOUT_PAIN)
			copies++
	qdel(second)
	TEST_ASSERT_EQUAL(copies, 1, "CAN_BE_OPERATED_WITHOUT_PAIN размножился в inherent_traits вида")

/// Ресайклер вытряхивает содержимое перед переработкой, а бумажный самолётик самоудаляется
/// в Exited(), как только внутренняя бумага вышла. Раунд 9832: два рантайма
/// "doMove qdel-нутого /obj/item/paperplane" из связки конвейер -> ресайклер.
/datum/unit_test/recycler_survives_self_deleting_container

/datum/unit_test/recycler_survives_self_deleting_container/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/obj/machinery/recycler/recycler = allocate(/obj/machinery/recycler, floor)
	var/obj/item/paperplane/plane = allocate(/obj/item/paperplane, floor)

	TEST_ASSERT_NOTNULL(plane.internalPaper, "У самолётика нет внутренней бумаги - тест ничего не проверяет")
	var/obj/item/paper/inner = plane.internalPaper

	recycler.recycle_item(plane)

	TEST_ASSERT(QDELETED(plane), "Самолётик обязан самоудалиться, отпустив бумагу")
	// Именно QDELETED, а не NOTNULL: локальная ссылка переживает qdel, и проверка на null тут
	// не могла упасть в принципе.
	TEST_ASSERT(!QDELETED(inner), "Внутренняя бумага удалилась вместе с самолётиком")
	TEST_ASSERT_EQUAL(inner.loc, floor, "Бумага обязана остаться на полу, а не уехать в нуль-спейс за контейнером")

/// adjustStaminaLoss брал bodyparts[1] без проверки длины и падал "list index out of bounds"
/// на мобе, который уже прошёл Destroy(), но получил ещё один Life из снапшота currentrun.
/datum/unit_test/stamina_loss_survives_missing_bodyparts

/datum/unit_test/stamina_loss_survives_missing_bodyparts/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human, floor)

	for(var/obj/item/bodypart/part as anything in patient.bodyparts.Copy())
		qdel(part)
	TEST_ASSERT_EQUAL(length(patient.bodyparts), 0, "Конечности не удалились - тест ничего не проверяет")

	// Зона, которой у моба заведомо нет: раньше это уводило в bodyparts[1] на пустом списке.
	var/result = patient.adjustStaminaLoss(-6, TRUE, FALSE, BODY_ZONE_CHEST)
	TEST_ASSERT_EQUAL(result, FALSE, "adjustStaminaLoss без конечностей обязан вернуть FALSE, а не падать или чинить пустоту")

/// Диагностика расхождения конфига с кодом обязана быть читаемой и не падать на краевых
/// значениях: списки, пустые списки, null и очень длинные строки идут в лог как есть.
///
/// Сам механизм нужен потому, что конфиг на проде живёт отдельно от репозитория и отстаёт:
/// поднятый в коде TGUI_MAX_CHUNK_COUNT молча перебивался строкой 64 из файла, и снаружи это
/// выглядело как "фикс не работает".
/datum/unit_test/config_override_report

/datum/unit_test/config_override_report/Run()
	TEST_ASSERT_EQUAL(config.config_value_to_text(null), "null", "null обязан печататься явно, а не пустой строкой")
	TEST_ASSERT_EQUAL(config.config_value_to_text(64), "64", "Число обязано печататься как есть")
	TEST_ASSERT_EQUAL(config.config_value_to_text(list()), "(пусто)", "Пустой список обязан быть отличим от отсутствующего значения")
	TEST_ASSERT_EQUAL(config.config_value_to_text(list("a", "b")), "(a, b)", "Список обязан разворачиваться в значения")
	TEST_ASSERT_EQUAL(config.config_value_to_text(list("a" = 1)), "(a=1)", "Ассоциативный список обязан показывать пары ключ-значение")
	// У плоского списка обращение по ключу трактуется как индекс: числовой элемент уводил за
	// границы и ронял весь отчёт целиком.
	TEST_ASSERT_EQUAL(config.config_value_to_text(list(1, 300)), "(1, 300)", "Плоский числовой список не должен ронять отчёт обращением по индексу")
	TEST_ASSERT_EQUAL(config.config_value_to_text(list(/mob/living)), "(/mob/living)", "Список типов обязан печататься путями")

	// Длинная строка режется, но обязана сообщать реальную длину - иначе по логу не понять,
	// насколько значение разошлось.
	var/long_value = config.config_value_to_text("Ж")
	TEST_ASSERT_EQUAL(long_value, "Ж", "Короткая строка не должна резаться")
	var/very_long = ""
	for(var/i in 1 to 300)
		very_long += "Ж"
	var/printed = config.config_value_to_text(very_long)
	TEST_ASSERT(findtext(printed, "300 символов"), "Обрезанная строка обязана называть свою длину в символах, а получилось: [printed]")
	TEST_ASSERT(length_char(printed) < 300, "Обрезка не сработала: строка ушла в лог целиком")

	// Сам отчёт обязан отрабатывать без рантайма на живой конфигурации раунда.
	config.LogValueOverrides()

/// Обе воронки выдачи в руки обязаны отвергать уже удалённый предмет.
///
/// put_in_hand с forced = TRUE обходит can_put_in_hand целиком, и стрип-меню приносило туда
/// предметы, самоудаляющиеся при снятии (прод-раунд 9834, "doMove qdel-нутого"). Отказ на
/// верхнем уровне мало что давал: put_in_hands проверял только null и в хвосте всё равно делал
/// удалённому предмету forceMove(drop_location()) и dropped().
/datum/unit_test/hands_reject_deleted_item

/datum/unit_test/hands_reject_deleted_item/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, floor)

	var/obj/item/paper/doomed = new /obj/item/paper(floor)
	qdel(doomed)
	TEST_ASSERT(QDELETED(doomed), "Предмет обязан быть удалён - тест ничего не проверяет")

	TEST_ASSERT_EQUAL(user.put_in_hand(doomed, user.active_hand_index, forced = TRUE), FALSE, "put_in_hand обязан отказать удалённому предмету даже при forced")
	TEST_ASSERT_EQUAL(user.put_in_hands(doomed, forced = TRUE), FALSE, "put_in_hands обязан отказать удалённому предмету")
	TEST_ASSERT_NULL(doomed.loc, "Удалённый предмет не имеет права вернуться в мир: ни в руку, ни на пол")
	TEST_ASSERT(!(doomed in user.held_items), "Удалённый предмет оказался в руках")

/// Вторженцы портального шторма обязаны нападать сами.
///
/// Клоунский вариант спавнит семейство /hostile/retaliate, а оно атакует только тех, кто ударил
/// первым: стратегия отбора целей требует, чтобы цель уже лежала в enemies. Ивент-вторжение
/// выкатывал толпу, которая стоит и ждёт, пока её побьют. Остальные варианты шторма спавнят
/// обычных враждебных мобов, поэтому пацифизм снимается точечно у заспавненных экземпляров.
/datum/unit_test/portal_storm_invaders_are_aggressive

/datum/unit_test/portal_storm_invaders_are_aggressive/Run()
	var/turf/floor = run_loc_floor_bottom_left
	var/mob/living/simple_animal/hostile/retaliate/clown/invader = allocate(/mob/living/simple_animal/hostile/retaliate/clown, floor)
	var/datum/ai_controller/controller = invader.ai_controller
	TEST_ASSERT_NOTNULL(controller, "У клоуна нет контроллера - тест ничего не проверяет")
	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy/retaliate, "Обычный клоун обязан оставаться пацифистом до первого удара")

	var/datum/round_event/portal_storm/storm = new
	storm.make_invader_aggressive(invader)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_TARGETING_STRATEGY], /datum/targeting_strategy/hostile_legacy, "Вторженец шторма обязан получить обычную стратегию отбора целей, иначе он не нападёт первым")

	// Мобы, которые и так агрессивны, трогать незачем: прок обязан их пропускать.
	var/mob/living/simple_animal/hostile/carp/fish = allocate(/mob/living/simple_animal/hostile/carp, floor)
	var/datum/ai_controller/carp_controller = fish.ai_controller
	var/before = carp_controller.blackboard[BB_AI_TARGETING_STRATEGY]
	storm.make_invader_aggressive(fish)
	TEST_ASSERT_EQUAL(carp_controller.blackboard[BB_AI_TARGETING_STRATEGY], before, "Не-retaliate моб не должен менять стратегию отбора целей")

	qdel(storm)
