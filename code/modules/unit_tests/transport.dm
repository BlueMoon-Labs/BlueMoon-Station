#define TEST_TRAM_ID "unit_test_tram"

/obj/effect/landmark/transport/transport_id/unit_test
	specific_transport_id = TEST_TRAM_ID

/obj/effect/landmark/transport/nav_beacon/tram/nav/unit_test
	specific_transport_id = TEST_TRAM_ID + "_nav"

/obj/effect/landmark/transport/nav_beacon/tram/platform/unit_test_first
	name = "Unit Test First"
	specific_transport_id = TEST_TRAM_ID
	platform_code = 1

/obj/effect/landmark/transport/nav_beacon/tram/platform/unit_test_second
	name = "Unit Test Second"
	specific_transport_id = TEST_TRAM_ID
	platform_code = 2

/obj/machinery/door/airlock/tram/unit_test
	transport_linked_id = TEST_TRAM_ID

/obj/effect/abstract/elevator_music_zone/unit_test
	linked_elevator_id = "unit_test_lift"

/// Два модуля сливаются в один трамвай, он едет к платформе, везёт груз и сносит препятствие на пути, но не решётку под путями.
/datum/unit_test/tram_travels_to_platform
	var/turf/start
	var/turf/second_tile
	var/turf/destination
	var/obj/effect/landmark/transport/nav_beacon/tram/platform/first_platform
	var/obj/effect/landmark/transport/nav_beacon/tram/platform/second_platform
	var/obj/structure/transport/linear/tram/lead
	var/obj/machinery/transport/tram_controller/cabinet
	var/datum/transport_controller/linear/tram/controller
	/// Reservation area the powered tiles came from, put back on teardown
	var/area/original_area
	var/area/powered_area
	var/list/turf/powered_turfs

/// Lays out a 3x2 tram parked at the first platform the way a map would load it
/datum/unit_test/tram_travels_to_platform/proc/build_tram(list/extra_types)
	start = run_loc_floor_bottom_left
	second_tile = get_step(start, EAST)
	destination = locate(start.x + 3, start.y, start.z)

	var/list/created = list()
	SSatoms.map_loader_begin()
	created += new /obj/effect/landmark/transport/transport_id/unit_test(start)
	created += new /obj/effect/landmark/transport/nav_beacon/tram/nav/unit_test(start)
	first_platform = new /obj/effect/landmark/transport/nav_beacon/tram/platform/unit_test_first(start)
	second_platform = new /obj/effect/landmark/transport/nav_beacon/tram/platform/unit_test_second(destination)
	created += first_platform
	created += second_platform
	lead = new(start)
	created += lead
	for(var/offset_x in 0 to 2)
		for(var/offset_y in 0 to 1)
			if(offset_x || offset_y)
				created += new /obj/structure/transport/linear/tram(locate(start.x + offset_x, start.y + offset_y, start.z))
	cabinet = new(start)
	created += cabinet
	for(var/extra_type in extra_types)
		created += new extra_type(start)
	SSatoms.map_loader_stop()
	SSatoms.InitializeAtoms(created)
	allocated += created
	controller = lead.transport_controller_datum

/// The reservation sits in /area/space, which is never powered, so the track gets an area of its own
/datum/unit_test/tram_travels_to_platform/proc/power_track()
	var/turf/track_start = run_loc_floor_bottom_left
	original_area = get_area(track_start)
	powered_area = new /area
	powered_area.power_equip = TRUE
	powered_area.power_light = TRUE
	powered_area.power_environ = TRUE
	powered_turfs = list()
	for(var/offset in 0 to 5)
		var/turf/track_turf = locate(track_start.x + offset, track_start.y, track_start.z)
		powered_area.contents.Add(track_turf)
		powered_turfs += track_turf

