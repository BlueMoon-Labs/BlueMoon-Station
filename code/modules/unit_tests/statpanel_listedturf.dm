/datum/unit_test/statpanel_listedturf_snapshot/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(test_turf, "Test turf should exist")

	var/obj/item/visible_item = allocate(/obj/item, test_turf)
	visible_item.name = "listed turf visible test item"

	var/obj/item/transparent_item = allocate(/obj/item, test_turf)
	transparent_item.name = "listed turf transparent test item"
	transparent_item.mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	var/obj/item/hidden_item = allocate(/obj/item, test_turf)
	hidden_item.name = "listed turf hidden test item"
	hidden_item.invisibility = SEE_INVISIBLE_LIVING + 1

	var/obj/item/overridden_item = allocate(/obj/item, test_turf)
	overridden_item.name = "listed turf overridden test item"

	var/obj/item/obscured_item = allocate(/obj/item, test_turf)
	obscured_item.name = "listed turf obscured test item"

	var/obj/item/obscurer = allocate(/obj/item, test_turf)
	obscurer.name = "listed turf obscurer"
	obscurer.density = TRUE
	obscurer.flags_1 |= PREVENT_CLICK_UNDER_1
	obscurer.layer = obscured_item.layer + 1
	visible_item.layer = obscurer.layer + 1
	transparent_item.layer = obscurer.layer + 1
	hidden_item.layer = obscurer.layer + 1
	overridden_item.layer = obscurer.layer + 1

	var/list/snapshot = SSstatpanels.build_listedturf_snapshot(test_turf, SEE_INVISIBLE_LIVING)
	TEST_ASSERT_NOTNULL(snapshot, "Snapshot helper should return data for a valid turf")

	var/list/decoded = json_decode(url_decode(snapshot["encoded"]))
	var/list/decoded_refs = list()
	for(var/entry in decoded)
		var/list/row = entry
		decoded_refs[row[2]] = TRUE

	TEST_ASSERT(decoded_refs[REF(test_turf)], "Snapshot should include the turf itself")
	TEST_ASSERT(decoded_refs[REF(visible_item)], "Snapshot should include visible turf contents")
	TEST_ASSERT(decoded_refs[REF(overridden_item)], "Snapshot should include override candidates unless an override list is provided")
	TEST_ASSERT(!decoded_refs[REF(transparent_item)], "Snapshot should skip transparent turf contents")
	TEST_ASSERT(!decoded_refs[REF(hidden_item)], "Snapshot should skip hidden turf contents")
	TEST_ASSERT(!decoded_refs[REF(obscured_item)], "Snapshot should skip obscured turf contents")

	var/list/needs_icons = snapshot["needs_icons"]
	TEST_ASSERT(test_turf in needs_icons, "Snapshot should request an icon for the turf when none were sent yet")
	TEST_ASSERT(visible_item in needs_icons, "Snapshot should request an icon for visible items when none were sent yet")
	TEST_ASSERT(overridden_item in needs_icons, "Visible override candidates should request icons before override filtering is applied")
	TEST_ASSERT(!(transparent_item in needs_icons), "Transparent items should not request icons")
	TEST_ASSERT(!(hidden_item in needs_icons), "Hidden items should not request icons")
	TEST_ASSERT(!(obscured_item in needs_icons), "Obscured items should not request icons")

	var/list/repeated_snapshot = SSstatpanels.build_listedturf_snapshot(test_turf, SEE_INVISIBLE_LIVING)
	TEST_ASSERT_EQUAL(repeated_snapshot["encoded"], snapshot["encoded"], "Identical turf contents should produce a stable encoded payload")

	var/list/sent_icons = list()
	for(var/atom/A as anything in needs_icons)
		sent_icons[REF(A)] = TRUE
	var/list/without_icons = SSstatpanels.build_listedturf_snapshot(test_turf, SEE_INVISIBLE_LIVING, null, sent_icons)
	TEST_ASSERT_EQUAL(length(without_icons["needs_icons"]), 0, "Snapshot should not request icons that were already sent")

	var/list/override_snapshot = SSstatpanels.build_listedturf_snapshot(test_turf, SEE_INVISIBLE_LIVING, list(overridden_item))
	var/list/override_decoded = json_decode(url_decode(override_snapshot["encoded"]))
	var/list/override_refs = list()
	for(var/entry in override_decoded)
		var/list/row = entry
		override_refs[row[2]] = TRUE
	TEST_ASSERT(!override_refs[REF(overridden_item)], "Snapshot should skip items hidden behind client image overrides")
	TEST_ASSERT(!(overridden_item in override_snapshot["needs_icons"]), "Override-filtered items should not request icons")

