/// Превью профессии в меню собирается на общем манекене и совпадает с внешностью свежего, даже после чужой расы.
/datum/unit_test/job_menu_preview_pooled_dummy/Run()
	var/datum/preferences/navigation_test/human_prefs = allocate(/datum/preferences/navigation_test)
	human_prefs.pref_species = new /datum/species/human
	human_prefs.random_character(MALE)
	var/datum/preferences/navigation_test/lizard_prefs = allocate(/datum/preferences/navigation_test)
	lizard_prefs.pref_species = new /datum/species/lizard
	lizard_prefs.random_character(FEMALE)

	var/datum/job_menu/human_menu = new("prefs", human_prefs)
	var/datum/job_menu/lizard_menu = new("prefs", lizard_prefs)
	var/expected = appearance_signature(get_human_preview_appearance(SSjob.GetJob("Scientist"), human_prefs, null))

	TEST_ASSERT_NOTNULL(lizard_menu.build_preview("Scientist", null), "превью ящера не собралось")
	var/mob/living/carbon/human/dummy/pooled = GLOB.human_dummy_list[DUMMY_HUMAN_SLOT_JOB_MENU]
	TEST_ASSERT_NOTNULL(pooled, "превью профессии не берёт манекен из пула")
	var/actual = appearance_signature(human_menu.build_preview("Scientist", null))
	TEST_ASSERT_EQUAL(GLOB.human_dummy_list[DUMMY_HUMAN_SLOT_JOB_MENU], pooled, "второе превью не переиспользовало манекен")
	TEST_ASSERT(!pooled.in_use, "манекен меню профессий остался занятым")
	TEST_ASSERT_EQUAL(actual, expected, "превью на общем манекене отличается от превью на свежем")
	qdel(human_menu)
	qdel(lizard_menu)

/// Всё, что видно на превью: слои внешности по порядку. Блокер свечения невидим, его не сравниваем.
/datum/unit_test/job_menu_preview_pooled_dummy/proc/appearance_signature(mutable_appearance/shown)
	if(!shown)
		return null
	var/list/parts = list("[shown.icon]|[shown.icon_state]|[shown.dir]")
	for(var/mutable_appearance/part as anything in shown.underlays + shown.overlays)
		if(part.plane == EMISSIVE_PLANE)
			continue
		parts += "[part.icon]|[part.icon_state]|[part.color]|[part.layer]|[part.plane]|[part.pixel_x],[part.pixel_y]|[part.alpha]|[length(part.overlays)]"
	return jointext(parts, ";")

/// Превью профессии клиент рисует сам: меню кладёт внешность на свою карту окна, а широкие части её расширяют.
/datum/unit_test/job_menu_preview_on_client_map/Run()
	var/datum/preferences/navigation_test/prefs = allocate(/datum/preferences/navigation_test)
	prefs.pref_species = new /datum/species/human
	prefs.random_character(MALE)
	var/datum/job_menu/menu = new("prefs", prefs)
	menu.preview_screen = new
	menu.preview_screen.generate_view("job_menu_test_map")
	var/atom/movable/screen/map_view/job_preview/screen = menu.preview_screen

	var/list/data = menu.ui_data(null)
	TEST_ASSERT(!data["previewShown"], "превью показано без выбранной профессии")
	TEST_ASSERT_EQUAL(data["previewMap"], "job_menu_test_map", "меню не отдаёт окну свою карту")

	menu.selected = "Scientist"
	data = menu.ui_data(null)
	TEST_ASSERT(data["previewShown"], "превью выбранной профессии не показано")
	TEST_ASSERT_EQUAL(length(screen.overlays), 1, "на карте не одна внешность")
	var/mutable_appearance/first_shown = screen.shown_appearance
	TEST_ASSERT_EQUAL(first_shown.dir, SOUTH, "персонаж на превью не смотрит на юг")
	TEST_ASSERT_EQUAL(data["previewTiles"], 1, "обычная внешность не в одной клетке")
	TEST_ASSERT_EQUAL(screen.frame.screen_loc, "job_menu_test_map:1,1 to 2,2", "карта превью меньше 2x2")
	TEST_ASSERT_EQUAL(screen.screen_loc, "job_menu_test_map:1:16,1:16", "внешность не в центре карты")

	// Новый контрол карты в окне: рамка на тик сжимается до клетки, чтобы клиент пересчитал вид
	screen.refit_view()
	TEST_ASSERT_EQUAL(screen.frame.screen_loc, "job_menu_test_map:1,1 to 1,1", "карта не пересчитывается под новый контрол")
	screen.place_in_frame(2)

	menu.selected = "Assistant"
	menu.ui_data(null)
	menu.selected = "Scientist"
	menu.ui_data(null)
	TEST_ASSERT(screen.shown_appearance == first_shown, "повторный выбор профессии собрал превью заново")

	// Тавры и крылья center_image сдвигает на -16: внешность занимает две клетки, окно уменьшит зум
	var/mutable_appearance/wide = mutable_appearance('icons/mob/robots.dmi', "robot")
	wide.overlays += mutable_appearance('icons/mob/robots.dmi', "robot", pixel_x = -16)
	screen.show_preview(wide)
	TEST_ASSERT_EQUAL(screen.shown_tiles, 2, "широкая внешность не расширила превью")
	TEST_ASSERT_EQUAL(screen.screen_loc, "job_menu_test_map:1:16,1:16", "широкая внешность не в центре карты")
	wide.overlays += mutable_appearance('icons/mob/robots.dmi', "robot", pixel_x = -32)
	screen.show_preview(wide)
	TEST_ASSERT_EQUAL(screen.frame.screen_loc, "job_menu_test_map:1,1 to 3,3", "очень широкая внешность не расширила карту")
	TEST_ASSERT_EQUAL(screen.screen_loc, "job_menu_test_map:2:0,2:0", "очень широкая внешность не в центре карты")

	menu.selected = null
	data = menu.ui_data(null)
	TEST_ASSERT(!data["previewShown"], "снятый выбор оставил превью")
	TEST_ASSERT_EQUAL(length(screen.overlays), 0, "снятый выбор не очистил карту")
	qdel(menu)
	TEST_ASSERT(QDELETED(screen), "меню не удалило свою карту")

