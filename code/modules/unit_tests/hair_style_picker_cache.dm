/// Миниатюры причёсок собираются по тикам вне Topic и берутся из общего кэша, пока не сменились раса, цвет или стили.
/datum/unit_test/hair_picker_cell_cache
	var/mob/living/carbon/human/dummy/consistent/viewer

/datum/unit_test/hair_picker_cell_cache/proc/open_picker(datum/preferences/prefs)
	var/datum/hair_style_picker/picker = new
	picker.owner_ckey = "unit_test_hair_cache"
	picker.setup_prefs(prefs, "hair", viewer)
	return picker

/datum/unit_test/hair_picker_cell_cache/proc/wait_render(datum/hair_style_picker/picker)
	var/waited = 0
	while(picker.rendering && waited < 400)
		sleep(world.tick_lag)
		waited++
	return !picker.rendering

/// Открытие окна: база собирается в фоне, за ней миниатюры страницы. Возвращает данные окна после сборки.
/datum/unit_test/hair_picker_cell_cache/proc/settle(datum/hair_style_picker/picker)
	picker.ui_data(viewer)
	if(!wait_render(picker))
		return null
	picker.ui_data(viewer)
	if(!wait_render(picker))
		return null
	return picker.ui_data(viewer)

/datum/unit_test/hair_picker_cell_cache/proc/all_cells_ready(list/data)
	var/list/cells = data["cells"]
	if(length(cells) != length(data["names"]))
		return FALSE
	for(var/cell in cells)
		if(!cell)
			return FALSE
	return TRUE

