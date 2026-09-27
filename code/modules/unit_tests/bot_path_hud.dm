/datum/atom_hud/data/diagnostic/advanced/test_path_updates
	var/list/added_keys = list()
	var/list/removed_keys = list()
	var/membership_changes = 0

/datum/atom_hud/data/diagnostic/advanced/test_path_updates/add_to_hud(atom/movable/target)
	membership_changes++
	return ..()

/datum/atom_hud/data/diagnostic/advanced/test_path_updates/remove_from_hud(atom/movable/target)
	membership_changes++
	return ..()

/datum/atom_hud/data/diagnostic/advanced/test_path_updates/add_to_single_hud(mob/viewer, atom/movable/target, list/hud_icon_keys = hud_icons)
	added_keys += hud_icon_keys
	return ..()

/datum/atom_hud/data/diagnostic/advanced/test_path_updates/remove_from_single_hud(mob/viewer, atom/movable/target, list/hud_icon_keys = hud_icons)
	removed_keys += hud_icon_keys
	return ..()

/// Смена маршрута обновляет только стрелки, сохраняя подписчиков и остальные иконки бота.
/datum/unit_test/bot_path_hud_updates
	var/datum/atom_hud/previous_diagnostic_hud

/datum/unit_test/bot_path_hud_updates/Destroy()
	GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED] = previous_diagnostic_hud
	previous_diagnostic_hud = null
	return ..()

/datum/unit_test/bot_path_hud_updates/Run()
	previous_diagnostic_hud = GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED]
	var/datum/atom_hud/data/diagnostic/advanced/test_path_updates/diagnostic_hud = allocate(/datum/atom_hud/data/diagnostic/advanced/test_path_updates)
	GLOB.huds[DATA_HUD_DIAGNOSTIC_ADVANCED] = diagnostic_hud
	var/turf/start = run_loc_floor_bottom_left
	var/turf/first = get_step(start, EAST)
	var/turf/second = get_step(first, NORTH)
	var/mob/living/simple_animal/bot/cleanbot/bot = allocate(/mob/living/simple_animal/bot/cleanbot, start)
	bot.toggle_ai(AI_OFF)
	var/mob/viewer = allocate(/mob)
	diagnostic_hud.add_hud_to(viewer)
	diagnostic_hud.add_hud_to(viewer)
	var/initial_membership_changes = diagnostic_hud.membership_changes
	var/image/status_image = bot.hud_list[DIAG_STAT_HUD]
	var/image/health_image = bot.hud_list[DIAG_HUD]

	bot.set_path(null)
	bot.set_path(list())
	TEST_ASSERT_EQUAL(length(diagnostic_hud.added_keys), 0, "Пустой маршрут не должен повторно добавлять иконки")
	TEST_ASSERT_EQUAL(length(diagnostic_hud.removed_keys), 0, "Пустой маршрут не должен снимать иконки")
	TEST_ASSERT_EQUAL(diagnostic_hud.membership_changes, initial_membership_changes, "Очистка пути не должна менять регистрацию бота")

	bot.set_path(list(first, second))
	TEST_ASSERT_EQUAL(length(diagnostic_hud.added_keys), 1, "Новый маршрут должен отправляться одним набором")
	TEST_ASSERT_EQUAL(diagnostic_hud.added_keys[1], DIAG_PATH_HUD, "Обновление пути не должно отправлять статус и здоровье")
	var/list/path_images = bot.hud_list[DIAG_PATH_HUD]
	TEST_ASSERT_EQUAL(length(path_images), 2, "Оба шага маршрута должны иметь стрелки")
	var/image/first_image = path_images[1]
	TEST_ASSERT_EQUAL(first_image.loc, first, "Первая стрелка должна стоять на первом шаге")
	bot.increment_path()
	TEST_ASSERT_NULL(first_image.icon_state, "Пройденная стрелка должна скрываться")
	bot.increment_path()
	TEST_ASSERT_EQUAL(length(bot.path), 0, "Путь должен закончиться после двух шагов")

	bot.set_path(null)
	TEST_ASSERT_EQUAL(length(diagnostic_hud.removed_keys), 1, "Завершённый путь должен убрать оставшиеся изображения")
	TEST_ASSERT_EQUAL(diagnostic_hud.removed_keys[1], DIAG_PATH_HUD, "Снимать нужно только стрелки")
	TEST_ASSERT_EQUAL(length(diagnostic_hud.added_keys), 1, "Очистка не должна заново добавлять диагностический HUD")
	TEST_ASSERT_EQUAL(length(path_images), 0, "Изображения завершённого пути должны очищаться")
	TEST_ASSERT(QDELETED(first_image), "Скрытые стрелки тоже должны удаляться")

	diagnostic_hud.queued_to_see[viewer] = TRUE
	bot.set_path(list(first, second))
	TEST_ASSERT_EQUAL(length(diagnostic_hud.added_keys), 1, "Ожидающий кулдауна наблюдатель не должен получать стрелки раньше времени")
	diagnostic_hud.show_hud_images_after_cooldown(viewer)
	var/list/visible_images = list()
	diagnostic_hud.collect_hud_images_for(viewer, visible_images)
	TEST_ASSERT(status_image in visible_images, "После смены пути статус должен оставаться доступным")
	TEST_ASSERT(health_image in visible_images, "После смены пути здоровье должно оставаться доступным")
	for(var/image/path_image as anything in path_images)
		TEST_ASSERT(path_image in visible_images, "После кулдауна HUD должен содержать актуальный маршрут")
	TEST_ASSERT_EQUAL(diagnostic_hud.hudusers[viewer], 2, "Смена пути не должна менять число подписок наблюдателя")
	TEST_ASSERT_EQUAL(diagnostic_hud.membership_changes, initial_membership_changes, "Бот должен оставаться зарегистрированным при всех сменах маршрута")
	TEST_ASSERT_EQUAL(bot.hud_list[DIAG_STAT_HUD], status_image, "Изображение статуса должно сохраняться")
	TEST_ASSERT_EQUAL(bot.hud_list[DIAG_HUD], health_image, "Изображение здоровья должно сохраняться")
