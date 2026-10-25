/// Игрок в режиме меню: тесты меню не зависят от дефолта режима в конфиге
/mob/living/carbon/human/dummy/consistent/context_menu_user

/mob/living/carbon/human/dummy/consistent/context_menu_user/right_click_mode()
	return RIGHT_CLICK_MODE_MENU

/mob/living/carbon/human/dummy/consistent/context_menu_probe
	var/right_clicked = FALSE
	var/shift_clicked = FALSE
	/// Интент, с которым пришёл последний обычный клик (ловится только при record_clicks)
	var/seen_intent
	var/record_clicks = FALSE
	var/click_mode = RIGHT_CLICK_MODE_MENU

/mob/living/carbon/human/dummy/consistent/context_menu_probe/right_click_mode()
	return click_mode

/mob/living/carbon/human/dummy/consistent/context_menu_probe/RightClickOn(atom/A, params)
	right_clicked = TRUE

/mob/living/carbon/human/dummy/consistent/context_menu_probe/ShiftClickOn(atom/A)
	shift_clicked = TRUE

/mob/living/carbon/human/dummy/consistent/context_menu_probe/ClickOn(atom/A, params)
	if(record_clicks)
		var/list/modifiers = params2list(params)
		if(!modifiers["shift"] && !modifiers["right"])
			seen_intent = a_intent
			return
	return ..()

/obj/item/context_menu_test_item
	name = "context menu test item"
	var/verb_used = FALSE
	var/alt_afterattacked = FALSE

/obj/item/context_menu_test_item/altafterattack(atom/target, mob/user, proximity_flag, click_parameters)
	alt_afterattacked = TRUE
	return ..()

/obj/item/context_menu_test_item/verb/context_menu_test_verb()
	set name = "Test verb"
	set src in usr
	verb_used = TRUE

/proc/find_context_entry(datum/context_menu/menu, name)
	for(var/datum/context_menu_entry/entry as anything in menu.entries)
		if(entry.name == name)
			return entry

/// В режиме меню ПКМ - меню, Shift+ПКМ - действие; режим действий меняет местами; в бою ПКМ - действие; Shift+ЛКМ - осмотр
/datum/unit_test/context_menu_routing

/datum/unit_test/context_menu_routing/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_probe/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_probe)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	TEST_ASSERT(!SEND_SIGNAL(user, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE), "Игрок в тесте не должен быть в комбат-режиме")

	user.CommonClickOn(target, "right=1")
	TEST_ASSERT_NOTNULL(user.active_context_menu, "ПКМ в режиме меню не открыл меню")
	TEST_ASSERT_EQUAL(user.active_context_menu.target, target, "Меню открылось не на цели")
	TEST_ASSERT(!user.right_clicked, "ПКМ в режиме меню ещё и сделал действие")

	user.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT_NULL(user.active_context_menu, "Клик мимо не закрыл меню")
	TEST_ASSERT(!user.right_clicked, "Клик, закрывший меню, ещё и выполнил действие")
	user.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT(user.right_clicked, "Shift+ПКМ в режиме меню не сделал второе действие")

	user.CommonClickOn(target, "left=1;shift=1")
	TEST_ASSERT(user.shift_clicked, "Shift+ЛКМ не осматривает")

	// зажатый ПКМ + ЛКМ: второе действие, отпускание ПКМ после этого ничего не делает
	user.right_clicked = FALSE
	user.CommonClickOn(target, "left=1;right=1;button=left")
	TEST_ASSERT(user.right_clicked, "ЛКМ при зажатом ПКМ не сделал второе действие")
	TEST_ASSERT_NULL(user.active_context_menu, "ЛКМ при зажатом ПКМ открыл меню")
	user.right_clicked = FALSE
	user.CommonClickOn(target, "right=1;button=right")
	TEST_ASSERT(!user.right_clicked && !user.active_context_menu, "Отпускание зажатого ПКМ что-то сделало")
	user.CommonClickOn(target, "right=1;button=right")
	TEST_ASSERT_NOTNULL(user.active_context_menu, "Следующий ПКМ после комбинации не открыл меню")
	user.close_context_menu()

	user.click_mode = RIGHT_CLICK_MODE_ACTION
	user.right_clicked = FALSE
	user.CommonClickOn(target, "right=1")
	TEST_ASSERT(user.right_clicked, "ПКМ в режиме действий не сделал действие")
	TEST_ASSERT_NULL(user.active_context_menu, "ПКМ в режиме действий открыл меню")
	user.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT_NOTNULL(user.active_context_menu, "Shift+ПКМ в режиме действий не открыл меню")
	TEST_ASSERT_EQUAL(user.right_click_action_hint(), "ПКМ", "Подсказка действия в режиме действий")
	user.close_context_menu()

	user.click_mode = RIGHT_CLICK_MODE_MENU
	TEST_ASSERT_EQUAL(user.right_click_action_hint(), "Shift-ПКМ", "Подсказка действия в режиме меню")
	SEND_SIGNAL(user, COMSIG_TOGGLE_COMBAT_MODE)
	TEST_ASSERT(SEND_SIGNAL(user, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE), "Не удалось включить комбат-режим")
	user.right_clicked = FALSE
	user.CommonClickOn(target, "right=1")
	TEST_ASSERT(user.right_clicked, "ПКМ в комбат-режиме не сделал действие")
	TEST_ASSERT_NULL(user.active_context_menu, "ПКМ в комбат-режиме открыл меню")
	SEND_SIGNAL(user, COMSIG_TOGGLE_COMBAT_MODE)

/datum/unit_test/context_menu_right_click_mode

/datum/unit_test/context_menu_right_click_mode/Run()
	var/mob/living/carbon/human/human_type = /mob/living/carbon/human
	var/mob/living/silicon/robot/robot_type = /mob/living/silicon/robot
	var/mob/living/silicon/ai/ai_type = /mob/living/silicon/ai
	var/mob/dead/observer/ghost_type = /mob/dead/observer
	TEST_ASSERT(initial(human_type.right_click_actions), "У человека ПКМ должен быть действием")
	TEST_ASSERT(initial(robot_type.right_click_actions), "У киборга ПКМ должен быть действием")
	TEST_ASSERT(!initial(ai_type.right_click_actions), "У ИИ ПКМ должен открывать меню BYOND")
	TEST_ASSERT(!initial(ghost_type.right_click_actions), "У призрака ПКМ должен открывать меню BYOND")

