/// У каждого пути своя книга с полными анимациями, названием и звуками.
/datum/unit_test/heretic_books_catalog/Run()
	var/list/covers = list()
	var/list/titles = list()
	var/list/page_sounds = list()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/obj/item/forbidden_book/book = allocate(path.book_type)
		TEST_ASSERT_EQUAL(book.book_path, path_id, "Физический подтип книги должен соответствовать своему пути.")
		TEST_ASSERT_EQUAL(book.name, path.book_name, "Имя предмета должно соответствовать переплёту.")
		TEST_ASSERT_EQUAL(book.name, path.book_title, "Русское название должно совпадать у предмета и окна книги.")
		TEST_ASSERT(!(book.icon_state in covers), "Обложки путей не должны повторяться.")
		TEST_ASSERT(!(path.book_title in titles), "Названия томов не должны повторяться.")
		covers += book.icon_state
		titles += path.book_title
		page_sounds |= path.book_page_sound
		var/list/states = icon_states(book.icon)
		for(var/suffix in list("", "_open", "_opening", "_closing"))
			TEST_ASSERT("[path.book_cover][suffix]" in states, "У книги [path_id] отсутствует состояние [suffix].")
		TEST_ASSERT(book.item_state in icon_states(book.lefthand_file), "Нет левого спрайта книги [path_id] в руках.")
		TEST_ASSERT(book.item_state in icon_states(book.righthand_file), "Нет правого спрайта книги [path_id] в руках.")
		TEST_ASSERT(isfile(path.book_open_sound) && isfile(path.book_page_sound), "Звуки книги должны быть ресурсами сборки.")
	TEST_ASSERT_EQUAL(length(covers), length(GLOB.heretic_paths), "У каждого пути должна быть своя обложка.")
	TEST_ASSERT_EQUAL(length(page_sounds), length(GLOB.heretic_paths), "У каждого материала должен быть свой звук страницы.")

/// TGUI получает экземпляр набора ресурсов с фонами всех путей.
/datum/unit_test/heretic_book_ui_assets/Run()
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	var/list/assets = book.ui_assets()
	TEST_ASSERT_EQUAL(length(assets), 1, "Книга должна передавать один набор ресурсов.")
	var/datum/asset/simple/heretic_book/book_assets = assets[1]
	TEST_ASSERT(istype(book_assets), "TGUI ожидает экземпляр набора ресурсов, а не путь типа.")
	var/list/mappings = book_assets.get_url_mappings()
	TEST_ASSERT_EQUAL(length(mappings), length(GLOB.heretic_paths), "Нужны адреса фонов всех путей.")
	for(var/path_id in GLOB.heretic_paths)
		var/filename = "heretic-[lowertext(path_id)].webp"
		var/datum/asset_cache_item/background = book_assets.assets[filename]
		TEST_ASSERT(istype(background) && isfile(background.resource), "Фон [filename] должен быть зарегистрированным ресурсом.")
		TEST_ASSERT(length(mappings[filename]), "TGUI должен получить адрес фона [filename].")

