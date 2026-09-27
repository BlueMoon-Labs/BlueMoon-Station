/atom/movable/screen/map_view/examine_panel_screen/profile_test
	var/character_rebuilds = 0

/atom/movable/screen/map_view/examine_panel_screen/profile_test/add_overlay(list/add_overlays)
	character_rebuilds++
	return ..()

/// Карточка переиспользует форматирование, но проверяет маску и одежду для каждого зрителя.
/datum/unit_test/character_profile_text_cache/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human/dummy/consistent)
	var/mob/viewer = allocate(/mob)
	var/mob/dead/observer/observer = allocate(/mob/dead/observer)
	var/datum/description_profile/profile = allocate(/datum/description_profile, subject)
	subject.dna.flavor_text = "**Описание**\n<текст>"
	subject.dna.custom_species_lore = "*История*"
	subject.dna.naked_flavor_text = "Описание тела"
	subject.dna.headshot_links = list("https://example.invalid/portrait.png")
	subject.dna.headshot_naked_links = list("https://example.invalid/body.png")
	var/list/first_data = profile.ui_data(viewer)
	TEST_ASSERT_EQUAL(first_data["flavortext"], format_flavor_for_tgui(subject.dna.flavor_text), "Первое форматирование изменило текст")
	TEST_ASSERT_EQUAL(first_data["flavortext_naked"], format_flavor_for_tgui(subject.dna.naked_flavor_text), "Открытое тело не получило описание")
	var/list/first_entry = profile.formatted_text_cache["flavortext"]
	var/list/repeated_data = profile.ui_data(viewer)
	TEST_ASSERT_EQUAL(repeated_data["flavortext"], first_data["flavortext"], "Повторное чтение изменило текст")
	TEST_ASSERT_EQUAL(profile.formatted_text_cache["flavortext"], first_entry, "Неизменный текст заново отформатирован")

	var/obj/item/clothing/mask/gas/mask = allocate(/obj/item/clothing/mask/gas)
	subject.equip_to_slot_if_possible(mask, ITEM_SLOT_MASK)
	TEST_ASSERT_EQUAL(subject.wear_mask, mask, "Не удалось надеть маску")
	var/list/masked_data = profile.ui_data(viewer)
	TEST_ASSERT_EQUAL(masked_data["flavortext"], "Скрыто", "Кэш раскрыл описание через маску")
	TEST_ASSERT_EQUAL(masked_data["custom_species_lore"], "", "Кэш раскрыл историю вида через маску")
	TEST_ASSERT_EQUAL(length(masked_data["headshot_links"]), 0, "Маска не скрыла портрет")
	var/list/observer_data = profile.ui_data(observer)
	TEST_ASSERT_EQUAL(observer_data["flavortext"], first_data["flavortext"], "Маска скрыла описание от призрака")
	TEST_ASSERT_EQUAL(length(observer_data["headshot_links"]), 1, "Призрак потерял доступ к портрету")
	masked_data = profile.ui_data(viewer)
	TEST_ASSERT_EQUAL(masked_data["flavortext"], "Скрыто", "Чтение призраком раскрыло текст следующему зрителю")

	var/obj/item/clothing/under/color/grey/uniform = allocate(/obj/item/clothing/under/color/grey)
	subject.equip_to_slot_if_possible(uniform, ITEM_SLOT_ICLOTHING)
	TEST_ASSERT_EQUAL(subject.w_uniform, uniform, "Не удалось надеть форму")
	var/list/clothed_data = profile.ui_data(observer)
	TEST_ASSERT_EQUAL(clothed_data["flavortext_naked"], "", "Кэш раскрыл описание закрытого тела")
	TEST_ASSERT_EQUAL(length(clothed_data["headshot_naked_links"]), 0, "Одежда не скрыла изображение тела")
	subject.force_naked_flavor = TRUE
	clothed_data = profile.ui_data(observer)
	TEST_ASSERT_EQUAL(clothed_data["flavortext_naked"], first_data["flavortext_naked"], "Принудительное раскрытие тела не обновило карточку")

	var/cache_size = length(profile.formatted_text_cache)
	for(var/edit_index in 1 to 12)
		subject.dna.flavor_text = "**Изменение [edit_index]**"
		var/list/edited_data = profile.ui_data(observer)
		TEST_ASSERT_EQUAL(edited_data["flavortext"], format_flavor_for_tgui(subject.dna.flavor_text), "Редактирование не обновило кэш")
	TEST_ASSERT_EQUAL(length(profile.formatted_text_cache), cache_size, "Правки накапливают старые версии текста")
	subject.dna.flavor_text = ""
	var/list/cleared_data = profile.ui_data(observer)
	TEST_ASSERT_EQUAL(cleared_data["flavortext"], "", "Очистка описания вернула старый текст")
	TEST_ASSERT_NULL(profile.formatted_text_cache["flavortext"], "Кэш удерживает удалённый текст")