/// Меню по человеку: осмотр, текущий интент помечен, остальные интенты - в подменю «Интенты…»; шапка открывает выбор режима
/datum/unit_test/context_menu_human_entries

/datum/unit_test/context_menu_human_entries/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	user.a_intent = INTENT_HELP
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1;shift=1")
	TEST_ASSERT_NOTNULL(menu, "Меню не открылось")
	for(var/name in list("Осмотреть", "Указать", "Потянуть", "Утешить", "Толкнуть", "Интенты…"))
		TEST_ASSERT_NOTNULL(find_context_entry(menu, name), "Нет пункта «[name]»")
	for(var/name in list("Обезоружить", "Схватить", "Ударить"))
		TEST_ASSERT_NULL(find_context_entry(menu, name), "Пункт другого интента «[name]» не убран в «Интенты…»")
	var/datum/context_menu_entry/help_entry = find_context_entry(menu, "Утешить")
	TEST_ASSERT_EQUAL(help_entry.style, CONTEXT_ENTRY_CURRENT, "Текущий интент не помечен")
	TEST_ASSERT_NOTNULL(menu.header_entry, "Шапка меню не кликабельна")
	var/header_row_found = FALSE
	for(var/atom/movable/screen/context_menu/row in menu.screen_objects)
		if(row.entry == menu.header_entry)
			header_row_found = TRUE
	TEST_ASSERT(header_row_found, "Шапка меню не нарисована как пункт")
	menu.choose(find_context_entry(menu, "Интенты…"))
	for(var/name in list("Назад", "Обезоружить", "Схватить", "Ударить"))
		TEST_ASSERT_NOTNULL(find_context_entry(menu, name), "В «Интенты…» нет «[name]»")
	var/datum/context_menu_entry/harm_entry = find_context_entry(menu, "Ударить")
	TEST_ASSERT_EQUAL(harm_entry.style, CONTEXT_ENTRY_DANGER, "Удар не помечен как агрессивный")
	menu.choose(find_context_entry(menu, "Назад"))
	TEST_ASSERT_NOTNULL(find_context_entry(menu, "Утешить"), "«Назад» из интентов не вернул действия цели")
	if(user.GetComponent(/datum/component/interaction_menu_granter))
		TEST_ASSERT_NOTNULL(find_context_entry(menu, "Взаимодействовать"), "Нет пункта взаимодействий")
	for(var/datum/context_menu_entry/entry as anything in menu.entries)
		TEST_ASSERT(!istype(entry, /datum/context_menu_entry/verb_call), "У моба в меню оказался верб [entry.name]")
	TEST_ASSERT(length(menu.screen_objects) > length(menu.entries), "Меню не нарисовано")
	user.close_context_menu()

/// Хоткеи не растягивают меню: в строках только имена, хоткей строки под курсором - плашкой сбоку
/datum/unit_test/context_menu_compact_hints

/datum/unit_test/context_menu_compact_hints/Run()
	TEST_ASSERT_EQUAL(context_menu_text_width("Осмотреть"), 48, "Ширина текста не по буквам Small Fonts")
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	user.a_intent = INTENT_HELP
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1;shift=1")
	var/atom/movable/screen/context_menu/examine_row
	var/widest_name = 0
	for(var/atom/movable/screen/context_menu/row in menu.screen_objects)
		if(row.entry == menu.header_entry)
			continue
		widest_name = max(widest_name, context_menu_text_width(row.entry.name))
		if(row.entry.name == "Осмотреть")
			examine_row = row
	TEST_ASSERT_NOTNULL(examine_row, "Нет строки «Осмотреть»")
	for(var/atom/movable/screen/context_menu_text/label in menu.screen_objects)
		TEST_ASSERT(!findtext(label.maptext, "Shift-ЛКМ"), "Хоткей нарисован в строке и растягивает меню")
	TEST_ASSERT(menu.width <= max(widest_name, context_menu_text_width(menu.header_text || capitalize(target.name), TRUE) + 8 + context_menu_text_width("режим")) + 8, "Меню шире самого длинного имени")

	examine_row.MouseEntered()
	var/hint_shown = FALSE
	for(var/atom/movable/screen/context_menu_text/label in menu.hint_objects)
		if(findtext(label.maptext, "Shift-ЛКМ"))
			hint_shown = TRUE
	TEST_ASSERT(hint_shown, "Наведение на «Осмотреть» не показало хоткей")
	examine_row.MouseExited()
	TEST_ASSERT_EQUAL(length(menu.hint_objects), 0, "Плашка хоткея осталась после ухода курсора")
	examine_row.MouseEntered()
	user.close_context_menu()
	TEST_ASSERT_EQUAL(length(menu.hint_objects), 0, "Плашка хоткея пережила закрытие меню")

/// Значок - видимая часть спрайта: мелкая вещь в натуральную величину, крупная ровно вдвое меньше, в обоих случаях в своём месте строки; сглаженный стол без своего стейта - вдвое меньше целиком
/datum/unit_test/context_menu_icon_scale