/// Runs a calculated route to the end right away instead of waiting on SStransport
/datum/unit_test/tram_travels_to_platform/proc/drive_route()
	controller.set_active(TRUE)
	controller.dispatch_transport()
	STOP_PROCESSING(SStransport, controller)
	for(var/step in 1 to 10)
		controller.scheduled_move = world.time
		if(controller.process(SStransport.wait * 0.1) == PROCESS_KILL)
			break

/datum/unit_test/tram_travels_to_platform/Destroy()
	controller = null
	QDEL_LIST(allocated)
	if(powered_area)
		for(var/turf/track_turf as anything in powered_turfs)
			original_area.contents.Add(track_turf)
		qdel(powered_area)
	powered_area = null
	original_area = null
	powered_turfs = null
	return ..()

/datum/unit_test/tram_travels_to_platform/Run()
	build_tram()
	var/obj/item/stack/rods/cargo = new
	allocated += cargo
	cargo.forceMove(second_tile)

	TEST_ASSERT_NOTNULL(controller, "Трамвай не создал контроллер")
	TEST_ASSERT_EQUAL(controller.specific_transport_id, TEST_TRAM_ID, "Маркер transport_id не передал ID трамваю")
	TEST_ASSERT_EQUAL(length(controller.transport_modules), 1, "Модули одного уровня не слились в один")
	TEST_ASSERT_EQUAL(lead.width, 3, "Слитый модуль не растянулся на всю ширину")
	TEST_ASSERT_EQUAL(lead.height, 2, "Слитый модуль не растянулся на всю высоту")
	TEST_ASSERT_NOTNULL(locate(/obj/structure/transport/linear/tram) in second_tile, "Второй тайл не видит мультитайловый трамвай в своём содержимом")
	for(var/turf/tram_turf as anything in lead.locs)
		for(var/obj/structure/transport/linear/tram/stray_module in tram_turf)
			TEST_ASSERT_EQUAL(stray_module, lead, "После слияния на [COORD(tram_turf)] остался отдельный модуль")
	TEST_ASSERT_EQUAL(controller.idle_platform, first_platform, "Трамвай не встал на стартовую платформу")
	TEST_ASSERT_EQUAL(controller.paired_cabinet, cabinet, "Шкаф управления не нашёл контроллер трамвая")
	TEST_ASSERT(cargo in lead.transport_contents, "Предмет, попавший на трамвай, не стал его грузом")

	var/obj/structure/table/obstacle = allocate(/obj/structure/table, locate(start.x + 4, start.y + 1, start.z))
	var/obj/structure/lattice/track_lattice = allocate(/obj/structure/lattice, locate(start.x + 4, start.y, start.z))
	var/turf/landing_tail = get_step(destination, EAST)
	var/turf/landing_corner = locate(destination.x + 2, destination.y + 1, destination.z)

	TEST_ASSERT(controller.calculate_route(second_platform), "Маршрут до второй платформы не построился")
	TEST_ASSERT_EQUAL(controller.travel_remaining, 3, "Неверная длина маршрута")
	drive_route()

	TEST_ASSERT_EQUAL(lead.loc, destination, "Трамвай не доехал до платформы")
	TEST_ASSERT_EQUAL(controller.idle_platform, second_platform, "Контроллер не отметил прибытие")
	TEST_ASSERT_EQUAL(get_turf(controller.nav_beacon), destination, "Навигационный маяк отстал от трамвая")
	TEST_ASSERT_EQUAL(cabinet.loc, destination, "Шкаф управления отстал от трамвая")
	TEST_ASSERT_EQUAL(cargo.loc, landing_tail, "Груз отстал от трамвая")
	TEST_ASSERT_NOTNULL(locate(/obj/structure/transport/linear/tram) in landing_corner, "После поездки трамвай занимает не те тайлы")
	TEST_ASSERT_NULL(locate(/obj/structure/transport/linear/tram) in start, "Трамвай оставил часть себя на старте")
	TEST_ASSERT(QDELETED(obstacle), "Трамвай проехал сквозь стол, не снеся его")
	TEST_ASSERT(!QDELETED(track_lattice), "Трамвай разломал решётку под путями в прутья")

