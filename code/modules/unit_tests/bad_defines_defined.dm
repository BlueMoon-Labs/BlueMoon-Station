/datum/unit_test/bad_defines_used/Run()
	var/force_map_check = FALSE
	#ifdef FORCE_MAP
	force_map_check = TRUE
	#endif
	var/lowmemorymode_check = FALSE
	#ifdef LOWMEMORYMODE
	lowmemorymode_check = TRUE
	#endif
	var/minimal_compile_check = FALSE
	#ifdef ABSOLUTE_MINIMUM_MODE
	minimal_compile_check = TRUE
	#endif
	TEST_ASSERT_EQUAL(force_map_check + lowmemorymode_check + minimal_compile_check, 0, "used [force_map_check ? "define FORCE_MAP " : ""][lowmemorymode_check ? "define LOWMEMORYMODE " : ""][minimal_compile_check ? "define ABSOLUTE_MINIMUM_MODE " : ""]. UNDEFINE THEM")
