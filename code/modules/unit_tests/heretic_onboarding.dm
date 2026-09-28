/// Призыв кодекса достаёт книгу из сумки в руку, прячет только книгу в руке и объясняет каждый шаг.
/datum/unit_test/heretic_codex_summon_toggle/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/body = heretic.owner.current
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	TEST_ASSERT(body.equip_to_slot_if_possible(bag, ITEM_SLOT_BACK), "Рюкзак надет.")
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	book.forceMove(bag)
	heretic.personal_codex = WEAKREF(book)
	var/obj/effect/proc_holder/spell/self/heretic_summon/book/spell = allocate(/obj/effect/proc_holder/spell/self/heretic_summon/book)

	spell.cast(list(body), body)
	TEST_ASSERT(body.is_holding(book), "Кодекс из рюкзака переходит в руку, а не прячется.")
	TEST_ASSERT(!(book in heretic.summon_items), "Кодекс из рюкзака не уходит за завесу.")
	TEST_ASSERT(findtext(spell.last_notice, "Кодекс в руке"), "Призыв говорит, что кодекс в руке: [spell.last_notice]")

	spell.cast(list(body), body)
	TEST_ASSERT(book in heretic.summon_items, "Кодекс в руке прячется за завесу.")
	TEST_ASSERT(!body.is_holding(book), "Спрятанный кодекс покидает руку.")
	TEST_ASSERT(findtext(spell.last_notice, "спрятан за завесой"), "Сокрытие сообщает, как достать кодекс: [spell.last_notice]")

	var/obj/item/pen/first_pen = allocate(/obj/item/pen)
	var/obj/item/pen/second_pen = allocate(/obj/item/pen)
	body.put_in_hands(first_pen)
	body.put_in_hands(second_pen)
	spell.cast(list(body), body)
	TEST_ASSERT_EQUAL(book.loc, bag, "При занятых руках призванный кодекс ложится в рюкзак.")
	TEST_ASSERT(findtext(spell.last_notice, "Руки заняты") && findtext(spell.last_notice, "в рюкзаке"), "Призыв называет, куда лёг кодекс: [spell.last_notice]")

	spell.cast(list(body), body)
	TEST_ASSERT_EQUAL(book.loc, bag, "Кодекс в рюкзаке при занятых руках остаётся на месте.")
	TEST_ASSERT(!(book in heretic.summon_items), "Повторное нажатие с занятыми руками не прячет кодекс из рюкзака.")
	TEST_ASSERT(findtext(spell.heretic_failure_reason, "в рюкзаке") && findtext(spell.heretic_failure_reason, "руки заняты"), "Отказ называет, где кодекс и что мешает: [spell.heretic_failure_reason]")

	body.dropItemToGround(second_pen)
	spell.cast(list(body), body)
	TEST_ASSERT(body.is_holding(book), "Со свободной рукой кодекс из рюкзака переходит в руку.")
	TEST_ASSERT(!(book in bag.contents), "Рюкзак больше не держит кодекс.")

/// Нажатие в кодексе, который нельзя листать, объясняет причину и ничего не меняет.
/datum/unit_test/heretic_codex_ui_refusal/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/reader = heretic.owner.current
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	TEST_ASSERT(reader.put_in_hands(book), "Кодекс в руке.")
	TEST_ASSERT_NULL(book.ui_refusal_reason(reader), "Кодекс в руке листается без отказа.")
	var/datum/tgui/heretic_book_test/ui = allocate(/datum/tgui/heretic_book_test, reader, book, "ForbiddenLore", "Кодекс Рубцов")
	ui.status = UI_INTERACTIVE
	reader.Stun(10 SECONDS)
	if(!reader.is_holding(book))
		reader.put_in_hand(book, reader.active_hand_index, forced = TRUE)
	TEST_ASSERT(findtext(book.ui_refusal_reason(reader), "оглушены"), "Оглушённому отказ называет причину: [book.ui_refusal_reason(reader)]")
	TEST_ASSERT(!book.ui_act("research", list("id" = "[/datum/eldritch_knowledge/base_ash]"), ui), "Оглушённый не изучает знания.")
	TEST_ASSERT_NULL(heretic.selected_path, "Путь не выбран в оглушении.")
	reader.SetStun(0)
	reader.dropItemToGround(book)
	TEST_ASSERT(findtext(book.ui_refusal_reason(reader), "держать в руке"), "Без книги в руке отказ просит взять её: [book.ui_refusal_reason(reader)]")
