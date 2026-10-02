/// Хватка настраивает окно, не повреждая его, и считает отдел один раз.
/datum/unit_test/heretic_deed_glass/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_GLASS)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/window/pane = allocate(/obj/structure/window, get_step(user, EAST))
	var/integrity_before = pane.obj_integrity
	TEST_ASSERT(glass.on_mansus_grasp(pane, user, TRUE), "Хватка настраивает окно.")
	TEST_ASSERT_EQUAL(pane.obj_integrity, integrity_before, "Настройка не повреждает окно.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Первое окно засчитано.")
	var/obj/structure/window/second_pane = allocate(/obj/structure/window, get_step(user, NORTH))
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(glass.on_mansus_grasp(second_pane, user, TRUE), "Второе окно в том же отделе тоже настраивается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Второе окно в том же отделе не засчитывается.")

/// Хватка в «Помощи» читает чужую кровь, засчитывает человека один раз, не принимает собственную и во время паузы дела не теряет нового человека.
/datum/unit_test/heretic_deed_blood/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	user.a_intent = INTENT_HELP
	var/obj/effect/decal/cleanable/blood/stain = allocate(/obj/effect/decal/cleanable/blood, get_step(user, EAST))
	stain.blood_DNA = list("dna_a" = "O+")
	TEST_ASSERT(blood.on_mansus_grasp(stain, user, TRUE), "Чужая кровь читается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Первая подпись засчитана.")
	var/obj/effect/decal/cleanable/heretic_trace/trace = locate() in get_turf(stain)
	TEST_ASSERT_EQUAL(trace?.name, heretic.deed.trace_name, "У прочитанной крови остаётся след дела.")
	var/obj/effect/decal/cleanable/blood/repeat = allocate(/obj/effect/decal/cleanable/blood, get_step(user, NORTH))
	repeat.blood_DNA = list("dna_a" = "O+")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(blood.on_mansus_grasp(repeat, user, TRUE), "Уже прочитанную подпись можно прочитать снова.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Повторная подпись не засчитывается.")
	var/obj/effect/decal/cleanable/blood/own = allocate(/obj/effect/decal/cleanable/blood, get_step(user, NORTHEAST))
	var/list/own_dna = list()
	own_dna[user.dna.unique_enzymes] = "O+"
	own.blood_DNA = own_dna
	TEST_ASSERT(!blood.on_mansus_grasp(own, user, TRUE), "Собственная кровь не читается.")
	TEST_ASSERT(findtext(blood.grasp_failure_reason, "нет чужой подписи"), "Отказ объясняет ограничение собственной крови.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Собственная кровь не засчитывается.")
	var/obj/item/melee/touch_attack/mansus_fist/fist = allocate(/obj/item/melee/touch_attack/mansus_fist)
	var/charges_before = fist.charges
	fist.afterattack(own, user, TRUE)
	TEST_ASSERT(!QDELETED(fist) && fist.charges == charges_before, "Отказ чтения крови сохраняет подготовленную хватку и её заряд.")
	stain.blood_DNA = list("dna_b" = "O+")
	COOLDOWN_START(heretic.deed, progress_cooldown, HERETIC_DEED_COOLDOWN)
	TEST_ASSERT(!blood.on_mansus_grasp(stain, user, TRUE), "Во время паузы дела кровь нового человека не читается.")
	TEST_ASSERT(findtext(blood.grasp_failure_reason, "Слишком быстро"), "Ожидание не выдаётся за повторную подпись.")
	TEST_ASSERT(findtext(blood.grasp_failure_reason, "[HERETIC_DEED_COOLDOWN / (1 SECONDS)] с"), "Отказ называет остаток паузы: [blood.grasp_failure_reason]")
	TEST_ASSERT(blood.on_mansus_grasp(repeat, user, TRUE), "Уже прочитанного человека пауза не держит.")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(blood.on_mansus_grasp(stain, user, TRUE), "После ожидания новая подпись засчитывается.")
	TEST_ASSERT("dna_b" in heretic.deed.counted_keys, "Новый человек засчитан.")
	TEST_ASSERT_NULL(blood.grasp_failure_reason, "Успех очищает прежнюю причину отказа.")

/// Хватка ставит прослушку на интерком и считает отдел один раз.
/datum/unit_test/heretic_deed_echo/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ECHO)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/obj/item/radio/intercom/speaker = allocate(/obj/item/radio/intercom, get_step(user, EAST))
	TEST_ASSERT(echo.on_mansus_grasp(speaker, user, TRUE), "Хватка ставит прослушку.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Первый интерком засчитан.")
	var/obj/item/radio/intercom/second_speaker = allocate(/obj/item/radio/intercom, get_step(user, NORTH))
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(echo.on_mansus_grasp(second_speaker, user, TRUE), "Второй интерком в том же отделе тоже прослушивается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Второй интерком в том же отделе не засчитывается.")
