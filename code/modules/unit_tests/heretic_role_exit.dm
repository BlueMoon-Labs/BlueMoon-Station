/// 10775: еретику перепутавшему путь админ снимал роль и выдавал заново. Сброс возвращает очки и сохраняет ступень дела.
/datum/unit_test/heretic_path_reset

/datum/unit_test/heretic_path_reset/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.knowledge_points = 10
	heretic.side_knowledge_points = 0
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, user), "Путь Пепла выбирается")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/ashen_grasp, user), "Вторая ступень изучается")
	TEST_ASSERT(heretic.knowledge_points < 10, "Вторая ступень стоит очков")
	heretic.deed.tier = 1
	heretic.total_sacrifices = 1
	TEST_ASSERT(!heretic.reset_path(user), "После первой жертвы путь не меняется")
	heretic.total_sacrifices = 0
	var/selected_at = heretic.path_selected_at
	heretic.path_selected_at = world.time - HERETIC_PATH_RESET_WINDOW - 1
	TEST_ASSERT(!heretic.reset_path(user), "После окна путь не меняется")
	heretic.path_selected_at = selected_at
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	TEST_ASSERT(user.put_in_hands(book), "Кодекс в руке")
	var/datum/tgui/heretic_book_test/ui = allocate(/datum/tgui/heretic_book_test, user, book, "ForbiddenLore", "Кодекс Рубцов")
	ui.status = UI_INTERACTIVE
	var/list/exit_data = book.ui_data(user)["role_exit"]
	TEST_ASSERT(exit_data["can_reset"], "Кодекс показывает кнопку смены пути")
	TEST_ASSERT(book.ui_act("reset_path", list(), ui), "В окне до первой жертвы путь меняется кнопкой кодекса")
	TEST_ASSERT_NULL(heretic.selected_path, "Путь снят")
	TEST_ASSERT_EQUAL(heretic.path_stage, 0, "Ступени пути обнулены")
	TEST_ASSERT_EQUAL(heretic.knowledge_points, 10, "Очки за ступени вернулись полностью")
	TEST_ASSERT_NULL(heretic.get_knowledge(/datum/eldritch_knowledge/base_ash), "Знания старого пути сняты")
	TEST_ASSERT_NULL(heretic.get_knowledge(/datum/eldritch_knowledge/ashen_grasp), "Знания старого пути сняты")
	TEST_ASSERT_NULL(heretic.deed, "Дело старого пути снято")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_rust, user), "Новый путь выбирается")
	TEST_ASSERT_EQUAL(heretic.selected_path, PATH_RUST, "Выбран новый путь")
	TEST_ASSERT_EQUAL(heretic.deed.tier, 1, "Новое дело начинается со ступени старого: награды не выдаются дважды")
	TEST_ASSERT(heretic.path_reset_error(), "Второй раз путь не сменить")
	TEST_ASSERT(!heretic.reset_path(user), "Второй сброс отклоняется")
	TEST_ASSERT_EQUAL(heretic.selected_path, PATH_RUST, "Отказ не трогает путь")

/// Схлопнувшаяся изнанка не закрывает сброс навсегда, клинки старого пути рассыпаются, кодекс знает, что сброс уже потрачен.
/datum/unit_test/heretic_path_reset_leftovers

/datum/unit_test/heretic_path_reset_leftovers/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	heretic.knowledge_points = 10
	TEST_ASSERT(heretic.role_exit_data()["reset_possible"], "До выбора кодекс обещает смену пути")
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, user), "Путь Пепла выбирается")
	var/datum/heretic_pocket/pocket = new(heretic)
	allocated += pocket
	heretic.pocket = pocket
	pocket.active = TRUE
	TEST_ASSERT(heretic.path_reset_error(), "Из открытой изнанки путь не меняется")
	pocket.active = FALSE
	TEST_ASSERT_NULL(heretic.path_reset_error(), "Схлопнувшаяся изнанка сброс не закрывает")
	var/datum/eldritch_knowledge/base = heretic.get_knowledge(/datum/eldritch_knowledge/base_ash)
	var/list/blades = list()
	for(var/index in 1 to HERETIC_BLADE_LIMIT)
		var/obj/item/melee/sickly_blade/ash/blade = allocate(/obj/item/melee/sickly_blade/ash)
		base.track_blade(blade, user)
		blades += blade
	TEST_ASSERT(heretic.reset_path(user), "Путь сбрасывается")
	for(var/obj/item/melee/sickly_blade/blade as anything in blades)
		TEST_ASSERT(QDELETED(blade), "Клинок старого пути рассыпался: иначе сброс даёт клинки сверх предела")
	var/list/exit_data = heretic.role_exit_data()
	TEST_ASSERT(!exit_data["reset_possible"], "После сброса кодекс не обещает смену пути")
	TEST_ASSERT(!exit_data["token_role"], "Роль не с жетона")
	heretic.pocket = null