/datum/unit_test/context_menu_icon_scale/Run()
	var/obj/item/reagent_containers/glass/beaker/beaker = allocate(/obj/item/reagent_containers/glass/beaker)
	var/obj/item/storage/toolbox/mechanical/toolbox = allocate(/obj/item/storage/toolbox/mechanical)
	var/obj/structure/table/glass/table = allocate(/obj/structure/table/glass)
	var/started = REALTIMEOFDAY
	var/list/beaker_bounds = context_menu_icon_bounds(beaker.icon, beaker.icon_state, beaker.dir)
	TEST_ASSERT(REALTIMEOFDAY - started < 2, "Рамка стейта считается дольше 0.2 с")
	TEST_ASSERT(beaker_bounds[3] - beaker_bounds[1] < 16 && beaker_bounds[4] - beaker_bounds[2] < 16, "Мензурка не уместилась в 16 px: [json_encode(beaker_bounds)]")
	TEST_ASSERT(beaker_bounds[1] > 1 && beaker_bounds[3] < 32, "Рамка мензурки на всю иконку: [json_encode(beaker_bounds)]")
	for(var/obj/thing as anything in list(beaker, toolbox, table))
		var/atom/movable/screen/context_menu_icon/icon_object = new(null, thing, CONTEXT_MENU_ICON_ROW_HEIGHT)
		var/list/bounds = context_menu_icon_bounds(thing.icon, thing.icon_state, thing.dir)
		var/matrix/transform = icon_object.transform
		var/expected_scale = max(bounds[3] - bounds[1], bounds[4] - bounds[2]) + 1 > CONTEXT_MENU_ICON_SIZE ? 0.5 : 1
		TEST_ASSERT_EQUAL(transform.a, expected_scale, "[thing]: масштаб не целый или не тот")
		// видимая часть после масштаба вокруг центра и сдвига
		var/left = 16 + expected_scale * (bounds[1] - 1 - 16) + transform.c
		var/right = 16 + expected_scale * (bounds[3] - 16) + transform.c
		var/bottom = 16 + expected_scale * (bounds[2] - 1 - 16) + transform.f
		var/top = 16 + expected_scale * (bounds[4] - 16) + transform.f
		TEST_ASSERT(left >= 1 && right <= 2 + CONTEXT_MENU_ICON_SIZE + 1, "[thing]: значок вылез из своего места по ширине ([left]..[right])")
		TEST_ASSERT(bottom >= -1 && top <= CONTEXT_MENU_ICON_ROW_HEIGHT + 1, "[thing]: значок вылез из строки по высоте ([bottom]..[top])")
		qdel(icon_object)
	var/list/toolbox_bounds = context_menu_icon_bounds(toolbox.icon, toolbox.icon_state, toolbox.dir)
	TEST_ASSERT(toolbox_bounds[3] - toolbox_bounds[1] >= 16, "Ящик неожиданно мелкий, тест не проверяет уменьшение: [json_encode(toolbox_bounds)]")
	TEST_ASSERT_EQUAL(json_encode(context_menu_icon_bounds(table.icon, table.icon_state, table.dir)), json_encode(list(1, 1, 32, 32, 32, 32)), "Рамка сглаженного стола взята по уголку")

/// Пункт интента делает одно действие этим интентом и возвращает прежний
/datum/unit_test/context_menu_intent_once

/datum/unit_test/context_menu_intent_once/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_probe/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_probe)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	user.a_intent = INTENT_HELP
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1;shift=1")
	user.record_clicks = TRUE
	menu.choose(find_context_entry(menu, "Интенты…"))
	menu.choose(find_context_entry(menu, "Ударить"))
	TEST_ASSERT_EQUAL(user.seen_intent, INTENT_HARM, "Клик из меню пришёл не с интентом вреда")
	TEST_ASSERT_EQUAL(user.a_intent, INTENT_HELP, "Интент игрока не вернулся")
	TEST_ASSERT_NULL(user.active_context_menu, "Меню не закрылось после выбора")
	TEST_ASSERT(QDELETED(menu), "Меню не удалено после выбора")

/// Куча на клетке: меню сразу по объекту под курсором, остальные - пунктом «Другие на клетке»; по полу - список клетки
/datum/unit_test/context_menu_tile_pick

/datum/unit_test/context_menu_tile_pick/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/turf/next_turf = get_step(user, EAST)
	var/obj/item/pen/pen = allocate(/obj/item/pen, next_turf)

	var/datum/context_menu/menu = user.open_context_menu(pen, "right=1;shift=1")
	TEST_ASSERT_EQUAL(menu.target, pen, "Одиночный предмет должен открываться сразу")
	TEST_ASSERT_NOTNULL(find_context_entry(menu, "Взять"), "Нет пункта «Взять»")
	TEST_ASSERT_NULL(menu.tile, "У одиночного предмета не из чего выбирать, а список клетки есть")

	var/obj/item/paper/paper = allocate(/obj/item/paper, next_turf)
	menu = user.open_context_menu(pen, "right=1;shift=1")
	TEST_ASSERT_EQUAL(menu.target, pen, "В куче меню должно открываться по объекту под курсором")
	TEST_ASSERT_NOTNULL(find_context_entry(menu, "Взять"), "В куче нет «Взять» у предмета под курсором")
	var/datum/context_menu_entry/others = find_context_entry(menu, "Другие на клетке (1)")
	TEST_ASSERT_NOTNULL(others, "Нет пункта «Другие на клетке» со счётом остальных")
	menu.choose(others)
	TEST_ASSERT_NULL(menu.target, "«Другие на клетке» не открыл список клетки")
	var/datum/context_menu_entry/pick/pick_pen
	var/found_paper = FALSE
	for(var/datum/context_menu_entry/pick/entry in menu.entries)
		var/atom/picked = entry.picked_ref?.resolve()
		if(picked == pen)
			pick_pen = entry
		if(picked == paper)
			found_paper = TRUE
	TEST_ASSERT_NOTNULL(pick_pen, "Ручки нет в списке клетки")
	TEST_ASSERT(found_paper, "Бумаги нет в списке клетки")
	menu.choose(pick_pen)
	TEST_ASSERT_EQUAL(menu.target, pen, "Выбор объекта не перестроил меню")
	TEST_ASSERT_NOTNULL(find_context_entry(menu, "Назад"), "Нет пункта «Назад»")
	menu.choose(find_context_entry(menu, "Назад"))
	TEST_ASSERT_NULL(menu.target, "«Назад» не вернул к списку клетки")

	menu = user.open_context_menu(next_turf, "right=1;shift=1")
	TEST_ASSERT_NULL(menu.target, "ПКМ по полу с вещами должен начинаться со списка клетки")
	user.close_context_menu()

/// Длинный список листается пунктом «Ещё…» по кругу, и на экране именно он
/datum/unit_test/context_menu_paging

/datum/unit_test/context_menu_paging/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/turf/next_turf = get_step(user, EAST)
	// разные имена, иначе одинаковые ручки свернутся в одну строку
	for(var/i in 1 to CONTEXT_MENU_MAX_ROWS + 2)
		var/obj/item/pen/pen = allocate(/obj/item/pen, next_turf)
		pen.name = "pen [i]"
	var/datum/context_menu/menu = user.open_context_menu(next_turf, "right=1;shift=1")
	TEST_ASSERT_EQUAL(menu.page_count(), 2, "Список клетки должен занять две страницы")
	var/datum/context_menu_entry/more
	for(var/atom/movable/screen/context_menu/row in menu.screen_objects)
		if(istype(row.entry, /datum/context_menu_entry/page))
			more = row.entry
	TEST_ASSERT_NOTNULL(more, "На экране нет пункта «Ещё…»")
	menu.choose(more)
	TEST_ASSERT_EQUAL(menu.page, 2, "«Ещё…» не перелистнул на вторую страницу")
	more = null
	for(var/atom/movable/screen/context_menu/row in menu.screen_objects)
		if(istype(row.entry, /datum/context_menu_entry/page))
			more = row.entry
	TEST_ASSERT_NOTNULL(more, "На второй странице нет пункта «Ещё…»")
	menu.choose(more)
	TEST_ASSERT_EQUAL(menu.page, 1, "«Ещё…» на последней странице не вернул к первой")
	user.close_context_menu()

