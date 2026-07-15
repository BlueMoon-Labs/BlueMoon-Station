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
