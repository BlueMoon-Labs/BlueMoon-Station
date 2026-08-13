/// Ридаут костюма ниндзя висит последней веткой `else if` в дереве
/// /mob/living/carbon/human/get_status_tab_items(). Он уже один раз пропал при
/// переносе этого дерева из modular_bluemoon в code/: сам get_status_readout()
/// остался на месте, а звать его стало некому, и потеря была невидима - прок
/// компилируется и без вызывающих.
///
/// Соседняя ветка нанокостюма здесь намеренно не проверяется: его equipped()
/// раздевает носителя, переодевает по аутфиту и объявляет тревогу на станцию,
/// то есть тест платил бы за одну строку статус-таба половиной раунда.
/datum/unit_test/status_tab_suit_readouts/Run()
	var/mob/living/carbon/human/tester = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!status_tab_has_prefix(tester, "SpiderOS:"), \
		"Без костюма ридаута ниндзя в статус-табе быть не должно")

	var/obj/item/clothing/suit/space/space_ninja/ninja_suit = allocate(/obj/item/clothing/suit/space/space_ninja)
	TEST_ASSERT(tester.equip_to_slot_or_del(ninja_suit, ITEM_SLOT_OCLOTHING, TRUE), \
		"Не удалось надеть костюм ниндзя")
	TEST_ASSERT(status_tab_has_prefix(tester, "SpiderOS:"), \
		"Костюм ниндзя обязан печатать свой ридаут в статус-табе")

/// Ридауты приезжают вложенным списком, поэтому сверяем по началу строки, а не
/// полным совпадением: значения внутри зависят от состояния тела.
/datum/unit_test/status_tab_suit_readouts/proc/status_tab_has_prefix(mob/living/carbon/human/tester, prefix)
	for(var/line as anything in tester.get_status_tab_items())
		if(findtextEx("[line]", prefix) == 1)
			return TRUE
	return FALSE