/// Книга меняет облик для читателя, не перенося чужие знания и не оставляя открытый переплёт после падения.
/datum/unit_test/heretic_book_reader_and_cleanup/Run()
	var/datum/antagonist/heretic/first = allocate_heretic()
	var/datum/antagonist/heretic/second = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/mob/living/first_reader = first.owner.current
	var/mob/living/second_reader = second.owner.current
	first.research_knowledge(/datum/eldritch_knowledge/base_rust, first_reader)
	second.research_knowledge(/datum/eldritch_knowledge/base_moon, second_reader)
	first.knowledge_points = 4
	second.knowledge_points = 9
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	TEST_ASSERT(first_reader.put_in_hands(book), "Первый читатель должен взять книгу.")
	TEST_ASSERT_EQUAL(book.book_path, PATH_RUST, "Поднятая книга принимает железный переплёт.")
	book.pixel_y = 4
	book.alpha = 165
	book.open_book(first_reader)
	TEST_ASSERT(book.book_open, "Книга должна раскрыться.")
	TEST_ASSERT(length(book.overlays) > 0, "Открытая книга показывает знак своего пути.")
	TEST_ASSERT(book.turn_page(first_reader), "Читатель может перелистнуть страницу.")
	TEST_ASSERT(!book.turn_page(first_reader), "Повторный запрос в тот же момент не должен складывать звуки.")
	first_reader.dropItemToGround(book)
	TEST_ASSERT(!book.book_open, "Уроненная книга должна закрыться.")
	TEST_ASSERT_EQUAL(book.pixel_y, 4, "Закрытие сохраняет исходное положение предмета.")
	TEST_ASSERT_EQUAL(book.alpha, 165, "Закрытие сохраняет исходную прозрачность предмета.")
	TEST_ASSERT(!book.turn_page(first_reader), "Нельзя листать выпущенную книгу.")
	TEST_ASSERT(second_reader.put_in_hands(book), "Второй читатель должен взять книгу.")
	TEST_ASSERT_EQUAL(book.book_path, PATH_MOON, "В руках другого еретика книга становится зеркальной.")
	book.open_book(second_reader)
	book.ui_close(first_reader)
	TEST_ASSERT(book.book_open, "Запоздалое закрытие окна прежнего читателя не закрывает книгу в чужих руках.")
	var/list/data = book.ui_data(second_reader)
	var/list/book_data = data["book"]
	TEST_ASSERT_EQUAL(book_data["path"], PATH_MOON, "В интерфейс передаётся путь нового читателя.")
	TEST_ASSERT_EQUAL(data["points"], 9, "Книга показывает личные знания нового читателя.")
	TEST_ASSERT_EQUAL(first.knowledge_points, 4, "Передача книги не меняет знания прежнего читателя.")
	book.ui_close(second_reader)
	TEST_ASSERT(!book.book_open, "Закрытие окна текущим читателем складывает переплёт.")

/// Создание запасного кодекса и начертание руны сохраняют выбранный облик пути.
/datum/unit_test/heretic_book_recipe_and_rune/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.research_knowledge(/datum/eldritch_knowledge/base_cosmic, user)
	var/datum/eldritch_knowledge/codex_cicatrix/recipe = allocate(/datum/eldritch_knowledge/codex_cicatrix)
	TEST_ASSERT(recipe.on_finished_recipe(user, list(), run_loc_floor_top_right), "Запасной кодекс должен создаваться.")
	var/obj/item/forbidden_book/cosmic/book = locate() in run_loc_floor_top_right
	TEST_ASSERT_NOTNULL(book, "Ритуал должен создавать настоящий подтип звёздного атласа.")
	allocated += book
	var/obj/effect/eldritch/big/rune = allocate(/obj/effect/eldritch/big)
	rune.inscribe_path(PATH_COSMIC)
	TEST_ASSERT_EQUAL(rune.rune_path, PATH_COSMIC, "Руна должна запомнить знак Космоса.")
	TEST_ASSERT_EQUAL(length(rune.overlays), 1, "На руне должен быть ровно один знак пути.")
	rune.inscribe_path(PATH_MOON)
	TEST_ASSERT_EQUAL(length(rune.overlays), 1, "Перенастройка не должна складывать знаки разных путей.")


