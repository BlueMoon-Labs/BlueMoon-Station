/// Призрак без клиента с выбранным режимом ПКМ
/mob/dead/observer/context_menu_probe
	var/click_mode = RIGHT_CLICK_MODE_MENU
	var/examined = FALSE

/mob/dead/observer/context_menu_probe/right_click_mode()
	return click_mode

/mob/dead/observer/context_menu_probe/ShiftClickOn(atom/A)
	examined = TRUE

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
	for(var/name in list("Осмотреть", "Следовать", "Смотреть его глазами", "Перейти сюда"))
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
