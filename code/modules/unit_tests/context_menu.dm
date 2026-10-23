/mob/living/carbon/human/dummy/consistent/context_menu_probe
	var/right_clicked = FALSE
	var/shift_clicked = FALSE
	/// Интент, с которым пришёл последний обычный клик (ловится только при record_clicks)
	var/seen_intent
	var/record_clicks = FALSE
	var/menu_on_plain_click = TRUE

/mob/living/carbon/human/dummy/consistent/context_menu_probe/right_click_menu_preferred()
	return menu_on_plain_click

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

/// По умолчанию ПКМ - меню, Shift+ПКМ - действие; настройка меняет местами; в бою ПКМ - действие; Shift+ЛКМ - осмотр
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

	user.menu_on_plain_click = FALSE
	user.right_clicked = FALSE
	user.CommonClickOn(target, "right=1")
	TEST_ASSERT(user.right_clicked, "ПКМ в режиме действий не сделал действие")
	TEST_ASSERT_NULL(user.active_context_menu, "ПКМ в режиме действий открыл меню")
	user.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT_NOTNULL(user.active_context_menu, "Shift+ПКМ в режиме действий не открыл меню")
	TEST_ASSERT_EQUAL(user.right_click_action_hint(), "ПКМ", "Подсказка действия в режиме действий")
	user.close_context_menu()

	user.menu_on_plain_click = TRUE
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

/// Меню по человеку: осмотр, четыре интента, текущий помечен
/datum/unit_test/context_menu_human_entries

/datum/unit_test/context_menu_human_entries/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	user.a_intent = INTENT_HELP
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1;shift=1")
	TEST_ASSERT_NOTNULL(menu, "Меню не открылось")
	for(var/name in list("Осмотреть", "Указать", "Потянуть", "Утешить", "Обезоружить", "Схватить", "Ударить", "Толкнуть"))
		TEST_ASSERT_NOTNULL(find_context_entry(menu, name), "Нет пункта «[name]»")
	var/datum/context_menu_entry/help_entry = find_context_entry(menu, "Утешить")
	TEST_ASSERT_EQUAL(help_entry.style, CONTEXT_ENTRY_CURRENT, "Текущий интент не помечен")
	var/datum/context_menu_entry/harm_entry = find_context_entry(menu, "Ударить")
	TEST_ASSERT_EQUAL(harm_entry.style, CONTEXT_ENTRY_DANGER, "Удар не помечен как агрессивный")
	if(user.GetComponent(/datum/component/interaction_menu_granter))
		TEST_ASSERT_NOTNULL(find_context_entry(menu, "Взаимодействовать"), "Нет пункта взаимодействий")
	for(var/datum/context_menu_entry/entry as anything in menu.entries)
		TEST_ASSERT(!istype(entry, /datum/context_menu_entry/verb_call), "У моба в меню оказался верб [entry.name]")
	TEST_ASSERT(length(menu.screen_objects) > length(menu.entries), "Меню не нарисовано")
	user.close_context_menu()

/// Пункт интента делает одно действие этим интентом и возвращает прежний
/datum/unit_test/context_menu_intent_once

/datum/unit_test/context_menu_intent_once/Run()
	var/mob/living/carbon/human/dummy/consistent/context_menu_probe/user = allocate(/mob/living/carbon/human/dummy/consistent/context_menu_probe)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	user.a_intent = INTENT_HELP
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1;shift=1")
	user.record_clicks = TRUE
	menu.choose(find_context_entry(menu, "Ударить"))
	TEST_ASSERT_EQUAL(user.seen_intent, INTENT_HARM, "Клик из меню пришёл не с интентом вреда")
	TEST_ASSERT_EQUAL(user.a_intent, INTENT_HELP, "Интент игрока не вернулся")
	TEST_ASSERT_NULL(user.active_context_menu, "Меню не закрылось после выбора")
	TEST_ASSERT(QDELETED(menu), "Меню не удалено после выбора")

/// Куча на клетке: сперва выбор объекта, потом его действия; одиночный предмет можно взять
/datum/unit_test/context_menu_tile_pick

/datum/unit_test/context_menu_tile_pick/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
	var/turf/next_turf = get_step(user, EAST)
	var/obj/item/pen/pen = allocate(/obj/item/pen, next_turf)

	var/datum/context_menu/menu = user.open_context_menu(pen, "right=1;shift=1")
	TEST_ASSERT_EQUAL(menu.target, pen, "Одиночный предмет должен открываться сразу")
	TEST_ASSERT_NOTNULL(find_context_entry(menu, "Взять"), "Нет пункта «Взять»")

	var/obj/item/paper/paper = allocate(/obj/item/paper, next_turf)
	menu = user.open_context_menu(pen, "right=1;shift=1")
	TEST_ASSERT_NULL(menu.target, "В куче меню должно начинаться с выбора объекта")
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
	user.close_context_menu()

/// Вербы предмета в руке доступны из меню
/datum/unit_test/context_menu_item_verbs

/datum/unit_test/context_menu_item_verbs/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
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
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
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

/// Движение закрывает меню и убирает его с экрана
/datum/unit_test/context_menu_close_on_move

/datum/unit_test/context_menu_close_on_move/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(user, EAST))
	var/datum/context_menu/menu = user.open_context_menu(target, "right=1;shift=1")
	var/list/screen_objects = menu.screen_objects.Copy()
	TEST_ASSERT(length(screen_objects), "Меню без экранных объектов")
	user.forceMove(get_step(user, NORTH))
	TEST_ASSERT_NULL(user.active_context_menu, "Движение не закрыло меню")
	TEST_ASSERT(QDELETED(menu), "Меню не удалено")
	for(var/atom/movable/screen/object as anything in screen_objects)
		TEST_ASSERT(QDELETED(object), "Экранный объект меню пережил закрытие")

/// Толчок на ПКМ виден в скринтипе по человеку и попадает в меню
/datum/unit_test/context_menu_intent_screentips

/datum/unit_test/context_menu_intent_screentips/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
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
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
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
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
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
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
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
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
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
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
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
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
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
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/dummy/consistent)
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

/// Режим ПКМ, который игрок не выбирал, берётся из конфига; выбранный - нет
/datum/unit_test/context_menu_default_from_config
	var/old_default

/datum/unit_test/context_menu_default_from_config/Run()
	old_default = CONFIG_GET(flag/right_click_menu_default)
	var/datum/preferences/prefs = new
	TEST_ASSERT_NULL(prefs.right_click_menu, "Новый игрок уже с выбранным режимом ПКМ")
	CONFIG_SET(flag/right_click_menu_default, FALSE)
	TEST_ASSERT(!prefs.right_click_menu_enabled(), "Дефолт из конфига не дошёл до невыбравшего")
	CONFIG_SET(flag/right_click_menu_default, TRUE)
	TEST_ASSERT(prefs.right_click_menu_enabled(), "Дефолт из конфига не дошёл до невыбравшего")
	prefs.right_click_menu = FALSE
	TEST_ASSERT(!prefs.right_click_menu_enabled(), "Дефолт конфига перебил выбор игрока")
	qdel(prefs)

/datum/unit_test/context_menu_default_from_config/Destroy()
	CONFIG_SET(flag/right_click_menu_default, old_default)
	return ..()
