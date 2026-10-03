/// Карман 3x3 вокруг пары открытых тайлов A-B (или одного тайла при width = 2).
/proc/refactor_linda_build_arena(turf/base, width)
	for(var/dx in 0 to width)
		for(var/dy in 0 to 2)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			if(dx == 0 || dy == 0 || dx == width || dy == 2)
				T.ChangeTurf(/turf/closed/wall)

/// Пара без разницы не снимает архив соседа, пара с разницей снимает его и шерит в тот же фаер.
/datum/unit_test/refactor_linda_neighbour_archive_on_share/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/saved_flag = SSair.sleeping_edges_enabled
	SSair.sleeping_edges_enabled = FALSE

	var/turf/base = run_loc_floor_bottom_left
	refactor_linda_build_arena(base, 3)
	var/turf/open/tile_a = locate(base.x + 1, base.y + 1, base.z)
	var/turf/open/tile_b = locate(base.x + 2, base.y + 1, base.z)
	TEST_ASSERT(istype(tile_a) && istype(tile_b), "arena pair is not open turfs")
	tile_a.ImmediateCalculateAdjacentTurfs()
	tile_b.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(tile_b in tile_a.atmos_adjacent_turfs, "pair must be atmos-adjacent")
	tile_a.air.copy_from_turf(tile_a)
	tile_b.air.copy_from_turf(tile_b)
	var/datum/excited_group/pair_group = new
	pair_group.add_turf(tile_a)
	pair_group.add_turf(tile_b)

	var/fire = max(tile_a.current_cycle, tile_b.current_cycle, SSair.times_fired) + 100
	tile_b.archived_cycle = 0
	tile_a.process_cell(fire)
	TEST_ASSERT_EQUAL(tile_a.archived_cycle, fire, "the processed tile must archive itself")
	TEST_ASSERT_EQUAL(tile_b.archived_cycle, 0, "a pair with nothing to share must leave the neighbour archive alone")

	var/o2_before = tile_a.air.get_moles(GAS_O2)
	tile_b.air.set_moles(GAS_O2, tile_b.air.get_moles(GAS_O2) + 30)
	fire++
	tile_a.process_cell(fire)
	TEST_ASSERT_EQUAL(tile_b.archived_cycle, fire, "a sharing pair must archive the neighbour in the same fire")
	TEST_ASSERT_EQUAL(tile_b.temperature_archived, tile_b.air.temperature, "the neighbour archive must carry its temperature")
	TEST_ASSERT(tile_a.air.get_moles(GAS_O2) > o2_before + 1, "the pair must share from the fresh archive (moved [tile_a.air.get_moles(GAS_O2) - o2_before] mol)")

	fire++
	tile_a.archived_cycle = fire
	tile_a.temperature_archived = 123
	tile_a.process_cell(fire)
	TEST_ASSERT_EQUAL(tile_a.temperature_archived, 123, "a tile already archived this fire must keep its snapshot")

	SSair.sleeping_edges_enabled = saved_flag
	if(tile_a.excited_group)
		tile_a.excited_group.dismantle()
	SSair.remove_from_active(tile_a)
	SSair.remove_from_active(tile_b)
	tile_a.air.copy_from_turf(tile_a)
	tile_b.air.copy_from_turf(tile_b)

/// Выселение осевших членов идёт по месту: тот же список, порядок бодрых сохранён, осевшие отвязаны.
/datum/unit_test/refactor_linda_evict_compacts_in_place/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/base = run_loc_floor_bottom_left
	var/turf/open/first = locate(base.x + 1, base.y + 1, base.z)
	var/turf/open/settled = locate(base.x + 2, base.y + 1, base.z)
	var/turf/open/last = locate(base.x + 3, base.y + 1, base.z)
	TEST_ASSERT(istype(first) && istype(settled) && istype(last), "test turfs are not open")

	var/datum/excited_group/group = new
	group.add_turf(first)
	group.add_turf(settled)
	group.add_turf(last)
	SSair.sleep_active_turf(settled)
	var/list/members = group.turf_list

	group.evict_settled_members()
	TEST_ASSERT(group.turf_list == members, "eviction must compact turf_list in place")
	TEST_ASSERT_EQUAL(length(members), 2, "only the settled member must leave")
	TEST_ASSERT(members[1] == first && members[2] == last, "awake members must keep their order")
	TEST_ASSERT_NULL(settled.excited_group, "the evicted member must be unhooked")
	TEST_ASSERT(first.excited_group == group && last.excited_group == group, "awake members must stay in the group")
	TEST_ASSERT_EQUAL(group.awake_members, 2, "awake members must be recounted")

	group.dismantle()

/// process_cell перерисовывает оверлей, когда смесь поменялась, и снимает его с чистого воздуха.
/datum/unit_test/refactor_linda_process_cell_redraws_overlay/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/base = run_loc_floor_bottom_left
	refactor_linda_build_arena(base, 2)
	var/turf/open/tile = locate(base.x + 1, base.y + 1, base.z)
	TEST_ASSERT(istype(tile), "arena tile is not open")
	tile.ImmediateCalculateAdjacentTurfs()
	tile.air.copy_from_turf(tile)
	tile.update_visuals()
	TEST_ASSERT_NULL(tile.atmos_overlay_types, "clean air must start without an overlay")

	var/fire = max(tile.current_cycle, SSair.times_fired) + 100
	tile.air.set_moles(GAS_PLASMA, 50)
	tile.process_cell(fire)
	TEST_ASSERT_NOTNULL(tile.atmos_overlay_types, "a visible gas must get an overlay on the next process_cell")
	var/list/overlay_after_change = tile.atmos_overlay_types
	fire++
	tile.process_cell(fire)
	TEST_ASSERT(tile.atmos_overlay_types == overlay_after_change, "unchanged air must keep the same overlay")

	tile.air.copy_from_turf(tile)
	fire++
	tile.process_cell(fire)
	TEST_ASSERT_NULL(tile.atmos_overlay_types, "clean air must drop the overlay on the next process_cell")

	SSair.remove_from_active(tile)