/// Объекты освещения тайлов не становятся грузом и остаются на своих тайлах после поездки.
/datum/unit_test/tram_travels_to_platform/leaves_lighting
	var/list/atom/movable/lighting_object/created_lighting

/datum/unit_test/tram_travels_to_platform/leaves_lighting/Destroy()
	for(var/atom/movable/lighting_object/tile_lighting as anything in created_lighting)
		if(!QDELETED(tile_lighting))
			qdel(tile_lighting, force = TRUE)
	created_lighting = null
	return ..()

/datum/unit_test/tram_travels_to_platform/leaves_lighting/Run()
	created_lighting = list()
	var/turf/first_tile = run_loc_floor_bottom_left
	var/list/turf/tram_tiles = block(first_tile, locate(first_tile.x + 2, first_tile.y + 1, first_tile.z))
	for(var/turf/tram_tile as anything in tram_tiles)
		if(!tram_tile.lighting_object)
			created_lighting += new /atom/movable/lighting_object(tram_tile)
	build_tram()

	for(var/turf/tram_tile as anything in tram_tiles)
		TEST_ASSERT(!(tram_tile.lighting_object in lead.transport_contents), "Освещение тайла [COORD(tram_tile)] стало грузом трамвая")
	TEST_ASSERT(controller.calculate_route(second_platform), "Маршрут до второй платформы не построился")
	drive_route()
	TEST_ASSERT_EQUAL(lead.loc, destination, "Трамвай не доехал до платформы")
	for(var/turf/tram_tile as anything in tram_tiles)
		TEST_ASSERT_EQUAL(tram_tile.lighting_object.loc, tram_tile, "Освещение тайла [COORD(tram_tile)] уехало с трамваем")

/// Вызов через подсистему закрывает двери, везёт трамвай и открывает их на прибытии.
/datum/unit_test/tram_travels_to_platform/on_request

/datum/unit_test/tram_travels_to_platform/on_request/Run()
	power_track()
	build_tram(list(/obj/machinery/door/airlock/tram/unit_test))
	var/obj/machinery/door/airlock/tram/door = locate() in start
	TEST_ASSERT_NOTNULL(door, "Дверь трамвая не создалась")
	TEST_ASSERT(wait_for_var(door, "density", FALSE, 5 SECONDS), "Дверь трамвая не открылась после загрузки")

	SStransport.incoming_request(cabinet, TEST_TRAM_ID, second_platform.platform_code)
	TEST_ASSERT(wait_for_var(controller, "idle_platform", second_platform, 30 SECONDS), "Трамвай не доехал до платформы по запросу")
	TEST_ASSERT_EQUAL(lead.loc, destination, "Трамвай встал не там, где платформа")
	TEST_ASSERT_EQUAL(door.loc, destination, "Дверь отстала от трамвая")
	TEST_ASSERT(wait_for_var(door, "density", FALSE, 10 SECONDS), "Дверь не открылась на прибытии")
	TEST_ASSERT(wait_for_var(controller, "controller_active", FALSE, 10 SECONDS), "Контроллер не освободился после поездки")

/// Аварийный рычаг обесточенной двери трамвая срабатывает, даже если трамвай сдвинул дверь и пассажира посреди рывка.
/datum/unit_test/tram_door_lever_survives_movement

/datum/unit_test/tram_door_lever_survives_movement/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/obj/machinery/door/airlock/tram/unit_test/door = allocate(/obj/machinery/door/airlock/tram/unit_test, start)
	var/mob/living/carbon/human/passenger = allocate(/mob/living/carbon/human, start)
	TEST_ASSERT(!door.hasPower(), "Резерв обесточен: проверяется ручной рычаг")
	TEST_ASSERT(door.density, "Дверь должна начинать закрытой")

	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door/airlock/tram, try_safety_unlock), passenger)
	sleep(world.tick_lag)
	var/turf/next = get_step(start, NORTH)
	door.forceMove(next)
	passenger.forceMove(next)
	TEST_ASSERT(wait_for_var(door, "density", FALSE, 5 SECONDS), "Рычаг сорвался, когда трамвай сдвинул дверь вместе с пассажиром")

