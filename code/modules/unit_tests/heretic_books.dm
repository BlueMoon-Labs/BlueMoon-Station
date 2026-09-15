/// Подготовка различает изученный рецепт, доступные вещи и надетую защиту.
/datum/unit_test/heretic_book_preparation/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.selected_path = PATH_BLADE
	heretic.gain_knowledge(/datum/eldritch_knowledge/base_blade)
	heretic.gain_knowledge(/datum/eldritch_knowledge/armor)
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	var/list/data = book.preparation_data(heretic)
	TEST_ASSERT(!data["blade_ready"] && !data["armor_ready"], "Изученные рецепты не означают наличие экипировки.")
	var/obj/item/melee/sickly_blade/duelist/blade = allocate(/obj/item/melee/sickly_blade/duelist, user)
	data = book.preparation_data(heretic)
	TEST_ASSERT(!data["blade_ready"], "Чужой тёмный клинок не подходит.")
	blade.bound_mind = heretic.owner
	var/obj/item/clothing/suit/hooded/cultrobes/eldritch/robes = allocate(/obj/item/clothing/suit/hooded/cultrobes/eldritch)
	TEST_ASSERT(user.equip_to_slot_if_possible(robes, ITEM_SLOT_OCLOTHING), "Мантия надета.")
	data = book.preparation_data(heretic)
	TEST_ASSERT(data["blade_ready"] && !data["armor_ready"], "Клинок доступен, но капюшон ещё не поднят.")
	robes.ToggleHood()
	data = book.preparation_data(heretic)
	TEST_ASSERT(data["armor_ready"], "Поднятый капюшон завершает подготовку брони.")
	blade.forceMove(run_loc_floor_top_right)
	data = book.preparation_data(heretic)
	TEST_ASSERT(!data["blade_ready"], "Утраченный клинок больше не отмечается готовым.")

/// Кнопка книги вызывает своё сердце и не прячет его при запоздалом повторном нажатии.
/datum/unit_test/heretic_book_call_heart/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/carbon/human/user = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	TEST_ASSERT(user.put_in_hands(book), "Книга в руке.")
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart)
	heart.bind(heretic.owner)
	heart.moveToNullspace()
	heretic.summon_items += heart
	var/list/data = book.heart_preparation_data(heretic)
	TEST_ASSERT(data["can_call"] && !data["ready"], "Сердце за завесой доступно для призыва.")
	TEST_ASSERT(book.call_heart(user, heretic), "Книга принимает призыв.")
	TEST_ASSERT(heart in user.held_items, "Сердце оказывается в руке через обычную способность.")
	TEST_ASSERT(book.call_heart(user, heretic), "Запоздалый повторный запрос безопасен.")
	TEST_ASSERT(heart in user.held_items, "Кнопка призыва не прячет уже доступное сердце.")
	var/mob/living/carbon/human/other = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	user.dropItemToGround(heart)
	TEST_ASSERT(other.put_in_hands(heart), "Другой человек забрал сердце.")
	data = book.heart_preparation_data(heretic)
	TEST_ASSERT(!data["can_call"] && !data["ready"], "Удерживаемое другим человеком сердце недоступно.")
	book.call_heart(user, heretic)
	TEST_ASSERT(heart in other.held_items, "Книга не отбирает сердце из чужой руки.")
	TEST_ASSERT(!book.call_heart(other, heretic), "Чужое тело не вызывает способность владельца.")

/// Подсказка следующего действия существует у каждого зарегистрированного пути.
/datum/unit_test/heretic_deed_next_steps/Run()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/datum/heretic_deed/deed = allocate(path.deed_type)
		TEST_ASSERT(length(deed.next_step), "Путь [path_id] объясняет конкретное следующее действие.")

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
	var/list/armor_knowledge = knowledge_by_id["/datum/eldritch_knowledge/armor"]
	TEST_ASSERT(armor_knowledge["starter_armor"], "Общий рецепт брони должен быть отмечен для подсказки по развитию.")
	TEST_ASSERT(!ash_data["starter_armor"], "Начальное знание пути не должно подменять рецепт брони.")
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

