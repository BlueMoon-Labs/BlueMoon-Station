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

	// Идемпотентность: повторное создание экземпляра вида не должно копить трейт в общем
	// списке типа (LAZYADD именно этим и был плох).
	var/datum/species/golem/second = new /datum/species/golem()
	var/copies = 0
	for(var/trait in second.inherent_traits)
		if(trait == CAN_BE_OPERATED_WITHOUT_PAIN)
			copies++
	TEST_ASSERT_EQUAL(copies, 1, "CAN_BE_OPERATED_WITHOUT_PAIN размножился в inherent_traits: New() мутирует общий дефолт типа")

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
	TEST_ASSERT_NOTNULL(inner, "Внутренняя бумага пропала вместе с самолётиком")

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