/// Админский сброс не трогает вознёсшегося и учебного еретика: вознесение без пути блокировало бы инжекции.
/datum/unit_test/heretic_admin_path_reset_refusals

/datum/unit_test/heretic_admin_path_reset_refusals/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	var/mob/living/admin = allocate(/mob/living/carbon/human)
	heretic.knowledge_points = 10
	TEST_ASSERT(heretic.research_knowledge(/datum/eldritch_knowledge/base_ash, user), "Путь Пепла выбирается")
	heretic.ascended = TRUE
	heretic.admin_reset_path(admin)
	heretic.ascended = FALSE
	TEST_ASSERT_EQUAL(heretic.selected_path, PATH_ASH, "Вознёсшемуся админ путь не сбрасывает")
	heretic.simulated = TRUE
	heretic.admin_reset_path(admin)
	TEST_ASSERT_EQUAL(heretic.selected_path, PATH_ASH, "Учебному еретику путь меняет полигон, а не админ")
	TEST_ASSERT(!heretic.role_exit_data()["reset_possible"], "На полигоне кодекс не обещает смену пути")
	heretic.simulated = FALSE
	heretic.admin_reset_path(admin)
	TEST_ASSERT_NULL(heretic.selected_path, "Обычному еретику админ путь сбрасывает")

/// Сброс снимает базу любого пути без рантаймов и хвостов: тот же порядок, что при снятии роли.
/datum/unit_test/heretic_path_reset_all_paths

/datum/unit_test/heretic_path_reset_all_paths/Run()
	var/datum/antagonist/heretic/heretic = allocate_heretic()
	var/mob/living/user = heretic.owner.current
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		TEST_ASSERT(heretic.research_knowledge(path.knowledge[1], user), "[path_id]: путь выбирается после сброса предыдущего")
		heretic.release_path(user)
		TEST_ASSERT_NULL(heretic.selected_path, "[path_id]: путь снят")
		TEST_ASSERT_NULL(heretic.get_knowledge(path.knowledge[1]), "[path_id]: база пути снята")

/// 10677, 10722: новички просили снять роль. Отказ снимает её, игрок больше не идёт в мидраунд-конверсии.
/datum/unit_test/heretic_role_abandon

/datum/unit_test/heretic_role_abandon/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.mind_initialize()
	allocated += user.mind
	var/datum/antagonist/heretic/heretic = user.mind.add_antag_datum(/datum/antagonist/heretic)
	TEST_ASSERT_NOTNULL(heretic, "Роль выдана")
	heretic.total_sacrifices = 1
	TEST_ASSERT(!heretic.abandon_role(user), "После первой жертвы от роли не отказаться")
	heretic.total_sacrifices = 0
	heretic.role_gained_at = world.time - HERETIC_ROLE_ABANDON_WINDOW - 1
	TEST_ASSERT(!heretic.abandon_role(user), "После окна отказ только через администрацию")
	TEST_ASSERT(IS_HERETIC(user), "Отклонённый отказ не снимает роль")
	heretic.role_gained_at = world.time
	var/obj/item/forbidden_book/book = allocate(/obj/item/forbidden_book)
	TEST_ASSERT(user.put_in_hands(book), "Кодекс в руке")
	var/datum/tgui/heretic_book_test/ui = allocate(/datum/tgui/heretic_book_test, user, book, "ForbiddenLore", "Кодекс Рубцов")
	ui.status = UI_INTERACTIVE
	TEST_ASSERT(book.ui_act("abandon_role", list(), ui), "В окне до первой жертвы от роли можно отказаться кнопкой кодекса")
	TEST_ASSERT_NULL(IS_HERETIC(user), "Роль снята")
	TEST_ASSERT_NULL(user.mind.special_role, "Флаг роли снят")
	TEST_ASSERT(user.mind.declined_antag_role, "Отказ запомнен на разуме")
	var/datum/dynamic_ruleset/midround/crew_conversion/heretic/rule = allocate(/datum/dynamic_ruleset/midround/crew_conversion/heretic)
	TEST_ASSERT(!rule.can_convert(user), "Отказавшегося мидраунд-конверсия не выбирает")
