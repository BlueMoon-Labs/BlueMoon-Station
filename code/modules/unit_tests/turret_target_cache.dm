/// Кэш целей турели между сканами не держит удалённую цель: выключенная турель с полным кэшем делала из стаи тараканов хардделы (10604).
/datum/unit_test/turret_target_cache_does_not_hold_targets/Run()
	var/obj/machinery/porta_turret/turret = allocate(/obj/machinery/porta_turret)
	var/obj/item/target = new /obj/item/toy/plush(run_loc_floor_bottom_left)
	var/obj/item/survivor = allocate(/obj/item/toy/plush)
	turret.cache_targets(list(target, survivor))
	var/list/live = turret.cached_live_targets()
	TEST_ASSERT_EQUAL(length(live), 2, "кэш потерял живые цели")
	live = null
	qdel(target)
	live = turret.cached_live_targets()
	TEST_ASSERT_EQUAL(length(live), 1, "удалённая цель осталась среди целей турели")
	TEST_ASSERT(survivor in live, "живая цель пропала из кэша")
	live = null
	// Кроме переменной теста ссылок быть не должно.
	TEST_ASSERT_EQUAL(refcount(target), 1, "кэш турели держит удалённую цель")