/datum/unit_test/statpanel_listedturf_dirty_changes/Run()
	var/turf/test_turf = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	TEST_ASSERT_NOTNULL(test_turf, "Dirty-change test turf should exist")

	var/list/initial_snapshot = SSstatpanels.build_listedturf_snapshot(test_turf, SEE_INVISIBLE_LIVING)
	TEST_ASSERT_NOTNULL(initial_snapshot, "Initial snapshot should exist")
	var/initial_encoded = initial_snapshot["encoded"]

	var/obj/item/added_item = allocate(/obj/item, test_turf)
	added_item.name = "listed turf dirty add item"
	var/list/after_add = SSstatpanels.build_listedturf_snapshot(test_turf, SEE_INVISIBLE_LIVING)
	TEST_ASSERT_NOTEQUAL(after_add["encoded"], initial_encoded, "Adding an item should change the encoded turf snapshot")
	TEST_ASSERT(added_item in after_add["needs_icons"], "Newly added item should need an icon")

	added_item.forceMove(run_loc_floor_top_right)
	var/list/after_remove = SSstatpanels.build_listedturf_snapshot(test_turf, SEE_INVISIBLE_LIVING)
	TEST_ASSERT_EQUAL(after_remove["encoded"], initial_encoded, "Removing an item should restore the previous snapshot")

	var/obj/item/doomed_item = allocate(/obj/item, test_turf)
	doomed_item.name = "listed turf dirty doomed item"
	var/list/with_doomed = SSstatpanels.build_listedturf_snapshot(test_turf, SEE_INVISIBLE_LIVING)
	TEST_ASSERT_NOTEQUAL(with_doomed["encoded"], initial_encoded, "Adding a doomed item should still change the snapshot before deletion")

	qdel(doomed_item)
	TEST_ASSERT(QDELETED(doomed_item), "Doomed item should be qdeleted in the dirty-change test")
	var/list/after_qdel = SSstatpanels.build_listedturf_snapshot(test_turf, SEE_INVISIBLE_LIVING)
	TEST_ASSERT_EQUAL(after_qdel["encoded"], initial_encoded, "Qdeleting an item should restore the previous snapshot")

