// ===== SSspatial_grid (tg port, HEARING + CLIENTS channels) =====
//
// The grid keeps per-cell lists of hearing atoms and client mobs so that
// "who is around" queries walk a few cell lists instead of view() scans or
// full per-z player loops (see has_nearby_player).

/datum/unit_test/spatial_grid_hearing/Run()
	var/obj/item/listener = allocate(/obj/item)
	TEST_ASSERT(!listener.spatial_grid_key, "A plain item must not start with a spatial_grid_key")

	listener.become_hearing_sensitive()
	TEST_ASSERT(listener.spatial_grid_key, "become_hearing_sensitive must set the spatial_grid_key")

	var/datum/spatial_grid_cell/home_cell = SSspatial_grid.get_cell_of(listener)
	TEST_ASSERT_NOTNULL(home_cell, "The test z-level must be covered by the spatial grid")
	TEST_ASSERT(listener in home_cell.hearing_contents, "A hearing item must be in its cell's hearing_contents")

	// crossing a cell boundary moves the entry between cells
	// (the reserved test zone can land near the map edge, so step whichever way fits)
	var/far_x = run_loc_floor_bottom_left.x + SPATIAL_GRID_CELLSIZE * 2
	if(far_x > world.maxx)
		far_x = run_loc_floor_bottom_left.x - SPATIAL_GRID_CELLSIZE * 2
	var/turf/far_turf = locate(far_x, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	TEST_ASSERT_NOTNULL(far_turf, "test premise: a turf two grid cells away must exist")
	listener.forceMove(far_turf)

	var/datum/spatial_grid_cell/far_cell = SSspatial_grid.get_cell_of(listener)
	TEST_ASSERT(far_cell != home_cell, "test premise: the far turf must belong to a different grid cell")
	TEST_ASSERT(!(listener in home_cell.hearing_contents), "After moving away the old cell must not keep the item")
	TEST_ASSERT(listener in far_cell.hearing_contents, "After moving the new cell must hold the item")

	// a container carries its hearing contents between cells
	var/obj/structure/closet/container = allocate(/obj/structure/closet, far_turf)
	listener.forceMove(container)
	TEST_ASSERT(container.spatial_grid_key, "A container holding a hearing item must gain grid awareness")

	container.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(listener in home_cell.hearing_contents, "Moving the container must carry the hearing item into the new cell")
	TEST_ASSERT(!(listener in far_cell.hearing_contents), "Moving the container must remove the hearing item from the old cell")

	// a nullspace round-trip must not leave a stale registration behind
	// (doMove(null) does not call Moved(), it cleans the grid explicitly)
	listener.moveToNullspace()
	TEST_ASSERT(!(listener in home_cell.hearing_contents), "Moving to nullspace must remove the item from its cell")
	listener.forceMove(far_turf)
	TEST_ASSERT(listener in far_cell.hearing_contents, "Returning from nullspace must register in the new cell")
	TEST_ASSERT(!(listener in home_cell.hearing_contents), "Returning from nullspace must not leave a stale old-cell entry")
	listener.forceMove(run_loc_floor_bottom_left)

	// losing hearing cleans the cell, the key and the container's awareness
	listener.lose_hearing_sensitivity()
	TEST_ASSERT(!(listener in home_cell.hearing_contents), "lose_hearing_sensitivity must remove the item from its cell")
	TEST_ASSERT(!listener.spatial_grid_key, "lose_hearing_sensitivity must clear the spatial_grid_key")
	TEST_ASSERT(!container.spatial_grid_key, "The container must lose grid awareness when its contents stop hearing")

// Регресс: onShuttleMove двигает атомы голым присваиванием loc мимо Moved(),
// и без явного переключения ячеек слышащие оставались прописаны в ячейках
// старого дока (глухота после перелёта + вечная ссылка в hearing_contents)
/datum/unit_test/spatial_grid_shuttle_move/Run()
	var/obj/item/listener = allocate(/obj/item)
	listener.become_hearing_sensitive()

	var/datum/spatial_grid_cell/home_cell = SSspatial_grid.get_cell_of(listener)
	TEST_ASSERT_NOTNULL(home_cell, "The test z-level must be covered by the spatial grid")
	TEST_ASSERT(listener in home_cell.hearing_contents, "premise: a hearing item must be in its cell's hearing_contents")

	//(the reserved test zone can land near the map edge, so step whichever way fits)
	var/far_x = run_loc_floor_bottom_left.x + SPATIAL_GRID_CELLSIZE * 2
	if(far_x > world.maxx)
		far_x = run_loc_floor_bottom_left.x - SPATIAL_GRID_CELLSIZE * 2
	var/turf/far_turf = locate(far_x, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	TEST_ASSERT_NOTNULL(far_turf, "test premise: a turf two grid cells away must exist")

	listener.onShuttleMove(far_turf, get_turf(listener), null, NORTH, null, null)

	var/datum/spatial_grid_cell/far_cell = SSspatial_grid.get_cell_of(listener)
	TEST_ASSERT(far_cell != home_cell, "test premise: the far turf must belong to a different grid cell")
	TEST_ASSERT(!(listener in home_cell.hearing_contents), "A shuttle move must remove the item from the old cell")
	TEST_ASSERT(listener in far_cell.hearing_contents, "A shuttle move must register the item in the new cell")

	listener.lose_hearing_sensitivity()

/datum/unit_test/spatial_grid_clients/Run()
	var/mob/living/simple_animal/npc = allocate(/mob/living/simple_animal)
	var/mob/living/carbon/human/fake_player = allocate(/mob/living/carbon/human, get_step(run_loc_floor_bottom_left, EAST))

	TEST_ASSERT(SSspatial_grid.initialized, "test premise: SSspatial_grid must be initialized in CI")
	TEST_ASSERT(!npc.has_nearby_player(10), "No client mobs are registered, has_nearby_player must be FALSE")

	// the clients channel is normally fed by Login; feed it directly here
	fake_player.enable_client_mobs_in_contents()
	var/datum/spatial_grid_cell/cell = SSspatial_grid.get_cell_of(fake_player)
	TEST_ASSERT_NOTNULL(cell, "The test z-level must be covered by the spatial grid")
	TEST_ASSERT(fake_player in cell.client_contents, "A registered client mob must be in its cell's client_contents")
	TEST_ASSERT(npc.has_nearby_player(10), "has_nearby_player must see a client mob one tile away")

	// too far away: outside the searched cells entirely
	// (the reserved test zone can land near the map edge, so step whichever way fits)
	var/far_x = run_loc_floor_bottom_left.x + 60
	if(far_x > world.maxx)
		far_x = run_loc_floor_bottom_left.x - 60
	var/turf/far_turf = locate(far_x, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	TEST_ASSERT_NOTNULL(far_turf, "test premise: a turf 60 tiles away must exist")
	fake_player.forceMove(far_turf)
	TEST_ASSERT(!npc.has_nearby_player(10), "has_nearby_player must not see a client mob 60 tiles away")

	// a client mob inside a container still counts (recursive contents)
	var/obj/structure/closet/box = allocate(/obj/structure/closet, get_step(run_loc_floor_bottom_left, WEST))
	fake_player.forceMove(box)
	TEST_ASSERT(npc.has_nearby_player(10), "A client mob inside a nearby container must still count")

	// logout path
	fake_player.clear_important_client_contents()
	TEST_ASSERT(!npc.has_nearby_player(10), "After clearing the clients channel has_nearby_player must be FALSE")
	TEST_ASSERT(!(fake_player in SSspatial_grid.get_cell_of(box)?.client_contents), "Clearing the channel must empty the cell")

// ===== get_hearers_in_view / get_hearers_in_range on the grid =====

///opaque blocker for the line-of-sight assertion
/obj/effect/spatial_grid_test_wall
	opacity = TRUE

/datum/unit_test/spatial_grid_hearers
	var/hearer_signal_fired = FALSE

/datum/unit_test/spatial_grid_hearers/proc/on_hearer_signal(datum/source, list/candidates, list/hearers)
	SIGNAL_HANDLER
	hearer_signal_fired = TRUE

///the grid path must return exactly the same set of hearers as the legacy walk
/datum/unit_test/spatial_grid_hearers/proc/assert_hearers_equivalence(turf/center, scenario)
	var/list/via_legacy = legacy_get_hearers_in_view(7, center)
	var/list/via_grid = get_hearers_in_view(7, center)
	TEST_ASSERT_EQUAL(length(via_grid), length(via_legacy), "[scenario]: the grid path found [length(via_grid)] hearers, the legacy walk [length(via_legacy)]")
	for(var/hearer in via_legacy)
		TEST_ASSERT(hearer in via_grid, "[scenario]: the grid path is missing a hearer the legacy walk found")

/datum/unit_test/spatial_grid_hearers/Run()
	var/turf/center = run_loc_floor_bottom_left
	//the reserved test zone can land near the map edge: step whichever way has room
	var/step_dir = (center.x + 12 <= world.maxx) ? 1 : -1

	var/obj/effect/hearer_contents_test_listener/near_hearer = allocate(/obj/effect/hearer_contents_test_listener, locate(center.x + step_dir * 3, center.y, center.z))
	var/obj/structure/closet/box = allocate(/obj/structure/closet, locate(center.x + step_dir * 2, center.y + 1, center.z))
	var/obj/effect/hearer_contents_test_listener/boxed_hearer = allocate(/obj/effect/hearer_contents_test_listener)
	boxed_hearer.forceMove(box)
	var/obj/effect/hearer_contents_test_listener/far_hearer = allocate(/obj/effect/hearer_contents_test_listener, locate(center.x + step_dir * 12, center.y, center.z))
	var/obj/effect/hearer_contents_test_listener/center_hearer = allocate(/obj/effect/hearer_contents_test_listener, center)

	RegisterSignal(near_hearer, COMSIG_ATOM_HEARER_IN_VIEW, PROC_REF(on_hearer_signal))

	var/list/heard = get_hearers_in_view(7, center)
	TEST_ASSERT(near_hearer in heard, "get_hearers_in_view must find a hearer standing 3 tiles away")
	TEST_ASSERT(boxed_hearer in heard, "get_hearers_in_view must find a hearer inside a closet in view")
	TEST_ASSERT(center_hearer in heard, "get_hearers_in_view must find a hearer on the center turf")
	TEST_ASSERT(!(far_hearer in heard), "get_hearers_in_view must not find a hearer 12 tiles away with radius 7")
	TEST_ASSERT(hearer_signal_fired, "COMSIG_ATOM_HEARER_IN_VIEW must still fire for found hearers")
	UnregisterSignal(near_hearer, COMSIG_ATOM_HEARER_IN_VIEW)

	//the true correctness bar for the port: same output as the legacy BFS walk
	//over view(), with and without an opaque blocker in the line of sight
	//(whether that blocker stops hearing is engine LOS semantics, not ours -
	//we only guarantee the port does not CHANGE the answer)
	assert_hearers_equivalence(center, "open field")
	var/obj/effect/spatial_grid_test_wall/wall = allocate(/obj/effect/spatial_grid_test_wall, locate(center.x + step_dir, center.y, center.z))
	TEST_ASSERT_NOTNULL(wall, "test premise: the opaque wall must exist")
	assert_hearers_equivalence(center, "opaque blocker")
	qdel(wall)

	//radius 0: only the center turf's own hearers
	var/list/local_only = get_hearers_in_view(0, center)
	TEST_ASSERT(center_hearer in local_only, "Radius 0 must include hearers on the center turf")
	TEST_ASSERT(!(near_hearer in local_only), "Radius 0 must not include hearers on other turfs")

	//pure range variant ignores walls and filters by distance
	var/obj/effect/spatial_grid_test_wall/range_wall = allocate(/obj/effect/spatial_grid_test_wall, locate(center.x + step_dir, center.y, center.z))
	var/list/ranged = get_hearers_in_range(5, center)
	TEST_ASSERT_NOTNULL(range_wall, "test premise: the opaque wall must exist")
	TEST_ASSERT(near_hearer in ranged, "get_hearers_in_range must ignore opacity")
	TEST_ASSERT(boxed_hearer in ranged, "get_hearers_in_range must find hearers inside containers")
	TEST_ASSERT(!(far_hearer in ranged), "get_hearers_in_range must filter by distance")

	//no ears may remain assigned after the queries
	for(var/mob/oranges_ear/ear as anything in SSspatial_grid.pregenerated_oranges_ears)
		TEST_ASSERT_NULL(ear.loc, "All oranges_ears must be unassigned (in nullspace) after queries")

// Регресс: оверрайд Exited без ..() (слипер, харвестер и ко) глотал чистку
// important_recursive_contents - машина вечно держала каждого посетителя
// (прод-сканы: слиперы с удалёнными мобами в hearing/client каналах)

/datum/unit_test/sleeper_exit_recursive_contents/Run()
	var/obj/machinery/sleeper/bed = allocate(/obj/machinery/sleeper, run_loc_floor_bottom_left)
	var/obj/item/listener = allocate(/obj/item)
	listener.become_hearing_sensitive()

	listener.forceMove(bed)
	TEST_ASSERT(listener in bed.important_recursive_contents?[RECURSIVE_CONTENTS_HEARING_SENSITIVE], \
		"premise: a hearing item inside a sleeper must appear in its recursive contents")

	listener.forceMove(run_loc_floor_bottom_left)
	TEST_ASSERT(!LAZYLEN(bed.important_recursive_contents), \
		"leaving a sleeper must clean its important_recursive_contents (Exited must call parent)")

	listener.lose_hearing_sensitivity()

// ===== Регресс: выпуск жертвы из головокраба при его смерти =====
//
// headcrab/Destroy() выпускал человека голым присваиванием loc: без
// Exited/Moved жертва оставалась в important_recursive_contents умирающего
// краба, и его force_remove_from_grid снимал её из ячеек HEARING/CLIENTS до
// пересечения границы ячейки 17x17 (пропавший слух/радио, ложный
// has_nearby_player). Теперь Destroy() делает forceMove.

/datum/unit_test/headcrab_release_keeps_spatial_grid/Run()
	TEST_ASSERT(SSspatial_grid.initialized, "test premise: SSspatial_grid must be initialized in CI")

	var/mob/living/carbon/human/victim = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	victim.enable_client_mobs_in_contents() // канал CLIENTS обычно кормит Login
	TEST_ASSERT(victim in SSspatial_grid.get_cell_of(victim)?.hearing_contents, "premise: the victim must sit in the HEARING channel")
	TEST_ASSERT(victim in SSspatial_grid.get_cell_of(victim)?.client_contents, "premise: the victim must sit in the CLIENTS channel")

	var/mob/living/simple_animal/hostile/headcrab/crab = allocate(/mob/living/simple_animal/hostile/headcrab, run_loc_floor_bottom_left)
	victim.forceMove(crab)
	qdel(crab)

	TEST_ASSERT_EQUAL(victim.loc, run_loc_floor_bottom_left, "headcrab Destroy must dump the victim onto its turf")
	var/datum/spatial_grid_cell/cell = SSspatial_grid.get_cell_of(victim)
	TEST_ASSERT(victim in cell?.hearing_contents, "the victim must stay in the HEARING channel after the headcrab dies")
	TEST_ASSERT(victim in cell?.client_contents, "the victim must stay in the CLIENTS channel after the headcrab dies")

	victim.clear_important_client_contents() // cleanup канала CLIENTS