/// Статические описания не уходят в обновления, а доступность учитывает изменения прогресса и читателя.
/datum/unit_test/heretic_book_data_updates/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/reader = heretic.owner.current
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	var/list/static_data = book.ui_static_data(reader)
	var/list/data = book.ui_data(reader)
	var/list/catalog_knowledge = static_data["knowledge"]
	var/expected_knowledge = length(GLOB.heretic_start_knowledge) + length(GLOB.heretic_side_knowledge)
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/catalog_path = GLOB.heretic_paths[path_id]
		expected_knowledge += length(catalog_path.knowledge)
	TEST_ASSERT_EQUAL(length(catalog_knowledge), expected_knowledge, "Каталог содержит все ступени путей, начальные и побочные знания.")
	var/list/knowledge_by_id = list()
	for(var/list/entry as anything in catalog_knowledge)
		TEST_ASSERT_NULL(knowledge_by_id[entry["id"]], "Знание не должно повторяться в каталоге.")
		knowledge_by_id[entry["id"]] = entry
	var/list/ash_data = knowledge_by_id["/datum/eldritch_knowledge/base_ash"]
	TEST_ASSERT(ash_data, "Каталог должен содержать первый обет Пепла.")
	TEST_ASSERT_EQUAL(ash_data["path"], PATH_ASH, "Обет относится к Пути Пепла.")
	TEST_ASSERT_EQUAL(ash_data["stage"], 1, "Первый обет открывает дерево пути.")
	TEST_ASSERT_EQUAL(ash_data["cost"], 0, "Первый обет не требует очков.")
	var/list/rituals_by_id = list()
	var/regex/latin_letters = regex(@"[A-Za-z]")
	for(var/list/recipe as anything in static_data["rituals"])
		TEST_ASSERT(knowledge_by_id[recipe["id"]], "Каждый рецепт должен принадлежать знанию из каталога.")
		TEST_ASSERT(length(recipe["ingredients"]), "Каждый рецепт должен содержать ингредиенты.")
		TEST_ASSERT(recipe["duration"] > 0, "Книга должна показывать длительность обряда в секундах.")
		for(var/list/ingredient as anything in recipe["ingredients"])
			TEST_ASSERT(!latin_letters.Find(ingredient["name"]), "В рецепте [recipe["name"]] осталось английское имя ингредиента: [ingredient["name"]].")
		rituals_by_id[recipe["id"]] = recipe
	var/list/armor_recipe = rituals_by_id["/datum/eldritch_knowledge/armor"]
	TEST_ASSERT_EQUAL(armor_recipe["duration"], 5, "Обряд брони занимает пять секунд.")
	TEST_ASSERT(length(armor_recipe["hint"]), "Рецепт брони должен объяснять размещение готового стола.")
	var/list/hunt_recipe = rituals_by_id["/datum/eldritch_knowledge/spell/basic"]
	TEST_ASSERT_EQUAL(length(hunt_recipe["ingredients"]), 2, "Подношение требует и живое сердце, и назначенную цель.")
	var/list/ash_recipe = rituals_by_id["/datum/eldritch_knowledge/base_ash"]
	TEST_ASSERT(ash_recipe, "Книга должна показывать настоящий рецепт пепельного клинка.")
	var/list/ash_ingredients = ash_recipe["ingredients"]
	TEST_ASSERT_EQUAL(length(ash_ingredients), 2, "Для пепельного клинка нужны нож и спичка.")
	var/list/ash_amounts = list()
	for(var/list/ingredient as anything in ash_ingredients)
		ash_amounts[ingredient["name"]] = ingredient["amount"]
	TEST_ASSERT_EQUAL(ash_amounts["Нож, тесак или заточка"], 1, "Рецепт требует один нож с русским названием.")
	TEST_ASSERT_EQUAL(ash_amounts["Спичка"], 1, "Рецепт требует одну спичку с русским названием.")
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/catalog_path = GLOB.heretic_paths[path_id]
		var/final_type = catalog_path.knowledge[length(catalog_path.knowledge)]
		var/list/final_recipe = rituals_by_id["[final_type]"]
		TEST_ASSERT(final_recipe && final_recipe["ascension"], "Каждый путь должен иметь помеченный рецепт вознесения.")
		var/list/final_ingredients = final_recipe["ingredients"]
		TEST_ASSERT_EQUAL(length(final_ingredients), 1, "Одинаковые тела финального обряда объединяются в одну строку.")
		var/list/bodies = final_ingredients[1]
		TEST_ASSERT_EQUAL(bodies["amount"], HERETIC_ASCENSION_BODIES, "Рецепт вознесения использует установленное число тел.")
	TEST_ASSERT_NULL(data["knowledge"], "Обычное обновление не должно повторять описания знаний.")
	TEST_ASSERT_NULL(data["rituals"], "Обычное обновление не должно повторять рецепты.")
	var/list/states = data["knowledge_state"]
	var/list/base_state = states["/datum/eldritch_knowledge/base_ash"]
	TEST_ASSERT(base_state["available"], "Первый обет должен быть доступен.")
	TEST_ASSERT_EQUAL(book.knowledge_state(heretic), states, "Неизменившийся прогресс использует тот же список доступности.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, reader), "Читатель должен принять обет Пепла.")
	heretic.knowledge_points = 0
	states = book.knowledge_state(heretic)
	base_state = states["/datum/eldritch_knowledge/base_ash"]
	TEST_ASSERT(base_state["known"], "Исследование сразу отмечается изученным.")
	var/datum/heretic_path/path = GLOB.heretic_paths[PATH_ASH]
	var/datum/eldritch_knowledge/next_type = path.knowledge[2]
	var/list/next_state = states["[next_type]"]
	TEST_ASSERT(!next_state["available"], "Без очков следующая ступень закрыта.")
	heretic.knowledge_points = initial(next_type.cost)
	states = book.knowledge_state(heretic)
	next_state = states["[next_type]"]
	TEST_ASSERT(next_state["available"], "Начисление очков должно открыть следующую ступень без повторного открытия книги.")
	var/datum/antagonist/heretic/other_reader = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	states = book.knowledge_state(other_reader)
	base_state = states["/datum/eldritch_knowledge/base_ash"]
	TEST_ASSERT(!base_state["known"] && base_state["available"], "Другой читатель получает собственную доступность знаний.")
	var/datum/objective/sacrifice_ecult/objective = allocate(/datum/objective/sacrifice_ecult)
	TEST_ASSERT_EQUAL(objective.target_amount, HERETIC_ASCENSION_SACRIFICES, "Цель и книга должны требовать одинаковое число душ.")

/datum/tgui_window/heretic_book_test/New()
	id = "heretic-book-test"

/datum/tgui/heretic_book_test
	var/update_count = 0
	var/list/last_data

/datum/tgui/heretic_book_test/process_status()
	status = UI_INTERACTIVE
	return FALSE

/datum/tgui/heretic_book_test/send_update(custom_data, force)
	update_count++
	last_data = src_object.ui_data(user)

/// Тестовый кодекс однократно передаёт знания читателю и сохраняет их после потери книги.
/datum/unit_test/heretic_debug_book/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/reader = heretic.owner.current
	var/obj/item/forbidden_book/debug/book = allocate(/obj/item/forbidden_book/debug)
	var/starting_points = heretic.knowledge_points
	var/book_points = book.debug_knowledge_points
	TEST_ASSERT(book_points > 0, "Тестовая книга должна содержать очки знаний.")
	var/mob/living/carbon/human/outsider = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	TEST_ASSERT(outsider.put_in_hands(book), "Персонаж без роли может взять тестовую книгу.")
	book.attack_self(outsider)
	TEST_ASSERT_EQUAL(book.debug_knowledge_points, book_points, "Персонаж без роли не расходует запас книги.")
	outsider.dropItemToGround(book)
	book.attack_self(reader)
	TEST_ASSERT_EQUAL(heretic.knowledge_points, starting_points, "Книга на полу не выдаёт знания.")
	TEST_ASSERT(reader.put_in_hands(book), "Читатель должен взять тестовую книгу.")
	reader.Paralyze(10 SECONDS)
	book.attack_self(reader)
	TEST_ASSERT_EQUAL(book.debug_knowledge_points, book_points, "Недееспособный читатель не расходует запас.")
	reader.SetParalyzed(0)
	TEST_ASSERT(reader.put_in_hands(book), "После паралича читатель должен снова взять выпавшую книгу.")
	var/datum/tgui/heretic_book_test/ui = allocate(/datum/tgui/heretic_book_test, reader, book, "ForbiddenLore", "Кодекс Рубцов")
	ui.window = allocate(/datum/tgui_window/heretic_book_test)
	ui.window.locked_by = ui
	ui.initialized = TRUE
	ui.status = UI_INTERACTIVE
	SStgui.on_open(ui)
	book.attack_self(reader)
	TEST_ASSERT_EQUAL(heretic.knowledge_points, starting_points + book_points, "Запас книги должен перейти еретику.")
	TEST_ASSERT_EQUAL(ui.last_data["points"], heretic.knowledge_points, "Открытая книга сразу показывает выданные очки.")
	TEST_ASSERT_EQUAL(book.debug_knowledge_points, 0, "Выданный запас должен исчерпаться.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, reader), "Тестовая книга позволяет выбрать путь.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/ashen_grasp, reader), "Выданные очки оплачивают исследование.")
	var/remaining_points = heretic.knowledge_points
	book.attack_self(reader)
	TEST_ASSERT_EQUAL(heretic.knowledge_points, remaining_points, "Повторное открытие не восполняет потраченные очки.")
	reader.dropItemToGround(book)
	var/datum/antagonist/heretic/other = allocate_heretic(get_step(run_loc_floor_bottom_left, NORTH))
	var/other_points = other.knowledge_points
	TEST_ASSERT(other.owner.current.put_in_hands(book), "Другой еретик может взять использованную книгу.")
	var/list/data = book.ui_data(other.owner.current)
	TEST_ASSERT_EQUAL(data["points"], other_points, "Передача книги не передаёт знания первого читателя.")
	qdel(book)
	TEST_ASSERT_EQUAL(heretic.knowledge_points, remaining_points, "Удаление книги не отнимает знания.")