/// Подсказки каждого пути показывают выданные способности и убирают отозванные.
/datum/unit_test/heretic_book_combat_guidance/Run()
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		var/datum/antagonist/heretic/heretic = allocate_heretic()
		var/mob/living/reader = heretic.owner.current
		TEST_ASSERT(heretic.research_knowledge(path.knowledge[1], reader), "Читатель должен выбрать путь [path_id].")
		heretic.gain_knowledge(/datum/eldritch_knowledge/spell/basic)
		heretic.gain_knowledge(/datum/eldritch_knowledge/spell/summon/book)
		var/datum/eldritch_knowledge/base_knowledge = heretic.get_knowledge(path.knowledge[1])
		var/list/data = book.ui_data(reader)
		var/list/abilities = data["combat_abilities"]
		var/list/ability_ids = list()
		for(var/list/ability as anything in abilities)
			ability_ids += ability["id"]
			TEST_ASSERT(length(ability["name"]) && length(ability["desc"]) && length(ability["usage"]), "У способности [path_id] должны быть название, описание и способ применения.")
		var/datum/eldritch_knowledge/spell/summon/book/summon_book = heretic.get_knowledge(/datum/eldritch_knowledge/spell/summon/book)
		for(var/obj/effect/proc_holder/spell/spell as anything in heretic.owner.spell_list)
			if(spell != summon_book.granted_spell)
				TEST_ASSERT("[spell.type]" in ability_ids, "В подсказках [path_id] должна быть выданная способность [spell.name].")
		TEST_ASSERT("/obj/effect/proc_holder/spell/targeted/touch/mansus_grasp" in ability_ids, "Хватка должна быть видна у каждого пути.")
		TEST_ASSERT_EQUAL(length(abilities), 2, "Призыв кодекса не должен вытеснять боевые способности.")
		var/list/deed = data["deed"]
		TEST_ASSERT(length(deed["desc"]) && deed["goal"] > 0, "Книга должна описывать текущее дело [path_id].")
		base_knowledge.on_body_lose(reader)
		abilities = book.combat_ability_data(heretic)
		TEST_ASSERT_EQUAL(length(abilities), 1, "Отозванная способность [path_id] исчезает из подсказки.")

/// Изучение, вознесение и утрата заклинания обновляют доступные боевые подсказки.
/datum/unit_test/heretic_book_combat_guidance_progress/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/reader = heretic.owner.current
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_spirit, reader), "Читатель должен выбрать Дух.")
	TEST_ASSERT_EQUAL(length(book.combat_ability_data(heretic)), 1, "При выборе пути доступно только Разлучение.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	TEST_ASSERT_EQUAL(length(book.combat_ability_data(heretic)), 2, "Изученная Переправа появляется в подсказке.")
	heretic.gain_knowledge(/datum/eldritch_knowledge/final_eldritch/spirit_final)
	TEST_ASSERT_EQUAL(length(book.combat_ability_data(heretic)), 2, "Изучение финального обряда ещё не выдаёт Последний рейс.")
	var/datum/eldritch_knowledge/final_eldritch/spirit_final/final_knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/final_eldritch/spirit_final)
	final_knowledge.finished = TRUE
	final_knowledge.on_body_gain(reader)
	TEST_ASSERT_EQUAL(length(book.combat_ability_data(heretic)), 3, "Выданная способность вознесения появляется в подсказке.")
	final_knowledge.on_body_lose(reader)
	TEST_ASSERT_EQUAL(length(book.combat_ability_data(heretic)), 2, "Утрата вознесения убирает его способность.")
	var/datum/eldritch_knowledge/spell/spirit_step/step = heretic.get_knowledge(/datum/eldritch_knowledge/spell/spirit_step)
	qdel(step.granted_spell)
	TEST_ASSERT_EQUAL(length(book.combat_ability_data(heretic)), 1, "Удалённое заклинание не остаётся доступным на странице.")

