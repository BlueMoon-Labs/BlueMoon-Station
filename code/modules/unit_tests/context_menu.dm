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
	/// null - Shift+ПКМ по умолчанию для click_mode
	var/shift_click_mode

/mob/living/carbon/human/dummy/consistent/context_menu_probe/right_click_mode()
	return click_mode

/mob/living/carbon/human/dummy/consistent/context_menu_probe/shift_right_click_mode()
	return isnull(shift_click_mode) ? ..() : shift_click_mode

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
	var/mob/living/carbon/human/dummy/consistent/context_menu_styled/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_styled)
	user.style_prefs = new
	user.style_prefs.context_menu_style = list("hints" = "hover", "renderer" = "map")
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	user.a_intent = INTENT_HELP
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1;shift=1")
	var/atom/movable/screen/context_menu/examine_row
	var/widest_name = 0
	for(var/atom/movable/screen/context_menu/row in menu.screen_objects)
		if(!row.entry || row.entry == menu.header_entry)
			continue
		widest_name = max(widest_name, menu.text_width(row.entry.name))
		if(row.entry.name == "Осмотреть")
			examine_row = row
	TEST_ASSERT_NOTNULL(examine_row, "Нет строки «Осмотреть»")
	for(var/atom/movable/screen/context_menu_text/label in menu.screen_objects)
		TEST_ASSERT(!findtext(label.maptext, "Shift-ЛКМ"), "Хоткей нарисован в строке и растягивает меню")
	TEST_ASSERT(menu.width <= round(max(widest_name, menu.text_width(menu.header_text || capitalize(target.name), TRUE) + 8 + menu.text_width("режим")) + 8), "Меню шире самого длинного имени")

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

/// ПКМ по клетке, которую игрок не видит (за стеной, в темноте, вне обзора), приходит турфом через click_catcher: меню её не раскрывает
/datum/unit_test/context_menu_unseen_tile

/datum/unit_test/context_menu_unseen_tile/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/turf/hidden_turf = get_step(user, EAST)
	allocate(/obj/item/pen, hidden_turf)
	allocate(/mob/living/carbon/human/dummy/consistent, hidden_turf)
	user.CommonClickOn(hidden_turf, "right=1;button=right;catcher=1")
	TEST_ASSERT_NULL(user.active_context_menu, "ПКМ по невидимой клетке раскрыл её содержимое")
	TEST_ASSERT_NULL(user.open_context_menu(hidden_turf, "right=1;catcher=1"), "Меню открылось по клику мимо обзора")
	user.CommonClickOn(hidden_turf, "right=1;button=right")
	TEST_ASSERT_NOTNULL(user.active_context_menu, "ПКМ по видимой клетке не открыл меню")
	user.close_context_menu()

/// Имена с \improper и \proper в меню без служебных символов и с целой первой буквой («•ignal Ace DELUXE cartridge», 25.10)
/datum/unit_test/context_menu_improper_names

/datum/unit_test/context_menu_improper_names/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/turf/next_turf = get_step(user, EAST)
	var/obj/item/pen/improper_pen = allocate(/obj/item/pen, next_turf)
	improper_pen.name = "\improper Signal Ace DELUXE cartridge"
	var/obj/item/pen/proper_pen = allocate(/obj/item/pen, next_turf)
	proper_pen.name = "\proper the research director's headset"
	var/datum/context_menu/menu = user.open_context_menu(next_turf, "right=1")
	TEST_ASSERT_NOTNULL(find_context_entry(menu, "Signal Ace DELUXE cartridge"), "Имя с \\improper в списке клетки испорчено")
	TEST_ASSERT_NOTNULL(find_context_entry(menu, "The research director's headset"), "Имя с \\proper в списке клетки испорчено")
	menu = user.open_context_menu(improper_pen, "right=1")
	TEST_ASSERT_EQUAL(menu.header_entry?.name, "Signal Ace DELUXE cartridge", "Шапка меню с \\improper испорчена")
	user.close_context_menu()

/// Длинный список листается пунктом «Ещё…» по кругу, и на экране именно он
/datum/unit_test/context_menu_paging

/datum/unit_test/context_menu_paging/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/turf/next_turf = get_step(user, EAST)
	// разные имена, иначе одинаковые ручки свернутся в одну строку
	for(var/i in 1 to CONTEXT_MENU_MAX_LIST_ROWS + 2)
		var/obj/item/pen/pen = allocate(/obj/item/pen, next_turf)
		pen.name = "pen [i]"
	var/datum/context_menu/menu = user.open_context_menu(next_turf, "right=1;shift=1")
	TEST_ASSERT_EQUAL(menu.page_count(), 2, "Список клетки должен занять две страницы")
	TEST_ASSERT_EQUAL(length(menu.visible_entries()), CONTEXT_MENU_MAX_LIST_ROWS, "Страница списка клетки короче CONTEXT_MENU_MAX_LIST_ROWS")
	menu.scroll(-1)
	TEST_ASSERT_EQUAL(menu.page, 2, "Колесо вниз не перелистнуло вперёд")
	menu.scroll(1)
	TEST_ASSERT_EQUAL(menu.page, 1, "Колесо вверх не перелистнуло назад")
	menu.scroll(1)
	TEST_ASSERT_EQUAL(menu.page, 2, "Колесо вверх с первой страницы не ушло на последнюю")
	menu.scroll(-1)
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