/// Одинаковые объекты клетки - одна строка со счётом и своим списком; у объектов есть значки; меню уже максимума под короткие имена
/datum/unit_test/context_menu_tile_groups

/datum/unit_test/context_menu_tile_groups/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/turf/next_turf = get_step(user, EAST)
	var/list/pens = list()
	for(var/i in 1 to CONTEXT_MENU_GROUP_MIN + 1)
		pens += allocate(/obj/item/pen, next_turf)
	var/obj/item/paper/paper = allocate(/obj/item/paper, next_turf)
	var/obj/item/pen/first_pen = pens[1]
	var/group_name = "[capitalize(first_pen.name)] ([length(pens)])"

	var/datum/context_menu/menu = user.open_context_menu(next_turf, "right=1;shift=1")
	var/datum/context_menu_entry/group = find_context_entry(menu, group_name)
	TEST_ASSERT_NOTNULL(group, "Одинаковые ручки не свернулись в «[group_name]»")
	TEST_ASSERT_NOTNULL(find_context_entry(menu, capitalize(paper.name)), "Бумаги нет в списке клетки")
	TEST_ASSERT_EQUAL(length(menu.entries), 3, "В списке клетки должны быть ручки строкой, бумага и пол")
	var/icons = 0
	for(var/atom/movable/screen/context_menu_icon/icon_object in menu.screen_objects)
		icons++
	TEST_ASSERT_EQUAL(icons, 3, "У каждой строки списка клетки должен быть значок")
	TEST_ASSERT(menu.width < CONTEXT_MENU_WIDTH, "Меню с короткими именами растянуто на всю ширину")

	menu.choose(group)
	TEST_ASSERT_EQUAL(menu.header_text, group_name, "Список одинаковых без своей шапки")
	var/list/picked_pens = list()
	for(var/datum/context_menu_entry/pick/entry in menu.entries)
		var/atom/picked = entry.picked_ref?.resolve()
		if(picked)
			picked_pens += picked
	TEST_ASSERT_EQUAL(length(picked_pens), length(pens), "В списке одинаковых не все ручки")
	var/datum/context_menu_entry/pick/pick_pen
	for(var/datum/context_menu_entry/pick/entry in menu.entries)
		if(entry.picked_ref?.resolve() == first_pen)
			pick_pen = entry
	menu.choose(pick_pen)
	TEST_ASSERT_EQUAL(menu.target, first_pen, "Выбор ручки из списка одинаковых не открыл её действия")
	user.close_context_menu()

/// Вербы предмета в руке доступны из меню
/datum/unit_test/context_menu_item_verbs

/datum/unit_test/context_menu_item_verbs/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/obj/item/context_menu_test_item/item = allocate(/obj/item/context_menu_test_item)
	user.put_in_active_hand(item)
	var/datum/context_menu/menu = user.open_context_menu(item, "right=1;shift=1")
	var/datum/context_menu_entry/verb_entry = find_context_entry(menu, "Test verb")
	TEST_ASSERT_NOTNULL(verb_entry, "Нет верба предмета в руке")
	menu.choose(verb_entry)
	TEST_ASSERT(item.verb_used, "Верб из меню не сработал")

/// Подсказки скринтипа превращаются в пункты с хоткеем
/datum/unit_test/context_menu_screentip_entries

/datum/unit_test/context_menu_screentip_entries/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/obj/structure/table/table = allocate(/obj/structure/table, get_step(user, EAST))
	user.a_intent = INTENT_HELP
	var/datum/context_menu/menu = user.open_context_menu(table, "right=1;shift=1")
	var/datum/context_menu_entry/click/knock = find_context_entry(menu, "Постучать")
	TEST_ASSERT_NOTNULL(knock, "Нет пункта из скринтипа стола")
	TEST_ASSERT_EQUAL(knock.hint, "Shift-ПКМ", "Неверный хоткей у пункта скринтипа")
	TEST_ASSERT(findtext(knock.params, "right=1"), "Пункт скринтипа не повторяет ПКМ")
	var/datum/context_menu_entry/click/slam = find_context_entry(menu, "Грохнуть ладонью")
	TEST_ASSERT_NOTNULL(slam, "Нет пункта скринтипа для другого интента")
	TEST_ASSERT_EQUAL(slam.intent, INTENT_HARM, "Пункт другого интента не меняет интент")
	user.close_context_menu()

/// На ходу меню остаётся, а пропавший или далёкий объект закрывает его и убирает с экрана
/datum/unit_test/context_menu_close_on_move

/datum/unit_test/context_menu_close_on_move/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1;shift=1")
	var/list/screen_objects = menu.screen_objects.Copy()
	TEST_ASSERT(length(screen_objects), "Меню без экранных объектов")
	user.forceMove(get_step(user, NORTH))
	TEST_ASSERT_EQUAL(user.active_context_menu, menu, "Шаг рядом с объектом закрыл меню")
	target.moveToNullspace()
	user.forceMove(get_step(user, SOUTH))
	TEST_ASSERT_NULL(user.active_context_menu, "Шаг после пропажи объекта не закрыл меню")
	TEST_ASSERT(QDELETED(menu), "Меню не удалено")
	for(var/atom/movable/screen/object as anything in screen_objects)
		TEST_ASSERT(QDELETED(object), "Экранный объект меню пережил закрытие")

/// Толчок на ПКМ виден в скринтипе по человеку и попадает в меню
/datum/unit_test/context_menu_intent_screentips