/datum/unit_test/hair_picker_cell_cache/Run()
	GLOB.hair_picker_cell_cache.Cut()
	viewer = allocate(/mob/living/carbon/human/dummy/consistent)
	var/datum/preferences/navigation_test/human_prefs = allocate(/datum/preferences/navigation_test)
	human_prefs.pref_species = new /datum/species/human
	human_prefs.random_character(MALE)
	human_prefs.hair_color = "aa3311"

	var/datum/hair_style_picker/picker = open_picker(human_prefs)
	var/datum/tgui/ui = allocate(/datum/tgui, viewer, picker, "HairStylePicker")
	ui.status = UI_INTERACTIVE
	var/list/data = picker.ui_data(viewer)
	var/page_size = length(data["names"])
	TEST_ASSERT(page_size > 1, "в окне причёсок нет страницы стилей")
	TEST_ASSERT(data["cells_loading"], "открытое окно не показало ожидание миниатюр")
	TEST_ASSERT(!length(data["cells"]), "миниатюры появились до сборки базы")
	TEST_ASSERT(!length(picker.base_cache), "база собралась прямо в открытии окна")
	TEST_ASSERT(wait_render(picker), "база окна причёсок не собралась")
	data = picker.ui_data(viewer)
	TEST_ASSERT_EQUAL(picker.cell_builds, 0, "миниатюры собрались прямо в обновлении окна")
	TEST_ASSERT(wait_render(picker), "первая страница не собралась")
	data = picker.ui_data(viewer)
	TEST_ASSERT(all_cells_ready(data), "первая страница собралась не целиком")
	TEST_ASSERT(!data["cells_loading"], "готовая страница всё ещё ждёт сборки")
	TEST_ASSERT_EQUAL(picker.cell_builds, page_size, "миниатюры первой страницы собирались не по разу")
	var/list/first_cells = data["cells"]
	var/list/first_page = first_cells.Copy()

	usr = viewer
	picker.ui_act("page", list("page" = 2), ui)
	data = picker.ui_data(viewer)
	TEST_ASSERT(data["cells_loading"], "вторая страница не ждёт своих миниатюр")
	TEST_ASSERT_EQUAL(picker.cell_builds, page_size, "вторая страница собралась прямо в Topic")
	TEST_ASSERT(wait_render(picker), "вторая страница не собралась")
	data = picker.ui_data(viewer)
	TEST_ASSERT(all_cells_ready(data), "вторая страница собралась не целиком")
	var/second_builds = picker.cell_builds

	var/list/page_names = data["names"]
	picker.ui_act("select", list("name" = page_names[1]), ui)
	picker.ui_data(viewer)
	picker.ui_act("select", list("name" = page_names[2]), ui)
	picker.ui_data(viewer)
	var/preview_builds = picker.preview_builds
	picker.ui_act("select", list("name" = page_names[1]), ui)
	data = picker.ui_data(viewer)
	TEST_ASSERT_EQUAL(picker.preview_builds, preview_builds, "повторный выбор стиля собрал превью заново")
	TEST_ASSERT(length(data["preview_portraits"]), "повторный выбор стиля потерял превью")

	picker.ui_act("page", list("page" = 1), ui)
	data = picker.ui_data(viewer)
	usr = null
	var/list/cells = data["cells"]
	TEST_ASSERT(all_cells_ready(data) && cells[1] == first_page[1], "возврат на первую страницу не взял миниатюры из кэша")
	TEST_ASSERT_EQUAL(picker.cell_builds, second_builds, "возврат на первую страницу собрал миниатюры заново")
	TEST_ASSERT(!picker.rendering, "возврат на первую страницу запустил сборку")
	qdel(picker)

	var/datum/hair_style_picker/reopened = open_picker(human_prefs)
	data = settle(reopened)
	TEST_ASSERT_NOTNULL(data, "повторно открытое окно не собралось")
	TEST_ASSERT(all_cells_ready(data), "повторно открытое окно не показало миниатюры")
	cells = data["cells"]
	TEST_ASSERT_EQUAL(cells[1], first_page[1], "повторно открытое окно нарисовало другую миниатюру")
	TEST_ASSERT_EQUAL(reopened.cell_builds, 0, "повторно открытое окно собрало те же миниатюры")

	human_prefs.hair_color = "11aa33"
	data = reopened.ui_data(viewer)
	TEST_ASSERT(data["cells_loading"], "после смены цвета остались миниатюры старого цвета")
	TEST_ASSERT(wait_render(reopened), "миниатюры нового цвета не собрались")
	data = reopened.ui_data(viewer)
	TEST_ASSERT(all_cells_ready(data), "миниатюры нового цвета собрались не целиком")
	TEST_ASSERT_EQUAL(reopened.cell_builds, page_size, "смена цвета не перерисовала страницу")
	cells = data["cells"]
	var/recolored = 0
	for(var/index in 1 to page_size)
		if(cells[index] != first_page[index])
			recolored++
	TEST_ASSERT(recolored, "смена цвета не изменила ни одной миниатюры")
	qdel(reopened)

	var/datum/preferences/navigation_test/lizard_prefs = allocate(/datum/preferences/navigation_test)
	lizard_prefs.pref_species = new /datum/species/lizard
	lizard_prefs.random_character(MALE)
	lizard_prefs.hair_color = "aa3311"
	var/datum/hair_style_picker/lizard = open_picker(lizard_prefs)
	data = settle(lizard)
	TEST_ASSERT_NOTNULL(data, "окно ящера не собралось")
	TEST_ASSERT(all_cells_ready(data), "окно ящера не показало миниатюры")
	TEST_ASSERT_EQUAL(lizard.cell_builds, length(data["names"]), "другой вид взял миниатюры человека")
	qdel(lizard)

	GLOB.hair_picker_cell_cache.Cut()
	for(var/index in 1 to 5000)
		hair_picker_store_cell("key_[index]", "cell_[index]")
	TEST_ASSERT(length(GLOB.hair_picker_cell_cache) < 5000, "кэш миниатюр не ограничен")
	TEST_ASSERT_EQUAL(GLOB.hair_picker_cell_cache["key_5000"], "cell_5000", "кэш выбросил свежую миниатюру")
	TEST_ASSERT_NULL(GLOB.hair_picker_cell_cache["key_1"], "кэш держит самую старую миниатюру")
	GLOB.hair_picker_cell_cache.Cut()
