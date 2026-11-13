/// Удаление запаркованного атома снимает его с отложки света и сбрасывает кэш отложенных z.
/datum/unit_test/lighting_deferred_destroy_unparks/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/datum/space_level/level = SSmapping.get_level(test_turf.z)
	var/old_init = level.lighting_initialized
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()
	var/saved_cache = GLOB.lighting_deferred_z_cache

	var/obj/effect/light_emitter/emitter = park_deferred_emitter(test_turf, level)
	var/precond_parked = (emitter in GLOB.lighting_deferred_atoms)
	var/flagged = (emitter.flags_1 & LIGHTING_DEFERRED_PARKED_1)
	GLOB.lighting_deferred_z_cache = list(test_turf.z)
	qdel(emitter)
	var/unparked = !(emitter in GLOB.lighting_deferred_atoms)
	var/cache_reset = isnull(GLOB.lighting_deferred_z_cache)

	restore_deferred_lighting_atoms(saved_deferred)
	GLOB.lighting_deferred_z_cache = saved_cache
	level.lighting_initialized = old_init

	TEST_ASSERT(precond_parked, "предпосылка: эмиттер не запарковался в отложке света")
	TEST_ASSERT(flagged, "запаркованный атом не несёт признака парковки - удаление его не снимет")
	TEST_ASSERT(unparked, "удалённый запаркованный атом остался в отложке света")
	TEST_ASSERT(cache_reset, "удаление запаркованного атома не сбросило кэш отложенных z")

/// Удаление атома без признака парковки отложку не ищет и кэш отложенных z не трогает.
/datum/unit_test/lighting_deferred_destroy_skips_unparked/Run()
	var/obj/item/trash/candy/candy = allocate(/obj/item/trash/candy, run_loc_floor_bottom_left)
	var/list/saved_deferred = GLOB.lighting_deferred_atoms
	var/saved_cache = GLOB.lighting_deferred_z_cache

	// Атом подложен в отложку мимо парковки: если Destroy его нашёл, значит, искал.
	var/list/probe = list(candy)
	var/list/cache = list()
	GLOB.lighting_deferred_atoms = probe
	GLOB.lighting_deferred_z_cache = cache
	var/precond_unflagged = !(candy.flags_1 & LIGHTING_DEFERRED_PARKED_1)
	qdel(candy)
	var/searched = !(candy in probe)
	var/cache_kept = (GLOB.lighting_deferred_z_cache == cache)

	GLOB.lighting_deferred_atoms = saved_deferred
	GLOB.lighting_deferred_z_cache = saved_cache
	probe.Cut()

	TEST_ASSERT(precond_unflagged, "предпосылка: свежий предмет уже несёт признак парковки")
	TEST_ASSERT(!searched, "удаление незапаркованного атома прошло по отложке света")
	TEST_ASSERT(cache_kept, "удаление незапаркованного атома сбросило кэш отложенных z")

/// Подъём уровня снимает с атома признак парковки вместе с самим атомом из отложки.
/datum/unit_test/lighting_deferred_flush_clears_flag/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)
	var/old_init = level.lighting_initialized
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()

	var/obj/effect/light_emitter/emitter = park_deferred_emitter(test_turf, level)
	var/precond_flagged = (emitter.flags_1 & LIGHTING_DEFERRED_PARKED_1)
	GLOB.lighting_deferred_atoms = list(emitter)
	create_lighting_for_zlevel(test_z)
	var/flushed = !(emitter in GLOB.lighting_deferred_atoms) && !isnull(emitter.light)
	var/flag_cleared = !(emitter.flags_1 & LIGHTING_DEFERRED_PARKED_1)

	restore_deferred_lighting_atoms(saved_deferred)
	level.lighting_initialized = old_init

	TEST_ASSERT(precond_flagged, "предпосылка: запаркованный атом не несёт признака парковки")
	TEST_ASSERT(flushed, "подъём уровня не сфлашил запаркованный атом")
	TEST_ASSERT(flag_cleared, "сфлашенный атом сохранил признак парковки - его удаление зря пройдёт по отложке")
