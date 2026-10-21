/// Превью профессии в меню рисуется на общем манекене и совпадает с отрисовкой на свежем, даже после чужой расы.
/datum/unit_test/job_menu_preview_pooled_dummy/Run()
	var/datum/preferences/navigation_test/human_prefs = allocate(/datum/preferences/navigation_test)
	human_prefs.pref_species = new /datum/species/human
	human_prefs.random_character(MALE)
	var/datum/preferences/navigation_test/lizard_prefs = allocate(/datum/preferences/navigation_test)
	lizard_prefs.pref_species = new /datum/species/lizard
	lizard_prefs.random_character(FEMALE)

	var/datum/job_menu/human_menu = new("prefs", human_prefs)
	var/datum/job_menu/lizard_menu = new("prefs", lizard_prefs)
	var/expected = human_menu.encode_preview_icon(get_flat_human_icon(null, SSjob.GetJob("Scientist"), human_prefs, null, list(SOUTH)))

	TEST_ASSERT(length(lizard_menu.generate_preview("Scientist", null)), "превью ящера не собралось")
	var/mob/living/carbon/human/dummy/pooled = GLOB.human_dummy_list[DUMMY_HUMAN_SLOT_JOB_MENU]
	TEST_ASSERT_NOTNULL(pooled, "превью профессии не берёт манекен из пула")
	var/actual = human_menu.generate_preview("Scientist", null)
	TEST_ASSERT_EQUAL(GLOB.human_dummy_list[DUMMY_HUMAN_SLOT_JOB_MENU], pooled, "второе превью не переиспользовало манекен")
	TEST_ASSERT(!pooled.in_use, "манекен меню профессий остался занятым")
	TEST_ASSERT(actual == expected, "превью на общем манекене отличается от превью на свежем")
	qdel(human_menu)
	qdel(lizard_menu)

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