/// Несвязанные платформы лифта едут вбок вместе, без слияния и без потери груза.
/datum/unit_test/lift_platforms_move_together

/datum/unit_test/lift_platforms_move_together/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/above = get_step(start, NORTH)
	var/list/created = list()
	SSatoms.map_loader_begin()
	var/obj/structure/transport/linear/debug/lower = new(start)
	var/obj/structure/transport/linear/debug/upper = new(above)
	created += lower
	created += upper
	SSatoms.map_loader_stop()
	SSatoms.InitializeAtoms(created)
	allocated += created

	var/datum/transport_controller/linear/lift = lower.transport_controller_datum
	TEST_ASSERT_NOTNULL(lift, "Платформа не создала контроллер")
	TEST_ASSERT_EQUAL(upper.transport_controller_datum, lift, "Соседние платформы получили разные контроллеры")
	TEST_ASSERT_EQUAL(length(lift.transport_modules), 2, "Платформы лифта не должны сливаться")
	TEST_ASSERT(!lift.Check_lift_move(UP), "Лифт без открытого пространства над собой собрался ехать вверх")
	TEST_ASSERT(!lift.Check_lift_move(DOWN), "Лифт на сплошном полу собрался ехать вниз")

	var/obj/item/stack/rods/cargo = allocate(/obj/item/stack/rods, above)
	TEST_ASSERT(cargo in upper.transport_contents, "Созданный на платформе предмет не стал грузом")

	lift.move_transport_horizontally(NORTH)
	TEST_ASSERT_EQUAL(lower.loc, above, "Нижняя платформа не сдвинулась")
	TEST_ASSERT_EQUAL(upper.loc, get_step(above, NORTH), "Верхняя платформа не сдвинулась")
	TEST_ASSERT_EQUAL(cargo.loc, upper.loc, "Груз отстал от платформы")

	lift.move_transport_horizontally(SOUTH)
	TEST_ASSERT_EQUAL(lower.loc, start, "Нижняя платформа не вернулась")
	TEST_ASSERT_EQUAL(cargo.loc, above, "Груз не вернулся вместе с платформой")

	cargo.forceMove(get_step(above, EAST))
	TEST_ASSERT(!(cargo in upper.transport_contents), "Ушедший с платформы предмет остался её грузом")

/// Типы транспорта создаются и удаляются без рантаймов и не оставляют себя в реестрах SStransport.
/datum/unit_test/transport_types_create_and_destroy