/// Превью обновляет прямые изменения внешности и сохраняет независимый поворот зрителей.
/datum/unit_test/character_profile_preview_cache/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human/dummy/consistent)
	var/mob/first_viewer = allocate(/mob)
	var/mob/second_viewer = allocate(/mob)
	var/datum/description_profile/profile = allocate(/datum/description_profile, subject)
	var/atom/movable/screen/map_view/examine_panel_screen/profile_test/first_screen = allocate(/atom/movable/screen/map_view/examine_panel_screen/profile_test)
	var/atom/movable/screen/map_view/examine_panel_screen/profile_test/second_screen = allocate(/atom/movable/screen/map_view/examine_panel_screen/profile_test)
	profile.viewer_screens = list()
	profile.viewer_screens[first_viewer] = first_screen
	profile.viewer_screens[second_viewer] = second_screen
	profile.update_preview()
	TEST_ASSERT_EQUAL(first_screen.character_rebuilds, 1, "Первый зритель не получил превью")
	TEST_ASSERT_EQUAL(second_screen.character_rebuilds, 1, "Второй зритель не получил превью")
	profile.update_preview()
	TEST_ASSERT_EQUAL(first_screen.character_rebuilds, 1, "Неизменное превью собрано повторно")
	first_screen.setDir(EAST)
	second_screen.setDir(WEST)
	profile.current_bg_state = "engine"
	profile.update_preview()
	TEST_ASSERT_EQUAL(first_screen.icon_state, "engine", "Кэш помешал обновлению фона")
	TEST_ASSERT_EQUAL(first_screen.character_rebuilds, 1, "Смена фона пересобрала персонажа")

	subject.color = "#aa77cc"
	subject.setDir(NORTH)
	subject.pixel_x = 7
	subject.pixel_y = -4
	subject.transform = matrix(2, 0, 0, 0, 2, 0)
	profile.update_preview(first_viewer)
	TEST_ASSERT_EQUAL(first_screen.character_rebuilds, 2, "Прямое изменение внешности не обновило первого зрителя")
	TEST_ASSERT_EQUAL(second_screen.character_rebuilds, 1, "Обновление одного зрителя затронуло другого")
	second_screen.update_character(subject)
	TEST_ASSERT_EQUAL(second_screen.character_rebuilds, 2, "Периодическое обновление не заметило изменения без сигнала")
	TEST_ASSERT_EQUAL(first_screen.dir, EAST, "Обновление сбросило поворот первого зрителя")
	TEST_ASSERT_EQUAL(second_screen.dir, WEST, "Обновление сбросило поворот второго зрителя")
	var/mutable_appearance/displayed = first_screen.overlays[1]
	var/mutable_appearance/legacy_appearance = new(subject)
	legacy_appearance.setDir(SOUTH)
	legacy_appearance.transform = matrix()
	legacy_appearance.pixel_x = 0
	legacy_appearance.pixel_y = 0
	var/image/legacy_screen = image(null)
	legacy_screen.overlays += legacy_appearance
	TEST_ASSERT_EQUAL(displayed, legacy_screen.overlays[1], "Кэш изменил итоговый appearance относительно прежней сборки")
	TEST_ASSERT_EQUAL(displayed.color, subject.color, "Изменённый цвет не попал в превью")
	TEST_ASSERT_EQUAL(displayed.pixel_x, 0, "Превью наследует смещение по X")
	TEST_ASSERT_EQUAL(displayed.pixel_y, 0, "Превью наследует смещение по Y")
	TEST_ASSERT_EQUAL(displayed.transform.a, 1, "Превью наследует масштаб владельца")

	subject.add_overlay(mutable_appearance('icons/effects/effects.dmi', "nothing"))
	profile.update_preview()
	TEST_ASSERT_EQUAL(first_screen.character_rebuilds, 3, "Изменение overlays не обновило превью")
	TEST_ASSERT_EQUAL(second_screen.character_rebuilds, 3, "Изменение overlays не дошло до второго зрителя")
	profile.ui_close(first_viewer)
	TEST_ASSERT_NULL(profile.viewer_screens[first_viewer], "Закрытый экран остался в карточке")
	var/atom/movable/screen/map_view/examine_panel_screen/profile_test/reopened_screen = allocate(/atom/movable/screen/map_view/examine_panel_screen/profile_test)
	profile.viewer_screens[first_viewer] = reopened_screen
	profile.update_preview(first_viewer)
	TEST_ASSERT_EQUAL(reopened_screen.character_rebuilds, 1, "Повторное открытие не собрало изображение")

/// Быстрая проверка турфа сохраняет доступ на одном турфе, в контейнере и в nullspace.
/datum/unit_test/character_profile_visibility/Run()
	var/mob/subject = allocate(/mob)
	var/mob/viewer = allocate(/mob)
	var/datum/description_profile/profile = allocate(/datum/description_profile, subject)
	subject.invisibility = INVISIBILITY_ABSTRACT
	TEST_ASSERT_EQUAL(profile.ui_status(viewer, GLOB.always_state), UI_INTERACTIVE, "Невидимый владелец на том же турфе потерял доступ")
	var/obj/item/storage/box/container = allocate(/obj/item/storage/box)
	subject.forceMove(container)
	TEST_ASSERT_EQUAL(profile.ui_status(viewer, GLOB.always_state), UI_INTERACTIVE, "Контейнер на том же турфе изменил доступ")
	subject.forceMove(get_step(run_loc_floor_bottom_left, EAST))
	TEST_ASSERT_EQUAL(profile.ui_status(viewer, GLOB.always_state), UI_UPDATE, "Невидимый владелец на другом турфе дал управление")
	subject.moveToNullspace()
	TEST_ASSERT_NULL(subject.loc, "Владелец не перемещён в nullspace")
	TEST_ASSERT_EQUAL(profile.ui_status(viewer, GLOB.always_state), UI_UPDATE, "Владелец в nullspace дал управление зрителю на карте")
	viewer.moveToNullspace()
	TEST_ASSERT_NULL(viewer.loc, "Зритель не перемещён в nullspace")
	TEST_ASSERT_EQUAL(profile.ui_status(viewer, GLOB.always_state), UI_INTERACTIVE, "Проверка изменила прежнее поведение двух мобов в nullspace")
