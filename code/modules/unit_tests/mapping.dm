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

/// The model cache is mode-independent: the space-key shortcut is recorded as a
/// marker while the model entry itself stays stored, so one cache serves both a
/// no_changeturf load (which skips space tiles by the marker) and a normal load
/// (which must be able to look the same key up, or the loader CRASHes on an
/// otherwise valid map). One complete cache must also never be rebuilt: the eager
/// template prebuilds rely on load() reusing their work as-is.
/datum/unit_test/parsed_map_cache_mode_independent/Run()
	// Parsing no file at all is a supported way to get an empty shell we can feed by
	// hand, which keeps this off the disk and out of the map loader entirely.
	var/datum/parsed_map/parsed = new
	parsed.grid_models = list("a" = "[world.turf],[world.area]")

	var/list/cache = parsed.build_cache()
	TEST_ASSERT_EQUAL(cache[SPACE_KEY], "a", "the space-model marker was not recorded")
	TEST_ASSERT_NOTNULL(cache["a"], "the space model entry was dropped from the cache, which crashes any load that wants AfterChange")

	TEST_ASSERT_EQUAL(parsed.build_cache(), cache, "a complete cache was rebuilt instead of reused")