/datum/unit_test/context_menu_intent_screentips/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	user.a_intent = INTENT_HELP
	var/list/context = list()
	var/returns = SEND_SIGNAL(target, COMSIG_ATOM_REQUESTING_CONTEXT_FROM_ITEM, context, null, user)
	TEST_ASSERT(returns & CONTEXTUAL_SCREENTIP_SET, "У человека нет скринтипа")
	var/list/rmb = context[SCREENTIP_CONTEXT_RMB]
	TEST_ASSERT_EQUAL(rmb?[INTENT_DISARM], "Толкнуть", "Толчок на ПКМ не показан вне комбат-режима")

	var/datum/context_menu/menu = user.open_context_menu(target, "right=1;shift=1")
	var/datum/context_menu_entry/click/shove = find_context_entry(menu, "Толкнуть")
	TEST_ASSERT_NOTNULL(shove, "Толчка нет в меню")
	TEST_ASSERT_EQUAL(shove.intent, INTENT_DISARM, "Толчок из меню не на интенте дизарма")
	TEST_ASSERT_EQUAL(shove.hint, "Shift-ПКМ, дизарм", "Неверная подсказка толчка")
	TEST_ASSERT(findtext(shove.params, "right=1"), "Толчок из меню не ПКМ")
	user.close_context_menu()

/// ПКМ с предметом на помощи передаёт его и больше ничего не делает (раньше тазер ещё и стрелял)
/datum/unit_test/context_menu_give_without_alt_fire

/datum/unit_test/context_menu_give_without_alt_fire/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	var/obj/item/context_menu_test_item/item = allocate(/obj/item/context_menu_test_item)
	user.put_in_active_hand(item)
	user.a_intent = INTENT_HELP
	user.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT(!item.alt_afterattacked, "Передача предмета ПКМ ещё и вызвала его альт-действие")

/datum/context_menu_storage_probe
	var/shown_to

/datum/context_menu_storage_probe/proc/on_show(datum/source, mob/show_to)
	SIGNAL_HANDLER
	shown_to = show_to

/// ПКМ пустой рукой по сумке на полу открывает её, не поднимая; подсказка видна в меню
/datum/unit_test/context_menu_secondary_storage

/datum/unit_test/context_menu_secondary_storage/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/turf/next_turf = get_step(user, EAST)
	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack, next_turf)
	var/datum/context_menu_storage_probe/probe = allocate(/datum/context_menu_storage_probe)
	probe.RegisterSignal(bag, COMSIG_TRY_STORAGE_SHOW, TYPE_PROC_REF(/datum/context_menu_storage_probe, on_show))
	user.CommonClickOn(bag, "right=1;shift=1")
	TEST_ASSERT_EQUAL(bag.loc, next_turf, "ПКМ по сумке поднял её")
	TEST_ASSERT_EQUAL(probe.shown_to, user, "ПКМ по сумке её не открыл")

	var/datum/context_menu/menu = user.open_context_menu(bag, "right=1;shift=1")
	var/datum/context_menu_entry/click/open_entry = find_context_entry(menu, "Открыть")
	TEST_ASSERT_NOTNULL(open_entry, "Нет пункта «Открыть» у сумки")
	TEST_ASSERT_EQUAL(open_entry.hint, "Shift-ПКМ", "Открытие сумки не подписано как второе действие")
	user.close_context_menu()

/// ПКМ по мензурке в руке уменьшает объём переливания, ЛКМ увеличивает
/datum/unit_test/context_menu_secondary_transfer_amount

/datum/unit_test/context_menu_secondary_transfer_amount/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/obj/item/reagent_containers/glass/beaker/beaker = allocate(/obj/item/reagent_containers/glass/beaker)
	user.put_in_active_hand(beaker)
	var/list/amounts = beaker.possible_transfer_amounts
	beaker.amount_per_transfer_from_this = amounts[2]
	user.CommonClickOn(beaker, "right=1;shift=1")
	TEST_ASSERT_EQUAL(beaker.amount_per_transfer_from_this, amounts[1], "ПКМ не уменьшил объём переливания")
	beaker.rightclick_attack_self(user)
	TEST_ASSERT_EQUAL(beaker.amount_per_transfer_from_this, amounts[length(amounts)], "Объём не перешёл с меньшего на наибольший")

/// ПКМ по надетому комбинезону меняет стиль, не снимая; по баллону в руке - внутренний воздух
/datum/unit_test/context_menu_secondary_clothing_and_tank

/datum/unit_test/context_menu_secondary_clothing_and_tank/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	TEST_ASSERT(user.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING), "Не удалось надеть комбинезон")
	var/was_adjusted = uniform.adjusted
	user.CommonClickOn(uniform, "right=1;shift=1")
	TEST_ASSERT_EQUAL(uniform.loc, user, "ПКМ снял комбинезон")
	TEST_ASSERT(uniform.adjusted != was_adjusted, "ПКМ не сменил стиль комбинезона")

	var/obj/item/clothing/mask/breath/mask = allocate(/obj/item/clothing/mask/breath)
	TEST_ASSERT(user.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK), "Не удалось надеть маску")
	var/obj/item/tank/internals/emergency_oxygen/tank = allocate(/obj/item/tank/internals/emergency_oxygen)
	user.put_in_active_hand(tank)
	user.CommonClickOn(tank, "right=1;shift=1")
	TEST_ASSERT_EQUAL(user.internal, tank, "ПКМ по баллону не включил внутренний воздух")

/// ПКМ по закрытому шлюзу стучит, а не открывает его
/datum/unit_test/context_menu_secondary_door_knock

/datum/unit_test/context_menu_secondary_door_knock/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/obj/machinery/door/airlock/public/door = allocate(/obj/machinery/door/airlock/public, get_step(user, EAST))
	TEST_ASSERT(door.density, "Шлюз в тесте должен быть закрыт")
	user.CommonClickOn(door, "right=1;shift=1")
	TEST_ASSERT(door.density && !door.operating, "ПКМ по шлюзу его открыл вместо стука")
	TEST_ASSERT_EQUAL(door.secondary_action_hint(user, null), "Постучать", "Нет подсказки стука")

/// Скринтип без картинок подписывает кнопки по-русски
/datum/unit_test/context_menu_screentip_text_keys

