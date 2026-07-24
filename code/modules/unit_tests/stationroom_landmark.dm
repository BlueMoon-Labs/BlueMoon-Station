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