/// Окно причёсок берёт общий манекен, и база после чужой расы совпадает с первой отрисовкой.
/datum/unit_test/hair_picker_pooled_dummy/Run()
	var/datum/preferences/navigation_test/human_prefs = allocate(/datum/preferences/navigation_test)
	human_prefs.pref_species = new /datum/species/human
	human_prefs.random_character(MALE)
	var/datum/preferences/navigation_test/lizard_prefs = allocate(/datum/preferences/navigation_test)
	lizard_prefs.pref_species = new /datum/species/lizard
	lizard_prefs.random_character(FEMALE)

	var/datum/hair_style_picker/first = new
	first.owner_ckey = "unit_test_first"
	first.prefs = human_prefs
	TEST_ASSERT(first.build_all_bases(), "база причёсок не собралась")
	var/mob/living/carbon/human/dummy/pooled = GLOB.human_dummy_list[DUMMY_HUMAN_SLOT_HAIR_PICKER]
	TEST_ASSERT_NOTNULL(pooled, "окно причёсок не берёт манекен из пула")

	var/datum/hair_style_picker/lizard = new
	lizard.owner_ckey = "unit_test_lizard"
	lizard.prefs = lizard_prefs
	TEST_ASSERT(lizard.build_all_bases(), "база причёсок ящера не собралась")

	var/datum/hair_style_picker/second = new
	second.owner_ckey = "unit_test_second"
	second.prefs = human_prefs
	TEST_ASSERT(second.build_all_bases(), "повторная база причёсок не собралась")
	TEST_ASSERT_EQUAL(GLOB.human_dummy_list[DUMMY_HUMAN_SLOT_HAIR_PICKER], pooled, "окно причёсок не переиспользовало манекен")
	TEST_ASSERT(!pooled.in_use, "манекен окна причёсок остался занятым")

	var/icon/expected = first.base_cache["[SOUTH]"]
	var/icon/actual = second.base_cache["[SOUTH]"]
	TEST_ASSERT_EQUAL(actual.Width(), expected.Width(), "изменилась ширина базы")
	TEST_ASSERT_EQUAL(actual.Height(), expected.Height(), "изменилась высота базы")
	for(var/pixel_x in 1 to expected.Width())
		for(var/pixel_y in 1 to expected.Height())
			TEST_ASSERT_EQUAL(actual.GetPixel(pixel_x, pixel_y), expected.GetPixel(pixel_x, pixel_y), "база после чужой расы отличается в пикселе [pixel_x],[pixel_y]")
	qdel(first)
	qdel(lizard)
	qdel(second)