/// Потерянное сердце возвращается тем же предметом, а уничтоженное восстанавливается без сброса охоты.
/datum/unit_test/heretic_heart_recovery/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/body = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	var/datum/eldritch_knowledge/spell/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	var/obj/effect/proc_holder/spell/self/heretic_summon/heart/spell = knowledge.granted_spell
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_top_right)
	heart.bind(heretic.owner)
	var/datum/mind/target = allocate_mind()
	heretic.hunt_target = target
	heretic.total_sacrifices = 1
	spell.cast(list(body), body)
	TEST_ASSERT(heart in body.held_items, "Потерянное сердце возвращается в руку тем же экземпляром.")
	TEST_ASSERT(!(heart in heretic.summon_items), "Призванное сердце не остаётся за завесой.")
	TEST_ASSERT_EQUAL(heretic.hunt_target, target, "Возвращение сердца сохраняет назначенную душу.")
	qdel(heart)
	spell.cast(list(body), body)
	heart = locate() in body.held_items
	TEST_ASSERT_NOTNULL(heart, "Уничтоженное сердце восстанавливается.")
	allocated += heart
	TEST_ASSERT_EQUAL(heart.owner_mind, heretic.owner, "Восстановленное сердце связано с владельцем.")
	TEST_ASSERT_EQUAL(heretic.hunt_target, target, "Восстановление не сбрасывает цель охоты.")
	TEST_ASSERT_EQUAL(heretic.total_sacrifices, 1, "Восстановление не сбрасывает подношения.")
	var/owned_count = 0
	for(var/obj/item/living_heart/candidate as anything in GLOB.living_heart_cache)
		if(candidate.owner_mind == heretic.owner)
			owned_count++
	TEST_ASSERT_EQUAL(owned_count, 1, "Восстановление не создаёт дубликатов сердца.")
	spell.cast(list(body), body)
	TEST_ASSERT(heart in heretic.summon_items, "Повторное нажатие по-прежнему прячет своё сердце.")
	spell.cast(list(body), body)
	TEST_ASSERT(heart in body.held_items, "Спрятанное сердце можно снова призвать.")

/// Призыв не забирает чужие сердца, предметы в чужом инвентаре и компоненты действующего обряда.
/datum/unit_test/heretic_heart_recovery_ownership/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/body = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	var/datum/eldritch_knowledge/spell/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	var/obj/effect/proc_holder/spell/self/heretic_summon/heart/spell = knowledge.granted_spell
	var/datum/antagonist/heretic/other = allocate_heretic(run_loc_floor_top_right)
	var/obj/item/living_heart/foreign = allocate(/obj/item/living_heart, get_turf(body))
	foreign.bind(other.owner)
	TEST_ASSERT(!spell.can_summon_item(foreign, body), "Чужое сердце на полу не подходит для призыва.")
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_top_right)
	heart.bind(heretic.owner)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, other.owner.current)
	heart.forceMove(bag)
	spell.cast(list(body), body)
	TEST_ASSERT_EQUAL(heart.loc, bag, "Сердце в чужом рюкзаке не вырывается из инвентаря.")
	TEST_ASSERT_EQUAL(foreign.loc, get_turf(body), "Чужое сердце не прячется за завесу.")
	TEST_ASSERT_NULL(locate(/obj/item/living_heart) in body.held_items, "Блокировка не создаёт запасное сердце.")
	heart.forceMove(get_turf(body))
	var/obj/effect/eldritch/big/rune = allocate(/obj/effect/eldritch/big, get_turf(body))
	rune.reserve_atoms(list(heart))
	spell.cast(list(body), body)
	TEST_ASSERT_EQUAL(heart.loc, get_turf(body), "Сердце остаётся компонентом начатого обряда.")
	rune.release_atoms()
	spell.cast(list(body), body)
	TEST_ASSERT(heart in heretic.summon_items, "Свободное собственное сердце можно спрятать.")

/// Движение прерывает возврат, а чужой захват во время канала проверяется повторно.
/datum/unit_test/heretic_heart_recovery_interrupted/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/body = heretic.owner.current
	heretic.gain_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	var/datum/eldritch_knowledge/spell/knowledge = heretic.get_knowledge(/datum/eldritch_knowledge/spell/summon/heart)
	var/obj/effect/proc_holder/spell/self/heretic_summon/heart/spell = knowledge.granted_spell
	var/obj/item/living_heart/heart = allocate(/obj/item/living_heart, run_loc_floor_top_right)
	heart.bind(heretic.owner)
	addtimer(CALLBACK(body, TYPE_PROC_REF(/atom/movable, forceMove), get_step(body, EAST)), 1 SECONDS)
	spell.cast(list(body), body)
	TEST_ASSERT_EQUAL(heart.loc, run_loc_floor_top_right, "Прерванный возврат оставляет сердце на месте.")
	TEST_ASSERT(!spell.recovery_in_progress, "Прерывание освобождает способность для следующей попытки.")
	var/mob/living/other = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	addtimer(CALLBACK(other, TYPE_PROC_REF(/mob, put_in_hands), heart), 1 SECONDS)
	spell.cast(list(body), body)
	TEST_ASSERT(heart in other.held_items, "Подобранное во время канала сердце остаётся у нового держателя.")
	TEST_ASSERT_NULL(locate(/obj/item/living_heart) in body.held_items, "Сорванный возврат не создаёт второе сердце.")

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
