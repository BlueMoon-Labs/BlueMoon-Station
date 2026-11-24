/// Модуль карты, догруженный поверх станции до SSatoms, зовёт AfterChange по всей своей рамке,
/// дважды там, где рамки соседних модулей перекрылись. Неинициализированные шлюз и трамвай
/// на этих клетках ничего не собирают заранее и после Initialize встают как обычно.
/datum/unit_test/turf_change_before_init

/datum/unit_test/turf_change_before_init/Run()
	var/turf/door_spot = run_loc_floor_bottom_left
	var/turf/tram_spot = locate(door_spot.x + 2, door_spot.y, door_spot.z)
	var/turf/changed = get_step(door_spot, EAST)

	SSatoms.map_loader_begin()
	var/obj/machinery/door/firedoor/door = allocate(/obj/machinery/door/firedoor, door_spot)
	var/obj/structure/transport/linear/tram = allocate(/obj/structure/transport/linear/turf_change_before_init, tram_spot)
	for(var/pass in 1 to 2)
		changed.AfterChange(CHANGETURF_IGNORE_AIR)
		tram_spot.AfterChange(CHANGETURF_IGNORE_AIR)
	SSatoms.map_loader_stop()

	var/list/tram_signals = tram.signal_procs?[tram_spot]
	var/area/door_area = get_area(door)
	var/door_had_group = !!door.mergers
	var/door_listed_early = (door in door_area.firedoors)
	var/tram_listened_early = !!tram_signals?[COMSIG_ATOM_EXITED]
	SSatoms.InitializeAtoms(list(door, tram))

	TEST_ASSERT(!door_had_group, "Шлюз собрал группу до своей инициализации")
	TEST_ASSERT(!door_listed_early, "Шлюз записался в зону до своей инициализации")
	TEST_ASSERT(!tram_listened_early, "Трамвай подписался на турф до своей инициализации")
	TEST_ASSERT(door in door_area.firedoors, "Инициализированный шлюз не записан в свою зону")
	var/datum/merger/group = door.GetMergeGroup(door.merger_id, door.merger_typecache)
	TEST_ASSERT(group && (door in group.members),"Инициализированный шлюз не в своей группе")
	tram_signals = tram.signal_procs?[tram_spot]
	TEST_ASSERT(tram_signals?[COMSIG_ATOM_EXITED], "Инициализированный трамвай не слушает свой турф")

/obj/structure/transport/linear/turf_change_before_init
	transport_controller_type = null
