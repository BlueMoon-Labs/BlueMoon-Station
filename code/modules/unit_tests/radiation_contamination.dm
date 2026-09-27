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

/// Радиоактивные предметы с работающим свечением освобождаются без harddel.
/datum/unit_test/radioactive_parent_gc
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/radioactive_parent_gc/proc/create_and_delete(source_type)
	var/atom/movable/source = new source_type(run_loc_floor_bottom_left)
	if(istype(source, /obj/item/stock_parts/cell))
		var/obj/item/stock_parts/cell/cell = source
		cell.process()
	var/datum/component/radioactive/contamination = source.GetComponent(/datum/component/radioactive)
	TEST_ASSERT_NOTNULL(contamination, "У [source_type] нет радиоактивного компонента")
	contamination.glow_loop(source)
	qdel(source)

/datum/unit_test/radioactive_parent_gc/Run()
	configure_immediate_gc()
	var/list/source_types = list(/obj/item/nuke_core, /obj/item/fuel_rod/plutonium, /obj/item/stock_parts/cell/bluespacereactor, /obj/structure/reagent_dispensers/urbanismbarrel/radium)
	for(var/source_type in source_types)
		create_and_delete(source_type)
	run_gc_fire_cycles(3, yield_for_gc = TRUE)
	for(var/source_type in source_types)
		var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(source_type)
		TEST_ASSERT_EQUAL(item.hard_deletes, 0, "[source_type] потребовал harddel")
		TEST_ASSERT_EQUAL(item.failures, 0, "[source_type] остался жив после qdel")

/// Живые волна и загрязнение не удерживают удалённый источник излучения.
/datum/unit_test/radioactive_source_gc
	parent_type = /datum/unit_test/gc_rewrite_base
	var/obj/item/contaminated
	var/datum/radiation_wave/wave

/datum/unit_test/radioactive_source_gc/proc/create_and_delete_source()
	var/obj/item/wrench/source = new(run_loc_floor_bottom_left)
	contaminated = allocate(/obj/item)
	wave = new(source, NORTH, 1000, RAD_DISTANCE_COEFFICIENT, TRUE)
	STOP_PROCESSING(SSradiation, wave)
	wave.radiate(list(contaminated), 1000)
	TEST_ASSERT_NOTNULL(contaminated.GetComponent(/datum/component/radioactive), "Волна не заразила предмет")
	var/datum/component/radioactive/contamination = contaminated.GetComponent(/datum/component/radioactive)
	TEST_ASSERT_EQUAL(contamination.source_name, "[source]", "Имя источника должно сохраниться для лога")
	qdel(source)

/datum/unit_test/radioactive_source_gc/Run()
	configure_immediate_gc()
	create_and_delete_source()
	run_gc_fire_cycles(3, yield_for_gc = TRUE)
	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(/obj/item/wrench)
	TEST_ASSERT_EQUAL(item.hard_deletes, 0, "Волна или загрязнение удерживают источник")
	TEST_ASSERT_EQUAL(item.failures, 0, "Источник остался жив после qdel")
	qdel(wave)
	wave = null
	contaminated = null

/datum/station_trait/radiation_contamination/unit_test
	trait_to_give = null
	trait_flags = STATION_TRAIT_ABSTRACT

/// Черта заражения не удерживает удалённые предметы до своей отмены.
/datum/unit_test/radiation_trait_payload_gc
	parent_type = /datum/unit_test/gc_rewrite_base
	var/datum/station_trait/radiation_contamination/trait

/datum/unit_test/radiation_trait_payload_gc/proc/delete_payloads()
	for(var/atom/movable/source in run_loc_floor_bottom_left)
		if(istype(source, /obj/item/nuke_core) || istype(source, /obj/item/fuel_rod/plutonium) || istype(source, /obj/item/stock_parts/cell/bluespacereactor) || istype(source, /obj/structure/reagent_dispensers/urbanismbarrel/radium))
			qdel(source)

/datum/unit_test/radiation_trait_payload_gc/Run()
	configure_immediate_gc()
	trait = new /datum/station_trait/radiation_contamination/unit_test
	for(var/payload in list(0, 2, 3, 4))
		trait.spawn_contamination_payload(run_loc_floor_bottom_left, payload)
	TEST_ASSERT_EQUAL(length(trait.contamination_atoms), 4, "Все четыре типа должны учитываться чертой")
	delete_payloads()
	run_gc_fire_cycles(3, yield_for_gc = TRUE)
	for(var/source_type in list(/obj/item/nuke_core, /obj/item/fuel_rod/plutonium, /obj/item/stock_parts/cell/bluespacereactor, /obj/structure/reagent_dispensers/urbanismbarrel/radium))
		var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(source_type)
		TEST_ASSERT_EQUAL(item.hard_deletes, 0, "Черта удерживает [source_type]")
		TEST_ASSERT_EQUAL(item.failures, 0, "Предмет черты [source_type] не освободился")
	qdel(trait)
	trait = null

/// Отмена черты удаляет оставшиеся предметы и пропускает уже удалённые.
/datum/unit_test/radiation_trait_revert/Run()
	var/datum/station_trait/radiation_contamination/trait = allocate(/datum/station_trait/radiation_contamination/unit_test)
	for(var/payload in list(0, 2, 3, 4))
		trait.spawn_contamination_payload(run_loc_floor_bottom_left, payload)
	var/list/sources = list()
	for(var/datum/weakref/source_ref as anything in trait.contamination_atoms)
		sources += source_ref.resolve()
	qdel(sources[1])
	trait.revert()
	for(var/atom/source as anything in sources)
		TEST_ASSERT(QDELETED(source), "Отмена черты не удалила [source.type]")
	TEST_ASSERT_EQUAL(length(trait.contamination_atoms), 0, "Отмена черты должна очистить список")
