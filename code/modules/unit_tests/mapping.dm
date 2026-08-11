/// Conveys all log_mapping messages as unit test failures, as they all indicate mapping problems.
/datum/unit_test/log_mapping
	// Happen before all other tests, to make sure we only capture normal mapping logs.
	priority = TEST_PRE
	requires_full_map = TRUE

/datum/unit_test/log_mapping/Run()
	var/static/regex/test_areacoord_regex = regex(@"\(-?\d+,-?\d+,(-?\d+)\)")

	for(var/log_entry in GLOB.unit_test_mapping_logs)
		// Only fail if AREACOORD was conveyed, and it's a station or mining z-level.
		// This is due to mapping errors don't have coords being impossible to diagnose as a unit test,
		// and various ruins frequently intentionally doing non-standard things.
		if(!test_areacoord_regex.Find(log_entry))
			continue
		var/z = text2num(test_areacoord_regex.group[1])
		if(!is_station_level(z) && !is_mining_level(z))
			continue

		TEST_FAIL(log_entry)

/// build_cache() takes its space-key shortcut only when no_changeturf is set, and
/// that shortcut deliberately keeps the model key OUT of the cache. Handing such a
/// cache to a load that does want AfterChange sends the loader after a key that was
/// never stored, which CRASHes on an otherwise valid map - so a cache built under
/// the other value has to be rebuilt instead of returned as-is.
/datum/unit_test/parsed_map_cache_follows_changeturf/Run()
	// Parsing no file at all is a supported way to get an empty shell we can feed by
	// hand, which keeps this off the disk and out of the map loader entirely.
	var/datum/parsed_map/parsed = new
	parsed.grid_models = list("a" = "[world.turf],[world.area]")

	var/list/for_changeturf = parsed.build_cache(FALSE)
	TEST_ASSERT_NOTNULL(for_changeturf["a"], "a cache built for a changeturf load dropped the model the loader looks up")
	TEST_ASSERT_NULL(for_changeturf[SPACE_KEY], "a changeturf load was handed the space shortcut it must not use")

	var/list/for_skipping = parsed.build_cache(TRUE)
	TEST_ASSERT_EQUAL(for_skipping[SPACE_KEY], "a", "raising no_changeturf did not rebuild the cache with its space shortcut")

	var/list/for_changeturf_again = parsed.build_cache(FALSE)
	TEST_ASSERT_NOTNULL(for_changeturf_again["a"], "lowering no_changeturf reused a cache that omits the model key, which crashes the loader")