/// Предмет в большой куче открывает сразу список клетки, сам первым; Ctrl по строке тянет вещь, Shift осматривает и не закрывает список
/datum/unit_test/context_menu_pile

/datum/unit_test/context_menu_pile/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_probe/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_probe)
	var/turf/next_turf = get_step(user, EAST)
	var/list/pens = list()
	for(var/i in 1 to CONTEXT_MENU_PILE_MIN - 1)
		var/obj/item/pen/pen = allocate(/obj/item/pen, next_turf)
		pen.name = "pen [i]"
		pens += pen
	var/obj/item/pen/clicked_pen = pens[1]
	var/datum/context_menu/menu = user.open_context_menu(clicked_pen, "right=1")
	TEST_ASSERT_EQUAL(menu.target, clicked_pen, "Маленькая куча должна открываться по предмету под курсором")

	var/obj/item/pen/extra = allocate(/obj/item/pen, next_turf)
	extra.name = "pen extra"
	menu = user.open_context_menu(clicked_pen, "right=1")
	TEST_ASSERT_NULL(menu.target, "Предмет в большой куче не открыл список клетки")
	var/datum/context_menu_entry/pick/first_row = menu.entries[1]
	TEST_ASSERT_EQUAL(first_row.picked_ref?.resolve(), clicked_pen, "Вещь под курсором не первая в списке кучи")
	TEST_ASSERT(findtext(first_row.hint, "Ctrl"), "У строки вещи нет подсказки про Ctrl")

	TEST_ASSERT(menu.click_picked(first_row, list("shift" = "1", "left" = "1")), "Shift по строке не сработал")
	TEST_ASSERT(user.shift_clicked, "Shift по строке не осмотрел вещь")
	TEST_ASSERT_EQUAL(user.active_context_menu, menu, "Осмотр из списка закрыл меню")

	TEST_ASSERT(!menu.click_picked(first_row, list("left" = "1")), "Голый клик по строке ушёл в клик по вещи, а не в её действия")
	TEST_ASSERT(menu.click_picked(first_row, list("ctrl" = "1", "left" = "1")), "Ctrl по строке не сработал")
	TEST_ASSERT_EQUAL(user.pulling, clicked_pen, "Ctrl по строке не потянул вещь")
	TEST_ASSERT_NULL(user.active_context_menu, "Меню осталось после Ctrl-клика по строке")
	user.stop_pulling()

/// Одинаковые объекты клетки - одна строка со счётом и своим списком; у объектов есть значки; меню уже максимума под короткие имена
/datum/unit_test/context_menu_tile_groups

/datum/unit_test/context_menu_tile_groups/Run()
	// хоткеи в строке законно расширяют меню, здесь проверяется ширина по именам
	var/mob/living/carbon/human/dummy/consistent/context_menu_styled/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_styled)
	user.style_prefs = new
	user.style_prefs.context_menu_style = list("hints" = "hover")
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

/// Режим ПКМ, который игрок не выбирал, берётся из конфига (без конфига - меню действий); выбранный - нет
/datum/unit_test/context_menu_default_from_config
	var/old_default

/datum/unit_test/context_menu_default_from_config/Run()
	old_default = CONFIG_GET(number/right_click_mode_default)
	var/datum/config_entry/number/right_click_mode_default/entry_type = /datum/config_entry/number/right_click_mode_default
	TEST_ASSERT_EQUAL(initial(entry_type.default), RIGHT_CLICK_MODE_MENU, "Без конфига ПКМ должен открывать меню действий")
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

/// Билд-мод без клиента: только чтобы click_intercept был билд-модом
/datum/buildmode/context_menu_stub

/datum/buildmode/context_menu_stub/New()
	return

/// В билд-моде ПКМ уходит в его кнопки и броски: меню BYOND не возвращается ни у призрака, ни в режиме BYOND, пока билд-мод включён
/datum/unit_test/context_menu_buildmode_popup

/datum/unit_test/context_menu_buildmode_popup/Run()
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer)
	var/mob/living/carbon/human/dummy/consistent/context_menu_probe/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_probe)
	user.click_mode = RIGHT_CLICK_MODE_NATIVE
	var/datum/buildmode/context_menu_stub/buildmode = new
	TEST_ASSERT(ghost.popup_menus_wanted(null), "Призраку вне билд-мода не показывается меню BYOND")
	TEST_ASSERT(!ghost.popup_menus_wanted(buildmode), "Призраку в билд-моде ПКМ открывает меню BYOND вместо кнопок билд-мода")
	TEST_ASSERT(user.popup_menus_wanted(null), "В режиме BYOND вне боя не показывается меню BYOND")
	TEST_ASSERT(!user.popup_menus_wanted(buildmode), "В режиме BYOND в билд-моде ПКМ открывает меню BYOND")

/// Shift+ПКМ настраивается отдельно: ПКМ - действие, Shift+ПКМ - меню BYOND; ПКМ - меню BYOND, Shift+ПКМ - меню действий
/datum/unit_test/context_menu_shift_mode

