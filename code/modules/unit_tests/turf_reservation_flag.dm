/// Замена свободной клетки резерва сохраняет её пригодность для Reserve(), а выданная клетка флаг не получает.
/datum/unit_test/turf_reservation_flag/Run()
	var/datum/turf_reservation/probe = SSmapping.RequestBlockReservation(3, 3)
	TEST_ASSERT_NOTNULL(probe, "Резервация получена.")
	var/turf/reserved = probe.reserved_turfs[1]
	TEST_ASSERT(!(reserved.flags_1 & UNUSED_RESERVATION_TURF_1), "Выданная клетка не помечена свободной.")
	reserved = reserved.ChangeTurf(/turf/open/floor/plating)
	TEST_ASSERT(!(reserved.flags_1 & UNUSED_RESERVATION_TURF_1), "Замена выданной клетки не делает её свободной.")
	qdel(probe)
	TEST_ASSERT(reserved.flags_1 & UNUSED_RESERVATION_TURF_1, "Освобождённая клетка помечена свободной.")
	reserved = reserved.ChangeTurf(/turf/open/floor/plating)
	TEST_ASSERT(reserved.flags_1 & UNUSED_RESERVATION_TURF_1, "Замена свободной клетки сохраняет флаг.")
	reserved = reserved.ChangeTurf(/turf/open/space/basic, flags = CHANGETURF_SKIP)
	TEST_ASSERT(reserved.flags_1 & UNUSED_RESERVATION_TURF_1, "Быстрая замена свободной клетки тоже сохраняет флаг.")

/// Выдача убирает из пула ровно свои клетки, а постепенное освобождение возвращает их и удаляет резервацию.
/datum/unit_test/turf_reservation_gradual_release/Run()
	var/datum/turf_reservation/probe = SSmapping.RequestBlockReservation(3, 3)
	TEST_ASSERT_NOTNULL(probe, "Резервация получена.")
	var/list/taken = probe.reserved_turfs.Copy()
	var/turf/corner = taken[1]
	var/list/pool = SSmapping.unused_turfs["[corner.z]"]
	for(var/turf/reserved as anything in taken)
		TEST_ASSERT(!(reserved in pool), "Выданная клетка ушла из пула.")
	var/pool_size = length(pool)
	probe.release_gradually()
	TEST_ASSERT(wait_for_qdeleted(probe), "Резервация удаляется, отдав последнюю клетку.")
	pool = SSmapping.unused_turfs["[corner.z]"]
	TEST_ASSERT_EQUAL(length(pool), pool_size + length(taken), "В пул вернулись все клетки.")
	for(var/turf/reserved as anything in taken)
		TEST_ASSERT(reserved.flags_1 & UNUSED_RESERVATION_TURF_1, "Освобождённая клетка помечена свободной.")
		TEST_ASSERT_NULL(SSmapping.used_turfs[reserved], "Освобождённая клетка не числится занятой.")
