/// Шаблон-пустышка: ничего не грузит, только фиксирует состояние лендмарка на момент вызова load().
/datum/map_template/stationroom_reentrancy_probe
	name = "Stationroom Reentrancy Probe"
	var/obj/effect/landmark/stationroom/probe_landmark
	var/landmark_registered_during_load = FALSE
	var/load_calls = 0

/datum/map_template/stationroom_reentrancy_probe/load(turf/T, centered = FALSE, orientation = SOUTH, annihilate = default_annihilate, force_cache = FALSE, rotate_placement_to_orientation = FALSE)
	load_calls++
	if(probe_landmark in GLOB.stationroom_landmarks)
		landmark_registered_during_load = TRUE
	return null

/obj/effect/landmark/stationroom/reentrancy_probe
	template_names = list("Stationroom Reentrancy Probe" = 1)

/// Настоящий template.load() спит (маплоадер уступает тик). Пока лендмарк висит в
/// GLOB.stationroom_landmarks, параллельный seedStation() (таймер тикера, +60с после
/// раундстарта) подхватывает тот же лендмарк и грузит шаблон второй раз в ту же точку:
/// каждая атмос-машина дублируется, у устройства один слот nodes на две копии трубы,
/// и вторая копия передаёт в setPipenet отсутствующий в nodes объект (сотни рантаймов).
/datum/unit_test/stationroom_landmark_reentrancy/Run()
	var/datum/map_template/stationroom_reentrancy_probe/template = new
	SSmapping.station_room_templates[template.name] = template

	var/obj/effect/landmark/stationroom/reentrancy_probe/landmark = allocate(/obj/effect/landmark/stationroom/reentrancy_probe)
	template.probe_landmark = landmark
	TEST_ASSERT(landmark in GLOB.stationroom_landmarks, "Лендмарк не зарегистрировался в GLOB.stationroom_landmarks")

	landmark.load()

	TEST_ASSERT_EQUAL(template.load_calls, 1, "Шаблон станционной комнаты загрузился не ровно один раз")
	TEST_ASSERT(!template.landmark_registered_during_load, "Лендмарк остался в GLOB.stationroom_landmarks во время спящего template.load(): параллельный seedStation() загрузит тот же шаблон повторно в ту же точку")
	TEST_ASSERT(!(landmark in GLOB.stationroom_landmarks), "Лендмарк не снялся с учёта после загрузки")

	SSmapping.station_room_templates -= template.name
	GLOB.chosen_station_templates -= template.name

/// The large forgotten-ship room is intentionally inserted after round start. Its
/// parse and model-cache phases must be paid during mapping init, before clients can
/// be frozen by the late-load timer - and released once the single load attempt is
/// over (successful or not: the landmark never retries), since only one of the two
/// variants is ever placed and holding a quarter-megabyte DMM for the rest of the
/// round buys nothing.
/datum/unit_test/forgotten_ship_runtime_cache/Run()
	for(var/template_name in list("SCSBC-12", "SCSBC-13"))
		var/datum/map_template/template = SSmapping.station_room_templates[template_name]
		TEST_ASSERT_NOTNULL(template, "Missing station-room template [template_name]")
		TEST_ASSERT(template.keep_cached_map, "[template_name] does not retain its startup parse")
		// At most one variant is placed per round, so the branch below always runs
		// for the other one. `loaded` counts only successful placements (the
		// landmark's own duplicate counter is gone), so a chosen variant whose
		// placement FAILED lands in the else-branch with a released cache and
		// fails the not-null assert - which is the desired red flag: the ship
		// silently not placing is a mapping regression this test should surface.
		if(template.loaded)
			TEST_ASSERT_NULL(template.cached_map, "[template_name] went on holding its parsed DMM after being placed")
			continue
		TEST_ASSERT_NOTNULL(template.cached_map, "[template_name] holds no parsed DMM and was never placed - either the runtime cache was dropped before the late load, or the +60s placement failed")
		TEST_ASSERT_NOTNULL(template.cached_map.modelCache, "[template_name] deferred model-cache building into the live round")