/datum/unit_test/context_menu_shift_mode/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_probe/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_probe)
	var/obj/item/pen/target = allocate(/obj/item/pen, get_step(user, EAST))
	// без своей настройки Shift+ПКМ - противоположное ПКМ, меню BYOND остаётся меню BYOND
	TEST_ASSERT_EQUAL(default_shift_right_click_mode(RIGHT_CLICK_MODE_MENU), RIGHT_CLICK_MODE_ACTION, "Shift+ПКМ по умолчанию в режиме меню")
	TEST_ASSERT_EQUAL(default_shift_right_click_mode(RIGHT_CLICK_MODE_ACTION), RIGHT_CLICK_MODE_MENU, "Shift+ПКМ по умолчанию в режиме действий")
	TEST_ASSERT_EQUAL(default_shift_right_click_mode(RIGHT_CLICK_MODE_NATIVE), RIGHT_CLICK_MODE_NATIVE, "Shift+ПКМ по умолчанию в режиме BYOND")

	user.click_mode = RIGHT_CLICK_MODE_ACTION
	user.shift_click_mode = RIGHT_CLICK_MODE_NATIVE
	TEST_ASSERT(user.popup_menus_wanted(null), "Меню BYOND на Shift+ПКМ выключено")
	TEST_ASSERT(user.right_click_map_clicks(FALSE), "ПКМ-действие не приходит кликом")
	TEST_ASSERT(!user.right_click_map_clicks(TRUE), "Shift+ПКМ при меню BYOND приходит кликом")
	var/list/macros = user.right_click_shift_macros()
	TEST_ASSERT_EQUAL(macros?["Shift"], "\".winset :map.right-click=false\"", "Shift не включает меню BYOND на карте")
	TEST_ASSERT_EQUAL(macros?["Shift+UP"], "\".winset :map.right-click=true\"", "Отпущенный Shift не возвращает клики")
	user.CommonClickOn(target, "right=1")
	TEST_ASSERT(user.right_clicked, "ПКМ не сделал действие")
	TEST_ASSERT_NULL(user.active_context_menu, "ПКМ открыл меню действий")
	user.right_clicked = FALSE
	// клик дошёл раньше, чем сервер узнал про Shift: это не действие и не меню действий, а осмотр, как раньше
	user.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT(!user.right_clicked && !user.active_context_menu, "Shift+ПКМ при меню BYOND сделал действие или открыл меню действий")
	TEST_ASSERT(user.shift_clicked, "Дошедший Shift+ПКМ при меню BYOND не осмотрел")
	TEST_ASSERT_EQUAL(user.right_click_action_hint(), "ПКМ", "Подсказка второго действия")
	TEST_ASSERT_EQUAL(right_click_mode_name(RIGHT_CLICK_MODE_ACTION, RIGHT_CLICK_MODE_NATIVE), "ПКМ - действие, Shift+ПКМ - меню BYOND", "Название раскладки")

	user.click_mode = RIGHT_CLICK_MODE_NATIVE
	user.shift_click_mode = RIGHT_CLICK_MODE_MENU
	TEST_ASSERT(user.popup_menus_wanted(null), "При ПКМ - меню BYOND оно выключено")
	TEST_ASSERT(!user.right_click_map_clicks(FALSE), "ПКМ при меню BYOND приходит кликом")
	TEST_ASSERT(user.right_click_map_clicks(TRUE), "Shift+ПКМ при меню действий не приходит кликом")
	user.shift_click_mode = RIGHT_CLICK_MODE_NATIVE
	TEST_ASSERT_NULL(user.right_click_shift_macros(), "Макросы Shift там, где ПКМ и Shift+ПКМ одинаковы")
	user.shift_click_mode = RIGHT_CLICK_MODE_MENU
	user.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT_NOTNULL(user.active_context_menu, "Shift+ПКМ не открыл меню действий")
	user.close_context_menu()
	TEST_ASSERT_EQUAL(user.right_click_action_hint(), "ПКМ в бою", "Второе действие вне боя недоступно")
	SEND_SIGNAL(user, COMSIG_TOGGLE_COMBAT_MODE)
	TEST_ASSERT(!user.popup_menus_wanted(null), "В бою включено меню BYOND")
	user.right_clicked = FALSE
	user.CommonClickOn(target, "right=1")
	TEST_ASSERT(user.right_clicked, "ПКМ в бою не сделал действие")
	user.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT_NOTNULL(user.active_context_menu, "Shift+ПКМ в бою не открыл меню действий")
	user.close_context_menu()
	SEND_SIGNAL(user, COMSIG_TOGGLE_COMBAT_MODE)

/// Shift+ПКМ сохраняется отдельным ключом, вид меню - одним списком; мусор в сейве не проходит
/datum/unit_test/context_menu_style_saving
	var/datum/preferences/prefs

/datum/unit_test/context_menu_style_saving/Destroy()
	if(prefs)
		fdel(prefs.path)
		qdel(prefs)
		prefs = null
	return ..()

