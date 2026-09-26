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
