/// Призрак без клиента с выбранным режимом ПКМ
/mob/dead/observer/context_menu_probe
	var/click_mode = RIGHT_CLICK_MODE_MENU
	var/examined = FALSE

/mob/dead/observer/context_menu_probe/right_click_mode()
	return click_mode

/mob/dead/observer/context_menu_probe/ShiftClickOn(atom/A)
	examined = TRUE

// do_observe без клиента ничего не делает; связь с целью нужна тестам и без него
/mob/dead/observer/context_menu_probe/do_observe(mob/mob_eye)
	. = ..()
	if(!client && mob_eye != src)
		set_observetarget(mob_eye)

/// У призрака в режиме меню ПКМ открывает меню с его действиями: следовать, смотреть глазами, перейти; рук и интентов в нём нет
/datum/unit_test/context_menu_ghost_entries

/datum/unit_test/context_menu_ghost_entries/Run()
	var/mob/dead/observer/context_menu_probe/ghost = allocate(/mob/dead/observer/context_menu_probe)
	ghost.forceMove(run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(ghost, EAST))
	var/obj/item/pen/pen = allocate(/obj/item/pen, get_step(ghost, NORTH))

	ghost.CommonClickOn(target, "right=1")
	var/datum/context_menu/menu = ghost.active_context_menu
	TEST_ASSERT_NOTNULL(menu, "ПКМ призрака в режиме меню не открыл меню")
	TEST_ASSERT_EQUAL(menu.target, target, "Меню призрака открылось не на цели")
	for(var/name in list("Осмотреть", "Следовать", "Смотреть [target.ru_ego()] глазами", "Перейти сюда"))
		TEST_ASSERT_NOTNULL(find_context_entry(menu, name), "В меню призрака по мобу нет «[name]»")
	for(var/name in list("Потянуть", "Утешить", "Толкнуть", "Интенты…", "Взять"))
		TEST_ASSERT_NULL(find_context_entry(menu, name), "В меню призрака есть действие живого «[name]»")

	menu.choose(find_context_entry(menu, "Следовать"))
	TEST_ASSERT_NULL(ghost.active_context_menu, "Выбор пункта не закрыл меню")
	TEST_ASSERT_EQUAL(ghost.orbiting?.parent, target, "«Следовать» не повесил призрака на орбиту цели")
	menu = ghost.open_context_menu(target, "right=1")
	var/datum/context_menu_entry/unfollow = find_context_entry(menu, "Перестать следовать")
	TEST_ASSERT_NOTNULL(unfollow, "У следующего призрака нет «Перестать следовать»")
	menu.choose(unfollow)
	TEST_ASSERT_NULL(ghost.orbiting, "«Перестать следовать» не снял орбиту")

	menu = ghost.open_context_menu(pen, "right=1")
	TEST_ASSERT_NOTNULL(menu, "Меню призрака по ручке не открылось")
	TEST_ASSERT_NULL(find_context_entry(menu, "Взять"), "Призрак может взять ручку из меню")
	TEST_ASSERT_NOTNULL(find_context_entry(menu, "Взаимодействовать"), "У предмета нет «Взаимодействовать»")
	var/turf/pen_turf = get_turf(pen)
	menu.choose(find_context_entry(menu, "Перейти сюда"))
	TEST_ASSERT_EQUAL(get_turf(ghost), pen_turf, "«Перейти сюда» не перенёс призрака")

	TEST_ASSERT_NULL(ghost.open_context_menu(get_step(pen_turf, NORTH), "right=1"), "Голый пол открыл меню призрака")

/// Режим ПКМ у призрака: меню действий, второе действие (следовать) или меню BYOND, как у живого
/datum/unit_test/context_menu_ghost_modes