/datum/unit_test/context_menu_style_saving/Run()
	prefs = new
	prefs.load_path("unit_test_context_menu_style")
	fdel(prefs.path)
	TEST_ASSERT(prefs.save_preferences(TRUE, TRUE), "Корень настроек не записан")
	sleep(1)
	TEST_ASSERT(prefs.load_preferences(TRUE), "Настройки не прочитаны")
	TEST_ASSERT_NULL(prefs.shift_right_click_choice, "Невыбравший получил свой Shift+ПКМ")
	for(var/key in GLOB.context_menu_style_choices)
		TEST_ASSERT_EQUAL(prefs.context_menu_option(key), GLOB.context_menu_style_choices[key][1], "[key] по умолчанию не первый вариант")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("font"), "segoe", "Шрифт по умолчанию не Segoe UI")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("animation"), "none", "По умолчанию есть анимация")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("renderer"), "html", "По умолчанию меню не окном")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("opacity"), CONTEXT_MENU_OPACITY_DEFAULT, "Непрозрачность по умолчанию")

	TEST_ASSERT(prefs.set_shift_right_click_choice(RIGHT_CLICK_MODE_NATIVE), "Shift+ПКМ не принят")
	TEST_ASSERT(!prefs.set_shift_right_click_choice(7), "Принят несуществующий Shift+ПКМ")
	TEST_ASSERT(prefs.set_context_menu_style("font", "pixel"), "Шрифт не принят")
	TEST_ASSERT(prefs.set_context_menu_style("theme", "terminal"), "Тема не принята")
	TEST_ASSERT(!prefs.set_context_menu_style("theme", "comic"), "Принята несуществующая тема")
	TEST_ASSERT(prefs.set_context_menu_style("scale", "150"), "Размер не принят")
	TEST_ASSERT(!prefs.set_context_menu_style("scale", "333"), "Принят размер не из списка")
	TEST_ASSERT(prefs.set_context_menu_style("opacity", "5"), "Непрозрачность не принята")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("opacity"), CONTEXT_MENU_OPACITY_MIN, "Непрозрачность ниже минимума")
	TEST_ASSERT(prefs.set_context_menu_style("icons"), "Значки не переключились")
	TEST_ASSERT(prefs.set_context_menu_style("border", 1), "Рамка не включилась")
	TEST_ASSERT(!prefs.set_context_menu_style("nonsense", 1), "Принята несуществующая настройка")
	prefs.flush_single_prefs()
	sleep(1)
	prefs.shift_right_click_choice = null
	prefs.context_menu_style = null
	TEST_ASSERT(prefs.load_preferences(TRUE), "Настройки с видом меню не прочитаны")
	TEST_ASSERT_EQUAL(prefs.shift_right_click_choice, RIGHT_CLICK_MODE_NATIVE, "Shift+ПКМ не пережил сохранение")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("font"), "pixel", "Шрифт не пережил сохранение")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("theme"), "terminal", "Тема не пережила сохранение")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("scale"), 150, "Размер не пережил сохранение")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("opacity"), CONTEXT_MENU_OPACITY_MIN, "Непрозрачность не пережила сохранение")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("icons"), FALSE, "Значки не пережили сохранение")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("border"), TRUE, "Рамка не пережила сохранение")

	var/savefile/broken = new(prefs.path)
	WRITE_FILE(broken["context_menu_style"], list("font" = "comic sans", "scale" = 333, "theme" = "light", "junk" = 1))
	WRITE_FILE(broken["shift_right_click_mode"], 9)
	broken = null
	sleep(1)
	TEST_ASSERT(prefs.load_preferences(TRUE), "Настройки с мусором не прочитаны")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("font"), "segoe", "Мусорный шрифт прошёл")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("scale"), 100, "Мусорный размер прошёл")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("theme"), "light", "Годная тема рядом с мусором потерялась")
	TEST_ASSERT(!("junk" in prefs.context_menu_style), "Неизвестная настройка осталась в сейве")
	TEST_ASSERT_NULL(prefs.shift_right_click_choice, "Мусорный Shift+ПКМ прошёл")
	prefs.reset_context_menu_style()
	TEST_ASSERT_EQUAL(prefs.context_menu_option("theme"), "dark", "Сброс не вернул тему по умолчанию")

/// У каждой темы есть все цвета, которые рисует меню
/datum/unit_test/context_menu_themes_complete

/datum/unit_test/context_menu_themes_complete/Run()
	var/list/needed = GLOB.context_menu_themes["dark"]
	for(var/theme_id in GLOB.context_menu_style_choices["theme"])
		var/list/theme = GLOB.context_menu_themes[theme_id]
		TEST_ASSERT_NOTNULL(theme, "Темы [theme_id] нет в GLOB.context_menu_themes")
		for(var/color_key in needed)
			TEST_ASSERT(istext(theme[color_key]) && length(theme[color_key]) == 7, "У темы [theme_id] нет цвета [color_key]")
	for(var/font_id in GLOB.context_menu_map_fonts)
		if(font_id == "pixel")
			continue
		TEST_ASSERT_NOTNULL(GLOB.context_menu_font_families[font_id], "У шрифта [font_id] нет имени для css")
		TEST_ASSERT(context_menu_smooth_text_width("Осмотреть", FALSE, font_id) > 500, "У шрифта [font_id] нет таблицы ширин")

/// Игрок с настройками вида меню без клиента
/mob/living/carbon/human/dummy/consistent/context_menu_styled
	var/datum/preferences/style_prefs