/datum/unit_test/context_menu_screentip_text_keys/Run()
	var/list/context = list()
	LAZYSET(context[SCREENTIP_CONTEXT_RMB], INTENT_DISARM, "Толкнуть")
	LAZYSET(context[SCREENTIP_CONTEXT_CTRL_LMB], INTENT_ANY, "Потянуть")
	var/static/regex/tags = regex(@"<[^>]*>", "g")
	TEST_ASSERT_EQUAL(replacetext(build_context(context, SCREENTIP_CONTEXT_RMB, FALSE), tags, ""), "ПКМ (дизарм): Толкнуть", "ПКМ с интентом подписан не по-русски")
	TEST_ASSERT_EQUAL(replacetext(build_context(context, SCREENTIP_CONTEXT_CTRL_LMB, FALSE), tags, ""), "Ctrl-ЛКМ: Потянуть", "Ctrl-ЛКМ подписан не по-русски")

/// ПКМ предметом в руке попадает в меню: действие предмета перебивает передачу, а альт-выстрел подписан только вне досягаемости
/datum/unit_test/context_menu_secondary_held_item

/datum/unit_test/context_menu_secondary_held_item/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/mob/living/carbon/human/near = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	var/mob/living/carbon/human/far = allocate(/mob/living/carbon/human/dummy/consistent, locate(user.x + 3, user.y, user.z))
	user.a_intent = INTENT_HELP

	var/obj/item/shield/riot/shield = allocate(/obj/item/shield/riot)
	user.put_in_active_hand(shield)
	var/datum/context_menu/menu = user.open_context_menu(near, "right=1;shift=1")
	var/datum/context_menu_entry/click/bash = find_context_entry(menu, "Удар щитом")
	TEST_ASSERT_NOTNULL(bash, "Удара щитом нет в меню")
	TEST_ASSERT_EQUAL(bash.hint, "Shift-ПКМ", "Удар щитом не подписан как второе действие")
	TEST_ASSERT_NULL(find_context_entry(menu, "Передать"), "Щит на ПКМ бьёт, а меню предлагает передать")
	user.close_context_menu()
	qdel(shield)

	var/obj/item/gun/energy/e_gun/gun = allocate(/obj/item/gun/energy/e_gun)
	user.put_in_active_hand(gun)
	menu = user.open_context_menu(far, "right=1;shift=1")
	TEST_ASSERT_NOTNULL(find_context_entry(menu, "Сменить режим"), "Смены режима энергопушки нет в меню")
	user.close_context_menu()
	menu = user.open_context_menu(near, "right=1;shift=1")
	TEST_ASSERT_NULL(find_context_entry(menu, "Сменить режим"), "Смена режима подписана вплотную, где ПКМ стреляет")
	user.close_context_menu()
	qdel(gun)

	var/obj/item/melee/sabre/sabre = allocate(/obj/item/melee/sabre)
	user.put_in_active_hand(sabre)
	var/list/context = list()
	far.collect_screentip_context(user, sabre, context)
	var/list/rmb = context[SCREENTIP_CONTEXT_RMB]
	TEST_ASSERT_EQUAL(rmb?[INTENT_ANY], "Указать клинком", "Указание клинком не подписано")

/// ПКМ по структурам без своих подписей раньше не попадал в меню: стул из-под сидящего, поворот баррикады
/datum/unit_test/context_menu_secondary_structures

/datum/unit_test/context_menu_secondary_structures/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/turf/next_turf = get_step(user, EAST)
	var/obj/structure/chair/chair = allocate(/obj/structure/chair, next_turf)
	var/mob/living/carbon/human/sitter = allocate(/mob/living/carbon/human/dummy/consistent, next_turf)
	chair.setDir(user.dir)
	TEST_ASSERT(chair.buckle_mob(sitter, TRUE), "Не удалось усадить на стул")
	user.a_intent = INTENT_HELP
	TEST_ASSERT_NULL(chair.secondary_action_hint(user, null), "На помощи стул не выдёргивают, а подпись есть")
	user.a_intent = INTENT_HARM
	TEST_ASSERT_EQUAL(chair.secondary_action_hint(user, null), "Выдернуть стул", "Нет подписи выдёргивания стула")
	chair.unbuckle_all_mobs(TRUE)
	qdel(chair)

	var/obj/structure/deployable_barricade/barricade = allocate(/obj/structure/deployable_barricade, get_step(user, NORTH))
	barricade.anchored = FALSE
	var/obj/item/pen/pen = allocate(/obj/item/pen)
	user.put_in_active_hand(pen)
	user.a_intent = INTENT_HELP
	var/datum/context_menu/menu = user.open_context_menu(barricade, "right=1;shift=1")
	var/datum/context_menu_entry/click/rotate = find_context_entry(menu, "Повернуть")
	TEST_ASSERT_NOTNULL(rotate, "Поворота баррикады нет в меню")
	var/old_dir = barricade.dir
	menu.choose(rotate)
	TEST_ASSERT(barricade.dir != old_dir, "Пункт меню не повернул баррикаду")

/// Режим ПКМ, который игрок не выбирал, берётся из конфига (без конфига - меню BYOND, как раньше); выбранный - нет
/datum/unit_test/context_menu_default_from_config
	var/old_default

/datum/unit_test/context_menu_default_from_config/Run()
	old_default = CONFIG_GET(number/right_click_mode_default)
	var/datum/config_entry/number/right_click_mode_default/entry_type = /datum/config_entry/number/right_click_mode_default
	TEST_ASSERT_EQUAL(initial(entry_type.default), RIGHT_CLICK_MODE_NATIVE, "Без конфига ПКМ должен открывать меню BYOND, как раньше")
	var/datum/preferences/prefs = new
	TEST_ASSERT_NULL(prefs.right_click_choice, "Новый игрок уже с выбранным режимом ПКМ")
	for(var/mode in list(RIGHT_CLICK_MODE_ACTION, RIGHT_CLICK_MODE_MENU, RIGHT_CLICK_MODE_NATIVE))
		CONFIG_SET(number/right_click_mode_default, mode)
		TEST_ASSERT_EQUAL(prefs.right_click_mode(), mode, "Дефолт из конфига не дошёл до невыбравшего")
	TEST_ASSERT(prefs.set_right_click_choice(RIGHT_CLICK_MODE_MENU), "Выбор режима не принят")
	CONFIG_SET(number/right_click_mode_default, RIGHT_CLICK_MODE_ACTION)
	TEST_ASSERT_EQUAL(prefs.right_click_mode(), RIGHT_CLICK_MODE_MENU, "Дефолт конфига перебил выбор игрока")
	TEST_ASSERT(!prefs.set_right_click_choice(5), "Принят несуществующий режим")
	TEST_ASSERT_EQUAL(prefs.right_click_choice, RIGHT_CLICK_MODE_MENU, "Несуществующий режим затёр выбор")
	qdel(prefs)

