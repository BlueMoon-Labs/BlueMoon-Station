/// Tests for the data-HUD pixel offset cache.
///
/// Every med/diag HUD setter used to run `icon(icon, icon_state, dir)` and then
/// `.Height()` just to work out how high above the mob its HUD marker should
/// float. Those setters fire on every health change, for every mob, whether or
/// not anyone is actually wearing a HUD — 165k /icon allocations in six minutes
/// of round 9800. The offset only depends on (icon file, icon state, dir), so it
/// is cached.

/datum/unit_test/hud_pixel_offset_matches_icon_height

/datum/unit_test/hud_pixel_offset_matches_icon_height/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(patient.icon, "Sanity: a human should have an icon file to measure")

	var/icon/reference = icon(patient.icon, patient.icon_state, patient.dir)
	var/expected = reference.Height() - world.icon_size

	TEST_ASSERT_EQUAL(get_hud_pixel_offset(patient.icon, patient.icon_state, patient.dir), expected, "The cached offset must match a freshly measured icon")

/datum/unit_test/hud_pixel_offset_is_stable_and_keyed_by_dir

/datum/unit_test/hud_pixel_offset_is_stable_and_keyed_by_dir/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	var/first = get_hud_pixel_offset(patient.icon, patient.icon_state, SOUTH)
	var/second = get_hud_pixel_offset(patient.icon, patient.icon_state, SOUTH)
	TEST_ASSERT_EQUAL(first, second, "Repeated lookups must return the same offset")

	// A different dir is a different cache entry, and must still be measured
	// rather than inheriting the value cached for SOUTH.
	var/icon/north_reference = icon(patient.icon, patient.icon_state, NORTH)
	TEST_ASSERT_EQUAL(get_hud_pixel_offset(patient.icon, patient.icon_state, NORTH), north_reference.Height() - world.icon_size, "Each dir must be measured on its own")

/datum/unit_test/med_hud_set_health_uses_cached_offset

/datum/unit_test/med_hud_set_health_uses_cached_offset/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	patient.med_hud_set_health()

	var/image/holder = patient.hud_list[HEALTH_HUD]
	TEST_ASSERT_NOTNULL(holder, "A human should have a HEALTH_HUD holder image")
	TEST_ASSERT_EQUAL(holder.icon_state, "hud[RoundHealth(patient)]", "med_hud_set_health must still set the health icon state")
	TEST_ASSERT_EQUAL(holder.pixel_y, get_hud_pixel_offset(patient.icon, patient.icon_state, patient.dir), "med_hud_set_health must position the marker with the cached offset")

/datum/unit_test/med_hud_set_status_uses_cached_offset

/datum/unit_test/med_hud_set_status_uses_cached_offset/Run()
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human)

	patient.med_hud_set_status()

	var/image/holder = patient.hud_list[STATUS_HUD]
	TEST_ASSERT_NOTNULL(holder, "A human should have a STATUS_HUD holder image")
	TEST_ASSERT_EQUAL(holder.pixel_y, get_hud_pixel_offset(patient.icon, patient.icon_state, patient.dir), "med_hud_set_status must position the marker with the cached offset")
