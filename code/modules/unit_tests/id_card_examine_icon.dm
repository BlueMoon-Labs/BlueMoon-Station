/// Повторный осмотр ID-карты не собирает иконку заново.
/datum/unit_test/id_card_examine_reuses_icon

/datum/unit_test/id_card_examine_reuses_icon/Run()
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/first = card.get_examine_string(viewer)

	var/icons_before = GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS]
	var/second = card.get_examine_string(viewer)

	TEST_ASSERT_EQUAL(GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS] - icons_before, 0, "повторный осмотр собрал иконку заново")
	TEST_ASSERT_EQUAL(second, first, "повторный осмотр вернул другую строку")
	TEST_ASSERT(findtext(second, "<img"), "в строке осмотра нет иконки")

/// После смены вида карты осмотр показывает новую иконку.
/datum/unit_test/id_card_examine_refreshes_icon

/datum/unit_test/id_card_examine_refreshes_icon/Run()
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	card.get_examine_string(viewer)

	card.update_appearance()
	var/icons_before = GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS]
	card.get_examine_string(viewer)

	TEST_ASSERT(GLOB.nondatum_ledger[NONDATUM_LEDGER_ICONS] > icons_before, "осмотр после смены вида взял старую иконку")