/datum/unit_test/transport_types_create_and_destroy/Run()
	var/list/types_to_check = typesof(
		/obj/structure/transport/linear,
		/obj/structure/tram,
		/obj/structure/thermoplastic,
		/obj/structure/girder/tram,
		/obj/structure/fluff/tram_rail,
		/obj/structure/holosign/barrier/atmos/tram,
		/obj/structure/chair/sofa/bench,
		/obj/structure/plaque,
		/obj/structure/sign/tram_plate,
		/obj/machinery/transport,
		/obj/machinery/static_signal,
		/obj/machinery/computer/tram_controls,
		/obj/machinery/door/airlock/tram,
		/obj/machinery/door/window/elevator,
		/obj/machinery/door/poddoor/lift,
		/obj/machinery/button/elevator,
		/obj/machinery/button/transport,
		/obj/machinery/elevator_control_panel,
		/obj/machinery/lift_indicator,
		/obj/machinery/incident_display,
		/obj/effect/abstract/elevator_music_zone/unit_test,
		/obj/effect/landmark/transport,
		/obj/item/assembly/control/transport,
		/obj/item/assembly/control/elevator,
		/obj/item/stack/thermoplastic,
		/obj/item/stack/tile/tram,
		/obj/item/stack/tile/noslip/tram,
		/obj/item/wallframe/tram,
		/obj/item/wallframe/indicator_display,
		/obj/item/circuitboard/computer/tram_controls,
		/obj/item/circuitboard/machine/crossing_signal,
		/obj/item/circuitboard/machine/guideway_sensor,
	)
	// A tram module refuses to exist without the landmarks of a mapped tram
	types_to_check -= typesof(/obj/structure/transport/linear/tram)

	for(var/thing_type in types_to_check)
		var/atom/movable/thing = new thing_type(run_loc_floor_bottom_left)
		qdel(thing)
		TEST_ASSERT(QDELETED(thing), "[thing_type] не удалился")

	for(var/turf_type in typesof(/turf/open/floor/tram, /turf/open/indestructible/tram, /turf/open/floor/noslip/tram, /turf/open/floor/glass/reinforced/tram))
		run_loc_floor_bottom_left.ChangeTurf(turf_type)
		TEST_ASSERT(istype(run_loc_floor_bottom_left, turf_type), "Не удалось положить [turf_type]")
		run_loc_floor_bottom_left.ChangeTurf(/turf/open/floor/plasteel)

	for(var/registry in list(SStransport.doors, SStransport.sensors, SStransport.crossing_signals, SStransport.displays))
		for(var/datum/registered as anything in registry)
			TEST_ASSERT(!QDELETED(registered), "В реестре SStransport остался удалённый [registered.type]")
	for(var/network in SStransport.nav_beacons)
		for(var/datum/beacon as anything in SStransport.nav_beacons[network])
			TEST_ASSERT(!QDELETED(beacon), "В навигации SStransport остался удалённый [beacon.type]")
	for(var/transport_type in SStransport.transports_by_type)
		for(var/datum/transport_controller/transport as anything in SStransport.transports_by_type[transport_type])
			TEST_ASSERT(!QDELETED(transport), "В SStransport остался удалённый контроллер [transport.type]")
	for(var/obj/machinery/door/elevator_door as anything in GLOB.elevator_doors)
		TEST_ASSERT(!QDELETED(elevator_door), "В списке лифтовых дверей осталась удалённая [elevator_door.type]")

/// Пути трамвайных объектов, на которые ссылается карта Tramstation, существуют.
/datum/unit_test/tramstation_map_paths_exist

