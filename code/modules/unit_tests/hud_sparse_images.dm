/// Худ без клиента: значки зрителя складываются в список вместо client.images
/datum/atom_hud/sparse_test
	var/list/test_images = list()

/datum/atom_hud/sparse_test/New()
	// Без ..(): тестовый худ не должен попасть в GLOB.all_huds
	hud_icons = list(ID_HUD, WANTED_HUD, IMPLOYAL_HUD)

/datum/atom_hud/sparse_test/viewer_has_images(mob/viewer)
	return TRUE

/datum/atom_hud/sparse_test/add_hud_images(mob/viewer, list/images_to_add)
	test_images |= images_to_add

/datum/atom_hud/sparse_test/remove_hud_images(mob/viewer, list/images_to_remove)
	test_images -= images_to_remove

/// Пустые значки редких категорий (розыск, импланты) не раздаются зрителям худа, а появившийся значок
/// приходит к ним сразу. Гост с тремя продвинутыми худами держал их тысячами, и SendMaps перебирал их каждый тик.
/datum/unit_test/hud_sparse_images/Run()
	var/mob/living/carbon/human/suspect = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/datum/atom_hud/sparse_test/hud = new
	hud.add_to_hud(suspect)
	hud.hudusers[viewer] = 1
	var/image/id_image = suspect.hud_list[ID_HUD]
	var/image/wanted_image = suspect.hud_list[WANTED_HUD]
	var/image/loyal_image = suspect.hud_list[IMPLOYAL_HUD]

	var/list/shown = list()
	hud.collect_hud_images_for(viewer, shown)
	TEST_ASSERT(id_image in shown, "значок ID не раздаётся")
	TEST_ASSERT(!(wanted_image in shown), "пустой значок розыска раздаётся зрителю")
	TEST_ASSERT(!(loyal_image in shown), "пустой значок импланта раздаётся зрителю")

	suspect.set_hud_image_state(WANTED_HUD, "hudwanted")
	TEST_ASSERT(wanted_image in hud.test_images, "появившийся значок розыска не дошёл до зрителя")
	shown.Cut()
	hud.collect_hud_images_for(viewer, shown)
	TEST_ASSERT(wanted_image in shown, "непустой значок розыска не раздаётся новым зрителям")
	suspect.set_hud_image_state(WANTED_HUD, null)
	TEST_ASSERT(!(wanted_image in hud.test_images), "опустевший значок розыска остался у зрителя")

	ADD_TRAIT(suspect, TRAIT_MINDSHIELD, TRAIT_SOURCE_UNIT_TESTS)
	suspect.sec_hud_set_implants()
	TEST_ASSERT_EQUAL(loyal_image.icon_state, "hud_imp_loyal", "значок щита разума не выставлен")
	TEST_ASSERT(loyal_image in hud.test_images, "значок щита разума не дошёл до зрителя")
	REMOVE_TRAIT(suspect, TRAIT_MINDSHIELD, TRAIT_SOURCE_UNIT_TESTS)
	suspect.sec_hud_set_implants()
	TEST_ASSERT(!(loyal_image in hud.test_images), "снятый щит разума остался на худе зрителя")

	// Снятие худа убирает всё, включая пустые значки, которые могли попасть к зрителю раньше
	var/list/removed = list()
	hud.collect_hud_images_for(viewer, removed, check_visibility = FALSE)
	TEST_ASSERT(wanted_image in removed, "при снятии худа пустые значки не собираются")
	qdel(hud)
