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

/// Меню руны и кодекс называют, что даёт обряд; рецепт клинка стоит в первых строках базы каждого пути.
/datum/unit_test/heretic_ritual_result_names/Run()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/datum/eldritch_knowledge/base = allocate(path.knowledge[1])
		TEST_ASSERT_EQUAL(base.ritual_result_name(), "клинок", "База [path_id] делает клинок.")
		TEST_ASSERT_EQUAL(base.ritual_menu_name(), "[base.name] → клинок", "Меню руны [path_id] называет клинок.")
		var/recipe_line = 0
		for(var/index in 1 to min(length(base.details), 4))
			if(findtext(base.details[index], "Нож"))
				recipe_line = index
				break
		TEST_ASSERT(recipe_line, "Рецепт клинка [path_id] в первых четырёх строках: [jointext(base.details, " | ")]")
	var/datum/eldritch_knowledge/spell/basic/sacrifice = allocate(/datum/eldritch_knowledge/spell/basic)
	TEST_ASSERT_EQUAL(sacrifice.ritual_menu_name(), sacrifice.name, "Обряд без предмета называется как прежде.")
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	var/list/static_data = book.ui_static_data()
	var/found_blade = FALSE
	for(var/list/ritual as anything in static_data["rituals"])
		if(ritual["id"] == "[/datum/eldritch_knowledge/base_cosmic]")
			found_blade = ritual["result"] == "клинок"
	TEST_ASSERT(found_blade, "Кодекс передаёт результат обряда.")

/// Руна предлагает рецепт пути с результатом, а подготовка называет рецепт и компоненты клинка.
/datum/unit_test/heretic_rune_menu_blade/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	TEST_ASSERT(findtext(book.preparation_data(heretic)["blade_status"], "выберите путь"), "До выбора пути подготовка просит выбрать путь.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_cosmic, user), "Путь Космоса выбран.")
	var/datum/eldritch_knowledge/base = heretic.get_knowledge(/datum/eldritch_knowledge/base_cosmic)
	var/obj/effect/eldritch/big/pocket_fixture/rune = allocate(/obj/effect/eldritch/big/pocket_fixture, get_step(user, NORTHEAST))
	rune.drawn_by = WEAKREF(heretic.owner)
	rune.attack_hand(user)
	TEST_ASSERT_NOTNULL(rune.offered, "Руна предлагает выбор обряда.")
	TEST_ASSERT_EQUAL(rune.offered["[base.name] → клинок"], base, "Рецепт клинка подписан результатом.")
	var/status = book.preparation_data(heretic)["blade_status"]
	TEST_ASSERT(findtext(status, base.name) && findtext(status, "Лист стекла") && findtext(status, "Нож"), "Подготовка называет рецепт и компоненты: [status]")

/// Заложник идёт за еретиком и по диагонали: половина диагонального шага не срывает захват.
/datum/unit_test/heretic_blade_throat_follow_walk/Run()
	var/list/fixture = blade_throat_fixture()
	var/mob/living/carbon/human/user = fixture["user"]
	qdel(fixture["attacker"])
	var/turf/origin = run_loc_floor_bottom_left
	user.forceMove(locate(origin.x + 1, origin.y + 1, origin.z))
	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, origin)
	var/datum/status_effect/heretic_blade_throat/hold = seize_blade_hostage(fixture, victim)
	TEST_ASSERT_NOTNULL(hold, "Заложник взят.")
	for(var/direction in list(EAST, NORTH, EAST, NORTHEAST))
		var/turf/destination = get_step(user, direction)
		TEST_ASSERT(user.Move(destination, direction), "Еретик шагает на [dir2text(direction)].")
		TEST_ASSERT(!QDELETED(hold), "Шаг на [dir2text(direction)] не срывает захват: [hold.release_reason]")
		TEST_ASSERT(get_dist(victim, user) <= 1, "Заложник держится рядом после шага на [dir2text(direction)].")