/datum/unit_test/tramstation_map_paths_exist/Run()
	var/static/list/map_paths = list(
		"/obj/effect/abstract/elevator_music_zone",
		"/obj/effect/landmark/transport/nav_beacon/tram/nav/immovable_rod",
		"/obj/effect/landmark/transport/nav_beacon/tram/nav/tramstation/main",
		"/obj/effect/landmark/transport/nav_beacon/tram/platform/tramstation/central",
		"/obj/effect/landmark/transport/nav_beacon/tram/platform/tramstation/east",
		"/obj/effect/landmark/transport/nav_beacon/tram/platform/tramstation/west",
		"/obj/effect/landmark/transport/transport_id",
		"/obj/effect/landmark/transport/transport_id/tramstation/line_1",
		"/obj/effect/turf_decal/tile/neutral/tram",
		"/obj/effect/turf_decal/trimline/tram/corner",
		"/obj/effect/turf_decal/trimline/tram/filled/corner",
		"/obj/effect/turf_decal/trimline/tram/filled/line",
		"/obj/effect/turf_decal/trimline/tram/filled/warning",
		"/obj/machinery/button/elevator/directional/north",
		"/obj/machinery/button/elevator/directional/south",
		"/obj/machinery/button/elevator/directional/east",
		"/obj/machinery/button/elevator/directional/west",
		"/obj/machinery/button/transport/tram/directional/north",
		"/obj/machinery/button/transport/tram/directional/south",
		"/obj/machinery/computer/tram_controls/split/directional/north",
		"/obj/machinery/computer/tram_controls/split/directional/south",
		"/obj/machinery/door/airlock/tram",
		"/obj/machinery/door/window/elevator/left/directional/east",
		"/obj/machinery/door/window/elevator/left/directional/north",
		"/obj/machinery/door/window/elevator/left/directional/south",
		"/obj/machinery/door/window/elevator/left/directional/west",
		"/obj/machinery/door/window/elevator/right/directional/south",
		"/obj/machinery/door/window/elevator/right/directional/west",
		"/obj/machinery/elevator_control_panel",
		"/obj/machinery/elevator_control_panel/directional/north",
		"/obj/machinery/elevator_control_panel/directional/south",
		"/obj/machinery/elevator_control_panel/directional/west",
		"/obj/machinery/incident_display/tram/directional/north",
		"/obj/machinery/incident_display/tram/directional/south",
		"/obj/machinery/lift_indicator/directional/east",
		"/obj/machinery/lift_indicator/directional/north",
		"/obj/machinery/lift_indicator/directional/south",
		"/obj/machinery/lift_indicator/directional/west",
		"/obj/machinery/static_signal/northeast",
		"/obj/machinery/static_signal/northwest",
		"/obj/machinery/static_signal/southeast",
		"/obj/machinery/static_signal/southwest",
		"/obj/machinery/transport/crossing_signal/northeast",
		"/obj/machinery/transport/crossing_signal/northwest",
		"/obj/machinery/transport/crossing_signal/southeast",
		"/obj/machinery/transport/crossing_signal/southwest",
		"/obj/machinery/transport/destination_sign/indicator/directional/north",
		"/obj/machinery/transport/destination_sign/indicator/directional/south",
		"/obj/machinery/transport/destination_sign/split/north",
		"/obj/machinery/transport/destination_sign/split/south",
		"/obj/machinery/transport/guideway_sensor",
		"/obj/machinery/transport/power_rectifier",
		"/obj/machinery/transport/tram_controller",
		"/obj/machinery/transport/tram_controller/tcomms",
		"/obj/structure/chair/sofa/bench/tram",
		"/obj/structure/chair/sofa/bench/tram/left",
		"/obj/structure/chair/sofa/bench/tram/right",
		"/obj/structure/fluff/tram_rail",
		"/obj/structure/fluff/tram_rail/electric",
		"/obj/structure/fluff/tram_rail/electric/anchor",
		"/obj/structure/fluff/tram_rail/end",
		"/obj/structure/fluff/tram_rail/floor",
		"/obj/structure/holosign/barrier/atmos/tram",
		"/obj/structure/plaque/static_plaque/golden/commission/tram",
		"/obj/structure/sign/tram_plate/directional/south",
		"/obj/structure/thermoplastic",
		"/obj/structure/thermoplastic/light",
		"/obj/structure/tram",
		"/obj/structure/tram/split",
		"/obj/structure/tram/spoiler",
		"/obj/structure/transport/linear/public",
		"/obj/structure/transport/linear/tram",
		"/obj/structure/transport/linear/tram/corner/northeast",
		"/obj/structure/transport/linear/tram/corner/northwest",
		"/obj/structure/transport/linear/tram/corner/southeast",
		"/obj/structure/transport/linear/tram/corner/southwest",
		"/turf/open/floor/glass/reinforced/tram",
		"/turf/open/floor/noslip/tram",
		"/turf/open/floor/plating/elevatorshaft",
		"/turf/open/floor/tram",
		"/turf/open/floor/tram/plate",
		"/turf/open/floor/tram/plate/energized",
		"/turf/open/indestructible/tram",
		"/turf/open/indestructible/tram/plate",
	)
	for(var/map_path in map_paths)
		TEST_ASSERT_NOTNULL(text2path(map_path), "Нет типа [map_path], на который ссылается карта")

#undef TEST_TRAM_ID