/datum/unit_test/context_menu_default_from_config/Destroy()
	CONFIG_SET(number/right_click_mode_default, old_default)
	return ..()

/// Выбор режима ПКМ переживает сохранение, а ключ right_click_menu, который тест-мерж писал всем подряд, не читается
/datum/unit_test/context_menu_mode_saving
	var/datum/preferences/prefs

/datum/unit_test/context_menu_mode_saving/Destroy()
	if(prefs)
		fdel(prefs.path)
		qdel(prefs)
		prefs = null
	return ..()

/datum/unit_test/context_menu_mode_saving/Run()
	prefs = new
	prefs.load_path("unit_test_right_click_mode")
	fdel(prefs.path)
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "Корень настроек не записан")
	sleep(1)
	TEST_ASSERT(prefs.load_preferences(TRUE), "Настройки не прочитаны")
	// sanitize_integer(null, ..., null) отдавал 0: всем невыбравшим доставалось «сразу действие» (10602)
	TEST_ASSERT_NULL(prefs.right_click_choice, "Невыбравший после загрузки получил режим ПКМ")
	var/savefile/old_save = new(prefs.path)
	WRITE_FILE(old_save["right_click_menu"], RIGHT_CLICK_MODE_ACTION)
	old_save = null
	sleep(1)
	TEST_ASSERT(prefs.load_preferences(TRUE), "Настройки со старым ключом не прочитаны")
	TEST_ASSERT_NULL(prefs.right_click_choice, "Старый ключ right_click_menu прочитан как выбор игрока")

	TEST_ASSERT(prefs.set_right_click_choice(RIGHT_CLICK_MODE_MENU), "Выбор режима не принят")
	prefs.flush_single_prefs()
	sleep(1)
	var/savefile/readback = new(prefs.path)
	var/written
	READ_FILE(readback["right_click_mode"], written)
	readback = null
	TEST_ASSERT_EQUAL(written, RIGHT_CLICK_MODE_MENU, "Выбор режима не записан под ключом right_click_mode")
	prefs.right_click_choice = null
	TEST_ASSERT(prefs.load_preferences(TRUE), "Настройки с выбором не прочитаны")
	TEST_ASSERT_EQUAL(prefs.right_click_choice, RIGHT_CLICK_MODE_MENU, "Выбор режима не пережил сохранение")

	TEST_ASSERT(!prefs.right_click_notice_seen, "Санити: сообщение о режимах ПКМ ещё не показывалось")
	prefs.right_click_notice_seen = TRUE
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "Настройки с показанным сообщением не записаны")
	sleep(1)
	prefs.right_click_notice_seen = FALSE
	TEST_ASSERT(prefs.load_preferences(TRUE), "Настройки с показанным сообщением не прочитаны")
	TEST_ASSERT(prefs.right_click_notice_seen, "Сообщение о режимах ПКМ покажется снова")

/// Режим «меню BYOND», как раньше: дошедший ПКМ (в бою) - действие, Shift+ПКМ - осмотр, меню действий нет
/datum/unit_test/context_menu_native_mode

/datum/unit_test/context_menu_native_mode/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_probe/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_probe)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	user.click_mode = RIGHT_CLICK_MODE_NATIVE
	TEST_ASSERT_EQUAL(user.right_click_action_hint(), "ПКМ в бою", "Вне боя второе действие в режиме BYOND доступно только в бою")
	SEND_SIGNAL(user, COMSIG_TOGGLE_COMBAT_MODE)
	TEST_ASSERT(user.right_click_needs_clicks(), "В комбат-режиме ПКМ должен приходить кликом")
	TEST_ASSERT_EQUAL(user.right_click_action_hint(), "ПКМ", "В бою второе действие - на ПКМ")
	user.CommonClickOn(target, "right=1")
	TEST_ASSERT(user.right_clicked, "ПКМ в бою в режиме BYOND не сделал действие")
	TEST_ASSERT_NULL(user.active_context_menu, "ПКМ в бою в режиме BYOND открыл меню действий")
	user.right_clicked = FALSE
	user.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT(user.shift_clicked, "Shift+ПКМ в бою в режиме BYOND не осматривает, как раньше")
	TEST_ASSERT(!user.right_clicked, "Shift+ПКМ в бою в режиме BYOND сделал второе действие")
	TEST_ASSERT_NULL(user.active_context_menu, "Shift+ПКМ в бою в режиме BYOND открыл меню действий")
	SEND_SIGNAL(user, COMSIG_TOGGLE_COMBAT_MODE)
	TEST_ASSERT(!user.right_click_needs_clicks(), "Вне боя и меха ПКМ в режиме BYOND - меню BYOND")

/// Скринтип называет ту кнопку, на которой второе действие у этого игрока
/datum/unit_test/context_menu_screentip_prefix

/datum/unit_test/context_menu_screentip_prefix/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_probe/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_probe)
	user.click_mode = RIGHT_CLICK_MODE_MENU
	TEST_ASSERT_EQUAL(user.right_click_screentip_prefix(), "Shift-", "В режиме меню второе действие не подписано Shift+ПКМ")
	TEST_ASSERT_EQUAL(user.right_click_screentip_prefix(TRUE), "", "Ctrl+ПКМ меню не открывает, приставка не нужна")
	var/list/context = list(SCREENTIP_CONTEXT_RMB = list(INTENT_ANY = "Открыть"))
	var/line = build_context(context, SCREENTIP_CONTEXT_RMB, FALSE, user.right_click_screentip_prefix())
	TEST_ASSERT_EQUAL(findtext(line, "Shift-"), 1, "Приставка не попала в начало подписи: [line]")
	user.click_mode = RIGHT_CLICK_MODE_ACTION
	TEST_ASSERT_EQUAL(user.right_click_screentip_prefix(), "", "В режиме действий второе действие на голом ПКМ")
	user.click_mode = RIGHT_CLICK_MODE_NATIVE
	TEST_ASSERT_EQUAL(user.right_click_screentip_prefix(), "В бою ", "В режиме BYOND вне боя ПКМ - меню BYOND, а не действие")
	TEST_ASSERT_EQUAL(user.right_click_screentip_prefix(TRUE), "В бою ", "В режиме BYOND вне боя Ctrl+ПКМ - меню BYOND")
	SEND_SIGNAL(user, COMSIG_TOGGLE_COMBAT_MODE)
	TEST_ASSERT_EQUAL(user.right_click_screentip_prefix(), "", "В бою в режиме BYOND второе действие на голом ПКМ")
	SEND_SIGNAL(user, COMSIG_TOGGLE_COMBAT_MODE)

