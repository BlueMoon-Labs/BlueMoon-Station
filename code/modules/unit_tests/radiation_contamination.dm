/// Тесты цепочки радиационного заражения.
/// Перф-инвариант: вторичное заражение (от волны) не должно порождать новое заражение -
/// иначе цепь "волна -> предмет -> волна" самоподдерживается быстрее полураспада, и комната
/// с сильным источником (реактор) превращается в вечный фонтан волн и компонентов.
/datum/unit_test/radiation_contamination

/datum/unit_test/radiation_contamination/proc/collect_rad_waves()
	var/list/waves = list()
	for(var/datum/thing in SSradiation.processing)
		if(istype(thing, /datum/radiation_wave))
			waves += thing
	return waves

/datum/unit_test/radiation_contamination/Run()
	var/turf/spot = run_loc_floor_bottom_left
	var/obj/item/wrench/first = new(spot)
	var/obj/item/wrench/second = new(spot)
	var/list/spawned_waves = list()

	// 1. Волна с can_contaminate=FALSE облучает, но не заражает
	var/datum/radiation_wave/no_contam_wave = new(first, NORTH, 1000, RAD_DISTANCE_COEFFICIENT, FALSE)
	spawned_waves += no_contam_wave
	no_contam_wave.radiate(list(second), 1000)
	TEST_ASSERT_NULL(second.GetComponent(/datum/component/radioactive), "Волна с can_contaminate=FALSE заразила предмет")

	// 2. Заражающая волна создаёт компонент, и этот компонент сам НЕ заражающий
	var/datum/radiation_wave/contam_wave = new(first, NORTH, 1000, RAD_DISTANCE_COEFFICIENT, TRUE)
	spawned_waves += contam_wave
	contam_wave.radiate(list(second), 1000)
	var/datum/component/radioactive/contamination = second.GetComponent(/datum/component/radioactive)
	TEST_ASSERT_NOTNULL(contamination, "Волна с can_contaminate=TRUE не заразила предмет")
	var/expected_strength = (1000 - RAD_MINIMUM_CONTAMINATION) * RAD_CONTAMINATION_STR_COEFFICIENT
	TEST_ASSERT_EQUAL(contamination.strength, expected_strength, "Сила вторичного заражения посчитана неверно")
	TEST_ASSERT(!contamination.can_contaminate, "Вторичное заражение от волны снова заражающее: цепь волн самоподдерживается")

	// 3. Повторная волна послабее не сбрасывает силу вниз и не включает заражаемость
	contam_wave.radiate(list(second), 500)
	TEST_ASSERT_EQUAL(contamination.strength, expected_strength, "Повторное заражение слабее сбросило силу вниз")
	TEST_ASSERT(!contamination.can_contaminate, "Повторное заражение включило заражаемость обратно")

	// 4. radiation_pulse пробрасывает can_contaminate в создаваемые волны
	var/list/waves_before = collect_rad_waves()
	radiation_pulse(first, 1000, RAD_DISTANCE_COEFFICIENT, FALSE, FALSE)
	var/list/created = collect_rad_waves() - waves_before
	TEST_ASSERT_EQUAL(length(created), 4, "Пульс 1000 не создал 4 волны (создано [length(created)])")
	for(var/datum/radiation_wave/wave as anything in created)
		TEST_ASSERT(!wave.can_contaminate, "radiation_pulse не пробросил can_contaminate=FALSE в волну")
	spawned_waves += created

	// 5. Пульс слабее порога заражения волн не создаёт вообще
	waves_before = collect_rad_waves()
	radiation_pulse(first, RAD_MINIMUM_CONTAMINATION - 100)
	TEST_ASSERT_EQUAL(length(collect_rad_waves() - waves_before), 0, "Пульс ниже RAD_MINIMUM_CONTAMINATION создал волны")

	// Уборка: волны сами по себе, компоненты уйдут с предметами
	for(var/datum/radiation_wave/wave as anything in spawned_waves)
		qdel(wave)
	qdel(first)
	qdel(second)