/mob/living/carbon/human/dummy/consistent/context_menu_styled/right_click_mode()
	return RIGHT_CLICK_MODE_MENU

/mob/living/carbon/human/dummy/consistent/context_menu_styled/context_menu_prefs()
	return style_prefs

/mob/living/carbon/human/dummy/consistent/context_menu_styled/Destroy()
	QDEL_NULL(style_prefs)
	return ..()

/// Гладкий шрифт растеризуется в зум карты раз крупнее и сжимается обратно; пиксельный - Small Fonts; размер, плотность, тема, рамка, шапка, хоткеи и анимация - из настроек
/datum/unit_test/context_menu_style

/datum/unit_test/context_menu_style/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_styled/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_styled)
	user.style_prefs = new
	var/turf/next_turf = get_step(user, EAST)
	allocate(/obj/item/pen, next_turf)
	allocate(/obj/item/paper, next_turf)
	var/datum/context_menu/menu = user.open_context_menu(next_turf, "right=1")
	TEST_ASSERT(menu.smooth_font, "Шрифт по умолчанию не гладкий")
	var/datum/context_menu_entry/first_row = menu.visible_entries()[1]
	TEST_ASSERT_EQUAL(menu.row_height(first_row), CONTEXT_MENU_ICON_ROW_HEIGHT, "Строка со значком при 100% не той высоты")
	TEST_ASSERT_EQUAL(menu.scale, 1, "Меню по умолчанию не 100%")
	var/labels = 0
	for(var/atom/movable/screen/context_menu_text/label in menu.screen_objects)
		labels++
		TEST_ASSERT(findtext(label.maptext, "Calibri"), "Гладкая надпись не Calibri: [label.maptext]")
		var/matrix/shrink = label.transform
		TEST_ASSERT_EQUAL(shrink.a, 1 / CONTEXT_MENU_DEFAULT_ZOOM, "Гладкая надпись не сжата в зум раз")
		TEST_ASSERT(label.maptext_width > menu.width, "Коробка гладкой надписи не крупнее строки")
	TEST_ASSERT(labels, "Нет надписей")
	// анимация открытия по умолчанию - проявление: всё стартует прозрачным
	TEST_ASSERT(menu.opened, "Меню не отметило анимацию открытия")
	var/smooth_width = menu.width
	var/list/header_group = menu.row_groups[1]
	var/atom/movable/screen/context_menu/header_row = header_group[1]
	TEST_ASSERT_EQUAL(header_row.entry, menu.header_entry, "Первая группа строк не шапка")
	TEST_ASSERT_EQUAL(header_row.base_color, GLOB.context_menu_themes["dark"]["header_bg"], "Шапка не цвета темы по умолчанию")

	var/list/style = list("font" = "pixel", "scale" = 150, "opacity" = 60, "icons" = FALSE, "theme" = "terminal", "density" = "roomy", "border" = TRUE, "header" = FALSE, "hints" = "inline", "animation" = "none")
	user.style_prefs.context_menu_style = style
	menu.render()
	TEST_ASSERT(!menu.smooth_font, "Пиксельный шрифт не включился")
	TEST_ASSERT_EQUAL(menu.row_height(first_row), round((CONTEXT_MENU_ROW_HEIGHT + 4) * 1.5), "Строка при 150%, просторно и без значков не той высоты")
	TEST_ASSERT(menu.width > smooth_width, "Меню на 150% не шире")
	for(var/atom/movable/screen/context_menu_icon/icon_object in menu.screen_objects)
		TEST_FAIL("Значок нарисован при выключенных значках")
	var/frames = 0
	for(var/atom/movable/screen/context_menu/row in menu.screen_objects)
		TEST_ASSERT_EQUAL(row.alpha, round(255 * 0.6), "Непрозрачность строки не из настроек")
		TEST_ASSERT(row.entry != menu.header_entry, "Шапка нарисована при выключенной шапке")
		if(!row.entry)
			frames++
			TEST_ASSERT_EQUAL(row.base_color, GLOB.context_menu_themes["terminal"]["border"], "Рамка не цвета темы")
		else if(row.entry.style == CONTEXT_ENTRY_NORMAL)
			TEST_ASSERT_EQUAL(row.base_color, GLOB.context_menu_themes["terminal"]["row_bg"], "Строка не цвета темы")
	TEST_ASSERT_EQUAL(frames, 1, "Рамка меню не одна")
	var/inline_hints = 0
	for(var/atom/movable/screen/context_menu_text/label in menu.screen_objects)
		TEST_ASSERT(findtext(label.maptext, "class='maptext'"), "Пиксельная надпись не Small Fonts: [label.maptext]")
		var/matrix/grow = label.transform
		TEST_ASSERT_EQUAL(grow.a, 1.5, "Пиксельная надпись на 150% не растянута")
		if(findtext(label.maptext, "Shift - осмотреть"))
			inline_hints++
	TEST_ASSERT(inline_hints, "Хоткеи не нарисованы в строках")
	var/atom/movable/screen/context_menu/some_row
	for(var/atom/movable/screen/context_menu/row in menu.screen_objects)
		if(row.entry)
			some_row = row
	some_row.MouseEntered()
	TEST_ASSERT(!length(menu.hint_objects), "Плашка хоткея при хоткеях в строках")
	user.close_context_menu()

	// animate() сразу пишет в переменные конечное значение: после любой анимации строки на месте и видны
	for(var/animation in GLOB.context_menu_style_choices["animation"])
		user.style_prefs.context_menu_style = list("animation" = animation)
		menu = user.open_context_menu(next_turf, "right=1")
		var/list/last_group = menu.row_groups[length(menu.row_groups)]
		var/atom/movable/screen/context_menu/last_row = last_group[1]
		TEST_ASSERT_EQUAL(last_row.alpha, menu.row_alpha, "После анимации [animation] строка не той прозрачности")
		TEST_ASSERT(!last_row.pixel_x && !last_row.pixel_y, "После анимации [animation] строка не на месте")
		user.close_context_menu()

	// слева и по центру от курсора
	user.style_prefs.context_menu_style = list("position" = "left", "animation" = "none")
	menu = user.open_context_menu(next_turf, "right=1;screen-loc=10:16,8:16")
	TEST_ASSERT(menu.left + menu.width <= menu.origin_x, "Меню слева заходит за курсор")
	user.close_context_menu()
	user.style_prefs.context_menu_style = list("position" = "center", "animation" = "none")
	menu = user.open_context_menu(next_turf, "right=1;screen-loc=10:16,8:16")
	TEST_ASSERT(abs(menu.left + menu.width / 2 - menu.origin_x) <= 1, "Меню по центру не над курсором")
	user.close_context_menu()