/// Админ-вербы меню BYOND попадают в «Админ…» только по подходящим атомам и только выданные
/datum/unit_test/context_menu_admin_verbs

/datum/unit_test/context_menu_admin_verbs/Run()
	var/mob/living/carbon/human/mob_target = allocate(/mob/living/carbon/human/dummy/consistent)
	var/obj/item/pen/obj_target = allocate(/obj/item/pen)
	var/turf/turf_target = get_turf(mob_target)
	var/list/granted = list(/client/proc/debug_variables, /datum/admins/proc/show_player_panel, /client/proc/jumptoturf, /client/proc/object_say)
	TEST_ASSERT(context_menu_admin_verbs_for(mob_target, granted) ~= list(/datum/admins/proc/show_player_panel, /client/proc/debug_variables), "Неверные админ-вербы по мобу")
	TEST_ASSERT(context_menu_admin_verbs_for(obj_target, granted) ~= list(/client/proc/debug_variables, /client/proc/object_say), "Неверные админ-вербы по предмету")
	TEST_ASSERT(context_menu_admin_verbs_for(turf_target, granted) ~= list(/client/proc/debug_variables, /client/proc/jumptoturf), "Неверные админ-вербы по турфу")
	TEST_ASSERT(!length(context_menu_admin_verbs_for(mob_target, list())), "Админ-вербы без выданных вербов")
	// Smite меню BYOND показывало по мобу, в «Админ…» его не хватало
	TEST_ASSERT(context_menu_admin_verbs_for(mob_target, list(/client/proc/smite)) ~= list(/client/proc/smite), "Нет Smite по мобу")
	TEST_ASSERT(!length(context_menu_admin_verbs_for(obj_target, list(/client/proc/smite))), "Smite по предмету")
	TEST_ASSERT(context_menu_admin_verbs_for(obj_target, list(/client/proc/cmd_admin_delete)) ~= list(/client/proc/cmd_admin_delete), "Нет Delete по предмету")

/// Пилоту меха ПКМ - модуль меха, а не меню; после высадки, ещё внутри меха, ПКМ снова по настройке
/datum/unit_test/context_menu_mecha_pilot

/datum/unit_test/context_menu_mecha_pilot/Run()
	var/obj/vehicle/sealed/mecha/combat/gygax/mech = allocate(/obj/vehicle/sealed/mecha/combat/gygax, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/dummy/consistent/context_menu_probe/pilot = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_probe, run_loc_floor_bottom_left)
	var/obj/item/pen/target = allocate(/obj/item/pen, get_step(mech, EAST))
	pilot.forceMove(mech)
	mech.add_occupant(pilot)
	TEST_ASSERT(pilot.piloting_mecha(), "Посаженный в мех не считается пилотом")
	TEST_ASSERT(pilot.right_click_needs_clicks(), "В мехе ПКМ должен приходить кликом")
	pilot.CommonClickOn(target, "right=1")
	TEST_ASSERT_NULL(pilot.active_context_menu, "ПКМ пилота открыл меню действий вместо модуля меха")
	TEST_ASSERT(pilot.right_clicked, "ПКМ пилота не дошёл как действие")
	mech.remove_occupant(pilot)
	TEST_ASSERT_EQUAL(pilot.loc, mech, "Санити: remove_occupant не двигает моба")
	TEST_ASSERT(!pilot.piloting_mecha(), "Высаженный пилот всё ещё считается пилотом")
	TEST_ASSERT(pilot.right_click_opens_menu(list("right" = 1)), "После высадки ПКМ не вернулся к меню")
	pilot.forceMove(run_loc_floor_bottom_left)

/// Shift+ПКМ киборга в режиме меню - второе действие, а не Shift-клик (у шлюза это открыть дверь); в режиме BYOND - Shift-клик, как раньше
/datum/unit_test/context_menu_cyborg_shift_right_click
	var/old_default
	var/shift_clicked = FALSE

/datum/unit_test/context_menu_cyborg_shift_right_click/Run()
	old_default = CONFIG_GET(number/right_click_mode_default)
	CONFIG_SET(number/right_click_mode_default, RIGHT_CLICK_MODE_MENU)
	var/mob/living/silicon/robot/borg = allocate(/mob/living/silicon/robot)
	var/obj/item/pen/target = allocate(/obj/item/pen, get_step(borg, EAST))
	RegisterSignal(target, COMSIG_CLICK_SHIFT, PROC_REF(on_shift_click))
	borg.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT(!shift_clicked, "Shift+ПКМ киборга ушёл в Shift-клик")
	TEST_ASSERT_NULL(borg.active_context_menu, "Shift+ПКМ киборга в режиме меню открыл меню")
	borg.CommonClickOn(target, "left=1;shift=1")
	TEST_ASSERT(shift_clicked, "Shift+ЛКМ киборга перестал быть Shift-кликом")
	borg.CommonClickOn(target, "right=1")
	TEST_ASSERT_NOTNULL(borg.active_context_menu, "ПКМ киборга в режиме меню не открыл меню")
	borg.close_context_menu()

	CONFIG_SET(number/right_click_mode_default, RIGHT_CLICK_MODE_NATIVE)
	shift_clicked = FALSE
	borg.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT(shift_clicked, "Shift+ПКМ киборга в режиме BYOND перестал быть Shift-кликом")
	TEST_ASSERT_NULL(borg.active_context_menu, "Shift+ПКМ киборга в режиме BYOND открыл меню")

/datum/unit_test/context_menu_cyborg_shift_right_click/proc/on_shift_click(datum/source)
	SIGNAL_HANDLER
	shift_clicked = TRUE

/datum/unit_test/context_menu_cyborg_shift_right_click/Destroy()
	CONFIG_SET(number/right_click_mode_default, old_default)
	return ..()