/datum/unit_test/context_menu_ghost_modes/Run()
	var/mob/dead/observer/context_menu_probe/ghost = allocate(/mob/dead/observer/context_menu_probe)
	ghost.forceMove(run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(ghost, EAST))

	TEST_ASSERT(ghost.right_click_map_clicks(FALSE), "ПКМ призрака в режиме меню не приходит кликом")
	TEST_ASSERT(!ghost.popup_menus_wanted(null), "Призраку в режиме меню включено меню BYOND")
	ghost.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT_NULL(ghost.active_context_menu, "Shift+ПКМ призрака в режиме меню открыл меню")
	TEST_ASSERT_EQUAL(ghost.orbiting?.parent, target, "Shift+ПКМ призрака в режиме меню не повёл за целью")
	ghost.orbiting.end_orbit(ghost)
	ghost.CommonClickOn(target, "left=1;shift=1")
	TEST_ASSERT(ghost.examined, "Shift+ЛКМ призрака не осматривает")

	ghost.click_mode = RIGHT_CLICK_MODE_ACTION
	ghost.CommonClickOn(target, "right=1")
	TEST_ASSERT_NULL(ghost.active_context_menu, "ПКМ призрака в режиме действий открыл меню")
	TEST_ASSERT_EQUAL(ghost.orbiting?.parent, target, "ПКМ призрака в режиме действий не повёл за целью")
	TEST_ASSERT_EQUAL(ghost.ghost_follow_hint(), "ПКМ", "Подсказка «Следовать» в режиме действий")
	ghost.orbiting.end_orbit(ghost)
	ghost.CommonClickOn(target, "right=1;shift=1")
	TEST_ASSERT_NOTNULL(ghost.active_context_menu, "Shift+ПКМ призрака в режиме действий не открыл меню")
	ghost.close_context_menu()

	ghost.click_mode = RIGHT_CLICK_MODE_NATIVE
	TEST_ASSERT(!ghost.right_click_map_clicks(FALSE), "ПКМ призрака в режиме BYOND приходит кликом")
	TEST_ASSERT(!ghost.right_click_map_clicks(TRUE), "Shift+ПКМ призрака в режиме BYOND приходит кликом")
	TEST_ASSERT(ghost.popup_menus_wanted(null), "Призраку в режиме BYOND не показывается меню BYOND")
	TEST_ASSERT_EQUAL(ghost.ghost_follow_hint(), "двойной ЛКМ", "Подсказка «Следовать» без второго действия")

/// Настройки карты считаются от моба: живой и призрак с одним режимом получают одно и то же, ИИ - меню BYOND
/datum/unit_test/context_menu_ghost_map_settings
	var/old_default

/datum/unit_test/context_menu_ghost_map_settings/Run()
	old_default = CONFIG_GET(number/right_click_mode_default)
	var/mob/dead/observer/ghost = allocate(/mob/dead/observer)
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human/dummy/consistent)
	var/mob/living/silicon/ai/ai_type = /mob/living/silicon/ai
	TEST_ASSERT(!initial(ai_type.right_click_actions), "У ИИ ПКМ должен открывать меню BYOND")
	for(var/mode in list(RIGHT_CLICK_MODE_MENU, RIGHT_CLICK_MODE_ACTION, RIGHT_CLICK_MODE_NATIVE))
		CONFIG_SET(number/right_click_mode_default, mode)
		TEST_ASSERT_EQUAL(ghost.right_click_map_clicks(FALSE), human.right_click_map_clicks(FALSE), "ПКМ карты у призрака и живого разный в режиме [mode]")
		TEST_ASSERT_EQUAL(ghost.right_click_map_clicks(TRUE), human.right_click_map_clicks(TRUE), "Shift+ПКМ карты у призрака и живого разный в режиме [mode]")
		TEST_ASSERT_EQUAL(ghost.popup_menus_wanted(null), human.popup_menus_wanted(null), "Меню BYOND у призрака и живого разное в режиме [mode]")
		TEST_ASSERT_EQUAL(json_encode(ghost.right_click_shift_macros()), json_encode(human.right_click_shift_macros()), "Макросы Shift у призрака и живого разные в режиме [mode]")

/datum/unit_test/context_menu_ghost_map_settings/Destroy()
	CONFIG_SET(number/right_click_mode_default, old_default)
	return ..()

/// Призрак, смотревший чужими глазами, сам ушёл (пункт меню, второе действие, двойной ЛКМ) - камера возвращается к нему; двойной ПКМ ничего не делает
/datum/unit_test/context_menu_ghost_move_leaves_view