/// «Админ…» на каждой странице: длинное меню не уносит его на вторую
/datum/unit_test/context_menu_admin_pinned

/datum/unit_test/context_menu_admin_pinned/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_user)
	var/obj/item/pen/target = allocate(/obj/item/pen, get_step(user, EAST))
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1")
	var/datum/context_menu_entry/admin_list/admin_entry = new("Админ…", null, CONTEXT_ENTRY_ADMIN)
	menu.entries = list()
	for(var/i in 1 to CONTEXT_MENU_MAX_ROWS * 2)
		menu.entries += new /datum/context_menu_entry("Пункт [i]")
	menu.entries += admin_entry
	TEST_ASSERT(menu.page_count() > 1, "Санити: пунктов на одну страницу")
	var/list/seen = list()
	for(var/page in 1 to menu.page_count())
		menu.page = page
		var/list/rows = menu.visible_entries()
		TEST_ASSERT(admin_entry in rows, "На странице [page] нет «Админ…»")
		TEST_ASSERT(length(rows) <= CONTEXT_MENU_MAX_ROWS, "Страница [page] длиннее [CONTEXT_MENU_MAX_ROWS]: [length(rows)]")
		for(var/datum/context_menu_entry/entry as anything in rows)
			if(entry != admin_entry && entry != menu.page_entry)
				seen |= entry
	TEST_ASSERT_EQUAL(length(seen), CONTEXT_MENU_MAX_ROWS * 2, "Пункты потерялись между страницами")
	user.close_context_menu()

/// Наборы вида: в каждом только существующие настройки с допустимыми значениями, набор применяется целиком и узнаётся обратно
/datum/unit_test/context_menu_presets

/datum/unit_test/context_menu_presets/Run()
	var/datum/preferences/prefs = new
	TEST_ASSERT_EQUAL(prefs.current_context_menu_preset(), "default", "Вид по умолчанию не узнан как «Стандарт»")
	var/list/seen_styles = list()
	for(var/preset_id in GLOB.context_menu_style_presets)
		var/list/preset = GLOB.context_menu_style_presets[preset_id]
		TEST_ASSERT(istext(preset["name"]) && istext(preset["desc"]), "У набора [preset_id] нет имени или описания")
		var/list/style = preset["style"]
		TEST_ASSERT_EQUAL(length(sanitize_context_menu_style(style)), length(style), "В наборе [preset_id] есть недопустимые настройки")
		var/style_key = json_encode(style)
		TEST_ASSERT(!seen_styles[style_key], "Набор [preset_id] повторяет [seen_styles[style_key]]")
		seen_styles[style_key] = preset_id
		TEST_ASSERT(prefs.apply_context_menu_preset(preset_id), "Набор [preset_id] не применился")
		TEST_ASSERT_EQUAL(prefs.current_context_menu_preset(), preset_id, "Применённый набор [preset_id] не узнан")
		for(var/key in style)
			TEST_ASSERT_EQUAL(prefs.context_menu_option(key), style[key], "Набор [preset_id] не выставил [key]")
	TEST_ASSERT(length(GLOB.context_menu_style_presets) >= 8, "Наборов меньше восьми")
	TEST_ASSERT(!prefs.apply_context_menu_preset("nonexistent"), "Применился несуществующий набор")
	prefs.set_context_menu_style("theme", "light")
	prefs.set_context_menu_style("font", "pixel")
	TEST_ASSERT_NULL(prefs.current_context_menu_preset(), "Свой вид узнан как набор")
	TEST_ASSERT(prefs.set_context_menu_style("accent", "#AbCdEf"), "Свой цвет акцента не принят")
	TEST_ASSERT_EQUAL(prefs.context_menu_option("accent"), "#abcdef", "Цвет акцента не приведён к нижнему регистру")
	TEST_ASSERT(!prefs.set_context_menu_style("accent", "red;color:x"), "Принят цвет акцента не в #rrggbb")
	TEST_ASSERT(prefs.set_context_menu_style("accent", ""), "Цвет акцента не сбрасывается к теме")
	qdel(prefs)

