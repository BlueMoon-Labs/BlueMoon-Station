/// backdrop() любой плоскости не падает, пока у клиента зрителя ещё нет prefs.
/datum/unit_test/plane_master_backdrop_without_prefs

/datum/unit_test/plane_master_backdrop_without_prefs/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	viewer.mock_client = new /datum/client_interface()
	for(var/master_type in subtypesof(/atom/movable/screen/plane_master))
		var/atom/movable/screen/plane_master/master = new master_type(null)
		allocated += master
		master.backdrop(viewer)
	for(var/category in LAZYCOPY(viewer.fullscreens))
		viewer.clear_fullscreen(category, 0)
	viewer.mock_client = null

/atom/movable/screen/plane_master/var/unit_test_filter_rebuilds = 0

/atom/movable/screen/plane_master/update_filters()
	if(!filter_updates_deferred)
		unit_test_filter_rebuilds++
	return ..()

/// Подложка плоскости переставляет фильтры по одному, а refresh_backdrop() пересобирает их один раз.
/datum/unit_test/plane_master_backdrop_single_rebuild/Run()
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/datum/preferences/prefs = new
	allocated += prefs
	prefs.lighting_blur = 3
	viewer.mock_client = new /datum/client_interface()
	viewer.mock_client.prefs = prefs
	var/atom/movable/screen/plane_master/lamps_selfglow/master = new(null)
	allocated += master
	master.refresh_backdrop(viewer)

	master.unit_test_filter_rebuilds = 0
	master.backdrop(viewer)
	var/direct_rebuilds = master.unit_test_filter_rebuilds
	master.unit_test_filter_rebuilds = 0
	master.refresh_backdrop(viewer)
	var/batched_rebuilds = master.unit_test_filter_rebuilds
	var/list/batched_filters = master.filters
	viewer.mock_client = null

	TEST_ASSERT(direct_rebuilds > 1, "test premise: подложка свечения ламп правит больше одного фильтра, правок [direct_rebuilds]")
	TEST_ASSERT_EQUAL(batched_rebuilds, 1, "refresh_backdrop() пересобрал фильтры не один раз")
	TEST_ASSERT_EQUAL(length(batched_filters), length(master.filter_data), "После refresh_backdrop() на плоскости не все фильтры из filter_data")