/datum/unit_test/context_menu_ghost_move_leaves_view/Run()
	var/mob/dead/observer/context_menu_probe/ghost = allocate(/mob/dead/observer/context_menu_probe)
	ghost.forceMove(run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(ghost, EAST))
	var/obj/item/pen/pen = allocate(/obj/item/pen, get_step(ghost, NORTH))

	ghost.set_observetarget(target)
	var/datum/context_menu/menu = ghost.open_context_menu(pen, "right=1")
	menu.choose(find_context_entry(menu, "Перейти сюда"))
	TEST_ASSERT_NULL(ghost.observetarget, "«Перейти сюда» оставил камеру на цели наблюдения")

	ghost.set_observetarget(target)
	menu = ghost.open_context_menu(pen, "right=1")
	menu.choose(find_context_entry(menu, "Следовать"))
	TEST_ASSERT_EQUAL(ghost.orbiting?.parent, pen, "«Следовать» не повёл за ручкой")
	TEST_ASSERT_NULL(ghost.observetarget, "«Следовать» оставил камеру на цели наблюдения")
	ghost.orbiting.end_orbit(ghost)

	ghost.set_observetarget(target)
	ghost.click_mode = RIGHT_CLICK_MODE_ACTION
	ghost.CommonClickOn(get_step(target, EAST), "right=1")
	TEST_ASSERT_NULL(ghost.observetarget, "Второе действие оставило камеру на цели наблюдения")

	ghost.set_observetarget(target)
	ghost.DblClickOn(run_loc_floor_bottom_left, "left=1")
	TEST_ASSERT_EQUAL(get_turf(ghost), run_loc_floor_bottom_left, "Двойной ЛКМ по полу не перенёс призрака")
	TEST_ASSERT_NULL(ghost.observetarget, "Двойной ЛКМ оставил камеру на цели наблюдения")

	ghost.DblClickOn(target, "right=1;button=right")
	TEST_ASSERT_NULL(ghost.orbiting, "Двойной ПКМ повёл призрака за целью")

/// «Смотреть его глазами» - как из окна орбиты: призрак на орбите цели, и шаг в сторону возвращает камеру
/datum/unit_test/context_menu_ghost_observe_exits_on_step

/datum/unit_test/context_menu_ghost_observe_exits_on_step/Run()
	var/mob/dead/observer/context_menu_probe/ghost = allocate(/mob/dead/observer/context_menu_probe)
	ghost.forceMove(run_loc_floor_bottom_left)
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human/dummy/consistent, get_step(ghost, EAST))

	var/datum/context_menu/menu = ghost.open_context_menu(target, "right=1")
	menu.choose(find_context_entry(menu, "Смотреть [target.ru_ego()] глазами"))
	TEST_ASSERT_EQUAL(ghost.observetarget, target, "«Смотреть его глазами» не включил наблюдение")
	TEST_ASSERT_EQUAL(ghost.orbiting?.parent, target, "Наблюдение без орбиты: с клавиатуры из него не выйти")
	menu = ghost.open_context_menu(target, "right=1")
	TEST_ASSERT_NOTNULL(find_context_entry(menu, "Перестать смотреть [target.ru_ego()] глазами"), "Нет пункта выхода из наблюдения")
	ghost.close_context_menu()

	ghost.forceMove(get_step(target, NORTH))
	TEST_ASSERT_NULL(ghost.orbiting, "Шаг не снял орбиту")
	TEST_ASSERT_NULL(ghost.observetarget, "Шаг не вернул камеру призраку")

/// Подпись ЛКМ в меню призрака - то, что сделает ЛКМ: вселение не прячется под «Проверить здоровье»
/datum/unit_test/context_menu_ghost_click_label

/datum/unit_test/context_menu_ghost_click_label/Run()
	var/mob/dead/observer/context_menu_probe/ghost = allocate(/mob/dead/observer/context_menu_probe)
	ghost.forceMove(run_loc_floor_bottom_left)
	ghost.health_scan = TRUE
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human/dummy/consistent, get_step(ghost, EAST))
	var/mob/living/simple_animal/pet/dog/corgi/corgi = allocate(/mob/living/simple_animal/pet/dog/corgi, get_step(ghost, NORTH))
	corgi.playable_by_ghost = TRUE
	var/mob/living/carbon/true_devil/devil = allocate(/mob/living/carbon/true_devil, get_step(ghost, NORTHEAST))
	devil.ascended = TRUE
	var/obj/item/pen/pen = allocate(/obj/item/pen)

	var/list/expected = list(
		"Проверить здоровье" = human,
		"Вселиться" = corgi,
		"Стать бесом" = devil,
	)
	for(var/label in expected)
		var/datum/context_menu/menu = ghost.open_context_menu(expected[label], "right=1")
		TEST_ASSERT_NOTNULL(find_context_entry(menu, label), "У [expected[label]] нет пункта «[label]»")
		if(label != "Проверить здоровье")
			TEST_ASSERT_NULL(find_context_entry(menu, "Проверить здоровье"), "ЛКМ по [expected[label]] не проверяет здоровье, а меню так пишет")
		ghost.close_context_menu()
	TEST_ASSERT_EQUAL(pen.ghost_click_label(ghost), "Взаимодействовать", "Подпись ЛКМ по предмету")
	corgi.playable_by_ghost = FALSE
	TEST_ASSERT_EQUAL(corgi.ghost_click_label(ghost), "Проверить здоровье", "Занятый зверь всё ещё зовёт вселиться")
	ghost.health_scan = FALSE
	TEST_ASSERT_NULL(human.ghost_click_label(ghost), "Без скана здоровья ЛКМ по человеку подписан")