/// Полоска акцента у основного действия, тень, щели между строками, заглавные, обводка и число пунктов на странице
/datum/unit_test/context_menu_style_extras

/datum/unit_test/context_menu_style_extras/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_styled/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_styled)
	user.style_prefs = new
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	user.a_intent = INTENT_HELP
	user.style_prefs.context_menu_style = list("animation" = "none", "stripe" = TRUE, "shadow" = TRUE, "separators" = TRUE, "caps" = TRUE, "outline" = TRUE, "page_rows" = 8, "accent" = "#123456")
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1")
	TEST_ASSERT_EQUAL(menu.rows_per_page(), 8, "Пунктов на странице не из настроек")
	TEST_ASSERT(length(menu.visible_entries()) <= 8, "Страница длиннее восьми пунктов")
	var/stripes = 0
	var/shadows = 0
	var/list/row_bottoms = list()
	for(var/atom/movable/screen/context_menu/row in menu.screen_objects)
		if(row.entry)
			row_bottoms += row.row_y
			continue
		if(row.base_color == "#123456")
			stripes++
		else if(row.base_color == "#000000")
			shadows++
	TEST_ASSERT(stripes >= 1, "Нет полоски своего цвета у основного действия")
	TEST_ASSERT_EQUAL(shadows, 1, "Тень меню не одна")
	// между соседними строками щель в пиксель
	var/list/atom/movable/screen/context_menu/rows = list()
	for(var/atom/movable/screen/context_menu/row in menu.screen_objects)
		if(row.entry)
			rows += row
	for(var/i in 1 to length(rows) - 1)
		var/atom/movable/screen/context_menu/upper = rows[i]
		var/atom/movable/screen/context_menu/lower = rows[i + 1]
		TEST_ASSERT_EQUAL(upper.row_y - (lower.row_y + menu.row_height(lower.entry)), 1, "Между строками [upper.entry.name] и [lower.entry.name] нет щели")
	var/caps_found = FALSE
	for(var/atom/movable/screen/context_menu_text/label in menu.screen_objects)
		if(findtext(label.maptext, "ОСМОТРЕТЬ"))
			caps_found = TRUE
		TEST_ASSERT(findtext(label.maptext, "-dm-text-outline"), "Гладкий текст без обводки: [label.maptext]")
	TEST_ASSERT(caps_found, "Пункты не заглавными")
	TEST_ASSERT_EQUAL(menu.text_width("Осмотреть"), menu.text_width("ОСМОТРЕТЬ"), "Ширина считается не по заглавным")
	user.close_context_menu()


/// Статистика меню: сводка по игрокам считает раскладки, наборы и каждую настройку, выгрузка - читаемый JSON
/datum/unit_test/context_menu_stats

/datum/unit_test/context_menu_stats/Run()
	var/datum/context_menu_stats/stats = new
	var/datum/preferences/default_prefs = new
	var/datum/preferences/custom_prefs = new
	custom_prefs.right_click_choice = RIGHT_CLICK_MODE_ACTION
	custom_prefs.shift_right_click_choice = RIGHT_CLICK_MODE_NATIVE
	custom_prefs.context_menu_style = list("theme" = "terminal", "font" = "pixel")
	var/list/first = stats.record_for("stats_one", default_prefs, 2)
	first["opens"] += 3
	first["choices"] += 2
	stats.record_for("stats_two", custom_prefs, 1.5)
	stats.entries["Осмотреть"] = 4
	var/list/snapshot = json_decode(json_encode(stats.snapshot()))
	var/list/summary = snapshot["summary"]
	TEST_ASSERT_EQUAL(summary["preset"]["default"], 1, "Игрок на стандартном виде не посчитан")
	TEST_ASSERT_EQUAL(summary["preset"]["custom"], 1, "Игрок со своим видом не посчитан")
	TEST_ASSERT_EQUAL(summary["right_click"]["действие"], 1, "Раскладка ПКМ не посчитана")
	TEST_ASSERT_EQUAL(summary["shift_right_click"]["меню BYOND"], 1, "Раскладка Shift+ПКМ не посчитана")
	TEST_ASSERT_EQUAL(summary["style"]["theme"]["terminal"], 1, "Тема игрока не посчитана")
	TEST_ASSERT_EQUAL(summary["style"]["theme"]["dark"], 1, "Тема по умолчанию не посчитана")
	TEST_ASSERT_EQUAL(summary["style"]["scale"]["100"], 2, "Размер по умолчанию не посчитан у обоих")
	TEST_ASSERT_EQUAL(snapshot["players"]["stats_one"]["opens"], 3, "Открытия игрока потерялись")
	TEST_ASSERT_EQUAL(snapshot["players"]["stats_two"]["zoom"], 1.5, "Зум карты игрока не записан")
	TEST_ASSERT_EQUAL(snapshot["entries"]["Осмотреть"], 4, "Счёт пунктов потерялся")
	TEST_ASSERT(snapshot["players"]["stats_two"]["right_click_chosen"], "Свой выбор ПКМ не отмечен")
	TEST_ASSERT(!snapshot["players"]["stats_one"]["right_click_chosen"], "Невыбравший отмечен как выбравший")
	qdel(stats)
	qdel(default_prefs)
	qdel(custom_prefs)

