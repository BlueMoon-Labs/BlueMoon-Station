/// Хватка оставляет трещину на окне, не разбивая его, и считает отдел один раз.
/datum/unit_test/heretic_deed_glass/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_GLASS)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_glass/glass = heretic.get_knowledge(/datum/eldritch_knowledge/base_glass)
	var/obj/structure/window/pane = allocate(/obj/structure/window, get_step(user, EAST))
	var/integrity_before = pane.obj_integrity
	TEST_ASSERT(glass.on_mansus_grasp(pane, user, TRUE), "Хватка оставляет трещину на окне.")
	TEST_ASSERT(!QDELETED(pane), "Трещина не разбивает окно.")
	TEST_ASSERT_EQUAL(pane.obj_integrity, integrity_before - 10, "Трещина снимает десять прочности.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Первое окно засчитано.")
	var/obj/structure/window/second_pane = allocate(/obj/structure/window, get_step(user, NORTH))
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	glass.on_mansus_grasp(second_pane, user, TRUE)
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Второе окно в том же отделе не засчитывается.")

/// Хватка читает чужую кровь один раз на человека и не принимает собственную.
/datum/unit_test/heretic_deed_blood/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_BLOOD)
	var/mob/living/carbon/human/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_blood/blood = heretic.get_knowledge(/datum/eldritch_knowledge/base_blood)
	var/obj/effect/decal/cleanable/blood/stain = allocate(/obj/effect/decal/cleanable/blood, get_step(user, EAST))
	stain.blood_DNA = list("dna_a" = "O+")
	TEST_ASSERT(blood.on_mansus_grasp(stain, user, TRUE), "Чужая кровь читается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Первая подпись засчитана.")
	TEST_ASSERT_EQUAL(stain.name, heretic.deed.trace_name, "Прочитанная кровь становится подписью.")
	var/obj/effect/decal/cleanable/blood/repeat = allocate(/obj/effect/decal/cleanable/blood, get_step(user, NORTH))
	repeat.blood_DNA = list("dna_a" = "O+")
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(!blood.on_mansus_grasp(repeat, user, TRUE), "Та же подпись не читается второй раз.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Повторная подпись не засчитывается.")
	var/obj/effect/decal/cleanable/blood/own = allocate(/obj/effect/decal/cleanable/blood, get_step(user, NORTHEAST))
	var/list/own_dna = list()
	own_dna[user.dna.unique_enzymes] = "O+"
	own.blood_DNA = own_dna
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(!blood.on_mansus_grasp(own, user, TRUE), "Собственная кровь не читается.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Собственная кровь не засчитывается.")

/// Хватка заставляет интерком шептать и считает отдел один раз.
/datum/unit_test/heretic_deed_echo/Run()
	var/datum/antagonist/heretic/heretic = allocate_deed_heretic(PATH_ECHO)
	var/mob/living/user = heretic.owner.current
	var/datum/eldritch_knowledge/base_echo/echo = heretic.get_knowledge(/datum/eldritch_knowledge/base_echo)
	var/obj/item/radio/intercom/speaker = allocate(/obj/item/radio/intercom, get_step(user, EAST))
	speaker.on = TRUE
	TEST_ASSERT(echo.on_mansus_grasp(speaker, user, TRUE), "Интерком шепчет.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Первый интерком засчитан.")
	var/obj/item/radio/intercom/second_speaker = allocate(/obj/item/radio/intercom, get_step(user, NORTH))
	second_speaker.on = TRUE
	COOLDOWN_RESET(heretic.deed, progress_cooldown)
	TEST_ASSERT(!echo.on_mansus_grasp(second_speaker, user, TRUE), "Второй интерком в том же отделе не шепчет.")
	TEST_ASSERT_EQUAL(heretic.deed.progress, 1, "Второй интерком не засчитывается.")