/datum/unit_test/statpanel_listedturf_refresh_gating/Run()
	var/current_time = 100

	var/list/no_refresh = SSstatpanels.get_listedturf_refresh_actions(
		last_refresh = current_time - 10,
		last_icon_refresh = current_time - 10,
		current_time = current_time,
	)
	TEST_ASSERT(!no_refresh["list_refresh_due"], "Fresh listed turf state should not trigger a list refresh")
	TEST_ASSERT(!no_refresh["icon_refresh_due"], "Fresh listed turf state should not trigger an icon refresh")

	var/list/dirty_refresh = SSstatpanels.get_listedturf_refresh_actions(
		listed_turf_dirty = TRUE,
		last_refresh = current_time,
		last_icon_refresh = current_time,
		current_time = current_time,
	)
	TEST_ASSERT(dirty_refresh["list_refresh_due"], "Dirty listed turf state should refresh the list")
	TEST_ASSERT(!dirty_refresh["icon_refresh_due"], "Dirty listed turf state alone should not refresh icons")

	var/list/dirty_icon_refresh = SSstatpanels.get_listedturf_refresh_actions(
		listed_turf_dirty = TRUE,
		listed_turf_icon_refresh_pending = TRUE,
		last_refresh = current_time,
		last_icon_refresh = current_time,
		current_time = current_time,
	)
	TEST_ASSERT(dirty_icon_refresh["list_refresh_due"], "Dirty listed turf state should still refresh the list when icon refresh is pending")
	TEST_ASSERT(dirty_icon_refresh["icon_refresh_due"], "Pending listed turf icon refresh should bypass icon throttling")

	var/list/eye_refresh = SSstatpanels.get_listedturf_refresh_actions(
		eye_changed = TRUE,
		last_refresh = current_time,
		last_icon_refresh = current_time,
		current_time = current_time,
	)
	TEST_ASSERT(eye_refresh["list_refresh_due"], "Eye turf changes should refresh the list")
	TEST_ASSERT(!eye_refresh["icon_refresh_due"], "Eye turf changes alone should not refresh icons")

	var/list/list_interval_refresh = SSstatpanels.get_listedturf_refresh_actions(
		last_refresh = current_time - 20,
		last_icon_refresh = current_time,
		current_time = current_time,
	)
	TEST_ASSERT(list_interval_refresh["list_refresh_due"], "List refresh fallback should fire after the configured interval")
	TEST_ASSERT(!list_interval_refresh["icon_refresh_due"], "List fallback should not force an icon refresh")

	var/list/turf_change_refresh = SSstatpanels.get_listedturf_refresh_actions(
		turf_changed = TRUE,
		last_refresh = current_time,
		last_icon_refresh = current_time,
		current_time = current_time,
	)
	TEST_ASSERT(turf_change_refresh["list_refresh_due"], "Changing listed turf should refresh the list")
	TEST_ASSERT(turf_change_refresh["icon_refresh_due"], "Changing listed turf should refresh icons")

	var/list/icon_interval_refresh = SSstatpanels.get_listedturf_refresh_actions(
		last_refresh = current_time,
		last_icon_refresh = current_time - 100,
		current_time = current_time,
	)
	TEST_ASSERT(!icon_interval_refresh["list_refresh_due"], "Icon fallback alone should not resend the list")
	TEST_ASSERT(icon_interval_refresh["icon_refresh_due"], "Icon fallback should requeue icons after the configured interval")

	var/list/forced_refresh = SSstatpanels.get_listedturf_refresh_actions(
		force_send = TRUE,
		last_refresh = current_time,
		last_icon_refresh = current_time,
		current_time = current_time,
	)
	TEST_ASSERT(forced_refresh["list_refresh_due"], "Forced sends should bypass list refresh throttling")

	var/list/forced_icon_refresh = SSstatpanels.get_listedturf_refresh_actions(
		force_icon_refresh = TRUE,
		last_refresh = current_time,
		last_icon_refresh = current_time,
		current_time = current_time,
	)
	TEST_ASSERT(forced_icon_refresh["icon_refresh_due"], "Forced icon refreshes should bypass icon throttling")

	var/list/initial_icon_refresh = SSstatpanels.get_listedturf_refresh_actions(
		last_refresh = current_time,
		last_icon_refresh = 0,
		current_time = current_time,
	)
	TEST_ASSERT(initial_icon_refresh["icon_refresh_due"], "Initial listed turf display should request icons immediately")

	// Debounce: a dirty flag set just now should NOT immediately retrigger when last_refresh is current
	var/list/dirty_debounced = SSstatpanels.get_listedturf_refresh_actions(
		listed_turf_dirty = TRUE,
		listed_turf_dirty_at = current_time,
		last_refresh = current_time,
		last_icon_refresh = current_time,
		current_time = current_time,
	)
	TEST_ASSERT(!dirty_debounced["list_refresh_due"], "Recently-dirty listed turf should be debounced when last_refresh is current")

	// Debounce: a dirty flag set on the previous tick should retrigger if min interval has passed
	var/list/dirty_after_debounce = SSstatpanels.get_listedturf_refresh_actions(
		listed_turf_dirty = TRUE,
		listed_turf_dirty_at = current_time - 5,
		last_refresh = current_time - 5,
		last_icon_refresh = current_time,
		current_time = current_time,
	)
	TEST_ASSERT(dirty_after_debounce["list_refresh_due"], "Dirty listed turf older than the debounce window should refresh")

/datum/unit_test/statpanel_listedturf_icon_queue_merge/Run()
	var/obj/item/first_item = allocate(/obj/item, run_loc_floor_bottom_left)
	var/obj/item/second_item = allocate(/obj/item, run_loc_floor_bottom_left)
	var/obj/item/third_item = allocate(/obj/item, run_loc_floor_bottom_left)

	var/list/existing = list(first_item, second_item)
	var/list/merged = SSstatpanels.merge_listedturf_icon_queue(existing, list(second_item, third_item, second_item))
	TEST_ASSERT_EQUAL(length(merged), 3, "Merged icon queue should only contain unique atoms")
	TEST_ASSERT_EQUAL(merged[1], first_item, "Existing icon queue order should be preserved")
	TEST_ASSERT_EQUAL(merged[2], second_item, "Existing icon queue entries should remain in place")
	TEST_ASSERT_EQUAL(merged[3], third_item, "New icon queue entries should be appended once")

	var/list/source = list(first_item, second_item)
	var/list/new_queue = SSstatpanels.merge_listedturf_icon_queue(null, source)
	TEST_ASSERT_EQUAL(length(new_queue), 2, "Merging into an empty queue should copy the new icons")
	new_queue += third_item
	TEST_ASSERT_EQUAL(length(source), 2, "Merging into an empty queue should return a copy instead of mutating the source list")