/// Открытая книга обновляется по событиям прогресса и цели, а обычный тик TGUI не собирает данные.
/datum/unit_test/heretic_book_event_updates/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/reader = heretic.owner.current
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	TEST_ASSERT(reader.put_in_hands(book), "Для чтения нужно держать книгу.")
	var/datum/tgui/heretic_book_test/ui = allocate(/datum/tgui/heretic_book_test, reader, book, "ForbiddenLore", "Кодекс Рубцов")
	ui.window = allocate(/datum/tgui_window/heretic_book_test)
	ui.window.locked_by = ui
	ui.initialized = TRUE
	ui.status = UI_INTERACTIVE
	SStgui.on_open(ui)
	book.ui_interact(reader, ui)
	TEST_ASSERT(!ui.autoupdate, "Книга должна отключить периодическую отправку данных.")
	var/previous_updates = ui.update_count
	ui.process(1)
	TEST_ASSERT_EQUAL(ui.update_count, previous_updates, "Тик TGUI не должен повторно собирать каталог и прогресс.")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, reader), "Исследование должно пройти.")
	TEST_ASSERT_EQUAL(ui.last_data["selected_path"], PATH_ASH, "Исследование сразу обновляет открытую книгу.")
	var/datum/eldritch_knowledge/base_ash/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	knowledge.gain_combat_resource()
	var/list/resource = ui.last_data["combat_resource"]
	TEST_ASSERT_EQUAL(resource["value"], knowledge.combat_resource, "Изменение боевого запаса сразу отражается в книге.")
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/mind/target_mind = allocate_mind()
	target_mind.current = target
	target.mind = target_mind
	heretic.set_hunt_target(target_mind)
	var/list/hunt = ui.last_data["hunt"]
	TEST_ASSERT_EQUAL(hunt["target_name"], target.real_name, "Новое имя из сердца обновляет уже открытую книгу.")
	TEST_ASSERT_EQUAL(book.observed_hunt_body?.resolve(), target, "Книга должна наблюдать за назначенным телом.")
	TEST_ASSERT_EQUAL(target.stat, CONSCIOUS, "Цель должна начинать проверку в сознании.")
	previous_updates = ui.update_count
	target.Unconscious(10 SECONDS)
	TEST_ASSERT_EQUAL(target.stat, UNCONSCIOUS, "Потеря сознания должна изменить состояние цели.")
	TEST_ASSERT(wait_for_var(book, "hunt_update_timer", null), "Обновление книги должно дождаться исполнения таймера.")
	TEST_ASSERT(ui.update_count > previous_updates, "Смена состояния цели должна отправить обновление.")
	var/mob/living/carbon/human/new_body = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	target_mind.transfer_to(new_body)
	TEST_ASSERT(wait_for_var(book, "hunt_update_timer", null), "Перенос души должен дождаться обновления книги.")
	TEST_ASSERT_EQUAL(book.observed_hunt_body?.resolve(), new_body, "Наблюдение следует за душой в новое тело.")
	previous_updates = ui.update_count
	target.set_stat(CONSCIOUS)
	TEST_ASSERT_NULL(book.hunt_update_timer, "Сигнал старого тела не должен назначать обновление книги.")
	TEST_ASSERT_EQUAL(ui.update_count, previous_updates, "Старое тело больше не обновляет охоту.")
	reader.dropItemToGround(book)
	TEST_ASSERT_NULL(book.observed_hunt_body, "После падения книги наблюдение за целью прекращается.")
	TEST_ASSERT_NULL(book.observed_hunt_mind, "После падения книги не остаётся наблюдения за душой.")
	ui.close()