/// ПКМ призрака по себе, как по голому полу, меню не открывает
/datum/unit_test/context_menu_ghost_self_no_menu

/datum/unit_test/context_menu_ghost_self_no_menu/Run()
	var/mob/dead/observer/context_menu_probe/ghost = allocate(/mob/dead/observer/context_menu_probe)
	ghost.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT_NULL(ghost.open_context_menu(ghost, "right=1"), "ПКМ призрака по себе открыл меню")

/// Точный режим панели спавна забирает только ЛКМ: ПКМ админа открывает меню, а не спавнит и не копирует
/datum/unit_test/context_menu_spawnpanel_right_click

/datum/unit_test/context_menu_spawnpanel_right_click/Run()
	var/mob/dead/observer/context_menu_probe/ghost = allocate(/mob/dead/observer/context_menu_probe)
	ghost.forceMove(run_loc_floor_bottom_left)
	var/obj/item/pen/pen = allocate(/obj/item/pen, get_step(ghost, NORTH))
	var/datum/spawnpanel/panel = new(ghost)
	panel.selected_atom = "[/obj/item/pen/fountain]"
	panel.precise_mode = PRECISE_MODE_COPY
	ghost.click_intercept = panel

	ghost.CommonClickOn(pen, "right=1")
	TEST_ASSERT_NOTNULL(ghost.active_context_menu, "ПКМ в точном режиме панели спавна не открыл меню")
	TEST_ASSERT_EQUAL(panel.selected_atom, "[/obj/item/pen/fountain]", "ПКМ в точном режиме скопировал тип")
	ghost.close_context_menu()
	TEST_ASSERT(ghost.check_click_intercept("left=1", pen), "ЛКМ в точном режиме больше не перехватывается")
	TEST_ASSERT(ghost.check_click_intercept("left=1;right=1;button=left;drag=right", pen), "ЛКМ при зажатом ПКМ не перехватывается")

	ghost.click_intercept = null
	qdel(panel)

/// Меню призрака в статистике - отдельно от меню живых
/datum/unit_test/context_menu_ghost_stats

/datum/unit_test/context_menu_ghost_stats/Run()
	var/datum/context_menu_stats/stats = new
	var/datum/preferences/prefs = new
	var/list/record = stats.record_for("ghost_stats", prefs, 1)
	stats.record_open_in(record, list(), "mob")
	var/list/ghost_record = stats.ghost_counters(record)
	stats.record_open_in(ghost_record, list(), "item")
	stats.record_abandon_in(ghost_record, "click", "item", 2, FALSE)
	var/list/snapshot = json_decode(json_encode(stats.snapshot()))
	var/list/summary = snapshot["summary"]
	TEST_ASSERT_EQUAL(summary["open_kinds"]["mob"], 1, "Открытие живого не посчитано")
	TEST_ASSERT_NULL(summary["open_kinds"]["item"], "Открытие призрака смешано с живыми")
	TEST_ASSERT_EQUAL(summary["ghost"]["opens"], 1, "Открытие призрака не посчитано")
	TEST_ASSERT_EQUAL(summary["ghost"]["abandoned"], 1, "Брошенное меню призрака не посчитано")
	TEST_ASSERT_EQUAL(summary["ghost"]["abandon_kinds"]["item"], 1, "Вид брошенного меню призрака не посчитан")
	qdel(stats)
	qdel(prefs)