/// Клик по строке браузерного меню приходит в Topic: номер строки выбирает пункт, чужой клик и мусорный номер ничего не делают
/datum/unit_test/context_menu_html_topic

/datum/unit_test/context_menu_html_topic/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_probe/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_probe)
	var/mob/living/carbon/human/stranger = allocate(/mob/living/carbon/human/dummy/consistent)
	var/obj/item/pen/target = allocate(/obj/item/pen, get_step(user, EAST))
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1")
	TEST_ASSERT(!menu.html_renderer(), "Браузерное меню без клиента")
	menu.html_rows = menu.entries.Copy()
	var/examine_index = 0
	for(var/i in 1 to length(menu.html_rows))
		var/datum/context_menu_entry/entry = menu.html_rows[i]
		if(entry.name == "Осмотреть")
			examine_index = i
	TEST_ASSERT(examine_index, "Нет строки «Осмотреть»")
	var/old_usr = usr
	usr = stranger
	menu.Topic("", list("choose" = "[examine_index]"))
	TEST_ASSERT_EQUAL(user.active_context_menu, menu, "Чужой клик выбрал пункт")
	usr = user
	menu.Topic("", list("choose" = "999"))
	TEST_ASSERT_EQUAL(user.active_context_menu, menu, "Мусорный номер строки закрыл меню")
	menu.Topic("", list("choose" = "[examine_index]"))
	usr = old_usr
	TEST_ASSERT_NULL(user.active_context_menu, "Клик по строке не выбрал пункт")
	TEST_ASSERT(menu.chosen, "Выбор из браузера посчитан брошенным меню")

/// Настройки содержимого и поведения: интенты в списке, опасные в конце и с переспросом, скрытые «Осмотреть»/«Указать», закрытие на любом шаге
/datum/unit_test/context_menu_behavior_options

/datum/unit_test/context_menu_behavior_options/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_styled/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_styled)
	user.style_prefs = new
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	user.a_intent = INTENT_HELP
	user.style_prefs.context_menu_style = list("intents" = "inline", "danger_order" = "bottom", "show_examine" = FALSE, "show_point" = FALSE, "confirm_danger" = TRUE)
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1")
	TEST_ASSERT_NULL(find_context_entry(menu, "Осмотреть"), "Скрытый «Осмотреть» в меню")
	TEST_ASSERT_NULL(find_context_entry(menu, "Указать"), "Скрытый «Указать» в меню")
	TEST_ASSERT_NULL(find_context_entry(menu, "Интенты…"), "Интенты в списке, а подменю осталось")
	var/datum/context_menu_entry/harm = find_context_entry(menu, "Ударить")
	TEST_ASSERT_NOTNULL(harm, "Интенты в списке, а удара нет")
	var/last_calm = 0
	var/first_danger = length(menu.entries) + 1
	for(var/i in 1 to length(menu.entries))
		var/datum/context_menu_entry/entry = menu.entries[i]
		if(entry.style == CONTEXT_ENTRY_DANGER)
			first_danger = min(first_danger, i)
		else if(entry.style != CONTEXT_ENTRY_SERVICE && entry.style != CONTEXT_ENTRY_ADMIN)
			last_calm = i
	TEST_ASSERT(last_calm < first_danger, "Опасные действия не в конце: спокойное [last_calm], опасное [first_danger]")

	menu.choose(harm)
	TEST_ASSERT_EQUAL(user.active_context_menu, menu, "Опасное действие выполнено с первого клика")
	TEST_ASSERT_EQUAL(menu.entry_display_name(harm), "Точно? Ударить", "Переспрос не показан")
	menu.choose(harm)
	TEST_ASSERT_NULL(user.active_context_menu, "Второй клик не выполнил опасное действие")

	user.style_prefs.context_menu_style = list("close_on_move" = "always")
	menu = user.open_context_menu(target, "right=1")
	user.forceMove(get_step(user, NORTH))
	TEST_ASSERT_NULL(user.active_context_menu, "Меню пережило шаг при «закрывать на любом шаге»")
	user.style_prefs.context_menu_style = list("close_on_move" = "never")
	menu = user.open_context_menu(target, "right=1")
	user.forceMove(get_step(user, SOUTH))
	TEST_ASSERT_EQUAL(user.active_context_menu, menu, "Меню закрылось на шаге при «не закрывать»")
	user.close_context_menu()

	// порядок без игрока: опасные перед служебными, служебные на месте
	var/datum/context_menu_entry/calm = new("Спокойное", null, CONTEXT_ENTRY_NORMAL)
	var/datum/context_menu_entry/danger = new("Опасное", null, CONTEXT_ENTRY_DANGER)
	var/datum/context_menu_entry/intent_list/intents = new("Интенты…", null, CONTEXT_ENTRY_SERVICE)
	var/list/order = list(danger, calm, intents)
	context_menu_danger_last(order)
	TEST_ASSERT(order[1] == calm && order[2] == danger && order[3] == intents, "Неверный порядок опасных действий")
